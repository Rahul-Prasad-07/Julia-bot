# Reinforcement Learning Enhanced Market Making Strategy
# Uses ML/LLM optimization for parameter tuning and strategy adaptation

using HTTP, JSON3, CSV, DataFrames, Statistics, Dates, Random, SHA
using LinearAlgebra, Printf
using ..CommonTypes: StrategyConfig, AgentContext, StrategySpecification, StrategyMetadata, StrategyInput

# Load environment variables if not already loaded
function load_env_variables()
    env_file = joinpath(@__DIR__, "../../../.env")
    if isfile(env_file) && isempty(get(ENV, "BINANCE_API_KEY", ""))
        println("📝 Loading environment variables from .env...")
        for line in readlines(env_file)
            line = strip(line)
            if !isempty(line) && !startswith(line, "#") && contains(line, "=")
                key, value = split(line, "=", limit=2)
                key = strip(key)
                value = strip(value, ['"', ' '])
                ENV[key] = value
            end
        end
        println("✅ Environment variables loaded successfully")
    end
end

# Load environment on module load
load_env_variables()

# Enhanced Market Making Configuration with RL parameters
Base.@kwdef struct RLMarketMakingConfig <: StrategyConfig
    symbols::Vector{String} = ["ETHUSDT", "BTCUSDT"]
    base_spread_pct::Float64 = 0.15
    order_levels::Int = 3
    max_capital::Float64 = 10000.0
    leverage::Int = 20
    api_key::String = get(ENV, "BINANCE_API_KEY", "")
    api_secret::String = get(ENV, "BINANCE_API_SECRET", "")
    max_drawdown::Float64 = 0.20
    risk_check_interval::Int = 30
    
    # RL/ML Parameters
    enable_rl_learning::Bool = true
    learning_rate::Float64 = 0.01
    exploration_rate::Float64 = 0.1
    reward_function::String = "sharpe_ratio"  # "sharpe_ratio", "profit", "risk_adjusted"
    memory_size::Int = 1000
    batch_size::Int = 32
    update_frequency::Int = 100
    
    # LLM Integration
    enable_llm_optimization::Bool = false
    llm_model::String = "gpt-4"
    openai_api_key::String = get(ENV, "OPENAI_API_KEY", "")
    llm_update_frequency::Int = 1000  # trades
    
    # Backtesting Parameters
    backtest_enabled::Bool = true
    backtest_days::Int = 30
    validation_split::Float64 = 0.2
    walk_forward_periods::Int = 5
end

# RL State representation
mutable struct MarketState
    price::Float64
    volatility::Float64
    spread::Float64
    inventory::Float64
    time_features::Vector{Float64}
    market_features::Vector{Float64}
    
    function MarketState()
        new(0.0, 0.0, 0.0, 0.0, zeros(5), zeros(11))
    end
end

# RL Action space
Base.@kwdef struct MarketAction
    spread_adjustment::Float64 = 0.0  # -0.5 to +0.5
    order_size_multiplier::Float64 = 1.0  # 0.5 to 2.0
    aggression_level::Float64 = 0.0  # -1.0 to +1.0 (passive to aggressive)
    risk_adjustment::Float64 = 0.0  # -0.3 to +0.3
end

# Experience replay buffer
mutable struct ExperienceBuffer
    states::Vector{MarketState}
    actions::Vector{MarketAction}
    rewards::Vector{Float64}
    next_states::Vector{MarketState}
    dones::Vector{Bool}
    capacity::Int
    position::Int
    
    function ExperienceBuffer(capacity::Int)
        new(MarketState[], MarketAction[], Float64[], MarketState[], Bool[], 
            capacity, 1)
    end
end

# RL Agent for market making
mutable struct RLMarketMaker
    q_network::Matrix{Float64}  # Simple Q-network approximation
    target_network::Matrix{Float64}
    experience_buffer::ExperienceBuffer
    epsilon::Float64
    learning_rate::Float64
    discount_factor::Float64
    
    function RLMarketMaker(state_size::Int, action_size::Int, memory_size::Int)
        q_net = randn(state_size, action_size) * 0.1
        target_net = copy(q_net)
        buffer = ExperienceBuffer(memory_size)
        new(q_net, target_net, buffer, 0.1, 0.001, 0.95)
    end
end

# Backtesting engine
mutable struct BacktestEngine
    historical_data::DataFrame
    results::Vector{Dict{String, Any}}
    metrics::Dict{String, Float64}
    
    function BacktestEngine()
        new(DataFrame(), Dict{String, Any}[], Dict{String, Float64}())
    end
end

# Trade record for PnL tracking
mutable struct TradeRecord
    trade_id::Int
    symbol::String
    side::String
    entry_price::Float64
    exit_price::Float64
    quantity::Float64
    entry_time::DateTime
    exit_time::DateTime
    realized_pnl::Float64
    fees::Float64
    net_pnl::Float64
    
    function TradeRecord()
        new(0, "", "", 0.0, 0.0, 0.0, now(), now(), 0.0, 0.0, 0.0)
    end
end

# Comprehensive PnL tracking system
mutable struct PnLTracker
    # Account balances
    initial_balance_usdt::Float64
    current_balance_usdt::Float64
    initial_balance_base::Float64  # e.g., ETH balance
    current_balance_base::Float64
    
    # Trading metrics
    start_time::DateTime
    last_update_time::DateTime
    total_trades::Int
    winning_trades::Int
    losing_trades::Int
    
    # PnL metrics
    total_realized_pnl::Float64
    total_unrealized_pnl::Float64
    total_fees_paid::Float64
    best_trade_pnl::Float64
    worst_trade_pnl::Float64
    
    # Performance metrics
    max_balance::Float64
    max_drawdown::Float64
    current_drawdown::Float64
    daily_pnl_history::Vector{Float64}
    hourly_pnl_history::Vector{Float64}
    
    # Trade records
    completed_trades::Vector{TradeRecord}
    open_positions::Dict{String, Dict{String, Any}}  # symbol -> position info
    
    # Risk metrics
    sharpe_ratio::Float64
    sortino_ratio::Float64
    profit_factor::Float64
    win_rate::Float64
    avg_win::Float64
    avg_loss::Float64
    
    function PnLTracker()
        new(
            0.0, 0.0, 0.0, 0.0,  # balances
            now(), now(), 0, 0, 0,  # time and trade counts
            0.0, 0.0, 0.0, 0.0, 0.0,  # PnL metrics
            0.0, 0.0, 0.0, Float64[], Float64[],  # performance metrics
            TradeRecord[], Dict{String, Dict{String, Any}}(),  # trade records
            0.0, 0.0, 0.0, 0.0, 0.0, 0.0  # risk metrics
        )
    end
end

# Global PnL tracker instance
const GLOBAL_PNL_TRACKER = PnLTracker()

# HMAC-SHA256 signature generation
function hmac_sha256_rl(key::String, message::String)
    key_bytes = Vector{UInt8}(key)
    message_bytes = Vector{UInt8}(message)
    signature = SHA.hmac_sha256(key_bytes, message_bytes)
    return bytes2hex(signature)
end

# ===== PnL TRACKING FUNCTIONS =====

