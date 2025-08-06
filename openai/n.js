const { OpenAI } = require("openai");

const client = new OpenAI({
    baseURL: "https://router.huggingface.co/v1",
    apiKey: "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",
});

const chatCompletion = await client.chat.completions.create({
    model: "openai/gpt-oss-20b:fireworks-ai",
    messages: [
        {
            role: "user",
            content: "What is the capital of France?",
        },
    ],
});

console.log(chatCompletion.choices[0].message);