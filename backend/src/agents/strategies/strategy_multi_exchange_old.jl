# Multi-Exchange and DeFi Integration for Market Making
# Supports CEX, DEX, and cross-chain operations

using HTTP, JSON3, CSV, DataFrames, Statistics, Dates
using ..CommonTypes: StrategySpecification, StrategyMetadata, ActionRequest, ActionResponse

# Blockchain and DeFi Integrations
abstract type BlockchainNetwork end

struct EthereumNetwork <: BlockchainNetwork
    rpc_url::String
    chain_id::Int64
    gas_price_gwei::Float64
    gas_limit::Int64
end

struct SolanaNetwork <: BlockchainNetwork
    rpc_url::String
    cluster::String  # mainnet-beta, devnet, testnet
    commitment::String  # confirmed, finalized
end

struct BinanceSmartChain <: BlockchainNetwork
    rpc_url::String
    chain_id::Int64
    gas_price_gwei::Float64
    gas_limit::Int64
end

struct ArbitrumNetwork <: BlockchainNetwork
    rpc_url::String
    chain_id::Int64
    gas_price_gwei::Float64
    gas_limit::Int64
end

struct PolygonNetwork <: BlockchainNetwork
    rpc_url::String
    chain_id::Int64
    gas_price_gwei::Float64
    gas_limit::Int64
end

# DEX Protocols
abstract type DexProtocol end

struct UniswapV3 <: DexProtocol
    router_address::String
    factory_address::String
    quoter_address::String
    network::BlockchainNetwork
    fee_tiers::Vector{Int64}  # 500, 3000, 10000 (0.05%, 0.3%, 1%)
end

struct PancakeSwap <: DexProtocol
    router_address::String
    factory_address::String
    network::BinanceSmartChain
    fee_tier::Int64  # 2500 (0.25%)
end

struct RaydiumAMM <: DexProtocol
    program_id::String
    network::SolanaNetwork
    fee_rate::Float64  # 0.25%
end

struct SushiSwap <: DexProtocol
    router_address::String
    factory_address::String
    network::BlockchainNetwork
    fee_tier::Int64  # 3000 (0.3%)
end

# Centralized Exchanges
abstract type CentralizedExchange end

struct BinanceSpot <: CentralizedExchange
    base_url::String
    api_key::String
    api_secret::String
    testnet::Bool
end

struct BinanceFutures <: CentralizedExchange
    base_url::String
    api_key::String
    api_secret::String
    testnet::Bool
end

struct BybitSpot <: CentralizedExchange
    base_url::String
    api_key::String
    api_secret::String
    testnet::Bool
end

struct BybitFutures <: CentralizedExchange
    base_url::String
    api_key::String
    api_secret::String
    testnet::Bool
end

struct OKXExchange <: CentralizedExchange
    base_url::String
    api_key::String
    api_secret::String
    passphrase::String
    testnet::Bool
end

struct KucoinExchange <: CentralizedExchange
    base_url::String
    api_key::String
    api_secret::String
    passphrase::String
    testnet::Bool
end

# Wallet Management
struct WalletConfig
    address::String
    private_key::String
    mnemonic::String
    derivation_path::String
    network::BlockchainNetwork
end

struct MultiWalletManager
    wallets::Dict{String, WalletConfig}  # network_name => wallet_config
    active_wallet::String
    backup_wallets::Vector{String}
end

# Cross-Chain Bridge Integration
struct BridgeConfig
    bridge_name::String
    source_chain::String
    destination_chain::String
    supported_tokens::Vector{String}
    bridge_contract::String
    min_amount::Float64
    max_amount::Float64
    fee_percentage::Float64
end

# Liquidity Pool Management
struct LiquidityPool
    pool_address::String
    token0::String
    token1::String
    fee_tier::Int64
    protocol::DexProtocol
    tvl::Float64
    apr::Float64
    volume_24h::Float64
    current_price::Float64
    price_range_lower::Float64
    price_range_upper::Float64
end

struct LiquidityPosition
    pool::LiquidityPool
    token0_amount::Float64
    token1_amount::Float64
    position_id::Union{Int64, String}
    entry_price::Float64
    current_value::Float64
    fees_earned::Float64
    impermanent_loss::Float64
    timestamp::DateTime
end

