# Enhanced Market Making Launch Script with RL/ML Integration
# Includes Reinforcement Learning, LLM Optimization, and Backtesting

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

# Manual .env parsing as fallback
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

# Import PnL tracking function for comprehensive reports
try
    using JuliaOSBackend.Agents.Strategies: generate_performance_report
catch e
    println("⚠️ PnL tracking functions not yet available - will be accessible after strategy initialization")
end

println("🚀 Starting Enhanced JuliaOS Market Making System")
println("="^60)

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

# Available strategies
available_strategies = ["market_making", "rl_market_making", "llm_backtesting", "multi_exchange", "agent_swarm"]
println("\n📋 Available Strategies:")
for (i, strategy) in enumerate(available_strategies)
    has_strategy = haskey(STRATEGY_REGISTRY, strategy)
    status = has_strategy ? "✅" : "❌"
    println("  $i. $status $strategy")
end

# Strategy selection menu
function select_strategy()
    println("\n" * "="^60)
    println("🎯 Strategy Selection Menu")
    println("="^60)
    println("1. 📈 Basic Market Making (Original)")
    println("2. 🤖 RL-Enhanced Market Making (Machine Learning)")
    println("3. 🧠 LLM Backtesting & Optimization")
    println("4. 🌐 Multi-Exchange Arbitrage")
    println("5. 🐝 Agent Swarm Coordination")
    println("6. 🔄 Compare All Strategies")
    println("7. ❌ Exit")
    println("="^60)
    
    print("Select strategy (1-7): ")
    choice = readline()
    
    if choice == "1"
        return "market_making"
    elseif choice == "2"
        return "rl_market_making"
    elseif choice == "3"
        return "llm_backtesting"
    elseif choice == "4"
        return "multi_exchange"
    elseif choice == "5"
        return "agent_swarm"
    elseif choice == "6"
        return "compare_all"
    elseif choice == "7"
        println("👋 Goodbye!")
        exit(0)
    else
        println("❌ Invalid choice. Please try again.")
        return select_strategy()
    end
end

# Create strategy configuration
function create_strategy_config(strategy_name::String)
    if strategy_name == "market_making"
        if !haskey(STRATEGY_REGISTRY, "market_making")
            error("❌ Market making strategy not found!")
        end
        
        strategy_spec = STRATEGY_REGISTRY["market_making"]
        return strategy_spec.config_type(
            symbols = ["ETHUSDT"],
            base_spread_pct = 0.2,
            order_levels = 3,
            max_capital = 1000.0,
            leverage = 10,
            api_key = binance_key,
            api_secret = binance_secret,
            max_drawdown = 0.15,
            risk_check_interval = 30,
            enable_llm_optimization = !isempty(openai_key),
            llm_model = "gpt-4"
        ), strategy_spec
        
    elseif strategy_name == "rl_market_making"
        if !haskey(STRATEGY_REGISTRY, "rl_market_making")
            error("❌ RL Market making strategy not found!")
        end
        
        strategy_spec = STRATEGY_REGISTRY["rl_market_making"]
        return strategy_spec.config_type(
            symbols = ["ETHUSDT"],
            base_spread_pct = 0.15,
            order_levels = 3,
            max_capital = 1000.0,
            leverage = 10,
            api_key = binance_key,
            api_secret = binance_secret,
            max_drawdown = 0.20,
            risk_check_interval = 30,
            
            # RL Parameters
            enable_rl_learning = true,
            learning_rate = 0.01,
            exploration_rate = 0.1,
            reward_function = "sharpe_ratio",
            memory_size = 1000,
            batch_size = 32,
            update_frequency = 100,
            
            # LLM Integration
            enable_llm_optimization = !isempty(openai_key),
            llm_model = "gpt-4",
            openai_api_key = openai_key,
            llm_update_frequency = 1000,
            
            # Backtesting
            backtest_enabled = true,
            backtest_days = 30,
            validation_split = 0.2,
            walk_forward_periods = 5
        ), strategy_spec
        
    elseif strategy_name == "llm_backtesting"
        if !haskey(STRATEGY_REGISTRY, "llm_backtesting")
            error("❌ LLM backtesting strategy not found!")
        end
        
        strategy_spec = STRATEGY_REGISTRY["llm_backtesting"]
        return strategy_spec.config_type(
            strategy_name = "market_making",
            optimization_objective = "sharpe_ratio",
            max_generations = 10,
            population_size = 20,
            llm_model = "gpt-4",
            openai_api_key = openai_key,
            backtest_start_date = "2024-01-01",
            backtest_end_date = "2024-12-31",
            initial_capital = 10000.0
        ), strategy_spec
        
    else
        error("❌ Unknown strategy: $strategy_name")
    end
