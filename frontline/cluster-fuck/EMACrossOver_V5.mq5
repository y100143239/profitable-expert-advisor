//+------------------------------------------------------------------+
//|                                             EMACrossOver_V5.mq5    |
//|  Reproducible TREND-FOLLOWING (no martingale).                   |
//|  Trade only WITH D1 trend; ride winners; fixed-risk sizing;      |
//|  ATR SL + trailing; dynamic margin cap; equity breaker.          |
//+------------------------------------------------------------------+
#property strict
#include <Trade\Trade.mqh>

// ---- Signal engine (H1 EMA crossover timing) ----
input int    MagicNumber       = 42;
input ENUM_TIMEFRAMES emaTimeFrame = PERIOD_H1;
input int    emaFastPeriod     = 12;       // Fast EMA for entry timing
input int    emaSlowPeriod     = 48;       // Slow EMA for entry timing
input int    tradeCooldownMin  = 60;       // Min minutes between entries

// ---- Trend filter (D1) — 强弱市方向 ----
input bool   UseTrendFilter    = true;
input ENUM_TIMEFRAMES TrendTF  = PERIOD_D1;
input int    TrendMAPeriod     = 100;      // D1 trend EMA
input int    TrendSlopeBars    = 5;        // Slope confirmation window

// ---- Risk / exits ----
input double RiskPercent       = 1.0;      // % equity risked per trade
input int    ATRPeriod         = 14;
input double ATR_SL_Mult       = 2.5;      // SL = ATR * this
input double ATR_TP_Mult       = 6.0;      // TP = ATR * this (let winners run)
input bool   UseTrailing       = true;
input double ATR_Trail_Mult    = 2.0;      // Trail distance = ATR * this
input double BreakevenATR      = 1.5;      // Move SL to BE after this many ATR profit

// ---- Safeguards ----
input bool   UseEquityProtection = true;
input double EquityDDStopPct     = 25.0;
input int    EquityStopCooldownMin = 240;
input bool   UseDynamicMargin    = true;
input double MaxMarginLoadPct    = 25.0;
input double MinMarginLevelPct   = 300.0;
input double MinLot              = 0.01;
input double MaxLot              = 50.0;
input bool   UseSwapManagement   = true;   // Close profitable pos before swap

int    emaFastHandle, emaSlowHandle, trendHandle, atrHandle;
CTrade trade;
datetime lastTradeTime = 0;
datetime lastEquityStop = 0;

int OnInit() {
    emaFastHandle = iMA(Symbol(), emaTimeFrame, emaFastPeriod, 0, MODE_EMA, PRICE_CLOSE);
    emaSlowHandle = iMA(Symbol(), emaTimeFrame, emaSlowPeriod, 0, MODE_EMA, PRICE_CLOSE);
    trendHandle   = iMA(Symbol(), TrendTF, TrendMAPeriod, 0, MODE_EMA, PRICE_CLOSE);
    atrHandle     = iATR(Symbol(), emaTimeFrame, ATRPeriod);
    if (emaFastHandle==INVALID_HANDLE || emaSlowHandle==INVALID_HANDLE ||
        trendHandle==INVALID_HANDLE || atrHandle==INVALID_HANDLE) {
        Print("Indicator init failed"); return INIT_FAILED;
    }
    return INIT_SUCCEEDED;
}

void OnDeinit(const int reason) {
    IndicatorRelease(emaFastHandle);
    IndicatorRelease(emaSlowHandle);
    IndicatorRelease(trendHandle);
    IndicatorRelease(atrHandle);
}

//+------------------------------------------------------------------+
//| Trend state from D1 EMA slope: 1 bull, -1 bear, 0 flat            |
//+------------------------------------------------------------------+
int GetTrend() {
    double tb[];
    if (CopyBuffer(trendHandle, 0, 0, TrendSlopeBars+1, tb) < TrendSlopeBars+1) return 0;
    double close = iClose(Symbol(), TrendTF, 0);
    double now = tb[0], past = tb[TrendSlopeBars];
    if (close > now && now > past) return 1;   // price above rising EMA
    if (close < now && now < past) return -1;  // price below falling EMA
    return 0;
}

double GetATR() {
    double a[];
    if (CopyBuffer(atrHandle, 0, 0, 1, a) < 1) return 0;
    return a[0];
}

bool IsEquityStopHit() {
    if (!UseEquityProtection) return false;
    if (lastEquityStop > 0 && (TimeCurrent() - lastEquityStop < EquityStopCooldownMin*60)) return true;
    double bal = AccountInfoDouble(ACCOUNT_BALANCE);
    double eq  = AccountInfoDouble(ACCOUNT_EQUITY);
    if (bal > 0 && (bal-eq)/bal*100.0 >= EquityDDStopPct) {
        CloseAll(); lastEquityStop = TimeCurrent(); return true;
    }
    return false;
}

