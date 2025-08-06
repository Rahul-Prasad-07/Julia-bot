# Solana Development Agents for JuliaOS

This directory contains specialized AI agents for Solana blockchain development, including both single-agent chat assistants and multi-agent swarm coordination systems.

## 🚀 Quick Start

### Prerequisites

1. **Environment Setup**: Ensure you have the required API keys:
   ```bash
   export GEMINI_API_KEY="your_gemini_api_key_here"
   ```

2. **JuliaOS Backend**: Make sure the JuliaOS backend is running:
   ```bash
   cd backend
   julia run_server.jl
   ```

### Running the Single Chat Agent

For general Solana development assistance:

```bash
cd python
python scripts/run_solana_chat_agent.py
```

### Running the Swarm Coordination System

For complex, multi-faceted development tasks:

```bash
cd python
python scripts/run_solana_swarm_agents.py
```

## 🤖 Agent Capabilities

### 1. Solana Knowledge Base (`solana_knowledge` tool)
- **Purpose**: Provides expert knowledge on Solana development
- **Specializations**:
  - Core concepts (accounts, programs, PDAs, CPIs)
  - Development tools (Anchor, Solana CLI, Web3.js)
  - Ecosystem overview (SPL, Serum, Jupiter, Raydium)
  - Best practices and security considerations
  - Current trends (compressed NFTs, state compression)

### 2. Code Generation (`solana_code_gen` tool)
- **Purpose**: Generates production-ready Solana code
- **Capabilities**:
  - Complete Anchor programs with proper structure
  - Client-side integration (Web3.js, wallet adapters)
  - Testing frameworks and deployment scripts
  - Common patterns (tokens, NFTs, DeFi protocols)
  - Security-focused implementations

### 3. Ecosystem Integration (`solana_ecosystem` tool)
- **Purpose**: Provides guidance on DeFi protocols and integrations
- **Coverage**:
  - Major DEXs (Jupiter, Raydium, Orca, Serum)
  - Lending protocols (Marginfi, Solend, Mango)
  - Yield strategies (Marinade, Lido, Jito)
  - Infrastructure (Pyth, Switchboard, Wormhole)
  - NFT platforms (Metaplex, Magic Eden)

## 🎯 Usage Patterns

### Single Agent Chat Mode

The chat agent (`run_solana_chat_agent.py`) provides intelligent routing based on your query:

- **General questions**: Automatically routed to knowledge base
- **Code requests**: Use `code:` prefix or include keywords like "generate", "implement"
- **Ecosystem queries**: Use `ecosystem:` prefix or mention protocols like "Jupiter", "Raydium"

Example interactions:
```
💬 Your Solana dev question: How do PDAs work in Solana?
💬 Your Solana dev question: code: Create an NFT minting program with Metaplex
💬 Your Solana dev question: ecosystem: How to integrate Jupiter for token swaps?
```

### Swarm Coordination Mode

The swarm system (`run_solana_swarm_agents.py`) coordinates multiple specialized agents:

- **Coordinator Agent**: Breaks down complex tasks and orchestrates specialists
- **Code Specialist**: Focuses on smart contract development and implementation
- **Ecosystem Expert**: Handles DeFi protocol integrations and ecosystem guidance
- **Security Auditor**: Performs security analysis and vulnerability assessments

Example complex tasks:
```
💼 Your development task: Create a comprehensive DeFi yield farming protocol with Jupiter integration
💼 Your development task: urgent: Security audit for lending protocol with flash loan protection
💼 Your development task: simple: Generate basic SPL token contract
```

## 🏗️ Architecture

### Tool Architecture
```
Tools/
├── tool_solana_knowledge.jl     # Expert knowledge base
├── tool_solana_code_gen.jl      # Code generation
└── tool_solana_ecosystem.jl     # Ecosystem integration
```

### Strategy Architecture
```
Strategies/
├── strategy_solana_dev_chat.jl    # Single-agent chat strategy
└── strategy_solana_swarm_dev.jl   # Multi-agent coordination strategy
```

### Agent Roles in Swarm
- **Coordinator**: Task decomposition and result synthesis
- **Code Specialist**: Smart contract development and implementation
- **Ecosystem Expert**: DeFi protocol integration and guidance
- **Security Auditor**: Security analysis and vulnerability assessment

