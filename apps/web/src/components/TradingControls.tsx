'use client'

import { useState } from 'react'
import { Play, Square, AlertTriangle, Settings } from 'lucide-react'
import { toast } from 'react-hot-toast'
import AISwarmAPI from '@/lib/api'
import { AISwarmStatus } from '@/types/api'

interface TradingControlsProps {
  status?: AISwarmStatus
  onStatusChange: () => void
}

export function TradingControls({ status, onStatusChange }: TradingControlsProps) {
  const [isLoading, setIsLoading] = useState(false)
  const [showConfig, setShowConfig] = useState(false)
  const [config, setConfig] = useState({
    symbols: ['ETHUSDT'],
    max_capital: 100,
    base_spread_pct: 0.15,
    consensus_threshold: 0.65,
    enable_neural_networks: true,
    enable_groq_sentiment: true,
    enable_swarm_consensus: true,
  })

  const isTrading = status?.trading_control?.is_running || false

  const handleStartTrading = async () => {
    setIsLoading(true)
    try {
      const response = await AISwarmAPI.startTrading(config)
      if (response.success) {
        toast.success('🚀 AI Swarm trading started successfully!')
        onStatusChange()
      } else {
        toast.error('❌ Failed to start trading')
      }
    } catch (error: any) {
      toast.error(`❌ Error: ${error.message}`)
    } finally {
      setIsLoading(false)
    }
  }

  const handleStopTrading = async () => {
    setIsLoading(true)
    try {
      const response = await AISwarmAPI.stopTrading()
      if (response.success) {
        toast.success('⏹️ AI Swarm trading stopped')
        onStatusChange()
      }
    } catch (error: any) {
      toast.error(`❌ Error: ${error.message}`)
    } finally {
      setIsLoading(false)
    }
  }

  const handleEmergencyStop = async () => {
    if (!confirm('⚠️ Are you sure you want to emergency stop? This will cancel all orders immediately.')) {
      return
    }
    
    setIsLoading(true)
    try {
      const response = await AISwarmAPI.emergencyStop()
      if (response.success) {
        toast.success(`🚨 Emergency stop executed! Cancelled ${response.cancelled_orders} orders`)
        onStatusChange()
      }
    } catch (error: any) {
      toast.error(`❌ Emergency stop failed: ${error.message}`)
    } finally {
      setIsLoading(false)
    }
  }

  return (
    <div className="card-base">
      <div className="flex items-center justify-between mb-6">
        <div>
          <h2 className="text-2xl font-bold text-white mb-2">Trading Controls</h2>
          <p className="text-gray-400">
            {isTrading 
              ? `Active trading • ${status?.trading_control?.iteration_count || 0} iterations completed`
              : 'Trading system ready to start'
            }
          </p>
        </div>
        
        <div className="flex items-center gap-3">
          {!isTrading ? (
            <button 
              onClick={handleStartTrading}
              disabled={isLoading}
              className="btn-success"
            >
              <Play className="w-5 h-5" />
              {isLoading ? 'Starting...' : 'Start AI Swarm'}
            </button>
          ) : (
            <button 
              onClick={handleStopTrading}
              disabled={isLoading}
              className="btn-warning"
            >
              <Square className="w-5 h-5" />
              {isLoading ? 'Stopping...' : 'Stop Trading'}
            </button>
          )}
          
          <button 
            onClick={handleEmergencyStop}
            disabled={isLoading || !isTrading}
            className="btn-danger"
          >
            <AlertTriangle className="w-5 h-5" />
            Emergency Stop
          </button>
          
          <button 
            onClick={() => setShowConfig(!showConfig)}
            className="btn-primary"
          >
            <Settings className="w-5 h-5" />
            Config
          </button>
        </div>
      </div>

      {/* Configuration Panel */}
      {showConfig && (
        <div className="border-t border-gray-700 pt-6 space-y-4">
          <h3 className="text-lg font-semibold text-white mb-4">AI Swarm Configuration</h3>
          
          <div className="grid grid-cols-1 md:grid-cols-2 lg:grid-cols-3 gap-4">
            <div>
              <label className="block text-sm font-medium text-gray-300 mb-1">
                Max Capital (USDT)
              </label>
              <input 
                type="number"
                value={config.max_capital}
                onChange={(e) => setConfig({...config, max_capital: Number(e.target.value)})}
                className="w-full px-3 py-2 bg-gray-800 border border-gray-600 rounded-lg text-white focus:border-blue-500 focus:outline-none"
              />
            </div>
            
            <div>
              <label className="block text-sm font-medium text-gray-300 mb-1">
                Base Spread (%)
              </label>
              <input 
                type="number"
                step="0.01"
                value={config.base_spread_pct}
                onChange={(e) => setConfig({...config, base_spread_pct: Number(e.target.value)})}
                className="w-full px-3 py-2 bg-gray-800 border border-gray-600 rounded-lg text-white focus:border-blue-500 focus:outline-none"
              />
            </div>
            
            <div>
              <label className="block text-sm font-medium text-gray-300 mb-1">
                Consensus Threshold (%)
              </label>
              <input 
                type="number"
                step="0.01"
                min="0.5"
                max="1"
                value={config.consensus_threshold}
                onChange={(e) => setConfig({...config, consensus_threshold: Number(e.target.value)})}
                className="w-full px-3 py-2 bg-gray-800 border border-gray-600 rounded-lg text-white focus:border-blue-500 focus:outline-none"
              />
            </div>
          </div>
          
          <div className="flex flex-wrap gap-4">
            <label className="flex items-center gap-2 text-sm text-gray-300">
              <input 
                type="checkbox"
                checked={config.enable_neural_networks}
                onChange={(e) => setConfig({...config, enable_neural_networks: e.target.checked})}
                className="rounded border-gray-600 bg-gray-800 text-blue-500 focus:ring-blue-500"
              />
              Enable Neural Networks
            </label>
            
            <label className="flex items-center gap-2 text-sm text-gray-300">
              <input 
                type="checkbox"
                checked={config.enable_groq_sentiment}
                onChange={(e) => setConfig({...config, enable_groq_sentiment: e.target.checked})}
                className="rounded border-gray-600 bg-gray-800 text-blue-500 focus:ring-blue-500"
              />
              Enable Groq LLM Sentiment
            </label>
            
            <label className="flex items-center gap-2 text-sm text-gray-300">
              <input 
                type="checkbox"
                checked={config.enable_swarm_consensus}
                onChange={(e) => setConfig({...config, enable_swarm_consensus: e.target.checked})}
                className="rounded border-gray-600 bg-gray-800 text-blue-500 focus:ring-blue-500"
              />
              Enable Swarm Consensus
            </label>
          </div>
        </div>
      )}
    </div>
  )
}
