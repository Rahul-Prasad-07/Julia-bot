"""
AI Swarm Trading Strategy Integration

This module provides the integration layer between the AI Swarm Market Making strategy
and the JuliaOS agent system, enabling API-driven trading operations.
"""

using ..CommonTypes: StrategyConfig, AgentContext, StrategySpecification, StrategyMetadata, StrategyInput

# Import the AI Swarm strategy
# include("strategy_ai_swarm_market_making.jl")  # Already included in Strategies.jl

"""
Wrapper configuration for AI Swarm integration with JuliaOS agent system
"""
Base.@kwdef mutable struct AISwarmWrapperConfig <: StrategyConfig
    # Core AI Swarm parameters (delegated to AISwarmMarketMakingConfig)
    ai_swarm_config::AISwarmMarketMakingConfig = AISwarmMarketMakingConfig()
    
    # Integration parameters
    auto_start::Bool = false
    api_mode::Bool = true
    enable_webhooks::Bool = true
    status_update_interval::Int = 30
    
    # Logging and monitoring
    detailed_logging::Bool = true
    performance_tracking::Bool = true
    enable_alerts::Bool = true
end

"""
Input structure for AI Swarm wrapper operations
"""
Base.@kwdef struct AISwarmWrapperInput <: StrategyInput
    action::String = "status"  # "start", "stop", "status", "emergency_stop", "configure"
    config_updates::Dict{String, Any} = Dict{String, Any}()
    symbol::String = "ETHUSDT"
    force_restart::Bool = false
end

"""
AI Swarm strategy wrapper initialization
"""
function strategy_ai_swarm_wrapper_initialization(
    cfg::AISwarmWrapperConfig,
    ctx::AgentContext
)
    push!(ctx.logs, "🤖🐝 Initializing AI Swarm Trading Wrapper")
    
    try
        # Validate API credentials
        if isempty(cfg.ai_swarm_config.api_key) || isempty(cfg.ai_swarm_config.api_secret)
            push!(ctx.logs, "⚠️ WARNING: Missing Binance API credentials")
            push!(ctx.logs, "ℹ️ Set BINANCE_API_KEY and BINANCE_API_SECRET environment variables")
        else
            push!(ctx.logs, "✅ Binance API credentials configured")
        end
        
        if cfg.ai_swarm_config.enable_groq_sentiment && isempty(cfg.ai_swarm_config.groq_api_key)
            push!(ctx.logs, "⚠️ WARNING: Missing Groq API key for sentiment analysis")
            push!(ctx.logs, "ℹ️ Set GROQ_API_KEY environment variable or disable Groq sentiment")
        else
            push!(ctx.logs, "✅ Groq LLM sentiment analysis configured")
        end
        
        # Initialize AI Swarm system state tracking
        push!(ctx.logs, "📊 AI Swarm configuration:")
        push!(ctx.logs, "   • Symbols: $(cfg.ai_swarm_config.symbols)")
        push!(ctx.logs, "   • Base Spread: $(cfg.ai_swarm_config.base_spread_pct)%")
        push!(ctx.logs, "   • Order Levels: $(cfg.ai_swarm_config.order_levels)")
        push!(ctx.logs, "   • Max Capital: \$$(cfg.ai_swarm_config.max_capital)")
        push!(ctx.logs, "   • Consensus Threshold: $(cfg.ai_swarm_config.consensus_threshold*100)%")
        push!(ctx.logs, "   • Neural Networks: $(cfg.ai_swarm_config.enable_neural_networks)")
        push!(ctx.logs, "   • Swarm Consensus: $(cfg.ai_swarm_config.enable_swarm_consensus)")
        
        # Auto-start if configured
        if cfg.auto_start
            push!(ctx.logs, "🚀 Auto-starting AI Swarm trading...")
            start_ai_swarm_trading(cfg.ai_swarm_config, ctx)
        end
        
        push!(ctx.logs, "✅ AI Swarm wrapper initialized successfully")
        push!(ctx.logs, "🌐 API endpoints available for external control")
        
    catch e
        push!(ctx.logs, "❌ AI Swarm wrapper initialization failed: $e")
        push!(ctx.logs, "📍 Stacktrace: $(sprint(showerror, e, catch_backtrace()))")
    end
end