# Governance and DAO Integration
struct GovernanceToken
    symbol::String
    contract_address::String
    network::BlockchainNetwork
    balance::Float64
    voting_power::Float64
    staked_amount::Float64
end

struct DAOProposal
    proposal_id::String
    title::String
    description::String
    proposal_type::String  # "parameter_change", "treasury", "upgrade"
    voting_deadline::DateTime
    current_votes_for::Float64
    current_votes_against::Float64
    quorum_required::Float64
    execution_eta::Union{DateTime, Nothing}
end

# Multi-Exchange Strategy State
mutable struct MultiExchangeState
    centralized_exchanges::Vector{CentralizedExchange}
    dex_protocols::Vector{DexProtocol}
    blockchain_networks::Vector{BlockchainNetwork}
    wallet_manager::MultiWalletManager
    bridge_configs::Vector{BridgeConfig}
    liquidity_positions::Vector{LiquidityPosition}
    governance_tokens::Vector{GovernanceToken}
    active_proposals::Vector{DAOProposal}
    cross_exchange_arbitrage::Bool
    auto_rebalancing::Bool
    governance_participation::Bool
    yield_farming::Bool
    flash_loan_arbitrage::Bool
    risk_limits::Dict{String, Float64}
    performance_tracking::Dict{String, Any}
end

# Initialize Multi-Exchange System
function create_multi_exchange_state()
    # Default blockchain networks
    ethereum = EthereumNetwork("https://mainnet.infura.io/v3/YOUR_KEY", 1, 20.0, 300000)
    solana = SolanaNetwork("https://api.mainnet-beta.solana.com", "mainnet-beta", "confirmed")
    bsc = BinanceSmartChain("https://bsc-dataseed.binance.org", 56, 5.0, 300000)
    arbitrum = ArbitrumNetwork("https://arb1.arbitrum.io/rpc", 42161, 0.1, 1000000)
    polygon = PolygonNetwork("https://polygon-rpc.com", 137, 30.0, 300000)
    
    # Default DEX protocols
    uniswap_v3 = UniswapV3(
        "0xE592427A0AEce92De3Edee1F18E0157C05861564",  # SwapRouter
        "0x1F98431c8aD98523631AE4a59f267346ea31F984",  # Factory
        "0xb27308f9F90D607463bb33eA1BeBb41C27CE5AB6",  # Quoter
        ethereum,
        [500, 3000, 10000]
    )
    
    raydium = RaydiumAMM("675kPX9MHTjS2zt1qfr1NYHuzeLXfQM9H24wFSUt1Mp8", solana, 0.0025)
    
    pancake = PancakeSwap(
        "0x10ED43C718714eb63d5aA57B78B54704E256024E",  # Router
        "0xcA143Ce32Fe78f1f7019d7d551a6402fC5350c73",  # Factory
        bsc,
        2500
    )
    
    # Default wallet configuration
    wallet_manager = MultiWalletManager(
        Dict{String, WalletConfig}(),
        "",
        String[]
    )
    
    return MultiExchangeState(
        CentralizedExchange[],
        DexProtocol[uniswap_v3, raydium, pancake],
        BlockchainNetwork[ethereum, solana, bsc, arbitrum, polygon],
        wallet_manager,
        BridgeConfig[],
        LiquidityPosition[],
        GovernanceToken[],
        DAOProposal[],
        false,  # cross_exchange_arbitrage
        false,  # auto_rebalancing
        false,  # governance_participation
        false,  # yield_farming
        false,  # flash_loan_arbitrage
        Dict{String, Float64}(
            "max_position_size" => 100000.0,
            "max_slippage" => 0.005,
            "max_gas_price" => 100.0,
            "min_profit_threshold" => 0.001
        ),
        Dict{String, Any}()
    )
end

# CEX Integration Functions
function authenticate_binance(exchange::Union{BinanceSpot, BinanceFutures})
    timestamp = string(Int(round(time() * 1000)))
    headers = Dict(
        "X-MBX-APIKEY" => exchange.api_key,
        "Content-Type" => "application/json"
    )
    return headers, timestamp
end

function authenticate_bybit(exchange::Union{BybitSpot, BybitFutures})
    timestamp = string(Int(round(time() * 1000)))
    headers = Dict(
        "X-BAPI-API-KEY" => exchange.api_key,
        "X-BAPI-TIMESTAMP" => timestamp,
        "Content-Type" => "application/json"
    )
    return headers, timestamp
