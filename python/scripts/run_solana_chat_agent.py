import juliaos

HOST = "http://127.0.0.1:8052/api/v1"

# Solana Development Chat Agent Configuration
SOLANA_CHAT_AGENT_BLUEPRINT = juliaos.AgentBlueprint(
    tools=[
        juliaos.ToolBlueprint(
            name="solana_knowledge",
            config={
                "temperature": 0.3,
                "max_output_tokens": 2048
            }
        ),
        juliaos.ToolBlueprint(
            name="solana_code_gen",
            config={
                "temperature": 0.4,
                "max_output_tokens": 4096
            }
        ),
        juliaos.ToolBlueprint(
            name="solana_ecosystem",
            config={
                "temperature": 0.2,
                "max_output_tokens": 3072
            }
        )
    ],
    strategy=juliaos.StrategyBlueprint(
        name="solana_dev_chat",
        config={
            "name": "solana-dev-assistant",
            "welcome_message": "Hello! I'm your Solana Development Assistant. I can help you with smart contracts, DeFi integrations, ecosystem tools, and code generation. What would you like to work on today?",
            "max_context_length": 10
        }
    ),
    trigger=juliaos.TriggerConfig(
        type="webhook",
        params={}
    )
)

AGENT_ID = "solana-dev-chat-agent"
AGENT_NAME = "Solana Development Chat Assistant"
AGENT_DESCRIPTION = "An AI assistant specialized in Solana blockchain development, DeFi protocols, smart contracts, and ecosystem integrations"

def test_solana_queries():
    """Test various Solana development queries"""
    test_queries = [
        {
            "message": "How do I create a basic SPL token program using Anchor?",
            "chat_type": "code_gen"
        },
        {
            "message": "What are the best practices for integrating with Jupiter aggregator?",
            "chat_type": "ecosystem"
        },
        {
            "message": "Explain Program Derived Addresses (PDAs) and their use cases",
            "chat_type": "general"
        },
        {
            "message": "Generate a simple staking program with rewards distribution",
            "chat_type": "code_gen"
        },
        {
            "message": "How can I integrate Raydium CLMM pools in my DeFi application?",
            "chat_type": "ecosystem"
        }
    ]
    
    return test_queries

with juliaos.JuliaOSConnection(HOST) as conn:
    print_agents = lambda: print("Agents:", conn.list_agents())
    
    def print_logs(agent, msg):
        print(f"\n{msg}")
        try:
            logs = agent.get_logs()["logs"]
            for log in logs[-10:]:  # Show last 10 logs
                print("   ", log)
        except Exception as e:
            print(f"   Error getting logs: {e}")

    try:
        existing_agent = juliaos.Agent.load(conn, AGENT_ID)
        print(f"Agent '{AGENT_ID}' already exists, deleting it.")
        existing_agent.delete()
    except Exception as e:
        print(f"No existing agent '{AGENT_ID}' found. Proceeding to create.")

    print_agents()
    print(f"\nCreating Solana Development Chat Agent...")
    agent = juliaos.Agent.create(conn, SOLANA_CHAT_AGENT_BLUEPRINT, AGENT_ID, AGENT_NAME, AGENT_DESCRIPTION)
    print_agents()
    
    print(f"\nStarting agent...")
    agent.set_state(juliaos.AgentState.RUNNING)
    print_logs(agent, "Agent logs after initialization:")

    # Test the agent with various Solana development queries
    test_queries = test_solana_queries()
    
    print(f"\n{'='*60}")
    print("TESTING SOLANA DEVELOPMENT CHAT AGENT")
    print(f"{'='*60}")
    
    for i, query in enumerate(test_queries, 1):
        print(f"\n🔹 Test Query {i}: {query['message'][:50]}...")
        print(f"   Type: {query['chat_type']}")
        
        try:
            # Call the agent with the query
            response = agent.call_webhook({
                "message": query["message"],
                "user_id": f"test_user_{i}",
                "chat_type": query["chat_type"]
            })
            
            print(f"✅ Response received")
            print_logs(agent, f"Agent logs after query {i}:")
            
        except Exception as e:
            print(f"❌ Error with query {i}: {e}")
        
        print("-" * 40)
    
    print(f"\n{'='*60}")
    print("INTERACTIVE MODE - Try your own queries!")
    print("Type 'exit' to quit, 'help' for commands")
    print(f"{'='*60}")
    
    while True:
        try:
            user_input = input("\n💬 Your Solana dev question: ").strip()
            
            if user_input.lower() in ['exit', 'quit']:
                break
            elif user_input.lower() == 'help':
                print("""
Available commands:
- Ask any Solana development question
- Prefix with 'code:' for code generation (e.g., 'code: create NFT minting program')
- Prefix with 'ecosystem:' for DeFi/protocol questions (e.g., 'ecosystem: Jupiter integration')
- 'logs' - Show recent agent logs
- 'exit' - Quit the interactive mode
                """)
                continue
            elif user_input.lower() == 'logs':
                print_logs(agent, "Recent agent logs:")
                continue
            elif not user_input:
                continue
            
            # Determine chat type based on prefix
            chat_type = "general"
            if user_input.startswith("code:"):
                chat_type = "code_gen"
                user_input = user_input[5:].strip()
            elif user_input.startswith("ecosystem:"):
                chat_type = "ecosystem"
                user_input = user_input[10:].strip()
            
            print(f"🤖 Processing ({chat_type})...")
            
            response = agent.call_webhook({
                "message": user_input,
                "user_id": "interactive_user",
                "chat_type": chat_type
            })
            
            print("✅ Response generated!")
            
        except KeyboardInterrupt:
            print("\n👋 Goodbye!")
            break
        except Exception as e:
            print(f"❌ Error: {e}")
    
    print(f"\nCleaning up...")
    agent.delete()
    print_agents()
    print("✅ Solana Development Chat Agent demo completed!")
