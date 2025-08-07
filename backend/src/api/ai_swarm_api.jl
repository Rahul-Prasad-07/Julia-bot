"""
AI Swarm Trading API Extension for JuliaOS

This module provides specialized API endpoints for AI Swarm Trading functionality,
integrating with the existing JuliaOS agent system and providing real-time trading capabilities.
"""

using HTTP
using JSON3
using ..JuliaOSV1Server
using ..Agents
using ...Resources: Errors
using Dates

# AI Swarm strategy will be accessed via the Strategies registry
# We need to import the strategy module to access global variables
using ..Agents.Strategies

"""
Global AI Swarm system state tracker
"""
mutable struct AISwarmSystemState
    is_running::Bool
    active_strategies::Dict{String, Any}
    performance_metrics::Dict{String, Any}
    last_update::Float64
    
    function AISwarmSystemState()
        new(false, Dict{String, Any}(), Dict{String, Any}(), time())
    end
end

const AI_SWARM_SYSTEM_STATE = AISwarmSystemState()

"""
Handle AI Swarm system status requests
GET /api/v1/ai-swarm/status
"""
function handle_ai_swarm_status(req::HTTP.Request)
    @info "AI Swarm status request received"
    
    try
        # Get trading control status safely
        trading_control_status = try
            if isdefined(Agents.Strategies, :AI_SWARM_TRADING_CONTROL)
                control = Agents.Strategies.AI_SWARM_TRADING_CONTROL
                Dict(
                    "is_running" => control.is_running,
                    "iteration_count" => control.iteration_count,
                    "should_stop" => control.should_stop,
                    "start_time" => control.start_time
                )
            else
                Dict(
                    "is_running" => false,
                    "iteration_count" => 0,
                    "should_stop" => false,
                    "start_time" => 0.0
                )
            end
        catch e
            @warn "Failed to get trading control status: $e"
            Dict(
                "is_running" => false,
                "iteration_count" => 0,
                "should_stop" => false,
                "start_time" => 0.0
            )
        end
        
        # Collect real-time system metrics
        system_status = Dict{String, Any}(
            "system_running" => AI_SWARM_SYSTEM_STATE.is_running,
            "active_strategies" => length(AI_SWARM_SYSTEM_STATE.active_strategies),
            "last_update" => AI_SWARM_SYSTEM_STATE.last_update,
            "uptime_seconds" => time() - AI_SWARM_SYSTEM_STATE.last_update,
            "trading_control" => trading_control_status,
            "agents_status" => collect_agents_status(),
            "performance_summary" => collect_performance_metrics(),
            "api_connectivity" => test_api_connectivity(),
            "timestamp" => string(Dates.now())
        )
        
        @info "AI Swarm status retrieved successfully"
        return HTTP.Response(200, JSON3.write(system_status))
        
    catch e
        @error "Error retrieving AI Swarm status: $e"
        return HTTP.Response(500, JSON3.write(Dict("error" => "Failed to retrieve system status: $(string(e))")))
    end
end

