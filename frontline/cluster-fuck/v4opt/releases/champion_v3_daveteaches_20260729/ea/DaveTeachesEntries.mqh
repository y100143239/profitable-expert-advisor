//+------------------------------------------------------------------+
//|                                           DaveTeachesEntries.mqh |
//|              Entry models: retracement and K-line structure       |
//+------------------------------------------------------------------+
#property copyright "Copyright 2026"
#property version   "1.00"
#property strict

#include "DaveTeachesCore.mqh"

//+------------------------------------------------------------------+
//| Entry signal result                                                |
//+------------------------------------------------------------------+
enum ENUM_DT_ENTRY
{
   DT_ENTRY_NONE,
   DT_ENTRY_BUY,
   DT_ENTRY_SELL
};

struct DT_EntrySignal
{
   ENUM_DT_ENTRY signal;
   double entryPrice;
   double stopLoss;
   double takeProfit;
   string reason;
};

//+------------------------------------------------------------------+
//| Retracement entry: after a liquidity sweep into a HTF zone,      |
//| price pulls back to 30%/50%/70% of the prior range.               |
//+------------------------------------------------------------------+
DT_EntrySignal DT_CheckRetracementEntry(const string symbol, const DT_Structure &s,
                                        const double retraceLevel,
                                        const double riskReward,
                                        const double slBufferPoints)
{
   DT_EntrySignal sig;
   ZeroMemory(sig);
   sig.signal = DT_ENTRY_NONE;

   if(!s.valid || s.trend == DT_TREND_RANGE || s.trend == DT_TREND_UNKNOWN)
      return sig;

   double point = SymbolInfoDouble(symbol, SYMBOL_POINT);
   if(point <= 0.0)
      return sig;

   MqlRates m15[];
   ArraySetAsSeries(m15, true);
   if(CopyRates(symbol, PERIOD_M15, 0, 5, m15) < 5)
      return sig;

   double range = s.lastSwingHigh - s.lastSwingLow;
   if(range <= 0.0)
      return sig;

   double buffer = slBufferPoints * point;

   // Buy: trend up, sweep down, price in demand zone, pullback to retrace level
   if(s.trend == DT_TREND_UP && s.liquiditySweepDown && DT_PriceInDemandZone(symbol, s))
   {
      double target = s.lastSwingLow + range * retraceLevel;
      double currentClose = m15[1].close;
      // Price near the retrace level on M15 closed bar
      if(MathAbs(currentClose - target) <= range * 0.10)
      {
         sig.signal = DT_ENTRY_BUY;
         sig.entryPrice = currentClose;
         sig.stopLoss = DT_NormalizePrice(symbol, s.lastSwingLow - buffer);
         sig.takeProfit = DT_NormalizePrice(symbol, sig.entryPrice + (sig.entryPrice - sig.stopLoss) * riskReward);
         sig.reason = "retracement buy @ " + DoubleToString(retraceLevel * 100.0, 0) + "%";
      }
   }

   // Sell: trend down, sweep up, price in supply zone, pullback to retrace level
   if(s.trend == DT_TREND_DOWN && s.liquiditySweepUp && DT_PriceInSupplyZone(symbol, s))
   {
      double target = s.lastSwingHigh - range * retraceLevel;
      double currentClose = m15[1].close;
      if(MathAbs(currentClose - target) <= range * 0.10)
      {
         sig.signal = DT_ENTRY_SELL;
         sig.entryPrice = currentClose;
         sig.stopLoss = DT_NormalizePrice(symbol, s.lastSwingHigh + buffer);
         sig.takeProfit = DT_NormalizePrice(symbol, sig.entryPrice - (sig.stopLoss - sig.entryPrice) * riskReward);
         sig.reason = "retracement sell @ " + DoubleToString(retraceLevel * 100.0, 0) + "%";
      }
   }

   return sig;
}

