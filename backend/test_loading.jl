using Pkg
Pkg.activate(".")

println("Testing backend module loading...")
try
    include("src/JuliaOSBackend.jl")
    using .JuliaOSBackend
    println("Backend loaded successfully")
    # Test tools registry
    println("Available tools: ", keys(JuliaOSBackend.Agents.Tools.TOOL_REGISTRY))
    println("Available strategies: ", keys(JuliaOSBackend.Agents.Strategies.STRATEGY_REGISTRY))
catch e
    println("Error: ", e)
    for (exc, bt) in Base.catch_stack()
        showerror(stdout, exc, bt)
        println()
    end
end
