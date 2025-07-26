using ..CommonTypes: StrategyConfig, AgentContext, StrategyMetadata, StrategyInput, StrategySpecification
using JSON
using HTTP

Base.@kwdef struct StrategySolanaSwarmDevConfig <: StrategyConfig
    name::String
    swarm_id::String = ""
    agent_role::String = "coordinator"  # coordinator, code_specialist, ecosystem_expert, security_auditor
    coordination_endpoint::String = "http://127.0.0.1:8052/api/v1"
    max_iterations::Int = 5
end

Base.@kwdef struct SolanaSwarmDevInput <: StrategyInput
    task::String
    project_context::Dict{String,Any} = Dict{String,Any}()
    priority::String = "normal"  # low, normal, high, critical
    requires_coordination::Bool = true
end

function strategy_solana_swarm_dev_initialization(
    cfg::StrategySolanaSwarmDevConfig,
    ctx::AgentContext
)
    push!(ctx.logs, "INFO: Solana Swarm Development Agent initialized with role: $(cfg.agent_role)")
    
    # Initialize swarm connection if swarm_id is provided
    if !isempty(cfg.swarm_id)
        push!(ctx.logs, "INFO: Connecting to swarm $(cfg.swarm_id)")
        try
            # Register this agent with the swarm
            register_with_swarm(cfg, ctx)
        catch e
            push!(ctx.logs, "WARN: Failed to register with swarm: $e")
        end
    end
    
    return ctx
end

function strategy_solana_swarm_dev(
    cfg::StrategySolanaSwarmDevConfig,
    ctx::AgentContext,
    input::SolanaSwarmDevInput
)
    task = input.task
    project_context = input.project_context
    priority = input.priority
    
    push!(ctx.logs, "INFO: Processing Solana development task ($(cfg.agent_role)): $(first(task, 100))...")
    
    # Route task based on agent role and coordination requirements
    if cfg.agent_role == "coordinator" && input.requires_coordination
        return handle_coordination_task(cfg, ctx, input)
    elseif cfg.agent_role == "code_specialist"
        return handle_code_specialization(cfg, ctx, input)
    elseif cfg.agent_role == "ecosystem_expert"
        return handle_ecosystem_specialization(cfg, ctx, input)
    elseif cfg.agent_role == "security_auditor"
        return handle_security_audit(cfg, ctx, input)
    else
        # Default single-agent processing
        return handle_single_agent_task(cfg, ctx, input)
    end
end

function handle_coordination_task(cfg::StrategySolanaSwarmDevConfig, ctx::AgentContext, input::SolanaSwarmDevInput)
    push!(ctx.logs, "INFO: Coordinating multi-agent Solana development task")
    
    # Break down the task into specialized components
    task_breakdown = analyze_and_decompose_task(input.task, input.project_context)
    
    results = Dict{String,Any}()
    
    # Coordinate with specialized agents
    for (component, details) in task_breakdown
        try
            if component == "smart_contract"
                result = coordinate_with_code_specialist(cfg, ctx, details, input.project_context)
                results[component] = result
            elseif component == "defi_integration"
                result = coordinate_with_ecosystem_expert(cfg, ctx, details, input.project_context)
                results[component] = result
            elseif component == "security_review"
                result = coordinate_with_security_auditor(cfg, ctx, details, input.project_context)
                results[component] = result
            end
        catch e
            push!(ctx.logs, "ERROR: Failed to coordinate $component: $e")
            results[component] = Dict("error" => string(e))
        end
    end
    
    # Synthesize final response
    return synthesize_coordination_results(ctx, results, input.task)
end

function handle_code_specialization(cfg::StrategySolanaSwarmDevConfig, ctx::AgentContext, input::SolanaSwarmDevInput)
    push!(ctx.logs, "INFO: Handling code specialization task")
    
    # Try Groq-enabled multi-model tool first, fallback to code gen tool
    codegen_tool = find_tool(ctx, "solana_knowledge_multi_model")
    if isnothing(codegen_tool)
        codegen_tool = find_tool(ctx, "solana_code_gen")
        if isnothing(codegen_tool)
            return "Code generation tool not available."
        end
    end
    
    enhanced_request = """
    SPECIALIZED CODE GENERATION REQUEST:
    Task: $(input.task)
    
    Project Context: $(JSON.json(input.project_context))
    
    Priority: $(input.priority)
    
    Focus on:
    - Production-ready code with comprehensive error handling
    - Optimized compute unit usage
    - Security best practices
    - Clear documentation and comments
    - Integration patterns with other components
    """
    
    # Use appropriate parameter name based on tool type
    request_param = if occursin("multi_model", codegen_tool.metadata.name)
        Dict("question" => enhanced_request)
    else
        Dict("request" => enhanced_request)
    end
    
    result = codegen_tool.execute(codegen_tool.config, request_param)
    
    if get(result, "success", false)
        push!(ctx.logs, "INFO: Code specialization completed successfully")
        return result["output"]
    else
        push!(ctx.logs, "ERROR: Code specialization failed: $(get(result, "error", "unknown"))")
        return "Code generation failed: $(get(result, "error", "unknown error"))"
    end
