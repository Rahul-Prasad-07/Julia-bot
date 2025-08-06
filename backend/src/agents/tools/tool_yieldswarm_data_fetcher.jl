"""
YieldSwarm Real-Time Data Fetcher Tool

This tool fetches live yield, TVL, and price data from DeFi protocols
using Julia's built-in HTTP.jl capabilities.
"""

using HTTP
using JSON3
using Dates
using ...Resources: Gemini, Groq
using ..CommonTypes: ToolSpecification, ToolMetadata, ToolConfig

Base.@kwdef struct ToolYieldSwarmDataFetcherConfig <: ToolConfig
    # API endpoints for real-time data
    defillama_api::String = "https://yields.llama.fi"
    coingecko_api::String = "https://api.coingecko.com/api/v3"
    jupiter_api::String = "https://quote-api.jup.ag/v6"
    uniswap_api::String = "https://api.thegraph.com/subgraphs/name/uniswap/uniswap-v3"
    raydium_api::String = "https://api.raydium.io/v2"
    
    # Request timeout and retry settings
    request_timeout::Int = 30
    max_retries::Int = 3
    retry_delay::Int = 2
    
    # Cache settings
    cache_duration_minutes::Int = 5
    enable_caching::Bool = true
    
    # Rate limiting
    rate_limit_per_minute::Int = 60
    last_request_time::Ref{Float64} = Ref(0.0)
end

# Global cache for protocol data
const PROTOCOL_DATA_CACHE = Dict{String, Dict{String, Any}}()
const CACHE_TIMESTAMPS = Dict{String, DateTime}()

function tool_yieldswarm_data_fetcher(cfg::ToolYieldSwarmDataFetcherConfig, task::Dict)
    if !haskey(task, "data_type") || !(task["data_type"] isa AbstractString)
        return Dict("success" => false, "error" => "Missing or invalid 'data_type' field")
    end
    
    data_type = task["data_type"]
    chains = get(task, "chains", ["ethereum", "solana"])
    protocols = get(task, "protocols", String[])
    
    try
        result = Dict{String, Any}()
        
        # Fetch different types of real-time data
        if data_type == "yields"
            result = fetch_yield_data(cfg, chains, protocols)
        elseif data_type == "prices"
            result = fetch_price_data(cfg, get(task, "tokens", String[]))
        elseif data_type == "tvl"
            result = fetch_tvl_data(cfg, chains, protocols)
        elseif data_type == "liquidity"
            result = fetch_liquidity_data(cfg, chains, protocols)
        elseif data_type == "comprehensive"
            result = fetch_comprehensive_data(cfg, chains, protocols)
        else
            return Dict("success" => false, "error" => "Unknown data_type: $data_type")
        end
        
        return Dict(
            "success" => true,
            "data" => result,
            "timestamp" => now(),
            "data_type" => data_type,
            "chains" => chains,
            "cache_used" => false
        )
        
    catch e
        @error "Error fetching real-time data: $e"
        return Dict("success" => false, "error" => "Data fetch error: $e")
    end
end

