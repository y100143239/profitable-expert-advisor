//+------------------------------------------------------------------+
//|                                             EMACrossOver_V3.mq5    |
//|   Original profit engine (martingale) + Equity circuit breaker   |
//|   + Dynamic-margin CAP (25% load / 300% level). Tames 70% EqDD.   |
//+------------------------------------------------------------------+
#property strict
#include <Trade\Trade.mqh>

// ---- Original inputs ----
input int MagicNumber = 42;
input int scoreThreshold = 5200;
input int slopeThreshold = 93;
input double maxScore = 7900;
input int cooldownMinutes = 18;
input int tradeCooldownMinutes = 24;
input ENUM_TIMEFRAMES emaTimeFrame = PERIOD_H1;
input double delayClampAbsolute = 1690;
input int emaPeriod = 64;
input double crossOverStep = 950;
input double slopeThresholdStep = 635;
input double emaDistanceStep = 150;
input double emaDecayStep = 0;
input double decayMultiplier = 0.08;
input double distanceThreshold = 28.5;
input double atrMultiplier = 7.6;
input double TrailingStop  = 5;
input bool UseTrailingStop = true;
input int maxCrossoverTrades = 4;
input double max_drawdown = 0.1;
input bool resetCrossoverTradeOnDistance = false;
input int resetCrossoverNumber = 0;
input double minimumLotSize = 0.01;
input int maxTimeInPosition = 9;
input int tradeLengthThreshold = 98;
input int reverseTP = 32;
input int reverseLotSizeMultiplier = 15;
input int secondaryPositionHoldTime = 32;

// ---- V3 safeguards ----
input bool   UseEquityProtection = true;   // Floating-DD circuit breaker
input double EquityDDStopPct     = 30.0;   // Close all if (bal-eq)/bal% >= this
input int    EquityStopCooldownMin = 240;  // Cool-down after a breaker hit
input bool   UseDynamicMargin    = true;   // Cap lot to margin budget
input double MaxMarginLoadPct    = 25.0;   // Max margin/equity load
input double MinMarginLevelPct   = 300.0;  // Min equity/margin level

// Global variables
int emaHandle;
double prevScore = 0;
double currentScore = 0;
double emaPrevValue = 0;
double emaCurrentValue = 0;
double emaSlope = 0;
CTrade trade;

datetime lastCrossoverTime = 0;
datetime lastTradeTime = 0;
int crossoverTradeCount = 0;
datetime lastEquityStopLimit = 0;

int OnInit() {
    emaHandle = iMA(Symbol(), emaTimeFrame, emaPeriod, 0, MODE_EMA, PRICE_CLOSE);
    if (emaHandle == INVALID_HANDLE) { Print("Failed to create EMA handle"); return INIT_FAILED; }
    return INIT_SUCCEEDED;
}

void OnDeinit(const int reason) {
    if (emaHandle != INVALID_HANDLE) { IndicatorRelease(emaHandle); emaHandle = INVALID_HANDLE; }
}

//+------------------------------------------------------------------+
//| Floating equity-DD circuit breaker                                |
//+------------------------------------------------------------------+
bool IsEquityStopHit() {
    if (!UseEquityProtection) return false;
    if (lastEquityStopLimit > 0 && (TimeCurrent() - lastEquityStopLimit < EquityStopCooldownMin * 60))
        return true;
    double balance = AccountInfoDouble(ACCOUNT_BALANCE);
    double equity  = AccountInfoDouble(ACCOUNT_EQUITY);
    if (balance > 0) {
        double ddPct = (balance - equity) / balance * 100.0;
        if (ddPct >= EquityDDStopPct) {
            CloseAllPositions();
            lastEquityStopLimit = TimeCurrent();
            return true;
        }
    }
    return false;
}

