"""
Simple Test Strategy for JuliaOS Backtesting System
This is a basic moving average crossover strategy to test the backtesting framework
"""

from backtesting import Strategy
from backtesting.lib import crossover
import pandas as pd
import numpy as np

class SimpleTestStrategy(Strategy):
    """
    Simple moving average crossover strategy for testing
    """
    
    # Strategy parameters
    fast_ma = 10
    slow_ma = 20
    
    def init(self):
        """
        Initialize strategy indicators
        """
        self.ma_fast = self.I(self.sma, self.data.Close, self.fast_ma)
        self.ma_slow = self.I(self.sma, self.data.Close, self.slow_ma)
    
    def next(self):
        """
        Strategy logic executed on each bar
        """
        # Buy when fast MA crosses above slow MA
        if crossover(self.ma_fast, self.ma_slow):
            # Use 50% of equity
            self.buy(size=0.5)
        
        # Sell when fast MA crosses below slow MA
        elif crossover(self.ma_slow, self.ma_fast):
            if self.position:
                self.position.close()
    
    def sma(self, values, period):
        """
        Simple Moving Average
        """
        values_series = pd.Series(values)
        return values_series.rolling(period).mean().values
