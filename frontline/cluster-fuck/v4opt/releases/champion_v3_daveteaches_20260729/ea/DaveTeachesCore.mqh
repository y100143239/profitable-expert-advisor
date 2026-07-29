//+------------------------------------------------------------------+
//|                                             DaveTeachesCore.mqh |
//|               Multi-timeframe market structure engine             |
//|               Based on Dave Teaches price-action methodology      |
//+------------------------------------------------------------------+
#property copyright "Copyright 2026"
#property version   "1.00"
#property strict

#include <MovingAverages.mqh>

//+------------------------------------------------------------------+
//| Market structure state                                             |
//+------------------------------------------------------------------+
enum ENUM_DT_TREND
{
   DT_TREND_UP,      // higher highs + higher lows
   DT_TREND_DOWN,    // lower lows + lower highs
   DT_TREND_RANGE,   // no clear structure
   DT_TREND_UNKNOWN  // data unavailable
};

struct DT_PriceRange
{
   double high;
   double low;
   datetime timeHigh;
   datetime timeLow;
   bool valid;
};

struct DT_Structure
{
   ENUM_DT_TREND trend;
   int hhllCount;              // consecutive HH/LL count
   double lastSwingHigh;
   double lastSwingLow;
   datetime lastSwingHighTime;
   datetime lastSwingLowTime;
   double demandZoneLow;
   double demandZoneHigh;
   double supplyZoneLow;
   double supplyZoneHigh;
   bool liquiditySweepUp;
   bool liquiditySweepDown;
   double ema21;               // M15 21 EMA for trailing stop
   bool valid;
};

//+------------------------------------------------------------------+
//| Helpers                                                            |
//+------------------------------------------------------------------+
double DT_NormalizePrice(const string symbol, const double price)
{
   int digits = (int)SymbolInfoInteger(symbol, SYMBOL_DIGITS);
   double tickSize = SymbolInfoDouble(symbol, SYMBOL_TRADE_TICK_SIZE);
   if(tickSize <= 0.0)
      return NormalizeDouble(price, digits);
   return NormalizeDouble(MathRound(price / tickSize) * tickSize, digits);
}

//+------------------------------------------------------------------+
//| Count higher-highs / higher-lows or lower-lows / lower-highs       |
//| Uses the last N bars of the higher timeframe to determine trend.   |
//+------------------------------------------------------------------+
ENUM_DT_TREND DT_DetectTrend(const string symbol, const ENUM_TIMEFRAMES tf, const int lookback)
{
   MqlRates rates[];
   ArraySetAsSeries(rates, true);
   int copied = CopyRates(symbol, tf, 0, lookback + 2, rates);
   if(copied < lookback + 2)
      return DT_TREND_UNKNOWN;

   int hh = 0, ll = 0, lh = 0, hl = 0;
   double lastHigh = rates[lookback + 1].high;
   double lastLow  = rates[lookback + 1].low;

   for(int i = lookback; i >= 1; i--)
   {
      bool isHH = (rates[i].high > lastHigh);
      bool isLL = (rates[i].low < lastLow);
      bool isHL = (rates[i].low > lastLow);
      bool isLH = (rates[i].high < lastHigh);

      if(isHH && isHL) hh++;
      else if(isLL && isLH) ll++;
      else if(isHH && isLH) lh++;
      else if(isLL && isHL) hl++;

      lastHigh = rates[i].high;
      lastLow  = rates[i].low;
   }

   if(hh >= 4 && hl >= 4)
      return DT_TREND_UP;
   if(ll >= 4 && lh >= 4)
      return DT_TREND_DOWN;
   return DT_TREND_RANGE;
}

