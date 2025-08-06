"""
JuliaOS Data Bridge
------------------
Connects Julia market making system with Python backtesting.py library
Handles data conversion, parameter passing, and cross-language communication
"""

import os
import json
import numpy as np
import pandas as pd
from datetime import datetime, timedelta
from typing import Dict, List, Optional, Union, Tuple

class JuliaDataBridge:
    """
    Bridge between Julia market making system and Python backtesting.py
    
    Handles:
    - Data conversion between Julia and Python formats
    - Market data transfer from Julia to Python
    - Strategy parameter synchronization
    - Results communication back to Julia
    """
    
    def __init__(self, config_path: Optional[str] = None):
        """
        Initialize the data bridge
        
        Args:
            config_path: Path to Julia market making config TOML file
        """
        self.config_path = config_path or os.path.join(
            os.path.dirname(os.path.dirname(os.path.dirname(os.path.abspath(__file__)))),
            "config", "market_making.toml"
        )
        self.config = self._load_config()
        self.data_cache = {}
        
    def _load_config(self) -> Dict:
        """Load configuration from TOML file"""
        import tomli  # Import here to make dependency optional
        
        try:
            with open(self.config_path, "rb") as f:
                config = tomli.load(f)
            return config
        except Exception as e:
            print(f"Error loading config from {self.config_path}: {e}")
            return {}
            
    def get_symbols(self) -> List[str]:
        """Get list of trading symbols from config"""
        try:
            return self.config.get("strategy", {}).get("symbols", ["ETHUSDT", "BTCUSDT"])
        except:
            return ["ETHUSDT", "BTCUSDT"]
    
    def get_strategy_params(self) -> Dict:
        """Get strategy parameters from config"""
        strategy_params = {}
        
        try:
            strategy_section = self.config.get("strategy", {})
            strategy_params = {
                "base_spread_pct": float(strategy_section.get("base_spread_pct", 0.15)),
                "ask_spread_pct": float(strategy_section.get("ask_spread_pct", 0.15)),
                "order_levels": int(strategy_section.get("order_levels", 3)),
                "order_amount": float(strategy_section.get("order_amount", 0.1)),
                "max_capital": float(strategy_section.get("max_capital", 10000.0)),
                "leverage": int(strategy_section.get("leverage", 20)),
                "inventory_target_pct": float(strategy_section.get("inventory_target_pct", 50.0)),
                "enable_dynamic_spreads": bool(strategy_section.get("enable_dynamic_spreads", True)),
                "enable_inventory_skew": bool(strategy_section.get("enable_inventory_skew", True)),
                "min_spread_pct": float(strategy_section.get("min_spread_pct", 0.05)),
                "max_spread_pct": float(strategy_section.get("max_spread_pct", 2.0)),
            }
            
            # Risk parameters
            risk_section = self.config.get("risk_management", {})
            risk_params = {
                "max_drawdown": float(risk_section.get("max_drawdown", 0.15)),
                "max_position_size": float(risk_section.get("max_position_size", 100000.0)),
                "stop_loss_threshold": float(risk_section.get("stop_loss_threshold", 0.006)),
                "take_profit_threshold": float(risk_section.get("take_profit_threshold", 0.005)),
            }
            
            strategy_params.update(risk_params)
            
            # Backtesting parameters
            backtest_start = strategy_section.get("backtest_start_date", "2024-01-01")
            backtest_end = strategy_section.get("backtest_end_date", "2024-12-31")
            backtest_timeframe = strategy_section.get("backtest_timeframe", "1h")
            
            strategy_params.update({
                "backtest_start_date": backtest_start,
                "backtest_end_date": backtest_end,
                "backtest_timeframe": backtest_timeframe
            })
            
        except Exception as e:
            print(f"Error extracting strategy parameters: {e}")
        
        return strategy_params
    
    def save_backtest_results(self, results: Dict, symbol: str, strategy_params: Dict) -> bool:
        """
        Save backtest results in a format Julia can read
        
        Args:
            results: Dictionary containing backtest results
            symbol: Trading pair symbol
            strategy_params: Strategy parameters used for the backtest
            
        Returns:
            bool: Success or failure
        """
        try:
            # Create results directory if it doesn't exist
            results_dir = os.path.join(
                os.path.dirname(os.path.dirname(os.path.abspath(__file__))),
                "backtest_results"
            )
            os.makedirs(results_dir, exist_ok=True)
            
            # Format results
            formatted_results = {
                "symbol": symbol,
                "strategy_params": strategy_params,
                "backtest_results": {
                    "equity_final": float(results._equity_final),
                    "equity_peak": float(results._equity_peak),
                    "return_pct": float(results["Return [%]"]),
                    "sharpe_ratio": float(results["Sharpe Ratio"]),
                    "sortino_ratio": float(results["Sortino Ratio"]),
                    "calmar_ratio": float(results["Calmar Ratio"]),
                    "max_drawdown_pct": float(results["Max. Drawdown [%]"]),
                    "win_rate": float(results["Win Rate [%]"]),
                    "best_trade_pct": float(results["Best Trade [%]"]),
                    "worst_trade_pct": float(results["Worst Trade [%]"]),
                    "avg_trade_pct": float(results["Avg. Trade [%]"]),
                    "profit_factor": float(results["Profit Factor"]),
                    "expectancy_pct": float(results["Expectancy [%]"]),
                    "sqn": float(results["SQN"]),
                    "total_trades": int(results["# Trades"]),
                    "exposure_time_pct": float(results["Exposure Time [%]"]),
                },
                "timestamp": datetime.now().isoformat()
            }
            
            # Extract equity curve if available
            if hasattr(results, "_equity_curve") and isinstance(results._equity_curve, pd.DataFrame):
                equity_data = results._equity_curve["Equity"].tolist()
                formatted_results["backtest_results"]["equity_curve"] = equity_data
            
            # Save to file
            filename = f"{symbol}_backtest_{datetime.now().strftime('%Y%m%d_%H%M%S')}.json"
            filepath = os.path.join(results_dir, filename)
            
            with open(filepath, "w") as f:
                json.dump(formatted_results, f, indent=2)
                
            print(f"Backtest results saved to {filepath}")
            return True
            
        except Exception as e:
            print(f"Error saving backtest results: {e}")
            return False

    def export_optimized_params(self, params: Dict, symbol: str) -> str:
        """
        Export optimized parameters for Julia to use
        
        Args:
            params: Dictionary of optimized parameters
            symbol: Trading pair symbol
            
        Returns:
            str: Path to saved parameter file
        """
        try:
            # Create params directory if it doesn't exist
            params_dir = os.path.join(
                os.path.dirname(os.path.dirname(os.path.abspath(__file__))),
                "optimized_params"
            )
            os.makedirs(params_dir, exist_ok=True)
            
            # Format parameters
            formatted_params = {
                "symbol": symbol,
                "optimized_params": params,
                "timestamp": datetime.now().isoformat()
            }
            
            # Save to file
            filename = f"{symbol}_optimized_params_{datetime.now().strftime('%Y%m%d_%H%M%S')}.json"
            filepath = os.path.join(params_dir, filename)
            
            with open(filepath, "w") as f:
                json.dump(formatted_params, f, indent=2)
                
            print(f"Optimized parameters saved to {filepath}")
            return filepath
            
        except Exception as e:
            print(f"Error exporting optimized parameters: {e}")
            return ""