end

function fetch_cex_orderbook(exchange::CentralizedExchange, symbol::String)
    if isa(exchange, BinanceFutures)
        url = "$(exchange.base_url)/fapi/v1/depth"
        params = Dict("symbol" => symbol, "limit" => 1000)
        
        headers, _ = authenticate_binance(exchange)
        
        try
            response = HTTP.get(url, headers=headers, query=params)
            data = JSON3.read(response.body)
            
            bids = [(parse(Float64, bid[1]), parse(Float64, bid[2])) for bid in data.bids]
            asks = [(parse(Float64, ask[1]), parse(Float64, ask[2])) for ask in data.asks]
            
            return bids, asks
        catch e
            println("Error fetching CEX orderbook: $e")
            return Tuple{Float64, Float64}[], Tuple{Float64, Float64}[]
        end
        
    elseif isa(exchange, BybitFutures)
        url = "$(exchange.base_url)/v5/market/orderbook"
        params = Dict("category" => "linear", "symbol" => symbol, "limit" => 200)
        
        headers, _ = authenticate_bybit(exchange)
        
        try
            response = HTTP.get(url, headers=headers, query=params)
            data = JSON3.read(response.body)
            
            if haskey(data, "result") && haskey(data.result, "b") && haskey(data.result, "a")
                bids = [(parse(Float64, bid[1]), parse(Float64, bid[2])) for bid in data.result.b]
                asks = [(parse(Float64, ask[1]), parse(Float64, ask[2])) for ask in data.result.a]
                return bids, asks
            end
        catch e
            println("Error fetching Bybit orderbook: $e")
        end
    end
    
    return Tuple{Float64, Float64}[], Tuple{Float64, Float64}[]
end

# DEX Integration Functions
function fetch_dex_price(protocol::UniswapV3, token0::String, token1::String, amount::Float64)
    # This would call the Uniswap V3 Quoter contract
    # For now, returning a mock price
    base_price = 2000.0 + rand() * 100  # Mock ETH price around $2000-2100
    slippage = 0.001 + rand() * 0.002   # 0.1-0.3% slippage
    
    return base_price * (1 + (rand() > 0.5 ? slippage : -slippage))
end

function fetch_dex_price(protocol::RaydiumAMM, token0::String, token1::String, amount::Float64)
    # This would call Raydium's AMM program on Solana
    # For now, returning a mock price
    base_price = 150.0 + rand() * 10    # Mock SOL price around $150-160
    slippage = 0.0005 + rand() * 0.001  # 0.05-0.15% slippage
    
    return base_price * (1 + (rand() > 0.5 ? slippage : -slippage))
end

function calculate_dex_liquidity(protocol::DexProtocol, token0::String, token1::String)
    # Mock liquidity calculation
    # In reality, this would query the actual pool reserves
    if isa(protocol, UniswapV3)
        return 1000000.0 + rand() * 5000000.0  # $1M - $6M TVL
    elseif isa(protocol, RaydiumAMM)
        return 500000.0 + rand() * 2000000.0   # $500K - $2.5M TVL
    else
        return 100000.0 + rand() * 1000000.0   # $100K - $1.1M TVL
    end
end