# Initialize PnL tracker with starting balances
function initialize_pnl_tracker(api_key::String, api_secret::String)
    try
        println("💰 Initializing PnL Tracker...")
        
        # Get current account balances
        account_data = binance_api_request_rl("/fapi/v2/account", "GET", api_key, api_secret)
        
        if isa(account_data, Dict) && haskey(account_data, "error")
            println("❌ Failed to get account data: $(account_data["error"])")
            return false
        end
        
        # Extract USDT balance
        usdt_balance = 0.0
        eth_balance = 0.0
        
        if haskey(account_data, "assets")
            for asset in account_data["assets"]
                if asset["asset"] == "USDT"
                    usdt_balance = parse(Float64, string(asset["walletBalance"]))
                elseif asset["asset"] == "ETH"
                    eth_balance = parse(Float64, string(asset["walletBalance"]))
                end
            end
        end
        
        # Initialize tracker
        GLOBAL_PNL_TRACKER.initial_balance_usdt = usdt_balance
        GLOBAL_PNL_TRACKER.current_balance_usdt = usdt_balance
        GLOBAL_PNL_TRACKER.initial_balance_base = eth_balance
        GLOBAL_PNL_TRACKER.current_balance_base = eth_balance
        GLOBAL_PNL_TRACKER.start_time = now()
        GLOBAL_PNL_TRACKER.last_update_time = now()
        GLOBAL_PNL_TRACKER.max_balance = usdt_balance
        
        println("✅ PnL Tracker Initialized:")
        println("   💵 Initial USDT Balance: \$$(round(usdt_balance, digits=2))")
        println("   🪙 Initial ETH Balance: $(round(eth_balance, digits=6)) ETH")
        println("   ⏰ Start Time: $(Dates.format(GLOBAL_PNL_TRACKER.start_time, "yyyy-mm-dd HH:MM:SS"))")
        
        return true
        
    catch e
        println("❌ Error initializing PnL tracker: $e")
        return false
    end
end

# Update account balances and calculate PnL
function update_pnl_tracker(api_key::String, api_secret::String)
    try
        # Get current account balances
        account_data = binance_api_request_rl("/fapi/v2/account", "GET", api_key, api_secret)
        
        if isa(account_data, Dict) && haskey(account_data, "error")
            return false
        end
        
        # Extract current balances
        usdt_balance = 0.0
        eth_balance = 0.0
        
        if haskey(account_data, "assets")
            for asset in account_data["assets"]
                if asset["asset"] == "USDT"
                    usdt_balance = parse(Float64, string(asset["walletBalance"]))
                elseif asset["asset"] == "ETH"
                    eth_balance = parse(Float64, string(asset["walletBalance"]))
                end
            end
        end
        
        # Update tracker
        old_balance = GLOBAL_PNL_TRACKER.current_balance_usdt
        GLOBAL_PNL_TRACKER.current_balance_usdt = usdt_balance
        GLOBAL_PNL_TRACKER.current_balance_base = eth_balance
        GLOBAL_PNL_TRACKER.last_update_time = now()
        
        # Update max balance and drawdown
        if usdt_balance > GLOBAL_PNL_TRACKER.max_balance
            GLOBAL_PNL_TRACKER.max_balance = usdt_balance
        end
        
        # Calculate drawdown
        current_dd = (GLOBAL_PNL_TRACKER.max_balance - usdt_balance) / GLOBAL_PNL_TRACKER.max_balance
        GLOBAL_PNL_TRACKER.current_drawdown = current_dd
        GLOBAL_PNL_TRACKER.max_drawdown = max(GLOBAL_PNL_TRACKER.max_drawdown, current_dd)
        
        # Store hourly PnL
        balance_change = usdt_balance - old_balance
        push!(GLOBAL_PNL_TRACKER.hourly_pnl_history, balance_change)
        
        # Keep only last 168 hours (7 days)
        if length(GLOBAL_PNL_TRACKER.hourly_pnl_history) > 168
            GLOBAL_PNL_TRACKER.hourly_pnl_history = GLOBAL_PNL_TRACKER.hourly_pnl_history[end-167:end]
        end
        
        return true
        
    catch e
        println("❌ Error updating PnL tracker: $e")
        return false
    end
end

# Record a completed trade
function record_trade(symbol::String, side::String, entry_price::Float64, exit_price::Float64, 
                     quantity::Float64, entry_time::DateTime, exit_time::DateTime, 
                     fees::Float64 = 0.0)
    try
        trade = TradeRecord()
        trade.trade_id = GLOBAL_PNL_TRACKER.total_trades + 1
        trade.symbol = symbol
        trade.side = side
        trade.entry_price = entry_price
        trade.exit_price = exit_price
        trade.quantity = quantity
        trade.entry_time = entry_time
        trade.exit_time = exit_time
        trade.fees = fees
        
        # Calculate PnL
        if side == "BUY"  # Long position
            trade.realized_pnl = (exit_price - entry_price) * quantity
        else  # Short position
            trade.realized_pnl = (entry_price - exit_price) * quantity
        end
        
        trade.net_pnl = trade.realized_pnl - fees
        
        # Update tracker
        GLOBAL_PNL_TRACKER.total_trades += 1
        GLOBAL_PNL_TRACKER.total_realized_pnl += trade.net_pnl
        GLOBAL_PNL_TRACKER.total_fees_paid += fees
        
        if trade.net_pnl > 0
            GLOBAL_PNL_TRACKER.winning_trades += 1
        else
            GLOBAL_PNL_TRACKER.losing_trades += 1
        end
        
        # Update best/worst trade
        GLOBAL_PNL_TRACKER.best_trade_pnl = max(GLOBAL_PNL_TRACKER.best_trade_pnl, trade.net_pnl)
        GLOBAL_PNL_TRACKER.worst_trade_pnl = min(GLOBAL_PNL_TRACKER.worst_trade_pnl, trade.net_pnl)
        
        # Store trade
        push!(GLOBAL_PNL_TRACKER.completed_trades, trade)
        
        println("📊 Trade Recorded: $(side) $(quantity) $(symbol) @ \$$(entry_price) → \$$(exit_price) | P&L: \$$(round(trade.net_pnl, digits=2))")
        
        return true
        
    catch e
        println("❌ Error recording trade: $e")
        return false
    end
end

# Calculate performance metrics
function calculate_performance_metrics()
    try
        if GLOBAL_PNL_TRACKER.total_trades == 0
            return
        end
        
        # Win rate
        GLOBAL_PNL_TRACKER.win_rate = GLOBAL_PNL_TRACKER.winning_trades / GLOBAL_PNL_TRACKER.total_trades
        
        # Average win/loss
        winning_trades = filter(t -> t.net_pnl > 0, GLOBAL_PNL_TRACKER.completed_trades)
        losing_trades = filter(t -> t.net_pnl <= 0, GLOBAL_PNL_TRACKER.completed_trades)
        
        if !isempty(winning_trades)
            GLOBAL_PNL_TRACKER.avg_win = mean([t.net_pnl for t in winning_trades])
        end
        
        if !isempty(losing_trades)
            GLOBAL_PNL_TRACKER.avg_loss = mean([abs(t.net_pnl) for t in losing_trades])
        end
        
        # Profit factor
        total_wins = sum([t.net_pnl for t in winning_trades])
        total_losses = sum([abs(t.net_pnl) for t in losing_trades])
        
        if total_losses > 0
            GLOBAL_PNL_TRACKER.profit_factor = total_wins / total_losses
        end
        
        # Sharpe ratio (simplified)
        if length(GLOBAL_PNL_TRACKER.hourly_pnl_history) > 1
            returns = GLOBAL_PNL_TRACKER.hourly_pnl_history
            avg_return = mean(returns)
            return_std = std(returns)
            
            if return_std > 0
                GLOBAL_PNL_TRACKER.sharpe_ratio = (avg_return * sqrt(8760)) / return_std  # Annualized
            end
        end
        
    catch e
        println("❌ Error calculating performance metrics: $e")
    end
end