end

# Enhanced trading menu for RL strategy
function rl_trading_menu(config, strategy_spec, context)
    while true
        println("\n" * "="^60)
        println("🤖 RL-Enhanced Market Making Control Panel (24/7)")
        println("="^60)
        println("1. 📈 Start 24/7 RL Trading (Cancel-Recreate Strategy)")
        println("2. 📊 Check Real-time Status (Trading + Open Orders)")
        println("3. ⏹️  Stop 24/7 Trading")
        println("4. 🚨 EMERGENCY: Cancel ALL Orders (Fix Margin Issues)")
        println("5. 🎯 Run Backtest")
        println("6. 🧠 Optimize Parameters (LLM)")
        println("7. 🏃 Train RL Model")
        println("8. 📋 Show Recent Logs")
        println("9. 📈 Performance Analytics")
        println("10. ⚙️  Adjust Parameters")
        println("11. 🧪 Test Mode (Single Iteration)")
        println("12. 💰 Show Comprehensive PnL Report")
        println("13. ❌ Exit")
        println("="^60)
        println("💡 24/7 Mode: Cancels ALL orders → Creates fresh orders every 30s")
        println("💡 Tip: Trading continues until manually stopped with option 3!")
        println("🚨 Emergency: Use option 4 if you have margin issues from stuck orders!")
        println("="^60)
        
        print("Enter your choice (1-13): ")
        choice = readline()
        
        if choice == "1"
            println("\n🤖 Starting 24/7 RL-Enhanced Market Making...")
            println("⚠️  This will start CONTINUOUS 24/7 trading with order refresh every 30s!")
            println("⚠️  Each cycle: Cancel ALL orders → Create fresh orders → Wait 30s → Repeat")
            println("⚠️  This ensures maximum PnL by adapting to market conditions!")
            println("💡 The trading will run 24/7 until you manually stop it with option 3!")
            print("Are you sure you want to start 24/7 trading? (y/N): ")
            confirm = readline()
            
            if lowercase(confirm) == "y" || lowercase(confirm) == "yes"
                input = strategy_spec.input_type(action="start_rl_trading", learning_mode=true)
                strategy_spec.run(config, context, input)
                println("\n✅ 24/7 RL continuous trading started!")
                println("💡 Trading is now running 24/7 automatically. You can:")
                println("   📊 Use option 2 to check real-time status and open orders")
                println("   ⏹️ Use option 3 to stop 24/7 trading") 
                println("   📋 Use option 7 to view recent logs")
                println("   📈 Continue using other menu options while trading runs")
            else
                println("❌ Operation cancelled.")
            end
            
        elseif choice == "2"
            println("\n📊 Checking 24/7 RL Trading Status...")
            input = strategy_spec.input_type(action="status_check")
            strategy_spec.run(config, context, input)
            
            # Show last few logs for immediate feedback
            if !isempty(context.logs)
                println("\n🔍 Live Status Details:")
                recent_logs = context.logs[max(1, length(context.logs)-20):end]
                for log in recent_logs
                    println("  $log")
                end
            end
            
        elseif choice == "3"
            println("\n⏹️ Stopping 24/7 RL Trading...")
            input = strategy_spec.input_type(action="stop_trading")
            strategy_spec.run(config, context, input)
            
        elseif choice == "4"
            println("\n🚨 EMERGENCY ORDER CLEANUP")
            println("⚠️  This will IMMEDIATELY cancel ALL open orders for all symbols!")
            println("⚠️  This should fix 'Margin insufficient' errors caused by stuck orders!")
            println("💡 Recommended when you see many open orders but system shows 'No open orders'")
            print("Are you sure you want to cancel ALL orders? (y/N): ")
            confirm = readline()
            
            if lowercase(confirm) == "y" || lowercase(confirm) == "yes"
                input = strategy_spec.input_type(action="emergency_cleanup")
                strategy_spec.run(config, context, input)
                println("\n✅ Emergency cleanup completed!")
                println("💡 Check option 2 to verify orders were cancelled")
                println("💡 Margin should now be available for new trades")
            else
                println("❌ Emergency cleanup cancelled.")
            end
            
        elseif choice == "5"
            println("\n🎯 Running Comprehensive Backtest...")
            input = strategy_spec.input_type(action="run_backtest")
            strategy_spec.run(config, context, input)
            
        elseif choice == "6"
            if !config.enable_llm_optimization
                println("❌ LLM optimization not available (OpenAI key not configured)")
            else
                println("\n🧠 Running LLM Parameter Optimization...")
                input = strategy_spec.input_type(action="optimize_parameters")
                strategy_spec.run(config, context, input)
            end
            
        elseif choice == "7"
            println("\n🏃 Training RL Model...")
            input = strategy_spec.input_type(action="train_rl_model")
            strategy_spec.run(config, context, input)
            
        elseif choice == "8"
            println("\n📋 Recent Trading Logs:")
            println("="^50)
            if !isempty(context.logs)
                # Show last 30 entries for better context
                recent_logs = context.logs[max(1, length(context.logs)-29):end]
                println("Showing last $(length(recent_logs)) log entries:")
                println()
                
                for (i, log) in enumerate(recent_logs)
                    # Add timestamp-style numbering
                    log_num = length(context.logs) - length(recent_logs) + i
                    println("[$log_num] $log")
                end
                
                if length(context.logs) > 30
                    println("\n📝 Note: Showing last 30 of $(length(context.logs)) total log entries")
                end
            else
                println("  No logs available yet")
                println("  Start trading with option 1 to generate logs")
            end
            println("="^50)
            
        elseif choice == "9"
            println("\n📈 Performance Analytics:")
            println("  RL Learning Rate: $(config.learning_rate)")
            println("  Exploration Rate: $(config.exploration_rate)")
            println("  Memory Size: $(config.memory_size)")
            println("  Update Frequency: $(config.update_frequency)")
            println("  Reward Function: $(config.reward_function)")
            println("  Backtest Days: $(config.backtest_days)")
            
        elseif choice == "10"
            println("\n⚙️ Current Parameters:")
            println("  Spread: $(config.base_spread_pct)%")
            println("  Order Levels: $(config.order_levels)")
            println("  Max Capital: \$$(config.max_capital)")
            println("  Learning Rate: $(config.learning_rate)")
            print("Enter new spread % (or press Enter to skip): ")
            new_spread = readline()
            if !isempty(new_spread)
                try
                    config.base_spread_pct = parse(Float64, new_spread)
                    println("✅ Updated spread to $(config.base_spread_pct)%")
                catch
                    println("❌ Invalid spread value")
                end
            end
            
        elseif choice == "11"
            println("\n🧪 Running Test Mode (Single Iteration)...")
            input = strategy_spec.input_type(action="start_rl_trading", learning_mode=false)
            strategy_spec.run(config, context, input)
            
        elseif choice == "12"
            println("\n💰 Comprehensive Trading Performance Report")
            println("="^60)
            
            try
                # Generate the comprehensive report
                performance_report = generate_performance_report()
                println(performance_report)
                
            catch e
                println("❌ Error generating PnL report: $e")
                println("💡 Make sure you have started trading at least once to initialize PnL tracking")
                println("💡 If PnL tracking is not initialized, start trading with option 1 first")
            end
            
        elseif choice == "13"
            println("\n👋 Exiting RL trading system...")
            break
            
        else
            println("❌ Invalid choice. Please enter 1-13.")
        end
        
        println("\nPress Enter to continue...")
        readline()
    end
