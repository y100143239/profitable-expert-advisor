//+------------------------------------------------------------------+
//|                                      RSIMidPointHijackStrategy.mqh |
//+------------------------------------------------------------------+

double RM_NormalizedLot(const string sym)
{
   return United_NormalizeVolume(sym, g_RM_LotSize);
}

bool RM_LTFConfirmHandleNeeded()
{
   return (RM_InpLTFConfirmEnable || RM_InpLTFSoftScaleEnable);
}

bool IsNewBar(string symbol)
{
   datetime time[];
   if(CopyTime(symbol, RM_InpTimeframe, 0, 1, time) > 0)
   {
      if(time[0] != rmData.lastBarTime)
      {
         rmData.lastBarTime = time[0];
         return true;
      }
   }
   return false;
}

bool IsWithinTradingHours(int startHour, int endHour)
{
   MqlDateTime currentTime;
   TimeToStruct(TimeCurrent(), currentTime);
   
   if(startHour <= endHour)
      return (currentTime.hour >= startHour && currentTime.hour < endHour);
   else
      return (currentTime.hour >= startHour || currentTime.hour < endHour);
}

bool HasPosition(string symbol, int magic)
{
   return PositionExistsByMagic(symbol, magic);
}

bool HasProfitablePosition(int excludeMagic)
{
   bool hasProfitable = false;
   for(int i = PositionsTotal() - 1; i >= 0; i--)
   {
      if(rmData.positionInfo.SelectByIndex(i))
      {
         if(rmData.positionInfo.Magic() != excludeMagic)
         {
            double profit = rmData.positionInfo.Profit();
            if(profit > RM_InpLockProfitThreshold * _Point)
            {
               hasProfitable = true;
               if(RM_InpCloseOppositeTrades)
               {
                  if((excludeMagic == RM_InpMagicNumberRSIFollow && rmData.positionInfo.Magic() == RM_InpMagicNumberRSIReverse) ||
                     (excludeMagic == RM_InpMagicNumberRSIReverse && rmData.positionInfo.Magic() == RM_InpMagicNumberRSIFollow) ||
                     (excludeMagic == RM_InpMagicNumberEMACross && (rmData.positionInfo.Magic() == RM_InpMagicNumberRSIReverse || rmData.positionInfo.Magic() == RM_InpMagicNumberRSIFollow)) ||
                     ((excludeMagic == RM_InpMagicNumberRSIFollow || excludeMagic == RM_InpMagicNumberRSIReverse) && rmData.positionInfo.Magic() == RM_InpMagicNumberEMACross))
                  {
                     ClosePosition(rmData.symbol, (int)rmData.positionInfo.Magic());
                  }
               }
            }
         }
      }
   }
   return hasProfitable;
}

bool IsRSIReverseInCooldown(string symbol)
{
   if(RM_InpRSIReverseCooldownBars <= 0)
      return false;
      
   if(!rmData.rsiReverseInCooldown)
      return false;
      
   datetime time[];
   if(CopyTime(symbol, RM_InpTimeframe, 0, 1, time) > 0)
   {
      datetime currentBarTime = time[0];
      datetime cooldownEndTime = rmData.rsiReverseLastCloseTime + RM_InpRSIReverseCooldownBars * PeriodSeconds(RM_InpTimeframe);
      
      if(currentBarTime >= cooldownEndTime)
      {
         rmData.rsiReverseInCooldown = false;
         return false;
      }
   }
   
   return true;
}

bool RM_LTFConfirmSignalPasses(const bool isBuy, bool &known)
{
   known = false;

   if(rmData.ltfConfirmRsiHandle == INVALID_HANDLE)
      return false;

   double ltfRsi[];
   ArraySetAsSeries(ltfRsi, true);
   if(CopyBuffer(rmData.ltfConfirmRsiHandle, 0, 1, 1, ltfRsi) != 1)
      return false;

   known = true;

   if(isBuy)
      return (ltfRsi[0] >= RM_InpLTFConfirmBuyMin);

   return (ltfRsi[0] <= RM_InpLTFConfirmSellMax);
}

