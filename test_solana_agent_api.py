#!/usr/bin/env python3
"""
Complete API Testing Script for Custom Solana Agents
This script demonstrates how to create, configure, and interact with your Solana development agents.
"""

import requests
import json
import time
from typing import Dict, Any

# Configuration
BASE_URL = "http://127.0.0.1:8052/api/v1"
HEADERS = {"Content-Type": "application/json"}

class SolanaAgentTester:
    def __init__(self, base_url: str = BASE_URL):
        self.base_url = base_url
        self.session = requests.Session()
        self.session.headers.update(HEADERS)
    
    def create_solana_chat_agent(self) -> str:
        """Create a Solana Development Chat Agent"""
        agent_config = {
            "id": "solana-dev-chat-001",
            "name": "Solana Development Assistant",
            "description": "AI assistant for Solana blockchain development, smart contracts, and DeFi",
            "blueprint": {
                "tools": [
                    {
                        "name": "solana_knowledge",
                        "config": {
                            "temperature": 0.3,
                            "max_output_tokens": 2048
                        }
                    },
                    {
                        "name": "solana_code_gen", 
                        "config": {
                            "temperature": 0.4,
                            "max_output_tokens": 4096
                        }
                    },
                    {
                        "name": "solana_ecosystem",
                        "config": {
                            "temperature": 0.2,
                            "max_output_tokens": 3072
                        }
                    }
                ],
                "strategy": {
                    "name": "solana_dev_chat",
                    "config": {
                        "name": "solana-dev-assistant",
                        "welcome_message": "Hello! I'm your Solana Development Assistant. Ready to help with smart contracts, DeFi, and ecosystem tools!",
                        "max_context_length": 10
                    }
                },
                "trigger": {
                    "type": "webhook",
                    "params": {}
                }
            }
        }
        
        print("🚀 Creating Solana Chat Agent...")
        response = self.session.post(f"{self.base_url}/agents", json=agent_config)
        
        if response.status_code == 201:
            agent_data = response.json()
            print(f"✅ Agent created successfully: {agent_data['id']}")
            print(f"   State: {agent_data['state']}")
            return agent_data['id']
        else:
            print(f"❌ Failed to create agent: {response.status_code}")
            print(f"   Error: {response.text}")
            return None

    def create_solana_swarm_agent(self) -> str:
        """Create a Solana Swarm Development Agent"""
        agent_config = {
            "id": "solana-swarm-coordinator-001",
            "name": "Solana Swarm Coordinator",
            "description": "Multi-agent coordinator for complex Solana development projects",
            "blueprint": {
                "tools": [
                    {
                        "name": "solana_knowledge",
                        "config": {"temperature": 0.2}
                    },
                    {
                        "name": "solana_code_gen",
                        "config": {"temperature": 0.3}
                    },
                    {
                        "name": "solana_ecosystem",
                        "config": {"temperature": 0.1}
                    }
                ],
                "strategy": {
                    "name": "solana_swarm_dev",
                    "config": {
                        "name": "solana-swarm-coordinator",
                        "agent_role": "coordinator",
                        "swarm_id": "solana-dev-swarm-001",
                        "max_iterations": 5
                    }
                },
                "trigger": {
                    "type": "webhook",
                    "params": {}
                }
            }
        }
        
        print("🚀 Creating Solana Swarm Agent...")
        response = self.session.post(f"{self.base_url}/agents", json=agent_config)
        
        if response.status_code == 201:
            agent_data = response.json()
            print(f"✅ Swarm Agent created successfully: {agent_data['id']}")
            print(f"   State: {agent_data['state']}")
            return agent_data['id']
        else:
            print(f"❌ Failed to create swarm agent: {response.status_code}")
            print(f"   Error: {response.text}")
            return None

    def update_agent_state(self, agent_id: str, new_state: str) -> bool:
        """Update agent state (e.g., CREATED -> RUNNING)"""
        update_data = {"state": new_state}
        
        print(f"🔄 Updating agent {agent_id} state to {new_state}...")
        response = self.session.put(f"{self.base_url}/agents/{agent_id}", json=update_data)
        
        if response.status_code == 200:
            print(f"✅ Agent state updated successfully")
            return True
        else:
            print(f"❌ Failed to update agent state: {response.status_code}")
            print(f"   Error: {response.text}")
            return False

    def test_chat_agent_queries(self, agent_id: str):
        """Test various types of queries with the chat agent"""
        test_queries = [
            {
                "type": "knowledge",
                "query": {
                    "message": "What are Program Derived Addresses (PDAs) in Solana and why are they important?",
                    "user_id": "test_user_1",
                    "chat_type": "general"
                }
            },
            {
                "type": "code_generation", 
                "query": {
                    "message": "Generate a basic Anchor program for a simple token swap",
                    "user_id": "test_user_1",
                    "chat_type": "code_gen"
                }
            },
            {
                "type": "ecosystem",
                "query": {
                    "message": "How do I integrate with Jupiter for token swaps in my dApp?",
                    "user_id": "test_user_1", 
                    "chat_type": "ecosystem"
                }
            }
        ]
        
        print(f"\n🧪 Testing Chat Agent: {agent_id}")
        print("=" * 50)
        
        for i, test in enumerate(test_queries, 1):
            print(f"\n📝 Test {i}: {test['type'].title()} Query")
            print(f"Query: {test['query']['message'][:60]}...")
            
            response = self.session.post(
                f"{self.base_url}/agents/{agent_id}/webhook",
                json=test['query']
            )
            
            if response.status_code == 200:
                print("✅ Query processed successfully")
                # Get agent logs to see the response
                logs_response = self.session.get(f"{self.base_url}/agents/{agent_id}/logs")
                if logs_response.status_code == 200:
                    logs = logs_response.json()['logs']
                    if logs:
                        print(f"📋 Latest log: {logs[-1][:100]}...")
                        
            else:
                print(f"❌ Query failed: {response.status_code}")
                print(f"   Error: {response.text}")
            
            time.sleep(2)  # Brief pause between requests

    def test_swarm_agent_tasks(self, agent_id: str):
        """Test complex multi-agent tasks with the swarm coordinator"""
        test_tasks = [
            {
                "task": "Create a comprehensive DeFi lending protocol on Solana with security audit",
                "project_context": {
                    "project_type": "defi_protocol",
                    "components": ["lending", "borrowing", "liquidation"],
                    "security_level": "high"
                },
                "priority": "high",
                "requires_coordination": True
            },
            {
                "task": "Audit this smart contract for common Solana vulnerabilities",
                "project_context": {
                    "project_type": "security_audit",
                    "focus_areas": ["account_validation", "pda_security", "arithmetic_safety"]
                },
                "priority": "critical",
                "requires_coordination": False
            }
        ]
        
        print(f"\n🧪 Testing Swarm Agent: {agent_id}")
        print("=" * 50)
        
        for i, task in enumerate(test_tasks, 1):
            print(f"\n📋 Task {i}: {task['task'][:50]}...")
            print(f"Priority: {task['priority']}")
            print(f"Coordination Required: {task['requires_coordination']}")
            
            response = self.session.post(
                f"{self.base_url}/agents/{agent_id}/webhook",
                json=task
            )
            
            if response.status_code == 200:
                print("✅ Task processed successfully")
                # Get agent logs
                logs_response = self.session.get(f"{self.base_url}/agents/{agent_id}/logs")
                if logs_response.status_code == 200:
                    logs = logs_response.json()['logs']
                    if logs:
                        print(f"📋 Processing log: {logs[-1][:100]}...")
                        
            else:
                print(f"❌ Task failed: {response.status_code}")
                print(f"   Error: {response.text}")
            
            time.sleep(3)  # Longer pause for complex tasks

    def list_all_agents(self):
        """List all agents in the system"""
        print("\n📋 Listing all agents...")
        response = self.session.get(f"{self.base_url}/agents")
        
        if response.status_code == 200:
            agents = response.json()
            print(f"✅ Found {len(agents)} agents:")
            for agent in agents:
                print(f"   • {agent['id']} ({agent['name']}) - State: {agent['state']}")
        else:
            print(f"❌ Failed to list agents: {response.status_code}")

    def get_available_strategies_and_tools(self):
        """Get available strategies and tools"""
        print("\n🔧 Available Strategies:")
        strategies_response = self.session.get(f"{self.base_url}/strategies")
        if strategies_response.status_code == 200:
            strategies = strategies_response.json()
            for strategy in strategies:
                print(f"   • {strategy['name']}")
        
        print("\n🛠️ Available Tools:")
        tools_response = self.session.get(f"{self.base_url}/tools")
        if tools_response.status_code == 200:
            tools = tools_response.json()
            for tool in tools:
                print(f"   • {tool['name']}: {tool['metadata']['description'][:80]}...")

    def cleanup_agents(self, agent_ids: list):
        """Clean up test agents"""
        print("\n🧹 Cleaning up test agents...")
        for agent_id in agent_ids:
            response = self.session.delete(f"{self.base_url}/agents/{agent_id}")
            if response.status_code == 204:
                print(f"✅ Deleted agent: {agent_id}")
            else:
                print(f"❌ Failed to delete agent {agent_id}: {response.status_code}")