end

# Strategy comparison function
function compare_strategies()
    println("\n🔄 Running Strategy Comparison...")
    
    strategies_to_test = ["market_making"]
    if haskey(STRATEGY_REGISTRY, "rl_market_making")
        push!(strategies_to_test, "rl_market_making")
    end
    
    results = Dict()
    
    for strategy_name in strategies_to_test
        println("\n📊 Testing $strategy_name...")
        
        try
            config, strategy_spec = create_strategy_config(strategy_name)
            context = AgentContext([], [])
            
            # Initialize
            if strategy_spec.initialize !== nothing
                strategy_spec.initialize(config, context)
            end
            
            # Run backtest if available
            if strategy_name == "rl_market_making"
                input = strategy_spec.input_type(action="run_backtest")
                strategy_spec.run(config, context, input)
            end
            
            results[strategy_name] = Dict(
                "logs" => length(context.logs),
                "status" => "✅ Success"
            )
            
        catch e
            results[strategy_name] = Dict(
                "logs" => 0,
                "status" => "❌ Error: $e"
            )
        end
    end
    
    println("\n📋 Strategy Comparison Results:")
    println("="^50)
    for (strategy, result) in results
        println("$strategy:")
        println("  Status: $(result["status"])")
        println("  Log Entries: $(result["logs"])")
        println()
    end
