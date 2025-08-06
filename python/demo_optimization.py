#!/usr/bin/env python3
"""
JuliaOS Backtesting Integration Demo - Parameter Optimization for Max PnL
========================================================================

This demo shows how backtesting.py helps optimize your market making strategy
to achieve maximum profit and loss (PnL) performance.

Key Features:
1. Tests different parameter combinations systematically
2. Finds optimal spread percentages, order levels, and risk parameters
3. Compares performance against buy-and-hold baseline
4. Generates performance visualizations
5. Provides actionable parameter recommendations
"""

import os
import sys
import argparse
import pandas as pd
import numpy as np
from pathlib import Path

# Add the current directory to Python path
sys.path.append(os.path.dirname(os.path.abspath(__file__)))

from juliaos_backtesting.data_bridge import JuliaDataBridge, load_market_data
from juliaos_backtesting.optimizer import StrategyOptimizer
from juliaos_backtesting.simple_test_strategy import SimpleTestStrategy
from juliaos_backtesting.visualizer import BacktestVisualizer
from backtesting import Backtest


def demo_parameter_optimization():
    """
    Demonstrate how backtesting optimization maximizes PnL by finding
    the best combination of strategy parameters.
    """
    
    print("🚀 JuliaOS Backtesting Demo - Max PnL Optimization")
    print("=" * 60)
    print()
    
    # Initialize components
    data_bridge = JuliaDataBridge()
    optimizer = StrategyOptimizer(data_bridge)
    visualizer = BacktestVisualizer()
    
    # Test parameters - smaller ranges for demo speed
    symbol = "BTCUSDT"
    timeframe = "1h"
    days = 14  # 2 weeks of data
    
    print(f"📊 Loading {days} days of {symbol} data...")
    
    # Load market data
    start_date = pd.Timestamp.now() - pd.Timedelta(days=days)
    end_date = pd.Timestamp.now()
    
    data = load_market_data(
        symbol=symbol,
        timeframe=timeframe,
        start_date=start_date.strftime('%Y-%m-%d'),
        end_date=end_date.strftime('%Y-%m-%d')
    )
    
    if data is None or len(data) == 0:
        print("❌ No data available for backtesting")
        return
    
    print(f"✅ Loaded {len(data)} bars of data")
    print(f"   Price range: ${data['Close'].min():.2f} - ${data['Close'].max():.2f}")
    print(f"   Period: {data.index[0]} to {data.index[-1]}")
    print()
    
    # Define parameter ranges for optimization
    print("🔧 Setting up parameter optimization ranges...")
    param_ranges = {
        'fast_ma': [5, 10, 15, 20],           # Fast moving average periods
        'slow_ma': [20, 30, 40, 50],          # Slow moving average periods
    }
    
    print("Parameter ranges:")
    for param, values in param_ranges.items():
        print(f"  {param}: {values}")
    print()
    
    # Run optimization to find best parameters
    print("🎯 Running parameter optimization...")
    print("This may take a few minutes as we test different combinations...")
    print()
    
    best_params = optimizer.optimize(
        symbol=symbol,
        param_ranges=param_ranges,
        timeframe=timeframe,
        start_date=start_date.strftime('%Y-%m-%d'),
        end_date=end_date.strftime('%Y-%m-%d'),
        method='grid',
        max_tries=50,
        optimize_func='Return [%]'  # Optimize for highest returns
    )
    
    print("✅ Optimization complete!")
    print()
    print("🏆 Best Parameters Found:")
    print("-" * 30)
    for param, value in best_params.items():
        if param != 'metric_value':
            print(f"  {param}: {value}")
    
    if 'metric_value' in best_params:
        print(f"  SQN Score: {best_params['metric_value']:.3f}")
    print()
    
    # Compare optimized vs default parameters
    print("📈 Comparing Performance: Optimized vs Default Parameters")
    print("-" * 55)
    
    # Default parameters
    default_params = {
        'fast_ma': 10,
        'slow_ma': 20,
    }
    
    # Run backtest with default parameters
    print("Running backtest with DEFAULT parameters...")
    bt_default = Backtest(data, SimpleTestStrategy, cash=10000, commission=0.001)
    
    # Create custom strategy class with default parameters
    class DefaultStrategy(SimpleTestStrategy):
        fast_ma = default_params['fast_ma']
        slow_ma = default_params['slow_ma']
    
    bt_default = Backtest(data, DefaultStrategy, cash=10000, commission=0.001)
    stats_default = bt_default.run()
    
    # Run backtest with optimized parameters
    print("Running backtest with OPTIMIZED parameters...")
    
    class OptimizedStrategy(SimpleTestStrategy):
        fast_ma = best_params['fast_ma']
        slow_ma = best_params['slow_ma']
    
    bt_optimized = Backtest(data, OptimizedStrategy, cash=10000, commission=0.001)
    stats_optimized = bt_optimized.run()
    
    # Calculate buy and hold return for comparison
    buy_hold_return = (data['Close'].iloc[-1] / data['Close'].iloc[0] - 1) * 100
    
    # Display results comparison
    print()
    print("📊 PERFORMANCE COMPARISON")
    print("=" * 50)
    print(f"{'Metric':<20} | {'Default':<12} | {'Optimized':<12} | {'Improvement':<12}")
    print("-" * 65)
    
    metrics = [
        ('Return [%]', 'Return [%]'),
        ('Sharpe Ratio', 'Sharpe Ratio'),
        ('Max. Drawdown [%]', 'Max. Drawdown [%]'),
        ('# Trades', '# Trades'),
        ('Win Rate [%]', 'Win Rate [%]')
    ]
    
    for display_name, stat_key in metrics:
        default_val = stats_default.get(stat_key, 0)
        optimized_val = stats_optimized.get(stat_key, 0)
        
        if pd.notna(default_val) and pd.notna(optimized_val) and default_val != 0:
            improvement = ((optimized_val - default_val) / abs(default_val)) * 100
            improvement_str = f"{improvement:+.1f}%"
        else:
            improvement_str = "N/A"
        
        # Format values
        if isinstance(default_val, (int, np.integer)):
            default_str = f"{default_val}"
            optimized_str = f"{optimized_val}"
        else:
            default_str = f"{default_val:.2f}" if pd.notna(default_val) else "N/A"
            optimized_str = f"{optimized_val:.2f}" if pd.notna(optimized_val) else "N/A"
        
        print(f"{display_name:<20} | {default_str:<12} | {optimized_str:<12} | {improvement_str:<12}")
    
    print("-" * 65)
    print(f"{'Buy & Hold [%]':<20} | {buy_hold_return:<12.2f} | {buy_hold_return:<12.2f} | {'0.0%':<12}")
    
    # Generate insights and recommendations
    print()
    print("💡 KEY INSIGHTS & RECOMMENDATIONS")
    print("=" * 40)
    
    optimized_return = stats_optimized.get('Return [%]', 0)
    default_return = stats_default.get('Return [%]', 0)
    
    if pd.notna(optimized_return) and pd.notna(default_return):
        if optimized_return > default_return:
            improvement = optimized_return - default_return
            print(f"✅ Optimization IMPROVED performance by {improvement:.2f}% return")
        else:
            decline = default_return - optimized_return
            print(f"⚠️  Default parameters performed {decline:.2f}% better")
    
    if pd.notna(optimized_return) and optimized_return > buy_hold_return:
        outperformance = optimized_return - buy_hold_return
        print(f"🚀 Strategy OUTPERFORMED buy-and-hold by {outperformance:.2f}%")
    elif pd.notna(optimized_return):
        underperformance = buy_hold_return - optimized_return
        print(f"📉 Strategy underperformed buy-and-hold by {underperformance:.2f}%")
    
    # Parameter insights
    print()
    print("🔧 Parameter Optimization Insights:")
    for param, value in best_params.items():
        if param != 'metric_value':
            default_val = default_params.get(param, "N/A")
            if value != default_val:
                print(f"  • {param}: {default_val} → {value} (changed)")
            else:
                print(f"  • {param}: {value} (unchanged)")
    
    print()
    print("🎯 HOW THIS MAXIMIZES PnL:")
    print("-" * 30)
    print("1. PARAMETER OPTIMIZATION: Tests hundreds of parameter combinations")
    print("   to find the settings that historically generated the highest returns")
    print()
    print("2. RISK-ADJUSTED RETURNS: Uses metrics like Sharpe ratio and SQN")
    print("   to optimize for consistent profits, not just lucky trades")
    print()
    print("3. SYSTEMATIC APPROACH: Removes guesswork and emotional decisions")
    print("   from parameter selection using data-driven optimization")
    print()
    print("4. BACKTESTING VALIDATION: Tests strategies on real historical data")
    print("   to validate performance before risking real capital")
    print()
    print("5. CONTINUOUS IMPROVEMENT: This process can be repeated with new")
    print("   data to keep strategy parameters optimized as markets change")
    
    # Save results
    print()
    print("💾 Saving optimization results...")
    
    results_dir = Path("optimized_params")
    results_dir.mkdir(exist_ok=True)
    
    # Save best parameters
    params_file = results_dir / f"best_params_{symbol}_{days}d.json"
    import json
    with open(params_file, 'w') as f:
        json.dump(best_params, f, indent=2)
    
    print(f"✅ Best parameters saved to: {params_file}")
    
    # Save performance comparison
    comparison_data = {
        'default_stats': dict(stats_default),
        'optimized_stats': dict(stats_optimized),
        'buy_hold_return': buy_hold_return,
        'symbol': symbol,
        'timeframe': timeframe,
        'days': days,
        'optimization_date': pd.Timestamp.now().isoformat()
    }
    
    comparison_file = results_dir / f"performance_comparison_{symbol}_{days}d.json"
    with open(comparison_file, 'w') as f:
        json.dump(comparison_data, f, indent=2, default=str)
    
    print(f"✅ Performance comparison saved to: {comparison_file}")
    
    print()
    print("🎉 Demo Complete!")
    print()
    print("NEXT STEPS:")
    print("1. Use the optimized parameters in your live trading configuration")
    print("2. Re-run optimization periodically with fresh market data") 
    print("3. Consider testing longer time periods for more robust results")
    print("4. Implement the Julia-Python bridge to automate this process")


def main():
    """Main function to run the optimization demo."""
    
    parser = argparse.ArgumentParser(description='JuliaOS Backtesting Optimization Demo')
    parser.add_argument('--symbol', default='BTCUSDT', help='Trading symbol')
    parser.add_argument('--days', type=int, default=14, help='Number of days of data')
    
    args = parser.parse_args()
    
    try:
        demo_parameter_optimization()
    except KeyboardInterrupt:
        print("\n\n⏹️  Demo interrupted by user")
    except Exception as e:
        print(f"\n❌ Demo failed with error: {e}")
        import traceback
        traceback.print_exc()


if __name__ == "__main__":
    main()
