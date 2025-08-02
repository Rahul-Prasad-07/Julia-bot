# Test RL API Function Directly
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

# HMAC function from RL strategy
function hmac_sha256_rl(key::String, message::String)
    key_bytes = Vector{UInt8}(key)
    message_bytes = Vector{UInt8}(message)
    signature = SHA.hmac_sha256(key_bytes, message_bytes)
    return bytes2hex(signature)
end

# Exact RL API function with debugging
function binance_api_request_rl(endpoint::String, method::String, api_key::String, api_secret::String, params::Dict=Dict())
    try
        base_url = "https://testnet.binancefuture.com"
        timestamp = string(Int(round(time() * 1000)))
        
        # Debug: Check API credentials
        if isempty(api_key) || isempty(api_secret)
            return Dict("error" => "API credentials are empty", "api_key_length" => length(api_key), "api_secret_length" => length(api_secret))
        end
        
        query_params = merge(params, Dict("timestamp" => timestamp))
        query_string = join(["$k=$v" for (k, v) in query_params], "&")
        
        # Create proper HMAC-SHA256 signature
        signature = hmac_sha256_rl(api_secret, query_string)
        full_query = "$query_string&signature=$signature"
        
        headers = [
            "X-MBX-APIKEY" => api_key,
            "Content-Type" => "application/x-www-form-urlencoded"
        ]
        
        # Debug: Log request details
        println("🔍 API Request Debug:")
        println("  Endpoint: $endpoint")
        println("  URL: $base_url$endpoint")
        println("  Query: $query_string")
        println("  API Key: $(api_key[1:8])...$(api_key[end-4:end])")
        
        if method == "GET"
            response = HTTP.get("$base_url$endpoint?$full_query", headers)
        elseif method == "POST"
            response = HTTP.post("$base_url$endpoint", headers, full_query)
        else
            error("Unsupported HTTP method: $method")
        end
        
        # Debug: Log response
        response_body = String(response.body)
        println("  Response Status: $(response.status)")
        println("  Response Body: $(response_body[1:min(200, end)])")
        
        parsed_response = JSON3.read(response_body)
        println("  Parsed Successfully: $(typeof(parsed_response))")
        
        return parsed_response
    catch e
        error_msg = string(e)
        println("❌ API Request Failed: $error_msg")
        return Dict("error" => error_msg, "endpoint" => endpoint, "method" => method)
    end
end

# Test the RL API function
function test_rl_api()
    api_key = get(ENV, "BINANCE_API_KEY", "")
    api_secret = get(ENV, "BINANCE_API_SECRET", "")
    
    println("🧪 Testing RL API Function...")
    
    # Test the exact call from the RL strategy
    result = binance_api_request_rl("/fapi/v1/ticker/price", "GET", api_key, api_secret, Dict("symbol" => "ETHUSDT"))
    
    println("\n📊 Result:")
    println("Type: $(typeof(result))")
    println("Content: $result")
    
    if isa(result, Dict) && haskey(result, "price")
        println("✅ Success! Price: $(result["price"])")
    else
        println("❌ Failed! No price in response")
    end
end

# Run the test
test_rl_api()
