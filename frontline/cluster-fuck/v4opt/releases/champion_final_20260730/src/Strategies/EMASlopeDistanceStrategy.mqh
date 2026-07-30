//+------------------------------------------------------------------+
//|                                    EMASlopeDistanceStrategy.mqh  |
//+------------------------------------------------------------------+

bool InitEMASlopeDistance(string symbol)
{
   esData.symbol = symbol;
   esData.letzte_überwachung_zeit = 0;
   esData.überwachung_aktiv = false;
   esData.preis_trigger_aktiv = false;
   esData.steigung_trigger_aktiv = false;
   esData.ticket = 0;
   esData.trades_in_current_crossover = 0;
   esData.crossover_detected = false;
   esData.trade_open_time = 0;
   esData.last_bar_time = 0;
   esData.es_last_sl_adjust_success_time = 0;
   
   // Check if symbol exists
   if(!SymbolSelect(symbol, true))
   {
      Print("EMASlopeDistance: Symbol '", symbol, "' not available in Market Watch. Please add it to Market Watch or check symbol name.");
      return false;
   }
   
   Sleep(100); // Wait for symbol to be ready
   
   esData.trade.SetExpertMagicNumber(ES_MagicNumber);
   esData.trade.SetDeviationInPoints(10);
   esData.trade.SetTypeFilling(ORDER_FILLING_IOC);
   
   esData.ema_handle = iMA(symbol, ES_Timeframe, ES_EMA_Periode, 0, MODE_EMA, PRICE_CLOSE);
   
   if(esData.ema_handle == INVALID_HANDLE)
   {
      Print("EMASlopeDistance: Error creating EMA indicator for '", symbol, "'");
      return false;
   }
   
   ArraySetAsSeries(esData.ema_array, true);
   esData.isInitialized = true;
   Print("EMASlopeDistance: Successfully initialized for symbol '", symbol, "'");
   return true;
}

void DeinitEMASlopeDistance()
{
   if(esData.ema_handle != INVALID_HANDLE)
      IndicatorRelease(esData.ema_handle);
}

bool ES_IsWeeklyADXTrendFavorable(const ENUM_ORDER_TYPE order_type)
{
   if(!ES_UseWeeklyADXFilter)
      return true;

   int adxShift = ES_WeeklyADXBarShift;
   if(adxShift < 0)
      adxShift = 0;

   int adx_handle = iADX(esData.symbol, PERIOD_W1, ES_WeeklyADXPeriod);
   if(adx_handle == INVALID_HANDLE)
      return false;

   double adx_buf[], plus_di_buf[], minus_di_buf[];
   ArraySetAsSeries(adx_buf, true);
   ArraySetAsSeries(plus_di_buf, true);
   ArraySetAsSeries(minus_di_buf, true);

   bool ok_adx = (CopyBuffer(adx_handle, 0, adxShift, 1, adx_buf) > 0);
   bool ok_plus = (CopyBuffer(adx_handle, 1, adxShift, 1, plus_di_buf) > 0);
   bool ok_minus = (CopyBuffer(adx_handle, 2, adxShift, 1, minus_di_buf) > 0);
   IndicatorRelease(adx_handle);

   if(!ok_adx || !ok_plus || !ok_minus)
      return false;

   double adx_value = adx_buf[0];
   double plus_di = plus_di_buf[0];
   double minus_di = minus_di_buf[0];

   bool strength_ok = (adx_value >= ES_WeeklyADXMin);
   bool direction_ok = true;
   if(ES_WeeklyADXUseDirection)
   {
      if(order_type == ORDER_TYPE_BUY)
         direction_ok = (plus_di > minus_di);
      else
         direction_ok = (minus_di > plus_di);
   }
   return strength_ok && direction_ok;
}

bool ES_TrailingActivationReached(const double position_profit, const ENUM_POSITION_TYPE position_type,
                                 const double pips_multiplier)
{
   if(ES_TrailingActivationPips <= 0.0)
      return (position_profit > 0.0);

   const double open_px = PositionGetDouble(POSITION_PRICE_OPEN);
   if(position_type == POSITION_TYPE_BUY)
   {
      const double bid = SymbolInfoDouble(esData.symbol, SYMBOL_BID);
      return ((bid - open_px) / SymbolInfoDouble(esData.symbol, SYMBOL_POINT) / pips_multiplier >= ES_TrailingActivationPips);
   }
   const double ask = SymbolInfoDouble(esData.symbol, SYMBOL_ASK);
   return ((open_px - ask) / SymbolInfoDouble(esData.symbol, SYMBOL_POINT) / pips_multiplier >= ES_TrailingActivationPips);
}

