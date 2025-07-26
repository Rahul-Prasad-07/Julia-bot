using ...Resources: Gemini
using ..CommonTypes: ToolSpecification, ToolMetadata, ToolConfig
using HTTP
using JSON

Base.@kwdef struct ToolSolanaCodeGenConfig <: ToolConfig
    api_key::String = get(ENV, "GEMINI_API_KEY", "")
    model_name::String = "models/gemini-1.5-pro"
    temperature::Float64 = 0.4
    max_output_tokens::Int = 4096
end

function tool_solana_code_gen(cfg::ToolSolanaCodeGenConfig, task::Dict)
    if !haskey(task, "request") || !(task["request"] isa AbstractString)
        return Dict("success" => false, "error" => "Missing or invalid 'request' field")
    end

    code_gen_context = """
    You are a Solana smart contract and application development expert. Generate high-quality, production-ready code based on user requests.

    SPECIALIZATIONS:
    1. ANCHOR FRAMEWORK PROGRAMS:
       - Complete program structure with proper imports
       - Account validation and constraints
       - Instruction handlers with error handling
       - State management and serialization
       - Cross-program invocations (CPIs)
       - PDA derivation and seeds

    2. CLIENT-SIDE INTEGRATION:
       - Web3.js transaction building
       - Account fetching and parsing
       - Wallet integration (Phantom, Solflare)
       - Transaction simulation and error handling

    3. TESTING AND DEPLOYMENT:
       - Unit tests with Anchor test framework
       - Integration tests with solana-test-validator
       - Deployment scripts and configuration

    4. COMMON PATTERNS:
       - Token programs (SPL tokens, NFTs)
       - DEX and AMM implementations
       - Staking and governance contracts
       - Oracle integrations
       - Multi-signature wallets

    REQUIREMENTS:
    - Include comprehensive error handling
    - Add security checks and validations
    - Provide clear comments and documentation
    - Follow Solana best practices
    - Include example usage where applicable
    - Consider compute unit optimization

    Generate complete, working code with explanations.
    """

    enhanced_prompt = code_gen_context * "\n\nCode Generation Request: " * task["request"]
    
    # Add specific context based on request type
    request_lower = lowercase(task["request"])
    if occursin("anchor", request_lower) || occursin("program", request_lower)
        enhanced_prompt *= "\n\nFocus on Anchor framework patterns and on-chain program development."
    elseif occursin("client", request_lower) || occursin("frontend", request_lower)
        enhanced_prompt *= "\n\nFocus on client-side integration and Web3.js usage."
    elseif occursin("test", request_lower)
        enhanced_prompt *= "\n\nFocus on comprehensive testing strategies and test code."
    end

    gemini_cfg = Gemini.GeminiConfig(
        api_key = cfg.api_key,
        model_name = cfg.model_name,
        temperature = cfg.temperature,
        max_output_tokens = cfg.max_output_tokens
    )

    try
        code_response = Gemini.gemini_util(gemini_cfg, enhanced_prompt)
        return Dict("output" => code_response, "success" => true)
    catch e
        return Dict("success" => false, "error" => string(e))
    end
end

const TOOL_SOLANA_CODE_GEN_METADATA = ToolMetadata(
    "solana_code_gen",
    "Generates Solana smart contracts, client-side code, tests, and deployment scripts using Anchor framework and Web3.js."
)

const TOOL_SOLANA_CODE_GEN_SPECIFICATION = ToolSpecification(
    tool_solana_code_gen,
    ToolSolanaCodeGenConfig,
    TOOL_SOLANA_CODE_GEN_METADATA
)