end

function handle_ecosystem_specialization(cfg::StrategySolanaSwarmDevConfig, ctx::AgentContext, input::SolanaSwarmDevInput)
    push!(ctx.logs, "INFO: Handling ecosystem specialization task")
    
    # Try Groq-enabled multi-model tool first, fallback to ecosystem tool
    ecosystem_tool = find_tool(ctx, "solana_knowledge_multi_model")
    if isnothing(ecosystem_tool)
        ecosystem_tool = find_tool(ctx, "solana_ecosystem")
        if isnothing(ecosystem_tool)
            return "Ecosystem analysis tool not available."
        end
    end
    
    enhanced_query = """
    ECOSYSTEM INTEGRATION REQUEST:
    Task: $(input.task)
    
    Project Context: $(JSON.json(input.project_context))
    
    Focus on:
    - Protocol integration patterns
    - API usage and best practices
    - Yield optimization strategies
    - Cross-protocol interactions
    - Risk assessment and mitigation
    - Integration testing approaches
    """
    
    # Use appropriate parameter name based on tool type
    query_param = if occursin("multi_model", ecosystem_tool.metadata.name)
        Dict("question" => enhanced_query)
    else
        Dict("query" => enhanced_query)
    end
    
    result = ecosystem_tool.execute(ecosystem_tool.config, query_param)
    
    if get(result, "success", false)
        push!(ctx.logs, "INFO: Ecosystem specialization completed successfully")
        return result["output"]
    else
        push!(ctx.logs, "ERROR: Ecosystem specialization failed: $(get(result, "error", "unknown"))")
        return "Ecosystem analysis failed: $(get(result, "error", "unknown error"))"
    end
end

function handle_security_audit(cfg::StrategySolanaSwarmDevConfig, ctx::AgentContext, input::SolanaSwarmDevInput)
    push!(ctx.logs, "INFO: Handling security audit task")
    
    # Try Groq-enabled multi-model tool first, fallback to knowledge tool
    knowledge_tool = find_tool(ctx, "solana_knowledge_multi_model")
    if isnothing(knowledge_tool)
        knowledge_tool = find_tool(ctx, "solana_knowledge")
        if isnothing(knowledge_tool)
            return "Security analysis tool not available."
        end
    end
    
    security_prompt = """
    SECURITY AUDIT REQUEST:
    Task: $(input.task)
    
    Project Context: $(JSON.json(input.project_context))
    
    Please provide a comprehensive security analysis focusing on:
    
    1. COMMON SOLANA VULNERABILITIES:
       - Account validation issues
       - PDA seed manipulation
       - Arithmetic overflow/underflow
       - Reentrancy attacks
       - Signer verification bypasses
       - Cross-program invocation risks
    
    2. SPECIFIC AUDIT AREAS:
       - Account ownership validation
       - Permission and access controls
       - State transition logic
       - External call safety
       - Economic attacks and MEV risks
    
    3. TESTING RECOMMENDATIONS:
       - Unit test coverage for edge cases
       - Integration test scenarios
       - Fuzzing strategies
       - Formal verification approaches
    
    4. DEPLOYMENT SECURITY:
       - Upgrade authority management
       - Key management practices
       - Monitoring and alerting
       - Incident response procedures
    
    Provide specific code examples of vulnerabilities and their fixes where applicable.
    """
    
    result = knowledge_tool.execute(knowledge_tool.config, Dict("question" => security_prompt))
    
    if get(result, "success", false)
        push!(ctx.logs, "INFO: Security audit completed successfully")
        return result["output"]
    else
        push!(ctx.logs, "ERROR: Security audit failed: $(get(result, "error", "unknown"))")
        return "Security audit failed: $(get(result, "error", "unknown error"))"
    end
end

function handle_single_agent_task(cfg::StrategySolanaSwarmDevConfig, ctx::AgentContext, input::SolanaSwarmDevInput)
    push!(ctx.logs, "INFO: Handling single-agent Solana development task")
    
    # Determine the most appropriate tool based on task content
    task_lower = lowercase(input.task)
    
    if occursin("audit", task_lower) || occursin("security", task_lower)
        return handle_security_audit(cfg, ctx, input)
    elseif occursin("code", task_lower) || occursin("implement", task_lower) || occursin("program", task_lower)
        return handle_code_specialization(cfg, ctx, input)
    elseif occursin("protocol", task_lower) || occursin("defi", task_lower) || occursin("integration", task_lower)
        return handle_ecosystem_specialization(cfg, ctx, input)
    else
        # Default to general knowledge with Groq-enabled tool
        knowledge_tool = find_tool(ctx, "solana_knowledge_multi_model")
        if isnothing(knowledge_tool)
            knowledge_tool = find_tool(ctx, "solana_knowledge")
        end
        
        if !isnothing(knowledge_tool)
            result = knowledge_tool.execute(knowledge_tool.config, Dict("question" => input.task))
            if get(result, "success", false)
                return result["output"]
            end
        end
        return "I can help with Solana development. Please specify if you need help with code generation, ecosystem integration, or security analysis."
    end