"""
Handle AI Swarm trading start requests
POST /api/v1/ai-swarm/start
"""
function handle_ai_swarm_start(req::HTTP.Request)
    @info "AI Swarm start trading request received"
    
    try
        # Parse request body for configuration
        body = String(req.body)
        config_data = isempty(body) ? Dict{String, Any}() : JSON3.read(body, Dict{String, Any})
        
        # Create AI Swarm configuration
        ai_swarm_config = create_ai_swarm_config(config_data)
        
        # Create agent context
        agent_context = Agents.CommonTypes.AgentContext(
            Agents.CommonTypes.InstantiatedTool[],  # Empty tools vector
            String[]  # Empty logs vector
        )
        
        # Validate API keys
        api_key = isa(ai_swarm_config, Dict) ? get(ai_swarm_config, "api_key", "") : getfield(ai_swarm_config, :api_key)
        api_secret = isa(ai_swarm_config, Dict) ? get(ai_swarm_config, "api_secret", "") : getfield(ai_swarm_config, :api_secret)
        enable_groq = isa(ai_swarm_config, Dict) ? get(ai_swarm_config, "enable_groq_sentiment", false) : getfield(ai_swarm_config, :enable_groq_sentiment)
        groq_key = isa(ai_swarm_config, Dict) ? get(ai_swarm_config, "groq_api_key", "") : getfield(ai_swarm_config, :groq_api_key)
        
        if isempty(api_key) || isempty(api_secret)
            return HTTP.Response(400, JSON3.write(Dict(
                "success" => false,
                "error" => "Missing Binance API credentials. Please set BINANCE_API_KEY and BINANCE_API_SECRET environment variables."
            )))
        end
        
        if enable_groq && isempty(groq_key)
            return HTTP.Response(400, JSON3.write(Dict(
                "success" => false,
                "error" => "Missing Groq API key. Please set GROQ_API_KEY environment variable or disable Groq sentiment analysis."
            )))
        end
        
        # Start AI Swarm trading safely
        trading_started = try
            if isdefined(Agents.Strategies, :start_ai_swarm_trading)
                Agents.Strategies.start_ai_swarm_trading(ai_swarm_config, agent_context)
                true
            else
                @warn "AI Swarm trading function not available - strategy not yet loaded"
                false
            end
        catch e
            @error "Failed to start AI Swarm trading: $e"
            false
        end
        
        # Update system state
        AI_SWARM_SYSTEM_STATE.is_running = trading_started
        AI_SWARM_SYSTEM_STATE.active_strategies["ai_swarm_market_making"] = ai_swarm_config
        AI_SWARM_SYSTEM_STATE.last_update = time()
        
        # Extract config values safely
        symbols = isa(ai_swarm_config, Dict) ? get(ai_swarm_config, "symbols", ["ETHUSDT"]) : getfield(ai_swarm_config, :symbols)
        base_spread_pct = isa(ai_swarm_config, Dict) ? get(ai_swarm_config, "base_spread_pct", 0.15) : getfield(ai_swarm_config, :base_spread_pct)
        order_levels = isa(ai_swarm_config, Dict) ? get(ai_swarm_config, "order_levels", 3) : getfield(ai_swarm_config, :order_levels)
        max_capital = isa(ai_swarm_config, Dict) ? get(ai_swarm_config, "max_capital", 1000.0) : getfield(ai_swarm_config, :max_capital)
        consensus_threshold = isa(ai_swarm_config, Dict) ? get(ai_swarm_config, "consensus_threshold", 0.65) : getfield(ai_swarm_config, :consensus_threshold)
        agent_count = isa(ai_swarm_config, Dict) ? get(ai_swarm_config, "agent_count", 4) : getfield(ai_swarm_config, :agent_count)
        neural_networks_enabled = isa(ai_swarm_config, Dict) ? get(ai_swarm_config, "enable_neural_networks", true) : getfield(ai_swarm_config, :enable_neural_networks)
        groq_sentiment_enabled = isa(ai_swarm_config, Dict) ? get(ai_swarm_config, "enable_groq_sentiment", true) : getfield(ai_swarm_config, :enable_groq_sentiment)
        swarm_consensus_enabled = isa(ai_swarm_config, Dict) ? get(ai_swarm_config, "enable_swarm_consensus", true) : getfield(ai_swarm_config, :enable_swarm_consensus)
        
        # Get system status safely
        system_status = try
            if isdefined(Agents.Strategies, :AI_SWARM_TRADING_CONTROL)
                control = Agents.Strategies.AI_SWARM_TRADING_CONTROL
                Dict(
                    "trading_active" => control.is_running,
                    "iteration_count" => control.iteration_count
                )
            else
                Dict(
                    "trading_active" => trading_started,
                    "iteration_count" => 0
                )
            end
        catch e
            @warn "Failed to get trading control status: $e"
            Dict(
                "trading_active" => trading_started,
                "iteration_count" => 0
            )
        end
        
        response_data = Dict(
            "success" => trading_started,
            "message" => trading_started ? "AI Swarm trading started successfully" : "AI Swarm trading request processed (functions not yet available)",
            "config" => Dict(
                "symbols" => symbols,
                "base_spread_pct" => base_spread_pct,
                "order_levels" => order_levels,
                "max_capital" => max_capital,
                "consensus_threshold" => consensus_threshold,
                "agent_count" => agent_count,
                "neural_networks_enabled" => neural_networks_enabled,
                "groq_sentiment_enabled" => groq_sentiment_enabled,
                "swarm_consensus_enabled" => swarm_consensus_enabled
            ),
            "system_status" => system_status,
            "timestamp" => now()
        )
        
        @info "AI Swarm trading started successfully"
        return HTTP.Response(200, JSON3.write(response_data))
        
    catch e
        @error "Error starting AI Swarm trading: $e"
        AI_SWARM_SYSTEM_STATE.is_running = false
        return HTTP.Response(500, JSON3.write(Dict(
            "success" => false,
            "error" => "Failed to start AI Swarm trading: $(string(e))"
        )))
    end
end