end

# Main execution
try
    selected_strategy = select_strategy()
    
    if selected_strategy == "compare_all"
        compare_strategies()
        println("\nPress Enter to exit...")
        readline()
        exit(0)
    end
    
    # Create configuration
    config, strategy_spec = create_strategy_config(selected_strategy)
    context = AgentContext([], [])
    
    println("\n📊 Strategy Configuration:")
    println("  Strategy: $selected_strategy")
    println("  Symbols: $(config.symbols)")
    
    if hasfield(typeof(config), :base_spread_pct)
        println("  Spread: $(config.base_spread_pct)%")
    end
    if hasfield(typeof(config), :order_levels)
        println("  Order Levels: $(config.order_levels)")
    end
    if hasfield(typeof(config), :max_capital)
        println("  Max Capital: \$$(config.max_capital)")
    end
    if hasfield(typeof(config), :enable_rl_learning)
        println("  RL Learning: $(config.enable_rl_learning)")
    end
    if hasfield(typeof(config), :enable_llm_optimization)
        println("  LLM Optimization: $(config.enable_llm_optimization)")
    end
    
    # Initialize strategy
    println("\n🔄 Initializing $selected_strategy...")
    if strategy_spec.initialize !== nothing
        strategy_spec.initialize(config, context)
        println("✅ Strategy initialization successful")
        
        # Show initialization logs
        if !isempty(context.logs)
            println("\n📋 Initialization Logs:")
            for log in context.logs[max(1, end-5):end]
                println("  $log")
            end
        end
    end
    
    # Launch appropriate control panel
    if selected_strategy == "rl_market_making"
        println("\n🎯 RL System ready! Starting enhanced control panel...")
        rl_trading_menu(config, strategy_spec, context)
    else
        println("\n🎯 System ready! Strategy: $selected_strategy")
        # Could add other specialized menus here
        
        # For now, run a simple test
        if selected_strategy == "llm_backtesting"
            println("🧠 Running LLM optimization...")
            input = strategy_spec.input_type(action="start_optimization")
            strategy_spec.run(config, context, input)
        else
            println("📈 Running strategy test...")
            input = strategy_spec.input_type(action="start_trading")
            strategy_spec.run(config, context, input)
        end
        
        println("\nPress Enter to exit...")
        readline()
    end
    
catch e
    println("❌ Fatal error: $e")
    println("\nFull error details:")
    showerror(stdout, e, catch_backtrace())
    println("\n\nPress Enter to exit...")
    readline()
end
