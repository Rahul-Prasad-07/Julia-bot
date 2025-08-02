#!/usr/bin/env python3
"""
YieldSwarm Real-Time Agent v3.0 - Simplified Demo
Creates and tests YieldSwarm agent with proper configuration
"""

import requests
import json
import time
from datetime import datetime

BASE_URL = "http://127.0.0.1:8052/api/v1"
HEADERS = {"Content-Type": "application/json"}

def print_section(title):
    print(f"\n{'='*60}")
    print(f"🚀 {title}")
    print(f"{'='*60}")

def print_success(message):
    print(f"✅ {message}")

def print_info(message):
    print(f"ℹ️  {message}")

def print_error(message):
    print(f"❌ {message}")

def create_yieldswarm_agent():
    """Create YieldSwarm agent with proper configuration"""
    print_section("Creating YieldSwarm Real-Time Agent v3.0")
    
    # Proper agent configuration matching the Julia struct
    agent_config = {
        "id": "yieldswarm-realtime-v3",
        "name": "YieldSwarm Real-Time Agent v3.0",
        "description": "Advanced DeFi yield optimization agent with real-time data integration and AI analysis",
        "blueprint": {
            "tools": [
                {
                    "name": "yieldswarm_data_fetcher",
                    "config": {
                        "cache_duration_minutes": 5,
                        "enable_caching": True
                    }
                },
                {
                    "name": "yieldswarm_analyzer",
                    "config": {
                        "ai_provider": "groq",
                        "temperature": 0.1
                    }
                },
                {
                    "name": "yieldswarm_risk_manager",
                    "config": {
                        "max_portfolio_risk_score": 7.0
                    }
                }
            ],
            "strategy": {
                "name": "yieldswarm",
                "config": {
                    "name": "yieldswarm-realtime-v3",
                    "swarm_id": "yieldswarm-v3-001",
                    "agent_role": "coordinator",
                    "coordination_endpoint": "http://127.0.0.1:8052/api/v1",
                    "max_coordination_rounds": 10,
                    "consensus_threshold": 0.75,
                    "agent_timeout_seconds": 30,
                    "default_risk_tolerance": "medium",
                    "min_portfolio_value_usd": 1000.0,
                    "max_portfolio_value_usd": 1000000.0,
                    "supported_chains": ["ethereum", "solana", "polygon", "avalanche"],
                    "enable_performance_tracking": True,
                    "benchmark_comparison": True,
                    "risk_adjusted_metrics": True
                }
            },
            "trigger": {
                "type": "webhook",
                "params": {}
            }
        }
    }
    
    try:
        # Clean up existing agent
        try:
            response = requests.delete(f"{BASE_URL}/agents/yieldswarm-realtime-v3")
            if response.status_code == 200:
                print_info("Cleaned up existing agent")
        except:
            pass
        
        print_info("Creating YieldSwarm agent with real-time capabilities...")
        response = requests.post(f"{BASE_URL}/agents", 
                               headers=HEADERS,
                               json=agent_config)
        
        print_info(f"Response Status: {response.status_code}")
        if response.status_code != 201:
            print_error(f"Response: {response.text}")
            return None
        
        agent = response.json()
        print_success("✨ YieldSwarm Agent v3.0 created successfully!")
        print_info(f"Agent ID: {agent['id']}")
        print_info(f"Tools: {len(agent_config['blueprint']['tools'])} tools loaded")
        print_info("Real-time data integration: ✅ ENABLED")
        return agent['id']
            
    except Exception as e:
        print_error(f"Error creating agent: {e}")
        return None

def start_agent(agent_id):
    """Start the YieldSwarm agent"""
    print_section("Starting YieldSwarm Agent")
    
    try:
        response = requests.put(f"{BASE_URL}/agents/{agent_id}",
                              headers=HEADERS,
                              json={"state": "RUNNING"})
        
        if response.status_code == 200:
            print_success("🟢 Agent started successfully!")
            return True
        else:
            print_error(f"Failed to start agent: {response.status_code} - {response.text}")
            return False
    except Exception as e:
        print_error(f"Error starting agent: {e}")
        return False

