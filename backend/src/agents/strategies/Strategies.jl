module Strategies

export STRATEGY_REGISTRY

include("strategy_example_adder.jl")
include("strategy_plan_and_execute.jl")
include("strategy_blogger.jl")
include("telegram/strategy_moderator.jl")
include("telegram/strategy_support.jl")
include("strategy_ai_news_scraping.jl")
include("strategy_solana_dev_chat.jl")
include("strategy_solana_swarm_dev.jl")
include("strategy_yieldswarm.jl")
include("strategy_market_making.jl")
include("strategy_llm_backtesting.jl")
include("strategy_multi_exchange.jl")
include("strategy_agent_swarm.jl")
include("strategy_rl_market_making.jl")
include("strategy_rl_market_making_enhanced.jl")
include("strategy_ai_swarm_market_making.jl")
include("strategy_ai_swarm_wrapper.jl")

using ..CommonTypes: StrategySpecification

const STRATEGY_REGISTRY = Dict{String, StrategySpecification}()

function register_strategy(strategy_spec::StrategySpecification)
    strategy_name = strategy_spec.metadata.name
    if haskey(STRATEGY_REGISTRY, strategy_name)
        error("Strategy with name '$strategy_name' is already registered.")
    end
    STRATEGY_REGISTRY[strategy_name] = strategy_spec
end

# All strategies to be used by agents must be registered here:

register_strategy(STRATEGY_EXAMPLE_ADDER_SPECIFICATION)
register_strategy(STRATEGY_PLAN_AND_EXECUTE_SPECIFICATION)
register_strategy(STRATEGY_BLOG_WRITER_SPECIFICATION)
register_strategy(STRATEGY_TELEGRAM_MODERATOR_SPECIFICATION)
register_strategy(STRATEGY_TELEGRAM_SUPPORT_SPECIFICATION)
register_strategy(STRATEGY_AI_NEWS_SCRAPING_SPECIFICATION)
register_strategy(STRATEGY_SOLANA_DEV_CHAT_SPECIFICATION)
register_strategy(STRATEGY_SOLANA_SWARM_DEV_SPECIFICATION)
register_strategy(STRATEGY_YIELDSWARM_SPECIFICATION)
register_strategy(STRATEGY_MARKET_MAKING_SPECIFICATION)
register_strategy(STRATEGY_LLM_BACKTESTING_SPECIFICATION)
register_strategy(STRATEGY_MULTI_EXCHANGE_SPECIFICATION)
register_strategy(STRATEGY_AGENT_SWARM_SPECIFICATION)
register_strategy(STRATEGY_RL_MARKET_MAKING_SPECIFICATION)
register_strategy(ENHANCED_RL_MARKET_MAKING_STRATEGY)
register_strategy(AI_SWARM_MARKET_MAKING_STRATEGY)
register_strategy(AI_SWARM_WRAPPER_STRATEGY)

end