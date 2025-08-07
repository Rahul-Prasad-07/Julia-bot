import { Activity, DollarSign, TrendingUp, Volume2 } from 'lucide-react'
import { RealtimeData as RealtimeDataType } from '@/types/api'

interface RealtimeDataProps {
  data?: RealtimeDataType
}

export function RealtimeData({ data }: RealtimeDataProps) {
  if (!data || !data.market_data) {
    return (
      <div className="card-base">
        <div className="flex items-center gap-2 mb-4">
          <Activity className="w-5 h-5 text-blue-400" />
          <h2 className="text-xl font-semibold">Live Market Data</h2>
          <span className="status-indicator bg-gray-500/20 text-gray-300">
            Connecting...
          </span>
        </div>
        
        <div className="animate-pulse space-y-4">
          <div className="h-8 bg-gray-700 rounded w-32"></div>
          <div className="grid grid-cols-2 gap-4">
            <div className="h-16 bg-gray-700 rounded"></div>
            <div className="h-16 bg-gray-700 rounded"></div>
          </div>
        </div>
      </div>
    )
  }

  const { market_data, ai_analysis } = data
  
  const formatPrice = (price: number) => {
    return new Intl.NumberFormat('en-US', {
      style: 'currency',
      currency: 'USD',
      minimumFractionDigits: 2,
      maximumFractionDigits: 2,
    }).format(price)
  }

  const formatVolume = (volume: number) => {
    if (volume > 1000000) {
      return `${(volume / 1000000).toFixed(2)}M`
    }
    if (volume > 1000) {
      return `${(volume / 1000).toFixed(2)}K`
    }
    return volume.toFixed(2)
  }

  const formatTime = (timestamp: string) => {
    return new Date(timestamp).toLocaleTimeString('en-US', { 
      hour12: false,
      hour: '2-digit', 
      minute: '2-digit',
      second: '2-digit'
    })
  }

  return (
    <div className="card-base">
      <div className="flex items-center justify-between mb-4">
        <div className="flex items-center gap-2">
          <Activity className="w-5 h-5 text-blue-400" />
          <h2 className="text-xl font-semibold">Live Market Data</h2>
          <span className="status-indicator bg-green-500/20 text-green-300">
            {market_data.symbol}
          </span>
        </div>
        <span className="text-xs text-gray-400">
          {formatTime(market_data.timestamp)}
        </span>
      </div>

      {/* Main Price Display */}
      <div className="mb-6">
        <div className="text-3xl font-bold text-white mb-2">
          {formatPrice(market_data.price)}
        </div>
        <div className="flex items-center gap-4 text-sm">
          <div className="flex items-center gap-1">
            <span className="text-gray-400">Bid:</span>
            <span className="text-green-400 font-medium">{formatPrice(market_data.bid)}</span>
          </div>
          <div className="flex items-center gap-1">
            <span className="text-gray-400">Ask:</span>
            <span className="text-red-400 font-medium">{formatPrice(market_data.ask)}</span>
          </div>
        </div>
      </div>

      {/* Market Metrics Grid */}
      <div className="grid grid-cols-2 gap-4 mb-6">
        <div className="bg-blue-500/10 border border-blue-500/20 rounded-lg p-4">
          <div className="flex items-center gap-2 mb-2">
            <Volume2 className="w-4 h-4 text-blue-400" />
            <span className="text-sm text-gray-400">Volume</span>
          </div>
          <div className="text-lg font-bold text-white">
            {formatVolume(market_data.volume)}
          </div>
        </div>

        <div className="bg-orange-500/10 border border-orange-500/20 rounded-lg p-4">
          <div className="flex items-center gap-2 mb-2">
            <TrendingUp className="w-4 h-4 text-orange-400" />
            <span className="text-sm text-gray-400">Volatility</span>
          </div>
          <div className="text-lg font-bold text-white">
            {(market_data.volatility * 100).toFixed(2)}%
          </div>
        </div>
      </div>

      {/* Additional Market Info */}
      <div className="space-y-2 text-sm">
        <div className="flex justify-between">
          <span className="text-gray-400">Spread:</span>
          <span className="font-medium text-white">
            {formatPrice(market_data.spread)} ({((market_data.spread / market_data.price) * 100).toFixed(3)}%)
          </span>
        </div>
        
        {ai_analysis && (
          <>
            <div className="flex justify-between">
              <span className="text-gray-400">AI Confidence:</span>
              <span className="font-medium text-purple-400">
                {(ai_analysis.neural_confidence * 100).toFixed(1)}%
              </span>
            </div>
            
            {ai_analysis.combined_signal && (
              <div className="flex justify-between">
                <span className="text-gray-400">AI Signal:</span>
                <span className="font-medium text-cyan-400">
                  {typeof ai_analysis.combined_signal === 'object' 
                    ? (ai_analysis.combined_signal as any)?.action || 'Processing...'
                    : ai_analysis.combined_signal}
                </span>
              </div>
            )}
          </>
        )}
      </div>

      {/* Live Data Indicator */}
      <div className="mt-4 pt-4 border-t border-gray-700">
        <div className="flex items-center gap-2 text-xs text-blue-400">
          <div className="w-2 h-2 bg-blue-500 rounded-full animate-pulse" />
          <span>Live data feed active</span>
        </div>
      </div>
    </div>
  )
}
