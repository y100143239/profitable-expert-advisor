//+------------------------------------------------------------------+
//|                                            DaveTeachesStops.mqh |
//|         Trailing stop methods: candle-low, swing-low, 21 EMA      |
//+------------------------------------------------------------------+
#property copyright "Copyright 2026"
#property version   "1.00"
#property strict

#include <Trade\Trade.mqh>
#include "DaveTeachesCore.mqh"

//+------------------------------------------------------------------+
//| Trailing stop mode                                                 |
//+------------------------------------------------------------------+
enum ENUM_DT_TRAIL_MODE
{
   DT_TRAIL_CANDLE,   // trail below each new candle low / above high
   DT_TRAIL_SWING,    // trail below new swing lows / above swing highs
   DT_TRAIL_EMA21,    // 21 EMA break-and-retest method
   DT_TRAIL_DISABLED
};

//+------------------------------------------------------------------+
//| Candle-low trailing stop                                          |
//+------------------------------------------------------------------+
double DT_CandleTrailSL(const string symbol, const ENUM_POSITION_TYPE ptype,
                        const ENUM_TIMEFRAMES tf, const int lookback)
{
   MqlRates rates[];
   ArraySetAsSeries(rates, true);
   if(CopyRates(symbol, tf, 1, lookback + 1, rates) < lookback + 1)
      return 0.0;

   double point = SymbolInfoDouble(symbol, SYMBOL_POINT);
   if(point <= 0.0)
      return 0.0;

   if(ptype == POSITION_TYPE_BUY)
   {
      double lowest = rates[0].low;
      for(int i = 1; i <= lookback; i++)
         lowest = MathMin(lowest, rates[i].low);
      return DT_NormalizePrice(symbol, lowest);
   }
   else
   {
      double highest = rates[0].high;
      for(int i = 1; i <= lookback; i++)
         highest = MathMax(highest, rates[i].high);
      return DT_NormalizePrice(symbol, highest);
   }
}

//+------------------------------------------------------------------+
//| Swing trailing stop: last N-bar fractal extreme                    |
//+------------------------------------------------------------------+
double DT_SwingTrailSL(const string symbol, const ENUM_POSITION_TYPE ptype,
                       const ENUM_TIMEFRAMES tf, const int lookback)
{
   double sh, sl;
   datetime sht, slt;
   DT_FindLastSwing(symbol, tf, lookback, sh, sht, sl, slt);

   if(ptype == POSITION_TYPE_BUY && sl < DBL_MAX)
      return DT_NormalizePrice(symbol, sl);
   if(ptype == POSITION_TYPE_SELL && sh > 0.0)
      return DT_NormalizePrice(symbol, sh);
   return 0.0;
}

//+------------------------------------------------------------------+
//| 21 EMA trailing stop: price breaks EMA, retests, low of the       |
//| break-and-retest becomes the new stop.                             |
//+------------------------------------------------------------------+
double DT_EMA21TrailSL(const string symbol, const ENUM_POSITION_TYPE ptype)
{
   MqlRates rates[];
   ArraySetAsSeries(rates, true);
   if(CopyRates(symbol, PERIOD_M15, 0, 10, rates) < 10)
      return 0.0;

   double ema = DT_GetEMA21(symbol, PERIOD_M15);
   if(ema <= 0.0)
      return 0.0;

   if(ptype == POSITION_TYPE_BUY)
   {
      // Find the most recent bar that closed below EMA then next bar above EMA.
      // The low of the below-EMA bar is the trailing stop level.
      for(int i = 2; i < ArraySize(rates) - 1; i++)
      {
         if(rates[i].close < ema && rates[i-1].close > ema)
            return DT_NormalizePrice(symbol, rates[i].low);
      }
   }
   else // SELL
   {
      for(int i = 2; i < ArraySize(rates) - 1; i++)
      {
         if(rates[i].close > ema && rates[i-1].close < ema)
            return DT_NormalizePrice(symbol, rates[i].high);
      }
   }
   return 0.0;
}

//+------------------------------------------------------------------+
//| Compute proposed trailing stop for a position                      |
//+------------------------------------------------------------------+
double DT_ComputeTrailingStop(const string symbol, const ENUM_POSITION_TYPE ptype,
                              const ENUM_DT_TRAIL_MODE mode,
                              const int candleLookback,
                              const int swingLookback)
{
   switch(mode)
   {
      case DT_TRAIL_CANDLE:
         return DT_CandleTrailSL(symbol, ptype, PERIOD_M15, candleLookback);
      case DT_TRAIL_SWING:
         return DT_SwingTrailSL(symbol, ptype, PERIOD_H1, swingLookback);
      case DT_TRAIL_EMA21:
         return DT_EMA21TrailSL(symbol, ptype);
      default:
         return 0.0;
   }
   return 0.0;
}

//+------------------------------------------------------------------+
//| Apply trailing stop to an open position                            |
//+------------------------------------------------------------------+
bool DT_ApplyTrailingStop(const ulong ticket, const ENUM_DT_TRAIL_MODE mode,
                          const int candleLookback, const int swingLookback,
                          const bool onlyTighten)
{
   if(mode == DT_TRAIL_DISABLED)
      return false;
   if(!PositionSelectByTicket(ticket))
      return false;

   string symbol = PositionGetString(POSITION_SYMBOL);
   ENUM_POSITION_TYPE ptype = (ENUM_POSITION_TYPE)PositionGetInteger(POSITION_TYPE);
   double currentSL = PositionGetDouble(POSITION_SL);
   double currentTP = PositionGetDouble(POSITION_TP);

   double proposed = DT_ComputeTrailingStop(symbol, ptype, mode, candleLookback, swingLookback);
   if(proposed <= 0.0)
      return false;

   double bid = SymbolInfoDouble(symbol, SYMBOL_BID);
   double ask = SymbolInfoDouble(symbol, SYMBOL_ASK);
   if(bid <= 0.0 || ask <= 0.0)
      return false;

   // Validate: never widen stop, never set beyond current price
   if(ptype == POSITION_TYPE_BUY)
   {
      if(proposed >= bid)
         return false;
      if(onlyTighten && currentSL > 0.0 && proposed <= currentSL)
         return false;
   }
   else
   {
      if(proposed <= ask)
         return false;
      if(onlyTighten && currentSL > 0.0 && proposed >= currentSL)
         return false;
   }

   // Minimum stop distance
   long stopLevel = SymbolInfoInteger(symbol, SYMBOL_TRADE_STOPS_LEVEL);
   double point = SymbolInfoDouble(symbol, SYMBOL_POINT);
   double minDist = stopLevel * point;
   if(ptype == POSITION_TYPE_BUY && (bid - proposed) < minDist)
      proposed = DT_NormalizePrice(symbol, bid - minDist);
   if(ptype == POSITION_TYPE_SELL && (proposed - ask) < minDist)
      proposed = DT_NormalizePrice(symbol, ask + minDist);

   CTrade trade;
   return trade.PositionModify(ticket, proposed, currentTP);
}