//+------------------------------------------------------------------+
//| EMA Berechnung (EMA Calculation)                                |
//+------------------------------------------------------------------+
void BerechneEMA()
{
   //--- EMA Werte vom Indicator kopieren (Copy EMA values from indicator)
   int copied = CopyBuffer(esData.ema_handle, 0, 0, 3, esData.ema_array);
   
   if(copied <= 0)
   {
      Print("TRACE: Error copying EMA values - Copied: ", copied);
      return;
   }
   
   Print("TRACE: EMA values copied: ", copied, " bars");
   Print("TRACE: EMA [0]: ", esData.ema_array[0], " [1]: ", esData.ema_array[1], " [2]: ", esData.ema_array[2]);
}

//+------------------------------------------------------------------+
//| Trigger-Bedingungen prüfen (Check trigger conditions)           |
//+------------------------------------------------------------------+
void PrüfeTrigger()
{
   if(ArraySize(esData.ema_array) < 2)
   {
      Print("TRACE: Array too small - Size: ", ArraySize(esData.ema_array));
      return;
   }
   
   //--- Aktuelle Werte (Current values)
   double aktueller_preis = SymbolInfoDouble(esData.symbol, SYMBOL_BID);
   double aktueller_ask = SymbolInfoDouble(esData.symbol, SYMBOL_ASK);
   double aktueller_close = iClose(esData.symbol, ES_Timeframe, 0);
   int digits = (int)SymbolInfoInteger(esData.symbol, SYMBOL_DIGITS);
   double point = SymbolInfoDouble(esData.symbol, SYMBOL_POINT);
   double pips_multiplier = (digits == 3 || digits == 5) ? 10.0 : 1.0;
   
   //--- EMA Werte in Variablen (EMA values in variables)
   double ema_aktuell = esData.ema_array[0];
   double ema_vorher = esData.ema_array[1];
   
   //--- EMA Crossover Erkennung (EMA Crossover Detection)
   // Prüfe ob Preis die EMA kreuzt (Check if price crosses EMA)
   static double last_close = 0;
   static double last_ema = 0;
   
   if(last_close != 0 && last_ema != 0)
   {
      bool crossover_bullish = (last_close <= last_ema) && (aktueller_close > ema_aktuell);
      bool crossover_bearish = (last_close >= last_ema) && (aktueller_close < ema_aktuell);
      
      //--- Neues Crossover-Ereignis erkannt (New crossover event detected)
      if(crossover_bullish || crossover_bearish)
      {
         esData.trades_in_current_crossover = 0; // Reset trade counter
         Print("TRACE: EMA crossover detected - ", (crossover_bullish ? "BULLISH" : "BEARISH"), " - trade counter reset");
         Print("TRACE: Before: Close=", last_close, " EMA=", last_ema, " Now: Close=", aktueller_close, " EMA=", ema_aktuell);
      }
   }
   
   //--- Aktuelle Werte für nächsten Vergleich speichern (Save current values for next comparison)
   last_close = aktueller_close;
   last_ema = ema_aktuell;
   
   //--- Preisbewegung zur EMA prüfen (Check price action to EMA)
   double preis_abstand = MathAbs(aktueller_close - ema_aktuell) / point / pips_multiplier;
   
   Print("TRACE: Price distance: ", preis_abstand, " pips (threshold: ", ES_PreisSchwelle, ")");
   Print("TRACE: Close: ", aktueller_close, " EMA: ", ema_aktuell);
   Print("TRACE: Trades in current crossover: ", esData.trades_in_current_crossover, "/", ES_MaxTradesPerCrossover);
   
   if(preis_abstand > ES_PreisSchwelle && !esData.preis_trigger_aktiv)
   {
      esData.preis_trigger_aktiv = true;
      Print("TRACE: Price trigger activated: ", preis_abstand, " pips");
   }
   
   //--- EMA Steigung prüfen (Check EMA slope)
   double steigung = (ema_aktuell - ema_vorher) / point / pips_multiplier;
   
   Print("TRACE: EMA slope: ", steigung, " pips (threshold: ", ES_SteigungSchwelle, ")");
   
   if(MathAbs(steigung) > ES_SteigungSchwelle && !esData.steigung_trigger_aktiv)
   {
      esData.steigung_trigger_aktiv = true;
      Print("TRACE: Slope trigger activated: ", steigung, " pips");
   }
   
   //--- Überwachung starten wenn beide Trigger aktiv sind (Start monitoring when both triggers are active)
   if(esData.preis_trigger_aktiv && esData.steigung_trigger_aktiv && !esData.überwachung_aktiv)
   {
      esData.überwachung_aktiv = true;
      
      if(ES_UseBarData)
      {
         esData.letzte_überwachung_zeit = iTime(esData.symbol, ES_Timeframe, 0); // Aktuelle Bar-Zeit
         Print("TRACE: Monitoring started - both triggers active (Bar: ", TimeToString(esData.letzte_überwachung_zeit), ")");
      }
      else
      {
         esData.letzte_überwachung_zeit = TimeCurrent(); // Aktuelle Tick-Zeit
         Print("TRACE: Monitoring started - both triggers active (Tick)");
      }
   }
   
   //--- Trade platzieren wenn Überwachung aktiv und Preis über/unter EMA (Place trade when monitoring active and price above/below EMA)
   if(esData.überwachung_aktiv)
   {
      bool bullish_signal = aktueller_close > ema_aktuell;
      bool bearish_signal = aktueller_close < ema_aktuell;
      
      Print("TRACE: Signal Check - Bullish: ", bullish_signal, " Bearish: ", bearish_signal);
      Print("TRACE: Close: ", aktueller_close, " EMA: ", ema_aktuell);
      Print("TRACE: Difference: ", aktueller_close - ema_aktuell);
      
      //--- Trade-Limit prüfen (Check trade limit)
      if(esData.trades_in_current_crossover >= ES_MaxTradesPerCrossover)
      {
         Print("TRACE: Trade limit reached (", ES_MaxTradesPerCrossover, ") - no new trade");
         return;
      }
      
      if(bullish_signal && !PositionExistsByMagic(esData.symbol, (ulong)ES_MagicNumber))
      {
         if(!ES_IsWeeklyADXTrendFavorable(ORDER_TYPE_BUY))
         {
            Print("TRACE: Weekly ADX blocked BUY entry");
            return;
         }
         Print("TRACE: Attempting to place BUY trade (Trade #", esData.trades_in_current_crossover + 1, ")");
         if(PlatziereTrade(ORDER_TYPE_BUY))
         {
            esData.trades_in_current_crossover++;
         }
      }
      else if(bearish_signal && !PositionExistsByMagic(esData.symbol, (ulong)ES_MagicNumber))
      {
         if(!ES_IsWeeklyADXTrendFavorable(ORDER_TYPE_SELL))
         {
            Print("TRACE: Weekly ADX blocked SELL entry");
            return;
         }
         Print("TRACE: Attempting to place SELL trade (Trade #", esData.trades_in_current_crossover + 1, ")");
         if(PlatziereTrade(ORDER_TYPE_SELL))
         {
            esData.trades_in_current_crossover++;
         }
      }
      else if(PositionExistsByMagic(esData.symbol, (ulong)ES_MagicNumber))
      {
         Print("TRACE: Position already open - no new trade");
      }
   }
}