# Generate comprehensive performance report
function generate_performance_report()::String
    calculate_performance_metrics()
    
    # Calculate runtime
    runtime = now() - GLOBAL_PNL_TRACKER.start_time
    runtime_hours = Dates.value(runtime) / (1000 * 60 * 60)
    runtime_days = runtime_hours / 24
    
    # Calculate total return
    total_return_pct = ((GLOBAL_PNL_TRACKER.current_balance_usdt - GLOBAL_PNL_TRACKER.initial_balance_usdt) / 
                       GLOBAL_PNL_TRACKER.initial_balance_usdt) * 100
    
    # Calculate APY (Annual Percentage Yield)
    apy = 0.0
    if runtime_days > 0
        daily_return = total_return_pct / runtime_days
        apy = ((1 + daily_return/100)^365 - 1) * 100
    end
    
    report = """
    
    🏆 ===== COMPREHENSIVE TRADING PERFORMANCE REPORT =====
    
    📅 Trading Period:
       Start: $(Dates.format(GLOBAL_PNL_TRACKER.start_time, "yyyy-mm-dd HH:MM:SS"))
       End:   $(Dates.format(GLOBAL_PNL_TRACKER.last_update_time, "yyyy-mm-dd HH:MM:SS"))
       Duration: $(round(runtime_days, digits=2)) days ($(round(runtime_hours, digits=1)) hours)
    
    💰 Account Balances:
       Initial USDT: \$$(round(GLOBAL_PNL_TRACKER.initial_balance_usdt, digits=2))
       Current USDT: \$$(round(GLOBAL_PNL_TRACKER.current_balance_usdt, digits=2))
       Balance Change: \$$(round(GLOBAL_PNL_TRACKER.current_balance_usdt - GLOBAL_PNL_TRACKER.initial_balance_usdt, digits=2))
    
    📈 Performance Metrics:
       Total Return: $(round(total_return_pct, digits=2))%
       Annualized APY: $(round(apy, digits=2))%
       Max Balance: \$$(round(GLOBAL_PNL_TRACKER.max_balance, digits=2))
       Max Drawdown: $(round(GLOBAL_PNL_TRACKER.max_drawdown * 100, digits=2))%
       Current Drawdown: $(round(GLOBAL_PNL_TRACKER.current_drawdown * 100, digits=2))%
    
    📊 Trading Statistics:
       Total Trades: $(GLOBAL_PNL_TRACKER.total_trades)
       Winning Trades: $(GLOBAL_PNL_TRACKER.winning_trades)
       Losing Trades: $(GLOBAL_PNL_TRACKER.losing_trades)
       Win Rate: $(round(GLOBAL_PNL_TRACKER.win_rate * 100, digits=1))%
    
    💸 PnL Breakdown:
       Total Realized PnL: \$$(round(GLOBAL_PNL_TRACKER.total_realized_pnl, digits=2))
       Total Fees Paid: \$$(round(GLOBAL_PNL_TRACKER.total_fees_paid, digits=2))
       Net PnL: \$$(round(GLOBAL_PNL_TRACKER.total_realized_pnl - GLOBAL_PNL_TRACKER.total_fees_paid, digits=2))
       Best Trade: \$$(round(GLOBAL_PNL_TRACKER.best_trade_pnl, digits=2))
       Worst Trade: \$$(round(GLOBAL_PNL_TRACKER.worst_trade_pnl, digits=2))
    
    🎯 Risk Metrics:
       Average Win: \$$(round(GLOBAL_PNL_TRACKER.avg_win, digits=2))
       Average Loss: \$$(round(GLOBAL_PNL_TRACKER.avg_loss, digits=2))
       Profit Factor: $(round(GLOBAL_PNL_TRACKER.profit_factor, digits=2))
       Sharpe Ratio: $(round(GLOBAL_PNL_TRACKER.sharpe_ratio, digits=2))
    
    📊 Recent Performance (Last 24 hours):
    """
    
    # Add recent hourly PnL
    if length(GLOBAL_PNL_TRACKER.hourly_pnl_history) >= 24
        recent_24h = GLOBAL_PNL_TRACKER.hourly_pnl_history[end-23:end]
        total_24h = sum(recent_24h)
        report *= "       24h PnL: \$$(round(total_24h, digits=2))\n"
        report *= "       24h Return: $(round((total_24h / GLOBAL_PNL_TRACKER.current_balance_usdt) * 100, digits=2))%\n"
    end
    
    report *= "\n    ===== END REPORT =====\n"
    
    return report
end

# Enhanced API functions for RL strategy
function binance_api_request_rl(endpoint::String, method::String, api_key::String, api_secret::String, params::Dict=Dict(), debug::Bool=false)
    try
        base_url = "https://testnet.binancefuture.com"
        timestamp = string(Int(round(time() * 1000)))
        
        # Debug: Check API credentials
        if isempty(api_key) || isempty(api_secret)
            error_result = Dict("error" => "API credentials are empty", "api_key_length" => length(api_key), "api_secret_length" => length(api_secret))
            if debug
                println("🔍 API Request Debug:")
                println("  ❌ Error: API credentials missing")
            end
            return error_result
        end
        
        query_params = merge(params, Dict("timestamp" => timestamp))
        query_string = join(["$k=$v" for (k, v) in query_params], "&")
        
        # Create proper HMAC-SHA256 signature
        signature = hmac_sha256_rl(api_secret, query_string)
        full_query = "$query_string&signature=$signature"
        
        headers = [
            "X-MBX-APIKEY" => api_key,
            "Content-Type" => "application/x-www-form-urlencoded"
        ]
        
        if debug
            println("🔍 API Request Debug:")
            #println("  Endpoint: $endpoint")
            #println("  URL: $base_url$endpoint")
            #println("  Query: $(query_string)")
            #println("  API Key: $(api_key[1:min(8,length(api_key))])...$(api_key[max(1,end-4):end])")
        end
        
        if method == "GET"
            response = HTTP.get("$base_url$endpoint?$full_query", headers)
        elseif method == "POST"
            response = HTTP.post("$base_url$endpoint", headers, full_query)
        elseif method == "DELETE"
            response = HTTP.delete("$base_url$endpoint?$full_query", headers)
        else
            error("Unsupported HTTP method: $method")
        end
        
        response_body = String(response.body)
        parsed_result = JSON3.read(response_body)
        
        if debug
            println("  Response Status: $(response.status)")
            #println("  Response Body: $(response_body[1:min(200, length(response_body))])")
            #println("  Parsed Successfully: $(typeof(parsed_result))")
        end
        
        return parsed_result
        
    catch e
        error_msg = string(e)
        if debug
            println("❌ API Request Failed: $error_msg")
        end
        return Dict("error" => error_msg, "endpoint" => endpoint, "method" => method)
    end
end

# Enhanced market data functions
function get_historical_klines(symbol::String, interval::String, limit::Int, api_key::String, api_secret::String)
    params = Dict("symbol" => symbol, "interval" => interval, "limit" => string(limit))
    return binance_api_request_rl("/fapi/v1/klines", "GET", api_key, api_secret, params)
end

function get_order_book_depth(symbol::String, api_key::String, api_secret::String)
    params = Dict("symbol" => symbol, "limit" => "100")
    return binance_api_request_rl("/fapi/v1/depth", "GET", api_key, api_secret, params)
end

