//+------------------------------------------------------------------+
//|                                             EMACrossOver_V2.mq5    |
//|                        Iterative Optimization V2                 |
//|   Strip martingale reverse-doubling. Add ATR TP + trend-filter   |
//+------------------------------------------------------------------+
#property strict
#include <Trade\Trade.mqh>

// Input parameters (Original signal engine)
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
input double atrMultiplier = 7.6;       // ATR multiplier for dynamic SL
input double atrTPMultiplier = 4.0;     // ATR multiplier for dynamic TP (NEW)
input double TrailingStop = 5;
input bool UseTrailingStop = true;
input int maxCrossoverTrades = 4;
input double max_drawdown = 0.1;
input double minimumLotSize = 0.01;
input int tradeLengthThreshold = 98;    // Minutes; time-based exit (NO reverse)

// --- Risk safeguards (from V1) ---
input bool UseEquityProtection = true;
input double EquityDDStopPct = 18.0;
input int EquityStopCooldownMin = 120;
input bool UseDynamicMargin = true;
input double MaxMarginLoadPct = 25.0;
input double MinMarginLevelPct = 300.0;
input bool UseTrendFilter = true;
input ENUM_TIMEFRAMES TrendTF = PERIOD_D1;
input int TrendMAPeriod = 200;
input bool UseSwapManagement = true;

// Global variables
int emaHandle;
int trendHandle;
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

//+------------------------------------------------------------------+
int OnInit() {
    emaHandle = iMA(Symbol(), emaTimeFrame, emaPeriod, 0, MODE_EMA, PRICE_CLOSE);
    trendHandle = iMA(Symbol(), TrendTF, TrendMAPeriod, 0, MODE_EMA, PRICE_CLOSE);
    if (emaHandle == INVALID_HANDLE || trendHandle == INVALID_HANDLE) {
        Print("Failed to create indicators");
        return INIT_FAILED;
    }
    return INIT_SUCCEEDED;
}

void OnDeinit(const int reason) {
    IndicatorRelease(emaHandle);
    IndicatorRelease(trendHandle);
}

//+------------------------------------------------------------------+
//| Market State: 1 (Strong/Bull), -1 (Weak/Bear), 0 (Neutral)        |
//+------------------------------------------------------------------+
int GetMarketState() {
    double tb[];
    if(CopyBuffer(trendHandle, 0, 0, 1, tb) < 1) return 0;
    double close = iClose(Symbol(), TrendTF, 0);
    if (close > tb[0]) return 1;
    if (close < tb[0]) return -1;
    return 0;
}

