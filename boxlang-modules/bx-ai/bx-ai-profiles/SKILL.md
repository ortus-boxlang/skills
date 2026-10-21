---
name: bx-ai-profiles
description: "Use this skill when configuring or selecting named bx-ai profiles (a named provider, model, params, options and API key): the profiles setting, defaultProfile, options.profile in aiChat()/aiEmbed(), profile in aiModel()/aiAgent()/aiService(), switching an agent with withProfile() or for one run, listing with aiProfiles()/aiProfile()/aiProviders(), the embeddings defaults, and API key rules."
---

# bx-ai: Profiles

> BoxLang is the AI-native software productivity platform for building, modernizing and running applications, with developers and AI agents working together.

A profile is a named combination of provider, model, params, options and API key, such as `fast` (small model, temperature 0) or `planner` (another provider, more tokens). Configure it once, select it by name. Available from the bx-ai release after 3.6.0. Without a `profiles` setting nothing changes.

## Configure (`boxlang.json`)

```json
{
  "modules": { "bxai": { "settings": {
    "provider": "openai",
    "defaultParams": { "temperature": 0.7 },
    "profiles": {
      "fast": {
        "description": "Cheap and quick, for small tasks",
        "provider": "openai",
        "model": "gpt-4.1-mini",
        "params": { "temperature": 0 },
        "apiKeyEnv": "OPENAI_API_KEY"
      },
      "planner": {
        "provider": "claude",
        "model": "claude-opus-5-5",
        "params": { "max_tokens": 8192 },
        "apiKeyEnv": "CLAUDE_API_KEY"
      }
    },
    "defaultProfile": ""
  } } }
}
```

| Key | Meaning |
|-----|---------|
| `description` | Free text for people and UIs, returned by `aiProfile()` and `aiProfiles()` |
| `provider` | Provider key. Empty uses the top level `provider` |
| `model` | Shorthand for `params.model` |
| `params` | Request params for this profile |
| `options` | Request options for this profile (`timeout`, logging, ...) |
| `apiKeyEnv` | The NAME of the env var that holds the key. Preferred |
| `apiKey` | A literal key. Avoid it |

- `default` always exists: it is the top level `provider`, `apiKey` and `defaultParams`. `defaultProfile` makes another profile the one used when a call names no provider.
- Params layer: `defaultParams`, then `providers.<name>.params`, then the profile, then the params of the call. Explicit provider, apiKey, params and options always win.
- Rejected when the module starts (`InvalidConfiguration`): a profile named like a provider (`openai`, `claude`, ...), named `default`, a name with characters other than letters, numbers, `_` and `-`, a `defaultProfile` that does not exist. An unknown profile at call time throws `ProfileNotFound`.

## Select a profile

```javascript
// Chat and embeddings: options.profile
aiChat( "Summarize this", {}, { profile: "fast" } )
aiChatStream( "Tell a story", chunk => print( chunk ), {}, { profile: "fast" } )
aiEmbed( "Hello", {}, { profile: "embed" } )

// Models, services and agents: profile argument
model   = aiModel( profile: "fast" )
service = aiService( profile: "planner" )
agent   = aiAgent( name: "support", profile: "fast" )
```

- `aiAgent( model: ..., profile: ... )` throws `InvalidArgument`. Pass one or the other.
- A profile key is only used with the profile's own provider. Passing a different `provider` explicitly keeps your provider and ignores the profile key.

## Switch an agent

```javascript
// One run only. The agent keeps its own profile, memory is shared
agent.run( "Plan the migration", {}, { profile: "planner" } )
agent.stream( onChunk, "Plan the migration", {}, { profile: "planner" } )

// For good. Replaces the model, keeps memory, tools, sub-agents, params and options
agent.withProfile( "planner" )
agent.getProfile()   // "planner", empty when the agent was given a model directly
```

- There is no per run switch for a sub-agent. Seed it: `aiAgent( name: "researcher", profile: "planner" )` and pass it in `subAgents`.
- `onAIProfileSwitch` fires with `{ agent, from, to, scope }`, scope is `agent` or `run`.

## List (for chat UIs and remote control)

```javascript
aiProfiles()          // [ { name, description, provider, model, params, options, apiKeyEnv, hasApiKey, isDefault } ]
aiProfile( "fast" )   // one profile, "" or no argument is the default profile
aiProviders()         // [ { name, isDefault, hasApiKey } ]
```

These never return an API key, only `hasApiKey` and the env var name. Params and options that look like secrets (`key`, `token`, `secret`, `password`) are masked as `****`. A terminal chat `/profile` command is `aiProfiles()` plus `agent.withProfile( name )`.

## Embeddings defaults

`aiEmbed()` used the chat provider. Set its own default, or use a profile:

```json
"embeddings": { "defaultProvider": "openai", "defaultModel": "text-embedding-3-small", "defaultApiKey": "" }
```

Empty values keep the old behavior. Order of priority: the call, then `options.profile`, then `embeddings`, then the top level provider. An empty `defaultApiKey` uses `<PROVIDER>_API_KEY`, never the chat provider's key.

## Rules

- ❌ `aiChat( "Hi", {}, {}, "fast" )`: the profile is `options.profile`
- ❌ A profile named `openai` or `default`
- ❌ Putting a key in a profile when an env var will do: use `apiKeyEnv`
- ✅ Test with the `mock` provider: `MockService::getRecorded()` entries have `model`, `messages` and `params`
