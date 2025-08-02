# Test Binance API Connection
using HTTP, JSON3, SHA, Dates

# Load environment from .env file
function load_env_file(file_path::String = ".env")
    if isfile(file_path)
        for line in readlines(file_path)
            line = strip(line)
            if !isempty(line) && !startswith(line, "#") && contains(line, "=")
                key, value = split(line, "=", limit=2)
                key = strip(key)
                value = strip(value, ['"', ' '])
                ENV[key] = value
            end
        end
        println("✅ Loaded environment variables from $file_path")
    else
        println("❌ Environment file $file_path not found")
    end
end

# Load .env
load_env_file()

function hmac_sha256_test(key::String, message::String)
    key_bytes = Vector{UInt8}(key)
    message_bytes = Vector{UInt8}(message)
    signature = SHA.hmac_sha256(key_bytes, message_bytes)
    return bytes2hex(signature)
end

function test_binance_api()
    api_key = get(ENV, "BINANCE_API_KEY", "")
    api_secret = get(ENV, "BINANCE_API_SECRET", "")
    
    println("🔧 Testing Binance API Connection...")
    
    if isempty(api_key) || isempty(api_secret)
        println("❌ API credentials not found!")
        println("BINANCE_API_KEY: $(isempty(api_key) ? "MISSING" : "PRESENT")")
        println("BINANCE_API_SECRET: $(isempty(api_secret) ? "MISSING" : "PRESENT")")
        return
    end
    
    println("API Key: $(api_key[1:8])...$(api_key[end-4:end]) ($(length(api_key)) chars)")
    
    # Test 1: Simple public endpoint (no auth)
    println("\n📊 Test 1: Public Price Data (No Auth)")
    try
        response = HTTP.get("https://testnet.binancefuture.com/fapi/v1/ticker/price?symbol=ETHUSDT")
        data = JSON3.read(String(response.body))
        println("✅ Public API Success: ETHUSDT = \$$(data.price)")
    catch e
        println("❌ Public API Failed: $e")
    end
    
    # Test 2: Authenticated endpoint
    println("\n🔐 Test 2: Authenticated Account Info")
    try
        base_url = "https://testnet.binancefuture.com"
        timestamp = string(Int(round(time() * 1000)))
        
        query_params = Dict("timestamp" => timestamp)
        query_string = join(["$k=$v" for (k, v) in query_params], "&")
        
        signature = hmac_sha256_test(api_secret, query_string)
        full_query = "$query_string&signature=$signature"
        
        headers = [
            "X-MBX-APIKEY" => api_key,
            "Content-Type" => "application/x-www-form-urlencoded"
        ]
        
        response = HTTP.get("$base_url/fapi/v2/account?$full_query", headers)
        data = JSON3.read(String(response.body))
        
        if haskey(data, "totalWalletBalance")
            println("✅ Auth API Success: Balance = \$$(data.totalWalletBalance)")
        else
            println("❌ Auth API Failed: $(data)")
        end
    catch e
        println("❌ Auth API Failed: $e")
    end
    
    # Test 3: Exchange Info
    println("\n📋 Test 3: Exchange Info")
    try
        response = HTTP.get("https://testnet.binancefuture.com/fapi/v1/exchangeInfo")
        data = JSON3.read(String(response.body))
        
        # Find ETHUSDT symbol info
        for symbol in data.symbols
            if symbol.symbol == "ETHUSDT"
                println("✅ ETHUSDT Symbol Info:")
                println("  Status: $(symbol.status)")
                println("  Base Asset: $(symbol.baseAsset)")
                println("  Quote Asset: $(symbol.quoteAsset)")
                break
            end
        end
    catch e
        println("❌ Exchange Info Failed: $e")
    end
end

# Run the test
test_binance_api()
