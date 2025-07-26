using ..CommonTypes: StrategyConfig, AgentContext, StrategyMetadata, StrategyInput, StrategySpecification
using JSON
using Dates

Base.@kwdef struct StrategySolanaDevChatConfig <: StrategyConfig
    name::String
    welcome_message::String = "Hello! I'm your Solana Development Assistant. I can help you with smart contracts, DeFi integrations, ecosystem tools, and code generation. What would you like to work on today?"
    max_context_length::Int = 10
end

Base.@kwdef struct SolanaDevChatInput <: StrategyInput
    message::String
    user_id::String = "default_user"
    chat_type::String = "general"  # general, code_gen, ecosystem, debug
end

# Context management for conversation history
const CONVERSATION_CONTEXTS = Dict{String, Vector{Dict{String,Any}}}()

function strategy_solana_dev_chat_initialization(
    cfg::StrategySolanaDevChatConfig,
    ctx::AgentContext
)
    push!(ctx.logs, "INFO: Solana Development Chat Agent initialized.")
    push!(ctx.logs, "INFO: Available capabilities: knowledge base, code generation, ecosystem guidance, debugging support.")
    
    # Initialize conversation context if needed
    if !haskey(CONVERSATION_CONTEXTS, cfg.name)
        CONVERSATION_CONTEXTS[cfg.name] = Vector{Dict{String,Any}}()
    end
    
    return ctx
end

function strategy_solana_dev_chat(
    cfg::StrategySolanaDevChatConfig,
    ctx::AgentContext,
    input::SolanaDevChatInput
)
    user_message = input.message
    user_id = input.user_id
    chat_type = input.chat_type
    
    push!(ctx.logs, "INFO: Processing Solana dev query from user $user_id: $(first(user_message, 50))...")
    
    # Add user message to context
    if !haskey(CONVERSATION_CONTEXTS, cfg.name)
        CONVERSATION_CONTEXTS[cfg.name] = Vector{Dict{String,Any}}()
    end
    
    conversation_context = CONVERSATION_CONTEXTS[cfg.name]
    push!(conversation_context, Dict("role" => "user", "content" => user_message, "timestamp" => string(now())))
    
    # Keep context manageable
    if length(conversation_context) > cfg.max_context_length * 2  # *2 for user+assistant pairs
        splice!(conversation_context, 1:2)  # Remove oldest pair
    end
    
    # Determine which tool to use based on message content
    tool_to_use = determine_appropriate_tool(user_message, chat_type)
    response = ""
    
    try
        if tool_to_use == "solana_knowledge"
            response = handle_knowledge_query(ctx, user_message, conversation_context)
        elseif tool_to_use == "solana_code_gen"
            response = handle_code_generation(ctx, user_message, conversation_context)
        elseif tool_to_use == "solana_ecosystem"
            response = handle_ecosystem_query(ctx, user_message, conversation_context)
        else
            # Default to knowledge base with enhanced context
            response = handle_general_query(ctx, user_message, conversation_context)
        end
        
        # Add assistant response to context
        push!(conversation_context, Dict("role" => "assistant", "content" => response, "timestamp" => string(now())))
        
        push!(ctx.logs, "INFO: Successfully generated response using $tool_to_use tool.")
        
    catch e
        push!(ctx.logs, "ERROR: Failed to process Solana dev query: $e")
        response = "I apologize, but I encountered an error processing your request. Could you please try rephrasing your question?"
    end
    
    return response
end

function determine_appropriate_tool(message::String, chat_type::String)
    message_lower = lowercase(message)
    
    # Explicit routing based on chat_type
    if chat_type == "code_gen"
        return "solana_code_gen"
    elseif chat_type == "ecosystem"
        return "solana_ecosystem"
    end
    
    # Smart routing based on content
    code_keywords = ["generate", "code", "implement", "program", "contract", "anchor", "rust", "function", "struct", "test"]
    ecosystem_keywords = ["jupiter", "raydium", "orca", "defi", "protocol", "integration", "api", "yield", "swap", "stake", "lending"]
    
    code_score = sum(occursin(keyword, message_lower) for keyword in code_keywords)
    ecosystem_score = sum(occursin(keyword, message_lower) for keyword in ecosystem_keywords)
    
    if code_score >= 2 || occursin("create", message_lower) && (occursin("program", message_lower) || occursin("contract", message_lower))
        return "solana_code_gen"
    elseif ecosystem_score >= 1
        return "solana_ecosystem"
    else
        return "solana_knowledge"
    end