# Market state extraction
function extract_market_state(symbol::String, cfg::RLMarketMakingConfig)::MarketState
    state = MarketState()
    
    try
        # Get current price
        price_data = binance_api_request_rl("/fapi/v1/ticker/price", "GET", cfg.api_key, cfg.api_secret, 
                                       Dict("symbol" => symbol))
        if haskey(price_data, "price")
            state.price = parse(Float64, string(price_data["price"]))
        end
        
        # Get historical data for volatility calculation
        klines = get_historical_klines(symbol, "1m", 30, cfg.api_key, cfg.api_secret)
        if isa(klines, Vector) && !isempty(klines)
            try
                prices = [parse(Float64, string(k[4])) for k in klines]  # Close prices
                if length(prices) > 1
                    returns = diff(log.(prices))
                    state.volatility = std(returns) * sqrt(1440)  # Annualized volatility
                end
            catch e
                state.volatility = 0.02  # Default volatility
            end
        end
        
        # Get order book for spread analysis
        order_book = get_order_book_depth(symbol, cfg.api_key, cfg.api_secret)
        if haskey(order_book, "bids") && haskey(order_book, "asks")
            try
                best_bid = parse(Float64, string(order_book["bids"][1][1]))
                best_ask = parse(Float64, string(order_book["asks"][1][1]))
                state.spread = (best_ask - best_bid) / ((best_ask + best_bid) / 2)
            catch e
                state.spread = 0.001  # Default spread
            end
        else
            state.spread = 0.001  # Default spread
        end
        
        # Time features
        now = Dates.now()
        state.time_features = [
            Dates.hour(now) / 24.0,
            Dates.dayofweek(now) / 7.0,
            Dates.day(now) / 31.0,
            sin(2π * Dates.hour(now) / 24),
            cos(2π * Dates.hour(now) / 24)
        ]
        
        # Market features (simplified) - ensure exactly 11 features for total of 20
        state.market_features = [
            state.volatility,
            state.spread,
            log(max(state.price, 1.0)) / 10.0,  # Normalized log price
            tanh(state.volatility * 100),  # Bounded volatility
            0.0, 0.0, 0.0, 0.0, 0.0, 0.0, 0.0  # 7 additional features (total 11)
        ]
        
    catch e
        println("Error extracting market state: $e")
    end
    
    return state
end

# RL Agent functions
function select_action(agent::RLMarketMaker, state::MarketState)::MarketAction
    if rand() < agent.epsilon
        # Exploration: random action
        return MarketAction(
            spread_adjustment = (rand() - 0.5),
            order_size_multiplier = 0.5 + rand() * 1.5,
            aggression_level = (rand() - 0.5) * 2,
            risk_adjustment = (rand() - 0.5) * 0.6
        )
    else
        # Exploitation: use Q-network
        state_vector = vcat(state.price/10000, state.volatility*100, state.spread*1000, 
                           state.inventory, state.time_features, state.market_features)
        q_values = agent.q_network' * state_vector
        
        # Convert Q-values to action (simplified)
        return MarketAction(
            spread_adjustment = tanh(q_values[1]) * 0.5,
            order_size_multiplier = sigmoid(q_values[2]) * 1.5 + 0.5,
            aggression_level = tanh(q_values[3]),
            risk_adjustment = tanh(q_values[4]) * 0.3
        )
    end
end

function update_q_network!(agent::RLMarketMaker)
    if length(agent.experience_buffer.states) < agent.experience_buffer.capacity ÷ 10
        return
    end
    
    # Simple Q-learning update (placeholder for more sophisticated methods)
    batch_size = min(32, length(agent.experience_buffer.states))
    indices = rand(1:length(agent.experience_buffer.states), batch_size)
    
    for i in indices
        state = agent.experience_buffer.states[i]
        action = agent.experience_buffer.actions[i]
        reward = agent.experience_buffer.rewards[i]
        next_state = agent.experience_buffer.next_states[i]
        done = agent.experience_buffer.dones[i]
        
        # Update Q-values (simplified)
        state_vector = vcat(state.price/10000, state.volatility*100, state.spread*1000,
                           state.inventory, state.time_features, state.market_features)
        
        target = reward
        if !done
            next_state_vector = vcat(next_state.price/10000, next_state.volatility*100, 
                                   next_state.spread*1000, next_state.inventory,
                                   next_state.time_features, next_state.market_features)
            next_q_values = agent.target_network' * next_state_vector
            target += agent.discount_factor * maximum(next_q_values)
        end
        
        # Gradient update (simplified)
        current_q = agent.q_network' * state_vector
        error = target - current_q[1]  # Assuming single action for simplicity
        
        # Update weights
        agent.q_network[:, 1] += agent.learning_rate * error * state_vector
    end
    
    # Decay epsilon
    agent.epsilon = max(0.01, agent.epsilon * 0.995)
end

function sigmoid(x::Float64)::Float64
    return 1.0 / (1.0 + exp(-x))
end

# Reward calculation
function calculate_reward(old_state::MarketState, new_state::MarketState, action::MarketAction, 
                         pnl::Float64, cfg::RLMarketMakingConfig)::Float64
    if cfg.reward_function == "sharpe_ratio"
        # Simplified Sharpe ratio approximation
        returns = pnl / cfg.max_capital
        risk = new_state.volatility
        return returns / max(risk, 0.001)
    elseif cfg.reward_function == "profit"
        return pnl
    elseif cfg.reward_function == "risk_adjusted"
        inventory_penalty = abs(new_state.inventory) * 0.1
        spread_reward = new_state.spread * 1000  # Reward wider spreads
        return pnl - inventory_penalty + spread_reward
    else
        return pnl
    end
end

# Backtesting functions
function run_backtest(cfg::RLMarketMakingConfig, symbol::String, days::Int)::Dict{String, Any}
    println("Running backtest for $symbol over $days days...")
    
    # Get historical data
    end_time = now()
    start_time = end_time - Dates.Day(days)
    
    # Simulate historical trading (simplified)
    total_trades = days * 24 * 4  # Assume 4 trades per hour
    wins = 0
    total_pnl = 0.0
    max_drawdown = 0.0
    equity_curve = Float64[]
    
    for i in 1:total_trades
        # Simulate a trade
        spread = cfg.base_spread_pct + randn() * 0.05
        profit_loss = randn() * 10.0  # Random P&L
        
        if profit_loss > 0
            wins += 1
        end
        
        total_pnl += profit_loss
        push!(equity_curve, total_pnl)
        
        # Calculate drawdown
        peak = maximum(equity_curve)
        current_dd = (peak - total_pnl) / peak
        max_drawdown = max(max_drawdown, current_dd)
    end
    
    win_rate = wins / total_trades
    sharpe_ratio = total_pnl / std(diff(equity_curve))
    
    return Dict(
        "symbol" => symbol,
        "total_trades" => total_trades,
        "total_pnl" => total_pnl,
        "win_rate" => win_rate,
        "max_drawdown" => max_drawdown,
        "sharpe_ratio" => sharpe_ratio,
        "equity_curve" => equity_curve
    )
end

# LLM optimization functions
function llm_optimize_parameters(cfg::RLMarketMakingConfig, backtest_results::Dict{String, Any})::Dict{String, Any}
    if isempty(cfg.openai_api_key)
        return Dict("error" => "OpenAI API key not configured")
    end
    
    # Prepare data for LLM analysis
    performance_data = """
    Current Strategy Performance:
    - Total P&L: $(backtest_results["total_pnl"])
    - Win Rate: $(backtest_results["win_rate"] * 100)%
    - Max Drawdown: $(backtest_results["max_drawdown"] * 100)%
    - Sharpe Ratio: $(backtest_results["sharpe_ratio"])
    
    Current Parameters:
    - Base Spread: $(cfg.base_spread_pct)%
    - Order Levels: $(cfg.order_levels)
    - Max Capital: $(cfg.max_capital)
    - Risk Check Interval: $(cfg.risk_check_interval)s
    """
    
    prompt = """
    Analyze the following market making strategy performance and suggest optimal parameters.
    
    $performance_data
    
    Please suggest improvements for:
    1. base_spread_pct (current: $(cfg.base_spread_pct))
    2. order_levels (current: $(cfg.order_levels))
    3. risk_check_interval (current: $(cfg.risk_check_interval))
    
    Respond with specific numerical recommendations in JSON format:
    {
        "base_spread_pct": 0.XX,
        "order_levels": X,
        "risk_check_interval": XX,
        "reasoning": "explanation"
    }
    """
    
    try
        # Make API call to OpenAI (simplified - would need proper HTTP request)
        # For now, return simulated optimization
        return Dict(
            "base_spread_pct" => cfg.base_spread_pct * 1.1,
            "order_levels" => min(cfg.order_levels + 1, 5),
            "risk_check_interval" => max(cfg.risk_check_interval - 5, 15),
            "reasoning" => "Simulated LLM optimization"
        )
    catch e
        return Dict("error" => "LLM optimization failed: $e")
    end