"""
Main AI Swarm wrapper strategy function
"""
function strategy_ai_swarm_wrapper(
    cfg::AISwarmWrapperConfig,
    ctx::AgentContext,
    input::AISwarmWrapperInput
)
    push!(ctx.logs, "🤖🐝 Processing AI Swarm request: $(input.action)")
    
    try
        result = Dict{String, Any}(
            "success" => false,
            "action" => input.action,
            "timestamp" => now(),
            "message" => ""
        )
        
        if input.action == "start"
            # Start AI Swarm trading
            push!(ctx.logs, "🚀 Starting AI Swarm trading...")
            
            # Apply any configuration updates
            if !isempty(input.config_updates)
                apply_config_updates!(cfg.ai_swarm_config, input.config_updates)
                push!(ctx.logs, "⚙️ Applied configuration updates: $(keys(input.config_updates))")
            end
            
            # Start the trading system
            start_ai_swarm_trading(cfg.ai_swarm_config, ctx)
            
            result["success"] = true
            result["message"] = "AI Swarm trading started successfully"
            result["config"] = extract_config_info(cfg.ai_swarm_config)
            
        elseif input.action == "stop"
            # Stop AI Swarm trading
            push!(ctx.logs, "🛑 Stopping AI Swarm trading...")
            
            stop_ai_swarm_trading(ctx)
            
            result["success"] = true
            result["message"] = "AI Swarm trading stopped successfully"
            result["final_stats"] = Dict(
                "iterations" => AI_SWARM_TRADING_CONTROL.iteration_count,
                "runtime_seconds" => time() - AI_SWARM_TRADING_CONTROL.start_time
            )
            
        elseif input.action == "emergency_stop"
            # Emergency stop with order cancellation
            push!(ctx.logs, "🚨 EMERGENCY STOP - Cancelling all orders and stopping trading")
            
            stop_ai_swarm_trading(ctx)
            
            # Cancel all orders for all symbols
            cancelled_orders = 0
            for symbol in cfg.ai_swarm_config.symbols
                try
                    cancelled = cancel_all_orders_ai_swarm(symbol, cfg.ai_swarm_config.api_key, cfg.ai_swarm_config.api_secret)
                    cancelled_orders += cancelled
                    push!(ctx.logs, "✅ Cancelled $cancelled orders for $symbol")
                catch e
                    push!(ctx.logs, "⚠️ Failed to cancel orders for $symbol: $e")
                end
            end
            
            result["success"] = true
            result["message"] = "Emergency stop executed - cancelled $cancelled_orders orders"
            result["cancelled_orders"] = cancelled_orders
            
        elseif input.action == "status"
            # Get current system status
            push!(ctx.logs, "📊 Retrieving AI Swarm system status")
            
            status_info = Dict{String, Any}(
                "trading_active" => AI_SWARM_TRADING_CONTROL.is_running,
                "iteration_count" => AI_SWARM_TRADING_CONTROL.iteration_count,
                "should_stop" => AI_SWARM_TRADING_CONTROL.should_stop,
                "start_time" => AI_SWARM_TRADING_CONTROL.start_time,
                "runtime_seconds" => AI_SWARM_TRADING_CONTROL.is_running ? time() - AI_SWARM_TRADING_CONTROL.start_time : 0,
                "active_symbols" => length(GLOBAL_AI_SWARM_AGENTS),
                "pnl_summary" => Dict(
                    "current_balance" => GLOBAL_AI_SWARM_PNL_TRACKER.current_balance_usdt,
                    "total_trades" => GLOBAL_AI_SWARM_PNL_TRACKER.total_trades,
                    "ai_accuracy" => GLOBAL_AI_SWARM_PNL_TRACKER.ai_decision_accuracy,
                    "consensus_rate" => GLOBAL_AI_SWARM_PNL_TRACKER.swarm_consensus_rate
                )
            )
            
            result["success"] = true
            result["message"] = "Status retrieved successfully"
            result["status"] = status_info
            
        elseif input.action == "configure"
            # Update configuration
            push!(ctx.logs, "⚙️ Updating AI Swarm configuration")
            
            if AI_SWARM_TRADING_CONTROL.is_running && !input.force_restart
                critical_updates = ["symbols", "api_key", "api_secret", "max_capital"]
                has_critical = any(key -> haskey(input.config_updates, key), critical_updates)
                
                if has_critical
                    result["success"] = false
                    result["message"] = "Critical configuration updates require system restart. Use force_restart=true or stop trading first."
                    return JSON3.write(result)
                end
            end
            
            # Apply configuration updates
            apply_config_updates!(cfg.ai_swarm_config, input.config_updates)
            
            # Restart if force_restart is true and system is running
            if input.force_restart && AI_SWARM_TRADING_CONTROL.is_running
                push!(ctx.logs, "🔄 Force restarting AI Swarm with new configuration")
                stop_ai_swarm_trading(ctx)
                sleep(2)  # Allow clean shutdown
                start_ai_swarm_trading(cfg.ai_swarm_config, ctx)
            end
            
            result["success"] = true
            result["message"] = "Configuration updated successfully"
            result["updated_fields"] = collect(keys(input.config_updates))
            result["current_config"] = extract_config_info(cfg.ai_swarm_config)
            
        elseif input.action == "performance"
            # Get performance report
            push!(ctx.logs, "📈 Generating AI Swarm performance report")
            
            performance_report = generate_ai_swarm_performance_report()
            
            result["success"] = true
            result["message"] = "Performance report generated successfully"
            result["performance_report"] = performance_report
            result["metrics_summary"] = Dict(
                "total_trades" => GLOBAL_AI_SWARM_PNL_TRACKER.total_trades,
                "ai_decision_accuracy" => GLOBAL_AI_SWARM_PNL_TRACKER.ai_decision_accuracy,
                "swarm_consensus_rate" => GLOBAL_AI_SWARM_PNL_TRACKER.swarm_consensus_rate,
                "current_balance" => GLOBAL_AI_SWARM_PNL_TRACKER.current_balance_usdt,
                "total_pnl" => GLOBAL_AI_SWARM_PNL_TRACKER.total_realized_pnl,
                "max_drawdown" => GLOBAL_AI_SWARM_PNL_TRACKER.max_drawdown
            )
            
        elseif input.action == "realtime_data"
            # Get real-time market data and AI analysis
            push!(ctx.logs, "📡 Fetching real-time data for $(input.symbol)")
            
            market_data = fetch_market_data(input.symbol, cfg.ai_swarm_config.api_key, cfg.ai_swarm_config.api_secret)
            
            ai_analysis = nothing
            if haskey(GLOBAL_AI_SWARM_AGENTS, input.symbol)
                agents = GLOBAL_AI_SWARM_AGENTS[input.symbol]
                try
                    ai_analysis = analyze_market_with_ai(agents["market_analyzer"], market_data)
                catch e
                    push!(ctx.logs, "⚠️ Failed to get AI analysis: $e")
                end
            end
            
            result["success"] = true
            result["message"] = "Real-time data retrieved successfully"
            result["symbol"] = input.symbol
            result["market_data"] = market_data
            result["ai_analysis"] = ai_analysis
            
        else
            result["success"] = false
            result["message"] = "Unknown action: $(input.action)"
            push!(ctx.logs, "❌ Unknown action requested: $(input.action)")
        end
        
        push!(ctx.logs, "✅ AI Swarm request completed: $(input.action)")
        return JSON3.write(result)
        
    catch e
        push!(ctx.logs, "❌ AI Swarm request failed: $e")
        push!(ctx.logs, "📍 Stacktrace: $(sprint(showerror, e, catch_backtrace()))")
        
        error_result = Dict{String, Any}(
            "success" => false,
            "action" => input.action,
            "error" => string(e),
            "timestamp" => now()
        )
        
        return JSON3.write(error_result)
    end