# Cross-Exchange Arbitrage Detection
function detect_arbitrage_opportunities(state::MultiExchangeState, symbol::String)
    opportunities = Dict{String, Any}[]
    
    # Collect prices from all exchanges
    cex_prices = Dict{String, Tuple{Float64, Float64}}()  # exchange => (bid, ask)
    dex_prices = Dict{String, Float64}()  # protocol => price
    
    # Fetch CEX prices
    for exchange in state.centralized_exchanges
        bids, asks = fetch_cex_orderbook(exchange, symbol)
        if !isempty(bids) && !isempty(asks)
            best_bid = bids[1][1]
            best_ask = asks[1][1]
            exchange_name = string(typeof(exchange))
            cex_prices[exchange_name] = (best_bid, best_ask)
        end
    end
    
    # Fetch DEX prices (mock implementation)
    for protocol in state.dex_protocols
        if isa(protocol, UniswapV3) && symbol == "ETHUSDT"
            price = fetch_dex_price(protocol, "ETH", "USDT", 1.0)
            dex_prices["UniswapV3"] = price
        elseif isa(protocol, RaydiumAMM) && symbol == "SOLUSDT"
            price = fetch_dex_price(protocol, "SOL", "USDT", 1.0)
            dex_prices["RaydiumAMM"] = price
        end
    end
    
    # Find arbitrage opportunities
    min_profit_threshold = state.risk_limits["min_profit_threshold"]
    
    # CEX-CEX arbitrage
    for (exchange1, (bid1, ask1)) in cex_prices
        for (exchange2, (bid2, ask2)) in cex_prices
            if exchange1 != exchange2
                # Buy on exchange2, sell on exchange1
                if bid1 > ask2
                    profit_rate = (bid1 - ask2) / ask2
                    if profit_rate > min_profit_threshold
                        push!(opportunities, Dict(
                            "type" => "cex_cex_arbitrage",
                            "buy_exchange" => exchange2,
                            "sell_exchange" => exchange1,
                            "buy_price" => ask2,
                            "sell_price" => bid1,
                            "profit_rate" => profit_rate,
                            "symbol" => symbol
                        ))
                    end
                end
            end
        end
    end
    
    # CEX-DEX arbitrage
    for (exchange, (bid, ask)) in cex_prices
        for (protocol, dex_price) in dex_prices
            # Buy CEX, sell DEX
            if dex_price > ask
                profit_rate = (dex_price - ask) / ask
                if profit_rate > min_profit_threshold
                    push!(opportunities, Dict(
                        "type" => "cex_dex_arbitrage",
                        "buy_exchange" => exchange,
                        "sell_protocol" => protocol,
                        "buy_price" => ask,
                        "sell_price" => dex_price,
                        "profit_rate" => profit_rate,
                        "symbol" => symbol
                    ))
                end
            end
            
            # Buy DEX, sell CEX
            if bid > dex_price
                profit_rate = (bid - dex_price) / dex_price
                if profit_rate > min_profit_threshold
                    push!(opportunities, Dict(
                        "type" => "dex_cex_arbitrage",
                        "buy_protocol" => protocol,
                        "sell_exchange" => exchange,
                        "buy_price" => dex_price,
                        "sell_price" => bid,
                        "profit_rate" => profit_rate,
                        "symbol" => symbol
                    ))
                end
            end
        end
    end
    
    # Sort by profit rate
    sort!(opportunities, by = x -> x["profit_rate"], rev=true)
    
    return opportunities
end

# Liquidity Mining and Yield Farming
function scan_yield_opportunities(state::MultiExchangeState)
    opportunities = Dict{String, Any}[]
    
    for protocol in state.dex_protocols
        if isa(protocol, UniswapV3)
            # Scan Uniswap V3 pools for high APR opportunities
            pools = [
                ("ETH", "USDC", 3000, 0.15),   # 15% APR
                ("ETH", "USDT", 500, 0.08),    # 8% APR
                ("WBTC", "ETH", 3000, 0.12),   # 12% APR
            ]
            
            for (token0, token1, fee_tier, apr) in pools
                tvl = calculate_dex_liquidity(protocol, token0, token1)
                
                push!(opportunities, Dict(
                    "protocol" => "UniswapV3",
                    "pool" => "$(token0)-$(token1)",
                    "fee_tier" => fee_tier,
                    "apr" => apr,
                    "tvl" => tvl,
                    "risk_level" => "medium",
                    "impermanent_loss_risk" => 0.05  # 5% estimated IL risk
                ))
            end
            
        elseif isa(protocol, RaydiumAMM)
            # Scan Raydium pools
            pools = [
                ("SOL", "USDC", 0.25),   # 25% APR
                ("SOL", "RAY", 0.35),    # 35% APR
                ("USDC", "USDT", 0.08),  # 8% APR
            ]
            
            for (token0, token1, apr) in pools
                tvl = calculate_dex_liquidity(protocol, token0, token1)
                
                push!(opportunities, Dict(
                    "protocol" => "RaydiumAMM",
                    "pool" => "$(token0)-$(token1)",
                    "apr" => apr,
                    "tvl" => tvl,
                    "risk_level" => "high",
                    "impermanent_loss_risk" => 0.08  # 8% estimated IL risk
                ))
            end
        end
    end
    
    # Sort by APR
    sort!(opportunities, by = x -> x["apr"], rev=true)
    
    return opportunities
end

