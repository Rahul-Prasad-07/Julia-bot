# 💻 **Code-Level Implementation Details**

## 🔗 **Frontend-Backend Code Connections**

### 📁 **File Structure & Connections**

```mermaid
graph TB
    subgraph "Frontend Files"
        PAGE["📄 apps/web/src/app/page.tsx<br/>Main Dashboard Component"]
        API_CLIENT["📡 apps/web/src/lib/api.ts<br/>AISwarmAPI Class"]
        TYPES["📋 apps/web/src/types/api.ts<br/>TypeScript Interfaces"]
        COMPONENTS["🎨 apps/web/src/components/<br/>• TradingControls.tsx<br/>• RealtimeData.tsx<br/>• PerformanceMetrics.tsx<br/>• MarketChart.tsx"]
    end
    
    subgraph "Backend Files"
        SERVER["🌐 backend/run_server.jl<br/>HTTP Server Startup"]
        AI_API["🤖 backend/src/api/ai_swarm_api.jl<br/>API Endpoint Handlers"]
        STRATEGY["⚙️ backend/src/agents/strategies/<br/>• strategy_rl_market_making.jl<br/>• strategy_ai_swarm.jl"]
        AGENTS["👥 backend/src/agents/<br/>AI Agent Implementations"]
    end
    
    subgraph "Configuration"
        ENV["🔒 .env<br/>API Keys & Secrets"]
        CONFIG["⚙️ config/<br/>Trading Parameters"]
    end
    
    PAGE --> API_CLIENT
    API_CLIENT --> TYPES
    PAGE --> COMPONENTS
    COMPONENTS --> API_CLIENT
    
    API_CLIENT -.->|HTTP Requests| SERVER
    SERVER --> AI_API
    AI_API --> STRATEGY
    STRATEGY --> AGENTS
    
    SERVER --> ENV
    STRATEGY --> CONFIG
    
    style PAGE fill:#1f2937,stroke:#3b82f6,color:#ffffff
    style API_CLIENT fill:#1f2937,stroke:#10b981,color:#ffffff
    style AI_API fill:#1f2937,stroke:#8b5cf6,color:#ffffff
    style STRATEGY fill:#1f2937,stroke:#f59e0b,color:#ffffff
```

### 🔄 **API Call Implementation**

```mermaid
sequenceDiagram
    participant Component as 🎨 TradingControls.tsx
    participant API as 📡 AISwarmAPI.ts
    participant HTTP as 🌐 axios instance
    participant Server as 🖥️ Julia Server:8052
    participant Handler as 🔧 handle_ai_swarm_start()
    participant Strategy as ⚙️ Strategy Engine
    
    Note over Component,Strategy: Code-level execution flow
    
    Component->>API: handleStartTrading() calls
    Note over API: AISwarmAPI.startTrading(config)
    API->>HTTP: api.post('/api/v1/ai-swarm/start', config)
    Note over HTTP: axios.create({baseURL: 'http://127.0.0.1:8052'})
    HTTP->>Server: POST Request with JSON body
    
    Note over Server: Router matches endpoint
    Server->>Handler: handle_ai_swarm_start(req::HTTP.Request)
    Note over Handler: Parse JSON config from req.body
    Handler->>Strategy: start_ai_swarm_trading(config, context)
    Note over Strategy: Initialize RL agents & trading loop
    Strategy-->>Handler: Boolean success result
    Handler-->>Server: HTTP.Response(200, JSON3.write(response))
    Server-->>HTTP: JSON response
    HTTP-->>API: Promise<StartTradingResponse>
    API-->>Component: Success/Error result
    
    Note over Component: Update UI state & show toast
```

### 📊 **Real-time Data Flow Code**

