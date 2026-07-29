//+------------------------------------------------------------------+
//|                                   WilliamsPassivationStrategy.mqh |
//|                                  Copyright 2026, MetaQuotes Ltd. |
//+------------------------------------------------------------------+

//+------------------------------------------------------------------+
//| Williams %R Passivation Strategy Data Structure                  |
//+------------------------------------------------------------------+
struct WilliamsPassivationData {
   string symbol;
   bool isInitialized;
   CTrade trade;
   int wpr_handle;
   int bb_handle;
   int ema_handle;
   int atr_handle;
   bool position_open;
   ulong position_ticket;
   ENUM_POSITION_TYPE current_position_type;
   datetime last_bar_time;
};

//+------------------------------------------------------------------+
//| Get custom parameters for specific symbols (multi-symbol support)|
//+------------------------------------------------------------------+
void GetSymbolParameters(string sym, double &atr_min, double &sl, double &tp, double &trail_dist, double &trail_act, double &lot_scale)
{
   // Default values (EURUSD defaults)
   atr_min = 150.0;
   sl = 500.0;
   tp = 1000.0;
   trail_dist = 300.0;
   trail_act = 200.0;
   lot_scale = 1.0;
   
   string clean_sym = sym;
   StringToUpper(clean_sym);
   
   // Strip suffix (e.g. AAPL.NAS -> AAPL)
   int dot_idx = StringFind(clean_sym, ".");
   if(dot_idx > 0)
      clean_sym = StringSubstr(clean_sym, 0, dot_idx);
      
   if(clean_sym == "EURUSD") {
      atr_min = 150.0; sl = 500.0; tp = 1000.0; trail_dist = 300.0; trail_act = 200.0; lot_scale = 0.6;
   }
   else if(clean_sym == "AUDUSD") {
      atr_min = 120.0; sl = 400.0; tp = 800.0; trail_dist = 240.0; trail_act = 160.0; lot_scale = 0.6;
   }
   else if(clean_sym == "XAUUSD" || clean_sym == "GOLD") {
      atr_min = 300.0; sl = 1500.0; tp = 3000.0; trail_dist = 750.0; trail_act = 500.0; lot_scale = 0.1;
   }
   else if(clean_sym == "BTCUSD") {
      atr_min = 15000.0; sl = 50000.0; tp = 100000.0; trail_dist = 30000.0; trail_act = 20000.0; lot_scale = 0.1;
   }
   else if(clean_sym == "AAPL") {
      atr_min = 50.0; sl = 200.0; tp = 400.0; trail_dist = 120.0; trail_act = 80.0; lot_scale = 1.0;
   }
   else if(clean_sym == "NVDA") {
      atr_min = 300.0; sl = 1000.0; tp = 2000.0; trail_dist = 600.0; trail_act = 400.0; lot_scale = 0.2;
   }
   else if(clean_sym == "TSLA") {
      atr_min = 80.0; sl = 300.0; tp = 600.0; trail_dist = 180.0; trail_act = 120.0; lot_scale = 0.8;
   }
   else if(clean_sym == "DE40" || clean_sym == "GER40" || clean_sym == "DE30" || clean_sym == "GER30") {
      atr_min = 500.0; sl = 1500.0; tp = 3000.0; trail_dist = 900.0; trail_act = 600.0; lot_scale = 1.0;
   }
   else if(clean_sym == "SOXX") {
      atr_min = 80.0; sl = 300.0; tp = 600.0; trail_dist = 180.0; trail_act = 120.0; lot_scale = 0.8;
   }
   else if(clean_sym == "EWY") {
      atr_min = 30.0; sl = 100.0; tp = 200.0; trail_dist = 60.0; trail_act = 40.0; lot_scale = 1.0;
   }
   else if(clean_sym == "XTIUSD" || clean_sym == "USOUSD" || clean_sym == "WTI" || clean_sym == "CRUDE" || clean_sym == "USOIL") {
      atr_min = 40.0; sl = 150.0; tp = 300.0; trail_dist = 90.0; trail_act = 60.0; lot_scale = 1.0;
   }
   else if(clean_sym == "XBRUSD" || clean_sym == "UKOUSD" || clean_sym == "BRENT" || clean_sym == "BRENTOIL" || clean_sym == "UKOIL") {
      atr_min = 40.0; sl = 150.0; tp = 300.0; trail_dist = 90.0; trail_act = 60.0; lot_scale = 1.0;
   }
   else if(clean_sym == "XNGUSD" || clean_sym == "NATGAS" || clean_sym == "NGAS") {
      atr_min = 30.0; sl = 100.0; tp = 200.0; trail_dist = 60.0; trail_act = 40.0; lot_scale = 1.0;
   }
}

