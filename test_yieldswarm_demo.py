#!/usr/bin/env python3
"""
YieldSwarm Demonstration Script
Showcases the fully functional YieldSwarm DeFi yield optimization system
"""

import requests
import json
import time
from datetime import datetime

# YieldSwarm server configuration
BASE_URL = "http://127.0.0.1:8052/api/v1"
HEADERS = {"Content-Type": "application/json"}

def print_section(title):
    """Print a formatted section header"""
    print(f"\n{'='*60}")
    print(f"🚀 {title}")
    print(f"{'='*60}")

def print_success(message):
    """Print success message"""
    print(f"✅ {message}")

def print_info(message):  
    """Print info message"""
    print(f"ℹ️  {message}")

def print_error(message):
    """Print error message"""  
    print(f"❌ {message}")

def create_yieldswarm_agent():
    """Create a properly configured YieldSwarm agent"""
    print_section("Creating YieldSwarm Master Agent")
    
    # Agent configuration following the Solana pattern
    agent_config = {
        "id": "yieldswarm-master-demo",
        "name": "YieldSwarm Master Agent",
        "description": "Advanced DeFi yield optimization agent with cross-chain capabilities and AI-powered analysis",
        "blueprint": {
            "tools": [
                {
                    "name": "yieldswarm_analyzer",
                    "config": {}
                },
                {
                    "name": "yieldswarm_executor", 
                    "config": {}
                },
                {
                    "name": "yieldswarm_risk_manager",
                    "config": {}
                }
            ],
            "strategy": {
                "name": "yieldswarm",
                "config": {
                    "name": "yieldswarm-master-demo",
                    "swarm_id": "yieldswarm-demo-001",
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
        # Delete existing agent if present
        try:
            requests.delete(f"{BASE_URL}/agents/yieldswarm-master-demo")
            print_info("Cleaned up existing agent")
        except:
            pass
        
        # Create new agent
        response = requests.post(f"{BASE_URL}/agents", headers=HEADERS, json=agent_config)
        
        if response.status_code == 201:
            agent_data = response.json()
            print_success(f"Agent created successfully: {agent_data['id']}")
            print_info(f"Initial State: {agent_data['state']}")
            
            # Start the agent
            update_response = requests.put(
                f"{BASE_URL}/agents/yieldswarm-master-demo", 
                headers=HEADERS, 
                json={"state": "RUNNING"}
            )
            
            if update_response.status_code == 200:
                print_success("Agent started successfully (RUNNING state)")
                return agent_data['id']
            else:
                print_error(f"Failed to start agent: {update_response.text}")
                return None
        else:
            print_error(f"Failed to create agent: {response.status_code}")
            print_error(f"Error: {response.text}")
            return None
            
    except Exception as e:
        print_error(f"Agent creation failed: {e}")
        return None

def test_yieldswarm_functionality(agent_id):
    """Test YieldSwarm agent functionality with proper payload structure"""
    print_section("Testing YieldSwarm Agent Functionality")
    
    # Test queries following the YieldSwarmInput structure
    test_queries = [
        {
            "name": "Basic Yield Analysis", 
            "payload": {
                "user_query": "I have $50,000 portfolio with ETH and USDC. What are the best yield farming opportunities with medium risk? Please provide specific protocols, APY rates, and expected returns.",
                "portfolio_data": {
                    "total_value": 50000,
                    "assets": {
                        "ETH": {"amount": 10, "value": 25000, "price_usd": 2500},
                        "USDC": {"amount": 25000, "value": 25000, "price_usd": 1.0}
                    },
                    "current_chain": "ethereum"
                },
                "market_context": {
                    "current_market": "bull",
                    "volatility": "medium",
                    "eth_gas_price": 30,
                    "market_sentiment": "optimistic"
                },
                "risk_preferences": {
                    "risk_tolerance": "medium",
                    "max_slippage": 0.5,
                    "preferred_protocols": ["uniswap", "compound", "aave"],
                    "min_apy_threshold": 8.0
                },
                "execution_mode": "analyze",
                "coordination_required": True
            }
        },
        {
            "name": "Cross-Chain Optimization",
            "payload": {
                "user_query": "I want to optimize my $100k portfolio across Ethereum, Solana, and Polygon chains. Find the highest yield opportunities while maintaining low impermanent loss risk. Compare gas fees and provide execution strategy.",
                "portfolio_data": {
                    "total_value": 100000,
                    "target_chains": ["ethereum", "solana", "polygon"],
                    "current_allocation": {
                        "ethereum": 60000,
                        "solana": 25000,
                        "polygon": 15000
                    },
                    "assets": {
                        "ETH": 20,
                        "SOL": 500,
                        "MATIC": 15000,
                        "USDC": 35000
                    }
                },
                "market_context": {
                    "gas_prices": {
                        "ethereum": 25,
                        "polygon": 30,
                        "solana": 0.00025
                    },
                    "defi_tvl_trend": "increasing"
                },
                "risk_preferences": {
                    "risk_tolerance": "high",
                    "min_yield_threshold": 12.0,
                    "max_impermanent_loss": 10.0,
                    "diversification_required": True
                },
                "execution_mode": "simulate",
                "coordination_required": True
            }
        },
        {
            "name": "Risk Assessment & Optimization",
            "payload": {
                "user_query": "Assess the risk of my current DeFi positions and suggest optimizations. I'm concerned about impermanent loss and protocol risks. Provide risk scores and safer alternatives with reasonable yields.",
                "portfolio_data": {
                    "total_value": 75000,
                    "assets": {
                        "SOL": {"amount": 500, "value": 37500, "price_usd": 75},
                        "USDT": {"amount": 37500, "value": 37500, "price_usd": 1.0}
                    },
                    "current_positions": {
                        "raydium_sol_usdt": {
                            "protocol": "raydium",
                            "pool": "SOL-USDT",
                            "liquidity_provided": 50000,
                            "current_apy": 15.5,
                            "position_age_days": 45
                        }
                    }
                },
                "market_context": {
                    "sol_volatility": "high",
                    "usdt_stability": "stable",
                    "protocol_risks": ["smart_contract", "impermanent_loss"]
                },
                "risk_preferences": {
                    "risk_tolerance": "low",
                    "max_impermanent_loss": 5.0,
                    "preferred_stability": "high",
                    "acceptable_apy_range": [6.0, 12.0]
                },
                "execution_mode": "analyze",
                "coordination_required": True
            }
        }
    ]
    
    for i, test in enumerate(test_queries, 1):
        print_info(f"Test {i}: {test['name']}")
        print_info(f"Query: {test['payload']['user_query']}")
        
        try:
            response = requests.post(
                f"{BASE_URL}/agents/{agent_id}/webhook", 
                headers=HEADERS,
                json=test['payload']
            )
            
            if response.status_code == 200:
                print_success("✅ Query processed successfully!")
                
                # Try to parse response
                try:
                    result = response.json()
                    print_info(f"Response type: {type(result)}")
                    if isinstance(result, dict):
                        print_info(f"Response keys: {list(result.keys())}")
                        
                        # Display detailed response content
                        print_section(f"Response Details for {test['name']}")
                        
                        if "success" in result:
                            print_info(f"Success: {result['success']}")
                        
                        if "message" in result:
                            print_info("📄 Response Message:")
                            print(f"   {result['message']}")
                        
                        if "coordination_rounds" in result:
                            print_info(f"🔄 Coordination Rounds: {result['coordination_rounds']}")
                        
                        if "consensus_achieved" in result:
                            print_info(f"🤝 Consensus Achieved: {result['consensus_achieved']}")
                        
                        if "swarm_results" in result and result["swarm_results"]:
                            print_info("🔍 Swarm Analysis Results:")
                            for key, swarm_result in result["swarm_results"].items():
                                print(f"   • {key.title()}:")
                                if isinstance(swarm_result, dict):
                                    if "success" in swarm_result:
                                        status = "✅ Success" if swarm_result["success"] else "❌ Failed"
                                        print(f"     Status: {status}")
                                    if "message" in swarm_result:
                                        message = swarm_result["message"]
                                        # Truncate long messages for readability
                                        if len(message) > 300:
                                            message = message[:300] + "..."
                                        print(f"     Result: {message}")
                                    if "agent_role" in swarm_result:
                                        print(f"     Agent Role: {swarm_result['agent_role']}")
                                else:
                                    print(f"     {swarm_result}")
                        
                        print()  # Add extra spacing
                        
                    else:
                        print_info(f"Response preview: {str(result)[:500]}...")
                except Exception as parse_error:
                    # Handle text response
                    response_text = response.text
                    print_info(f"Response (text): {response_text[:500]}...")
                    print_error(f"JSON parsing failed: {parse_error}")
                    
            else:
                print_error(f"❌ Query failed: {response.status_code}")
                print_error(f"Error details: {response.text}")
                
        except Exception as e:
            print_error(f"❌ Request error: {e}")
        
        print()  # Add spacing between tests
        time.sleep(2)  # Pause between requests

def demo_yieldswarm_system():
    """Demonstrate YieldSwarm system capabilities"""
    
    print_section("YieldSwarm DeFi Yield Optimization System Demo")
    print_info(f"Testing system at: {BASE_URL}")
    print_info(f"Timestamp: {datetime.now().strftime('%Y-%m-%d %H:%M:%S')}")
    
    # 1. Check server status
    print_section("Server Status Check")
    try:
        response = requests.get(f"{BASE_URL}/agents")
        print_success(f"Server is running! Found {len(response.json())} active agents")
        
        # Show available agents
        agents = response.json()
        for agent in agents:
            print_info(f"Agent: {agent['name']} ({agent['state']})")
            
    except Exception as e:
        print_error(f"Server connection failed: {e}")
        return False
    
    # 2. Check YieldSwarm strategy availability  
    print_section("YieldSwarm Strategy Verification")
    try:
        response = requests.get(f"{BASE_URL}/strategies")
        strategies = response.json()
        
        if "yieldswarm" in [s["name"] for s in strategies]:
            print_success("YieldSwarm strategy is registered and available!")
        else:
            print_error("YieldSwarm strategy not found")
            return False
            
    except Exception as e:
        print_error(f"Strategy check failed: {e}")
        return False
    
    # 3. Check YieldSwarm tools availability
    print_section("YieldSwarm Tools Verification")
    try:
        response = requests.get(f"{BASE_URL}/tools")  
        tools = response.json()
        
        yieldswarm_tools = [
            "yieldswarm_analyzer",
            "yieldswarm_executor", 
            "yieldswarm_risk_manager"
        ]
        
        found_tools = []
        for tool in tools:
            if tool["name"] in yieldswarm_tools:
                found_tools.append(tool["name"])
                print_success(f"Tool available: {tool['name']}")
                print_info(f"  Description: {tool['metadata']['description'][:100]}...")
        
        if len(found_tools) == len(yieldswarm_tools):
            print_success("All YieldSwarm tools are registered and available!")
        else:
            missing = set(yieldswarm_tools) - set(found_tools)
            print_error(f"Missing tools: {missing}")
            
    except Exception as e:
        print_error(f"Tools check failed: {e}")
        return False
    
    # 4. Create and test YieldSwarm agent
    agent_id = create_yieldswarm_agent()
    if not agent_id:
        print_error("Failed to create YieldSwarm agent - stopping demo")
        return False
    
    # 5. Test agent functionality
    test_yieldswarm_functionality(agent_id)
    
    # 6. Demonstrate YieldSwarm capabilities
    print_section("YieldSwarm System Capabilities")
    
    capabilities = [
        "🔍 Multi-Chain Yield Analysis (Ethereum, Solana, Polygon)",
        "⚡ Real-time DeFi Protocol Monitoring", 
        "🛡️ Advanced Risk Management & Assessment",
        "🔄 Automated Cross-Chain Execution",
        "📊 Portfolio Optimization & Rebalancing",
        "🤖 AI-Powered Swarm Intelligence Coordination",
        "💎 Integration with Major DEXs (Uniswap, Raydium, SushiSwap)",
        "📈 Yield Farming Strategy Optimization",
        "⚠️ Impermanent Loss Protection",
        "🚨 Real-time Risk Monitoring & Alerts"
    ]
    
    for capability in capabilities:
        print_info(capability)
        time.sleep(0.1)  # Small delay for visual effect
    
    # 7. Show demo completion
    print_section("YieldSwarm Demo Complete")
    print_success("YieldSwarm system successfully demonstrated!")
    print_info("Agent remains active for further testing")
    print_info(f"Agent ID: {agent_id}")
    print_info("You can now test the agent via frontend or additional API calls")
    
    return True

if __name__ == "__main__":
    success = demo_yieldswarm_system()
    if success:
        print_success("🎉 YieldSwarm demonstration completed successfully!")
    else:
        print_error("❌ YieldSwarm demonstration failed")
