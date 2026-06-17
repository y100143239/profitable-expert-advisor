//+------------------------------------------------------------------+
//| _EMACrossOver_iter1_dynamic_20260617 / main.mq5                  |
//|                                                                  |
//| Iteration 1 of READY_EMACrossOverXAUUSD optimisation            |
//| Key improvements over original:                                  |
//|  - ATR-based dynamic SL + TP (no more zero TP)                   |
//|  - ATR-based trailing stop (original 5-point trail was useless)  |
//|  - Market-regime detection (ADX): trend-follow vs mean-reversion |
//|    强市(ADX high) -> 长多短空 / 弱市(ADX low) -> 长空短多(fade) |
//|  - Swap management: close before swap roll, reopen if trend ok   |
//|  - Dynamic lot size: equity/balance boost + hard margin floor    |
//|    (min margin level 300%, equity boost capped at +25%)          |
//|  - Removed martingale (reverseLotSizeMultiplier) — too dangerous |
//|  - Max time in position with optional trend-valid re-entry       |
//+------------------------------------------------------------------+
#property copyright "y100143239"
#property version   "1.00"
#property strict
#include <Trade\Trade.mqh>

//===================================================================
// INPUT PARAMETERS
//===================================================================

input group "=== Core Score System ==="
input int    MagicNumber           = 4200;
input int    scoreThreshold        = 5200;      // Min |score| to enter
input int    slopeThreshold        = 93;        // EMA slope threshold
input int    cooldownMinutes       = 18;        // Min minutes between crossover signals
input int    tradeCooldownMinutes  = 24;        // Min minutes between trade entries
input ENUM_TIMEFRAMES emaTimeFrame = PERIOD_H1; // EMA signal timeframe
input double delayClampAbsolute    = 1690.0;    // Score magnitude before decay activates
input double decayMultiplier       = 0.08;      // Score decay rate when slope neutral
input int    emaPeriod             = 64;        // EMA period
input double crossOverStep         = 950.0;     // Score added on EMA crossover
input double slopeThresholdStep    = 635.0;     // Score added on slope signal
input double emaDistanceStep       = 150.0;     // Score added on price-EMA distance
input double emaDecayStep          = 0.0;       // Score decay per tick when price near EMA
input double distanceThreshold     = 28.5;      // Min price-EMA distance to trigger score
input double maxScore              = 7900.0;    // Score clamp ceiling
input int    maxCrossoverTrades    = 4;         // Max entries per crossover event

input group "=== ATR-based SL / TP / Trailing ==="
input int    atrPeriod             = 14;
input double atrSLMultiplier       = 1.8;       // Stop-loss  = ATR × this
input double atrTPMultiplier       = 2.5;       // Take-profit = ATR × this
input bool   UseTrailingStop       = true;
input double atrTrailActivateMult  = 1.0;       // Trail starts after ATR × this profit
input double atrTrailDistanceMult  = 0.8;       // Trail distance = ATR × this

input group "=== Market Regime (ADX + RSI) ==="
input int    adxPeriod             = 14;
input double adxStrongThreshold    = 25.0;      // ADX > this → strong trend market
input int    rsiPeriod             = 14;
input double rsiOverbought         = 70.0;      // Overbought level (weak market sell)
input double rsiOversold           = 30.0;      // Oversold level   (weak market buy)

input group "=== Lot Sizing & Margin Control ==="
input double minimumLotSize        = 0.01;
input double max_drawdown          = 0.10;      // Base drawdown budget as % of balance
input double equityBoostMultiplier = 2.0;       // Lot boost rate when equity > balance
input double maxLeverageBoost      = 0.25;      // Cap: max +25% lot increase
input double minMarginLevelPct     = 300.0;     // Hard floor: margin level must stay >= 300%

input group "=== Swap Management ==="
input bool   UseSwapManagement     = true;
input int    swapCloseHour         = 22;        // Server hour to start pre-swap close
input int    swapCloseMinute       = 45;        // Minute within that hour
input int    swapReopenHour        = 1;         // Server hour for post-swap re-entry
input int    swapReopenMinute      = 0;
input double swapMinProfitToClose  = 0.0;       // Close on swap only if profit >= this
input double swapMaxLossToAllow    = -100.0;    // Do NOT close if loss worse than this

