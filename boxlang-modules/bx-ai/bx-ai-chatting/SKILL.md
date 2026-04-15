---
name: bx-ai-chatting
description: "Use this skill when writing BoxLang AI chat code: aiChat(), aiChatAsync(), aiChatStream(), parameters (temperature, max_tokens, model), provider selection, API keys, return formats, multi-turn conversations, and error handling."
---

# bx-ai: Chatting with AI

## Core BIF: `aiChat()`

```java
// Signature
aiChat( message, params={}, options={} )
```

- `message` — string or array of message structs
- `params` — model parameters (`temperature`, `max_tokens`, `model`, `top_p`, `stop`, etc.)
- `options` — provider options (`provider`, `apiKey`, `returnFormat`, `timeout`)
- Returns: string by default; array or struct depending on `returnFormat`

## Simple Usage

```javascript
// Simplest call — uses configured default provider
answer = aiChat( "What is the capital of France?" )

// With parameters
code = aiChat(
    "Write a Fibonacci function in BoxLang",
    { temperature: 0.2, max_tokens: 500 }
)

// With a specific provider
result = aiChat(
    "Summarize this text: ...",
    { temperature: 0.5 },
    { provider: "claude" }
)
```

## Parameters Reference

```javascript
params = {
    temperature : 0.7,      // 0.0 (deterministic) → 1.0+ (creative)
    max_tokens  : 1000,     // max response length
    model       : "gpt-4o", // provider-specific model name
    top_p       : 1.0,      // nucleus sampling (use OR temperature, not both)
    stop        : ["\n\n"]  // stop sequences
}
```

Temperature guide:
- `0.0–0.3` — Facts, code, data extraction
- `0.5–0.7` — General chat, balanced
- `0.8–1.0` — Creative writing, brainstorming

## Return Formats

```javascript
// Default: returns string
text = aiChat( "Hello" )

// Full response struct (includes usage, model, finish_reason, etc.)
response = aiChat( "Hello", {}, { returnFormat: "full" } )
println( response.content )      // the AI text
println( response.usage.total )  // tokens used

// Multiple choices/candidates
choices = aiChat( "Tell a joke", { n: 3 }, { returnFormat: "choices" } )
```

## Multi-Turn Conversations

```javascript
// Pass an array of message structs
messages = [
    { role: "system",    content: "You are a helpful assistant." },
    { role: "user",      content: "What is 2+2?" },
    { role: "assistant", content: "4" },
    { role: "user",      content: "Multiply that by 10." }
]

result = aiChat( messages )
// "40"
```

## Async Chat

```javascript
// Non-blocking — returns a BoxFuture
future = aiChatAsync( "Explain quantum entanglement" )

// Do other work here...

response = future.get()    // blocks until complete
// or with timeout:
response = future.get( 30, "seconds" )
```

## Streaming Responses

```javascript
// aiChatStream — provides real-time chunks
aiChatStream(
    "Write a short story about a robot",
    {},
    {},
    ( chunk ) -> {
        // called for each token chunk
        print( chunk )
    }
)
```

## Provider Configuration

```javascript
// Provider in options
result = aiChat( "Hello", {}, { provider: "openai", apiKey: "sk-..." } )
result = aiChat( "Hello", {}, { provider: "claude", apiKey: "sk-ant-..." } )
result = aiChat( "Hello", {}, { provider: "gemini" } )
result = aiChat( "Hello", {}, { provider: "ollama" } )   // local, no key needed

// Available providers: openai, claude, gemini, grok, groq, deepseek, ollama, mistral
```

## Error Handling

```javascript
try {
    result = aiChat( "Hello", {}, { provider: "openai" } )
} catch ( bxModules.bxai.exceptions.AIProviderException e ) {
    // Provider-level error (bad key, rate limit, etc.)
    logError( "AI provider error: #e.message#" )
} catch ( bxModules.bxai.exceptions.AITimeoutException e ) {
    // Response took too long
    return getDefaultResponse()
}
```

## Common Pitfalls

- ❌ Do NOT pass `model:` as a top-level BIF argument — put it in `params`
- ❌ Do NOT use both `temperature` and `top_p` simultaneously
- ❌ Do NOT forget to handle provider exceptions in production code
- ✅ Set `returnFormat: "full"` when you need token counts or finish reasons
- ✅ Use `aiChatAsync()` for long-running requests in web handlers
