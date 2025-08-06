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
available_strategies = ["market_making", "rl_market_making", "enhanced_rl_market_making", "llm_backtesting", "multi_exchange", "agent_swarm"]
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
    println("3. 🚀 Enhanced RL + Python Backtesting (NEW!)")
    println("4. 🧠 LLM Backtesting & Optimization")
    println("5. 🌐 Multi-Exchange Arbitrage")
    println("6. 🐝 Agent Swarm Coordination")
    println("7. 🔄 Compare All Strategies")
    println("8. ❌ Exit")
    println("="^60)
    
    print("Select strategy (1-7): ")
    choice = readline()
    
    if choice == "1"
        return "market_making"
    elseif choice == "2"
        return "rl_market_making"
    elseif choice == "3"
        return "enhanced_rl_market_making"
    elseif choice == "4"
        return "llm_backtesting"
    elseif choice == "5"
        return "multi_exchange"
    elseif choice == "6"
        return "agent_swarm"
    elseif choice == "7"
        return "compare_all"
    elseif choice == "8"
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
        
    elseif strategy_name == "enhanced_rl_market_making"
        if !haskey(STRATEGY_REGISTRY, "enhanced_rl_market_making")
            error("❌ Enhanced RL Market making strategy not found!")
        end
        
        strategy_spec = STRATEGY_REGISTRY["enhanced_rl_market_making"]
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
            
            # Enhanced Python Backtesting Integration
            enable_python_backtesting = true,
            optimization_frequency_hours = 24,
            auto_parameter_update = true,
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

