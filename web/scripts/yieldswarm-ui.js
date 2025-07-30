/**
 * YieldSwarm UI Components
 * Handles all UI interactions and updates
 */

class YieldSwarmUI {
    constructor(api) {
        this.api = api;
        this.portfolioAssets = new Map();
        this.currentAgent = null;
        this.notifications = [];
        
        this.initializeEventListeners();
        this.initializeNavigation();
    }

    /**
     * Initialize event listeners
     */
    initializeEventListeners() {
        // Agent management buttons
        document.getElementById('createAgentBtn').addEventListener('click', () => this.createAgent());
        document.getElementById('startAgentBtn').addEventListener('click', () => this.startAgent());
        document.getElementById('stopAgentBtn').addEventListener('click', () => this.stopAgent());

        // Analysis form
        document.getElementById('runAnalysisBtn').addEventListener('click', () => this.runAnalysis());
        document.getElementById('clearFormBtn').addEventListener('click', () => this.clearAnalysisForm());

        // Portfolio management
        document.getElementById('addAssetBtn').addEventListener('click', () => this.addAsset());

        // Strategy execution
        document.getElementById('executeStrategyBtn').addEventListener('click', () => this.executeStrategy());
        document.getElementById('simulateStrategyBtn').addEventListener('click', () => this.simulateStrategy());

        // Strategy templates
        document.querySelectorAll('.template-btn').forEach(btn => {
            btn.addEventListener('click', (e) => {
                const strategy = e.target.closest('.template-card').dataset.strategy;
                this.useStrategyTemplate(strategy);
            });
        });

        // Modal controls
        document.getElementById('modalCloseBtn').addEventListener('click', () => this.closeModal());
        document.getElementById('modalCloseFooterBtn').addEventListener('click', () => this.closeModal());
        document.getElementById('saveResultsBtn').addEventListener('click', () => this.saveResults());

        // Form inputs
        document.getElementById('portfolioValue').addEventListener('input', () => this.updatePortfolioStats());
        document.getElementById('assetValue').addEventListener('input', () => this.calculateAssetAmount());
        document.getElementById('assetAmount').addEventListener('input', () => this.calculateAssetValue());
    }

    /**
     * Initialize navigation
     */
    initializeNavigation() {
        document.querySelectorAll('.nav-link').forEach(link => {
            link.addEventListener('click', (e) => {
                e.preventDefault();
                const target = link.getAttribute('href').substring(1);
                this.showSection(target);
                
                // Update active nav link
                document.querySelectorAll('.nav-link').forEach(l => l.classList.remove('active'));
                link.classList.add('active');
            });
        });
    }

    /**
     * Show specific section
     */
    showSection(sectionId) {
        document.querySelectorAll('.section').forEach(section => {
            section.classList.remove('active');
        });
        
        const targetSection = document.getElementById(sectionId);
        if (targetSection) {
            targetSection.classList.add('active');
        }
    }

    /**
     * Update connection status
     */
    updateConnectionStatus(connected) {
        const statusElement = document.getElementById('connectionStatus');
        const icon = statusElement.querySelector('i');
        const text = statusElement.querySelector('span');
        
        if (connected) {
            statusElement.className = 'connection-status connected';
            text.textContent = 'Connected';
        } else {
            statusElement.className = 'connection-status disconnected';
            text.textContent = 'Disconnected';
        }
    }

    /**
     * Create YieldSwarm agent
     */
    async createAgent() {
        try {
            this.showNotification('Creating YieldSwarm agent...', 'info');
            this.setButtonLoading('createAgentBtn', true);

            const agent = await this.api.createAgent();
            this.currentAgent = agent;
            
            // Update UI
            document.getElementById('agentName').textContent = agent.name;
            document.getElementById('agentId').textContent = agent.id;
            this.updateAgentStatus(agent.state || 'CREATED');
            
            // Enable start button
            document.getElementById('startAgentBtn').disabled = false;
            document.getElementById('createAgentBtn').disabled = true;
            
            this.showNotification('Agent created successfully!', 'success');
        } catch (error) {
            console.error('Failed to create agent:', error);
            this.showNotification(`Failed to create agent: ${error.message}`, 'error');
        } finally {
            this.setButtonLoading('createAgentBtn', false);
        }
    }

