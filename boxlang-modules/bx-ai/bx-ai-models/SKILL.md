---
name: bx-ai-models
description: "Use this skill when configuring AI models with aiModel(): selecting providers, the full provider list with capabilities and API key resolution, setting default parameters, using aiService(), and pre-configuring providers in module settings (provider, apiKey, defaultParams, providers)."
---

# bx-ai: Models & Providers

> BoxLang is the AI-native software productivity platform for building, modernizing and running applications, with developers and AI agents working together.

## `aiModel()` BIF

```javascript
// Signature (all arguments optional)
aiModel( provider, apiKey, tools=[], params={}, options={}, middleware=[], skills=[], mcpServers=[] )
```

Returns a reusable model runnable used in pipelines, agents, and direct calls. Always use named arguments beyond the first.

```javascript
// Uses the default provider from module settings
model = aiModel()

// Specific provider
model = aiModel( provider: "claude" )

// With default parameters (applied to every call on this model)
model = aiModel(
    provider: "openai",
    params  : {
        model      : "gpt-4o",
        temperature: 0.7,
        max_tokens : 2000
    },
    options : { timeout: 60 }
)
```

## Available Providers

The valid provider keys are exactly: `bedrock`, `cartesia`, `claude`, `cloudflare`, `cohere`, `deepseek`, `docker`, `elevenlabs`, `gemini`, `grok`, `groq`, `huggingface`, `minimax`, `mistral`, `mock`, `ollama`, `openai`, `openai-compatible`, `openrouter`, `perplexity`, `voyage`. Any other key throws `ProviderNotSupported` (unless another module answers the `onMissingAiProvider` announcement).

Capabilities come from each service's static `CAPABILITIES` array. Default model is the chat model in the service's default params.

| Key | Notes | Capabilities |
|-----|-------|--------------|
| `bedrock` | AWS Bedrock. Default modelId `anthropic.claude-3-sonnet-20240229-v1:0`, region `us-east-1` | chat, stream, embeddings |
| `cartesia` | Audio only. Default speech model `sonic-3.6`, transcription `ink-whisper` | speech, speechStream, transcription |
| `claude` | Anthropic. Default `claude-sonnet-5` | chat, stream |
| `cloudflare` | Workers AI. Default `@cf/openai/gpt-oss-20b`. Requires account ID | chat, stream, embeddings |
| `cohere` | Default `command-a-03-2025` | chat, stream, embeddings |
| `deepseek` | Default `deepseek-chat` | chat, stream, embeddings |
| `docker` | Docker Model Runner (local, OpenAI-compatible). Default base URL `http://model-runner.docker.internal/engines/v1`, no default model | chat, stream, embeddings (inherited from `openai-compatible`) |
| `elevenlabs` | Audio only. Default speech model `eleven_multilingual_v2` | speech, speechStream, transcription |
| `gemini` | Google. Default `gemini-2.5-flash` | chat, stream, embeddings, image, speech, speechStream, transcription |
| `grok` | xAI. Default `grok-4-1-fast-reasoning` | chat, stream, image, speech |
| `groq` | Default `openai/gpt-oss-20b`, transcription `whisper-large-v3` | chat, stream, transcription, translation |
| `huggingface` | Default `openai/gpt-oss-120b:groq` | chat, stream, embeddings |
| `minimax` | Default `MiniMax-M2.5-highspeed` | chat, stream, embeddings |
| `mistral` | Default `mistral-small-latest` | chat, stream, embeddings, speech, speechStream, transcription |
| `mock` | Test provider, no network. Default model `mock-model` | chat, stream |
| `ollama` | Local models. Default `qwen3:0.6b` | chat, stream, embeddings |
| `openai` | Default `gpt-5.6-luna` | chat, stream, embeddings, image, speech, speechStream, transcription, translation |
| `openai-compatible` | Any OpenAI-style endpoint (vLLM, LM Studio, etc). `baseURL` option, default `http://localhost:8080/v1`; API key optional | chat, stream, embeddings |
| `openrouter` | Default `openrouter/auto` | chat, stream, embeddings, image |
| `perplexity` | Default `sonar` | chat, stream |
| `voyage` | Embeddings only. Default `voyage-3` | embeddings |