# Governance Participation
function scan_governance_proposals(state::MultiExchangeState)
    active_proposals = DAOProposal[]
    
    # Mock governance proposals
    proposals = [
        DAOProposal(
            "PROP-001",
            "Increase Trading Fee to 0.05%",
            "Proposal to increase the base trading fee from 0.03% to 0.05% to increase protocol revenue",
            "parameter_change",
            now() + Day(3),
            150000.0,  # votes for
            50000.0,   # votes against
            100000.0,  # quorum required
            nothing
        ),
        DAOProposal(
            "PROP-002",
            "Treasury Diversification",
            "Allocate 20% of treasury to blue-chip DeFi protocols for yield generation",
            "treasury",
            now() + Day(7),
            80000.0,
            120000.0,
            100000.0,
            nothing
        )
    ]
    
    # Filter proposals based on governance tokens held
    for proposal in proposals
        # Check if we have voting power in this DAO
        relevant_tokens = [token for token in state.governance_tokens if token.voting_power > 0]
        
        if !isempty(relevant_tokens)
            push!(active_proposals, proposal)
        end
    end
    
    return active_proposals
end

function execute_governance_vote(state::MultiExchangeState, proposal_id::String, vote::String, amount::Float64)
    # Mock governance voting execution
    println("Executing vote on proposal $proposal_id: $vote with $amount voting power")
    
    # In reality, this would:
    # 1. Sign the vote transaction
    # 2. Submit to the governance contract
    # 3. Update local tracking
    
    return Dict(
        "tx_hash" => "0x" * randstring(64),
        "proposal_id" => proposal_id,
        "vote" => vote,
        "voting_power" => amount,
        "timestamp" => now()
    )
end

# Portfolio Rebalancing
function calculate_optimal_allocation(state::MultiExchangeState, target_allocation::Dict{String, Float64})
    current_allocation = Dict{String, Float64}()
    total_value = 0.0
    
    # Calculate current portfolio value
    for (token, target_pct) in target_allocation
        # Mock current holdings
        current_value = 1000.0 + rand() * 5000.0  # $1K - $6K per token
        current_allocation[token] = current_value
        total_value += current_value
    end
    
    # Convert to percentages
    for (token, value) in current_allocation
        current_allocation[token] = value / total_value
    end
    
    # Calculate rebalancing trades needed
    rebalancing_trades = Dict{String, Float64}()
    
    for (token, target_pct) in target_allocation
        current_pct = get(current_allocation, token, 0.0)
        difference = target_pct - current_pct
        
        if abs(difference) > 0.05  # Only rebalance if >5% off target
            rebalancing_trades[token] = difference * total_value
        end
    end
    
    return rebalancing_trades, current_allocation
end

# Risk Management for Multi-Exchange
function assess_multi_exchange_risk(state::MultiExchangeState)
    risk_metrics = Dict{String, Float64}()
    
    # Concentration risk
    exchange_exposure = Dict{String, Float64}()
    total_exposure = 0.0
    
    for exchange in state.centralized_exchanges
        exposure = 10000.0 + rand() * 50000.0  # Mock exposure $10K-$60K
        exchange_name = string(typeof(exchange))
        exchange_exposure[exchange_name] = exposure
        total_exposure += exposure
    end
    
    # Calculate Herfindahl-Hirschman Index for concentration
    hhi = sum([(exposure / total_exposure)^2 for exposure in values(exchange_exposure)])
    risk_metrics["concentration_risk"] = hhi
    
    # Counterparty risk (CEX vs DEX allocation)
    cex_exposure = sum(values(exchange_exposure))
    dex_exposure = 5000.0 + rand() * 20000.0  # Mock DEX exposure
    total_crypto_exposure = cex_exposure + dex_exposure
    
    risk_metrics["cex_exposure_ratio"] = cex_exposure / total_crypto_exposure
    risk_metrics["dex_exposure_ratio"] = dex_exposure / total_crypto_exposure
    
    # Liquidity risk
    avg_daily_volume = 1000000.0  # Mock $1M daily volume
    position_size = total_exposure
    risk_metrics["liquidity_risk"] = position_size / avg_daily_volume
    
    # Bridge/Cross-chain risk
    bridge_exposure = length(state.bridge_configs) * 1000.0  # Mock bridge exposure
    risk_metrics["bridge_risk"] = bridge_exposure / total_exposure
    
    # Smart contract risk (DEX protocols)
    protocol_count = length(state.dex_protocols)
    risk_metrics["smart_contract_risk"] = min(1.0, protocol_count * 0.1)  # 10% risk per protocol
    
    return risk_metrics