//+------------------------------------------------------------------+
//| Detect recent swing high/low using fractal-style local extrema     |
//+------------------------------------------------------------------+
void DT_FindLastSwing(const string symbol, const ENUM_TIMEFRAMES tf, const int bars,
                      double &swingHigh, datetime &swingHighTime,
                      double &swingLow, datetime &swingLowTime)
{
   swingHigh = 0.0;
   swingLow = DBL_MAX;
   swingHighTime = 0;
   swingLowTime = 0;

   MqlRates rates[];
   ArraySetAsSeries(rates, true);
   int copied = CopyRates(symbol, tf, 0, bars + 2, rates);
   if(copied < bars + 2)
      return;

   // Require 2 bars on each side for a fractal (5-bar pattern)
   for(int i = 2; i < copied - 2 && i < bars; i++)
   {
      bool isHigh = (rates[i].high > rates[i-1].high && rates[i].high > rates[i-2].high &&
                     rates[i].high > rates[i+1].high && rates[i].high > rates[i+2].high);
      bool isLow  = (rates[i].low < rates[i-1].low && rates[i].low < rates[i-2].low &&
                     rates[i].low < rates[i+1].low && rates[i].low < rates[i+2].low);

      if(isHigh && rates[i].high > swingHigh)
      {
         swingHigh = rates[i].high;
         swingHighTime = rates[i].time;
      }
      if(isLow && rates[i].low < swingLow)
      {
         swingLow = rates[i].low;
         swingLowTime = rates[i].time;
      }
   }
}

//+------------------------------------------------------------------+
//| Identify supply/demand zone from the most recent structural range  |
//+------------------------------------------------------------------+
void DT_FindSupplyDemandZones(const string symbol, const ENUM_TIMEFRAMES tf, const int lookback,
                              double &demandLow, double &demandHigh,
                              double &supplyLow, double &supplyHigh)
{
   demandLow = demandHigh = supplyLow = supplyHigh = 0.0;

   MqlRates rates[];
   ArraySetAsSeries(rates, true);
   int copied = CopyRates(symbol, tf, 0, lookback, rates);
   if(copied < lookback)
      return;

   double hh = 0.0, ll = DBL_MAX;
   int idxHH = 0, idxLL = 0;
   for(int i = 1; i < copied; i++)
   {
      if(rates[i].high > hh) { hh = rates[i].high; idxHH = i; }
      if(rates[i].low < ll)  { ll = rates[i].low;  idxLL = i; }
   }
   if(hh <= 0.0 || ll == DBL_MAX)
      return;

   // Demand zone = near the low (structural support)
   // Supply zone = near the high (structural resistance)
   double range = hh - ll;
   demandLow  = ll;
   demandHigh = DT_NormalizePrice(symbol, ll + range * 0.30);
   supplyLow  = DT_NormalizePrice(symbol, hh - range * 0.30);
   supplyHigh = hh;
}

//+------------------------------------------------------------------+
//| Liquidity sweep: price breaks the recent swing extreme then       |
//| returns inside the prior range within N bars.                     |
//+------------------------------------------------------------------+
bool DT_DetectLiquiditySweep(const string symbol, const ENUM_TIMEFRAMES tf, const int lookback,
                              bool &sweepUp, bool &sweepDown)
{
   sweepUp = false;
   sweepDown = false;

   double sh, sl;
   datetime sht, slt;
   DT_FindLastSwing(symbol, tf, lookback, sh, sht, sl, slt);
   if(sh <= 0.0 || sl == DBL_MAX)
      return false;

   MqlRates rates[];
   ArraySetAsSeries(rates, true);
   int copied = CopyRates(symbol, tf, 0, lookback, rates);
   if(copied < 3)
      return false;

   // Check if price broke the swing extreme and then closed back inside
   for(int i = 1; i < copied - 1; i++)
   {
      // Up sweep: wick above swing high, close below swing high
      if(rates[i].high > sh && rates[i].close < sh && !sweepUp)
         sweepUp = true;
      // Down sweep: wick below swing low, close above swing low
      if(rates[i].low < sl && rates[i].close > sl && !sweepDown)
         sweepDown = true;
   }
   return (sweepUp || sweepDown);
}

//+------------------------------------------------------------------+
//| Get 21 EMA value on the execution timeframe                       |
//+------------------------------------------------------------------+
double DT_GetEMA21(const string symbol, const ENUM_TIMEFRAMES tf)
{
   int handle = iMA(symbol, tf, 21, 0, MODE_EMA, PRICE_CLOSE);
   if(handle == INVALID_HANDLE)
      return 0.0;
   double ma[];
   ArraySetAsSeries(ma, true);
   if(CopyBuffer(handle, 0, 0, 1, ma) != 1)
   {
      IndicatorRelease(handle);
      return 0.0;
   }
   IndicatorRelease(handle);
   return ma[0];
}

