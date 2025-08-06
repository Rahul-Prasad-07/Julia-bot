#!/usr/bin/env python3
"""
Simple optimization test for Julia integration
"""

import json
import os
import sys
from datetime import datetime

def main():
    # Parse arguments
    args = sys.argv[1:]
    symbol = "ETHUSDT"
    days = 30
    
    for i, arg in enumerate(args):
        if arg == "--symbol" and i + 1 < len(args):
            symbol = args[i + 1]
        elif arg == "--days" and i + 1 < len(args):
            days = int(args[i + 1])
    
    print(f"🔄 Running optimization for {symbol} over {days} days...")
    
    # Simulate optimization results
    optimal_params = {
        "base_spread_pct": 0.18,
        "order_levels": 4,
        "volatility_adjustment_factor": 35,
        "rl_volatility_factor": 1.2,
        "rl_spread_factor": 0.8,
        "rl_inventory_factor": 1.1
    }
    
    # Simulate optimization metrics
    results = {
        "best_params": optimal_params,
        "results": {
            "SQN": 2.45,
            "Sharpe_Ratio": 1.82,
            "Return": 0.234,
            "Max_Drawdown": -0.086
        },
        "history": [
            {"params": optimal_params, "SQN": 2.45}
        ],
        "optimization_time": datetime.now().isoformat(),
        "symbol": symbol,
        "days": days
    }
    
    # Save results
    if "--save" in args:
        results_dir = "optimization_results"
        os.makedirs(results_dir, exist_ok=True)
        
        filepath = os.path.join(results_dir, f"optimization_results_{datetime.now().strftime('%Y%m%d_%H%M%S')}.json")
        
        with open(filepath, "w") as f:
            json.dump(results, f, indent=2)
        
        print(f"✅ Optimization results saved to {filepath}")
    
    print(f"✅ Optimization completed! Best SQN: {results['results']['SQN']}")
    print(f"📊 Optimal parameters: {optimal_params}")
    
    return 0

if __name__ == "__main__":
    sys.exit(main())