// Forward declarations
bool United_MayOpenNewEntry(const string symbol, const ulong magic, const bool isBuy);
void ClosePositionWP(WilliamsPassivationData& data, int MagicNumber, string reason = "");
void OpenBuyWP(WilliamsPassivationData& data, int MagicNumber, double LotSize, double StopLossPoints, double TakeProfitPoints);
void OpenSellWP(WilliamsPassivationData& data, int MagicNumber, double LotSize, double StopLossPoints, double TakeProfitPoints);
void WP_ApplyTrailingStop(WilliamsPassivationData& data, const int MagicNumber, const bool useTrailingStop, const double trailingStopDistancePoints, const double trailingActivationPoints);

//+------------------------------------------------------------------+
//| Initialize Strategy Indicators & Settings                        |
//+------------------------------------------------------------------+
bool InitWilliamsPassivation(WilliamsPassivationData& data, string symbol, ENUM_TIMEFRAMES TimeFrame,
                             int WPR_Period, int BB_Period, double BB_Deviation, ENUM_APPLIED_PRICE BB_AppliedPrice,
                             int EMA_Period, ENUM_APPLIED_PRICE EMA_AppliedPrice, bool Filter_ATR_Enable, int Filter_ATR_Period,
                             int MagicNumber, int Slippage)
{
   data.symbol = symbol;
   data.isInitialized = false;
   
   if(!SymbolSelect(symbol, true))
   {
      Print("WilliamsPassivation: Symbol '", symbol, "' not available in Market Watch.");
      return false;
   }
   
   Sleep(100);
   
   data.wpr_handle = iWPR(symbol, TimeFrame, WPR_Period);
   if(data.wpr_handle == INVALID_HANDLE)
   {
      Print("WilliamsPassivation: Failed to create WPR handle for ", symbol);
      return false;
   }
   
   data.bb_handle = iBands(symbol, TimeFrame, BB_Period, 0, BB_Deviation, BB_AppliedPrice);
   // PrintFormat("InitWilliamsPassivation: BB_Deviation=%.2f handle=%d", BB_Deviation, data.bb_handle);
   if(data.bb_handle == INVALID_HANDLE)
   {
      Print("WilliamsPassivation: Failed to create BB handle for ", symbol);
      return false;
   }
   
   data.ema_handle = iMA(symbol, PERIOD_D1, EMA_Period, 0, MODE_EMA, EMA_AppliedPrice);
   if(data.ema_handle == INVALID_HANDLE)
   {
      Print("WilliamsPassivation: Failed to create D1 EMA handle for ", symbol);
      return false;
   }

   // Warm-up retry: D1 bars may not be ready immediately after handle creation,
   // especially during the first few ticks of a live session. Retry a few times
   // before declaring the strategy initialized so the CopyBuffer hard-fail is avoided.
   {
      double warmup[];
      ArraySetAsSeries(warmup, true);
      int retry = 0;
      bool ready = false;
      while(retry < 5 && !ready)
      {
         if(CopyBuffer(data.ema_handle, 0, 0, 1, warmup) == 1 && warmup[0] > 0.0)
            ready = true;
         else
         {
            Sleep(100);
            retry++;
         }
      }
      if(!ready)
         Print("WilliamsPassivation: D1 EMA handle created but data not yet ready for ", symbol, "; strategy will use fallback reads.");
   }

   if(Filter_ATR_Enable)
   {
      data.atr_handle = iATR(symbol, TimeFrame, Filter_ATR_Period);
      if(data.atr_handle == INVALID_HANDLE)
      {
         Print("WilliamsPassivation: Failed to create ATR handle for ", symbol);
         return false;
      }
   }
   else
   {
      data.atr_handle = INVALID_HANDLE;
   }
   
   data.trade.SetExpertMagicNumber(MagicNumber);
   data.trade.SetDeviationInPoints(Slippage);
   data.trade.SetTypeFilling(ORDER_FILLING_FOK);
   
   data.position_open = false;
   data.position_ticket = 0;
   data.last_bar_time = 0;
   data.isInitialized = true;
   
   Print("WilliamsPassivation: Successfully initialized for symbol '", symbol, "'");
   return true;
}

