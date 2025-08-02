#!/usr/bin/env python3
"""
Enhanced YieldSwarm Dashboard Demo
Complete demonstration of the new live data integration features
"""

import subprocess
import time
import webbrowser
import requests
import json
from datetime import datetime

def print_banner():
    print("🎯" + "=" * 70)
    print("🚀 ENHANCED YIELDSWARM DASHBOARD DEMO")
    print("=" * 72)
    print("✨ Features to be demonstrated:")
    print("  🔥 Live DeFi yield opportunities (19,000+ pools)")
    print("  💰 Real-time token prices (BTC, ETH, SOL)")
    print("  🤖 Auto-managed YieldSwarm agents")
    print("  🧠 AI-powered live yield analysis")
    print("  📊 Multi-chain protocol support")
    print("  ⚡ Auto-refresh every 30 seconds")
    print("=" * 72)

def check_backend():
    """Check if the Julia backend is running"""
    try:
        response = requests.get('http://127.0.0.1:8052/api/v1/agents', timeout=5)
        return response.status_code == 200
    except:
        return False

def test_live_apis():
    """Test the live data APIs"""
    print("\n🔍 Testing Live Data Sources...")
    print("-" * 40)
    
    # Test DeFiLlama
    try:
        response = requests.get('https://yields.llama.fi/pools', timeout=10)
        if response.status_code == 200:
            data = response.json()
            pools = len(data.get('data', []))
            print(f"✅ DeFiLlama API: {pools:,} yield pools available")
        else:
            print(f"❌ DeFiLlama API: Error {response.status_code}")
    except Exception as e:
        print(f"❌ DeFiLlama API: {e}")
    
    # Test CoinGecko
    try:
        url = 'https://api.coingecko.com/api/v3/simple/price?ids=bitcoin,ethereum,solana&vs_currencies=usd&include_24hr_change=true'
        response = requests.get(url, timeout=10)
        if response.status_code == 200:
            data = response.json()
            print(f"✅ CoinGecko API: Live prices for {len(data)} tokens")
            for token, info in data.items():
                price = info.get('usd', 0)
                change = info.get('usd_24h_change', 0)
                change_icon = "📈" if change >= 0 else "📉"
                print(f"   • {token.upper()}: ${price:,.2f} {change_icon} {change:.2f}%")
        else:
            print(f"❌ CoinGecko API: Error {response.status_code}")
    except Exception as e:
        print(f"❌ CoinGecko API: {e}")

def start_backend():
    """Start the Julia backend if not running"""
    if not check_backend():
        print("\n🔄 Starting Julia backend...")
        print("This may take a minute for the first startup...")
        # Note: In a real scenario, you might want to start this in a separate process
        return False
    return True

def start_dashboard_server():
    """Start the enhanced dashboard server"""
    print("\n🌐 Starting Enhanced Dashboard Server...")
    try:
        # Start the server in the background
        process = subprocess.Popen([
            'python', 'serve_enhanced_dashboard.py'
        ], cwd='.', stdout=subprocess.PIPE, stderr=subprocess.PIPE)
        
        # Wait a moment for server to start
        time.sleep(2)
        
        return process
    except Exception as e:
        print(f"❌ Failed to start dashboard server: {e}")
        return None

def create_demo_agent():
    """Create a demo YieldSwarm agent"""
    print("\n🤖 Creating Demo YieldSwarm Agent...")
    
    agent_config = {
        "id": "yieldswarm-demo-enhanced",
        "name": "YieldSwarm Demo Agent (Enhanced)",
        "description": "Demo agent showcasing enhanced live data integration",
        "blueprint": {
            "tools": [
                {"name": "yieldswarm_data_fetcher", "config": {}},
                {"name": "yieldswarm_analyzer", "config": {"ai_provider": "groq"}},
                {"name": "yieldswarm_risk_manager", "config": {}}
            ],
            "strategy": {
                "name": "yieldswarm",
                "config": {
                    "name": "demo-enhanced",
                    "swarm_id": "demo-001",
                    "agent_role": "coordinator",
                    "supported_chains": ["ethereum", "solana", "polygon", "avalanche"]
                }
            },
            "trigger": {"type": "webhook", "params": {}}
        }
    }
    
    try:
        # Clean up existing demo agent
        try:
            requests.delete('http://127.0.0.1:8052/api/v1/agents/yieldswarm-demo-enhanced')
        except:
            pass
        
        # Create new agent
        response = requests.post(
            'http://127.0.0.1:8052/api/v1/agents',
            headers={'Content-Type': 'application/json'},
            json=agent_config
        )
        
        if response.status_code == 201:
            agent = response.json()
            print(f"✅ Created agent: {agent['name']}")
            
            # Start the agent
            start_response = requests.put(
                f'http://127.0.0.1:8052/api/v1/agents/{agent["id"]}',
                headers={'Content-Type': 'application/json'},
                json={"state": "RUNNING"}
            )
            
            if start_response.status_code == 200:
                print("✅ Agent started successfully")
                return agent
            else:
                print(f"⚠️ Agent created but failed to start: {start_response.status_code}")
                return agent
        else:
            print(f"❌ Failed to create agent: {response.status_code}")
            return None
            
    except Exception as e:
        print(f"❌ Error creating agent: {e}")
        return None

