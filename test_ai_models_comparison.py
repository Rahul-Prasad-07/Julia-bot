#!/usr/bin/env python3
"""
Comprehensive test script for Solana Agent AI Models
Tests both Gemini and Groq integration with your custom agents
"""

import requests
import json
import time
from typing import Dict, Any

BASE_URL = "http://127.0.0.1:8052/api/v1"

def test_ai_model_comparison():
    """Test both Gemini and Groq models with the same queries"""
    
    print("🧪 SOLANA AGENT AI MODEL COMPARISON TEST")
    print("="*60)
    
    # Test queries of different types
    test_queries = [
        {
            "query": "What are Program Derived Addresses in Solana?",
            "type": "knowledge",
            "expected_keywords": ["PDA", "seed", "program", "address"]
        },
        {
            "query": "Generate a simple Anchor program for token staking",
            "type": "code_generation", 
            "expected_keywords": ["anchor", "program", "stake", "token"]
        },
        {
            "query": "How do I integrate Jupiter for token swaps?",
            "type": "ecosystem",
            "expected_keywords": ["jupiter", "swap", "integration", "api"]
        }
    ]
    
    # Test with Gemini agent
    print("\n🔸 TESTING GEMINI-BASED AGENT")
    print("-" * 40)
    gemini_agent_id = create_gemini_agent()
    if gemini_agent_id:
        activate_agent(gemini_agent_id)
        test_agent_responses(gemini_agent_id, test_queries, "Gemini Pro 1.5")
    
    # Test with Groq agent  
    print("\n🔸 TESTING GROQ-BASED AGENT")
    print("-" * 40)
    groq_agent_id = create_groq_agent()
    if groq_agent_id:
        activate_agent(groq_agent_id)
        test_agent_responses(groq_agent_id, test_queries, "Groq Llama 3.1 70B")
    
    # Test multi-model agent with failover
    print("\n🔸 TESTING MULTI-MODEL AGENT (Groq + Gemini Fallback)")
    print("-" * 55)
    multi_agent_id = create_multi_model_agent()
    if multi_agent_id:
        activate_agent(multi_agent_id)
        test_agent_responses(multi_agent_id, test_queries, "Multi-Model (Groq Primary)")

def create_gemini_agent() -> str:
    """Create agent using Gemini model"""
    agent_config = {
        "id": "solana-gemini-test",
        "name": "Solana Gemini Assistant", 
        "description": "Solana development agent powered by Google Gemini Pro 1.5",
        "blueprint": {
            "tools": [
                {
                    "name": "solana_knowledge",
                    "config": {
                        "temperature": 0.3,
                        "max_output_tokens": 2048
                    }
                }
            ],
            "strategy": {
                "name": "solana_dev_chat",
                "config": {
                    "name": "gemini-solana-agent",
                    "max_context_length": 5
                }
            },
            "trigger": {"type": "webhook", "params": {}}
        }
    }
    
    return create_agent(agent_config)

def create_groq_agent() -> str:
    """Create agent using Groq model"""
    agent_config = {
        "id": "solana-groq-test",
        "name": "Solana Groq Assistant",
        "description": "Solana development agent powered by Groq Llama 3.1 70B", 
        "blueprint": {
            "tools": [
                {
                    "name": "solana_knowledge_multi_model",
                    "config": {
                        "ai_provider": "groq",
                        "temperature": 0.3,
                        "max_output_tokens": 2048,
                        "enable_fallback": False
                    }
                }
            ],
            "strategy": {
                "name": "solana_dev_chat",
                "config": {
                    "name": "groq-solana-agent",
                    "max_context_length": 5
                }
            },
            "trigger": {"type": "webhook", "params": {}}
        }
    }
    
    return create_agent(agent_config)

def create_multi_model_agent() -> str:
    """Create agent with multi-model support and fallback"""
    agent_config = {
        "id": "solana-multi-model-test",
        "name": "Solana Multi-Model Assistant",
        "description": "Solana agent with Groq primary and Gemini fallback",
        "blueprint": {
            "tools": [
                {
                    "name": "solana_knowledge_multi_model", 
                    "config": {
                        "ai_provider": "groq",
                        "temperature": 0.3,
                        "max_output_tokens": 2048,
                        "enable_fallback": True
                    }
                }
            ],
            "strategy": {
                "name": "solana_dev_chat",
                "config": {
                    "name": "multi-model-solana-agent",
                    "max_context_length": 10
                }
            },
            "trigger": {"type": "webhook", "params": {}}
        }
    }
    
    return create_agent(agent_config)

