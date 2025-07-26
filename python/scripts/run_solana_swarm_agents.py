import juliaos

HOST = "http://127.0.0.1:8052/api/v1"

# Solana Swarm Development Agent Configurations
def create_coordinator_agent():
    return juliaos.AgentBlueprint(
        tools=[
            juliaos.ToolBlueprint(
                name="solana_knowledge",
                config={"temperature": 0.3, "max_output_tokens": 2048}
            ),
            juliaos.ToolBlueprint(
                name="solana_code_gen",
                config={"temperature": 0.4, "max_output_tokens": 4096}
            ),
            juliaos.ToolBlueprint(
                name="solana_ecosystem",
                config={"temperature": 0.2, "max_output_tokens": 3072}
            )
        ],
        strategy=juliaos.StrategyBlueprint(
            name="solana_swarm_dev",
            config={
                "name": "coordinator-agent",
                "agent_role": "coordinator",
                "swarm_id": "solana-dev-swarm",
                "coordination_endpoint": HOST,
                "max_iterations": 5
            }
        ),
        trigger=juliaos.TriggerConfig(type="webhook", params={})
    )

def create_code_specialist_agent():
    return juliaos.AgentBlueprint(
        tools=[
            juliaos.ToolBlueprint(
                name="solana_code_gen",
                config={"temperature": 0.3, "max_output_tokens": 4096}
            ),
            juliaos.ToolBlueprint(
                name="solana_knowledge",
                config={"temperature": 0.2, "max_output_tokens": 2048}
            )
        ],
        strategy=juliaos.StrategyBlueprint(
            name="solana_swarm_dev",
            config={
                "name": "code-specialist-agent",
                "agent_role": "code_specialist",
                "swarm_id": "solana-dev-swarm",
                "coordination_endpoint": HOST
            }
        ),
        trigger=juliaos.TriggerConfig(type="webhook", params={})
    )

def create_ecosystem_expert_agent():
    return juliaos.AgentBlueprint(
        tools=[
            juliaos.ToolBlueprint(
                name="solana_ecosystem",
                config={"temperature": 0.2, "max_output_tokens": 3072}
            ),
            juliaos.ToolBlueprint(
                name="solana_knowledge",
                config={"temperature": 0.3, "max_output_tokens": 2048}
            )
        ],
        strategy=juliaos.StrategyBlueprint(
            name="solana_swarm_dev",
            config={
                "name": "ecosystem-expert-agent",
                "agent_role": "ecosystem_expert",
                "swarm_id": "solana-dev-swarm",
                "coordination_endpoint": HOST
            }
        ),
        trigger=juliaos.TriggerConfig(type="webhook", params={})
    )

def create_security_auditor_agent():
    return juliaos.AgentBlueprint(
        tools=[
            juliaos.ToolBlueprint(
                name="solana_knowledge",
                config={"temperature": 0.1, "max_output_tokens": 3072}
            )
        ],
        strategy=juliaos.StrategyBlueprint(
            name="solana_swarm_dev",
            config={
                "name": "security-auditor-agent",
                "agent_role": "security_auditor",
                "swarm_id": "solana-dev-swarm",
                "coordination_endpoint": HOST
            }
        ),
        trigger=juliaos.TriggerConfig(type="webhook", params={})
    )

def create_agents(conn):
    """Create all swarm agents"""
    agents = {}
    
    # Agent configurations
    agent_configs = [
        ("coordinator", create_coordinator_agent(), "Solana Development Coordinator", "Coordinates multi-agent Solana development tasks"),
        ("code_specialist", create_code_specialist_agent(), "Solana Code Specialist", "Specializes in Solana smart contract development and code generation"),
        ("ecosystem_expert", create_ecosystem_expert_agent(), "Solana Ecosystem Expert", "Expert in Solana DeFi protocols and ecosystem integrations"),
        ("security_auditor", create_security_auditor_agent(), "Solana Security Auditor", "Performs security audits and vulnerability analysis for Solana programs")
    ]
    
    for agent_id, blueprint, name, description in agent_configs:
        try:
            # Try to delete existing agent
            existing_agent = juliaos.Agent.load(conn, f"solana-{agent_id}")
            print(f"Deleting existing agent: solana-{agent_id}")
            existing_agent.delete()
        except:
            pass
        
        print(f"Creating agent: solana-{agent_id}")
        agent = juliaos.Agent.create(conn, blueprint, f"solana-{agent_id}", name, description)
        agent.set_state(juliaos.AgentState.RUNNING)
        agents[agent_id] = agent
        
    return agents

