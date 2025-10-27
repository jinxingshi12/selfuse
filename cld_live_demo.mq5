//+------------------------------------------------------------------+
//|                                       SMC_GoldEA_LiveDemo.mq5   |
//|                        Copyright 2024, LuxAlgo & Smart Money Concepts |
//|                                       https://www.luxalgo.com/   |
//+------------------------------------------------------------------+


#property copyright "Copyright 2024, LuxAlgo & Smart Money Concepts"  // 属性：版权声明
#property link "https://www.luxalgo.com/"  // 属性：LuxAlgo官网链接
#property version "4.00"  // 属性：EA版本号
#property description "ULTRA CONSERVATIVE SMC Gold EA - Optimized for Fast Profits & Capital Preservation"  // 属性：描述 - 超保守SMC金EA，优化快速盈利和资本保护
#property description "✅ M15/M5 Timeframes | ✅ 0.5% Risk | ✅ Fast Profit Taking | ✅ Tight Stops"  // 属性：描述 - 支持M15/M5时间框架，0.5%风险，快速盈利，紧止损

#include <Trade\Trade.mqh>  // 包含：MQL5交易操作库，用于执行买卖操作
#include <Trade\PositionInfo.mqh>  // 包含：仓位信息库，用于获取仓位数据
#include <Trade\AccountInfo.mqh>  // 包含：账户信息库，用于获取账户余额等
#include <Indicators\Indicators.mqh>  // 包含：指标库，用于技术指标操作

//--- Input Parameters  // 输入参数：用户可配置的EA设置
input group "═════════ STRATEGY SETTINGS ═════════"  // 参数组：策略设置
input ENUM_TIMEFRAMES BaseTimeframe = PERIOD_M15;                  // 基础时间框架（市场结构分析） - 默认M15，快速交易
input ENUM_TIMEFRAMES ConfirmTimeframe = PERIOD_M5;                // 确认时间框架（信号确认） - 默认M5，更快
input ENUM_TIMEFRAMES HigherTimeframe = PERIOD_H1;                 // 更高时间框架（市场偏向） - 默认H1，判断趋势
input int MaxOpenTrades = 5;                                       // 最大开仓数 - 默认2，增加交易机会
input int Slippage = 40;                                           // 滑点点数（点） - 默认30，适应实时交易

input group "═════════ RISK MANAGEMENT ═════════"  // 参数组：风险管理
input double RiskPerTradePercent = 2;                           // 每笔交易风险百分比（账户余额%） - 默认0.5%，保守
input int StopLossPips = 4000;                                       // 默认止损点数（XAUUSD 8点） - 默认80，紧止损
input int TakeProfitPips = 7000;                                    // 默认止盈点数（XAUUSD 16点） - 默认160，快速盈利
input bool UseAutoRR = true;                                       // 是否使用自动风险回报比 - 默认true
input double MinRiskReward = 1.6;                                  // 最小风险回报比 - 默认2.0，确保盈利空间


input group "═════════ SMC INDICATOR SETTINGS ═════════"  // 参数组：SMC指标设置
input string SMC_Indicator_Name = "LuxAlgo - Smart Money Concepts"; // SMC指标名称 - 默认LuxAlgo SMC

input int SMC_HigherTime_Lookback = 10;                                 // 更高时间框架（市场偏向） - 默认H1，判断趋势


input int SMC_OB_Lookback = 10;                                     // 订单块回溯周期（根K线） - 默认10，短周期
input int SMC_FVG_Lookback = 8;                                     // 公平价值缺口回溯周期（根K线） - 默认8，短周期
input bool UseOrderBlocks = true;                                   // 是否交易订单块 - 默认true
input bool UseFairValueGaps = true;                                 // 是否交易公平价值缺口 - 默认true
input bool UseLiquidityGrabs = true;                                // 是否交易流动性抓取 - 默认true
input double MinOBSize = 100;                                        // 最小订单块大小（点） - 默认15（1.5点），小块更多信号

input group "═════════ TRADING FILTERS ═════════"  // 参数组：交易过滤器

input bool UseSessionFilter = true;                                // 是否启用交易时段过滤 - 默认true
input int StartHour1 = 23;                                     // 伦敦时段开始（GMT小时） - 默认7
input int EndHour1 = 24;                                      // 伦敦时段结束（GMT小时） - 默认16

input int StartHour2 = 00;                                   // 纽约时段开始（GMT小时） - 默认13
input int EndHour2 = 21;                                     // 纽约时段结束（GMT小时） - 默认21

input int weekdaystart = 1; 
input int weekdayend = 5; 






input bool UseVolatilityFilter = true;                             // 是否启用波动过滤 - 默认true
input double MaxATRPercent = 1.3;                                  // 最大ATR百分比 - 默认1.2%，适度波动

input bool UseSpreadFilter = true;                                 // 是否启用点差过滤 - 默认true
input double MaxSpreadPips = 70;                                   // 最大点差（点） - 默认50，适应实时交易

input group "═════════ LIVE DEMO SETTINGS ═════════"  // 参数组：实时演示设置
input int MagicNumber = 20241225;                                  // EA魔术号 - 默认20241225，标识EA交易
input string TradeComment = "SMC-Gold-LiveDemo";                   // 交易备注 - 默认SMC-Gold-LiveDemo
input bool EnableAlerts = true;                                    // 是否启用交易提醒 - 默认true

input group "═════════ DAILY PROFIT OPTIMIZATION ═════════"  // 参数组：每日盈利优化
input double DailyProfitTarget = 400;                            // 每日盈利目标（美元） - 默认50
input double DailyMaxLoss = -200.0;                                // 每日最大亏损（美元） - 默认-25
input int MaxDailyTrades = 15;                                    // 每日最大交易数 - 默认15
input bool StopAfterDailyTarget = true;                           // 是否在达到每日目标后停止 - 默认true
input bool EnableAggressiveMode = false;                          // 是否启用激进模式 - 默认false
input int TradeFrequencyMinutes = 15;                             // 交易最小间隔分钟 - 默认15，增加机会

input group "═════════ ADVANCED RISK MANAGEMENT ═════════"  // 参数组：高级风险管理
input bool UseDynamicSLTP = true;                                 // 是否使用ATR动态止损止盈 - 默认true
input double ATRMultiplierSL = 1.0;                               // ATR止损倍数 - 默认1.0，紧
input double ATRMultiplierTP = 2.5;                               // ATR止盈倍数 - 默认2.5，快

//盈亏平衡
input bool UseBreakeven = true;                                    // 是否移动止损到盈亏平衡 - 默认true
input int BreakevenPips = 50;                                      // 盈亏平衡触发距离（点） - 默认40，快速保护

//分级平仓
input bool UseScaledExits = true;                                 // 是否启用分级平仓 - 默认true
input double FirstExitPercent = 50.0;                             // 第一次平仓百分比 - 默认50%，快速
input int FirstExitPips = 60;                                     // 第一次平仓触发（点） - 默认60（6点），非常快
input double SecondExitPercent = 50;                            // 第二次平仓百分比 - 默认30%
input int SecondExitPips = 100;                                   // 第二次平仓触发（点） - 默认100（10点）

//追踪止损
input bool UseTrailingStop = true;                                 // 是否启用追踪止损 - 默认true
input int TrailingStopPips = 6000;                                   // 追踪止损距离（点） - 默认60，紧

//大额部分平仓
input bool UseLargeProfit = true;                              // 是否启用部分平仓 - 默认true
input double LargeProfitPercent = 50;                          // 部分平仓百分比 - 默认50%
input int LargeProfitPips = 10000;                                  // 部分平仓触发点数（8点） - 默认80，快速盈利

// 7. EMERGENCY EXIT on smaller loss (much tighter)
input bool UseEmergencyLoss = true;   
input int EmergencyLossPoints = -100;

// 8. Emergency exit on opposing structure signals (SMC-based)
input int SMCExitProfitPoints = 50;

//Time-based management for losing positions (more aggressive)
input bool Time_exit = false;
input int MaxPositionAgeMinutes = 120;
input int MaxAgeLossPoints = -50;

input int PointMultiplier1 = 10;

input int MinConfluenceLevel = 1;                                 // 最小汇合水平（1-5） - 默认1，更多机会
input bool RequireHigherTFConfirmation = false;                   // 是否要求更高时间框架确认 - 默认false，放松
input bool UseConservativeEntries = false;                        // 是否使用保守进入逻辑 - 默认false，放松
input double SignalValidityHours = 4.0;                          // 信号有效小时数 - 默认4，较长窗口

input group "═════════ SMC SIGNAL STRENGTH ═════════"  // 参数组：SMC信号强度
input bool EnableManualTesting = false;                           // 是否启用手动测试 - 默认false，实时禁用
input bool TriggerBuyTrade = false;                               // 是否立即触发买入 - 默认false
input bool TriggerSellTrade = false;                              // 是否立即触发卖出 - 默认false
input bool CloseAllTrades = false;                                // 是否关闭所有交易 - 默认false
input double ManualLotSize = 0.01;                                // 手动交易手数 - 默认0.01


//--- Enhanced Global Variables
// Simplified trading objects
struct CTrade_Simple
{
    ulong magic_number;
    uint deviation;
    ENUM_ORDER_TYPE_FILLING filling_type;
    bool async_mode;
    
    void SetExpertMagicNumber(ulong magic) { magic_number = magic; }
    void SetDeviationInPoints(uint dev) { deviation = dev; }
    void SetTypeFilling(ENUM_ORDER_TYPE_FILLING fill) { filling_type = fill; }
    void SetAsyncMode(bool async) { async_mode = async; }
    
    bool Buy(double volume, string symbol, double price, double sl, double tp, string comment)
    {
        MqlTradeRequest request;
        MqlTradeResult result;
        ZeroMemory(request);
        ZeroMemory(result);
        
        request.action = TRADE_ACTION_DEAL;
        request.symbol = symbol;
        request.volume = volume;
        request.type = ORDER_TYPE_BUY;
        request.price = price;
        request.sl = sl;
        request.tp = tp;
        request.deviation = deviation;
        request.magic = magic_number;
        request.comment = comment;
        request.type_filling = filling_type;
        
        return OrderSend(request, result);
    }
    
    bool Sell(double volume, string symbol, double price, double sl, double tp, string comment)
    {
        MqlTradeRequest request;
        MqlTradeResult result;
        ZeroMemory(request);
        ZeroMemory(result);
        
        request.action = TRADE_ACTION_DEAL;
        request.symbol = symbol;
        request.volume = volume;
        request.type = ORDER_TYPE_SELL;
        request.price = price;
        request.sl = sl;
        request.tp = tp;
        request.deviation = deviation;
        request.magic = magic_number;
        request.comment = comment;
        request.type_filling = filling_type;
        
        return OrderSend(request, result);
    }
    
    bool PositionClose(ulong ticket)
    {
        if (!PositionSelectByTicket(ticket))
            return false;
            
        MqlTradeRequest request;
        MqlTradeResult result;
        ZeroMemory(request);
        ZeroMemory(result);
        
        request.action = TRADE_ACTION_DEAL;
        request.symbol = PositionGetString(POSITION_SYMBOL);
        request.volume = PositionGetDouble(POSITION_VOLUME);
        request.type = (PositionGetInteger(POSITION_TYPE) == POSITION_TYPE_BUY) ? ORDER_TYPE_SELL : ORDER_TYPE_BUY;
        request.price = (PositionGetInteger(POSITION_TYPE) == POSITION_TYPE_BUY) ? 
                       SymbolInfoDouble(request.symbol, SYMBOL_BID) : 
                       SymbolInfoDouble(request.symbol, SYMBOL_ASK);
        request.deviation = deviation;
        request.magic = magic_number;
        request.position = ticket;
        
        return OrderSend(request, result);
    }
    
    bool PositionModify(ulong ticket, double sl, double tp)
    {
        if (!PositionSelectByTicket(ticket))
            return false;
            
        MqlTradeRequest request;
        MqlTradeResult result;
        ZeroMemory(request);
        ZeroMemory(result);
        
        request.action = TRADE_ACTION_SLTP;
        request.symbol = PositionGetString(POSITION_SYMBOL);
        request.sl = sl;
        request.tp = tp;
        request.position = ticket;
        
        return OrderSend(request, result);
    }
    
    bool PositionClosePartial(ulong ticket, double volume)
    {
        if (!PositionSelectByTicket(ticket))
            return false;
            
        MqlTradeRequest request;
        MqlTradeResult result;
        ZeroMemory(request);
        ZeroMemory(result);
        
        request.action = TRADE_ACTION_DEAL;
        request.symbol = PositionGetString(POSITION_SYMBOL);
        request.volume = volume;
        request.type = (PositionGetInteger(POSITION_TYPE) == POSITION_TYPE_BUY) ? ORDER_TYPE_SELL : ORDER_TYPE_BUY;
        request.price = (PositionGetInteger(POSITION_TYPE) == POSITION_TYPE_BUY) ? 
                       SymbolInfoDouble(request.symbol, SYMBOL_BID) : 
                       SymbolInfoDouble(request.symbol, SYMBOL_ASK);
        request.deviation = deviation;
        request.magic = magic_number;
        request.position = ticket;
        
        return OrderSend(request, result);
    }
};

CTrade_Simple Trade;

//--- Global Variables
double PointMultiplier;
datetime LastTickTime;
datetime LastTradeTime = 0;
int ATR_Handle = INVALID_HANDLE;
int RSI_Handle = INVALID_HANDLE;
int SMC_Base_Handle = INVALID_HANDLE;
int SMC_Confirm_Handle = INVALID_HANDLE;
int SMC_Higher_Handle = INVALID_HANDLE;
bool SMC_Available = false;

//--- Daily Profit Tracking Variables
double DailyStartBalance = 0.0;
datetime LastDayCheck = 0;
bool DailyTargetReached = false;
int DailyTradeCount = 0;
int no_signal_counter = 0;        // Counter for consecutive periods without SMC signals

