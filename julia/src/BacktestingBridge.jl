"""
Julia-Python Bridge for Backtesting Integration
---------------------------------------------
This module connects Julia's market making system with the Python backtesting.py library
"""

module BacktestingBridge

using PyCall
using JSON
using Dates

# Import Python modules
py_backtesting = nothing
data_bridge = nothing  
market_making = nothing
optimizer = nothing
visualizer = nothing

function __init__()
    try
        # Use PyCall to import sys and add path
        PyCall.py"""
import sys
import os
# Get the Julia source directory and add Python path
julia_src_dir = r"$(dirname(@__FILE__))"
python_dir = os.path.join(os.path.dirname(os.path.dirname(julia_src_dir)), "python")
if python_dir not in sys.path:
    sys.path.insert(0, python_dir)
"""

        # Import backtesting modules
        global py_backtesting = PyCall.pyimport("backtesting")
        global data_bridge = PyCall.pyimport("juliaos_backtesting.data_bridge")
        global market_making = PyCall.pyimport("juliaos_backtesting.market_making_strategy")
        global optimizer = PyCall.pyimport("juliaos_backtesting.optimizer")
        global visualizer = PyCall.pyimport("juliaos_backtesting.visualizer")
        
        @info "Successfully initialized Python backtesting modules"
    catch e
        @warn "Error initializing Python modules: $e"
        @warn "Make sure backtesting.py and its dependencies are installed"
    end
end

"""
    create_strategy_with_params(strategy_class, params)
    
Create a strategy class with the specified parameters
"""
function create_strategy_with_params(strategy_class, params)
    # This is handled in Python, so we create a simple wrapper
    py_code = """
def create_custom_strategy(base_class, params):
    class CustomStrategy(base_class):
        pass
    
    # Set parameters as class attributes
    for param_name, param_value in params.items():
        if hasattr(base_class, param_name):
            setattr(CustomStrategy, param_name, param_value)
    
    return CustomStrategy
"""
    
    # Execute the Python code
    PyCall.py"exec"(py_code)
    
    # Call the function
    create_func = PyCall.py"create_custom_strategy"
    py_params = PyCall.PyDict(params)
    
    return create_func(strategy_class, py_params)
end

"""
    load_market_data(symbol::String, timeframe::String="1h", 
                      start_date::Union{String,Nothing}=nothing, 
                      end_date::Union{String,Nothing}=nothing)

Load market data for backtesting
"""
function load_market_data(symbol::String, timeframe::String="1h", 
                         start_date::Union{String,Nothing}=nothing, 
                         end_date::Union{String,Nothing}=nothing)
    try
        # Convert dates to string format
        if start_date isa Date
            start_date = Dates.format(start_date, "yyyy-mm-dd")
        end
        
        if end_date isa Date
            end_date = Dates.format(end_date, "yyyy-mm-dd")
        end
        
        # Use Python function to load data
        df = data_bridge.load_market_data(symbol, timeframe, start_date, end_date)
        return df
    catch e
        @warn "Error loading market data: $e"
        return nothing
    end
end

"""
    run_backtest(symbol::String, params::Dict, timeframe::String="1h", 
                 days::Int=30, adaptive::Bool=false)
    
Run a backtest using the specified parameters
"""
function run_backtest(symbol::String, params::Dict, timeframe::String="1h", 
                     days::Int=30, adaptive::Bool=false)
    try
        # Convert Julia Dict to Python dict
        py_params = PyCall.PyDict(params)
        
        # Set date range
        end_date = Dates.format(Dates.today(), "yyyy-mm-dd")
        start_date = Dates.format(Dates.today() - Dates.Day(days), "yyyy-mm-dd")
        
        # Load data
        data = data_bridge.load_market_data(symbol, timeframe, start_date, end_date)
        
        # Select strategy class
        strategy_class = adaptive ? market_making.AdaptiveRLMarketMakingStrategy : market_making.RLMarketMakingStrategy
        
        # Create a custom strategy class with parameters
        custom_strategy = create_strategy_with_params(strategy_class, py_params)
        
        # Run backtest
        bt = py_backtesting.Backtest(data, custom_strategy, cash=10000, commission=0.001)
        stats = bt.run()
        
        # Convert Python stats to Julia Dict
        stats_dict = Dict{String, Any}()
        for (k, v) in zip(stats.keys(), stats.values())
            k_str = string(k)
            # Skip complex objects - only include numerical statistics
            if !contains(k_str, "_") || k_str == "Equity Final [\$]" || k_str == "Equity Peak [\$]"
                stats_dict[k_str] = v
            end
        end
        
        return stats_dict
    catch e
        @error "Backtest error: $e"
        return Dict{String, Any}("error" => string(e))
    end
end