bool RM_LTFConfirmAllows(const bool isBuy)
{
   if(!RM_InpLTFConfirmEnable)
      return true;

   bool known = false;
   return (RM_LTFConfirmSignalPasses(isBuy, known) && known);
}

double RM_RSIFollowLot(const string sym, const bool isBuy)
{
   double lot = g_RM_LotSize;
   if(RM_InpLTFSoftScaleEnable && RM_InpLTFSoftScaleWeakLotFactor > 0.0 && RM_InpLTFSoftScaleWeakLotFactor < 1.0)
   {
      bool known = false;
      const bool ltfPasses = RM_LTFConfirmSignalPasses(isBuy, known);
      if(!known || !ltfPasses)
         lot *= RM_InpLTFSoftScaleWeakLotFactor;
   }
   return United_NormalizeVolume(sym, lot);
}

bool RM_LTFConfirmExpired(const int ageBars)
{
   return (RM_InpLTFConfirmEnable && RM_InpLTFConfirmMaxDelayBars > 0 && ageBars > RM_InpLTFConfirmMaxDelayBars);
}

void CheckRSIFollowStrategy(string symbol)
{
   if(!IsWithinTradingHours(RM_InpRSIFollowStartHour, RM_InpRSIFollowEndHour))
   {
      if(RM_InpRSIFollowCloseOutsideHours)
      {
         if(HasPosition(symbol, RM_InpMagicNumberRSIFollow))
            ClosePosition(symbol, RM_InpMagicNumberRSIFollow);
      }
      return;
   }
   
   if(RM_InpEnableStrategyLock && HasProfitablePosition(RM_InpMagicNumberRSIFollow))
      return;
   
   if(rmData.rsiOverbought)
      rmData.rsiOverboughtAgeBars++;
   if(rmData.rsiOversold)
      rmData.rsiOversoldAgeBars++;

   if(rmData.lastBarRSI > RM_InpRSIOverbought)
   {
      rmData.rsiOverbought = true;
      rmData.rsiOverboughtAgeBars = 0;
   }
   else if(rmData.lastBarRSI < RM_InpRSIOversold)
   {
      rmData.rsiOversold = true;
      rmData.rsiOversoldAgeBars = 0;
   }

   if(rmData.rsiOverbought && RM_LTFConfirmExpired(rmData.rsiOverboughtAgeBars))
   {
      rmData.rsiOverbought = false;
      rmData.rsiOverboughtAgeBars = 0;
   }
   if(rmData.rsiOversold && RM_LTFConfirmExpired(rmData.rsiOversoldAgeBars))
   {
      rmData.rsiOversold = false;
      rmData.rsiOversoldAgeBars = 0;
   }
   
   const double rsiFollowSellReentry = (RM_InpRSIFollowUseReentryBand ? MathMin((double)RM_InpRSIExitLevel, (double)RM_InpRSIOverbought) : (double)RM_InpRSIExitLevel);
   const double rsiFollowBuyReentry = (RM_InpRSIFollowUseReentryBand ? MathMax((double)RM_InpRSIExitLevel, (double)RM_InpRSIOversold) : (double)RM_InpRSIExitLevel);

   if(rmData.rsiOverbought && rmData.lastBarRSI < rsiFollowSellReentry)
   {
      if(!HasPosition(symbol, RM_InpMagicNumberRSIFollow))
      {
         rmData.trade.SetExpertMagicNumber(RM_InpMagicNumberRSIFollow);
         const double vol = RM_RSIFollowLot(symbol, false);
         if(vol > 0.0)
         {
            if(!RM_LTFConfirmAllows(false))
               return;
            if(!United_MayOpenNewEntry(symbol, (ulong)RM_InpMagicNumberRSIFollow, false))
               return;
            rmData.trade.Sell(vol, symbol, 0, 0, 0, "RSI Follow SELL #M" + IntegerToString(RM_InpMagicNumberRSIFollow));
         }
      }
      rmData.rsiOverbought = false;
      rmData.rsiOverboughtAgeBars = 0;
   }
   else if(rmData.rsiOversold && rmData.lastBarRSI > rsiFollowBuyReentry)
   {
      if(!HasPosition(symbol, RM_InpMagicNumberRSIFollow))
      {
         rmData.trade.SetExpertMagicNumber(RM_InpMagicNumberRSIFollow);
         const double vol = RM_RSIFollowLot(symbol, true);
         if(vol > 0.0)
         {
            if(!RM_LTFConfirmAllows(true))
               return;
            if(!United_MayOpenNewEntry(symbol, (ulong)RM_InpMagicNumberRSIFollow, true))
               return;
            rmData.trade.Buy(vol, symbol, 0, 0, 0, "RSI Follow BUY #M" + IntegerToString(RM_InpMagicNumberRSIFollow));
         }
      }
      rmData.rsiOversold = false;
      rmData.rsiOversoldAgeBars = 0;
   }
}