//--- Enhanced SMC Buffer Mapping
enum ENUM_SMC_BUFFERS
{
    BUFFER_BULLISH_BOS = 0,
    BUFFER_BEARISH_BOS = 1,
    BUFFER_BULLISH_CHOCH = 2,
    BUFFER_BEARISH_CHOCH = 3,
    BUFFER_BULLISH_OB_HIGH = 4,
    BUFFER_BULLISH_OB_LOW = 5,
    BUFFER_BEARISH_OB_HIGH = 6,
    BUFFER_BEARISH_OB_LOW = 7,
    BUFFER_BULLISH_FVG_HIGH = 8,
    BUFFER_BULLISH_FVG_LOW = 9,
    BUFFER_BEARISH_FVG_HIGH = 10,
    BUFFER_BEARISH_FVG_LOW = 11,
    BUFFER_EQ_HIGHS = 12,
    BUFFER_EQ_LOWS = 13,
    BUFFER_LIQUIDITY_GRAB_HIGH = 14,
    BUFFER_LIQUIDITY_GRAB_LOW = 15
};

//--- Market Structure Types
enum ENUM_MARKET_BIAS
{
    BIAS_BULLISH,
    BIAS_BEARISH,
    BIAS_NEUTRAL
};

enum ENUM_TRADE_TYPE
{
    TRADE_ORDER_BLOCK,
    TRADE_FAIR_VALUE_GAP,
    TRADE_LIQUIDITY_GRAB,
    TRADE_BOS_BREAKOUT,
    TRADE_CHOCH_REVERSAL,
    TRADE_NONE
};

struct SMarketConditions
{
    double atr_value;
    double atr_percent;
    double rsi_value;
    double current_spread;
    bool is_volatile;
    bool is_trending;
    ENUM_MARKET_BIAS trend_direction;
};

struct SMarketStructure
{
    bool bullish_bos;
    bool bearish_bos;
    bool bullish_choch;
    bool bearish_choch;
    double recent_high;
    double recent_low;
    datetime high_time;
    datetime low_time;
    int structure_strength;
};

struct SOrderBlocks
{
    double bullish_ob_high;
    double bullish_ob_low;
    double bearish_ob_high;
    double bearish_ob_low;
    datetime ob_time;
    bool is_valid;
    double size_pips;
};

struct SFairValueGaps
{
    double bullish_fvg_high;
    double bullish_fvg_low;
    double bearish_fvg_high;
    double bearish_fvg_low;
    datetime fvg_time;
    bool is_valid;
    double size_pips;
};

struct SLiquidityLevels
{
    double equal_highs;
    double equal_lows;
    double swing_highs;
    double swing_lows;
    bool liquidity_grab_high;
    bool liquidity_grab_low;
    datetime grab_time;
};

//+------------------------------------------------------------------+
//| Expert initialization function                                   |
//+------------------------------------------------------------------+
int OnInit()
{

    //--- Validate demo account (optional safety check)
    if (!AccountInfoInteger(ACCOUNT_TRADE_MODE) == ACCOUNT_TRADE_MODE_DEMO)
    {
        Print("⚠️ WARNING: This EA is designed for DEMO accounts!");
        Print("   Current account type: ", AccountInfoInteger(ACCOUNT_TRADE_MODE));
    }

    //--- Initialize trading objects
    Trade.SetExpertMagicNumber(MagicNumber);
    Trade.SetDeviationInPoints(Slippage);
    Trade.SetTypeFilling(ORDER_FILLING_FOK);
    Trade.SetAsyncMode(false);

    //--- Calculate point multiplier for XAUUSD
    //--- Calculate point multiplier for XAUUSD  // 计算XAUUSD点数乘数
          // 更健壮的自适应代码
      double point = SymbolInfoDouble(_Symbol, SYMBOL_POINT);
      if (point == 0.01) // 两位小数报价
          PointMultiplier = point * PointMultiplier1 * 0.1; // 0.010
      else if (point == 0.001) // 三位小数报价
          PointMultiplier = point * PointMultiplier1; // 0.010
   
    Print("💎 Point Multiplier: ", PointMultiplier);

    //--- Create core indicator handles
    ATR_Handle = iATR(_Symbol, PERIOD_H1, 14);
    RSI_Handle = iRSI(_Symbol, PERIOD_H1, 14, PRICE_CLOSE);
    
    //--- Validate essential indicators
    if (ATR_Handle == INVALID_HANDLE || RSI_Handle == INVALID_HANDLE)
    {
        Print("❌ Error creating essential indicator handles (ATR/RSI)!");
        return INIT_FAILED;
    }

    //--- Create SMC indicator handles for MASTERPIECE trading
    SMC_Base_Handle = iCustom(_Symbol, BaseTimeframe, SMC_Indicator_Name);
    SMC_Confirm_Handle = iCustom(_Symbol, ConfirmTimeframe, SMC_Indicator_Name);
    SMC_Higher_Handle = iCustom(_Symbol, HigherTimeframe, SMC_Indicator_Name);
    
    //--- Check SMC indicator availability (REQUIRED for MASTERPIECE trading)
    SMC_Available = (SMC_Base_Handle != INVALID_HANDLE && 
                     SMC_Confirm_Handle != INVALID_HANDLE && 
                     SMC_Higher_Handle != INVALID_HANDLE);
    
    if (!SMC_Available)
    {
        Print("❌ SMC Indicator not found - please install 'LuxAlgo - Smart Money Concepts'");
        Print("   This MASTERPIECE EA requires the SMC indicator for advanced trading");
        return INIT_FAILED;
    }
    else
    {
        Print("✅ SMC Indicator loaded successfully on all timeframes");
        Print("   📊 Base: ", EnumToString(BaseTimeframe));
        Print("   📊 Confirm: ", EnumToString(ConfirmTimeframe));
        Print("   📊 Higher: ", EnumToString(HigherTimeframe));
    }

    //--- Wait for indicators to initialize
    Print("⏳ Initializing MASTERPIECE SMC intelligence...");
    Sleep(2000); // Wait 2 seconds for live trading

    //--- Test indicator readiness
    if (!AreIndicatorsReady())
    {
        Print("⚠️ Warning: Indicators may not be ready yet. EA will wait during OnTick.");
    }

    //--- Validate symbol
    if (_Symbol != "XAUUSD")
    {
        Print("⚠️ Warning: EA optimized for XAUUSD, current symbol: ", _Symbol);
    }


    return INIT_SUCCEEDED;
}

//+------------------------------------------------------------------+
//| Expert deinitialization function                                 |
//+------------------------------------------------------------------+
void OnDeinit(const int reason)
{
    Print("📴 EA shutting down. Reason: ", reason);

    //--- Release indicators
    if (SMC_Base_Handle != INVALID_HANDLE)
        IndicatorRelease(SMC_Base_Handle);
    if (SMC_Confirm_Handle != INVALID_HANDLE)
        IndicatorRelease(SMC_Confirm_Handle);
    if (SMC_Higher_Handle != INVALID_HANDLE)
        IndicatorRelease(SMC_Higher_Handle);
    if (ATR_Handle != INVALID_HANDLE)
        IndicatorRelease(ATR_Handle);
    if (RSI_Handle != INVALID_HANDLE)
        IndicatorRelease(RSI_Handle);
}

//+------------------------------------------------------------------+
//| Check if indicators are ready                                    |
//+------------------------------------------------------------------+
bool AreIndicatorsReady()
{
    double test_atr[], test_rsi[];
    ArrayResize(test_atr, 1);
    ArrayResize(test_rsi, 1);
    
    int atr_result = CopyBuffer(ATR_Handle, 0, 0, 1, test_atr);
    int rsi_result = CopyBuffer(RSI_Handle, 0, 0, 1, test_rsi);
    
    bool ready = (atr_result > 0 && test_atr[0] != EMPTY_VALUE && 
                  rsi_result > 0 && test_rsi[0] != EMPTY_VALUE);
    
    if (ready)
    {
        Print("✅ All indicators ready! ATR: ", DoubleToString(test_atr[0], 5), 
              " | RSI: ", DoubleToString(test_rsi[0], 2));
    }
    
    return ready;
}

//+------------------------------------------------------------------+
//| Expert tick function - ENHANCED MASTERPIECE VERSION            |
//+------------------------------------------------------------------+
void OnTick()
{
    //--- Check if indicators are ready
    static bool indicators_ready = false;
    if (!indicators_ready)
    {
        if (!AreIndicatorsReady())
        {
            static int wait_counter = 0;
            wait_counter++;
            if (wait_counter % 500 == 0) // Every 500 ticks
            {
                Print("⏳ Waiting for indicators... (", wait_counter, " ticks)");
            }
            return;
        }
        indicators_ready = true;
        Print("✅ All indicators ready - Starting MASTERPIECE SMC trading!");
    }

    //--- Check for manual testing (demo only)
    if (EnableManualTesting)
    {
        HandleManualTesting();
    }

    //--- Basic trading environment checks
    if (!IsValidTradingEnvironment())
        return;

    //--- Prevent multiple trades on same tick
    if (TimeCurrent() == LastTickTime)
        return;

    //--- Get market conditions with enhanced monitoring
    SMarketConditions conditions = GetMarketConditions();
    
    //--- Enhanced market monitoring (every 10 ticks)
    static int monitor_counter = 0;
    monitor_counter++;
    if (monitor_counter >= 50)
    {
        monitor_counter = 0;
        PrintMarketStatus(conditions);
    }

    //--- Apply trading filters
    if (!PassesFilters(conditions))
        return;

    //--- Main SMC trading logic with MASTERPIECE enhancements
    CheckForSMCTrades(conditions);

    //--- Enhanced position management
    ManageOpenPositions(conditions);

    LastTickTime = TimeCurrent();
}

//+------------------------------------------------------------------+
//| Enhanced Market Status Monitor                                  |
//+------------------------------------------------------------------+
void PrintMarketStatus(SMarketConditions &conditions)
{
    static datetime last_status_time = 0;
    
    // Print status every 5 minutes
    if (TimeCurrent() - last_status_time < 300)
        return;
        
    last_status_time = TimeCurrent();
    
    // Get current position count
    int buy_positions = CountPositionsByMagic(MagicNumber, POSITION_TYPE_BUY);
    int sell_positions = CountPositionsByMagic(MagicNumber, POSITION_TYPE_SELL);
    
    // Get higher timeframe bias
    ENUM_MARKET_BIAS htf_bias = GetHigherTimeframeBias();
    
    // Get market structure
    SMarketStructure base_structure = GetMarketStructure(SMC_Base_Handle);
    
    Print("═══════════════════════════════════════");
    Print("🚀 SMC GOLD EA MASTERPIECE - MARKET STATUS");
    Print("═══════════════════════════════════════");
    Print("📊 Time: ", TimeToString(TimeCurrent()));
    Print("📈 Current Price: ", DoubleToString(SymbolInfoDouble(_Symbol, SYMBOL_BID), _Digits));
    Print("📊 Spread: ", DoubleToString(conditions.current_spread, 1), " pips");
    Print("📊 ATR: ", DoubleToString(conditions.atr_value, _Digits), " (", DoubleToString(conditions.atr_percent, 2), "%)");
    Print("📊 RSI: ", DoubleToString(conditions.rsi_value, 2));
    Print("📊 Volatility: ", conditions.is_volatile ? "HIGH" : "NORMAL");
    Print("📊 Trend: ", EnumToString(conditions.trend_direction));
    Print("📊 HTF Bias: ", EnumToString(htf_bias));
    Print("📊 Base Structure - Bull BOS: ", base_structure.bullish_bos ? "YES" : "NO");
    Print("📊 Base Structure - Bear BOS: ", base_structure.bearish_bos ? "YES" : "NO");
    Print("📊 Base Structure - Bull CHoCH: ", base_structure.bullish_choch ? "YES" : "NO");
    Print("📊 Base Structure - Bear CHoCH: ", base_structure.bearish_choch ? "YES" : "NO");
    Print("💼 Open Positions: ", buy_positions + sell_positions, " (", buy_positions, " BUY, ", sell_positions, " SELL)");
    Print("💰 Account Balance: $", DoubleToString(AccountInfoDouble(ACCOUNT_BALANCE), 2));
    Print("💰 Account Equity: $", DoubleToString(AccountInfoDouble(ACCOUNT_EQUITY), 2));
    Print("═══════════════════════════════════════");
}

