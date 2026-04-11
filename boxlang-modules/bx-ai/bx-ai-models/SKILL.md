---
name: bx-ai-models
description: Use this skill when configuring AI models with aiModel(): selecting providers, setting default parameters, structured output schemas, working with the service BIF aiService(), and pre-configuring providers in module settings.
---

# bx-ai: Models & Providers

## `aiModel()` BIF

```java
// Signature
aiModel( provider="", params={}, apiKey="" )
```

Returns a reusable model object used in pipelines, agents, and direct calls.

```javascript
// Basic — uses default provider from module config
model = aiModel()

// Specific provider
model = aiModel( provider: "openai" )
model = aiModel( provider: "claude" )
model = aiModel( provider: "gemini" )
model = aiModel( provider: "ollama" )

// With default parameters (applied to every call on this model)
model = aiModel(
    provider: "openai",
    params  : {
        model      : "gpt-4o",
        temperature: 0.7,
        max_tokens : 2000
    }
)
```

## Available Providers

| Provider | Key Name | Notes |
|----------|----------|-------|
| OpenAI | `openai` | GPT-4o, GPT-4-turbo, o1, etc. |
| Anthropic Claude | `claude` | Claude 3.5 Sonnet, Haiku, Opus |
| Google Gemini | `gemini` | Gemini 1.5 Pro, Flash |
| Grok (xAI) | `grok` | Grok-2 |
| Groq | `groq` | Ultra-fast inference; Llama, Mixtral |
| DeepSeek | `deepseek` | DeepSeek-R1, DeepSeek-V3 |
| Ollama | `ollama` | Local models — no API key needed |
| Mistral | `mistral` | Mistral Large, Pixtral |
| Perplexity | `perplexity` | Online search-augmented |

## Module-Level Provider Config (Recommended)

Configure providers once in `ModuleConfig.bx` or `boxlang.json` rather than repeating API keys in every call:

```javascript
// ModuleConfig.bx
moduleSettings = {
    "bx-ai": {
        defaultProvider: "openai",
        providers: {
            openai: {
                apiKey: server.system.environment.OPENAI_API_KEY,
                model : "gpt-4o"
            },
            claude: {
                apiKey: server.system.environment.ANTHROPIC_API_KEY,
                model : "claude-3-5-sonnet-20241022"
            }
        }
    }
}
```

With pre-configured providers you can omit `apiKey` everywhere:

```javascript
// No apiKey needed — resolved from module config
result = aiChat( "Hello" )
model  = aiModel( provider: "claude" )
agent  = aiAgent( name: "Bot", model: aiModel( provider: "openai" ) )
```

## `aiService()` — Service-Level Access

```javascript
// Get the global AI service
service = aiService()

// List configured providers
providers = service.getProviders()

// Get a specific provider instance
openaiProvider = service.getProvider( "openai" )

// Set the default provider at runtime
service.setDefaultProvider( "claude" )
```

## Switching Models per Call

```javascript
// Override model on a per-request basis via params
result = aiChat(
    "Complex reasoning task",
    { model: "o1-preview", temperature: 1 },
    { provider: "openai" }
)

// Use a cheaper model for simple tasks
simple = aiChat(
    "Is this email spam? Yes or No.",
    { model: "gpt-4o-mini", temperature: 0.0 },
    { provider: "openai" }
)
```

## Common Pitfalls

- ❌ `aiModel( "gpt-4o" )` is WRONG — `gpt-4o` is a model name, not provider
- ✅ `aiModel( provider: "openai", params: { model: "gpt-4o" } )` is correct
- ❌ Never hardcode API keys in source code — use environment variables
- ✅ Configure all providers in module settings for centralized management
