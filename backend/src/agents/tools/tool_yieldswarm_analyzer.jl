using ...Resources: Gemini, Groq
using ..CommonTypes: ToolSpecification, ToolMetadata, ToolConfig
using HTTP
using JSON
using Dates

Base.@kwdef struct ToolYieldSwarmAnalyzerConfig <: ToolConfig
    # Primary AI provider
    ai_provider::String = "groq"  # "gemini" or "groq"
    
    # Gemini configuration
    gemini_api_key::String = get(ENV, "GEMINI_API_KEY", "")
    gemini_model::String = "models/gemini-1.5-pro"
    
    # Groq configuration  
    groq_api_key::String = get(ENV, "GROQ_API_KEY", "")
    groq_model::String = get(ENV, "GROQ_MODEL", "llama-3.1-70b-versatile")
    groq_base_url::String = get(ENV, "GROQ_BASE_URL", "https://api.groq.com/openai/v1")
    
    # Analysis parameters
    temperature::Float64 = 0.1  # Lower temperature for more precise analysis
    max_output_tokens::Int = 4096
    
    # Fallback configuration
    enable_fallback::Bool = true
    
    # Protocol configurations
    supported_protocols::Vector{String} = [
        "uniswap_v3", "raydium", "orca", "jupiter", "pancakeswap", 
        "sushiswap", "traderjoe", "quickswap", "curve", "balancer",
        "aave", "compound", "solend", "marginfi", "kamino", "marinade", "lido"
    ]
    
    # Risk parameters
    max_slippage::Float64 = 0.005  # 0.5%
    min_liquidity_usd::Float64 = 100000.0  # $100k minimum liquidity
    max_risk_score::Float64 = 7.0  # Out of 10
end

function tool_yieldswarm_analyzer(cfg::ToolYieldSwarmAnalyzerConfig, task::Dict)
    if !haskey(task, "analysis_type") || !(task["analysis_type"] isa AbstractString)
        return Dict("success" => false, "error" => "Missing or invalid 'analysis_type' field")
    end
    
    analysis_type = task["analysis_type"]
    
    # Fetch real-time data first
    real_time_data = fetch_real_time_protocol_data(task)
    
    # Enhanced DeFi yield analysis context with real-time data
    defi_context = """
    You are an expert DeFi yield strategist and cross-chain optimization specialist. 
    You have deep knowledge of yield farming, liquidity provision, lending protocols, 
    and advanced DeFi strategies across multiple chains.
    
    REAL-TIME MARKET DATA AVAILABLE:
    $(format_real_time_data_for_prompt(real_time_data))
    
    CORE COMPETENCIES:
    
    1. YIELD ANALYSIS:
    - APY/APR calculation and risk-adjusted returns
    - Impermanent loss analysis and mitigation strategies  
    - Liquidity provision optimization across AMMs
    - Lending and borrowing yield opportunities
    - Liquid staking and validator economics
    - Yield aggregation and auto-compounding strategies
    
    2. CROSS-CHAIN PROTOCOLS:
    
    ETHEREUM ECOSYSTEM:
    - Uniswap V3 (concentrated liquidity, fee tiers, range orders)
    - Curve Finance (stableswap, cryptoswap, gauge voting)
    - Balancer (weighted pools, stable pools, boosted pools)
    - Aave (lending, borrowing, flash loans, liquidations)
    - Compound (money markets, governance, COMP rewards)
    - Yearn Finance (vault strategies, automated yield farming)
    - Convex Finance (Curve LP boosting, vlCVX strategies)
    
    SOLANA ECOSYSTEM:  
    - Raydium (AMM, farms, fusion pools, clmm)
    - Orca (Whirlpools, concentrated liquidity)
    - Jupiter (aggregation, DCA, limit orders)
    - Solend (lending protocol, collateral management)
    - Marginfi (lending, cross-margin trading)
    - Kamino (leveraged yield farming, automated strategies)
    - Marinade (liquid staking, mSOL strategies)
    - Jito (MEV-enhanced staking, JitoSOL)
    
    POLYGON ECOSYSTEM:
    - QuickSwap (AMM, dragon's syrup, concentrated liquidity)
    - SushiSwap (multi-chain presence, onsen farms)
    - PancakeSwap (BSC and Polygon deployment)
    
    AVALANCHE ECOSYSTEM:
    - Trader Joe (liquidity book, concentrated liquidity)
    - Pangolin (community-driven AMM)
    
    3. RISK ASSESSMENT:
    - Smart contract risk analysis (audit status, TVL history)
    - Liquidity risk (market depth, withdrawal capacity)
    - Impermanent loss modeling and hedging strategies
    - Protocol governance risk and token economics
    - Slippage analysis and MEV protection strategies
    - Cross-chain bridge risks and validation
    
    4. OPTIMIZATION STRATEGIES:
    - Multi-protocol yield comparison and selection
    - Dynamic rebalancing based on market conditions
    - Gas-efficient execution across different chains
    - Risk-adjusted portfolio construction
    - Correlation analysis between assets and protocols
    - Automated harvest and compound timing optimization
    
    5. REAL-TIME MARKET ANALYSIS:
    - Current yield rates across all major protocols
    - Liquidity depth and trading volume analysis  
    - Token price trends and volatility assessment
    - Governance token reward rates and vesting schedules
    - Protocol TVL trends and user adoption metrics
    
    ANALYSIS REQUIREMENTS:
    - Provide specific APY calculations with risk adjustments
    - Include gas cost considerations in yield calculations
    - Assess protocol security and audit status
    - Consider market conditions and volatility
    - Recommend specific position sizes and risk limits
    - Include exit strategy and risk management plans
    
    Always provide actionable insights with specific numbers, timeframes, and risk assessments.
    Focus on maximizing risk-adjusted returns while maintaining appropriate diversification.
    """
    
    # Create analysis-specific prompt based on type
    analysis_prompt = case_analysis_type(analysis_type, task, defi_context)
    
    # Try primary provider first
    primary_result = try_ai_provider(cfg, analysis_prompt, cfg.ai_provider)
    
    if primary_result["success"]
        # Post-process the result to add structured data
        processed_result = enhance_analysis_result(primary_result, analysis_type, cfg)
        return processed_result
    end
    
    # Try fallback provider if enabled and primary failed
    if cfg.enable_fallback
        fallback_provider = cfg.ai_provider == "gemini" ? "groq" : "gemini"
        fallback_result = try_ai_provider(cfg, analysis_prompt, fallback_provider)
        
        if fallback_result["success"]
            # Add note about fallback usage and enhance result
            fallback_result["output"] = "[Fallback AI used] " * fallback_result["output"]
            processed_result = enhance_analysis_result(fallback_result, analysis_type, cfg)
            return processed_result
        end
    end
    
    # Both providers failed
    return Dict(
        "success" => false, 
        "error" => "Both AI providers failed: $(primary_result["error"])"
    )
