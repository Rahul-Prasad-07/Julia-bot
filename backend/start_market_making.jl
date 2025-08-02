# Market Making Launch Script for Binance Testnet
# Uses environment variables from .env file

using Pkg
Pkg.activate(".")

# Load environment variables
println("🔧 Loading environment variables...")
try
    using DotEnv
    DotEnv.config()
    println("✅ DotEnv loaded successfully")
catch e
    println("⚠️ DotEnv not available, loading manually...")
end

# Manual .env parsing as fallback (handles quoted values better)
try
    env_content = read(".env", String)
    lines = split(env_content, '\n')
    for line in lines
        line = strip(line)
        if !isempty(line) && !startswith(line, "#") && contains(line, "=")
            key_value = split(line, '=', limit=2)
            if length(key_value) == 2
                key = strip(key_value[1])
                value = strip(key_value[2])
                # Remove quotes if present
                if (startswith(value, '"') && endswith(value, '"')) || 
                   (startswith(value, '\'') && endswith(value, '\''))
                    value = value[2:end-1]
                end
                ENV[key] = value
            end
        end
    end
    println("✅ Environment variables processed")
catch e2
    println("❌ Failed to load .env file: $e2")
end

# Import JuliaOS components
using JuliaOSBackend
using JuliaOSBackend.Agents.Strategies
using JuliaOSBackend.Agents.CommonTypes
import JuliaOSBackend.Agents.CommonTypes: AgentContext

println("🚀 Starting JuliaOS Market Making System")
println("="^50)

# Verify environment setup
println("\n🔧 Environment Configuration:")
binance_key = get(ENV, "BINANCE_API_KEY", "")
binance_secret = get(ENV, "BINANCE_API_SECRET", "")
openai_key = get(ENV, "OPENAI_API_KEY", "")

if isempty(binance_key) || isempty(binance_secret)
    println("❌ Error: Binance API credentials not found in environment!")
    println("Please check your .env file contains:")
    println("  BINANCE_API_KEY=your_key")
    println("  BINANCE_API_SECRET=your_secret")
    exit(1)
end

println("  Binance API Key: $(binance_key[1:min(8,length(binance_key))])...$(binance_key[max(1,end-4):end]) ($(length(binance_key)) chars)")
println("  Binance Secret: $(binance_secret[1:min(8,length(binance_secret))])...$(binance_secret[max(1,end-4):end]) ($(length(binance_secret)) chars)")
println("  OpenAI Key: $(isempty(openai_key) ? "❌ Not configured" : "✅ Configured")")

# Get market making strategy
if !haskey(STRATEGY_REGISTRY, "market_making")
    error("❌ Market making strategy not found!")
end

strategy_spec = STRATEGY_REGISTRY["market_making"]
println("\n✅ Market Making Strategy loaded: $(strategy_spec.metadata.name)")

# Create configuration for Binance testnet
config = strategy_spec.config_type(
    symbols = ["ETHUSDT"],  # Popular testnet pairs
    base_spread_pct = 0.2,                        # 0.2% spread
    order_levels = 3,                             # 3 order levels
    max_capital = 1000.0,                         # $1000 max capital
    leverage = 10,                                # 10x leverage
    api_key = binance_key,
    api_secret = binance_secret,
    max_drawdown = 0.15,                         # 15% max drawdown
    risk_check_interval = 30,                    # Check risk every 30s
    enable_llm_optimization = !isempty(openai_key),
    llm_model = "gpt-4"
)

println("\n📊 Trading Configuration:")
println("  Symbols: $(config.symbols)")
println("  Spread: $(config.base_spread_pct)%")
println("  Order Levels: $(config.order_levels)")
println("  Max Capital: \$$(config.max_capital)")
println("  Leverage: $(config.leverage)x")
println("  Max Drawdown: $(config.max_drawdown * 100)%")
println("  LLM Optimization: $(config.enable_llm_optimization)")

# Create agent context
context = AgentContext([], [])

# Initialize strategy
println("\n🔄 Initializing Market Making Strategy...")
try
    if strategy_spec.initialize !== nothing
        strategy_spec.initialize(config, context)
        println("✅ Strategy initialization successful")
        
        # Show initialization logs
        if !isempty(context.logs)
            println("\n📋 Initialization Logs:")
            for log in context.logs
                println("  $log")
            end
        end
    end
catch e
    println("❌ Initialization failed: $e")
    exit(1)
end

# Function to execute trading action
function execute_trading_action(action::String)
    try
        input = strategy_spec.input_type(action=action)
        strategy_spec.run(config, context, input)
        
        # Show recent logs
        if !isempty(context.logs)
            recent_logs = context.logs[max(1, length(context.logs)-10):end]
            for log in recent_logs[end-min(5, length(recent_logs)-1):end]
                println("  $log")
            end
        end
        return true
    catch e
        println("❌ Error executing $action: $e")
        return false
    end
end