//+------------------------------------------------------------------+
//| Trade platzieren (Place trade)                                  |
//+------------------------------------------------------------------+
bool PlatziereTrade(ENUM_ORDER_TYPE order_type)
{
   Print("TRACE: Attempting to place trade - Type: ", (order_type == ORDER_TYPE_BUY) ? "BUY" : "SELL");
   const double lot = United_NormalizeVolume(esData.symbol, g_ES_LotSize);
   Print("TRACE: Lot (raw): ", g_ES_LotSize, " normalized: ", lot);
   if(lot <= 0.0)
   {
      Print("TRACE: Abort - lot invalid after normalization");
      return false;
   }

   bool success = false;
   
   if(order_type == ORDER_TYPE_BUY)
   {
      if(!United_MayOpenNewEntry(esData.symbol, (ulong)ES_MagicNumber, true))
         return false;
      success = esData.trade.Buy(lot, esData.symbol, 0, 0, 0, "EMA Crossover Trade BUY #M" + IntegerToString(ES_MagicNumber));
   }
   else
   {
      if(!United_MayOpenNewEntry(esData.symbol, (ulong)ES_MagicNumber, false))
         return false;
      success = esData.trade.Sell(lot, esData.symbol, 0, 0, 0, "EMA Crossover Trade SELL #M" + IntegerToString(ES_MagicNumber));
   }
   
   if(success)
   {
      esData.ticket = (int)esData.trade.ResultOrder();
      Print("TRACE: Trade placed successfully: ", (order_type == ORDER_TYPE_BUY) ? "BUY" : "SELL", " Ticket: ", esData.ticket);
      
      //--- Trade-Öffnungszeit speichern (Save trade opening time)
      esData.trade_open_time = iTime(esData.symbol, ES_Timeframe, 0);
      esData.es_last_sl_adjust_success_time = 0;
      Print("TRACE: Trade open time: ", TimeToString(esData.trade_open_time));
      
      //--- Überwachung zurücksetzen (Reset monitoring)
      esData.überwachung_aktiv = false;
      esData.preis_trigger_aktiv = false;
      esData.steigung_trigger_aktiv = false;
      
      return true;
   }
   else
   {
      Print("TRACE: Error placing trade - Retcode: ", esData.trade.ResultRetcode());
      Print("TRACE: Error description: ", esData.trade.ResultRetcodeDescription());
      
      return false;
   }
}

