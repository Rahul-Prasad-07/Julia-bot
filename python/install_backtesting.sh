#!/usr/bin/env bash
# JuliaOS Backtesting Installation Script

echo "🚀 Installing JuliaOS Backtesting System"
echo "========================================"

# Ensure we're in the right directory
SCRIPT_DIR="$( cd "$( dirname "${BASH_SOURCE[0]}" )" &> /dev/null && pwd )"
cd "$SCRIPT_DIR" || exit 1
cd ../

# Check for Python
if command -v python3 &>/dev/null; then
    PYTHON_CMD=python3
elif command -v python &>/dev/null; then
    PYTHON_CMD=python
else
    echo "❌ Python not found! Please install Python 3.6+ and try again."
    exit 1
fi

echo "✓ Using Python: $($PYTHON_CMD --version)"

# Check for pip
if command -v pip3 &>/dev/null; then
    PIP_CMD=pip3
elif command -v pip &>/dev/null; then
    PIP_CMD=pip
else
    echo "❌ pip not found! Please install pip and try again."
    exit 1
fi

echo "✓ Using pip: $($PIP_CMD --version)"

# Install Python dependencies
echo "📦 Installing Python dependencies..."
$PIP_CMD install -r "$SCRIPT_DIR/requirements_backtesting.txt"

# Check for Julia
if command -v julia &>/dev/null; then
    echo "✓ Julia found: $(julia --version)"
    
    # Install Julia dependencies
    echo "📦 Installing Julia dependencies..."
    julia -e 'using Pkg; Pkg.add.(["PyCall", "JSON", "Dates", "TOML"])'
else
    echo "⚠️ Julia not found. You will need to install Julia packages manually."
    echo "In Julia REPL, run: using Pkg; Pkg.add.(["PyCall", "JSON", "Dates", "TOML"])"
fi

# Create necessary directories
echo "📁 Creating directories..."
mkdir -p "$SCRIPT_DIR/../python/backtest_results"
mkdir -p "$SCRIPT_DIR/../python/visualizations"
mkdir -p "$SCRIPT_DIR/../python/optimized_params"
mkdir -p "$SCRIPT_DIR/../python/data"

echo "✅ Installation complete!"
echo ""
echo "To run a backtest in Python:"
echo "  cd $SCRIPT_DIR"
echo "  $PYTHON_CMD run_backtest.py --symbol BTCUSDT --days 30 --visualize"
echo ""
echo "To run a backtest in Julia:"
echo "  cd $SCRIPT_DIR/../julia/examples"
echo "  julia backtest_example.jl --symbol BTCUSDT --days 30 --report"
echo ""
