//+------------------------------------------------------------------+
//|                                  RSICrossOverReversalStrategy.mqh |
//+------------------------------------------------------------------+

void WeekDays_Init()
{
   rcData.WeekDays[0] = RC_Sunday;
   rcData.WeekDays[1] = RC_Monday;
   rcData.WeekDays[2] = RC_Tuesday;
   rcData.WeekDays[3] = RC_Wednesday;
   rcData.WeekDays[4] = RC_Thursday;
   rcData.WeekDays[5] = RC_Friday;
   rcData.WeekDays[6] = RC_Saturday;
}

bool WeekDays_Check(datetime aTime)
{
   MqlDateTime stm;
   TimeToStruct(aTime, stm);
   return(rcData.WeekDays[stm.day_of_week]);
}

bool RC_HourInWindow(const int h, const int beginRaw, const int endRaw)
{
   const int b = beginRaw % 24;
   const int e = endRaw % 24;
   if(b == e)
      return false;
   if(b < e)
      return (h >= b && h < e);
   return (h >= b || h < e);
}

bool RC_TradingHoursAllow(const int currentHour)
{
   return RC_HourInWindow(currentHour, RC_tradingHourOneBegin, RC_tradingHourOneEnd)
       || RC_HourInWindow(currentHour, RC_tradingHourTwoBegin, RC_tradingHourTwoEnd);
}

int TimeHour(datetime when = 0)
{
   if(when == 0) when = TimeCurrent();
   MqlDateTime dt;
   TimeToStruct(when, dt);
   return dt.hour;
}

bool InitRSICrossOverReversal(string symbol)
{
   WeekDays_Init();
   
   rcData.symbol = symbol;
   rcData.previousRSIDef = 0;
   rcData.lastTradeTime = 0;
   rcData.bartime = 0;
   rcData.lastBarTime = 0;
   
   // Check if symbol exists
   if(!SymbolSelect(symbol, true))
   {
      Print("RSICrossOverReversal: Symbol '", symbol, "' not available in Market Watch. Please add it to Market Watch or check symbol name.");
      return false;
   }
   
   Sleep(100); // Wait for symbol to be ready
   
   rcData.rsiHandle = iRSI(symbol, RC_TimeFrame1, RC_rsiPeriod, PRICE_CLOSE);
   if(rcData.rsiHandle == INVALID_HANDLE)
   {
      Print("RSICrossOverReversal: Error creating RSI handle for '", symbol, "'");
      return false;
   }
   
   rcData.emaHandle = iMA(symbol, RC_TimeFrame2, RC_emaPeriod, 0, MODE_EMA, PRICE_CLOSE);
   if(rcData.emaHandle == INVALID_HANDLE)
   {
      Print("RSICrossOverReversal: Error creating EMA handle for '", symbol, "'");
      return false;
   }
   
   rcData.trade.SetExpertMagicNumber(RC_MagicNumber);
   rcData.trade.SetDeviationInPoints(RC_slippage);
   rcData.isInitialized = true;
   Print("RSICrossOverReversal: Successfully initialized for symbol '", symbol, "'");
   return true;
}

void DeinitRSICrossOverReversal()
{
   if(rcData.rsiHandle != INVALID_HANDLE)
      IndicatorRelease(rcData.rsiHandle);
   if(rcData.emaHandle != INVALID_HANDLE)
      IndicatorRelease(rcData.emaHandle);
}

void Close_Position_MN(ulong magicNumber)
{
   ClosePositionByMagic(rcData.trade, rcData.symbol, (int)magicNumber);
}