//+------------------------------------------------------------------+
//| Trades verwalten (Manage trades)                                |
//+------------------------------------------------------------------+
void VerwalteTrades()
{
   if(!PositionSelectByMagic(esData.symbol, (ulong)ES_MagicNumber))
      return;

   if(ES_UseStaleStopLossExit && ES_StaleStopLossSeconds > 0)
   {
      const datetime stale_ref = (esData.es_last_sl_adjust_success_time > 0)
         ? esData.es_last_sl_adjust_success_time
         : (datetime)PositionGetInteger(POSITION_TIME);
      if(TimeCurrent() - stale_ref >= ES_StaleStopLossSeconds)
      {
         SchließePosition("Stale stop loss - no SL adjustment");
         return;
      }
   }

   double position_profit = PositionGetDouble(POSITION_PROFIT);
   ENUM_POSITION_TYPE position_type = (ENUM_POSITION_TYPE)PositionGetInteger(POSITION_TYPE);

   int digits = (int)SymbolInfoInteger(esData.symbol, SYMBOL_DIGITS);
   double point = SymbolInfoDouble(esData.symbol, SYMBOL_POINT);
   double pips_multiplier = (digits == 3 || digits == 5) ? 10.0 : 1.0;
   const double trail_dist = ES_TrailingStop * point * pips_multiplier;
   const long stops_level = SymbolInfoInteger(esData.symbol, SYMBOL_TRADE_STOPS_LEVEL);
   const double min_dist = (double)stops_level * point;

   if(ES_UseTrailingStop && ES_TrailingStop > 0.0 && ES_TrailingActivationReached(position_profit, position_type, pips_multiplier))
   {
      if(position_type == POSITION_TYPE_BUY)
      {
         const double bid = SymbolInfoDouble(esData.symbol, SYMBOL_BID);
         double new_stop_loss = NormalizeDouble(bid - trail_dist, digits);
         if(min_dist > 0.0 && bid - new_stop_loss < min_dist)
            new_stop_loss = NormalizeDouble(bid - min_dist, digits);
         const double current_stop_loss = PositionGetDouble(POSITION_SL);
         if(new_stop_loss < bid && new_stop_loss > 0.0 && new_stop_loss > current_stop_loss)
            ÄndereStopLoss(new_stop_loss);
      }
      else if(position_type == POSITION_TYPE_SELL)
      {
         const double ask = SymbolInfoDouble(esData.symbol, SYMBOL_ASK);
         double new_stop_loss = NormalizeDouble(ask + trail_dist, digits);
         if(min_dist > 0.0 && new_stop_loss - ask < min_dist)
            new_stop_loss = NormalizeDouble(ask + min_dist, digits);
         const double current_stop_loss = PositionGetDouble(POSITION_SL);
         if(new_stop_loss > ask && new_stop_loss > 0.0 &&
            (new_stop_loss < current_stop_loss || current_stop_loss == 0.0))
            ÄndereStopLoss(new_stop_loss);
      }
   }
   
   //--- Ausstieg bei Preis unter/über EMA (Exit when price below/above EMA)
   if(ArraySize(esData.ema_array) >= 1)
   {
      double aktueller_close = iClose(esData.symbol, ES_Timeframe, 0);
      double ema_aktuell = esData.ema_array[0];
      bool exit_bullish = (position_type == POSITION_TYPE_SELL && aktueller_close > ema_aktuell);
      bool exit_bearish = (position_type == POSITION_TYPE_BUY && aktueller_close < ema_aktuell);
      
      if(exit_bullish || exit_bearish)
      {
         Print("TRACE: Exit signal - Close: ", aktueller_close, " EMA: ", ema_aktuell);
         SchließePosition("EMA Crossover Exit");
         
         Print("TRACE: Position closed - trade counter stays at ", esData.trades_in_current_crossover);
      }
   }
   
   //--- Profit-Prüfung nach X Bars (Profit check after X bars)
   if(ES_CloseUnprofitableTrades && esData.trade_open_time != 0 && PositionExistsByMagic(esData.symbol, (ulong)ES_MagicNumber))
   {
      Print("TRACE: Profit check enabled - CloseUnprofitableTrades: ", ES_CloseUnprofitableTrades);
      PrüfeProfitNachBars();
   }
   else if(!ES_CloseUnprofitableTrades)
   {
      Print("TRACE: Profit check disabled - CloseUnprofitableTrades: ", ES_CloseUnprofitableTrades);
   }
}

