//+------------------------------------------------------------------+
//|                                             DaveTeachesRisk.mqh |
//|     Risk management, position sizing, and session filters         |
//+------------------------------------------------------------------+
#property copyright "Copyright 2026"
#property version   "1.00"
#property strict

//+------------------------------------------------------------------+
//| Convert broker time to NY local time (approximate UTC-5/EDT)      |
//| Returns hour-of-day in NY.                                        |
//+------------------------------------------------------------------+
int DT_NYHour(const datetime t)
{
   MqlDateTime dt;
   TimeToStruct(t, dt);
   // Approximation: broker time is usually UTC+2/3; subtract 7 for NY hour
   // Better: use explicit NY timezone offset. Here we assume NY = UTC-5.
   // Server time offset varies by broker; this is a pragmatic default.
   int nyHour = (dt.hour - 7 + 24) % 24;
   return nyHour;
}

//+------------------------------------------------------------------+
//| Skip the first hour after NY open (09:30 - 10:30 NY time)         |
//+------------------------------------------------------------------+
bool DT_IsNYFirstHour(const datetime t)
{
   int nyHour = DT_NYHour(t);
   return (nyHour == 9);
}

//+------------------------------------------------------------------+
//| Check if we are inside the configured avoid-NY-first-hour window  |
//+------------------------------------------------------------------+
bool DT_ShouldAvoidNYFirstHour(const bool enable, const datetime t)
{
   if(!enable)
      return false;
   return DT_IsNYFirstHour(t);
}

//+------------------------------------------------------------------+
//| Position size from risk % and stop distance                       |
//| Returns lot size, NOT volume in units.                            |
//+------------------------------------------------------------------+
double DT_RiskBasedLotSize(const string symbol, const double riskPct,
                           const double entryPrice, const double stopLossPrice)
{
   if(riskPct <= 0.0)
      return 0.0;

   double account = AccountInfoDouble(ACCOUNT_BALANCE);
   if(account <= 0.0)
      return 0.0;

   double riskAmount = account * riskPct / 100.0;
   double slDistance = MathAbs(entryPrice - stopLossPrice);
   if(slDistance <= 0.0)
      return 0.0;

   double tickSize = SymbolInfoDouble(symbol, SYMBOL_TRADE_TICK_SIZE);
   double tickValue = SymbolInfoDouble(symbol, SYMBOL_TRADE_TICK_VALUE);
   double lotStep = SymbolInfoDouble(symbol, SYMBOL_VOLUME_STEP);
   double minLot = SymbolInfoDouble(symbol, SYMBOL_VOLUME_MIN);
   double maxLot = SymbolInfoDouble(symbol, SYMBOL_VOLUME_MAX);

   if(tickSize <= 0.0 || tickValue <= 0.0 || lotStep <= 0.0)
      return 0.0;

   double lossPerLotPerTick = tickValue / tickSize;
   double ticksAtRisk = slDistance / tickSize;
   double lossPerLot = lossPerLotPerTick * ticksAtRisk;
   if(lossPerLot <= 0.0)
      return 0.0;

   double lots = riskAmount / lossPerLot;
   lots = MathFloor(lots / lotStep) * lotStep;
   lots = MathMax(minLot, MathMin(maxLot, lots));
   return NormalizeDouble(lots, 2);
}

//+------------------------------------------------------------------+
//| Account-stage sizing: increase lots only when equity crosses      |
//| fixed thresholds (e.g. every $1000).                              |
//+------------------------------------------------------------------+
double DT_AccountStageMultiplier(const double stageSizeUSD)
{
   if(stageSizeUSD <= 0.0)
      return 1.0;

   double equity = AccountInfoDouble(ACCOUNT_EQUITY);
   if(equity <= 0.0)
      return 0.0;

   int stages = (int)MathFloor(equity / stageSizeUSD);
   if(stages < 1)
      return 0.0; // below minimum stage -> no trade
   return 1.0;   // fixed unit per stage; caller can multiply by stage count if desired
}

//+------------------------------------------------------------------+
//| Daily loss limit: hard stop for the day                           |
//+------------------------------------------------------------------+
datetime DT_TodayStart()
{
   MqlDateTime dt;
   TimeToStruct(TimeCurrent(), dt);
   dt.hour = 0; dt.min = 0; dt.sec = 0;
   return StructToTime(dt);
}

double DT_TodayRealizedPL()
{
   datetime from = DT_TodayStart();
   datetime to = TimeCurrent();
   if(!HistorySelect(from, to))
      return 0.0;

   double pl = 0.0;
   int total = HistoryDealsTotal();
   for(int i = 0; i < total; i++)
   {
      ulong deal = HistoryDealGetTicket(i);
      if(deal == 0)
         continue;
      ENUM_DEAL_TYPE type = (ENUM_DEAL_TYPE)HistoryDealGetInteger(deal, DEAL_TYPE);
      if(type != DEAL_TYPE_BUY && type != DEAL_TYPE_SELL)
         continue;
      pl += HistoryDealGetDouble(deal, DEAL_PROFIT);
      pl += HistoryDealGetDouble(deal, DEAL_SWAP);
      pl += HistoryDealGetDouble(deal, DEAL_COMMISSION);
   }
   return pl;
}

bool DT_DailyLossLimitHit(const double dailyLossPct)
{
   if(dailyLossPct <= 0.0)
      return false;
   double balance = AccountInfoDouble(ACCOUNT_BALANCE);
   if(balance <= 0.0)
      return false;
   double limit = -balance * dailyLossPct / 100.0;
   return (DT_TodayRealizedPL() <= limit);
}

//+------------------------------------------------------------------+
//| Spread guard                                                       |
//+------------------------------------------------------------------+
bool DT_SpreadTooHigh(const string symbol, const int maxSpreadPoints)
{
   if(maxSpreadPoints <= 0)
      return false;
   long spread = SymbolInfoInteger(symbol, SYMBOL_SPREAD);
   return (spread > maxSpreadPoints);
}