end

function case_analysis_type(analysis_type::String, task::Dict, base_context::String)
    case_prompt = ""
    
    if analysis_type == "yield_optimization"
        amount = get(task, "amount", "1000")
        risk_level = get(task, "risk_level", "medium")
        timeframe = get(task, "timeframe", "1-3 months")
        preferred_chains = get(task, "chains", ["ethereum", "solana", "polygon"])
        
        case_prompt = """
        YIELD OPTIMIZATION ANALYSIS REQUEST:
        
        Investment Amount: \$$amount USD
        Risk Tolerance: $(risk_level) (low/medium/high)
        Investment Timeframe: $(timeframe)
        Preferred Chains: $(join(preferred_chains, ", "))
        
        Please provide a comprehensive yield optimization strategy including:
        1. Top 5 yield opportunities with specific APY calculations
        2. Risk assessment for each opportunity (1-10 scale)
        3. Recommended allocation percentages
        4. Step-by-step execution plan with specific protocols
        5. Gas cost analysis and optimization
        6. Exit strategy and rebalancing triggers
        7. Real-time monitoring requirements
        
        Focus on maximizing risk-adjusted returns while maintaining diversification.
        """
        
    elseif analysis_type == "protocol_comparison"
        protocols = get(task, "protocols", ["uniswap_v3", "raydium", "aave"])
        asset_pair = get(task, "asset_pair", "ETH/USDC")
        
        case_prompt = """
        PROTOCOL COMPARISON ANALYSIS REQUEST:
        
        Protocols to Compare: $(join(protocols, ", "))
        Asset Pair/Token: $(asset_pair)
        
        Please provide detailed comparison including:
        1. Current yield rates and reward structures
        2. Liquidity depth and trading volume
        3. Risk assessment (smart contract, liquidity, IL risk)
        4. Gas costs and transaction efficiency
        5. User experience and interface quality
        6. Historical performance and reliability
        7. Governance and tokenomics analysis
        8. Recommended protocol ranking with rationale
        
        Include specific numbers and provide clear winner with reasoning.
        """
        
    elseif analysis_type == "risk_assessment"
        protocol = get(task, "protocol", "")
        position_size = get(task, "position_size", "10000")
        
        case_prompt = """
        RISK ASSESSMENT ANALYSIS REQUEST:
        
        Protocol: $(protocol)
        Position Size: \$$position_size USD
        
        Please provide comprehensive risk analysis including:
        1. Smart contract risk (audit status, bug bounties, TVL history)
        2. Liquidity risk (market depth, withdrawal capacity)
        3. Impermanent loss modeling (various price scenarios)
        4. Protocol governance risks
        5. Market risk (volatility, correlation analysis)
        6. Operational risks (oracle failures, bridge risks)
        7. Risk mitigation strategies
        8. Position sizing recommendations
        9. Stop-loss and risk management triggers
        10. Overall risk score (1-10) with detailed explanation
        
        Be specific about potential loss scenarios and provide actionable risk management plans.
        """
        
    elseif analysis_type == "market_conditions"
        case_prompt = """
        MARKET CONDITIONS ANALYSIS REQUEST:
        
        Please provide current DeFi market analysis including:
        1. Overall market sentiment and trends
        2. Yield rate trends across major protocols
        3. TVL movements and capital flows
        4. Governance token performance and rewards
        5. New protocol launches and opportunities
        6. Risk events and market dislocations
        7. Seasonal patterns and cyclical trends
        8. Cross-chain bridge activity and arbitrage opportunities
        9. Regulatory developments affecting yields
        10. Strategic recommendations for current conditions
        
        Focus on actionable insights for yield optimization in current market environment.
        """
        
    else
        # Generic analysis
        query = get(task, "query", "Analyze DeFi yield opportunities")
        case_prompt = """
        GENERAL DEFI ANALYSIS REQUEST:
        
        Query: $(query)
        
        Please provide detailed analysis addressing the specific question while incorporating:
        - Current market conditions
        - Risk-adjusted return calculations  
        - Protocol security considerations
        - Execution recommendations
        - Risk management strategies
        """
    end
    
    return base_context * "\n\n" * case_prompt
