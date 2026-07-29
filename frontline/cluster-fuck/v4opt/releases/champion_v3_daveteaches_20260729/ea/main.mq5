//+------------------------------------------------------------------+
//|                                                    DaveTeachesEA |
//|               V3 = Dave Teaches price-action methodology          |
//|               D1 -> H4 -> H1 -> M15 top-down, liquidity sweeps,   |
//|               retracement entries, candle/swing/EMA trailing.     |
//+------------------------------------------------------------------+
#property copyright "Copyright 2026"
#property link      ""
#property version   "3.00"
#property strict

#include <Trade\Trade.mqh>
#include "BrokerSymbolMapper.mqh"
#include "MagicNumberHelpers.mqh"
#include "DaveTeachesCore.mqh"
#include "DaveTeachesEntries.mqh"
#include "DaveTeachesStops.mqh"
#include "DaveTeachesRisk.mqh"

//+------------------------------------------------------------------+
//| Inputs                                                             |
//+------------------------------------------------------------------+
input group "=== Symbol & Session ==="
input string DT_Symbol = "EURUSD";
input bool   DT_AvoidNYFirstHour = true;
input int    DT_MaxSpreadPoints = 30;

input group "=== Risk Management ==="
input double DT_RiskPerTradePct = 2.0;        // 1-2% conservative; Dave used 3-5%
input double DT_DailyLossLimitPct = 5.0;      // 0 = disabled
input double DT_AccountStageUSD = 0.0;        // 0 = disabled; else min equity stage
input double DT_MaxMarginLoadPct = 10.0;      // broker-aware cap for one new position
input double DT_MaxPositionLossPct = 2.0;     // emergency floating-loss cap per position
input double DT_MaxEquityDrawdownPct = 10.0;  // emergency account high-water cap

input group "=== Entry Models ==="
input bool   DT_EnableRetracementEntry = true;
input bool   DT_EnableKLineEntry = true;
input bool   DT_RequireM1BreakRetest = true;
input int    DT_TrendLookback = 20;
input int    DT_MinStructurePivots = 3;
input int    DT_SweepLookback = 30;
input double DT_RetraceLevel = 0.50;          // 0.30 / 0.50 / 0.70
input int    DT_KLineSequenceBars = 3;
input double DT_RiskReward = 2.0;             // target = entry +/- R*SL
input double DT_SLBufferPoints = 50.0;        // extra buffer beyond structural extreme

input group "=== Trailing Stop ==="
input ENUM_DT_TRAIL_MODE DT_TrailMode = DT_TRAIL_CANDLE;
input int    DT_CandleTrailLookback = 1;
input int    DT_SwingTrailLookback = 20;

input group "=== Execution ==="
input int    DT_MagicNumber = 300000;
input int    DT_Slippage = 10;
input int    DT_MinBarsBetweenTrades = 3;

//+------------------------------------------------------------------+
//| Global state                                                       |
//+------------------------------------------------------------------+
string g_symbol = "";
CTrade   g_trade;
datetime g_lastBarTime = 0;
datetime g_lastTradeTime = 0;
int      g_lastTradeBarCount = 0;
double   g_equityPeak = 0.0;

//+------------------------------------------------------------------+
//| Expert initialization                                              |
//+------------------------------------------------------------------+
int OnInit()
{
   g_symbol = SymbolMapper.GetTerminalSymbol(DT_Symbol);
   if(g_symbol == "")
   {
      Print("DaveTeachesEA: symbol mapping failed for ", DT_Symbol);
      return INIT_FAILED;
   }

   if(!SymbolSelect(g_symbol, true))
   {
      Print("DaveTeachesEA: symbol not available in Market Watch: ", g_symbol);
      return INIT_FAILED;
   }

   g_trade.SetExpertMagicNumber(DT_MagicNumber);
   g_trade.SetDeviationInPoints(DT_Slippage);
   g_trade.SetTypeFilling(ORDER_FILLING_IOC);
   g_trade.SetAsyncMode(false);
   g_equityPeak = AccountInfoDouble(ACCOUNT_EQUITY);

   Print("DaveTeachesEA initialized on ", g_symbol);
   return INIT_SUCCEEDED;
}

//+------------------------------------------------------------------+
//| Expert deinitialization                                            |
//+------------------------------------------------------------------+
void OnDeinit(const int reason)
{
   Print("DaveTeachesEA deinitialized. Reason: ", reason);
}

//+------------------------------------------------------------------+
//| Position management                                                |
//+------------------------------------------------------------------+
bool DT_HasOpenPosition()
{
   return PositionExistsByMagic(g_symbol, DT_MagicNumber);
}

void DT_CloseAll(const string reason)
{
   ulong ticket = GetPositionTicketByMagic(g_symbol, DT_MagicNumber);
   if(ticket > 0)
   {
      g_trade.PositionClose(ticket);
      Print("DaveTeachesEA close: ", reason, " ticket=", ticket);
   }
}

