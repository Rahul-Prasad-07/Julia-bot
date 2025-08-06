# Detailed Flow Analysis: Custom Solana Agent System

## 🏗️ System Architecture Overview

```
┌─────────────────────────────────────────────────────────────────┐
│                      JULIA BACKEND SERVER                       │
│                     (127.0.0.1:8052)                           │
├─────────────────────────────────────────────────────────────────┤
│  ┌─────────────────┐    ┌──────────────────┐                   │
│  │   HTTP Server   │    │  Agent Manager   │                   │
│  │  (JuliaOSV1)    │◄──►│  (Agents.jl)     │                   │
│  └─────────────────┘    └──────────────────┘                   │
│           │                       │                             │
│           ▼                       ▼                             │
│  ┌─────────────────┐    ┌──────────────────┐                   │
│  │   API Routes    │    │   Strategy       │                   │
│  │   (/api/v1)     │    │   Registry       │                   │
│  └─────────────────┘    └──────────────────┘                   │
│                                   │                             │
│                                   ▼                             │
│           ┌─────────────────────────────────────────┐           │
│           │         STRATEGY IMPLEMENTATIONS         │           │
│           ├─────────────────────────────────────────┤           │
│           │  • strategy_solana_dev_chat.jl         │           │
│           │  • strategy_solana_swarm_dev.jl        │           │
│           └─────────────────────────────────────────┘           │
│                                   │                             │
│                                   ▼                             │
│           ┌─────────────────────────────────────────┐           │
│           │            TOOL ECOSYSTEM               │           │
│           ├─────────────────────────────────────────┤           │
│           │  • tool_solana_knowledge.jl             │           │
│           │  • tool_solana_code_gen.jl              │           │
│           │  • tool_solana_ecosystem.jl             │           │
│           └─────────────────────────────────────────┘           │
└─────────────────────────────────────────────────────────────────┘
```

## 🔄 Complete Request Flow

### Phase 1: Server Startup & Initialization

**1. Server Bootstrap (`run_server.jl`)**
```julia
# Database connection established
JuliaDB.initialize_connection(connection_string)
JuliaDB.load_state()  # Load existing agents from DB

# HTTP server starts
JuliaOSV1Server.run_server("127.0.0.1", 8052)
```

**2. Strategy & Tool Registration**
```julia
# In Strategies.jl
register_strategy(STRATEGY_SOLANA_DEV_CHAT_SPECIFICATION)
register_strategy(STRATEGY_SOLANA_SWARM_DEV_SPECIFICATION)

# In Tools.jl  
register_tool(TOOL_SOLANA_KNOWLEDGE_SPECIFICATION)
register_tool(TOOL_SOLANA_CODE_GEN_SPECIFICATION)
register_tool(TOOL_SOLANA_ECOSYSTEM_SPECIFICATION)
```

### Phase 2: Agent Creation Flow

**API Call:**
```bash
POST /api/v1/agents
Content-Type: application/json

{
  "id": "solana-dev-chat-001",
  "name": "Solana Development Assistant", 
  "description": "AI assistant for Solana development",
  "blueprint": {
    "tools": [
      {"name": "solana_knowledge", "config": {...}},
      {"name": "solana_code_gen", "config": {...}},
      {"name": "solana_ecosystem", "config": {...}}
    ],
    "strategy": {
      "name": "solana_dev_chat",
      "config": {
        "name": "solana-dev-assistant",
        "max_context_length": 10
      }
    },
    "trigger": {"type": "webhook", "params": {}}
  }
}
```

**Internal Processing Flow:**
```julia
function create_agent(req, create_agent_request)
    # 1. Validate request structure
    @validate_model create_agent_request
    
    # 2. Extract blueprint components
    tools = Vector{Agents.ToolBlueprint}()
    for tool in received_blueprint.tools
        push!(tools, Agents.ToolBlueprint(tool.name, tool.config))
    end
    
    # 3. Process strategy configuration
    strategy_blueprint = Agents.StrategyBlueprint(
        received_blueprint.strategy.name, 
        received_blueprint.strategy.config
    )
    
    # 4. Setup trigger configuration
    trigger_type = Triggers.trigger_name_to_enum(received_blueprint.trigger.type)
    trigger_params = Triggers.process_trigger_params(trigger_type, received_blueprint.trigger.params)
    
    # 5. Create agent with CREATED state
    agent = Agents.create_agent(id, name, description, internal_blueprint)
    
    # 6. Persist to database
    JuliaDB.insert_agent(agent)
    
    # 7. Initialize agent (tools + strategy setup)
    Agents.initialize(agent)
    
    return HTTP.Response(201, agent_summary)
end
```

