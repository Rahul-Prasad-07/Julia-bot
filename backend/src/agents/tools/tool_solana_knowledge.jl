using ...Resources: Gemini
using ..CommonTypes: ToolSpecification, ToolMetadata, ToolConfig
using HTTP
using JSON

Base.@kwdef struct ToolSolanaKnowledgeConfig <: ToolConfig
    api_key::String = get(ENV, "GEMINI_API_KEY", "")
    model_name::String = "models/gemini-1.5-pro"
    temperature::Float64 = 0.3  # Lower temperature for more accurate technical responses
    max_output_tokens::Int = 2048
end

function tool_solana_knowledge(cfg::ToolSolanaKnowledgeConfig, task::Dict)
    if !haskey(task, "question") || !(task["question"] isa AbstractString)
        return Dict("success" => false, "error" => "Missing or invalid 'question' field")
    end

    # Solana-specific context and knowledge base
    solana_context = """
    You are a Solana blockchain development expert. Provide accurate, up-to-date information about:
    
    CORE CONCEPTS:
    - Accounts, Programs, Instructions, Transactions
    - Program Derived Addresses (PDAs)
    - Cross-program invocations (CPIs)
    - Rent, lamports, and account management
    - Solana's account model vs Ethereum's
    
    DEVELOPMENT TOOLS:
    - Anchor Framework for smart contract development
    - Solana CLI tools and commands
    - Web3.js for JavaScript integration
    - Rust programming for on-chain programs
    - Testing with solana-test-validator
    
    ECOSYSTEM:
    - SPL Token Program
    - Serum DEX, Jupiter, Raydium, Orca
    - Metaplex for NFTs
    - Solana Pay for payments
    - Phantom, Solflare wallets
    
    BEST PRACTICES:
    - Security considerations and common vulnerabilities
    - Program optimization and compute unit management
    - Transaction fee optimization
    - Error handling and debugging
    
    CURRENT TRENDS:
    - Compressed NFTs
    - State compression
    - Solana Mobile Stack
    - xNFTs and Saga phone integration
    
    Provide code examples, explanations, and practical guidance for Solana development.
    """

    enhanced_prompt = solana_context * "\n\nUser Question: " * task["question"]

    gemini_cfg = Gemini.GeminiConfig(
        api_key = cfg.api_key,
        model_name = cfg.model_name,
        temperature = cfg.temperature,
        max_output_tokens = cfg.max_output_tokens
    )

    try
        answer = Gemini.gemini_util(gemini_cfg, enhanced_prompt)
        return Dict("output" => answer, "success" => true)
    catch e
        return Dict("success" => false, "error" => string(e))
    end
end

const TOOL_SOLANA_KNOWLEDGE_METADATA = ToolMetadata(
    "solana_knowledge",
    "Provides expert knowledge and guidance on Solana blockchain development, including smart contracts, DeFi, NFTs, and ecosystem tools."
)

const TOOL_SOLANA_KNOWLEDGE_SPECIFICATION = ToolSpecification(
    tool_solana_knowledge,
    ToolSolanaKnowledgeConfig,
    TOOL_SOLANA_KNOWLEDGE_METADATA
)