def load_market_data(symbol: str, timeframe: str = "1h", 
                     start_date: str = None, end_date: str = None,
                     source: str = "binance") -> pd.DataFrame:
    """
    Load market data from various sources
    
    Args:
        symbol: Trading pair symbol (e.g., "BTCUSDT")
        timeframe: Data timeframe (e.g., "1h", "15m", "1d")
        start_date: Start date in YYYY-MM-DD format
        end_date: End date in YYYY-MM-DD format
        source: Data source ("binance", "file", etc.)
        
    Returns:
        pd.DataFrame: OHLCV data formatted for backtesting.py
    """
    # Default date range if not provided
    if not start_date:
        start_date = (datetime.now() - timedelta(days=30)).strftime("%Y-%m-%d")
    if not end_date:
        end_date = datetime.now().strftime("%Y-%m-%d")
    
    if source == "binance":
        try:
            # Using ccxt for data fetching
            import ccxt
            
            # Initialize exchange
            exchange = ccxt.binanceusdm({
                'enableRateLimit': True,
            })
            
            # Convert timeframe to milliseconds
            timeframe_map = {
                '1m': 60 * 1000,
                '5m': 5 * 60 * 1000,
                '15m': 15 * 60 * 1000,
                '30m': 30 * 60 * 1000,
                '1h': 60 * 60 * 1000,
                '4h': 4 * 60 * 60 * 1000,
                '1d': 24 * 60 * 60 * 1000,
            }
            
            # Convert dates to timestamps
            since = int(datetime.strptime(start_date, "%Y-%m-%d").timestamp() * 1000)
            until = int(datetime.strptime(end_date, "%Y-%m-%d").timestamp() * 1000)
            
            # Fetch OHLCV data
            all_candles = []
            current_since = since
            
            while current_since < until:
                candles = exchange.fetch_ohlcv(symbol, timeframe, current_since)
                if not candles:
                    break
                
                all_candles.extend(candles)
                if len(candles) == 0:
                    break
                
                # Update since to fetch next batch
                current_since = candles[-1][0] + timeframe_map.get(timeframe, 60 * 60 * 1000)
            
            # Convert to DataFrame
            df = pd.DataFrame(all_candles, columns=['time', 'Open', 'High', 'Low', 'Close', 'Volume'])
            df['time'] = pd.to_datetime(df['time'], unit='ms')
            df.set_index('time', inplace=True)
            
            # Ensure required columns for backtesting.py
            required_cols = ['Open', 'High', 'Low', 'Close', 'Volume']
            for col in required_cols:
                if col not in df.columns:
                    if col != 'Volume':  # Volume might be missing in some data sources
                        raise ValueError(f"Required column {col} missing from data")
            
            return df
            
        except ImportError:
            print("ccxt library not installed. Please install with: pip install ccxt")
            return pd.DataFrame()
            
        except Exception as e:
            print(f"Error fetching data from Binance: {e}")
            return pd.DataFrame()
    
    elif source == "file":
        try:
            # Check if a CSV file exists for this symbol
            file_path = os.path.join(
                os.path.dirname(os.path.dirname(os.path.abspath(__file__))),
                "data",
                f"{symbol}_{timeframe}.csv"
            )
            
            if os.path.exists(file_path):
                df = pd.read_csv(file_path)
                if 'time' in df.columns:
                    df['time'] = pd.to_datetime(df['time'])
                    df.set_index('time', inplace=True)
                
                # Filter by date range
                start_dt = pd.to_datetime(start_date)
                end_dt = pd.to_datetime(end_date)
                df = df[(df.index >= start_dt) & (df.index <= end_dt)]
                
                return df
            else:
                print(f"No data file found at {file_path}")
                return pd.DataFrame()
                
        except Exception as e:
            print(f"Error loading data from file: {e}")
            return pd.DataFrame()
    
    else:
        print(f"Unsupported data source: {source}")
        return pd.DataFrame()