//+------------------------------------------------------------------+
//| SMC Trading Logic for Live Demo - ENHANCED DEBUG VERSION       |
//+------------------------------------------------------------------+
void CheckForSMCTrades(SMarketConditions &conditions)
{
    MqlTick current_tick;
    if (!SymbolInfoTick(_Symbol, current_tick))
        return;

    //--- Prevent too frequent trading - REDUCED for more opportunities
    if (TimeCurrent() - LastTradeTime < 900) // 15 minutes minimum between trades (was 30 minutes)
        return;

    //--- Get market structure analysis with debugging
    ENUM_MARKET_BIAS higher_tf_bias = GetHigherTimeframeBias();
    SMarketStructure base_structure = GetMarketStructure(SMC_Base_Handle);
    SMarketStructure confirm_structure = GetMarketStructure(SMC_Confirm_Handle);

    //--- Get SMC components with debugging
    SOrderBlocks order_blocks = GetOrderBlocks(SMC_Base_Handle);
    SFairValueGaps fvgs = GetFairValueGaps(SMC_Base_Handle);
    SLiquidityLevels liquidity = GetLiquidityLevels(SMC_Higher_Handle);
    
    //--- DEBUG: Print detailed SMC analysis every 30 seconds for troubleshooting
    static datetime last_debug_time = 0;
    if (TimeCurrent() - last_debug_time >= 30) // Every 30 seconds for intensive debugging
    {
        last_debug_time = TimeCurrent();
        Print("🔍 INTENSIVE SMC ANALYSIS DEBUG:");
        Print("   📊 HTF Bias: ", EnumToString(higher_tf_bias));
        Print("   📊 Base - Bull BOS: ", base_structure.bullish_bos ? "YES" : "NO");
        Print("   📊 Base - Bear BOS: ", base_structure.bearish_bos ? "YES" : "NO");
        Print("   📊 Base - Bull CHoCH: ", base_structure.bullish_choch ? "YES" : "NO");
        Print("   📊 Base - Bear CHoCH: ", base_structure.bearish_choch ? "YES" : "NO");
        Print("   📊 Base Structure Strength: ", base_structure.structure_strength);
        Print("   📊 Order Blocks Valid: ", order_blocks.is_valid ? "YES" : "NO");
        
        if (order_blocks.is_valid)
        {
            Print("   📊 Bull OB High: ", DoubleToString(order_blocks.bullish_ob_high, _Digits));
            Print("   📊 Bull OB Low: ", DoubleToString(order_blocks.bullish_ob_low, _Digits));
            Print("   📊 Bear OB High: ", DoubleToString(order_blocks.bearish_ob_high, _Digits));
            Print("   📊 Bear OB Low: ", DoubleToString(order_blocks.bearish_ob_low, _Digits));
            Print("   📊 OB Size: ", DoubleToString(order_blocks.size_pips, 1), " pips");
        }
        else
        {
            Print("   ❌ No valid Order Blocks found");
        }
        
        Print("   📊 FVGs Valid: ", fvgs.is_valid ? "YES" : "NO");
        
        if (fvgs.is_valid)
        {
            Print("   📊 Bull FVG High: ", DoubleToString(fvgs.bullish_fvg_high, _Digits));
            Print("   📊 Bull FVG Low: ", DoubleToString(fvgs.bullish_fvg_low, _Digits));
            Print("   📊 Bear FVG High: ", DoubleToString(fvgs.bearish_fvg_high, _Digits));
            Print("   📊 Bear FVG Low: ", DoubleToString(fvgs.bearish_fvg_low, _Digits));
            Print("   📊 FVG Size: ", DoubleToString(fvgs.size_pips, 1), " pips");
        }
        else
        {
            Print("   ❌ No valid FVGs found");
        }
        
        Print("   📊 Liquidity Grab High: ", liquidity.liquidity_grab_high ? "YES" : "NO");
        Print("   📊 Liquidity Grab Low: ", liquidity.liquidity_grab_low ? "YES" : "NO");
        Print("   📊 Current Price: ", DoubleToString(current_tick.ask, _Digits));
        Print("   📊 Min Confluence Required: ", MinConfluenceLevel);
        Print("   📊 Conservative Entries: ", UseConservativeEntries ? "ENABLED" : "DISABLED");
        Print("   📊 Higher TF Confirmation: ", RequireHigherTFConfirmation ? "REQUIRED" : "NOT REQUIRED");
        Print("   📊 Use Order Blocks: ", UseOrderBlocks ? "YES" : "NO");
        Print("   📊 Use FVGs: ", UseFairValueGaps ? "YES" : "NO");
        Print("   📊 Use Liquidity: ", UseLiquidityGrabs ? "YES" : "NO");
    }

    //--- Check for buy setups with enhanced debugging
    if (CountPositionsByMagic(MagicNumber, POSITION_TYPE_BUY) < MaxOpenTrades)
    {
        ENUM_TRADE_TYPE buy_setup = AnalyzeBuyOpportunity(higher_tf_bias, base_structure,
                                                          confirm_structure, order_blocks,
                                                          fvgs, liquidity, current_tick.ask, conditions);

        if (buy_setup != TRADE_NONE)
        {
            int confluence_score = CalculateConfluenceScore(buy_setup, base_structure, confirm_structure, 
                                                           order_blocks, fvgs, liquidity, true);
            
            Print("🚀 BUY OPPORTUNITY FOUND!");
            Print("   📊 Setup Type: ", EnumToString(buy_setup));
            Print("   ⭐ Confluence Score: ", confluence_score, "/5 (Required: ", MinConfluenceLevel, ")");
            
            if (confluence_score >= MinConfluenceLevel)
            {
                Print("🚀 SMC BUY SIGNAL DETECTED!");
                Print("   📊 Setup: ", EnumToString(buy_setup));
                Print("   ⭐ Confluence Score: ", confluence_score, "/5");
                Print("   📈 Higher TF Bias: ", EnumToString(higher_tf_bias));
                
                ExecuteSMCBuyTrade(current_tick.ask, buy_setup, confluence_score, conditions);
                no_signal_counter = 0; // Reset counter when trade is executed
            }
            else
            {
                Print("⚠️ BUY signal confluence too low: ", confluence_score, "/", MinConfluenceLevel);
                
                // If confluence is just 1 below minimum and we have a good setup, consider it
                if (confluence_score == (MinConfluenceLevel - 1) && buy_setup == TRADE_ORDER_BLOCK)
                {
                    Print("🔄 Considering marginal BUY Order Block signal (", confluence_score, "/", MinConfluenceLevel, ")");
                    static datetime last_marginal_buy = 0;
                    
                    if (TimeCurrent() - last_marginal_buy > 2400) // Only one marginal trade per 40 minutes
                    {
                        Print("✅ Executing marginal BUY Order Block trade");
                        ExecuteSMCBuyTrade(current_tick.ask, buy_setup, confluence_score, conditions);
                        last_marginal_buy = TimeCurrent();
                        no_signal_counter = 0;
                    }
                    else
                    {
                        Print("⏳ Marginal trade limit reached - waiting");
                    }
                }
            }
        }
        else
        {
            // Debug why no buy setup was found
            if (TimeCurrent() - last_debug_time < 5) // Only in recent debug cycle
            {
                Print("🔍 No BUY setup found - Checking reasons:");
                if (higher_tf_bias == BIAS_BEARISH && RequireHigherTFConfirmation)
                    Print("   ❌ HTF Bias is bearish (", EnumToString(higher_tf_bias), ")");
                if (!UseOrderBlocks && !UseFairValueGaps && !UseLiquidityGrabs)
                    Print("   ❌ All SMC methods disabled");
            }
        }
    }

    //--- Check for sell setups with enhanced debugging
    if (CountPositionsByMagic(MagicNumber, POSITION_TYPE_SELL) < MaxOpenTrades)
    {
        ENUM_TRADE_TYPE sell_setup = AnalyzeSellOpportunity(higher_tf_bias, base_structure,
                                                            confirm_structure, order_blocks,
                                                            fvgs, liquidity, current_tick.bid, conditions);

        if (sell_setup != TRADE_NONE)
        {
            int confluence_score = CalculateConfluenceScore(sell_setup, base_structure, confirm_structure, 
                                                           order_blocks, fvgs, liquidity, false);
            
            Print("🚀 SELL OPPORTUNITY FOUND!");
            Print("   📊 Setup Type: ", EnumToString(sell_setup));
            Print("   ⭐ Confluence Score: ", confluence_score, "/5 (Required: ", MinConfluenceLevel, ")");
            
            if (confluence_score >= MinConfluenceLevel)
            {
                Print("🚀 SMC SELL SIGNAL DETECTED!");
                Print("   📊 Setup: ", EnumToString(sell_setup));
                Print("   ⭐ Confluence Score: ", confluence_score, "/5");
                Print("   📉 Higher TF Bias: ", EnumToString(higher_tf_bias));
                
                ExecuteSMCSellTrade(current_tick.bid, sell_setup, confluence_score, conditions);
                no_signal_counter = 0; // Reset counter when trade is executed
            }
            else
            {
                Print("⚠️ SELL signal confluence too low: ", confluence_score, "/", MinConfluenceLevel);
                
                // If confluence is just 1 below minimum and we have a good setup, consider it
                if (confluence_score == (MinConfluenceLevel - 1) && sell_setup == TRADE_ORDER_BLOCK)
                {
                    Print("🔄 Considering marginal SELL Order Block signal (", confluence_score, "/", MinConfluenceLevel, ")");
                    static datetime last_marginal_sell = 0;
                    
                    if (TimeCurrent() - last_marginal_sell > 2400) // Only one marginal trade per 40 minutes
                    {
                        Print("✅ Executing marginal SELL Order Block trade");
                        ExecuteSMCSellTrade(current_tick.bid, sell_setup, confluence_score, conditions);
                        last_marginal_sell = TimeCurrent();
                        no_signal_counter = 0;
                    }
                    else
                    {
                        Print("⏳ Marginal trade limit reached - waiting");
                    }
                }
            }
        }
        else
        {
            // Debug why no sell setup was found
            if (TimeCurrent() - last_debug_time < 5) // Only in recent debug cycle
            {
                Print("🔍 No SELL setup found - Checking reasons:");
                if (higher_tf_bias == BIAS_BULLISH && RequireHigherTFConfirmation)
                    Print("   ❌ HTF Bias is bullish (", EnumToString(higher_tf_bias), ")");
                if (!UseOrderBlocks && !UseFairValueGaps && !UseLiquidityGrabs)
                    Print("   ❌ All SMC methods disabled");
            }
        }
    }
    
    //--- CONSERVATIVE FALLBACK TRADING if no SMC signals for extended period
    static datetime last_smc_trade_attempt = 0;
    
    // Count consecutive periods with no SMC signals
    no_signal_counter++;
    
    // After 20 minutes of no SMC signals, allow very conservative fallback
    if (no_signal_counter > 200 && TimeCurrent() - last_smc_trade_attempt > 1200) // 20 minutes
    {
        Print("FALLBACK MODE: No SMC signals for 20+ minutes - Checking conservative alternatives");
        
        // Only use fallback if RSI shows reasonable conditions (relaxed)
        if (conditions.rsi_value < 35) // Oversold (relaxed from 25)
        {
            if (CountPositionsByMagic(MagicNumber, POSITION_TYPE_BUY) == 0)
            {
                Print("🔄 CONSERVATIVE FALLBACK BUY: Extreme RSI Oversold (", DoubleToString(conditions.rsi_value, 2), ")");
                ExecuteFallbackTrade(true, current_tick, conditions);
                last_smc_trade_attempt = TimeCurrent();
                no_signal_counter = 0;
                return;
            }
        }
        else if (conditions.rsi_value > 65) // Overbought (relaxed from 75)
        {
            if (CountPositionsByMagic(MagicNumber, POSITION_TYPE_SELL) == 0)
            {
                Print("🔄 CONSERVATIVE FALLBACK SELL: Extreme RSI Overbought (", DoubleToString(conditions.rsi_value, 2), ")");
                ExecuteFallbackTrade(false, current_tick, conditions);
                last_smc_trade_attempt = TimeCurrent();
                no_signal_counter = 0;
                return;
            }
        }
    }
    
    Print("🔍 No valid SMC signals found - Waiting for higher quality setups (Counter: ", no_signal_counter, ")");
    
    return; // Exit without any trades
}

//+------------------------------------------------------------------+
//| Enhanced Breakout Trading with SMC Context                      |
//+------------------------------------------------------------------+
void CheckForEnhancedBreakoutTrades(SMarketConditions &conditions, MqlTick &tick, SMarketStructure &structure)
{
    static datetime last_enhanced_time = 0;
    
    // Only try enhanced trading every 15 minutes
    if (TimeCurrent() - last_enhanced_time < 900)
        return;
        
    Print("🔄 ENHANCED BREAKOUT ANALYSIS:");
    Print("   📊 Structure Strength: ", structure.structure_strength);
    Print("   📊 RSI: ", DoubleToString(conditions.rsi_value, 2));
    Print("   📊 Recent High: ", DoubleToString(structure.recent_high, _Digits));
    Print("   📊 Recent Low: ", DoubleToString(structure.recent_low, _Digits));
    Print("   📊 Current Price: ", DoubleToString(tick.ask, _Digits));
    
    // Enhanced buy conditions with SMC context
    if ((structure.bullish_bos || structure.bullish_choch) && 
        conditions.rsi_value < 60 && 
        structure.recent_low > 0 &&
        tick.ask > structure.recent_low)
    {
        if (CountPositionsByMagic(MagicNumber, POSITION_TYPE_BUY) == 0)
        {
            Print("🔄 ENHANCED BUY: SMC Bullish Structure + RSI (", DoubleToString(conditions.rsi_value, 2), ")");
            ExecuteFallbackTrade(true, tick, conditions);
            last_enhanced_time = TimeCurrent();
            return;
        }
    }
    
    // Enhanced sell conditions with SMC context
    if ((structure.bearish_bos || structure.bearish_choch) && 
        conditions.rsi_value > 40 && 
        structure.recent_high > 0 &&
        tick.bid < structure.recent_high)
    {
        if (CountPositionsByMagic(MagicNumber, POSITION_TYPE_SELL) == 0)
        {
            Print("🔄 ENHANCED SELL: SMC Bearish Structure + RSI (", DoubleToString(conditions.rsi_value, 2), ")");
            ExecuteFallbackTrade(false, tick, conditions);
            last_enhanced_time = TimeCurrent();
            return;
        }
    }
}