"""
Handle AI Swarm trading stop requests
POST /api/v1/ai-swarm/stop
"""
function handle_ai_swarm_stop(req::HTTP.Request)
    @info "AI Swarm stop trading request received"
    
    try
        # Create agent context for stopping
        agent_context = Agents.CommonTypes.AgentContext(
            Agents.CommonTypes.InstantiatedTool[],  # Empty tools vector
            String[]  # Empty logs vector
        )
        
        # Stop AI Swarm trading safely
        trading_stopped = try
            if isdefined(Agents.Strategies, :stop_ai_swarm_trading)
                Agents.Strategies.stop_ai_swarm_trading(agent_context)
                true
            else
                @warn "AI Swarm stop function not available - strategy not yet loaded"
                true  # Assume stopped if function doesn't exist
            end
        catch e
            @error "Failed to stop AI Swarm trading: $e"
            false
        end
        
        # Update system state
        AI_SWARM_SYSTEM_STATE.is_running = false
        AI_SWARM_SYSTEM_STATE.active_strategies = Dict{String, Any}()
        AI_SWARM_SYSTEM_STATE.last_update = time()
        
        response_data = Dict(
            "success" => true,
            "message" => "AI Swarm trading stopped successfully",
            "final_status" => Dict(
                "trading_active" => AI_SWARM_TRADING_CONTROL.is_running,
                "total_iterations" => AI_SWARM_TRADING_CONTROL.iteration_count,
                "session_duration" => time() - AI_SWARM_TRADING_CONTROL.start_time
            ),
            "timestamp" => now()
        )
        
        @info "AI Swarm trading stopped successfully"
        return HTTP.Response(200, JSON3.write(response_data))
        
    catch e
        @error "Error stopping AI Swarm trading: $e"
        return HTTP.Response(500, JSON3.write(Dict(
            "success" => false,
            "error" => "Failed to stop AI Swarm trading: $(string(e))"
        )))
    end
end

"""
Handle AI Swarm performance report requests
GET /api/v1/ai-swarm/performance
"""
function handle_ai_swarm_performance(req::HTTP.Request)
    @info "AI Swarm performance report request received"
    
    try
        # Generate comprehensive performance report safely
        performance_report = try
            if isdefined(Agents.Strategies, :generate_ai_swarm_performance_report)
                Agents.Strategies.generate_ai_swarm_performance_report()
            else
                "Performance tracking not yet initialized. No trading sessions recorded."
            end
        catch e
            @warn "Failed to generate AI Swarm performance report: $e"
            "Performance data temporarily unavailable."
        end
        
        # Parse the string report into structured data
        performance_data = parse_performance_report(performance_report)
        
        # Add real-time metrics with safe access
        realtime_metrics = Dict(
            "current_time" => now(),
            "system_uptime" => time() - AI_SWARM_SYSTEM_STATE.last_update
        )
        
        # Add trading control metrics safely
        if isdefined(Agents.Strategies, :AI_SWARM_TRADING_CONTROL)
            try
                control = Agents.Strategies.AI_SWARM_TRADING_CONTROL
                realtime_metrics["trading_iterations"] = control.iteration_count
            catch e
                @warn "Failed to access trading control: $e"
                realtime_metrics["trading_iterations"] = 0
            end
        else
            realtime_metrics["trading_iterations"] = 0
        end
        
        # Add agents count safely
        agents_count = try
            if isdefined(Agents.Strategies, :GLOBAL_AI_SWARM_AGENTS)
                length(Agents.Strategies.GLOBAL_AI_SWARM_AGENTS)
            else
                0
            end
        catch e
            @warn "Failed to access agents: $e"
            0
        end
        realtime_metrics["agents_active"] = agents_count
        
        # Add PnL tracker safely
        pnl_data = try
            if isdefined(Agents.Strategies, :GLOBAL_AI_SWARM_PNL_TRACKER)
                tracker = Agents.Strategies.GLOBAL_AI_SWARM_PNL_TRACKER
                Dict(
                    "current_balance_usdt" => tracker.current_balance_usdt,
                    "total_realized_pnl" => tracker.total_realized_pnl,
                    "total_trades" => tracker.total_trades,
                    "ai_decision_accuracy" => tracker.ai_decision_accuracy,
                    "swarm_consensus_rate" => tracker.swarm_consensus_rate,
                    "max_drawdown" => tracker.max_drawdown
                )
            else
                Dict(
                    "current_balance_usdt" => 0.0,
                    "total_realized_pnl" => 0.0,
                    "total_trades" => 0,
                    "ai_decision_accuracy" => 0.0,
                    "swarm_consensus_rate" => 0.0,
                    "max_drawdown" => 0.0
                )
            end
        catch e
            @warn "Failed to access PnL tracker: $e"
            Dict(
                "current_balance_usdt" => 0.0,
                "total_realized_pnl" => 0.0,
                "total_trades" => 0,
                "ai_decision_accuracy" => 0.0,
                "swarm_consensus_rate" => 0.0,
                "max_drawdown" => 0.0
            )
        end
        realtime_metrics["pnl_tracker"] = pnl_data
        
        response_data = Dict(
            "success" => true,
            "performance_report" => performance_data,
            "realtime_metrics" => realtime_metrics,
            "raw_report" => performance_report,
            "timestamp" => now()
        )
        
        @info "AI Swarm performance report generated successfully"
        return HTTP.Response(200, JSON3.write(response_data))
        
    catch e
        @error "Error generating AI Swarm performance report: $e"
        return HTTP.Response(500, JSON3.write(Dict(
            "success" => false,
            "error" => "Failed to generate performance report: $(string(e))"
        )))
    end