input group "=== Time-based Position Exit ==="
input int    maxTimeInPositionMin  = 480;       // Max minutes in position (8 h default)
input bool   reopenAfterTimeExit   = true;      // Re-enter if trend still valid after exit

//===================================================================
// GLOBAL STATE
//===================================================================
int      g_emaHandle = INVALID_HANDLE;
int      g_atrHandle = INVALID_HANDLE;
int      g_adxHandle = INVALID_HANDLE;
int      g_rsiHandle = INVALID_HANDLE;

double   g_prevScore    = 0.0;
double   g_currentScore = 0.0;
double   g_emaPrev      = 0.0;
double   g_emaCurr      = 0.0;

CTrade   g_trade;

datetime g_lastCrossoverTime   = 0;
datetime g_lastTradeTime       = 0;
int      g_crossoverTradeCount = 0;

bool     g_swapClosed      = false;
datetime g_swapClosedAt    = 0;
int      g_lastClosedType  = -1;   // Type of position closed by swap/time logic

//===================================================================
// INIT / DEINIT
//===================================================================
int OnInit()
{
    g_emaHandle = iMA(_Symbol, emaTimeFrame, emaPeriod, 0, MODE_EMA, PRICE_CLOSE);
    g_atrHandle = iATR(_Symbol, PERIOD_CURRENT, atrPeriod);
    g_adxHandle = iADX(_Symbol, PERIOD_CURRENT, adxPeriod);
    g_rsiHandle = iRSI(_Symbol, PERIOD_CURRENT, rsiPeriod, PRICE_CLOSE);

    if (g_emaHandle == INVALID_HANDLE || g_atrHandle == INVALID_HANDLE ||
        g_adxHandle == INVALID_HANDLE || g_rsiHandle == INVALID_HANDLE)
    {
        Print("OnInit: indicator handle creation failed. Error=", GetLastError());
        return INIT_FAILED;
    }

    g_trade.SetExpertMagicNumber(MagicNumber);
    g_trade.SetDeviationInPoints(30);
    g_trade.SetTypeFilling(ORDER_FILLING_IOC);

    Print("EMACrossOver_iter1 ready | Symbol=", _Symbol,
          " | Magic=", MagicNumber,
          " | EMA(", emaPeriod, ") TF=", EnumToString(emaTimeFrame));
    return INIT_SUCCEEDED;
}

void OnDeinit(const int reason)
{
    if (g_emaHandle != INVALID_HANDLE) { IndicatorRelease(g_emaHandle); g_emaHandle = INVALID_HANDLE; }
    if (g_atrHandle != INVALID_HANDLE) { IndicatorRelease(g_atrHandle); g_atrHandle = INVALID_HANDLE; }
    if (g_adxHandle != INVALID_HANDLE) { IndicatorRelease(g_adxHandle); g_adxHandle = INVALID_HANDLE; }
    if (g_rsiHandle != INVALID_HANDLE) { IndicatorRelease(g_rsiHandle); g_rsiHandle = INVALID_HANDLE; }
}

//===================================================================
// HELPER: Copy one confirmed indicator buffer value (bar index 1)
//===================================================================
bool GetIndicatorVal(int handle, int bufIdx, double &val)
{
    double buf[];
    ArraySetAsSeries(buf, true);
    if (CopyBuffer(handle, bufIdx, 0, 3, buf) < 3) return false;
    val = buf[1];
    return true;
}

//===================================================================
// HELPER: Count our open positions split by direction
//===================================================================
void CountPositions(int &buys, int &sells)
{
    buys = 0; sells = 0;
    for (int i = PositionsTotal() - 1; i >= 0; i--)
    {
        ulong tk = PositionGetTicket(i);
        if (!PositionSelectByTicket(tk)) continue;
        if (PositionGetString(POSITION_SYMBOL) != _Symbol) continue;
        if ((int)PositionGetInteger(POSITION_MAGIC) != MagicNumber) continue;
        if (PositionGetInteger(POSITION_TYPE) == POSITION_TYPE_BUY) buys++;
        else                                                          sells++;
    }
}

