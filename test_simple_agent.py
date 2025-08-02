#!/usr/bin/env python3
"""
Simple YieldSwarm Agent Test
Test with minimal configuration to isolate the issue
"""

import requests
import json

BASE_URL = "http://127.0.0.1:8052/api/v1"
HEADERS = {"Content-Type": "application/json"}

def test_simple_agent():
    """Test creating a minimal YieldSwarm agent"""
    
    # Very simple agent configuration
    agent_config = {
        "id": "yieldswarm-simple-test",
        "name": "YieldSwarm Simple Test",
        "description": "Simple test agent for YieldSwarm functionality",
        "blueprint": {
            "tools": [
                {
                    "name": "yieldswarm_data_fetcher",
                    "config": {}
                }
            ],
            "strategy": {
                "name": "yieldswarm",
                "config": {
                    "name": "simple-test",
                    "swarm_id": "test-001",
                    "agent_role": "coordinator"
                }
            },
            "trigger": {
                "type": "webhook",
                "params": {}
            }
        }
    }
    
    try:
        # Clean up existing
        try:
            requests.delete(f"{BASE_URL}/agents/yieldswarm-simple-test")
        except:
            pass
        
        print("Creating simple agent...")
        response = requests.post(f"{BASE_URL}/agents", 
                               headers=HEADERS,
                               json=agent_config)
        
        print(f"Response Status: {response.status_code}")
        print(f"Response Text: {response.text}")
        
        if response.status_code == 201:
            print("✅ Simple agent created successfully!")
            return response.json()
        else:
            print(f"❌ Failed: {response.status_code}")
            print(f"Error: {response.text}")
            return None
            
    except Exception as e:
        print(f"Exception: {e}")
        return None

def test_with_analyzer_tool():
    """Test with yieldswarm_analyzer tool"""
    
    agent_config = {
        "id": "yieldswarm-analyzer-test", 
        "name": "YieldSwarm Analyzer Test",
        "description": "Test agent with analyzer tool",
        "blueprint": {
            "tools": [
                {
                    "name": "yieldswarm_analyzer",
                    "config": {
                        "ai_provider": "groq"
                    }
                }
            ],
            "strategy": {
                "name": "yieldswarm",
                "config": {
                    "name": "analyzer-test",
                    "swarm_id": "test-002"
                }
            },
            "trigger": {
                "type": "webhook",
                "params": {}
            }
        }
    }
    
    try:
        # Clean up existing
        try:
            requests.delete(f"{BASE_URL}/agents/yieldswarm-analyzer-test")
        except:
            pass
        
        print("\nCreating analyzer agent...")
        response = requests.post(f"{BASE_URL}/agents",
                               headers=HEADERS,
                               json=agent_config)
        
        print(f"Response Status: {response.status_code}")
        print(f"Response Text: {response.text}")
        
        if response.status_code == 201:
            print("✅ Analyzer agent created successfully!")
            return response.json()
        else:
            print(f"❌ Failed: {response.status_code}")
            return None
            
    except Exception as e:
        print(f"Exception: {e}")
        return None

def test_available_tools():
    """Check what tools are available"""
    try:
        response = requests.get(f"{BASE_URL}/tools")
        print(f"\nAvailable Tools (Status: {response.status_code}):")
        if response.status_code == 200:
            tools = response.json()
            for tool in tools:
                print(f"  - {tool}")
        else:
            print(f"Error: {response.text}")
    except Exception as e:
        print(f"Error checking tools: {e}")

if __name__ == "__main__":
    print("YieldSwarm Agent Creation Test")
    print("="*50)
    
    # Test available tools first
    test_available_tools()
    
    # Test simple agent
    result1 = test_simple_agent()
    
    # Test analyzer agent if simple works
    if result1:
        result2 = test_with_analyzer_tool()
    else:
        print("Skipping analyzer test due to simple test failure")