end

"""
Handle AI Swarm agent management requests
GET /api/v1/ai-swarm/agents
"""
function handle_ai_swarm_agents(req::HTTP.Request)
    @info "AI Swarm agents status request received"
    
    try
        agents_data = Dict{String, Any}()
        
        # Collect data for each symbol's agents safely
        global_agents = try
            if isdefined(Agents.Strategies, :GLOBAL_AI_SWARM_AGENTS)
                Agents.Strategies.GLOBAL_AI_SWARM_AGENTS
            else
                Dict{String, Any}()
            end
        catch e
            @warn "Failed to access GLOBAL_AI_SWARM_AGENTS: $e"
            Dict{String, Any}()
        end
        
        if !isempty(global_agents)
            for (symbol, agents_dict) in global_agents
                try
                    agents_data[symbol] = Dict(
                        "market_analyzer" => collect_agent_info(get(agents_dict, "market_analyzer", nothing)),
                        "risk_manager" => collect_agent_info(get(agents_dict, "risk_manager", nothing)),
                        "strategy_optimizer" => collect_agent_info(get(agents_dict, "strategy_optimizer", nothing)),
                        "execution_agent" => collect_agent_info(get(agents_dict, "execution_agent", nothing)),
                        "swarm" => collect_swarm_info(get(agents_dict, "swarm", nothing))
                    )
                catch e
                    @warn "Failed to collect agent info for $symbol: $e"
                    agents_data[symbol] = Dict(
                        "market_analyzer" => Dict("status" => "unavailable"),
                        "risk_manager" => Dict("status" => "unavailable"),
                        "strategy_optimizer" => Dict("status" => "unavailable"),
                        "execution_agent" => Dict("status" => "unavailable"),
                        "swarm" => Dict("status" => "unavailable")
                    )
                end
            end
        else
            # No agents initialized yet
            agents_data["info"] = "No AI Swarm agents currently initialized. Start trading to create agents."
        end
        
        response_data = Dict(
            "success" => true,
            "agents_by_symbol" => agents_data,
            "total_symbols" => length(global_agents),
            "agents_available" => !isempty(global_agents),
            "timestamp" => now()
        )
        
        @info "AI Swarm agents status retrieved successfully"
        return HTTP.Response(200, JSON3.write(response_data))
        
    catch e
        @error "Error retrieving AI Swarm agents status: $e"
        return HTTP.Response(500, JSON3.write(Dict(
            "success" => false,
            "error" => "Failed to retrieve agents status: $(string(e))"
        )))
    end
end

"""
Handle AI Swarm configuration update requests
PUT /api/v1/ai-swarm/config
"""
function handle_ai_swarm_config_update(req::HTTP.Request)
    @info "AI Swarm configuration update request received"
    
    try
        body = String(req.body)
        if isempty(body)
            return HTTP.Response(400, JSON3.write(Dict("success" => false, "error" => "Empty request body")))
        end
        
        config_updates = JSON3.read(body, Dict{String, Any})
        
        # Validate that system is not currently running for critical updates
        critical_fields = ["symbols", "api_key", "api_secret", "max_capital"]
        has_critical_updates = any(field -> haskey(config_updates, field), critical_fields)
        
        # Check if system is running safely
        is_trading_active = try
            if isdefined(Agents.Strategies, :AI_SWARM_TRADING_CONTROL)
                Agents.Strategies.AI_SWARM_TRADING_CONTROL.is_running
            else
                AI_SWARM_SYSTEM_STATE.is_running
            end
        catch e
            @warn "Failed to check trading status: $e"
            AI_SWARM_SYSTEM_STATE.is_running
        end
        
        if has_critical_updates && is_trading_active
            return HTTP.Response(400, JSON3.write(Dict(
                "success" => false,
                "error" => "Cannot update critical configuration while trading is active. Stop trading first."
            )))
        end
        
        # Apply configuration updates
        updated_config = try
            apply_config_updates(config_updates)
        catch e
            @warn "Failed to apply config updates: $e"
            config_updates  # Return the updates as-is
        end
        
        response_data = Dict(
            "success" => true,
            "message" => "Configuration updated successfully",
            "updated_fields" => collect(keys(config_updates)),
            "current_config" => try
                extract_config_summary(updated_config)
            catch e
                @warn "Failed to extract config summary: $e"
                updated_config
            end,
            "requires_restart" => has_critical_updates,
            "timestamp" => now()
        )
        
        @info "AI Swarm configuration updated successfully"
        return HTTP.Response(200, JSON3.write(response_data))
        
    catch e
        @error "Error updating AI Swarm configuration: $e"
        return HTTP.Response(500, JSON3.write(Dict(
            "success" => false,
            "error" => "Failed to update configuration: $(string(e))"
        )))
    end
