#!/usr/bin/env python3
"""
Enhanced YieldSwarm Dashboard Server
Serves the enhanced dashboard with live data integration
"""

import http.server
import socketserver
import os
import json
from pathlib import Path

class YieldSwarmHTTPRequestHandler(http.server.SimpleHTTPRequestHandler):
    def __init__(self, *args, **kwargs):
        super().__init__(*args, directory="web", **kwargs)
    
    def end_headers(self):
        # Add CORS headers for API calls
        self.send_header('Access-Control-Allow-Origin', '*')
        self.send_header('Access-Control-Allow-Methods', 'GET, POST, PUT, DELETE, OPTIONS')
        self.send_header('Access-Control-Allow-Headers', 'Content-Type, Authorization')
        super().end_headers()
    
    def do_OPTIONS(self):
        # Handle preflight requests
        self.send_response(200)
        self.end_headers()

def main():
    PORT = 8080
    
    print("🚀 Enhanced YieldSwarm Dashboard Server")
    print("=" * 50)
    print(f"🌐 Dashboard URL: http://localhost:{PORT}/yieldswarm-dashboard.html")
    print(f"📊 Backend API: http://127.0.0.1:8052/api/v1")
    print("=" * 50)
    print("✨ Features:")
    print("  • Live DeFi yield opportunities from DeFiLlama")
    print("  • Real-time token prices from CoinGecko")
    print("  • Auto-managed YieldSwarm agents")
    print("  • AI-powered yield analysis")
    print("  • Multi-chain protocol support")
    print("=" * 50)
    print("📝 Usage:")
    print("  1. Open the dashboard URL in your browser")
    print("  2. Click 'Auto-Start All Agents' to initialize")
    print("  3. Click 'Refresh Live Data' to load current yields")
    print("  4. Use 'Run Live Analysis' for AI recommendations")
    print("=" * 50)
    print(f"🟢 Server starting on port {PORT}...")
    
    # Change to project root directory
    os.chdir(os.path.dirname(os.path.abspath(__file__)))
    
    with socketserver.TCPServer(("", PORT), YieldSwarmHTTPRequestHandler) as httpd:
        try:
            httpd.serve_forever()
        except KeyboardInterrupt:
            print("\n🛑 Server stopped by user")
        except Exception as e:
            print(f"❌ Server error: {e}")
        finally:
            httpd.server_close()
            print("👋 Goodbye!")

if __name__ == "__main__":
    main()
