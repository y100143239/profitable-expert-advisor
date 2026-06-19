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
string s_RS_MU;
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
#include "Strategies/WilliamsPassivationStrategy.mqh"

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
double g_Pos_RS_MU;
double g_Pos_RRA_EURUSD;
double g_Pos_RRA_AUDUSD;
double g_Pos_SE;
double g_Pos_RCO;
double g_Pos_ST_BTCUSD;
double g_Pos_ST_XAUUSD;
double g_Pos_ST_GER40;
double g_RSS_LotSize;
double g_WP_LotSize;
string s_WP_Symbol;
WilliamsPassivationData wpDataArray[];
string s_WP_Symbols[];
int wp_symbol_count = 0;

input group "=== Global Portfolio Risk Manager (iter9) ==="
// Iter10E9 verified default: enables causal portfolio-level risk controls.
input bool   GRM_Enable = true;
// 0 = disabled. Counts known V4 magic numbers only.
input int    GRM_MaxConcurrentPositions = 0;
// 0 = disabled. Unique symbols with known V4 positions.
input int    GRM_MaxConcurrentSymbols = 0;
// 0 = disabled. Useful for XAUUSD cluster crowding.
input int    GRM_MaxSameSymbolPositions = 0;
// 0 = disabled. Caps same symbol and direction only.
input int    GRM_MaxSameSymbolSameSidePositions = 0;
// 0 = disabled. margin / equity * 100.
input double GRM_MaxMarginLoadPct = 0.0;
// 0 = disabled. Blocks new entries after realized daily profit reaches target.
input double GRM_DailyProfitTargetUSD = 0.0;
// 0 = disabled. Blocks new entries after realized daily loss reaches limit.
input double GRM_DailyLossLimitUSD = 0.0;
// 0 = disabled. Threshold = free margin * pct / 100.
input double GRM_DailyProfitTargetFreeMarginPct = 0.0;
// 0 = disabled. Threshold = free margin * pct / 100.
input double GRM_DailyLossLimitFreeMarginPct = 0.0;
// 0 = disabled. Blocks new entries after realized monthly profit reaches target.
input double GRM_MonthlyProfitTargetUSD = 0.0;
// 0 = disabled. Blocks new entries after realized monthly loss reaches limit.
input double GRM_MonthlyLossLimitUSD = 0.0;
// 0 = disabled. Threshold = free margin * pct / 100.
input double GRM_MonthlyProfitTargetFreeMarginPct = 0.0;
// 0 = disabled. Threshold = free margin * pct / 100.
input double GRM_MonthlyLossLimitFreeMarginPct = 3.0;
// Monthly-loss breaker recovery: 0 = legacy hard lock for the rest of the month;
// >0 = re-arming cooldown (hours). After the limit is hit, entries pause for this
// many hours then resume (within-month recovery), re-arming only if losses deepen
// by another full threshold. Avoids the crude "no trading until next month" lockout.
input double GRM_MonthlyLossCooldownHours = 0.0;
// --- Virtual Recovery Probe (VRP): smart monthly-loss breaker recovery. ---
// When the monthly-loss limit is hit, instead of a blunt month-lock or a fixed
// timed cooldown, switch REAL trading off but keep "shadow" trading: every
// would-be entry is recorded as a VIRTUAL position and resolved against a
// short-horizon ATR take-profit / stop-loss. The EA monitors the virtual win
// rate; once the simulated book shows the market has recovered (win rate >=
// VRP_ResumeWinRate over >= VRP_ProbeTrades closed virtual trades, net non-
// negative), REAL trading resumes (re-arming only if losses deepen another full
// threshold). This recovers trading time on real signal-quality evidence rather
// than a clock. Default OFF (opt-in until validated). Takes precedence over the
// timed cooldown when enabled.
input bool   VRP_Enable = false;
input ENUM_TIMEFRAMES VRP_ATRTimeframe = PERIOD_H1;  // horizon for virtual TP/SL
input int    VRP_ATRPeriod = 14;
input double VRP_VirtualTPATR = 1.0;   // virtual take-profit in ATR
input double VRP_VirtualSLATR = 1.0;   // virtual stop-loss in ATR
input int    VRP_ProbeTrades = 8;      // min closed virtual trades before resume
input double VRP_ResumeWinRate = 0.55; // resume real trading at/above this virtual win rate
// Comma-separated months 1-12. Empty = disabled.
input string GRM_BlockEntryMonths = "";
// Comma-separated symbol fragments. Empty = all symbols in blocked months.
input string GRM_BlockEntrySymbolContains = "";
// Comma-separated symbol fragments. Empty = disabled.
input string GRM_BlockLongSymbolContains = "";
// Comma-separated symbol fragments. Empty = disabled.
input string GRM_BlockShortSymbolContains = "";
input bool   GRM_XAUStressRegimeEnable = true;
input string GRM_XAUStressSymbolContains = "XAUUSD";
input ENUM_TIMEFRAMES GRM_XAUStressTimeframe = PERIOD_D1;
input int    GRM_XAUStressATRPeriod = 14;
input double GRM_XAUStressMinATRPct = 1.00;
input int    GRM_XAUStressADXPeriod = 14;
input double GRM_XAUStressMaxADX = 26.0;
input bool   GRM_TrendAlignEnable = true;
input string GRM_TrendAlignSymbolContains = "";
input ENUM_TIMEFRAMES GRM_TrendAlignTimeframe = PERIOD_D1;
input int    GRM_TrendAlignMAPeriod = 200;
input int    GRM_TrendAlignSlopeLookback = 20;
input double GRM_TrendAlignMinSlopePct = 0.30;
input int    GRM_TrendAlignATRPeriod = 14;
input double GRM_TrendAlignMinDistanceATR = 0.0;
// Empty = apply the regime trend-align filter to ALL strategies; else only to
// these magics (CSV). Use to scope it to trend-followers and exempt mean-
// reversion scalpers that intentionally take quick counter-trend trades.
input string GRM_TrendAlignMagics = "";
// --- Regime Quick-Exit (RQE): timely stop for COUNTER-TREND open positions. ---
// Surgical exit-side discipline (强市短空 / 弱市短多): when a position is held
// against the D1 regime (same MA/slope test as the trend-align entry filter)
// AND its adverse excursion exceeds RQE_AdverseATRMult * ATR, close it early to
// cap runaway losses. With-trend positions are never touched. Default OFF
// (opt-in until validated). Reuses the GRM_TrendAlign* regime parameters.
input bool   RQE_Enable = true;
input string RQE_Magics = "";            // CSV scope; "" = all known V4 magics
input double RQE_AdverseATRMult = 0.25;  // close when underwater >= this * D1 ATR
input bool   GRM_ConsecutiveLossCooldownEnable = false;
input int    GRM_ConsecutiveLossCount = 3;
input int    GRM_ConsecutiveLossLookbackDays = 30;
input int    GRM_ConsecutiveLossCooldownBars = 12;
input ENUM_TIMEFRAMES GRM_ConsecutiveLossCooldownTimeframe = PERIOD_H1;
input string GRM_ConsecutiveLossSymbolContains = "";
input string GRM_ConsecutiveLossMagics = "";
input string GRM_ConsecutiveLossSide = "both";
input bool   GRM_ConsecutiveLossLotThrottleEnable = false;
input double GRM_ConsecutiveLossLotThrottleFactor = 0.50;
input bool   GRM_MonthlyLossLotThrottleEnable = false;
input double GRM_MonthlyLossLotThrottleUSD = 0.0;
input double GRM_MonthlyLossLotThrottleFactor = 0.70;
input string GRM_MonthlyLossLotThrottleSymbolContains = "";
input string GRM_MonthlyLossLotThrottleMagics = "";
input bool   GRM_PortfolioLossCooldownEnable = false;
input int    GRM_PortfolioConsecutiveLossCount = 4;
input int    GRM_PortfolioConsecutiveLossLookbackDays = 30;
input int    GRM_PortfolioLossCooldownBars = 6;
input ENUM_TIMEFRAMES GRM_PortfolioLossCooldownTimeframe = PERIOD_H1;
input bool   GRM_PortfolioConsecutiveLossLotThrottleEnable = true;
input double GRM_PortfolioConsecutiveLossLotThrottleFactor = 0.80;
input bool   GRM_PortfolioDailyLossLotThrottleEnable = false;
input double GRM_PortfolioDailyLossLotThrottleUSD = 0.0;
input double GRM_PortfolioDailyLossLotThrottleFactor = 0.80;
input bool   GRM_PortfolioMonthlyLossLotThrottleEnable = false;
input double GRM_PortfolioMonthlyLossLotThrottleUSD = 0.0;
input double GRM_PortfolioMonthlyLossLotThrottleFactor = 0.80;
input bool   GRM_PortfolioWinRateCooldownEnable = false;
input int    GRM_PortfolioWinRateLookbackTrades = 40;
input int    GRM_PortfolioWinRateLookbackDays = 30;
input int    GRM_PortfolioWinRateMinTrades = 20;
input double GRM_PortfolioWinRateMinPct = 35.0;
input int    GRM_PortfolioWinRateCooldownBars = 6;
input ENUM_TIMEFRAMES GRM_PortfolioWinRateCooldownTimeframe = PERIOD_H1;
input bool   GRM_SymbolWinRateCooldownEnable = false;
input int    GRM_SymbolWinRateLookbackTrades = 30;
input int    GRM_SymbolWinRateLookbackDays = 60;
input int    GRM_SymbolWinRateMinTrades = 10;
input double GRM_SymbolWinRateMinPct = 35.0;
input int    GRM_SymbolWinRateCooldownBars = 24;
input ENUM_TIMEFRAMES GRM_SymbolWinRateCooldownTimeframe = PERIOD_H1;
input bool   GRM_DebugLogs = false;