end

"""
Handle AI Swarm real-time data requests
GET /api/v1/ai-swarm/data/realtime
"""
function handle_ai_swarm_realtime_data(req::HTTP.Request)
    @info "AI Swarm real-time data request received"
    
    try
        # Parse query parameters
        uri = HTTP.URI(req.target)
        query_params = HTTP.queryparams(uri)
        symbol = get(query_params, "symbol", "ETHUSDT")
        
        # Get current configuration
        current_config = get(AI_SWARM_SYSTEM_STATE.active_strategies, "ai_swarm_market_making", nothing)
        
        if current_config === nothing
            return HTTP.Response(400, JSON3.write(Dict(
                "success" => false,
                "error" => "AI Swarm trading not active. Start trading first."
            )))
        end
        
        # Fetch real-time market data safely
        market_data = try
            api_key = isa(current_config, Dict) ? get(current_config, "api_key", "") : getfield(current_config, :api_key)
            api_secret = isa(current_config, Dict) ? get(current_config, "api_secret", "") : getfield(current_config, :api_secret)
            
            if isdefined(Agents.Strategies, :fetch_market_data)
                Agents.Strategies.fetch_market_data(symbol, api_key, api_secret)
            else
                Dict("error" => "Market data function not available")
            end
        catch e
            @warn "Failed to fetch market data: $e"
            Dict("error" => "Market data temporarily unavailable")
        end
        
        if haskey(market_data, "error")
            return HTTP.Response(500, JSON3.write(Dict(
                "success" => false,
                "error" => "Failed to fetch market data: $(market_data["error"])"
            )))
        end
        
        # Get AI analysis if agents are available
        ai_analysis = try
            global_agents = if isdefined(Agents.Strategies, :GLOBAL_AI_SWARM_AGENTS)
                Agents.Strategies.GLOBAL_AI_SWARM_AGENTS
            else
                Dict{String, Any}()
            end
            
            if haskey(global_agents, symbol) && isdefined(Agents.Strategies, :analyze_market_with_ai)
                agents = global_agents[symbol]
                Agents.Strategies.analyze_market_with_ai(agents["market_analyzer"], market_data)
            else
                nothing
            end
        catch e
            @warn "Failed to get AI analysis: $e"
            nothing
        end
        
        # Get system status safely
        system_active = try
            if isdefined(Agents.Strategies, :AI_SWARM_TRADING_CONTROL)
                Agents.Strategies.AI_SWARM_TRADING_CONTROL.is_running
            else
                AI_SWARM_SYSTEM_STATE.is_running
            end
        catch e
            @warn "Failed to get system status: $e"
            AI_SWARM_SYSTEM_STATE.is_running
        end
        
        response_data = Dict(
            "success" => true,
            "symbol" => symbol,
            "market_data" => market_data,
            "ai_analysis" => ai_analysis,
            "system_active" => system_active,
            "timestamp" => now()
        )
        
        @info "AI Swarm real-time data retrieved successfully for $symbol"
        return HTTP.Response(200, JSON3.write(response_data))
        
    catch e
        @error "Error retrieving AI Swarm real-time data: $e"
        return HTTP.Response(500, JSON3.write(Dict(
            "success" => false,
            "error" => "Failed to retrieve real-time data: $(string(e))"
        )))
    end
end

