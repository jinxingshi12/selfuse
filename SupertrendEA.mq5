//+------------------------------------------------------------------+
//|                                                   SupertrendEA.mq5|
//|   Automated trading EA using the provided supertrend.mq5          |
//+------------------------------------------------------------------+
#property copyright "collar"
#property link      "https://aillm.net"
#property version   "1.0"
#property strict

#include <Trade\Trade.mqh>

input double   Lots                  = 0.10;          // Fixed lot size
input double   MaxSpreadPoints       = 30;            // Maximum allowed spread in points
input double   SlippagePoints        = 5;             // Slippage in points
input bool     UseSuperTrendStop     = true;          // Use SuperTrend line as stop loss
input double   ExtraStopPoints       = 0;             // Additional stop buffer in points
input double   TakeProfitPoints      = 0;             // Optional take profit in points (0 = no TP)
input int      ATRPeriod             = 10;            // SuperTrend ATR period
input double   Multiplier            = 3.0;           // SuperTrend multiplier
input ENUM_APPLIED_PRICE SourcePrice = PRICE_MEDIAN;  // SuperTrend price source
input bool     TakeWicksIntoAccount  = true;          // SuperTrend wick handling
input ulong    MagicNumber           = 24090901;      // Unique identifier for this EA's trades
input bool     CloseOnlyOurMagic     = true;          // Whether to close only trades opened by this EA

//--- Globals
CTrade trade;
int    supertrendHandle = INVALID_HANDLE;
int    prevDirection    = 0;       // 1 = uptrend, -1 = downtrend
long   slippage;                   // cached slippage in points

//+------------------------------------------------------------------+
//| Expert initialization function                                   |
//+------------------------------------------------------------------+
int OnInit()
{
   slippage = (long)SlippagePoints;

   trade.SetExpertMagicNumber((int)MagicNumber);

   supertrendHandle = iCustom(_Symbol, _Period, "supertrend",
                              ATRPeriod, Multiplier, SourcePrice, TakeWicksIntoAccount);
   if(supertrendHandle == INVALID_HANDLE)
   {
      Print("Failed to create SuperTrend handle. Error: ", GetLastError());
      return(INIT_FAILED);
   }

   return(INIT_SUCCEEDED);
}

//+------------------------------------------------------------------+
//| Expert deinitialization function                                 |
//+------------------------------------------------------------------+
void OnDeinit(const int reason)
{
   if(supertrendHandle != INVALID_HANDLE)
      IndicatorRelease(supertrendHandle);
}

//+------------------------------------------------------------------+
//| Helper: check if a new bar formed                                |
//+------------------------------------------------------------------+
bool IsNewBar()
{
   static datetime lastBarTime = 0;
   datetime current = iTime(_Symbol, _Period, 0);
   if(current != lastBarTime)
   {
      lastBarTime = current;
      return true;
   }
   return false;
}

//+------------------------------------------------------------------+
//| Helper: ensure spread is within limits                           |
//+------------------------------------------------------------------+
bool SpreadOK()
{
   long spreadPoints = 0;
   if(!SymbolInfoInteger(_Symbol, SYMBOL_SPREAD, spreadPoints))
      return false;

   return (double)spreadPoints <= MaxSpreadPoints;
}

//+------------------------------------------------------------------+
//| Helper: close all open positions for this symbol                 |
//+------------------------------------------------------------------+
void CloseOpenPositions()
{
   for(int i = PositionsTotal() - 1; i >= 0; --i)
   {
      ulong ticket = PositionGetTicket(i);
      if(ticket == 0)
         continue;

      if(PositionSelectByTicket(ticket))
      {
         if(PositionGetString(POSITION_SYMBOL) != _Symbol)
            continue;

         // If requested, limit to this EA's magic to avoid touching manual or other EA trades
         if(CloseOnlyOurMagic && PositionGetInteger(POSITION_MAGIC) != (long)MagicNumber)
            continue;

         ENUM_POSITION_TYPE type = (ENUM_POSITION_TYPE)PositionGetInteger(POSITION_TYPE);
         if(type == POSITION_TYPE_BUY)
            trade.PositionClose(ticket, slippage);
         else if(type == POSITION_TYPE_SELL)
            trade.PositionClose(ticket, slippage);
      }
   }
}

//+------------------------------------------------------------------+
//| Helper: fetch latest closed bar SuperTrend data                  |
//+------------------------------------------------------------------+
bool GetSuperTrendSignal(int &direction, double &line)
{
   double dirBuffer[];
   double stBuffer[];

   // We read from the last closed bar (shift 1)
   if(CopyBuffer(supertrendHandle, 2, 1, 1, dirBuffer) <= 0)
      return false;
   if(CopyBuffer(supertrendHandle, 0, 1, 1, stBuffer) <= 0)
      return false;

   direction = (int)MathRound(dirBuffer[0]);
   line = stBuffer[0];
   return true;
}

//+------------------------------------------------------------------+
//| Helper: send market order with optional SL/TP                    |
//+------------------------------------------------------------------+
bool OpenPosition(int direction, double stLine)
{
   double price = 0.0, sl = 0.0, tp = 0.0;

   if(direction > 0)
   {
      if(!SymbolInfoDouble(_Symbol, SYMBOL_ASK, price))
         return false;
      if(UseSuperTrendStop)
         sl = stLine - ExtraStopPoints * _Point;
      if(TakeProfitPoints > 0)
         tp = price + TakeProfitPoints * _Point;
      return trade.Buy(Lots, NULL, price, sl, tp, "SuperTrend Buy");
   }
   else if(direction < 0)
   {
      if(!SymbolInfoDouble(_Symbol, SYMBOL_BID, price))
         return false;
      if(UseSuperTrendStop)
         sl = stLine + ExtraStopPoints * _Point;
      if(TakeProfitPoints > 0)
         tp = price - TakeProfitPoints * _Point;
      return trade.Sell(Lots, NULL, price, sl, tp, "SuperTrend Sell");
   }
   return false;
}

//+------------------------------------------------------------------+
//| Expert tick function                                             |
//+------------------------------------------------------------------+
void OnTick()
{
   if(supertrendHandle == INVALID_HANDLE)
      return;

   if(!IsNewBar())
      return;

   if(!SpreadOK())
   {
      Print("Spread too high, skipping bar.");
      return;
   }

   int direction = 0;
   double stLine = 0.0;
   if(!GetSuperTrendSignal(direction, stLine))
      return;

   if(prevDirection == 0)
   {
      prevDirection = direction;
      return; // first data point, nothing to trade yet
   }

   if(direction == prevDirection)
      return;

   // Direction changed -> signal
   CloseOpenPositions();
   if(OpenPosition(direction, stLine))
      Print("Opened ", (direction > 0 ? "BUY" : "SELL"), " on direction change. SL: ", stLine);
   else
      Print("Order send failed. Error: ", GetLastError());

   prevDirection = direction;
}
//+------------------------------------------------------------------+