    /**
     * Start agent
     */
    async startAgent() {
        if (!this.currentAgent) return;

        try {
            this.setButtonLoading('startAgentBtn', true);
            await this.api.startAgent(this.currentAgent.id);
            
            this.updateAgentStatus('RUNNING');
            document.getElementById('startAgentBtn').disabled = true;
            document.getElementById('stopAgentBtn').disabled = false;
            
            this.showNotification('Agent started successfully!', 'success');
        } catch (error) {
            console.error('Failed to start agent:', error);
            this.showNotification(`Failed to start agent: ${error.message}`, 'error');
        } finally {
            this.setButtonLoading('startAgentBtn', false);
        }
    }

    /**
     * Stop agent
     */
    async stopAgent() {
        if (!this.currentAgent) return;

        try {
            this.setButtonLoading('stopAgentBtn', true);
            await this.api.stopAgent(this.currentAgent.id);
            
            this.updateAgentStatus('STOPPED');
            document.getElementById('startAgentBtn').disabled = false;
            document.getElementById('stopAgentBtn').disabled = true;
            
            this.showNotification('Agent stopped successfully!', 'warning');
        } catch (error) {
            console.error('Failed to stop agent:', error);
            this.showNotification(`Failed to stop agent: ${error.message}`, 'error');
        } finally {
            this.setButtonLoading('stopAgentBtn', false);
        }
    }

    /**
     * Update agent status display
     */
    updateAgentStatus(status) {
        const statusDot = document.getElementById('agentStatusDot');
        const statusText = document.getElementById('agentStatusText');
        
        statusDot.className = 'status-dot';
        
        switch (status.toUpperCase()) {
            case 'RUNNING':
                statusDot.classList.add('running');
                statusText.textContent = 'Running';
                break;
            case 'STOPPED':
                statusDot.classList.add('stopped');
                statusText.textContent = 'Stopped';
                break;
            case 'ERROR':
                statusDot.classList.add('error');
                statusText.textContent = 'Error';
                break;
            default:
                statusText.textContent = status;
        }
    }

    /**
     * Run portfolio analysis
     */
    async runAnalysis() {
        try {
            if (!this.currentAgent) {
                this.showNotification('Please create and start an agent first', 'warning');
                return;
            }

            this.setButtonLoading('runAnalysisBtn', true);
            this.showModal('Analysis Results', true); // Show loading modal

            // Collect form data
            const portfolioValue = parseFloat(document.getElementById('portfolioValue').value) || 50000;
            const riskTolerance = document.getElementById('riskTolerance').value;
            const analysisQuery = document.getElementById('analysisQuery').value;
            const targetChains = this.getSelectedChains();

            // Build portfolio data
            const portfolioData = {
                total_value: portfolioValue,
                assets: this.getPortfolioAssetsData(),
                target_chains: targetChains
            };

            // Build risk preferences
            const riskPreferences = {
                risk_tolerance: riskTolerance,
                max_slippage: 0.5,
                min_apy_threshold: this.getMinAPYThreshold(riskTolerance)
            };

            // Run analysis
            const response = await this.api.analyzeYield(portfolioData, riskPreferences);
            const parsedResponse = this.api.parseResponse(response);

            // Display results
            this.displayAnalysisResults(parsedResponse);
            this.updateCoordinationMetrics(parsedResponse);
            
            this.showNotification('Analysis completed successfully!', 'success');
        } catch (error) {
            console.error('Analysis failed:', error);
            this.showNotification(`Analysis failed: ${error.message}`, 'error');
            this.closeModal();
        } finally {
            this.setButtonLoading('runAnalysisBtn', false);
        }
    }

    /**
     * Execute strategy
     */
    async executeStrategy() {
        await this.runStrategyExecution('execute');
    }

    /**
     * Simulate strategy
     */
    async simulateStrategy() {
        await this.runStrategyExecution('simulate');
    }