void ApplyTrailingStop()
{
   if(!PositionSelectByMagic(rcData.symbol, RC_MagicNumber))
      return;
   
   ulong PositionTicket = PositionGetInteger(POSITION_TICKET);
   ENUM_POSITION_TYPE trade_type = (ENUM_POSITION_TYPE)PositionGetInteger(POSITION_TYPE);
   string symbol = rcData.symbol;
   
   double POINT = SymbolInfoDouble(symbol, SYMBOL_POINT);
   int DIGIT = (int)SymbolInfoInteger(symbol, SYMBOL_DIGITS);
   
   if(trade_type == POSITION_TYPE_BUY)
   {
      double Bid = NormalizeDouble(SymbolInfoDouble(symbol, SYMBOL_BID), DIGIT);
      
      if(Bid - PositionGetDouble(POSITION_PRICE_OPEN) > NormalizeDouble(POINT * RC_TrailingStop, DIGIT))
      {
         if(PositionGetDouble(POSITION_SL) < NormalizeDouble(Bid - POINT * RC_TrailingStop, DIGIT))
         {
            ModifyPositionByMagic(rcData.trade, symbol, RC_MagicNumber,
                                 NormalizeDouble(Bid - POINT * RC_TrailingStop, DIGIT),
                                 PositionGetDouble(POSITION_TP));
         }
      }
   }
   else if(trade_type == POSITION_TYPE_SELL)
   {
      double Ask = NormalizeDouble(SymbolInfoDouble(symbol, SYMBOL_ASK), DIGIT);
      
      if((PositionGetDouble(POSITION_PRICE_OPEN) - Ask) > NormalizeDouble(POINT * RC_TrailingStop, DIGIT))
      {
         if((PositionGetDouble(POSITION_SL) > NormalizeDouble(Ask + POINT * RC_TrailingStop, DIGIT)) ||
            (PositionGetDouble(POSITION_SL) == 0))
         {
            ModifyPositionByMagic(rcData.trade, symbol, RC_MagicNumber,
                                NormalizeDouble(Ask + POINT * RC_TrailingStop, DIGIT),
                                PositionGetDouble(POSITION_TP));
         }
      }
   }
}