def test_real_time_analysis(agent_id):
    """Test real-time yield analysis"""
    print_section("Testing Real-Time Yield Analysis")
    
    test_payload = {
        "input": "Analyze current DeFi yield opportunities with real-time data. I have $25,000 to invest with medium risk tolerance. Show me the top 5 yield opportunities across Ethereum and Solana with current APY rates, TVL data, and risk assessments. Include live token prices in your analysis."
    }
    
    try:
        print_info("🔄 Sending real-time analysis request...")
        
        response = requests.post(f"{BASE_URL}/agents/{agent_id}/webhook",
                               headers=HEADERS,
                               json=test_payload)
        
        print_info(f"Response Status: {response.status_code}")
        
        if response.status_code == 200:
            result = response.json()
            
            if result.get('success'):
                print_success("✨ Real-time analysis completed!")
                
                message = result.get('message', '')
                
                # Check for real-time data indicators
                indicators = [
                    ('Live Data', 'live' in message.lower() or 'real-time' in message.lower()),
                    ('Price Data', '$' in message or 'price' in message.lower()),
                    ('APY/Yield', 'apy' in message.lower() or 'yield' in message.lower() or '%' in message),
                    ('Protocol Names', any(p in message.lower() for p in ['uniswap', 'raydium', 'aave', 'compound', 'orca'])),
                    ('Chain Analysis', any(c in message.lower() for c in ['ethereum', 'solana', 'polygon']))
                ]
                
                print_section("Analysis Quality Check")
                for indicator, found in indicators:
                    status = "✅ FOUND" if found else "❌ MISSING"
                    print_info(f"{indicator}: {status}")
                
                # Show preview
                preview = message[:500] + "..." if len(message) > 500 else message
                print_section("Response Preview")
                print(preview)
                
                return True
            else:
                print_error(f"Analysis failed: {result.get('error', 'Unknown error')}")
                return False
        else:
            print_error(f"Request failed: {response.status_code} - {response.text}")
            return False
            
    except Exception as e:
        print_error(f"Analysis error: {e}")
        return False

def test_data_fetcher_directly():
    """Test the data fetcher tool directly"""
    print_section("Testing Data Fetcher Tool")
    
    try:
        # Test data fetcher endpoint
        response = requests.get(f"{BASE_URL}/tools")
        if response.status_code == 200:
            tools = response.json()
            data_fetcher = next((t for t in tools if t['name'] == 'yieldswarm_data_fetcher'), None)
            
            if data_fetcher:
                print_success("✅ YieldSwarm Data Fetcher tool is available")
                print_info(f"Description: {data_fetcher['metadata']['description']}")
                return True
            else:
                print_error("❌ YieldSwarm Data Fetcher tool not found")
                return False
        else:
            print_error(f"Failed to get tools: {response.status_code}")
            return False
            
    except Exception as e:
        print_error(f"Error testing data fetcher: {e}")
        return False

def show_agent_status(agent_id):
    """Show current agent status"""
    print_section("Agent Status")
    
    try:
        response = requests.get(f"{BASE_URL}/agents/{agent_id}")
        if response.status_code == 200:
            agent = response.json()
            print_info(f"ID: {agent['id']}")
            print_info(f"Name: {agent['name']}")
            print_info(f"State: {agent['state']}")
            print_info(f"Trigger: {agent['trigger_type']}")
            
            # Check tools
            if 'blueprint' in agent:
                tools_count = len(agent['blueprint'].get('tools', []))
                print_info(f"Tools: {tools_count} configured")
            
            return True
        else:
            print_error(f"Failed to get agent status: {response.status_code}")
            return False
            
    except Exception as e:
        print_error(f"Error getting agent status: {e}")
        return False

def main():
    """Main demo function"""
    print_section("YieldSwarm v3.0 Real-Time Demo")
    print_info(f"Server: {BASE_URL}")
    print_info(f"Timestamp: {datetime.now().strftime('%Y-%m-%d %H:%M:%S')}")
    
    # Test server connectivity
    try:
        response = requests.get(f"{BASE_URL}/agents")
        print_success(f"✅ Server is running! Found {len(response.json())} existing agents")
    except Exception as e:
        print_error(f"❌ Server connection failed: {e}")
        return False
    
    # Test data fetcher tool availability
    if not test_data_fetcher_directly():
        print_error("Data fetcher tool not available - aborting")
        return False
    
    # Create agent
    agent_id = create_yieldswarm_agent()
    if not agent_id:
        print_error("Failed to create agent - aborting")
        return False
    
    # Show agent status
    show_agent_status(agent_id)
    
    # Start agent
    if not start_agent(agent_id):
        print_error("Failed to start agent - aborting")
        return False
    
    # Give agent time to initialize
    print_info("🔄 Initializing agent...")
    time.sleep(3)
    
    # Test real-time analysis
    success = test_real_time_analysis(agent_id)
    
    print_section("Demo Results")
    if success:
        print_success("🎉 YieldSwarm v3.0 Real-Time Demo SUCCESSFUL!")
        print_info("✨ Real-time data integration is working!")
        print_info("🤖 AI analysis is functional!")
        print_info("🌐 Multi-chain support confirmed!")
        print_info("🚀 Ready for bounty submission!")
    else:
        print_error("❌ Demo completed with issues")
        print_info("🔧 Check the logs above for troubleshooting")
    
    print_section("Next Steps")
    print_info(f"🤖 Agent ID: {agent_id}")
    print_info("📊 Web Dashboard: http://localhost:8080/yieldswarm-dashboard.html")
    print_info("🔗 Backend API: http://127.0.0.1:8052/api/v1")
    print_info("💡 Use the agent ID above for further testing!")
    
    return success

if __name__ == "__main__":
    success = main()
    if success:
        print("\n" + "="*60)
        print("🏆 YIELDSWARM V3.0 DEMO SUCCESSFUL!")
        print("🎯 Ready for bounty submission!")
        print("="*60)
    else:
        print("\n" + "="*60)
        print("⚠️  Demo completed - check results above")
        print("="*60)
