"""
YieldSwarm API Extension for JuliaOS

This module provides specialized API endpoints for YieldSwarm functionality,
integrating with the existing JuliaOS agent system.
"""

using HTTP
using JSON3
using ..JuliaOSV1Server
using ..Agents
using ...Resources: Errors

"""
Handle YieldSwarm analysis requests
"""
function handle_yieldswarm_analyze(req::HTTP.Request)
    @info "YieldSwarm analysis request received"
    
    try
        # Parse request body
        body = String(req.body)
        if isempty(body)
            return HTTP.Response(400, JSON3.write(Dict("success" => false, "error" => "Empty request body")))
        end
        
        request_data = JSON3.read(body, Dict{String, Any})
        
        # Validate required fields
        if !haskey(request_data, "query")
            return HTTP.Response(400, JSON3.write(Dict("success" => false, "error" => "Missing 'query' field")))
        end
        
        query = request_data["query"]
        agent_type = get(request_data, "agent_type", "coordinator")
        portfolio_data = get(request_data, "portfolio_data", Dict{String, Any}())
        risk_preferences = get(request_data, "risk_preferences", Dict{String, Any}())
        execution_mode = get(request_data, "execution_mode", "analyze")
        
        @info "Processing YieldSwarm request: agent_type=$agent_type, execution_mode=$execution_mode"
        
        # Create or get YieldSwarm agent
        agent_id = "yieldswarm_$(agent_type)_agent"
        agent = get_or_create_yieldswarm_agent(agent_id, agent_type)
        
        if agent === nothing
            return HTTP.Response(500, JSON3.write(Dict("success" => false, "error" => "Failed to create YieldSwarm agent")))
        end
        
        # Prepare strategy input
        strategy_input = Agents.CommonTypes.StrategyInput(
            "yieldswarm",
            Dict{String, Any}(
                "user_query" => query,
                "portfolio_data" => portfolio_data,
                "market_context" => Dict{String, Any}(),
                "risk_preferences" => risk_preferences,
                "execution_mode" => execution_mode,
                "coordination_required" => agent_type == "coordinator"
            )
        )
        
        # Process the request
        result = Agents.process_strategy_input(agent, strategy_input)
        
        if result["success"]
            response_data = Dict(
                "success" => true,
                "message" => result["message"],
                "agent_type" => agent_type,
                "execution_mode" => execution_mode,
                "metadata" => get(result, "metadata", Dict())
            )
            
            @info "YieldSwarm analysis completed successfully"
            return HTTP.Response(200, JSON3.write(response_data))
        else
            @error "YieldSwarm analysis failed: $(result["error"])"
            return HTTP.Response(500, JSON3.write(Dict("success" => false, "error" => result["error"])))
        end
        
    catch e
        @error "Error processing YieldSwarm request: $e"
        return HTTP.Response(500, JSON3.write(Dict("success" => false, "error" => "Internal server error: $(string(e))")))
    end
end

"""
Handle YieldSwarm execution requests
"""
function handle_yieldswarm_execute(req::HTTP.Request)
    @info "YieldSwarm execution request received"
    
    try
        body = String(req.body)
        if isempty(body)
            return HTTP.Response(400, JSON3.write(Dict("success" => false, "error" => "Empty request body")))
        end
        
        request_data = JSON3.read(body, Dict{String, Any})
        
        # Validate required fields
        if !haskey(request_data, "execution_plan")
            return HTTP.Response(400, JSON3.write(Dict("success" => false, "error" => "Missing 'execution_plan' field")))
        end
        
        execution_plan = request_data["execution_plan"]
        execution_type = get(request_data, "execution_type", "simulate")
        safety_checks = get(request_data, "safety_checks", true)
        
        @info "Processing YieldSwarm execution: type=$execution_type, safety_checks=$safety_checks"
        
        # Create or get executor agent
        agent_id = "yieldswarm_executor_agent"
        agent = get_or_create_yieldswarm_agent(agent_id, "executor")
        
        if agent === nothing
            return HTTP.Response(500, JSON3.write(Dict("success" => false, "error" => "Failed to create YieldSwarm executor agent")))
        end
        
        # Prepare execution input
        strategy_input = Agents.CommonTypes.StrategyInput(
            "yieldswarm",
            Dict{String, Any}(
                "user_query" => "Execute: $execution_plan",
                "portfolio_data" => get(request_data, "portfolio_data", Dict{String, Any}()),
                "execution_mode" => execution_type,
                "execution_plan" => execution_plan,
                "safety_checks" => safety_checks,
                "coordination_required" => false
            )
        )
        
        # Process the execution request
        result = Agents.process_strategy_input(agent, strategy_input)
        
        if result["success"]
            response_data = Dict(
                "success" => true,
                "message" => result["message"],
                "execution_type" => execution_type,
                "execution_metadata" => get(result, "execution_metadata", Dict())
            )
            
            @info "YieldSwarm execution completed successfully"
            return HTTP.Response(200, JSON3.write(response_data))
        else
            @error "YieldSwarm execution failed: $(result["error"])"
            return HTTP.Response(500, JSON3.write(Dict("success" => false, "error" => result["error"])))
        end
        
    catch e
        @error "Error processing YieldSwarm execution: $e"
        return HTTP.Response(500, JSON3.write(Dict("success" => false, "error" => "Internal server error: $(string(e))")))
    end
end