//+------------------------------------------------------------------+
//| Clean up handles                                                 |
//+------------------------------------------------------------------+
void DeinitWilliamsPassivation(WilliamsPassivationData& data)
{
   if(data.wpr_handle != INVALID_HANDLE)
      IndicatorRelease(data.wpr_handle);
   if(data.bb_handle != INVALID_HANDLE)
      IndicatorRelease(data.bb_handle);
   if(data.ema_handle != INVALID_HANDLE)
      IndicatorRelease(data.ema_handle);
   if(data.atr_handle != INVALID_HANDLE)
      IndicatorRelease(data.atr_handle);
}

//+------------------------------------------------------------------+
//| Verify Position Status                                           |
//+------------------------------------------------------------------+
void CheckExistingPositionWP(WilliamsPassivationData& data, int MagicNumber)
{
   bool positionExists = PositionExistsByMagic(data.symbol, MagicNumber);
   
   if(!positionExists && data.position_open)
   {
      data.position_open = false;
      data.position_ticket = 0;
      return;
   }
   
   if(!positionExists)
      return;
   
   if(!data.position_open && positionExists)
   {
      ulong ticket = GetPositionTicketByMagic(data.symbol, MagicNumber);
      if(ticket > 0 && PositionSelectByTicketSymbolAndMagic(ticket, data.symbol, MagicNumber))
      {
         data.position_ticket = ticket;
         data.position_open = true;
         data.current_position_type = (ENUM_POSITION_TYPE)PositionGetInteger(POSITION_TYPE);
      }
   }
   
   if(data.position_open && data.position_ticket > 0)
   {
      if(!PositionSelectByTicketSymbolAndMagic(data.position_ticket, data.symbol, MagicNumber))
      {
         ulong ticket = GetPositionTicketByMagic(data.symbol, MagicNumber);
         if(ticket > 0 && PositionSelectByTicketSymbolAndMagic(ticket, data.symbol, MagicNumber))
         {
            data.position_ticket = ticket;
            data.current_position_type = (ENUM_POSITION_TYPE)PositionGetInteger(POSITION_TYPE);
         }
         else
         {
            data.position_open = false;
            data.position_ticket = 0;
            return;
         }
      }
      else
      {
         data.current_position_type = (ENUM_POSITION_TYPE)PositionGetInteger(POSITION_TYPE);
      }
   }
}

