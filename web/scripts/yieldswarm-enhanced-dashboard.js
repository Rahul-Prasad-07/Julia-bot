/**
 * Enhanced YieldSwarm Dashboard UI Controller
 * Manages all dashboard interactions and live data updates
 */

class YieldSwarmDashboard {
    constructor() {
        this.api = window.yieldswarmAPI;
        this.isInitialized = false;
        this.updateInterval = null;
        this.autoRefreshEnabled = true;
        this.refreshIntervalMs = 30000; // 30 seconds
        this.currentAgent = null;
        this.notifications = [];
    }

    async init() {
        if (this.isInitialized) return;

        console.log('🚀 Initializing YieldSwarm Dashboard...');

        // Check connection
        await this.checkConnection();

        // Initialize UI components
        this.initializeElements();
        this.bindEventListeners();

        // Load initial data
        await this.loadInitialData();

        // Start auto-refresh
        this.startAutoRefresh();

        this.isInitialized = true;
        this.showNotification('Dashboard initialized successfully!', 'success');

        console.log('✅ YieldSwarm Dashboard ready!');
    }

    initializeElements() {
        // Main elements
        this.elements = {
            // Header
            connectionStatus: document.getElementById('connectionStatus'),
            dataFreshness: document.getElementById('dataFreshness'),

            // Stats
            totalPortfolioValue: document.getElementById('totalPortfolioValue'),
            currentAPY: document.getElementById('currentAPY'),
            riskScore: document.getElementById('riskScore'),
            activeChains: document.getElementById('activeChains'),
            livePools: document.getElementById('livePools'),
            bestAPY: document.getElementById('bestAPY'),
            activeAgents: document.getElementById('activeAgents'),

            // Price ticker
            btcPrice: document.getElementById('btcPrice'),
            ethPrice: document.getElementById('ethPrice'),
            solPrice: document.getElementById('solPrice'),

            // Yield opportunities
            yieldOpportunitiesGrid: document.getElementById('yieldOpportunitiesGrid'),

            // Agents
            agentsGrid: document.getElementById('agentsGrid'),

            // Analysis
            portfolioValue: document.getElementById('portfolioValue'),
            riskTolerance: document.getElementById('riskTolerance'),
            analysisQuery: document.getElementById('analysisQuery'),
            analysisResults: document.getElementById('analysisResults'),
            resultsContent: document.getElementById('resultsContent'),

            // Buttons
            autoStartAgentsBtn: document.getElementById('autoStartAgentsBtn'),
            refreshAllDataBtn: document.getElementById('refreshAllDataBtn'),
            runAnalysisBtn: document.getElementById('runAnalysisBtn'),
            createNewAgentBtn: document.getElementById('createNewAgentBtn'),
            startAllAgentsBtn: document.getElementById('startAllAgentsBtn'),
            loadMoreOpportunities: document.getElementById('loadMoreOpportunities'),
            viewResultsBtn: document.getElementById('viewResultsBtn')
        };
    }

    bindEventListeners() {
        // Auto-start agents
        this.elements.autoStartAgentsBtn?.addEventListener('click', () => {
            this.autoStartAllAgents();
        });

        // Refresh all data
        this.elements.refreshAllDataBtn?.addEventListener('click', () => {
            this.refreshAllData();
        });

        // Run analysis
        this.elements.runAnalysisBtn?.addEventListener('click', () => {
            this.runAnalysis();
        });

        // Create new agent
        this.elements.createNewAgentBtn?.addEventListener('click', () => {
            this.createNewAgent();
        });

        // Start all agents
        this.elements.startAllAgentsBtn?.addEventListener('click', () => {
            this.startAllAgents();
        });

        // Load more opportunities
        this.elements.loadMoreOpportunities?.addEventListener('click', () => {
            this.loadMoreYieldOpportunities();
        });

        // View results
        this.elements.viewResultsBtn?.addEventListener('click', () => {
            this.toggleAnalysisResults();
        });
    }

    async checkConnection() {
        const isConnected = await this.api.checkConnection();
        this.updateConnectionStatus(isConnected);
        return isConnected;
    }

    updateConnectionStatus(isConnected) {
        const statusEl = this.elements.connectionStatus;
        if (!statusEl) return;

        const icon = statusEl.querySelector('i');
        const text = statusEl.querySelector('span');

        if (isConnected) {
            statusEl.className = 'connection-status connected';
            icon.className = 'fas fa-circle';
            text.textContent = 'Connected';
        } else {
            statusEl.className = 'connection-status disconnected';
            icon.className = 'fas fa-circle';
            text.textContent = 'Disconnected';
        }
    }