bool IsEquityStopHit() {
    if (!UseEquityProtection) return false;
    if (lastEquityStopLimit > 0 && (TimeCurrent() - lastEquityStopLimit < EquityStopCooldownMin * 60))
        return true;
    double balance = AccountInfoDouble(ACCOUNT_BALANCE);
    double equity = AccountInfoDouble(ACCOUNT_EQUITY);
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

//+------------------------------------------------------------------+
void OnTick() {
    if (IsEquityStopHit()) return;

    double emaBuffer[];
    double lotSize = CalculateLotSize();
    if(lotSize < minimumLotSize) lotSize = minimumLotSize;

    double Ask = SymbolInfoDouble(Symbol(), SYMBOL_ASK);
    double Bid = SymbolInfoDouble(Symbol(), SYMBOL_BID);

    if (CopyBuffer(emaHandle, 0, 0, 2, emaBuffer) < 2) return;
    emaPrevValue = emaBuffer[1];
    emaCurrentValue = emaBuffer[0];
    emaSlope = - (emaCurrentValue - emaPrevValue) * 100;

    double closePrev = iClose(Symbol(), Period(), 1);
    double closeCurr = iClose(Symbol(), Period(), 0);

    if (UseSwapManagement) {
        MqlDateTime dt; TimeCurrent(dt);
        if (dt.hour == 23 && dt.min > 55) CheckForSwapExit();
    }

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
    if (crossoverTradeCount >= maxCrossoverTrades) { CheckPositions(); return; }

    if (TimeCurrent() - lastTradeTime >= tradeCooldownMinutes * 60) {
        double atrArray[];
        if (CopyBuffer(iATR(Symbol(), Period(), 14), 0, 0, 1, atrArray) < 1) { CheckPositions(); return; }
        double atrValue = atrArray[0];
        long stopLevel = SymbolInfoInteger(Symbol(), SYMBOL_TRADE_STOPS_LEVEL);
        double minStop = stopLevel * SymbolInfoDouble(Symbol(), SYMBOL_POINT);
        double dynamicSL = MathMax(atrValue * atrMultiplier, minStop);
        double dynamicTP = MathMax(atrValue * atrTPMultiplier, minStop);

        int marketState = UseTrendFilter ? GetMarketState() : 0;

        if (currentScore > scoreThreshold) { // BUY
            bool allow = (!UseTrendFilter) || (marketState >= 0);
            if (allow && (!PositionSelect(Symbol()) || PositionGetInteger(POSITION_MAGIC) != MagicNumber)) {
                trade.SetExpertMagicNumber(MagicNumber);
                if (trade.Buy(lotSize, Symbol(), Ask, Bid - dynamicSL, Bid + dynamicTP)) {
                    crossoverTradeCount++; lastTradeTime = TimeCurrent();
                }
            }
        } else if (currentScore < -scoreThreshold) { // SELL
            bool allow = (!UseTrendFilter) || (marketState <= 0);
            if (allow && (!PositionSelect(Symbol()) || PositionGetInteger(POSITION_MAGIC) != MagicNumber)) {
                trade.SetExpertMagicNumber(MagicNumber);
                if (trade.Sell(lotSize, Symbol(), Bid, Ask + dynamicSL, Ask - dynamicTP)) {
                    crossoverTradeCount++; lastTradeTime = TimeCurrent();
                }
            }
        }
    }
    CheckPositions();
}

void CheckForSwapExit() {
    for (int i = PositionsTotal() - 1; i >= 0; i--) {
        ulong ticket = PositionGetTicket(i);
        if (PositionSelectByTicket(ticket) && PositionGetInteger(POSITION_MAGIC) == MagicNumber) {
            if (PositionGetDouble(POSITION_PROFIT) > 0) trade.PositionClose(ticket);
        }
    }
}

//+------------------------------------------------------------------+
//| Position mgmt: time-based exit ONLY (no martingale reverse)       |
//| 强市: 长多短空   弱市: 长空短多                                    |
//+------------------------------------------------------------------+
void CheckPositions() {
    if (PositionsTotal() <= 0) return;
    int marketState = GetMarketState();
    for (int i = PositionsTotal() - 1; i >= 0; i--) {
        ulong ticket = PositionGetTicket(i);
        if (!PositionSelectByTicket(ticket)) continue;
        if (PositionGetInteger(POSITION_MAGIC) != MagicNumber) continue;
        if (PositionGetString(POSITION_SYMBOL) != Symbol()) continue;

        long type = PositionGetInteger(POSITION_TYPE);
        long tradeLength = (long)(TimeCurrent() - PositionGetInteger(POSITION_TIME));

        double durationMultiplier = 1.0;
        if (marketState == 1)
            durationMultiplier = (type == POSITION_TYPE_BUY) ? 1.5 : 0.5;
        else if (marketState == -1)
            durationMultiplier = (type == POSITION_TYPE_SELL) ? 1.5 : 0.5;

        if (tradeLength > (long)(tradeLengthThreshold * 60 * durationMultiplier))
            trade.PositionClose(ticket);
    }
}

void CloseAllPositions() {
    for (int i = PositionsTotal() - 1; i >= 0; i--) {
        ulong ticket = PositionGetTicket(i);
        if (PositionSelectByTicket(ticket) && PositionGetInteger(POSITION_MAGIC) == MagicNumber)
            trade.PositionClose(ticket);
    }
}

void ApplyTrailingStop() {
    for(int i=PositionsTotal()-1; i>=0; i--) {
        if(PositionGetSymbol(i) != Symbol()) continue;
        ulong ticket = PositionGetTicket(i);
        if(PositionGetInteger(POSITION_MAGIC) != MagicNumber) continue;
        double point = SymbolInfoDouble(Symbol(), SYMBOL_POINT);
        int digits = (int)SymbolInfoInteger(Symbol(), SYMBOL_DIGITS);
        long type = PositionGetInteger(POSITION_TYPE);
        double sl = PositionGetDouble(POSITION_SL);
        double tp = PositionGetDouble(POSITION_TP);
        double openPrice = PositionGetDouble(POSITION_PRICE_OPEN);
        if(type == POSITION_TYPE_BUY) {
            double bid = NormalizeDouble(SymbolInfoDouble(Symbol(), SYMBOL_BID), digits);
            if(bid - openPrice > NormalizeDouble(point * TrailingStop, digits)) {
                double newSL = NormalizeDouble(bid - point * TrailingStop, digits);
                if(sl < newSL) trade.PositionModify(ticket, newSL, tp);
            }
        } else if(type == POSITION_TYPE_SELL) {
            double ask = NormalizeDouble(SymbolInfoDouble(Symbol(), SYMBOL_ASK), digits);
            if(openPrice - ask > NormalizeDouble(point * TrailingStop, digits)) {
                double newSL = NormalizeDouble(ask + point * TrailingStop, digits);
                if(sl > newSL || sl == 0) trade.PositionModify(ticket, newSL, tp);
            }
        }
    }
}

void Close_Position_MN(ulong magicNumber) {
    for(int i = PositionsTotal() - 1; i >= 0; i--) {
        ulong ticket = PositionGetTicket(i);
        if(PositionSelectByTicket(ticket) && PositionGetInteger(POSITION_MAGIC) == magicNumber)
            trade.PositionClose(ticket);
    }
}

double CalculateLotSize() {
    double balance = AccountInfoDouble(ACCOUNT_BALANCE);
    double equity = AccountInfoDouble(ACCOUNT_EQUITY);
    double margin = AccountInfoDouble(ACCOUNT_MARGIN);
    double allowedDrawdown = balance * max_drawdown;
    double baseDrawdownPerLot = 150;
    double lotSize = (allowedDrawdown / baseDrawdownPerLot) * 0.01;

    if (UseDynamicMargin) {
        double maxLoad = MaxMarginLoadPct / 100.0;
        double minLevel = MinMarginLevelPct / 100.0;
        double targetTotalMargin = equity * maxLoad;
        double availableMargin = targetTotalMargin - margin;
        double capTotalMargin = equity / minLevel;
        double levelAvailableMargin = capTotalMargin - margin;
        double finalAvailableMargin = MathMin(availableMargin, levelAvailableMargin);
        if (finalAvailableMargin < 0) finalAvailableMargin = 0;
        double marginRequired = 0;
        if (OrderCalcMargin(ORDER_TYPE_BUY, Symbol(), 1.0, SymbolInfoDouble(Symbol(), SYMBOL_ASK), marginRequired) && marginRequired > 0) {
            double marginBasedLot = finalAvailableMargin / marginRequired;
            lotSize = MathMin(lotSize, marginBasedLot);
        }
    }
    if (lotSize < minimumLotSize) lotSize = minimumLotSize;
    return NormalizeDouble(lotSize, 2);
}