//+------------------------------------------------------------------+
//| Risk-based lot, capped by margin budget (25% load / 300% level)  |
//+------------------------------------------------------------------+
double CalcLot(double slPriceDist) {
    double eq = AccountInfoDouble(ACCOUNT_EQUITY);
    double riskMoney = eq * RiskPercent / 100.0;
    double tickVal = SymbolInfoDouble(Symbol(), SYMBOL_TRADE_TICK_VALUE);
    double tickSize = SymbolInfoDouble(Symbol(), SYMBOL_TRADE_TICK_SIZE);
    if (tickSize <= 0 || tickVal <= 0 || slPriceDist <= 0) return MinLot;
    double lossPerLot = (slPriceDist / tickSize) * tickVal;
    double lot = (lossPerLot > 0) ? riskMoney / lossPerLot : MinLot;

    if (UseDynamicMargin) {
        double margin = AccountInfoDouble(ACCOUNT_MARGIN);
        double availByLoad  = eq * (MaxMarginLoadPct/100.0) - margin;
        double availByLevel = eq / (MinMarginLevelPct/100.0) - margin;
        double avail = MathMin(availByLoad, availByLevel);
        if (avail < 0) avail = 0;
        double mreq = 0;
        if (OrderCalcMargin(ORDER_TYPE_BUY, Symbol(), 1.0, SymbolInfoDouble(Symbol(),SYMBOL_ASK), mreq) && mreq > 0) {
            double capLot = avail / mreq;
            if (capLot < lot) lot = capLot;
        }
    }
    double step = SymbolInfoDouble(Symbol(), SYMBOL_VOLUME_STEP);
    if (step > 0) lot = MathFloor(lot/step)*step;
    if (lot < MinLot) lot = MinLot;
    if (lot > MaxLot) lot = MaxLot;
    return NormalizeDouble(lot, 2);
}

void OnTick() {
    if (IsEquityStopHit()) return;
    ManageOpen();

    // one position per symbol/magic
    if (PositionSelect(Symbol()) && PositionGetInteger(POSITION_MAGIC) == MagicNumber) return;
    if (TimeCurrent() - lastTradeTime < tradeCooldownMin*60) return;

    double ef[2], es[2];
    if (CopyBuffer(emaFastHandle,0,0,2,ef) < 2) return;
    if (CopyBuffer(emaSlowHandle,0,0,2,es) < 2) return;
    bool crossUp   = (ef[1] <= es[1] && ef[0] >  es[0]);
    bool crossDown = (ef[1] >= es[1] && ef[0] <  es[0]);

    int trend = UseTrendFilter ? GetTrend() : 0;
    double atr = GetATR();
    if (atr <= 0) return;
    double ask = SymbolInfoDouble(Symbol(), SYMBOL_ASK);
    double bid = SymbolInfoDouble(Symbol(), SYMBOL_BID);
    double sl = atr * ATR_SL_Mult;
    double tp = atr * ATR_TP_Mult;

    // Trade only WITH the trend (强市做多 / 弱市做空)
    if (crossUp && (!UseTrendFilter || trend >= 0)) {
        double lot = CalcLot(sl);
        trade.SetExpertMagicNumber(MagicNumber);
        if (trade.Buy(lot, Symbol(), ask, ask - sl, ask + tp)) lastTradeTime = TimeCurrent();
    } else if (crossDown && (!UseTrendFilter || trend <= 0)) {
        double lot = CalcLot(sl);
        trade.SetExpertMagicNumber(MagicNumber);
        if (trade.Sell(lot, Symbol(), bid, bid + sl, bid - tp)) lastTradeTime = TimeCurrent();
    }
}

//+------------------------------------------------------------------+
//| Manage: breakeven, ATR trailing, swap exit                        |
//+------------------------------------------------------------------+
void ManageOpen() {
    if (!PositionSelect(Symbol())) return;
    if (PositionGetInteger(POSITION_MAGIC) != MagicNumber) return;

    double atr = GetATR();
    if (atr <= 0) return;
    int digits = (int)SymbolInfoInteger(Symbol(), SYMBOL_DIGITS);
    ulong ticket = PositionGetInteger(POSITION_TICKET);
    long type = PositionGetInteger(POSITION_TYPE);
    double open = PositionGetDouble(POSITION_PRICE_OPEN);
    double sl = PositionGetDouble(POSITION_SL);
    double tp = PositionGetDouble(POSITION_TP);
    double bid = SymbolInfoDouble(Symbol(), SYMBOL_BID);
    double ask = SymbolInfoDouble(Symbol(), SYMBOL_ASK);

    // Swap reduction: near server midnight, close if in profit
    if (UseSwapManagement) {
        MqlDateTime dt; TimeCurrent(dt);
        if (dt.hour == 23 && dt.min >= 50 && PositionGetDouble(POSITION_PROFIT) > 0) {
            trade.PositionClose(ticket); return;
        }
    }

    if (type == POSITION_TYPE_BUY) {
        double profit = bid - open;
        double newSL = sl;
        if (profit >= BreakevenATR*atr && sl < open) newSL = open;     // breakeven
        if (UseTrailing && profit >= ATR_Trail_Mult*atr) {
            double trail = bid - ATR_Trail_Mult*atr;
            if (trail > newSL) newSL = trail;
        }
        if (newSL > sl) trade.PositionModify(ticket, NormalizeDouble(newSL,digits), tp);
    } else if (type == POSITION_TYPE_SELL) {
        double profit = open - ask;
        double newSL = sl;
        if (profit >= BreakevenATR*atr && (sl > open || sl == 0)) newSL = open;
        if (UseTrailing && profit >= ATR_Trail_Mult*atr) {
            double trail = ask + ATR_Trail_Mult*atr;
            if (newSL == 0 || trail < newSL) newSL = trail;
        }
        if (newSL != sl && (newSL < sl || sl == 0)) trade.PositionModify(ticket, NormalizeDouble(newSL,digits), tp);
    }
}

void CloseAll() {
    for (int i = PositionsTotal()-1; i >= 0; i--) {
        ulong t = PositionGetTicket(i);
        if (PositionSelectByTicket(t) && PositionGetInteger(POSITION_MAGIC) == MagicNumber)
            trade.PositionClose(t);
    }
}