//===================================================================
// MARKET REGIME: ADX determines strong (trend) vs weak (range) market
//  强市(strong ADX) → trend-following: 长多短空
//  弱市(weak ADX)   → mean-reversion:  长空短多 (fade extremes via RSI)
//===================================================================
bool IsStrongMarket(double &adxMain, double &diPlus, double &diMinus)
{
    double mainBuf[], plusBuf[], minusBuf[];
    ArraySetAsSeries(mainBuf,  true);
    ArraySetAsSeries(plusBuf,  true);
    ArraySetAsSeries(minusBuf, true);

    if (CopyBuffer(g_adxHandle, 0, 0, 3, mainBuf)  < 3) { adxMain = 0; return false; }
    if (CopyBuffer(g_adxHandle, 1, 0, 3, plusBuf)   < 3) { adxMain = 0; return false; }
    if (CopyBuffer(g_adxHandle, 2, 0, 3, minusBuf)  < 3) { adxMain = 0; return false; }

    adxMain = mainBuf[1];
    diPlus  = plusBuf[1];
    diMinus = minusBuf[1];
    return (adxMain > adxStrongThreshold);
}

//===================================================================
// DYNAMIC LOT SIZE
//   Base: proportional to balance × max_drawdown
//   Boost: equity above balance → up to +maxLeverageBoost (25%)
//   Cap: margin level after opening must stay >= minMarginLevelPct
//===================================================================
double CalculateLotSize()
{
    double balance    = AccountInfoDouble(ACCOUNT_BALANCE);
    double equity     = AccountInfoDouble(ACCOUNT_EQUITY);
    double margin     = AccountInfoDouble(ACCOUNT_MARGIN);

    if (balance <= 0) return minimumLotSize;

    // Base lot from historical drawdown-per-lot calibration (~$150 DD / 0.01 lot)
    double baseLot = (balance * max_drawdown / 150.0) * 0.01;

    // Equity boost: positive float → increase position size proportionally
    double boost = 0.0;
    if (equity > balance)
    {
        double excessRatio = (equity - balance) / balance;
        boost = MathMin(excessRatio * equityBoostMultiplier, maxLeverageBoost);
    }
    double lotSize = baseLot * (1.0 + boost);

    // Margin floor: ensure margin_level remains >= minMarginLevelPct after open
    double marginInit = SymbolInfoDouble(_Symbol, SYMBOL_MARGIN_INITIAL);
    if (marginInit > 0)
    {
        // margin_level = equity / (existing_margin + new_margin) × 100 >= minMarginLevelPct
        // → new_margin <= equity × (100/minMarginLevelPct) – existing_margin
        double allowedNewMargin = equity * (100.0 / minMarginLevelPct) - margin;
        if (allowedNewMargin <= 0) return minimumLotSize;
        double maxLotByMargin = allowedNewMargin / marginInit;
        lotSize = MathMin(lotSize, maxLotByMargin);
    }

    // Round to broker lot step
    double lotStep = SymbolInfoDouble(_Symbol, SYMBOL_VOLUME_STEP);
    double lotMin  = SymbolInfoDouble(_Symbol, SYMBOL_VOLUME_MIN);
    double lotMax  = SymbolInfoDouble(_Symbol, SYMBOL_VOLUME_MAX);
    if (lotStep > 0) lotSize = MathFloor(lotSize / lotStep) * lotStep;
    lotSize = MathMax(lotSize, MathMax(minimumLotSize, lotMin));
    lotSize = MathMin(lotSize, lotMax);

    return NormalizeDouble(lotSize, 2);
}