//+------------------------------------------------------------------+
//| Fallback Simple Breakout Trading                                |
//+------------------------------------------------------------------+
void CheckForSimpleBreakoutTrades(SMarketConditions &conditions, MqlTick &tick)
{
    static datetime last_fallback_time = 0;
    
    // Only try fallback trading every 20 minutes (more frequent)
    if (TimeCurrent() - last_fallback_time < 1200)
        return;
        
    Print("🔄 BASIC FALLBACK ANALYSIS:");
    Print("   📊 RSI: ", DoubleToString(conditions.rsi_value, 2));
    Print("   📊 Trend: ", EnumToString(conditions.trend_direction));
        
    // Check if RSI indicates oversold/overbought with reversal potential (more aggressive)
    if (conditions.rsi_value < 35) // Oversold (relaxed from 30)
    {
        if (CountPositionsByMagic(MagicNumber, POSITION_TYPE_BUY) == 0)
        {
            Print("🔄 FALLBACK BUY: RSI Oversold (", DoubleToString(conditions.rsi_value, 2), ")");
            ExecuteFallbackTrade(true, tick, conditions);
            last_fallback_time = TimeCurrent();
        }
    }
    else if (conditions.rsi_value > 65) // Overbought (relaxed from 70)
    {
        if (CountPositionsByMagic(MagicNumber, POSITION_TYPE_SELL) == 0)
        {
            Print("🔄 FALLBACK SELL: RSI Overbought (", DoubleToString(conditions.rsi_value, 2), ")");
            ExecuteFallbackTrade(false, tick, conditions);
            last_fallback_time = TimeCurrent();
        }
    }
    // NEW: Add trend following mode for ranging RSI
    else if (conditions.rsi_value > 50 && conditions.rsi_value < 60 && conditions.trend_direction == BIAS_BULLISH)
    {
        if (CountPositionsByMagic(MagicNumber, POSITION_TYPE_BUY) == 0)
        {
            Print("🔄 FALLBACK BUY: Trend Following (RSI: ", DoubleToString(conditions.rsi_value, 2), ")");
            ExecuteFallbackTrade(true, tick, conditions);
            last_fallback_time = TimeCurrent();
        }
    }
    else if (conditions.rsi_value > 40 && conditions.rsi_value < 50 && conditions.trend_direction == BIAS_BEARISH)
    {
        if (CountPositionsByMagic(MagicNumber, POSITION_TYPE_SELL) == 0)
        {
            Print("🔄 FALLBACK SELL: Trend Following (RSI: ", DoubleToString(conditions.rsi_value, 2), ")");
            ExecuteFallbackTrade(false, tick, conditions);
            last_fallback_time = TimeCurrent();
        }
    }
}

//+------------------------------------------------------------------+
//| Execute Fallback Trade                                          |
//+------------------------------------------------------------------+
void ExecuteFallbackTrade(bool is_buy, MqlTick &tick, SMarketConditions &conditions)
{
    double entry_price = is_buy ? tick.ask : tick.bid;
    double lot_size = CalculateLotSize(entry_price, StopLossPips);
    double sl, tp;
    
    // Use dynamic SL/TP for fallback trades too
    CalculateDynamicSLTP(entry_price, is_buy, sl, tp);
    
    string comment = TradeComment + "-FALLBACK-RSI";
    
    bool success = false;
    if (is_buy)
        success = Trade.Buy(lot_size, _Symbol, entry_price, sl, tp, comment);
    else
        success = Trade.Sell(lot_size, _Symbol, entry_price, sl, tp, comment);
    
    if (success)
    {
        LastTradeTime = TimeCurrent();
        Print("✅ FALLBACK ", is_buy ? "BUY" : "SELL", " TRADE EXECUTED:");
        Print("   💰 Entry: ", DoubleToString(entry_price, _Digits));
        Print("   🛑 SL: ", DoubleToString(sl, _Digits), " (", DoubleToString(MathAbs(entry_price - sl) / PointMultiplier, 1), " pips)");
        Print("   🎯 TP: ", DoubleToString(tp, _Digits), " (", DoubleToString(MathAbs(tp - entry_price) / PointMultiplier, 1), " pips)");
        Print("   📈 Lot: ", DoubleToString(lot_size, 2));
        Print("   📊 RSI: ", DoubleToString(conditions.rsi_value, 2));
        Print("   🔄 Dynamic SL/TP: ", UseDynamicSLTP ? "YES" : "NO");
        
        if (EnableAlerts)
            Alert("SMC Gold EA: Fallback ", is_buy ? "BUY" : "SELL", " trade executed");
    }
    else
    {
        Print("❌ FALLBACK TRADE FAILED - Error: ", GetLastError());
    }
}

//+------------------------------------------------------------------+
//| Execute SMC Buy Trade                                            |
//+------------------------------------------------------------------+
void ExecuteSMCBuyTrade(double ask_price, ENUM_TRADE_TYPE setup_type, int confluence_score, SMarketConditions &conditions)
{
    double lot_size = CalculateLotSize(ask_price, StopLossPips);
    double sl, tp;
    
    // Use dynamic SL/TP calculation
    CalculateDynamicSLTP(ask_price, true, sl, tp);
    
    // Adjust SL/TP based on setup type and confluence
    if (setup_type == TRADE_ORDER_BLOCK)
    {
        // Tighter SL for order blocks (more precise entries)
        sl = ask_price - ((sl - ask_price) * 0.8);
    }
    else if (setup_type == TRADE_FAIR_VALUE_GAP)
    {
        // Larger TP for FVG (higher probability)
        tp = ask_price + ((tp - ask_price) * 1.2);
    }
    
    string comment = TradeComment + "-" + EnumToString(setup_type) + "-C" + IntegerToString(confluence_score);
    
    if (Trade.Buy(lot_size, _Symbol, ask_price, sl, tp, comment))
    {
        LastTradeTime = TimeCurrent();
        
        Print("✅ SMC BUY TRADE EXECUTED:");
        Print("   💰 Entry: ", DoubleToString(ask_price, _Digits));
        Print("   🛑 SL: ", DoubleToString(sl, _Digits), " (", DoubleToString((ask_price - sl) / PointMultiplier, 1), " pips)");
        Print("   🎯 TP: ", DoubleToString(tp, _Digits), " (", DoubleToString((tp - ask_price) / PointMultiplier, 1), " pips)");
        Print("   📈 Lot: ", DoubleToString(lot_size, 2));
        Print("   📊 Setup: ", EnumToString(setup_type));
        Print("   ⭐ Confluence: ", confluence_score, "/5");
        Print("   🔄 Dynamic SL/TP: ", UseDynamicSLTP ? "YES" : "NO");
        
        if (EnableAlerts)
        {
            Alert("SMC Gold EA: BUY trade executed - ", EnumToString(setup_type), " - Confluence: ", confluence_score);
        }
    }
    else
    {
        int error = GetLastError();
        Print("❌ SMC BUY TRADE FAILED:");
        Print("   🚨 Error: ", error, " - ", ErrorDescription(error));
        Print("   💰 Price: ", DoubleToString(ask_price, _Digits));
        Print("   📈 Lot: ", DoubleToString(lot_size, 2));
    }
}

//+------------------------------------------------------------------+
//| Execute SMC Sell Trade                                           |
//+------------------------------------------------------------------+
void ExecuteSMCSellTrade(double bid_price, ENUM_TRADE_TYPE setup_type, int confluence_score, SMarketConditions &conditions)
{
    double lot_size = CalculateLotSize(bid_price, StopLossPips);
    double sl, tp;
    
    // Use dynamic SL/TP calculation
    CalculateDynamicSLTP(bid_price, false, sl, tp);
    
    // Adjust SL/TP based on setup type and confluence
    if (setup_type == TRADE_ORDER_BLOCK)
    {
        // Tighter SL for order blocks (more precise entries)
        sl = bid_price + ((sl - bid_price) * 0.8);
    }
    else if (setup_type == TRADE_FAIR_VALUE_GAP)
    {
        // Larger TP for FVG (higher probability)
        tp = bid_price - ((bid_price - tp) * 1.2);
    }
    
    string comment = TradeComment + "-" + EnumToString(setup_type) + "-C" + IntegerToString(confluence_score);
    
    if (Trade.Sell(lot_size, _Symbol, bid_price, sl, tp, comment))
    {
        LastTradeTime = TimeCurrent();
        
        Print("✅ SMC SELL TRADE EXECUTED:");
        Print("   💰 Entry: ", DoubleToString(bid_price, _Digits));
        Print("   🛑 SL: ", DoubleToString(sl, _Digits), " (", DoubleToString((sl - bid_price) / PointMultiplier, 1), " pips)");
        Print("   🎯 TP: ", DoubleToString(tp, _Digits), " (", DoubleToString((bid_price - tp) / PointMultiplier, 1), " pips)");
        Print("   📈 Lot: ", DoubleToString(lot_size, 2));
        Print("   📊 Setup: ", EnumToString(setup_type));
        Print("   ⭐ Confluence: ", confluence_score, "/5");
        Print("   🔄 Dynamic SL/TP: ", UseDynamicSLTP ? "YES" : "NO");
        
        if (EnableAlerts)
        {
            Alert("SMC Gold EA: SELL trade executed - ", EnumToString(setup_type), " - Confluence: ", confluence_score);
        }
    }
    else
    {
        int error = GetLastError();
        Print("❌ SMC SELL TRADE FAILED:");
        Print("   🚨 Error: ", error, " - ", ErrorDescription(error));
        Print("   💰 Price: ", DoubleToString(bid_price, _Digits));
        Print("   📈 Lot: ", DoubleToString(lot_size, 2));
    }
}

//+------------------------------------------------------------------+
//| Calculate Confluence Score                                       |
//+------------------------------------------------------------------+
int CalculateConfluenceScore(ENUM_TRADE_TYPE setup_type, SMarketStructure &base, SMarketStructure &confirm,
                            SOrderBlocks &ob, SFairValueGaps &fvg, SLiquidityLevels &liq, bool is_buy)
{
    int score = 0;
    
    //--- Base structure confirmation
    if (is_buy && (base.bullish_bos || base.bullish_choch)) score++;
    if (!is_buy && (base.bearish_bos || base.bearish_choch)) score++;
    
    //--- Confirmation timeframe alignment
    if (is_buy && (confirm.bullish_bos || confirm.bullish_choch)) score++;
    if (!is_buy && (confirm.bearish_bos || confirm.bearish_choch)) score++;
    
    //--- Order block validation
    if (setup_type == TRADE_ORDER_BLOCK && ob.is_valid && ob.size_pips > MinOBSize) score++;
    
    //--- Fair Value Gap validation
    if (setup_type == TRADE_FAIR_VALUE_GAP && fvg.is_valid && fvg.size_pips > 50) score++;
    
    //--- Liquidity grab confirmation
    if (is_buy && liq.liquidity_grab_low) score++;
    if (!is_buy && liq.liquidity_grab_high) score++;
    
    return MathMin(score, 5); // Max score of 5
}

//+------------------------------------------------------------------+
//| Helper Functions                                                 |
//+------------------------------------------------------------------+

// Calculate lot size based on risk percentage with dynamic SL
double CalculateLotSize(double entry_price, int stop_loss_pips)
{
    double account_balance = AccountInfoDouble(ACCOUNT_BALANCE);
    double risk_amount = account_balance * (RiskPerTradePercent / 100.0);
    
    // Use dynamic SL if enabled
    double actual_sl_pips = stop_loss_pips;
    if (UseDynamicSLTP)
    {
        double atr_buffer[];
        if (CopyBuffer(ATR_Handle, 0, 0, 1, atr_buffer) > 0)
        {
            actual_sl_pips = (atr_buffer[0] * ATRMultiplierSL) / PointMultiplier;
            actual_sl_pips = MathMax(actual_sl_pips, 30);  // Minimum 3 pips for M15
            actual_sl_pips = MathMin(actual_sl_pips, 120); // Maximum 12 pips for M15
        }
    }
    
    double pip_value = SymbolInfoDouble(_Symbol, SYMBOL_TRADE_TICK_VALUE);
    double lot_size = risk_amount / (actual_sl_pips * pip_value);
    
    // CONSERVATIVE: Use 80% of calculated lot size for more trading power
    lot_size = lot_size * 0.8; // Use 80% of calculated lot size (increased from 70%)
    
    // Normalize lot size
    double min_lot = SymbolInfoDouble(_Symbol, SYMBOL_VOLUME_MIN);
    double max_lot = SymbolInfoDouble(_Symbol, SYMBOL_VOLUME_MAX);
    double lot_step = SymbolInfoDouble(_Symbol, SYMBOL_VOLUME_STEP);
    
    // Absolute maximum for safety
    double max_allowed = account_balance / 50000.0; // Max 0.01 lot per $500
    
    lot_size = MathMax(lot_size, min_lot);
    lot_size = MathMin(lot_size, max_lot);
    lot_size = MathMin(lot_size, max_allowed);
    lot_size = NormalizeDouble(lot_size / lot_step, 0) * lot_step;
    
    Print("📊 LOT SIZE CALCULATION:");
    Print("   💰 Account Balance: $", DoubleToString(account_balance, 2));
    Print("   📊 Risk Amount: $", DoubleToString(risk_amount, 2));
    Print("   📏 SL Pips: ", DoubleToString(actual_sl_pips, 1));
    Print("   📈 Calculated Lot: ", DoubleToString(lot_size, 3));
    
    return lot_size;
}

// Calculate dynamic Stop Loss and Take Profit
void CalculateDynamicSLTP(double entry_price, bool is_buy, double &sl, double &tp)
{
    double sl_distance = StopLossPips * PointMultiplier;
    double tp_distance = TakeProfitPips * PointMultiplier;
    
    if (UseDynamicSLTP)
    {
        double atr_buffer[];
        if (CopyBuffer(ATR_Handle, 0, 0, 1, atr_buffer) > 0)
        {
            double atr_value = atr_buffer[0];
            sl_distance = atr_value * ATRMultiplierSL;
            tp_distance = atr_value * ATRMultiplierTP;
            
            // Apply reasonable limits for M15 timeframe
            sl_distance = MathMax(sl_distance, 30 * PointMultiplier);  // Min 3 pips
            sl_distance = MathMin(sl_distance, 120 * PointMultiplier); // Max 12 pips
            tp_distance = MathMax(tp_distance, 60 * PointMultiplier);  // Min 6 pips
            tp_distance = MathMin(tp_distance, 300 * PointMultiplier); // Max 30 pips
        }
    }
    
    if (is_buy)
    {
        sl = entry_price - sl_distance;
        tp = entry_price + tp_distance;
    }
    else
    {
        sl = entry_price + sl_distance;
        tp = entry_price - tp_distance;
    }
    
    Print("📊 DYNAMIC SL/TP CALCULATION:");
    Print("   📏 SL Distance: ", DoubleToString(sl_distance / PointMultiplier, 1), " pips");
    Print("   📏 TP Distance: ", DoubleToString(tp_distance / PointMultiplier, 1), " pips");
    Print("   🛑 Stop Loss: ", DoubleToString(sl, _Digits));
    Print("   🎯 Take Profit: ", DoubleToString(tp, _Digits));
}