    async loadInitialData() {
        try {
            // Load in parallel for better performance
            await Promise.all([
                this.updateLivePrices(),
                this.updateYieldOpportunities(),
                this.updateAgents(),
                this.ensureDefaultAgent()
            ]);

            this.updateDataFreshness();
        } catch (error) {
            console.error('Failed to load initial data:', error);
            this.showNotification('Failed to load some data. Check connection.', 'error');
        }
    }

    async updateLivePrices() {
        try {
            const pricesResult = await this.api.getLivePrices();
            const prices = pricesResult.data;

            if (prices.bitcoin) {
                this.updatePriceTicker('btcPrice', 'BTC', prices.bitcoin);
            }
            if (prices.ethereum) {
                this.updatePriceTicker('ethPrice', 'ETH', prices.ethereum);
            }
            if (prices.solana) {
                this.updatePriceTicker('solPrice', 'SOL', prices.solana);
            }
        } catch (error) {
            console.error('Failed to update live prices:', error);
        }
    }

    updatePriceTicker(elementId, symbol, priceData) {
        const element = this.elements[elementId];
        if (!element) return;

        const priceEl = element.querySelector('.ticker-price');
        const changeEl = element.querySelector('.ticker-change');

        if (priceEl) {
            priceEl.textContent = this.api.formatCurrency(priceData.usd, 0);
        }

        if (changeEl && priceData.usd_24h_change !== undefined) {
            const change = priceData.usd_24h_change;
            changeEl.textContent = this.api.formatPercentage(change);
            changeEl.className = `ticker-change ${change >= 0 ? 'positive' : 'negative'}`;
        }
    }

    async updateYieldOpportunities() {
        try {
            const yieldResult = await this.api.getLiveYieldOpportunities(8);
            const opportunities = yieldResult.data;

            this.renderYieldOpportunities(opportunities);

            // Update stats
            if (this.elements.livePools) {
                this.elements.livePools.textContent = opportunities.length.toLocaleString();
            }

            if (this.elements.bestAPY && opportunities.length > 0) {
                const bestAPY = Math.max(...opportunities.map(o => o.apy));
                this.elements.bestAPY.textContent = this.api.formatPercentage(bestAPY);
            }
        } catch (error) {
            console.error('Failed to update yield opportunities:', error);
        }
    }

    renderYieldOpportunities(opportunities) {
        const grid = this.elements.yieldOpportunitiesGrid;
        if (!grid) return;

        if (opportunities.length === 0) {
            grid.innerHTML = `
                <div class="opportunity-card">
                    <p>No yield opportunities found. Check your connection.</p>
                </div>
            `;
            return;
        }

        grid.innerHTML = opportunities.map(opportunity => `
            <div class="opportunity-card">
                <div class="opportunity-header">
                    <div>
                        <div class="opportunity-protocol">${opportunity.project}</div>
                        <div class="opportunity-chain">${opportunity.chain}</div>
                    </div>
                    <div class="opportunity-apy">${this.api.formatPercentage(opportunity.apy)}</div>
                </div>
                <div class="opportunity-details">
                    <div class="opportunity-detail">
                        <span class="opportunity-detail-label">Pool:</span>
                        <span class="opportunity-detail-value">${opportunity.symbol}</span>
                    </div>
                    <div class="opportunity-detail">
                        <span class="opportunity-detail-label">TVL:</span>
                        <span class="opportunity-detail-value">${this.api.formatLargeNumber(opportunity.tvlUsd)}</span>
                    </div>
                    <div class="opportunity-detail">
                        <span class="opportunity-detail-label">Base APY:</span>
                        <span class="opportunity-detail-value">${this.api.formatPercentage(opportunity.apyBase || 0)}</span>
                    </div>
                    <div class="opportunity-detail">
                        <span class="opportunity-detail-label">Reward APY:</span>
                        <span class="opportunity-detail-value">${this.api.formatPercentage(opportunity.apyReward || 0)}</span>
                    </div>
                </div>
            </div>
        `).join('');
    }

    async updateAgents() {
        try {
            const agents = await this.api.getAgents();
            this.renderAgents(agents);

            // Update stats
            const runningAgents = agents.filter(a => a.state === 'RUNNING').length;
            if (this.elements.activeAgents) {
                this.elements.activeAgents.textContent = runningAgents;
            }
        } catch (error) {
            console.error('Failed to update agents:', error);
        }
    }