end

function handle_knowledge_query(ctx::AgentContext, message::String, context::Vector{Dict{String,Any}})
    knowledge_tool = find_tool(ctx, "solana_knowledge")
    if isnothing(knowledge_tool)
        return "I'm sorry, but the Solana knowledge tool is not available right now."
    end
    
    # Enhanced prompt with conversation context
    enhanced_question = build_contextual_prompt(message, context, "knowledge")
    
    result = knowledge_tool.execute(knowledge_tool.config, Dict("question" => enhanced_question))
    
    if get(result, "success", false)
        return result["output"]
    else
        return "I encountered an error while accessing my knowledge base: $(get(result, "error", "unknown error"))"
    end
end

function handle_code_generation(ctx::AgentContext, message::String, context::Vector{Dict{String,Any}})
    codegen_tool = find_tool(ctx, "solana_code_gen")
    if isnothing(codegen_tool)
        return "I'm sorry, but the code generation tool is not available right now."
    end
    
    enhanced_request = build_contextual_prompt(message, context, "code_gen")
    
    result = codegen_tool.execute(codegen_tool.config, Dict("request" => enhanced_request))
    
    if get(result, "success", false)
        return result["output"]
    else
        return "I encountered an error while generating code: $(get(result, "error", "unknown error"))"
    end
end

function handle_ecosystem_query(ctx::AgentContext, message::String, context::Vector{Dict{String,Any}})
    ecosystem_tool = find_tool(ctx, "solana_ecosystem")
    if isnothing(ecosystem_tool)
        return "I'm sorry, but the ecosystem tool is not available right now."
    end
    
    enhanced_query = build_contextual_prompt(message, context, "ecosystem")
    
    result = ecosystem_tool.execute(ecosystem_tool.config, Dict("query" => enhanced_query))
    
    if get(result, "success", false)
        return result["output"]
    else
        return "I encountered an error while accessing ecosystem information: $(get(result, "error", "unknown error"))"
    end
end

function handle_general_query(ctx::AgentContext, message::String, context::Vector{Dict{String,Any}})
    # Default to knowledge base with conversation awareness
    return handle_knowledge_query(ctx, message, context)
end

function build_contextual_prompt(current_message::String, context::Vector{Dict{String,Any}}, query_type::String)
    if isempty(context)
        return current_message
    end
    
    # Get recent context (last 3 exchanges)
    recent_context = context[max(1, end-5):end]
    context_str = ""
    
    for entry in recent_context
        role = get(entry, "role", "unknown")
        content = get(entry, "content", "")
        if role == "user"
            context_str *= "Previous User: $content\n"
        elseif role == "assistant"
            context_str *= "Previous Assistant: $content\n"
        end
    end
    
    if !isempty(context_str)
        return "CONVERSATION CONTEXT:\n$context_str\nCURRENT QUESTION: $current_message"
    else
        return current_message
    end
end

function find_tool(ctx::AgentContext, tool_name::String)
    tool_index = findfirst(tool -> tool.metadata.name == tool_name, ctx.tools)
    return tool_index === nothing ? nothing : ctx.tools[tool_index]
end

const STRATEGY_SOLANA_DEV_CHAT_METADATA = StrategyMetadata(
    "solana_dev_chat"
)

const STRATEGY_SOLANA_DEV_CHAT_SPECIFICATION = StrategySpecification(
    strategy_solana_dev_chat,
    strategy_solana_dev_chat_initialization,
    StrategySolanaDevChatConfig,
    STRATEGY_SOLANA_DEV_CHAT_METADATA,
    SolanaDevChatInput
)