"""
    optimize_strategy(symbol::String, param_ranges::Dict, timeframe::String="1h",
                      days::Int=30, max_tries::Int=100)
                      
Optimize strategy parameters
"""
function optimize_strategy(symbol::String, param_ranges::Dict, timeframe::String="1h",
                         days::Int=30, max_tries::Int=100)
    try
        # Set date range
        end_date = Dates.format(Dates.today(), "yyyy-mm-dd")
        start_date = Dates.format(Dates.today() - Dates.Day(days), "yyyy-mm-dd")
        
        # Create optimizer
        bridge = data_bridge.JuliaDataBridge()
        opt = optimizer.StrategyOptimizer(bridge)
        
        # Convert Julia param_ranges to Python dict
        py_param_ranges = PyCall.PyDict()
        for (k, v) in param_ranges
            if v isa Tuple && length(v) == 2
                # Min/max range
                py_param_ranges[k] = v
            elseif v isa Tuple && length(v) == 3
                # Min/max/step range
                py_param_ranges[k] = v
            elseif v isa AbstractRange
                # Convert range to Python list
                py_param_ranges[k] = collect(v)
            else
                # Pass as is
                py_param_ranges[k] = v
            end
        end
        
        # Run optimization
        best_params = opt.optimize(
            symbol,
            py_param_ranges,
            timeframe,
            start_date,
            end_date,
            "grid",
            max_tries,
            "SQN"
        )
        
        # Convert Python dict to Julia Dict
        result = Dict{String, Any}(string(k) => v for (k, v) in zip(best_params.keys(), best_params.values()))
        return result
    catch e
        @error "Optimization error: $e"
        return Dict{String, Any}("error" => string(e))
    end
end

"""
    get_optimized_params(symbol::String)
    
Get the latest optimized parameters for a symbol
"""
function get_optimized_params(symbol::String)
    try
        params_dir = joinpath(dirname(dirname(@__FILE__)), "python", "optimized_params")
        if !isdir(params_dir)
            @warn "No optimized parameters directory found"
            return nothing
        end
        
        # Find latest params file for this symbol
        files = filter(f -> startswith(f, symbol) && endswith(f, ".json"), readdir(params_dir))
        if isempty(files)
            @warn "No optimized parameters found for $symbol"
            return nothing
        end
        
        # Sort by date (newest first)
        sort!(files, by=f -> begin
            m = match(r".*_(\d{8}_\d{6})\.json", f)
            if m !== nothing
                return m.captures[1]
            else
                return ""
            end
        end, rev=true)
        
        # Load the latest params file
        latest_file = files[1]
        params_path = joinpath(params_dir, latest_file)
        
        open(params_path, "r") do file
            params = JSON.parse(file)
            return params
        end
    catch e
        @error "Error loading optimized parameters: $e"
        return nothing
    end
end

"""
    py_range(r::AbstractRange)
    
Convert Julia range to Python range
"""
function py_range(r::AbstractRange)
    if length(r) == 0
        return py_range(0, 0)
    end
    
    start = first(r)
    stop = last(r)
    
    if length(r) > 1
        step = r[2] - r[1]
    else
        step = 1
    end
    
    # Python's range is exclusive of stop, so we add step
    return PyCall.pybuiltin("range")(start, stop + step, step)
end

"""
    generate_backtest_report(symbol::String, params::Dict)
    
Generate and save a comprehensive backtest report
"""
function generate_backtest_report(symbol::String, params::Dict, days::Int=30)
    try
        # Create Python script to run in a separate process
        script = """
import os
import sys
from datetime import datetime, timedelta
from backtesting import Backtest

# Add path to imports
sys.path.insert(0, os.path.dirname(os.path.dirname(os.path.abspath(__file__))))
from juliaos_backtesting.market_making_strategy import AdaptiveRLMarketMakingStrategy
from juliaos_backtesting.data_bridge import load_market_data
from juliaos_backtesting.visualizer import BacktestVisualizer

# Set parameters
symbol = "$(symbol)"
days = $(days)
params = $(json(params))

# Set date range
end_date = datetime.now().strftime('%Y-%m-%d')
start_date = (datetime.now() - timedelta(days=days)).strftime('%Y-%m-%d')

# Load data
data = load_market_data(symbol, "1h", start_date, end_date)

# Run backtest
bt = Backtest(data, AdaptiveRLMarketMakingStrategy, cash=10000, commission=0.001, **params)
stats = bt.run()

# Create visualizer
visualizer = BacktestVisualizer()

# Generate plots
fig1, ax1 = visualizer.plot_equity_curve(stats, f"{symbol} Equity Curve")
visualizer.save_plot(fig1, f"{symbol}_equity_curve")

fig2, ax2 = visualizer.plot_drawdowns(stats)
visualizer.save_plot(fig2, f"{symbol}_drawdowns")

fig3, ax3 = visualizer.plot_performance_metrics(stats)
visualizer.save_plot(fig3, f"{symbol}_performance_metrics")

# Save backtest results
from juliaos_backtesting.data_bridge import JuliaDataBridge
bridge = JuliaDataBridge()
bridge.save_backtest_results(stats, symbol, params)

print("Report generation complete")
"""
        
        # Write script to temporary file
        temp_script = joinpath(tempdir(), "generate_backtest_report.py")
        open(temp_script, "w") do file
            write(file, script)
        end
        
        # Run script with Python
        result = read(`python $temp_script`, String)
        
        # Return success message with path to report
        vis_dir = joinpath(dirname(dirname(@__FILE__)), "python", "visualizations")
        return Dict(
            "status" => "success", 
            "message" => "Report generated successfully", 
            "visualizations_path" => vis_dir,
            "output" => result
        )
    catch e
        @error "Error generating backtest report: $e"
        return Dict("status" => "error", "message" => string(e))
    end
end

end # module