end

function enhance_analysis_result(result::Dict, analysis_type::String, cfg::ToolYieldSwarmAnalyzerConfig)
    enhanced = copy(result)
    
    # Add structured metadata
    enhanced["analysis_metadata"] = Dict(
        "analysis_type" => analysis_type,
        "timestamp" => string(now()),
        "ai_provider" => enhanced["provider"],
        "supported_protocols" => cfg.supported_protocols,
        "risk_parameters" => Dict(
            "max_slippage" => cfg.max_slippage,
            "min_liquidity_usd" => cfg.min_liquidity_usd,
            "max_risk_score" => cfg.max_risk_score
        )
    )
    
    # Add execution readiness flag
    enhanced["execution_ready"] = true
    enhanced["requires_swarm_coordination"] = analysis_type in ["yield_optimization", "protocol_comparison"]
    
    return enhanced
end

function try_ai_provider(cfg::ToolYieldSwarmAnalyzerConfig, prompt::String, provider::String)
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

function call_groq_api(cfg::ToolYieldSwarmAnalyzerConfig, prompt::String)
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

function call_gemini_api(cfg::ToolYieldSwarmAnalyzerConfig, prompt::String)
    gemini_cfg = Gemini.GeminiConfig(
        api_key = cfg.gemini_api_key,
        model_name = cfg.gemini_model,
        temperature = cfg.temperature,
        max_output_tokens = cfg.max_output_tokens
    )
    
    answer = Gemini.gemini_util(gemini_cfg, prompt)
    return Dict("output" => answer, "success" => true, "provider" => "gemini")
end

"""
Fetch real-time protocol data for analysis
"""
function fetch_real_time_protocol_data(task::Dict)
    # Extract chains and protocols from task
    chains = get(task, "chains", ["ethereum", "solana"])
    protocols = get(task, "protocols", String[])
    
    # Create data fetcher config
    data_fetcher_config = ToolYieldSwarmDataFetcherConfig()
    
    # Fetch comprehensive real-time data
    fetch_task = Dict(
        "data_type" => "comprehensive",
        "chains" => chains,
        "protocols" => protocols
    )
    
    try
        # Import and use the data fetcher tool
        include("tool_yieldswarm_data_fetcher.jl")
        result = tool_yieldswarm_data_fetcher(data_fetcher_config, fetch_task)
        
        if result["success"]
            return result["data"]
        else
            @warn "Failed to fetch real-time data: $(result["error"])"
            return Dict{String, Any}()
        end
    catch e
        @warn "Error fetching real-time data: $e"
        return Dict{String, Any}()
    end
