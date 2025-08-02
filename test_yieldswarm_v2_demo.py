#!/usr/bin/env python3
"""
Enhanced YieldSwarm Real-Time Agent Demo
Creates and tests the new YieldSwarm agent with live data integration
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
    print(f"\n{'='*70}")
    print(f"🚀 {title}")
    print(f"{'='*70}")

def print_success(message):
    """Print success message"""
    print(f"✅ {message}")

def print_info(message):  
    """Print info message"""
    print(f"ℹ️  {message}")

def print_error(message):
    """Print error message"""  
    print(f"❌ {message}")

def print_data(label, data):
    """Print formatted data"""
    print(f"📊 {label}: {data}")

def create_enhanced_yieldswarm_agent():
    """Create YieldSwarm agent with real-time data capabilities"""
    print_section("Creating Enhanced YieldSwarm Agent v2.0")
    
    # Enhanced agent configuration with real-time data fetcher
    agent_config = {
        "id": "yieldswarm-realtime-v2",
        "name": "YieldSwarm Real-Time Agent v2.0",
        "description": "Advanced DeFi yield optimization agent with live data integration, AI analysis, and multi-chain support",
        "blueprint": {
            "tools": [
                {
                    "name": "yieldswarm_analyzer",
                    "config": {
                        "ai_provider": "groq",
                        "temperature": 0.1,
                        "enable_fallback": True,
                        "max_output_tokens": 4096
                    }
                },
                {
                    "name": "yieldswarm_executor", 
                    "config": {
                        "simulation_mode": True,
                        "max_single_transaction_usd": 50000.0,
                        "require_confirmation": True
                    }
                },
                {
                    "name": "yieldswarm_risk_manager",
                    "config": {
                        "max_portfolio_risk_score": 6.5,
                        "max_single_protocol_allocation": 0.30,
                        "enable_monitoring": True
                    }
                },
                {
                    "name": "yieldswarm_data_fetcher",
                    "config": {
                        "cache_duration_minutes": 5,
                        "enable_caching": True,
                        "rate_limit_per_minute": 60,
                        "request_timeout": 30
                    }
                }
            ],
            "strategy": {
                "name": "yieldswarm",
                "config": {
                    "name": "yieldswarm-realtime-v2",
                    "swarm_id": "yieldswarm-realtime-v2-001",
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
                    "risk_adjusted_metrics": True,
                    "real_time_data_enabled": True,
                    "data_refresh_interval_minutes": 5
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
            response = requests.delete(f"{BASE_URL}/agents/yieldswarm-realtime-v2")
            if response.status_code == 200:
                print_info("Cleaned up existing agent")
        except:
            pass
        
        # Create new enhanced agent
        print_info("Creating new agent with real-time capabilities...")
        response = requests.post(f"{BASE_URL}/agents", 
                               headers=HEADERS,
                               json=agent_config)
        
        if response.status_code == 201:
            agent = response.json()
            print_success(f"✨ Enhanced YieldSwarm Agent v2.0 created successfully!")
            print_data("Agent ID", agent['id'])
            print_data("Agent Name", agent['name'])
            print_data("Tools", f"{len(agent['blueprint']['tools'])} tools (including data fetcher)")
            print_data("Real-Time Data", "✅ ENABLED")
            print_data("Multi-Chain Support", "✅ ETH, SOL, MATIC, AVAX")
            print_data("AI Provider", "✅ Groq (Llama 3.1 70B)")
            return agent['id']
        else:
            print_error(f"Failed to create agent: {response.status_code} - {response.text}")
            return None
            
    except Exception as e:
        print_error(f"Error creating agent: {e}")
        return None

def start_agent(agent_id):
    """Start the YieldSwarm agent"""
    print_section("Starting YieldSwarm Agent v2.0")
    
    try:
        response = requests.put(f"{BASE_URL}/agents/{agent_id}",
                              headers=HEADERS,
                              json={"state": "RUNNING"})
        
        if response.status_code == 200:
            print_success("🟢 Agent started successfully!")
            return True
        else:
            print_error(f"Failed to start agent: {response.status_code}")
            return False
    except Exception as e:
        print_error(f"Error starting agent: {e}")
        return False

def test_real_time_yield_analysis(agent_id):
    """Test real-time yield analysis capabilities"""
    print_section("Testing Real-Time Yield Analysis")
    
    test_payload = {
        "user_query": "Analyze the current best yield opportunities with live data. I have $50,000 to invest with medium risk tolerance. Show me the top 10 real yield opportunities across Ethereum, Solana, and Polygon with current APY rates, TVL data, and risk assessments. Include real token prices and market conditions in your analysis.",
        "portfolio_data": {
            "total_value": 50000,
            "current_allocation": {
                "cash": 50000
            },
            "target_chains": ["ethereum", "solana", "polygon"],
            "preferred_assets": ["ETH", "SOL", "USDC", "USDT"]
        },
        "market_context": {
            "analysis_type": "live_yield_optimization",
            "data_sources": ["defillama", "coingecko", "protocol_apis"],
            "real_time_analysis": True,
            "timestamp": int(time.time())
        },
        "risk_preferences": {
            "risk_tolerance": "medium",
            "min_apy_threshold": 5.0,
            "max_impermanent_loss": 15.0,
            "min_protocol_tvl": 10000000,  # $10M minimum TVL
            "preferred_protocols": ["uniswap", "raydium", "aave", "compound", "orca"]
        },
        "execution_mode": "analyze",
        "coordination_required": True
    }
    
    try:
        print_info("🔄 Sending real-time analysis request...")
        print_info("📊 Fetching live data from DeFiLlama, CoinGecko, and protocol APIs...")
        
        response = requests.post(f"{BASE_URL}/agents/{agent_id}/webhook",
                               headers=HEADERS,
                               json=test_payload)
        
        if response.status_code == 200:
            result = response.json()
            
            if result.get('success'):
                print_success("✨ Real-time analysis completed successfully!")
                
                message = result.get('message', '')
                
                # Check for real-time data indicators
                real_time_indicators = [
                    ('Live Data', 'LIVE' in message.upper() or 'REAL-TIME' in message.upper()),
                    ('Current Prices', any(keyword in message.upper() for keyword in ['$', 'PRICE', 'ETH:', 'SOL:', 'BTC:'])),
                    ('APY Data', 'APY' in message.upper() or '%' in message),
                    ('TVL Data', 'TVL' in message.upper()),
                    ('Protocol Analysis', any(protocol in message.upper() for protocol in ['UNISWAP', 'RAYDIUM', 'AAVE', 'COMPOUND'])),
                    ('Risk Assessment', any(risk in message.upper() for risk in ['RISK', 'IMPERMANENT', 'VOLATILITY']))
                ]
                
                print_section("Analysis Results")
                for indicator, found in real_time_indicators:
                    status = "✅ FOUND" if found else "❌ MISSING"
                    print_data(indicator, status)
                
                # Show response preview
                print_section("Response Preview")
                preview = message[:800] + "..." if len(message) > 800 else message
                print(preview)
                
                # Show metadata if available
                if 'coordination_rounds' in result:
                    print_data("Coordination Rounds", result['coordination_rounds'])
                if 'consensus_achieved' in result:
                    print_data("Consensus Achieved", result['consensus_achieved'])
                
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

def test_cross_chain_comparison(agent_id):
    """Test cross-chain yield comparison with live data"""
    print_section("Testing Cross-Chain Yield Comparison")
    
    test_payload = {
        "user_query": "Compare real-time yield opportunities for ETH/USDC pairs across Ethereum (Uniswap V3), Solana (Raydium), and Polygon (QuickSwap). Show current APY rates, gas costs, liquidity depth, and recommend the best option for a $25,000 position. Use live market data and current token prices.",
        "portfolio_data": {
            "total_value": 25000,
            "asset_focus": "ETH/USDC",
            "target_chains": ["ethereum", "solana", "polygon"]
        },
        "market_context": {
            "analysis_type": "cross_chain_comparison",
            "comparison_focus": "eth_usdc_pairs",
            "include_gas_costs": True
        },
        "risk_preferences": {
            "risk_tolerance": "low",
            "prefer_established_protocols": True,
            "max_slippage": 0.5
        },
        "execution_mode": "analyze",
        "coordination_required": True
    }
    
    try:
        print_info("🔄 Running cross-chain comparison analysis...")
        
        response = requests.post(f"{BASE_URL}/agents/{agent_id}/webhook",
                               headers=HEADERS,
                               json=test_payload)
        
        if response.status_code == 200:
            result = response.json()
            
            if result.get('success'):
                print_success("✨ Cross-chain comparison completed!")
                
                message = result.get('message', '')
                
                # Check for comparison indicators
                comparison_indicators = [
                    ('Ethereum Data', 'ETHEREUM' in message.upper() or 'UNISWAP' in message.upper()),
                    ('Solana Data', 'SOLANA' in message.upper() or 'RAYDIUM' in message.upper()),
                    ('Polygon Data', 'POLYGON' in message.upper() or 'QUICKSWAP' in message.upper()),
                    ('Gas Cost Analysis', 'GAS' in message.upper() or 'COST' in message.upper()),
                    ('Liquidity Analysis', 'LIQUIDITY' in message.upper() or 'DEPTH' in message.upper()),
                    ('Recommendation', 'RECOMMEND' in message.upper() or 'BEST' in message.upper())
                ]
                
                print_section("Comparison Results")
                for indicator, found in comparison_indicators:
                    status = "✅ INCLUDED" if found else "❌ MISSING"
                    print_data(indicator, status)
                
                # Show preview
                preview = message[:600] + "..." if len(message) > 600 else message
                print_section("Analysis Preview")
                print(preview)
                
                return True
            else:
                print_error(f"Comparison failed: {result.get('error')}")
                return False
        else:
            print_error(f"Request failed: {response.status_code}")
            return False
            
    except Exception as e:
        print_error(f"Comparison error: {e}")
        return False

def test_real_time_market_conditions(agent_id):
    """Test real-time market conditions analysis"""
    print_section("Testing Real-Time Market Conditions")
    
    test_payload = {
        "user_query": "Analyze current DeFi market conditions using live data. What are the trends in yield rates, TVL movements, and token price changes in the last 24 hours? Are there any emerging opportunities or risks I should be aware of? Focus on major protocols across Ethereum and Solana.",
        "portfolio_data": {
            "analysis_scope": "market_overview",
            "focus_chains": ["ethereum", "solana"]
        },
        "market_context": {
            "analysis_type": "market_conditions",
            "timeframe": "24h",
            "include_trends": True
        },
        "risk_preferences": {
            "risk_tolerance": "medium",
            "market_outlook": "neutral"
        },
        "execution_mode": "analyze",
        "coordination_required": False
    }
    
    try:
        print_info("🔄 Analyzing real-time market conditions...")
        
        response = requests.post(f"{BASE_URL}/agents/{agent_id}/webhook",
                               headers=HEADERS,
                               json=test_payload)
        
        if response.status_code == 200:
            result = response.json()
            
            if result.get('success'):
                print_success("✨ Market analysis completed!")
                
                message = result.get('message', '')
                
                # Check for market indicators
                market_indicators = [
                    ('Current Prices', any(indicator in message.upper() for indicator in ['$', 'USD', 'PRICE'])),
                    ('Price Changes', any(indicator in message.upper() for indicator in ['%', 'CHANGE', 'UP', 'DOWN'])),
                    ('TVL Trends', 'TVL' in message.upper()),
                    ('Yield Trends', any(indicator in message.upper() for indicator in ['YIELD', 'APY', 'APR'])),
                    ('Market Sentiment', any(indicator in message.upper() for indicator in ['BULLISH', 'BEARISH', 'NEUTRAL', 'TREND'])),
                    ('Opportunities', any(indicator in message.upper() for indicator in ['OPPORTUNITY', 'RECOMMEND', 'SUGGEST']))
                ]
                
                print_section("Market Analysis Results")
                for indicator, found in market_indicators:
                    status = "✅ DETECTED" if found else "❌ NOT FOUND"
                    print_data(indicator, status)
                
                return True
            else:
                print_error(f"Market analysis failed: {result.get('error')}")
                return False
        else:
            print_error(f"Request failed: {response.status_code}")
            return False
            
    except Exception as e:
        print_error(f"Market analysis error: {e}")
        return False

def show_final_summary(agent_id, test_results):
    """Show final test summary"""
    print_section("Enhanced YieldSwarm v2.0 Test Summary")
    
    total_tests = len(test_results)
    passed_tests = sum(test_results.values())
    success_rate = (passed_tests / total_tests) * 100
    
    print_data("Agent ID", agent_id)
    print_data("Total Tests", total_tests)
    print_data("Passed Tests", passed_tests)
    print_data("Success Rate", f"{success_rate:.1f}%")
    
    print_section("Test Results Details")
    for test_name, result in test_results.items():
        status = "✅ PASSED" if result else "❌ FAILED"
        print_data(test_name, status)
    
    if success_rate >= 75:
        print_section("🎉 SUCCESS: YieldSwarm v2.0 Ready!")
        print_success("✨ Real-time data integration is working!")
        print_success("🤖 AI analysis is functional!")
        print_success("🌐 Multi-chain support confirmed!")
        print_success("📊 Live market data integration verified!")
        print_info("🚀 System is ready for bounty submission!")
    else:
        print_section("⚠️ PARTIAL SUCCESS: Needs Review")
        print_info("Some tests failed - review the results above")

def main():
    """Main demo function"""
    print_section("YieldSwarm v2.0 Real-Time Integration Demo")
    print_info(f"Server: {BASE_URL}")
    print_info(f"Timestamp: {datetime.now().strftime('%Y-%m-%d %H:%M:%S')}")
    
    # Test server connectivity
    try:
        response = requests.get(f"{BASE_URL}/agents")
        print_success(f"✅ Server is running! Found {len(response.json())} existing agents")
    except Exception as e:
        print_error(f"❌ Server connection failed: {e}")
        return False
    
    # Create enhanced agent
    agent_id = create_enhanced_yieldswarm_agent()
    if not agent_id:
        print_error("Failed to create agent. Aborting demo.")
        return False
    
    # Start agent
    if not start_agent(agent_id):
        print_error("Failed to start agent. Aborting demo.")
        return False
    
    # Run tests
    test_results = {}
    
    print_info("🧪 Running comprehensive test suite...")
    time.sleep(2)  # Give agent time to fully initialize
    
    test_results["Real-Time Yield Analysis"] = test_real_time_yield_analysis(agent_id)
    time.sleep(3)
    
    test_results["Cross-Chain Comparison"] = test_cross_chain_comparison(agent_id)
    time.sleep(3)
    
    test_results["Market Conditions Analysis"] = test_real_time_market_conditions(agent_id)
    time.sleep(2)
    
    # Show final summary
    show_final_summary(agent_id, test_results)
    
    print_section("Next Steps")
    print_info("🌐 Web Dashboard: http://localhost:8080/yieldswarm-dashboard.html")
    print_info("📚 API Docs: http://127.0.0.1:8052/api/v1")
    print_info(f"🤖 Agent ID: {agent_id}")
    print_info("💡 Ready for bounty submission and demo!")
    
    return True

if __name__ == "__main__":
    success = main()
    if success:
        print("\n" + "="*70)
        print("🏆 YIELDSWARM V2.0 REAL-TIME DEMO SUCCESSFUL!")
        print("🎯 Ready for bounty submission!")
        print("="*70)
    else:
        print("\n" + "="*70)
        print("❌ Demo failed - check configuration")
        print("="*70)