// Count positions by magic number and type
int CountPositionsByMagic(int magic, ENUM_POSITION_TYPE pos_type)
{
    int count = 0;
    for (int i = 0; i < PositionsTotal(); i++)
    {
        if (PositionGetSymbol(i) == _Symbol && 
            PositionGetInteger(POSITION_MAGIC) == magic &&
            PositionGetInteger(POSITION_TYPE) == pos_type)
            count++;
    }
    return count;
}

// Calculate profit in pips
double CalculateProfitPips(ulong ticket)
{
    if (!PositionSelectByTicket(ticket))
        return 0;
        
    double open_price = PositionGetDouble(POSITION_PRICE_OPEN);
    double current_price = (PositionGetInteger(POSITION_TYPE) == POSITION_TYPE_BUY) ?
                           SymbolInfoDouble(_Symbol, SYMBOL_BID) :
                           SymbolInfoDouble(_Symbol, SYMBOL_ASK);
    
    double profit_points = (PositionGetInteger(POSITION_TYPE) == POSITION_TYPE_BUY) ?
                          (current_price - open_price) :
                          (open_price - current_price);
    
    return profit_points / PointMultiplier;
}

// Enhanced trading environment validation
bool IsValidTradingEnvironment()
{
    if (!TerminalInfoInteger(TERMINAL_TRADE_ALLOWED))
    {
        static datetime last_terminal_error = 0;
        if (TimeCurrent() - last_terminal_error > 300) // Every 5 minutes
        {
            Print("❌ Terminal trading not allowed");
            last_terminal_error = TimeCurrent();
        }
        return false;
    }

    if (!MQLInfoInteger(MQL_TRADE_ALLOWED))
    {
        static datetime last_mql_error = 0;
        if (TimeCurrent() - last_mql_error > 300)
        {
            Print("❌ MQL trading not allowed");
            last_mql_error = TimeCurrent();
        }
        return false;
    }

    if (!SymbolInfoInteger(_Symbol, SYMBOL_TRADE_MODE))
    {
        static datetime last_symbol_error = 0;
        if (TimeCurrent() - last_symbol_error > 300)
        {
            Print("❌ Trading disabled for ", _Symbol);
            last_symbol_error = TimeCurrent();
        }
        return false;
    }

    return true;
}

// Get market conditions
SMarketConditions GetMarketConditions()
{
    SMarketConditions conditions;

    // Get ATR
    double atr_buffer[];
    if (CopyBuffer(ATR_Handle, 0, 0, 1, atr_buffer) > 0)
    {
        conditions.atr_value = atr_buffer[0];
        double current_price = SymbolInfoDouble(_Symbol, SYMBOL_BID);
        conditions.atr_percent = (conditions.atr_value / current_price) * 100;
        conditions.is_volatile = conditions.atr_percent > MaxATRPercent;
    }

    // Get RSI
    double rsi_buffer[];
    if (CopyBuffer(RSI_Handle, 0, 0, 1, rsi_buffer) > 0)
    {
        conditions.rsi_value = rsi_buffer[0];
    }

    // Get spread
    conditions.current_spread = (SymbolInfoDouble(_Symbol, SYMBOL_ASK) -
                                SymbolInfoDouble(_Symbol, SYMBOL_BID)) / PointMultiplier;

    // Determine trend
    conditions.is_trending = conditions.rsi_value > 70 || conditions.rsi_value < 30;
    if (conditions.rsi_value > 50)
        conditions.trend_direction = BIAS_BULLISH;
    else if (conditions.rsi_value < 50)
        conditions.trend_direction = BIAS_BEARISH;
    else
        conditions.trend_direction = BIAS_NEUTRAL;

    return conditions;
}

// Trading filters
bool PassesFilters(SMarketConditions &conditions)
{
    // Session filter
    if (UseSessionFilter && !IsValidTradingSession())
        return false;

    // Volatility filter
    if (UseVolatilityFilter && conditions.is_volatile)
        return false;

    // Spread filter
    if (UseSpreadFilter && conditions.current_spread > MaxSpreadPips)
        return false;

    return true;
}

// Trading session validation

bool IsValidTradingSession()
{
    MqlDateTime dt;
    TimeToStruct(TimeCurrent(), dt);
    int hour = dt.hour;
    int day_of_week = dt.day_of_week;

    bool session1 = (hour >= StartHour1 && hour < EndHour1);
    bool session2 = (hour >= StartHour2 && hour < EndHour2);
    
    bool weekday_session  = (day_of_week >= weekdaystart && day_of_week < weekdayend);
    
    return (session1 || session2) && weekday_session;
}



// Enhanced manual testing handler (for demo only)
void HandleManualTesting()
{
    static bool buy_triggered = false;
    static bool sell_triggered = false;
    static bool close_triggered = false;
    
    if (TriggerBuyTrade && !buy_triggered)
    {
        buy_triggered = true;
        Print("🧪 Manual BUY trigger activated");
        
        // Execute manual buy trade
        MqlTick current_tick;
        if (SymbolInfoTick(_Symbol, current_tick))
        {
            double lot_size = ManualLotSize;
            double sl = current_tick.ask - (StopLossPips * PointMultiplier);
            double tp = current_tick.ask + (TakeProfitPips * PointMultiplier);
            
            string comment = TradeComment + "-MANUAL-BUY";
            
            if (Trade.Buy(lot_size, _Symbol, current_tick.ask, sl, tp, comment))
            {
                Print("✅ Manual BUY trade executed:");
                Print("   💰 Entry: ", DoubleToString(current_tick.ask, _Digits));
                Print("   🛑 SL: ", DoubleToString(sl, _Digits));
                Print("   🎯 TP: ", DoubleToString(tp, _Digits));
                Print("   📈 Lot: ", DoubleToString(lot_size, 2));
                
                if (EnableAlerts)
                    Alert("SMC Gold EA: Manual BUY trade executed");
            }
            else
            {
                Print("❌ Manual BUY trade failed - Error: ", GetLastError());
            }
        }
    }
    
    if (TriggerSellTrade && !sell_triggered)
    {
        sell_triggered = true;
        Print("🧪 Manual SELL trigger activated");
        
        // Execute manual sell trade
        MqlTick current_tick;
        if (SymbolInfoTick(_Symbol, current_tick))
        {
            double lot_size = ManualLotSize;
            double sl = current_tick.bid + (StopLossPips * PointMultiplier);
            double tp = current_tick.bid - (TakeProfitPips * PointMultiplier);
            
            string comment = TradeComment + "-MANUAL-SELL";
            
            if (Trade.Sell(lot_size, _Symbol, current_tick.bid, sl, tp, comment))
            {
                Print("✅ Manual SELL trade executed:");
                Print("   💰 Entry: ", DoubleToString(current_tick.bid, _Digits));
                Print("   🛑 SL: ", DoubleToString(sl, _Digits));
                Print("   🎯 TP: ", DoubleToString(tp, _Digits));
                Print("   📈 Lot: ", DoubleToString(lot_size, 2));
                
                if (EnableAlerts)
                    Alert("SMC Gold EA: Manual SELL trade executed");
            }
            else
            {
                Print("❌ Manual SELL trade failed - Error: ", GetLastError());
            }
        }
    }
    
    if (CloseAllTrades && !close_triggered)
    {
        close_triggered = true;
        Print("🧪 Manual close all triggered");
        
        int closed_count = 0;
        for (int i = PositionsTotal() - 1; i >= 0; i--)
        {
            string symbol = PositionGetSymbol(i);
            if (symbol == _Symbol && PositionGetInteger(POSITION_MAGIC) == MagicNumber)
            {
                ulong ticket = PositionGetInteger(POSITION_TICKET);
                if (Trade.PositionClose(ticket))
                {
                    closed_count++;
                    Print("✅ Manually closed position #", ticket);
                }
                else
                {
                    Print("❌ Failed to close position #", ticket, " - Error: ", GetLastError());
                }
            }
        }
        
        Print("🧪 Manual close all completed - ", closed_count, " positions closed");
        
        if (EnableAlerts && closed_count > 0)
            Alert("SMC Gold EA: Manually closed ", closed_count, " positions");
    }
    
    // Reset triggers
    if (!TriggerBuyTrade) buy_triggered = false;
    if (!TriggerSellTrade) sell_triggered = false;
    if (!CloseAllTrades) close_triggered = false;
}

//+------------------------------------------------------------------+
//| ADVANCED SMC ANALYSIS FUNCTIONS - MASTERPIECE IMPLEMENTATION   |
//+------------------------------------------------------------------+

//+------------------------------------------------------------------+
//| Get Higher Timeframe Market Bias                                |
//+------------------------------------------------------------------+
ENUM_MARKET_BIAS GetHigherTimeframeBias()




{
    if (SMC_Higher_Handle == INVALID_HANDLE)
        return BIAS_NEUTRAL;
    
    double bos_bull[], bos_bear[], choch_bull[], choch_bear[];
    
    ArrayResize(bos_bull, SMC_HigherTime_Lookback);
    ArrayResize(bos_bear, SMC_HigherTime_Lookback);
    ArrayResize(choch_bull, SMC_HigherTime_Lookback);
    ArrayResize(choch_bear, SMC_HigherTime_Lookback);
    
    // Get recent structure breaks
    int bull_bos = CopyBuffer(SMC_Higher_Handle, BUFFER_BULLISH_BOS, 0, SMC_HigherTime_Lookback, bos_bull);
    int bear_bos = CopyBuffer(SMC_Higher_Handle, BUFFER_BEARISH_BOS, 0, SMC_HigherTime_Lookback, bos_bear);
    int bull_choch = CopyBuffer(SMC_Higher_Handle, BUFFER_BULLISH_CHOCH, 0, SMC_HigherTime_Lookback, choch_bull);
    int bear_choch = CopyBuffer(SMC_Higher_Handle, BUFFER_BEARISH_CHOCH, 0, SMC_HigherTime_Lookback, choch_bear);
    
    if (bull_bos <= 0 || bear_bos <= 0 || bull_choch <= 0 || bear_choch <= 0)
        return BIAS_NEUTRAL;
    
    int bullish_signals = 0, bearish_signals = 0;
    datetime last_bull_time = 0, last_bear_time = 0;
    
    // Count recent signals and find most recent
    for (int i = 0; i < SMC_HigherTime_Lookback; i++)
    {
        if (bos_bull[i] != EMPTY_VALUE && bos_bull[i] != 0)
        {
            bullish_signals++;
            datetime signal_time = iTime(_Symbol, HigherTimeframe, i);
            if (signal_time > last_bull_time) last_bull_time = signal_time;
        }
        if (bos_bear[i] != EMPTY_VALUE && bos_bear[i] != 0)
        {
            bearish_signals++;
            datetime signal_time = iTime(_Symbol, HigherTimeframe, i);
            if (signal_time > last_bear_time) last_bear_time = signal_time;
        }
        if (choch_bull[i] != EMPTY_VALUE && choch_bull[i] != 0)
        {
            bullish_signals++;
            datetime signal_time = iTime(_Symbol, HigherTimeframe, i);
            if (signal_time > last_bull_time) last_bull_time = signal_time;
        }
        if (choch_bear[i] != EMPTY_VALUE && choch_bear[i] != 0)
        {
            bearish_signals++;
            datetime signal_time = iTime(_Symbol, HigherTimeframe, i);
            if (signal_time > last_bear_time) last_bear_time = signal_time;
        }
    }
    
    // Determine bias based on most recent signal and signal strength
    if (last_bull_time > last_bear_time && bullish_signals >= bearish_signals)
        return BIAS_BULLISH;
    else if (last_bear_time > last_bull_time && bearish_signals >= bullish_signals)
        return BIAS_BEARISH;
    else
        return BIAS_NEUTRAL;
}

//+------------------------------------------------------------------+
//| Advanced Market Structure Analysis                              |
//+------------------------------------------------------------------+
SMarketStructure GetMarketStructure(int handle)
{
    SMarketStructure structure;
    ZeroMemory(structure);
    
    if (handle == INVALID_HANDLE)
        return structure;
    
    double bos_bull[], bos_bear[], choch_bull[], choch_bear[];
    ArrayResize(bos_bull, 5);
    ArrayResize(bos_bear, 5);
    ArrayResize(choch_bull, 5);
    ArrayResize(choch_bear, 5);
    
    // Get recent structure data
    int bull_bos = CopyBuffer(handle, BUFFER_BULLISH_BOS, 0, 5, bos_bull);
    int bear_bos = CopyBuffer(handle, BUFFER_BEARISH_BOS, 0, 5, bos_bear);
    int bull_choch = CopyBuffer(handle, BUFFER_BULLISH_CHOCH, 0, 5, choch_bull);
    int bear_choch = CopyBuffer(handle, BUFFER_BEARISH_CHOCH, 0, 5, choch_bear);
    
    if (bull_bos <= 0 || bear_bos <= 0 || bull_choch <= 0 || bear_choch <= 0)
        return structure;
    
    // Check for recent structure breaks (last 3 bars)
    for (int i = 0; i < 3; i++)
    {
        if (bos_bull[i] != EMPTY_VALUE && bos_bull[i] != 0)
        {
            structure.bullish_bos = true;
            structure.bullstructure_strength++;
        }
        if (bos_bear[i] != EMPTY_VALUE && bos_bear[i] != 0)
        {
            structure.bearish_bos = true;
            structure.bearstructure_strength++;
        }
        if (choch_bull[i] != EMPTY_VALUE && choch_bull[i] != 0)
        {
            structure.bullish_choch = true;
            structure.bullstructure_strength++;
        }
        if (choch_bear[i] != EMPTY_VALUE && choch_bear[i] != 0)
        {
            structure.bearish_choch = true;
            structure.bearstructure_strength++;
        }
    }
    
    // Get recent high/low levels
    double high[], low[];
    ArrayResize(high, 10);
    ArrayResize(low, 10);
    
    ENUM_TIMEFRAMES timeframe = (handle == SMC_Base_Handle) ? BaseTimeframe : 
                               (handle == SMC_Confirm_Handle) ? ConfirmTimeframe : HigherTimeframe;
    
    if (CopyHigh(_Symbol, timeframe, 0, 10, high) > 0 && CopyLow(_Symbol, timeframe, 0, 10, low) > 0)
    {
        int max_index = ArrayMaximum(high, 0, 5);
        int min_index = ArrayMinimum(low, 0, 5);
        
        if (max_index >= 0) 
        {
            structure.recent_high = high[max_index];
            structure.high_time = iTime(_Symbol, timeframe, max_index);
        }
        if (min_index >= 0)
        {
            structure.recent_low = low[min_index];
            structure.low_time = iTime(_Symbol, timeframe, min_index);
        }
    }
    
    return structure;
}


