# JuliaOS Backtesting Module
# Integration with backtesting.py for JuliaOS market making strategies

from .market_making_strategy import RLMarketMakingStrategy
from .data_bridge import JuliaDataBridge, load_market_data
from .optimizer import StrategyOptimizer
from .visualizer import BacktestVisualizer

__all__ = [
    'RLMarketMakingStrategy',
    'JuliaDataBridge',
    'load_market_data',
    'StrategyOptimizer',
    'BacktestVisualizer'
]
