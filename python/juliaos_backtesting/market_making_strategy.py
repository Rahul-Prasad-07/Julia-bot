"""
RLMarketMakingStrategy for backtesting.py
----------------------------------------
Implements a market making strategy compatible with backtesting.py
that mirrors the behavior of the Julia-based RL market making strategy
"""

from backtesting import Strategy
from backtesting.lib import crossover, TrailingStrategy
import numpy as np
import pandas as pd
from typing import Dict, List, Optional, Union, Tuple, Any

class RLMarketMakingStrategy(Strategy):
    """
    Reinforcement Learning enhanced Market Making Strategy that mirrors
    the Julia strategy_rl_market_making.jl implementation
    
    This strategy implements:
    - Dynamic spread adjustment based on volatility
    - Inventory management
    - RL-based parameter optimization
    - Multiple order levels
    - Stop loss and take profit mechanisms
    """
    
    # Strategy parameters with defaults
    base_spread_pct = 0.15        # Base spread percentage
    ask_spread_pct = 0.15         # Ask spread might differ from bid
    order_levels = 3              # Number of order levels per side
    order_amount = 0.1            # Base order size as fraction of capital
    max_capital = 10000.0         # Maximum capital to deploy
    leverage = 20                 # Leverage multiplier
    inventory_target_pct = 50.0   # Target inventory percentage (50% = neutral)
    
    # Dynamic features
    enable_dynamic_spreads = True  # Adjust spreads based on volatility
    enable_inventory_skew = True   # Skew orders based on inventory
    min_spread_pct = 0.05          # Minimum spread percentage
    max_spread_pct = 2.0           # Maximum spread percentage
    volatility_adjustment_factor = 50.0  # Volatility impact on spreads
    
    # Risk parameters
    max_drawdown = 0.15           # Maximum portfolio drawdown (15%)
    stop_loss_threshold = 0.006   # Stop-loss threshold (0.6% for 20x leverage)
    take_profit_threshold = 0.005 # Take-profit threshold (0.5% for 20x leverage)
    
    # RL parameters
    rl_volatility_factor = 1.0    # RL-adjusted volatility factor
    rl_spread_factor = 1.0        # RL-adjusted spread factor
    rl_inventory_factor = 1.0     # RL-adjusted inventory factor
    
    def init(self):
        """
        Initialize strategy indicators and variables
        """
        # Price data
        self.price = self.data.Close
        
        # Calculate volatility indicators (ATR and Bollinger Bands)
        self.atr = self.I(self.calculate_atr, self.data.High, self.data.Low, self.data.Close, 14)
        self.bb_upper, self.bb_lower, self.bb_width = self.I(self.calculate_bollinger_bands, self.price, 20, 2.0)
        
        # Track inventory and capital
        self.inventory = 0
        self.inventory_value = 0
        self.available_capital = self.max_capital
        self.position_value = 0
        
        # Track spread and levels
        self.current_spread = self.base_spread_pct
        self.bid_levels = []
        self.ask_levels = []
        
        # Track orders
        self.active_orders = {}
        self.executed_orders = []
        
        # Performance tracking
        self.trade_log = []  # Use different name to avoid conflict
        self.daily_pnl = []
        self.drawdowns = []
    
    def next(self):
        """
        Main strategy logic executed on each price update
        """
        # Calculate dynamic spread based on volatility
        current_volatility = self.atr[-1] / self.price[-1]
        
        if self.enable_dynamic_spreads:
            # Adjust spread based on volatility
            vol_adjusted_spread = self.base_spread_pct * (1 + self.volatility_adjustment_factor * 
                                                         current_volatility * self.rl_volatility_factor)
            # Ensure within bounds
            self.current_spread = max(self.min_spread_pct, 
                                      min(vol_adjusted_spread, self.max_spread_pct))
        else:
            self.current_spread = self.base_spread_pct
        
        # Adjust for RL factors
        self.current_spread *= self.rl_spread_factor
        
        # Calculate inventory ratio (0-100%)
        if self.position and self.position.size != 0:
            self.inventory = self.position.size
            self.position_value = self.inventory * self.price[-1]
            total_value = self.position_value + self.available_capital
            self.inventory_ratio = (self.position_value / total_value) * 100
        else:
            self.inventory = 0
            self.position_value = 0
            self.inventory_ratio = 0
        
        # Inventory skew adjustments
        bid_skew = 1.0
        ask_skew = 1.0
        
        if self.enable_inventory_skew:
            # Adjust skew based on inventory vs target
            inventory_deviation = self.inventory_ratio - self.inventory_target_pct
            skew_factor = abs(inventory_deviation) / 50.0  # Normalize to 0-1 range
            
            # Apply RL factor to inventory management
            skew_factor *= self.rl_inventory_factor
            
            if inventory_deviation > 0:  # We have more inventory than target
                # Increase sell (ask) orders, decrease buy (bid) orders
                ask_skew = 1.0 - (skew_factor * 0.5)  # Tighter ask spread
                bid_skew = 1.0 + (skew_factor * 0.5)  # Wider bid spread
            else:  # We have less inventory than target
                # Increase buy (bid) orders, decrease sell (ask) orders
                bid_skew = 1.0 - (skew_factor * 0.5)  # Tighter bid spread
                ask_skew = 1.0 + (skew_factor * 0.5)  # Wider ask spread
        
        # Calculate spread-adjusted bid and ask prices
        bid_spread = self.current_spread * bid_skew
        ask_spread = self.current_spread * ask_skew
        
        # Generate order levels
        self.bid_levels = []
        self.ask_levels = []
        
        for level in range(1, self.order_levels + 1):
            # Progressively wider spreads for further levels
            level_factor = 1.0 + (level - 1) * 0.5
            
            # Calculate bid and ask prices
            bid_price = self.price[-1] * (1 - bid_spread * level_factor)
            ask_price = self.price[-1] * (1 + ask_spread * level_factor)
            
            # Calculate order size (decrease size for further levels)
            size_factor = 1.0 / level
            bid_size = self.order_amount * size_factor
            ask_size = self.order_amount * size_factor
            
            # Adjust for inventory skew
            if self.enable_inventory_skew:
                inventory_factor = (self.inventory_target_pct - self.inventory_ratio) / 100.0
                size_adjustment = 1.0 + (inventory_factor * self.rl_inventory_factor)
                
                # Apply bounds to size adjustments
                size_adjustment = max(0.5, min(size_adjustment, 1.5))
                
                bid_size *= size_adjustment
                ask_size *= (2.0 - size_adjustment)  # Inverse relationship
            
            # Store order levels
            self.bid_levels.append((bid_price, bid_size))
            self.ask_levels.append((ask_price, ask_size))
        
        # Check for existing position
        if self.position:
            # Implement stop loss and take profit
            entry_price = self.position.entry_price
            current_price = self.price[-1]
            
            if self.position.is_long:
                # Stop loss for long position
                if current_price < entry_price * (1 - self.stop_loss_threshold):
                    self.position.close()
                    return
                
                # Take profit for long position
                elif current_price > entry_price * (1 + self.take_profit_threshold):
                    self.position.close()
                    return
                    
            else:  # Short position
                # Stop loss for short position
                if current_price > entry_price * (1 + self.stop_loss_threshold):
                    self.position.close()
                    return
                    
                # Take profit for short position
                elif current_price < entry_price * (1 - self.take_profit_threshold):
                    self.position.close()
                    return
        
        # Execute market making orders
        self._execute_orders()
    
    def _execute_orders(self):
        """
        Execute market making orders based on calculated levels
        """
        # Close any existing position before placing new orders
        if self.position:
            # Only close if we need to reverse direction
            current_inventory_sign = 1 if self.inventory > 0 else -1 if self.inventory < 0 else 0
            
            # Determine if we need to completely reverse position
            needs_reversal = False
            
            for price, size in self.bid_levels:
                if price >= self.price[-1] and current_inventory_sign < 0:
                    needs_reversal = True
                    break
                    
            for price, size in self.ask_levels:
                if price <= self.price[-1] and current_inventory_sign > 0:
                    needs_reversal = True
                    break
            
            if needs_reversal:
                self.position.close()
        
        # Execute bid orders (buy)
        for price, size in self.bid_levels:
            if price >= self.price[-1]:  # Only execute if price crosses our bid
                self.buy(size=size)
        
        # Execute ask orders (sell)
        for price, size in self.ask_levels:
            if price <= self.price[-1]:  # Only execute if price crosses our ask
                self.sell(size=size)
    
    def calculate_atr(self, high, low, close, period=14):
        """
        Calculate Average True Range
        """
        # Convert to pandas Series for easier manipulation
        high_series = pd.Series(high)
        low_series = pd.Series(low)
        close_series = pd.Series(close)
        
        tr1 = high_series - low_series
        tr2 = abs(high_series - close_series.shift(1))
        tr3 = abs(low_series - close_series.shift(1))
        
        tr = pd.DataFrame({'tr1': tr1, 'tr2': tr2, 'tr3': tr3}).max(axis=1)
        atr = tr.rolling(period).mean()
        
        return atr.values  # Return numpy array
    
    def calculate_bollinger_bands(self, price, period=20, std_dev=2.0):
        """
        Calculate Bollinger Bands
        """
        # Convert to pandas Series for easier manipulation
        price_series = pd.Series(price)
        
        middle = price_series.rolling(period).mean()
        std = price_series.rolling(period).std()
        
        upper = middle + (std_dev * std)
        lower = middle - (std_dev * std)
        
        # Calculate bandwidth
        width = (upper - lower) / middle
        
        return upper.values, lower.values, width.values  # Return numpy arrays