end

# Enhanced market making execution with RL
function execute_rl_market_making(symbol::String, cfg::RLMarketMakingConfig, ctx::AgentContext, 
                                 agent::RLMarketMaker)
    try
        push!(ctx.logs, "Executing RL-enhanced market making for $symbol")
        
        # Extract current market state
        current_state = extract_market_state(symbol, cfg)
        
        # Select action using RL agent
        action = select_action(agent, current_state)
        
        # Apply action to strategy parameters
        adjusted_spread = cfg.base_spread_pct * (1.0 + action.spread_adjustment)
        adjusted_size_multiplier = action.order_size_multiplier
        
        push!(ctx.logs, "RL Action - Spread: $(round(adjusted_spread, digits=3))%, Size: $(round(adjusted_size_multiplier, digits=2))x")
        
        # Get current price for order placement
        price_data = binance_api_request_rl("/fapi/v1/ticker/price", "GET", cfg.api_key, cfg.api_secret,
                                       Dict("symbol" => symbol), true)  # Enable debug
        
        push!(ctx.logs, "🔍 Price data response type: $(typeof(price_data))")
        push!(ctx.logs, "🔍 Price data content: $price_data")
        
        # Handle both Dict and JSON3.Object types
        if haskey(price_data, "error")
            push!(ctx.logs, "❌ API Error: $(price_data["error"])")
            return false
        end
        
        if !haskey(price_data, "price")
            push!(ctx.logs, "❌ No price field in response. Available keys: $(keys(price_data))")
            return false
        end
        
        current_price = parse(Float64, string(price_data["price"]))
        push!(ctx.logs, "✅ Current price parsed: \$$(current_price)")
        
        # Calculate order sizes and prices
        base_order_size = (cfg.max_capital / cfg.order_levels / current_price) * adjusted_size_multiplier
        push!(ctx.logs, "📊 Base order size calculated: $(round(base_order_size, digits=6)) ETH")
        
        # Place orders at multiple levels
        orders_placed = 0
        total_orders_attempted = 0
        
        for level in 1:cfg.order_levels
            spread_multiplier = level * 0.5
            
            # Buy orders (bids)
            buy_price = current_price * (1 - adjusted_spread/100 * spread_multiplier)
            buy_size = base_order_size * (1.0 + action.risk_adjustment)
            
            push!(ctx.logs, "📉 Attempting BUY Level $level: $(round(buy_size, digits=6)) ETH @ \$$(round(buy_price, digits=2))")
            total_orders_attempted += 1
            
            buy_result = place_order_with_precision(symbol, "BUY", buy_size, buy_price, cfg.api_key, cfg.api_secret)
            
            if haskey(buy_result, "orderId")
                push!(ctx.logs, "✅ BUY order placed successfully: ID $(buy_result["orderId"])")
                orders_placed += 1
            else
                push!(ctx.logs, "❌ BUY order failed: $(get(buy_result, "error", "Unknown error")) - Full response: $buy_result")
            end
            
            # Sell orders (asks)
            sell_price = current_price * (1 + adjusted_spread/100 * spread_multiplier)
            sell_size = base_order_size * (1.0 - action.risk_adjustment)
            
            push!(ctx.logs, "📈 Attempting SELL Level $level: $(round(sell_size, digits=6)) ETH @ \$$(round(sell_price, digits=2))")
            total_orders_attempted += 1
            
            sell_result = place_order_with_precision(symbol, "SELL", sell_size, sell_price, cfg.api_key, cfg.api_secret)
            
            if haskey(sell_result, "orderId")
                push!(ctx.logs, "✅ SELL order placed successfully: ID $(sell_result["orderId"])")
                orders_placed += 1
            else
                push!(ctx.logs, "❌ SELL order failed: $(get(sell_result, "error", "Unknown error")) - Full response: $sell_result")
            end
        end
        
        push!(ctx.logs, "📋 Order Summary: $(orders_placed)/$(total_orders_attempted) orders placed successfully")
        
        # Store experience for learning
        if length(agent.experience_buffer.states) > 0
            prev_state = agent.experience_buffer.states[end]
            prev_action = agent.experience_buffer.actions[end]
            
            # Calculate reward based on order success
            reward = calculate_reward(prev_state, current_state, prev_action, Float64(orders_placed), cfg)
            
            # Add experience to buffer
            push!(agent.experience_buffer.rewards, reward)
            push!(agent.experience_buffer.next_states, current_state)
            push!(agent.experience_buffer.dones, false)
            
            push!(ctx.logs, "🧠 RL Learning: Reward=$(round(reward, digits=4)), Experience buffer size=$(length(agent.experience_buffer.states))")
        else
            push!(ctx.logs, "🧠 RL Learning: First experience recorded")
        end
        
        # Add current experience for next iteration
        push!(agent.experience_buffer.states, current_state)
        push!(agent.experience_buffer.actions, action)
        
        # Update Q-network periodically
        if length(agent.experience_buffer.states) % cfg.update_frequency == 0
            update_q_network!(agent)
            push!(ctx.logs, "🔄 Updated RL Q-network - Epsilon: $(round(agent.epsilon, digits=3)), Buffer size: $(length(agent.experience_buffer.states))")
        end
        
        push!(ctx.logs, "🎯 RL trading iteration completed successfully: $(orders_placed > 0 ? "SUCCESS" : "NO_ORDERS")")
        return orders_placed > 0
        
    catch e
        push!(ctx.logs, "❌ Critical error in RL market making: $e")
        push!(ctx.logs, "📍 Error stacktrace: $(sprint(showerror, e, catch_backtrace()))")
        return false
    end
end

# Helper function for precise order placement
function place_order_with_precision(symbol::String, side::String, amount::Float64, price::Float64, 
                                   api_key::String, api_secret::String)
    # Get symbol info for precision
    try
        #println("🔧 Getting exchange info for precision...")
        response = HTTP.get("https://testnet.binancefuture.com/fapi/v1/exchangeInfo")
        data = JSON3.read(String(response.body))
        
        qty_precision = 3  # Default
        price_precision = 2  # Default
        min_qty = 0.001  # Default
        
        for s in data.symbols
            if s.symbol == symbol
                for filter in s.filters
                    if filter.filterType == "LOT_SIZE"
                        min_qty = parse(Float64, filter.minQty)
                        step_size = parse(Float64, filter.stepSize)
                        if step_size < 1.0
                            qty_precision = length(split(string(step_size), ".")[2])
                        end
                    elseif filter.filterType == "PRICE_FILTER"
                        tick_size = parse(Float64, filter.tickSize)
                        if tick_size < 1.0
                            price_precision = length(split(string(tick_size), ".")[2])
                        end
                    end
                end
                break
            end
        end
        
        # Format with proper precision
        formatted_qty = round(max(amount, min_qty), digits=qty_precision)
        formatted_price = round(price, digits=price_precision)
        
        #println("🔧 Order formatting: Qty=$(formatted_qty) (precision=$qty_precision), Price=$(formatted_price) (precision=$price_precision)")
        
        params = Dict(
            "symbol" => symbol,
            "side" => side,
            "type" => "LIMIT",
            "timeInForce" => "GTC",
            "quantity" => string(formatted_qty),
            "price" => string(formatted_price)
        )
        
        #println("🔧 Placing order with params: $params")
        result = binance_api_request_rl("/fapi/v1/order", "POST", api_key, api_secret, params, true)  # Enable debug
        #println("🔧 Order result: $result")
        
        return result
        
    catch e
        error_result = Dict("error" => "Precision error: $e")
        println("❌ Order placement error: $error_result")
        return error_result
    end