```mermaid
graph LR
    subgraph "Frontend Polling (React Query)"
        QUERY["🔄 useQuery Hook<br/>```tsx<br/>const { data: realtimeData } = useQuery({<br/>  queryKey: ['ai-swarm-realtime'],<br/>  queryFn: () => AISwarmAPI.getRealtimeData('ETHUSDT'),<br/>  refetchInterval: 2000<br/>})<br/>```"]
    end
    
    subgraph "API Client Method"
        METHOD["📡 AISwarmAPI.getRealtimeData()<br/>```typescript<br/>static async getRealtimeData(symbol: string): Promise<RealtimeData> {<br/>  const response = await api.get(<br/>    `/api/v1/ai-swarm/data/realtime?symbol=${symbol}`<br/>  )<br/>  return response.data<br/>}<br/>```"]
    end
    
    subgraph "Backend Handler"
        HANDLER["🔧 handle_ai_swarm_realtime_data()<br/>```julia<br/>function handle_ai_swarm_realtime_data(req::HTTP.Request)<br/>  # Get market data from Binance<br/>  market_data = fetch_market_data(symbol, api_key, api_secret)<br/>  # Get AI analysis<br/>  ai_analysis = analyze_market_with_ai(agents, market_data)<br/>  # Return combined data<br/>  return HTTP.Response(200, JSON3.write(response_data))<br/>end<br/>```"]
    end
    
    subgraph "Strategy Integration"
        STRATEGY["⚙️ Trading Strategy<br/>```julia<br/>function fetch_market_data(symbol, api_key, api_secret)<br/>  # Binance API call<br/>  price_data = get_symbol_price(symbol, api_key, api_secret)<br/>  # Process and return structured data<br/>end<br/>```"]
    end
    
    QUERY --> METHOD
    METHOD --> HANDLER  
    HANDLER --> STRATEGY
    
    style QUERY fill:#61dafb,color:#000000
    style METHOD fill:#3178c6,color:#ffffff
    style HANDLER fill:#389826,color:#ffffff
    style STRATEGY fill:#9558b2,color:#ffffff
```

### 🤖 **AI Agent Code Structure**

```mermaid
classDiagram
    class AISwarmSystemState {
        +Bool is_running
        +Dict active_strategies
        +Dict performance_metrics
        +Float64 last_update
        +AISwarmSystemState()
    }
    
    class TradingControls {
        +handleStartTrading()
        +handleStopTrading()
        +handleEmergencyStop()
        +useState config
        +useState isLoading
    }
    
    class AISwarmAPI {
        +static getStatus()
        +static startTrading()
        +static stopTrading()
        +static getRealtimeData()
        +static getPerformance()
    }
    
    class MarketMaker {
        +q_network: Matrix
        +experience_buffer: Buffer
        +epsilon: Float64
        +select_action()
        +update_q_network()
    }
    
    class AgentContext {
        +tools: Vector
        +logs: Vector
        +push_log()
    }
    
    TradingControls --> AISwarmAPI: HTTP calls
    AISwarmAPI --> AISwarmSystemState: Updates state
    AISwarmSystemState --> MarketMaker: Controls agents
    MarketMaker --> AgentContext: Logs actions
    
    style TradingControls fill:#e1f5fe
    style AISwarmAPI fill:#f3e5f5
    style MarketMaker fill:#e8f5e8
```

### 📈 **Trading Loop Implementation**

```mermaid
graph TD
    subgraph "Backend Trading Loop"
        START_LOOP["🔄 start_continuous_rl_trading()<br/>```julia<br/>TRADING_CONTROL.is_running = true<br/>BACKGROUND_TASK[] = @async trading_loop_background(cfg, ctx)<br/>```"]
        
        LOOP_CYCLE["🔁 trading_loop_background()<br/>```julia<br/>while TRADING_CONTROL.is_running<br/>  # Cancel existing orders<br/>  cancel_all_orders_rl(symbol, api_key, api_secret)<br/>  # Execute RL trading<br/>  execute_rl_market_making(symbol, cfg, ctx, agent)<br/>  # Wait 30 seconds<br/>  sleep(30)<br/>end<br/>```"]
        
        RL_EXECUTION["🧠 execute_rl_market_making()<br/>```julia<br/># Get market state<br/>current_state = extract_market_state(symbol, cfg)<br/># RL decision<br/>action = select_action(agent, current_state)<br/># Place orders<br/>place_orders_with_precision(...)<br/>```"]
        
        BINANCE_API["📈 Binance API Calls<br/>```julia<br/>function place_order_with_precision(symbol, side, size, price)<br/>  # Create HMAC signature<br/>  signature = hmac_sha256(api_secret, query_string)<br/>  # HTTP POST to Binance<br/>  response = HTTP.post(url, headers, body)<br/>end<br/>```"]
    end
    
    subgraph "Frontend Updates"
        POLL_STATUS["🔄 Status Polling<br/>```tsx<br/>useQuery({<br/>  queryKey: ['ai-swarm-status'],<br/>  queryFn: AISwarmAPI.getStatus,<br/>  refetchInterval: 5000<br/>})<br/>```"]
        
        UPDATE_UI["🖥️ UI Updates<br/>```tsx<br/>const isTrading = status?.trading_control?.is_running<br/><StatusIndicator<br/>  status={isTrading ? 'active' : 'inactive'}<br/>  label={isTrading ? 'Trading Active' : 'Stopped'}<br/>/><br/>```"]
    end
    
    START_LOOP --> LOOP_CYCLE
    LOOP_CYCLE --> RL_EXECUTION
    RL_EXECUTION --> BINANCE_API
    BINANCE_API --> LOOP_CYCLE
    
    POLL_STATUS --> UPDATE_UI
    UPDATE_UI --> POLL_STATUS
    
    style START_LOOP fill:#e3f2fd
    style LOOP_CYCLE fill:#f1f8e9
    style RL_EXECUTION fill:#fce4ec
    style BINANCE_API fill:#fff3e0
    style POLL_STATUS fill:#e8eaf6
    style UPDATE_UI fill:#f3e5f5