    /**
     * Run strategy execution (simulate or execute)
     */
    async runStrategyExecution(mode) {
        try {
            if (!this.currentAgent) {
                this.showNotification('Please create and start an agent first', 'warning');
                return;
            }

            const buttonId = mode === 'execute' ? 'executeStrategyBtn' : 'simulateStrategyBtn';
            this.setButtonLoading(buttonId, true);
            this.showModal(`Strategy ${mode === 'execute' ? 'Execution' : 'Simulation'}`, true);

            // Collect strategy data
            const portfolioData = {
                total_value: this.calculateTotalPortfolioValue(),
                assets: this.getPortfolioAssetsData(),
                target_chains: this.getSelectedChains()
            };

            const strategyConfig = {
                type: 'balanced', // This could be dynamic based on UI selection
                maxSlippage: parseFloat(document.getElementById('maxSlippage').value) || 0.5,
                query: document.getElementById('strategyQuery').value,
                riskPreferences: {
                    risk_tolerance: 'medium',
                    max_slippage: parseFloat(document.getElementById('maxSlippage').value) || 0.5
                }
            };

            // Execute strategy
            const response = await this.api.executeStrategy(portfolioData, strategyConfig, mode);
            const parsedResponse = this.api.parseResponse(response);

            // Display results
            this.displayStrategyResults(parsedResponse, mode);
            this.updateCoordinationMetrics(parsedResponse);
            
            const action = mode === 'execute' ? 'executed' : 'simulated';
            this.showNotification(`Strategy ${action} successfully!`, 'success');
        } catch (error) {
            console.error(`Strategy ${mode} failed:`, error);
            this.showNotification(`Strategy ${mode} failed: ${error.message}`, 'error');
            this.closeModal();
        } finally {
            const buttonId = mode === 'execute' ? 'executeStrategyBtn' : 'simulateStrategyBtn';
            this.setButtonLoading(buttonId, false);
        }
    }

    /**
     * Add asset to portfolio
     */
    addAsset() {
        const symbol = document.getElementById('assetSymbol').value.toUpperCase();
        const amount = parseFloat(document.getElementById('assetAmount').value);
        const value = parseFloat(document.getElementById('assetValue').value);

        if (!symbol || !amount || !value) {
            this.showNotification('Please fill in all asset fields', 'warning');
            return;
        }

        // Add to portfolio
        this.portfolioAssets.set(symbol, {
            amount: amount,
            value: value,
            price: value / amount
        });

        // Update UI
        this.updateAssetTable();
        this.updatePortfolioStats();
        
        // Clear form
        document.getElementById('assetSymbol').value = '';
        document.getElementById('assetAmount').value = '';
        document.getElementById('assetValue').value = '';

        this.showNotification(`${symbol} added to portfolio`, 'success');
    }

    /**
     * Remove asset from portfolio
     */
    removeAsset(symbol) {
        this.portfolioAssets.delete(symbol);
        this.updateAssetTable();
        this.updatePortfolioStats();
        this.showNotification(`${symbol} removed from portfolio`, 'info');
    }

    /**
     * Update asset table
     */
    updateAssetTable() {
        const tbody = document.getElementById('assetTableBody');
        
        if (this.portfolioAssets.size === 0) {
            tbody.innerHTML = '<tr class="empty-state"><td colspan="5">No assets configured. Add assets to get started.</td></tr>';
            return;
        }

        const totalValue = this.calculateTotalPortfolioValue();
        let html = '';

        this.portfolioAssets.forEach((asset, symbol) => {
            const percentage = ((asset.value / totalValue) * 100).toFixed(1);
            html += `
                <tr>
                    <td><strong>${symbol}</strong></td>
                    <td>${asset.amount.toFixed(4)}</td>
                    <td>${this.api.formatCurrency(asset.value)}</td>
                    <td>${percentage}%</td>
                    <td>
                        <button class="btn btn-danger" onclick="ui.removeAsset('${symbol}')">
                            <i class="fas fa-trash"></i>
                        </button>
                    </td>
                </tr>
            `;
        });

        tbody.innerHTML = html;
    }

    /**
     * Update portfolio statistics
     */
    updatePortfolioStats() {
        const totalValue = this.calculateTotalPortfolioValue();
        document.getElementById('totalPortfolioValue').textContent = this.api.formatCurrency(totalValue);
        
        // Update active chains count
        const chains = this.getSelectedChains();
        document.getElementById('activeChains').textContent = chains.length;
    }

