module Groq

using HTTP
using JSON

export GroqConfig, groq_util

@kwdef struct GroqConfig
    api_key::String
    model_name::String = "meta-llama/llama-4-scout-17b-16e-instruct"  # Fast, high-quality model
    temperature::Float64 = 0.0
    max_tokens::Int = 4096
    base_url::String = "https://api.groq.com/openai/v1"
end

"""
    groq_util(cfg::GroqConfig, prompt::String) :: String

Sends prompt to Groq's API and returns its text completion using OpenAI-compatible format.
"""
function groq_util(
    cfg::GroqConfig,
    prompt::String
)::String
    endpoint_url = "$(cfg.base_url)/chat/completions"

    body_dict = Dict(
        "model" => cfg.model_name,
        "messages" => [
            Dict("role" => "user", "content" => prompt)
        ],
        "temperature" => cfg.temperature,
        "max_tokens" => cfg.max_tokens,
        "stream" => false
    )
    request_body = JSON.json(body_dict)

    headers = [
        "Content-Type" => "application/json",
        "Authorization" => "Bearer $(cfg.api_key)"
    ]

    resp = HTTP.request(
        "POST",
        endpoint_url;
        headers = headers,
        body = request_body
    )

    if resp.status != 200
        error("Groq API failed with status $(resp.status): $(String(resp.body))")
    end

    resp_json = JSON.parse(String(resp.body))

    if !haskey(resp_json, "choices") || isempty(resp_json["choices"])
        error("Groq response missing 'choices' or the list is empty.")
    end
    
    first_choice = resp_json["choices"][1]
    
    if !haskey(first_choice, "message") || 
       !haskey(first_choice["message"], "content")
        error("Groq response's first choice missing 'message.content'.")
    end

    generated_text = first_choice["message"]["content"]
    return generated_text
end

# Available Groq models for different use cases
const GROQ_MODELS = Dict(
    "fast" => "llama-3.1-8b-instant",      # Fastest responses
    "balanced" => "llama-3.1-70b-versatile", # Best balance of speed/quality  
    "powerful" => "llama-3.1-405b-reasoning", # Most capable, slower
    "code" => "llama-3.1-70b-versatile",   # Best for code generation
    "mixtral" => "mixtral-8x7b-32768"      # Alternative high-quality model
)

end
