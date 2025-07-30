#!/usr/bin/env python3
"""
YieldSwarm Production Web Server
Serves the YieldSwarm DeFi yield optimization frontend with real backend integration
"""

import http.server
import socketserver
import os
import sys
import socket
import json
import urllib.parse
import urllib.request
from pathlib import Path
import logging
from datetime import datetime

# Get the directory where this script is located
WEB_DIR = Path(__file__).parent
PORT = 3001

# JuliaOS Backend Configuration
BACKEND_URL = "http://127.0.0.1:8052/api/v1"

# Configure logging
logging.basicConfig(level=logging.INFO, format='%(asctime)s - %(levelname)s - %(message)s')
logger = logging.getLogger(__name__)

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

class YieldSwarmHandler(http.server.SimpleHTTPRequestHandler):
    """Enhanced request handler with YieldSwarm API proxy and CORS support"""
    
    def end_headers(self):
        # Add CORS headers
        self.send_header('Access-Control-Allow-Origin', '*')
        self.send_header('Access-Control-Allow-Methods', 'GET, POST, PUT, DELETE, OPTIONS')
        self.send_header('Access-Control-Allow-Headers', 'Content-Type, Authorization')
        super().end_headers()
    
    def do_OPTIONS(self):
        """Handle preflight requests"""
        self.send_response(200)
        self.send_header('Access-Control-Allow-Origin', '*')
        self.send_header('Access-Control-Allow-Methods', 'GET, POST, PUT, DELETE, OPTIONS')
        self.send_header('Access-Control-Allow-Headers', 'Content-Type, Authorization')
        self.end_headers()
    
    def do_POST(self):
        """Handle POST requests for YieldSwarm API calls"""
        if self.path.startswith('/api/'):
            self.handle_api_request()
        else:
            super().do_POST()
    
    def do_GET(self):
        """Handle GET requests with API proxy support"""
        if self.path.startswith('/api/'):
            self.handle_api_request()
        else:
            # Serve static files
            if self.path == '/':
                self.path = '/yieldswarm-dashboard.html'
            super().do_GET()
    
    def handle_api_request(self):
        """Proxy API requests to JuliaOS backend"""
        try:
            # Parse the request
            content_length = int(self.headers.get('Content-Length', 0))
            post_data = self.rfile.read(content_length) if content_length > 0 else b''
            
            # Construct backend URL
            backend_path = self.path.replace('/api/', '/')
            backend_url = f"{BACKEND_URL}{backend_path}"
            
            logger.info(f"Proxying {self.command} request to: {backend_url}")
            
            # Create request to backend
            req = urllib.request.Request(
                backend_url,
                data=post_data if post_data else None,
                headers={'Content-Type': 'application/json'}
            )
            req.get_method = lambda: self.command
            
            # Make request to backend
            with urllib.request.urlopen(req) as response:
                # Send response back to client
                self.send_response(response.getcode())
                self.send_header('Content-Type', 'application/json')
                self.end_headers()
                
                # Stream response data
                while True:
                    chunk = response.read(8192)
                    if not chunk:
                        break
                    self.wfile.write(chunk)
                    
        except urllib.error.HTTPError as e:
            logger.error(f"Backend HTTP error: {e.code} - {e.reason}")
            self.send_response(e.code)
            self.send_header('Content-Type', 'application/json')
            self.end_headers()
            error_response = json.dumps({
                "error": f"Backend error: {e.reason}",
                "code": e.code
            })
            self.wfile.write(error_response.encode())
            
        except Exception as e:
            logger.error(f"API proxy error: {e}")
            self.send_response(500)
            self.send_header('Content-Type', 'application/json')
            self.end_headers()
            error_response = json.dumps({
                "error": f"Server error: {str(e)}",
                "code": 500
            })
            self.wfile.write(error_response.encode())

def check_backend_connection():
    """Check if JuliaOS backend is accessible"""
    try:
        req = urllib.request.Request(f"{BACKEND_URL}/agents")
        with urllib.request.urlopen(req, timeout=5) as response:
            if response.getcode() == 200:
                logger.info("✅ JuliaOS backend is accessible")
                return True
    except Exception as e:
        logger.error(f"❌ Cannot connect to JuliaOS backend: {e}")
        logger.error(f"Make sure JuliaOS backend is running on {BACKEND_URL}")
        return False
    return False

def main():
    """Start the YieldSwarm web server"""
    logger.info("🚀 Starting YieldSwarm Production Web Server")
    
    # Check backend connection
    if not check_backend_connection():
        logger.warning("⚠️  Backend not accessible - some features may not work")
    
    # Change to the web directory
    os.chdir(WEB_DIR)
    
    # Find a free port
    try:
        port = find_free_port(PORT)
        logger.info(f"Using port: {port}")
    except OSError as e:
        logger.error(f"Port error: {e}")
        sys.exit(1)
    
    # Create and start server
    try:
        with socketserver.TCPServer(("", port), YieldSwarmHandler) as httpd:
            logger.info(f"🌐 YieldSwarm Dashboard available at:")
            logger.info(f"   http://localhost:{port}")
            logger.info(f"   http://127.0.0.1:{port}")
            logger.info("📊 Features available:")
            logger.info("   • Portfolio Analysis & Optimization")
            logger.info("   • Cross-Chain Yield Farming")
            logger.info("   • Risk Assessment & Management")
            logger.info("   • Real-time Strategy Execution")
            logger.info("🛑 Press Ctrl+C to stop the server")
            
            httpd.serve_forever()
            
    except KeyboardInterrupt:
        logger.info("\n🛑 Server stopped by user")
    except Exception as e:
        logger.error(f"Server error: {e}")
        sys.exit(1)

if __name__ == "__main__":
    main()