    /**
     * Calculate total portfolio value
     */
    calculateTotalPortfolioValue() {
        let total = 0;
        this.portfolioAssets.forEach(asset => {
            total += asset.value;
        });
        return total;
    }

    /**
     * Get portfolio assets data for API
     */
    getPortfolioAssetsData() {
        const assets = {};
        this.portfolioAssets.forEach((asset, symbol) => {
            assets[symbol] = {
                amount: asset.amount,
                value: asset.value,
                price_usd: asset.price
            };
        });
        return assets;
    }

    /**
     * Get selected chains
     */
    getSelectedChains() {
        const checkboxes = document.querySelectorAll('input[type="checkbox"][value]');
        const selected = [];
        checkboxes.forEach(cb => {
            if (cb.checked) {
                selected.push(cb.value);
            }
        });
        return selected.length > 0 ? selected : ['ethereum'];
    }

    /**
     * Get minimum APY threshold based on risk tolerance
     */
    getMinAPYThreshold(riskTolerance) {
        switch (riskTolerance) {
            case 'low': return 5.0;
            case 'medium': return 8.0;
            case 'high': return 12.0;
            default: return 8.0;
        }
    }

    /**
     * Use strategy template
     */
    useStrategyTemplate(strategyType) {
        const queryElement = document.getElementById('strategyQuery');
        const executionMode = document.getElementById('executionMode');
        const maxSlippage = document.getElementById('maxSlippage');

        let query = '';
        let slippage = 0.5;

        switch (strategyType) {
            case 'conservative':
                query = 'Execute a conservative yield farming strategy focusing on stable protocols with TVL > $500M. Prioritize Aave, Compound, and established Uniswap V3 pools. Target 5-8% APY with minimal impermanent loss risk.';
                slippage = 0.3;
                executionMode.value = 'simulate';
                break;
            case 'balanced':
                query = 'Execute a balanced yield farming strategy mixing stable and growth protocols. Include Uniswap V3, Raydium, and Aave positions. Target 8-15% APY with moderate risk tolerance and diversified exposure.';
                slippage = 0.5;
                executionMode.value = 'simulate';
                break;
            case 'aggressive':
                query = 'Execute a high-yield aggressive strategy targeting maximum returns. Focus on newer protocols, concentrated liquidity positions, and yield farming opportunities. Target 15-30% APY with higher risk acceptance.';
                slippage = 1.0;
                executionMode.value = 'analyze';
                break;
        }

        queryElement.value = query;
        maxSlippage.value = slippage;
        
        // Switch to strategies section
        this.showSection('strategies');
        document.querySelectorAll('.nav-link').forEach(l => l.classList.remove('active'));
        document.querySelector('a[href="#strategies"]').classList.add('active');

        this.showNotification(`${strategyType.charAt(0).toUpperCase() + strategyType.slice(1)} strategy template loaded`, 'success');
    }

    /**
     * Display analysis results in modal
     */
    displayAnalysisResults(parsedResponse) {
        const content = document.getElementById('resultsContent');
        
        let html = '<div class="results-sections">';
        
        // Success status
        html += `<div class="result-section">
            <h3>Analysis Status</h3>
            <div class="status-info">
                <span class="status-badge ${parsedResponse.success ? 'success' : 'error'}">
                    ${parsedResponse.success ? 'Success' : 'Failed'}
                </span>
                <span>Coordination Rounds: ${parsedResponse.coordinationRounds}</span>
                <span>Consensus: ${parsedResponse.consensusAchieved ? 'Achieved' : 'Not Achieved'}</span>
            </div>
        </div>`;

        // Protocol Analysis
        if (parsedResponse.analysis && parsedResponse.analysis.success) {
            html += `<div class="result-section">
                <h3>Yield Analysis</h3>
                <div class="protocol-recommendations">`;
            
            const protocols = this.api.extractProtocolRecommendations(parsedResponse.analysis.message);
            
            if (protocols.length > 0) {
                protocols.forEach(protocol => {
                    html += `<div class="protocol-recommendation">
                        <div class="protocol-header">
                            <span class="protocol-name">${protocol.name}</span>
                            <span class="protocol-apy">${protocol.apy}% APY</span>
                        </div>
                        <div class="protocol-details">
                            Risk Score: ${protocol.riskScore || 'N/A'}/10
                        </div>
                    </div>`;
                });
            } else {
                html += `<div class="result-content">${parsedResponse.analysis.message}</div>`;
            }
            
            html += `</div></div>`;
        }

        // Risk Assessment
        if (parsedResponse.riskAssessment && parsedResponse.riskAssessment.success) {
            html += `<div class="result-section">
                <h3>Risk Assessment</h3>
                <div class="result-content">${parsedResponse.riskAssessment.message}</div>
            </div>`;
            
            // Update risk metrics in the UI
            const riskMetrics = this.api.extractRiskMetrics(parsedResponse.riskAssessment.message);
            this.updateRiskMetrics(riskMetrics);
        }

        html += '</div>';
        content.innerHTML = html;
    }

