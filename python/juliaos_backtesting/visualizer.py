"""
BacktestVisualizer for JuliaOS Market Making
-------------------------------------------
Provides enhanced visualization tools for backtesting.py results
with specific focus on market making metrics
"""

import os
import json
import numpy as np
import pandas as pd
import matplotlib.pyplot as plt
import matplotlib.dates as mdates
from matplotlib.ticker import FuncFormatter
import seaborn as sns
from datetime import datetime, timedelta
from typing import Dict, List, Optional, Union, Tuple, Any
from backtesting import Backtest
from backtesting._plotting import plot_heatmaps

class BacktestVisualizer:
    """
    Enhanced visualization tools for backtesting.py results
    
    Features:
    - Equity curve visualization
    - Drawdown analysis
    - Order book heatmap visualization
    - Parameter optimization heatmaps
    - Performance comparisons
    - Intraday PnL analysis
    """
    
    def __init__(self):
        """
        Initialize the visualizer
        """
        self.theme = "darkgrid"  # Default theme
        sns.set_theme(style=self.theme)
        
        # Set matplotlib defaults
        plt.rcParams['figure.figsize'] = (14, 8)
        plt.rcParams['axes.grid'] = True
        plt.rcParams['grid.alpha'] = 0.3
        
        # Directory for saving figures
        self.output_dir = os.path.join(
            os.path.dirname(os.path.dirname(os.path.abspath(__file__))),
            "visualizations"
        )
        os.makedirs(self.output_dir, exist_ok=True)
    
    def set_theme(self, theme: str = "darkgrid"):
        """
        Set visualization theme
        
        Args:
            theme: Theme name (darkgrid, whitegrid, dark, white, ticks)
        """
        self.theme = theme
        sns.set_theme(style=theme)
    
    def plot_equity_curve(self, results, title: str = "Equity Curve", 
                         show_drawdowns: bool = True, 
                         show_trades: bool = True):
        """
        Plot equity curve with drawdowns and trades
        
        Args:
            results: Backtest results object
            title: Plot title
            show_drawdowns: Whether to show drawdowns
            show_trades: Whether to show individual trades
        """
        fig, ax = plt.subplots(figsize=(14, 8))
        
        # Extract equity curve
        equity = results._equity_curve['Equity']
        equity_idx = equity.index
        
        # Plot equity curve
        ax.plot(equity_idx, equity, label='Equity', linewidth=2)
        
        # Plot drawdowns if requested
        if show_drawdowns and 'DrawdownPct' in results._equity_curve.columns:
            dd = results._equity_curve['DrawdownPct']
            ddax = ax.twinx()
            ddax.fill_between(dd.index, 0, -dd*100, alpha=0.3, color='crimson', label='Drawdown %')
            ddax.set_ylabel('Drawdown %')
            ddax.set_ylim(min(-dd*100)*1.5, 0)
            
            # Format y-axis as percentage
            ddax.yaxis.set_major_formatter(FuncFormatter(lambda y, _: f'{y:.0f}%'))
        
        # Plot trades if requested
        if show_trades and hasattr(results, '_trades') and len(results._trades):
            trades = results._trades
            
            # Long trades
            long_trades = trades[trades['Size'] > 0]
            if len(long_trades):
                entry_points = long_trades['EntryBar'].values
                exit_points = long_trades['ExitBar'].values
                entry_prices = long_trades['EntryPrice'].values
                exit_prices = long_trades['ExitPrice'].values
                
                for i, (entry, exit, entry_price, exit_price) in enumerate(zip(entry_points, exit_points, entry_prices, exit_prices)):
                    if entry < len(equity_idx) and exit < len(equity_idx):
                        profit = (exit_price - entry_price) / entry_price
                        color = 'green' if profit > 0 else 'red'
                        ax.plot([equity_idx[entry], equity_idx[exit]], 
                                [equity[entry], equity[exit]], 
                                color=color, linestyle='--', alpha=0.5)
            
            # Short trades
            short_trades = trades[trades['Size'] < 0]
            if len(short_trades):
                entry_points = short_trades['EntryBar'].values
                exit_points = short_trades['ExitBar'].values
                entry_prices = short_trades['EntryPrice'].values
                exit_prices = short_trades['ExitPrice'].values
                
                for i, (entry, exit, entry_price, exit_price) in enumerate(zip(entry_points, exit_points, entry_prices, exit_prices)):
                    if entry < len(equity_idx) and exit < len(equity_idx):
                        profit = (entry_price - exit_price) / entry_price
                        color = 'green' if profit > 0 else 'red'
                        ax.plot([equity_idx[entry], equity_idx[exit]], 
                                [equity[entry], equity[exit]], 
                                color=color, linestyle='--', alpha=0.5)
        
        # Format x-axis dates
        ax.xaxis.set_major_formatter(mdates.DateFormatter('%Y-%m-%d'))
        ax.xaxis.set_major_locator(mdates.AutoDateLocator())
        plt.xticks(rotation=45)
        
        # Set labels and title
        ax.set_title(title, fontsize=16)
        ax.set_ylabel('Equity')
        ax.set_xlabel('Date')
        
        # Add performance metrics in the plot
        metrics_text = (
            f"Return: {results['Return [%]']:.2f}%\n"
            f"Sharpe: {results['Sharpe Ratio']:.2f}\n"
            f"Sortino: {results['Sortino Ratio']:.2f}\n"
            f"Max DD: {results['Max. Drawdown [%]']:.2f}%\n"
            f"Win Rate: {results['Win Rate [%]']:.1f}%\n"
            f"# Trades: {results['# Trades']}"
        )
        
        # Position the text box in figure coords
        props = dict(boxstyle='round', facecolor='white', alpha=0.8)
        ax.text(0.02, 0.97, metrics_text, transform=ax.transAxes, fontsize=11,
                verticalalignment='top', bbox=props)
        
        # Adjust layout and show plot
        plt.tight_layout()
        
        return fig, ax
    
    def plot_drawdowns(self, results, top_n: int = 5):
        """
        Plot the top drawdowns
        
        Args:
            results: Backtest results object
            top_n: Number of top drawdowns to show
        """
        if 'DrawdownPct' not in results._equity_curve.columns:
            print("No drawdown data available")
            return
            
        # Get drawdown data
        dd = results._equity_curve['DrawdownPct']
        
        # Find drawdown periods
        drawdown_periods = []
        in_drawdown = False
        start_idx = None
        peak_equity = 0
        
        for i, (date, value) in enumerate(dd.items()):
            if not in_drawdown and value < 0:
                # Start of drawdown
                in_drawdown = True
                start_idx = i
                peak_equity = results._equity_curve['Equity'][i-1] if i > 0 else results._equity_curve['Equity'][i]
                
            elif in_drawdown and value == 0:
                # End of drawdown
                in_drawdown = False
                end_idx = i
                
                # Calculate drawdown statistics
                min_idx = dd[start_idx:end_idx+1].idxmin()
                max_dd = dd[min_idx]
                recovery_duration = (dd.index[end_idx] - min_idx).days
                drawdown_duration = (min_idx - dd.index[start_idx]).days
                total_duration = (dd.index[end_idx] - dd.index[start_idx]).days
                
                drawdown_periods.append({
                    'start': dd.index[start_idx],
                    'bottom': min_idx,
                    'end': dd.index[end_idx],
                    'max_dd': max_dd,
                    'peak_equity': peak_equity,
                    'bottom_equity': results._equity_curve['Equity'][min_idx],
                    'recovery_equity': results._equity_curve['Equity'][end_idx],
                    'drawdown_duration': drawdown_duration,
                    'recovery_duration': recovery_duration,
                    'total_duration': total_duration
                })
        
        # Handle case where we're still in drawdown at the end
        if in_drawdown:
            end_idx = len(dd) - 1
            min_idx = dd[start_idx:end_idx+1].idxmin()
            max_dd = dd[min_idx]
            
            drawdown_duration = (min_idx - dd.index[start_idx]).days
            total_duration = (dd.index[end_idx] - dd.index[start_idx]).days
            
            drawdown_periods.append({
                'start': dd.index[start_idx],
                'bottom': min_idx,
                'end': dd.index[end_idx],
                'max_dd': max_dd,
                'peak_equity': peak_equity,
                'bottom_equity': results._equity_curve['Equity'][min_idx],
                'recovery_equity': None,
                'drawdown_duration': drawdown_duration,
                'recovery_duration': None,
                'total_duration': total_duration
            })
        
        # Sort by max drawdown
        drawdown_periods.sort(key=lambda x: x['max_dd'])
        top_drawdowns = drawdown_periods[:top_n]
        
        # Plot
        fig, axs = plt.subplots(top_n, 1, figsize=(14, 4*top_n))
        
        if top_n == 1:
            axs = [axs]  # Make iterable
            
        for i, dd_period in enumerate(top_drawdowns):
            ax = axs[i]
            
            # Get data for this period
            start_date = dd_period['start']
            end_date = dd_period['end']
            
            # Add some buffer before and after
            buffer_days = (end_date - start_date).days // 5
            buffer_days = max(5, buffer_days)  # At least 5 days
            
            start_date_with_buffer = start_date - timedelta(days=buffer_days)
            end_date_with_buffer = end_date + timedelta(days=buffer_days)
            
            # Get slice of equity curve
            equity_slice = results._equity_curve['Equity'][
                (results._equity_curve.index >= start_date_with_buffer) & 
                (results._equity_curve.index <= end_date_with_buffer)
            ]
            
            # Plot equity during this period
            ax.plot(equity_slice.index, equity_slice, label='Equity', linewidth=2)
            
            # Mark key points
            ax.axvline(x=start_date, color='green', linestyle='--', alpha=0.7, label='Drawdown Start')
            ax.axvline(x=dd_period['bottom'], color='red', linestyle='--', alpha=0.7, label='Drawdown Bottom')
            if dd_period['recovery_equity'] is not None:
                ax.axvline(x=end_date, color='green', linestyle='--', alpha=0.7, label='Recovery Complete')
            
            # Add annotations
            ax.set_title(f"Drawdown #{i+1}: {dd_period['max_dd']*100:.2f}%")
            
            # Add drawdown info text
            info_text = (
                f"Start: {start_date:%Y-%m-%d}\n"
                f"Bottom: {dd_period['bottom']:%Y-%m-%d}\n"
                f"Duration: {dd_period['total_duration']} days\n"
                f"Max DD: {dd_period['max_dd']*100:.2f}%"
            )
            if dd_period['recovery_equity'] is not None:
                info_text += f"\nRecovery: {end_date:%Y-%m-%d}"
                info_text += f"\nRecovery Duration: {dd_period['recovery_duration']} days"
            
            props = dict(boxstyle='round', facecolor='white', alpha=0.8)
            ax.text(0.02, 0.97, info_text, transform=ax.transAxes, fontsize=10,
                    verticalalignment='top', bbox=props)
            
            # Format x-axis dates
            ax.xaxis.set_major_formatter(mdates.DateFormatter('%Y-%m-%d'))
            ax.xaxis.set_major_locator(mdates.AutoDateLocator())
            plt.sca(ax)
            plt.xticks(rotation=45)
            
            # Add legend
            ax.legend(loc='lower right')
        
        plt.tight_layout()
        
        return fig, axs
    
    def plot_order_book_heatmap(self, results, data, window_size: int = 20):
        """
        Plot a heatmap of order book activity
        
        Args:
            results: Backtest results object
            data: OHLCV data used for backtesting
            window_size: Number of bars to include in each heatmap window
        """
        if not hasattr(results, '_trades') or len(results._trades) == 0:
            print("No trades available")
            return
        
        trades = results._trades
        
        # Calculate total number of windows
        n_bars = len(data)
        n_windows = n_bars // window_size
        
        # Create figure
        fig, axs = plt.subplots(n_windows, 1, figsize=(14, 6*n_windows))
        if n_windows == 1:
            axs = [axs]  # Make iterable
            
        for i in range(n_windows):
            ax = axs[i]
            
            # Get data for this window
            start_idx = i * window_size
            end_idx = min((i + 1) * window_size, n_bars)
            
            window_data = data.iloc[start_idx:end_idx]
            
            # Calculate price range for this window
            min_price = window_data['Low'].min() * 0.995
            max_price = window_data['High'].max() * 1.005
            price_range = max_price - min_price
            
            # Create price bins
            n_bins = 50
            bin_size = price_range / n_bins
            price_bins = np.linspace(min_price, max_price, n_bins)
            
            # Create order book heatmap matrix
            heatmap_matrix = np.zeros((len(window_data), len(price_bins)-1))
            
            # Add trades to the heatmap
            for _, trade in trades.iterrows():
                entry_bar = trade['EntryBar']
                exit_bar = trade['ExitBar']
                
                # Check if trade is in this window
                if entry_bar >= start_idx and entry_bar < end_idx:
                    entry_price = trade['EntryPrice']
                    bin_idx = int((entry_price - min_price) / bin_size)
                    if 0 <= bin_idx < len(price_bins)-1:
                        bar_idx = entry_bar - start_idx
                        heatmap_matrix[bar_idx, bin_idx] += abs(trade['Size'])
                        
                if exit_bar >= start_idx and exit_bar < end_idx:
                    exit_price = trade['ExitPrice']
                    bin_idx = int((exit_price - min_price) / bin_size)
                    if 0 <= bin_idx < len(price_bins)-1:
                        bar_idx = exit_bar - start_idx
                        heatmap_matrix[bar_idx, bin_idx] += abs(trade['Size'])
            
            # Plot heatmap
            sns.heatmap(heatmap_matrix.T, cmap='viridis', ax=ax, cbar_kws={'label': 'Order Volume'})
            
            # Plot price on top
            ax2 = ax.twinx()
            ax2.plot(window_data['Close'].values, color='red', linewidth=2)
            ax2.set_ylim(min_price, max_price)
            
            # Set labels
            ax.set_title(f"Order Book Activity (Window {i+1}/{n_windows})")
            ax.set_xlabel("Time")
            ax.set_ylabel("Price Level")
            ax2.set_ylabel("Close Price")
            
            # Set x-axis ticks to dates
            window_dates = window_data.index
            step = max(1, len(window_dates) // 10)  # Show at most 10 date labels
            ax.set_xticks(range(0, len(window_dates), step))
            ax.set_xticklabels([d.strftime('%m-%d') for d in window_dates[::step]], rotation=45)
            
            # Set y-axis ticks to price levels
            step = max(1, len(price_bins) // 10)  # Show at most 10 price labels
            ax.set_yticks(range(0, len(price_bins), step))
            ax.set_yticklabels([f"{p:.2f}" for p in price_bins[::step]], rotation=0)
            
        plt.tight_layout()
        
        return fig, axs
    
    def plot_performance_metrics(self, results, figsize=(14, 10)):
        """
        Plot various performance metrics
        
        Args:
            results: Backtest results object
            figsize: Figure size
        """
        fig, axs = plt.subplots(2, 2, figsize=figsize)
        
        # 1. Plot trade outcomes (win/loss distribution)
        if hasattr(results, '_trades') and len(results._trades) > 0:
            trades = results._trades
            trade_returns = ((trades['ExitPrice'] - trades['EntryPrice']) / trades['EntryPrice']) * 100
            trade_returns = trade_returns * np.sign(trades['Size'])  # Adjust for short positions
            
            ax = axs[0, 0]
            sns.histplot(trade_returns, kde=True, ax=ax)
            ax.set_title('Trade Returns Distribution')
            ax.set_xlabel('Return (%)')
            ax.set_ylabel('Count')
            
            # Add vertical line at 0
            ax.axvline(x=0, color='red', linestyle='--')
            
            # Add text with stats
            stats_text = (
                f"Mean: {trade_returns.mean():.2f}%\n"
                f"Median: {trade_returns.median():.2f}%\n"
                f"Std Dev: {trade_returns.std():.2f}%\n"
                f"Skew: {trade_returns.skew():.2f}\n"
                f"Win Rate: {results['Win Rate [%]']:.1f}%"
            )
            
            props = dict(boxstyle='round', facecolor='white', alpha=0.8)
            ax.text(0.05, 0.95, stats_text, transform=ax.transAxes, fontsize=10,
                    verticalalignment='top', bbox=props)
        
        # 2. Plot trade duration vs return
        if hasattr(results, '_trades') and len(results._trades) > 0:
            trades = results._trades
            trade_durations = trades['ExitBar'] - trades['EntryBar']
            
            # Convert bar numbers to actual duration if possible
            if hasattr(results, '_data') and hasattr(results._data, 'index'):
                trade_durations = trade_durations.apply(lambda x: x * (results._data.index[1] - results._data.index[0]).total_seconds() / 3600)  # Hours
                duration_label = 'Duration (hours)'
            else:
                duration_label = 'Duration (bars)'
            
            ax = axs[0, 1]
            ax.scatter(trade_durations, trade_returns, alpha=0.6)
            ax.set_title('Trade Duration vs Return')
            ax.set_xlabel(duration_label)
            ax.set_ylabel('Return (%)')
            
            # Add horizontal line at 0
            ax.axhline(y=0, color='red', linestyle='--')
            
            # Add trend line
            if len(trade_durations) > 1:
                z = np.polyfit(trade_durations, trade_returns, 1)
                p = np.poly1d(z)
                ax.plot(trade_durations, p(trade_durations), "r--")
                
                # Add correlation coefficient
                corr = np.corrcoef(trade_durations, trade_returns)[0, 1]
                ax.text(0.05, 0.95, f"Correlation: {corr:.2f}", transform=ax.transAxes, 
                        fontsize=10, verticalalignment='top',
                        bbox=dict(boxstyle='round', facecolor='white', alpha=0.8))
        
        # 3. Plot monthly returns
        if 'Equity' in results._equity_curve.columns:
            equity = results._equity_curve['Equity']
            
            # Resample to monthly returns
            try:
                monthly_returns = equity.resample('M').last().pct_change() * 100
                
                ax = axs[1, 0]
                monthly_returns.plot(kind='bar', ax=ax)
                ax.set_title('Monthly Returns')
                ax.set_xlabel('Month')
                ax.set_ylabel('Return (%)')
                ax.tick_params(axis='x', rotation=45)
                
                # Add horizontal line at 0
                ax.axhline(y=0, color='red', linestyle='--')
                
                # Add average monthly return
                avg_monthly = monthly_returns.mean()
                ax.axhline(y=avg_monthly, color='green', linestyle='-')
                
                # Add text with stats
                stats_text = (
                    f"Avg Monthly: {avg_monthly:.2f}%\n"
                    f"Best Month: {monthly_returns.max():.2f}%\n"
                    f"Worst Month: {monthly_returns.min():.2f}%\n"
                    f"% Profitable: {(monthly_returns > 0).mean() * 100:.1f}%"
                )
                
                props = dict(boxstyle='round', facecolor='white', alpha=0.8)
                ax.text(0.05, 0.95, stats_text, transform=ax.transAxes, fontsize=10,
                        verticalalignment='top', bbox=props)
            except:
                ax = axs[1, 0]
                ax.text(0.5, 0.5, "Insufficient data for monthly returns", 
                        horizontalalignment='center', verticalalignment='center')
        
        # 4. Plot underwater equity curve (drawdowns)
        if 'DrawdownPct' in results._equity_curve.columns:
            dd = results._equity_curve['DrawdownPct'] * 100
            
            ax = axs[1, 1]
            dd.plot(ax=ax)
            ax.fill_between(dd.index, 0, -dd, alpha=0.3, color='red')
            ax.set_title('Underwater Equity Curve (Drawdowns)')
            ax.set_xlabel('Date')
            ax.set_ylabel('Drawdown (%)')
            
            # Set y-axis to negative values only
            ax.set_ylim(min(-dd) * 1.1, 0)
            
            # Format y-axis as percentage
            ax.yaxis.set_major_formatter(FuncFormatter(lambda y, _: f'{y:.0f}%'))
            
            # Format x-axis dates
            ax.xaxis.set_major_formatter(mdates.DateFormatter('%Y-%m-%d'))
            ax.xaxis.set_major_locator(mdates.AutoDateLocator())
            plt.sca(ax)
            plt.xticks(rotation=45)
            
            # Add text with drawdown stats
            stats_text = (
                f"Max Drawdown: {results['Max. Drawdown [%]']:.2f}%\n"
                f"Avg Drawdown: {results['Avg. Drawdown [%]']:.2f}%\n"
                f"Max Drawdown Duration: {results['Max. Drawdown Duration']}\n"
                f"Calmar Ratio: {results['Calmar Ratio']:.2f}"
            )
            
            props = dict(boxstyle='round', facecolor='white', alpha=0.8)
            ax.text(0.05, 0.95, stats_text, transform=ax.transAxes, fontsize=10,
                    verticalalignment='top', bbox=props)
        
        plt.tight_layout()
        
        return fig, axs
    
    def plot_optimization_heatmap(self, heatmap_data, param1: str, param2: str, metric: str = "SQN"):
        """
        Plot optimization results heatmap
        
        Args:
            heatmap_data: Results from optimizer (must contain param1, param2, and metric)
            param1: Name of first parameter
            param2: Name of second parameter
            metric: Performance metric to use for coloring
        """
        # Convert to DataFrame if it's a list of dictionaries
        if isinstance(heatmap_data, list):
            df = pd.DataFrame(heatmap_data)
        else:
            df = heatmap_data
            
        # Check if required columns exist
        if param1 not in df.columns or param2 not in df.columns or metric not in df.columns:
            print(f"Error: Required columns not found in data. Available columns: {df.columns.tolist()}")
            return
        
        # Create pivot table
        pivot = df.pivot_table(index=param1, columns=param2, values=metric)
        
        # Create figure
        fig, ax = plt.subplots(figsize=(12, 10))
        
        # Plot heatmap
        sns.heatmap(pivot, cmap='viridis', annot=True, fmt='.2f', ax=ax, cbar_kws={'label': metric})
        
        # Set labels
        ax.set_title(f'Parameter Optimization Heatmap ({metric})')
        ax.set_xlabel(param2)
        ax.set_ylabel(param1)
        
        plt.tight_layout()
        
        return fig, ax
    
    def save_plot(self, fig, filename: str, dpi: int = 300):
        """
        Save plot to file
        
        Args:
            fig: Figure to save
            filename: Filename (without path or extension)
            dpi: DPI for saving
        """
        # Add timestamp to filename
        timestamp = datetime.now().strftime('%Y%m%d_%H%M%S')
        filename = f"{filename}_{timestamp}.png"
        
        # Full path
        filepath = os.path.join(self.output_dir, filename)
        
        # Save figure
        fig.savefig(filepath, dpi=dpi, bbox_inches='tight')
        print(f"Plot saved to {filepath}")
        return filepath
