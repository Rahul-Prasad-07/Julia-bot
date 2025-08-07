'use client'

import { LineChart, Line, XAxis, YAxis, CartesianGrid, Tooltip, ResponsiveContainer } from 'recharts'
import { RealtimeData } from '@/types/api'
import { TrendingUp } from 'lucide-react'

interface MarketChartProps {
  data?: RealtimeData
}

export function MarketChart({ data }: MarketChartProps) {
  // Mock chart data for now - in production this would come from historical API
  const mockChartData = [
    { time: '15:50', price: 3692.50, ai_prediction: 3693.20 },
    { time: '15:52', price: 3693.10, ai_prediction: 3694.50 },
    { time: '15:54', price: 3694.20, ai_prediction: 3695.10 },
    { time: '15:56', price: 3694.81, ai_prediction: 3695.80 },
    { time: '15:58', price: 3695.12, ai_prediction: 3696.20 },
  ]

  const currentPrice = data?.market_data?.price || 3695.12

  return (
    <div className="card-base">
      <div className="flex items-center gap-2 mb-4">
        <TrendingUp className="w-5 h-5 text-green-400" />
        <h2 className="text-xl font-semibold">Price Chart</h2>
        <span className="status-indicator bg-green-500/20 text-green-300">
          ${currentPrice.toFixed(2)}
        </span>
      </div>

      <div className="h-64">
        <ResponsiveContainer width="100%" height="100%">
          <LineChart data={mockChartData}>
            <CartesianGrid strokeDasharray="3 3" stroke="#374151" />
            <XAxis 
              dataKey="time" 
              stroke="#9CA3AF"
              fontSize={12}
            />
            <YAxis 
              stroke="#9CA3AF"
              fontSize={12}
              domain={['dataMin - 0.5', 'dataMax + 0.5']}
            />
            <Tooltip 
              contentStyle={{
                backgroundColor: '#1F2937',
                border: '1px solid #374151',
                borderRadius: '8px',
                color: '#FFFFFF'
              }}
              formatter={(value: any, name: string) => [
                `$${Number(value).toFixed(2)}`,
                name === 'price' ? 'Market Price' : 'AI Prediction'
              ]}
            />
            <Line 
              type="monotone" 
              dataKey="price" 
              stroke="#3B82F6" 
              strokeWidth={2}
              dot={{ fill: '#3B82F6', strokeWidth: 2, r: 4 }}
              name="price"
            />
            <Line 
              type="monotone" 
              dataKey="ai_prediction" 
              stroke="#A855F7" 
              strokeWidth={2}
              strokeDasharray="5 5"
              dot={{ fill: '#A855F7', strokeWidth: 2, r: 3 }}
              name="ai_prediction"
            />
          </LineChart>
        </ResponsiveContainer>
      </div>

      <div className="mt-4 flex items-center justify-between text-xs">
        <div className="flex items-center gap-4">
          <div className="flex items-center gap-2">
            <div className="w-3 h-0.5 bg-blue-500"></div>
            <span className="text-gray-400">Market Price</span>
          </div>
          <div className="flex items-center gap-2">
            <div className="w-3 h-0.5 bg-purple-500 border-dashed"></div>
            <span className="text-gray-400">AI Prediction</span>
          </div>
        </div>
        
        <div className="text-gray-500">
          Last updated: {data?.timestamp ? new Date(data.timestamp).toLocaleTimeString() : 'Live'}
        </div>
      </div>
    </div>
  )
}