//+------------------------------------------------------------------+
//| Advanced Order Block Detection                                  |
//+------------------------------------------------------------------+
SOrderBlocks GetOrderBlocks(int handle)
{
    SOrderBlocks blocks;
    ZeroMemory(blocks);
    
    if (handle == INVALID_HANDLE)
        return blocks;
    
    double bull_ob_high[], bull_ob_low[], bear_ob_high[], bear_ob_low[];
    ArrayResize(bull_ob_high, SMC_OB_Lookback);
    ArrayResize(bull_ob_low, SMC_OB_Lookback);
    ArrayResize(bear_ob_high, SMC_OB_Lookback);
    ArrayResize(bear_ob_low, SMC_OB_Lookback);
    
    // Get order block data
    int bull_high = CopyBuffer(handle, BUFFER_BULLISH_OB_HIGH, 0, SMC_OB_Lookback, bull_ob_high);
    int bull_low = CopyBuffer(handle, BUFFER_BULLISH_OB_LOW, 0, SMC_OB_Lookback, bull_ob_low);
    int bear_high = CopyBuffer(handle, BUFFER_BEARISH_OB_HIGH, 0, SMC_OB_Lookback, bear_ob_high);
    int bear_low = CopyBuffer(handle, BUFFER_BEARISH_OB_LOW, 0, SMC_OB_Lookback, bear_ob_low);
    
    if (bull_high <= 0 || bull_low <= 0 || bear_high <= 0 || bear_low <= 0)
        return blocks;
    
    double current_price = SymbolInfoDouble(_Symbol, SYMBOL_BID);
    double best_bull_distance = DBL_MAX;
    double best_bear_distance = DBL_MAX;
    
    // Find the nearest valid order blocks
    for (int i = 0; i < SMC_OB_Lookback; i++)
    {
        // Check bullish order blocks
        if (bull_ob_high[i] != EMPTY_VALUE && bull_ob_low[i] != EMPTY_VALUE && 
            bull_ob_high[i] != 0 && bull_ob_low[i] != 0)
        {
            double ob_size = (bull_ob_high[i] - bull_ob_low[i]) / PointMultiplier;
            double distance = MathAbs(current_price - bull_ob_low[i]);
            
            if (ob_size >= MinOBSize && distance < best_bull_distance)
            {
                blocks.bullish_ob_high = bull_ob_high[i];
                blocks.bullish_ob_low = bull_ob_low[i];
                blocks.size_pips = ob_size;
                blocks.is_valid = true;
                best_bull_distance = distance;
                
                ENUM_TIMEFRAMES tf = (handle == SMC_Base_Handle) ? BaseTimeframe : 
                                   (handle == SMC_Confirm_Handle) ? ConfirmTimeframe : HigherTimeframe;
                blocks.ob_time = iTime(_Symbol, tf, i);
            }
        }
        
        // Check bearish order blocks
        if (bear_ob_high[i] != EMPTY_VALUE && bear_ob_low[i] != EMPTY_VALUE &&
            bear_ob_high[i] != 0 && bear_ob_low[i] != 0)
        {
            double ob_size = (bear_ob_high[i] - bear_ob_low[i]) / PointMultiplier;
            double distance = MathAbs(current_price - bear_ob_high[i]);
            
            if (ob_size >= MinOBSize && distance < best_bear_distance)
            {
                blocks.bearish_ob_high = bear_ob_high[i];
                blocks.bearish_ob_low = bear_ob_low[i];
                blocks.size_pips = ob_size;
                blocks.is_valid = true;
                best_bear_distance = distance;
                
                ENUM_TIMEFRAMES tf = (handle == SMC_Base_Handle) ? BaseTimeframe : 
                                   (handle == SMC_Confirm_Handle) ? ConfirmTimeframe : HigherTimeframe;
                blocks.ob_time = iTime(_Symbol, tf, i);
            }
        }
    }
    
    return blocks;
}

//+------------------------------------------------------------------+
//| Advanced Fair Value Gap Detection                               |
//+------------------------------------------------------------------+
SFairValueGaps GetFairValueGaps(int handle)
{
    SFairValueGaps gaps;
    ZeroMemory(gaps);
    
    if (handle == INVALID_HANDLE)
        return gaps;
    
    double bull_fvg_high[], bull_fvg_low[], bear_fvg_high[], bear_fvg_low[];
    ArrayResize(bull_fvg_high, SMC_FVG_Lookback);
    ArrayResize(bull_fvg_low, SMC_FVG_Lookback);
    ArrayResize(bear_fvg_high, SMC_FVG_Lookback);
    ArrayResize(bear_fvg_low, SMC_FVG_Lookback);
    
    // Get FVG data
    int bull_high = CopyBuffer(handle, BUFFER_BULLISH_FVG_HIGH, 0, SMC_FVG_Lookback, bull_fvg_high);
    int bull_low = CopyBuffer(handle, BUFFER_BULLISH_FVG_LOW, 0, SMC_FVG_Lookback, bull_fvg_low);
    int bear_high = CopyBuffer(handle, BUFFER_BEARISH_FVG_HIGH, 0, SMC_FVG_Lookback, bear_fvg_high);
    int bear_low = CopyBuffer(handle, BUFFER_BEARISH_FVG_LOW, 0, SMC_FVG_Lookback, bear_fvg_low);
    
    if (bull_high <= 0 || bull_low <= 0 || bear_high <= 0 || bear_low <= 0)
        return gaps;
    
    double current_price = SymbolInfoDouble(_Symbol, SYMBOL_BID);
    double best_bull_distance = DBL_MAX;
    double best_bear_distance = DBL_MAX;
    
    // Find the nearest valid FVGs
    for (int i = 0; i < SMC_FVG_Lookback; i++)
    {
        // Check bullish FVGs
        if (bull_fvg_high[i] != EMPTY_VALUE && bull_fvg_low[i] != EMPTY_VALUE &&
            bull_fvg_high[i] != 0 && bull_fvg_low[i] != 0)
        {
            double fvg_size = (bull_fvg_high[i] - bull_fvg_low[i]) / PointMultiplier;
            double distance = MathAbs(current_price - bull_fvg_low[i]);
            
            if (fvg_size >= 50 && distance < best_bull_distance) // Minimum 5 pip FVG
            {
                gaps.bullish_fvg_high = bull_fvg_high[i];
                gaps.bullish_fvg_low = bull_fvg_low[i];
                gaps.size_pips = fvg_size;
                gaps.is_valid = true;
                best_bull_distance = distance;
                
                ENUM_TIMEFRAMES tf = (handle == SMC_Base_Handle) ? BaseTimeframe : 
                                   (handle == SMC_Confirm_Handle) ? ConfirmTimeframe : HigherTimeframe;
                gaps.fvg_time = iTime(_Symbol, tf, i);
            }
        }
        
        // Check bearish FVGs
        if (bear_fvg_high[i] != EMPTY_VALUE && bear_fvg_low[i] != EMPTY_VALUE &&
            bear_fvg_high[i] != 0 && bear_fvg_low[i] != 0)
        {
            double fvg_size = (bear_fvg_high[i] - bear_fvg_low[i]) / PointMultiplier;
            double distance = MathAbs(current_price - bear_fvg_high[i]);
            
            if (fvg_size >= 50 && distance < best_bear_distance)
            {
                gaps.bearish_fvg_high = bear_fvg_high[i];
                gaps.bearish_fvg_low = bear_fvg_low[i];
                gaps.size_pips = fvg_size;
                gaps.is_valid = true;
                best_bear_distance = distance;
                
                ENUM_TIMEFRAMES tf = (handle == SMC_Base_Handle) ? BaseTimeframe : 
                                   (handle == SMC_Confirm_Handle) ? ConfirmTimeframe : HigherTimeframe;
                gaps.fvg_time = iTime(_Symbol, tf, i);
            }
        }
    }
    
    return gaps;
}

//+------------------------------------------------------------------+
//| Advanced Liquidity Level Analysis                               |
//+------------------------------------------------------------------+
SLiquidityLevels GetLiquidityLevels(int handle)
{
    SLiquidityLevels levels;
    ZeroMemory(levels);
    
    if (handle == INVALID_HANDLE)
        return levels;
    
    double eq_highs[], eq_lows[], liq_grab_high[], liq_grab_low[];
    ArrayResize(eq_highs, 10);
    ArrayResize(eq_lows, 10);
    ArrayResize(liq_grab_high, 10);
    ArrayResize(liq_grab_low, 10);
    
    // Get liquidity data
    int eq_high_count = CopyBuffer(handle, BUFFER_EQ_HIGHS, 0, 10, eq_highs);
    int eq_low_count = CopyBuffer(handle, BUFFER_EQ_LOWS, 0, 10, eq_lows);
    int grab_high_count = CopyBuffer(handle, BUFFER_LIQUIDITY_GRAB_HIGH, 0, 10, liq_grab_high);
    int grab_low_count = CopyBuffer(handle, BUFFER_LIQUIDITY_GRAB_LOW, 0, 10, liq_grab_low);
    
    if (eq_high_count <= 0 || eq_low_count <= 0 || grab_high_count <= 0 || grab_low_count <= 0)
        return levels;
    
    // Find recent equal highs and lows
    for (int i = 0; i < 5; i++) // Check last 5 bars
    {
        if (eq_highs[i] != EMPTY_VALUE && eq_highs[i] != 0)
        {
            levels.equal_highs = eq_highs[i];
        }
        if (eq_lows[i] != EMPTY_VALUE && eq_lows[i] != 0)
        {
            levels.equal_lows = eq_lows[i];
        }
    }
    
    // Check for recent liquidity grabs (last 3 bars)
    for (int i = 0; i < 3; i++)
    {
        if (liq_grab_high[i] != EMPTY_VALUE && liq_grab_high[i] != 0)
        {
            levels.liquidity_grab_high = true;
            ENUM_TIMEFRAMES tf = (handle == SMC_Base_Handle) ? BaseTimeframe : 
                               (handle == SMC_Confirm_Handle) ? ConfirmTimeframe : HigherTimeframe;
            levels.grab_time = iTime(_Symbol, tf, i);
        }
        if (liq_grab_low[i] != EMPTY_VALUE && liq_grab_low[i] != 0)
        {
            levels.liquidity_grab_low = true;
            ENUM_TIMEFRAMES tf = (handle == SMC_Base_Handle) ? BaseTimeframe : 
                               (handle == SMC_Confirm_Handle) ? ConfirmTimeframe : HigherTimeframe;
            levels.grab_time = iTime(_Symbol, tf, i);
        }
    }
    
    // Calculate swing highs and lows
    double high[], low[];
    ArrayResize(high, 20);
    ArrayResize(low, 20);
    
    ENUM_TIMEFRAMES tf = (handle == SMC_Base_Handle) ? BaseTimeframe : 
                       (handle == SMC_Confirm_Handle) ? ConfirmTimeframe : HigherTimeframe;
    
    if (CopyHigh(_Symbol, tf, 0, 20, high) > 0 && CopyLow(_Symbol, tf, 0, 20, low) > 0)
    {
        // Find recent swing high
        for (int i = 1; i < 19; i++)
        {
            if (high[i] > high[i-1] && high[i] > high[i+1])
            {
                levels.swing_highs = high[i];
                break;
            }
        }
        
        // Find recent swing low
        for (int i = 1; i < 19; i++)
        {
            if (low[i] < low[i-1] && low[i] < low[i+1])
            {
                levels.swing_lows = low[i];
                break;
            }
        }
    }
    
    return levels;
}