end

"""
Format real-time data for AI prompt
"""
function format_real_time_data_for_prompt(data::Dict{String, Any})
    if isempty(data)
        return "No real-time data available - using built-in protocol knowledge."
    end
    
    prompt_parts = String[]
    
    # Format yield data
    if haskey(data, "yields") && !isempty(data["yields"])
        push!(prompt_parts, "\n📊 LIVE YIELD OPPORTUNITIES:")
        
        # Sort yields by APY descending
        sorted_yields = sort(collect(data["yields"]), by=x->get(x[2], "apy", 0.0), rev=true)
        
        for (pool_key, yield_info) in sorted_yields[1:min(20, length(sorted_yields))]  # Top 20
            apy = get(yield_info, "apy", 0.0)
            protocol = get(yield_info, "protocol", "unknown")
            chain = get(yield_info, "chain", "unknown")
            tvl = get(yield_info, "tvl_usd", 0.0)
            symbol = get(yield_info, "symbol", "")
            
            if apy > 0
                push!(prompt_parts, "• $(uppercase(protocol)) on $(uppercase(chain)): $(symbol) - $(round(apy, digits=2))% APY (TVL: \$$(format_number(tvl)))")
            end
        end
    end
    
    # Format price data
    if haskey(data, "prices") && !isempty(data["prices"])
        push!(prompt_parts, "\n💰 CURRENT TOKEN PRICES:")
        for (token, price_info) in data["prices"]
            price = get(price_info, "price_usd", 0.0)
            change = get(price_info, "change_24h", 0.0)
            change_indicator = change >= 0 ? "📈" : "📉"
            push!(prompt_parts, "• $(uppercase(token)): \$$(round(price, digits=2)) $(change_indicator) $(round(change, digits=2))%")
        end
    end
    
    # Format TVL data
    if haskey(data, "tvl") && !isempty(data["tvl"])
        push!(prompt_parts, "\n🏦 PROTOCOL TVL DATA:")
        sorted_tvl = sort(collect(data["tvl"]), by=x->get(x[2], "tvl", 0.0), rev=true)
        
        for (protocol, tvl_info) in sorted_tvl[1:min(15, length(sorted_tvl))]  # Top 15
            tvl = get(tvl_info, "tvl", 0.0)
            change_7d = get(tvl_info, "change_7d", 0.0)
            category = get(tvl_info, "category", "DeFi")
            
            if tvl > 1000000  # Only show protocols with >$1M TVL
                push!(prompt_parts, "• $(uppercase(protocol)) ($(category)): \$$(format_number(tvl)) TVL (7d: $(round(change_7d, digits=2))%)")
            end
        end
    end
    
    push!(prompt_parts, "\n⏰ Data timestamp: $(get(data, "timestamp", "unknown"))")
    push!(prompt_parts, "✨ Use this LIVE data for accurate recommendations!")
    
    return join(prompt_parts, "\n")
end

"""
Format large numbers for display
"""
function format_number(num::Real)
    if num >= 1e9
        return "$(round(num/1e9, digits=2))B"
    elseif num >= 1e6
        return "$(round(num/1e6, digits=2))M"
    elseif num >= 1e3
        return "$(round(num/1e3, digits=2))K"
    else
        return string(round(num, digits=2))
    end
end

const TOOL_YIELDSWARM_ANALYZER_METADATA = ToolMetadata(
    "yieldswarm_analyzer",
    "Advanced multi-protocol DeFi yield analysis tool with cross-chain optimization capabilities. Provides comprehensive yield farming strategies, risk assessment, and protocol comparisons across Ethereum, Solana, Polygon, and Avalanche ecosystems."
)

const TOOL_YIELDSWARM_ANALYZER_SPECIFICATION = ToolSpecification(
    tool_yieldswarm_analyzer,
    ToolYieldSwarmAnalyzerConfig,
    TOOL_YIELDSWARM_ANALYZER_METADATA
)