class AdaptiveRLMarketMakingStrategy(RLMarketMakingStrategy):
    """
    Enhanced version with adaptive RL features
    """
    
    # RL specific parameters
    learning_rate = 0.01
    exploration_rate = 0.1
    reward_function = "sharpe_ratio"  # "sharpe_ratio", "profit", "risk_adjusted"
    
    def init(self):
        """
        Initialize with additional RL components
        """
        super().init()
        
        # RL state tracking
        self.states = []
        self.actions = []
        self.rewards = []
        
        # RL memory for learning
        self.memory = []
        self.memory_max_size = 1000
        
        # RL parameters that can be optimized
        self.rl_params = {
            "volatility_factor": self.rl_volatility_factor,
            "spread_factor": self.rl_spread_factor,
            "inventory_factor": self.rl_inventory_factor
        }
    
    def next(self):
        """
        Enhanced next method with RL components
        """
        # Record current state
        current_state = self._get_state()
        self.states.append(current_state)
        
        # Get action from RL policy or exploration
        if np.random.random() < self.exploration_rate:
            # Explore: Random adjustment to parameters
            self._explore_action()
        else:
            # Exploit: Use current best parameters
            pass  # Using current parameters
        
        # Execute standard strategy logic
        super().next()
        
        # Calculate reward
        reward = self._calculate_reward()
        self.rewards.append(reward)
        
        # Store experience in memory
        if len(self.states) > 1:
            experience = {
                "state": self.states[-2],
                "action": self.rl_params.copy(),
                "reward": reward,
                "next_state": current_state
            }
            self._add_to_memory(experience)
    
    def _get_state(self) -> Dict[str, float]:
        """
        Get current state representation for RL
        """
        return {
            "price": float(self.price[-1]),
            "volatility": float(self.atr[-1] / self.price[-1]),
            "bb_width": float(self.bb_width[-1]),
            "inventory_ratio": float(self.inventory_ratio),
            "spread": float(self.current_spread),
            "capital_ratio": float(self.available_capital / self.max_capital)
        }
    
    def _explore_action(self):
        """
        Explore new parameter settings
        """
        # Randomly adjust RL factors
        self.rl_volatility_factor = max(0.5, min(1.5, self.rl_volatility_factor * (1 + np.random.uniform(-0.1, 0.1))))
        self.rl_spread_factor = max(0.5, min(1.5, self.rl_spread_factor * (1 + np.random.uniform(-0.1, 0.1))))
        self.rl_inventory_factor = max(0.5, min(1.5, self.rl_inventory_factor * (1 + np.random.uniform(-0.1, 0.1))))
        
        # Update RL params dictionary
        self.rl_params = {
            "volatility_factor": self.rl_volatility_factor,
            "spread_factor": self.rl_spread_factor,
            "inventory_factor": self.rl_inventory_factor
        }
    
    def _calculate_reward(self) -> float:
        """
        Calculate reward based on selected reward function
        """
        # Default to simple PnL reward
        reward = 0.0
        
        # Only calculate if we have a position
        if self.position:
            # Calculate unrealized PnL
            if self.position.is_long:
                pnl = (self.price[-1] - self.position.entry_price) * self.position.size
            else:
                pnl = (self.position.entry_price - self.price[-1]) * self.position.size
            
            if self.reward_function == "sharpe_ratio":
                # Simple Sharpe approximation
                if len(self.daily_pnl) > 1:
                    mean_pnl = np.mean(self.daily_pnl[-20:]) if len(self.daily_pnl) >= 20 else np.mean(self.daily_pnl)
                    std_pnl = np.std(self.daily_pnl[-20:]) if len(self.daily_pnl) >= 20 else np.std(self.daily_pnl)
                    if std_pnl > 0:
                        reward = mean_pnl / std_pnl
                    else:
                        reward = pnl
                else:
                    reward = pnl
            
            elif self.reward_function == "risk_adjusted":
                # Risk-adjusted return
                if self.position_value > 0:
                    reward = pnl / self.position_value
                else:
                    reward = pnl
            
            else:  # Default to profit
                reward = pnl
        
        # Store daily PnL for tracking
        if len(self.daily_pnl) == 0 or self.data.index[-1].date() != self.data.index[-2].date():
            self.daily_pnl.append(reward)
        else:
            self.daily_pnl[-1] += reward
        
        return reward
    
    def _add_to_memory(self, experience: Dict[str, Any]):
        """
        Add experience to memory with capacity management
        """
        self.memory.append(experience)
        
        # Limit memory size
        if len(self.memory) > self.memory_max_size:
            self.memory.pop(0)
