'use client'

import { useState, useEffect } from 'react'
import { useQuery, useQueryClient } from '@tanstack/react-query'
import { toast } from 'react-hot-toast'
import { 
  Activity, 
  Brain, 
  Users, 
  TrendingUp, 
  DollarSign, 
  Settings,
  Play,
  Square,
  AlertTriangle,
  RefreshCw,
  Zap,
  Target
} from 'lucide-react'

import AISwarmAPI from '@/lib/api'
import { StatusIndicator } from '@/components/StatusIndicator'
import { AgentCard } from '@/components/AgentCard'
import { SwarmConsensus } from '@/components/SwarmConsensus'
import { MarketChart } from '@/components/MarketChartFixed'
import { PerformanceMetrics } from '@/components/PerformanceMetrics'
import { TradingControls } from '@/components/TradingControls'
import { RealtimeData } from '@/components/RealtimeData'

export default function Dashboard() {
  const [isConnected, setIsConnected] = useState(false)
  const queryClient = useQueryClient()

  // Test API connection on mount
  useEffect(() => {
    const testConnection = async () => {
      const connected = await AISwarmAPI.testConnection()
      setIsConnected(connected)
      if (!connected) {
        toast.error('❌ Unable to connect to AI Swarm backend. Please ensure Julia server is running on port 8052.')
      } else {
        toast.success('✅ Connected to AI Swarm Trading System')
      }
    }
    testConnection()
  }, [])

  // Fetch system status
  const { data: status, isLoading: statusLoading, error: statusError } = useQuery({
    queryKey: ['ai-swarm-status'],
    queryFn: AISwarmAPI.getStatus,
    enabled: isConnected,
    refetchInterval: 5000, // Every 5 seconds
  })

  // Fetch performance data
  const { data: performance, isLoading: performanceLoading } = useQuery({
    queryKey: ['ai-swarm-performance'],
    queryFn: AISwarmAPI.getPerformance,
    enabled: isConnected,
    refetchInterval: 10000, // Every 10 seconds
  })

  // Fetch real-time market data
  const { data: realtimeData } = useQuery({
    queryKey: ['ai-swarm-realtime'],
    queryFn: () => AISwarmAPI.getRealtimeData('ETHUSDT'),
    enabled: isConnected && status?.trading_control?.is_running,
    refetchInterval: 2000, // Every 2 seconds when trading
  })

  // Fetch agents data
  const { data: agents } = useQuery({
    queryKey: ['ai-swarm-agents'],
    queryFn: AISwarmAPI.getAgents,
    enabled: isConnected,
    refetchInterval: 8000, // Every 8 seconds
  })

  const refreshAll = () => {
    queryClient.invalidateQueries({ queryKey: ['ai-swarm'] })
    toast.success('🔄 Refreshing all data...')
  }

  if (!isConnected) {
    return (
      <div className="min-h-screen flex items-center justify-center">
        <div className="text-center space-y-4">
          <div className="w-16 h-16 mx-auto border-4 border-blue-500 border-t-transparent rounded-full animate-spin"></div>
          <h2 className="text-2xl font-bold text-white">Connecting to AI Swarm Backend...</h2>
          <p className="text-gray-400">
            Please ensure the Julia server is running:<br />
            <code className="bg-gray-800 px-2 py-1 rounded">cd backend && julia run_server.jl</code>
          </p>
        </div>
      </div>
    )
  }

  if (statusError) {
    return (
      <div className="min-h-screen flex items-center justify-center">
        <div className="text-center space-y-4">
          <AlertTriangle className="w-16 h-16 mx-auto text-red-500" />
          <h2 className="text-2xl font-bold text-white">Connection Error</h2>
          <p className="text-gray-400">Failed to connect to AI Swarm backend</p>
          <button 
            onClick={() => window.location.reload()}
            className="btn-primary"
          >
            <RefreshCw className="w-4 h-4" />
            Retry Connection
          </button>
        </div>
      </div>
    )
  }

  return (
    <div className="min-h-screen p-6 space-y-6">
      {/* Header */}
      <header className="flex items-center justify-between">
        <div className="flex items-center space-x-4">
          <div className="text-3xl">🤖🐝</div>
          <div>
            <h1 className="text-3xl font-bold ai-gradient bg-clip-text text-transparent">
              AI Swarm Trading System
            </h1>
            <p className="text-gray-400">
              Advanced Market Making with Neural Networks & Swarm Intelligence
            </p>
          </div>
        </div>
        
        <div className="flex items-center space-x-4">
          <StatusIndicator 
            status={status?.trading_control?.is_running ? 'active' : 'inactive'}
            label={status?.trading_control?.is_running ? 'Trading Active' : 'Trading Stopped'}
          />
          <button onClick={refreshAll} className="btn-primary">
            <RefreshCw className="w-4 h-4" />
            Refresh
          </button>
        </div>
      </header>

      {/* Main Controls */}
      <TradingControls 
        status={status}
        onStatusChange={() => queryClient.invalidateQueries({ queryKey: ['ai-swarm-status'] })}
      />

      {/* Main Dashboard Grid */}
      <div className="grid grid-cols-1 lg:grid-cols-3 gap-6">
        {/* Left Column - AI Agents */}
        <div className="space-y-6">
          <div className="card-base">
            <div className="flex items-center gap-2 mb-4">
              <Brain className="w-5 h-5 text-purple-400" />
              <h2 className="text-xl font-semibold">AI Agents</h2>
              <span className="status-indicator bg-purple-500/20 text-purple-300">
                {agents?.total_symbols || 0} Active
              </span>
            </div>
            
            <div className="space-y-4">
              <AgentCard 
                name="Market Analyzer"
                type="analyzer"
                confidence={85}
                status="active"
                description="Neural network + LLM sentiment analysis"
                icon={<TrendingUp className="w-5 h-5" />}
              />
              
              <AgentCard 
                name="Risk Manager"
                type="risk"
                confidence={78}
                status="active"
                description="AI-powered risk assessment"
                icon={<AlertTriangle className="w-5 h-5" />}
                weight={30}
              />
              
              <AgentCard 
                name="Strategy Optimizer"
                type="optimizer"
                confidence={72}
                status="active"
                description="Parameter optimization"
                icon={<Target className="w-5 h-5" />}
              />
              
              <AgentCard 
                name="Execution Agent"
                type="execution"
                confidence={88}
                status="active"
                description="Order timing and execution"
                icon={<Zap className="w-5 h-5" />}
              />
            </div>
          </div>

          {/* Performance Metrics */}
          <PerformanceMetrics data={performance} loading={performanceLoading} />
        </div>

        {/* Center Column - Market Data & Chart */}
        <div className="space-y-6">
          <RealtimeData data={realtimeData} />
          <MarketChart data={realtimeData} />
        </div>

        {/* Right Column - Swarm Consensus & Analytics */}
        <div className="space-y-6">
          <SwarmConsensus 
            consensusRate={99.2}
            lastDecision={{ action: 'buy', strength: 97.8, timestamp: new Date() }}
            votingHistory={[
              { action: 'buy', strength: 97.8, timestamp: new Date(Date.now() - 24000) },
              { action: 'buy', strength: 91.0, timestamp: new Date(Date.now() - 54000) },
              { action: 'hold', strength: 65.3, timestamp: new Date(Date.now() - 84000) },
            ]}
          />

          {/* Neural Network Status */}
          <div className="card-base neural-glow">
            <div className="flex items-center gap-2 mb-4">
              <Brain className="w-5 h-5 text-purple-400" />
              <h2 className="text-xl font-semibold">Neural Networks</h2>
            </div>
            
            <div className="space-y-3">
              <div className="flex justify-between items-center">
                <span className="text-sm">Market Analysis Net</span>
                <StatusIndicator status="active" size="sm" />
              </div>
              <div className="flex justify-between items-center">
                <span className="text-sm">Risk Management DQN</span>
                <StatusIndicator status="active" size="sm" />
              </div>
              <div className="flex justify-between items-center">
                <span className="text-sm">Strategy Optimizer DQN</span>
                <StatusIndicator status="active" size="sm" />
              </div>
              <div className="flex justify-between items-center">
                <span className="text-sm">Execution Agent DQN</span>
                <StatusIndicator status="active" size="sm" />
              </div>
              <div className="flex justify-between items-center">
                <span className="text-sm">Groq LLM Integration</span>
                <StatusIndicator status="active" size="sm" />
              </div>
            </div>
          </div>

          {/* Live Trading Status */}
          <div className="card-base">
            <div className="flex items-center gap-2 mb-4">
              <Activity className="w-5 h-5 text-green-400" />
              <h2 className="text-xl font-semibold">Live Trading</h2>
            </div>
            
            <div className="space-y-3 text-sm">
              <div className="flex justify-between">
                <span className="text-gray-400">Active Orders:</span>
                <span className="font-medium">2</span>
              </div>
              <div className="flex justify-between">
                <span className="text-gray-400">Last Trade:</span>
                <span className="font-medium">00:58</span>
              </div>
              <div className="flex justify-between">
                <span className="text-gray-400">Success Rate:</span>
                <span className="font-medium text-green-400">100%</span>
              </div>
              <div className="flex justify-between">
                <span className="text-gray-400">Consensus Rate:</span>
                <span className="font-medium text-cyan-400">99.2%</span>
              </div>
            </div>
          </div>
        </div>
      </div>
    </div>
  )
}