bool United_IsKnownV4Magic(const ulong magic)
{
   return magic == 135790      // DarvasBox
       || magic == 12350       // EMA Slope Distance
       || magic == 7           // RSI CrossOver Reversal
       || magic == 1001 || magic == 1002 || magic == 1003
       || magic == 20001 || magic == 123459123 || magic == 20003 || magic == 125421321 || magic == 129102315
       || magic == 20004       // RSI Scalping MU.NAS
       || magic == 30001 || magic == 30002
       || magic == 940001
       || magic == 20250420
       || magic == 26042501 || magic == 26042502 || magic == 26042503
       || magic == 789012
       || (magic >= 20260524 && magic <= 20260524 + 15);
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

double United_TodayKnownRealizedPL()
{
   return United_KnownRealizedPLSince(United_TodayStart());
}

double United_ThisMonthKnownRealizedPL()
{
   return United_KnownRealizedPLSince(United_MonthStart());
}

double United_KnownRealizedPLSinceForMagic(const datetime from, const ulong magicFilter)
{
   datetime to = TimeCurrent();
   if(!HistorySelect(from, to))
      return 0.0;

   double pl = 0.0;
   int total = HistoryDealsTotal();
   for(int dealIndex = 0; dealIndex < total; dealIndex++)
   {
      ulong deal = HistoryDealGetTicket(dealIndex);
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

bool United_MagicIsInCsv(const ulong magic, const string csv)
{
   if(csv == "")
      return true;
   string parts[];
   int count = StringSplit(csv, ',', parts);
   for(int partIndex = 0; partIndex < count; partIndex++)
   {
      string token = parts[partIndex];
      StringTrimLeft(token);
      StringTrimRight(token);
      if(token != "" && (ulong)StringToInteger(token) == magic)
         return true;
   }
   return false;
}

bool United_ConsecutiveLossScopeMatches(const string symbol, const ulong magic, const bool isBuy, const bool sideAware)
{
   if(!United_IsKnownV4Magic(magic) || !United_MagicIsInCsv(magic, GRM_ConsecutiveLossMagics))
      return false;
   if(GRM_ConsecutiveLossSymbolContains != "" && !United_SymbolContainsAny(symbol, GRM_ConsecutiveLossSymbolContains))
      return false;
   if(sideAware)
   {
      if(GRM_ConsecutiveLossSide == "buy" && !isBuy)
         return false;
      if(GRM_ConsecutiveLossSide == "sell" && isBuy)
         return false;
   }
   return true;
}

int United_RecentConsecutiveLosses(const string symbol, const ulong magic, const bool isBuy, datetime &lastLossTime, const bool sideAware)
{
   lastLossTime = 0;
   if(GRM_ConsecutiveLossCount <= 0 || !United_ConsecutiveLossScopeMatches(symbol, magic, isBuy, sideAware))
      return 0;

   datetime from = TimeCurrent() - (datetime)MathMax(1, GRM_ConsecutiveLossLookbackDays) * 86400;
   if(!HistorySelect(from, TimeCurrent()))
      return 0;

   int losses = 0;
   int total = HistoryDealsTotal();
   for(int dealIndex = total - 1; dealIndex >= 0; dealIndex--)
   {
      ulong deal = HistoryDealGetTicket(dealIndex);
      if(deal == 0)
         continue;
      if((ulong)HistoryDealGetInteger(deal, DEAL_MAGIC) != magic)
         continue;
      if(HistoryDealGetString(deal, DEAL_SYMBOL) != symbol)
         continue;

      ENUM_DEAL_TYPE type = (ENUM_DEAL_TYPE)HistoryDealGetInteger(deal, DEAL_TYPE);
      if(type != DEAL_TYPE_BUY && type != DEAL_TYPE_SELL)
         continue;
      ENUM_DEAL_ENTRY entry = (ENUM_DEAL_ENTRY)HistoryDealGetInteger(deal, DEAL_ENTRY);
      if(entry != DEAL_ENTRY_OUT && entry != DEAL_ENTRY_INOUT)
         continue;

      bool closedBuy = (type == DEAL_TYPE_SELL);
      if(sideAware && closedBuy != isBuy)
         continue;

      double pl = HistoryDealGetDouble(deal, DEAL_PROFIT)
                + HistoryDealGetDouble(deal, DEAL_SWAP)
                + HistoryDealGetDouble(deal, DEAL_COMMISSION);
      if(pl < 0.0)
      {
         if(lastLossTime == 0)
            lastLossTime = (datetime)HistoryDealGetInteger(deal, DEAL_TIME);
         losses++;
         continue;
      }
      break;
   }
   return losses;
}

bool United_ConsecutiveLossCooldownBlocksEntry(const string symbol, const ulong magic, const bool isBuy)
{
   if(!GRM_Enable || !GRM_ConsecutiveLossCooldownEnable || GRM_ConsecutiveLossCooldownBars <= 0)
      return false;
   datetime lastLossTime = 0;
   int losses = United_RecentConsecutiveLosses(symbol, magic, isBuy, lastLossTime, true);
   if(losses < GRM_ConsecutiveLossCount || lastLossTime <= 0)
      return false;
   int secondsPerBar = PeriodSeconds(GRM_ConsecutiveLossCooldownTimeframe);
   if(secondsPerBar <= 0)
      secondsPerBar = PeriodSeconds(PERIOD_H1);
   datetime untilTime = lastLossTime + (datetime)GRM_ConsecutiveLossCooldownBars * secondsPerBar;
   if(TimeCurrent() < untilTime)
   {
      if(GRM_DebugLogs) Print("GRM blocks entry: consecutive-loss cooldown, symbol=", symbol, ", magic=", magic, ", losses=", losses);
      return true;
   }
   return false;
}

int United_RecentPortfolioConsecutiveLosses(datetime &lastLossTime)
{
   lastLossTime = 0;
   if(GRM_PortfolioConsecutiveLossCount <= 0)
      return 0;

   datetime from = TimeCurrent() - (datetime)MathMax(1, GRM_PortfolioConsecutiveLossLookbackDays) * 86400;
   if(!HistorySelect(from, TimeCurrent()))
      return 0;

   int losses = 0;
   int total = HistoryDealsTotal();
   for(int dealIndex = total - 1; dealIndex >= 0; dealIndex--)
   {
      ulong deal = HistoryDealGetTicket(dealIndex);
      if(deal == 0)
         continue;
      ulong magic = (ulong)HistoryDealGetInteger(deal, DEAL_MAGIC);
      if(!United_IsKnownV4Magic(magic))
         continue;

      ENUM_DEAL_TYPE type = (ENUM_DEAL_TYPE)HistoryDealGetInteger(deal, DEAL_TYPE);
      if(type != DEAL_TYPE_BUY && type != DEAL_TYPE_SELL)
         continue;
      ENUM_DEAL_ENTRY entry = (ENUM_DEAL_ENTRY)HistoryDealGetInteger(deal, DEAL_ENTRY);
      if(entry != DEAL_ENTRY_OUT && entry != DEAL_ENTRY_INOUT)
         continue;

      double pl = HistoryDealGetDouble(deal, DEAL_PROFIT)
                + HistoryDealGetDouble(deal, DEAL_SWAP)
                + HistoryDealGetDouble(deal, DEAL_COMMISSION);
      if(pl < 0.0)
      {
         if(lastLossTime == 0)
            lastLossTime = (datetime)HistoryDealGetInteger(deal, DEAL_TIME);
         losses++;
         continue;
      }
      break;
   }
   return losses;
}

bool United_PortfolioLossCooldownBlocksEntry()
{
   if(!GRM_Enable || !GRM_PortfolioLossCooldownEnable || GRM_PortfolioLossCooldownBars <= 0)
      return false;
   datetime lastLossTime = 0;
   int losses = United_RecentPortfolioConsecutiveLosses(lastLossTime);
   if(losses < GRM_PortfolioConsecutiveLossCount || lastLossTime <= 0)
      return false;
   int secondsPerBar = PeriodSeconds(GRM_PortfolioLossCooldownTimeframe);
   if(secondsPerBar <= 0)
      secondsPerBar = PeriodSeconds(PERIOD_H1);
   datetime untilTime = lastLossTime + (datetime)GRM_PortfolioLossCooldownBars * secondsPerBar;
   if(TimeCurrent() < untilTime)
   {
      if(GRM_DebugLogs) Print("GRM blocks entry: portfolio consecutive-loss cooldown, losses=", losses);
      return true;
   }
   return false;
}

bool United_RecentPortfolioWinRate(int &wins, int &losses, datetime &lastDealTime)
{
   wins = 0;
   losses = 0;
   lastDealTime = 0;
   int lookbackTrades = MathMax(1, GRM_PortfolioWinRateLookbackTrades);
   datetime from = TimeCurrent() - (datetime)MathMax(1, GRM_PortfolioWinRateLookbackDays) * 86400;
   if(!HistorySelect(from, TimeCurrent()))
      return false;

   int total = HistoryDealsTotal();
   for(int dealIndex = total - 1; dealIndex >= 0 && (wins + losses) < lookbackTrades; dealIndex--)
   {
      ulong deal = HistoryDealGetTicket(dealIndex);
      if(deal == 0)
         continue;
      ulong magic = (ulong)HistoryDealGetInteger(deal, DEAL_MAGIC);
      if(!United_IsKnownV4Magic(magic))
         continue;

      ENUM_DEAL_TYPE type = (ENUM_DEAL_TYPE)HistoryDealGetInteger(deal, DEAL_TYPE);
      if(type != DEAL_TYPE_BUY && type != DEAL_TYPE_SELL)
         continue;
      ENUM_DEAL_ENTRY entry = (ENUM_DEAL_ENTRY)HistoryDealGetInteger(deal, DEAL_ENTRY);
      if(entry != DEAL_ENTRY_OUT && entry != DEAL_ENTRY_INOUT)
         continue;

      double pl = HistoryDealGetDouble(deal, DEAL_PROFIT)
                + HistoryDealGetDouble(deal, DEAL_SWAP)
                + HistoryDealGetDouble(deal, DEAL_COMMISSION);
      if(lastDealTime == 0)
         lastDealTime = (datetime)HistoryDealGetInteger(deal, DEAL_TIME);
      if(pl > 0.0)
         wins++;
      else
         losses++;
   }
   return (wins + losses) > 0;
}

bool United_PortfolioWinRateCooldownBlocksEntry()
{
   if(!GRM_Enable || !GRM_PortfolioWinRateCooldownEnable || GRM_PortfolioWinRateCooldownBars <= 0)
      return false;

   int wins = 0;
   int losses = 0;
   datetime lastDealTime = 0;
   if(!United_RecentPortfolioWinRate(wins, losses, lastDealTime))
      return false;
   int trades = wins + losses;
   if(trades < MathMax(1, GRM_PortfolioWinRateMinTrades) || lastDealTime <= 0)
      return false;

   double winRate = (double)wins / (double)trades * 100.0;
   if(winRate >= GRM_PortfolioWinRateMinPct)
      return false;

   int secondsPerBar = PeriodSeconds(GRM_PortfolioWinRateCooldownTimeframe);
   if(secondsPerBar <= 0)
      secondsPerBar = PeriodSeconds(PERIOD_H1);
   datetime untilTime = lastDealTime + (datetime)GRM_PortfolioWinRateCooldownBars * secondsPerBar;
   if(TimeCurrent() < untilTime)
   {
      if(GRM_DebugLogs) Print("GRM blocks entry: portfolio rolling win-rate cooldown, winRate=", DoubleToString(winRate, 2), ", trades=", trades);
      return true;
   }
   return false;
}

bool United_RecentSymbolWinRate(const string symbol, int &wins, int &losses, datetime &lastDealTime)
{
   wins = 0;
   losses = 0;
   lastDealTime = 0;
   int lookbackTrades = MathMax(1, GRM_SymbolWinRateLookbackTrades);
   datetime from = TimeCurrent() - (datetime)MathMax(1, GRM_SymbolWinRateLookbackDays) * 86400;
   if(!HistorySelect(from, TimeCurrent()))
      return false;

   int total = HistoryDealsTotal();
   for(int dealIndex = total - 1; dealIndex >= 0 && (wins + losses) < lookbackTrades; dealIndex--)
   {
      ulong deal = HistoryDealGetTicket(dealIndex);
      if(deal == 0)
         continue;
      if(HistoryDealGetString(deal, DEAL_SYMBOL) != symbol)
         continue;
      ulong magic = (ulong)HistoryDealGetInteger(deal, DEAL_MAGIC);
      if(!United_IsKnownV4Magic(magic))
         continue;

      ENUM_DEAL_TYPE type = (ENUM_DEAL_TYPE)HistoryDealGetInteger(deal, DEAL_TYPE);
      if(type != DEAL_TYPE_BUY && type != DEAL_TYPE_SELL)
         continue;
      ENUM_DEAL_ENTRY entry = (ENUM_DEAL_ENTRY)HistoryDealGetInteger(deal, DEAL_ENTRY);
      if(entry != DEAL_ENTRY_OUT && entry != DEAL_ENTRY_INOUT)
         continue;

      double pl = HistoryDealGetDouble(deal, DEAL_PROFIT)
                + HistoryDealGetDouble(deal, DEAL_SWAP)
                + HistoryDealGetDouble(deal, DEAL_COMMISSION);
      if(lastDealTime == 0)
         lastDealTime = (datetime)HistoryDealGetInteger(deal, DEAL_TIME);
      if(pl > 0.0)
         wins++;
      else
         losses++;
   }
   return (wins + losses) > 0;
}

bool United_SymbolWinRateCooldownBlocksEntry(const string symbol)
{
   if(!GRM_Enable || !GRM_SymbolWinRateCooldownEnable || GRM_SymbolWinRateCooldownBars <= 0)
      return false;

   int wins = 0;
   int losses = 0;
   datetime lastDealTime = 0;
   if(!United_RecentSymbolWinRate(symbol, wins, losses, lastDealTime))
      return false;
   int trades = wins + losses;
   if(trades < MathMax(1, GRM_SymbolWinRateMinTrades) || lastDealTime <= 0)
      return false;

   double winRate = (double)wins / (double)trades * 100.0;
   if(winRate >= GRM_SymbolWinRateMinPct)
      return false;

   int secondsPerBar = PeriodSeconds(GRM_SymbolWinRateCooldownTimeframe);
   if(secondsPerBar <= 0)
      secondsPerBar = PeriodSeconds(PERIOD_H1);
   datetime untilTime = lastDealTime + (datetime)GRM_SymbolWinRateCooldownBars * secondsPerBar;
   if(TimeCurrent() < untilTime)
   {
      if(GRM_DebugLogs) Print("GRM blocks entry: symbol rolling win-rate cooldown, symbol=", symbol, ", winRate=", DoubleToString(winRate, 2), ", trades=", trades);
      return true;
   }
   return false;
}

double United_PortfolioLossLotThrottleFactor()
{
   if(!GRM_Enable)
      return 1.0;

   double factor = 1.0;
   if(GRM_PortfolioConsecutiveLossLotThrottleEnable && GRM_PortfolioConsecutiveLossLotThrottleFactor < factor)
   {
      datetime lastLossTime = 0;
      int losses = United_RecentPortfolioConsecutiveLosses(lastLossTime);
      if(losses >= GRM_PortfolioConsecutiveLossCount)
         factor = MathMax(0.0, GRM_PortfolioConsecutiveLossLotThrottleFactor);
   }
   if(GRM_PortfolioDailyLossLotThrottleEnable
      && GRM_PortfolioDailyLossLotThrottleUSD > 0.0
      && GRM_PortfolioDailyLossLotThrottleFactor < factor
      && United_TodayKnownRealizedPL() <= -GRM_PortfolioDailyLossLotThrottleUSD)
      factor = MathMax(0.0, GRM_PortfolioDailyLossLotThrottleFactor);
   if(GRM_PortfolioMonthlyLossLotThrottleEnable
      && GRM_PortfolioMonthlyLossLotThrottleUSD > 0.0
      && GRM_PortfolioMonthlyLossLotThrottleFactor < factor
      && United_ThisMonthKnownRealizedPL() <= -GRM_PortfolioMonthlyLossLotThrottleUSD)
      factor = MathMax(0.0, GRM_PortfolioMonthlyLossLotThrottleFactor);

   return factor;
}

double United_LotThrottleFactor(const string symbol, const ulong magic)
{
   if(!GRM_Enable || !United_IsKnownV4Magic(magic))
      return 1.0;

   double factor = United_PortfolioLossLotThrottleFactor();
   if(GRM_MonthlyLossLotThrottleEnable
      && GRM_MonthlyLossLotThrottleUSD > 0.0
      && GRM_MonthlyLossLotThrottleFactor < factor
      && United_MagicIsInCsv(magic, GRM_MonthlyLossLotThrottleMagics)
      && (GRM_MonthlyLossLotThrottleSymbolContains == "" || United_SymbolContainsAny(symbol, GRM_MonthlyLossLotThrottleSymbolContains)))
   {
      double monthPL = United_KnownRealizedPLSinceForMagic(United_MonthStart(), magic);
      if(monthPL <= -GRM_MonthlyLossLotThrottleUSD)
         factor = MathMax(0.0, GRM_MonthlyLossLotThrottleFactor);
   }

   if(GRM_ConsecutiveLossLotThrottleEnable && GRM_ConsecutiveLossLotThrottleFactor < factor)
   {
      datetime lastLossTime = 0;
      int losses = United_RecentConsecutiveLosses(symbol, magic, true, lastLossTime, false);
      if(losses >= GRM_ConsecutiveLossCount)
         factor = MathMax(0.0, GRM_ConsecutiveLossLotThrottleFactor);
   }

   return factor;
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

bool United_TrendAlignmentBlocksEntry(const string symbol, const ulong magic, const bool isBuy)
{
   if(!GRM_TrendAlignEnable)
      return false;
   if(GRM_TrendAlignMagics != "" && !United_MagicIsInCsv(magic, GRM_TrendAlignMagics))
      return false;  // not in scope -> never blocked (e.g. scalpers keep counter-trend)
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

//+------------------------------------------------------------------+
//| Regime direction from the same D1 MA/slope test used by the      |
//| trend-align entry filter. Returns +1 uptrend, -1 downtrend,      |
//| 0 range/undetermined. Used by the regime quick-exit guard.       |
//+------------------------------------------------------------------+
int United_TrendRegimeDir(const string symbol)
{
   if(GRM_TrendAlignMAPeriod <= 1 || GRM_TrendAlignSlopeLookback <= 0)
      return 0;

   int maHandle = iMA(symbol, GRM_TrendAlignTimeframe, GRM_TrendAlignMAPeriod, 0, MODE_EMA, PRICE_CLOSE);
   if(maHandle == INVALID_HANDLE)
      return 0;

   double ma[];
   ArraySetAsSeries(ma, true);
   bool ok = (CopyBuffer(maHandle, 0, 1, GRM_TrendAlignSlopeLookback + 1, ma) == GRM_TrendAlignSlopeLookback + 1);
   IndicatorRelease(maHandle);
   if(!ok)
      return 0;

   double close = iClose(symbol, GRM_TrendAlignTimeframe, 1);
   if(close <= 0.0 || ma[0] <= 0.0 || ma[GRM_TrendAlignSlopeLookback] <= 0.0)
      return 0;

   double slopePct = (ma[0] - ma[GRM_TrendAlignSlopeLookback]) / ma[GRM_TrendAlignSlopeLookback] * 100.0;
   if(close > ma[0] && slopePct >= GRM_TrendAlignMinSlopePct)
      return 1;
   if(close < ma[0] && slopePct <= -GRM_TrendAlignMinSlopePct)
      return -1;
   return 0;
}

//+------------------------------------------------------------------+
//| Regime quick-exit: close any EA position held COUNTER to the D1   |
//| regime once its adverse excursion exceeds RQE_AdverseATRMult*ATR. |
//| With-trend and range-regime positions are left untouched. This is |
//| a surgical loss-cap on the exact judgement errors (counter-trend  |
//| runaways) that depress win-rate, without disabling any strategy.  |
//+------------------------------------------------------------------+
void United_RegimeQuickExit()
{
   if(!RQE_Enable || RQE_AdverseATRMult <= 0.0) return;

   CTrade rqeTrade;
   for(int i = PositionsTotal() - 1; i >= 0; i--)
   {
      ulong ticket = PositionGetTicket(i);
      if(ticket == 0 || !PositionSelectByTicket(ticket)) continue;
      ulong magic = (ulong)PositionGetInteger(POSITION_MAGIC);
      if(!United_IsKnownV4Magic(magic)) continue;
      if(RQE_Magics != "" && !United_MagicIsInCsv(magic, RQE_Magics)) continue;

      string symbol = PositionGetString(POSITION_SYMBOL);
      int dir = United_TrendRegimeDir(symbol);
      if(dir == 0) continue;  // range / undetermined -> leave alone

      bool isBuy = (PositionGetInteger(POSITION_TYPE) == POSITION_TYPE_BUY);
      bool counterTrend = (dir > 0 && !isBuy) || (dir < 0 && isBuy);
      if(!counterTrend) continue;  // with-trend -> let it run

      double openPx = PositionGetDouble(POSITION_PRICE_OPEN);
      double curPx  = isBuy ? SymbolInfoDouble(symbol, SYMBOL_BID)
                            : SymbolInfoDouble(symbol, SYMBOL_ASK);
      if(openPx <= 0.0 || curPx <= 0.0) continue;
      double adverse = isBuy ? (openPx - curPx) : (curPx - openPx);
      if(adverse <= 0.0) continue;  // not underwater

      int atrHandle = iATR(symbol, GRM_TrendAlignTimeframe, GRM_TrendAlignATRPeriod);
      if(atrHandle == INVALID_HANDLE) continue;
      double atr[];
      ArraySetAsSeries(atr, true);
      bool atrOk = (CopyBuffer(atrHandle, 0, 1, 1, atr) == 1);
      IndicatorRelease(atrHandle);
      if(!atrOk || atr[0] <= 0.0) continue;

      if(adverse >= RQE_AdverseATRMult * atr[0])
      {
         PrintFormat("[REGIME QUICK-EXIT] closing %s ticket %I64u magic=%I64u: counter-trend (regime %d) adverse %.5f >= %.2f*ATR(%.5f)",
                     symbol, ticket, magic, dir, adverse, RQE_AdverseATRMult, atr[0]);
         rqeTrade.PositionClose(ticket);
      }
   }
}

//+------------------------------------------------------------------+
//| Virtual Recovery Probe helpers. The shadow book records would-be |
//| entries while the monthly-loss breaker is tripped, resolves them |
//| against a short-horizon ATR TP/SL, and resumes REAL trading once |
//| the simulated win rate shows the market has recovered.           |
//+------------------------------------------------------------------+
void United_VRPClearBook()
{
   ArrayResize(g_VRPSym, 0);
   ArrayResize(g_VRPIsBuy, 0);
   ArrayResize(g_VRPEntry, 0);
   ArrayResize(g_VRPTP, 0);
   ArrayResize(g_VRPSL, 0);
}

void United_VRPResetEpisode()
{
   g_VRPWins = 0;
   g_VRPLosses = 0;
   United_VRPClearBook();
}

// Record a would-be entry as a virtual position. Deduped by symbol+side so the
// shadow book stays small and representative (one open probe per symbol/side).
void United_VRPRecordVirtual(const string symbol, const bool isBuy)
{
   for(int i = 0; i < ArraySize(g_VRPSym); i++)
      if(g_VRPSym[i] == symbol && g_VRPIsBuy[i] == isBuy)
         return;  // already probing this symbol/side

   double entry = SymbolInfoDouble(symbol, SYMBOL_BID);
   if(entry <= 0.0) return;

   int atrHandle = iATR(symbol, VRP_ATRTimeframe, VRP_ATRPeriod);
   if(atrHandle == INVALID_HANDLE) return;
   double atr[];
   ArraySetAsSeries(atr, true);
   bool ok = (CopyBuffer(atrHandle, 0, 1, 1, atr) == 1);
   IndicatorRelease(atrHandle);
   if(!ok || atr[0] <= 0.0) return;

   double tp = isBuy ? entry + VRP_VirtualTPATR * atr[0] : entry - VRP_VirtualTPATR * atr[0];
   double sl = isBuy ? entry - VRP_VirtualSLATR * atr[0] : entry + VRP_VirtualSLATR * atr[0];

   int n = ArraySize(g_VRPSym);
   ArrayResize(g_VRPSym, n + 1);   g_VRPSym[n]   = symbol;
   ArrayResize(g_VRPIsBuy, n + 1); g_VRPIsBuy[n] = isBuy;
   ArrayResize(g_VRPEntry, n + 1); g_VRPEntry[n] = entry;
   ArrayResize(g_VRPTP, n + 1);    g_VRPTP[n]    = tp;
   ArrayResize(g_VRPSL, n + 1);    g_VRPSL[n]    = sl;
}

void United_VRPRemoveAt(const int idx)
{
   int last = ArraySize(g_VRPSym) - 1;
   if(idx < 0 || idx > last) return;
   g_VRPSym[idx]   = g_VRPSym[last];
   g_VRPIsBuy[idx] = g_VRPIsBuy[last];
   g_VRPEntry[idx] = g_VRPEntry[last];
   g_VRPTP[idx]    = g_VRPTP[last];
   g_VRPSL[idx]    = g_VRPSL[last];
   ArrayResize(g_VRPSym, last);
   ArrayResize(g_VRPIsBuy, last);
   ArrayResize(g_VRPEntry, last);
   ArrayResize(g_VRPTP, last);
   ArrayResize(g_VRPSL, last);
}

//+------------------------------------------------------------------+
//| Per-tick shadow-book manager: resolve virtual positions and, when |
//| the virtual win rate shows recovery, resume REAL trading by       |
//| raising the monthly re-arm level (so the breaker won't re-trip    |
//| until losses deepen another full threshold).                      |
//+------------------------------------------------------------------+
void United_VirtualRecoveryManage()
{
   if(!VRP_Enable || !g_VRPActive) return;

   for(int i = ArraySize(g_VRPSym) - 1; i >= 0; i--)
   {
      double px = SymbolInfoDouble(g_VRPSym[i], SYMBOL_BID);
      if(px <= 0.0) continue;
      bool isBuy = g_VRPIsBuy[i];
      bool win  = isBuy ? (px >= g_VRPTP[i]) : (px <= g_VRPTP[i]);
      bool loss = isBuy ? (px <= g_VRPSL[i]) : (px >= g_VRPSL[i]);
      if(!win && !loss) continue;
      if(win) g_VRPWins++; else g_VRPLosses++;
      United_VRPRemoveAt(i);
   }

   int closed = g_VRPWins + g_VRPLosses;
   if(closed >= VRP_ProbeTrades)
   {
      double winRate = (closed > 0 ? (double)g_VRPWins / (double)closed : 0.0);
      if(winRate >= VRP_ResumeWinRate)
      {
         // Recovery confirmed -> resume real trading. Raise the arm level so the
         // breaker stays disarmed until losses deepen another full threshold.
         double monthPL   = United_ThisMonthKnownRealizedPL();
         double threshold = United_MonthlyLossThresholdUSD();
         g_MonthlyLossArmLevel = monthPL - threshold;
         PrintFormat("[VIRTUAL-RECOVERY] REAL trading RESUMED: virtual winRate=%.0f%% (%d/%d) >= %.0f%% | monthPL=%.2f, re-arm level lowered to %.2f",
                     winRate * 100.0, g_VRPWins, closed, VRP_ResumeWinRate * 100.0, monthPL, g_MonthlyLossArmLevel);
         g_VRPActive = false;
         United_VRPResetEpisode();
      }
      else if(TimeCurrent() - g_VRPLastLog >= 3600)
      {
         g_VRPLastLog = TimeCurrent();
         PrintFormat("[VIRTUAL-RECOVERY] shadow probing: virtual winRate=%.0f%% (%d/%d) < %.0f%% target, real trading still paused",
                     winRate * 100.0, g_VRPWins, closed, VRP_ResumeWinRate * 100.0);
      }
   }
}

bool United_GlobalRiskAllowsEntry(const string symbol, const ulong magic, const bool isBuy)
{
   // Portfolio circuit-breaker cooldown blocks ALL new real entries (even if GRM off).
   if(United_PortfolioEquityStopInCooldown())
   {
      United_LogVirtualEntry(symbol, magic, isBuy);
      return false;
   }

   // Principal Guard hard floor: defend the STARTING capital. Once equity
   // reaches the principal floor, block new entries (optionally flatten) so
   // the initial principal cannot be eroded further by a bleeding book.
   if(United_PrincipalGuardBlocksEntry())
      return false;

   // Session gate: do not attempt entries when the symbol's market is closed
   // (stocks/.NAS, DE40 overnight/weekend) -> avoids retcode 10018 spam.
   // Scoped to SessGate_SymbolContains so 24h FX/metal/crypto are unaffected.
   if(SessGate_Enable
      && (SessGate_SymbolContains == "" || United_SymbolContainsAny(symbol, SessGate_SymbolContains))
      && !United_MarketSessionOpen(symbol))
      return false;

   // News guard: block entries around high-impact USD events when enabled.
   if(United_NewsGuardBlocksEntry(symbol))
      return false;

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
         double eqNow = AccountInfoDouble(ACCOUNT_EQUITY);
         double fmNow = AccountInfoDouble(ACCOUNT_MARGIN_FREE);
         if(VRP_Enable)
         {
            // Virtual Recovery Probe: pause REAL trading but keep shadow-trading;
            // resume on simulated win-rate recovery (handled by the OnTick manager
            // which raises g_MonthlyLossArmLevel). Highest-precedence recovery mode.
            datetime ms = United_MonthStart();
            if(ms != g_MonthlyLossArmMonth)   // new month -> reset breaker + probe state
            {
               g_MonthlyLossArmMonth = ms;
               g_MonthlyLossArmLevel = 0.0;
               g_VRPActive = false;
               United_VRPResetEpisode();
            }
            if(monthPL <= g_MonthlyLossArmLevel)   // still armed at/below this loss level
            {
               if(!g_VRPActive)
               {
                  g_VRPActive = true;
                  United_VRPResetEpisode();
                  PrintFormat("[VIRTUAL-RECOVERY] SHADOW MODE engaged: monthPL=%.2f <= -%.2f limit | equity=%.2f freeMargin=%.2f | real entries paused, probing virtual win rate (need %d trades @ >=%.0f%%)",
                              monthPL, monthlyLossThreshold, eqNow, fmNow, VRP_ProbeTrades, VRP_ResumeWinRate * 100.0);
               }
               United_VRPRecordVirtual(symbol, isBuy);   // log the would-be entry as virtual
               return false;                              // no real entry while probing
            }
            // monthPL recovered above the arm level -> allow real trading
         }
         else if(GRM_MonthlyLossCooldownHours <= 0.0)
         {
            // Legacy hard block: no new entries for the rest of the calendar month.
            // Always-on, throttled log (rich context) so the wasted month is visible.
            if(TimeCurrent() - g_MonthlyLossLastLog >= 3600)
            {
               g_MonthlyLossLastLog = TimeCurrent();
               PrintFormat("[MONTHLY-LOSS BREAKER] MONTH-LOCK active for %s: monthPL=%.2f <= -%.2f limit | equity=%.2f freeMargin=%.2f | NO new entries until next calendar month (set GRM_MonthlyLossCooldownHours>0 for recoverable cooldown)",
                           symbol, monthPL, monthlyLossThreshold, eqNow, fmNow);
            }
            return false;
         }
         else
         {
            // Re-arming cooldown: pause entries for a recoverable window, not the whole month.
            datetime ms = United_MonthStart();
            if(ms != g_MonthlyLossArmMonth)   // new month -> reset breaker state
            {
               g_MonthlyLossArmMonth = ms;
               g_MonthlyLossArmLevel = 0.0;
               g_MonthlyLossCooldownUntil = 0;
            }
            datetime nowt = TimeCurrent();
            if(nowt >= g_MonthlyLossCooldownUntil && monthPL <= g_MonthlyLossArmLevel)
            {
               g_MonthlyLossCooldownUntil = nowt + (datetime)(GRM_MonthlyLossCooldownHours * 3600.0);
               g_MonthlyLossArmLevel = monthPL - monthlyLossThreshold;  // re-arm only if losses deepen another full threshold
               // Always-on log on each fresh arm: rich context for tuning.
               PrintFormat("[MONTHLY-LOSS BREAKER] cooldown ARMED for %s: monthPL=%.2f <= -%.2f limit | equity=%.2f freeMargin=%.2f | pause %.1fh until %s | re-arms only if monthPL falls below %.2f",
                           symbol, monthPL, monthlyLossThreshold, eqNow, fmNow,
                           GRM_MonthlyLossCooldownHours, TimeToString(g_MonthlyLossCooldownUntil, TIME_DATE | TIME_MINUTES),
                           g_MonthlyLossArmLevel);
            }
            if(nowt < g_MonthlyLossCooldownUntil)
            {
               if(TimeCurrent() - g_MonthlyLossLastLog >= 3600)
               {
                  g_MonthlyLossLastLog = TimeCurrent();
                  PrintFormat("[MONTHLY-LOSS BREAKER] in cooldown for %s: monthPL=%.2f | resumes %s",
                              symbol, monthPL, TimeToString(g_MonthlyLossCooldownUntil, TIME_DATE | TIME_MINUTES));
               }
               return false;   // inside cooldown window -> pause new entries
            }
            // cooldown elapsed -> allow entries again for a within-month recovery chance
         }
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
   if(United_TrendAlignmentBlocksEntry(symbol, magic, isBuy))
   {
      if(GRM_DebugLogs) Print("GRM blocks entry: trend-alignment regime for ", symbol);
      return false;
   }
   if(United_ConsecutiveLossCooldownBlocksEntry(symbol, magic, isBuy))
      return false;
   if(United_PortfolioLossCooldownBlocksEntry())
      return false;
   if(United_PortfolioWinRateCooldownBlocksEntry())
      return false;
   if(United_SymbolWinRateCooldownBlocksEntry(symbol))
      return false;

   if(!United_IsStrategyAllowedInRegime(magic, United_GetMarketRegime(symbol)))
   {
      if(GRM_DebugLogs) Print("GRM blocks entry: strategy magic ", magic, " is not suitable for current market regime of ", symbol);
      return false;
   }

   return true;
}

bool United_MayOpenNewEntry(const string symbol, const ulong magic, const bool isBuy)
{
   if(PositionExistsByMagic(symbol, magic))
      return false;
   if(!United_GlobalRiskAllowsEntry(symbol, magic, isBuy))
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
input bool EnableRSIScalpingMU = true;
input bool EnableSuperEMA = true;
input bool EnableRSIConsolidation = false;
input bool EnableRSIReversalAsianEURUSD = true;
input bool EnableRSIReversalAsianAUDUSD = true;
input bool EnableSimpleTrendlineBTCUSD = true;
input bool EnableSimpleTrendlineXAUUSD = true;
input bool EnableSimpleTrendlineGER40 = true;
input bool EnableRSISecretSauce = true;
input bool EnableWilliamsPassivation = true;

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
input double LOT_RS_MU = 10.0;
input double LOT_RRA_EURUSD = 0.05;
input double LOT_RRA_AUDUSD = 0.08;
input double LOT_SE_SuperEMA = 0.02;
input double LOT_RCO_RSIConsolidation = 0.02;
input double LOT_ST_BTCUSD = 0.07;
input double LOT_ST_XAUUSD = 0.01;
input double LOT_ST_GER40 = 0.10;
input double LOT_RSS_SecretSauce = 0.01;
input double LOT_WP_WilliamsPassivation = 0.03;

input group "=== Balance-based position sizing ==="
input bool   ORCH_ScaleLotsByBalance = true;
input bool   ORCH_UseEquityInsteadOfBalance = false;
input double ORCH_ReferenceBalance = 3000.0;
input double ORCH_MinBalanceScale = 0.1;
input double ORCH_MaxBalanceScale = 10.0;

//+------------------------------------------------------------------+
//| Unified Risk Facade (v4opt Phase 1)                              |
//| One margin-aware multiplier that REPLACES the blind DD-only      |
//| scale-up. Enforces: margin-load cap, margin-level floor, and an  |
//| equity-peak drawdown soft/hard breaker. Hides the 100+ GRM knobs |
//| behind ~7 inputs; keeps the full strategy set intact.            |
//+------------------------------------------------------------------+
input group "=== Unified Risk Facade (Phase 1) ==="
input bool   URF_Enable             = true;   // margin facade ON = the stability lever: halves cold-start/live-start worst DD (~40% vs ~70%). Set false for the greedy high-DD variant.
input double URF_BaseScale          = 1.5;    // flat lot multiplier (sweep DOWN to cut DD)
input double URF_MaxMarginLoadPct   = 25.0;   // cap used-margin / equity (%)
input double URF_MinMarginLevelPct  = 300.0;  // floor equity / used-margin * 100 (%)
input double URF_SoftBreakerDDPct   = 8.0;    // equity DD from peak to begin throttling (%)
input double URF_HardBreakerDDPct   = 20.0;   // equity DD from peak -> near-zero new exposure (%)
input double URF_MinScale           = 0.05;   // never fully zero new exposure

//+------------------------------------------------------------------+
//| Portfolio Equity Stop (Phase 1b) — the real equity-DD gate       |
//| Throttling lot size only fixes margin/liquidation risk; the      |
//| equity drawdown is driven by FLOATING losses on open positions.  |
//| This breaker CLOSES all EA positions when the equity drawdown    |
//| from the running peak exceeds a threshold, then pauses new        |
//| entries for a cooldown, capping the maximum equity excursion.    |
//+------------------------------------------------------------------+
input group "=== Portfolio Equity Stop (Phase 1b) ==="
input bool   PES_Enable             = false;  // master switch
input double PES_TriggerDDPct       = 12.0;   // close-all when equity DD from peak >= this (%)
input int    PES_CooldownMin        = 720;    // pause new entries this many minutes after a stop

//+------------------------------------------------------------------+
//| Circuit Breaker & Position Monitor (Phase 5)                     |
//| Breaker trips ONLY when BOTH: (1) equity DD from peak >=          |
//| CB_LossThresholdPct AND (2) >= CB_ConsecutiveLosses consecutive   |
//| losing closed trades. On trip it optionally flattens and pauses   |
//| new REAL entries; while paused, would-be entries are printed as   |
//| VIRTUAL trades. Position monitor hard-caps any single position's  |
//| floating loss so a fast crash cannot become a catastrophic loss.  |
//+------------------------------------------------------------------+
input group "=== Circuit Breaker & Position Monitor (Phase 5) ==="
input bool   CB_Enable              = false;  // OFF: peak-DD breaker chops recoverable profit-zone DD (validated: kills compounding). Opt-in only.
input double CB_LossThresholdPct    = 3.0;    // arm cond 1: equity DD from peak (%)
input int    CB_ConsecutiveLosses   = 4;      // arm cond 2: consecutive losing closed trades
input int    CB_LossLookbackTrades  = 20;     // recent closed-trade window to scan
input int    CB_CooldownMin         = 240;    // pause real entries this many minutes after a trip
input bool   CB_FlattenOnTrip       = true;   // close all EA positions when the breaker trips
input bool   CB_LogVirtual          = true;   // print would-be (virtual) entries while paused
input int    CB_VirtualLogThrottleSec = 60;   // min seconds between virtual-entry log lines
input bool   PM_Enable              = false;  // OFF: per-position cap cuts recoverable swings (harms profit). Opt-in only.
input double PM_MaxPositionLossPct  = 2.5;    // close a position if float loss >= this % of equity
input double PM_MaxPositionLossUSD  = 0.0;    // OR absolute USD cap (0 = use percent only)

//+------------------------------------------------------------------+
//| Principal Guard (asymmetric capital protection)                  |
//| Priority: protect the STARTING principal; tolerate profit DD.    |
//| Throttles lot size ONLY while equity is at/below the initial     |
//| principal (no profit buffer to spend) and applies a hard floor   |
//| that blocks new entries once capital erosion reaches the limit.  |
//| Profit-zone trading (equity > principal) is left unconstrained.  |
//+------------------------------------------------------------------+
input group "=== Principal Guard (capital protection, asymmetric) ==="
input bool   PG_Enable             = false;  // OFF: equity-feedback de-risk slows recovery -> WORSE principal DD (p8b: -21.5% vs champ -12.4%) AND less profit. Opt-in only.
input double PG_PrincipalUSD       = 0.0;    // 0 = auto-capture initial deposit at OnInit; else fixed
input double PG_FloorMult          = 0.80;   // de-risk floor = principal * this (scale bottoms out here)
input double PG_DeriskTopMult      = 1.00;   // start de-risking when equity < principal * this
input double PG_MinScale           = 0.40;   // lot scale at/below floor (linear up to 1.0 at DeriskTop)
input bool   PG_HaltEntriesAtFloor = false;  // OFF: a hard halt at the floor death-spirals (validated p7). De-risk only.
input bool   PG_FlattenAtFloor     = false;  // also force-close all positions at floor (off: don't realize)

//+------------------------------------------------------------------+
//| Session & News guards (Phase 3) — profit-neutral cleanups        |
//| - Session gate: skip ENTRY when the symbol's trading session is  |
//|   closed (stocks/.NAS, DE40 overnight/weekend) -> stops the      |
//|   retcode 10018 "market closed" order spam.                      |
//| - News guard: block new entries in a window around high-impact   |
//|   monthly USD events (NFP first Friday, CPI/FOMC mid-month) as a  |
//|   tester-safe date/time fallback (the strategy tester has no live |
//|   economic calendar).                                            |
//+------------------------------------------------------------------+
input group "=== Session & News Guards (Phase 3) ==="
input bool   SessGate_Enable        = false;  // skip entries when symbol session is closed
input string SessGate_SymbolContains = ".NAS,DE40"; // only gate these (stocks/index); empty = all
input bool   NewsGuard_Enable       = false;  // block entries around high-impact USD events
input string NewsGuard_SymbolContains = "XAUUSD,EURUSD,USD"; // which symbols the guard applies to
input int    NewsGuard_BeforeMin    = 30;     // block this many minutes before an event
input int    NewsGuard_AfterMin     = 30;     // block this many minutes after an event
input int    NewsGuard_NFPHourUTC   = 12;     // NFP/CPI release hour (UTC, ~12:30 = 13:30 CET)
input int    NewsGuard_NFPMinUTC    = 30;     // release minute (UTC)
input int    NewsGuard_CPIDay       = 12;     // approx day-of-month for CPI
input int    NewsGuard_FOMCDay      = 18;     // approx day-of-month for FOMC decision (14:00 UTC)
input int    NewsGuard_FOMCHourUTC  = 18;     // FOMC decision hour (UTC)

//+------------------------------------------------------------------+
//| Swap-aware close (Phase 3) — reduce overnight swap cost          |
//| Just before the daily swap charge (server rollover ~00:00), close|
//| positions whose floating profit is small/positive so we don't pay|
//| swap to hold them; strong winners (>= keep threshold in ATR or   |
//| money) are left to ride. Strategies re-enter next session if the |
//| signal persists. Triple-swap (Wednesday) handled by a wider band.|
//+------------------------------------------------------------------+
input group "=== Swap-Aware Close (Phase 3) ==="
input bool   SwapClose_Enable        = false; // close marginal positions before rollover
input int    SwapClose_StartHourSrv  = 23;    // begin closing window at this server hour
input int    SwapClose_StartMinSrv   = 50;    // begin closing window at this server minute
input double SwapClose_KeepProfitUSD = 50.0;  // keep positions with floating profit >= this
input bool   SwapClose_OnlyNegativeSwap = true; // only close when the symbol's swap is negative

//+------------------------------------------------------------------+
//| Strategy 1: DarvasBoxXAUUSD                                      |
//+------------------------------------------------------------------+
input group "=== DarvasBox Strategy ==="
input string DB_Symbol = "XAUUSD";
input int    DB_BoxPeriod = 165;
// Increased to allow larger ranges (was 25140)
input double DB_BoxDeviation = 30000;
// Set to 0 to disable volume threshold check. Volume data from indicator used instead.
input int    DB_VolumeThreshold = 0;
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
// V4-iter4: tighter cap on RC SELL (2000 pts = $20 on XAU). 0 = disabled.
input double RC_SellHardSL_Points = 2000;
// V4-iter7-D: skip RC SELL entry when HTF (D1 EMA200) shows uptrend (slope>0 AND price>EMA).
input bool   RC_VetoSellAgainstHTF = true;
// V4-iter7-D: timeframe for HTF veto.
input ENUM_TIMEFRAMES RC_HTF_TimeFrame = PERIOD_D1;
// V4-iter7-D: EMA length on HTF for trend bias.
input int    RC_HTF_EMAPeriod = 200;
// V4-iter7-D: bars to measure HTF EMA slope.
input int    RC_HTF_SlopeBars  = 5;
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
input bool   RM_InpIntrabarExitMonitorEnable = false;
input bool   RM_InpLTFConfirmEnable = false;
input ENUM_TIMEFRAMES RM_InpLTFConfirmTimeframe = PERIOD_M15;
input int    RM_InpLTFConfirmRSIPeriod = 14;
input double RM_InpLTFConfirmBuyMin = 50.0;
input double RM_InpLTFConfirmSellMax = 50.0;
input int    RM_InpLTFConfirmMaxDelayBars = 0;
input bool   RM_InpLTFSoftScaleEnable = false;
input double RM_InpLTFSoftScaleWeakLotFactor = 0.70;
input int    RM_InpRSIPeriod = 32;
input int    RM_InpRSIOverbought = 78;
input int    RM_InpRSIOversold = 46;
input int    RM_InpRSIExitLevel = 44;
input bool   RM_InpRSIFollowUseReentryBand = false;
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
// Pepperstone / match tester set (also try AAPL.US)
input string RS_APPL_Symbol = "AAPL.NAS";
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
// Pepperstone may use: "BTCUSD", "BTC/USD", or "BTCUSD.c"
input string RS_BTCUSD_Symbol = "BTCUSD";
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
// Pepperstone / match tester set (also try NVDA.US)
input string RS_NVDA_Symbol = "NVDA.NAS";
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
// Pepperstone / match tester set (also try TSLA.US)
input string RS_TSLA_Symbol = "TSLA.NAS";
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
input bool   RS_RequireOrderedBands = false;
input bool   RS_UseClosedBarExit = false;
input bool   RS_UseReversalEscape = true;
input bool   RS_UseReversalEscapeAllSymbols = false;
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

input group "=== RSI Scalping MU (Micron) - IC Markets .NAS ==="
// IC Markets NASDAQ stock symbol; tick history present in mt5-dev container.
input string RS_MU_Symbol = "MU.NAS";
input ENUM_TIMEFRAMES RS_MU_TimeFrame = PERIOD_M15;
input int    RS_MU_RSI_Period = 8;
input ENUM_APPLIED_PRICE RS_MU_RSI_Applied_Price = PRICE_CLOSE;
input double RS_MU_RSI_Overbought = 36;
input double RS_MU_RSI_Oversold = 38;
input double RS_MU_RSI_Target_Buy = 90;
input double RS_MU_RSI_Target_Sell = 70;
input int    RS_MU_BarsToWait = 5;
input double RS_MU_LotSize = 50;
input int    RS_MU_MagicNumber = 20004;
input int    RS_MU_Slippage = 3;

input group "=== RSI Scalping MU — Trailing ==="
input bool   RS_MU_UseTrailingStop = true;
input double RS_MU_TrailDistancePoints = 375.0;
input double RS_MU_TrailActivationPoints = 75.0;

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
// V4-iter8-E2: block RRA SELL when D1 EMA200 trending UP.
input bool             RRA_VetoSellAgainstHTF = true;
input ENUM_TIMEFRAMES  RRA_HTF_TimeFrame      = PERIOD_D1;
input int              RRA_HTF_EMAPeriod      = 200;
// require EMA(now) > EMA(N bars ago) AND price > EMA to veto SELL.
input int              RRA_HTF_SlopeBars      = 5;

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
// V4-iter5: enforce time-based exit only for this magic (ST_XAU). 0 = disabled / any.
input ulong  ST_MaxHoldMagic   = 26042503;
// V4-iter7-C: also apply MaxHold to ST_DE40. 0 = none.
input ulong  ST_MaxHoldMagic2  = 26042502;
// V4-iter5: close stuck positions after N hours (0 = disabled). XAU ST avg hold ~92k-180k min observed.
input int    ST_MaxHoldHours   = 72;
// V4-iter8-H REVERTED: H-4 FAIL all 3 windows; H-6 IS+RECENT hung 45m/5h. 0 = disabled.
input ulong  ST_MinHoldMagic   = 0;
// V4-iter8-H REVERTED: 0 = disabled.
input int    ST_MinHoldHours   = 0;
input double ST_MinSlopePointsPerBar = 0.0;
input bool   ST_EarlyFailureExitEnable = false;
input int    ST_EarlyFailureMinHoldBars = 1;
input int    ST_EarlyFailureMaxHoldHours = 4;
input double ST_EarlyFailureMinLossPoints = 0.0;
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

input group "=== Williams Passivation Strategy ==="
input string              WP_Symbol = "EURUSD;AUDUSD;XAUUSD;BTCUSD;AAPL.NAS;NVDA.NAS;TSLA.NAS;DE40;SOXX.NAS;XTIUSD;XBRUSD;XNGUSD";
input ENUM_TIMEFRAMES     WP_Timeframe = PERIOD_H1;
input int                 WP_WPR_Period = 14;
input int                 WP_PassivationBars = 3;
input double              WP_OverboughtLevel = -20.0;
input double              WP_OversoldLevel = -80.0;
input int                 WP_BB_Period = 20;
input double              WP_BB_Deviation = 2.0;
input ENUM_APPLIED_PRICE  WP_BB_AppliedPrice = PRICE_CLOSE;
input int                 WP_EMA_D1_Period = 200;
input ENUM_APPLIED_PRICE  WP_EMA_D1_AppliedPrice = PRICE_CLOSE;
input bool                WP_Filter_D1_EMA_Slope = true;
input bool                WP_Filter_D1_EMA_Price = true;
input bool                WP_Filter_ATR_Enable = true;
input int                 WP_Filter_ATR_Period = 14;
input double              WP_Filter_ATR_MinPoints = 120.0;
input bool                WP_UseTrailingStop = true;
input double              WP_TrailDistancePoints = 300.0;
input double              WP_TrailActivationPoints = 200.0;
input bool                WP_ExitOnPassivationEnd = false;
input double              WP_StopLossPoints = 500.0;
input double              WP_TakeProfitPoints = 1000.0;
input int                 WP_MagicNumber = 20260524;
input int                 WP_Slippage = 10;
input int                 WP_MaxSpreadPoints = 30;

//+------------------------------------------------------------------+
//| Dynamic Strategy Regime and Margin utilization Regulator         |
//+------------------------------------------------------------------+
enum ENUM_MARKET_REGIME {
   REGIME_TRENDING,
   REGIME_RANGING,
   REGIME_NEUTRAL
};

struct SymbolRegime {
   string symbol;
   int adxHandle;
};

SymbolRegime g_SymbolRegimes[30];
int g_NumSymbolRegimes = 0;

//--- Performance caching to avoid per-tick HistorySelect overhead ---
double g_CachedMarginScale = 1.0;
double g_EquityPeak = 0.0;   // running equity high-water mark for the URF drawdown breaker
datetime g_MonthlyLossCooldownUntil = 0;  // recoverable monthly-loss breaker: pause-until time
double   g_MonthlyLossArmLevel = 0.0;     // monthPL level that re-arms the cooldown
datetime g_MonthlyLossArmMonth = 0;       // month-start of the current arm state (for reset)
datetime g_MonthlyLossLastLog = 0;        // throttle for the always-on monthly-loss breaker log
// --- Virtual Recovery Probe (VRP) state ---
bool     g_VRPActive = false;             // shadow-trading mode engaged (real entries paused)
datetime g_VRPLastLog = 0;                // throttle for shadow-mode status log
int      g_VRPWins = 0;                   // closed virtual wins in the current probe episode
int      g_VRPLosses = 0;                 // closed virtual losses in the current probe episode
string   g_VRPSym[];                      // open virtual positions: symbol
bool     g_VRPIsBuy[];                    //                          side
double   g_VRPEntry[];                    //                          entry price
double   g_VRPTP[];                       //                          take-profit price (absolute)
double   g_VRPSL[];                       //                          stop-loss price (absolute)
double g_InitialDeposit = 0.0;   // starting principal (captured at OnInit) for the Principal Guard
datetime g_PESCooldownUntil = 0;   // Portfolio Equity Stop: block new entries until this time
datetime g_CBLastVirtualLog = 0;   // throttle for circuit-breaker virtual-entry logging

struct StrategyPerfCache {
   ulong magic;
   double multiplier;
};

StrategyPerfCache g_PerfCache[30];
int g_NumPerfCache = 0;
datetime g_LastPerfRefreshTime = 0;
const int PERF_REFRESH_INTERVAL = 3600; // refresh strategy multipliers once per hour

int GetSymbolRegimeIndex(const string symbol)
{
   for(int i = 0; i < g_NumSymbolRegimes; i++)
   {
      if(g_SymbolRegimes[i].symbol == symbol)
         return i;
   }
   if(g_NumSymbolRegimes >= 30)
      return -1;
   
   int idx = g_NumSymbolRegimes;
   g_SymbolRegimes[idx].symbol = symbol;
   g_SymbolRegimes[idx].adxHandle = iADX(symbol, PERIOD_H4, 14);
   
   g_NumSymbolRegimes++;
   return idx;
}

ENUM_MARKET_REGIME United_GetMarketRegime(const string symbol)
{
   int idx = GetSymbolRegimeIndex(symbol);
   if(idx < 0 || g_SymbolRegimes[idx].adxHandle == INVALID_HANDLE) 
      return REGIME_NEUTRAL;
   
   double adxValues[1];
   if(CopyBuffer(g_SymbolRegimes[idx].adxHandle, 0, 1, 1, adxValues) <= 0)
      return REGIME_NEUTRAL;
      
   double adx = adxValues[0];
   if(adx > 25.0)
      return REGIME_TRENDING;
   else if(adx < 20.0)
      return REGIME_RANGING;
   
   return REGIME_NEUTRAL;
}

bool United_IsStrategyAllowedInRegime(const ulong magic, const ENUM_MARKET_REGIME regime)
{
   if(regime == REGIME_NEUTRAL)
      return true;
      
   bool isTrendStrat = (magic == 135790 
                     || magic == 12350 
                     || magic == 940001 
                     || magic == 26042501 || magic == 26042502 || magic == 26042503
                     || (magic >= 20260524 && magic <= 20260524 + 15));
                     
   bool isRangeStrat = (magic == 7
                     || magic == 1001 || magic == 1002 || magic == 1003
                     || magic == 30001 || magic == 30002
                     || magic == 20250420
                     || magic == 789012);
                     
   if(regime == REGIME_TRENDING)
   {
      if(isRangeStrat)
         return false;
   }
   else if(regime == REGIME_RANGING)
   {
      if(isTrendStrat)
         return false;
   }
   
   return true;
}

bool United_RecentStrategyWinRate(const ulong magic, int &wins, int &losses)
{
   wins = 0;
   losses = 0;
   // NOTE: Caller must have called HistorySelect() before this function.
   // We do NOT call HistorySelect() here to avoid redundant per-magic calls.
   int total = HistoryDealsTotal();
   int count = 0;
   for(int i = total - 1; i >= 0 && count < 20; i--)
   {
      ulong deal = HistoryDealGetTicket(i);
      if(deal == 0) continue;
      if((ulong)HistoryDealGetInteger(deal, DEAL_MAGIC) != magic)
         continue;
      ENUM_DEAL_TYPE type = (ENUM_DEAL_TYPE)HistoryDealGetInteger(deal, DEAL_TYPE);
      if(type != DEAL_TYPE_BUY && type != DEAL_TYPE_SELL)
         continue;
      ENUM_DEAL_ENTRY entry = (ENUM_DEAL_ENTRY)HistoryDealGetInteger(deal, DEAL_ENTRY);
      if(entry != DEAL_ENTRY_OUT && entry != DEAL_ENTRY_INOUT)
         continue;
         
      double pl = HistoryDealGetDouble(deal, DEAL_PROFIT)
                + HistoryDealGetDouble(deal, DEAL_SWAP)
                + HistoryDealGetDouble(deal, DEAL_COMMISSION);
      if(pl > 0.0) wins++;
      else losses++;
      count++;
   }
   return (count > 0);
}

double United_StrategyPerformanceMultiplier_Raw(const ulong magic)
{
   int wins = 0;
   int losses = 0;
   if(!United_RecentStrategyWinRate(magic, wins, losses))
      return 1.0;
   int total = wins + losses;
   if(total >= 5)
   {
      double winRate = (double)wins / total;
      if(winRate < 0.30)
         return 0.1; // scale down to 10% lot size
      else if(winRate < 0.40)
         return 0.5; // scale down to 50% lot size
   }
   return 1.0;
}

double United_CachedPerfMultiplier(const ulong magic)
{
   for(int i = 0; i < g_NumPerfCache; i++)
   {
      if(g_PerfCache[i].magic == magic)
         return g_PerfCache[i].multiplier;
   }
   return 1.0; // not yet cached, assume 1.0
}

void United_RefreshPerformanceCache()
{
   datetime now = TimeCurrent();
   if(g_LastPerfRefreshTime != 0 && (now - g_LastPerfRefreshTime) < PERF_REFRESH_INTERVAL)
      return; // skip refresh, cache still valid
   
   g_LastPerfRefreshTime = now;
   
   // Single HistorySelect for all strategies
   datetime from = now - 30 * 86400;
   if(!HistorySelect(from, now))
      return;
   
   // Collect all known magic numbers
   ulong magics[];
   int magicCount = 0;
   ArrayResize(magics, 20);
   magics[magicCount++] = (ulong)DB_MagicNumber;
   magics[magicCount++] = (ulong)ES_MagicNumber;
   magics[magicCount++] = (ulong)RC_MagicNumber;
   magics[magicCount++] = (ulong)RM_InpMagicNumberRSIFollow;
   magics[magicCount++] = (ulong)RS_APPL_MagicNumber;
   magics[magicCount++] = (ulong)RS_BTCUSD_MagicNumber;
   magics[magicCount++] = (ulong)RS_NVDA_MagicNumber;
   magics[magicCount++] = (ulong)RS_TSLA_MagicNumber;
   magics[magicCount++] = (ulong)RS_XAUUSD_MagicNumber;
   magics[magicCount++] = (ulong)RRA_EURUSD_MagicNumber;
   magics[magicCount++] = (ulong)RRA_AUDUSD_MagicNumber;
   magics[magicCount++] = (ulong)SE_MagicNumber;
   magics[magicCount++] = (ulong)RCO_MagicNumber;
   magics[magicCount++] = (ulong)ST_BTC_MagicNumber;
   magics[magicCount++] = (ulong)ST_XAU_MagicNumber;
   magics[magicCount++] = (ulong)ST_GER_MagicNumber;
   magics[magicCount++] = (ulong)RSS_MagicNumber;
   magics[magicCount++] = (ulong)WP_MagicNumber;
   
   g_NumPerfCache = 0;
   for(int m = 0; m < magicCount && g_NumPerfCache < 30; m++)
   {
      g_PerfCache[g_NumPerfCache].magic = magics[m];
      g_PerfCache[g_NumPerfCache].multiplier = United_StrategyPerformanceMultiplier_Raw(magics[m]);
      g_NumPerfCache++;
   }
}

double United_DynamicMarginScale()
{
   double balance = AccountInfoDouble(ACCOUNT_BALANCE);
   double equity = AccountInfoDouble(ACCOUNT_EQUITY);
   if(balance <= 0.0) return 1.0;
   double drawdownPct = (balance - equity) / balance;
   if(drawdownPct < 0.0) drawdownPct = 0.0;
   
   double limit = 0.15; // Target hard max drawdown limit of 15%
   
   double scale = 1.0;
   if(drawdownPct < 0.03)
   {
      scale = 2.5; 
   }
   else if(drawdownPct < 0.06)
   {
      scale = 1.5;
   }
   else if(drawdownPct < 0.10)
   {
      scale = 0.8;
   }
   else
   {
      // Throttling down from 0.8 to 0.05 linearly as drawdownPct goes from 10% to 15%
      double factor = (limit - drawdownPct) / (limit - 0.10);
      scale = MathMax(0.05, 0.8 * factor);
   }

   return scale;
}

//+------------------------------------------------------------------+
//| Unified Risk Facade scale — margin-load cap + margin-level floor |
//| + equity-peak drawdown breaker. Returns a lot multiplier in      |
//| [URF_MinScale .. URF_MaxScaleUp]. Replaces United_DynamicMargin- |
//| Scale() at the OnTick chokepoint when URF_Enable.                |
//+------------------------------------------------------------------+
double United_RiskFacadeScale()
{
   double equity = AccountInfoDouble(ACCOUNT_EQUITY);
   double margin = AccountInfoDouble(ACCOUNT_MARGIN);

   // Flat base multiplier (replaces the blind 2.5x). Profit and drawdown scale
   // ~proportionally with URF_BaseScale, so it is a clean single dial to sweep.
   double scale = URF_BaseScale;

   double level   = (margin > 0.0) ? equity / margin * 100.0 : 1.0e9;
   double loadPct = (equity > 0.0 && margin > 0.0) ? margin / equity * 100.0 : 0.0;

   // A. Hard margin-load cap: never let used-margin / equity exceed the cap.
   if(loadPct > URF_MaxMarginLoadPct)
      scale = MathMin(scale, URF_BaseScale * URF_MaxMarginLoadPct / MathMax(loadPct, 0.01));

   // B. Hard margin-level floor: linearly throttle NEW exposure to zero only in a
   //    tight safety band just above the 300% floor. Inactive in normal operation;
   //    this is the no-liquidation guarantee, not a profit throttle.
   double floorBand = URF_MinMarginLevelPct * 1.10;
   if(level < floorBand)
   {
      double f = (level - URF_MinMarginLevelPct) / MathMax(floorBand - URF_MinMarginLevelPct, 0.01);
      scale = MathMin(scale, URF_BaseScale * MathMax(0.0, f));
   }

   if(scale > URF_BaseScale) scale = URF_BaseScale;
   if(scale < URF_MinScale)  scale = URF_MinScale;
   return scale;
}

//+------------------------------------------------------------------+
//| Count consecutive losing CLOSED EA trades, newest-first, within   |
//| a recent window. The streak ends at the first non-losing trade.   |
//+------------------------------------------------------------------+
int United_CBConsecutiveLosses(const int lookback)
{
   datetime from = TimeCurrent() - (datetime)60 * 86400; // 60-day history slice
   if(!HistorySelect(from, TimeCurrent())) return 0;
   int losses = 0, scanned = 0, total = HistoryDealsTotal();
   for(int i = total - 1; i >= 0 && scanned < lookback; i--)
   {
      ulong deal = HistoryDealGetTicket(i);
      if(deal == 0) continue;
      if(!United_IsKnownV4Magic((ulong)HistoryDealGetInteger(deal, DEAL_MAGIC))) continue;
      ENUM_DEAL_TYPE  ty = (ENUM_DEAL_TYPE)HistoryDealGetInteger(deal, DEAL_TYPE);
      if(ty != DEAL_TYPE_BUY && ty != DEAL_TYPE_SELL) continue;
      ENUM_DEAL_ENTRY en = (ENUM_DEAL_ENTRY)HistoryDealGetInteger(deal, DEAL_ENTRY);
      if(en != DEAL_ENTRY_OUT && en != DEAL_ENTRY_INOUT) continue;
      scanned++;
      double pl = HistoryDealGetDouble(deal, DEAL_PROFIT)
                + HistoryDealGetDouble(deal, DEAL_SWAP)
                + HistoryDealGetDouble(deal, DEAL_COMMISSION);
      if(pl < 0.0) losses++; else break;
   }
   return losses;
}

//+------------------------------------------------------------------+
//| Portfolio circuit breaker. When CB_Enable, trips ONLY when BOTH    |
//| the equity-DD threshold AND a consecutive-loss streak are met,     |
//| then flattens (optional) and starts a cooldown. Falls back to the  |
//| legacy single-condition PES when CB is off. Returns true on trip.  |
//+------------------------------------------------------------------+
bool United_PortfolioEquityStop()
{
   double equity = AccountInfoDouble(ACCOUNT_EQUITY);
   if(equity > g_EquityPeak) g_EquityPeak = equity;
   if(g_EquityPeak <= 0.0) return false;
   double ddFromPeak = (g_EquityPeak - equity) / g_EquityPeak * 100.0;
   if(ddFromPeak < 0.0) ddFromPeak = 0.0;

   bool trip = false; string reason = ""; int cooldown = PES_CooldownMin; bool flatten = true;
   if(CB_Enable)
   {
      if(ddFromPeak >= CB_LossThresholdPct)
      {
         int cl = United_CBConsecutiveLosses(CB_LossLookbackTrades);
         if(cl >= CB_ConsecutiveLosses)
         {
            trip = true; cooldown = CB_CooldownMin; flatten = CB_FlattenOnTrip;
            reason = StringFormat("DD=%.2f%%>=%.2f AND consecLosses=%d>=%d",
                                  ddFromPeak, CB_LossThresholdPct, cl, CB_ConsecutiveLosses);
         }
      }
   }
   else if(PES_Enable && ddFromPeak >= PES_TriggerDDPct)
   {
      trip = true; reason = StringFormat("DD=%.2f%%", ddFromPeak);
   }
   if(!trip) return false;

   if(flatten)
   {
      CTrade pesTrade;
      for(int i = PositionsTotal() - 1; i >= 0; i--)
      {
         ulong ticket = PositionGetTicket(i);
         if(ticket == 0 || !PositionSelectByTicket(ticket)) continue;
         if(!United_IsKnownV4Magic((ulong)PositionGetInteger(POSITION_MAGIC))) continue;
         pesTrade.PositionClose(ticket);
      }
   }
   g_EquityPeak = AccountInfoDouble(ACCOUNT_EQUITY);
   g_PESCooldownUntil = TimeCurrent() + (datetime)cooldown * 60;
   PrintFormat("[CIRCUIT BREAKER] TRIPPED: %s -> %s, cooldown %d min",
               reason, (flatten ? "FLATTEN all" : "hold positions"), cooldown);
   return true;
}

bool United_PortfolioEquityStopInCooldown()
{
   return ((CB_Enable || PES_Enable) && g_PESCooldownUntil > 0 && TimeCurrent() < g_PESCooldownUntil);
}

//+------------------------------------------------------------------+
//| Print a would-be entry as a VIRTUAL trade while the breaker is     |
//| paused (forensic visibility into what is being skipped). Rate-     |
//| limited by CB_VirtualLogThrottleSec.                              |
//+------------------------------------------------------------------+
void United_LogVirtualEntry(const string symbol, const ulong magic, const bool isBuy)
{
   if(!CB_Enable || !CB_LogVirtual) return;
   if(TimeCurrent() - g_CBLastVirtualLog < CB_VirtualLogThrottleSec) return;
   g_CBLastVirtualLog = TimeCurrent();
   double px = isBuy ? SymbolInfoDouble(symbol, SYMBOL_ASK) : SymbolInfoDouble(symbol, SYMBOL_BID);
   PrintFormat("[CB-VIRTUAL] would %s %s magic=%I64u @ %.5f (breaker paused, resumes %s)",
               (isBuy ? "BUY" : "SELL"), symbol, magic, px,
               TimeToString(g_PESCooldownUntil, TIME_DATE | TIME_MINUTES));
}

//+------------------------------------------------------------------+
//| Real-time per-position floating-loss guard: close any single EA    |
//| position whose floating loss exceeds a hard cap (% of equity or    |
//| absolute USD), preventing a fast adverse move from snowballing.    |
//+------------------------------------------------------------------+
void United_RealtimePositionGuard()
{
   if(!PM_Enable) return;
   double equity = AccountInfoDouble(ACCOUNT_EQUITY);
   double capPct = (PM_MaxPositionLossPct > 0.0 && equity > 0.0) ? equity * PM_MaxPositionLossPct / 100.0 : 0.0;
   if(capPct <= 0.0 && PM_MaxPositionLossUSD <= 0.0) return;
   CTrade pmTrade;
   for(int i = PositionsTotal() - 1; i >= 0; i--)
   {
      ulong ticket = PositionGetTicket(i);
      if(ticket == 0 || !PositionSelectByTicket(ticket)) continue;
      if(!United_IsKnownV4Magic((ulong)PositionGetInteger(POSITION_MAGIC))) continue;
      double fl = PositionGetDouble(POSITION_PROFIT) + PositionGetDouble(POSITION_SWAP);
      if(fl >= 0.0) continue;
      double loss = -fl;
      bool hit = (capPct > 0.0 && loss >= capPct) || (PM_MaxPositionLossUSD > 0.0 && loss >= PM_MaxPositionLossUSD);
      if(hit)
      {
         PrintFormat("[POSITION MONITOR] closing %s ticket %I64u: float loss %.2f (cap pct %.2f / usd %.2f)",
                     PositionGetString(POSITION_SYMBOL), ticket, loss, capPct, PM_MaxPositionLossUSD);
         pmTrade.PositionClose(ticket);
      }
   }
}

//+------------------------------------------------------------------+
//| Principal Guard scale: asymmetric capital protection. Returns a   |
//| [PG_MinScale .. 1.0] lot multiplier that throttles size ONLY      |
//| while equity is at/below the initial principal (no profit buffer  |
//| to spend); profit-zone trading (equity >= principal) is full size.|
//+------------------------------------------------------------------+
double United_PrincipalGuardScale()
{
   if(!PG_Enable || g_InitialDeposit <= 0.0) return 1.0;
   double top   = g_InitialDeposit * PG_DeriskTopMult;   // at/above this -> full size
   double floorv= g_InitialDeposit * PG_FloorMult;       // at/below this -> PG_MinScale
   if(top <= floorv) return 1.0;
   double equity = AccountInfoDouble(ACCOUNT_EQUITY);
   if(equity >= top)    return 1.0;
   if(equity <= floorv) return PG_MinScale;
   double f = (equity - floorv) / (top - floorv);        // 0..1
   return PG_MinScale + f * (1.0 - PG_MinScale);
}

//+------------------------------------------------------------------+
//| Principal Guard hard floor: block new entries (and optionally     |
//| flatten) when equity has fallen to the principal floor, so the    |
//| starting capital is defended even if every strategy is bleeding.  |
//+------------------------------------------------------------------+
bool United_PrincipalGuardBlocksEntry()
{
   if(!PG_Enable || !PG_HaltEntriesAtFloor || g_InitialDeposit <= 0.0) return false;
   double equity = AccountInfoDouble(ACCOUNT_EQUITY);
   if(equity > g_InitialDeposit * PG_FloorMult) return false;
   if(PG_FlattenAtFloor)
   {
      CTrade pgTrade;
      for(int i = PositionsTotal() - 1; i >= 0; i--)
      {
         ulong ticket = PositionGetTicket(i);
         if(ticket == 0 || !PositionSelectByTicket(ticket)) continue;
         if(!United_IsKnownV4Magic((ulong)PositionGetInteger(POSITION_MAGIC))) continue;
         pgTrade.PositionClose(ticket);
      }
   }
   return true;
}

//+------------------------------------------------------------------+
//| Session gate: is the symbol's trading session open right now?    |
//| Uses SymbolInfoSessionTrade for the current server weekday and   |
//| checks whether server time-of-day falls in any trade session.    |
//| Returns true when open (or when no session info is available, to |
//| avoid false negatives on 24h FX/metal/crypto).                   |
//+------------------------------------------------------------------+
bool United_MarketSessionOpen(const string symbol)
{
   datetime now = TimeCurrent();
   MqlDateTime t;
   TimeToStruct(now, t);
   ENUM_DAY_OF_WEEK dow = (ENUM_DAY_OF_WEEK)t.day_of_week;

   int secOfDay = t.hour * 3600 + t.min * 60 + t.sec;

   datetime from, to;
   bool anySession = false;
   for(int i = 0; i < 8; i++)
   {
      if(!SymbolInfoSessionTrade(symbol, dow, i, from, to))
         break;
      anySession = true;
      // session times are seconds-from-midnight encoded as datetime
      int fromSec = (int)from;
      int toSec   = (int)to;
      if(secOfDay >= fromSec && secOfDay < toSec)
         return true;
   }
   // No session data at all -> treat as open (24h instruments often report none).
   if(!anySession)
      return true;
   // Sessions exist but none contains 'now' -> closed.
   return false;
}

//+------------------------------------------------------------------+
//| News guard: block entries in a window around high-impact monthly |
//| USD events. Tester-safe date/time fallback (no live calendar):   |
//|  - NFP: first Friday of month at NFP release time                 |
//|  - CPI: ~NewsGuard_CPIDay at NFP release time                     |
//|  - FOMC: ~NewsGuard_FOMCDay at FOMC decision time                 |
//+------------------------------------------------------------------+
bool United_TimeWithinEvent(const MqlDateTime &t, const int evHour, const int evMin)
{
   int nowSec = t.hour * 3600 + t.min * 60 + t.sec;
   int evSec  = evHour * 3600 + evMin * 60;
   int before = NewsGuard_BeforeMin * 60;
   int after  = NewsGuard_AfterMin * 60;
   return (nowSec >= evSec - before && nowSec <= evSec + after);
}

bool United_NewsGuardBlocksEntry(const string symbol)
{
   if(!NewsGuard_Enable)
      return false;
   if(NewsGuard_SymbolContains != "" && !United_SymbolContainsAny(symbol, NewsGuard_SymbolContains))
      return false;

   MqlDateTime t;
   TimeToStruct(TimeCurrent(), t);

   // First Friday of the month -> NFP
   bool isFirstFriday = (t.day_of_week == 5 && t.day <= 7);
   if(isFirstFriday && United_TimeWithinEvent(t, NewsGuard_NFPHourUTC, NewsGuard_NFPMinUTC))
      return true;

   // CPI day (approx) -> same release time
   if(t.day == NewsGuard_CPIDay && United_TimeWithinEvent(t, NewsGuard_NFPHourUTC, NewsGuard_NFPMinUTC))
      return true;

   // FOMC day (approx) -> decision time
   if(t.day == NewsGuard_FOMCDay && United_TimeWithinEvent(t, NewsGuard_FOMCHourUTC, 0))
      return true;

   return false;
}

//+------------------------------------------------------------------+
//| Swap-aware close: near rollover, close marginal/positive EA      |
//| positions on symbols with a negative swap so we avoid paying     |
//| overnight cost. Strong winners are kept. Runs at most once per   |
//| day inside the configured server-time window.                    |
//+------------------------------------------------------------------+
void United_SwapAwareClose()
{
   if(!SwapClose_Enable)
      return;

   MqlDateTime t;
   TimeToStruct(TimeCurrent(), t);
   int nowSec   = t.hour * 3600 + t.min * 60;
   int startSec = SwapClose_StartHourSrv * 3600 + SwapClose_StartMinSrv * 60;
   // Active from start until end-of-day (rollover).
   if(nowSec < startSec)
      return;

   // Only run once per calendar day.
   static int s_lastSwapCloseDay = -1;
   if(s_lastSwapCloseDay == t.day_of_year)
      return;
   s_lastSwapCloseDay = t.day_of_year;

   CTrade swapTrade;
   for(int i = PositionsTotal() - 1; i >= 0; i--)
   {
      ulong ticket = PositionGetTicket(i);
      if(ticket == 0) continue;
      if(!PositionSelectByTicket(ticket)) continue;
      if(!United_IsKnownV4Magic((ulong)PositionGetInteger(POSITION_MAGIC))) continue;

      string psym = PositionGetString(POSITION_SYMBOL);
      double profit = PositionGetDouble(POSITION_PROFIT) + PositionGetDouble(POSITION_SWAP);

      // keep strong winners
      if(profit >= SwapClose_KeepProfitUSD)
         continue;

      if(SwapClose_OnlyNegativeSwap)
      {
         long ptype = PositionGetInteger(POSITION_TYPE);
         double swapRate = (ptype == POSITION_TYPE_BUY)
                           ? SymbolInfoDouble(psym, SYMBOL_SWAP_LONG)
                           : SymbolInfoDouble(psym, SYMBOL_SWAP_SHORT);
         if(swapRate >= 0.0)
            continue; // positive/zero swap -> no cost to hold
      }

      swapTrade.PositionClose(ticket);
   }
}

void DeinitSymbolRegimes()
{
   for(int i = 0; i < g_NumSymbolRegimes; i++)
   {
      if(g_SymbolRegimes[i].adxHandle != INVALID_HANDLE)
      {
         IndicatorRelease(g_SymbolRegimes[i].adxHandle);
         g_SymbolRegimes[i].adxHandle = INVALID_HANDLE;
      }
   }
   g_NumSymbolRegimes = 0;
}

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

double United_ScaledRiskLot(const double baseLot, const string symbol, const ulong magic)
{
   double lot = United_ScaledLot(baseLot) 
              * United_LotThrottleFactor(symbol, magic)
              * United_CachedPerfMultiplier(magic)
              * United_PrincipalGuardScale()
              * g_CachedMarginScale;
   return (lot > 0.0 ? lot : 0.0);
}

void United_RefreshScaledLots()
{
   g_DB_LotSize = United_ScaledRiskLot(LOT_DB_DarvasBox, s_DB_Symbol, (ulong)DB_MagicNumber);
   g_ES_LotSize = United_ScaledRiskLot(LOT_ES_EMASlopeDistance, s_ES_Symbol, (ulong)ES_MagicNumber);
   g_RC_LotSize = United_ScaledRiskLot(LOT_RC_RSICrossOver, s_RC_Symbol, (ulong)RC_MagicNumber);
   g_RM_LotSize = United_ScaledRiskLot(LOT_RM_RSIMidPointHijack, s_RM_Symbol, (ulong)RM_InpMagicNumberRSIFollow);
   g_Pos_RS_APPL = United_ScaledRiskLot(LOT_RS_APPL, s_RS_APPL, (ulong)RS_APPL_MagicNumber);
   g_Pos_RS_BTCUSD = United_ScaledRiskLot(LOT_RS_BTCUSD, s_RS_BTCUSD, (ulong)RS_BTCUSD_MagicNumber);
   g_Pos_RS_NVDA = United_ScaledRiskLot(LOT_RS_NVDA, s_RS_NVDA, (ulong)RS_NVDA_MagicNumber);
   g_Pos_RS_TSLA = United_ScaledRiskLot(LOT_RS_TSLA, s_RS_TSLA, (ulong)RS_TSLA_MagicNumber);
   g_Pos_RS_XAUUSD = United_ScaledRiskLot(LOT_RS_XAUUSD, s_RS_XAUUSD, (ulong)RS_XAUUSD_MagicNumber);
   g_Pos_RS_MU = United_ScaledRiskLot(LOT_RS_MU, s_RS_MU, (ulong)RS_MU_MagicNumber);
   g_Pos_RRA_EURUSD = United_ScaledRiskLot(LOT_RRA_EURUSD, s_RRA_EURUSD, (ulong)RRA_EURUSD_MagicNumber);
   g_Pos_RRA_AUDUSD = United_ScaledRiskLot(LOT_RRA_AUDUSD, s_RRA_AUDUSD, (ulong)RRA_AUDUSD_MagicNumber);
   g_Pos_SE = United_ScaledRiskLot(LOT_SE_SuperEMA, s_SE_Symbol, (ulong)SE_MagicNumber);
   g_Pos_RCO = United_ScaledRiskLot(LOT_RCO_RSIConsolidation, s_RCO_Symbol, (ulong)RCO_MagicNumber);
   g_Pos_ST_BTCUSD = United_ScaledRiskLot(LOT_ST_BTCUSD, s_ST_BTC_Symbol, (ulong)ST_BTC_MagicNumber);
   g_Pos_ST_XAUUSD = United_ScaledRiskLot(LOT_ST_XAUUSD, s_ST_XAU_Symbol, (ulong)ST_XAU_MagicNumber);
   g_Pos_ST_GER40 = United_ScaledRiskLot(LOT_ST_GER40, s_ST_GER_Symbol, (ulong)ST_GER_MagicNumber);
   g_RSS_LotSize = United_ScaledRiskLot(LOT_RSS_SecretSauce, s_RSS_Symbol, (ulong)RSS_MagicNumber);
   g_WP_LotSize = United_ScaledRiskLot(LOT_WP_WilliamsPassivation, s_WP_Symbol, (ulong)WP_MagicNumber);
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
   int ltfConfirmRsiHandle;
   int emaHandle;
   bool rsiOverbought;
   bool rsiOversold;
   int rsiOverboughtAgeBars;
   int rsiOversoldAgeBars;
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
RSIScalpingData rsMUData;
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

   // Seed the URF equity high-water mark with the starting equity/balance.
   g_EquityPeak = MathMax(AccountInfoDouble(ACCOUNT_EQUITY), AccountInfoDouble(ACCOUNT_BALANCE));

   // Capture the starting principal for the asymmetric Principal Guard
   // (protect capital, tolerate profit drawdown).
   g_InitialDeposit = (PG_PrincipalUSD > 0.0) ? PG_PrincipalUSD : AccountInfoDouble(ACCOUNT_BALANCE);
   if(g_InitialDeposit <= 0.0) g_InitialDeposit = AccountInfoDouble(ACCOUNT_EQUITY);

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
   s_RS_MU         = SymbolMapper.GetTerminalSymbol(RS_MU_Symbol);
   s_RRA_EURUSD    = SymbolMapper.GetTerminalSymbol(RRA_EURUSD_Symbol);
   s_RRA_AUDUSD    = SymbolMapper.GetTerminalSymbol(RRA_AUDUSD_Symbol);
   s_SE_Symbol     = SymbolMapper.GetTerminalSymbol(SE_Symbol);
   s_RCO_Symbol    = SymbolMapper.GetTerminalSymbol(RCO_Symbol);
   s_ST_BTC_Symbol = SymbolMapper.GetTerminalSymbol(ST_BTC_Symbol);
   s_ST_XAU_Symbol = SymbolMapper.GetTerminalSymbol(ST_XAU_Symbol);
   s_ST_GER_Symbol = SymbolMapper.GetTerminalSymbol(ST_GER_Symbol);
   s_RSS_Symbol    = SymbolMapper.GetTerminalSymbol(RSS_Symbol);
   s_WP_Symbol     = SymbolMapper.GetTerminalSymbol(WP_Symbol);

   // Handle multi-symbol splitting for Williams Passivation strategy
   string raw_symbols[];
   wp_symbol_count = StringSplit(WP_Symbol, ';', raw_symbols);
   if(wp_symbol_count <= 0)
   {
      wp_symbol_count = 1;
      ArrayResize(raw_symbols, 1);
      raw_symbols[0] = WP_Symbol;
   }
   
   ArrayResize(wpDataArray, wp_symbol_count);
   ArrayResize(s_WP_Symbols, wp_symbol_count);
   
   for(int i = 0; i < wp_symbol_count; i++)
   {
      StringTrimLeft(raw_symbols[i]);
      StringTrimRight(raw_symbols[i]);
      s_WP_Symbols[i] = SymbolMapper.GetTerminalSymbol(raw_symbols[i]);
   }

   PrintFormat("[V4] Broker: %s | mapped DB=%s ES=%s RC=%s RM=%s", AccountInfoString(ACCOUNT_COMPANY), s_DB_Symbol, s_ES_Symbol, s_RC_Symbol, s_RM_Symbol);
   PrintFormat("[V4] mapped RS_AAPL=%s BTC=%s NVDA=%s TSLA=%s XAU=%s", s_RS_APPL, s_RS_BTCUSD, s_RS_NVDA, s_RS_TSLA, s_RS_XAUUSD);
   PrintFormat("[V4] mapped RRA_EUR=%s RRA_AUD=%s SE=%s RCO=%s RSS=%s", s_RRA_EURUSD, s_RRA_AUDUSD, s_SE_Symbol, s_RCO_Symbol, s_RSS_Symbol);
   PrintFormat("[V4] mapped ST_BTC=%s ST_XAU=%s ST_GER=%s", s_ST_BTC_Symbol, s_ST_XAU_Symbol, s_ST_GER_Symbol);
   PrintFormat("[V4] mapped WP_Symbol=%s (count=%d)", WP_Symbol, wp_symbol_count);

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

   if(EnableRSIScalpingMU) // Scalping / Choppy
      InitRSIScalping(rsMUData, s_RS_MU, RS_MU_TimeFrame, RS_MU_RSI_Period, RS_MU_RSI_Applied_Price, RS_MU_MagicNumber, RS_MU_Slippage);

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
   
   if(EnableWilliamsPassivation)
   {
      for(int i = 0; i < wp_symbol_count; i++)
      {
         double atr_min=0.0; double sl=0.0; double tp=0.0; double trail_dist=0.0; double trail_act=0.0; double lot_scale=1.0;
         GetSymbolParameters(s_WP_Symbols[i], atr_min, sl, tp, trail_dist, trail_act, lot_scale);
         
         ulong magic = WP_MagicNumber + i;
         
         if(!InitWilliamsPassivation(wpDataArray[i], s_WP_Symbols[i], WP_Timeframe, WP_WPR_Period, WP_BB_Period, WP_BB_Deviation, WP_BB_AppliedPrice, WP_EMA_D1_Period, WP_EMA_D1_AppliedPrice, WP_Filter_ATR_Enable, WP_Filter_ATR_Period, (int)magic, WP_Slippage))
            Print("Warning: WilliamsPassivation strategy failed to initialize for symbol '", s_WP_Symbols[i], "'");
      }
   }
   
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
         (EnableSimpleTrendlineGER40 ? "SimpleTrendlineGER40 " : ""),
         (EnableWilliamsPassivation ? "WilliamsPassivation " : ""));
   
   return initResult;
}

//+------------------------------------------------------------------+
//| Expert deinitialization function                                 |
//+------------------------------------------------------------------+
/* void OnDeinit_Corrupted(const int reason)
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
      ProcessRSIMidPointHijack(s_RM_Symbol);

   if(EnableRSIScalpingAPPL) // Scalping / Choppy
      ProcessRSIScalping(rsAPPLData, s_RS_APPL, RS_APPL_TimeFrame, RS_APPL_RSI_Period, RS_APPL_RSI_Applied_Price,
                        RS_APPL_RSI_Overbought, RS_APPL_RSI_Oversold, RS_APPL_RSI_Target_Buy, RS_APPL_RSI_Target_Sell,
                        RS_APPL_BarsToWait, g_Pos_RS_APPL, RS_APPL_MagicNumber,
                        RS_RequireOrderedBands,
                        RS_UseClosedBarExit,
                        (RS_UseReversalEscape && RS_UseReversalEscapeAllSymbols), RS_ReversalATRPeriod, RS_ReversalAdverseAtrMult, RS_ReversalSignsRequired,
                        RS_ReversalRsiVelocity, RS_ReversalBodyAtrMult,
                        RS_APPL_UseTrailingStop, RS_APPL_TrailDistancePoints, RS_APPL_TrailActivationPoints);

   if(EnableRSIScalpingBTCUSD) // Scalping / Choppy
      ProcessRSIScalping(rsBTCUSDData, s_RS_BTCUSD, RS_BTCUSD_TimeFrame, RS_BTCUSD_RSI_Period, RS_BTCUSD_RSI_Applied_Price,
                        RS_BTCUSD_RSI_Overbought, RS_BTCUSD_RSI_Oversold, RS_BTCUSD_RSI_Target_Buy, RS_BTCUSD_RSI_Target_Sell,
                        RS_BTCUSD_BarsToWait, g_Pos_RS_BTCUSD, RS_BTCUSD_MagicNumber,
                        RS_RequireOrderedBands,
                        RS_UseClosedBarExit,
                        (RS_UseReversalEscape && RS_UseReversalEscapeAllSymbols), RS_ReversalATRPeriod, RS_ReversalAdverseAtrMult, RS_ReversalSignsRequired,
                        RS_ReversalRsiVelocity, RS_ReversalBodyAtrMult,
                        RS_BTCUSD_UseTrailingStop, RS_BTCUSD_TrailDistancePoints, RS_BTCUSD_TrailActivationPoints);

   if(EnableRSIScalpingNVDA) // Scalping / Choppy
      ProcessRSIScalping(rsNVDAData, s_RS_NVDA, RS_NVDA_TimeFrame, RS_NVDA_RSI_Period, RS_NVDA_RSI_Applied_Price,
                        RS_NVDA_RSI_Overbought, RS_NVDA_RSI_Oversold, RS_NVDA_RSI_Target_Buy, RS_NVDA_RSI_Target_Sell,
                        RS_NVDA_BarsToWait, g_Pos_RS_NVDA, RS_NVDA_MagicNumber,
                        RS_RequireOrderedBands,
                        RS_UseClosedBarExit,
                        (RS_UseReversalEscape && RS_UseReversalEscapeAllSymbols), RS_ReversalATRPeriod, RS_ReversalAdverseAtrMult, RS_ReversalSignsRequired,
                        RS_ReversalRsiVelocity, RS_ReversalBodyAtrMult,
                        RS_NVDA_UseTrailingStop, RS_NVDA_TrailDistancePoints, RS_NVDA_TrailActivationPoints);

   if(EnableRSIScalpingTSLA) // Scalping / Choppy
      ProcessRSIScalping(rsTSLAData, s_RS_TSLA, RS_TSLA_TimeFrame, RS_TSLA_RSI_Period, RS_TSLA_RSI_Applied_Price,
                        RS_TSLA_RSI_Overbought, RS_TSLA_RSI_Oversold, RS_TSLA_RSI_Target_Buy, RS_TSLA_RSI_Target_Sell,
                        RS_TSLA_BarsToWait, g_Pos_RS_TSLA, RS_TSLA_MagicNumber,
                        RS_RequireOrderedBands,
                        RS_UseClosedBarExit,
                        (RS_UseReversalEscape && RS_UseReversalEscapeAllSymbols), RS_ReversalATRPeriod, RS_ReversalAdverseAtrMult, RS_ReversalSignsRequired,
                        RS_ReversalRsiVelocity, RS_ReversalBodyAtrMult,
                        RS_TSLA_UseTrailingStop, RS_TSLA_TrailDistancePoints, RS_TSLA_TrailActivationPoints);

   if(EnableRSIScalpingXAUUSD) // Scalping / Choppy
      ProcessRSIScalping(rsXAUUSDData, s_RS_XAUUSD, RS_XAUUSD_TimeFrame, RS_XAUUSD_RSI_Period, RS_XAUUSD_RSI_Applied_Price,
                        RS_XAUUSD_RSI_Overbought, RS_XAUUSD_RSI_Oversold, RS_XAUUSD_RSI_Target_Buy, RS_XAUUSD_RSI_Target_Sell,
                        RS_XAUUSD_BarsToWait, g_Pos_RS_XAUUSD, RS_XAUUSD_MagicNumber,
                        RS_RequireOrderedBands,
                        RS_UseClosedBarExit,
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

   if(EnableWilliamsPassivation)
   {
      for(int i = 0; i < wp_symbol_count; i++)
      {
         double atr_min = WP_Filter_ATR_MinPoints;
         double sl = WP_StopLossPoints;
         double tp = WP_TakeProfitPoints;
         double trail_dist = WP_TrailDistancePoints;
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
   
   if(EnableWilliamsPassivation)
   {
      for(int i = 0; i < wp_symbol_count; i++)
      {
         double atr_min=0.0; double sl=0.0; double tp=0.0; double trail_dist=0.0; double trail_act=0.0; double lot_scale=1.0;
         GetSymbolParameters(s_WP_Symbols[i], atr_min, sl, tp, trail_dist, trail_act, lot_scale);
         
         ulong magic = WP_MagicNumber + i;
         
         if(!InitWilliamsPassivation(wpDataArray[i], s_WP_Symbols[i], WP_Timeframe, WP_WPR_Period, WP_BB_Period, WP_BB_Deviation, WP_BB_AppliedPrice, WP_EMA_D1_Period, WP_EMA_D1_AppliedPrice, WP_Filter_ATR_Enable, WP_Filter_ATR_Period, (int)magic, WP_Slippage))
            Print("Warning: WilliamsPassivation strategy failed to initialize for symbol '", s_WP_Symbols[i], "'");
      }
   }
   
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
         (EnableSimpleTrendlineGER40 ? "SimpleTrendlineGER40 " : ""),
         (EnableWilliamsPassivation ? "WilliamsPassivation " : ""));
   
   return initResult;
} */

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

   if(EnableRSIScalpingMU)
      DeinitRSIScalping(rsMUData);

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

   if(EnableWilliamsPassivation)
   {
      for(int i = 0; i < wp_symbol_count; i++)
         DeinitWilliamsPassivation(wpDataArray[i]);
   }
   
   DeinitSymbolRegimes();

   Print("United EA deinitialized. Reason: ", reason);
}

//+------------------------------------------------------------------+
//| Expert tick function                                             |
//+------------------------------------------------------------------+
void OnTick()
{
   // Refresh cached values (margin scale per tick, perf multipliers hourly)
   g_CachedMarginScale = URF_Enable ? United_RiskFacadeScale() : United_DynamicMarginScale();

   // Portfolio circuit breaker: dual-condition flatten + cooldown.
   United_PortfolioEquityStop();

   // Real-time per-position floating-loss guard.
   United_RealtimePositionGuard();

   // Regime quick-exit: cap counter-trend runaways (opt-in, default off).
   United_RegimeQuickExit();

   // Virtual Recovery Probe: resolve shadow trades + resume real trading on recovery.
   United_VirtualRecoveryManage();

   // Swap-aware close near rollover (off by default).
   United_SwapAwareClose();
   United_RefreshPerformanceCache();
   United_RefreshScaledLots();

   if(EnableRSIScalpingMU) // Scalping / Choppy (Micron MU.NAS)
      ProcessRSIScalping(rsMUData, s_RS_MU, RS_MU_TimeFrame, RS_MU_RSI_Period, RS_MU_RSI_Applied_Price,
                        RS_MU_RSI_Overbought, RS_MU_RSI_Oversold, RS_MU_RSI_Target_Buy, RS_MU_RSI_Target_Sell,
                        RS_MU_BarsToWait, g_Pos_RS_MU, RS_MU_MagicNumber,
                        RS_RequireOrderedBands,
                        RS_UseClosedBarExit,
                        (RS_UseReversalEscape && RS_UseReversalEscapeAllSymbols), RS_ReversalATRPeriod, RS_ReversalAdverseAtrMult, RS_ReversalSignsRequired,
                        RS_ReversalRsiVelocity, RS_ReversalBodyAtrMult,
                        RS_MU_UseTrailingStop, RS_MU_TrailDistancePoints, RS_MU_TrailActivationPoints);

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
                        RS_RequireOrderedBands,
                        RS_UseClosedBarExit,
                        (RS_UseReversalEscape && RS_UseReversalEscapeAllSymbols), RS_ReversalATRPeriod, RS_ReversalAdverseAtrMult, RS_ReversalSignsRequired,
                        RS_ReversalRsiVelocity, RS_ReversalBodyAtrMult,
                        RS_APPL_UseTrailingStop, RS_APPL_TrailDistancePoints, RS_APPL_TrailActivationPoints);

   if(EnableRSIScalpingBTCUSD) // Scalping / Choppy
      ProcessRSIScalping(rsBTCUSDData, s_RS_BTCUSD, RS_BTCUSD_TimeFrame, RS_BTCUSD_RSI_Period, RS_BTCUSD_RSI_Applied_Price,
                        RS_BTCUSD_RSI_Overbought, RS_BTCUSD_RSI_Oversold, RS_BTCUSD_RSI_Target_Buy, RS_BTCUSD_RSI_Target_Sell,
                        RS_BTCUSD_BarsToWait, g_Pos_RS_BTCUSD, RS_BTCUSD_MagicNumber,
                        RS_RequireOrderedBands,
                        RS_UseClosedBarExit,
                        (RS_UseReversalEscape && RS_UseReversalEscapeAllSymbols), RS_ReversalATRPeriod, RS_ReversalAdverseAtrMult, RS_ReversalSignsRequired,
                        RS_ReversalRsiVelocity, RS_ReversalBodyAtrMult,
                        RS_BTCUSD_UseTrailingStop, RS_BTCUSD_TrailDistancePoints, RS_BTCUSD_TrailActivationPoints);

   if(EnableRSIScalpingNVDA) // Scalping / Choppy
      ProcessRSIScalping(rsNVDAData, s_RS_NVDA, RS_NVDA_TimeFrame, RS_NVDA_RSI_Period, RS_NVDA_RSI_Applied_Price,
                        RS_NVDA_RSI_Overbought, RS_NVDA_RSI_Oversold, RS_NVDA_RSI_Target_Buy, RS_NVDA_RSI_Target_Sell,
                        RS_NVDA_BarsToWait, g_Pos_RS_NVDA, RS_NVDA_MagicNumber,
                        RS_RequireOrderedBands,
                        RS_UseClosedBarExit,
                        (RS_UseReversalEscape && RS_UseReversalEscapeAllSymbols), RS_ReversalATRPeriod, RS_ReversalAdverseAtrMult, RS_ReversalSignsRequired,
                        RS_ReversalRsiVelocity, RS_ReversalBodyAtrMult,
                        RS_NVDA_UseTrailingStop, RS_NVDA_TrailDistancePoints, RS_NVDA_TrailActivationPoints);

   if(EnableRSIScalpingTSLA) // Scalping / Choppy
      ProcessRSIScalping(rsTSLAData, s_RS_TSLA, RS_TSLA_TimeFrame, RS_TSLA_RSI_Period, RS_TSLA_RSI_Applied_Price,
                        RS_TSLA_RSI_Overbought, RS_TSLA_RSI_Oversold, RS_TSLA_RSI_Target_Buy, RS_TSLA_RSI_Target_Sell,
                        RS_TSLA_BarsToWait, g_Pos_RS_TSLA, RS_TSLA_MagicNumber,
                        RS_RequireOrderedBands,
                        RS_UseClosedBarExit,
                        (RS_UseReversalEscape && RS_UseReversalEscapeAllSymbols), RS_ReversalATRPeriod, RS_ReversalAdverseAtrMult, RS_ReversalSignsRequired,
                        RS_ReversalRsiVelocity, RS_ReversalBodyAtrMult,
                        RS_TSLA_UseTrailingStop, RS_TSLA_TrailDistancePoints, RS_TSLA_TrailActivationPoints);

   if(EnableRSIScalpingXAUUSD) // Scalping / Choppy
      ProcessRSIScalping(rsXAUUSDData, s_RS_XAUUSD, RS_XAUUSD_TimeFrame, RS_XAUUSD_RSI_Period, RS_XAUUSD_RSI_Applied_Price,
                        RS_XAUUSD_RSI_Overbought, RS_XAUUSD_RSI_Oversold, RS_XAUUSD_RSI_Target_Buy, RS_XAUUSD_RSI_Target_Sell,
                        RS_XAUUSD_BarsToWait, g_Pos_RS_XAUUSD, RS_XAUUSD_MagicNumber,
                        RS_RequireOrderedBands,
                        RS_UseClosedBarExit,
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

   if(EnableWilliamsPassivation)
   {
      for(int i = 0; i < wp_symbol_count; i++)
      {
         double atr_min = WP_Filter_ATR_MinPoints;
         double sl = WP_StopLossPoints;
         double tp = WP_TakeProfitPoints;
         double trail_dist = WP_TrailDistancePoints;
         double trail_act = WP_TrailActivationPoints;
         double lot_scale = 1.0;
         
         GetSymbolParameters(s_WP_Symbols[i], atr_min, sl, tp, trail_dist, trail_act, lot_scale);
         
         ulong magic = WP_MagicNumber + i;
         double base_lot = g_WP_LotSize * lot_scale;
         
         ProcessWilliamsPassivation(wpDataArray[i], s_WP_Symbols[i], WP_Timeframe, WP_WPR_Period, WP_PassivationBars, WP_OverboughtLevel, WP_OversoldLevel,
                                    WP_BB_Period, WP_BB_Deviation, WP_BB_AppliedPrice, WP_EMA_D1_Period, WP_EMA_D1_AppliedPrice,
                                    WP_Filter_D1_EMA_Slope, WP_Filter_D1_EMA_Price,
                                    WP_Filter_ATR_Enable, WP_Filter_ATR_Period, atr_min,
                                    base_lot, (int)magic, WP_Slippage, WP_MaxSpreadPoints,
                                    WP_UseTrailingStop, trail_dist, trail_act,
                                    WP_ExitOnPassivationEnd, sl, tp);
      }
   }
}

//+------------------------------------------------------------------+
