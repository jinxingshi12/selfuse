//+------------------------------------------------------------------+
//|                                             SuperTrendEA.mq5     |
//|   Example Expert Advisor using supertrend.mq5 indicator          |
//|   Buys on SuperTrend flip to uptrend and sells on downtrend      |
//+------------------------------------------------------------------+
#property copyright "OpenAI"
#property version   "1.0"
#property strict

#include <Trade/Trade.mqh>

//--- indicator parameters (must match supertrend.mq5 inputs)
input string IndicatorName            = "supertrend"; // Name of the compiled SuperTrend indicator
input int    InpATRPeriod             = 10;           // ATR period
input double InpMultiplier            = 3.0;          // ATR multiplier
input ENUM_APPLIED_PRICE InpPrice     = PRICE_MEDIAN; // Price source
input bool   InpUseWicks              = true;         // Count wicks in calculation

//--- trading parameters
input bool   AllowBuy                 = true;
input bool   AllowSell                = true;
input double FixedLot                 = 0.10;         // Fixed lot if risk-based lot cannot be used
input double RiskPercent              = 1.0;          // % of equity to risk per trade
input double RiskRewardRatio          = 2.0;          // Take profit distance relative to risk
input int    Slippage                 = 3;            // Max slippage in points
input bool   TrailWithSuperTrend      = true;         // Move SL along SuperTrend
input int    MagicNumber              = 20240519;

//--- global
CTrade         trade;
int            stHandle = INVALID_HANDLE;
datetime       lastBarTime = 0;

//+------------------------------------------------------------------+
//| Expert initialization                                            |
//+------------------------------------------------------------------+
int OnInit()
{
   trade.SetExpertMagicNumber(MagicNumber);
   stHandle = iCustom(_Symbol, _Period, IndicatorName, InpATRPeriod, InpMultiplier, InpPrice, InpUseWicks);
   if(stHandle == INVALID_HANDLE)
   {
      Print("Failed to create SuperTrend handle. Error: ", GetLastError());
      return INIT_FAILED;
   }
   return(INIT_SUCCEEDED);
}

//+------------------------------------------------------------------+
//| Expert deinitialization                                          |
//+------------------------------------------------------------------+
void OnDeinit(const int reason)
{
   if(stHandle != INVALID_HANDLE)
      IndicatorRelease(stHandle);
}

//+------------------------------------------------------------------+
//| Get buffer values                                                |
//+------------------------------------------------------------------+
bool GetSuperTrend(int shift, double &value, double &direction)
{
   double valueBuf[2];
   double dirBuf[2];
   if(CopyBuffer(stHandle, 0, shift, 1, valueBuf) <= 0) return false; // main line
   if(CopyBuffer(stHandle, 2, shift, 1, dirBuf)   <= 0) return false; // direction buffer (1 / -1)
   value = valueBuf[0];
   direction = dirBuf[0];
   return true;
}

//+------------------------------------------------------------------+
//| Calculate lot based on SL distance                               |
//+------------------------------------------------------------------+
double CalculateLot(double stopPrice)
{
   double tickValue = SymbolInfoDouble(_Symbol, SYMBOL_TRADE_TICK_VALUE);
   double tickSize  = SymbolInfoDouble(_Symbol, SYMBOL_TRADE_TICK_SIZE);
   double slDistance = MathAbs(stopPrice - (PositionSelect(_Symbol) ? PositionGetDouble(POSITION_PRICE_OPEN) : (Ask + Bid) / 2.0));
   double volumeStep = SymbolInfoDouble(_Symbol, SYMBOL_VOLUME_STEP);
   double minVolume  = SymbolInfoDouble(_Symbol, SYMBOL_VOLUME_MIN);

   // distance converted to price to ticks
   double moneyRisk = AccountInfoDouble(ACCOUNT_EQUITY) * RiskPercent / 100.0;
   double lots = FixedLot;
   if(slDistance > SymbolInfoDouble(_Symbol, SYMBOL_POINT) && tickValue > 0.0 && tickSize > 0.0)
   {
      double ticks = slDistance / tickSize;
      double lotPerTickValue = tickValue / SymbolInfoDouble(_Symbol, SYMBOL_TRADE_CONTRACT_SIZE);
      if(lotPerTickValue > 0)
      {
         lots = moneyRisk / (ticks * tickValue);
      }
   }

   // normalize
   lots = MathMax(minVolume, MathFloor(lots / volumeStep) * volumeStep);
   return lots;
}