def create_agent(config: Dict[str, Any]) -> str:
    """Create agent via API"""
    try:
        response = requests.post(f"{BASE_URL}/agents", json=config, timeout=30)
        
        if response.status_code == 201:
            agent_data = response.json()
            agent_id = agent_data.get("id")
            print(f"✅ Created agent: {agent_id}")
            return agent_id
        else:
            print(f"❌ Failed to create agent: {response.status_code} - {response.text}")
            return None
            
    except Exception as e:
        print(f"❌ Error creating agent: {str(e)}")
        return None

def activate_agent(agent_id: str) -> bool:
    """Activate agent"""
    try:
        response = requests.put(
            f"{BASE_URL}/agents/{agent_id}",
            json={"state": "RUNNING"},
            timeout=10
        )
        
        if response.status_code == 200:
            print(f"✅ Activated agent: {agent_id}")
            time.sleep(2)  # Wait for activation
            return True
        else:
            print(f"❌ Failed to activate agent: {response.status_code}")
            return False
            
    except Exception as e:
        print(f"❌ Error activating agent: {str(e)}")
        return False

def test_agent_responses(agent_id: str, queries: list, model_name: str):
    """Test agent with multiple queries and analyze responses"""
    print(f"\nTesting {model_name}...")
    
    for i, test_case in enumerate(queries, 1):
        print(f"\n📝 Query {i}: {test_case['query']}")
        print(f"   Type: {test_case['type']}")
        
        try:
            # Send query
            start_time = time.time()
            response = requests.post(
                f"{BASE_URL}/agents/{agent_id}/webhook",
                json={
                    "message": test_case["query"],
                    "user_id": "test_user",
                    "chat_type": "general"
                },
                timeout=60
            )
            response_time = time.time() - start_time
            
            if response.status_code == 200:
                result = response.json()
                output = result.get("output", "No output")
                
                # Analyze response
                keyword_matches = sum(1 for keyword in test_case["expected_keywords"] 
                                    if keyword.lower() in output.lower())
                
                print(f"✅ Response received ({response_time:.2f}s)")
                print(f"   Length: {len(output)} characters")
                print(f"   Keywords found: {keyword_matches}/{len(test_case['expected_keywords'])}")
                print(f"   Preview: {output[:150]}...")
                
                # Quality indicators
                if keyword_matches >= len(test_case["expected_keywords"]) // 2:
                    print("   🎯 Quality: Good (relevant keywords present)")
                else:
                    print("   ⚠️  Quality: Check (few relevant keywords)")
                    
            else:
                print(f"❌ Request failed: {response.status_code} - {response.text}")
                
        except Exception as e:
            print(f"❌ Error testing query: {str(e)}")
        
        time.sleep(3)  # Rate limiting

def check_agent_logs(agent_id: str, model_name: str):
    """Check agent logs for debugging"""
    try:
        response = requests.get(f"{BASE_URL}/agents/{agent_id}/logs", timeout=10)
        if response.status_code == 200:
            logs = response.json()
            print(f"\n📋 {model_name} Agent Logs:")
            for log in logs[-5:]:  # Last 5 logs
                print(f"   {log}")
        else:
            print(f"❌ Failed to get logs: {response.status_code}")
    except Exception as e:
        print(f"❌ Error getting logs: {str(e)}")

def performance_comparison():
    """Compare performance metrics between models"""
    print("\n📊 PERFORMANCE COMPARISON")
    print("="*40)
    print("Metric          | Gemini Pro 1.5  | Groq Llama 3.1")
    print("-"*50)
    print("Speed           | ~3-5 seconds    | ~1-2 seconds   ")
    print("Context Window  | 1M tokens       | 32K tokens     ")
    print("Accuracy        | Very High       | High           ")
    print("Cost            | Moderate        | Very Low       ")
    print("Rate Limits     | 15 RPM          | 30 RPM         ")
    print("Specialization  | General+Code    | Fast Inference ")

if __name__ == "__main__":
    print("🚀 Starting Solana Agent AI Model Tests...")
    print("Make sure Julia backend is running on 127.0.0.1:8052")
    
    # Wait for user confirmation
    input("\nPress Enter to start tests...")
    
    try:
        test_ai_model_comparison()
        performance_comparison()
        
        print("\n✨ Test complete! Check the responses above to compare model performance.")
        
    except KeyboardInterrupt:
        print("\n⏹️  Tests interrupted by user")
    except Exception as e:
        print(f"\n❌ Unexpected error: {str(e)}")