"""
Fetch real-time yield data from DeFiLlama and protocol-specific APIs
"""
function fetch_yield_data(cfg::ToolYieldSwarmDataFetcherConfig, chains::Vector{String}, protocols::Vector{String})
    yields_data = Dict{String, Any}()
    
    # Check cache first
    cache_key = "yields_$(join(chains, "_"))_$(join(protocols, "_"))"
    if cfg.enable_caching && is_cache_valid(cache_key, cfg.cache_duration_minutes)
        @info "Using cached yield data"
        return PROTOCOL_DATA_CACHE[cache_key]
    end
    
    # Rate limiting
    enforce_rate_limit(cfg)
    
    try
        # Fetch from DeFiLlama - Real yields API
        defillama_url = "$(cfg.defillama_api)/pools"
        @info "Fetching yield data from DeFiLlama: $defillama_url"
        
        response = HTTP.get(defillama_url, ["User-Agent" => "JuliaOS-YieldSwarm/1.0"])
        
        if response.status == 200
            data = JSON3.read(response.body)
            
            # Filter and process yield data by chains
            for pool in data["data"]
                chain = lowercase(get(pool, "chain", ""))
                protocol = lowercase(get(pool, "project", ""))
                
                if chain in chains || isempty(chains)
                    if isempty(protocols) || protocol in protocols
                        pool_key = "$(chain)_$(protocol)_$(get(pool, "symbol", "unknown"))"
                        
                        yields_data[pool_key] = Dict(
                            "protocol" => protocol,
                            "chain" => chain,
                            "symbol" => get(pool, "symbol", ""),
                            "apy" => get(pool, "apy", 0.0),
                            "apy_base" => get(pool, "apyBase", 0.0),
                            "apy_reward" => get(pool, "apyReward", 0.0),
                            "tvl_usd" => get(pool, "tvlUsd", 0.0),
                            "pool_id" => get(pool, "pool", ""),
                            "confidence" => get(pool, "confidence", 0),
                            "il_risk" => get(pool, "ilRisk", "unknown"),
                            "exposure" => get(pool, "exposure", "single"),
                            "predicted_class" => get(pool, "predictedClass", ""),
                            "mu" => get(pool, "mu", 0.0),
                            "sigma" => get(pool, "sigma", 0.0),
                            "count" => get(pool, "count", 0),
                            "outlier" => get(pool, "outlier", false),
                            "underlyingTokens" => get(pool, "underlyingTokens", String[])
                        )
                    end
                end
            end
            
            @info "Successfully fetched $(length(yields_data)) yield opportunities"
            
            # Cache the results
            if cfg.enable_caching
                PROTOCOL_DATA_CACHE[cache_key] = yields_data
                CACHE_TIMESTAMPS[cache_key] = now()
            end
            
        else
            @warn "DeFiLlama API returned status: $(response.status)"
        end
        
    catch e
        @error "Error fetching yield data: $e"
        # Fallback to cached data if available
        if haskey(PROTOCOL_DATA_CACHE, cache_key)
            @info "Using stale cached data due to API error"
            return PROTOCOL_DATA_CACHE[cache_key]
        end
    end
    
    # Enhance with protocol-specific data
    enhance_with_protocol_data!(yields_data, cfg, chains)
    
    return yields_data
end

"""
Fetch real-time price data from CoinGecko
"""
function fetch_price_data(cfg::ToolYieldSwarmDataFetcherConfig, tokens::Vector{String})
    prices_data = Dict{String, Any}()
    
    if isempty(tokens)
        tokens = ["ethereum", "solana", "bitcoin", "usd-coin", "tether"]
    end
    
    cache_key = "prices_$(join(tokens, "_"))"
    if cfg.enable_caching && is_cache_valid(cache_key, cfg.cache_duration_minutes)
        return PROTOCOL_DATA_CACHE[cache_key]
    end
    
    enforce_rate_limit(cfg)
    
    try
        token_ids = join(tokens, ",")
        url = "$(cfg.coingecko_api)/simple/price?ids=$(token_ids)&vs_currencies=usd&include_24hr_change=true&include_market_cap=true&include_24hr_vol=true"
        
        @info "Fetching price data from CoinGecko: $url"
        
        response = HTTP.get(url, ["User-Agent" => "JuliaOS-YieldSwarm/1.0"])
        
        if response.status == 200
            data = JSON3.read(response.body)
            
            for (token, price_info) in data
                prices_data[String(token)] = Dict(
                    "price_usd" => get(price_info, "usd", 0.0),
                    "change_24h" => get(price_info, "usd_24h_change", 0.0),
                    "market_cap" => get(price_info, "usd_market_cap", 0.0),
                    "volume_24h" => get(price_info, "usd_24h_vol", 0.0),
                    "timestamp" => now()
                )
            end
            
            @info "Successfully fetched prices for $(length(prices_data)) tokens"
            
            if cfg.enable_caching
                PROTOCOL_DATA_CACHE[cache_key] = prices_data
                CACHE_TIMESTAMPS[cache_key] = now()
            end
        end
        
    catch e
        @error "Error fetching price data: $e"
    end
    
    return prices_data
end

