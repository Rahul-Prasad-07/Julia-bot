using ...Resources: Gemini
using ..CommonTypes: ToolSpecification, ToolMetadata, ToolConfig
using HTTP
using JSON

Base.@kwdef struct ToolSolanaEcosystemConfig <: ToolConfig
    api_key::String = get(ENV, "GEMINI_API_KEY", "")
    model_name::String = "models/gemini-1.5-pro"
    temperature::Float64 = 0.2
    max_output_tokens::Int = 3072
end

function tool_solana_ecosystem(cfg::ToolSolanaEcosystemConfig, task::Dict)
    if !haskey(task, "query") || !(task["query"] isa AbstractString)
        return Dict("success" => false, "error" => "Missing or invalid 'query' field")
    end

    ecosystem_context = """
    You are a Solana ecosystem and DeFi expert with deep knowledge of protocols, integrations, and market dynamics.

    MAJOR PROTOCOLS & INTEGRATIONS:
    
    DEXs & AMMs:
    - Jupiter (aggregator): Best routes, swap APIs, DCA, limit orders
    - Raydium: CLMM pools, farming, staking integration
    - Orca: Whirlpools, concentrated liquidity
    - Serum: Order book DEX, market making
    - Phoenix: New order book protocol
    - Meteora: Multi-asset AMM and vaults
    
    LENDING & BORROWING:
    - Marginfi: Lending protocol integration
    - Solend: Risk management and liquidations
    - Mango: Perps and spot trading
    - Kamino: Yield strategies and automation
    
    YIELD & STAKING:
    - Marinade Finance: Liquid staking (mSOL)
    - Lido: stSOL liquid staking
    - Jito: MEV and staking rewards
    - Sanctum: Multi-LST infrastructure
    
    INFRASTRUCTURE:
    - Pyth Network: Price oracles
    - Switchboard: Decentralized oracles
    - Wormhole: Cross-chain bridging
    - Allbridge: Multi-chain transfers
    
    NFT & GAMING:
    - Metaplex: NFT standard and tooling
    - Magic Eden: Marketplace APIs
    - Tensor: Professional NFT trading
    - Star Atlas: Gaming ecosystem
    
    DEVELOPMENT TOOLS:
    - Helius: Enhanced RPC and webhooks
    - QuickNode: RPC and analytics
    - Triton: RPC infrastructure
    - Anchor: Smart contract framework
    
    INTEGRATION PATTERNS:
    - Multi-protocol yield strategies
    - Cross-chain bridge integrations
    - Oracle price feed integration
    - NFT marketplace integration
    - Wallet adapter patterns
    
    Provide specific integration guides, API usage, smart contract interactions, and ecosystem updates.
    """

    enhanced_prompt = ecosystem_context * "\n\nEcosystem Query: " * task["query"]

    gemini_cfg = Gemini.GeminiConfig(
        api_key = cfg.api_key,
        model_name = cfg.model_name,
        temperature = cfg.temperature,
        max_output_tokens = cfg.max_output_tokens
    )

    try
        ecosystem_response = Gemini.gemini_util(gemini_cfg, enhanced_prompt)
        return Dict("output" => ecosystem_response, "success" => true)
    catch e
        return Dict("success" => false, "error" => string(e))
    end
end

const TOOL_SOLANA_ECOSYSTEM_METADATA = ToolMetadata(
    "solana_ecosystem",
    "Provides comprehensive information about Solana DeFi protocols, integrations, yield strategies, and ecosystem developments."
)

const TOOL_SOLANA_ECOSYSTEM_SPECIFICATION = ToolSpecification(
    tool_solana_ecosystem,
    ToolSolanaEcosystemConfig,
    TOOL_SOLANA_ECOSYSTEM_METADATA
)