//+------------------------------------------------------------------+
//| Profit-Prüfung nach X Bars (Profit check after X bars)           |
//+------------------------------------------------------------------+
void PrüfeProfitNachBars()
{
   if(!PositionSelectByMagic(esData.symbol, (ulong)ES_MagicNumber))
   {
      return; // Keine Position offen
   }
   
   datetime current_bar_time = iTime(esData.symbol, ES_Timeframe, 0);
   int bars_since_trade_open = iBarShift(esData.symbol, ES_Timeframe, esData.trade_open_time);
   
   Print("TRACE: Bars since trade open: ", bars_since_trade_open, "/", ES_ProfitCheckBars);
   
   //--- Prüfe ob genügend Bars vergangen sind (Check if enough bars have passed)
   if(bars_since_trade_open >= ES_ProfitCheckBars)
   {
      double position_profit = PositionGetDouble(POSITION_PROFIT);
      double position_volume = PositionGetDouble(POSITION_VOLUME);
      ENUM_POSITION_TYPE position_type = (ENUM_POSITION_TYPE)PositionGetInteger(POSITION_TYPE);
      
      Print("TRACE: Profit check after ", ES_ProfitCheckBars, " bars");
      Print("TRACE: Position Profit: ", position_profit, " USD");
      
      //--- Schließe Position wenn nicht im Profit (Close position if not in profit)
      if(position_profit <= 0)
      {
         Print("TRACE: Position not in profit - closing position");
         SchließePosition("Profit Check - Unprofitable");
         
         //--- Trade-Öffnungszeit zurücksetzen (Reset trade opening time)
         esData.trade_open_time = 0;
         Print("TRACE: Trade open time reset");
      }
      else
      {
         Print("TRACE: Position in profit - keeping position");
         //--- Trade-Öffnungszeit zurücksetzen um weitere Prüfungen zu vermeiden (Reset to avoid further checks)
         esData.trade_open_time = 0;
      }
   }
}

//+------------------------------------------------------------------+
//| Stop Loss ändern (Modify Stop Loss)                             |
//+------------------------------------------------------------------+
void ÄndereStopLoss(double new_stop_loss)
{
   Print("TRACE: Attempting to modify stop loss to: ", new_stop_loss);
   
   bool success = ModifyPositionByMagic(esData.trade, esData.symbol, (ulong)ES_MagicNumber, new_stop_loss, PositionGetDouble(POSITION_TP));
   
   if(success)
   {
      esData.es_last_sl_adjust_success_time = TimeCurrent();
      Print("TRACE: Stop loss modified successfully to: ", new_stop_loss);
   }
   else
   {
      Print("TRACE: Error modifying stop loss - Retcode: ", esData.trade.ResultRetcode());
      Print("TRACE: Error description: ", esData.trade.ResultRetcodeDescription());
   }
}