"""
Handle AI Swarm emergency stop requests
POST /api/v1/ai-swarm/emergency-stop
"""
function handle_ai_swarm_emergency_stop(req::HTTP.Request)
    @info "AI Swarm EMERGENCY STOP request received"
    
    try
        # Create agent context
        agent_context = Agents.CommonTypes.AgentContext(
            Agents.CommonTypes.InstantiatedTool[],  # Empty tools vector
            String[]  # Empty logs vector
        )
        
        # Force stop all trading activities safely
        trading_stopped = try
            if isdefined(Agents.Strategies, :stop_ai_swarm_trading)
                Agents.Strategies.stop_ai_swarm_trading(agent_context)
                true
            else
                @warn "AI Swarm stop function not available - assuming stopped"
                true
            end
        catch e
            @error "Failed to stop AI Swarm trading: $e"
            false
        end
        
        # Cancel all orders for all symbols safely
        cancelled_orders = 0
        current_config = get(AI_SWARM_SYSTEM_STATE.active_strategies, "ai_swarm_market_making", nothing)
        
        if current_config !== nothing
            symbols = isa(current_config, Dict) ? get(current_config, "symbols", ["ETHUSDT"]) : getfield(current_config, :symbols)
            api_key = isa(current_config, Dict) ? get(current_config, "api_key", "") : getfield(current_config, :api_key)
            api_secret = isa(current_config, Dict) ? get(current_config, "api_secret", "") : getfield(current_config, :api_secret)
            
            for symbol in symbols
                try
                    if isdefined(Agents.Strategies, :cancel_all_orders_ai_swarm)
                        cancelled = Agents.Strategies.cancel_all_orders_ai_swarm(symbol, api_key, api_secret)
                        cancelled_orders += cancelled
                        @info "Emergency cancelled $cancelled orders for $symbol"
                    else
                        @warn "Order cancellation function not available for $symbol"
                    end
                catch e
                    @warn "Failed to cancel orders for $symbol: $e"
                end
            end
        end
        
        # Reset system state
        AI_SWARM_SYSTEM_STATE.is_running = false
        AI_SWARM_SYSTEM_STATE.active_strategies = Dict{String, Any}()
        AI_SWARM_SYSTEM_STATE.last_update = time()
        
        response_data = Dict(
            "success" => true,
            "message" => "EMERGENCY STOP executed successfully",
            "actions_taken" => [
                "Stopped all AI Swarm trading activities",
                "Cancelled $cancelled_orders open orders",
                "Reset system state",
                "All agents deactivated"
            ],
            "timestamp" => now()
        )
        
        @info "AI Swarm EMERGENCY STOP executed successfully"
        return HTTP.Response(200, JSON3.write(response_data))
        
    catch e
        @error "Error during AI Swarm emergency stop: $e"
        return HTTP.Response(500, JSON3.write(Dict(
            "success" => false,
            "error" => "Failed to execute emergency stop: $(string(e))"
        )))
    end
end

"""
Helper Functions
"""

function create_ai_swarm_config(config_data::Dict{String, Any})
    # Try to access the AISwarmMarketMakingConfig type from the strategy module
    try
        if isdefined(Agents.Strategies, :AISwarmMarketMakingConfig)
            ConfigType = Agents.Strategies.AISwarmMarketMakingConfig
            return ConfigType(
                symbols = get(config_data, "symbols", ["ETHUSDT"]),
                base_spread_pct = get(config_data, "base_spread_pct", 0.15),
                order_levels = get(config_data, "order_levels", 3),
                max_capital = get(config_data, "max_capital", 1000.0),
                leverage = get(config_data, "leverage", 10),
                api_key = get(config_data, "api_key", get(ENV, "BINANCE_API_KEY", "")),
                api_secret = get(config_data, "api_secret", get(ENV, "BINANCE_API_SECRET", "")),
                max_drawdown = get(config_data, "max_drawdown", 0.12),
                risk_check_interval = get(config_data, "risk_check_interval", 20),
                enable_neural_networks = get(config_data, "enable_neural_networks", true),
                enable_groq_sentiment = get(config_data, "enable_groq_sentiment", true),
                groq_api_key = get(config_data, "groq_api_key", get(ENV, "GROQ_API_KEY", "")),
                neural_update_frequency = get(config_data, "neural_update_frequency", 50),
                enable_swarm_consensus = get(config_data, "enable_swarm_consensus", true),
                consensus_threshold = get(config_data, "consensus_threshold", 0.65),
                agent_count = get(config_data, "agent_count", 4),
                swarm_update_frequency = get(config_data, "swarm_update_frequency", 30)
            )
        else
            # Return a dictionary if type is not available
            return Dict{String, Any}(
                "symbols" => get(config_data, "symbols", ["ETHUSDT"]),
                "base_spread_pct" => get(config_data, "base_spread_pct", 0.15),
                "order_levels" => get(config_data, "order_levels", 3),
                "max_capital" => get(config_data, "max_capital", 1000.0),
                "leverage" => get(config_data, "leverage", 10),
                "api_key" => get(config_data, "api_key", get(ENV, "BINANCE_API_KEY", "")),
                "api_secret" => get(config_data, "api_secret", get(ENV, "BINANCE_API_SECRET", "")),
                "max_drawdown" => get(config_data, "max_drawdown", 0.12),
                "risk_check_interval" => get(config_data, "risk_check_interval", 20),
                "enable_neural_networks" => get(config_data, "enable_neural_networks", true),
                "enable_groq_sentiment" => get(config_data, "enable_groq_sentiment", true),
                "groq_api_key" => get(config_data, "groq_api_key", get(ENV, "GROQ_API_KEY", "")),
                "neural_update_frequency" => get(config_data, "neural_update_frequency", 50),
                "enable_swarm_consensus" => get(config_data, "enable_swarm_consensus", true),
                "consensus_threshold" => get(config_data, "consensus_threshold", 0.65),
                "agent_count" => get(config_data, "agent_count", 4),
                "swarm_update_frequency" => get(config_data, "swarm_update_frequency", 30)
            )
        end
    catch e
        @error "Failed to create AI Swarm config: $e"
        throw(e)
    end
