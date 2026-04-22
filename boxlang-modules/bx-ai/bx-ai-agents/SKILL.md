---
name: bx-ai-agents
description: "Use this skill when building AI agents with aiAgent(): instructions, custom models, tools, skills (always-on and lazy), MCP servers, memory, fluent configuration, multi-agent hierarchies, streaming, and agent middleware."
---

# bx-ai: AI Agents

## `aiAgent()` BIF

```java
// Signature
aiAgent(
    name           = "",
    description    = "",
    instructions   = "",
    model          = null,         // aiModel() instance
    params         = {},           // default model params
    tools          = [],           // array of aiTool() instances
    skills         = [],           // always-on AiSkill instances (v3.0+)
    availableSkills= [],           // lazy-loaded skills pool (v3.0+)
    memory         = null,         // aiMemory() instance
    mcpServers     = [],           // array of MCP server configs (v3.0+)
    middleware     = []            // middleware chain
)
```

## Basic Agent

```javascript
agent = aiAgent(
    name        : "Assistant",
    description : "A helpful assistant",
    instructions: "Be concise, accurate, and friendly."
)

response = agent.run( "What is BoxLang?" )
println( response )
```

## Agent with a Custom Model

```javascript
model = aiModel( provider: "claude", params: { model: "claude-3-5-sonnet-20241022" } )

agent = aiAgent(
    name  : "Claude Agent",
    model : model,
    params: { temperature: 0.7, max_tokens: 2000 }
)
```

## Agent with Tools

```javascript
// Define tools
weatherTool = aiTool(
    "get_weather",
    "Get current weather for a location",
    location -> getWeatherData( location )
).describeLocation( "City name, e.g. Boston, MA" )

dbTool = aiTool(
    "query_users",
    "Look up users in the database",
    filter -> queryExecute( "SELECT * FROM users WHERE name LIKE :name", { name: "%#filter#%" } )
).describeFilter( "Search term for user names" )

// Agent with tools
agent = aiAgent(
    name        : "DataAgent",
    instructions: "Use tools to fetch real-time data. Always be accurate.",
    tools       : [ weatherTool, dbTool ]
)

response = agent.run( "How many users are named Smith and what's the weather in Boston?" )
```

## Agent with Skills (v3.0+)

Skills inject markdown-based knowledge into the agent system context.

```javascript
import bxModules.bxai.models.skills.AiSkill;

agent = aiAgent(
    name           : "CodeReviewer",
    instructions   : "Review code for quality and security issues",
    // Always-on: content always injected into system context
    skills         : [
        aiSkill( ".agents/skills/security/SKILL.md" ),
        aiSkill( ".agents/skills/code-style/SKILL.md" )
    ],
    // Lazy-loaded: agent picks relevant ones on demand
    availableSkills: aiSkill( ".agents/skills/languages" )  // scans entire directory
)
```

### Inline Skill Definition

```javascript
agent = aiAgent(
    name  : "Writer",
    skills: [
        aiSkill(
            name       : "tone",
            description: "Professional writing tone",
            content    : "Always write in a clear, professional tone. Avoid jargon."
        )
    ]
)
```

## Agent with Memory

```javascript
// Windowed conversation memory (keeps last N messages)
memory = aiMemory( "windowed", config: { maxMessages: 20 } )

agent = aiAgent(
    name        : "ConversationalBot",
    instructions: "Maintain context across the conversation",
    memory      : memory
)

// Subsequent calls remember previous context
agent.run( "My name is Alice." )
agent.run( "What is my name?" )  // → "Your name is Alice."
```

## Agent with MCP Servers (v3.0+)

```javascript
agent = aiAgent(
    name      : "ResearchAgent",
    mcpServers: [
        {
            url      : "http://localhost:3000/mcp",
            toolNames: [ "web_search", "fetch_page" ]
        },
        {
            url      : "https://api.example.com/mcp",
            apiKey   : server.system.environment.MCP_API_KEY,
            toolNames: [ "*" ]   // load all tools from this server
        }
    ]
)
```

## Fluent Configuration

```javascript
agent = aiAgent( name: "Assistant" )
    .setModel( aiModel( provider: "claude" ) )
    .setInstructions( "Be concise and helpful" )
    .addTool( searchTool )
    .addTool( calcTool )
    .addMemory( conversationMemory )
    .setParam( "temperature", 0.6 )
    .setParam( "max_tokens", 1500 )
```

## Streaming Agent Responses

```javascript
agent = aiAgent(
    name        : "StreamBot",
    instructions: "Respond with detailed explanations"
)

// Stream responses token by token
agent.stream( "Explain how Hibernate ORM works", chunk -> {
    print( chunk )
})
```

## Multi-Agent Hierarchy

```javascript
// Specialized sub-agents
coder   = aiAgent( name: "Coder",   instructions: "Write clean BoxLang code" )
tester  = aiAgent( name: "Tester",  instructions: "Write TestBox test cases" )
reviewer= aiAgent( name: "Reviewer",instructions: "Review code for bugs and performance" )

// Router agent delegates to sub-agents
router = aiAgent(
    name        : "Router",
    instructions: "Route tasks to the appropriate specialist agent",
    tools       : [
        aiTool( "code",   "Write code", task -> coder.run( task ) ),
        aiTool( "test",   "Write tests", task -> tester.run( task ) ),
        aiTool( "review", "Review code", task -> reviewer.run( task ) )
    ]
)

result = router.run( "Write a BoxLang class for user authentication and tests for it" )
```

## Common Pitfalls

- ❌ Do NOT call `.build()` on `aiAgent()` — it doesn't exist
- ❌ Do NOT call `.withMemory()` — pass `memory:` in the constructor
- ❌ Do NOT call `.withInstructions()` — use `instructions:` in constructor or `.setInstructions()`
- ✅ Always give agents clear, specific `instructions`
- ✅ Use `availableSkills` (lazy) for large skill libraries to avoid bloating context
- ✅ Use `skills` (always-on) only for core behavioral rules the agent must always follow
