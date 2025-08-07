// Types for AI Swarm Trading System API
export interface AISwarmStatus {
  system_running: boolean
  active_strategies: number
  last_update: number
  uptime_seconds: number
  trading_control: {
    is_running: boolean
    iteration_count: number
    should_stop: boolean
    start_time: number
  }
  agents_status: AgentsStatus
  performance_summary: PerformanceSummary
  api_connectivity: APIConnectivity
  timestamp: string
}

export interface AgentsStatus {
  market_analyzer: AgentInfo
  risk_manager: AgentInfo
  strategy_optimizer: AgentInfo
  execution_agent: AgentInfo
  swarm_consensus: SwarmInfo
}

export interface AgentInfo {
  status: 'active' | 'inactive' | 'error'
  confidence_score: number
  voting_weight: number
  last_decision?: string
  neural_network_status?: 'active' | 'training' | 'idle'
}

export interface SwarmInfo {
  consensus_rate: number
  active_agents: number
  last_consensus_strength: number
  voting_history: VotingDecision[]
}

export interface VotingDecision {
  timestamp: string
  action: 'buy' | 'sell' | 'hold'
  consensus_strength: number
  agent_votes: Record<string, { vote: string; confidence: number }>
}

export interface PerformanceSummary {
  current_balance: number
  total_trades: number
  ai_accuracy: number
  consensus_rate: number
  max_drawdown: number
  total_return_pct: number
}

export interface APIConnectivity {
  binance: boolean
  groq: boolean
  neural_networks: boolean
}

export interface AISwarmConfig {
  symbols: string[]
  base_spread_pct: number
  order_levels: number
  max_capital: number
  leverage: number
  consensus_threshold: number
  agent_count: number
  enable_neural_networks: boolean
  enable_groq_sentiment: boolean
  enable_swarm_consensus: boolean
}

export interface MarketData {
  symbol: string
  price: number
  bid: number
  ask: number
  volume: number
  spread: number
  volatility: number
  timestamp: string
}

export interface AIAnalysis {
  agent_id: string
  market_price: number
  neural_prediction: number[]
  neural_confidence: number
  groq_sentiment: string
  combined_signal: string | {
    groq_contribution?: number
    nn_contribution?: number
    action?: string
    signal?: string
    confidence?: number
  }
  timestamp: string
}

export interface RealtimeData {
  success: boolean
  system_active: boolean
  symbol: string
  market_data: MarketData
  ai_analysis: AIAnalysis
  timestamp: string
}

export interface PerformanceReport {
  success: boolean
  realtime_metrics: {
    current_time: string
    system_uptime: number
    trading_iterations: number
    agents_active: number
    pnl_tracker: any
  }
  performance_report: {
    parsed_at: string
    raw_report: string
  }
  raw_report: string
  timestamp: string
}

export interface StartTradingRequest {
  symbols?: string[]
  max_capital?: number
  base_spread_pct?: number
  order_levels?: number
  consensus_threshold?: number
  enable_neural_networks?: boolean
  enable_groq_sentiment?: boolean
  enable_swarm_consensus?: boolean
}

export interface StartTradingResponse {
  success: boolean
  message: string
  config: AISwarmConfig
  system_status: {
    trading_active: boolean
    iteration_count: number
  }
  timestamp: string
}

export interface APIError {
  error: string
  timestamp?: string
}
