/**
 * YieldSwarm Main Application
 * Initializes and coordinates the entire YieldSwarm frontend
 */

class YieldSwarmApp {
    constructor() {
        this.api = null;
        this.ui = null;
        this.connectionCheckInterval = null;
        this.isInitialized = false;
    }

    /**
     * Initialize the application
     */
    async init() {
        console.log('🚀 Initializing YieldSwarm Application');
        
        try {
            // Initialize API client
            this.api = new YieldSwarmAPI();
            
            // Initialize UI
            this.ui = new YieldSwarmUI(this.api);
            
            // Make UI available globally for event handlers
            window.ui = this.ui;
            
            // Check initial connection
            await this.checkConnection();
            
            // Start periodic connection monitoring
            this.startConnectionMonitoring();
            
            // Load initial data
            await this.loadInitialData();
            
            this.isInitialized = true;
            console.log('✅ YieldSwarm Application initialized successfully');
            
            // Show welcome notification
            this.ui.showNotification('YieldSwarm Dashboard loaded successfully!', 'success');
            
        } catch (error) {
            console.error('❌ Failed to initialize YieldSwarm Application:', error);
            this.ui?.showNotification('Failed to initialize application. Please check backend connection.', 'error');
        }
    }

    /**
     * Check backend connection
     */
    async checkConnection() {
        try {
            const connected = await this.api.checkConnection();
            this.ui.updateConnectionStatus(connected);
            
            if (connected) {
                console.log('✅ Backend connection established');
                await this.checkExistingAgent();
            } else {
                console.warn('⚠️ Backend connection failed');
            }
            
            return connected;
        } catch (error) {
            console.error('Connection check failed:', error);
            this.ui.updateConnectionStatus(false);
            return false;
        }
    }

    /**
     * Check for existing YieldSwarm agent
     */
    async checkExistingAgent() {
        try {
            const agents = await this.api.getAgents();
            const yieldswarmAgent = agents.find(agent => 
                agent.id === 'yieldswarm-web-agent' || 
                agent.name.includes('YieldSwarm')
            );
            
            if (yieldswarmAgent) {
                console.log('Found existing YieldSwarm agent:', yieldswarmAgent.id);
                this.ui.currentAgent = yieldswarmAgent;
                this.api.agentId = yieldswarmAgent.id;
                
                // Update UI
                document.getElementById('agentName').textContent = yieldswarmAgent.name;
                document.getElementById('agentId').textContent = yieldswarmAgent.id;
                this.ui.updateAgentStatus(yieldswarmAgent.state);
                
                // Update button states
                document.getElementById('createAgentBtn').disabled = true;
                
                if (yieldswarmAgent.state === 'RUNNING') {
                    document.getElementById('startAgentBtn').disabled = true;
                    document.getElementById('stopAgentBtn').disabled = false;
                } else {
                    document.getElementById('startAgentBtn').disabled = false;
                    document.getElementById('stopAgentBtn').disabled = true;
                }
                
                this.ui.showNotification(`Connected to existing agent: ${yieldswarmAgent.id}`, 'info');
            }
        } catch (error) {
            console.error('Failed to check existing agents:', error);
        }
    }

    /**
     * Start connection monitoring
     */
    startConnectionMonitoring() {
        // Check connection every 30 seconds
        this.connectionCheckInterval = setInterval(async () => {
            await this.checkConnection();
        }, 30000);
    }

    /**
     * Stop connection monitoring
     */
    stopConnectionMonitoring() {
        if (this.connectionCheckInterval) {
            clearInterval(this.connectionCheckInterval);
            this.connectionCheckInterval = null;
        }
    }

    /**
     * Load initial data
     */
    async loadInitialData() {
        try {
            // Check available strategies
            const strategies = await this.api.getStrategies();
            console.log('Available strategies:', strategies.map(s => s.name));
            
            // Check available tools
            const tools = await this.api.getTools();
            const yieldswarmTools = tools.filter(tool => tool.name.startsWith('yieldswarm_'));
            console.log('YieldSwarm tools:', yieldswarmTools.map(t => t.name));
            
            // Update UI with tool availability
            if (yieldswarmTools.length === 3) {
                console.log('✅ All YieldSwarm tools are available');
            } else {
                console.warn('⚠️ Some YieldSwarm tools may be missing');
                this.ui.showNotification('Some YieldSwarm tools may be unavailable', 'warning');
            }
            
        } catch (error) {
            console.error('Failed to load initial data:', error);
        }
    }

    /**
     * Handle application errors
     */
    handleError(error, context = 'Application') {
        console.error(`${context} Error:`, error);
        
        let userMessage = 'An unexpected error occurred.';
        
        if (error.message.includes('Failed to fetch')) {
            userMessage = 'Unable to connect to backend server. Please check if the server is running.';
        } else if (error.message.includes('Agent not initialized')) {
            userMessage = 'Please create and start an agent first.';
        } else if (error.message.includes('timeout')) {
            userMessage = 'Request timed out. Please try again.';
        } else {
            userMessage = error.message || userMessage;
        }
        
        this.ui.showNotification(userMessage, 'error');
    }

    /**
     * Cleanup resources
     */
    cleanup() {
        console.log('🧹 Cleaning up YieldSwarm Application');
        
        this.stopConnectionMonitoring();
        
        // Additional cleanup if needed
        this.isInitialized = false;
    }

    /**
     * Get application status
     */
    getStatus() {
        return {
            initialized: this.isInitialized,
            connected: this.ui?.connectionStatus || false,
            agent: this.ui?.currentAgent || null,
            portfolioAssets: this.ui?.portfolioAssets?.size || 0
        };
    }
}

// Global application instance
let app = null;

/**
 * Initialize application when DOM is loaded
 */
document.addEventListener('DOMContentLoaded', async () => {
    console.log('🌐 DOM loaded, initializing YieldSwarm App');
    
    try {
        app = new YieldSwarmApp();
        await app.init();
    } catch (error) {
        console.error('Failed to initialize app:', error);
        
        // Show basic error message
        const container = document.getElementById('notificationContainer');
        if (container) {
            const notification = document.createElement('div');
            notification.className = 'notification error';
            notification.innerHTML = `
                <div class="notification-content">
                    <span>Failed to initialize YieldSwarm. Please refresh the page and ensure the backend is running.</span>
                </div>
            `;
            container.appendChild(notification);
        }
    }
});

/**
 * Handle page unload
 */
window.addEventListener('beforeunload', () => {
    if (app) {
        app.cleanup();
    }
});

/**
 * Handle uncaught errors
 */
window.addEventListener('error', (event) => {
    console.error('Uncaught error:', event.error);
    if (app) {
        app.handleError(event.error, 'Global');
    }
});

/**
 * Handle unhandled promise rejections
 */
window.addEventListener('unhandledrejection', (event) => {
    console.error('Unhandled promise rejection:', event.reason);
    if (app) {
        app.handleError(event.reason, 'Promise');
    }
});

// Export for debugging and testing
window.YieldSwarmApp = YieldSwarmApp;
window.app = app;
