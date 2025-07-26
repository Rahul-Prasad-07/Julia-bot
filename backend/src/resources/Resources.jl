module Resources

include("types/Errors.jl")
include("types/Telegram.jl")
include("utils/Gemini.jl")
include("utils/Groq.jl")

using .Telegram
using .Gemini
using .Groq

end