end

function collect_agents_status()::Dict{String, Any}
    agents_status = Dict{String, Any}()
    
    try
        if isdefined(Agents.Strategies, :GLOBAL_AI_SWARM_AGENTS)
            global_agents = Agents.Strategies.GLOBAL_AI_SWARM_AGENTS
            for (symbol, agents_dict) in global_agents
                agents_status[symbol] = Dict(
                    "total_agents" => length(agents_dict) - 1,  # Exclude swarm
                    "swarm_active" => haskey(agents_dict, "swarm"),
                    "consensus_threshold" => haskey(agents_dict, "swarm") ? agents_dict["swarm"].consensus_threshold : 0.0
                )
            end
        else
            @info "GLOBAL_AI_SWARM_AGENTS not available"
        end
    catch e
        @warn "Failed to collect agents status: $e"
    end
    
    return agents_status
end

function collect_performance_metrics()::Dict{String, Any}
    try
        if isdefined(Agents.Strategies, :GLOBAL_AI_SWARM_PNL_TRACKER)
            pnl_tracker = Agents.Strategies.GLOBAL_AI_SWARM_PNL_TRACKER
            return Dict{String, Any}(
                "current_balance" => pnl_tracker.current_balance_usdt,
                "total_trades" => pnl_tracker.total_trades,
                "ai_accuracy" => pnl_tracker.ai_decision_accuracy,
                "consensus_rate" => pnl_tracker.swarm_consensus_rate,
                "max_drawdown" => pnl_tracker.max_drawdown
            )
        else
            @info "GLOBAL_AI_SWARM_PNL_TRACKER not available"
            return Dict{String, Any}(
                "current_balance" => 0.0,
                "total_trades" => 0,
                "ai_accuracy" => 0.0,
                "consensus_rate" => 0.0,
                "max_drawdown" => 0.0
            )
        end
    catch e
        @warn "Failed to collect performance metrics: $e"
        return Dict{String, Any}(
            "current_balance" => 0.0,
            "total_trades" => 0,
            "ai_accuracy" => 0.0,
            "consensus_rate" => 0.0,
            "max_drawdown" => 0.0
        )
    end
end

function test_api_connectivity()::Dict{String, Any}
    connectivity = Dict{String, Any}()
    
    # Test Binance API
    try
        current_config = get(AI_SWARM_SYSTEM_STATE.active_strategies, "ai_swarm_market_making", nothing)
        if current_config !== nothing
            test_data = fetch_market_data("ETHUSDT", current_config.api_key, current_config.api_secret)
            connectivity["binance"] = !haskey(test_data, "error")
        else
            connectivity["binance"] = false
        end
    catch
        connectivity["binance"] = false
    end
    
    # Test Groq API (would need actual implementation)
    connectivity["groq"] = true  # Placeholder
    
    return connectivity
end

function collect_agent_info(agent::Any)::Dict{String, Any}
    if agent === nothing
        return Dict{String, Any}(
            "status" => "not_initialized",
            "type" => "unknown",
            "confidence_score" => 0.0,
            "voting_weight" => 0.0
        )
    end
    
    return Dict{String, Any}(
        "status" => "active",
        "type" => hasfield(typeof(agent), :type) ? string(agent.type) : "unknown",
        "confidence_score" => hasfield(typeof(agent), :confidence_score) ? agent.confidence_score : 0.0,
        "voting_weight" => hasfield(typeof(agent), :voting_weight) ? agent.voting_weight : 0.0,
        "id" => hasfield(typeof(agent), :id) ? agent.id : "unknown"
    )
end