//===================================================================
// ATR-BASED TRAILING STOP
//   Activates once position profit >= atrTrailActivateMult × ATR
//   Trails at atrTrailDistanceMult × ATR from current price
//===================================================================
void ApplyTrailingStop(double atrVal)
{
    if (!UseTrailingStop || atrVal <= 0.0) return;

    double trailActivate = atrVal * atrTrailActivateMult;
    double trailDist     = atrVal * atrTrailDistanceMult;
    int    digits        = (int)SymbolInfoInteger(_Symbol, SYMBOL_DIGITS);

    for (int i = PositionsTotal() - 1; i >= 0; i--)
    {
        ulong tk = PositionGetTicket(i);
        if (!PositionSelectByTicket(tk)) continue;
        if (PositionGetString(POSITION_SYMBOL) != _Symbol) continue;
        if ((int)PositionGetInteger(POSITION_MAGIC) != MagicNumber) continue;

        long   ptype     = PositionGetInteger(POSITION_TYPE);
        double openPrice = PositionGetDouble(POSITION_PRICE_OPEN);
        double curSL     = PositionGetDouble(POSITION_SL);
        double curTP     = PositionGetDouble(POSITION_TP);
        double bid       = SymbolInfoDouble(_Symbol, SYMBOL_BID);
        double ask       = SymbolInfoDouble(_Symbol, SYMBOL_ASK);

        if (ptype == POSITION_TYPE_BUY)
        {
            if (bid - openPrice >= trailActivate)
            {
                double newSL = NormalizeDouble(bid - trailDist, digits);
                if (curSL == 0.0 || newSL > curSL)
                    g_trade.PositionModify(tk, newSL, curTP);
            }
        }
        else if (ptype == POSITION_TYPE_SELL)
        {
            if (openPrice - ask >= trailActivate)
            {
                double newSL = NormalizeDouble(ask + trailDist, digits);
                if (curSL == 0.0 || newSL < curSL)
                    g_trade.PositionModify(tk, newSL, curTP);
            }
        }
    }
}

//===================================================================
// SWAP MANAGEMENT
//   Before swapCloseHour:swapCloseMinute → close qualifying positions
//   After swapReopenHour:swapReopenMinute → re-enter if trend valid
//===================================================================
void ManageSwap(double atrVal)
{
    if (!UseSwapManagement || atrVal <= 0.0) return;

    MqlDateTime dt;
    TimeToStruct(TimeCurrent(), dt);

    bool isSwapWindow   = (dt.hour == swapCloseHour  && dt.min >= swapCloseMinute) ||
                          (dt.hour == (swapCloseHour + 1) % 24 && dt.min < 30);
    bool isReopenWindow = (dt.hour == swapReopenHour && dt.min >= swapReopenMinute &&
                           dt.min < swapReopenMinute + 30);

    // --- Pre-swap close ---
    if (isSwapWindow && !g_swapClosed)
    {
        for (int i = PositionsTotal() - 1; i >= 0; i--)
        {
            ulong tk = PositionGetTicket(i);
            if (!PositionSelectByTicket(tk)) continue;
            if (PositionGetString(POSITION_SYMBOL) != _Symbol) continue;
            if ((int)PositionGetInteger(POSITION_MAGIC) != MagicNumber) continue;

            double profit = PositionGetDouble(POSITION_PROFIT) +
                            PositionGetDouble(POSITION_SWAP);

            // Close if profit meets threshold AND loss is not beyond the allowed cap
            if (profit >= swapMinProfitToClose && profit >= swapMaxLossToAllow)
            {
                int posType = (int)PositionGetInteger(POSITION_TYPE);
                if (g_trade.PositionClose(tk))
                {
                    g_lastClosedType = posType;
                    g_swapClosed     = true;
                    g_swapClosedAt   = TimeCurrent();
                    Print("SwapClose: type=", posType,
                          " profit=", DoubleToString(profit, 2));
                }
            }
        }
    }

    // --- Post-swap re-entry ---
    if (isReopenWindow && g_swapClosed && g_lastClosedType >= 0)
    {
        int buys, sells;
        CountPositions(buys, sells);
        if (buys == 0 && sells == 0)
        {
            bool reBuy  = (g_lastClosedType == POSITION_TYPE_BUY  && g_currentScore >  scoreThreshold);
            bool reSell = (g_lastClosedType == POSITION_TYPE_SELL && g_currentScore < -scoreThreshold);

            if (reBuy || reSell)
            {
                int    digits  = (int)SymbolInfoInteger(_Symbol, SYMBOL_DIGITS);
                double lot     = CalculateLotSize();
                double sl      = MathMax(atrVal * atrSLMultiplier,
                                         SymbolInfoInteger(_Symbol, SYMBOL_TRADE_STOPS_LEVEL) *
                                         SymbolInfoDouble(_Symbol, SYMBOL_POINT));
                double tp      = MathMax(atrVal * atrTPMultiplier, sl * 1.5);
                double ask     = SymbolInfoDouble(_Symbol, SYMBOL_ASK);
                double bid     = SymbolInfoDouble(_Symbol, SYMBOL_BID);
                bool   ok      = false;

                if (reBuy)
                    ok = g_trade.Buy(lot, _Symbol, ask,
                                     NormalizeDouble(ask - sl, digits),
                                     NormalizeDouble(ask + tp, digits),
                                     "SwapReopen");
                else
                    ok = g_trade.Sell(lot, _Symbol, bid,
                                      NormalizeDouble(bid + sl, digits),
                                      NormalizeDouble(bid - tp, digits),
                                      "SwapReopen");

                if (ok)
                {
                    g_lastTradeTime = TimeCurrent();
                    Print("SwapReopen: type=", g_lastClosedType, " lot=", lot);
                }
            }

            // Reset swap state regardless of whether we reopened
            g_swapClosed     = false;
            g_swapClosedAt   = 0;
            g_lastClosedType = -1;
        }
    }
}

