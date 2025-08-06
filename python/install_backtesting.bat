@echo off
REM JuliaOS Backtesting Installation Script for Windows

echo 🚀 Installing JuliaOS Backtesting System
echo ========================================

REM Ensure we're in the right directory
cd /d "%~dp0"

REM Check for Python
python --version >nul 2>&1
if %ERRORLEVEL% NEQ 0 (
    echo ❌ Python not found! Please install Python 3.6+ and try again.
    exit /b 1
)

echo ✓ Using Python: 
python --version

REM Check for pip
pip --version >nul 2>&1
if %ERRORLEVEL% NEQ 0 (
    echo ❌ pip not found! Please install pip and try again.
    exit /b 1
)

echo ✓ Using pip: 
pip --version

REM Install Python dependencies
echo 📦 Installing Python dependencies...
pip install -r requirements_backtesting.txt

REM Check for Julia
julia --version >nul 2>&1
if %ERRORLEVEL% EQU 0 (
    echo ✓ Julia found:
    julia --version
    
    REM Install Julia dependencies
    echo 📦 Installing Julia dependencies...
    julia -e "using Pkg; Pkg.add.(["PyCall", "JSON", "Dates", "TOML"])"
) else (
    echo ⚠️ Julia not found. You will need to install Julia packages manually.
    echo In Julia REPL, run: using Pkg; Pkg.add.(["PyCall", "JSON", "Dates", "TOML"])
)

REM Create necessary directories
echo 📁 Creating directories...
if not exist "..\python\backtest_results" mkdir "..\python\backtest_results"
if not exist "..\python\visualizations" mkdir "..\python\visualizations"
if not exist "..\python\optimized_params" mkdir "..\python\optimized_params"
if not exist "..\python\data" mkdir "..\python\data"

echo ✅ Installation complete!
echo.
echo To run a backtest in Python:
echo   cd %~dp0
echo   python run_backtest.py --symbol BTCUSDT --days 30 --visualize
echo.
echo To run a backtest in Julia:
echo   cd %~dp0..\julia\examples
echo   julia backtest_example.jl --symbol BTCUSDT --days 30 --report
echo.

pause