//+------------------------------------------------------------------+
//| Advanced Buy Opportunity Analysis                               |
//+------------------------------------------------------------------+
ENUM_TRADE_TYPE AnalyzeBuyOpportunity(ENUM_MARKET_BIAS bias, SMarketStructure &base, SMarketStructure &confirm,
                                     SOrderBlocks &ob, SFairValueGaps &fvg, SLiquidityLevels &liq,
                                     double price, SMarketConditions &conditions)
{
    // Require bullish or neutral higher timeframe bias
    if (bias == BIAS_BEARISH && RequireHigherTFConfirmation)
        return TRADE_NONE;
    
    double tolerance_pips = 100; // 10 pip tolerance for XAUUSD
    double tolerance = tolerance_pips * PointMultiplier;
    
    // 1. ORDER BLOCK ANALYSIS - Highest Priority with STRICT CONFIRMATION
    if (UseOrderBlocks && ob.is_valid && ob.bullish_ob_high > 0 && ob.bullish_ob_low > 0)
    {
        // MUCH STRICTER: Price must be very close to order block
        double tolerance_pips = 20; // Only 2 pip tolerance for M15
        double tolerance = tolerance_pips * PointMultiplier;
        
        // Check if price is near bullish order block
        if (price >= (ob.bullish_ob_low - tolerance) && price <= (ob.bullish_ob_high + tolerance))
        {
            // STRICT CONFIRMATION: Multiple requirements
            bool structure_confirmed = (base.bullish_bos || base.bullish_choch);
            bool momentum_ok = conditions.rsi_value < 65 && conditions.rsi_value > 35; // Not overbought
            bool size_ok = ob.size_pips >= MinOBSize && ob.size_pips <= 100; // Reasonable size
            bool time_ok = (TimeCurrent() - ob.ob_time) < (SignalValidityHours * 3600); // Fresh signal
            
            if (structure_confirmed && momentum_ok && size_ok && time_ok)
            {
                Print("🔍 HIGH QUALITY BUY Order Block Signal:");
                Print("   📊 Structure: ", structure_confirmed ? "CONFIRMED" : "MISSING");
                Print("   📊 RSI: ", DoubleToString(conditions.rsi_value, 2));
                Print("   📊 OB Size: ", DoubleToString(ob.size_pips, 1), " pips");
                Print("   📊 Signal Age: ", (TimeCurrent() - ob.ob_time) / 3600, " hours");
                
                return TRADE_ORDER_BLOCK;
            }
        }
    }
    
    // 2. FAIR VALUE GAP ANALYSIS - RELAXED CONDITIONS
    if (UseFairValueGaps && fvg.is_valid && fvg.bullish_fvg_high > 0 && fvg.bullish_fvg_low > 0)
    {
        // Check if price is in bullish FVG
        if (price >= fvg.bullish_fvg_low && price <= fvg.bullish_fvg_high)
        {
            // RELAXED MOMENTUM AND STRUCTURE ALIGNMENT
            bool momentum_ok = conditions.rsi_value < 70 && conditions.rsi_value > 30; // Wider RSI range
            bool structure_ok = base.bullish_bos || confirm.bullish_bos || !UseConservativeEntries; // Either timeframe OR relaxed mode
            bool size_adequate = fvg.size_pips >= 10 && fvg.size_pips <= 120; // Even more flexible FVG size
            bool fresh_signal = (TimeCurrent() - fvg.fvg_time) < (SignalValidityHours * 3600);
            
            if (momentum_ok && structure_ok && size_adequate && fresh_signal)
            {
                Print("🔍 BUY Fair Value Gap Signal (RELAXED):");
                Print("   📊 RSI: ", DoubleToString(conditions.rsi_value, 2));
                Print("   📊 Base BOS: ", base.bullish_bos ? "YES" : "NO");
                Print("   📊 Confirm BOS: ", confirm.bullish_bos ? "YES" : "NO");
                Print("   📊 FVG Size: ", DoubleToString(fvg.size_pips, 1), " pips");
                
                return TRADE_FAIR_VALUE_GAP;
            }
        }
    }
    
    // 3. LIQUIDITY GRAB ANALYSIS - RELAXED
    if (UseLiquidityGrabs && liq.liquidity_grab_low)
    {
        // After liquidity grab below, look for reversal - EXTENDED TIME WINDOW
        if (TimeCurrent() - liq.grab_time < 7200) // Within 2 hours (was 1 hour)
        {
            // Check if we have supporting structure - MORE FLEXIBLE
            if (base.bullish_choch || confirm.bullish_choch || base.bullish_bos || !RequireHigherTFConfirmation)
            {
                Print("🔍 BUY Liquidity Grab Signal Detected:");
                Print("   📊 Grab Time: ", TimeToString(liq.grab_time));
                Print("   📊 Time Since Grab: ", (TimeCurrent() - liq.grab_time)/60, " minutes");
                Print("   📊 Structure Support Available");
                
                return TRADE_LIQUIDITY_GRAB;
            }
        }
    }
    
    // 4. BREAK OF STRUCTURE (BOS) ANALYSIS
    if (base.bullish_bos && base.structure_strength >= 1)
    {
        // Price should be above recent lows for continuation
        if (price > base.recent_low)
        {
            Print("🔍 BUY Break of Structure Signal Detected:");
            Print("   📊 Structure Strength: ", base.structure_strength);
            Print("   📊 Recent Low: ", DoubleToString(base.recent_low, _Digits));
            
            return TRADE_BOS_BREAKOUT;
        }
    }
    
    // 5. CHANGE OF CHARACTER (CHoCH) REVERSAL - RELAXED
    if (base.bullish_choch && conditions.rsi_value < 60) // Expanded RSI range
    {
        // Look for reversal after CHoCH - MORE FLEXIBLE
        if (confirm.bullish_choch || base.bullish_bos || !RequireHigherTFConfirmation)
        {
            Print("🔍 BUY Change of Character Signal Detected:");
            Print("   📊 Base CHoCH: ", base.bullish_choch);
            Print("   📊 Confirm CHoCH: ", confirm.bullish_choch);
            Print("   📊 Base BOS: ", base.bullish_bos);
            Print("   📊 RSI: ", DoubleToString(conditions.rsi_value, 2));
            
            return TRADE_CHOCH_REVERSAL;
        }
    }
    
    return TRADE_NONE;
}

//+------------------------------------------------------------------+
//| Advanced Sell Opportunity Analysis                              |
//+------------------------------------------------------------------+
ENUM_TRADE_TYPE AnalyzeSellOpportunity(ENUM_MARKET_BIAS bias, SMarketStructure &base, SMarketStructure &confirm,
                                      SOrderBlocks &ob, SFairValueGaps &fvg, SLiquidityLevels &liq,
                                      double price, SMarketConditions &conditions)
{
    // Require bearish or neutral higher timeframe bias
    if (bias == BIAS_BULLISH && RequireHigherTFConfirmation)
        return TRADE_NONE;
    
    double tolerance_pips = 100; // 10 pip tolerance for XAUUSD
    double tolerance = tolerance_pips * PointMultiplier;
    
    // 1. ORDER BLOCK ANALYSIS - Highest Priority
    if (UseOrderBlocks && ob.is_valid && ob.bearish_ob_high > 0 && ob.bearish_ob_low > 0)
    {
        // Check if price is near bearish order block
        if (price >= (ob.bearish_ob_low - tolerance) && price <= (ob.bearish_ob_high + tolerance))
        {
            // Additional confirmation: check for structure alignment
            if ((base.bearish_bos || base.bearish_choch) || !UseConservativeEntries)
            {
                Print("🔍 SELL Order Block Signal Detected:");
                Print("   📊 OB High: ", DoubleToString(ob.bearish_ob_high, _Digits));
                Print("   📊 OB Low: ", DoubleToString(ob.bearish_ob_low, _Digits));
                Print("   📊 Current Price: ", DoubleToString(price, _Digits));
                Print("   📊 OB Size: ", DoubleToString(ob.size_pips, 1), " pips");
                
                return TRADE_ORDER_BLOCK;
            }
        }
    }
    
    // 2. FAIR VALUE GAP ANALYSIS
    if (UseFairValueGaps && fvg.is_valid && fvg.bearish_fvg_high > 0 && fvg.bearish_fvg_low > 0)
    {
        // Check if price is in bearish FVG
        if (price >= fvg.bearish_fvg_low && price <= fvg.bearish_fvg_high)
        {
            // Check for momentum alignment - RELAXED
            bool momentum_ok = conditions.rsi_value > 25 && conditions.rsi_value < 75; // Wider range
            bool structure_ok = base.bearish_bos || base.bearish_choch || !UseConservativeEntries; // More flexible
            
            if (momentum_ok && structure_ok)
            {
                Print("🔍 SELL Fair Value Gap Signal Detected:");
                Print("   📊 FVG High: ", DoubleToString(fvg.bearish_fvg_high, _Digits));
                Print("   📊 FVG Low: ", DoubleToString(fvg.bearish_fvg_low, _Digits));
                Print("   📊 Current Price: ", DoubleToString(price, _Digits));
                Print("   📊 FVG Size: ", DoubleToString(fvg.size_pips, 1), " pips");
                Print("   📊 RSI: ", DoubleToString(conditions.rsi_value, 2));
                
                return TRADE_FAIR_VALUE_GAP;
            }
        }
    }
    
    // 3. LIQUIDITY GRAB ANALYSIS - RELAXED
    if (UseLiquidityGrabs && liq.liquidity_grab_high)
    {
        // After liquidity grab above, look for reversal - EXTENDED TIME WINDOW
        if (TimeCurrent() - liq.grab_time < 7200) // Within 2 hours (was 1 hour)
        {
            // Check if we have supporting structure - MORE FLEXIBLE
            if (base.bearish_choch || confirm.bearish_choch || base.bearish_bos || !RequireHigherTFConfirmation)
            {
                Print("🔍 SELL Liquidity Grab Signal Detected:");
                Print("   📊 Grab Time: ", TimeToString(liq.grab_time));
                Print("   📊 Time Since Grab: ", (TimeCurrent() - liq.grab_time)/60, " minutes");
                Print("   📊 Structure Support Available");
                
                return TRADE_LIQUIDITY_GRAB;
            }
        }
    }
    
    // 4. BREAK OF STRUCTURE (BOS) ANALYSIS
    if (base.bearish_bos && base.structure_strength >= 1)
    {
        // Price should be below recent highs for continuation
        if (price < base.recent_high)
        {
            Print("🔍 SELL Break of Structure Signal Detected:");
            Print("   📊 Structure Strength: ", base.structure_strength);
            Print("   📊 Recent High: ", DoubleToString(base.recent_high, _Digits));
            
            return TRADE_BOS_BREAKOUT;
        }
    }
    
    // 5. CHANGE OF CHARACTER (CHoCH) REVERSAL - RELAXED
    if (base.bearish_choch && conditions.rsi_value > 40) // Expanded RSI range
    {
        // Look for reversal after CHoCH - MORE FLEXIBLE
        if (confirm.bearish_choch || base.bearish_bos || !RequireHigherTFConfirmation)
        {
            Print("🔍 SELL Change of Character Signal Detected:");
            Print("   📊 Base CHoCH: ", base.bearish_choch);
            Print("   📊 Confirm CHoCH: ", confirm.bearish_choch);
            Print("   📊 Base BOS: ", base.bearish_bos);
            Print("   📊 RSI: ", DoubleToString(conditions.rsi_value, 2));
            
            return TRADE_CHOCH_REVERSAL;
        }
    }
    
    return TRADE_NONE;
}

//+------------------------------------------------------------------+
//| ADVANCED POSITION MANAGEMENT - MASTERPIECE IMPLEMENTATION      |
//+------------------------------------------------------------------+

//+------------------------------------------------------------------+
//| Advanced Breakeven Management                                   |
//+------------------------------------------------------------------+
void MoveToBreakeven(ulong ticket)
{
    if (!PositionSelectByTicket(ticket))
        return;
        
    double open_price = PositionGetDouble(POSITION_PRICE_OPEN);
    double current_sl = PositionGetDouble(POSITION_SL);
    double current_tp = PositionGetDouble(POSITION_TP);
    ENUM_POSITION_TYPE pos_type = (ENUM_POSITION_TYPE)PositionGetInteger(POSITION_TYPE);
    string symbol = PositionGetString(POSITION_SYMBOL);
    
    // Calculate breakeven level with small buffer
    double be_buffer = 20 * PointMultiplier; // 2 pip buffer for XAUUSD
    double new_sl = 0;
    
    if (pos_type == POSITION_TYPE_BUY)
    {
        new_sl = open_price + be_buffer;
        
        // Only move if new SL is better than current
        if (current_sl == 0 || new_sl > current_sl)
        {
            if (Trade.PositionModify(ticket, new_sl, current_tp))
            {
                Print("✅ BREAKEVEN MOVED - BUY Position #", ticket);
                Print("   📊 Old SL: ", DoubleToString(current_sl, _Digits));
                Print("   📊 New SL: ", DoubleToString(new_sl, _Digits), " (BE + 2 pips)");
                Print("   📊 Open: ", DoubleToString(open_price, _Digits));
                
                if (EnableAlerts)
                {
                    Alert("SMC Gold EA: Breakeven moved for BUY #", ticket);
                }
            }
            else
            {
                Print("❌ Failed to move breakeven for position #", ticket, " - Error: ", GetLastError());
            }
        }
    }
    else if (pos_type == POSITION_TYPE_SELL)
    {
        new_sl = open_price - be_buffer;
        
        // Only move if new SL is better than current
        if (current_sl == 0 || new_sl < current_sl)
        {
            if (Trade.PositionModify(ticket, new_sl, current_tp))
            {
                Print("✅ BREAKEVEN MOVED - SELL Position #", ticket);
                Print("   📊 Old SL: ", DoubleToString(current_sl, _Digits));
                Print("   📊 New SL: ", DoubleToString(new_sl, _Digits), " (BE - 2 pips)");
                Print("   📊 Open: ", DoubleToString(open_price, _Digits));
                
                if (EnableAlerts)
                {
                    Alert("SMC Gold EA: Breakeven moved for SELL #", ticket);
                }
            }
            else
            {
                Print("❌ Failed to move breakeven for position #", ticket, " - Error: ", GetLastError());
            }
        }
    }
}

