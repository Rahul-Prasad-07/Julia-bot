println("Testing environment variables...")
println("BINANCE_API_KEY: ", get(ENV, "BINANCE_API_KEY", "NOT_SET"))
println("Length: ", length(get(ENV, "BINANCE_API_KEY", "")))

# Try loading .env file
try
    using DotEnv
    DotEnv.config()
    println("After DotEnv.config():")
    println("BINANCE_API_KEY: ", get(ENV, "BINANCE_API_KEY", "NOT_SET"))
    println("Length: ", length(get(ENV, "BINANCE_API_KEY", "")))
catch e
    println("DotEnv not available or failed: ", e)
    
    # Try manual .env parsing
    try
        env_content = read(".env", String)
        lines = split(env_content, '\n')
        for line in lines
            if startswith(line, "BINANCE_API_KEY=")
                key_value = split(line, '=', limit=2)
                if length(key_value) == 2
                    ENV["BINANCE_API_KEY"] = strip(key_value[2], '"')
                    println("Manually loaded BINANCE_API_KEY")
                end
            elseif startswith(line, "BINANCE_API_SECRET=")
                key_value = split(line, '=', limit=2)
                if length(key_value) == 2
                    ENV["BINANCE_API_SECRET"] = strip(key_value[2], '"')
                    println("Manually loaded BINANCE_API_SECRET")
                end
            elseif startswith(line, "OPENAI_API_KEY=")
                key_value = split(line, '=', limit=2)
                if length(key_value) == 2
                    ENV["OPENAI_API_KEY"] = strip(key_value[2], '"')
                    println("Manually loaded OPENAI_API_KEY")
                end
            end
        end
        
        println("Final check:")
        println("BINANCE_API_KEY: ", get(ENV, "BINANCE_API_KEY", "NOT_SET")[1:min(10, length(get(ENV, "BINANCE_API_KEY", "")))])
        println("BINANCE_API_SECRET: ", length(get(ENV, "BINANCE_API_SECRET", "")) > 0 ? "SET" : "NOT_SET")
        println("OPENAI_API_KEY: ", length(get(ENV, "OPENAI_API_KEY", "")) > 0 ? "SET" : "NOT_SET")
        
    catch e2
        println("Manual parsing failed: ", e2)
    end
end
