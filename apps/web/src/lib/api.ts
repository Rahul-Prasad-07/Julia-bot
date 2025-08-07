import axios from 'axios'
import type {
  AISwarmStatus,
  AISwarmConfig,
  RealtimeData,
  PerformanceReport,
  StartTradingRequest,
  StartTradingResponse,
  APIError
} from '@/types/api'

// Create axios instance with base configuration
const api = axios.create({
  baseURL: process.env.NEXT_PUBLIC_JULIA_API_URL || 'http://127.0.0.1:8052',
  timeout: 30000,
  headers: {
    'Content-Type': 'application/json',
    'Accept': 'application/json',
  },
})

// Request interceptor for logging
api.interceptors.request.use(
  (config) => {
    console.log(`🔗 API Request: ${config.method?.toUpperCase()} ${config.url}`)
    return config
  },
  (error) => {
    console.error('❌ API Request Error:', error)
    return Promise.reject(error)
  }
)

// Response interceptor for error handling
api.interceptors.response.use(
  (response) => {
    console.log(`✅ API Response: ${response.status} ${response.config.url}`)
    return response
  },
  (error) => {
    console.error('❌ API Response Error:', error.response?.data || error.message)
    return Promise.reject(error)
  }
)

export class AISwarmAPI {
  /**
   * Get AI Swarm system status and metrics
   */
  static async getStatus(): Promise<AISwarmStatus> {
    try {
      const response = await api.get('/api/v1/ai-swarm/status')
      return response.data
    } catch (error) {
      console.error('Failed to get AI Swarm status:', error)
      throw new Error('Failed to fetch system status')
    }
  }

  /**
   * Start AI Swarm trading with configuration
   */
  static async startTrading(config: StartTradingRequest = {}): Promise<StartTradingResponse> {
    try {
      const response = await api.post('/api/v1/ai-swarm/start', config)
      return response.data
    } catch (error: any) {
      console.error('Failed to start AI Swarm trading:', error)
      const errorMessage = error.response?.data?.error || 'Failed to start trading'
      throw new Error(errorMessage)
    }
  }

  /**
   * Stop AI Swarm trading gracefully
   */
  static async stopTrading(): Promise<{ success: boolean; message: string }> {
    try {
      const response = await api.post('/api/v1/ai-swarm/stop')
      return response.data
    } catch (error) {
      console.error('Failed to stop AI Swarm trading:', error)
      throw new Error('Failed to stop trading')
    }
  }

  /**
   * Emergency stop - halt all trading and cancel orders
   */
  static async emergencyStop(): Promise<{ success: boolean; message: string; cancelled_orders: number }> {
    try {
      const response = await api.post('/api/v1/ai-swarm/emergency-stop')
      return response.data
    } catch (error) {
      console.error('Failed to emergency stop AI Swarm:', error)
      throw new Error('Failed to emergency stop')
    }
  }

  /**
   * Get performance report and analytics
   */
  static async getPerformance(): Promise<PerformanceReport> {
    try {
      const response = await api.get('/api/v1/ai-swarm/performance')
      return response.data
    } catch (error) {
      console.error('Failed to get performance report:', error)
      throw new Error('Failed to fetch performance data')
    }
  }

  /**
   * Get AI agents status and monitoring data
   */
  static async getAgents(): Promise<{
    success: boolean
    agents_by_symbol: Record<string, any>
    total_symbols: number
    agents_available: boolean
    timestamp: string
  }> {
    try {
      const response = await api.get('/api/v1/ai-swarm/agents')
      return response.data
    } catch (error) {
      console.error('Failed to get agents status:', error)
      throw new Error('Failed to fetch agents data')
    }
  }

  /**
   * Get real-time market data and AI analysis
   */
  static async getRealtimeData(symbol: string = 'ETHUSDT'): Promise<RealtimeData> {
    try {
      const response = await api.get(`/api/v1/ai-swarm/data/realtime?symbol=${symbol}`)
      return response.data
    } catch (error) {
      console.error('Failed to get real-time data:', error)
      throw new Error('Failed to fetch real-time data')
    }
  }

  /**
   * Update AI Swarm configuration
   */
  static async updateConfig(updates: Partial<AISwarmConfig>): Promise<{
    success: boolean
    message: string
    updated_fields: string[]
    current_config: AISwarmConfig
    requires_restart: boolean
    timestamp: string
  }> {
    try {
      const response = await api.put('/api/v1/ai-swarm/config', updates)
      return response.data
    } catch (error) {
      console.error('Failed to update configuration:', error)
      throw new Error('Failed to update configuration')
    }
  }

  /**
   * Test API connectivity
   */
  static async testConnection(): Promise<boolean> {
    try {
      const response = await api.get('/api/v1/ai-swarm/status')
      return response.status === 200
    } catch (error) {
      console.error('API connection test failed:', error)
      return false
    }
  }

  /**
   * Get historical trading data (if available)
   */
  static async getHistoricalData(
    symbol: string = 'ETHUSDT',
    timeframe: string = '1h',
    limit: number = 100
  ): Promise<any[]> {
    try {
      // This would be a custom endpoint for historical data
      const response = await api.get(`/api/v1/ai-swarm/data/historical`, {
        params: { symbol, timeframe, limit }
      })
      return response.data.data || []
    } catch (error) {
      console.error('Failed to get historical data:', error)
      return []
    }
  }
}

export default AISwarmAPI
