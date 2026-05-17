//+------------------------------------------------------------------+
//|                                                    UnitedEA.mq5 |
//|                                  Copyright 2025, MetaQuotes Ltd. |
//|                                             https://www.mql5.com |
//+------------------------------------------------------------------+
#property copyright "Copyright 2025, MetaQuotes Ltd."
#property link      "https://www.mql5.com"
#property version   "4.10"
#property strict
#property description "V4 = V2 baseline + BrokerSymbolMapper auto symbol switching + strategy-type comments."

#include <Trade\Trade.mqh>
#include <Trade\PositionInfo.mqh>
#include <Indicators\Trend.mqh>
#include <Indicators\Volumes.mqh>
#include "MagicNumberHelpers.mqh"
#include "BrokerSymbolMapper.mqh"
#define UNITED_V2_DYNAMIC_LOTS
double               g_DB_LotSize;

// Internal actual symbols (mapped from inputs via BrokerSymbolMapper)
string s_DB_Symbol, s_ES_Symbol, s_RC_Symbol, s_RM_Symbol;
string s_RS_APPL, s_RS_BTCUSD, s_RS_NVDA, s_RS_TSLA, s_RS_XAUUSD;
string s_RRA_EURUSD, s_RRA_AUDUSD, s_SE_Symbol, s_RCO_Symbol;
string s_ST_BTC_Symbol, s_ST_XAU_Symbol, s_ST_GER_Symbol, s_RSS_Symbol;

// Include strategy implementations early so structs are available
#include "Strategies/DarvasBoxStrategy.mqh"
#include "Strategies/EMASlopeDistanceStrategy.mqh"
#include "Strategies/RSICrossOverReversalStrategy.mqh"
#include "Strategies/RSIMidPointHijackStrategy.mqh"
#include "Strategies/RSIScalpingStrategy.mqh"
#include "Strategies/SuperEMAStrategy.mqh"
#include "Strategies/RSIReversalAsianStrategy.mqh"
#include "Strategies/RSIConsolidationStrategy.mqh"
#include "Strategies/SimpleTrendlineStrategy.mqh"
#include "Strategies/RSISecretSauceStrategy.mqh"

//+------------------------------------------------------------------+
//| Global Lot Size Variables (for dynamic lot sizing)               |
//+------------------------------------------------------------------+
double g_ES_LotSize;  // EMA Slope Distance lot size
double g_RC_LotSize;  // RSI CrossOver Reversal lot size
double g_RM_LotSize;  // RSI MidPoint Hijack lot size

double g_Pos_RS_APPL;
double g_Pos_RS_BTCUSD;
double g_Pos_RS_NVDA;
double g_Pos_RS_TSLA;
double g_Pos_RS_XAUUSD;
double g_Pos_RRA_EURUSD;
double g_Pos_RRA_AUDUSD;
double g_Pos_SE;
double g_Pos_RCO;
double g_Pos_ST_BTCUSD;
double g_Pos_ST_XAUUSD;
double g_Pos_ST_GER40;
double g_RSS_LotSize;

input group "=== Global Portfolio Risk Manager (iter9) ==="
input bool   GRM_Enable = false;              // Iter9: disabled by default; blocks new entries only when enabled.
input int    GRM_MaxConcurrentPositions = 0;  // 0 = disabled. Counts known V4 magic numbers only.
input int    GRM_MaxConcurrentSymbols = 0;    // 0 = disabled. Unique symbols with known V4 positions.
input int    GRM_MaxSameSymbolPositions = 0;  // 0 = disabled. Useful for XAUUSD cluster crowding.
input int    GRM_MaxSameSymbolSameSidePositions = 0; // 0 = disabled. Caps same symbol and direction only.
input double GRM_MaxMarginLoadPct = 0.0;      // 0 = disabled. margin / equity * 100.
input double GRM_DailyProfitTargetUSD = 0.0;  // 0 = disabled. Blocks new entries after realized daily profit reaches target.
input double GRM_DailyLossLimitUSD = 0.0;     // 0 = disabled. Blocks new entries after realized daily loss reaches limit.
input double GRM_DailyProfitTargetFreeMarginPct = 0.0; // 0 = disabled. Threshold = free margin * pct / 100.
input double GRM_DailyLossLimitFreeMarginPct = 0.0;    // 0 = disabled. Threshold = free margin * pct / 100.
input double GRM_MonthlyProfitTargetUSD = 0.0; // 0 = disabled. Blocks new entries after realized monthly profit reaches target.
input double GRM_MonthlyLossLimitUSD = 0.0;    // 0 = disabled. Blocks new entries after realized monthly loss reaches limit.
input double GRM_MonthlyProfitTargetFreeMarginPct = 0.0; // 0 = disabled. Threshold = free margin * pct / 100.
input double GRM_MonthlyLossLimitFreeMarginPct = 0.0;    // 0 = disabled. Threshold = free margin * pct / 100.
input bool   GRM_MagicMonthlyLossGateEnable = false;     // Blocks only the current magic after its monthly realized loss reaches limit.
input double GRM_MagicMonthlyLossLimitUSD = 0.0;          // 0 = disabled. Per-magic monthly loss limit.
input double GRM_MagicMonthlyLossLimitFreeMarginPct = 0.0; // 0 = disabled. Per-magic threshold = free margin * pct / 100.
input string GRM_MagicMonthlyGateMagics = "";             // Comma-separated magics. Empty = all known V4 magics.
input string GRM_BlockEntryMonths = "";       // Comma-separated months 1-12. Empty = disabled.
input string GRM_BlockEntrySymbolContains = ""; // Comma-separated symbol fragments. Empty = all symbols in blocked months.
input string GRM_BlockLongSymbolContains = "";  // Comma-separated symbol fragments. Empty = disabled.
input string GRM_BlockShortSymbolContains = ""; // Comma-separated symbol fragments. Empty = disabled.
input bool   GRM_XAUStressRegimeEnable = false;
input string GRM_XAUStressSymbolContains = "XAUUSD";
input ENUM_TIMEFRAMES GRM_XAUStressTimeframe = PERIOD_D1;
input int    GRM_XAUStressATRPeriod = 14;
input double GRM_XAUStressMinATRPct = 1.20;
input int    GRM_XAUStressADXPeriod = 14;
input double GRM_XAUStressMaxADX = 22.0;
input bool   GRM_TrendAlignEnable = false;
input string GRM_TrendAlignSymbolContains = "";
input ENUM_TIMEFRAMES GRM_TrendAlignTimeframe = PERIOD_D1;
input int    GRM_TrendAlignMAPeriod = 200;
input int    GRM_TrendAlignSlopeLookback = 20;
input double GRM_TrendAlignMinSlopePct = 0.30;
input int    GRM_TrendAlignATRPeriod = 14;
input double GRM_TrendAlignMinDistanceATR = 0.0;
input bool   GRM_DebugLogs = false;

bool United_IsKnownV4Magic(const ulong magic)
{
   return magic == 135790      // DarvasBox
       || magic == 12350       // EMA Slope Distance
       || magic == 7           // RSI CrossOver Reversal
       || magic == 1001 || magic == 1002 || magic == 1003
       || magic == 20001 || magic == 123459123 || magic == 20003 || magic == 125421321 || magic == 129102315
       || magic == 30001 || magic == 30002
       || magic == 940001
       || magic == 20250420
       || magic == 26042501 || magic == 26042502 || magic == 26042503
       || magic == 789012;
}

int United_CountKnownPositions(const string symbolFilter = "")
{
   int count = 0;
   for(int i = PositionsTotal() - 1; i >= 0; i--)
   {
      ulong ticket = PositionGetTicket(i);
      if(ticket == 0 || !PositionSelectByTicket(ticket))
         continue;
      if(!United_IsKnownV4Magic((ulong)PositionGetInteger(POSITION_MAGIC)))
         continue;
      if(symbolFilter != "" && PositionGetString(POSITION_SYMBOL) != symbolFilter)
         continue;
      count++;
   }
   return count;
}

int United_CountKnownPositionsBySide(const string symbolFilter, const bool isBuy)
{
   int count = 0;
   ENUM_POSITION_TYPE wantType = (isBuy ? POSITION_TYPE_BUY : POSITION_TYPE_SELL);
   for(int i = PositionsTotal() - 1; i >= 0; i--)
   {
      ulong ticket = PositionGetTicket(i);
      if(ticket == 0 || !PositionSelectByTicket(ticket))
         continue;
      if(!United_IsKnownV4Magic((ulong)PositionGetInteger(POSITION_MAGIC)))
         continue;
      if(PositionGetString(POSITION_SYMBOL) != symbolFilter)
         continue;
      if((ENUM_POSITION_TYPE)PositionGetInteger(POSITION_TYPE) != wantType)
         continue;
      count++;
   }
   return count;
}

int United_CountKnownSymbols()
{
   string symbols[];
   ArrayResize(symbols, 0);
   for(int i = PositionsTotal() - 1; i >= 0; i--)
   {
      ulong ticket = PositionGetTicket(i);
      if(ticket == 0 || !PositionSelectByTicket(ticket))
         continue;
      if(!United_IsKnownV4Magic((ulong)PositionGetInteger(POSITION_MAGIC)))
         continue;
      string sym = PositionGetString(POSITION_SYMBOL);
      bool seen = false;
      for(int j = 0; j < ArraySize(symbols); j++)
      {
         if(symbols[j] == sym)
         {
            seen = true;
            break;
         }
      }
      if(!seen)
      {
         int n = ArraySize(symbols);
         ArrayResize(symbols, n + 1);
         symbols[n] = sym;
      }
   }
   return ArraySize(symbols);
}

datetime United_TodayStart()
{
   MqlDateTime dt;
   TimeToStruct(TimeCurrent(), dt);
   dt.hour = 0;
   dt.min = 0;
   dt.sec = 0;
   return StructToTime(dt);
}

datetime United_MonthStart()
{
   MqlDateTime dt;
   TimeToStruct(TimeCurrent(), dt);
   dt.day = 1;
   dt.hour = 0;
   dt.min = 0;
   dt.sec = 0;
   return StructToTime(dt);
}