def test_swarm_scenarios():
    """Define test scenarios for the swarm"""
    return [
        {
            "task": "Create a comprehensive DeFi yield farming protocol with Jupiter integration",
            "project_context": {
                "protocols": ["jupiter", "raydium"],
                "features": ["yield_farming", "auto_compounding", "governance"],
                "security_level": "high",
                "target_network": "mainnet"
            },
            "priority": "high",
            "requires_coordination": True
        },
        {
            "task": "Implement a secure NFT marketplace with royalty enforcement",
            "project_context": {
                "features": ["nft_trading", "royalties", "escrow"],
                "metaplex_integration": True,
                "security_level": "critical"
            },
            "priority": "high",
            "requires_coordination": True
        },
        {
            "task": "Generate a simple SPL token with basic transfer functionality",
            "project_context": {
                "token_type": "spl_token",
                "features": ["mint", "transfer", "burn"],
                "complexity": "basic"
            },
            "priority": "normal",
            "requires_coordination": False
        },
        {
            "task": "Security audit for a lending protocol with flash loan protection",
            "project_context": {
                "protocol_type": "lending",
                "attack_vectors": ["flash_loans", "reentrancy", "oracle_manipulation"],
                "audit_scope": "comprehensive"
            },
            "priority": "critical",
            "requires_coordination": False
        }
    ]

with juliaos.JuliaOSConnection(HOST) as conn:
    print("🚀 Setting up Solana Development Swarm...")
    
    # Create all agents
    agents = create_agents(conn)
    coordinator = agents["coordinator"]
    
    print(f"\n📋 Current agents:")
    for agent_summary in conn.list_agents():
        if agent_summary.id.startswith("solana-"):
            print(f"   • {agent_summary.id}: {agent_summary.name} ({agent_summary.state})")
    
    # Test swarm scenarios
    test_scenarios = test_swarm_scenarios()
    
    print(f"\n{'='*60}")
    print("TESTING SOLANA DEVELOPMENT SWARM")
    print(f"{'='*60}")
    
    for i, scenario in enumerate(test_scenarios, 1):
        print(f"\n🔹 Scenario {i}: {scenario['task'][:60]}...")
        print(f"   Priority: {scenario['priority']}")
        print(f"   Coordination: {'Yes' if scenario['requires_coordination'] else 'No'}")
        
        try:
            # Send task to coordinator
            response = coordinator.call_webhook(scenario)
            print(f"✅ Swarm processing completed")
            
            # Show logs from coordinator
            logs = coordinator.get_logs()["logs"]
            print("📊 Coordinator logs:")
            for log in logs[-5:]:  # Show last 5 logs
                print(f"   {log}")
                
        except Exception as e:
            print(f"❌ Error with scenario {i}: {e}")
        
        print("-" * 60)
    
    print(f"\n{'='*60}")
    print("INTERACTIVE SWARM MODE")
    print("Send complex tasks to the coordinated swarm!")
    print("Type 'exit' to quit, 'help' for commands")
    print(f"{'='*60}")
    
    while True:
        try:
            user_input = input("\n💼 Your development task: ").strip()
            
            if user_input.lower() in ['exit', 'quit']:
                break
            elif user_input.lower() == 'help':
                print("""
Available commands:
- Describe any complex Solana development task
- The coordinator will break it down and coordinate with specialists
- Prefix with 'urgent:' for high priority tasks
- Prefix with 'simple:' for single-agent tasks (no coordination)
- 'status' - Show agent status
- 'logs [agent]' - Show logs for specific agent (coordinator, code_specialist, ecosystem_expert, security_auditor)
- 'exit' - Quit
                """)
                continue
            elif user_input.lower() == 'status':
                print("📊 Agent Status:")
                for agent_summary in conn.list_agents():
                    if agent_summary.id.startswith("solana-"):
                        print(f"   • {agent_summary.id}: {agent_summary.state}")
                continue
            elif user_input.lower().startswith('logs'):
                parts = user_input.split()
                if len(parts) > 1:
                    agent_name = parts[1]
                    if agent_name in agents:
                        logs = agents[agent_name].get_logs()["logs"]
                        print(f"📋 {agent_name} logs:")
                        for log in logs[-10:]:
                            print(f"   {log}")
                    else:
                        print(f"❌ Agent '{agent_name}' not found")
                else:
                    print("Usage: logs [agent_name]")
                continue
            elif not user_input:
                continue
            
            # Parse task parameters
            priority = "normal"
            requires_coordination = True
            
            if user_input.startswith("urgent:"):
                priority = "high"
                user_input = user_input[7:].strip()
            elif user_input.startswith("simple:"):
                requires_coordination = False
                user_input = user_input[7:].strip()
            
            print(f"🤖 Coordinating swarm for task...")
            print(f"   Priority: {priority}")
            print(f"   Coordination: {'Yes' if requires_coordination else 'No'}")
            
            task_data = {
                "task": user_input,
                "project_context": {
                    "source": "interactive",
                    "timestamp": "now"
                },
                "priority": priority,
                "requires_coordination": requires_coordination
            }
            
            response = coordinator.call_webhook(task_data)
            print("✅ Swarm task completed!")
            
        except KeyboardInterrupt:
            print("\n👋 Goodbye!")
            break
        except Exception as e:
            print(f"❌ Error: {e}")
    
    print(f"\n🧹 Cleaning up agents...")
    for agent_id, agent in agents.items():
        try:
            agent.delete()
            print(f"✅ Deleted {agent_id}")
        except Exception as e:
            print(f"❌ Error deleting {agent_id}: {e}")
    
    print("✅ Solana Development Swarm demo completed!")
