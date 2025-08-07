interface StatusIndicatorProps {
  status: 'active' | 'inactive' | 'error' | 'warning'
  label?: string
  size?: 'sm' | 'md' | 'lg'
}

export function StatusIndicator({ status, label, size = 'md' }: StatusIndicatorProps) {
  const getStatusStyles = () => {
    switch (status) {
      case 'active':
        return 'bg-green-500/20 text-green-300 border-green-500/30'
      case 'inactive':
        return 'bg-gray-500/20 text-gray-300 border-gray-500/30'
      case 'error':
        return 'bg-red-500/20 text-red-300 border-red-500/30'
      case 'warning':
        return 'bg-orange-500/20 text-orange-300 border-orange-500/30'
      default:
        return 'bg-gray-500/20 text-gray-300 border-gray-500/30'
    }
  }

  const getDotColor = () => {
    switch (status) {
      case 'active':
        return 'bg-green-500'
      case 'inactive':
        return 'bg-gray-500'
      case 'error':
        return 'bg-red-500'
      case 'warning':
        return 'bg-orange-500'
      default:
        return 'bg-gray-500'
    }
  }

  const getSizeStyles = () => {
    switch (size) {
      case 'sm':
        return 'px-2 py-1 text-xs'
      case 'md':
        return 'px-2.5 py-1.5 text-sm'
      case 'lg':
        return 'px-3 py-2 text-base'
      default:
        return 'px-2.5 py-1.5 text-sm'
    }
  }

  const dotSize = size === 'sm' ? 'w-2 h-2' : size === 'lg' ? 'w-3 h-3' : 'w-2.5 h-2.5'

  return (
    <div className={`inline-flex items-center gap-2 rounded-full border ${getStatusStyles()} ${getSizeStyles()}`}>
      <div className={`${dotSize} rounded-full ${getDotColor()} ${status === 'active' ? 'animate-pulse' : ''}`} />
      {label && <span className="font-medium">{label}</span>}
    </div>
  )
}