void OnTick() {
    if (IsEquityStopHit()) return;

    double emaBuffer[];
    double lotSize = CalculateLotSize();
    if(lotSize < minimumLotSize) lotSize = minimumLotSize;

    double Ask = SymbolInfoDouble(Symbol(), SYMBOL_ASK);
    double Bid = SymbolInfoDouble(Symbol(), SYMBOL_BID);

    int copied = CopyBuffer(emaHandle, 0, 0, 2, emaBuffer);
    if (copied < 2) return;

    emaPrevValue = emaBuffer[1];
    emaCurrentValue = emaBuffer[0];
    emaSlope = - (emaCurrentValue - emaPrevValue) * 100;

    double closePrev = iClose(Symbol(), Period(), 1);
    double closeCurr = iClose(Symbol(), Period(), 0);

    if (TimeCurrent() - lastCrossoverTime >= cooldownMinutes * 60) {
        if (closePrev < emaPrevValue && closeCurr > emaCurrentValue) {
            currentScore += crossOverStep; crossoverTradeCount = 0; lastCrossoverTime = TimeCurrent();
        } else if (closePrev > emaPrevValue && closeCurr < emaCurrentValue) {
            currentScore -= crossOverStep; crossoverTradeCount = 0; lastCrossoverTime = TimeCurrent();
        }
    }

    if (emaSlope > slopeThreshold) currentScore += slopeThresholdStep;
    else if (emaSlope < -slopeThreshold) currentScore -= slopeThresholdStep;
    else if (MathAbs(currentScore) > delayClampAbsolute) currentScore *= decayMultiplier;

    if(UseTrailingStop) ApplyTrailingStop();

    double priceToEmaDistance = closeCurr - emaCurrentValue;
    if (MathAbs(priceToEmaDistance) > distanceThreshold) {
        if (priceToEmaDistance > 0) currentScore += emaDistanceStep;
        else currentScore -= emaDistanceStep;
    } else {
        if (currentScore > 0) currentScore -= emaDecayStep;
        else currentScore += emaDecayStep;
    }

    if ((prevScore > 0 && currentScore <= 0) || (prevScore < 0 && currentScore >= 0))
        Close_Position_MN(MagicNumber);
    prevScore = currentScore;

    if (crossoverTradeCount > maxCrossoverTrades) return;

    if (TimeCurrent() - lastTradeTime >= tradeCooldownMinutes * 60) {
        double atrArray[];
        if (CopyBuffer(iATR(Symbol(), Period(), 14), 0, 0, 1, atrArray) < 1) return;
        double currentPrice = Bid;
        double atrValue = atrArray[0];
        long stopLevel = SymbolInfoInteger(Symbol(), SYMBOL_TRADE_STOPS_LEVEL);
        double minStopLoss = stopLevel * SymbolInfoDouble(Symbol(), SYMBOL_POINT);
        double dynamicSL = MathMax(atrValue * atrMultiplier, minStopLoss);

        if (currentScore > scoreThreshold) {
            if ((!PositionSelect(Symbol()) || PositionGetInteger(POSITION_MAGIC) != MagicNumber)
                && crossoverTradeCount < maxCrossoverTrades) {
                trade.SetExpertMagicNumber(MagicNumber);
                if (trade.Buy(lotSize, Symbol(), currentPrice, Bid - dynamicSL, 0)) {
                    crossoverTradeCount++; lastTradeTime = TimeCurrent();
                }
            }
        } else if (currentScore < -scoreThreshold) {
            if ((!PositionSelect(Symbol()) || PositionGetInteger(POSITION_MAGIC) != MagicNumber)
                && crossoverTradeCount < maxCrossoverTrades) {
                trade.SetExpertMagicNumber(MagicNumber);
                if (trade.Sell(lotSize, Symbol(), currentPrice, Ask + dynamicSL, 0)) {
                    crossoverTradeCount++; lastTradeTime = TimeCurrent();
                }
            }
        }
    }

    CheckPositions();
}

//+------------------------------------------------------------------+
//| Original CheckPositions (martingale reverse + reverseTP)          |
//+------------------------------------------------------------------+
void CheckPositions() {
    if (PositionsTotal() <= 0) return;
    if (PositionsTotal() == 2) {
        for (int i = 0; i < PositionsTotal(); i++) {
            ulong ticket = PositionGetTicket(i);
            if (PositionSelectByTicket(ticket)) {
                long tradeLength = (long)(TimeCurrent() - PositionGetInteger(POSITION_TIME));
                if (tradeLength > secondaryPositionHoldTime * 60) {
                    CloseAllPositions();
                    return;
                }
            }
        }
    } else if (PositionsTotal() < 2) {
        for (int i = 0; i < PositionsTotal(); i++) {
            ulong ticket = PositionGetTicket(i);
            if (PositionSelectByTicket(ticket)) {
                double profit = PositionGetDouble(POSITION_PROFIT);
                long tradeLength = (long)(TimeCurrent() - PositionGetInteger(POSITION_TIME));
                long type = PositionGetInteger(POSITION_TYPE);

                if (tradeLength > tradeLengthThreshold * 60) {
                    double lots = PositionGetDouble(POSITION_VOLUME);
                    double newLotSize = NormalizeDouble(lots * reverseLotSizeMultiplier, 2);
                    crossoverTradeCount = maxCrossoverTrades + 1;
                    if (type == POSITION_TYPE_BUY) {
                        trade.SetExpertMagicNumber(MagicNumber);
                        trade.Sell(newLotSize, Symbol(), SymbolInfoDouble(Symbol(), SYMBOL_BID));
                    } else if (type == POSITION_TYPE_SELL) {
                        trade.SetExpertMagicNumber(MagicNumber);
                        trade.Buy(newLotSize, Symbol(), SymbolInfoDouble(Symbol(), SYMBOL_ASK));
                    }
                }

                if (profit >= reverseTP) {
                    Close_Position_MN(MagicNumber);
                    CloseAllPositions();
                }

                if (PositionsTotal() == 1 && PositionGetDouble(POSITION_VOLUME) == minimumLotSize * reverseLotSizeMultiplier) {
                    trade.PositionClose(ticket);
                }

                double Ask = SymbolInfoDouble(Symbol(), SYMBOL_ASK);
                double Bid = SymbolInfoDouble(Symbol(), SYMBOL_BID);
                if (type == POSITION_TYPE_BUY && PositionGetDouble(POSITION_SL) > 0 && Bid <= PositionGetDouble(POSITION_SL))
                    CloseOriginalTrade();
                else if (type == POSITION_TYPE_SELL && PositionGetDouble(POSITION_SL) > 0 && Ask >= PositionGetDouble(POSITION_SL))
                    CloseOriginalTrade();
            }
        }
    }
}

