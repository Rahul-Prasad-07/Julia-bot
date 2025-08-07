import './globals.css'
import type { Metadata } from 'next'
import { Providers } from './providers'

export const metadata: Metadata = {
  title: '🤖🐝 AI Swarm Trading System',
  description: 'Advanced AI Trading Platform with Neural Networks, Swarm Intelligence, and Real-time Market Making',
  keywords: ['AI Trading', 'Swarm Intelligence', 'Neural Networks', 'Market Making', 'DeFi', 'JuliaOS'],
}

export default function RootLayout({
  children,
}: {
  children: React.ReactNode
}) {
  return (
    <html lang="en" className="dark">
      <body className="min-h-screen bg-gradient-to-br from-slate-900 via-slate-800 to-slate-900 text-white">
        <Providers>
          <div className="min-h-screen">
            {children}
          </div>
        </Providers>
      </body>
    </html>
  )
}