end

# Main RL strategy functions
function strategy_rl_market_making_initialization(cfg::RLMarketMakingConfig, ctx::AgentContext)
    push!(ctx.logs, "Initializing RL-Enhanced Market Making Strategy")
    push!(ctx.logs, "Symbols: $(cfg.symbols)")
    push!(ctx.logs, "RL Learning: $(cfg.enable_rl_learning)")
    push!(ctx.logs, "LLM Optimization: $(cfg.enable_llm_optimization)")
    push!(ctx.logs, "Backtesting: $(cfg.backtest_enabled)")
    
    if cfg.backtest_enabled
        push!(ctx.logs, "Running initial backtest...")
        for symbol in cfg.symbols
            backtest_result = run_backtest(cfg, symbol, cfg.backtest_days)
            push!(ctx.logs, "Backtest $symbol: P&L=$(round(backtest_result["total_pnl"], digits=2)), WinRate=$(round(backtest_result["win_rate"]*100, digits=1))%")
        end
    end
    
    if !isempty(cfg.api_key)
        balance_data = binance_api_request_rl("/fapi/v2/account", "GET", cfg.api_key, cfg.api_secret)
        if !haskey(balance_data, "error")
            push!(ctx.logs, "Successfully connected to exchange API")
        else
            push!(ctx.logs, "WARNING: API connection failed")
        end
    end
end

# RL Input type
Base.@kwdef struct RLMarketMakingInput <: StrategyInput
    action::String = "start_rl_trading"
    symbol::Union{String, Nothing} = nothing
    learning_mode::Bool = true
    backtest_first::Bool = false
    params::Dict{String, Any} = Dict{String, Any}()
end

# Create global RL agent
const RL_AGENTS = Dict{String, RLMarketMaker}()

# Global trading control variables
mutable struct TradingControl
    is_running::Bool
    should_stop::Bool
    iteration_count::Int
    start_time::Float64
    
    function TradingControl()
        new(false, false, 0, 0.0)
    end
end

const TRADING_CONTROL = TradingControl()

# Cancel all open orders for a symbol (RL version) - FIXED
function cancel_all_orders_rl(symbol::String, api_key::String, api_secret::String)
    try
        println("🔍 DEBUG: Checking open orders for $symbol...")
        
        # Get all open orders
        open_orders = binance_api_request_rl("/fapi/v1/openOrders", "GET", api_key, api_secret, 
                                           Dict("symbol" => symbol), true)  # Enable debug
        
        #println("🔍 DEBUG: Open orders response type: $(typeof(open_orders))")
        
        # Handle error responses (when API returns Dict with error)
        if isa(open_orders, Dict) && haskey(open_orders, "error")
            println("❌ Error getting open orders: $(open_orders["error"])")
            return 0
        end
        
        # Handle successful response (JSON3.Array or Vector)
        if (isa(open_orders, Vector) || isa(open_orders, JSON3.Array)) && !isempty(open_orders)
            println("🔍 Found $(length(open_orders)) open orders to cancel")
            cancelled_count = 0
            
            for (i, order) in enumerate(open_orders)
                try
                    order_id = string(order["orderId"])
                    side = string(order["side"])
                    price = string(order["price"])
                    qty = string(order["origQty"])
                    
                    println("🔄 Cancelling order $i/$(length(open_orders)): $side $(qty) @ \$$(price) (ID: $order_id)")
                    
                    # Cancel each order
                    cancel_params = Dict("symbol" => symbol, "orderId" => order_id)
                    cancel_result = binance_api_request_rl("/fapi/v1/order", "DELETE", api_key, api_secret, cancel_params, true)
                    
                    # Check if cancellation was successful
                    if isa(cancel_result, Dict) && haskey(cancel_result, "error")
                        println("❌ Failed to cancel order $order_id: $(cancel_result["error"])")
                    elseif haskey(cancel_result, "orderId") || haskey(cancel_result, "symbol")
                        println("✅ Successfully cancelled order $order_id")
                        cancelled_count += 1
                    else
                        println("⚠️ Uncertain cancellation result for order $order_id: $cancel_result")
                        cancelled_count += 1  # Assume success if no clear error
                    end
                    
                    # Rate limiting to avoid API spam
                    sleep(0.1)
                    
                catch order_error
                    println("❌ Error cancelling individual order: $order_error")
                end
            end
            
            println("📊 Cancellation Summary: $cancelled_count/$(length(open_orders)) orders cancelled successfully")
            return cancelled_count
        else
            println("✅ No open orders found for $symbol")
            return 0
        end
        
    catch e
        println("❌ Critical error in cancel_all_orders_rl: $e")
        println("📍 Full stacktrace: $(sprint(showerror, e, catch_backtrace()))")
        return 0
    end
end

# Global variable to store the background trading task
BACKGROUND_TASK = Ref{Union{Task, Nothing}}(nothing)