"""
Fetch TVL data for protocols
"""
function fetch_tvl_data(cfg::ToolYieldSwarmDataFetcherConfig, chains::Vector{String}, protocols::Vector{String})
    tvl_data = Dict{String, Any}()
    
    cache_key = "tvl_$(join(chains, "_"))_$(join(protocols, "_"))"
    if cfg.enable_caching && is_cache_valid(cache_key, cfg.cache_duration_minutes)
        return PROTOCOL_DATA_CACHE[cache_key]
    end
    
    enforce_rate_limit(cfg)
    
    try
        # Fetch protocol TVL from DeFiLlama
        url = "$(cfg.defillama_api)/protocols"
        @info "Fetching TVL data from DeFiLlama: $url"
        
        response = HTTP.get(url, ["User-Agent" => "JuliaOS-YieldSwarm/1.0"])
        
        if response.status == 200
            data = JSON3.read(response.body)
            
            for protocol in data
                protocol_name = lowercase(get(protocol, "name", ""))
                protocol_chains = get(protocol, "chains", String[])
                
                # Filter by requested protocols and chains
                if (isempty(protocols) || protocol_name in protocols) &&
                   (isempty(chains) || any(chain -> chain in chains, lowercase.(protocol_chains)))
                    
                    tvl_data[protocol_name] = Dict(
                        "name" => get(protocol, "name", ""),
                        "tvl" => get(protocol, "tvl", 0.0),
                        "chains" => protocol_chains,
                        "change_1h" => get(protocol, "change_1h", 0.0),
                        "change_1d" => get(protocol, "change_1d", 0.0),
                        "change_7d" => get(protocol, "change_7d", 0.0),
                        "mcap" => get(protocol, "mcap", 0.0),
                        "category" => get(protocol, "category", ""),
                        "logo" => get(protocol, "logo", ""),
                        "url" => get(protocol, "url", ""),
                        "description" => get(protocol, "description", "")
                    )
                end
            end
            
            @info "Successfully fetched TVL data for $(length(tvl_data)) protocols"
            
            if cfg.enable_caching
                PROTOCOL_DATA_CACHE[cache_key] = tvl_data
                CACHE_TIMESTAMPS[cache_key] = now()
            end
        end
        
    catch e
        @error "Error fetching TVL data: $e"
    end
    
    return tvl_data
end

"""
Fetch comprehensive data combining yields, prices, and TVL
"""
function fetch_comprehensive_data(cfg::ToolYieldSwarmDataFetcherConfig, chains::Vector{String}, protocols::Vector{String})
    comprehensive_data = Dict{String, Any}()
    
    # Fetch all data types
    yields = fetch_yield_data(cfg, chains, protocols)
    prices = fetch_price_data(cfg, String[])
    tvl = fetch_tvl_data(cfg, chains, protocols)
    
    comprehensive_data["yields"] = yields
    comprehensive_data["prices"] = prices
    comprehensive_data["tvl"] = tvl
    comprehensive_data["timestamp"] = now()
    comprehensive_data["data_freshness"] = "live"
    
    return comprehensive_data
end

"""
Enhance yield data with protocol-specific information
"""
function enhance_with_protocol_data!(yields_data::Dict{String, Any}, cfg::ToolYieldSwarmDataFetcherConfig, chains::Vector{String})
    # Add Solana-specific data from Raydium
    if "solana" in chains
        try
            enhance_with_raydium_data!(yields_data, cfg)
        catch e
            @warn "Failed to enhance with Raydium data: $e"
        end
    end
    
    # Add Ethereum-specific data from Uniswap
    if "ethereum" in chains
        try
            enhance_with_uniswap_data!(yields_data, cfg)
        catch e
            @warn "Failed to enhance with Uniswap data: $e"
        end
    end
end