## 🔧 Configuration

### Tool Configuration

Each tool can be configured with different parameters:

```julia
# Example tool configuration
juliaos.ToolBlueprint(
    name="solana_knowledge",
    config={
        "temperature": 0.3,        # Lower for more precise responses
        "max_output_tokens": 2048  # Adjust based on response length needs
    }
)
```

### Strategy Configuration

Strategies support various configuration options:

```julia
# Chat strategy configuration
strategy=juliaos.StrategyBlueprint(
    name="solana_dev_chat",
    config={
        "name": "solana-dev-assistant",
        "max_context_length": 10,  # Conversation history length
        "welcome_message": "Custom welcome message"
    }
)

# Swarm strategy configuration
strategy=juliaos.StrategyBlueprint(
    name="solana_swarm_dev",
    config={
        "agent_role": "coordinator",     # coordinator, code_specialist, ecosystem_expert, security_auditor
        "swarm_id": "solana-dev-swarm",
        "max_iterations": 5
    }
)
```

## 📚 Example Use Cases

### 1. Learning Solana Development
- Ask questions about core concepts
- Get explanations of complex topics
- Understand best practices and common patterns

### 2. Code Generation
- Generate complete Anchor programs
- Create client-side integration code
- Build testing and deployment scripts

### 3. DeFi Protocol Integration
- Learn about protocol APIs and SDKs
- Get integration examples and patterns
- Understand yield strategies and optimizations

### 4. Security Analysis
- Get security best practices
- Understand common vulnerabilities
- Receive audit checklists and testing strategies

### 5. Complex Project Development
- Use swarm coordination for multi-faceted projects
- Get specialized expertise for different aspects
- Coordinate development across multiple domains

## 🛠️ Development and Extension

### Adding New Tools

1. Create a new tool file in `backend/src/agents/tools/`:
```julia
# tool_my_solana_tool.jl
function tool_my_solana_tool(cfg::MyToolConfig, task::Dict)
    # Implementation
end

const TOOL_MY_SOLANA_TOOL_SPECIFICATION = ToolSpecification(
    tool_my_solana_tool,
    MyToolConfig,
    TOOL_MY_SOLANA_TOOL_METADATA
)
```

2. Register the tool in `Tools.jl`:
```julia
include("tool_my_solana_tool.jl")
register_tool(TOOL_MY_SOLANA_TOOL_SPECIFICATION)
```

### Creating Custom Strategies

1. Implement strategy functions:
```julia
function my_strategy(cfg::MyConfig, ctx::AgentContext, input::MyInput)
    # Strategy implementation
end

const MY_STRATEGY_SPECIFICATION = StrategySpecification(
    my_strategy,
    MyConfig,
    MyInput,
    MY_STRATEGY_METADATA,
    my_strategy_initialization  # Optional
)
```

2. Register in `Strategies.jl`:
```julia
register_strategy(MY_STRATEGY_SPECIFICATION)
```

## 🔍 Troubleshooting

### Common Issues

1. **API Key Not Set**: Ensure `GEMINI_API_KEY` is exported in your environment
2. **Backend Not Running**: Start the JuliaOS backend server before running agents
3. **Import Errors**: The Python scripts expect the `juliaos` package to be available
4. **Tool Not Found**: Check that all tools are properly registered in `Tools.jl`
5. **Strategy Not Found**: Verify strategy registration in `Strategies.jl`

### Debug Mode

Enable debug logs by checking agent logs:
```python
# In interactive mode
logs coordinator  # Show coordinator logs
logs code_specialist  # Show specialist logs
```

## 🤝 Contributing

To contribute new Solana development capabilities:

1. **Tools**: Add specialized tools for specific Solana use cases
2. **Strategies**: Create new coordination patterns or specialized workflows
3. **Knowledge**: Enhance the knowledge base with latest Solana developments
4. **Examples**: Add more complex use case examples and demonstrations

## 📖 Additional Resources

- [Solana Developer Documentation](https://docs.solana.com/)
- [Anchor Framework Guide](https://www.anchor-lang.com/)
- [Solana Cookbook](https://solanacookbook.com/)
- [JuliaOS Documentation](https://juliaos.gitbook.io/juliaos-documentation-hub/)

---

*Built with ❤️ for the Solana developer community using the JuliaOS framework*