void ProcessRSICrossOverReversal(string symbol)
{
   // Skip if not initialized (symbol not available)
   if(!rcData.isInitialized)
      return;
      
   rcData.symbol = symbol; // Update symbol in case it changed
   if(rcData.bartime == iTime(rcData.symbol, RC_BarTimeFrame, 0))
      return;
   rcData.bartime = iTime(rcData.symbol, RC_BarTimeFrame, 0);
   
   double rsi[];
   if(CopyBuffer(rcData.rsiHandle, 0, 0, 2, rsi) <= 0)
      return;
   
   double ema[];
   if(CopyBuffer(rcData.emaHandle, 0, 0, 2, ema) <= 0)
      return;
   
   datetime currentTime = TimeCurrent();
   int currentHour = TimeHour(TimeCurrent());
   
   if(!WeekDays_Check(TimeTradeServer()))
   {
      Close_Position_MN(RC_MagicNumber);
      return;
   }
   
   if(!RC_TradingHoursAllow(currentHour))
   {
      Close_Position_MN(RC_MagicNumber);
      return;
   }
   
   bool hasPosition = PositionExistsByMagic(rcData.symbol, RC_MagicNumber);
   
   double currentRSI = rsi[0];
   double previousRSI = rsi[1];
   
   if(rcData.previousRSIDef == 0)
   {
      rcData.previousRSIDef = currentRSI;
      return;
   }
   
   double currentEMA = ema[0];
   double previousEMA = ema[1];
   
   double emaSlope = (currentEMA - previousEMA) * 100;
   const double closeCurr = iClose(rcData.symbol, RC_TimeFrame1, 0);
   // Raw (close-EMA)*10 blows past threshold on XAUUSD (~2600) almost every bar — blocks all entries.
   // Compare distance in pips so RC_emaDistanceThreshold matches intent across symbols.
   const double point = SymbolInfoDouble(rcData.symbol, SYMBOL_POINT);
   const int symDig = (int)SymbolInfoInteger(rcData.symbol, SYMBOL_DIGITS);
   const double pipMult = (symDig == 3 || symDig == 5) ? 10.0 : 1.0;
   const double pipSize = (point > 0.0 ? point * pipMult : point);
   const double priceToEmaPips = (pipSize > 0.0 ? MathAbs(closeCurr - currentEMA) / pipSize : 0.0);
   
   bool isBuyPosition = false;
   bool isSellPosition = false;
   if(hasPosition)
   {
      if(PositionSelectByMagic(rcData.symbol, RC_MagicNumber))
      {
         ENUM_POSITION_TYPE positionType = (ENUM_POSITION_TYPE)PositionGetInteger(POSITION_TYPE);
         if(positionType == POSITION_TYPE_BUY)
            isBuyPosition = true;
         else if(positionType == POSITION_TYPE_SELL)
            isSellPosition = true;
      }
   }
   
   ApplyTrailingStop();
   
   bool cooldownPassed = (currentTime - rcData.lastTradeTime) >= RC_cooldownSeconds;
   const bool isTrendStrong = RC_UseTrendStrengthFilter &&
      (MathAbs(emaSlope) > RC_emaSlopeThreshold || priceToEmaPips > RC_emaDistanceThreshold);
   
   if(isBuyPosition && currentRSI > RC_exitBuyRSI)
   {
      Close_Position_MN(RC_MagicNumber);
      rcData.lastTradeTime = currentTime;
   }
   
   if(isSellPosition && currentRSI < RC_exitSellRSI)
   {
      Close_Position_MN(RC_MagicNumber);
      rcData.lastTradeTime = currentTime;
   }
   
   if(isTrendStrong)
   {
      Close_Position_MN(RC_MagicNumber);
      rcData.lastTradeTime = currentTime;
   }

   if(!isTrendStrong &&
      currentRSI < RC_overboughtLevel - RC_entryRSISellSpread && rcData.previousRSIDef >= RC_overboughtLevel &&
      !isSellPosition && !hasPosition && cooldownPassed)
   {
      // V4-iter7-D: HTF EMA200 veto on SELL when underlying is in clear HTF uptrend.
      bool htfVetoSell = false;
      if(RC_VetoSellAgainstHTF)
      {
         static int s_htfHandle = INVALID_HANDLE;
         static string s_htfSymbol = "";
         static ENUM_TIMEFRAMES s_htfTF = PERIOD_CURRENT;
         static int s_htfPer = 0;
         if(s_htfHandle == INVALID_HANDLE || s_htfSymbol != rcData.symbol
            || s_htfTF != RC_HTF_TimeFrame || s_htfPer != RC_HTF_EMAPeriod)
         {
            if(s_htfHandle != INVALID_HANDLE) IndicatorRelease(s_htfHandle);
            s_htfHandle = iMA(rcData.symbol, RC_HTF_TimeFrame, RC_HTF_EMAPeriod, 0, MODE_EMA, PRICE_CLOSE);
            s_htfSymbol = rcData.symbol; s_htfTF = RC_HTF_TimeFrame; s_htfPer = RC_HTF_EMAPeriod;
         }
         if(s_htfHandle != INVALID_HANDLE)
         {
            double htfBuf[]; ArraySetAsSeries(htfBuf, true);
            int need = MathMax(RC_HTF_SlopeBars + 2, 3);
            if(CopyBuffer(s_htfHandle, 0, 0, need, htfBuf) >= need)
            {
               double maNow  = htfBuf[1];
               double maPast = htfBuf[1 + RC_HTF_SlopeBars];
               double bid    = SymbolInfoDouble(rcData.symbol, SYMBOL_BID);
               // veto only when HTF strongly up: EMA rising AND price above EMA.
               if(maNow > maPast && bid > maNow)
                  htfVetoSell = true;
            }
         }
      }
      if(!htfVetoSell)
      {
      const double vol = United_NormalizeVolume(rcData.symbol, g_RC_LotSize);
      if(vol > 0.0)
      {
         rcData.trade.SetExpertMagicNumber(RC_MagicNumber);
         double sellSL = 0.0;
         if(RC_SellHardSL_Points > 0.0)
         {
            const double pt   = SymbolInfoDouble(rcData.symbol, SYMBOL_POINT);
            const int    dig  = (int)SymbolInfoInteger(rcData.symbol, SYMBOL_DIGITS);
            const double bid  = SymbolInfoDouble(rcData.symbol, SYMBOL_BID);
            sellSL = NormalizeDouble(bid + RC_SellHardSL_Points * pt, dig);
         }
         if(!United_MayOpenNewEntry(rcData.symbol, (ulong)RC_MagicNumber, false))
            return;
         if(rcData.trade.Sell(vol, rcData.symbol, 0.0, sellSL, 0.0, "RSI Overbought Crossover Sell #M" + IntegerToString(RC_MagicNumber)))
            rcData.lastTradeTime = currentTime;
      }
      }
   }

   if(!isTrendStrong &&
      currentRSI > RC_oversoldLevel + RC_entryRSIBuySpread && rcData.previousRSIDef <= RC_oversoldLevel &&
      !isBuyPosition && !hasPosition && cooldownPassed)
   {
      const double vol = United_NormalizeVolume(rcData.symbol, g_RC_LotSize);
      if(vol > 0.0)
      {
         rcData.trade.SetExpertMagicNumber(RC_MagicNumber);
         if(!United_MayOpenNewEntry(rcData.symbol, (ulong)RC_MagicNumber, true))
            return;
         if(rcData.trade.Buy(vol, rcData.symbol, 0.0, 0.0, 0.0, "RSI Oversold Crossover Buy #M" + IntegerToString(RC_MagicNumber)))
            rcData.lastTradeTime = currentTime;
      }
   }
   
   rcData.previousRSIDef = currentRSI;
}

//+------------------------------------------------------------------+
