#!/usr/bin/env python3
"""
Simple HTTP server to serve the Solana development web interfaces
This fixes CORS issues when accessing the JuliaOS backend
"""

import http.server
import socketserver
import os
import sys
import socket
from pathlib import Path

# Get the directory where this script is located
WEB_DIR = Path(__file__).parent
PORT = 3001  # Changed from 3000 to 3001

def find_free_port(start_port=3001, max_attempts=10):
    """Find a free port starting from start_port"""
    for port in range(start_port, start_port + max_attempts):
        try:
            with socket.socket(socket.AF_INET, socket.SOCK_STREAM) as s:
                s.bind(('', port))
                return port
        except OSError:
            continue
    raise OSError(f"No free port found in range {start_port}-{start_port + max_attempts}")

class CORSRequestHandler(http.server.SimpleHTTPRequestHandler):
    def end_headers(self):
        # Add CORS headers
        self.send_header('Access-Control-Allow-Origin', '*')
        self.send_header('Access-Control-Allow-Methods', 'GET, POST, PUT, DELETE, OPTIONS')
        self.send_header('Access-Control-Allow-Headers', 'Content-Type, Authorization')
        super().end_headers()
    
    def do_OPTIONS(self):
        # Handle preflight requests
        self.send_response(200)
        self.send_header('Access-Control-Allow-Origin', '*')
        self.send_header('Access-Control-Allow-Methods', 'GET, POST, PUT, DELETE, OPTIONS')
        self.send_header('Access-Control-Allow-Headers', 'Content-Type, Authorization')
        self.end_headers()

def main():
    # Change to the web directory
    os.chdir(WEB_DIR)
    
    # Find a free port
    try:
        actual_port = find_free_port(PORT)
    except OSError as e:
        print(f"❌ Error: {e}")
        sys.exit(1)
    
    # Create the server
    try:
        with socketserver.TCPServer(("", actual_port), CORSRequestHandler) as httpd:
            print(f"🚀 Solana Development Web Interface Server")
            print(f"📂 Serving files from: {WEB_DIR}")
            print(f"🌐 Server running at: http://localhost:{actual_port}")
            print(f"")
            print(f"Available interfaces:")
            print(f"  • Chat Interface:  http://localhost:{actual_port}/solana-chat.html")
            print(f"  • Swarm Interface: http://localhost:{actual_port}/solana-swarm.html")
            print(f"")
            if actual_port != PORT:
                print(f"💡 Note: Port {PORT} was busy, using {actual_port} instead")
            print(f"Press Ctrl+C to stop the server")
            print(f"{'='*60}")
            
            try:
                httpd.serve_forever()
            except KeyboardInterrupt:
                print(f"\n👋 Server stopped!")
    except OSError as e:
        print(f"❌ Failed to start server: {e}")
        print(f"💡 Try running: netstat -ano | findstr :{actual_port}")
        sys.exit(1)

if __name__ == "__main__":
    main()
