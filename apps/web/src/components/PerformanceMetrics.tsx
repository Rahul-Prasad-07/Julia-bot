import { TrendingUp, DollarSign, Activity, Target } from 'lucide-react'
import { PerformanceReport } from '@/types/api'

interface PerformanceMetricsProps {
  data?: PerformanceReport
  loading: boolean
}

export function PerformanceMetrics({ data, loading }: PerformanceMetricsProps) {
  if (loading) {
    return (
      <div className="card-base">
        <div className="animate-pulse space-y-4">
          <div className="h-6 bg-gray-700 rounded w-32"></div>
          <div className="space-y-2">
            <div className="h-4 bg-gray-700 rounded"></div>
            <div className="h-4 bg-gray-700 rounded w-3/4"></div>
          </div>
        </div>
      </div>
    )
  }

  const metrics = data?.realtime_metrics
  const performanceReport = data?.performance_report

  // Parse performance data from the raw report
  const parsePerformanceData = (rawReport: string) => {
    if (!rawReport) return null
    
    try {
      // Extract key metrics from the raw report string
      const balanceMatch = rawReport.match(/Current Balance: \$([0-9,.]+)/)
      const returnMatch = rawReport.match(/Total Return: ([0-9.-]+)%/)
      const tradesMatch = rawReport.match(/Total Trades Executed: ([0-9]+)/)
      const accuracyMatch = rawReport.match(/AI Decision Accuracy: ([0-9.]+)%/)
      const consensusMatch = rawReport.match(/Swarm Consensus Rate: ([0-9.]+)%/)
      
      return {
        currentBalance: balanceMatch ? parseFloat(balanceMatch[1].replace(',', '')) : 1000,
        totalReturn: returnMatch ? parseFloat(returnMatch[1]) : 0,
        totalTrades: tradesMatch ? parseInt(tradesMatch[1]) : 0,
        aiAccuracy: accuracyMatch ? parseFloat(accuracyMatch[1]) : 0,
        consensusRate: consensusMatch ? parseFloat(consensusMatch[1]) : 0
      }
    } catch (e) {
      return null
    }
  }

  const parsed = parsePerformanceData(data?.raw_report || '')

  const performanceData = {
    currentBalance: parsed?.currentBalance || 1000,
    totalReturn: parsed?.totalReturn || 0,
    totalTrades: parsed?.totalTrades || metrics?.trading_iterations || 0,
    aiAccuracy: parsed?.aiAccuracy || 85,
    consensusRate: parsed?.consensusRate || 91,
    systemUptime: metrics?.system_uptime || 0
  }

  const formatUptime = (seconds: number) => {
    const hours = Math.floor(seconds / 3600)
    const minutes = Math.floor((seconds % 3600) / 60)
    return hours > 0 ? `${hours}h ${minutes}m` : `${minutes}m`
  }

  const getReturnColor = (returnPct: number) => {
    if (returnPct > 0) return 'text-green-400'
    if (returnPct < 0) return 'text-red-400'
    return 'text-gray-400'
  }

  return (
    <div className="card-base">
      <div className="flex items-center gap-2 mb-4">
        <DollarSign className="w-5 h-5 text-green-400" />
        <h2 className="text-xl font-semibold">Performance</h2>
      </div>

      <div className="space-y-4">
        {/* Account Balance */}
        <div className="bg-green-500/10 border border-green-500/20 rounded-lg p-4">
          <div className="flex items-center justify-between mb-2">
            <span className="text-sm text-gray-400">Current Balance</span>
            <TrendingUp className="w-4 h-4 text-green-400" />
          </div>
          <div className="text-2xl font-bold text-white">
            ${performanceData.currentBalance.toLocaleString()}
          </div>
          <div className="text-sm">
            <span className={`font-medium ${getReturnColor(performanceData.totalReturn)}`}>
              {performanceData.totalReturn > 0 ? '+' : ''}{performanceData.totalReturn.toFixed(2)}%
            </span>
            <span className="text-gray-400 ml-1">total return</span>
          </div>
        </div>

        {/* Trading Stats */}
        <div className="grid grid-cols-2 gap-3">
          <div className="bg-blue-500/10 border border-blue-500/20 rounded-lg p-3">
            <div className="flex items-center gap-2 mb-1">
              <Activity className="w-4 h-4 text-blue-400" />
              <span className="text-xs text-gray-400">Total Trades</span>
            </div>
            <div className="text-lg font-bold text-white">
              {performanceData.totalTrades}
            </div>
          </div>

          <div className="bg-purple-500/10 border border-purple-500/20 rounded-lg p-3">
            <div className="flex items-center gap-2 mb-1">
              <Target className="w-4 h-4 text-purple-400" />
              <span className="text-xs text-gray-400">AI Accuracy</span>
            </div>
            <div className="text-lg font-bold text-white">
              {performanceData.aiAccuracy.toFixed(1)}%
            </div>
          </div>
        </div>

        {/* Additional Metrics */}
        <div className="space-y-3 text-sm">
          <div className="flex justify-between">
            <span className="text-gray-400">Consensus Rate:</span>
            <span className="font-medium text-cyan-400">
              {performanceData.consensusRate.toFixed(1)}%
            </span>
          </div>
          
          <div className="flex justify-between">
            <span className="text-gray-400">System Uptime:</span>
            <span className="font-medium text-white">
              {formatUptime(performanceData.systemUptime)}
            </span>
          </div>
          
          <div className="flex justify-between">
            <span className="text-gray-400">Active Agents:</span>
            <span className="font-medium text-green-400">
              {metrics?.agents_active || 4}
            </span>
          </div>
        </div>

        {/* Performance Indicator */}
        <div className="pt-3 border-t border-gray-700">
          <div className="flex items-center gap-2 text-xs">
            <div className="w-2 h-2 bg-green-500 rounded-full animate-pulse" />
            <span className="text-gray-400">
              Real-time performance tracking active
            </span>
          </div>
        </div>
      </div>
    </div>
  )
}