//+------------------------------------------------------------------+
//| Position schließen (Close position)                             |
//+------------------------------------------------------------------+
void SchließePosition(string reason = "Unknown")
{
   Print("TRACE: Attempting to close position - Reason: ", reason);
   
   bool success = ClosePositionByMagic(esData.trade, esData.symbol, (ulong)ES_MagicNumber);
   
   if(success)
   {
      esData.es_last_sl_adjust_success_time = 0;
      Print("TRACE: Position closed successfully - Reason: ", reason);
   }
   else
   {
      Print("TRACE: Error closing position - Retcode: ", esData.trade.ResultRetcode());
      Print("TRACE: Error description: ", esData.trade.ResultRetcodeDescription());
   }
}

//+------------------------------------------------------------------+
//| Expert tick function                                             |
//+------------------------------------------------------------------+
void ProcessEMASlopeDistance(string symbol)
{
   if(!esData.isInitialized)
      return;

   esData.symbol = symbol;

   const datetime current_bar_time = iTime(esData.symbol, ES_Timeframe, 0);
   const bool new_bar = (current_bar_time != esData.last_bar_time);
   const bool has_position = PositionExistsByMagic(esData.symbol, (ulong)ES_MagicNumber);

   if(ES_UseBarData && !new_bar && !has_position)
      return;

   if(new_bar)
      esData.last_bar_time = current_bar_time;

   BerechneEMA();

   const bool run_signals = (!ES_UseBarData || new_bar);

   if(run_signals && ArraySize(esData.ema_array) > 0)
   {
      double aktueller_close = iClose(esData.symbol, ES_Timeframe, 0);
      double ema_aktuell = esData.ema_array[0];
      double ema_vorher = esData.ema_array[1];
      double point = SymbolInfoDouble(esData.symbol, SYMBOL_POINT);
      double preis_abstand = MathAbs(aktueller_close - ema_aktuell) / point;
      double steigung = (ema_aktuell - ema_vorher) / point;

      if(ES_UseBarData)
      {
         Print("=== DEBUG INFO (Neuer Bar) ===");
         Print("Bar Zeit: ", TimeToString(iTime(esData.symbol, ES_Timeframe, 0)));
      }
      else
      {
         Print("=== DEBUG INFO (Tick) ===");
      }

      Print("Current Close: ", aktueller_close);
      Print("EMA: ", ema_aktuell);
      Print("Price distance: ", preis_abstand, " pips");
      Print("EMA slope: ", steigung, " pips");
      Print("Difference Close-EMA: ", aktueller_close - ema_aktuell);
      Print("Price trigger: ", esData.preis_trigger_aktiv, " Slope trigger: ", esData.steigung_trigger_aktiv);
      Print("Monitoring active: ", esData.überwachung_aktiv);
      Print("Position open: ", PositionExistsByMagic(esData.symbol, (ulong)ES_MagicNumber));
      Print("Trades in current crossover: ", esData.trades_in_current_crossover, "/", ES_MaxTradesPerCrossover);
      Print("==================");
   }

   if(run_signals)
   {
      if(esData.überwachung_aktiv)
      {
         if(ES_UseBarData)
         {
            int bars_since_monitoring = iBarShift(esData.symbol, ES_Timeframe, esData.letzte_überwachung_zeit);
            int timeout_bars = (int)(ES_ÜberwachungTimeout / PeriodSeconds(ES_Timeframe));

            if(bars_since_monitoring > timeout_bars)
            {
               esData.überwachung_aktiv = false;
               esData.preis_trigger_aktiv = false;
               esData.steigung_trigger_aktiv = false;
               Print("Monitoring ended - bar-based timeout (", bars_since_monitoring, " bars)");
            }
         }
         else
         {
            if(TimeCurrent() - esData.letzte_überwachung_zeit > ES_ÜberwachungTimeout)
            {
               esData.überwachung_aktiv = false;
               esData.preis_trigger_aktiv = false;
               esData.steigung_trigger_aktiv = false;
               Print("Monitoring ended - tick-based timeout");
            }
         }
      }

      PrüfeTrigger();
   }

   VerwalteTrades();
}

//+------------------------------------------------------------------+
