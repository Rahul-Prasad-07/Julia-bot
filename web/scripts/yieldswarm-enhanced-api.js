/**
 * Enhanced YieldSwarm API Integration
 * Handles live data fetching from DeFiLlama, CoinGecko, and backend agents
 */

class YieldSwarmAPI {
    constructor() {
        this.baseURL = 'http://127.0.0.1:8052/api/v1';
        this.defillama = 'https://yields.llama.fi';
        this.coingecko = 'https://api.coingecko.com/api/v3';
        this.cache = new Map();
        this.cacheTimeout = 5 * 60 * 1000; // 5 minutes
        this.agents = new Map();
        this.isConnected = false;
        this.lastDataUpdate = null;
    }

    // Connection management
    async checkConnection() {
        try {
            const response = await fetch(`${this.baseURL}/agents`);
            this.isConnected = response.ok;
            return this.isConnected;
        } catch (error) {
            console.error('Connection check failed:', error);
            this.isConnected = false;
            return false;
        }
    }

    // Live price data from CoinGecko
    async getLivePrices(tokens = ['bitcoin', 'ethereum', 'solana']) {
        const cacheKey = `prices_${tokens.join('_')}`;

        if (this.isCacheValid(cacheKey)) {
            return this.cache.get(cacheKey);
        }

        try {
            const tokenIds = tokens.join(',');
            const url = `${this.coingecko}/simple/price?ids=${tokenIds}&vs_currencies=usd&include_24hr_change=true&include_market_cap=true`;

            const response = await fetch(url);
            if (!response.ok) throw new Error(`HTTP ${response.status}`);

            const data = await response.json();
            this.cache.set(cacheKey, { data, timestamp: Date.now() });
            return { data, timestamp: Date.now() };
        } catch (error) {
            console.error('Failed to fetch live prices:', error);
            return { data: {}, timestamp: Date.now(), error: error.message };
        }
    }

    // Live yield opportunities from DeFiLlama
    async getLiveYieldOpportunities(limit = 20, chains = []) {
        const cacheKey = `yields_${limit}_${chains.join('_')}`;

        if (this.isCacheValid(cacheKey)) {
            return this.cache.get(cacheKey);
        }

        try {
            const response = await fetch(`${this.defillama}/pools`);
            if (!response.ok) throw new Error(`HTTP ${response.status}`);

            const data = await response.json();
            let pools = data.data || [];

            // Filter by chains if specified
            if (chains.length > 0) {
                pools = pools.filter(pool =>
                    chains.includes(pool.chain?.toLowerCase())
                );
            }

            // Filter valid pools and sort by APY
            pools = pools
                .filter(pool => pool.apy > 0 && pool.tvlUsd > 100000) // Min $100k TVL
                .sort((a, b) => b.apy - a.apy)
                .slice(0, limit);

            const result = { data: pools, timestamp: Date.now() };
            this.cache.set(cacheKey, result);
            return result;
        } catch (error) {
            console.error('Failed to fetch yield opportunities:', error);
            return { data: [], timestamp: Date.now(), error: error.message };
        }
    }

    // Get all agents
    async getAgents() {
        try {
            const response = await fetch(`${this.baseURL}/agents`);
            if (!response.ok) throw new Error(`HTTP ${response.status}`);

            const agents = await response.json();
            // Update local agents map
            agents.forEach(agent => {
                this.agents.set(agent.id, agent);
            });

            return agents;
        } catch (error) {
            console.error('Failed to fetch agents:', error);
            return [];
        }
    }

    // Create YieldSwarm agent
    async createYieldSwarmAgent(config = {}) {
        const defaultConfig = {
            id: `yieldswarm-auto-${Date.now()}`,
            name: 'YieldSwarm Auto Agent',
            description: 'Auto-created YieldSwarm agent with real-time data capabilities',
            blueprint: {
                tools: [
                    { name: 'yieldswarm_data_fetcher', config: {} },
                    { name: 'yieldswarm_analyzer', config: { ai_provider: 'groq' } },
                    { name: 'yieldswarm_risk_manager', config: {} }
                ],
                strategy: {
                    name: 'yieldswarm',
                    config: {
                        name: 'auto-yieldswarm',
                        swarm_id: `swarm-${Date.now()}`,
                        agent_role: 'coordinator',
                        supported_chains: ['ethereum', 'solana', 'polygon', 'avalanche']
                    }
                },
                trigger: { type: 'webhook', params: {} }
            }
        };

        const agentConfig = { ...defaultConfig, ...config };

        try {
            const response = await fetch(`${this.baseURL}/agents`, {
                method: 'POST',
                headers: { 'Content-Type': 'application/json' },
                body: JSON.stringify(agentConfig)
            });

            if (!response.ok) {
                const errorText = await response.text();
                throw new Error(`HTTP ${response.status}: ${errorText}`);
            }

            const agent = await response.json();
            this.agents.set(agent.id, agent);
            return agent;
        } catch (error) {
            console.error('Failed to create agent:', error);
            throw error;
        }
    }

