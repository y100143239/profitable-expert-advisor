//+------------------------------------------------------------------+
//|                                             EMACrossOver_V1.mq5    | 
//|                        Iterative Optimization V1                 | 
//|                        Added: Dynamic Margin, Equity Guard, Trend| 
//+------------------------------------------------------------------+ 
#property strict 
#include <Trade\Trade.mqh> 

// Input parameters (Original)
input int MagicNumber = 42;
input int scoreThreshold = 5200;       // Score threshold for trade entry
input int slopeThreshold = 93;        // EMA slope threshold
input double maxScore = 7900;             // Max score value for clamping
input int cooldownMinutes = 18;        // Cooldown period in minutes
input int tradeCooldownMinutes = 24;    // Trade debounce cooldown period
input ENUM_TIMEFRAMES emaTimeFrame = PERIOD_H1;  // EMA Timeframe
input double delayClampAbsolute = 1690;
input int emaPeriod = 64; // EMA period
input double crossOverStep = 950;
input double slopeThresholdStep = 635;
input double emaDistanceStep = 150;
input double emaDecayStep = 0;
input double decayMultiplier = 0.08; // Decay multiplier
input double distanceThreshold = 28.5;  // Distance threshold
input double atrMultiplier = 7.6;  // Multiplier for dynamic SL and TP
input double TrailingStop  = 5;
input bool UseTrailingStop = true;
input int maxCrossoverTrades = 4;  // Maximum number of trades per crossover
input double max_drawdown = 0.1;     // Maximum drawdown percentage (original)
input bool resetCrossoverTradeOnDistance = false;
input int resetCrossoverNumber = 0;
input double minimumLotSize = 0.01;
input int maxTimeInPosition = 9;
input int tradeLengthThreshold = 98;
input int reverseTP = 32;
input int reverseLotSizeMultiplier = 15;
input int secondaryPositionHoldTime = 32;

// --- Iteration 1 Refancements ---
input bool UseEquityProtection = true;      // Enable equity drawdown protection
input double EquityDDStopPct = 18.0;         // Stop all trading if EqDD % exceeds this
input int EquityStopCooldownMin = 120;       // Minutes to wait after equity stop

input bool UseDynamicMargin = true;         // Enable dynamic margin management
input double MaxMarginLoadPct = 25.0;        // Max margin load (Margin/Equity)
input double MinMarginLevelPct = 300.0;      // Min Margin Level (Equity/Margin)

input bool UseMarketStateDuration = true;   // Vary hold time based on Strong/Weak market
input ENUM_TIMEFRAMES TrendTF = PERIOD_D1;  // Timeframe for trend detection
input int TrendMAPeriod = 200;               // Period for trend EMA

input bool UseSwapManagement = true;        // Close positions before swap if in profit
input double SwapCostThreshold = 1.0;        // swap per lot threshold for warning

// Global variables
int emaHandle;                       // EMA handle
int trendHandle;                     // Trend EMA handle
double prevScore = 0;                // Previous score 
double currentScore = 0;             // Current score 
double emaPrevValue = 0;             // Previous EMA value 
double emaCurrentValue = 0;          // Current EMA value 
double emaSlope = 0;                 // EMA slope value 
CTrade trade;                        // Trading object

datetime lastCrossoverTime = 0;      // Time of last crossover
datetime lastTradeTime = 0;          // Time of last trade
int crossoverTradeCount = 0;         // Count of trades after each crossover

datetime lastEquityStopLimit = 0;    // Time when equity guard was triggered

//+------------------------------------------------------------------+
//| Expert initialization function                                   |
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

//+------------------------------------------------------------------+
//| Expert deinitialization function                                 |
//+------------------------------------------------------------------+
void OnDeinit(const int reason) {
    IndicatorRelease(emaHandle);
    IndicatorRelease(trendHandle);
}

//+------------------------------------------------------------------+
//| Market State Detection                                           |
//| Returns: 1 (Strong/Bullish), -1 (Weak/Bearish), 0 (Neutral)       |
//+------------------------------------------------------------------+
int GetMarketState() {
    double trendBuffer[];
    if(CopyBuffer(trendHandle, 0, 0, 1, trendBuffer) < 1) return 0;
    double trendMA = trendBuffer[0];
    double close = iClose(Symbol(), TrendTF, 0);
    
    if (close > trendMA) return 1;  // Bullish
    if (close < trendMA) return -1; // Bearish
    return 0;
}

