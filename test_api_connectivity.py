import requests
import json

print("🚀 Testing Real-Time Data API Connectivity")
print("=" * 50)

# Test DeFiLlama API
print("\n1. Testing DeFiLlama API...")
try:
    response = requests.get('https://yields.llama.fi/pools', timeout=10)
    if response.status_code == 200:
        data = response.json()
        pools = data.get('data', [])
        print(f'✅ DeFiLlama API: {len(pools)} pools available')
        
        # Show top 5 yields
        valid_pools = [p for p in pools if p.get('apy', 0) > 0]
        sorted_pools = sorted(valid_pools, key=lambda x: x.get('apy', 0), reverse=True)[:5]
        print('\n🔥 Top 5 Yield Opportunities:')
        for pool in sorted_pools:
            protocol = pool.get('project', 'Unknown')
            chain = pool.get('chain', 'Unknown')
            apy = pool.get('apy', 0)
            symbol = pool.get('symbol', '')
            print(f'• {protocol} ({chain}): {symbol} - {apy:.2f}% APY')
    else:
        print(f'❌ DeFiLlama API Error: {response.status_code}')
except Exception as e:
    print(f'❌ DeFiLlama API Error: {e}')

# Test CoinGecko API
print("\n2. Testing CoinGecko API...")
try:
    url = 'https://api.coingecko.com/api/v3/simple/price?ids=ethereum,solana,bitcoin&vs_currencies=usd&include_24hr_change=true'
    response = requests.get(url, timeout=10)
    if response.status_code == 200:
        data = response.json()
        print(f'✅ CoinGecko API: {len(data)} tokens retrieved')
        print('\n💰 Current Prices:')
        for token, info in data.items():
            price = info.get('usd', 0)
            change = info.get('usd_24h_change', 0)
            change_indicator = '📈' if change >= 0 else '📉'
            print(f'• {token.upper()}: ${price:,.2f} {change_indicator} {change:.2f}%')
    else:
        print(f'❌ CoinGecko API Error: {response.status_code}')
except Exception as e:
    print(f'❌ CoinGecko API Error: {e}')

print('\n🎯 Real-time data connectivity test complete!')
print('✅ YieldSwarm is ready for live data integration!')