//+------------------------------------------------------------------+
//| Check existing positions                                         |
//+------------------------------------------------------------------+
bool HasPosition(int direction)
{
   if(!PositionSelect(_Symbol))
      return false;
   long type = PositionGetInteger(POSITION_TYPE);
   if(direction > 0 && type == POSITION_TYPE_BUY)
      return true;
   if(direction < 0 && type == POSITION_TYPE_SELL)
      return true;
   return false;
}

//+------------------------------------------------------------------+
//| Close opposite                                                   |
//+------------------------------------------------------------------+
void CloseOpposite(int direction)
{
   if(!PositionSelect(_Symbol)) return;
   long type = PositionGetInteger(POSITION_TYPE);
   if((direction > 0 && type == POSITION_TYPE_SELL) || (direction < 0 && type == POSITION_TYPE_BUY))
   {
      trade.PositionClose(_Symbol, Slippage);
   }
}

//+------------------------------------------------------------------+
//| Set SL/TP using RR                                               |
//+------------------------------------------------------------------+
void SetStops(double slPrice, int direction)
{
   double tpPrice = 0;
   double entry   = (direction > 0) ? SymbolInfoDouble(_Symbol, SYMBOL_ASK) : SymbolInfoDouble(_Symbol, SYMBOL_BID);
   double risk = MathAbs(entry - slPrice);
   if(risk <= 0) return;
   double reward = risk * RiskRewardRatio;
   tpPrice = (direction > 0) ? entry + reward : entry - reward;
   trade.SetStopLossPrice(slPrice);
   trade.SetTakeProfitPrice(tpPrice);
}

//+------------------------------------------------------------------+
//| Trailing logic                                                   |
//+------------------------------------------------------------------+
void UpdateTrailing()
{
   if(!TrailWithSuperTrend) return;
   if(!PositionSelect(_Symbol)) return;
   double stValue, stDir;
   if(!GetSuperTrend(0, stValue, stDir)) return;

   long type = PositionGetInteger(POSITION_TYPE);
   double currentSL = PositionGetDouble(POSITION_SL);

   if(type == POSITION_TYPE_BUY && stDir > 0)
   {
      double newSL = stValue;
      if(newSL > currentSL + SymbolInfoDouble(_Symbol, SYMBOL_POINT))
         trade.PositionModify(_Symbol, newSL, PositionGetDouble(POSITION_TP));
   }
   else if(type == POSITION_TYPE_SELL && stDir < 0)
   {
      double newSL = stValue;
      if(newSL < currentSL - SymbolInfoDouble(_Symbol, SYMBOL_POINT))
         trade.PositionModify(_Symbol, newSL, PositionGetDouble(POSITION_TP));
   }
}

//+------------------------------------------------------------------+
//| Main tick                                                        |
//+------------------------------------------------------------------+
void OnTick()
{
   // operate only on new bar to reduce noise
   datetime barTime = iTime(_Symbol, _Period, 0);
   if(barTime == 0 || barTime == lastBarTime)
   {
      UpdateTrailing();
      return;
   }
   lastBarTime = barTime;

   double stCurr, dirCurr, stPrev, dirPrev;
   if(!GetSuperTrend(0, stCurr, dirCurr)) return;
   if(!GetSuperTrend(1, stPrev, dirPrev)) return;

   // Detect flips
   if(dirCurr > 0 && dirPrev < 0)
   {
      if(AllowBuy && !HasPosition(1))
      {
         CloseOpposite(1);
         double sl = stPrev;
         trade.SetDeviationInPoints(Slippage);
         SetStops(sl, 1);
         double lots = CalculateLot(sl);
         trade.Buy(lots, _Symbol, 0, 0, 0, "SuperTrend BUY");
      }
   }
   else if(dirCurr < 0 && dirPrev > 0)
   {
      if(AllowSell && !HasPosition(-1))
      {
         CloseOpposite(-1);
         double sl = stPrev;
         trade.SetDeviationInPoints(Slippage);
         SetStops(sl, -1);
         double lots = CalculateLot(sl);
         trade.Sell(lots, _Symbol, 0, 0, 0, "SuperTrend SELL");
      }
   }

   UpdateTrailing();
}
//+------------------------------------------------------------------+
