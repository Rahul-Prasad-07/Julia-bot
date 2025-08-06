# JuliaOS Market Making Backtesting System

This system integrates the powerful [backtesting.py](https://kernc.github.io/backtesting.py/) library with JuliaOS's market making strategies to provide comprehensive backtesting, optimization, and visualization capabilities.

## Features

- **Comprehensive Backtesting**: Test your market making strategies against historical data with accurate order simulation
- **Parameter Optimization**: Automatically find the optimal parameters for your strategies
- **Advanced Visualizations**: Interactive charts and visualizations to analyze performance
- **Seamless Julia Integration**: Direct integration with JuliaOS's Julia-based market making system
- **Reinforcement Learning Support**: Test RL-enhanced adaptive market making strategies
- **Multi-Symbol Testing**: Backtest across multiple trading pairs simultaneously

## Installation

### Install Python Dependencies

```bash
# From JuliaOS root directory
cd python
pip install -r requirements_backtesting.txt
```

### Install Julia Dependencies

```julia
# From Julia REPL
using Pkg
Pkg.add(["PyCall", "JSON", "Dates", "TOML"])
```

## Usage

### Python Interface

Use the Python interface for direct access to all backtesting.py features:

```bash
cd python
python run_backtest.py --symbol BTCUSDT --days 30 --optimize --visualize
```

Command line options:
- `--symbol`: Trading pair to backtest (default: BTCUSDT)
- `--timeframe`: Data timeframe (default: 1h)
- `--days`: Number of days to backtest (default: 30)
- `--start`: Start date (format: YYYY-MM-DD)
- `--end`: End date (format: YYYY-MM-DD)
- `--optimize`: Run parameter optimization
- `--param1`: First parameter to optimize in heatmap (default: base_spread_pct)
- `--param2`: Second parameter to optimize in heatmap (default: order_levels)
- `--visualize`: Generate visualizations
- `--save`: Save results and figures
- `--adaptive`: Use adaptive RL strategy

### Julia Interface

Use the Julia interface for integration with your existing JuliaOS code:

```bash
cd julia/examples
julia backtest_example.jl --symbol ETHUSDT --days 60 --optimize --report
```

Command line options:
- `--symbol`: Trading pair to backtest (default: BTCUSDT)
- `--days`: Number of days to backtest (default: 30)
- `--optimize`: Run parameter optimization
- `--report`: Generate comprehensive report
- `--visualize`: Show visualizations

### Julia API

Import and use the `BacktestingBridge` module in your Julia code:

```julia
include("julia/src/BacktestingBridge.jl")

# Run backtest
stats = BacktestingBridge.run_backtest(
    "BTCUSDT",                # Symbol
    Dict("base_spread_pct" => 0.15, "order_levels" => 3),  # Parameters
    "1h",                     # Timeframe
    30,                       # Days
    true                      # Use adaptive strategy
)

# Optimize parameters
param_ranges = Dict{String, Any}(
    "base_spread_pct" => (0.05, 0.5, 0.05),
    "order_levels" => 1:5
)

best_params = BacktestingBridge.optimize_strategy(
    "BTCUSDT",               # Symbol
    param_ranges,            # Parameter ranges
    "1h",                    # Timeframe
    30,                      # Days
    100                      # Max optimization attempts
)

# Generate report
report = BacktestingBridge.generate_backtest_report(
    "BTCUSDT",               # Symbol
    Dict("base_spread_pct" => 0.15, "order_levels" => 3),  # Parameters
    30                       # Days
)
```

## Directory Structure

- `python/backtesting/`: Python backtesting implementation
  - `__init__.py`: Module initialization
  - `data_bridge.py`: Data transfer between Julia and Python
  - `market_making_strategy.py`: Strategy implementations
  - `optimizer.py`: Parameter optimization
  - `visualizer.py`: Performance visualization
- `python/run_backtest.py`: Main Python runner script
- `julia/src/BacktestingBridge.jl`: Julia integration module
- `julia/examples/backtest_example.jl`: Example Julia script

## Results and Output

- Backtest results are saved to `python/backtest_results/`
- Visualizations are saved to `python/visualizations/`
- Optimized parameters are saved to `python/optimized_params/`

## Customization

To customize the market making strategy for backtesting:

1. Edit the `RLMarketMakingStrategy` or `AdaptiveRLMarketMakingStrategy` classes in `python/backtesting/market_making_strategy.py`
2. Modify the optimization parameters in `python/backtesting/optimizer.py`
3. Add new visualization types in `python/backtesting/visualizer.py`

## Integration with JuliaOS

This backtesting system is designed to work seamlessly with JuliaOS's market making strategies:

1. **Develop Strategies in Julia**: Create and refine your market making strategies in Julia
2. **Backtest in Python**: Use Python's backtesting.py for comprehensive testing
3. **Optimize Parameters**: Find optimal parameters for your strategies
4. **Apply to Production**: Apply optimized parameters back to your Julia strategies

The system provides a feedback loop between strategy development, backtesting, optimization, and deployment.