def main():
    """Main test execution"""
    print("🎯 Solana Agent API Testing Suite")
    print("=" * 60)
    
    tester = SolanaAgentTester()
    created_agents = []
    
    try:
        # Check server connectivity
        print("🔗 Checking server connectivity...")
        ping_response = tester.session.get(f"{BASE_URL}/ping")
        if ping_response.status_code == 200:
            print("✅ Server is running")
        else:
            print("❌ Server not responding")
            return
        
        # Show available strategies and tools
        tester.get_available_strategies_and_tools()
        
        # Create and test chat agent
        chat_agent_id = tester.create_solana_chat_agent()
        if chat_agent_id:
            created_agents.append(chat_agent_id)
            
            # Update to RUNNING state
            if tester.update_agent_state(chat_agent_id, "RUNNING"):
                tester.test_chat_agent_queries(chat_agent_id)
        
        # Create and test swarm agent
        swarm_agent_id = tester.create_solana_swarm_agent()
        if swarm_agent_id:
            created_agents.append(swarm_agent_id)
            
            # Update to RUNNING state
            if tester.update_agent_state(swarm_agent_id, "RUNNING"):
                tester.test_swarm_agent_tasks(swarm_agent_id)
        
        # List all agents 
        tester.list_all_agents()
        
        print("\n🎉 Testing completed successfully!")
        
    except KeyboardInterrupt:
        print("\n\n⏹️ Testing interrupted by user")
    except Exception as e:
        print(f"\n❌ Unexpected error: {e}")
    finally:
        # Optional cleanup (comment out if you want to keep agents for further testing)
        # tester.cleanup_agents(created_agents)
        pass

if __name__ == "__main__":
    main()