    renderAgents(agents) {
        const grid = this.elements.agentsGrid;
        if (!grid) return;

        if (agents.length === 0) {
            grid.innerHTML = `
                <div class="agent-card">
                    <p>No agents found. Create your first YieldSwarm agent!</p>
                </div>
            `;
            return;
        }

        grid.innerHTML = agents.map(agent => `
            <div class="agent-card ${agent.state.toLowerCase()}">
                <div class="agent-header">
                    <div>
                        <div class="agent-name">${agent.name}</div>
                        <div class="agent-id">${agent.id}</div>
                    </div>
                    <div class="agent-status ${agent.state.toLowerCase()}">
                        <i class="fas fa-circle"></i>
                        ${agent.state}
                    </div>
                </div>
                <div class="agent-metrics">
                    <div class="agent-metric">
                        <span class="agent-metric-label">Type:</span>
                        <span class="agent-metric-value">${agent.trigger_type}</span>
                    </div>
                    <div class="agent-metric">
                        <span class="agent-metric-label">Tools:</span>
                        <span class="agent-metric-value">${agent.blueprint?.tools?.length || 0}</span>
                    </div>
                </div>
                <div class="agent-actions">
                    <button class="btn btn-sm ${agent.state === 'RUNNING' ? 'btn-danger' : 'btn-success'}" 
                            onclick="dashboard.toggleAgent('${agent.id}', '${agent.state}')">
                        <i class="fas fa-${agent.state === 'RUNNING' ? 'stop' : 'play'}"></i>
                        ${agent.state === 'RUNNING' ? 'Stop' : 'Start'}
                    </button>
                    <button class="btn btn-sm btn-secondary" 
                            onclick="dashboard.analyzeWithAgent('${agent.id}')">
                        <i class="fas fa-brain"></i> Analyze
                    </button>
                </div>
            </div>
        `).join('');
    }

    async ensureDefaultAgent() {
        try {
            this.currentAgent = await this.api.ensureYieldSwarmAgent();
            this.showNotification(`Default agent ready: ${this.currentAgent.name}`, 'success');
        } catch (error) {
            console.error('Failed to ensure default agent:', error);
            this.showNotification('Failed to create default agent', 'error');
        }
    }

    async autoStartAllAgents() {
        this.showNotification('Starting all YieldSwarm agents...', 'info');

        try {
            const results = await this.api.autoStartAllAgents();
            const successful = results.filter(r => r.success).length;
            const total = results.length;

            this.showNotification(`Started ${successful}/${total} agents`, 'success');
            await this.updateAgents();
        } catch (error) {
            this.showNotification('Failed to start agents', 'error');
        }
    }

    async refreshAllData() {
        const btn = this.elements.refreshAllDataBtn;
        if (btn) {
            btn.disabled = true;
            btn.innerHTML = '<i class="fas fa-sync-alt spinning"></i> Refreshing...';
        }

        try {
            this.api.clearCache();
            await this.loadInitialData();
            this.showNotification('All data refreshed successfully!', 'success');
        } catch (error) {
            this.showNotification('Failed to refresh data', 'error');
        } finally {
            if (btn) {
                btn.disabled = false;
                btn.innerHTML = '<i class="fas fa-sync-alt"></i> Refresh Live Data';
            }
        }
    }

    async runAnalysis() {
        const btn = this.elements.runAnalysisBtn;
        if (btn) {
            btn.disabled = true;
            btn.innerHTML = '<i class="fas fa-spinner fa-spin"></i> Analyzing...';
        }

        try {
            if (!this.currentAgent) {
                await this.ensureDefaultAgent();
            }

            const query = this.elements.analysisQuery?.value || 'Analyze current yield opportunities';
            const portfolioValue = parseFloat(this.elements.portfolioValue?.value) || 25000;
            const riskTolerance = this.elements.riskTolerance?.value || 'medium';

            const portfolioData = {
                total_value: portfolioValue,
                current_allocation: { cash: portfolioValue },
                target_chains: this.getSelectedChains(),
                risk_preferences: {
                    risk_tolerance: riskTolerance,
                    min_apy_threshold: 3.0
                }
            };

            const result = await this.api.runAnalysis(this.currentAgent.id, query, portfolioData);

            if (result.success) {
                this.displayAnalysisResults(result.message);
                this.showNotification('Analysis completed successfully!', 'success');
            } else {
                throw new Error(result.error || 'Analysis failed');
            }
        } catch (error) {
            console.error('Analysis failed:', error);
            this.showNotification(`Analysis failed: ${error.message}`, 'error');
        } finally {
            if (btn) {
                btn.disabled = false;
                btn.innerHTML = '<i class="fas fa-robot"></i> Run Live Analysis';
            }
        }
    }