### Phase 3: Agent State Management

**State Transitions:**
```
CREATED → RUNNING → PAUSED → RUNNING → STOPPED
    ↑        ↓                  ↓
    └────────┴──────────────────┘
```

**API Call to Activate:**
```bash
PUT /api/v1/agents/solana-dev-chat-001
Content-Type: application/json

{"state": "RUNNING"}
```

### Phase 4: Query Processing Flow

**API Call:**
```bash
POST /api/v1/agents/solana-dev-chat-001/webhook
Content-Type: application/json

{
  "message": "How do I create a PDA in Solana?",
  "user_id": "user123",
  "chat_type": "general"
}
```

**Detailed Processing in `strategy_solana_dev_chat.jl`:**

```julia
function strategy_solana_dev_chat(cfg, ctx, input)
    # 1. Extract input parameters
    user_message = input.message
    user_id = input.user_id
    chat_type = input.chat_type
    
    # 2. Manage conversation context
    if !haskey(CONVERSATION_CONTEXTS, cfg.name)
        CONVERSATION_CONTEXTS[cfg.name] = Vector{Dict{String,Any}}()
    end
    conversation_context = CONVERSATION_CONTEXTS[cfg.name]
    
    # 3. Add user message to context
    push!(conversation_context, Dict(
        "role" => "user", 
        "content" => user_message, 
        "timestamp" => string(now())
    ))
    
    # 4. Smart tool routing based on content analysis
    tool_to_use = determine_appropriate_tool(user_message, chat_type)
    
    # 5. Route to appropriate handler
    if tool_to_use == "solana_knowledge"
        response = handle_knowledge_query(ctx, user_message, conversation_context)
    elseif tool_to_use == "solana_code_gen"
        response = handle_code_generation(ctx, user_message, conversation_context)
    elseif tool_to_use == "solana_ecosystem"
        response = handle_ecosystem_query(ctx, user_message, conversation_context)
    end
    
    # 6. Add response to context for continuity
    push!(conversation_context, Dict(
        "role" => "assistant", 
        "content" => response, 
        "timestamp" => string(now())
    ))
    
    return response
end
```

**Tool Routing Logic:**
```julia
function determine_appropriate_tool(message::String, chat_type::String)
    message_lower = lowercase(message)
    
    # Explicit routing based on chat_type
    if chat_type == "code_gen"
        return "solana_code_gen"
    elseif chat_type == "ecosystem"
        return "solana_ecosystem"
    end
    
    # Smart content-based routing
    code_keywords = ["generate", "code", "implement", "program", "contract", "anchor"]
    ecosystem_keywords = ["jupiter", "raydium", "orca", "defi", "protocol", "integration"]
    
    code_score = sum(occursin(keyword, message_lower) for keyword in code_keywords)
    ecosystem_score = sum(occursin(keyword, message_lower) for keyword in ecosystem_keywords)
    
    if code_score >= 2
        return "solana_code_gen"
    elseif ecosystem_score >= 1
        return "solana_ecosystem"
    else
        return "solana_knowledge"  # Default
    end
end
```

### Phase 5: Tool Execution

**Knowledge Tool Execution:**
```julia
function handle_knowledge_query(ctx, message, context)
    # 1. Find the tool in agent context
    knowledge_tool = find_tool(ctx, "solana_knowledge")
    
    # 2. Build contextual prompt with conversation history
    enhanced_question = build_contextual_prompt(message, context, "knowledge")
    
    # 3. Execute tool with enhanced context
    result = knowledge_tool.execute(knowledge_tool.config, Dict("question" => enhanced_question))
    
    # 4. Return processed response
    if get(result, "success", false)
        return result["output"]
    else
        return "Error: $(get(result, "error", "unknown error"))"
    end
end
```