"""
Add Raydium-specific pool data
"""
function enhance_with_raydium_data!(yields_data::Dict{String, Any}, cfg::ToolYieldSwarmDataFetcherConfig)
    enforce_rate_limit(cfg)
    
    url = "$(cfg.raydium_api)/main/pairs"
    @info "Fetching Raydium pool data: $url"
    
    response = HTTP.get(url, ["User-Agent" => "JuliaOS-YieldSwarm/1.0"])
    
    if response.status == 200
        data = JSON3.read(response.body)
        
        for pool in data
            if haskey(pool, "name") && haskey(pool, "apy")
                pool_name = "solana_raydium_$(get(pool, "name", ""))"
                
                if !haskey(yields_data, pool_name)
                    yields_data[pool_name] = Dict{String, Any}()
                end
                
                merge!(yields_data[pool_name], Dict(
                    "raydium_apy" => get(pool, "apy", 0.0),
                    "raydium_tvl" => get(pool, "liquidity", 0.0),
                    "raydium_volume_24h" => get(pool, "volume_24h", 0.0),
                    "raydium_pool_id" => get(pool, "ammId", "")
                ))
            end
        end
        
        @info "Enhanced data with Raydium pools"
    end
end

"""
Add Uniswap V3-specific pool data
"""
function enhance_with_uniswap_data!(yields_data::Dict{String, Any}, cfg::ToolYieldSwarmDataFetcherConfig)
    # Uniswap V3 subgraph query for top pools
    query = """
    {
      pools(first: 50, orderBy: totalValueLockedUSD, orderDirection: desc) {
        id
        token0 {
          symbol
        }
        token1 {
          symbol
        }
        feeTier
        totalValueLockedUSD
        volumeUSD
        txCount
      }
    }
    """
    
    enforce_rate_limit(cfg)
    
    try
        response = HTTP.post(cfg.uniswap_api,
            ["Content-Type" => "application/json", "User-Agent" => "JuliaOS-YieldSwarm/1.0"],
            JSON3.write(Dict("query" => query))
        )
        
        if response.status == 200
            data = JSON3.read(response.body)
            
            if haskey(data, "data") && haskey(data["data"], "pools")
                for pool in data["data"]["pools"]
                    token0 = get(pool["token0"], "symbol", "")
                    token1 = get(pool["token1"], "symbol", "")
                    pool_name = "ethereum_uniswap_$(token0)_$(token1)"
                    
                    if !haskey(yields_data, pool_name)
                        yields_data[pool_name] = Dict{String, Any}()
                    end
                    
                    merge!(yields_data[pool_name], Dict(
                        "uniswap_tvl" => parse(Float64, get(pool, "totalValueLockedUSD", "0")),
                        "uniswap_volume" => parse(Float64, get(pool, "volumeUSD", "0")),
                        "uniswap_fee_tier" => get(pool, "feeTier", 0),
                        "uniswap_pool_id" => get(pool, "id", ""),
                        "uniswap_tx_count" => get(pool, "txCount", 0)
                    ))
                end
                
                @info "Enhanced data with Uniswap V3 pools"
            end
        end
        
    catch e
        @warn "Failed to fetch Uniswap data: $e"
    end
end

"""
Cache validation helper
"""
function is_cache_valid(cache_key::String, duration_minutes::Int)::Bool
    if !haskey(CACHE_TIMESTAMPS, cache_key)
        return false
    end
    
    cache_time = CACHE_TIMESTAMPS[cache_key]
    return (now() - cache_time) < Minute(duration_minutes)
end

"""
Rate limiting helper
"""
function enforce_rate_limit(cfg::ToolYieldSwarmDataFetcherConfig)
    current_time = time()
    time_since_last = current_time - cfg.last_request_time[]
    
    min_interval = 60.0 / cfg.rate_limit_per_minute
    
    if time_since_last < min_interval
        sleep_time = min_interval - time_since_last
        @info "Rate limiting: sleeping for $(sleep_time) seconds"
        sleep(sleep_time)
    end
    
    cfg.last_request_time[] = time()
end

# Tool metadata and specification
const TOOL_YIELDSWARM_DATA_FETCHER_METADATA = ToolMetadata(
    "yieldswarm_data_fetcher",
    "Fetches real-time yield, price, and TVL data from DeFi protocols across multiple chains using live APIs including DeFiLlama, CoinGecko, and protocol-specific endpoints"
)

const TOOL_YIELDSWARM_DATA_FETCHER_SPECIFICATION = ToolSpecification(
    tool_yieldswarm_data_fetcher,
    ToolYieldSwarmDataFetcherConfig,
    TOOL_YIELDSWARM_DATA_FETCHER_METADATA
)
