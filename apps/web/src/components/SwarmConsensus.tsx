import { Users, TrendingUp, Clock } from 'lucide-react'

interface SwarmConsensusProps {
  consensusRate: number
  lastDecision: {
    action: 'buy' | 'sell' | 'hold'
    strength: number
    timestamp: Date
  }
  votingHistory: Array<{
    action: 'buy' | 'sell' | 'hold'
    strength: number
    timestamp: Date
  }>
}

export function SwarmConsensus({ consensusRate, lastDecision, votingHistory }: SwarmConsensusProps) {
  const getActionColor = (action: string) => {
    switch (action) {
      case 'buy':
        return 'text-green-400 bg-green-500/20'
      case 'sell':
        return 'text-red-400 bg-red-500/20'
      case 'hold':
        return 'text-yellow-400 bg-yellow-500/20'
      default:
        return 'text-gray-400 bg-gray-500/20'
    }
  }

  const formatTime = (date: Date) => {
    return date.toLocaleTimeString('en-US', { 
      hour12: false, 
      hour: '2-digit', 
      minute: '2-digit',
      second: '2-digit'
    })
  }

  return (
    <div className="card-base swarm-glow">
      <div className="flex items-center gap-2 mb-4">
        <Users className="w-5 h-5 text-cyan-400" />
        <h2 className="text-xl font-semibold">Swarm Consensus</h2>
        <span className="status-indicator bg-cyan-500/20 text-cyan-300">
          {consensusRate}% Rate
        </span>
      </div>

      {/* Current Consensus */}
      <div className="mb-6">
        <div className="flex items-center justify-between mb-2">
          <span className="text-sm text-gray-400">Latest Decision</span>
          <span className="text-xs text-gray-500">
            {formatTime(lastDecision.timestamp)}
          </span>
        </div>
        
        <div className="flex items-center gap-3">
          <span className={`px-3 py-1 rounded-full text-sm font-medium uppercase ${getActionColor(lastDecision.action)}`}>
            {lastDecision.action}
          </span>
          <div className="flex-1">
            <div className="flex justify-between text-sm mb-1">
              <span className="text-gray-400">Consensus Strength</span>
              <span className="text-white font-medium">{lastDecision.strength}%</span>
            </div>
            <div className="w-full bg-gray-700 rounded-full h-2">
              <div 
                className="h-2 rounded-full bg-gradient-to-r from-cyan-500 to-green-500 transition-all duration-500"
                style={{ width: `${lastDecision.strength}%` }}
              />
            </div>
          </div>
        </div>
      </div>

      {/* Voting Progress Simulation */}
      <div className="mb-6">
        <h3 className="text-sm font-medium text-gray-300 mb-3">Agent Voting Progress</h3>
        <div className="space-y-2">
          {[
            { name: 'Market Analyzer', vote: 'BUY', confidence: 85 },
            { name: 'Risk Manager', vote: 'BUY', confidence: 78 },
            { name: 'Strategy Optimizer', vote: 'BUY', confidence: 72 },
            { name: 'Execution Agent', vote: 'BUY', confidence: 88 }
          ].map((agent, index) => (
            <div key={agent.name} className="flex items-center justify-between text-xs">
              <span className="text-gray-400 w-24 truncate">{agent.name}</span>
              <span className={`px-2 py-1 rounded text-xs font-medium ${getActionColor(agent.vote.toLowerCase())}`}>
                {agent.vote}
              </span>
              <span className="text-white w-12 text-right">{agent.confidence}%</span>
            </div>
          ))}
        </div>
      </div>

      {/* Recent Decisions History */}
      <div>
        <h3 className="text-sm font-medium text-gray-300 mb-3">Recent Decisions</h3>
        <div className="space-y-2">
          {votingHistory.slice(0, 5).map((decision, index) => (
            <div key={index} className="flex items-center justify-between text-xs">
              <div className="flex items-center gap-2">
                <span className="text-gray-500">#{index + 1}</span>
                <span className={`px-2 py-1 rounded text-xs font-medium ${getActionColor(decision.action)}`}>
                  {decision.action.toUpperCase()}
                </span>
              </div>
              <div className="flex items-center gap-2">
                <span className="text-white">{decision.strength}%</span>
                <span className="text-gray-500">{formatTime(decision.timestamp)}</span>
              </div>
            </div>
          ))}
        </div>
      </div>

      {/* Swarm Intelligence Indicator */}
      <div className="mt-4 pt-4 border-t border-gray-700">
        <div className="flex items-center gap-2 text-xs text-cyan-400">
          <div className="w-2 h-2 bg-cyan-500 rounded-full animate-pulse" />
          Democratic voting in progress...
        </div>
      </div>
    </div>
  )
}
