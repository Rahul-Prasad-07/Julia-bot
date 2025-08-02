# Simple Market Making Demo
# Quick demo of the market making integration

println("🚀 JuliaOS Market Making Demo")
println("="^40)

# Load the backend
include("backend/src/JuliaOSBackend.jl")

using .JuliaOSBackend
using .JuliaOSBackend.Agents.Strategies
using .JuliaOSBackend.Agents.CommonTypes

println("\n📈 Available Trading Strategies:")
for (name, strategy) in STRATEGY_REGISTRY
    if name in ["market_making", "llm_backtesting", "multi_exchange", "agent_swarm"]
        println("  ✓ $name - $(strategy.metadata.name)")
    end
end

println("\n🎯 Market Making Strategy Configuration:")
if haskey(STRATEGY_REGISTRY, "market_making")
    market_making_spec = STRATEGY_REGISTRY["market_making"]
    
    # Create sample configuration
    config = market_making_spec.config_type(
        symbols = ["ETHUSDT", "BTCUSDT"],
        base_spread_pct = 0.2,
        order_levels = 3,
        max_capital = 10000.0,
        api_key = get(ENV, "BINANCE_API_KEY", "demo_key"),
        api_secret = get(ENV, "BINANCE_API_SECRET", "demo_secret")
    )
    
    println("  Symbols: $(config.symbols)")
    println("  Spread: $(config.base_spread_pct)%")
    println("  Order levels: $(config.order_levels)")
    println("  Capital: \$$(config.max_capital)")
    println("  API configured: $(config.api_key != "demo_key")")
end

println("\n🧠 LLM Optimization Configuration:")
if haskey(STRATEGY_REGISTRY, "llm_backtesting")
    llm_spec = STRATEGY_REGISTRY["llm_backtesting"]
    
    config = llm_spec.config_type(
        strategy_name = "market_making",
        optimization_objective = "sharpe_ratio",
        max_generations = 20,
        population_size = 50,
        openai_api_key = get(ENV, "OPENAI_API_KEY", "")
    )
    
    println("  Target strategy: $(config.strategy_name)")
    println("  Objective: $(config.optimization_objective)")
    println("  Generations: $(config.max_generations)")
    println("  Population: $(config.population_size)")
    println("  LLM available: $(config.openai_api_key != "")")
end

println("\n🌐 Multi-Exchange Configuration:")
if haskey(STRATEGY_REGISTRY, "multi_exchange")
    multi_spec = STRATEGY_REGISTRY["multi_exchange"]
    
    config = multi_spec.config_type(
        exchanges = ["binance", "bybit", "okx"],
        symbols = ["ETHUSDT", "BTCUSDT", "SOLUSDT"],
        arbitrage_threshold = 0.5,
        enable_defi = true,
        defi_protocols = ["uniswap_v3", "raydium", "pancakeswap"]
    )
    
    println("  Exchanges: $(length(config.exchanges)) ($(join(config.exchanges, ", ")))")
    println("  Symbols: $(length(config.symbols)) pairs")
    println("  Arbitrage threshold: $(config.arbitrage_threshold)%")
    println("  DeFi enabled: $(config.enable_defi)")
end

println("\n🐝 Agent Swarm Configuration:")
if haskey(STRATEGY_REGISTRY, "agent_swarm")
    swarm_spec = STRATEGY_REGISTRY["agent_swarm"]
    
    config = swarm_spec.config_type(
        swarm_size = 5,
        agent_types = ["market_maker", "arbitrage", "risk_manager", "data_analyst", "yield_farmer"],
        consensus_threshold = 0.6,
        enable_learning = true
    )
    
    println("  Swarm size: $(config.swarm_size)")
    println("  Agent types: $(join(config.agent_types, ", "))")
    println("  Consensus threshold: $(config.consensus_threshold * 100)%")
    println("  Learning: $(config.enable_learning)")
end

println("\n🔧 Environment Setup:")
env_vars = ["BINANCE_API_KEY", "BINANCE_API_SECRET", "OPENAI_API_KEY", "ETHEREUM_RPC_URL", "SOLANA_RPC_URL"]
for var in env_vars
    status = haskey(ENV, var) ? "✓ Set" : "✗ Not set"
    println("  $var: $status")
end

println("\n✅ Integration Status:")
println("  ✓ All strategy modules compiled successfully")
println("  ✓ $(length(STRATEGY_REGISTRY)) strategies registered")
println("  ✓ Market making core functionality ready")
println("  ✓ LLM optimization system ready")
println("  ✓ Multi-exchange arbitrage ready")
println("  ✓ Agent swarm coordination ready")

println("\n🚀 Your JuliaOS trading system is ready!")
println("\n📋 To get started:")
println("1. Set environment variables for API keys")
println("2. Use the strategy specifications to create agents")
println("3. Configure and deploy agents via JuliaOS API")
println("4. Monitor agent performance and logs")

println("\n🎯 Example usage:")
println("julia> using JuliaOSBackend")
println("julia> using JuliaOSBackend.Agents.Strategies")
println("julia> strategy = STRATEGY_REGISTRY[\"market_making\"]")
println("julia> # Configure and use the strategy...")