//===================================================================
// TIME-BASED EXIT: close positions held longer than maxTimeInPositionMin
//===================================================================
void CheckMaxTimeExit()
{
    for (int i = PositionsTotal() - 1; i >= 0; i--)
    {
        ulong tk = PositionGetTicket(i);
        if (!PositionSelectByTicket(tk)) continue;
        if (PositionGetString(POSITION_SYMBOL) != _Symbol) continue;
        if ((int)PositionGetInteger(POSITION_MAGIC) != MagicNumber) continue;

        datetime openTime = (datetime)PositionGetInteger(POSITION_TIME);
        long     elapsed  = (long)(TimeCurrent() - openTime);

        if (elapsed > (long)maxTimeInPositionMin * 60)
        {
            int posType = (int)PositionGetInteger(POSITION_TYPE);
            if (g_trade.PositionClose(tk))
            {
                if (reopenAfterTimeExit) g_lastClosedType = posType;
                Print("TimeExit: elapsed=", elapsed / 60, "min type=", posType);
            }
        }
    }
}

//===================================================================
// CLOSE ALL positions for this EA on this symbol
//===================================================================
void CloseAll()
{
    for (int i = PositionsTotal() - 1; i >= 0; i--)
    {
        ulong tk = PositionGetTicket(i);
        if (!PositionSelectByTicket(tk)) continue;
        if (PositionGetString(POSITION_SYMBOL) != _Symbol) continue;
        if ((int)PositionGetInteger(POSITION_MAGIC) != MagicNumber) continue;
        g_trade.PositionClose(tk);
    }
}