end

# Main Multi-Exchange Strategy Handler
function handle_multi_exchange_action(req::ActionRequest, state::MultiExchangeState)
    action = req.action_type
    
    if action == "scan_arbitrage"
        symbols = get(req.parameters, "symbols", ["ETHUSDT", "BTCUSDT"])
        all_opportunities = Dict{String, Vector{Dict{String, Any}}}()
        
        for symbol in symbols
            opportunities = detect_arbitrage_opportunities(state, symbol)
            all_opportunities[symbol] = opportunities
        end
        
        return ActionResponse(
            req.request_id,
            "success",
            Dict{String, Any}("arbitrage_opportunities" => all_opportunities)
        )
        
    elseif action == "scan_yield_opportunities"
        opportunities = scan_yield_opportunities(state)
        
        return ActionResponse(
            req.request_id,
            "success",
            Dict{String, Any}("yield_opportunities" => opportunities)
        )
        
    elseif action == "scan_governance"
        proposals = scan_governance_proposals(state)
        
        return ActionResponse(
            req.request_id,
            "success",
            Dict{String, Any}("governance_proposals" => proposals)
        )
        
    elseif action == "execute_vote"
        proposal_id = get(req.parameters, "proposal_id", "")
        vote = get(req.parameters, "vote", "for")  # "for", "against", "abstain"
        amount = get(req.parameters, "amount", 0.0)
        
        result = execute_governance_vote(state, proposal_id, vote, amount)
        
        return ActionResponse(
            req.request_id,
            "success",
            Dict{String, Any}("vote_result" => result)
        )
        
    elseif action == "rebalance_portfolio"
        target_allocation = get(req.parameters, "target_allocation", Dict{String, Float64}())
        
        trades, current_allocation = calculate_optimal_allocation(state, target_allocation)
        
        return ActionResponse(
            req.request_id,
            "success",
            Dict{String, Any}(
                "rebalancing_trades" => trades,
                "current_allocation" => current_allocation,
                "target_allocation" => target_allocation
            )
        )
        
    elseif action == "assess_risk"
        risk_metrics = assess_multi_exchange_risk(state)
        
        return ActionResponse(
            req.request_id,
            "success",
            Dict{String, Any}("risk_metrics" => risk_metrics)
        )
        
    elseif action == "add_exchange"
        exchange_type = get(req.parameters, "exchange_type", "")
        config = get(req.parameters, "config", Dict{String, Any}())
        
        if exchange_type == "binance_futures"
            exchange = BinanceFutures(
                get(config, "base_url", "https://testnet.binancefuture.com"),
                get(config, "api_key", ""),
                get(config, "api_secret", ""),
                get(config, "testnet", true)
            )
            push!(state.centralized_exchanges, exchange)
        elseif exchange_type == "bybit_futures"
            exchange = BybitFutures(
                get(config, "base_url", "https://api-testnet.bybit.com"),
                get(config, "api_key", ""),
                get(config, "api_secret", ""),
                get(config, "testnet", true)
            )
            push!(state.centralized_exchanges, exchange)
        end
        
        return ActionResponse(
            req.request_id,
            "success",
            Dict{String, Any}("message" => "Exchange added successfully")
        )
        
    else
        return ActionResponse(
            req.request_id,
            "error",
            Dict{String, Any}("error" => "Unknown action: $action")
        )
    end
end

# Strategy specification for registration
const STRATEGY_MULTI_EXCHANGE_SPECIFICATION = StrategySpecification(
    StrategyMetadata(
        "multi_exchange",
        "Multi-Exchange & DeFi Integration",
        "Advanced multi-exchange arbitrage, yield farming, and governance participation",
        "1.0.0",
        ["multi_exchange", "defi", "arbitrage", "yield_farming", "governance", "cross_chain"]
    ),
    function(req::ActionRequest)
        # Initialize state if not exists
        if !haskey(req.parameters, "state")
            state = create_multi_exchange_state()
        else
            state = req.parameters["state"]
        end
        
        return handle_multi_exchange_action(req, state)
    end
)