//+------------------------------------------------------------------+
//| Advanced Trailing Stop Management                               |
//+------------------------------------------------------------------+
void UpdateTrailingStop(ulong ticket, double profit_pips)
{
    if (!PositionSelectByTicket(ticket))
        return;
        
    double current_sl = PositionGetDouble(POSITION_SL);
    double current_tp = PositionGetDouble(POSITION_TP);
    ENUM_POSITION_TYPE pos_type = (ENUM_POSITION_TYPE)PositionGetInteger(POSITION_TYPE);
    string symbol = PositionGetString(POSITION_SYMBOL);
    
    double current_price = (pos_type == POSITION_TYPE_BUY) ? 
                          SymbolInfoDouble(symbol, SYMBOL_BID) : 
                          SymbolInfoDouble(symbol, SYMBOL_ASK);
    
    // Dynamic trailing distance based on profit
    double trailing_distance = TrailingStopPips;
    
    // Tighten trailing stop as profit increases
    if (profit_pips > 500) // 50+ pips profit
        trailing_distance = TrailingStopPips * 0.6; // Tighter trailing
    else if (profit_pips > 300) // 30+ pips profit
        trailing_distance = TrailingStopPips * 0.8;
    
    double trail_distance = trailing_distance * PointMultiplier;
    double new_sl = 0;
    bool should_update = false;
    
    if (pos_type == POSITION_TYPE_BUY)
    {
        new_sl = current_price - trail_distance;
        
        // Only trail if new SL is better than current
        if (current_sl == 0 || new_sl > current_sl)
        {
            should_update = true;
        }
    }
    else if (pos_type == POSITION_TYPE_SELL)
    {
        new_sl = current_price + trail_distance;
        
        // Only trail if new SL is better than current
        if (current_sl == 0 || new_sl < current_sl)
        {
            should_update = true;
        }
    }
    
    if (should_update)
    {
        if (Trade.PositionModify(ticket, new_sl, current_tp))
        {
            Print("✅ TRAILING STOP UPDATED - ", EnumToString(pos_type), " Position #", ticket);
            Print("   📊 Profit: ", DoubleToString(profit_pips, 1), " pips");
            Print("   📊 Old SL: ", DoubleToString(current_sl, _Digits));
            Print("   📊 New SL: ", DoubleToString(new_sl, _Digits));
            Print("   📊 Trail Distance: ", DoubleToString(trailing_distance, 1), " pips");
            Print("   📊 Current Price: ", DoubleToString(current_price, _Digits));
        }
        else
        {
            Print("❌ Failed to update trailing stop for position #", ticket, " - Error: ", GetLastError());
        }
    }
}


//+------------------------------------------------------------------+
//| Enhanced Position Management with SMC Logic                     |
//+------------------------------------------------------------------+
void ManageOpenPositions(SMarketConditions &conditions)
{
    static datetime last_management_time = 0;
    
    // Don't manage too frequently
    if (TimeCurrent() - last_management_time < 15) // Every 15 seconds for better responsiveness
        return;
        
    last_management_time = TimeCurrent();
    
    for (int i = PositionsTotal() - 1; i >= 0; i--)
    {
        string symbol = PositionGetSymbol(i);
        if (symbol != _Symbol || PositionGetInteger(POSITION_MAGIC) != MagicNumber)
            continue;
            
        ulong ticket = PositionGetInteger(POSITION_TICKET);
        double profit_pips = CalculateProfitPips(ticket);
        double profit_money = PositionGetDouble(POSITION_PROFIT);
        ENUM_POSITION_TYPE pos_type = (ENUM_POSITION_TYPE)PositionGetInteger(POSITION_TYPE);
        datetime open_time = (datetime)PositionGetInteger(POSITION_TIME);
        int position_age_minutes = (int)((TimeCurrent() - open_time) / 60);
        double volume = PositionGetDouble(POSITION_VOLUME);
        string comment = PositionGetString(POSITION_COMMENT);
        
        // Get current market structure for exit signals
        SMarketStructure current_structure = GetMarketStructure(SMC_Base_Handle);
        
        
        // 2. SCALED EXITS - First Exit (30% at FirstExitPips)
        if (UseScaledExits && profit_pips >= FirstExitPips && 
            volume > SymbolInfoDouble(_Symbol, SYMBOL_VOLUME_MIN) && 
            StringFind(comment, "SCALED1") < 0)
        {
            ExecuteScaledExit(ticket, FirstExitPercent, "SCALED1");
        }
        
        // 3. SCALED EXITS - Second Exit (40% of remaining at SecondExitPips)
        if (UseScaledExits && profit_pips >= SecondExitPips && 
            volume > SymbolInfoDouble(_Symbol, SYMBOL_VOLUME_MIN) && 
            StringFind(comment, "SCALED2") < 0 && StringFind(comment, "SCALED1") >= 0)
        {
            ExecuteScaledExit(ticket, SecondExitPercent, "SCALED2");
        }
        

            // LARGE_PROFIT
        if (UseLargeProfit && profit_pips >= LargeProfitPips && 
            volume > SymbolInfoDouble(_Symbol, SYMBOL_VOLUME_MIN) && 
            StringFind(comment, "LargeProfit") < 0 )
        {
            ExecuteScaledExit(ticket, LargeProfitPercent, "LargeProfit");
        }
        
   
        
        
        // 4. 盈亏平衡 - Move to breakeven at just 3 pips profit
        
       
        if (profit_pips >= BreakevenPips && UseBreakeven && StringFind(comment, "BE") < 0)
        {
            MoveToBreakeven(ticket);
        }
        
        // 5. TRAILING STOP
        if (UseTrailingStop && profit_pips > TrailingStopPips)
        {
            UpdateTrailingStop(ticket, profit_pips);
        }
        
        
        
        // 7. EMERGENCY EXIT on smaller loss (much tighter)
        if (UseEmergencyLoss && profit_pips <= EmergencyLossPoints) // Emergency exit at -10 pips loss (much tighter)
        {
            Print("🚨 EMERGENCY EXIT triggered for position #", ticket, " (Loss: ", DoubleToString(profit_pips, 1), " pips)");
            if (Trade.PositionClose(ticket))
            {
                Print("✅ Emergency exit executed");
                if (EnableAlerts)
                    Alert("SMC Gold EA: Emergency exit - Loss: ", DoubleToString(profit_pips, 1), " pips");
            }
            continue;
        }
        
        // 8. Emergency exit on opposing structure signals (SMC-based)
        bool emergency_exit = false;
        if (pos_type == POSITION_TYPE_BUY && current_structure.bearish_bos && profit_pips < SMCExitProfitPoints)
        {
            emergency_exit = true;
            Print("🚨 SMC EMERGENCY EXIT: BUY position facing bearish BOS");
        }
        else if (pos_type == POSITION_TYPE_SELL && current_structure.bullish_bos && profit_pips < SMCExitProfitPoints)
        {
            emergency_exit = true;
            Print("🚨 SMC EMERGENCY EXIT: SELL position facing bullish BOS");
        }
        
        if (emergency_exit)
        {
            if (Trade.PositionClose(ticket))
            {
                Print("✅ SMC Emergency close executed for position #", ticket);
                if (EnableAlerts)
                    Alert("SMC Gold EA: Emergency exit due to opposing structure");
            }
            continue;
        }
        
        
        
        // 9. Time-based management for losing positions (more aggressive)
        if (Time_exit && position_age_minutes > MaxPositionAgeMinutes && profit_pips < MaxAgeLossPoints) // 2 hours old and losing 5+ pips
        {
            Print("⚠️ Position #", ticket, " is old and losing. Age: ", position_age_minutes, " min, Profit: ", DoubleToString(profit_pips, 1), " pips");
            
            // Consider closing if market structure has changed significantly
            if ((pos_type == POSITION_TYPE_BUY && current_structure.bearish_choch) ||
                (pos_type == POSITION_TYPE_SELL && current_structure.bullish_choch))
            {
                Print("📊 Market structure changed - closing old position");
                
                if (Trade.PositionClose(ticket))
                {
                    Print("✅ Closed old losing position #", ticket, " due to structure change");
                }
                continue;
            }
        }
       
        
        
        
    }
}




//+------------------------------------------------------------------+
//| // 函数功能：在早期盈利时调整止损以保护利润                                |
//+------------------------------------------------------------------+
void ApplyEarlyProfitProtection(ulong ticket, double profit_pips)
{
    if (!PositionSelectByTicket(ticket))
        return;
        
    double open_price = PositionGetDouble(POSITION_PRICE_OPEN);
    double current_sl = PositionGetDouble(POSITION_SL);
    double current_tp = PositionGetDouble(POSITION_TP);
    ENUM_POSITION_TYPE pos_type = (ENUM_POSITION_TYPE)PositionGetInteger(POSITION_TYPE);
    
    // Move SL to small profit (50% of current profit or minimum 5 pips)
    double protection_pips = MathMax(profit_pips * 0.5, 50); // At least 5 pips profit
    double new_sl = 0;
    
    if (pos_type == POSITION_TYPE_BUY)
    {
        new_sl = open_price + (protection_pips * PointMultiplier);
        if (current_sl == 0 || new_sl > current_sl)
        {
            if (Trade.PositionModify(ticket, new_sl, current_tp))
            {
                Print("✅ EARLY PROFIT PROTECTION Applied - BUY #", ticket);
                Print("   📊 Profit: ", DoubleToString(profit_pips, 1), " pips");
                Print("   📊 Protected at: +", DoubleToString(protection_pips, 1), " pips");
            }
        }
    }
    else
    {
        new_sl = open_price - (protection_pips * PointMultiplier);
        if (current_sl == 0 || new_sl < current_sl)
        {
            if (Trade.PositionModify(ticket, new_sl, current_tp))
            {
                Print("✅ EARLY PROFIT PROTECTION Applied - SELL #", ticket);
                Print("   📊 Profit: ", DoubleToString(profit_pips, 1), " pips");
                Print("   📊 Protected at: +", DoubleToString(protection_pips, 1), " pips");
            }
        }
    }
}




//+------------------------------------------------------------------+
//| Execute Scaled Exit                                             |
//+------------------------------------------------------------------+

void ExecuteScaledExit(ulong ticket, double exit_percent, string exit_label)
{
    if (!PositionSelectByTicket(ticket))
        return;
    // 检查是否能选中该持仓单。如果不能（例如订单不存在或已平仓），则直接退出函数。

    double current_volume = PositionGetDouble(POSITION_VOLUME);
    // 获取当前持仓的交易量（手数）。
    double exit_volume = NormalizeDouble(current_volume * (exit_percent / 100.0), 2);
    // 计算要平仓的交易量：当前手数 × 平仓百分比。
    // 使用 NormalizeDouble(_, 2) 将交易量四舍五入到小数点后两位（需根据经纪商最小手数调整精度）。
    double min_volume = SymbolInfoDouble(_Symbol, SYMBOL_VOLUME_MIN);
    // 获取当前交易品种的最小交易量（手数，例如 0.01 手）。

    // Ensure we don't try to close more than available or less than minimum
    // 确保平仓量不会超过可用手数或小于最小手数
    if (exit_volume < min_volume)
        exit_volume = min_volume;
    // 如果计算出的平仓量小于最小手数，则强制设置为最小手数。

    if (exit_volume >= current_volume)
        exit_volume = current_volume - min_volume; // Leave minimum volume
    // 如果计算出的平仓量大于或等于当前手数，则将其调整为：
    // 当前手数 - 最小手数。目的：确保至少留下一个最小手数的仓位来继续运行。

    if (exit_volume >= min_volume && exit_volume < current_volume)
    // 最终的平仓量必须满足两个条件：
    // 1. 大于等于最小交易量（确保可交易）。
    // 2. 小于当前总手数（确保是部分平仓，而不是完全平仓）。
    {
        if (Trade.PositionClosePartial(ticket, exit_volume))
        // 使用内置的 Trade 对象执行部分平仓。
        {
            Print("✅ SCALED EXIT EXECUTED - ", exit_label);
            Print("    📊 Position #", ticket);
            Print("    📊 Closed Volume: ", DoubleToString(exit_volume, 2));
            Print("    📊 Remaining Volume: ", DoubleToString(current_volume - exit_volume, 2));
            Print("    📊 Exit Percentage: ", DoubleToString(exit_percent, 1), "%");
            // 打印成功的日志信息。

            if (EnableAlerts)
                Alert("SMC Gold EA: ", exit_label, " executed - ", DoubleToString(exit_percent, 1), "% closed");
            // 如果启用了警报，则发送通知。
        }
        else
        {
            Print("❌ Failed to execute ", exit_label, " for position #", ticket, " - Error: ", GetLastError());
            // 如果平仓失败，打印失败信息和错误代码。
        }
    }
}

//+------------------------------------------------------------------+
//| Error Description Function                                       |
//+------------------------------------------------------------------+
string ErrorDescription(int error_code)
{
    switch(error_code)
    {
        case 10004: return "Requote";
        case 10006: return "Request rejected";
        case 10007: return "Request canceled by trader";
        case 10008: return "Order placed";
        case 10009: return "Request completed";
        case 10010: return "Only part of the request was completed";
        case 10011: return "Request processing error";
        case 10012: return "Request canceled by timeout";
        case 10013: return "Invalid request";
        case 10014: return "Invalid volume in the request";
        case 10015: return "Invalid price in the request";
        case 10016: return "Invalid stops in the request";
        case 10017: return "Trade is disabled";
        case 10018: return "Market is closed";
        case 10019: return "Not enough money";
        case 10020: return "Prices changed";
        case 10021: return "Not enough money for operation";
        case 10022: return "Order is filled";
        case 10023: return "Order is canceled";
        case 10024: return "Order is placed";
        case 10025: return "Request executed";
        case 10026: return "Request partially executed";
        case 10027: return "Request processing error";
        case 10028: return "Request canceled by timeout";
        case 10029: return "Order or position frozen";
        case 10030: return "Invalid order filling type";
        case 10031: return "No connection with the trade server";
        case 10032: return "Operation is allowed only for live accounts";
        case 10033: return "Exceeded limit of pending orders";
        case 10034: return "Exceeded limit of orders/positions";
        case 10035: return "Incorrect or prohibited order type";
        case 10036: return "Position with the specified POSITION_IDENTIFIER already closed";
        default: return "Unknown error " + IntegerToString(error_code);
    }
}