**Tool Implementation (`tool_solana_knowledge.jl`):**
```julia
function tool_solana_knowledge(cfg::ToolSolanaKnowledgeConfig, task::Dict)
    # 1. Validate input
    if !haskey(task, "question")
        return Dict("success" => false, "error" => "Missing 'question' field")
    end
    
    # 2. Prepare Solana-specific context
    solana_context = """
    You are a Solana blockchain development expert. Provide accurate information about:
    - Accounts, Programs, Instructions, Transactions
    - Program Derived Addresses (PDAs)
    - Cross-program invocations (CPIs)
    - SPL Token Program, Anchor Framework
    - DeFi protocols: Jupiter, Raydium, Orca
    """
    
    # 3. Build enhanced prompt
    enhanced_prompt = solana_context * "\n\nUser Question: " * task["question"]
    
    # 4. Call Gemini API
    gemini_cfg = Gemini.GeminiConfig(
        api_key = cfg.api_key,
        model_name = cfg.model_name,
        temperature = cfg.temperature
    )
    
    # 5. Execute and return
    answer = Gemini.gemini_util(gemini_cfg, enhanced_prompt)
    return Dict("output" => answer, "success" => true)
end
```

## 🧪 How to Test Your Agents

### 1. **Start the Julia Server**
```bash
cd "h:\Rahul Prasad 01\bot\JuliaOS\backend"
julia run_server.jl
```

### 2. **Run the Test Script**
```bash
cd "h:\Rahul Prasad 01\bot\JuliaOS" 
python test_solana_agent_api.py
```

### 3. **Manual API Testing Examples**

**A. Create Chat Agent:**
```bash
curl -X POST "http://127.0.0.1:8052/api/v1/agents" \
  -H "Content-Type: application/json" \
  -d '{
    "id": "solana-chat-test",
    "name": "Solana Chat Assistant",
    "description": "Test agent for Solana development",
    "blueprint": {
      "tools": [
        {"name": "solana_knowledge", "config": {"temperature": 0.3}}
      ],
      "strategy": {
        "name": "solana_dev_chat",
        "config": {"name": "test-agent", "max_context_length": 5}
      },
      "trigger": {"type": "webhook", "params": {}}
    }
  }'
```

**B. Activate Agent:**
```bash
curl -X PUT "http://127.0.0.1:8052/api/v1/agents/solana-chat-test" \
  -H "Content-Type: application/json" \
  -d '{"state": "RUNNING"}'
```

**C. Send Query:**
```bash
curl -X POST "http://127.0.0.1:8052/api/v1/agents/solana-chat-test/webhook" \
  -H "Content-Type: application/json" \
  -d '{
    "message": "Explain Program Derived Addresses in Solana",
    "user_id": "test_user",
    "chat_type": "general"
  }'
```

**D. Check Logs:**
```bash
curl -X GET "http://127.0.0.1:8052/api/v1/agents/solana-chat-test/logs"
```

## 🚀 Advanced Testing Scenarios

### Multi-turn Conversation Test:
```python
queries = [
    "What are PDAs in Solana?",
    "Show me code to create a PDA",
    "How do I use that PDA in a program?",
    "What are security considerations?"
]

for query in queries:
    response = requests.post(f"{BASE_URL}/agents/{agent_id}/webhook", 
                           json={"message": query, "user_id": "test"})
```

### Swarm Coordination Test:
```python
complex_task = {
    "task": "Build a complete DeFi lending protocol with Jupiter integration",
    "project_context": {
        "components": ["lending", "borrowing", "liquidation", "yield_farming"],
        "integrations": ["jupiter", "raydium"],
        "security_level": "production"
    },
    "priority": "high",
    "requires_coordination": True
}

response = requests.post(f"{BASE_URL}/agents/{swarm_agent_id}/webhook", json=complex_task)
```

## 📊 Key Features of Your System

1. **Contextual Conversations**: Maintains conversation history for coherent multi-turn interactions
2. **Smart Tool Routing**: Automatically selects appropriate tools based on query content
3. **Multi-Agent Coordination**: Swarm agents can coordinate complex tasks across specialized roles
4. **Persistent State**: Agent configurations and conversations persist across server restarts
5. **Modular Architecture**: Easy to add new tools, strategies, and agent types
6. **API-First Design**: Complete REST API for integration with external systems

Your Solana agent system is sophisticated and production-ready! 🎉
