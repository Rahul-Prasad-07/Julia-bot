/**
 * YieldSwarm API Client
 * Handles all communication with the JuliaOS backend
 */

class YieldSwarmAPI {
    constructor() {
        this.baseURL = '/api';
        this.agentId = null;
        this.requestTimeout = 30000; // 30 seconds
    }

    /**
     * Make HTTP request with error handling
     */
    async request(endpoint, options = {}) {
        const url = `${this.baseURL}${endpoint}`;
        const config = {
            headers: {
                'Content-Type': 'application/json',
                ...options.headers
            },
            timeout: this.requestTimeout,
            ...options
        };

        try {
            const response = await fetch(url, config);
            
            if (!response.ok) {
                const errorData = await response.json().catch(() => ({}));
                throw new Error(errorData.error || `HTTP ${response.status}: ${response.statusText}`);
            }

            const data = await response.json();
            return data;
        } catch (error) {
            console.error(`API Request failed: ${endpoint}`, error);
            throw error;
        }
    }

    /**
     * Check backend server connectivity
     */
    async checkConnection() {
        try {
            await this.request('/agents');
            return true;
        } catch (error) {
            console.error('Backend connection failed:', error);
            return false;
        }
    }

    /**
     * Get list of all agents
     */
    async getAgents() {
        return await this.request('/agents');
    }

    /**
     * Get specific agent details
     */
    async getAgent(agentId) {
        return await this.request(`/agents/${agentId}`);
    }

    /**
     * Create YieldSwarm agent
     */
    async createAgent() {
        const agentConfig = {
            id: "yieldswarm-web-agent",
            name: "YieldSwarm Web Agent",
            description: "YieldSwarm DeFi yield optimization agent for web interface",
            blueprint: {
                tools: [
                    { name: "yieldswarm_analyzer", config: {} },
                    { name: "yieldswarm_executor", config: {} },
                    { name: "yieldswarm_risk_manager", config: {} }
                ],
                strategy: {
                    name: "yieldswarm",
                    config: {
                        name: "yieldswarm-web-agent",
                        swarm_id: "yieldswarm-web-001",
                        agent_role: "coordinator",
                        coordination_endpoint: "http://127.0.0.1:8052/api/v1",
                        max_coordination_rounds: 10,
                        consensus_threshold: 0.75,
                        agent_timeout_seconds: 30,
                        default_risk_tolerance: "medium",
                        min_portfolio_value_usd: 1000.0,
                        max_portfolio_value_usd: 1000000.0,
                        supported_chains: ["ethereum", "solana", "polygon", "avalanche"],
                        enable_performance_tracking: true,
                        benchmark_comparison: true,
                        risk_adjusted_metrics: true
                    }
                },
                trigger: {
                    type: "webhook",
                    params: {}
                }
            }
        };

        try {
            // Try to delete existing agent first
            try {
                await this.request(`/agents/${agentConfig.id}`, { method: 'DELETE' });
            } catch (e) {
                // Ignore if agent doesn't exist
            }

            // Create new agent
            const agent = await this.request('/agents', {
                method: 'POST',
                body: JSON.stringify(agentConfig)
            });

            this.agentId = agent.id;
            return agent;
        } catch (error) {
            console.error('Failed to create agent:', error);
            throw error;
        }
    }

    /**
     * Start agent
     */
    async startAgent(agentId) {
        return await this.request(`/agents/${agentId}`, {
            method: 'PUT',
            body: JSON.stringify({ state: "RUNNING" })
        });
    }

    /**
     * Stop agent
     */
    async stopAgent(agentId) {
        return await this.request(`/agents/${agentId}`, {
            method: 'PUT',
            body: JSON.stringify({ state: "STOPPED" })
        });
    }

    /**
     * Delete agent
     */
    async deleteAgent(agentId) {
        return await this.request(`/agents/${agentId}`, {
            method: 'DELETE'
        });
    }

    /**
     * Send query to YieldSwarm agent
     */
    async queryAgent(agentId, payload) {
        return await this.request(`/agents/${agentId}/webhook`, {
            method: 'POST',
            body: JSON.stringify(payload)
        });
    }