double United_KnownRealizedPLSince(const datetime from)
{
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
      ulong magic = (ulong)HistoryDealGetInteger(deal, DEAL_MAGIC);
      if(!United_IsKnownV4Magic(magic))
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

double United_KnownRealizedPLSinceForMagic(const datetime from, const ulong magicFilter)
{
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
      ulong magic = (ulong)HistoryDealGetInteger(deal, DEAL_MAGIC);
      if(magic != magicFilter || !United_IsKnownV4Magic(magic))
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

double United_TodayKnownRealizedPL()
{
   return United_KnownRealizedPLSince(United_TodayStart());
}

double United_ThisMonthKnownRealizedPL()
{
   return United_KnownRealizedPLSince(United_MonthStart());
}

double United_DailyProfitThresholdUSD()
{
   double threshold = GRM_DailyProfitTargetUSD;
   if(GRM_DailyProfitTargetFreeMarginPct > 0.0)
   {
      double freeMargin = AccountInfoDouble(ACCOUNT_MARGIN_FREE);
      threshold = MathMax(threshold, freeMargin * GRM_DailyProfitTargetFreeMarginPct / 100.0);
   }
   return threshold;
}

double United_DailyLossThresholdUSD()
{
   double threshold = GRM_DailyLossLimitUSD;
   if(GRM_DailyLossLimitFreeMarginPct > 0.0)
   {
      double freeMargin = AccountInfoDouble(ACCOUNT_MARGIN_FREE);
      threshold = MathMax(threshold, freeMargin * GRM_DailyLossLimitFreeMarginPct / 100.0);
   }
   return threshold;
}

double United_MonthlyProfitThresholdUSD()
{
   double threshold = GRM_MonthlyProfitTargetUSD;
   if(GRM_MonthlyProfitTargetFreeMarginPct > 0.0)
   {
      double freeMargin = AccountInfoDouble(ACCOUNT_MARGIN_FREE);
      threshold = MathMax(threshold, freeMargin * GRM_MonthlyProfitTargetFreeMarginPct / 100.0);
   }
   return threshold;
}

double United_MonthlyLossThresholdUSD()
{
   double threshold = GRM_MonthlyLossLimitUSD;
   if(GRM_MonthlyLossLimitFreeMarginPct > 0.0)
   {
      double freeMargin = AccountInfoDouble(ACCOUNT_MARGIN_FREE);
      threshold = MathMax(threshold, freeMargin * GRM_MonthlyLossLimitFreeMarginPct / 100.0);
   }
   return threshold;
}

double United_MagicMonthlyLossThresholdUSD()
{
   double threshold = GRM_MagicMonthlyLossLimitUSD;
   if(GRM_MagicMonthlyLossLimitFreeMarginPct > 0.0)
   {
      double freeMargin = AccountInfoDouble(ACCOUNT_MARGIN_FREE);
      threshold = MathMax(threshold, freeMargin * GRM_MagicMonthlyLossLimitFreeMarginPct / 100.0);
   }
   return threshold;
}

bool United_MagicIsInCsv(const ulong magic, const string csv)
{
   if(csv == "")
      return true;
   string parts[];
   int n = StringSplit(csv, ',', parts);
   for(int i = 0; i < n; i++)
   {
      string part = parts[i];
      if(part == "")
         continue;
      if((ulong)StringToInteger(part) == magic)
         return true;
   }
   return false;
}

bool United_MagicMonthlyLossAllowsEntry(const ulong magic)
{
   if(!GRM_Enable || !GRM_MagicMonthlyLossGateEnable)
      return true;
   if(!United_IsKnownV4Magic(magic) || !United_MagicIsInCsv(magic, GRM_MagicMonthlyGateMagics))
      return true;
   double lossThreshold = United_MagicMonthlyLossThresholdUSD();
   if(lossThreshold <= 0.0)
      return true;
   double monthPL = United_KnownRealizedPLSinceForMagic(United_MonthStart(), magic);
   if(monthPL <= -lossThreshold)
   {
      if(GRM_DebugLogs) Print("GRM blocks entry: magic monthly loss limit reached, magic=", magic, ", monthPL=", DoubleToString(monthPL, 2));
      return false;
   }
   return true;
}

bool United_CurrentMonthIsBlocked()
{
   if(GRM_BlockEntryMonths == "")
      return false;
   MqlDateTime dt;
   TimeToStruct(TimeCurrent(), dt);
   string parts[];
   int n = StringSplit(GRM_BlockEntryMonths, ',', parts);
   for(int i = 0; i < n; i++)
   {
      if((int)StringToInteger(parts[i]) == dt.mon)
         return true;
   }
   return false;
}

bool United_SymbolIsBlockedByList(const string symbol)
{
   if(GRM_BlockEntrySymbolContains == "")
      return true;
   string parts[];
   int n = StringSplit(GRM_BlockEntrySymbolContains, ',', parts);
   for(int i = 0; i < n; i++)
   {
      string token = parts[i];
      StringTrimLeft(token);
      StringTrimRight(token);
      if(token != "" && StringFind(symbol, token) >= 0)
         return true;
   }
   return false;
}

bool United_SymbolContainsAny(const string symbol, const string fragments)
{
   if(fragments == "")
      return false;
   string parts[];
   int n = StringSplit(fragments, ',', parts);
   for(int i = 0; i < n; i++)
   {
      string token = parts[i];
      StringTrimLeft(token);
      StringTrimRight(token);
      if(token != "" && StringFind(symbol, token) >= 0)
         return true;
   }
   return false;
}

bool United_XAUStressRegimeBlocksEntry(const string symbol)
{
   if(!GRM_XAUStressRegimeEnable)
      return false;
   if(!United_SymbolContainsAny(symbol, GRM_XAUStressSymbolContains))
      return false;

   int atrHandle = iATR(symbol, GRM_XAUStressTimeframe, GRM_XAUStressATRPeriod);
   int adxHandle = iADX(symbol, GRM_XAUStressTimeframe, GRM_XAUStressADXPeriod);
   if(atrHandle == INVALID_HANDLE || adxHandle == INVALID_HANDLE)
   {
      if(atrHandle != INVALID_HANDLE) IndicatorRelease(atrHandle);
      if(adxHandle != INVALID_HANDLE) IndicatorRelease(adxHandle);
      return false;
   }

   double atr[], adx[];
   ArraySetAsSeries(atr, true);
   ArraySetAsSeries(adx, true);
   bool ok = (CopyBuffer(atrHandle, 0, 1, 1, atr) == 1 && CopyBuffer(adxHandle, 0, 1, 1, adx) == 1);
   IndicatorRelease(atrHandle);
   IndicatorRelease(adxHandle);
   if(!ok)
      return false;

   double close = iClose(symbol, GRM_XAUStressTimeframe, 1);
   if(close <= 0.0)
      return false;
   double atrPct = atr[0] / close * 100.0;
   return (atrPct >= GRM_XAUStressMinATRPct && adx[0] <= GRM_XAUStressMaxADX);
}

bool United_TrendAlignmentBlocksEntry(const string symbol, const bool isBuy)
{
   if(!GRM_TrendAlignEnable)
      return false;
   if(GRM_TrendAlignSymbolContains != "" && !United_SymbolContainsAny(symbol, GRM_TrendAlignSymbolContains))
      return false;
   if(GRM_TrendAlignMAPeriod <= 1 || GRM_TrendAlignSlopeLookback <= 0)
      return false;

   int maHandle = iMA(symbol, GRM_TrendAlignTimeframe, GRM_TrendAlignMAPeriod, 0, MODE_EMA, PRICE_CLOSE);
   if(maHandle == INVALID_HANDLE)
      return false;

   double ma[];
   ArraySetAsSeries(ma, true);
   bool ok = (CopyBuffer(maHandle, 0, 1, GRM_TrendAlignSlopeLookback + 1, ma) == GRM_TrendAlignSlopeLookback + 1);
   IndicatorRelease(maHandle);
   if(!ok)
      return false;

   double close = iClose(symbol, GRM_TrendAlignTimeframe, 1);
   if(close <= 0.0 || ma[0] <= 0.0 || ma[GRM_TrendAlignSlopeLookback] <= 0.0)
      return false;

   if(GRM_TrendAlignMinDistanceATR > 0.0)
   {
      int atrHandle = iATR(symbol, GRM_TrendAlignTimeframe, GRM_TrendAlignATRPeriod);
      if(atrHandle == INVALID_HANDLE)
         return false;
      double atr[];
      ArraySetAsSeries(atr, true);
      bool atrOk = (CopyBuffer(atrHandle, 0, 1, 1, atr) == 1);
      IndicatorRelease(atrHandle);
      if(!atrOk || atr[0] <= 0.0)
         return false;
      if(MathAbs(close - ma[0]) / atr[0] < GRM_TrendAlignMinDistanceATR)
         return false;
   }

   double slopePct = (ma[0] - ma[GRM_TrendAlignSlopeLookback]) / ma[GRM_TrendAlignSlopeLookback] * 100.0;
   if(isBuy)
      return (close < ma[0] && slopePct <= -GRM_TrendAlignMinSlopePct);
   return (close > ma[0] && slopePct >= GRM_TrendAlignMinSlopePct);
}

bool United_GlobalRiskAllowsEntry(const string symbol, const bool isBuy)
{
   if(!GRM_Enable)
      return true;

   if(GRM_MaxConcurrentPositions > 0 && United_CountKnownPositions() >= GRM_MaxConcurrentPositions)
   {
      if(GRM_DebugLogs) Print("GRM blocks entry: max positions reached");
      return false;
   }
   if(GRM_MaxConcurrentSymbols > 0 && !PositionSelect(symbol) && United_CountKnownSymbols() >= GRM_MaxConcurrentSymbols)
   {
      if(GRM_DebugLogs) Print("GRM blocks entry: max symbols reached for ", symbol);
      return false;
   }
   if(GRM_MaxSameSymbolPositions > 0 && United_CountKnownPositions(symbol) >= GRM_MaxSameSymbolPositions)
   {
      if(GRM_DebugLogs) Print("GRM blocks entry: max same-symbol positions reached for ", symbol);
      return false;
   }
   if(GRM_MaxSameSymbolSameSidePositions > 0 && United_CountKnownPositionsBySide(symbol, isBuy) >= GRM_MaxSameSymbolSameSidePositions)
   {
      if(GRM_DebugLogs) Print("GRM blocks entry: max same-symbol same-side positions reached for ", symbol);
      return false;
   }
   if(GRM_MaxMarginLoadPct > 0.0)
   {
      double equity = AccountInfoDouble(ACCOUNT_EQUITY);
      double margin = AccountInfoDouble(ACCOUNT_MARGIN);
      double load = (equity > 0.0 ? margin / equity * 100.0 : 999999.0);
      if(load >= GRM_MaxMarginLoadPct)
      {
         if(GRM_DebugLogs) Print("GRM blocks entry: margin load=", DoubleToString(load, 2));
         return false;
      }
   }
   double profitThreshold = United_DailyProfitThresholdUSD();
   double lossThreshold = United_DailyLossThresholdUSD();
   if(profitThreshold > 0.0 || lossThreshold > 0.0)
   {
      double todayPL = United_TodayKnownRealizedPL();
      if(profitThreshold > 0.0 && todayPL >= profitThreshold)
      {
         if(GRM_DebugLogs) Print("GRM blocks entry: daily profit target reached, todayPL=", DoubleToString(todayPL, 2));
         return false;
      }
      if(lossThreshold > 0.0 && todayPL <= -lossThreshold)
      {
         if(GRM_DebugLogs) Print("GRM blocks entry: daily loss limit reached, todayPL=", DoubleToString(todayPL, 2));
         return false;
      }
   }
   double monthlyProfitThreshold = United_MonthlyProfitThresholdUSD();
   double monthlyLossThreshold = United_MonthlyLossThresholdUSD();
   if(monthlyProfitThreshold > 0.0 || monthlyLossThreshold > 0.0)
   {
      double monthPL = United_ThisMonthKnownRealizedPL();
      if(monthlyProfitThreshold > 0.0 && monthPL >= monthlyProfitThreshold)
      {
         if(GRM_DebugLogs) Print("GRM blocks entry: monthly profit target reached, monthPL=", DoubleToString(monthPL, 2));
         return false;
      }
      if(monthlyLossThreshold > 0.0 && monthPL <= -monthlyLossThreshold)
      {
         if(GRM_DebugLogs) Print("GRM blocks entry: monthly loss limit reached, monthPL=", DoubleToString(monthPL, 2));
         return false;
      }
   }
   if(United_CurrentMonthIsBlocked() && United_SymbolIsBlockedByList(symbol))
   {
      if(GRM_DebugLogs) Print("GRM blocks entry: month/symbol gate for ", symbol);
      return false;
   }
   if(isBuy && United_SymbolContainsAny(symbol, GRM_BlockLongSymbolContains))
   {
      if(GRM_DebugLogs) Print("GRM blocks entry: long-side symbol gate for ", symbol);
      return false;
   }
   if(!isBuy && United_SymbolContainsAny(symbol, GRM_BlockShortSymbolContains))
   {
      if(GRM_DebugLogs) Print("GRM blocks entry: short-side symbol gate for ", symbol);
      return false;
   }
   if(United_XAUStressRegimeBlocksEntry(symbol))
   {
      if(GRM_DebugLogs) Print("GRM blocks entry: XAU stress regime for ", symbol);
      return false;
   }
   if(United_TrendAlignmentBlocksEntry(symbol, isBuy))
   {
      if(GRM_DebugLogs) Print("GRM blocks entry: trend-alignment regime for ", symbol);
      return false;
   }
   return true;
}

bool United_MayOpenNewEntry(const string symbol, const ulong magic, const bool isBuy)
{
   if(PositionExistsByMagic(symbol, magic))
      return false;
   if(!United_MagicMonthlyLossAllowsEntry(magic))
      return false;
   if(!United_GlobalRiskAllowsEntry(symbol, isBuy))
      return false;
   return true;
}

//+------------------------------------------------------------------+
//| Strategy Enable/Disable Switches                                 |
//+------------------------------------------------------------------+
input group "=== Strategy Enable/Disable ==="
input bool EnableDarvasBox = true;
input bool EnableEMASlopeDistance = true;
input bool EnableRSICrossOverReversal = true;
input bool EnableRSIMidPointHijack = true;
input bool EnableRSIScalpingAPPL = true;
input bool EnableRSIScalpingBTCUSD = true;
input bool EnableRSIScalpingNVDA = true;
input bool EnableRSIScalpingTSLA = true;
input bool EnableRSIScalpingXAUUSD = true;
input bool EnableSuperEMA = true;
input bool EnableRSIConsolidation = true;
input bool EnableRSIReversalAsianEURUSD = true;
input bool EnableRSIReversalAsianAUDUSD = true;
input bool EnableSimpleTrendlineBTCUSD = true;
input bool EnableSimpleTrendlineXAUUSD = true;
input bool EnableSimpleTrendlineGER40 = true;
input bool EnableRSISecretSauce = true;

input group "=== Centralized Lot Size (Granular Per Robot) ==="
input double LOT_DB_DarvasBox = 0.05;
input double LOT_ES_EMASlopeDistance = 0.05;
input double LOT_RC_RSICrossOver = 0.06;
input double LOT_RM_RSIMidPointHijack = 0.03;
input double LOT_RS_APPL = 5.0;
input double LOT_RS_BTCUSD = 0.1;
input double LOT_RS_NVDA = 10.0;
input double LOT_RS_TSLA = 15.0;
input double LOT_RS_XAUUSD = 0.1;
input double LOT_RRA_EURUSD = 0.05;
input double LOT_RRA_AUDUSD = 0.08;
input double LOT_SE_SuperEMA = 0.02;
input double LOT_RCO_RSIConsolidation = 0.02;
input double LOT_ST_BTCUSD = 0.07;
input double LOT_ST_XAUUSD = 0.01;
input double LOT_ST_GER40 = 0.10;
input double LOT_RSS_SecretSauce = 0.01;

input group "=== Balance-based position sizing ==="
input bool   ORCH_ScaleLotsByBalance = true;
input bool   ORCH_UseEquityInsteadOfBalance = false;
input double ORCH_ReferenceBalance = 10000.0;
input double ORCH_MinBalanceScale = 0.1;
input double ORCH_MaxBalanceScale = 10.0;

//+------------------------------------------------------------------+
//| Strategy 1: DarvasBoxXAUUSD                                      |
//+------------------------------------------------------------------+
input group "=== DarvasBox Strategy ==="
input string DB_Symbol = "XAUUSD";
input int    DB_BoxPeriod = 165;
input double DB_BoxDeviation = 30000;  // Increased to allow larger ranges (was 25140)
input int    DB_VolumeThreshold = 0;  // Set to 0 to disable volume threshold check. Volume data from indicator used instead.
input double DB_StopLoss = 1665;
input double DB_TakeProfit = 3685;
input bool   DB_EnableLogging = false;
input color  DB_BoxColor = (color)16711680;
input int    DB_BoxWidth = 1;
input ENUM_TIMEFRAMES DB_TrendTimeframe = PERIOD_H2;
input int    DB_MA_Period = 125;
input ENUM_MA_METHOD DB_MA_Method = MODE_EMA;
input ENUM_APPLIED_PRICE DB_MA_Price = PRICE_WEIGHTED;
input double DB_TrendThreshold = 4.94;
input int    DB_VolumeMA_Period = 110;
input double DB_VolumeThresholdMultiplier = 1.5;
input bool   DB_UseVolumeSpikeFilter = true;
input bool   DB_UseTrendFilter = true;
input int    DB_MagicNumber = 135790;

//+------------------------------------------------------------------+
//| Strategy 2: EMASlopeDistanceCocktailXAUUSD                     |
//| PEPPERSTONE US: Gold symbol is typically "XAUUSD" or "GOLD"    |
//+------------------------------------------------------------------+
input group "=== EMA Slope Distance Strategy ==="
input string ES_Symbol = "XAUUSD";
input int    ES_EMA_Periode = 46;
input double ES_PreisSchwelle = 600.0;
input double ES_SteigungSchwelle = 80.0;
input int    ES_ÜberwachungTimeout = 800;
input double ES_TrailingStop = 370.0;
input bool   ES_UseTrailingStop = true;
input double ES_TrailingActivationPips = 0.0;
input bool   ES_UseStaleStopLossExit = false;
input int    ES_StaleStopLossSeconds = 33800;
input double ES_LotGröße = 0.03;
input int    ES_MagicNumber = 12350;
input bool   ES_UseSpreadAdjustment = true;
input ENUM_TIMEFRAMES ES_Timeframe = PERIOD_H1;
input bool   ES_UseBarData = true;
input int    ES_MaxTradesPerCrossover = 9;
input int    ES_ProfitCheckBars = 18;
input bool   ES_CloseUnprofitableTrades = true;
input bool   ES_UseWeeklyADXFilter = true;
input int    ES_WeeklyADXPeriod = 15;
input double ES_WeeklyADXMin = 40.0;
input int    ES_WeeklyADXBarShift = 2;
input bool   ES_WeeklyADXUseDirection = true;

//+------------------------------------------------------------------+
//| Strategy 3: RSICrossOverReversalXAUUSD                          |
//| PEPPERSTONE US: Gold symbol is typically "XAUUSD" or "GOLD"    |
//+------------------------------------------------------------------+
input group "=== RSI CrossOver Reversal Strategy ==="
input string RC_Symbol = "XAUUSD";
input int    RC_MagicNumber = 7;
input int    RC_rsiPeriod = 19;
input int    RC_overboughtLevel = 93;
input int    RC_oversoldLevel = 22;
input double RC_entryRSIBuySpread = 0;
input double RC_entryRSISellSpread = 0;
input double RC_lotSize = 0.01;
input int    RC_slippage = 3;
input int    RC_cooldownSeconds = 209;
input ENUM_TIMEFRAMES RC_TimeFrame1 = PERIOD_M1;
input ENUM_TIMEFRAMES RC_TimeFrame2 = PERIOD_M1;
input ENUM_TIMEFRAMES RC_BarTimeFrame = PERIOD_M12;
input int    RC_emaPeriod = 140;
input double RC_emaSlopeThreshold = 105;
input double RC_exitBuyRSI = 86;
input double RC_exitSellRSI = 10;
input double RC_TrailingStop = 295;
input double RC_emaDistanceThreshold = 165;
input bool   RC_UseTrendStrengthFilter = true;
input double RC_SellHardSL_Points = 2000; // V4-iter4: tighter cap on RC SELL (2000 pts = $20 on XAU). 0 = disabled.
input bool   RC_VetoSellAgainstHTF = true; // V4-iter7-D: skip RC SELL entry when HTF (D1 EMA200) shows uptrend (slope>0 AND price>EMA).
input ENUM_TIMEFRAMES RC_HTF_TimeFrame = PERIOD_D1; // V4-iter7-D: timeframe for HTF veto.
input int    RC_HTF_EMAPeriod = 200;       // V4-iter7-D: EMA length on HTF for trend bias.
input int    RC_HTF_SlopeBars  = 5;        // V4-iter7-D: bars to measure HTF EMA slope.
input int    RC_tradingHourOneBegin = 24;
input int    RC_tradingHourOneEnd = 22;
input int    RC_tradingHourTwoBegin = 6;
input int    RC_tradingHourTwoEnd = 19;
input bool   RC_Sunday = false;
input bool   RC_Monday = false;
input bool   RC_Tuesday = true;
input bool   RC_Wednesday = true;
input bool   RC_Thursday = true;
input bool   RC_Friday = false;
input bool   RC_Saturday = false;

//+------------------------------------------------------------------+
//| Strategy 4: RSIMidPointHijackXAUUSD                              |
//| PEPPERSTONE US: Gold symbol is typically "XAUUSD" or "GOLD"    |
//+------------------------------------------------------------------+
input group "=== RSI MidPoint Hijack Strategy ==="
input string RM_Symbol = "XAUUSD";
input ENUM_TIMEFRAMES RM_InpTimeframe = PERIOD_H1;
input double RM_InpLotSize = 0.02;
input int    RM_InpMagicNumberRSIFollow = 1001;
input int    RM_InpMagicNumberRSIReverse = 1002;
input int    RM_InpMagicNumberEMACross = 1003;
input bool   RM_InpEnableRSIFollow = true;
input bool   RM_InpEnableRSIReverse = true;
input bool   RM_InpEnableEMACross = true;
input bool   RM_InpEnableStrategyLock = false;
input double RM_InpLockProfitThreshold = 0.0;
input bool   RM_InpCloseOppositeTrades = false;
input int    RM_InpRSIPeriod = 32;
input int    RM_InpRSIOverbought = 78;
input int    RM_InpRSIOversold = 46;
input int    RM_InpRSIExitLevel = 44;
input int    RM_InpRSIFollowStartHour = 23;
input int    RM_InpRSIFollowEndHour = 8;
input bool   RM_InpRSIFollowCloseOutsideHours = false;
input int    RM_InpRSIReversePeriod = 59;
input int    RM_InpRSIReverseOverbought = 51;
input int    RM_InpRSIReverseOversold = 49;
input int    RM_InpRSIReverseCrossLevel = 53;
input int    RM_InpRSIReverseExitLevel = 48;
input int    RM_InpRSIReverseStartHour = 7;
input int    RM_InpRSIReverseEndHour = 13;
input bool   RM_InpRSIReverseCloseOutsideHours = false;
input int    RM_InpRSIReverseCooldownBars = 15;
input bool   RM_InpRSIReverseCooldownOnLoss = true;
input int    RM_InpEMAPeriod = 120;
input int    RM_InpEMACrossStartHour = 8;
input int    RM_InpEMACrossEndHour = 14;
input bool   RM_InpEMACrossCloseOutsideHours = true;
input bool   RM_InpUseEMADistanceEntry = true;
input double RM_InpEMADistancePips = 160.0;
input int    RM_InpEMADistancePeriod = 26;

//+------------------------------------------------------------------+
//| Strategy 5-10: RSI Scalping Strategies                           |
//| Each RSI Scalping strategy trades on its own symbol:             |
//| - APPL: Apple stock (AAPL)                                       |
//| - BTCUSD: Bitcoin/USD                                            |
//| - NVDA: NVIDIA stock                                              |
//| - TSLA: Tesla stock                                               |
//| - XAUUSD: Gold/USD                                                |
//|                                                                   |
//| PEPPERSTONE US SYMBOL FORMATS:                                    |
//| - Stocks may use: "AAPL.US", "NASDAQ:AAPL", or just "AAPL"      |
//| - To find correct symbols:                                       |
//|   1. Open Market Watch (Ctrl+M)                                   |
//|   2. Right-click > Show All                                       |
//|   3. Search for the stock name                                    |
//|   4. Use the exact symbol name shown                              |
//+------------------------------------------------------------------+
input group "=== RSI Scalping APPL (AAPL) - Pepperstone US ==="
input string RS_APPL_Symbol = "AAPL.NAS";  // Pepperstone / match tester set (also try AAPL.US)
input ENUM_TIMEFRAMES RS_APPL_TimeFrame = PERIOD_M10;
input int    RS_APPL_RSI_Period = 14;
input ENUM_APPLIED_PRICE RS_APPL_RSI_Applied_Price = PRICE_CLOSE;
input double RS_APPL_RSI_Overbought = 80;
input double RS_APPL_RSI_Oversold = 78;
input double RS_APPL_RSI_Target_Buy = 94;
input double RS_APPL_RSI_Target_Sell = 44;
input int    RS_APPL_BarsToWait = 7;
input double RS_APPL_LotSize = 25;
input int    RS_APPL_MagicNumber = 20001;
input int    RS_APPL_Slippage = 3;

input group "=== RSI Scalping BTCUSD ==="
input string RS_BTCUSD_Symbol = "BTCUSD";  // Pepperstone may use: "BTCUSD", "BTC/USD", or "BTCUSD.c"
input ENUM_TIMEFRAMES RS_BTCUSD_TimeFrame = PERIOD_H1;
input int    RS_BTCUSD_RSI_Period = 14;
input ENUM_APPLIED_PRICE RS_BTCUSD_RSI_Applied_Price = PRICE_CLOSE;
input double RS_BTCUSD_RSI_Overbought = 90;
input double RS_BTCUSD_RSI_Oversold = 73;
input double RS_BTCUSD_RSI_Target_Buy = 88;
input double RS_BTCUSD_RSI_Target_Sell = 48;
input int    RS_BTCUSD_BarsToWait = 6;
input double RS_BTCUSD_LotSize = 0.1;
input int    RS_BTCUSD_MagicNumber = 123459123;
input int    RS_BTCUSD_Slippage = 3;

input group "=== RSI Scalping NVDA - Pepperstone US ==="
input string RS_NVDA_Symbol = "NVDA.NAS";  // Pepperstone / match tester set (also try NVDA.US)
input ENUM_TIMEFRAMES RS_NVDA_TimeFrame = PERIOD_M15;
input int    RS_NVDA_RSI_Period = 8;
input ENUM_APPLIED_PRICE RS_NVDA_RSI_Applied_Price = PRICE_CLOSE;
input double RS_NVDA_RSI_Overbought = 36;
input double RS_NVDA_RSI_Oversold = 38;
input double RS_NVDA_RSI_Target_Buy = 90;
input double RS_NVDA_RSI_Target_Sell = 70;
input int    RS_NVDA_BarsToWait = 5;
input double RS_NVDA_LotSize = 50;
input int    RS_NVDA_MagicNumber = 20003;
input int    RS_NVDA_Slippage = 3;

input group "=== RSI Scalping TSLA - Pepperstone US ==="
input string RS_TSLA_Symbol = "TSLA.NAS";  // Pepperstone / match tester set (also try TSLA.US)
input ENUM_TIMEFRAMES RS_TSLA_TimeFrame = PERIOD_H1;
input int    RS_TSLA_RSI_Period = 14;
input ENUM_APPLIED_PRICE RS_TSLA_RSI_Applied_Price = PRICE_CLOSE;
input double RS_TSLA_RSI_Overbought = 54;
input double RS_TSLA_RSI_Oversold = 73;
input double RS_TSLA_RSI_Target_Buy = 87;
input double RS_TSLA_RSI_Target_Sell = 33;
input int    RS_TSLA_BarsToWait = 1;
input double RS_TSLA_LotSize = 50;
input int    RS_TSLA_MagicNumber = 125421321;
input int    RS_TSLA_Slippage = 3;

input group "=== RSI Scalping XAUUSD ==="
input string RS_XAUUSD_Symbol = "XAUUSD";
input ENUM_TIMEFRAMES RS_XAUUSD_TimeFrame = PERIOD_H1;
input int    RS_XAUUSD_RSI_Period = 14;
input ENUM_APPLIED_PRICE RS_XAUUSD_RSI_Applied_Price = PRICE_CLOSE;
input double RS_XAUUSD_RSI_Overbought = 71;
input double RS_XAUUSD_RSI_Oversold = 57;
input double RS_XAUUSD_RSI_Target_Buy = 80;
input double RS_XAUUSD_RSI_Target_Sell = 57;
input int    RS_XAUUSD_BarsToWait = 4;
input double RS_XAUUSD_LotSize = 0.1;
input int    RS_XAUUSD_MagicNumber = 129102315;
input int    RS_XAUUSD_Slippage = 3;

input group "=== RSI Scalping Reversal Escape (XAUUSD only) ==="
input bool   RS_UseReversalEscape = true;
input int    RS_ReversalATRPeriod = 14;
input double RS_ReversalAdverseAtrMult = 5.25;
input int    RS_ReversalSignsRequired = 2;
input double RS_ReversalRsiVelocity = 16.0;
input double RS_ReversalBodyAtrMult = 5.1;

input group "=== RSI Scalping APPL — Trailing (cluster-fuck BTC-style defaults) ==="
input bool   RS_APPL_UseTrailingStop = true;
input double RS_APPL_TrailDistancePoints = 120.0;
input double RS_APPL_TrailActivationPoints = 0.0;

input group "=== RSI Scalping BTCUSD — Trailing ==="
input bool   RS_BTCUSD_UseTrailingStop = true;
input double RS_BTCUSD_TrailDistancePoints = 120.0;
input double RS_BTCUSD_TrailActivationPoints = 0.0;

input group "=== RSI Scalping NVDA — Trailing ==="
input bool   RS_NVDA_UseTrailingStop = true;
input double RS_NVDA_TrailDistancePoints = 375.0;
input double RS_NVDA_TrailActivationPoints = 75.0;

input group "=== RSI Scalping TSLA — Trailing ==="
input bool   RS_TSLA_UseTrailingStop = true;
input double RS_TSLA_TrailDistancePoints = 900.0;
input double RS_TSLA_TrailActivationPoints = 950.0;

input group "=== RSI Scalping XAUUSD — Trailing ==="
input bool   RS_XAUUSD_UseTrailingStop = true;
input double RS_XAUUSD_TrailDistancePoints = 71.0;
input double RS_XAUUSD_TrailActivationPoints = 41.0;

//+------------------------------------------------------------------+
//| Strategy 11-12: RSI Reversal Asian Strategies                    |
//| Each RSI Reversal Asian strategy trades on its own symbol:       |
//| - EURUSD: Euro/USD                                                |
//| - AUDUSD: Australian Dollar/USD                                   |
//+------------------------------------------------------------------+
input group "=== RSI Reversal Asian EURUSD ==="
input string RRA_EURUSD_Symbol = "EURUSD";
input int    RRA_EURUSD_RSIPeriod = 28;
input double RRA_EURUSD_OverboughtLevel = 60;
input double RRA_EURUSD_OversoldLevel = 8;
input int    RRA_EURUSD_TakeProfitPips = 175;
input int    RRA_EURUSD_StopLossPips = 5;
input double RRA_EURUSD_MaxLotSize = 0.1;
input int    RRA_EURUSD_MaxSpread = 1000;
input int    RRA_EURUSD_MaxDuration = 270;
input bool   RRA_EURUSD_UseStopLoss = false;
input bool   RRA_EURUSD_UseTakeProfit = false;
input bool   RRA_EURUSD_UseRSIExit = true;
input double RRA_EURUSD_RSIExitLevel = 55;
input bool   RRA_EURUSD_CloseOutsideSession = false;
input ENUM_TIMEFRAMES RRA_EURUSD_TimeFrame = PERIOD_M15;
input int    RRA_EURUSD_MagicNumber = 30001;
input int    RRA_EURUSD_Slippage = 3;

input group "=== RSI Reversal Asian AUDUSD ==="
input string RRA_AUDUSD_Symbol = "AUDUSD";
input int    RRA_AUDUSD_RSIPeriod = 28;
input double RRA_AUDUSD_OverboughtLevel = 68;
input double RRA_AUDUSD_OversoldLevel = 30;
input int    RRA_AUDUSD_TakeProfitPips = 175;
input int    RRA_AUDUSD_StopLossPips = 5;
input double RRA_AUDUSD_MaxLotSize = 0.2;
input int    RRA_AUDUSD_MaxSpread = 1000;
input int    RRA_AUDUSD_MaxDuration = 340;
input bool   RRA_AUDUSD_UseStopLoss = false;
input bool   RRA_AUDUSD_UseTakeProfit = false;
input bool   RRA_AUDUSD_UseRSIExit = true;
input double RRA_AUDUSD_RSIExitLevel = 48;
input bool   RRA_AUDUSD_CloseOutsideSession = true;
input ENUM_TIMEFRAMES RRA_AUDUSD_TimeFrame = PERIOD_M15;
input int    RRA_AUDUSD_MagicNumber = 30002;
input int    RRA_AUDUSD_Slippage = 3;

input group "=== RSI Reversal Asian HTF Veto (iter8-E2) ==="
input bool             RRA_VetoSellAgainstHTF = true;       // V4-iter8-E2: block RRA SELL when D1 EMA200 trending UP.
input ENUM_TIMEFRAMES  RRA_HTF_TimeFrame      = PERIOD_D1;
input int              RRA_HTF_EMAPeriod      = 200;
input int              RRA_HTF_SlopeBars      = 5;          // require EMA(now) > EMA(N bars ago) AND price > EMA to veto SELL.

input group "=== SuperEMA (EMA + CCI + MACD) ==="
input string              SE_Symbol = "XAUUSD";
input ENUM_TIMEFRAMES     SE_Timeframe = PERIOD_M15;
input double              SE_LotSize = 0.01;
input int                 SE_SlippagePoints = 55;
input int                 SE_MagicNumber = 940001;
input int                 SE_EmaFast = 40;
input int                 SE_EmaMid = 180;
input int                 SE_EmaSlow = 125;
input int                 SE_EmaTrendBars = 3;
input int                 SE_CciPeriod = 17;
input double              SE_CciOverbought = 80.0;
input double              SE_CciOversold = -140.0;
input int                 SE_PullbackCciLookback = 20;
input int                 SE_MacdFast = 14;
input int                 SE_MacdSlow = 38;
input int                 SE_MacdSignal = 9;
input ENUM_SE_ENTRY_STYLE SE_EntryStyle = SE_ENTRY_LAMBERT;
input bool                SE_OneTradeOnly = true;
input bool                SE_UseStructuralSL = false;
input double              SE_SlBufferPoints = 110;
input bool                SE_ExitOnTrendFlip = false;
input bool                SE_ExitOnMacdFlip = false;
input bool                SE_ExitOnCciZeroCross = true;
input int                 SE_MaxHoldingBars = 168;
input bool                SE_ExitBelowMidEma = false;
input bool                SE_DebugLogs = false;

input group "=== RSI Consolidation (ranging / mean-reversion) ==="
input string              RCO_Symbol = "XAUUSD";
input ENUM_TIMEFRAMES     RCO_SignalTF = PERIOD_M15;
input bool                RCO_EntryOnNewBarOnly = true;
input int                 RCO_ADX_Period = 23;
input double              RCO_ADX_Max = 29.0;
input bool                RCO_UseATRRatioFilter = true;
input int                 RCO_ATR_Period = 8;
input int                 RCO_ATR_SMA_Period = 35;
input double              RCO_ATR_Ratio_Max = 1.36;
input bool                RCO_UseFlatEMAFilter = true;
input int                 RCO_EMA_Fast = 13;
input int                 RCO_EMA_Slow = 17;
input double              RCO_EMA_Separation_MaxPct = 0.26;
input int                 RCO_RSI_Period = 8;
input ENUM_APPLIED_PRICE  RCO_RSI_Price = PRICE_OPEN;
input double              RCO_RSI_Oversold = 22.0;
input double              RCO_RSI_Overbought = 63.0;
input bool                RCO_UseRSI_MeanExit = true;
input double              RCO_RSI_Exit_Long = 48.0;
input double              RCO_RSI_Exit_Short = 52.0;
input double              RCO_SL_ATR_Mult = 2.15;
input double              RCO_TP_ATR_Mult = 2.40;
input int                 RCO_MaxBarsInTrade = 54;
input double              RCO_Lots = 0.10;
input ulong               RCO_MagicNumber = 20250420;
input int                 RCO_Slippage = 10;
input int                 RCO_MaxSpreadPoints = 28;

input group "=== SimpleTrendline BTCUSD ==="
input ulong  ST_MaxHoldMagic   = 26042503; // V4-iter5: enforce time-based exit only for this magic (ST_XAU). 0 = disabled / any.
input ulong  ST_MaxHoldMagic2  = 26042502; // V4-iter7-C: also apply MaxHold to ST_DE40. 0 = none.
input int    ST_MaxHoldHours   = 72;       // V4-iter5: close stuck positions after N hours (0 = disabled). XAU ST avg hold ~92k-180k min observed.
input ulong  ST_MinHoldMagic   = 0;        // V4-iter8-H REVERTED: H-4 FAIL all 3 windows; H-6 IS+RECENT hung 45m/5h. 0 = disabled.
input int    ST_MinHoldHours   = 0;        // V4-iter8-H REVERTED: 0 = disabled.
input string              ST_BTC_Symbol = "BTCUSD";
input ENUM_TIMEFRAMES     ST_BTC_SignalTF = PERIOD_H1;
input ENUM_TIMEFRAMES     ST_BTC_HigherTF = PERIOD_H4;
input int                 ST_BTC_MAPeriod = 150;
input ENUM_MA_METHOD      ST_BTC_MAMethod = MODE_SMMA;
input ENUM_APPLIED_PRICE  ST_BTC_AppliedPrice = PRICE_OPEN;
input int                 ST_BTC_HTFBarsToScan = 1200;
input double              ST_BTC_LineTouchTolerance = 170.0;
input double              ST_BTC_BreakBuffer = 90.0;
input ulong               ST_BTC_MagicNumber = 26042501;
input bool                ST_BTC_DrawTrendline = true;

input group "=== SimpleTrendline XAUUSD ==="
input string              ST_XAU_Symbol = "XAUUSD";
input ENUM_TIMEFRAMES     ST_XAU_SignalTF = PERIOD_H1;
input ENUM_TIMEFRAMES     ST_XAU_HigherTF = PERIOD_M10;
input int                 ST_XAU_MAPeriod = 65;
input ENUM_MA_METHOD      ST_XAU_MAMethod = MODE_EMA;
input ENUM_APPLIED_PRICE  ST_XAU_AppliedPrice = PRICE_OPEN;
input int                 ST_XAU_HTFBarsToScan = 500;
input double              ST_XAU_LineTouchTolerance = 220.0;
input double              ST_XAU_BreakBuffer = 110.0;
input ulong               ST_XAU_MagicNumber = 26042503;
input bool                ST_XAU_DrawTrendline = true;

input group "=== SimpleTrendline GER40 ==="
input string              ST_GER_Symbol = "GER40";
input ENUM_TIMEFRAMES     ST_GER_SignalTF = PERIOD_M15;
input ENUM_TIMEFRAMES     ST_GER_HigherTF = PERIOD_M15;
input int                 ST_GER_MAPeriod = 65;
input ENUM_MA_METHOD      ST_GER_MAMethod = MODE_LWMA;
input ENUM_APPLIED_PRICE  ST_GER_AppliedPrice = PRICE_OPEN;
input int                 ST_GER_HTFBarsToScan = 1200;
input double              ST_GER_LineTouchTolerance = 100.0;
input double              ST_GER_BreakBuffer = 80.0;
input ulong               ST_GER_MagicNumber = 26042502;
input bool                ST_GER_DrawTrendline = true;

input group "=== RSI Secret Sauce XAUUSD ==="
input string RSS_Symbol = "XAUUSD";
input int    RSS_MagicNumber = 789012;
input int    RSS_Slippage = 10;
input ENUM_TIMEFRAMES RSS_Timeframe = PERIOD_M30;
input int    RSS_RSIPeriod = 16;
input double RSS_RSIOverbought = 72.5;
input double RSS_RSIOversold = 32.5;
input int    RSS_RSILookback = 60;
input int    RSS_PeakBars = 2;
input double RSS_StopLossATR = 2.75;
input double RSS_TakeProfitATR = 5.0;
input int    RSS_ATRPeriod = 14;
input bool   RSS_UseSwingStopLoss = false;
input int    RSS_SwingLookback = 30;
input int    RSS_MaxPositions = 1;
input int    RSS_MinBarsBetweenTrades = 7;

//+------------------------------------------------------------------+
//| Balance scaling: LOT_* = nominal size at ORCH_ReferenceBalance    |
//+------------------------------------------------------------------+
double United_BalanceScaleFactor()
{
   if(!ORCH_ScaleLotsByBalance || ORCH_ReferenceBalance <= 0.0)
      return 1.0;
   const double money = ORCH_UseEquityInsteadOfBalance
                        ? AccountInfoDouble(ACCOUNT_EQUITY)
                        : AccountInfoDouble(ACCOUNT_BALANCE);
   double raw = money / ORCH_ReferenceBalance;
   if(raw < ORCH_MinBalanceScale)
      raw = ORCH_MinBalanceScale;
   if(raw > ORCH_MaxBalanceScale)
      raw = ORCH_MaxBalanceScale;
   return raw;
}

double United_ScaledLot(const double baseLot)
{
   const double lot = baseLot * United_BalanceScaleFactor();
   return (lot > 0.0 ? lot : 0.0);
}

void United_RefreshScaledLots()
{
   g_DB_LotSize = United_ScaledLot(LOT_DB_DarvasBox);
   g_ES_LotSize = United_ScaledLot(LOT_ES_EMASlopeDistance);
   g_RC_LotSize = United_ScaledLot(LOT_RC_RSICrossOver);
   g_RM_LotSize = United_ScaledLot(LOT_RM_RSIMidPointHijack);
   g_Pos_RS_APPL = United_ScaledLot(LOT_RS_APPL);
   g_Pos_RS_BTCUSD = United_ScaledLot(LOT_RS_BTCUSD);
   g_Pos_RS_NVDA = United_ScaledLot(LOT_RS_NVDA);
   g_Pos_RS_TSLA = United_ScaledLot(LOT_RS_TSLA);
   g_Pos_RS_XAUUSD = United_ScaledLot(LOT_RS_XAUUSD);
   g_Pos_RRA_EURUSD = United_ScaledLot(LOT_RRA_EURUSD);
   g_Pos_RRA_AUDUSD = United_ScaledLot(LOT_RRA_AUDUSD);
   g_Pos_SE = United_ScaledLot(LOT_SE_SuperEMA);
   g_Pos_RCO = United_ScaledLot(LOT_RCO_RSIConsolidation);
   g_Pos_ST_BTCUSD = United_ScaledLot(LOT_ST_BTCUSD);
   g_Pos_ST_XAUUSD = United_ScaledLot(LOT_ST_XAUUSD);
   g_Pos_ST_GER40 = United_ScaledLot(LOT_ST_GER40);
   g_RSS_LotSize = United_ScaledLot(LOT_RSS_SecretSauce);
}

//+------------------------------------------------------------------+
//| Global Variables - DarvasBox                                      |
//+------------------------------------------------------------------+
struct DarvasBoxData {
   string symbol;
   bool isInitialized;
   double boxHigh;
   double boxLow;
   bool boxFormed;
   datetime lastBoxTime;
   string boxName;
   double minStopLevel;
   double point;
   CTrade trade;
   int maHandle;
   int volumeHandle;
   datetime lastBarTime;
};

//+------------------------------------------------------------------+
//| Global Variables - EMA Slope Distance                            |
//+------------------------------------------------------------------+
struct EMASlopeData {
   string symbol;
   bool isInitialized;
   int ema_handle;
   double ema_array[];
   datetime letzte_überwachung_zeit;
   bool überwachung_aktiv;
   bool preis_trigger_aktiv;
   bool steigung_trigger_aktiv;
   int ticket;
   CTrade trade;
   int trades_in_current_crossover;
   bool crossover_detected;
   datetime trade_open_time;
   datetime last_bar_time;
   datetime es_last_sl_adjust_success_time;
};

//+------------------------------------------------------------------+
//| Global Variables - RSI CrossOver Reversal                       |
//+------------------------------------------------------------------+
struct RSICrossOverData {
   string symbol;
   bool isInitialized;
   int rsiHandle;
   int emaHandle;
   double previousRSIDef;
   CTrade trade;
   datetime lastTradeTime;
   datetime bartime;
   bool WeekDays[7];
   datetime lastBarTime;
};

//+------------------------------------------------------------------+
//| Global Variables - RSI MidPoint Hijack                          |
//+------------------------------------------------------------------+
struct RSIMidPointData {
   string symbol;
   bool isInitialized;
   int rsiHandle;
   int rsiReverseHandle;
   int emaHandle;
   bool rsiOverbought;
   bool rsiOversold;
   bool rsiReverseOverbought;
   bool rsiReverseOversold;
   CTrade trade;
   CPositionInfo positionInfo;
   bool emaCrossBuySignal;
   bool emaCrossSellSignal;
   int emaCrossSignalBar;
   datetime lastBarTime;
   datetime rsiReverseLastCloseTime;
   bool rsiReverseInCooldown;
   double lastBarRSI;
   double lastBarRSIReverse;
   double lastBarEMA;
   double lastBarClose;
   double lastBarEMAPrev;
   double lastBarClosePrev;
};

//+------------------------------------------------------------------+
//| Global Strategy Instances                                        |
//+------------------------------------------------------------------+
DarvasBoxData dbData;
EMASlopeData esData;
RSICrossOverData rcData;
RSIMidPointData rmData;
RSIScalpingData rsAPPLData;
RSIScalpingData rsBTCUSDData;
RSIScalpingData rsNVDAData;
RSIScalpingData rsTSLAData;
RSIScalpingData rsXAUUSDData;
SuperEMAData seData;
RSIConsolidationData rcoData;
SimpleTrendlineData stBTCData;
SimpleTrendlineData stXAUData;
SimpleTrendlineData stGERData;
RSISecretSauceOrcData rssData;

//+------------------------------------------------------------------+
//| Global Variables - RSI Reversal Asian                            |
//+------------------------------------------------------------------+
RSIReversalAsianData rraEURUSDData;
RSIReversalAsianData rraAUDUSDData;

//+------------------------------------------------------------------+
//| Expert initialization function                                   |
//+------------------------------------------------------------------+
int OnInit()
{
   int initResult = INIT_SUCCEEDED;

   // --- Dynamic Symbol Mapping (auto-adapt to broker like IC Markets / Pepperstone / MetaQuotes) ---
   s_DB_Symbol     = SymbolMapper.GetTerminalSymbol(DB_Symbol);
   s_ES_Symbol     = SymbolMapper.GetTerminalSymbol(ES_Symbol);
   s_RC_Symbol     = SymbolMapper.GetTerminalSymbol(RC_Symbol);
   s_RM_Symbol     = SymbolMapper.GetTerminalSymbol(RM_Symbol);
   s_RS_APPL       = SymbolMapper.GetTerminalSymbol(RS_APPL_Symbol);
   s_RS_BTCUSD     = SymbolMapper.GetTerminalSymbol(RS_BTCUSD_Symbol);
   s_RS_NVDA       = SymbolMapper.GetTerminalSymbol(RS_NVDA_Symbol);
   s_RS_TSLA       = SymbolMapper.GetTerminalSymbol(RS_TSLA_Symbol);
   s_RS_XAUUSD     = SymbolMapper.GetTerminalSymbol(RS_XAUUSD_Symbol);
   s_RRA_EURUSD    = SymbolMapper.GetTerminalSymbol(RRA_EURUSD_Symbol);
   s_RRA_AUDUSD    = SymbolMapper.GetTerminalSymbol(RRA_AUDUSD_Symbol);
   s_SE_Symbol     = SymbolMapper.GetTerminalSymbol(SE_Symbol);
   s_RCO_Symbol    = SymbolMapper.GetTerminalSymbol(RCO_Symbol);
   s_ST_BTC_Symbol = SymbolMapper.GetTerminalSymbol(ST_BTC_Symbol);
   s_ST_XAU_Symbol = SymbolMapper.GetTerminalSymbol(ST_XAU_Symbol);
   s_ST_GER_Symbol = SymbolMapper.GetTerminalSymbol(ST_GER_Symbol);
   s_RSS_Symbol    = SymbolMapper.GetTerminalSymbol(RSS_Symbol);

   PrintFormat("[V4] Broker: %s | mapped DB=%s ES=%s RC=%s RM=%s", AccountInfoString(ACCOUNT_COMPANY), s_DB_Symbol, s_ES_Symbol, s_RC_Symbol, s_RM_Symbol);
   PrintFormat("[V4] mapped RS_AAPL=%s BTC=%s NVDA=%s TSLA=%s XAU=%s", s_RS_APPL, s_RS_BTCUSD, s_RS_NVDA, s_RS_TSLA, s_RS_XAUUSD);
   PrintFormat("[V4] mapped RRA_EUR=%s RRA_AUD=%s SE=%s RCO=%s RSS=%s", s_RRA_EURUSD, s_RRA_AUDUSD, s_SE_Symbol, s_RCO_Symbol, s_RSS_Symbol);
   PrintFormat("[V4] mapped ST_BTC=%s ST_XAU=%s ST_GER=%s", s_ST_BTC_Symbol, s_ST_XAU_Symbol, s_ST_GER_Symbol);

   United_RefreshScaledLots();

   // Initialize strategies - log warnings but don't fail entire EA if symbol unavailable
   if(EnableDarvasBox) // Trend / Breakout
      if(!InitDarvasBox(s_DB_Symbol))
         Print("Warning: DarvasBox strategy failed to initialize for symbol '", s_DB_Symbol, "'");

   if(EnableEMASlopeDistance) // Trend
      if(!InitEMASlopeDistance(s_ES_Symbol))
         Print("Warning: EMASlopeDistance strategy failed to initialize for symbol '", s_ES_Symbol, "'");

   if(EnableRSICrossOverReversal) // Reversal
      if(!InitRSICrossOverReversal(s_RC_Symbol))
         Print("Warning: RSICrossOverReversal strategy failed to initialize for symbol '", s_RC_Symbol, "'");

   if(EnableRSIMidPointHijack) // Reversal
      if(!InitRSIMidPointHijack(s_RM_Symbol))
         Print("Warning: RSIMidPointHijack strategy failed to initialize for symbol '", s_RM_Symbol, "'");

   // Initialize RSI Scalping strategies - don't fail entire EA if symbol unavailable
   if(EnableRSIScalpingAPPL) // Scalping / Choppy
      InitRSIScalping(rsAPPLData, s_RS_APPL, RS_APPL_TimeFrame, RS_APPL_RSI_Period, RS_APPL_RSI_Applied_Price, RS_APPL_MagicNumber, RS_APPL_Slippage);

   if(EnableRSIScalpingBTCUSD) // Scalping / Choppy
      InitRSIScalping(rsBTCUSDData, s_RS_BTCUSD, RS_BTCUSD_TimeFrame, RS_BTCUSD_RSI_Period, RS_BTCUSD_RSI_Applied_Price, RS_BTCUSD_MagicNumber, RS_BTCUSD_Slippage);

   if(EnableRSIScalpingNVDA) // Scalping / Choppy
      InitRSIScalping(rsNVDAData, s_RS_NVDA, RS_NVDA_TimeFrame, RS_NVDA_RSI_Period, RS_NVDA_RSI_Applied_Price, RS_NVDA_MagicNumber, RS_NVDA_Slippage);

   if(EnableRSIScalpingTSLA) // Scalping / Choppy
      InitRSIScalping(rsTSLAData, s_RS_TSLA, RS_TSLA_TimeFrame, RS_TSLA_RSI_Period, RS_TSLA_RSI_Applied_Price, RS_TSLA_MagicNumber, RS_TSLA_Slippage);

   if(EnableRSIScalpingXAUUSD) // Scalping / Choppy
      InitRSIScalping(rsXAUUSDData, s_RS_XAUUSD, RS_XAUUSD_TimeFrame, RS_XAUUSD_RSI_Period, RS_XAUUSD_RSI_Applied_Price, RS_XAUUSD_MagicNumber, RS_XAUUSD_Slippage);

   if(EnableRSISecretSauce) // Choppy / Reversal
      if(!InitRSISecretSauce(rssData, s_RSS_Symbol))
         Print("Warning: RSI Secret Sauce failed to initialize for symbol '", s_RSS_Symbol, "'");

   if(EnableSuperEMA) // Trend
      if(!InitSuperEMA(seData, s_SE_Symbol, SE_Timeframe, SE_SlippagePoints, SE_MagicNumber,
                       SE_EmaFast, SE_EmaMid, SE_EmaSlow, SE_EmaTrendBars,
                       SE_CciPeriod, SE_CciOverbought, SE_CciOversold, SE_PullbackCciLookback,
                       SE_MacdFast, SE_MacdSlow, SE_MacdSignal,
                       SE_EntryStyle, SE_OneTradeOnly, SE_UseStructuralSL, SE_SlBufferPoints,
                       SE_ExitOnTrendFlip, SE_ExitOnMacdFlip, SE_ExitOnCciZeroCross,
                       SE_MaxHoldingBars, SE_ExitBelowMidEma, SE_DebugLogs))
         Print("Warning: SuperEMA failed to initialize for symbol '", s_SE_Symbol, "'");

   if(EnableRSIConsolidation) // Choppy
      if(!InitRSIConsolidation(rcoData, s_RCO_Symbol, RCO_SignalTF, RCO_EntryOnNewBarOnly,
            RCO_ADX_Period, RCO_ADX_Max, RCO_UseATRRatioFilter, RCO_ATR_Period, RCO_ATR_SMA_Period, RCO_ATR_Ratio_Max,
            RCO_UseFlatEMAFilter, RCO_EMA_Fast, RCO_EMA_Slow, RCO_EMA_Separation_MaxPct,
            RCO_RSI_Period, RCO_RSI_Price, RCO_RSI_Oversold, RCO_RSI_Overbought,
            RCO_UseRSI_MeanExit, RCO_RSI_Exit_Long, RCO_RSI_Exit_Short, RCO_SL_ATR_Mult, RCO_TP_ATR_Mult,
            RCO_MaxBarsInTrade, RCO_MagicNumber, RCO_Slippage, RCO_MaxSpreadPoints))
         Print("Warning: RSIConsolidation failed to initialize for symbol '", s_RCO_Symbol, "'");

   // Initialize RSI Reversal Asian strategies
   if(EnableRSIReversalAsianEURUSD) // Reversal (Asian session)
      if(!InitRSIReversalAsian(rraEURUSDData, s_RRA_EURUSD, RRA_EURUSD_RSIPeriod, RRA_EURUSD_OverboughtLevel, RRA_EURUSD_OversoldLevel,
                               RRA_EURUSD_TakeProfitPips, RRA_EURUSD_StopLossPips, LOT_RRA_EURUSD,
                               RRA_EURUSD_MaxSpread, RRA_EURUSD_MaxDuration, RRA_EURUSD_UseStopLoss,
                               RRA_EURUSD_UseTakeProfit, RRA_EURUSD_UseRSIExit, RRA_EURUSD_RSIExitLevel,
                               RRA_EURUSD_CloseOutsideSession, RRA_EURUSD_TimeFrame, RRA_EURUSD_MagicNumber, RRA_EURUSD_Slippage))
         Print("Warning: RSIReversalAsianEURUSD strategy failed to initialize for symbol '", s_RRA_EURUSD, "'");

   if(EnableRSIReversalAsianAUDUSD) // Reversal (Asian session)
      if(!InitRSIReversalAsian(rraAUDUSDData, s_RRA_AUDUSD, RRA_AUDUSD_RSIPeriod, RRA_AUDUSD_OverboughtLevel, RRA_AUDUSD_OversoldLevel,
                               RRA_AUDUSD_TakeProfitPips, RRA_AUDUSD_StopLossPips, LOT_RRA_AUDUSD,
                               RRA_AUDUSD_MaxSpread, RRA_AUDUSD_MaxDuration, RRA_AUDUSD_UseStopLoss,
                               RRA_AUDUSD_UseTakeProfit, RRA_AUDUSD_UseRSIExit, RRA_AUDUSD_RSIExitLevel,
                               RRA_AUDUSD_CloseOutsideSession, RRA_AUDUSD_TimeFrame, RRA_AUDUSD_MagicNumber, RRA_AUDUSD_Slippage))
         Print("Warning: RSIReversalAsianAUDUSD strategy failed to initialize for symbol '", s_RRA_AUDUSD, "'");

   if(EnableSimpleTrendlineBTCUSD) // Trend
      if(!InitSimpleTrendline(stBTCData, s_ST_BTC_Symbol, ST_BTC_SignalTF, ST_BTC_HigherTF, ST_BTC_MAPeriod,
                              ST_BTC_MAMethod, ST_BTC_AppliedPrice, ST_BTC_HTFBarsToScan,
                              ST_BTC_LineTouchTolerance, ST_BTC_BreakBuffer, ST_BTC_MagicNumber, ST_BTC_DrawTrendline))
         Print("Warning: SimpleTrendlineBTCUSD failed to initialize for symbol '", s_ST_BTC_Symbol, "'");

   if(EnableSimpleTrendlineXAUUSD) // Trend
      if(!InitSimpleTrendline(stXAUData, s_ST_XAU_Symbol, ST_XAU_SignalTF, ST_XAU_HigherTF, ST_XAU_MAPeriod,
                              ST_XAU_MAMethod, ST_XAU_AppliedPrice, ST_XAU_HTFBarsToScan,
                              ST_XAU_LineTouchTolerance, ST_XAU_BreakBuffer, ST_XAU_MagicNumber, ST_XAU_DrawTrendline))
         Print("Warning: SimpleTrendlineXAUUSD failed to initialize for symbol '", s_ST_XAU_Symbol, "'");

   if(EnableSimpleTrendlineGER40) // Trend
      if(!InitSimpleTrendline(stGERData, s_ST_GER_Symbol, ST_GER_SignalTF, ST_GER_HigherTF, ST_GER_MAPeriod,
                              ST_GER_MAMethod, ST_GER_AppliedPrice, ST_GER_HTFBarsToScan,
                              ST_GER_LineTouchTolerance, ST_GER_BreakBuffer, ST_GER_MagicNumber, ST_GER_DrawTrendline))
         Print("Warning: SimpleTrendlineGER40 failed to initialize for symbol '", s_ST_GER_Symbol, "'");
   
   Print("United EA initialized. Active strategies: ", 
         (EnableDarvasBox ? "DarvasBox " : ""),
         (EnableEMASlopeDistance ? "EMASlope " : ""),
         (EnableRSICrossOverReversal ? "RSICrossOver " : ""),
         (EnableRSIMidPointHijack ? "RSIMidPoint " : ""),
         (EnableRSIScalpingAPPL ? "RSIScalpingAPPL " : ""),
         (EnableRSIScalpingBTCUSD ? "RSIScalpingBTCUSD " : ""),
         (EnableRSIScalpingNVDA ? "RSIScalpingNVDA " : ""),
         (EnableRSIScalpingTSLA ? "RSIScalpingTSLA " : ""),
         (EnableRSIScalpingXAUUSD ? "RSIScalpingXAUUSD " : ""),
         (EnableRSISecretSauce ? "RSISecretSauce " : ""),
         (EnableSuperEMA ? "SuperEMA " : ""),
         (EnableRSIConsolidation ? "RSIConsolidation " : ""),
         (EnableRSIReversalAsianEURUSD ? "RSIReversalAsianEURUSD " : ""),
         (EnableRSIReversalAsianAUDUSD ? "RSIReversalAsianAUDUSD " : ""),
         (EnableSimpleTrendlineBTCUSD ? "SimpleTrendlineBTCUSD " : ""),
         (EnableSimpleTrendlineXAUUSD ? "SimpleTrendlineXAUUSD " : ""),
         (EnableSimpleTrendlineGER40 ? "SimpleTrendlineGER40 " : ""));
   
   return initResult;
}

//+------------------------------------------------------------------+
//| Expert deinitialization function                                 |
//+------------------------------------------------------------------+
void OnDeinit(const int reason)
{
   if(EnableDarvasBox)
      DeinitDarvasBox();
   
   if(EnableEMASlopeDistance)
      DeinitEMASlopeDistance();
   
   if(EnableRSICrossOverReversal)
      DeinitRSICrossOverReversal();
   
   if(EnableRSIMidPointHijack)
      DeinitRSIMidPointHijack();
   
   if(EnableRSIScalpingAPPL)
      DeinitRSIScalping(rsAPPLData);
   
   if(EnableRSIScalpingBTCUSD)
      DeinitRSIScalping(rsBTCUSDData);
   
   if(EnableRSIScalpingNVDA)
      DeinitRSIScalping(rsNVDAData);
   
   if(EnableRSIScalpingTSLA)
      DeinitRSIScalping(rsTSLAData);
   
   if(EnableRSIScalpingXAUUSD)
      DeinitRSIScalping(rsXAUUSDData);

   if(EnableRSISecretSauce)
      DeinitRSISecretSauce(rssData);

   if(EnableSuperEMA)
      DeinitSuperEMA(seData);

   if(EnableRSIConsolidation)
      DeinitRSIConsolidation(rcoData);
   
   if(EnableRSIReversalAsianEURUSD)
      DeinitRSIReversalAsian(rraEURUSDData);
   
   if(EnableRSIReversalAsianAUDUSD)
      DeinitRSIReversalAsian(rraAUDUSDData);

   if(EnableSimpleTrendlineBTCUSD)
      DeinitSimpleTrendline(stBTCData);
   if(EnableSimpleTrendlineXAUUSD)
      DeinitSimpleTrendline(stXAUData);
   if(EnableSimpleTrendlineGER40)
      DeinitSimpleTrendline(stGERData);
   
   Print("United EA deinitialized. Reason: ", reason);
}

//+------------------------------------------------------------------+
//| Expert tick function                                             |
//+------------------------------------------------------------------+
void OnTick()
{
   United_RefreshScaledLots();

   if(EnableDarvasBox) // Trend / Breakout
      ProcessDarvasBox(s_DB_Symbol);

   if(EnableEMASlopeDistance) // Trend
      ProcessEMASlopeDistance(s_ES_Symbol);

   if(EnableRSICrossOverReversal) // Reversal
      ProcessRSICrossOverReversal(s_RC_Symbol);

   if(EnableRSIMidPointHijack) // Reversal
      ProcessRSIMidPointHijack(s_RM_Symbol);

   if(EnableRSIScalpingAPPL) // Scalping / Choppy
      ProcessRSIScalping(rsAPPLData, s_RS_APPL, RS_APPL_TimeFrame, RS_APPL_RSI_Period, RS_APPL_RSI_Applied_Price,
                        RS_APPL_RSI_Overbought, RS_APPL_RSI_Oversold, RS_APPL_RSI_Target_Buy, RS_APPL_RSI_Target_Sell,
                        RS_APPL_BarsToWait, g_Pos_RS_APPL, RS_APPL_MagicNumber,
                        false, RS_ReversalATRPeriod, RS_ReversalAdverseAtrMult, RS_ReversalSignsRequired,
                        RS_ReversalRsiVelocity, RS_ReversalBodyAtrMult,
                        RS_APPL_UseTrailingStop, RS_APPL_TrailDistancePoints, RS_APPL_TrailActivationPoints);

   if(EnableRSIScalpingBTCUSD) // Scalping / Choppy
      ProcessRSIScalping(rsBTCUSDData, s_RS_BTCUSD, RS_BTCUSD_TimeFrame, RS_BTCUSD_RSI_Period, RS_BTCUSD_RSI_Applied_Price,
                        RS_BTCUSD_RSI_Overbought, RS_BTCUSD_RSI_Oversold, RS_BTCUSD_RSI_Target_Buy, RS_BTCUSD_RSI_Target_Sell,
                        RS_BTCUSD_BarsToWait, g_Pos_RS_BTCUSD, RS_BTCUSD_MagicNumber,
                        false, RS_ReversalATRPeriod, RS_ReversalAdverseAtrMult, RS_ReversalSignsRequired,
                        RS_ReversalRsiVelocity, RS_ReversalBodyAtrMult,
                        RS_BTCUSD_UseTrailingStop, RS_BTCUSD_TrailDistancePoints, RS_BTCUSD_TrailActivationPoints);

   if(EnableRSIScalpingNVDA) // Scalping / Choppy
      ProcessRSIScalping(rsNVDAData, s_RS_NVDA, RS_NVDA_TimeFrame, RS_NVDA_RSI_Period, RS_NVDA_RSI_Applied_Price,
                        RS_NVDA_RSI_Overbought, RS_NVDA_RSI_Oversold, RS_NVDA_RSI_Target_Buy, RS_NVDA_RSI_Target_Sell,
                        RS_NVDA_BarsToWait, g_Pos_RS_NVDA, RS_NVDA_MagicNumber,
                        false, RS_ReversalATRPeriod, RS_ReversalAdverseAtrMult, RS_ReversalSignsRequired,
                        RS_ReversalRsiVelocity, RS_ReversalBodyAtrMult,
                        RS_NVDA_UseTrailingStop, RS_NVDA_TrailDistancePoints, RS_NVDA_TrailActivationPoints);

   if(EnableRSIScalpingTSLA) // Scalping / Choppy
      ProcessRSIScalping(rsTSLAData, s_RS_TSLA, RS_TSLA_TimeFrame, RS_TSLA_RSI_Period, RS_TSLA_RSI_Applied_Price,
                        RS_TSLA_RSI_Overbought, RS_TSLA_RSI_Oversold, RS_TSLA_RSI_Target_Buy, RS_TSLA_RSI_Target_Sell,
                        RS_TSLA_BarsToWait, g_Pos_RS_TSLA, RS_TSLA_MagicNumber,
                        false, RS_ReversalATRPeriod, RS_ReversalAdverseAtrMult, RS_ReversalSignsRequired,
                        RS_ReversalRsiVelocity, RS_ReversalBodyAtrMult,
                        RS_TSLA_UseTrailingStop, RS_TSLA_TrailDistancePoints, RS_TSLA_TrailActivationPoints);

   if(EnableRSIScalpingXAUUSD) // Scalping / Choppy
      ProcessRSIScalping(rsXAUUSDData, s_RS_XAUUSD, RS_XAUUSD_TimeFrame, RS_XAUUSD_RSI_Period, RS_XAUUSD_RSI_Applied_Price,
                        RS_XAUUSD_RSI_Overbought, RS_XAUUSD_RSI_Oversold, RS_XAUUSD_RSI_Target_Buy, RS_XAUUSD_RSI_Target_Sell,
                        RS_XAUUSD_BarsToWait, g_Pos_RS_XAUUSD, RS_XAUUSD_MagicNumber,
                        RS_UseReversalEscape, RS_ReversalATRPeriod, RS_ReversalAdverseAtrMult, RS_ReversalSignsRequired,
                        RS_ReversalRsiVelocity, RS_ReversalBodyAtrMult,
                        RS_XAUUSD_UseTrailingStop, RS_XAUUSD_TrailDistancePoints, RS_XAUUSD_TrailActivationPoints);

   if(EnableRSISecretSauce) // Choppy / Reversal
      ProcessRSISecretSauce(rssData, g_RSS_LotSize);

   if(EnableRSIReversalAsianEURUSD) // Reversal (Asian session)
      ProcessRSIReversalAsian(rraEURUSDData, g_Pos_RRA_EURUSD);

   if(EnableRSIReversalAsianAUDUSD) // Reversal (Asian session)
      ProcessRSIReversalAsian(rraAUDUSDData, g_Pos_RRA_AUDUSD);

   if(EnableSuperEMA) // Trend
      ProcessSuperEMA(seData, g_Pos_SE);

   if(EnableRSIConsolidation) // Choppy
      ProcessRSIConsolidation(rcoData, g_Pos_RCO);

   if(EnableSimpleTrendlineBTCUSD) // Trend
      ProcessSimpleTrendline(stBTCData, g_Pos_ST_BTCUSD);
   if(EnableSimpleTrendlineXAUUSD) // Trend
      ProcessSimpleTrendline(stXAUData, g_Pos_ST_XAUUSD);
   if(EnableSimpleTrendlineGER40) // Trend
      ProcessSimpleTrendline(stGERData, g_Pos_ST_GER40);
}

//+------------------------------------------------------------------+