void CheckRSIReverseStrategy(string symbol)
{
   if(!IsWithinTradingHours(RM_InpRSIReverseStartHour, RM_InpRSIReverseEndHour))
   {
      if(RM_InpRSIReverseCloseOutsideHours)
      {
         if(HasPosition(symbol, RM_InpMagicNumberRSIReverse))
            ClosePosition(symbol, RM_InpMagicNumberRSIReverse);
      }
      return;
   }
   
   if(RM_InpEnableStrategyLock && HasProfitablePosition(RM_InpMagicNumberRSIReverse))
      return;
      
   if(IsRSIReverseInCooldown(symbol))
      return;
   
   if(rmData.lastBarRSIReverse > RM_InpRSIReverseOverbought)
      rmData.rsiReverseOverbought = true;
   else if(rmData.lastBarRSIReverse < RM_InpRSIReverseOversold)
      rmData.rsiReverseOversold = true;
   
   if(rmData.rsiReverseOverbought && rmData.lastBarRSIReverse < RM_InpRSIReverseCrossLevel)
   {
      if(!HasPosition(symbol, RM_InpMagicNumberRSIReverse))
      {
         rmData.trade.SetExpertMagicNumber(RM_InpMagicNumberRSIReverse);
         const double vol = RM_NormalizedLot(symbol);
         if(vol > 0.0)
         {
            if(!United_MayOpenNewEntry(symbol, (ulong)RM_InpMagicNumberRSIReverse, false))
               return;
            rmData.trade.Sell(vol, symbol, 0, 0, 0, "RSI Reverse SELL #M" + IntegerToString(RM_InpMagicNumberRSIReverse));
         }
      }
      rmData.rsiReverseOverbought = false;
   }
   else if(rmData.rsiReverseOversold && rmData.lastBarRSIReverse > RM_InpRSIReverseCrossLevel)
   {
      if(!HasPosition(symbol, RM_InpMagicNumberRSIReverse))
      {
         rmData.trade.SetExpertMagicNumber(RM_InpMagicNumberRSIReverse);
         const double vol = RM_NormalizedLot(symbol);
         if(vol > 0.0)
         {
            if(!United_MayOpenNewEntry(symbol, (ulong)RM_InpMagicNumberRSIReverse, true))
               return;
            rmData.trade.Buy(vol, symbol, 0, 0, 0, "RSI Reverse BUY #M" + IntegerToString(RM_InpMagicNumberRSIReverse));
         }
      }
      rmData.rsiReverseOversold = false;
   }
}

