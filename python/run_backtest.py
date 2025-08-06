#!/usr/bin/env python3
"""
JuliaOS Backtesting Runner
------------------------
Main script for running backtests on JuliaOS market making strategies

This script demonstrates how to use the backtesting.py library 
to backtest and optimize the market making strategies from JuliaOS.
"""

import os
import sys
import argparse
import pandas as pd
import matplotlib.pyplot as plt
from datetime import datetime, timedelta
from backtesting import Backtest

# Add current directory to path to import local modules
sys.path.append(os.path.dirname(os.path.dirname(os.path.abspath(__file__))))
from juliaos_backtesting.market_making_strategy import RLMarketMakingStrategy, AdaptiveRLMarketMakingStrategy
from juliaos_backtesting.simple_test_strategy import SimpleTestStrategy
from juliaos_backtesting.data_bridge import JuliaDataBridge, load_market_data
from juliaos_backtesting.optimizer import StrategyOptimizer
from juliaos_backtesting.visualizer import BacktestVisualizer


def main():
    # Parse command line arguments
    parser = argparse.ArgumentParser(description='JuliaOS Market Making Backtesting Tool')
    parser.add_argument('--symbol', type=str, default='BTCUSDT', help='Trading symbol to backtest')
    parser.add_argument('--timeframe', type=str, default='1h', help='Data timeframe (e.g., 1h, 15m, 1d)')
    parser.add_argument('--days', type=int, default=30, help='Number of days to backtest')
    parser.add_argument('--start', type=str, help='Start date (YYYY-MM-DD)')
    parser.add_argument('--end', type=str, help='End date (YYYY-MM-DD)')
    parser.add_argument('--optimize', action='store_true', help='Run parameter optimization')
    parser.add_argument('--param1', type=str, default='base_spread_pct', help='First parameter to optimize')
    parser.add_argument('--param2', type=str, default='order_levels', help='Second parameter to optimize')
    parser.add_argument('--visualize', action='store_true', help='Generate visualizations')
    parser.add_argument('--save', action='store_true', help='Save results and figures')
    parser.add_argument('--adaptive', action='store_true', help='Use adaptive RL strategy')
    parser.add_argument('--test', action='store_true', help='Use simple test strategy for testing')
    
    args = parser.parse_args()
    
    # Initialize components
    data_bridge = JuliaDataBridge()
    optimizer = StrategyOptimizer(data_bridge)
    visualizer = BacktestVisualizer()
    
    # Set date range
    if args.start:
        start_date = args.start
    else:
        start_date = (datetime.now() - timedelta(days=args.days)).strftime('%Y-%m-%d')
        
    if args.end:
        end_date = args.end
    else:
        end_date = datetime.now().strftime('%Y-%m-%d')
        
    print(f"Backtesting {args.symbol} from {start_date} to {end_date}")
    
    # Load data
    data = load_market_data(args.symbol, args.timeframe, start_date, end_date)
    if data.empty:
        print("Error: No data available for backtesting")
        return
        
    print(f"Loaded {len(data)} bars of {args.symbol} data")
    
    # Get strategy parameters
    params = data_bridge.get_strategy_params()
    
    # Select strategy class
    if args.test:
        strategy_class = SimpleTestStrategy
    else:
        strategy_class = AdaptiveRLMarketMakingStrategy if args.adaptive else RLMarketMakingStrategy
    
    # Run optimization if requested
    if args.optimize:
        print("Running parameter optimization...")
        
        # Define parameter ranges
        param_ranges = {
            'base_spread_pct': (0.05, 0.5, 0.05),
            'order_levels': range(1, 6),
            'volatility_adjustment_factor': (10, 100, 10),
            'rl_volatility_factor': (0.5, 1.5, 0.1),
            'rl_spread_factor': (0.5, 1.5, 0.1),
            'rl_inventory_factor': (0.5, 1.5, 0.1)
        }
        
        # Run optimization
        best_params = optimizer.optimize(
            args.symbol,
            param_ranges,
            args.timeframe,
            start_date,
            end_date,
            method='grid',
            max_tries=100,
            optimize_func='SQN'
        )
        
        print(f"Optimization complete. Best parameters: {best_params}")
        
        # Update parameters with optimized values
        params.update(best_params)
        
        # Save optimization results if requested
        if args.save:
            optimizer.save_optimization_results()
        
        # Visualize optimization results if requested
        if args.visualize:
            # Get heatmap data
            heatmap_data = optimizer.optimization_history
            
            # Create heatmap
            fig, ax = visualizer.plot_optimization_heatmap(
                heatmap_data, 
                args.param1,
                args.param2,
                'SQN'
            )
            
            # Save or show
            if args.save:
                visualizer.save_plot(fig, f"{args.symbol}_optimization_heatmap")
            else:
                plt.show()
    
    # Run backtest
    print("Running backtest with params:", params)
    
    # Create a custom strategy class with the specified parameters
    class CustomStrategy(strategy_class):
        pass
    
    # Set the parameters as class attributes
    for param_name, param_value in params.items():
        if hasattr(strategy_class, param_name):
            setattr(CustomStrategy, param_name, param_value)
    
    # Use higher cash for Bitcoin to avoid fractional trading issues
    initial_cash = 100000 if 'BTC' in args.symbol else 10000
    
    bt = Backtest(data, CustomStrategy, cash=initial_cash, commission=0.001)
    stats = bt.run()
    
    print("\nBacktest Results:")
    print("=================")
    print(f"Start: {stats['Start']}")
    print(f"End: {stats['End']}")
    print(f"Duration: {stats['Duration']}")
    print(f"Exposure Time: {stats['Exposure Time [%]']:.2f}%")
    print(f"Equity Final: ${stats['Equity Final [$]']:.2f}")
    print(f"Equity Peak: ${stats['Equity Peak [$]']:.2f}")
    print(f"Return: {stats['Return [%]']:.2f}%")
    print(f"Buy & Hold Return: {stats['Buy & Hold Return [%]']:.2f}%")
    print(f"Max. Drawdown: {stats['Max. Drawdown [%]']:.2f}%")
    print(f"Avg. Drawdown: {stats['Avg. Drawdown [%]']:.2f}%")
    print(f"# Trades: {stats['# Trades']}")
    print(f"Win Rate: {stats['Win Rate [%]']:.2f}%")
    print(f"Best Trade: {stats['Best Trade [%]']:.2f}%")
    print(f"Worst Trade: {stats['Worst Trade [%]']:.2f}%")
    print(f"Profit Factor: {stats['Profit Factor']:.2f}")
    print(f"Sharpe Ratio: {stats['Sharpe Ratio']:.2f}")
    print(f"Sortino Ratio: {stats['Sortino Ratio']:.2f}")
    print(f"Calmar Ratio: {stats['Calmar Ratio']:.2f}")
    print(f"SQN: {stats['SQN']:.2f}")
    
    # Save backtest results
    if args.save:
        data_bridge.save_backtest_results(stats, args.symbol, params)
    
    # Create visualizations
    if args.visualize:
        # Plot equity curve
        fig1, ax1 = visualizer.plot_equity_curve(stats, f"{args.symbol} Equity Curve")
        
        # Plot drawdowns
        fig2, ax2 = visualizer.plot_drawdowns(stats)
        
        # Plot performance metrics
        fig3, ax3 = visualizer.plot_performance_metrics(stats)
        
        # Save or show plots
        if args.save:
            visualizer.save_plot(fig1, f"{args.symbol}_equity_curve")
            visualizer.save_plot(fig2, f"{args.symbol}_drawdowns")
            visualizer.save_plot(fig3, f"{args.symbol}_performance_metrics")
        else:
            plt.show()
    
    # Show interactive plot if not saving
    if not args.save:
        bt.plot()


if __name__ == '__main__':
    main()