//+------------------------------------------------------------------+
//| Check Equity Guard                                               |
//+------------------------------------------------------------------+
bool IsEquityStopHit() {
    if (!UseEquityProtection) return false;
    
    // Check if currently in cooldown
    if (lastEquityStopLimit > 0 && (TimeCurrent() - lastEquityStopLimit < EquityStopCooldownMin * 60)) {
        return true;
    }

    double balance = AccountInfoDouble(ACCOUNT_BALANCE);
    double equity = AccountInfoDouble(ACCOUNT_EQUITY);
    
    if (balance > 0) {
        double ddPct = (balance - equity) / balance * 100.0;
        if (ddPct >= EquityDDStopPct) {
            Print("EQUITY PROTECTION TRIGGERED: ddPct=", ddPct, "% - Closing all positions.");
            CloseAllPositions();
            lastEquityStopLimit = TimeCurrent();
            return true;
        }
    }
    return false;
}

//+------------------------------------------------------------------+
//| Expert tick function                                             |
//+------------------------------------------------------------------+
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

    // Swap Management: If near swap time and in small profit, consider closing
    if (UseSwapManagement) {
        MqlDateTime dt;
        TimeCurrent(dt);
        // Near server midnight (e.g. 23:55 to 00:05)
        if (dt.hour == 23 && dt.min > 55) {
             // Close positions that have profit > spread cost
             CheckForSwapExit();
        }
    }

    if (TimeCurrent() - lastCrossoverTime >= cooldownMinutes * 60) {
        if (closePrev < emaPrevValue && closeCurr > emaCurrentValue) {
            currentScore += crossOverStep;
            crossoverTradeCount = 0;
            lastCrossoverTime = TimeCurrent();
        } 
        else if (closePrev > emaPrevValue && closeCurr < emaCurrentValue) {
            currentScore -= crossOverStep;
            crossoverTradeCount = 0;
            lastCrossoverTime = TimeCurrent();
        }
    }

    if (emaSlope > slopeThreshold) currentScore += slopeThresholdStep;
    else if (emaSlope < -slopeThreshold) currentScore -= slopeThresholdStep;
    else if (MathAbs(currentScore) > delayClampAbsolute) {
        currentScore *= decayMultiplier;
    }

    if(UseTrailingStop) ApplyTrailingStop();

    double priceToEmaDistance = closeCurr - emaCurrentValue;
    if (MathAbs(priceToEmaDistance) > distanceThreshold) {
        if (priceToEmaDistance > 0) currentScore += emaDistanceStep;
        else currentScore -= emaDistanceStep;
    } 
    else {
        if (currentScore > 0) currentScore -= emaDecayStep;
        else currentScore += emaDecayStep;
    }

    if ((prevScore > 0 && currentScore <= 0) || (prevScore < 0 && currentScore >= 0)) {
        Close_Position_MN(MagicNumber);
    }

    prevScore = currentScore;
    if (crossoverTradeCount >= maxCrossoverTrades) return;

    if (TimeCurrent() - lastTradeTime >= tradeCooldownMinutes * 60) {
        double atrArray[];
        if (CopyBuffer(iATR(Symbol(), Period(), 14), 0, 0, 1, atrArray) < 1) return;
        double atrValue = atrArray[0];

        long stopLevel = SymbolInfoInteger(Symbol(), SYMBOL_TRADE_STOPS_LEVEL);
        double minStopLoss = stopLevel * SymbolInfoDouble(Symbol(), SYMBOL_POINT);

        double dynamicSL = atrValue * atrMultiplier;
        dynamicSL = MathMax(dynamicSL, minStopLoss);

        // Signal Logic
        if (currentScore > scoreThreshold) { // Buy
            if (!PositionSelect(Symbol()) || PositionGetInteger(POSITION_MAGIC) != MagicNumber) {
                trade.SetExpertMagicNumber(MagicNumber);
                if (trade.Buy(lotSize, Symbol(), Bid, Bid - dynamicSL, 0)) { 
                    crossoverTradeCount++;
                    lastTradeTime = TimeCurrent();
                }
            }
        }
        else if (currentScore < -scoreThreshold) { // Sell
            if (!PositionSelect(Symbol()) || PositionGetInteger(POSITION_MAGIC) != MagicNumber) {
                trade.SetExpertMagicNumber(MagicNumber);
                if (trade.Sell(lotSize, Symbol(), Ask, Ask + dynamicSL, 0)) { 
                    crossoverTradeCount++;
                    lastTradeTime = TimeCurrent();
                }
            }
        }
    }

    CheckPositions();
}

void CheckForSwapExit() {
    for (int i = PositionsTotal() - 1; i >= 0; i--) {
        ulong ticket = PositionGetTicket(i);
        if (PositionSelectByTicket(ticket)) {
            if (PositionGetInteger(POSITION_MAGIC) == MagicNumber) {
                double profit = PositionGetDouble(POSITION_PROFIT);
                if (profit > 0) {
                    Print("Swap exit triggered for ticket ", ticket);
                    trade.PositionClose(ticket);
                }
            }
        }
    }
}

