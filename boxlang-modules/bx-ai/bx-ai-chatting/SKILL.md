---
name: bx-ai-chatting
description: "Use this skill when writing BoxLang AI chat code: aiChat(), aiChatAsync(), aiChatStream(), aiMessage(), params (temperature, max_tokens, model), options (provider, apiKey, returnFormat, timeout), provider selection, return formats, multi-turn conversations, normalized reasoning, and error handling."
---

# bx-ai: Chatting with AI

> BoxLang is the AI-native software productivity platform for building, modernizing and running applications, with developers and AI agents working together.

## Core BIF: `aiChat()`

```javascript
// Signature
aiChat( messages, params={}, options={}, headers={} )
```

- `messages`: string, a message struct, an array of message structs, or an `aiMessage()` object
- `params`: model parameters sent to the provider (`temperature`, `max_tokens`, `model`, `top_p`, `stop`, etc.)
- `options`: `provider`, `apiKey`, `timeout` (seconds, module default 90), `returnFormat`, `logRequest`, `logResponse`, `logRequestToConsole`, `logResponseToConsole`
- `headers`: struct of extra HTTP headers for the request
- Returns: the message content string by default (`returnFormat: "single"`)

## Simple Usage

```javascript
// Uses the configured default provider
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
    temperature : 0.7,      // 0.0 (deterministic) up to creative
    max_tokens  : 1000,     // max response length
    model       : "gpt-4o", // provider-specific model name
    top_p       : 1.0,      // nucleus sampling (use OR temperature, not both)
    stop        : ["\n\n"]  // stop sequences
}
```

Params are passed through to the provider, so valid names depend on the provider.

## Return Formats

Valid `options.returnFormat` strings: `single` (default), `all`, `raw`, `json`, `xml`. Anything else throws `InvalidArgument`.

| Value | Returns |
|-------|---------|
| `single` | The message content string |
| `all` | Array of choices (OpenAI-shaped providers); for `claude`, the array of content blocks |
| `raw` | The full provider response (struct) |
| `json` | Parsed JSON from the reply (struct/array); empty struct if none is found |
| `xml` | Parsed XML document |

```javascript
text = aiChat( "Hello" )

// Full provider response (OpenAI-shaped providers)
response = aiChat( "Hello", {}, { returnFormat: "raw" } )
println( response.choices.first().message.content )
println( response.usage.total_tokens )   // usage keys: prompt_tokens, completion_tokens, total_tokens

// A class, struct, or array may also be passed as returnFormat for structured output
```

`raw` returns the provider's own envelope, so for `claude` it is Anthropic's native shape, not `choices[]`.

## Multi-Turn Conversations

```javascript
messages = [
    { role: "system",    content: "You are a helpful assistant." },
    { role: "user",      content: "What is 2+2?" },
    { role: "assistant", content: "4" },
    { role: "user",      content: "Multiply that by 10." }
]

result = aiChat( messages )
```

`aiMessage()` is a fluent builder; the method name is the role, and `bind()` fills `${placeholders}`:

```javascript
msg = aiMessage()
    .system( "You are a helpful assistant." )
    .user( "Tell me about ${topic}" )
    .bind( { topic: "BoxLang" } )

result = aiChat( msg.render() )
```

## Async Chat

```javascript
// Non-blocking, returns a BoxLang Future
future = aiChatAsync( "Explain quantum entanglement" )

// Do other work here...

response = future.get()
```

`aiChatAsync()` takes the same arguments as `aiChat()`.

## Streaming Responses

```javascript
// aiChatStream( messages, callback, params={}, options={}, headers={} )
aiChatStream(
    "Write a short story about a robot",
    ( chunk ) => {
        // chunk is an OpenAI-shaped chat.completion.chunk struct
        print( chunk.choices?.first()?.delta?.content ?: "" )
    },
    { temperature: 0.7 },
    { provider: "openai" }
)
```

- The callback is the 2nd argument, and is called once per chunk with the parsed chunk struct.
- `aiChatStream()` returns nothing. It has no `returnFormat`.
- `delta.content` may be absent on some chunks (role, reasoning, or usage chunks), so default it with `?: ""`.

## Reasoning (Normalized)

Reasoning/thinking text is surfaced on one standard key regardless of provider, and is never merged into `content`.

- Streaming: `chunk.choices.first().delta.reasoning`. Providers that emit `reasoning_content` (for example DeepSeek) or `thinking` are mapped onto `delta.reasoning`. Claude extended thinking is emitted as `delta.reasoning` chunks before the text.
- Sync (OpenAI-shaped providers): `response.choices[ i ].message.reasoning`, available with `returnFormat: "raw"` or `"all"`. `reasoning_content` and `thinking` are mapped onto it.
- Sync Claude with `returnFormat: "raw"`: `response.reasoning` at the top level of the native envelope (only present when the model produced thinking blocks).
- Absence is normal: if a model has no reasoning, the key is simply not set. Always read it with `?.` and a default.

```javascript
aiChatStream( "Solve 17 * 24", ( chunk ) => {
    var delta = chunk.choices?.first()?.delta ?: {}
    if( delta.keyExists( "reasoning" ) ) print( "[thinking] " & delta.reasoning )
    if( delta.keyExists( "content" ) )   print( delta.content ?: "" )
}, {}, { provider: "deepseek" } )
```

## Provider Configuration

```javascript
result = aiChat( "Hello", {}, { provider: "openai", apiKey: "sk-..." } )
result = aiChat( "Hello", {}, { provider: "claude" } )
result = aiChat( "Hello", {}, { provider: "ollama" } )   // local
```

The provider must support chat, otherwise `UnsupportedCapability` is thrown. If no `apiKey` is passed, the `<PROVIDER>_API_KEY` environment setting is used, then the module `apiKey` setting. Valid provider keys and their capabilities are in the `bx-ai-models` skill. For speech and transcription, see the `bx-ai-audio` skill.

## Error Handling

There is no exceptions package. Errors are thrown as plain BoxLang exceptions with a `type`:

- `ProviderError`: a streaming request failed (thrown from `aiChatStream()`)
- `JsonDeserializationError`: the provider response was not valid JSON
- `ProviderNotSupported`: unknown `provider` key
- `UnsupportedCapability`: the provider cannot chat
- `InvalidArgument`: invalid `returnFormat`

```javascript
try {
    result = aiChat( "Hello", {}, { provider: "openai" } )
} catch ( any e ) {
    if( e.type == "ProviderNotSupported" ) {
        logError( "Bad provider: #e.message#" )
    } else {
        logError( "AI error [#e.type#]: #e.message#" )
    }
}
```

Failures and rate limits also announce the `onAIError` and `onAIRateLimitHit` interception points.

## Common Pitfalls

- Do NOT pass `model:` as a top-level BIF argument: put it in `params`
- Do NOT use both `temperature` and `top_p` simultaneously
- Do NOT put the callback last in `aiChatStream()`: it is the 2nd argument
- Do NOT use `returnFormat: "full"` or `"choices"`: they are not valid values
- Handle provider errors in production code
- Use `returnFormat: "raw"` when you need token counts, finish reasons or reasoning
- Use `aiChatAsync()` for long-running requests in web handlers