    /**
     * Display strategy results
     */
    displayStrategyResults(parsedResponse, mode) {
        const content = document.getElementById('resultsContent');
        
        let html = `<div class="results-sections">
            <div class="result-section">
                <h3>Strategy ${mode === 'execute' ? 'Execution' : 'Simulation'} Results</h3>
                <div class="status-info">
                    <span class="status-badge ${parsedResponse.success ? 'success' : 'error'}">
                        ${parsedResponse.success ? 'Success' : 'Failed'}
                    </span>
                    <span>Mode: ${mode.toUpperCase()}</span>
                    <span>Coordination Rounds: ${parsedResponse.coordinationRounds}</span>
                </div>
            </div>`;

        if (parsedResponse.analysis && parsedResponse.analysis.success) {
            html += `<div class="result-section">
                <h3>Execution Plan</h3>
                <div class="result-content">${parsedResponse.analysis.message}</div>
            </div>`;
        }

        if (parsedResponse.riskAssessment && parsedResponse.riskAssessment.success) {
            html += `<div class="result-section">
                <h3>Risk Analysis</h3>
                <div class="result-content">${parsedResponse.riskAssessment.message}</div>
            </div>`;
        }

        html += '</div>';
        content.innerHTML = html;
    }

    /**
     * Update coordination metrics
     */
    updateCoordinationMetrics(parsedResponse) {
        document.getElementById('coordinationRounds').textContent = parsedResponse.coordinationRounds || 0;
        // Update success rate based on recent operations (simplified)
        const successRate = parsedResponse.success ? '100' : '0';
        document.getElementById('successRate').textContent = `${successRate}%`;
    }

    /**
     * Update risk metrics display
     */
    updateRiskMetrics(metrics) {
        this.updateRiskBar('overallRiskFill', 'overallRiskValue', metrics.overallRisk);
        this.updateRiskBar('contractRiskFill', 'contractRiskValue', metrics.smartContractRisk);
        this.updateRiskBar('liquidityRiskFill', 'liquidityRiskValue', metrics.liquidityRisk);
        this.updateRiskBar('marketRiskFill', 'marketRiskValue', metrics.marketRisk);
        
        // Update main risk score
        document.getElementById('riskScore').textContent = `${metrics.overallRisk}/10`;
    }

    /**
     * Update individual risk bar
     */
    updateRiskBar(fillId, valueId, score) {
        const fill = document.getElementById(fillId);
        const value = document.getElementById(valueId);
        
        if (fill && value) {
            fill.style.width = `${(score / 10) * 100}%`;
            value.textContent = `${score}/10`;
        }
    }

    /**
     * Clear analysis form
     */
    clearAnalysisForm() {
        document.getElementById('portfolioValue').value = '';
        document.getElementById('riskTolerance').value = 'medium';
        document.getElementById('analysisQuery').value = 'Find the best yield farming opportunities for my portfolio with medium risk tolerance. Focus on stable protocols with good liquidity.';
        
        // Uncheck all chains except Ethereum
        document.querySelectorAll('input[type="checkbox"][value]').forEach(cb => {
            cb.checked = cb.value === 'ethereum';
        });
        
        this.updatePortfolioStats();
    }

