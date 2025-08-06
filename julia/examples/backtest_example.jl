#!/usr/bin/env julia

"""
JuliaOS Backtesting Integration Example
--------------------------------------
Demonstrates how to use the Python backtesting.py integration with JuliaOS
"""

using Pkg
# Ensure we have the required packages
required_pkgs = ["PyCall", "JSON", "Dates", "TOML"]
for pkg in required_pkgs
    try
        eval(:(using $(Symbol(pkg))))
    catch
        try
            Pkg.add(pkg)
            eval(:(using $(Symbol(pkg))))
        catch e
            println("⚠️ Could not install or load $pkg: $e")
        end
    end
end

using JSON
using Dates
using TOML

# Add the parent directory to the load path to import the BacktestingBridge module
parent_dir = dirname(dirname(@__FILE__))
if !(parent_dir in LOAD_PATH)
    push!(LOAD_PATH, parent_dir)
end

# Import the BacktestingBridge module
include(joinpath(parent_dir, "src", "BacktestingBridge.jl"))

# Function to parse command line arguments
function parse_arguments()
    args = Dict{Symbol, Any}()
    
    # Default values
    args[:symbol] = "BTCUSDT"
    args[:days] = 30
    args[:optimize] = false
    args[:report] = false
    args[:visualize] = false
    
    i = 1
    while i <= length(ARGS)
        arg = ARGS[i]
        if arg == "--symbol" && i+1 <= length(ARGS)
            args[:symbol] = ARGS[i+1]
            i += 2
        elseif arg == "--days" && i+1 <= length(ARGS)
            args[:days] = parse(Int, ARGS[i+1])
            i += 2
        elseif arg == "--optimize"
            args[:optimize] = true
            i += 1
        elseif arg == "--report"
            args[:report] = true
            i += 1
        elseif arg == "--visualize"
            args[:visualize] = true
            i += 1
        else
            i += 1
        end
    end
    
    return args
end

# Main function
function main()
    println("""
    🚀 JuliaOS Backtesting Integration Example
    ----------------------------------------
    Using backtesting.py for advanced strategy testing and optimization
    """)
    
    # Parse arguments
    args = parse_arguments()
    
    symbol = args[:symbol]
    days = args[:days]
    
    println("Symbol: $symbol")
    println("Days: $days")
    println("Optimize: $(args[:optimize])")
    println("Generate Report: $(args[:report])")
    println("Visualize: $(args[:visualize])")
    
    # Load default parameters from config
    config_path = joinpath(dirname(dirname(dirname(@__FILE__))), "config", "market_making.toml")
    
    if !isfile(config_path)
        println("❌ Config file not found at $config_path")
        return
    end
    
    # Parse TOML config
    config = nothing
    try
        config = TOML.parsefile(config_path)
    catch e
        println("❌ Error parsing config file: $e")
        return
    end
    
    # Extract strategy parameters
    strategy_params = Dict{String, Any}()
    
    if haskey(config, "strategy")
        strategy = config["strategy"]
        
        # Basic parameters
        strategy_params["base_spread_pct"] = get(strategy, "base_spread_pct", 0.15)
        strategy_params["ask_spread_pct"] = get(strategy, "ask_spread_pct", 0.15)
        strategy_params["order_levels"] = get(strategy, "order_levels", 3)
        strategy_params["order_amount"] = get(strategy, "order_amount", 0.1)
        strategy_params["max_capital"] = get(strategy, "max_capital", 10000.0)
        strategy_params["leverage"] = get(strategy, "leverage", 20)
        
        # Dynamic features
        strategy_params["enable_dynamic_spreads"] = get(strategy, "enable_dynamic_spreads", true)
        strategy_params["enable_inventory_skew"] = get(strategy, "enable_inventory_skew", true)
        strategy_params["min_spread_pct"] = get(strategy, "min_spread_pct", 0.05)
        strategy_params["max_spread_pct"] = get(strategy, "max_spread_pct", 2.0)
        strategy_params["volatility_adjustment_factor"] = get(strategy, "volatility_adjustment_factor", 50.0)
    end
    
    # Risk parameters
    if haskey(config, "risk_management")
        risk = config["risk_management"]
        
        strategy_params["max_drawdown"] = get(risk, "max_drawdown", 0.15)
        strategy_params["stop_loss_threshold"] = get(risk, "stop_loss_threshold", 0.006)
        strategy_params["take_profit_threshold"] = get(risk, "take_profit_threshold", 0.005)
    end
    
    # Add RL parameters
    strategy_params["rl_volatility_factor"] = 1.0
    strategy_params["rl_spread_factor"] = 1.0
    strategy_params["rl_inventory_factor"] = 1.0
    
    # Run optimization if requested
    if args[:optimize]
        println("\n🔄 Running parameter optimization...")
        
        # Define parameter ranges
        param_ranges = Dict{String, Any}(
            "base_spread_pct" => (0.05, 0.5, 0.05),
            "order_levels" => 1:5,
            "volatility_adjustment_factor" => (10, 100, 10),
            "rl_volatility_factor" => (0.5, 1.5, 0.1),
            "rl_spread_factor" => (0.5, 1.5, 0.1),
            "rl_inventory_factor" => (0.5, 1.5, 0.1)
        )
        
        # Run optimization
        try
            best_params = BacktestingBridge.optimize_strategy(
                symbol,
                param_ranges,
                "1h",
                days,
                100
            )
            
            if haskey(best_params, "error")
                println("❌ Optimization error: $(best_params["error"])")
            else
                println("✅ Optimization complete!")
                println("Best parameters:")
                for (key, value) in best_params
                    println("  $key: $value")
                end
                
                # Update strategy parameters with optimized values
                for (key, value) in best_params
                    strategy_params[key] = value
                end
            end
        catch e
            println("❌ Optimization error: $e")
        end
    end
    
    # Run backtest
    println("\n🧮 Running backtest...")
    
    try
        stats = BacktestingBridge.run_backtest(
            symbol,
            strategy_params,
            "1h",
            days,
            true  # Use adaptive strategy
        )
        
        if haskey(stats, "error")
            println("❌ Backtest error: $(stats["error"])")
        else
            println("✅ Backtest complete!")
            println("\n📊 Backtest Results:")
            println("=================")
            println("Return: $(stats["Return [%]"])%")
            println("Sharpe Ratio: $(stats["Sharpe Ratio"])")
            println("Sortino Ratio: $(stats["Sortino Ratio"])")
            println("Max Drawdown: $(stats["Max. Drawdown [%]"])%")
            println("Win Rate: $(stats["Win Rate [%]"])%")
            println("# Trades: $(stats["# Trades"])")
            println("Profit Factor: $(stats["Profit Factor"])")
            println("SQN: $(stats["SQN"])")
            
            # Generate comprehensive report if requested
            if args[:report]
                println("\n📝 Generating comprehensive report...")
                report_result = BacktestingBridge.generate_backtest_report(symbol, strategy_params, days)
                
                if haskey(report_result, "status") && report_result["status"] == "success"
                    println("✅ Report generated successfully!")
                    println("📂 Visualizations saved to: $(report_result["visualizations_path"])")
                else
                    println("❌ Report generation error: $(get(report_result, "message", "Unknown error"))")
                end
            end
        end
    catch e
        println("❌ Backtest error: $e")
    end
end

# Run main function
main()