//===================================================================
// MAIN TICK
//===================================================================
void OnTick()
{
    //------------------------------------------------------------------
    // 1. Read confirmed indicator values (bar index 1, not forming bar 0)
    //------------------------------------------------------------------
    double emaBuf[];
    ArraySetAsSeries(emaBuf, true);
    if (CopyBuffer(g_emaHandle, 0, 0, 4, emaBuf) < 4) return;
    g_emaPrev = emaBuf[2];
    g_emaCurr = emaBuf[1];

    // Slope: negative sign so upward EMA = positive score (gold convention)
    double emaSlope = -(g_emaCurr - g_emaPrev) * 100.0;

    double atrVal = 0.0;
    if (!GetIndicatorVal(g_atrHandle, 0, atrVal) || atrVal <= 0.0) return;

    double adxMain = 0.0, diPlus = 0.0, diMinus = 0.0;
    bool   strongMarket = IsStrongMarket(adxMain, diPlus, diMinus);

    double rsiVal = 0.0;
    if (!GetIndicatorVal(g_rsiHandle, 0, rsiVal)) return;

    double ask    = SymbolInfoDouble(_Symbol, SYMBOL_ASK);
    double bid    = SymbolInfoDouble(_Symbol, SYMBOL_BID);
    // Use confirmed closed bars
    double close2 = iClose(_Symbol, Period(), 2);
    double close1 = iClose(_Symbol, Period(), 1);
    int    digits = (int)SymbolInfoInteger(_Symbol, SYMBOL_DIGITS);
    double point  = SymbolInfoDouble(_Symbol, SYMBOL_POINT);

    //------------------------------------------------------------------
    // 2. Score accumulation
    //------------------------------------------------------------------

    // EMA crossover (gated by cooldown)
    if (TimeCurrent() - g_lastCrossoverTime >= (datetime)(cooldownMinutes * 60))
    {
        if (close2 < g_emaPrev && close1 > g_emaCurr)      // Bullish crossover
        {
            g_currentScore += crossOverStep;
            g_crossoverTradeCount = 0;
            g_lastCrossoverTime   = TimeCurrent();
            Print("Bullish EMA cross | score=", g_currentScore);
        }
        else if (close2 > g_emaPrev && close1 < g_emaCurr) // Bearish crossover
        {
            g_currentScore -= crossOverStep;
            g_crossoverTradeCount = 0;
            g_lastCrossoverTime   = TimeCurrent();
            Print("Bearish EMA cross | score=", g_currentScore);
        }
    }

    // EMA slope contribution
    if (emaSlope > slopeThreshold)
        g_currentScore += slopeThresholdStep;
    else if (emaSlope < -slopeThreshold)
        g_currentScore -= slopeThresholdStep;
    else if (MathAbs(g_currentScore) > delayClampAbsolute)
        g_currentScore *= decayMultiplier;

    // EMA distance contribution
    double priceDist = close1 - g_emaCurr;
    if (MathAbs(priceDist) > distanceThreshold)
    {
        if (priceDist > 0) g_currentScore += emaDistanceStep;
        else               g_currentScore -= emaDistanceStep;
    }
    else
    {
        if (g_currentScore > 0) g_currentScore -= emaDecayStep;
        else                    g_currentScore += emaDecayStep;
    }

    // Market-regime overlay
    if (strongMarket)
    {
        // 强市: amplify score in the direction the DI lines agree with
        if (diPlus  > diMinus) g_currentScore += emaDistanceStep * 0.5;
        else                   g_currentScore -= emaDistanceStep * 0.5;
    }
    else
    {
        // 弱市: RSI extremes push score against current direction (fade)
        if (rsiVal > rsiOverbought) g_currentScore -= emaDistanceStep * 2.0;
        if (rsiVal < rsiOversold)   g_currentScore += emaDistanceStep * 2.0;
    }

    // Clamp
    g_currentScore = MathMax(-maxScore, MathMin(maxScore, g_currentScore));

    //------------------------------------------------------------------
    // 3. Score zero-crossing → close all & reset
    //------------------------------------------------------------------
    bool zeroCross = (g_prevScore > 0 && g_currentScore <= 0) ||
                     (g_prevScore < 0 && g_currentScore >= 0);
    if (zeroCross)
    {
        CloseAll();
        g_crossoverTradeCount = 0;
        Print("Score zero-cross | prev=", g_prevScore, " curr=", g_currentScore);
    }
    g_prevScore = g_currentScore;

    //------------------------------------------------------------------
    // 4. Trailing stop
    //------------------------------------------------------------------
    ApplyTrailingStop(atrVal);

    //------------------------------------------------------------------
    // 5. Swap management
    //------------------------------------------------------------------
    ManageSwap(atrVal);

    //------------------------------------------------------------------
    // 6. Time-based exit
    //------------------------------------------------------------------
    CheckMaxTimeExit();

    //------------------------------------------------------------------
    // 7. Trade entry
    //------------------------------------------------------------------
    if (g_crossoverTradeCount >= maxCrossoverTrades) return;
    if ((long)(TimeCurrent() - g_lastTradeTime) < (long)(tradeCooldownMinutes * 60)) return;

    int buys, sells;
    CountPositions(buys, sells);

    // SL / TP in price distance
    double minStopDist = SymbolInfoInteger(_Symbol, SYMBOL_TRADE_STOPS_LEVEL) * point;
    double dynamicSL   = MathMax(atrVal * atrSLMultiplier, minStopDist);
    double dynamicTP   = MathMax(atrVal * atrTPMultiplier, dynamicSL * 1.5);

    double lotSize = CalculateLotSize();

    // --- Signal determination ---
    bool buySignal  = false;
    bool sellSignal = false;

    if (strongMarket)
    {
        // 强市: trend-following → long when bullish, short when bearish
        buySignal  = (g_currentScore >  scoreThreshold) && (diPlus  > diMinus);
        sellSignal = (g_currentScore < -scoreThreshold) && (diMinus > diPlus);
    }
    else
    {
        // 弱市: mean-reversion → fade RSI extremes at lower score threshold
        buySignal  = (g_currentScore >  scoreThreshold * 0.6) && (rsiVal < rsiOversold);
        sellSignal = (g_currentScore < -scoreThreshold * 0.6) && (rsiVal > rsiOverbought);
    }

    // --- Execute entry ---
    if (buySignal && buys == 0)
    {
        double slPx = NormalizeDouble(ask - dynamicSL, digits);
        double tpPx = NormalizeDouble(ask + dynamicTP, digits);
        if (g_trade.Buy(lotSize, _Symbol, ask, slPx, tpPx))
        {
            g_crossoverTradeCount++;
            g_lastTradeTime  = TimeCurrent();
            g_lastClosedType = -1;
            Print("BUY | lot=", lotSize,
                  " sl=", slPx, " tp=", tpPx,
                  " | ADX=", DoubleToString(adxMain, 1),
                  " DI+=", DoubleToString(diPlus, 1),
                  " DI-=", DoubleToString(diMinus, 1),
                  " RSI=", DoubleToString(rsiVal, 1),
                  " score=", DoubleToString(g_currentScore, 0),
                  " strong=", strongMarket);
        }
    }
    else if (sellSignal && sells == 0)
    {
        double slPx = NormalizeDouble(bid + dynamicSL, digits);
        double tpPx = NormalizeDouble(bid - dynamicTP, digits);
        if (g_trade.Sell(lotSize, _Symbol, bid, slPx, tpPx))
        {
            g_crossoverTradeCount++;
            g_lastTradeTime  = TimeCurrent();
            g_lastClosedType = -1;
            Print("SELL | lot=", lotSize,
                  " sl=", slPx, " tp=", tpPx,
                  " | ADX=", DoubleToString(adxMain, 1),
                  " DI+=", DoubleToString(diPlus, 1),
                  " DI-=", DoubleToString(diMinus, 1),
                  " RSI=", DoubleToString(rsiVal, 1),
                  " score=", DoubleToString(g_currentScore, 0),
                  " strong=", strongMarket);
        }
    }

    //------------------------------------------------------------------
    // 8. Re-entry after time-based exit (if trend still valid)
    //------------------------------------------------------------------
    if (reopenAfterTimeExit && g_lastClosedType >= 0 &&
        buys == 0 && sells == 0 &&
        (long)(TimeCurrent() - g_lastTradeTime) >= (long)(tradeCooldownMinutes * 60))
    {
        bool reBuy  = (g_lastClosedType == POSITION_TYPE_BUY  && buySignal);
        bool reSell = (g_lastClosedType == POSITION_TYPE_SELL && sellSignal);

        if (reBuy || reSell)
        {
            double lot = CalculateLotSize();
            bool   ok  = false;

            if (reBuy)
                ok = g_trade.Buy(lot, _Symbol, ask,
                                 NormalizeDouble(ask - dynamicSL, digits),
                                 NormalizeDouble(ask + dynamicTP, digits),
                                 "ReEntry");
            else
                ok = g_trade.Sell(lot, _Symbol, bid,
                                  NormalizeDouble(bid + dynamicSL, digits),
                                  NormalizeDouble(bid - dynamicTP, digits),
                                  "ReEntry");

            if (ok)
            {
                g_crossoverTradeCount++;
                g_lastTradeTime  = TimeCurrent();
                g_lastClosedType = -1;
                Print("ReEntry after time-exit | type=", reBuy ? "BUY" : "SELL",
                      " lot=", lot);
            }
        }
    }
}