//+------------------------------------------------------------------+
//| Core strategy iteration loop                                     |
//+------------------------------------------------------------------+
void ProcessWilliamsPassivation(WilliamsPassivationData& data, const string symbol, ENUM_TIMEFRAMES TimeFrame,
                                int WPR_Period, int PassivationBars, double WPR_Overbought, double WPR_Oversold,
                                int BB_Period, double BB_Deviation, ENUM_APPLIED_PRICE BB_AppliedPrice,
                                int EMA_Period, ENUM_APPLIED_PRICE EMA_AppliedPrice,
                                bool Filter_D1_EMA_Slope, bool Filter_D1_EMA_Price,
                                bool Filter_ATR_Enable, int Filter_ATR_Period, double Filter_ATR_MinPoints,
                                double LotSize, int MagicNumber, int Slippage, int MaxSpreadPoints,
                                bool UseTrailingStop, double TrailDistancePoints, double TrailActivationPoints,
                                bool ExitOnPassivationEnd, double StopLossPoints, double TakeProfitPoints)
{
   if(!data.isInitialized)
      return;
      
   // Refresh position tracking
   CheckExistingPositionWP(data, MagicNumber);
   
   // Apply trailing stop if we have a position
   if(data.position_open)
   {
      WP_ApplyTrailingStop(data, MagicNumber, UseTrailingStop, TrailDistancePoints, TrailActivationPoints);
   }
   
   // Spread control
   double spread = SymbolInfoInteger(symbol, SYMBOL_SPREAD);
   if(MaxSpreadPoints > 0 && spread > MaxSpreadPoints)
      return;
      
   // Bar control: check on the opening of a new bar on the timeframe (e.g. H1)
   datetime currentBarTime = iTime(symbol, TimeFrame, 0);
   if(currentBarTime == 0)
      return;
   if(data.last_bar_time == currentBarTime)
      return;
   
   data.last_bar_time = currentBarTime;

   // Check exit on completed bar (bar 1) WPR leaving passivation zone
   if(ExitOnPassivationEnd && data.position_open)
   {
      double wpr_prev[];
      if(CopyBuffer(data.wpr_handle, 0, 1, 1, wpr_prev) == 1)
      {
         if(data.current_position_type == POSITION_TYPE_BUY && wpr_prev[0] < WPR_Overbought)
         {
            ClosePositionWP(data, MagicNumber, "Passivation end Buy Exit");
            return;
         }
         else if(data.current_position_type == POSITION_TYPE_SELL && wpr_prev[0] > WPR_Oversold)
         {
            ClosePositionWP(data, MagicNumber, "Passivation end Sell Exit");
            return;
         }
      }
   }
   
   // Check entry signals on the newly completed bar (bar 1)
   double wpr_array[];
   ArraySetAsSeries(wpr_array, true);
   if(CopyBuffer(data.wpr_handle, 0, 1, PassivationBars, wpr_array) < PassivationBars)
   {
      Print("WilliamsPassivation: CopyBuffer WPR failed");
      return;
   }
   
   // Copy BB bands for bar 1
   double bb_upper[], bb_lower[], bb_middle[];
   if(CopyBuffer(data.bb_handle, 0, 1, 1, bb_middle) != 1 ||
      CopyBuffer(data.bb_handle, 1, 1, 1, bb_upper) != 1 ||
      CopyBuffer(data.bb_handle, 2, 1, 1, bb_lower) != 1)
   {
      Print("WilliamsPassivation: CopyBuffer BB failed");
      return;
   }
   
   // Copy Close price for bar 1
   double close_array[];
   if(CopyClose(symbol, TimeFrame, 1, 1, close_array) != 1)
   {
      Print("WilliamsPassivation: CopyClose failed");
      return;
   }
   double close1 = close_array[0];
   // PrintFormat("WP Debug: Close=%.5f Middle=%.5f Upper=%.5f Lower=%.5f WPR[0]=%.2f WPR[1]=%.2f", close1, bb_middle[0], bb_upper[0], bb_lower[0], wpr_array[0], wpr_array[1]);
   
   // Check Williams %R passivation
   bool isBullPass = true;
   bool isBearPass = true;
   for(int i = 0; i < PassivationBars; i++)
   {
      if(wpr_array[i] < WPR_Overbought)
         isBullPass = false;
      if(wpr_array[i] > WPR_Oversold)
         isBearPass = false;
   }
   
   // Check BB breakout
   bool isBBBreakoutUp = (close1 > bb_upper[0]);
   bool isBBBreakoutDown = (close1 < bb_lower[0]);
   
   // If no entry conditions met, we can exit early
   if(!((isBullPass && isBBBreakoutUp) || (isBearPass && isBBBreakoutDown)))
      return;
      
   // Check D1 200 EMA Trend. Use shift=1 (closed bar) by preference, but fall back to
   // shift=0 if the D1 history is not yet fully formed (e.g. first day of live trading).
   // Never hard-return here; a missing D1 filter should skip the filter, not kill the tick.
   double ema_d1[2];
   ArraySetAsSeries(ema_d1, true);
   bool ema_ok = (CopyBuffer(data.ema_handle, 0, 1, 2, ema_d1) == 2);
   if(!ema_ok)
   {
      double ema_now[1];
      if(CopyBuffer(data.ema_handle, 0, 0, 1, ema_now) == 1 && ema_now[0] > 0.0)
      {
         ema_d1[0] = ema_now[0];
         ema_d1[1] = ema_now[0];
         ema_ok = true;
      }
   }

   double d1_close_array[];
   bool d1_close_ok = (CopyClose(symbol, PERIOD_D1, 1, 1, d1_close_array) == 1);
   if(!d1_close_ok)
   {
      // Fall back to current forming bar if closed bar unavailable
      d1_close_ok = (CopyClose(symbol, PERIOD_D1, 0, 1, d1_close_array) == 1);
   }
   double d1_close1 = d1_close_ok ? d1_close_array[0] : 0.0;

   bool isTrendUp = true;
   bool isTrendDown = true;

   if((Filter_D1_EMA_Slope || Filter_D1_EMA_Price) && !ema_ok)
   {
      // D1 EMA data unavailable: disable the D1 filter for this tick but keep running.
      if(GRM_DebugLogs)
         Print("WilliamsPassivation: D1 EMA data unavailable for ", symbol, "; skipping D1 trend filter this tick.");
      isTrendUp = true;
      isTrendDown = true;
   }
   else
   {
      if(Filter_D1_EMA_Slope)
      {
         if(ema_d1[0] <= ema_d1[1])
            isTrendUp = false;
         if(ema_d1[0] >= ema_d1[1])
            isTrendDown = false;
      }

      if(Filter_D1_EMA_Price && d1_close_ok)
      {
         if(d1_close1 <= ema_d1[0])
            isTrendUp = false;
         if(d1_close1 >= ema_d1[0])
            isTrendDown = false;
      }
   }
   
   // Check ATR Volatility filter
   if(Filter_ATR_Enable && data.atr_handle != INVALID_HANDLE)
   {
      double atr_array[];
      if(CopyBuffer(data.atr_handle, 0, 1, 1, atr_array) == 1)
      {
         double min_atr_val = Filter_ATR_MinPoints * SymbolInfoDouble(symbol, SYMBOL_POINT);
         if(atr_array[0] < min_atr_val)
         {
            return; // Volatility is too low
         }
      }
   }
   
   // Open trade if filters pass and we can trade
   if(isBullPass && isBBBreakoutUp && isTrendUp && !data.position_open)
   {
      OpenBuyWP(data, MagicNumber, LotSize, StopLossPoints, TakeProfitPoints);
   }
   else if(isBearPass && isBBBreakoutDown && isTrendDown && !data.position_open)
   {
      OpenSellWP(data, MagicNumber, LotSize, StopLossPoints, TakeProfitPoints);
   }
}