void CloseOriginalTrade() {
    for (int i = PositionsTotal() - 1; i >= 0; i--) {
        ulong ticket = PositionGetTicket(i);
        if (PositionSelectByTicket(ticket)) {
            if (PositionGetInteger(POSITION_TYPE) == POSITION_TYPE_BUY) trade.PositionClose(ticket);
            else if (PositionGetInteger(POSITION_TYPE) == POSITION_TYPE_SELL) trade.PositionClose(ticket);
        }
    }
}

void CloseAllPositions() {
    for (int i = PositionsTotal() - 1; i >= 0; i--) {
        ulong ticket = PositionGetTicket(i);
        if (PositionSelectByTicket(ticket)) {
            if (PositionGetInteger(POSITION_TYPE) == POSITION_TYPE_BUY) trade.PositionClose(ticket);
            else if (PositionGetInteger(POSITION_TYPE) == POSITION_TYPE_SELL) trade.PositionClose(ticket);
        }
    }
}

void ApplyTrailingStop() {
    for(int i=PositionsTotal()-1; i>=0; i--) {
        string symbol = PositionGetSymbol(i);
        ulong PositionTicket = PositionGetTicket(i);
        long trade_type = PositionGetInteger(POSITION_TYPE);
        if(PositionGetInteger(POSITION_MAGIC) != MagicNumber) continue;
        double POINT = SymbolInfoDouble(symbol, SYMBOL_POINT);
        int DIGIT = (int)SymbolInfoInteger(symbol, SYMBOL_DIGITS);
        if(trade_type == 0) {
            double Bid = NormalizeDouble(SymbolInfoDouble(symbol,SYMBOL_BID),DIGIT);
            if(Bid-PositionGetDouble(POSITION_PRICE_OPEN) > NormalizeDouble(POINT * TrailingStop,DIGIT)) {
                if(PositionGetDouble(POSITION_SL) < NormalizeDouble(Bid - POINT * TrailingStop,DIGIT))
                    trade.PositionModify(PositionTicket,NormalizeDouble(Bid - POINT * TrailingStop,DIGIT),PositionGetDouble(POSITION_TP));
            }
        }
        if(trade_type == 1) {
            double Ask = NormalizeDouble(SymbolInfoDouble(symbol,SYMBOL_ASK),DIGIT);
            if((PositionGetDouble(POSITION_PRICE_OPEN) - Ask) > NormalizeDouble(POINT * TrailingStop,DIGIT)) {
                if((PositionGetDouble(POSITION_SL) > NormalizeDouble(Ask + POINT * TrailingStop,DIGIT)) || (PositionGetDouble(POSITION_SL)==0))
                    trade.PositionModify(PositionTicket,NormalizeDouble(Ask + POINT * TrailingStop,DIGIT),PositionGetDouble(POSITION_TP));
            }
        }
    }
}

void Close_Position_MN(ulong magicNumber) {
    int total = PositionsTotal();
    for(int i = total - 1; i >= 0; i--) {
        ulong ticket = PositionGetTicket(i);
        string symbol = PositionGetSymbol(i);
        if(PositionSelect(symbol)) {
            if (PositionGetInteger(POSITION_MAGIC) == magicNumber && PositionGetInteger(POSITION_TICKET) == ticket) {
                if(symbol == _Symbol) trade.PositionClose(ticket);
            }
        }
    }
}

//+------------------------------------------------------------------+
//| Original lot sizing + dynamic-margin CAP (only caps, never grows) |
//+------------------------------------------------------------------+
double CalculateLotSize() {
    double balance = AccountInfoDouble(ACCOUNT_BALANCE);
    double allowedDrawdown = balance * max_drawdown;
    double baseDrawdownPerLot = 150;
    double lotSize = (allowedDrawdown / baseDrawdownPerLot) * 0.01;

    if (UseDynamicMargin) {
        double equity = AccountInfoDouble(ACCOUNT_EQUITY);
        double margin = AccountInfoDouble(ACCOUNT_MARGIN);
        double maxLoad = MaxMarginLoadPct / 100.0;
        double minLevel = MinMarginLevelPct / 100.0;
        double availByLoad  = equity * maxLoad - margin;
        double availByLevel = equity / minLevel - margin;
        double avail = MathMin(availByLoad, availByLevel);
        if (avail < 0) avail = 0;
        double marginReq = 0;
        if (OrderCalcMargin(ORDER_TYPE_BUY, Symbol(), 1.0, SymbolInfoDouble(Symbol(), SYMBOL_ASK), marginReq) && marginReq > 0) {
            double capLot = avail / marginReq;
            if (capLot < lotSize) lotSize = capLot;  // CAP only
        }
    }
    return NormalizeDouble(lotSize, 2);
}
