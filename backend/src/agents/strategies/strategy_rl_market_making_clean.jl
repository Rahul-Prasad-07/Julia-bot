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

# HMAC-SHA256 signature generation
function hmac_sha256_rl(key::String, message::String)
    key_bytes = Vector{UInt8}(key)
    message_bytes = Vector{UInt8}(message)
    signature = SHA.hmac_sha256(key_bytes, message_bytes)
    return bytes2hex(signature)
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
            println("  Endpoint: $endpoint")
            println("  URL: $base_url$endpoint")
            println("  Query: $(query_string)")
            println("  API Key: $(api_key[1:min(8,length(api_key))])...$(api_key[max(1,end-4):end])")
        end
        
        if method == "GET"
            response = HTTP.get("$base_url$endpoint?$full_query", headers)
        elseif method == "POST"
            response = HTTP.post("$base_url$endpoint", headers, full_query)
        else
            error("Unsupported HTTP method: $method")
        end
        
        response_body = String(response.body)
        parsed_result = JSON3.read(response_body)
        
        if debug
            println("  Response Status: $(response.status)")
            println("  Response Body: $(response_body[1:min(200, length(response_body))])")
            println("  Parsed Successfully: $(typeof(parsed_result))")
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
        println("🔧 Getting exchange info for precision...")
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
        
        println("🔧 Order formatting: Qty=$(formatted_qty) (precision=$qty_precision), Price=$(formatted_price) (precision=$price_precision)")
        
        params = Dict(
            "symbol" => symbol,
            "side" => side,
            "type" => "LIMIT",
            "timeInForce" => "GTC",
            "quantity" => string(formatted_qty),
            "price" => string(formatted_price)
        )
        
        println("🔧 Placing order with params: $params")
        result = binance_api_request_rl("/fapi/v1/order", "POST", api_key, api_secret, params, true)  # Enable debug
        println("🔧 Order result: $result")
        
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

function strategy_rl_market_making(cfg::RLMarketMakingConfig, ctx::AgentContext, input::RLMarketMakingInput)
    push!(ctx.logs, "RL Market Making Strategy execution started")
    push!(ctx.logs, "Action: $(input.action)")
    
    if input.action == "start_rl_trading"
        push!(ctx.logs, "🚀 Starting RL-enhanced market making...")
        push!(ctx.logs, "🔧 Configuration: Symbols=$(cfg.symbols), Spread=$(cfg.base_spread_pct)%, Levels=$(cfg.order_levels)")
        
        # Initialize RL agents for each symbol
        for symbol in cfg.symbols
            if !haskey(RL_AGENTS, symbol)
                RL_AGENTS[symbol] = RLMarketMaker(20, 4, cfg.memory_size)  # 20 state features, 4 actions
                push!(ctx.logs, "🤖 Initialized RL agent for $symbol (State: 20D, Actions: 4D, Memory: $(cfg.memory_size))")
            end
        end
        
        success_count = 0
        total_symbols = length(cfg.symbols)
        
        for (i, symbol) in enumerate(cfg.symbols)
            push!(ctx.logs, "📈 Processing symbol $i/$total_symbols: $symbol")
            agent = RL_AGENTS[symbol]
            
            start_time = time()
            success = execute_rl_market_making(symbol, cfg, ctx, agent)
            execution_time = time() - start_time
            
            if success
                success_count += 1
                push!(ctx.logs, "✅ $symbol completed successfully in $(round(execution_time, digits=2))s")
            else
                push!(ctx.logs, "❌ $symbol failed after $(round(execution_time, digits=2))s")
            end
            
            if i < total_symbols
                push!(ctx.logs, "⏱️ Rate limiting: sleeping 1s...")
                sleep(1)  # Rate limiting
            end
        end
        
        push!(ctx.logs, "🎯 RL trading round completed: $success_count/$total_symbols symbols successful")
        
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
        
    elseif input.action == "status_check"
        push!(ctx.logs, "Checking RL trading status...")
        
        for symbol in cfg.symbols
            if haskey(RL_AGENTS, symbol)
                agent = RL_AGENTS[symbol]
                push!(ctx.logs, "Status for $symbol:")
                push!(ctx.logs, "  Experience buffer: $(length(agent.experience_buffer.states))/$(agent.experience_buffer.capacity)")
                push!(ctx.logs, "  Exploration rate: $(round(agent.epsilon, digits=3))")
                push!(ctx.logs, "  Learning rate: $(agent.learning_rate)")
            else
                push!(ctx.logs, "No RL agent found for $symbol")
            end
        end
        
    elseif input.action == "stop_trading"
        push!(ctx.logs, "Stopping RL trading...")
        # Could add order cancellation here
        push!(ctx.logs, "RL trading stopped")
        
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