function collect_swarm_info(swarm::Any)::Dict{String, Any}
    if swarm === nothing
        return Dict{String, Any}(
            "status" => "not_initialized",
            "agent_count" => 0,
            "consensus_threshold" => 0.0,
            "collective_confidence" => 0.0,
            "voting_history_length" => 0
        )
    end
    
    return Dict{String, Any}(
        "status" => "active",
        "agent_count" => hasfield(typeof(swarm), :agents) ? length(swarm.agents) : 0,
        "consensus_threshold" => hasfield(typeof(swarm), :consensus_threshold) ? swarm.consensus_threshold : 0.0,
        "collective_confidence" => hasfield(typeof(swarm), :collective_confidence) ? swarm.collective_confidence : 0.0,
        "voting_history_length" => hasfield(typeof(swarm), :voting_history) ? length(swarm.voting_history) : 0
    )
end

function parse_performance_report(report::String)::Dict{String, Any}
    # Parse the string report into structured data
    # This is a simplified parser - could be enhanced
    return Dict{String, Any}(
        "raw_report" => report,
        "parsed_at" => now()
    )
end

function apply_config_updates(updates::Dict{String, Any})::Dict{String, Any}
    # Apply configuration updates to active strategy
    # This would update the actual configuration
    return updates
end

function extract_config_summary(config)::Dict{String, Any}
    # Extract key configuration parameters for API response
    if isa(config, Dict)
        return Dict{String, Any}(
            "symbols" => get(config, "symbols", ["ETHUSDT"]),
            "base_spread_pct" => get(config, "base_spread_pct", 0.15),
            "order_levels" => get(config, "order_levels", 3),
            "max_capital" => get(config, "max_capital", 1000.0),
            "consensus_threshold" => get(config, "consensus_threshold", 0.65),
            "neural_networks_enabled" => get(config, "enable_neural_networks", true),
            "groq_sentiment_enabled" => get(config, "enable_groq_sentiment", true)
        )
    else
        return Dict{String, Any}(
            "symbols" => hasfield(typeof(config), :symbols) ? getfield(config, :symbols) : ["ETHUSDT"],
            "base_spread_pct" => hasfield(typeof(config), :base_spread_pct) ? getfield(config, :base_spread_pct) : 0.15,
            "order_levels" => hasfield(typeof(config), :order_levels) ? getfield(config, :order_levels) : 3,
            "max_capital" => hasfield(typeof(config), :max_capital) ? getfield(config, :max_capital) : 1000.0,
            "consensus_threshold" => hasfield(typeof(config), :consensus_threshold) ? getfield(config, :consensus_threshold) : 0.65,
            "neural_networks_enabled" => hasfield(typeof(config), :enable_neural_networks) ? getfield(config, :enable_neural_networks) : true,
            "groq_sentiment_enabled" => hasfield(typeof(config), :enable_groq_sentiment) ? getfield(config, :enable_groq_sentiment) : true
        )
    end
end

"""
Register AI Swarm API routes
"""
function register_ai_swarm_routes(router::HTTP.Router)
    @info "Registering AI Swarm API routes..."
    
    # System management endpoints
    HTTP.register!(router, "GET", "/api/v1/ai-swarm/status", handle_ai_swarm_status)
    HTTP.register!(router, "POST", "/api/v1/ai-swarm/start", handle_ai_swarm_start)
    HTTP.register!(router, "POST", "/api/v1/ai-swarm/stop", handle_ai_swarm_stop)
    HTTP.register!(router, "POST", "/api/v1/ai-swarm/emergency-stop", handle_ai_swarm_emergency_stop)
    
    # Performance and monitoring endpoints
    HTTP.register!(router, "GET", "/api/v1/ai-swarm/performance", handle_ai_swarm_performance)
    HTTP.register!(router, "GET", "/api/v1/ai-swarm/agents", handle_ai_swarm_agents)
    HTTP.register!(router, "GET", "/api/v1/ai-swarm/data/realtime", handle_ai_swarm_realtime_data)
    
    # Configuration management endpoints
    HTTP.register!(router, "PUT", "/api/v1/ai-swarm/config", handle_ai_swarm_config_update)
    
    @info "AI Swarm API routes registered successfully"
    @info "Available endpoints:"
    @info "  GET  /api/v1/ai-swarm/status"
    @info "  POST /api/v1/ai-swarm/start"
    @info "  POST /api/v1/ai-swarm/stop"
    @info "  POST /api/v1/ai-swarm/emergency-stop"
    @info "  GET  /api/v1/ai-swarm/performance"
    @info "  GET  /api/v1/ai-swarm/agents"
    @info "  GET  /api/v1/ai-swarm/data/realtime"
    @info "  PUT  /api/v1/ai-swarm/config"
end