# Interactive trading menu
function trading_menu()
    while true
        println("\n" * "="^50)
        println("🎯 JuliaOS Market Making Control Panel")
        println("="^50)
        println("1. 📈 Start Trading")
        println("2. 📊 Check Status")
        println("3. ⏹️  Stop Trading")
        println("4. 🧠 Run LLM Optimization (if available)")
        println("5. 🌐 Scan Multi-Exchange Arbitrage")
        println("6. 🐝 Deploy Agent Swarm")
        println("7. 📋 Show Recent Logs")
        println("8. ❌ Exit")
        println("="^50)
        
        print("Enter your choice (1-8): ")
        choice = readline()
        
        if choice == "1"
            println("\n🚀 Starting Market Making...")
            if execute_trading_action("start_trading")
                println("✅ Market making started successfully!")
            end
            
        elseif choice == "2"
            println("\n📊 Checking Status...")
            execute_trading_action("status_check")
            
        elseif choice == "3"
            println("\n⏹️ Stopping Trading...")
            if execute_trading_action("stop_trading")
                println("✅ Trading stopped successfully!")
            end
            
        elseif choice == "4"
            if !config.enable_llm_optimization
                println("❌ LLM optimization not available (OpenAI key not configured)")
            else
                println("\n🧠 Running LLM Optimization...")
                try
                    llm_strategy = STRATEGY_REGISTRY["llm_backtesting"]
                    llm_config = llm_strategy.config_type(
                        strategy_name = "market_making",
                        optimization_objective = "sharpe_ratio",
                        max_generations = 10,
                        population_size = 20,
                        openai_api_key = openai_key
                    )
                    llm_context = AgentContext([], [])
                    
                    if llm_strategy.initialize !== nothing
                        llm_strategy.initialize(llm_config, llm_context)
                    end
                    
                    llm_input = llm_strategy.input_type(action="start_optimization")
                    llm_strategy.run(llm_config, llm_context, llm_input)
                    
                    println("✅ LLM optimization completed!")
                    
                    # Show optimization results
                    if !isempty(llm_context.logs)
                        recent_logs = llm_context.logs[max(1, length(llm_context.logs)-8):end]
                        for log in recent_logs
                            println("  $log")
                        end
                    end
                catch e
                    println("❌ LLM optimization failed: $e")
                end
            end
            
        elseif choice == "5"
            println("\n🌐 Scanning Multi-Exchange Arbitrage...")
            try
                multi_strategy = STRATEGY_REGISTRY["multi_exchange"]
                multi_config = multi_strategy.config_type(
                    exchanges = ["binance", "bybit"],
                    symbols = config.symbols,
                    arbitrage_threshold = 0.3,
                    enable_defi = false  # Disable DeFi for testnet
                )
                multi_context = AgentContext([], [])
                
                if multi_strategy.initialize !== nothing
                    multi_strategy.initialize(multi_config, multi_context)
                end
                
                multi_input = multi_strategy.input_type(action="scan_arbitrage")
                multi_strategy.run(multi_config, multi_context, multi_input)
                
                println("✅ Arbitrage scan completed!")
                
                # Show scan results
                if !isempty(multi_context.logs)
                    recent_logs = multi_context.logs[max(1, length(multi_context.logs)-6):end]
                    for log in recent_logs
                        println("  $log")
                    end
                end
            catch e
                println("❌ Arbitrage scan failed: $e")
            end
            
        elseif choice == "6"
            println("\n🐝 Deploying Agent Swarm...")
            try
                swarm_strategy = STRATEGY_REGISTRY["agent_swarm"]
                swarm_config = swarm_strategy.config_type(
                    swarm_size = 3,
                    agent_types = ["market_maker", "arbitrage", "risk_manager"],
                    consensus_threshold = 0.6,
                    enable_learning = true
                )
                swarm_context = AgentContext([], [])
                
                if swarm_strategy.initialize !== nothing
                    swarm_strategy.initialize(swarm_config, swarm_context)
                end
                
                swarm_input = swarm_strategy.input_type(action="coordinate_agents")
                swarm_strategy.run(swarm_config, swarm_context, swarm_input)
                
                println("✅ Agent swarm deployed!")
                
                # Show swarm results
                if !isempty(swarm_context.logs)
                    recent_logs = swarm_context.logs[max(1, length(swarm_context.logs)-5):end]
                    for log in recent_logs
                        println("  $log")
                    end
                end
            catch e
                println("❌ Agent swarm deployment failed: $e")
            end
            
        elseif choice == "7"
            println("\n📋 Recent Logs (last 15 entries):")
            if !isempty(context.logs)
                recent_logs = context.logs[max(1, length(context.logs)-14):end]
                for (i, log) in enumerate(recent_logs)
                    println("  $i. $log")
                end
            else
                println("  No logs available")
            end
            
        elseif choice == "8"
            println("\n👋 Shutting down market making system...")
            execute_trading_action("stop_trading")
            println("✅ System shutdown complete. Goodbye!")
            break
            
        else
            println("❌ Invalid choice. Please enter 1-8.")
        end
        
        println("\nPress Enter to continue...")
        readline()
    end
end

# Start the system
println("\n🎯 System ready! Starting interactive control panel...")
println("💡 Tip: Start with option 2 (Check Status) to verify connection")

trading_menu()