end

function analyze_and_decompose_task(task::String, context::Dict{String,Any})
    # Simple task decomposition logic
    components = Dict{String,String}()
    task_lower = lowercase(task)
    
    if occursin("smart contract", task_lower) || occursin("program", task_lower) || occursin("anchor", task_lower)
        components["smart_contract"] = "Develop smart contract components: $task"
    end
    
    if occursin("defi", task_lower) || occursin("protocol", task_lower) || occursin("integration", task_lower)
        components["defi_integration"] = "Handle DeFi protocol integration: $task"
    end
    
    if occursin("security", task_lower) || occursin("audit", task_lower) || contains(task_lower, "secure")
        components["security_review"] = "Conduct security review: $task"
    end
    
    # If no specific components identified, treat as general development
    if isempty(components)
        components["general_development"] = task
    end
    
    return components
end

function coordinate_with_code_specialist(cfg::StrategySolanaSwarmDevConfig, ctx::AgentContext, details::String, context::Dict{String,Any})
    # In a real implementation, this would make HTTP calls to other agents in the swarm
    push!(ctx.logs, "INFO: Coordinating with code specialist for: $details")
    
    # For now, use local tools as a fallback
    return handle_code_specialization(cfg, ctx, SolanaSwarmDevInput(task=details, project_context=context))
end

function coordinate_with_ecosystem_expert(cfg::StrategySolanaSwarmDevConfig, ctx::AgentContext, details::String, context::Dict{String,Any})
    push!(ctx.logs, "INFO: Coordinating with ecosystem expert for: $details")
    return handle_ecosystem_specialization(cfg, ctx, SolanaSwarmDevInput(task=details, project_context=context))
end

function coordinate_with_security_auditor(cfg::StrategySolanaSwarmDevConfig, ctx::AgentContext, details::String, context::Dict{String,Any})
    push!(ctx.logs, "INFO: Coordinating with security auditor for: $details")
    return handle_security_audit(cfg, ctx, SolanaSwarmDevInput(task=details, project_context=context))
end

function synthesize_coordination_results(ctx::AgentContext, results::Dict{String,Any}, original_task::String)
    push!(ctx.logs, "INFO: Synthesizing coordination results")
    
    synthesis = """
    # Comprehensive Solana Development Response
    
    **Original Task:** $original_task
    
    ## Component Analysis Results:
    """
    
    for (component, result) in results
        synthesis *= "\n\n### $(titlecase(replace(component, "_" => " ")))\n"
        if isa(result, Dict) && haskey(result, "error")
            synthesis *= "⚠️ **Error:** $(result["error"])\n"
        else
            synthesis *= "$result\n"
        end
    end
    
    synthesis *= """
    
    ## Integration Recommendations:
    
    1. **Development Workflow:** Implement components in the order: security review → smart contracts → DeFi integrations
    2. **Testing Strategy:** Use comprehensive unit tests for each component before integration
    3. **Deployment Plan:** Deploy to devnet first, then mainnet with proper monitoring
    4. **Monitoring:** Set up alerts for key metrics and potential issues
    
    ## Next Steps:
    
    - Review each component's implementation details
    - Set up development environment and dependencies
    - Begin with security-first development approach
    - Test integrations thoroughly before deployment
    """
    
    return synthesis
end

function register_with_swarm(cfg::StrategySolanaSwarmDevConfig, ctx::AgentContext)
    # Register this agent with the specified swarm
    if !isempty(cfg.swarm_id)
        push!(ctx.logs, "INFO: Registering with swarm $(cfg.swarm_id)")
        # In a real implementation, this would make API calls to register with the swarm
        # For now, just log the registration
    end
end

# function find_tool(ctx::AgentContext, tool_name::String)
#     tool_index = findfirst(tool -> tool.metadata.name == tool_name, ctx.tools)
#     return tool_index === nothing ? nothing : ctx.tools[tool_index]
# end

const STRATEGY_SOLANA_SWARM_DEV_METADATA = StrategyMetadata(
    "solana_swarm_dev"
)

const STRATEGY_SOLANA_SWARM_DEV_SPECIFICATION = StrategySpecification(
    strategy_solana_swarm_dev,
    strategy_solana_swarm_dev_initialization,
    StrategySolanaSwarmDevConfig,
    STRATEGY_SOLANA_SWARM_DEV_METADATA,
    SolanaSwarmDevInput
)