void CheckEMACrossStrategy(string symbol)
{
   if(!IsWithinTradingHours(RM_InpEMACrossStartHour, RM_InpEMACrossEndHour))
   {
      if(RM_InpEMACrossCloseOutsideHours)
      {
         if(HasPosition(symbol, RM_InpMagicNumberEMACross))
            ClosePosition(symbol, RM_InpMagicNumberEMACross);
      }
      return;
   }
   
   if(RM_InpEnableStrategyLock && HasProfitablePosition(RM_InpMagicNumberEMACross))
      return;
   
   if(rmData.lastBarEMAPrev < rmData.lastBarClosePrev && rmData.lastBarEMA > rmData.lastBarClose)
   {
      rmData.emaCrossBuySignal = true;
      rmData.emaCrossSellSignal = false;
      rmData.emaCrossSignalBar = 0;
   }
   else if(rmData.lastBarEMAPrev > rmData.lastBarClosePrev && rmData.lastBarEMA < rmData.lastBarClose)
   {
      rmData.emaCrossSellSignal = true;
      rmData.emaCrossBuySignal = false;
      rmData.emaCrossSignalBar = 0;
   }
   
   if(RM_InpUseEMADistanceEntry)
   {
      if(rmData.emaCrossBuySignal)
      {
         bool distanceConditionMet = true;
         double emaHistory[], closeHistory[];
         ArraySetAsSeries(emaHistory, true);
         ArraySetAsSeries(closeHistory, true);
         
         if(CopyBuffer(rmData.emaHandle, 0, 0, RM_InpEMADistancePeriod, emaHistory) > 0 &&
            CopyClose(symbol, RM_InpTimeframe, 0, RM_InpEMADistancePeriod, closeHistory) > 0)
         {
            double point = SymbolInfoDouble(symbol, SYMBOL_POINT);
            for(int i = 0; i < RM_InpEMADistancePeriod; i++)
            {
               double distance = (closeHistory[i] - emaHistory[i]) / point;
               if(distance < RM_InpEMADistancePips)
               {
                  distanceConditionMet = false;
                  break;
               }
            }
            
            if(distanceConditionMet && !HasPosition(symbol, RM_InpMagicNumberEMACross))
            {
               rmData.trade.SetExpertMagicNumber(RM_InpMagicNumberEMACross);
               const double vol = RM_NormalizedLot(symbol);
               if(vol > 0.0)
               {
                  if(!United_MayOpenNewEntry(symbol, (ulong)RM_InpMagicNumberEMACross, true))
                     return;
                  rmData.trade.Buy(vol, symbol, 0, 0, 0, "EMA Cross Distance BUY #M" + IntegerToString(RM_InpMagicNumberEMACross));
               }
               rmData.emaCrossBuySignal = false;
            }
         }
      }
      else if(rmData.emaCrossSellSignal)
      {
         bool distanceConditionMet = true;
         double emaHistory[], closeHistory[];
         ArraySetAsSeries(emaHistory, true);
         ArraySetAsSeries(closeHistory, true);
         
         if(CopyBuffer(rmData.emaHandle, 0, 0, RM_InpEMADistancePeriod, emaHistory) > 0 &&
            CopyClose(symbol, RM_InpTimeframe, 0, RM_InpEMADistancePeriod, closeHistory) > 0)
         {
            double point = SymbolInfoDouble(symbol, SYMBOL_POINT);
            for(int i = 0; i < RM_InpEMADistancePeriod; i++)
            {
               double distance = (emaHistory[i] - closeHistory[i]) / point;
               if(distance < RM_InpEMADistancePips)
               {
                  distanceConditionMet = false;
                  break;
               }
            }
            
            if(distanceConditionMet && !HasPosition(symbol, RM_InpMagicNumberEMACross))
            {
               rmData.trade.SetExpertMagicNumber(RM_InpMagicNumberEMACross);
               const double vol = RM_NormalizedLot(symbol);
               if(vol > 0.0)
               {
                  if(!United_MayOpenNewEntry(symbol, (ulong)RM_InpMagicNumberEMACross, false))
                     return;
                  rmData.trade.Sell(vol, symbol, 0, 0, 0, "EMA Cross Distance SELL #M" + IntegerToString(RM_InpMagicNumberEMACross));
               }
               rmData.emaCrossSellSignal = false;
            }
         }
      }
   }
   else
   {
      if(rmData.lastBarEMAPrev < rmData.lastBarClosePrev && rmData.lastBarEMA > rmData.lastBarClose)
      {
         if(!HasPosition(symbol, RM_InpMagicNumberEMACross))
         {
            rmData.trade.SetExpertMagicNumber(RM_InpMagicNumberEMACross);
            const double vol = RM_NormalizedLot(symbol);
            if(vol > 0.0)
            {
               if(!United_MayOpenNewEntry(symbol, (ulong)RM_InpMagicNumberEMACross, true))
                  return;
               rmData.trade.Buy(vol, symbol, 0, 0, 0, "EMA Cross BUY #M" + IntegerToString(RM_InpMagicNumberEMACross));
            }
         }
      }
      else if(rmData.lastBarEMAPrev > rmData.lastBarClosePrev && rmData.lastBarEMA < rmData.lastBarClose)
      {
         if(!HasPosition(symbol, RM_InpMagicNumberEMACross))
         {
            rmData.trade.SetExpertMagicNumber(RM_InpMagicNumberEMACross);
            const double vol = RM_NormalizedLot(symbol);
            if(vol > 0.0)
            {
               if(!United_MayOpenNewEntry(symbol, (ulong)RM_InpMagicNumberEMACross, false))
                  return;
               rmData.trade.Sell(vol, symbol, 0, 0, 0, "EMA Cross SELL #M" + IntegerToString(RM_InpMagicNumberEMACross));
            }
         }
      }
   }
   
   if(rmData.emaCrossBuySignal || rmData.emaCrossSellSignal)
   {
      rmData.emaCrossSignalBar++;
      if(rmData.emaCrossSignalBar > RM_InpEMADistancePeriod * 2)
      {
         rmData.emaCrossBuySignal = false;
         rmData.emaCrossSellSignal = false;
      }
   }
}