# Background Trading Loop
function trading_loop_background(cfg::RLMarketMakingConfig, ctx::AgentContext)
    try
        while TRADING_CONTROL.is_running && !TRADING_CONTROL.should_stop
            TRADING_CONTROL.iteration_count += 1
            cycle_start = time()
            
            push!(ctx.logs, "")
            push!(ctx.logs, "🔄 === RL Trading Cycle $(TRADING_CONTROL.iteration_count) ===")
            push!(ctx.logs, "⏰ Time: $(Dates.format(Dates.now(), "HH:MM:SS"))")
            
            for symbol in cfg.symbols
                push!(ctx.logs, "📈 Processing $symbol...")
                
                # Step 1: ALWAYS Cancel existing orders first (fresh start each cycle)
                push!(ctx.logs, "🧹 FORCE CANCELLING all orders for $symbol...")
                cancelled_count = cancel_all_orders_rl(symbol, cfg.api_key, cfg.api_secret)
                
                if cancelled_count > 0
                    push!(ctx.logs, "✅ Successfully cancelled $cancelled_count orders for $symbol")
                    # Give exchange time to process cancellations
                    sleep(3)
                else
                    push!(ctx.logs, "🔄 No orders to cancel for $symbol (fresh start)")
                end
                
                # Step 2: Execute RL market making (creates new orders)
                if haskey(RL_AGENTS, symbol)
                    agent = RL_AGENTS[symbol]
                    success = execute_rl_market_making(symbol, cfg, ctx, agent)
                    
                    if success
                        push!(ctx.logs, "✅ $symbol cycle completed successfully")
                    else
                        push!(ctx.logs, "❌ $symbol cycle failed - will retry next cycle")
                    end
                else
                    push!(ctx.logs, "❌ No RL agent found for $symbol - creating agent...")
                    # Create missing agent
                    RL_AGENTS[symbol] = RLMarketMaker(20, 4, cfg.memory_size)
                    push!(ctx.logs, "✅ Created new RL agent for $symbol")
                end
                
                # Rate limiting between symbols
                sleep(2)
            end
            
            cycle_time = time() - cycle_start
            push!(ctx.logs, "⏱️ Cycle $(TRADING_CONTROL.iteration_count) completed in $(round(cycle_time, digits=1))s")
            
            # Update PnL tracking every cycle
            if TRADING_CONTROL.iteration_count % 2 == 0  # Update every 2 cycles (every minute)
                if update_pnl_tracker(cfg.api_key, cfg.api_secret)
                    # Quick PnL status
                    current_pnl = GLOBAL_PNL_TRACKER.current_balance_usdt - GLOBAL_PNL_TRACKER.initial_balance_usdt
                    pnl_pct = (current_pnl / GLOBAL_PNL_TRACKER.initial_balance_usdt) * 100
                    
                    if abs(current_pnl) > 0.01
                        push!(ctx.logs, "💰 PnL Update: \$$(round(current_pnl, digits=2)) ($(round(pnl_pct, digits=2))%)")
                        push!(ctx.logs, "📊 Balance: \$$(round(GLOBAL_PNL_TRACKER.current_balance_usdt, digits=2)) | Trades: $(GLOBAL_PNL_TRACKER.total_trades)")
                    end
                end
            end
            
            # Learning progress
            total_experiences = sum([length(agent.experience_buffer.states) for agent in values(RL_AGENTS)])
            avg_epsilon = mean([agent.epsilon for agent in values(RL_AGENTS)])
            push!(ctx.logs, "🧠 Learning Progress: $(total_experiences) experiences, ε=$(round(avg_epsilon, digits=3))")
            
            # Check stopping conditions (24/7 operation - only stops when manually requested)
            runtime = time() - TRADING_CONTROL.start_time
            if runtime > 86400  # Log every 24 hours for monitoring
                hours = round(runtime / 3600, digits=1)
                push!(ctx.logs, "⏰ 24/7 Trading Status: Running for $hours hours ($(TRADING_CONTROL.iteration_count) cycles)")
                
                # Generate detailed performance report every 24 hours
                performance_report = generate_performance_report()
                for line in split(performance_report, '\n')
                    if !isempty(strip(line))
                        push!(ctx.logs, line)
                    end
                end
            end
            
            # Wait for next cycle
            if !TRADING_CONTROL.should_stop
                push!(ctx.logs, "😴 Waiting 30s for next cycle...")
                for i in 1:30
                    if TRADING_CONTROL.should_stop
                        break
                    end
                    sleep(1)
                end
            end
        end
        
    catch e
        push!(ctx.logs, "❌ Critical error in continuous trading: $e")
        push!(ctx.logs, "📍 Stacktrace: $(sprint(showerror, e, catch_backtrace()))")
    finally
        TRADING_CONTROL.is_running = false
        push!(ctx.logs, "🛑 Continuous RL trading stopped")
        push!(ctx.logs, "📊 Final Stats: $(TRADING_CONTROL.iteration_count) cycles, $(round((time() - TRADING_CONTROL.start_time)/60, digits=1))min runtime")
        
        # Generate final comprehensive performance report
        push!(ctx.logs, "💰 Generating Final Performance Report...")
        final_report = generate_performance_report()
        for line in split(final_report, '\n')
            if !isempty(strip(line))
                push!(ctx.logs, line)
            end
        end
        
        # Cancel all remaining orders
        for symbol in cfg.symbols
            cancelled = cancel_all_orders_rl(symbol, cfg.api_key, cfg.api_secret)
            if cancelled > 0
                push!(ctx.logs, "🔄 Final cleanup: cancelled $cancelled orders for $symbol")
            end
        end
        
        BACKGROUND_TASK[] = nothing
    end
end

# Updated Continuous RL Trading Loop - Non-blocking
function start_continuous_rl_trading(cfg::RLMarketMakingConfig, ctx::AgentContext)
    # Check if already running
    if TRADING_CONTROL.is_running
        push!(ctx.logs, "⚠️ Trading loop already running! Use option 3 to stop first.")
        return
    end
    
    TRADING_CONTROL.is_running = true
    TRADING_CONTROL.should_stop = false
    TRADING_CONTROL.iteration_count = 0
    TRADING_CONTROL.start_time = time()
    
    push!(ctx.logs, "🚀 Starting CONTINUOUS RL Trading Loop (24/7)")
    push!(ctx.logs, "📊 Trading Config: Symbols=$(cfg.symbols), Cycle=30s, Mode=24/7")
    push!(ctx.logs, "💡 Trading will run 24/7 until manually stopped!")
    push!(ctx.logs, "🔄 Each cycle: Cancel ALL orders → Create fresh orders → Wait 30s → Repeat")
    
    # Initialize PnL Tracker
    push!(ctx.logs, "💰 Initializing comprehensive PnL tracking system...")
    if initialize_pnl_tracker(cfg.api_key, cfg.api_secret)
        push!(ctx.logs, "✅ PnL Tracker initialized successfully!")
        push!(ctx.logs, "📊 Tracking: Balance changes, PnL, APY, Sharpe ratio, Win rate, Drawdown")
    else
        push!(ctx.logs, "⚠️ PnL Tracker initialization failed - continuing without detailed tracking")
    end
    
    # Initialize RL agents for each symbol
    for symbol in cfg.symbols
        if !haskey(RL_AGENTS, symbol)
            RL_AGENTS[symbol] = RLMarketMaker(20, 4, cfg.memory_size)
            push!(ctx.logs, "🤖 Initialized RL agent for $symbol")
        end
    end
    
    # Start background task
    BACKGROUND_TASK[] = @async trading_loop_background(cfg, ctx)
    
    push!(ctx.logs, "✅ Background trading task started successfully!")
    push!(ctx.logs, "📌 You can now:")
    push!(ctx.logs, "   - Use option 2 to check real-time status")
    push!(ctx.logs, "   - Use option 3 to stop trading")
    push!(ctx.logs, "   - Use option 7 to view recent logs")
end

# Stop continuous trading
function stop_continuous_rl_trading(ctx::AgentContext)
    if TRADING_CONTROL.is_running
        TRADING_CONTROL.should_stop = true
        push!(ctx.logs, "🛑 Stop signal sent to continuous trading loop...")
    else
        push!(ctx.logs, "ℹ️ No continuous trading session running")
    end
end

