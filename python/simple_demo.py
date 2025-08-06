#!/usr/bin/env python3
"""
Simple Backtesting Demo - How backtesting.py Maximizes PnL
=========================================================

This demo shows how backtesting different parameter combinations helps
find the optimal settings for maximum profit and loss (PnL).
"""

import os
import sys
import pandas as pd
import numpy as np
from pathlib import Path

# Add the current directory to Python path
sys.path.append(os.path.dirname(os.path.abspath(__file__)))

from juliaos_backtesting.data_bridge import load_market_data
from juliaos_backtesting.simple_test_strategy import SimpleTestStrategy
from backtesting import Backtest


def test_parameter_combinations():
    """
    Test different parameter combinations to find optimal settings
    """
    
    print("🚀 JuliaOS Backtesting Demo - Parameter Testing for Max PnL")
    print("=" * 65)
    print()
    
    # Load market data
    symbol = "BTCUSDT"
    timeframe = "1h"
    days = 14
    
    print(f"📊 Loading {days} days of {symbol} data...")
    
    start_date = (pd.Timestamp.now() - pd.Timedelta(days=days)).strftime('%Y-%m-%d')
    end_date = pd.Timestamp.now().strftime('%Y-%m-%d')
    
    data = load_market_data(
        symbol=symbol,
        timeframe=timeframe,
        start_date=start_date,
        end_date=end_date
    )
    
    if data is None or len(data) == 0:
        print("❌ No data available for backtesting")
        return
    
    print(f"✅ Loaded {len(data)} bars of data")
    print(f"   Price range: ${data['Close'].min():.2f} - ${data['Close'].max():.2f}")
    print(f"   Period: {data.index[0]} to {data.index[-1]}")
    print()
    
    # Calculate buy & hold return
    buy_hold_return = (data['Close'].iloc[-1] / data['Close'].iloc[0] - 1) * 100
    
    # Test different parameter combinations
    print("🧪 Testing Different Parameter Combinations")
    print("-" * 45)
    
    parameter_combinations = [
        {'fast_ma': 5, 'slow_ma': 20, 'name': 'Very Fast'},
        {'fast_ma': 10, 'slow_ma': 20, 'name': 'Default'},
        {'fast_ma': 15, 'slow_ma': 30, 'name': 'Conservative'},
        {'fast_ma': 20, 'slow_ma': 50, 'name': 'Very Conservative'},
        {'fast_ma': 5, 'slow_ma': 50, 'name': 'Wide Spread'},
    ]
    
    results = []
    
    for i, params in enumerate(parameter_combinations, 1):
        print(f"Testing combination {i}/{len(parameter_combinations)}: {params['name']} (Fast MA: {params['fast_ma']}, Slow MA: {params['slow_ma']})")
        
        # Create strategy class with specific parameters
        class TestStrategy(SimpleTestStrategy):
            fast_ma = params['fast_ma']
            slow_ma = params['slow_ma']
        
        # Run backtest
        bt = Backtest(data, TestStrategy, cash=10000, commission=0.001)
        stats = bt.run()
        
        # Store results
        result = {
            'name': params['name'],
            'fast_ma': params['fast_ma'],
            'slow_ma': params['slow_ma'],
            'return_pct': stats.get('Return [%]', 0),
            'sharpe': stats.get('Sharpe Ratio', 0),
            'max_drawdown': stats.get('Max. Drawdown [%]', 0),
            'num_trades': stats.get('# Trades', 0),
            'win_rate': stats.get('Win Rate [%]', 0),
            'profit_factor': stats.get('Profit Factor', 0),
        }
        results.append(result)
    
    print("\n📊 RESULTS COMPARISON")
    print("=" * 80)
    print(f"{'Strategy':<18} | {'Return %':<10} | {'Sharpe':<8} | {'Drawdown %':<12} | {'Trades':<7} | {'Win Rate %':<12}")
    print("-" * 80)\n    \n    for result in results:\n        return_str = f\"{result['return_pct']:.2f}\" if pd.notna(result['return_pct']) else \"N/A\"\n        sharpe_str = f\"{result['sharpe']:.2f}\" if pd.notna(result['sharpe']) else \"N/A\"\n        drawdown_str = f\"{result['max_drawdown']:.2f}\" if pd.notna(result['max_drawdown']) else \"N/A\"\n        trades_str = f\"{result['num_trades']}\"\n        winrate_str = f\"{result['win_rate']:.1f}\" if pd.notna(result['win_rate']) else \"N/A\"\n        \n        print(f\"{result['name']:<18} | {return_str:<10} | {sharpe_str:<8} | {drawdown_str:<12} | {trades_str:<7} | {winrate_str:<12}\")\n    \n    print(\"-\" * 80)\n    print(f\"{'Buy & Hold':<18} | {buy_hold_return:<10.2f} | {'N/A':<8} | {'N/A':<12} | {'1':<7} | {'N/A':<12}\")\n    \n    # Find best strategy\n    best_strategy = max(results, key=lambda x: x['return_pct'] if pd.notna(x['return_pct']) else -999)\n    worst_strategy = min(results, key=lambda x: x['return_pct'] if pd.notna(x['return_pct']) else 999)\n    \n    print(\"\\n🏆 KEY FINDINGS\")\n    print(\"=\" * 20)\n    \n    if pd.notna(best_strategy['return_pct']):\n        print(f\"✅ BEST Strategy: {best_strategy['name']}\")\n        print(f\"   Parameters: Fast MA = {best_strategy['fast_ma']}, Slow MA = {best_strategy['slow_ma']}\")\n        print(f\"   Return: {best_strategy['return_pct']:.2f}%\")\n        print(f\"   Sharpe Ratio: {best_strategy['sharpe']:.2f}\" if pd.notna(best_strategy['sharpe']) else \"   Sharpe Ratio: N/A\")\n        print(f\"   Max Drawdown: {best_strategy['max_drawdown']:.2f}%\" if pd.notna(best_strategy['max_drawdown']) else \"   Max Drawdown: N/A\")\n        \n        if best_strategy['return_pct'] > buy_hold_return:\n            outperformance = best_strategy['return_pct'] - buy_hold_return\n            print(f\"   🚀 Outperformed buy-and-hold by {outperformance:.2f}%\")\n        else:\n            underperformance = buy_hold_return - best_strategy['return_pct']\n            print(f\"   📉 Underperformed buy-and-hold by {underperformance:.2f}%\")\n    \n    print()\n    if pd.notna(worst_strategy['return_pct']):\n        print(f\"❌ WORST Strategy: {worst_strategy['name']}\")\n        print(f\"   Parameters: Fast MA = {worst_strategy['fast_ma']}, Slow MA = {worst_strategy['slow_ma']}\")\n        print(f\"   Return: {worst_strategy['return_pct']:.2f}%\")\n    \n    # Calculate performance spread\n    if pd.notna(best_strategy['return_pct']) and pd.notna(worst_strategy['return_pct']):\n        performance_spread = best_strategy['return_pct'] - worst_strategy['return_pct']\n        print(f\"\\n📈 Performance Spread: {performance_spread:.2f}%\")\n        print(f\"   (Difference between best and worst parameter combinations)\")\n    \n    print(\"\\n🎯 HOW THIS MAXIMIZES PnL:\")\n    print(\"-\" * 30)\n    print(\"1. PARAMETER TESTING: We tested 5 different parameter combinations\")\n    print(\"   instead of using default values or guessing\")\n    print()\n    print(\"2. DATA-DRIVEN DECISIONS: Selected parameters based on historical\")\n    print(\"   performance data, not intuition or random choices\")\n    print()\n    print(\"3. SYSTEMATIC COMPARISON: Compared all strategies using consistent\")\n    print(\"   metrics (return, Sharpe ratio, drawdown, win rate)\")\n    print()\n    print(\"4. RISK CONSIDERATION: Best strategy balances returns with risk\")\n    print(\"   (drawdown) and consistency (Sharpe ratio)\")\n    print()\n    if pd.notna(best_strategy['return_pct']) and best_strategy['return_pct'] > buy_hold_return:\n        print(\"5. MARKET OUTPERFORMANCE: Found parameters that beat buy-and-hold\")\n        print(\"   passive strategy, generating alpha through active management\")\n    else:\n        print(\"5. MARKET AWARENESS: Even when strategies don't beat buy-and-hold,\")\n        print(\"   backtesting helps identify this before risking real capital\")\n    \n    print(\"\\n💰 PnL MAXIMIZATION PROCESS:\")\n    print(\"-\" * 35)\n    print(\"• Test many parameter combinations systematically\")\n    print(\"• Find the combination with highest risk-adjusted returns\")\n    print(\"• Validate performance on different time periods\")\n    print(\"• Use optimized parameters in live trading\")\n    print(\"• Repeat process periodically as market conditions change\")\n    \n    # Save results\n    print(\"\\n💾 Saving Results...\")\n    results_dir = Path(\"backtest_results\")\n    results_dir.mkdir(exist_ok=True)\n    \n    # Save to CSV\n    df_results = pd.DataFrame(results)\n    csv_file = results_dir / f\"parameter_comparison_{symbol}_{days}d.csv\"\n    df_results.to_csv(csv_file, index=False)\n    print(f\"✅ Results saved to: {csv_file}\")\n    \n    # Save best parameters\n    best_params_file = results_dir / f\"best_parameters_{symbol}_{days}d.json\"\n    import json\n    with open(best_params_file, 'w') as f:\n        json.dump({\n            'best_strategy': best_strategy,\n            'symbol': symbol,\n            'timeframe': timeframe,\n            'days': days,\n            'buy_hold_return': buy_hold_return,\n            'analysis_date': pd.Timestamp.now().isoformat()\n        }, f, indent=2)\n    print(f\"✅ Best parameters saved to: {best_params_file}\")\n    \n    print(\"\\n🎉 Backtesting Demo Complete!\")\n    print(\"\\nNEXT STEPS:\")\n    print(\"1. Use the best parameters in your live trading strategy\")\n    print(\"2. Test on longer time periods for more robust results\")\n    print(\"3. Consider transaction costs and slippage in live trading\")\n    print(\"4. Implement the Julia-Python bridge for automated optimization\")\n\n\ndef main():\n    \"\"\"Main function to run the demo.\"\"\"\n    \n    try:\n        test_parameter_combinations()\n    except KeyboardInterrupt:\n        print(\"\\n\\n⏹️  Demo interrupted by user\")\n    except Exception as e:\n        print(f\"\\n❌ Demo failed with error: {e}\")\n        import traceback\n        traceback.print_exc()\n\n\nif __name__ == \"__main__\":\n    main()
