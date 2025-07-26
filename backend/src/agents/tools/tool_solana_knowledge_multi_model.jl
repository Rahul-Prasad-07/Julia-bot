using ...Resources: Gemini, Groq
using ..CommonTypes: ToolSpecification, ToolMetadata, ToolConfig
using HTTP
using JSON

Base.@kwdef struct ToolSolanaKnowledgeMultiModelConfig <: ToolConfig
    # Primary AI provider
    ai_provider::String = "groq"  # "gemini" or "groq"
    
    # Gemini configuration
    gemini_api_key::String = get(ENV, "GEMINI_API_KEY", "")
    gemini_model::String = "models/gemini-1.5-pro"
    
    # Groq configuration  
    groq_api_key::String = get(ENV, "GROQ_API_KEY", "")
    groq_model::String = get(ENV, "GROQ_MODEL", "llama-3.1-70b-versatile")
    groq_base_url::String = get(ENV, "GROQ_BASE_URL", "https://api.groq.com/openai/v1")
    
    # Shared parameters
    temperature::Float64 = 0.3
    max_output_tokens::Int = 2048
    
    # Fallback configuration
    enable_fallback::Bool = true  # Fallback to other provider if primary fails
end

function tool_solana_knowledge_multi_model(cfg::ToolSolanaKnowledgeMultiModelConfig, task::Dict)
    if !haskey(task, "question") || !(task["question"] isa AbstractString)
        return Dict("success" => false, "error" => "Missing or invalid 'question' field")
    end

    # Enhanced Solana context (same as before but optimized for both models)
    solana_context = """
    You are a Solana blockchain development expert. Provide accurate, up-to-date information about:
    
    CORE CONCEPTS:
    - Accounts, Programs, Instructions, Transactions
    - Program Derived Addresses (PDAs) and seed derivation
    - Cross-program invocations (CPIs) and security
    - Rent, lamports, and account lifecycle management
    - Solana's account model vs other blockchains
    
    DEVELOPMENT FRAMEWORKS:
    - Anchor Framework: programs, accounts, instructions, macros
    - Native Solana programs with borsh serialization
    - Solana CLI tools and development workflows
    - Testing with solana-test-validator and Anchor tests
    
    CLIENT INTEGRATION:
    - Web3.js for JavaScript/TypeScript applications
    - Solana Python SDK and Rust client libraries
    - Wallet integration (Phantom, Solflare, Backpack)
    - Transaction building, simulation, and error handling
    
    ECOSYSTEM PROTOCOLS:
    - SPL Token Program and token management
    - Jupiter (DEX aggregator), Raydium (AMM), Orca (Whirlpools)
    - Metaplex (NFT infrastructure), Solana Pay
    - Lending protocols: Marginfi, Solend, Kamino
    - Liquid staking: Marinade, Lido, Jito
    
    SECURITY & BEST PRACTICES:
    - Common vulnerabilities and prevention
    - Account validation and ownership checks
    - Compute unit optimization and fee management
    - Error handling patterns and debugging techniques
    
    CURRENT DEVELOPMENTS:
    - Compressed NFTs and state compression
    - Solana Mobile Stack and Saga integration
    - Token Extensions and Token-2022 program
    - Account lookup tables and versioned transactions
    
    Provide detailed explanations with code examples where applicable.
    Be precise, practical, and include security considerations.
    """

    enhanced_prompt = solana_context * "\n\nUser Question: " * task["question"]

    # Try primary provider first
    primary_result = try_ai_provider(cfg, enhanced_prompt, cfg.ai_provider)
    
    if primary_result["success"]
        return primary_result
    end
    
    # Try fallback provider if enabled and primary failed
    if cfg.enable_fallback
        fallback_provider = cfg.ai_provider == "gemini" ? "groq" : "gemini"
        fallback_result = try_ai_provider(cfg, enhanced_prompt, fallback_provider)
        
        if fallback_result["success"]
            # Add note about fallback usage
            fallback_result["output"] = "[Fallback AI used] " * fallback_result["output"]
            return fallback_result
        end
    end
    
    # Both providers failed
    return Dict(
        "success" => false, 
        "error" => "Both AI providers failed: $(primary_result["error"])"
    )
end

function try_ai_provider(cfg::ToolSolanaKnowledgeMultiModelConfig, prompt::String, provider::String)
    try
        if provider == "groq"
            return call_groq_api(cfg, prompt)
        elseif provider == "gemini" 
            return call_gemini_api(cfg, prompt)
        else
            return Dict("success" => false, "error" => "Unknown provider: $provider")
        end
    catch e
        return Dict("success" => false, "error" => "$(provider) API error: $(string(e))")
    end
end

function call_groq_api(cfg::ToolSolanaKnowledgeMultiModelConfig, prompt::String)
    groq_cfg = Groq.GroqConfig(
        api_key = cfg.groq_api_key,
        model_name = cfg.groq_model,
        base_url = cfg.groq_base_url,
        temperature = cfg.temperature,
        max_tokens = cfg.max_output_tokens
    )
    
    answer = Groq.groq_util(groq_cfg, prompt)
    return Dict("output" => answer, "success" => true, "provider" => "groq")
end

function call_gemini_api(cfg::ToolSolanaKnowledgeMultiModelConfig, prompt::String)
    gemini_cfg = Gemini.GeminiConfig(
        api_key = cfg.gemini_api_key,
        model_name = cfg.gemini_model,
        temperature = cfg.temperature,
        max_output_tokens = cfg.max_output_tokens
    )
    
    answer = Gemini.gemini_util(gemini_cfg, prompt)
    return Dict("output" => answer, "success" => true, "provider" => "gemini")
end

const TOOL_SOLANA_KNOWLEDGE_MULTI_MODEL_METADATA = ToolMetadata(
    "solana_knowledge_multi_model",
    "Multi-model Solana expert with Groq and Gemini support. Provides comprehensive blockchain development guidance with AI provider fallback capability."
)

const TOOL_SOLANA_KNOWLEDGE_MULTI_MODEL_SPECIFICATION = ToolSpecification(
    tool_solana_knowledge_multi_model,
    ToolSolanaKnowledgeMultiModelConfig,
    TOOL_SOLANA_KNOWLEDGE_MULTI_MODEL_METADATA
)
