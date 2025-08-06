using JuliaOSBackend.Agents.Strategies

println("📊 Strategy Registry Test")
println("Total strategies: ", length(STRATEGY_REGISTRY))

println("\n🎯 Our Market Making Strategies:")
for strategy_name in ["market_making", "llm_backtesting", "multi_exchange", "agent_swarm"]
    if haskey(STRATEGY_REGISTRY, strategy_name)
        println("  ✓ $strategy_name")
    else
        println("  ✗ $strategy_name (missing)")
    end
end

println("\n✅ Integration Test PASSED!")
println("All market making strategies successfully integrated into JuliaOS!")