# Enhanced trading menu for Enhanced RL strategy with Python backtesting
function enhanced_rl_trading_menu(config, strategy_spec, context)
    while true
        println("\n" * "="^70)
        println("🚀 Enhanced RL + Python Backtesting Control Panel (24/7)")
        println("="^70)
        println("1. 🚀 Start 24/7 Enhanced Trading (RL + Auto-Optimization)")
        println("2. 📊 Check Real-time Status (Trading + Python Integration)")
        println("3. ⏹️  Stop 24/7 Trading")
        println("4. 🚨 EMERGENCY: Cancel ALL Orders")
        println("5. 🐍 Run Python Backtesting Optimization")
        println("6. 🔄 Force Parameter Update from Python")
        println("7. 📈 Show Optimization History")
        println("8. 🧠 Train RL Model")
        println("9. 📋 Show Recent Logs")
        println("10. 📊 Performance Analytics (Enhanced)")
        println("11. ⚙️  Adjust Parameters")
        println("12. 🧪 Test Mode (Single Iteration)")
        println("13. 💰 Show Comprehensive PnL Report")
        println("14. 🔧 Configure Python Integration")
        println("15. ❌ Exit")
        println("="^70)
        println("🐍 Python Integration: Automated backtesting every 24h")
        println("🔄 Auto-Optimization: Parameters update automatically from Python results")
        println("🚨 Emergency: Use option 4 for margin issues!")
        println("="^70)
        
        print("Enter your choice (1-15): ")
        choice = readline()
        
        if choice == "1"
            println("\n🚀 Starting Enhanced 24/7 Trading with Python Auto-Optimization...")
            println("⚠️  This enables CONTINUOUS trading with these features:")
            println("   🤖 RL-enhanced market making with neural network learning")
            println("   🐍 Automated Python backtesting optimization every 24 hours")
            println("   📈 Real-time parameter updates from optimization results")
            println("   💰 Comprehensive PnL tracking and performance monitoring")
            println("   🔄 Order refresh every 30s with optimized parameters")
            print("Are you sure you want to start enhanced 24/7 trading? (y/N): ")
            confirm = readline()
            
            if lowercase(confirm) == "y" || lowercase(confirm) == "yes"
                input = strategy_spec.input_type(action="start_enhanced_rl_trading", learning_mode=true)
                strategy_spec.run(config, context, input)
                println("\n✅ Enhanced 24/7 trading started!")
                println("🐍 Python optimization will run automatically every 24 hours")
                println("📊 Monitor with option 2 for real-time status")
            else
                println("❌ Operation cancelled.")
            end
            
        elseif choice == "2"
            println("\n📊 Enhanced Trading Status Check...")
            input = strategy_spec.input_type(action="status_enhanced")
            strategy_spec.run(config, context, input)
            
        elseif choice == "3"
            println("\n⏹️ Stopping Enhanced Trading...")
            input = strategy_spec.input_type(action="stop_trading")
            strategy_spec.run(config, context, input)
            
        elseif choice == "4"
            println("\n🚨 EMERGENCY ORDER CLEANUP")
            println("⚠️  This will IMMEDIATELY cancel ALL open orders!")
            print("Continue? (y/N): ")
            confirm = readline()
            
            if lowercase(confirm) == "y"
                input = strategy_spec.input_type(action="emergency_cleanup")
                strategy_spec.run(config, context, input)
            end
            
        elseif choice == "5"
            println("\n🐍 Running Python Backtesting Optimization...")
            input = strategy_spec.input_type(action="run_python_optimization")
            strategy_spec.run(config, context, input)
            
        elseif choice == "6"
            println("\n🔄 Forcing Parameter Update from Python Results...")
            input = strategy_spec.input_type(action="apply_python_params")
            strategy_spec.run(config, context, input)
            
        elseif choice == "7"
            println("\n📈 Optimization History:")
            println("="^50)
            # Show optimization history from context logs
            optimization_logs = filter(log -> contains(log, "optimization") || contains(log, "Python"), context.logs)
            if !isempty(optimization_logs)
                for log in optimization_logs[max(1, end-9):end]
                    println("  $log")
                end
            else
                println("  No optimization history available yet")
            end
            println("="^50)
            
        elseif choice == "8"
            println("\n🧠 Training RL Model...")
            input = strategy_spec.input_type(action="train_rl_model")
            strategy_spec.run(config, context, input)
            
        elseif choice == "9"
            println("\n📋 Recent Trading Logs:")
            println("="^50)
            if !isempty(context.logs)
                recent_logs = context.logs[max(1, length(context.logs)-29):end]
                for (i, log) in enumerate(recent_logs)
                    log_num = length(context.logs) - length(recent_logs) + i
                    println("[$log_num] $log")
                end
            else
                println("  No logs available yet")
            end
            println("="^50)
            
        elseif choice == "10"
            println("\n📊 Enhanced Performance Analytics:")
            println("  RL Learning Rate: $(config.learning_rate)")
            println("  Python Backtesting: $(config.enable_python_backtesting)")
            println("  Optimization Frequency: $(config.optimization_frequency_hours) hours")
            println("  Auto Parameter Update: $(config.auto_parameter_update)")
            println("  Backtest Days: $(config.backtest_days)")
            
        elseif choice == "11"
            println("\n⚙️ Current Enhanced Parameters:")
            println("  Spread: $(config.base_spread_pct)%")
            println("  Python Integration: $(config.enable_python_backtesting)")
            println("  Optimization Frequency: $(config.optimization_frequency_hours)h")
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
            
        elseif choice == "12"
            println("\n🧪 Running Enhanced Test Mode...")
            input = strategy_spec.input_type(action="test_enhanced", learning_mode=false)
            strategy_spec.run(config, context, input)
            
        elseif choice == "13"
            println("\n💰 Comprehensive Enhanced PnL Report")
            println("="^60)
            
            # Store current log count to find new logs
            initial_log_count = length(context.logs)
            
            # Generate the enhanced PnL report
            input = strategy_spec.input_type(action="generate_enhanced_report")
            strategy_spec.run(config, context, input)
            
            # Display the newly generated report logs immediately
            if length(context.logs) > initial_log_count
                println("\n📊 Enhanced Performance Report:")
                println("="^60)
                new_logs = context.logs[initial_log_count+1:end]
                for log in new_logs
                    # Skip the action start/end logs, show only report content
                    if !contains(log, "Enhanced RL Market Making Strategy execution") && 
                       !contains(log, "Generating Enhanced Performance Report") &&
                       !contains(log, "Unknown action")
                        println(log)
                    end
                end
                println("="^60)
            else
                println("⚠️ No report data generated. PnL tracker may need initialization.")
            end
            
        elseif choice == "14"
            println("\n🔧 Enhanced Python Integration Configuration")
            println("="^60)
            println("📊 Current Settings:")
            println("  🐍 Python Path: $(config.python_env_path)")
            println("  ⏰ Optimization Frequency: $(config.optimization_frequency_hours) hours")
            println("  📅 Backtest Analysis Days: $(config.backtest_days) days")
            println("  🔄 Auto Parameter Update: $(config.auto_parameter_update ? "✅ Enabled" : "❌ Disabled")")
            println("  📈 Optimization Metric: $(config.python_optimization_params["optimization_metric"])")
            println()
            
            # Optimization Frequency Configuration
            println("1️⃣ Configure Optimization Frequency:")
            println("   Current: Every $(config.optimization_frequency_hours) hours")
            println("   Suggestions: 1h (aggressive), 6h (active), 12h (moderate), 24h (conservative)")
            print("   Enter new frequency in hours (or press Enter to skip): ")
            new_freq = readline()
            if !isempty(new_freq)
                try
                    new_freq_int = parse(Int, new_freq)
                    if new_freq_int >= 1 && new_freq_int <= 168  # Max 1 week
                        config.optimization_frequency_hours = new_freq_int
                        println("   ✅ Updated optimization frequency to $(config.optimization_frequency_hours) hours")
                        
                        # Update the global optimizer
                        input = strategy_spec.input_type(action="update_optimization_frequency", 
                                                       optimization_params=Dict("frequency_hours" => new_freq_int))
                        strategy_spec.run(config, context, input)
                    else
                        println("   ❌ Frequency must be between 1 and 168 hours")
                    end
                catch
                    println("   ❌ Invalid frequency value")
                end
            end
            
            # Backtest Days Configuration
            println("\n2️⃣ Configure Backtest Analysis Period:")
            println("   Current: Analyzing $(config.backtest_days) days of historical data")
            println("   Suggestions: 7d (fast), 14d (quick), 30d (standard), 60d (comprehensive)")
            print("   Enter new analysis period in days (or press Enter to skip): ")
            new_days = readline()
            if !isempty(new_days)
                try
                    new_days_int = parse(Int, new_days)
                    if new_days_int >= 7 && new_days_int <= 365  # Max 1 year
                        config.backtest_days = new_days_int
                        println("   ✅ Updated backtest analysis to $(config.backtest_days) days")
                        
                        # Update optimization parameters
                        input = strategy_spec.input_type(action="update_backtest_period", 
                                                       optimization_params=Dict("backtest_days" => new_days_int))
                        strategy_spec.run(config, context, input)
                    else
                        println("   ❌ Analysis period must be between 7 and 365 days")
                    end
                catch
                    println("   ❌ Invalid days value")
                end
            end
            
            # Auto Parameter Update Toggle
            println("\n3️⃣ Auto Parameter Update:")
            println("   Current: $(config.auto_parameter_update ? "✅ Enabled" : "❌ Disabled")")
            print("   Toggle auto-update? (y/n or Enter to skip): ")
            toggle_auto = readline()
            if lowercase(toggle_auto) == "y"
                config.auto_parameter_update = !config.auto_parameter_update
                println("   ✅ Auto parameter update: $(config.auto_parameter_update ? "ENABLED" : "DISABLED")")
            elseif lowercase(toggle_auto) == "n"
                println("   ℹ️ Auto parameter update setting unchanged")
            end
            
            # Optimization Metric Selection
            println("\n4️⃣ Optimization Metric:")
            println("   Current: $(config.python_optimization_params["optimization_metric"])")
            println("   Available metrics:")
            println("     • SQN (Statistical Quality Number) - Overall strategy quality")
            println("     • Sharpe_Ratio - Risk-adjusted returns")
            println("     • Return - Total return percentage")
            println("     • Calmar_Ratio - Return/Max Drawdown ratio")
            print("   Enter new metric (SQN/Sharpe_Ratio/Return/Calmar_Ratio or Enter to skip): ")
            new_metric = readline()
            if !isempty(new_metric) && new_metric in ["SQN", "Sharpe_Ratio", "Return", "Calmar_Ratio"]
                config.python_optimization_params["optimization_metric"] = new_metric
                println("   ✅ Updated optimization metric to $(new_metric)")
            elseif !isempty(new_metric)
                println("   ❌ Invalid metric. Use: SQN, Sharpe_Ratio, Return, or Calmar_Ratio")
            end
            
            # Force Optimization Run
            println("\n5️⃣ Force Immediate Optimization:")
            print("   Run optimization now with new settings? (y/N): ")
            run_now = readline()
            if lowercase(run_now) == "y" || lowercase(run_now) == "yes"
                println("   🔄 Running immediate Python optimization with new settings...")
                input = strategy_spec.input_type(action="run_python_optimization")
                strategy_spec.run(config, context, input)
            end
            
            println("\n📋 Updated Configuration Summary:")
            println("  ⏰ Optimization Frequency: Every $(config.optimization_frequency_hours) hours")
            println("  📅 Backtest Analysis: $(config.backtest_days) days")
            println("  🔄 Auto Parameter Update: $(config.auto_parameter_update ? "✅ Enabled" : "❌ Disabled")")
            println("  📈 Optimization Metric: $(config.python_optimization_params["optimization_metric"])")
            println("💡 New settings will take effect on next optimization cycle!")
            
        elseif choice == "15"
            println("\n👋 Exiting Enhanced RL trading system...")
            break
            
        else
            println("❌ Invalid choice. Please enter 1-15.")
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
    if hasfield(typeof(config), :enable_python_backtesting)
        println("  Python Backtesting: $(config.enable_python_backtesting)")
    end
    if hasfield(typeof(config), :optimization_frequency_hours)
        println("  Auto-Optimization: Every $(config.optimization_frequency_hours) hours")
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
    elseif selected_strategy == "enhanced_rl_market_making"
        println("\n🚀 Enhanced RL + Python System ready! Starting advanced control panel...")
        enhanced_rl_trading_menu(config, strategy_spec, context)
    elseif selected_strategy == "enhanced_rl_market_making"
        println("\n🚀 Enhanced RL + Python System ready! Starting advanced control panel...")
        enhanced_rl_trading_menu(config, strategy_spec, context)
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