```

### 🔐 **Environment & Configuration**

```mermaid
graph TB
    subgraph ".env File"
        ENV_VARS["🔒 Environment Variables<br/>```bash<br/>BINANCE_API_KEY=your_api_key<br/>BINANCE_API_SECRET=your_secret<br/>GROQ_API_KEY=your_groq_key<br/>NEXT_PUBLIC_JULIA_API_URL=http://127.0.0.1:8052<br/>```"]
    end
    
    subgraph "Frontend Config"
        NEXT_CONFIG["⚙️ next.config.js<br/>```javascript<br/>env: {<br/>  NEXT_PUBLIC_JULIA_API_URL: process.env.NEXT_PUBLIC_JULIA_API_URL<br/>}<br/>```"]
        
        API_CONFIG["📡 API Client Config<br/>```typescript<br/>const api = axios.create({<br/>  baseURL: process.env.NEXT_PUBLIC_JULIA_API_URL || 'http://127.0.0.1:8052',<br/>  timeout: 30000<br/>})<br/>```"]
    end
    
    subgraph "Backend Config"
        JULIA_ENV["📖 Julia Environment<br/>```julia<br/>using DotEnv<br/>DotEnv.load!()<br/>api_key = get(ENV, 'BINANCE_API_KEY', '')<br/>```"]
        
        SERVER_CONFIG["🌐 Server Configuration<br/>```julia<br/>host = get(ENV, 'HOST', '127.0.0.1')<br/>port = parse(Int, get(ENV, 'PORT', '8052'))<br/>JuliaOSV1Server.run_server(host, port)<br/>```"]
    end
    
    ENV_VARS --> NEXT_CONFIG
    ENV_VARS --> JULIA_ENV
    NEXT_CONFIG --> API_CONFIG
    JULIA_ENV --> SERVER_CONFIG
    
    style ENV_VARS fill:#ffebee
    style API_CONFIG fill:#e3f2fd
    style SERVER_CONFIG fill:#e8f5e8
```

### 📊 **Data Type Definitions**

```mermaid
classDiagram
    class AISwarmStatus {
        +Boolean system_running
        +Number active_strategies
        +Number last_update
        +TradingControl trading_control
        +AgentsStatus agents_status
        +PerformanceSummary performance_summary
    }
    
    class RealtimeData {
        +Boolean success
        +String symbol
        +MarketData market_data
        +AIAnalysis ai_analysis
        +String timestamp
    }
    
    class MarketData {
        +String symbol
        +Number price
        +Number bid
        +Number ask
        +Number volume
        +Number spread
        +Number volatility
    }
    
    class AIAnalysis {
        +String agent_id
        +Number market_price
        +Array neural_prediction
        +Number neural_confidence
        +String groq_sentiment
        +Object combined_signal
    }
    
    class TradingControlsProps {
        +AISwarmStatus status
        +Function onStatusChange
    }
    
    AISwarmStatus --> RealtimeData: API Response
    RealtimeData --> MarketData: Contains
    RealtimeData --> AIAnalysis: Contains
    TradingControlsProps --> AISwarmStatus: Uses
    
    style AISwarmStatus fill:#e1f5fe
    style RealtimeData fill:#f3e5f5
    style MarketData fill:#e8f5e8
    style AIAnalysis fill:#fff3e0
```

This code-level diagram shows:

1. **📁 Exact file connections** between frontend and backend
2. **🔄 Implementation details** of API calls and handlers  
3. **🤖 Code structure** of AI agents and trading loops
4. **📈 Real-time execution flow** with actual code snippets
5. **🔐 Configuration management** across environments
6. **📊 Data type definitions** and interfaces

The diagrams show exactly how your TypeScript frontend communicates with your Julia backend through HTTP APIs to execute real-time AI trading strategies!