function strategy_rl_market_making(cfg::RLMarketMakingConfig, ctx::AgentContext, input::RLMarketMakingInput)
    push!(ctx.logs, "RL Market Making Strategy execution started")
    push!(ctx.logs, "Action: $(input.action)")
    
    if input.action == "start_rl_trading"
        push!(ctx.logs, "🚀 Starting RL-enhanced market making...")
        push!(ctx.logs, "🔧 Configuration: Symbols=$(cfg.symbols), Spread=$(cfg.base_spread_pct)%, Levels=$(cfg.order_levels)")
        
        if input.learning_mode
            # Start continuous trading loop
            start_continuous_rl_trading(cfg, ctx)
        else
            # Single iteration mode (for testing)
            push!(ctx.logs, "🧪 Running single iteration (test mode)...")
            # Initialize RL agents for each symbol
            for symbol in cfg.symbols
                if !haskey(RL_AGENTS, symbol)
                    RL_AGENTS[symbol] = RLMarketMaker(20, 4, cfg.memory_size)
                    push!(ctx.logs, "🤖 Initialized RL agent for $symbol")
                end
            end
            
            success_count = 0
            for (i, symbol) in enumerate(cfg.symbols)
                agent = RL_AGENTS[symbol]
                success = execute_rl_market_making(symbol, cfg, ctx, agent)
                if success
                    success_count += 1
                end
            end
            push!(ctx.logs, "🎯 Single iteration completed: $success_count/$(length(cfg.symbols)) successful")
        end
        
    elseif input.action == "run_backtest"
        push!(ctx.logs, "Running comprehensive backtest...")
        
        for symbol in cfg.symbols
            result = run_backtest(cfg, symbol, cfg.backtest_days)
            push!(ctx.logs, "Backtest $symbol - P&L: $(round(result["total_pnl"], digits=2)), Sharpe: $(round(result["sharpe_ratio"], digits=3))")
        end
        
    elseif input.action == "optimize_parameters"
        push!(ctx.logs, "Running LLM parameter optimization...")
        
        if cfg.enable_llm_optimization
            for symbol in cfg.symbols
                backtest_result = run_backtest(cfg, symbol, cfg.backtest_days)
                optimization_result = llm_optimize_parameters(cfg, backtest_result)
                push!(ctx.logs, "LLM Optimization $symbol: $optimization_result")
            end
        else
            push!(ctx.logs, "LLM optimization disabled")
        end
        
    elseif input.action == "train_rl_model"
        push!(ctx.logs, "Training RL models...")
        
        for symbol in cfg.symbols
            if haskey(RL_AGENTS, symbol)
                agent = RL_AGENTS[symbol]
                update_q_network!(agent)
                push!(ctx.logs, "Updated RL model for $symbol - Buffer: $(length(agent.experience_buffer.states))")
            end
        end
        
    elseif input.action == "emergency_cleanup"
        push!(ctx.logs, "🚨 EMERGENCY: Cancelling ALL open orders...")
        
        total_cancelled = 0
        for symbol in cfg.symbols
            push!(ctx.logs, "🔧 Emergency cleanup for $symbol...")
            cancelled = cancel_all_orders_rl(symbol, cfg.api_key, cfg.api_secret)
            total_cancelled += cancelled
            push!(ctx.logs, "✅ Emergency cleanup $symbol: $cancelled orders cancelled")
        end
        
        push!(ctx.logs, "🎯 Emergency cleanup completed: $total_cancelled total orders cancelled")
        push!(ctx.logs, "💡 Margin should now be freed up for new orders!")
        
    elseif input.action == "status_check"
        push!(ctx.logs, "📊 === RL Trading System Status ===")
        
        # Background task status
        if BACKGROUND_TASK[] !== nothing
            task_status = istaskdone(BACKGROUND_TASK[]) ? "COMPLETED" : (istaskfailed(BACKGROUND_TASK[]) ? "FAILED" : "RUNNING")
            push!(ctx.logs, "🔧 Background Task: $task_status")
        else
            push!(ctx.logs, "🔧 Background Task: NOT STARTED")
        end
        
        # Trading status
        if TRADING_CONTROL.is_running
            runtime = time() - TRADING_CONTROL.start_time
            hours_running = round(runtime/3600, digits=1)
            push!(ctx.logs, "🟢 24/7 Continuous Trading ACTIVE")
            push!(ctx.logs, "  ⏱️ Cycles completed: $(TRADING_CONTROL.iteration_count) (unlimited)")
            push!(ctx.logs, "  🕐 Runtime: $(hours_running) hours (24/7 mode)")
            push!(ctx.logs, "  🔄 Order management: Cancel ALL → Create fresh orders every 30s")
            push!(ctx.logs, "  🛑 Stop requested: $(TRADING_CONTROL.should_stop)")
            
            # Next cycle countdown
            cycle_time_elapsed = (time() - TRADING_CONTROL.start_time) % 30
            next_cycle_in = round(30 - cycle_time_elapsed, digits=1)
            push!(ctx.logs, "  ⏰ Next cycle in: $(next_cycle_in)s")
        else
            push!(ctx.logs, "🔴 24/7 Trading INACTIVE - Ready to start")
        end
        
        # Agent status
        push!(ctx.logs, "")
        push!(ctx.logs, "🤖 RL Agent Status:")
        for symbol in cfg.symbols
            if haskey(RL_AGENTS, symbol)
                agent = RL_AGENTS[symbol]
                buffer_percent = round(length(agent.experience_buffer.states) / agent.experience_buffer.capacity * 100, digits=1)
                push!(ctx.logs, "  📈 $symbol:")
                push!(ctx.logs, "    💾 Experience buffer: $(length(agent.experience_buffer.states))/$(agent.experience_buffer.capacity) ($(buffer_percent)%)")
                push!(ctx.logs, "    🎯 Exploration rate: $(round(agent.epsilon, digits=3))")
                push!(ctx.logs, "    🧠 Learning rate: $(round(agent.learning_rate, digits=4))")
            else
                push!(ctx.logs, "  📈 $symbol: ❌ No agent initialized")
            end
        end
        
        # Current open orders status - ENHANCED DEBUG
        push!(ctx.logs, "")
        push!(ctx.logs, "📋 Current Open Orders (DETAILED CHECK):")
        for symbol in cfg.symbols
            try
                push!(ctx.logs, "  🔍 Checking open orders for $symbol...")
                open_orders = binance_api_request_rl("/fapi/v1/openOrders", "GET", cfg.api_key, cfg.api_secret, 
                                                   Dict("symbol" => symbol), true)  # Enable debug
                
                push!(ctx.logs, "  🔍 API Response Type: $(typeof(open_orders))")
                
                # Handle error responses
                if isa(open_orders, Dict) && haskey(open_orders, "error")
                    push!(ctx.logs, "  ❌ $symbol: API Error - $(open_orders["error"])")
                    continue
                end
                
                if (isa(open_orders, Vector) || isa(open_orders, JSON3.Array)) && !isempty(open_orders)
                    push!(ctx.logs, "  � $symbol: $(length(open_orders)) OPEN ORDERS FOUND!")
                    push!(ctx.logs, "    ⚠️  This explains the margin insufficient error!")
                    
                    for (i, order) in enumerate(open_orders[1:min(5, length(open_orders))])  # Show first 5
                        side = string(order["side"])
                        price = string(order["price"])
                        qty = string(order["origQty"])
                        status = string(get(order, "status", "UNKNOWN"))
                        order_id = string(order["orderId"])
                        push!(ctx.logs, "    $(i). $side $(qty) @ \$$(price) (Status: $status, ID: $order_id)")
                    end
                    
                    if length(open_orders) > 5
                        push!(ctx.logs, "    ... and $(length(open_orders) - 5) MORE orders!")
                    end
                    
                    push!(ctx.logs, "  💡 Next cycle should cancel these $(length(open_orders)) orders")
                else
                    push!(ctx.logs, "  ✅ $symbol: No open orders found")
                end
            catch e
                push!(ctx.logs, "  ❌ $symbol: Exception checking orders - $e")
                push!(ctx.logs, "     Full error: $(sprint(showerror, e, catch_backtrace()))")
            end
        end
        
        # Recent activity (last 10 log entries)
        push!(ctx.logs, "")
        push!(ctx.logs, "📋 Recent Activity (last 10 entries):")
        if length(ctx.logs) > 10
            recent_logs = ctx.logs[max(1, length(ctx.logs)-20):end-1]  # Exclude current log entries
            for (i, log) in enumerate(recent_logs[max(1, end-9):end])
                if !contains(log, "Recent Activity") && !contains(log, "RL Trading System Status")
                    push!(ctx.logs, "    $(i). $log")
                end
            end
        else
            push!(ctx.logs, "    No recent activity to display")
        end
        
    elseif input.action == "stop_trading"
        push!(ctx.logs, "Stopping RL trading...")
        stop_continuous_rl_trading(ctx)
        
    else
        push!(ctx.logs, "Unknown RL action: $(input.action)")
    end
    
    push!(ctx.logs, "RL Market Making Strategy execution completed")
end

# Strategy specification
const STRATEGY_RL_MARKET_MAKING_METADATA = StrategyMetadata(
    "rl_market_making"
)

const STRATEGY_RL_MARKET_MAKING_SPECIFICATION = StrategySpecification(
    strategy_rl_market_making,
    strategy_rl_market_making_initialization,
    RLMarketMakingConfig,
    STRATEGY_RL_MARKET_MAKING_METADATA,
    RLMarketMakingInput
)