    displayAnalysisResults(message) {
        if (this.elements.resultsContent) {
            this.elements.resultsContent.innerHTML = `<pre>${message}</pre>`;
        }

        if (this.elements.viewResultsBtn) {
            this.elements.viewResultsBtn.disabled = false;
        }

        this.toggleAnalysisResults(true);
    }

    toggleAnalysisResults(show = null) {
        const results = this.elements.analysisResults;
        if (!results) return;

        if (show === null) {
            show = results.style.display === 'none';
        }

        results.style.display = show ? 'block' : 'none';

        if (this.elements.viewResultsBtn) {
            this.elements.viewResultsBtn.innerHTML = show
                ? '<i class="fas fa-eye-slash"></i> Hide Results'
                : '<i class="fas fa-eye"></i> View Results';
        }
    }

    getSelectedChains() {
        const checkboxes = document.querySelectorAll('input[type="checkbox"]');
        return Array.from(checkboxes)
            .filter(cb => cb.checked)
            .map(cb => cb.value);
    }

    async toggleAgent(agentId, currentState) {
        try {
            if (currentState === 'RUNNING') {
                await this.api.stopAgent(agentId);
                this.showNotification('Agent stopped', 'info');
            } else {
                await this.api.startAgent(agentId);
                this.showNotification('Agent started', 'success');
            }

            await this.updateAgents();
        } catch (error) {
            this.showNotification('Failed to toggle agent', 'error');
        }
    }

    async analyzeWithAgent(agentId) {
        try {
            const query = 'Provide a quick analysis of current yield opportunities with live data';
            const portfolioData = { total_value: 25000 };

            const result = await this.api.runAnalysis(agentId, query, portfolioData);

            if (result.success) {
                this.displayAnalysisResults(result.message);
                this.showNotification('Quick analysis completed!', 'success');
            } else {
                throw new Error(result.error);
            }
        } catch (error) {
            this.showNotification(`Analysis failed: ${error.message}`, 'error');
        }
    }

    async createNewAgent() {
        try {
            const agent = await this.api.createYieldSwarmAgent();
            this.showNotification(`Created new agent: ${agent.name}`, 'success');
            await this.updateAgents();
        } catch (error) {
            this.showNotification('Failed to create agent', 'error');
        }
    }

    async startAllAgents() {
        await this.autoStartAllAgents();
    }

    async loadMoreYieldOpportunities() {
        try {
            const yieldResult = await this.api.getLiveYieldOpportunities(20);
            this.renderYieldOpportunities(yieldResult.data);
            this.showNotification('Loaded more opportunities', 'info');
        } catch (error) {
            this.showNotification('Failed to load more opportunities', 'error');
        }
    }

    updateDataFreshness() {
        if (this.elements.dataFreshness) {
            const now = new Date();
            this.elements.dataFreshness.innerHTML = `
                <i class="fas fa-clock"></i> Data updated: ${now.toLocaleTimeString()}
            `;
        }
    }

    startAutoRefresh() {
        if (this.updateInterval) {
            clearInterval(this.updateInterval);
        }

        this.updateInterval = setInterval(() => {
            if (this.autoRefreshEnabled) {
                this.loadInitialData();
            }
        }, this.refreshIntervalMs);
    }

    showNotification(message, type = 'info') {
        console.log(`[${type.toUpperCase()}] ${message}`);

        // You can implement a more sophisticated notification system here
        const container = document.getElementById('notificationContainer');
        if (container) {
            const notification = document.createElement('div');
            notification.className = `notification notification-${type}`;
            notification.innerHTML = `
                <i class="fas fa-${type === 'success' ? 'check' : type === 'error' ? 'times' : 'info'}"></i>
                <span>${message}</span>
            `;

            container.appendChild(notification);

            setTimeout(() => {
                notification.remove();
            }, 5000);
        }
    }
}

// Global dashboard instance
window.dashboard = new YieldSwarmDashboard();

// Initialize when DOM is loaded
document.addEventListener('DOMContentLoaded', () => {
    window.dashboard.init();
});