void CheckExitConditions(string symbol)
{
   if(RM_InpEnableRSIFollow)
   {
      if(HasPosition(symbol, RM_InpMagicNumberRSIFollow))
      {
         if(PositionSelectByMagic(symbol, RM_InpMagicNumberRSIFollow))
         {
            ENUM_POSITION_TYPE posType = (ENUM_POSITION_TYPE)PositionGetInteger(POSITION_TYPE);
            if((posType == POSITION_TYPE_BUY && rmData.lastBarRSI < RM_InpRSIExitLevel) ||
               (posType == POSITION_TYPE_SELL && rmData.lastBarRSI > RM_InpRSIExitLevel))
            {
               ClosePosition(symbol, RM_InpMagicNumberRSIFollow);
            }
         }
      }
   }
   
   if(RM_InpEnableRSIReverse)
   {
      if(HasPosition(symbol, RM_InpMagicNumberRSIReverse))
      {
         if(PositionSelectByMagic(symbol, RM_InpMagicNumberRSIReverse))
         {
            ENUM_POSITION_TYPE posType = (ENUM_POSITION_TYPE)PositionGetInteger(POSITION_TYPE);
            if((posType == POSITION_TYPE_BUY && rmData.lastBarRSIReverse < RM_InpRSIReverseExitLevel) ||
               (posType == POSITION_TYPE_SELL && rmData.lastBarRSIReverse > RM_InpRSIReverseExitLevel))
            {
               ClosePosition(symbol, RM_InpMagicNumberRSIReverse);
            }
         }
      }
   }
   
   if(RM_InpEnableEMACross)
   {
      if(HasPosition(symbol, RM_InpMagicNumberEMACross))
      {
         if(PositionSelectByMagic(symbol, RM_InpMagicNumberEMACross))
         {
            ENUM_POSITION_TYPE posType = (ENUM_POSITION_TYPE)PositionGetInteger(POSITION_TYPE);
            if((posType == POSITION_TYPE_BUY && rmData.lastBarEMA > rmData.lastBarClose) ||
               (posType == POSITION_TYPE_SELL && rmData.lastBarEMA < rmData.lastBarClose))
            {
               ClosePosition(symbol, RM_InpMagicNumberEMACross);
            }
         }
      }
   }
}

