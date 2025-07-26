using Pkg
Pkg.activate(".")

println("Testing tools registration...")
try
    include("src/agents/CommonTypes.jl")
    using .CommonTypes
    println("CommonTypes loaded")
    
    # Test just the tools loading
    include("src/resources/Resources.jl")
    using .Resources
    println("Resources loaded")
    
    include("src/agents/tools/Tools.jl")
    using .Tools
    println("Tools loaded successfully")
    println("Available tools: ", keys(Tools.TOOL_REGISTRY))
    
catch e
    println("Error: ", e)
    for (exc, bt) in Base.catch_stack()
        showerror(stdout, exc, bt)
        println()
    end
end