def demonstrate_features():
    """Demonstrate the dashboard features"""
    print("\n📋 Dashboard Features Demo Guide:")
    print("-" * 40)
    
    features = [
        {
            "name": "Live Market Data",
            "description": "Real-time BTC, ETH, SOL prices with 24h changes",
            "location": "Top section with price tickers"
        },
        {
            "name": "Yield Opportunities",
            "description": "Live yield farming pools from DeFiLlama",
            "location": "Middle section with opportunity cards"
        },
        {
            "name": "Agents Management",
            "description": "Auto-managed YieldSwarm agents",
            "location": "Agent cards with start/stop controls"
        },
        {
            "name": "AI Analysis",
            "description": "Live AI-powered yield analysis",
            "location": "Analysis form with portfolio input"
        },
        {
            "name": "Auto-Refresh",
            "description": "Data refreshes every 30 seconds",
            "location": "Automatic background updates"
        }
    ]
    
    for i, feature in enumerate(features, 1):
        print(f"{i}. 🎯 {feature['name']}")
        print(f"   Description: {feature['description']}")
        print(f"   Location: {feature['location']}")
        print()

def run_demo():
    """Run the complete demo"""
    print_banner()
    
    # Test live APIs first
    test_live_apis()
    
    # Check backend
    print(f"\n🔌 Backend Status: {'✅ Running' if check_backend() else '❌ Not Running'}")
    
    if not check_backend():
        print("\n⚠️ Julia backend not running!")
        print("Please start the backend first:")
        print("cd backend && julia run_server.jl")
        return False
    
    # Create demo agent
    demo_agent = create_demo_agent()
    if not demo_agent:
        print("⚠️ Could not create demo agent, but continuing...")
    
    # Start dashboard server
    server_process = start_dashboard_server()
    if not server_process:
        return False
    
    # Show features guide
    demonstrate_features()
    
    # Open browser
    dashboard_url = "http://localhost:8080/yieldswarm-dashboard.html"
    print(f"\n🌐 Opening dashboard: {dashboard_url}")
    
    try:
        webbrowser.open(dashboard_url)
    except:
        print("Could not auto-open browser. Please manually navigate to:")
        print(dashboard_url)
    
    print("\n🎮 Demo Instructions:")
    print("=" * 50)
    print("1. 🚀 Click 'Auto-Start All Agents' to initialize")
    print("2. 🔄 Click 'Refresh Live Data' to load current yields")
    print("3. 📊 Explore the live yield opportunities")
    print("4. 🤖 Try 'Run Live Analysis' for AI recommendations")
    print("5. 👀 Watch the auto-refresh in action")
    print("=" * 50)
    
    print(f"\n⏰ Demo started at: {datetime.now().strftime('%Y-%m-%d %H:%M:%S')}")
    print("🎯 The dashboard will auto-refresh every 30 seconds")
    print("📈 All data is LIVE from DeFiLlama and CoinGecko")
    print("🤖 AI analysis uses real market data")
    print("\n⌨️  Press Ctrl+C to stop the demo")
    
    try:
        # Keep the demo running
        while True:
            time.sleep(10)
            print(".", end="", flush=True)
    except KeyboardInterrupt:
        print("\n\n🛑 Demo stopped by user")
        if server_process:
            server_process.terminate()
        print("👋 Thank you for trying YieldSwarm Enhanced!")
        return True

if __name__ == "__main__":
    success = run_demo()
    if success:
        print("\n🏆 DEMO COMPLETED SUCCESSFULLY!")
        print("🚀 YieldSwarm Enhanced Dashboard is ready for production!")
    else:
        print("\n❌ Demo encountered issues")
        print("Please check the setup and try again")