    /**
     * Analyze portfolio yield opportunities
     */
    async analyzeYield(portfolioData, riskPreferences, marketContext = {}) {
        if (!this.agentId) {
            throw new Error('Agent not initialized. Please create an agent first.');
        }

        const payload = {
            user_query: this.buildAnalysisQuery(portfolioData, riskPreferences),
            portfolio_data: portfolioData,
            market_context: {
                current_market: "bull", // This could be dynamic
                volatility: "medium",
                timestamp: Date.now(),
                ...marketContext
            },
            risk_preferences: riskPreferences,
            execution_mode: "analyze",
            coordination_required: true
        };

        return await this.queryAgent(this.agentId, payload);
    }

    /**
     * Execute yield farming strategy
     */
    async executeStrategy(portfolioData, strategyConfig, executionMode = "simulate") {
        if (!this.agentId) {
            throw new Error('Agent not initialized. Please create an agent first.');
        }

        const payload = {
            user_query: this.buildExecutionQuery(strategyConfig),
            portfolio_data: portfolioData,
            market_context: {
                current_market: "bull",
                volatility: "medium",
                timestamp: Date.now()
            },
            risk_preferences: strategyConfig.riskPreferences || {},
            execution_mode: executionMode, // "analyze", "simulate", or "execute"
            coordination_required: true
        };

        return await this.queryAgent(this.agentId, payload);
    }

    /**
     * Get risk assessment for portfolio
     */
    async assessRisk(portfolioData, riskPreferences = {}) {
        if (!this.agentId) {
            throw new Error('Agent not initialized. Please create an agent first.');
        }

        const payload = {
            user_query: "Provide comprehensive risk assessment for my portfolio. Include VaR calculations, impermanent loss analysis, and protocol-specific risks.",
            portfolio_data: portfolioData,
            market_context: {
                current_market: "bull",
                volatility: "medium",
                timestamp: Date.now()
            },
            risk_preferences: {
                risk_tolerance: "medium",
                ...riskPreferences
            },
            execution_mode: "analyze",
            coordination_required: true
        };

        return await this.queryAgent(this.agentId, payload);
    }

    /**
     * Get available strategies
     */
    async getStrategies() {
        return await this.request('/strategies');
    }

    /**
     * Get available tools
     */
    async getTools() {
        return await this.request('/tools');
    }

    /**
     * Build analysis query based on portfolio and preferences
     */
    buildAnalysisQuery(portfolioData, riskPreferences) {
        const totalValue = portfolioData.total_value || 0;
        const riskLevel = riskPreferences.risk_tolerance || "medium";
        const chains = portfolioData.target_chains || ["ethereum"];
        
        let query = `Analyze yield opportunities for a $${totalValue.toLocaleString()} portfolio with ${riskLevel} risk tolerance. `;
        
        if (portfolioData.assets) {
            const assetsList = Object.keys(portfolioData.assets).join(", ");
            query += `Current assets include: ${assetsList}. `;
        }
        
        query += `Focus on ${chains.join(", ")} chains. `;
        
        if (riskPreferences.min_apy_threshold) {
            query += `Target minimum APY of ${riskPreferences.min_apy_threshold}%. `;
        }
        
        query += "Provide specific protocol recommendations with APY rates, risk assessments, and position sizing suggestions.";
        
        return query;
    }

    /**
     * Build execution query based on strategy config
     */
    buildExecutionQuery(strategyConfig) {
        let query = `Execute ${strategyConfig.type || 'balanced'} yield farming strategy. `;
        
        if (strategyConfig.protocols) {
            query += `Focus on ${strategyConfig.protocols.join(", ")} protocols. `;
        }
        
        if (strategyConfig.maxSlippage) {
            query += `Maximum slippage tolerance: ${strategyConfig.maxSlippage}%. `;
        }
        
        if (strategyConfig.timeframe) {
            query += `Execution timeframe: ${strategyConfig.timeframe}. `;
        }
        
        query += "Provide detailed execution plan with transaction sequences, gas estimates, and risk mitigation measures.";
        
        return query;
    }