end

"""
Helper Functions
"""

function apply_config_updates!(config::AISwarmMarketMakingConfig, updates::Dict{String, Any})
    for (key, value) in updates
        if key == "symbols" && isa(value, Vector)
            config.symbols = value
        elseif key == "base_spread_pct" && isa(value, Number)
            config.base_spread_pct = Float64(value)
        elseif key == "order_levels" && isa(value, Number)
            config.order_levels = Int(value)
        elseif key == "max_capital" && isa(value, Number)
            config.max_capital = Float64(value)
        elseif key == "leverage" && isa(value, Number)
            config.leverage = Int(value)
        elseif key == "max_drawdown" && isa(value, Number)
            config.max_drawdown = Float64(value)
        elseif key == "consensus_threshold" && isa(value, Number)
            config.consensus_threshold = Float64(value)
        elseif key == "enable_neural_networks" && isa(value, Bool)
            config.enable_neural_networks = value
        elseif key == "enable_groq_sentiment" && isa(value, Bool)
            config.enable_groq_sentiment = value
        elseif key == "enable_swarm_consensus" && isa(value, Bool)
            config.enable_swarm_consensus = value
        elseif key == "agent_count" && isa(value, Number)
            config.agent_count = Int(value)
        elseif key == "swarm_update_frequency" && isa(value, Number)
            config.swarm_update_frequency = Int(value)
        end
    end
end

function extract_config_info(config::AISwarmMarketMakingConfig)::Dict{String, Any}
    return Dict{String, Any}(
        "symbols" => config.symbols,
        "base_spread_pct" => config.base_spread_pct,
        "order_levels" => config.order_levels,
        "max_capital" => config.max_capital,
        "leverage" => config.leverage,
        "max_drawdown" => config.max_drawdown,
        "consensus_threshold" => config.consensus_threshold,
        "agent_count" => config.agent_count,
        "swarm_update_frequency" => config.swarm_update_frequency,
        "neural_networks_enabled" => config.enable_neural_networks,
        "groq_sentiment_enabled" => config.enable_groq_sentiment,
        "swarm_consensus_enabled" => config.enable_swarm_consensus,
        "api_credentials_configured" => !isempty(config.api_key) && !isempty(config.api_secret),
        "groq_configured" => !isempty(config.groq_api_key)
    )
end

"""
Strategy specification for AI Swarm wrapper
"""
const AI_SWARM_WRAPPER_STRATEGY = StrategySpecification(
    strategy_ai_swarm_wrapper,
    strategy_ai_swarm_wrapper_initialization,
    AISwarmWrapperConfig,
    StrategyMetadata("ai_swarm_wrapper"),
    AISwarmWrapperInput
)

println("🤖🐝 ✅ AI Swarm Wrapper Strategy loaded successfully!")
println("🌐 Ready for API-driven AI Swarm trading operations!")
println("📡 Supports: start, stop, emergency_stop, status, configure, performance, realtime_data")