//+------------------------------------------------------------------+
//| Aggregate multi-timeframe structure: D1 -> H4 -> H1 -> M15        |
//+------------------------------------------------------------------+
DT_Structure DT_AnalyzeStructure(const string symbol)
{
   DT_Structure s;
   ZeroMemory(s);
   s.trend = DT_TREND_UNKNOWN;
   s.valid = false;

   ENUM_DT_TREND d1 = DT_DetectTrend(symbol, PERIOD_D1, 30);
   ENUM_DT_TREND h4 = DT_DetectTrend(symbol, PERIOD_H4, 30);
   ENUM_DT_TREND h1 = DT_DetectTrend(symbol, PERIOD_H1, 30);

   // Top-down confirmation: at least D1 and H4 must agree, H1 can refine
   if(d1 == DT_TREND_UNKNOWN || h4 == DT_TREND_UNKNOWN)
      return s;

   if(d1 == h4)
      s.trend = d1;
   else if(h4 == h1 && h1 != DT_TREND_RANGE)
      s.trend = h4;
   else
      s.trend = DT_TREND_RANGE;

   // Find swings on H1 for entry precision
   DT_FindLastSwing(symbol, PERIOD_H1, 50,
                    s.lastSwingHigh, s.lastSwingHighTime,
                    s.lastSwingLow, s.lastSwingLowTime);

   // Find supply/demand zones on H4
   DT_FindSupplyDemandZones(symbol, PERIOD_H4, 30,
                            s.demandZoneLow, s.demandZoneHigh,
                            s.supplyZoneLow, s.supplyZoneHigh);

   // Liquidity sweep on H1
   DT_DetectLiquiditySweep(symbol, PERIOD_H1, 20,
                           s.liquiditySweepUp, s.liquiditySweepDown);

   // M15 21 EMA for trailing stop
   s.ema21 = DT_GetEMA21(symbol, PERIOD_M15);

   s.valid = true;
   return s;
}

//+------------------------------------------------------------------+
//| Is price inside a higher-timeframe zone of interest?              |
//+------------------------------------------------------------------+
bool DT_PriceInDemandZone(const string symbol, const DT_Structure &s)
{
   double bid = SymbolInfoDouble(symbol, SYMBOL_BID);
   if(s.demandZoneLow <= 0.0 || s.demandZoneHigh <= 0.0)
      return false;
   return (bid >= s.demandZoneLow && bid <= s.demandZoneHigh);
}

bool DT_PriceInSupplyZone(const string symbol, const DT_Structure &s)
{
   double bid = SymbolInfoDouble(symbol, SYMBOL_BID);
   if(s.supplyZoneLow <= 0.0 || s.supplyZoneHigh <= 0.0)
      return false;
   return (bid >= s.supplyZoneLow && bid <= s.supplyZoneHigh);
}

//+------------------------------------------------------------------+
//| Count consecutive higher highs/lows (simplified)                  |
//+------------------------------------------------------------------+
int DT_CountHHLL(const string symbol, const ENUM_TIMEFRAMES tf, const int maxBars)
{
   int count = 0;
   MqlRates rates[];
   ArraySetAsSeries(rates, true);
   int copied = CopyRates(symbol, tf, 0, maxBars + 2, rates);
   if(copied < maxBars + 2)
      return 0;

   double prevHigh = rates[maxBars].high;
   double prevLow  = rates[maxBars].low;
   bool expectingHHLL = true;

   for(int i = maxBars - 1; i >= 1; i--)
   {
      bool hh = (rates[i].high > prevHigh);
      bool ll = (rates[i].low < prevLow);
      if(hh && ll)
      {
         count++;
         prevHigh = rates[i].high;
         prevLow  = rates[i].low;
      }
      else
         break;
   }
   return count;
}
