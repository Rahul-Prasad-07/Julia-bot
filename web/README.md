# YieldSwarm Web Interface

Production-level web interface for the YieldSwarm DeFi yield optimization system.

## Features

### 📊 Dashboard
- Real-time portfolio overview
- Agent status monitoring
- Quick analysis capabilities
- Connection status tracking

### 🔧 Agent Management
- Create and manage YieldSwarm agents
- Start/stop agent operations
- Monitor coordination metrics
- Real-time status updates

### 💼 Portfolio Management
- Add/remove portfolio assets
- Automatic portfolio valuation
- Multi-chain asset support
- Portfolio composition analysis

### ⚡ Strategy Execution
- Pre-built strategy templates (Conservative, Balanced, Aggressive)
- Real strategy execution capabilities
- Simulation mode for testing
- Custom strategy configuration

### 📈 Analytics & Risk Management
- Comprehensive risk assessment
- Value at Risk (VaR) calculations
- Impermanent loss analysis
- Protocol-specific risk scores

## Getting Started

### Prerequisites
- JuliaOS backend server running on `http://127.0.0.1:8052`
- YieldSwarm strategy and tools installed
- Modern web browser with JavaScript enabled

### Running the Interface

1. **Start the web server:**
   ```bash
   cd web
   python serve.py
   ```

2. **Access the dashboard:**
   - Open your browser to `http://localhost:3001`
   - The interface will automatically detect the backend connection

3. **Create an agent:**
   - Click "Create Agent" to initialize a YieldSwarm agent
   - Start the agent to begin processing requests

### Usage Workflow

#### Basic Portfolio Analysis
1. **Configure Portfolio:**
   - Enter portfolio value
   - Add your assets in the Portfolio section
   - Select target blockchain networks

2. **Run Analysis:**
   - Set risk tolerance level
   - Enter specific analysis requirements
   - Click "Run Analysis" to get recommendations

3. **Review Results:**
   - Protocol recommendations with APY rates
   - Risk assessments and scores
   - Position sizing suggestions

#### Strategy Execution
1. **Choose Strategy Template:**
   - Conservative: 5-8% APY, low risk
   - Balanced: 8-15% APY, medium risk
   - Aggressive: 15-30% APY, high risk

2. **Configure Execution:**
   - Set slippage tolerance
   - Choose execution mode (Analyze/Simulate/Execute)
   - Customize strategy parameters

3. **Execute or Simulate:**
   - Use "Simulate First" for testing
   - Use "Execute Strategy" for real transactions

## API Integration

The web interface communicates with the JuliaOS backend through:

### Endpoints Used
- `GET /api/v1/agents` - List agents
- `POST /api/v1/agents` - Create agent
- `PUT /api/v1/agents/{id}` - Update agent state
- `POST /api/v1/agents/{id}/webhook` - Send queries
- `GET /api/v1/strategies` - List strategies
- `GET /api/v1/tools` - List tools

### Real Execution Capabilities
- **Analyze Mode:** Portfolio analysis only
- **Simulate Mode:** Detailed execution planning without transactions
- **Execute Mode:** Real blockchain transactions (requires wallet integration)

## Architecture

### Frontend Components
```
web/
├── yieldswarm-dashboard.html    # Main HTML interface
├── styles/
│   └── yieldswarm.css          # Complete styling
├── scripts/
│   ├── yieldswarm-api.js       # Backend API client
│   ├── yieldswarm-ui.js        # UI components and interactions
│   └── yieldswarm-main.js      # Application initialization
└── serve.py                    # Production web server
```

### Key Classes
- **YieldSwarmAPI:** Handles all backend communication
- **YieldSwarmUI:** Manages user interface and interactions
- **YieldSwarmApp:** Application lifecycle and coordination

## Configuration

### Server Configuration
The web server (`serve.py`) includes:
- CORS support for API requests
- Request proxying to JuliaOS backend
- Error handling and logging
- Production-ready HTTP server

### API Configuration
```javascript
// Backend URL (automatically configured)
const BACKEND_URL = "http://127.0.0.1:8052/api/v1";

// Agent configuration
const AGENT_CONFIG = {
    id: "yieldswarm-web-agent",
    tools: ["yieldswarm_analyzer", "yieldswarm_executor", "yieldswarm_risk_manager"],
    strategy: "yieldswarm"
};
```

## Security Considerations

### Production Deployment
- Enable HTTPS for production
- Implement authentication for sensitive operations
- Add rate limiting for API requests
- Secure private keys and wallet connections

### Risk Management
- All strategy execution modes include risk assessment
- Simulation mode available for testing
- Slippage protection and position limits
- Real-time risk monitoring

## Troubleshooting

### Common Issues

1. **Connection Failed:**
   - Ensure JuliaOS backend is running on port 8052
   - Check firewall settings
   - Verify CORS configuration

2. **Agent Creation Failed:**
   - Verify YieldSwarm strategy is registered
   - Check all required tools are available
   - Review backend logs for errors

3. **Analysis/Execution Errors:**
   - Ensure agent is in RUNNING state
   - Verify portfolio data format
   - Check backend server resources

### Debug Information
- Browser console shows detailed API requests
- Network tab shows backend communication
- Backend logs provide execution details

## Development

### Adding New Features
1. **New Analysis Types:** Extend `YieldSwarmAPI.analyzeYield()`
2. **Custom Strategies:** Add templates in `YieldSwarmUI.useStrategyTemplate()`
3. **Additional Chains:** Update chain selection and configuration
4. **Enhanced Risk Metrics:** Extend risk parsing and display

### Testing
- Use browser developer tools for debugging
- Test with simulation mode before real execution
- Monitor backend logs during development

## Support

For issues and questions:
1. Check the browser console for errors
2. Review backend server logs
3. Verify YieldSwarm system is properly configured
4. Refer to the complete documentation in `YIELDSWARM_COMPLETE_DOCUMENTATION.md`

---

**Production Ready:** This interface includes real transaction capabilities and should be used with appropriate security measures and testing in a development environment first.