//+------------------------------------------------------------------+
//| K-line structure entry: sequence of same-color candles then       |
//| reversal candle closing beyond prior candles, wait for retest.    |
//+------------------------------------------------------------------+
DT_EntrySignal DT_CheckKLineStructureEntry(const string symbol, const DT_Structure &s,
                                           const int sequenceBars,
                                           const double riskReward,
                                           const double slBufferPoints)
{
   DT_EntrySignal sig;
   ZeroMemory(sig);
   sig.signal = DT_ENTRY_NONE;

   if(!s.valid || s.trend == DT_TREND_RANGE || s.trend == DT_TREND_UNKNOWN)
      return sig;

   double point = SymbolInfoDouble(symbol, SYMBOL_POINT);
   if(point <= 0.0)
      return sig;

   MqlRates m15[];
   ArraySetAsSeries(m15, true);
   int need = sequenceBars + 3;
   if(CopyRates(symbol, PERIOD_M15, 0, need, m15) < need)
      return sig;

   double buffer = slBufferPoints * point;

   // Buy K-line structure: N bearish candles, then bullish candle that closes above
   // the high of the last bearish candle, then a retest (current bar low near that level).
   bool bearSequence = true;
   for(int i = sequenceBars; i >= 2; i--)
   {
      if(m15[i].close >= m15[i].open)
      { bearSequence = false; break; }
   }
   bool reversalCandle = (m15[1].close > m15[2].high);
   if(bearSequence && reversalCandle && s.trend == DT_TREND_UP && s.liquiditySweepDown)
   {
      double entry = m15[1].close;
      double sl = DT_NormalizePrice(symbol, m15[1].low - buffer);
      sig.signal = DT_ENTRY_BUY;
      sig.entryPrice = entry;
      sig.stopLoss = sl;
      sig.takeProfit = DT_NormalizePrice(symbol, entry + (entry - sl) * riskReward);
      sig.reason = "K-line bullish reversal";
      return sig;
   }

   // Sell K-line structure: N bullish candles, then bearish candle that closes below
   // the low of the last bullish candle.
   bool bullSequence = true;
   for(int i = sequenceBars; i >= 2; i--)
   {
      if(m15[i].close <= m15[i].open)
      { bullSequence = false; break; }
   }
   bool reversalCandleDown = (m15[1].close < m15[2].low);
   if(bullSequence && reversalCandleDown && s.trend == DT_TREND_DOWN && s.liquiditySweepUp)
   {
      double entry = m15[1].close;
      double sl = DT_NormalizePrice(symbol, m15[1].high + buffer);
      sig.signal = DT_ENTRY_SELL;
      sig.entryPrice = entry;
      sig.stopLoss = sl;
      sig.takeProfit = DT_NormalizePrice(symbol, entry - (sl - entry) * riskReward);
      sig.reason = "K-line bearish reversal";
      return sig;
   }

   return sig;
}

//+------------------------------------------------------------------+
//| Aggregate entry check: returns highest-priority signal             |
//+------------------------------------------------------------------+
DT_EntrySignal DT_GetEntrySignal(const string symbol, const DT_Structure &s,
                                 const bool enableRetracement,
                                 const bool enableKLine,
                                 const double retraceLevel,
                                 const int kLineSequenceBars,
                                 const double riskReward,
                                 const double slBufferPoints)
{
   DT_EntrySignal sig;
   ZeroMemory(sig);
   sig.signal = DT_ENTRY_NONE;

   // Retracement entry has priority
   if(enableRetracement)
   {
      sig = DT_CheckRetracementEntry(symbol, s, retraceLevel, riskReward, slBufferPoints);
      if(sig.signal != DT_ENTRY_NONE)
         return sig;
   }

   // K-line structure entry
   if(enableKLine)
   {
      sig = DT_CheckKLineStructureEntry(symbol, s, kLineSequenceBars, riskReward, slBufferPoints);
      if(sig.signal != DT_ENTRY_NONE)
         return sig;
   }

   return sig;
}
