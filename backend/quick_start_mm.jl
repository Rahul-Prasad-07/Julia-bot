# Quick Start Market Making - Binance Testnet
# Simple script to immediately start market making

using Pkg
Pkg.activate(".")

using DotEnv
DotEnv.config()

using JuliaOSBackend.Agents.Strategies
using JuliaOSBackend.Agents.CommonTypes

println("🚀 Quick Start: Binance Testnet Market Making")
println("="^45)

# Get environment variables
binance_key = ENV["BINANCE_API_KEY"]
binance_secret = ENV["BINANCE_API_SECRET"]
openai_key = get(ENV, "OPENAI_API_KEY", "")

println("✅ Binance API configured")
println("$(isempty(openai_key) ? "⚠️" : "✅") OpenAI API $(isempty(openai_key) ? "not configured" : "configured")")

# Get strategy
strategy = STRATEGY_REGISTRY["market_making"]

# Create configuration
config = strategy.config_type(
    symbols = ["ETHUSDT", "BTCUSDT"],
    base_spread_pct = 0.25,      # Slightly wider spread for safety
    order_levels = 2,            # Start with 2 levels
    max_capital = 500.0,         # Conservative starting capital
    leverage = 5,                # Conservative leverage
    api_key = binance_key,
    api_secret = binance_secret,
    max_drawdown = 0.10,         # 10% max drawdown
    risk_check_interval = 60     # Check every minute
)

# Create context and initialize
context = AgentContext([], [])
strategy.initialize(config, context)

println("\n📊 Configuration:")
println("  Symbols: $(config.symbols)")
println("  Spread: $(config.base_spread_pct)%")
println("  Capital: \$$(config.max_capital)")
println("  Leverage: $(config.leverage)x")

println("\n🔄 Running initial status check...")
input = strategy.input_type(action="status_check")
strategy.run(config, context, input)

println("\n📋 System Status:")
for log in context.logs[max(1, length(context.logs)-5):end]
    println("  $log")
end

println("\n🎯 Ready to trade! Available actions:")
println("  1. Start Trading: julia> input = strategy.input_type(action=\"start_trading\")")
println("  2. Stop Trading:  julia> input = strategy.input_type(action=\"stop_trading\")")
println("  3. Check Status:  julia> input = strategy.input_type(action=\"status_check\")")
println("\n💡 To execute: julia> strategy.run(config, context, input)")

println("\n⚠️  TESTNET REMINDER: You're using Binance testnet - no real money at risk!")
println("🚀 Your market making bot is ready for testing!")