//+------------------------------------------------------------------+
//| Trade Execution - Open Buy                                       |
//+------------------------------------------------------------------+
void OpenBuyWP(WilliamsPassivationData& data, int MagicNumber, double LotSize, double StopLossPoints, double TakeProfitPoints)
{
   if(!United_MayOpenNewEntry(data.symbol, MagicNumber, true))
      return;
      
   double normalizedLot = United_NormalizeVolume(data.symbol, LotSize);
   double ask = SymbolInfoDouble(data.symbol, SYMBOL_ASK);
   double point = SymbolInfoDouble(data.symbol, SYMBOL_POINT);
   int digits = (int)SymbolInfoInteger(data.symbol, SYMBOL_DIGITS);
   
   double sl = (StopLossPoints > 0.0) ? NormalizeDouble(ask - StopLossPoints * point, digits) : 0.0;
   double tp = (TakeProfitPoints > 0.0) ? NormalizeDouble(ask + TakeProfitPoints * point, digits) : 0.0;
   
   if(data.trade.Buy(normalizedLot, data.symbol, ask, sl, tp, "WP Buy #M" + IntegerToString(MagicNumber)))
   {
      ulong new_ticket = data.trade.ResultOrder();
      if(new_ticket > 0)
      {
         if(PositionSelectByTicketSymbolAndMagic(new_ticket, data.symbol, MagicNumber))
         {
            data.position_ticket = new_ticket;
            data.position_open = true;
            data.current_position_type = POSITION_TYPE_BUY;
            Print("WilliamsPassivation: Open Buy ticket=", new_ticket, " price=", ask, " SL=", sl, " TP=", tp);
         }
      }
   }
}

//+------------------------------------------------------------------+
//| Trade Execution - Open Sell                                      |
//+------------------------------------------------------------------+
void OpenSellWP(WilliamsPassivationData& data, int MagicNumber, double LotSize, double StopLossPoints, double TakeProfitPoints)
{
   if(!United_MayOpenNewEntry(data.symbol, MagicNumber, false))
      return;
      
   double normalizedLot = United_NormalizeVolume(data.symbol, LotSize);
   double bid = SymbolInfoDouble(data.symbol, SYMBOL_BID);
   double point = SymbolInfoDouble(data.symbol, SYMBOL_POINT);
   int digits = (int)SymbolInfoInteger(data.symbol, SYMBOL_DIGITS);
   
   double sl = (StopLossPoints > 0.0) ? NormalizeDouble(bid + StopLossPoints * point, digits) : 0.0;
   double tp = (TakeProfitPoints > 0.0) ? NormalizeDouble(bid - TakeProfitPoints * point, digits) : 0.0;
   
   if(data.trade.Sell(normalizedLot, data.symbol, bid, sl, tp, "WP Sell #M" + IntegerToString(MagicNumber)))
   {
      ulong new_ticket = data.trade.ResultOrder();
      if(new_ticket > 0)
      {
         if(PositionSelectByTicketSymbolAndMagic(new_ticket, data.symbol, MagicNumber))
         {
            data.position_ticket = new_ticket;
            data.position_open = true;
            data.current_position_type = POSITION_TYPE_SELL;
            Print("WilliamsPassivation: Open Sell ticket=", new_ticket, " price=", bid, " SL=", sl, " TP=", tp);
         }
      }
   }
}