bool DT_EmergencyProtection(const ulong ticket)
{
   if(!PositionSelectByTicket(ticket))
      return false;

   double equity = AccountInfoDouble(ACCOUNT_EQUITY);
   if(equity > g_equityPeak)
      g_equityPeak = equity;

   double balance = AccountInfoDouble(ACCOUNT_BALANCE);
   double floating = PositionGetDouble(POSITION_PROFIT) + PositionGetDouble(POSITION_SWAP);
   bool positionBreach = DT_MaxPositionLossPct > 0.0 && balance > 0.0
                         && floating <= -balance * DT_MaxPositionLossPct / 100.0;
   bool accountBreach = DT_MaxEquityDrawdownPct > 0.0 && g_equityPeak > 0.0
                        && equity <= g_equityPeak * (1.0 - DT_MaxEquityDrawdownPct / 100.0);
   if(!positionBreach && !accountBreach)
      return false;

   if(accountBreach)
      DT_CloseAll("equity drawdown emergency");
   else
      g_trade.PositionClose(ticket);
   PrintFormat("DaveTeachesEA emergency exit: position=%s account=%s equity=%.2f peak=%.2f floating=%.2f",
               positionBreach ? "true" : "false", accountBreach ? "true" : "false",
               equity, g_equityPeak, floating);
   return true;
}

//+------------------------------------------------------------------+
//| Open a new position                                                |
//+------------------------------------------------------------------+
bool DT_OpenPosition(const DT_EntrySignal &sig)
{
   if(sig.signal == DT_ENTRY_NONE)
      return false;
   if(DT_HasOpenPosition())
      return false;
   if(DT_DailyLossLimitHit(DT_DailyLossLimitPct))
   {
      Print("DaveTeachesEA: daily loss limit hit, no new entries");
      return false;
   }
   if(DT_AccountStageUSD > 0.0 && DT_AccountStageMultiplier(DT_AccountStageUSD) <= 0.0)
   {
      Print("DaveTeachesEA: account below minimum stage");
      return false;
   }

   double lots = DT_RiskBasedLotSize(g_symbol, DT_RiskPerTradePct,
                                     sig.entryPrice, sig.stopLoss);
   lots = DT_MarginCappedLot(g_symbol, lots, DT_MaxMarginLoadPct);
   if(lots <= 0.0)
   {
      Print("DaveTeachesEA: lot size zero (SL too close?)");
      return false;
   }

   double price = (sig.signal == DT_ENTRY_BUY) ? SymbolInfoDouble(g_symbol, SYMBOL_ASK)
                                               : SymbolInfoDouble(g_symbol, SYMBOL_BID);

   bool ok = false;
   if(sig.signal == DT_ENTRY_BUY)
      ok = g_trade.Buy(lots, g_symbol, price, sig.stopLoss, sig.takeProfit, sig.reason);
   else
      ok = g_trade.Sell(lots, g_symbol, price, sig.stopLoss, sig.takeProfit, sig.reason);

   if(ok)
   {
      g_lastTradeTime = TimeCurrent();
      g_lastTradeBarCount = 0;
      PrintFormat("DaveTeachesEA OPEN %s lots=%.2f entry=%.5f sl=%.5f tp=%.5f reason=%s",
                  (sig.signal == DT_ENTRY_BUY ? "BUY" : "SELL"), lots, price,
                  sig.stopLoss, sig.takeProfit, sig.reason);
   }
   else
   {
      PrintFormat("DaveTeachesEA OPEN FAILED %s lots=%.2f retcode=%d",
                  (sig.signal == DT_ENTRY_BUY ? "BUY" : "SELL"), lots, g_trade.ResultRetcode());
   }
   return ok;
}

//+------------------------------------------------------------------+
//| OnTick                                                             |
//+------------------------------------------------------------------+
void OnTick()
{
   if(g_symbol == "")
      return;

   // Session / spread filters
   if(DT_AvoidNYFirstHour && DT_ShouldAvoidNYFirstHour(true, TimeCurrent()))
      return;
   if(DT_SpreadTooHigh(g_symbol, DT_MaxSpreadPoints))
      return;

   // Bar control: re-evaluate structure on new M15 bar
   datetime currentBarTime = iTime(g_symbol, PERIOD_M15, 0);
   if(currentBarTime == 0)
      return;
   bool newBar = (currentBarTime != g_lastBarTime);
   if(newBar)
   {
      g_lastBarTime = currentBarTime;
      g_lastTradeBarCount++;
   }

   // Manage existing position: trailing stop every tick, bar-independent
   if(DT_HasOpenPosition())
   {
      ulong ticket = GetPositionTicketByMagic(g_symbol, DT_MagicNumber);
      if(ticket > 0)
      {
         if(DT_EmergencyProtection(ticket))
            return;
         DT_ApplyTrailingStop(ticket, DT_TrailMode,
                              DT_CandleTrailLookback, DT_SwingTrailLookback,
                              true);
      }
      return; // one position at a time
   }

   // Entry logic only on new bar and after cooldown
   if(!newBar)
      return;
   if(g_lastTradeBarCount > 0 && g_lastTradeBarCount < DT_MinBarsBetweenTrades)
      return;

   // Analyze multi-timeframe structure
   DT_Structure structure = DT_AnalyzeStructure(g_symbol, DT_TrendLookback,
                                                 DT_MinStructurePivots, DT_SweepLookback);
   if(!structure.valid)
   {
      if(GetLastError() != ERR_SUCCESS)
         ResetLastError();
      return;
   }

   // Get entry signal
   DT_EntrySignal sig = DT_GetEntrySignal(g_symbol, structure,
                                          DT_EnableRetracementEntry,
                                          DT_EnableKLineEntry,
                                          DT_RequireM1BreakRetest,
                                          DT_RetraceLevel,
                                          DT_KLineSequenceBars,
                                          DT_RiskReward,
                                          DT_SLBufferPoints);

   if(sig.signal != DT_ENTRY_NONE)
   {
      DT_OpenPosition(sig);
   }
}