"""
Handle YieldSwarm risk assessment requests
"""
function handle_yieldswarm_risk(req::HTTP.Request)
    @info "YieldSwarm risk assessment request received"
    
    try
        body = String(req.body)
        if isempty(body)
            return HTTP.Response(400, JSON3.write(Dict("success" => false, "error" => "Empty request body")))
        end
        
        request_data = JSON3.read(body, Dict{String, Any})
        
        # Validate required fields
        if !haskey(request_data, "risk_action")
            return HTTP.Response(400, JSON3.write(Dict("success" => false, "error" => "Missing 'risk_action' field")))
        end
        
        risk_action = request_data["risk_action"]
        portfolio_data = get(request_data, "portfolio_data", Dict{String, Any}())
        market_conditions = get(request_data, "market_conditions", Dict{String, Any}())
        
        @info "Processing YieldSwarm risk assessment: action=$risk_action"
        
        # Create or get risk manager agent
        agent_id = "yieldswarm_risk_manager_agent"
        agent = get_or_create_yieldswarm_agent(agent_id, "risk_manager")
        
        if agent === nothing
            return HTTP.Response(500, JSON3.write(Dict("success" => false, "error" => "Failed to create YieldSwarm risk manager agent")))
        end
        
        # Prepare risk assessment input
        strategy_input = Agents.CommonTypes.StrategyInput(
            "yieldswarm",
            Dict{String, Any}(
                "user_query" => "Risk Assessment: $risk_action",
                "portfolio_data" => portfolio_data,
                "market_context" => market_conditions,
                "risk_action" => risk_action,
                "execution_mode" => "analyze",
                "coordination_required" => false
            )
        )
        
        # Process the risk assessment request
        result = Agents.process_strategy_input(agent, strategy_input)
        
        if result["success"]
            response_data = Dict(
                "success" => true,
                "message" => result["message"],
                "risk_action" => risk_action,
                "risk_metadata" => get(result, "risk_metadata", Dict())
            )
            
            @info "YieldSwarm risk assessment completed successfully"
            return HTTP.Response(200, JSON3.write(response_data))
        else
            @error "YieldSwarm risk assessment failed: $(result["error"])"
            return HTTP.Response(500, JSON3.write(Dict("success" => false, "error" => result["error"])))
        end
        
    catch e
        @error "Error processing YieldSwarm risk assessment: $e"
        return HTTP.Response(500, JSON3.write(Dict("success" => false, "error" => "Internal server error: $(string(e))")))
    end
end

"""
Get or create a YieldSwarm agent with the specified role
"""
function get_or_create_yieldswarm_agent(agent_id::String, agent_role::String)
    try
        # Check if agent already exists
        existing_agent = Agents.get_agent(agent_id)
        if existing_agent !== nothing
            @info "Using existing YieldSwarm agent: $agent_id"
            return existing_agent
        end
        
        @info "Creating new YieldSwarm agent: $agent_id with role: $agent_role"
        
        # Create agent blueprint
        tools = [
            Agents.ToolBlueprint("yieldswarm_analyzer", Dict{String, Any}()),
            Agents.ToolBlueprint("yieldswarm_executor", Dict{String, Any}()),
            Agents.ToolBlueprint("yieldswarm_risk_manager", Dict{String, Any}())
        ]
        
        strategy_config = Dict{String, Any}(
            "name" => "YieldSwarm $(uppercasefirst(agent_role))",
            "agent_role" => agent_role,
            "swarm_id" => "yieldswarm_main",
            "coordination_endpoint" => "http://127.0.0.1:8052/api/v1",
            "default_risk_tolerance" => "medium",
            "supported_chains" => ["ethereum", "solana", "polygon", "avalanche"]
        )
        
        strategy = Agents.StrategyBlueprint("yieldswarm", strategy_config)
        
        # Use webhook trigger for API-driven agents
        trigger = Agents.CommonTypes.TriggerConfig(
            Agents.Triggers.WebhookTrigger, 
            Dict{String, Any}()
        )
        
        blueprint = Agents.AgentBlueprint(tools, strategy, trigger)
        
        # Create the agent
        agent_name = "YieldSwarm $(uppercasefirst(agent_role)) Agent"
        agent_description = "Advanced DeFi yield optimization agent specialized in $(agent_role) operations"
        
        agent = Agents.create_agent(agent_id, agent_name, agent_description, blueprint)
        
        # Store in database
        # JuliaDB.insert_agent(agent)  # Uncomment if database storage is needed
        
        # Initialize the agent
        Agents.initialize(agent)
        
        @info "YieldSwarm agent created successfully: $agent_id"
        return agent
        
    catch e
        @error "Failed to create YieldSwarm agent $agent_id: $e"
        return nothing
    end
end

"""
Register YieldSwarm API routes with the server
"""
function register_yieldswarm_routes(router)
    @info "Registering YieldSwarm API routes"
    
    # YieldSwarm analysis endpoint
    HTTP.register!(router, "POST", "/api/v1/yieldswarm/analyze", handle_yieldswarm_analyze)
    
    # YieldSwarm execution endpoint
    HTTP.register!(router, "POST", "/api/v1/yieldswarm/execute", handle_yieldswarm_execute)
    
    # YieldSwarm risk assessment endpoint
    HTTP.register!(router, "POST", "/api/v1/yieldswarm/risk", handle_yieldswarm_risk)
    
    @info "YieldSwarm API routes registered successfully"
end

export register_yieldswarm_routes
