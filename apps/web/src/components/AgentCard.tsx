import { ReactNode } from 'react'
import { StatusIndicator } from './StatusIndicator'

interface AgentCardProps {
  name: string
  type: 'analyzer' | 'risk' | 'optimizer' | 'execution'
  confidence: number
  status: 'active' | 'inactive' | 'error'
  description: string
  icon: ReactNode
  weight?: number
}

export function AgentCard({ 
  name, 
  type, 
  confidence, 
  status, 
  description, 
  icon, 
  weight 
}: AgentCardProps) {
  const getTypeColor = () => {
    switch (type) {
      case 'analyzer':
        return 'border-blue-500/30 bg-blue-500/5'
      case 'risk':
        return 'border-orange-500/30 bg-orange-500/5'
      case 'optimizer':
        return 'border-purple-500/30 bg-purple-500/5'
      case 'execution':
        return 'border-green-500/30 bg-green-500/5'
      default:
        return 'border-gray-500/30 bg-gray-500/5'
    }
  }

  const getIconColor = () => {
    switch (type) {
      case 'analyzer':
        return 'text-blue-400'
      case 'risk':
        return 'text-orange-400'
      case 'optimizer':
        return 'text-purple-400'
      case 'execution':
        return 'text-green-400'
      default:
        return 'text-gray-400'
    }
  }

  const getConfidenceColor = (confidence: number) => {
    if (confidence >= 80) return 'text-green-400'
    if (confidence >= 60) return 'text-yellow-400'
    return 'text-red-400'
  }

  return (
    <div className={`agent-card ${getTypeColor()}`}>
      <div className="flex items-start justify-between mb-3">
        <div className="flex items-center gap-3">
          <div className={`p-2 rounded-lg bg-white/10 ${getIconColor()}`}>
            {icon}
          </div>
          <div>
            <h3 className="font-semibold text-white">{name}</h3>
            <p className="text-xs text-gray-400">{description}</p>
          </div>
        </div>
        <StatusIndicator status={status} size="sm" />
      </div>

      <div className="space-y-2">
        <div className="flex justify-between items-center">
          <span className="text-sm text-gray-400">Confidence</span>
          <span className={`font-medium ${getConfidenceColor(confidence)}`}>
            {confidence}%
          </span>
        </div>
        
        {weight && (
          <div className="flex justify-between items-center">
            <span className="text-sm text-gray-400">Voting Weight</span>
            <span className="font-medium text-cyan-400">{weight}%</span>
          </div>
        )}

        {/* Confidence Bar */}
        <div className="w-full bg-gray-700 rounded-full h-2">
          <div 
            className={`h-2 rounded-full transition-all duration-500 ${
              confidence >= 80 ? 'bg-green-500' : 
              confidence >= 60 ? 'bg-yellow-500' : 'bg-red-500'
            }`}
            style={{ width: `${confidence}%` }}
          />
        </div>
      </div>

      {/* Neural Network Activity Indicator */}
      {status === 'active' && (
        <div className="mt-3 flex items-center gap-2 text-xs text-gray-400">
          <div className="w-2 h-2 bg-purple-500 rounded-full animate-pulse" />
          Neural network active
        </div>
      )}
    </div>
  )
}