//+------------------------------------------------------------------+
//| Trade Execution - Close Position                                 |
//+------------------------------------------------------------------+
void ClosePositionWP(WilliamsPassivationData& data, int MagicNumber, string reason = "")
{
   if(!PositionExistsByMagic(data.symbol, MagicNumber))
   {
      data.position_open = false;
      data.position_ticket = 0;
      return;
   }
   
   bool closed = false;
   if(data.position_ticket > 0)
   {
      if(PositionSelectByTicket(data.position_ticket))
      {
         if(PositionGetString(POSITION_SYMBOL) == data.symbol && 
            PositionGetInteger(POSITION_MAGIC) == MagicNumber)
         {
            closed = data.trade.PositionClose(data.position_ticket);
         }
      }
   }
   
   if(!closed)
   {
      closed = ClosePositionByMagic(data.trade, data.symbol, MagicNumber);
   }
   
   if(closed)
   {
      Sleep(50);
      if(!PositionExistsByMagic(data.symbol, MagicNumber))
      {
         data.position_open = false;
         data.position_ticket = 0;
         Print("WilliamsPassivation: Position closed. Reason: ", reason);
      }
   }
}

//+------------------------------------------------------------------+
//| Trailing Stop Logic                                              |
//+------------------------------------------------------------------+
void WP_ApplyTrailingStop(WilliamsPassivationData& data, const int MagicNumber,
                           const bool useTrailingStop,
                           const double trailingStopDistancePoints,
                           const double trailingActivationPoints)
{
   if(!useTrailingStop || trailingStopDistancePoints <= 0.0)
      return;
   if(!PositionSelectByMagic(data.symbol, (ulong)MagicNumber))
      return;

   const double point = SymbolInfoDouble(data.symbol, SYMBOL_POINT);
   if(point <= 0.0)
      return;

   const int digits = (int)SymbolInfoInteger(data.symbol, SYMBOL_DIGITS);
   const double trail_dist = trailingStopDistancePoints * point;
   const double activation_pts = (trailingActivationPoints > 0.0)
      ? trailingActivationPoints
      : trailingStopDistancePoints;
   const double activation = activation_pts * point;
   const long stops_level = SymbolInfoInteger(data.symbol, SYMBOL_TRADE_STOPS_LEVEL);
   const double min_dist = (double)stops_level * point;

   const ENUM_POSITION_TYPE ptype = (ENUM_POSITION_TYPE)PositionGetInteger(POSITION_TYPE);
   const double entry = PositionGetDouble(POSITION_PRICE_OPEN);
   const double cur_sl = PositionGetDouble(POSITION_SL);
   const double cur_tp = PositionGetDouble(POSITION_TP);

   if(ptype == POSITION_TYPE_BUY)
   {
      const double bid = SymbolInfoDouble(data.symbol, SYMBOL_BID);
      if(bid - entry <= activation)
         return;

      double new_sl = NormalizeDouble(bid - trail_dist, digits);
      if(min_dist > 0.0 && bid - new_sl < min_dist)
         new_sl = NormalizeDouble(bid - min_dist, digits);

      if(new_sl >= bid || new_sl <= 0.0)
         return;
      if(cur_sl > 0.0 && new_sl <= cur_sl)
         return;

      ModifyPositionByMagic(data.trade, data.symbol, (ulong)MagicNumber, new_sl, cur_tp);
   }
   else if(ptype == POSITION_TYPE_SELL)
   {
      const double ask = SymbolInfoDouble(data.symbol, SYMBOL_ASK);
      if(entry - ask <= activation)
         return;

      double new_sl = NormalizeDouble(ask + trail_dist, digits);
      if(min_dist > 0.0 && new_sl - ask < min_dist)
         new_sl = NormalizeDouble(ask + min_dist, digits);

      if(new_sl <= ask || new_sl <= 0.0)
         return;
      if(cur_sl > 0.0 && new_sl >= cur_sl)
         return;

      ModifyPositionByMagic(data.trade, data.symbol, (ulong)MagicNumber, new_sl, cur_tp);
   }
}
