# bx-ai Skills

Skills for the [BoxLang AI module](https://ai.ortusbooks.com/) — a comprehensive library for integrating AI capabilities into BoxLang applications.

## Available Skills

| Skill | Load When... |
|-------|--------------|
| [bx-ai-chatting](./bx-ai-chatting/SKILL.md) | Using `aiChat()`, `aiChatAsync()`, `aiChatStream()`, handling responses, multi-turn conversations |
| [bx-ai-models](./bx-ai-models/SKILL.md) | Configuring providers with `aiModel()`, `aiService()`, module-level provider setup |
| [bx-ai-profiles](./bx-ai-profiles/SKILL.md) | Named profiles (provider, model, params, options, key), `options.profile`, `aiAgent( profile: )`, `agent.withProfile()`, `aiProfiles()`, embeddings defaults |
| [bx-ai-agents](./bx-ai-agents/SKILL.md) | Building agents with `aiAgent()`, tools, skills, MCP servers, multi-agent hierarchies |
| [bx-ai-mcp](./bx-ai-mcp/SKILL.md) | Consuming and exposing MCP servers: `MCP()` clients over HTTP and stdio (child processes), `mcpServers` on agents, `MCPServer()`, `MCPResponse`, stdio security |
| [bx-ai-tools](./bx-ai-tools/SKILL.md) | Creating tools with `aiTool()`, parameter descriptions, `aiToolRegistry()` |
| [bx-ai-memory](./bx-ai-memory/SKILL.md) | Memory systems with `aiMemory()`, multi-tenant isolation, choosing memory types |
| [bx-ai-rag](./bx-ai-rag/SKILL.md) | RAG systems, `aiDocuments()`, `aiEmbed()`, vector stores, document ingestion |
| [bx-ai-pipelines](./bx-ai-pipelines/SKILL.md) | Building pipelines with `aiMessage()`, `aiTransform()`, `.to()` chaining, multi-model workflows |
| [bx-ai-audio](./bx-ai-audio/SKILL.md) | Text-to-speech with `aiSpeak()`, streaming speech with `aiSpeakStream()`, `aiTranscribe()`, `aiTranslate()`, Cartesia, voice agents |

## Combining Skills

For complex tasks, load multiple skills together:

- **Conversational AI app** → `bx-ai-chatting` + `bx-ai-memory`
- **Autonomous agent** → `bx-ai-agents` + `bx-ai-tools` + `bx-ai-memory`
- **Several model setups (fast, planner) or switching models at runtime** → `bx-ai-profiles` + `bx-ai-models` (add `bx-ai-agents` to switch an agent)
- **Agent that uses MCP servers or a browser** → `bx-ai-agents` + `bx-ai-mcp`
- **RAG system** → `bx-ai-rag` + `bx-ai-agents`
- **AI pipeline** → `bx-ai-pipelines` + `bx-ai-models`
- **Agent that edits audio files** → `bx-ai-agents` + `bx-ai-tools` + `bx-audio` (from `boxlang-modules/bx-audio`)
- **Voice agent or speech app** → `bx-ai-audio` + `bx-ai-models` (add `bx-ai-agents` for an agent that speaks)
- **Human approvals or chat platform gateways** → `bx-ai-agents`
- **Full AI application** → all skills

## Critical Rules (Apply to All bx-ai Skills)

- ❌ `aiModel( "gpt-4o" )` — WRONG (model name is not a provider)
- ✅ `aiModel( provider: "openai", params: { model: "gpt-4o" } )` — correct
- ❌ `aiMemory( "windowed" )`: the type key is `window`
- ❌ `aiAgent().build()` — `.build()` does not exist
- ❌ `agent.withMemory( mem )` — `.withMemory()` does not exist
- ✅ Pass `memory:` in the `aiAgent()` constructor