void ClosePosition(string symbol, int magic)
{
   if(!PositionExistsByMagic(symbol, magic))
      return;
   
   ulong ticket = GetPositionTicketByMagic(symbol, magic);
   if(ticket == 0)
      return;
   
   if(magic == RM_InpMagicNumberRSIReverse)
   {
      if(PositionSelectByTicketSymbolAndMagic(ticket, symbol, magic))
      {
         datetime time[];
         if(CopyTime(symbol, RM_InpTimeframe, 0, 1, time) > 0)
         {
            rmData.rsiReverseLastCloseTime = time[0];
            double profit = PositionGetDouble(POSITION_PROFIT);
            if(!RM_InpRSIReverseCooldownOnLoss || profit < 0)
            {
               rmData.rsiReverseInCooldown = true;
            }
         }
      }
   }
   
   ClosePositionByMagic(rmData.trade, symbol, magic);
}

bool InitRSIMidPointHijack(string symbol)
{
   rmData.symbol = symbol;
   rmData.rsiOverbought = false;
   rmData.rsiOversold = false;
   rmData.rsiOverboughtAgeBars = 0;
   rmData.rsiOversoldAgeBars = 0;
   rmData.rsiReverseOverbought = false;
   rmData.rsiReverseOversold = false;
   rmData.emaCrossBuySignal = false;
   rmData.emaCrossSellSignal = false;
   rmData.emaCrossSignalBar = 0;
   rmData.rsiReverseInCooldown = false;
   rmData.ltfConfirmRsiHandle = INVALID_HANDLE;
   rmData.lastBarRSI = 0;
   rmData.lastBarRSIReverse = 0;
   rmData.lastBarEMA = 0;
   rmData.lastBarClose = 0;
   rmData.lastBarEMAPrev = 0;
   rmData.lastBarClosePrev = 0;
   
   // Check if symbol exists
   if(!SymbolSelect(symbol, true))
   {
      Print("RSIMidPointHijack: Symbol '", symbol, "' not available in Market Watch. Please add it to Market Watch or check symbol name.");
      return false;
   }
   
   Sleep(100); // Wait for symbol to be ready
   
   rmData.rsiHandle = iRSI(symbol, RM_InpTimeframe, RM_InpRSIPeriod, PRICE_CLOSE);
   rmData.rsiReverseHandle = iRSI(symbol, RM_InpTimeframe, RM_InpRSIReversePeriod, PRICE_CLOSE);
   if(RM_LTFConfirmHandleNeeded())
      rmData.ltfConfirmRsiHandle = iRSI(symbol, RM_InpLTFConfirmTimeframe, RM_InpLTFConfirmRSIPeriod, PRICE_CLOSE);
   rmData.emaHandle = iMA(symbol, RM_InpTimeframe, RM_InpEMAPeriod, 0, MODE_EMA, PRICE_CLOSE);
   
   if(rmData.rsiHandle == INVALID_HANDLE || rmData.rsiReverseHandle == INVALID_HANDLE || rmData.emaHandle == INVALID_HANDLE ||
      (RM_LTFConfirmHandleNeeded() && rmData.ltfConfirmRsiHandle == INVALID_HANDLE))
   {
      Print("RSIMidPointHijack: Error creating indicators for '", symbol, "'");
      return false;
   }
   
   rmData.trade.SetExpertMagicNumber(RM_InpMagicNumberRSIFollow);
   rmData.trade.SetMarginMode();
   rmData.trade.SetTypeFillingBySymbol(symbol);
   rmData.trade.SetDeviationInPoints(10);
   
   datetime time[];
   if(CopyTime(symbol, RM_InpTimeframe, 0, 1, time) > 0)
      rmData.lastBarTime = time[0];
   
   rmData.isInitialized = true;
   Print("RSIMidPointHijack: Successfully initialized for symbol '", symbol, "'");
   return true;
}