Check capabilities at runtime with `aiService( "openai" ).getCapabilities()` or `.hasCapability( "stream" )`. For speech, streaming speech and transcription, see the `bx-ai-audio` skill.

## API Key Resolution

`aiService()` resolves the key in this order:

1. `apiKey` passed in the call (`options.apiKey`, or the `apiKey` argument of `aiModel()`)
2. Environment/system setting `<PROVIDER>_API_KEY`, where the provider key is upper-cased as is (`OPENAI_API_KEY`, `CLAUDE_API_KEY`, `GEMINI_API_KEY`, `GROQ_API_KEY`). Note it is the BoxLang provider key, so Claude is `CLAUDE_API_KEY`, not `ANTHROPIC_API_KEY`.
3. The module-level `apiKey` setting

Extra requirements:

- `cloudflare`: account ID from the `accountId` option, else the `CLOUDFLARE_ACCOUNT_ID` environment setting. Missing it throws an error on use.
- `bedrock`: uses AWS credentials, not a plain API key. Options: `region`, `awsAccessKeyId`, `awsSecretAccessKey`, `awsSessionToken`, `modelId`, `baseURL`, `bearerToken`. Falls back to `AWS_ACCESS_KEY_ID`, `AWS_SECRET_ACCESS_KEY`, `AWS_SESSION_TOKEN`, `AWS_REGION` / `AWS_DEFAULT_REGION`, `AWS_BEARER_TOKEN_BEDROCK`, and ECS/EKS container credentials. `configure( "string" )` sets the `modelId`, not a key.

```javascript
aiChat( "Hi", {}, { provider: "cloudflare", accountId: "abc123" } )
```

## Module-Level Config (Recommended)

Settings live under `modules.bxai.settings` in `boxlang.json`. Top-level keys include `provider` (default provider, default `"openai"`), `apiKey`, `defaultParams`, `timeout` (default 90), `returnFormat` and the `log*` flags. Per-provider defaults go in `providers.<providerKey>` with `params` and `options` sub-structs.

```json
{
  "modules": {
    "bxai": {
      "settings": {
        "provider": "claude",
        "defaultParams": { "temperature": 0.7 },
        "providers": {
          "openai": {
            "params" : { "model": "gpt-4o" },
            "options": { "timeout": 60 }
          },
          "claude": {
            "params": { "model": "claude-sonnet-5", "max_tokens": 2048 }
          }
        }
      }
    }
  }
}
```

Merge order for params: `defaultParams`, then `providers.<key>.params`, then per-call `params`. Prefer env vars (`OPENAI_API_KEY`, ...) over hardcoding keys in settings.

```javascript
// No apiKey needed when env vars or settings supply it
result = aiChat( "Hello" )
model  = aiModel( provider: "claude" )
agent  = aiAgent( name: "Bot", model: aiModel( provider: "openai" ) )
```

## `aiService()`: Direct Provider Access

```javascript
// aiService( provider, options={} ): returns a configured provider service instance.
// options may be a struct or a simple API key string.
service = aiService( "openai" )
service = aiService( provider: "openai", options: { apiKey: "sk-..." } )

service.getName()
service.getCapabilities()           // array of capability strings
service.hasCapability( "stream" )   // boolean
```

There is no `getProviders()`, `getProvider()` or `setDefaultProvider()`. To change the default provider set the `provider` module setting. Use `aiModel()` for pipelines and agents; use `aiService()` when you need the raw provider.

## Switching Models per Call

```javascript
// Override model per request via params
result = aiChat(
    "Complex reasoning task",
    { model: "gpt-4o", temperature: 1 },
    { provider: "openai" }
)
```

## Audio

Speech (`aiSpeak`, `aiSpeakStream`) and transcription (`aiTranscribe`) are covered in the `bx-ai-audio` skill. Providers with audio capabilities are marked in the table above.

## Common Pitfalls

- `aiModel( "gpt-4o" )` is WRONG: the first argument is the provider key, not a model name
- `aiModel( provider: "openai", params: { model: "gpt-4o" } )` is correct
- Never hardcode API keys in source code: use environment variables
- Use only the provider keys listed above; they are lowercase
- Configure defaults once in module settings for centralized management