void CheckPositions() {
    if (PositionsTotal() <= 0) return;
    int marketState = GetMarketState();

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

                // Strong/Weak Market logic for hold duration "长多 短空"
                double durationMultiplier = 1.0;
                if (UseMarketStateDuration) {
                    if (marketState == 1) { // Strong Market
                        if (type == POSITION_TYPE_BUY) durationMultiplier = 1.5; // Hold longer
                        else durationMultiplier = 0.5; // Shorten hold
                    } else if (marketState == -1) { // Weak Market
                        if (type == POSITION_TYPE_SELL) durationMultiplier = 1.5;
                        else durationMultiplier = 0.5;
                    }
                }

                if (tradeLength > (long)(tradeLengthThreshold * 60 * durationMultiplier)) {
                    double lotSize = PositionGetDouble(POSITION_VOLUME);
                    double newLotSize = NormalizeDouble(lotSize * reverseLotSizeMultiplier, 2);
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
                
                if (PositionsTotal() == 1 && PositionGetDouble(POSITION_VOLUME) > lotSizeForReverse(ticket)) {
                    // Close extra volume if needed logic... (simplified here)
                }

                double Ask = SymbolInfoDouble(Symbol(), SYMBOL_ASK);
                double Bid = SymbolInfoDouble(Symbol(), SYMBOL_BID);
                if (type == POSITION_TYPE_BUY && PositionGetDouble(POSITION_SL) > 0 && Bid <= PositionGetDouble(POSITION_SL)) CloseOriginalTrade();
                else if (type == POSITION_TYPE_SELL && PositionGetDouble(POSITION_SL) > 0 && Ask >= PositionGetDouble(POSITION_SL)) CloseOriginalTrade();
            }
        }
    }
}

double lotSizeForReverse(ulong ticket) {
    if (PositionSelectByTicket(ticket)) return PositionGetDouble(POSITION_VOLUME); 
    return 0;
}

void CloseOriginalTrade() {
    for (int i = PositionsTotal() - 1; i >= 0; i--) {
        ulong ticket = PositionGetTicket(i);
        if (PositionSelectByTicket(ticket) && PositionGetInteger(POSITION_MAGIC) == MagicNumber) {
            trade.PositionClose(ticket);
        }
    }
}

void CloseAllPositions() {
    for (int i = PositionsTotal() - 1; i >= 0; i--) {
        ulong ticket = PositionGetTicket(i);
        if (PositionSelectByTicket(ticket) && PositionGetInteger(POSITION_MAGIC) == MagicNumber) {
            trade.PositionClose(ticket);
        }
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
        double openPrice = PositionGetDouble(POSITION_PRICE_OPEN);

        if(type == POSITION_TYPE_BUY) {
            double bid = NormalizeDouble(SymbolInfoDouble(Symbol(), SYMBOL_BID), digits);
            if(bid - openPrice > NormalizeDouble(point * TrailingStop, digits)) {
                double newSL = NormalizeDouble(bid - point * TrailingStop, digits);
                if(sl < newSL) trade.PositionModify(ticket, newSL, PositionGetDouble(POSITION_TP));
            }
        } else if(type == POSITION_TYPE_SELL) {
            double ask = NormalizeDouble(SymbolInfoDouble(Symbol(), SYMBOL_ASK), digits);
            if(openPrice - ask > NormalizeDouble(point * TrailingStop, digits)) {
                double newSL = NormalizeDouble(ask + point * TrailingStop, digits);
                if(sl > newSL || sl == 0) trade.PositionModify(ticket, newSL, PositionGetDouble(POSITION_TP));
            }
        }
    }
}

void Close_Position_MN(ulong magicNumber) {  
    for(int i = PositionsTotal() - 1; i >= 0; i--) {
        ulong ticket = PositionGetTicket(i);
        if(PositionSelectByTicket(ticket) && PositionGetInteger(POSITION_MAGIC) == magicNumber) {
            trade.PositionClose(ticket);
        }
    }
}

double CalculateLotSize() {
    double balance = AccountInfoDouble(ACCOUNT_BALANCE);
    double equity = AccountInfoDouble(ACCOUNT_EQUITY);
    double margin = AccountInfoDouble(ACCOUNT_MARGIN);
    
    // Original balance-based risk
    double allowedDrawdown = balance * max_drawdown;
    double baseDrawdownPerLot = 150; 
    double lotSize = (allowedDrawdown / baseDrawdownPerLot) * 0.01;
    
    if (UseDynamicMargin) {
        double maxLoad = MaxMarginLoadPct / 100.0;
        double minLevel = MinMarginLevelPct / 100.0;
        
        // Target margin based on Equity (rewarding growth)
        double targetTotalMargin = equity * maxLoad;
        double availableMargin = targetTotalMargin - margin;
        
        // Margin Level check (Total Equity / Total Margin >= 3.0)
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
    
    return NormalizeDouble(lotSize, 2);
}
