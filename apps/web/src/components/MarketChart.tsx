'use client'

import { useMemo } from 'react'
import { LineChart, Line, XAxis, YAxis, CartesianGrid, Tooltip, ResponsiveContainer } from 'recharts'
import { TrendingUp } from 'lucide-react'
import { RealtimeData } from '@/types/api'

interface MarketChartProps {
  data?: RealtimeData
}

export function MarketChart({ data }: MarketChartProps) {
  // Generate mock historical data for demonstration
  const chartData = useMemo(() => {
    const basePrice = data?.market_data?.price || 3687
    const dataPoints = []
    
    for (let i = 29; i >= 0; i--) {
      const time = new Date(Date.now() - i * 60000) // Every minute
      const randomVariation = (Math.random() - 0.5) * 20 // ±$10 variation
      const price = basePrice + randomVariation
      
      dataPoints.push({
        time: time.toLocaleTimeString('en-US', { 
          hour12: false,
          hour: '2-digit', 
          minute: '2-digit' 
        }),
        price: price,
        bid: price - (Math.random() * 2 + 0.5),
        ask: price + (Math.random() * 2 + 0.5),
        aiPrediction: price + (Math.random() - 0.5) * 5, // AI prediction
        timestamp: time.getTime()
      })
    }
    
    return dataPoints
  }, [data?.market_data?.price])

  const currentPrice = data?.market_data?.price || 0
  const previousPrice = chartData[chartData.length - 2]?.price || currentPrice
  const priceChange = currentPrice - previousPrice
  const priceChangePercent = ((priceChange / previousPrice) * 100)

  const CustomTooltip = ({ active, payload, label }: any) => {
    if (active && payload && payload.length) {
      return (
        <div className="bg-gray-800 border border-gray-600 rounded-lg p-3 shadow-lg">
          <p className="text-gray-300 text-sm mb-2">{label}</p>
          {payload.map((entry: any, index: number) => (
            <p key={index} className="text-sm" style={{ color: entry.color }}>
              {entry.name}: ${entry.value?.toFixed(2)}
            </p>
          ))}
        </div>
      )
    }
    return null
  }

  return (
    <div className="card-base">
      <div className="flex items-center justify-between mb-4">
        <div className="flex items-center gap-2">
          <TrendingUp className="w-5 h-5 text-blue-400" />
          <h2 className="text-xl font-semibold">Price Chart</h2>
          <span className="text-xs text-gray-400">ETHUSDT • 1M</span>
        </div>
        
        <div className="text-right">
          <div className="text-lg font-bold text-white">
            ${currentPrice.toFixed(2)}
          </div>
          <div className={`text-sm ${priceChange >= 0 ? 'text-green-400' : 'text-red-400'}`}>
            {priceChange >= 0 ? '+' : ''}{priceChange.toFixed(2)} ({priceChangePercent.toFixed(2)}%)
          </div>
        </div>
      </div>

      <div className="h-64 w-full">
        <ResponsiveContainer width="100%" height="100%">
          <LineChart
            data={chartData}
            margin={{
              top: 5,
              right: 30,
              left: 20,
              bottom: 5,
            }}
          >
            <CartesianGrid strokeDasharray="3 3" stroke="#374151" />
            <XAxis 
              dataKey="time" 
              stroke="#9CA3AF"
              fontSize={12}
              tick={{ fill: '#9CA3AF' }}
              interval="preserveStartEnd"
            />
            <YAxis 
              stroke="#9CA3AF"
              fontSize={12}
              tick={{ fill: '#9CA3AF' }}
              domain={['dataMin - 5', 'dataMax + 5']}
              tickFormatter={(value) => `$${value.toFixed(0)}`}
            />
            <Tooltip content={<CustomTooltip />} />
            
            {/* Price Line */}
            <Line
              type="monotone"
              dataKey="price"
              stroke="#3B82F6"
              strokeWidth={2}
              dot={false}
              name="Price"
            />
            
            {/* Bid Line */}
            <Line
              type="monotone"
              dataKey="bid"
              stroke="#10B981"
              strokeWidth={1}
              strokeDasharray="5 5"
              dot={false}
              name="Bid"
            />
            
            {/* Ask Line */}
            <Line
              type="monotone"
              dataKey="ask"
              stroke="#EF4444"
              strokeWidth={1}
              strokeDasharray="5 5"
              dot={false}
              name="Ask"
            />
            
            {/* AI Prediction Line */}
            <Line
              type="monotone"
              dataKey="aiPrediction"
              stroke="#A855F7"
              strokeWidth={1.5}
              strokeDasharray="3 3"
              dot={false}
              name="AI Prediction"
            />
          </LineChart>
        </ResponsiveContainer>
      </div>

      {/* Chart Legend */}
      <div className="flex items-center justify-center gap-6 mt-4 text-xs">
        <div className="flex items-center gap-2">
          <div className="w-3 h-0.5 bg-blue-500"></div>
          <span className="text-gray-400">Price</span>
        </div>
        <div className="flex items-center gap-2">
          <div className="w-3 h-0.5 bg-green-500 border-dashed"></div>
          <span className="text-gray-400">Bid</span>
        </div>
        <div className="flex items-center gap-2">
          <div className="w-3 h-0.5 bg-red-500 border-dashed"></div>
          <span className="text-gray-400">Ask</span>
        </div>
        <div className="flex items-center gap-2">
          <div className="w-3 h-0.5 bg-purple-500 border-dashed"></div>
          <span className="text-gray-400">AI Prediction</span>
        </div>
      </div>

      {/* AI Analysis Indicator */}
      {data?.ai_analysis && (
        <div className="mt-4 pt-4 border-t border-gray-700">
          <div className="flex items-center gap-2 text-xs text-purple-400">
            <div className="w-2 h-2 bg-purple-500 rounded-full animate-pulse" />
            <span>
              AI neural network analysis: {(data.ai_analysis.neural_confidence * 100).toFixed(1)}% confidence
            </span>
          </div>
        </div>
      )}
    </div>
  )
}