    /**
     * Parse response from YieldSwarm agent
     */
    parseResponse(response) {
        if (!response || typeof response !== 'object') {
            return {
                success: false,
                message: "Invalid response format",
                analysis: null,
                riskAssessment: null
            };
        }

        const result = {
            success: response.success || false,
            message: response.message || "No message provided",
            coordinationRounds: response.coordination_rounds || 0,
            consensusAchieved: response.consensus_achieved || false,
            analysis: null,
            riskAssessment: null
        };

        // Parse swarm results
        if (response.swarm_results) {
            if (response.swarm_results.analysis) {
                result.analysis = {
                    success: response.swarm_results.analysis.success,
                    message: response.swarm_results.analysis.message,
                    agentRole: response.swarm_results.analysis.agent_role
                };
            }
            
            if (response.swarm_results.risk_assessment) {
                result.riskAssessment = {
                    success: response.swarm_results.risk_assessment.success,
                    message: response.swarm_results.risk_assessment.message,
                    agentRole: response.swarm_results.risk_assessment.agent_role
                };
            }
        }

        return result;
    }

    /**
     * Extract protocol recommendations from analysis
     */
    extractProtocolRecommendations(analysisMessage) {
        const protocols = [];
        
        // Parse protocol information from the message
        // This is a simplified parser - in production, you might want more sophisticated parsing
        const lines = analysisMessage.split('\n');
        let currentProtocol = null;
        
        lines.forEach(line => {
            // Look for protocol names (patterns like "Uniswap V3", "Raydium", etc.)
            const protocolMatch = line.match(/\*\*(.*?)\*\*/);
            if (protocolMatch) {
                const protocolName = protocolMatch[1];
                if (protocolName.includes('Uniswap') || protocolName.includes('Raydium') || 
                    protocolName.includes('Aave') || protocolName.includes('Compound')) {
                    currentProtocol = {
                        name: protocolName,
                        apy: 0,
                        risk: 'Unknown',
                        details: []
                    };
                    protocols.push(currentProtocol);
                }
            }
            
            // Look for APY information
            const apyMatch = line.match(/(\d+\.?\d*)%\s*(APY|APR)/i);
            if (apyMatch && currentProtocol) {
                currentProtocol.apy = parseFloat(apyMatch[1]);
            }
            
            // Look for risk information
            const riskMatch = line.match(/Risk\s*Score:\s*(\d+)\/10/i);
            if (riskMatch && currentProtocol) {
                currentProtocol.riskScore = parseInt(riskMatch[1]);
            }
            
            // Collect additional details
            if (currentProtocol && line.trim() && !line.includes('**')) {
                currentProtocol.details.push(line.trim());
            }
        });
        
        return protocols;
    }

    /**
     * Extract risk metrics from risk assessment
     */
    extractRiskMetrics(riskMessage) {
        const metrics = {
            overallRisk: 0,
            smartContractRisk: 0,
            liquidityRisk: 0,
            marketRisk: 0,
            impermanentLossRisk: 0
        };
        
        // Parse risk scores from the message
        const riskMatches = riskMessage.match(/Risk Score:\s*(\d+(?:\.\d+)?)\/10/gi) || [];
        
        riskMatches.forEach((match, index) => {
            const score = parseFloat(match.match(/(\d+(?:\.\d+)?)/)[1]);
            switch (index) {
                case 0:
                    metrics.overallRisk = score;
                    break;
                case 1:
                    metrics.smartContractRisk = score;
                    break;
                case 2:
                    metrics.liquidityRisk = score;
                    break;
                case 3:
                    metrics.marketRisk = score;
                    break;
            }
        });
        
        return metrics;
    }

    /**
     * Format currency values
     */
    formatCurrency(value, currency = 'USD') {
        return new Intl.NumberFormat('en-US', {
            style: 'currency',
            currency: currency,
            minimumFractionDigits: 2,
            maximumFractionDigits: 2
        }).format(value);
    }

    /**
     * Format percentage values
     */
    formatPercentage(value, decimals = 2) {
        return `${value.toFixed(decimals)}%`;
    }
}

// Export for use in other modules
window.YieldSwarmAPI = YieldSwarmAPI;