    // Start agent
    async startAgent(agentId) {
        try {
            const response = await fetch(`${this.baseURL}/agents/${agentId}`, {
                method: 'PUT',
                headers: { 'Content-Type': 'application/json' },
                body: JSON.stringify({ state: 'RUNNING' })
            });

            if (!response.ok) throw new Error(`HTTP ${response.status}`);

            const agent = await response.json();
            this.agents.set(agent.id, agent);
            return agent;
        } catch (error) {
            console.error(`Failed to start agent ${agentId}:`, error);
            throw error;
        }
    }

    // Stop agent
    async stopAgent(agentId) {
        try {
            const response = await fetch(`${this.baseURL}/agents/${agentId}`, {
                method: 'PUT',
                headers: { 'Content-Type': 'application/json' },
                body: JSON.stringify({ state: 'STOPPED' })
            });

            if (!response.ok) throw new Error(`HTTP ${response.status}`);

            const agent = await response.json();
            this.agents.set(agent.id, agent);
            return agent;
        } catch (error) {
            console.error(`Failed to stop agent ${agentId}:`, error);
            throw error;
        }
    }

    // Run analysis with agent
    async runAnalysis(agentId, query, portfolioData = {}) {
        const payload = {
            user_query: query,
            portfolio_data: portfolioData,
            market_context: {
                analysis_type: 'live_yield_optimization',
                real_time_analysis: true,
                timestamp: Math.floor(Date.now() / 1000)
            },
            risk_preferences: portfolioData.risk_preferences || {
                risk_tolerance: 'medium',
                min_apy_threshold: 3.0
            },
            execution_mode: 'analyze',
            coordination_required: true
        };

        try {
            const response = await fetch(`${this.baseURL}/agents/${agentId}/webhook`, {
                method: 'POST',
                headers: { 'Content-Type': 'application/json' },
                body: JSON.stringify(payload)
            });

            if (!response.ok) {
                const errorText = await response.text();
                throw new Error(`HTTP ${response.status}: ${errorText}`);
            }

            return await response.json();
        } catch (error) {
            console.error('Analysis failed:', error);
            throw error;
        }
    }

    // Auto-start all YieldSwarm agents
    async autoStartAllAgents() {
        try {
            const agents = await this.getAgents();
            const yieldswarmAgents = agents.filter(agent =>
                agent.name.toLowerCase().includes('yieldswarm')
            );

            const results = [];
            for (const agent of yieldswarmAgents) {
                if (agent.state !== 'RUNNING') {
                    try {
                        const result = await this.startAgent(agent.id);
                        results.push({ success: true, agent: result });
                    } catch (error) {
                        results.push({ success: false, agent, error: error.message });
                    }
                }
            }

            return results;
        } catch (error) {
            console.error('Failed to auto-start agents:', error);
            return [];
        }
    }

    // Create default agent if none exist
    async ensureYieldSwarmAgent() {
        try {
            const agents = await this.getAgents();
            let yieldswarmAgent = agents.find(agent =>
                agent.name.toLowerCase().includes('yieldswarm')
            );

            if (!yieldswarmAgent) {
                console.log('No YieldSwarm agent found, creating one...');
                yieldswarmAgent = await this.createYieldSwarmAgent();
            }

            if (yieldswarmAgent.state !== 'RUNNING') {
                console.log('Starting YieldSwarm agent...');
                yieldswarmAgent = await this.startAgent(yieldswarmAgent.id);
            }

            return yieldswarmAgent;
        } catch (error) {
            console.error('Failed to ensure YieldSwarm agent:', error);
            throw error;
        }
    }

    // Cache management
    isCacheValid(key) {
        const cached = this.cache.get(key);
        if (!cached) return false;
        return Date.now() - cached.timestamp < this.cacheTimeout;
    }

    clearCache() {
        this.cache.clear();
    }

    // Format currency
    formatCurrency(amount, decimals = 2) {
        return new Intl.NumberFormat('en-US', {
            style: 'currency',
            currency: 'USD',
            minimumFractionDigits: decimals,
            maximumFractionDigits: decimals
        }).format(amount);
    }

    // Format percentage
    formatPercentage(value, decimals = 2) {
        return `${value.toFixed(decimals)}%`;
    }

    // Format large numbers
    formatLargeNumber(num) {
        if (num >= 1e9) return `$${(num / 1e9).toFixed(1)}B`;
        if (num >= 1e6) return `$${(num / 1e6).toFixed(1)}M`;
        if (num >= 1e3) return `$${(num / 1e3).toFixed(1)}K`;
        return `$${num.toFixed(0)}`;
    }
}

// Global API instance
window.yieldswarmAPI = new YieldSwarmAPI();