    /**
     * Show modal
     */
    showModal(title, loading = false) {
        document.getElementById('modalTitle').textContent = title;
        const modal = document.getElementById('resultsModal');
        const content = document.getElementById('resultsContent');
        
        if (loading) {
            content.innerHTML = `
                <div class="loading-spinner">
                    <i class="fas fa-spinner fa-spin"></i>
                    <span>Processing your request...</span>
                </div>
            `;
        }
        
        modal.classList.add('active');
    }

    /**
     * Close modal
     */
    closeModal() {
        document.getElementById('resultsModal').classList.remove('active');
    }

    /**
     * Save results (placeholder)
     */
    saveResults() {
        // In a real implementation, this would save results to local storage or backend
        this.showNotification('Results saved successfully!', 'success');
        this.closeModal();
    }

    /**
     * Set button loading state
     */
    setButtonLoading(buttonId, loading) {
        const button = document.getElementById(buttonId);
        if (!button) return;

        if (loading) {
            button.disabled = true;
            const icon = button.querySelector('i');
            if (icon) {
                icon.className = 'fas fa-spinner fa-spin';
            }
        } else {
            button.disabled = false;
            const icon = button.querySelector('i');
            if (icon) {
                // Restore original icon based on button
                switch (buttonId) {
                    case 'createAgentBtn':
                        icon.className = 'fas fa-plus';
                        break;
                    case 'startAgentBtn':
                        icon.className = 'fas fa-play';
                        break;
                    case 'stopAgentBtn':
                        icon.className = 'fas fa-stop';
                        break;
                    case 'runAnalysisBtn':
                        icon.className = 'fas fa-search';
                        break;
                    case 'executeStrategyBtn':
                        icon.className = 'fas fa-play';
                        break;
                    case 'simulateStrategyBtn':
                        icon.className = 'fas fa-flask';
                        break;
                }
            }
        }
    }

    /**
     * Show notification
     */
    showNotification(message, type = 'info') {
        const container = document.getElementById('notificationContainer');
        const notification = document.createElement('div');
        notification.className = `notification ${type}`;
        notification.innerHTML = `
            <div class="notification-content">
                <span>${message}</span>
            </div>
        `;

        container.appendChild(notification);

        // Remove notification after 5 seconds
        setTimeout(() => {
            if (notification.parentElement) {
                notification.parentElement.removeChild(notification);
            }
        }, 5000);
    }

    /**
     * Calculate asset amount from value
     */
    calculateAssetAmount() {
        const valueInput = document.getElementById('assetValue');
        const amountInput = document.getElementById('assetAmount');
        const symbolInput = document.getElementById('assetSymbol');
        
        const value = parseFloat(valueInput.value);
        const symbol = symbolInput.value.toUpperCase();
        
        if (value && symbol) {
            // Use mock prices for common assets (in real implementation, fetch from price API)
            const prices = {
                'ETH': 2500,
                'BTC': 45000,
                'SOL': 75,
                'MATIC': 0.8,
                'USDC': 1,
                'USDT': 1,
                'DAI': 1
            };
            
            const price = prices[symbol] || 1;
            const amount = value / price;
            amountInput.value = amount.toFixed(6);
        }
    }

    /**
     * Calculate asset value from amount
     */
    calculateAssetValue() {
        const amountInput = document.getElementById('assetAmount');
        const valueInput = document.getElementById('assetValue');
        const symbolInput = document.getElementById('assetSymbol');
        
        const amount = parseFloat(amountInput.value);
        const symbol = symbolInput.value.toUpperCase();
        
        if (amount && symbol) {
            // Use mock prices for common assets
            const prices = {
                'ETH': 2500,
                'BTC': 45000,
                'SOL': 75,
                'MATIC': 0.8,
                'USDC': 1,
                'USDT': 1,
                'DAI': 1
            };
            
            const price = prices[symbol] || 1;
            const value = amount * price;
            valueInput.value = value.toFixed(2);
        }
    }
}

// Export for use in main script
window.YieldSwarmUI = YieldSwarmUI;
