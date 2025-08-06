"""
Strategy Optimizer for JuliaOS Market Making
-------------------------------------------
Uses backtesting.py's built-in optimizer to find optimal strategy parameters
and feeds them back to the Julia strategy implementation
"""

import os
import json
import numpy as np
import pandas as pd
from datetime import datetime, timedelta
from typing import Dict, List, Optional, Union, Tuple, Any
from backtesting import Backtest
from backtesting.test import GOOG  # For testing only

from .market_making_strategy import RLMarketMakingStrategy, AdaptiveRLMarketMakingStrategy
from .data_bridge import JuliaDataBridge, load_market_data

class StrategyOptimizer:
    """
    Optimizes market making strategy parameters using backtesting.py
    
    Features:
    - Grid search and random search optimization
    - Genetic algorithm optimization
    - Parameter importance analysis
    - Multiple objective functions
    """
    
    def __init__(self, data_bridge: Optional[JuliaDataBridge] = None):
        """
        Initialize strategy optimizer
        
        Args:
            data_bridge: JuliaDataBridge instance for data exchange
        """
        self.data_bridge = data_bridge or JuliaDataBridge()
        self.results = {}
        self.best_params = {}
        self.optimization_history = []
    
    def optimize(self, symbol: str, 
                 param_ranges: Dict[str, Union[List, Tuple]], 
                 timeframe: str = "1h",
                 start_date: Optional[str] = None,
                 end_date: Optional[str] = None,
                 method: str = "grid",
                 max_tries: int = 100,
                 optimize_func: str = "SQN") -> Dict:
        """
        Optimize strategy parameters
        
        Args:
            symbol: Trading pair symbol
            param_ranges: Dictionary of parameter ranges to test
            timeframe: Data timeframe
            start_date: Backtest start date
            end_date: Backtest end date
            method: Optimization method ("grid", "random", "genetic")
            max_tries: Maximum number of optimization attempts
            optimize_func: Optimization metric ("SQN", "Sharpe", "Return", "Calmar", etc.)
            
        Returns:
            Dict: Best parameters found
        """
        print(f"Optimizing {symbol} strategy parameters using {method} search...")
        
        # Load data
        data = load_market_data(symbol, timeframe, start_date, end_date)
        if data.empty:
            print("Error: No data available for optimization")
            return {}
            
        print(f"Loaded {len(data)} bars of {symbol} data")
        
        # Set up backtest
        strategy_class = AdaptiveRLMarketMakingStrategy
        bt = Backtest(data, strategy_class, cash=10000, commission=0.001)
        
        # Create optimization function based on specified metric
        def optimize_by_metric(sharpe=None, sqn=None, return_pct=None, calmar=None, **kwargs):
            if optimize_func == "Sharpe":
                return sharpe
            elif optimize_func == "SQN":
                return sqn
            elif optimize_func == "Return":
                return return_pct
            elif optimize_func == "Calmar":
                return calmar
            else:
                return sqn  # Default to SQN
                
        # Run optimization
        if method == "grid":
            stats = bt.optimize(
                base_spread_pct=param_ranges.get("base_spread_pct", (0.1, 0.5, 0.05)),
                order_levels=param_ranges.get("order_levels", range(1, 6)),
                volatility_adjustment_factor=param_ranges.get("volatility_adjustment_factor", (10, 100, 10)),
                rl_volatility_factor=param_ranges.get("rl_volatility_factor", (0.5, 1.5, 0.1)),
                rl_spread_factor=param_ranges.get("rl_spread_factor", (0.5, 1.5, 0.1)),
                rl_inventory_factor=param_ranges.get("rl_inventory_factor", (0.5, 1.5, 0.1)),
                maximize=optimize_by_metric,
                max_tries=max_tries,
                constraint=lambda param: param.order_levels * param.base_spread_pct < 1.0
            )
        
        elif method == "random":
            stats = bt.optimize(
                base_spread_pct=param_ranges.get("base_spread_pct", (0.1, 0.5)),
                order_levels=param_ranges.get("order_levels", (1, 5)),
                volatility_adjustment_factor=param_ranges.get("volatility_adjustment_factor", (10, 100)),
                rl_volatility_factor=param_ranges.get("rl_volatility_factor", (0.5, 1.5)),
                rl_spread_factor=param_ranges.get("rl_spread_factor", (0.5, 1.5)),
                rl_inventory_factor=param_ranges.get("rl_inventory_factor", (0.5, 1.5)),
                maximize=optimize_by_metric,
                method="random",
                max_tries=max_tries,
                constraint=lambda param: param.order_levels * param.base_spread_pct < 1.0
            )
            
        else:  # Default to grid search
            stats = bt.optimize(
                base_spread_pct=param_ranges.get("base_spread_pct", (0.1, 0.5, 0.1)),
                order_levels=param_ranges.get("order_levels", range(1, 5)),
                maximize=optimize_by_metric,
                max_tries=max_tries
            )
        
        # Extract best parameters
        self.best_params = {
            param: getattr(stats._strategy, param)
            for param in param_ranges.keys()
        }
        
        # Save optimization results
        self.results = {
            "symbol": symbol,
            "timeframe": timeframe,
            "start_date": start_date,
            "end_date": end_date,
            "method": method,
            "optimize_func": optimize_func,
            "best_params": self.best_params,
            "performance": {
                "return_pct": float(stats["Return [%]"]),
                "sharpe_ratio": float(stats["Sharpe Ratio"]),
                "sqn": float(stats["SQN"]),
                "max_drawdown_pct": float(stats["Max. Drawdown [%]"]),
                "win_rate": float(stats["Win Rate [%]"]),
                "profit_factor": float(stats["Profit Factor"]),
                "total_trades": int(stats["# Trades"])
            },
            "timestamp": datetime.now().isoformat()
        }
        
        # Add to optimization history
        self.optimization_history.append(self.results)
        
        # Export optimized parameters to Julia
        if self.data_bridge:
            export_path = self.data_bridge.export_optimized_params(
                self.best_params, symbol
            )
            if export_path:
                print(f"Exported optimized parameters to {export_path}")
        
        print(f"Optimization complete. Best {optimize_func}: {stats[optimize_func]}")
        print(f"Best parameters: {self.best_params}")
        
        return self.best_params
    
    def analyze_param_importance(self, symbol: str, 
                                param_ranges: Dict[str, Union[List, Tuple]],
                                num_samples: int = 100) -> Dict[str, float]:
        """
        Analyze the importance of different parameters on strategy performance
        
        Args:
            symbol: Trading pair symbol
            param_ranges: Dictionary of parameter ranges to test
            num_samples: Number of random samples to use
            
        Returns:
            Dict: Parameter importance scores
        """
        print(f"Analyzing parameter importance for {symbol} strategy...")
        
        # Load data
        data = load_market_data(symbol)
        if data.empty:
            print("Error: No data available for parameter analysis")
            return {}
        
        # Generate random parameter combinations
        samples = []
        param_values = {}
        
        for param, range_values in param_ranges.items():
            if isinstance(range_values, tuple) and len(range_values) == 2:
                min_val, max_val = range_values
                param_values[param] = np.random.uniform(min_val, max_val, num_samples)
            elif isinstance(range_values, tuple) and len(range_values) == 3:
                min_val, max_val, step = range_values
                param_values[param] = np.arange(min_val, max_val, step)
                np.random.shuffle(param_values[param])
                param_values[param] = param_values[param][:num_samples]
            elif isinstance(range_values, range):
                param_values[param] = np.random.choice(list(range_values), num_samples)
            else:
                param_values[param] = np.random.choice(range_values, num_samples)
        
        # Run backtests with random parameter combinations
        results = []
        strategy_class = AdaptiveRLMarketMakingStrategy
        
        for i in range(num_samples):
            params = {param: param_values[param][i] for param in param_ranges}
            bt = Backtest(data, strategy_class, cash=10000, commission=0.001, **params)
            stats = bt.run()
            
            results.append({
                "params": params,
                "return": stats["Return [%]"],
                "sharpe": stats["Sharpe Ratio"],
                "sqn": stats["SQN"],
                "calmar": stats["Calmar Ratio"]
            })
        
        # Calculate correlation between parameters and results
        importance = {}
        df = pd.DataFrame(results)
        
        for param in param_ranges:
            param_series = pd.Series([r["params"][param] for r in results])
            importance[param] = {
                "return_corr": param_series.corr(df["return"]),
                "sharpe_corr": param_series.corr(df["sharpe"]),
                "sqn_corr": param_series.corr(df["sqn"]),
                "calmar_corr": param_series.corr(df["calmar"])
            }
        
        return importance
    
    def save_optimization_results(self, filepath: Optional[str] = None) -> str:
        """
        Save optimization results to file
        
        Args:
            filepath: Path to save results to
            
        Returns:
            str: Path to saved file
        """
        if not filepath:
            results_dir = os.path.join(
                os.path.dirname(os.path.dirname(os.path.abspath(__file__))),
                "optimization_results"
            )
            os.makedirs(results_dir, exist_ok=True)
            
            filepath = os.path.join(
                results_dir, 
                f"optimization_results_{datetime.now().strftime('%Y%m%d_%H%M%S')}.json"
            )
        
        try:
            with open(filepath, "w") as f:
                json.dump({
                    "results": self.results,
                    "best_params": self.best_params,
                    "history": self.optimization_history
                }, f, indent=2)
            
            print(f"Optimization results saved to {filepath}")
            return filepath
            
        except Exception as e:
            print(f"Error saving optimization results: {e}")
            return ""