void DeinitRSIMidPointHijack()
{
   if(rmData.rsiHandle != INVALID_HANDLE) IndicatorRelease(rmData.rsiHandle);
   if(rmData.rsiReverseHandle != INVALID_HANDLE) IndicatorRelease(rmData.rsiReverseHandle);
   if(rmData.ltfConfirmRsiHandle != INVALID_HANDLE) IndicatorRelease(rmData.ltfConfirmRsiHandle);
   if(rmData.emaHandle != INVALID_HANDLE) IndicatorRelease(rmData.emaHandle);
}

void ProcessRSIMidPointHijack(string symbol)
{
   // Skip if not initialized (symbol not available)
   if(!rmData.isInitialized)
      return;
      
   rmData.symbol = symbol; // Update symbol in case it changed
   const bool newBar = IsNewBar(rmData.symbol);
   if(!newBar)
   {
      if(RM_InpIntrabarExitMonitorEnable)
      {
         double rsiTick[], rsiReverseTick[], emaTick[], closeTick[];
         ArraySetAsSeries(rsiTick, true);
         ArraySetAsSeries(rsiReverseTick, true);
         ArraySetAsSeries(emaTick, true);
         ArraySetAsSeries(closeTick, true);

         if(CopyBuffer(rmData.rsiHandle, 0, 0, 1, rsiTick) > 0)
            rmData.lastBarRSI = rsiTick[0];
         if(CopyBuffer(rmData.rsiReverseHandle, 0, 0, 1, rsiReverseTick) > 0)
            rmData.lastBarRSIReverse = rsiReverseTick[0];
         if(CopyBuffer(rmData.emaHandle, 0, 0, 1, emaTick) > 0)
            rmData.lastBarEMA = emaTick[0];
         if(CopyClose(rmData.symbol, RM_InpTimeframe, 0, 1, closeTick) > 0)
            rmData.lastBarClose = closeTick[0];

         CheckExitConditions(rmData.symbol);
      }
      return;
   }
      
   double rsi[], rsiReverse[], ema[], close[];
   ArraySetAsSeries(rsi, true);
   ArraySetAsSeries(rsiReverse, true);
   ArraySetAsSeries(ema, true);
   ArraySetAsSeries(close, true);
   
   rmData.lastBarEMAPrev = rmData.lastBarEMA;
   rmData.lastBarClosePrev = rmData.lastBarClose;
   
   if(CopyBuffer(rmData.rsiHandle, 0, 0, 1, rsi) > 0)
      rmData.lastBarRSI = rsi[0];
      
   if(CopyBuffer(rmData.rsiReverseHandle, 0, 0, 1, rsiReverse) > 0)
      rmData.lastBarRSIReverse = rsiReverse[0];
      
   if(CopyBuffer(rmData.emaHandle, 0, 0, 1, ema) > 0)
      rmData.lastBarEMA = ema[0];
      
   if(CopyClose(rmData.symbol, RM_InpTimeframe, 0, 1, close) > 0)
      rmData.lastBarClose = close[0];
      
   if(RM_InpEnableRSIFollow)
      CheckRSIFollowStrategy(rmData.symbol);
   if(RM_InpEnableRSIReverse)
      CheckRSIReverseStrategy(rmData.symbol);
   if(RM_InpEnableEMACross)
      CheckEMACrossStrategy(rmData.symbol);
   
   CheckExitConditions(rmData.symbol);
}

//+------------------------------------------------------------------+
