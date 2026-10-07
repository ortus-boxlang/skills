---
name: bx-ai-agents
description: "Use this skill when building AI agents with aiAgent(): instructions, custom models, tools, skills (always-on and lazy), MCP servers, memory, fluent configuration, sub-agents and multi-agent hierarchies, streaming, middleware (logging, retry, guardrails, flight recorder), human in the loop approvals with suspend/resume, run control (cancelRun/steerRun), and gateways (aiGateway, aiGatewaySession)."
---

# bx-ai: AI Agents

> BoxLang is the AI-native software productivity platform for building, modernizing and running applications, with developers and AI agents working together.

## `aiAgent()` BIF

```javascript
// Signature (all optional)
aiAgent(
    name            = "BxAi",
    description     = "",
    instructions    = "",
    model           = aiModel(),      // aiModel() instance
    memory          = aiMemory(),     // one IAiMemory or an array of them
    tools           = [],             // array of aiTool() instances
    subAgents       = [],             // other agents, auto-wrapped as tools
    skills          = [],             // always-on AiSkill instances
    availableSkills = [],             // lazy-loaded skills pool
    params          = {},             // default model params
    options         = {},             // default run options (threadId, userId, conversationId, ...)
    middleware      = [],             // IAiMiddleware, struct of closures, or array of either
    checkpointer    ,                 // IAiMemory used to save state when a run suspends
    checkpointTTL   = 30,             // checkpoint TTL in minutes
    mcpServers      = [],             // MCP server URLs / config structs / MCPClient instances
    register        = false,          // register in aiAgentRegistry()
    module          = ""              // registry key suffix when register is true
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

`run( input, params = {}, options = {} )` returns the assistant content (`returnFormat` defaults to `single`).

## Agent with a Custom Model

```javascript
model = aiModel( provider: "claude", params: { model: "claude-sonnet-5" } )

agent = aiAgent(
    name  : "Claude Agent",
    model : model,
    params: { temperature: 0.7, max_tokens: 2000 }
)
```

## Agent with Tools

```javascript
weatherTool = aiTool(
    "get_weather",
    "Get current weather for a location",
    location -> getWeatherData( location )
).describeLocation( "City name, e.g. Boston, MA" )

agent = aiAgent(
    name        : "DataAgent",
    instructions: "Use tools to fetch real-time data. Always be accurate.",
    tools       : [ weatherTool ]
)

response = agent.run( "What's the weather in Boston?" )
```

`aiTool( name, description, callable, autoRegister = true )`. Fluent describers: `.describeMyArg( "..." )`, `.describeArg( name, text )`, `.describe( text )`. See the `bx-ai-tools` skill for more.

## Agent with Skills

Skills inject markdown knowledge into the system message.

```javascript
agent = aiAgent(
    name           : "CodeReviewer",
    instructions   : "Review code for quality and security issues",
    // Always-on: full content injected on every call (a file path returns ONE AiSkill)
    skills         : [
        aiSkill( ".agents/skills/security/SKILL.md" ),
        aiSkill( ".agents/skills/code-style/SKILL.md" )
    ],
    // Lazy: only an index is injected, the LLM loads one via the built-in loadSkill tool
    // (a directory path returns an ARRAY of AiSkill, scanned recursively)
    availableSkills: aiSkill( ".agents/skills/languages" )
)
```

`aiSkill( path, name, description = "", content = "", recurse = true )`. With `path` it loads from disk; with `name` (and no `path`) it builds an inline skill:

```javascript
aiAgent(
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
// "window" keeps the last N messages (default 100)
memory = aiMemory( "window", config: { maxMessages: 20 } )

agent = aiAgent( name: "ConversationalBot", memory: memory )

agent.run( "My name is Alice." )
agent.run( "What is my name?" )  // "Your name is Alice."
```

`aiMemory( memory, key, userId, conversationId, config )`. Common types: `window`, `cache`, `file`, `jdbc`, `summary`, `session`, `hybrid`, plus vector stores. Shared memory is scoped per call with `options: { userId, conversationId }`. See `bx-ai-memory`.

## Agent with MCP Servers

Each entry is a URL string, a config struct, or an `MCPClient`. All tools discovered on the server are loaded.

```javascript
agent = aiAgent(
    name      : "ResearchAgent",
    mcpServers: [
        "http://localhost:3000/mcp",
        { url: "https://api.example.com/mcp", token: server.system.environment.MCP_TOKEN, timeout: 5000 }
    ]
)
```

Struct keys: `url`, `token` (bearer), `timeout`, `headers`, `user` + `password` (basic auth).

## Fluent Configuration

```javascript
agent = aiAgent( name: "Assistant" )
    .setModel( aiModel( provider: "claude" ) )
    .setInstructions( "Be concise and helpful" )
    .addTool( searchTool )
    .addMemory( conversationMemory )
    .setParam( "temperature", 0.6 )
    .withMiddleware( new bxModules.bxai.models.middleware.core.LoggingMiddleware() )
    .withCheckpointer( aiMemory( "cache" ), 30 )
```

Other setters: `setName`, `setMemory` (replaces), `setTools`, `withTools`, `addSubAgent`, `setSubAgents`.

## Streaming Agent Responses

The callback comes FIRST: `stream( onChunk, input, params = {}, options = {} )`.

```javascript
agent.stream(
    chunk -> print( chunk.choices.first().delta?.content ?: "" ),
    "Explain how Hibernate ORM works"
)
```

Chunks are OpenAI-shaped structs. Reasoning-capable models also surface `choices[].delta.reasoning` (streaming) and `choices[].message.reasoning` (sync run), kept separate from content and never saved to memory. See `bx-ai-chatting` for detail.

## Sub-Agents and Multi-Agent Hierarchy

`subAgents` are registered as tools named `delegate_to_<agent-name-slug>`, described from each sub-agent's `name` and `description`. Give sub-agents a clear `description`.

```javascript
coder    = aiAgent( name: "Coder",    description: "Writes clean BoxLang code", instructions: "Write clean BoxLang code" )
tester   = aiAgent( name: "Tester",   description: "Writes TestBox tests",      instructions: "Write TestBox test cases" )
reviewer = aiAgent( name: "Reviewer", description: "Reviews code for bugs",     instructions: "Review code for bugs and performance" )

router = aiAgent(
    name        : "Router",
    instructions: "Route tasks to the appropriate specialist agent",
    subAgents   : [ coder, tester, reviewer ]
)

result = router.run( "Write a BoxLang class for user authentication and tests for it" )
```

Inspect with `getSubAgentNames()`, `getSubAgent( name )`, `hasSubAgent( name )`, `getAgentPath()`.

## Middleware

Pass one or many via `middleware:` (or `.withMiddleware()`). Built-ins live in `bxModules.bxai.models.middleware.core`.

```javascript
import bxModules.bxai.models.middleware.core.LoggingMiddleware;
import bxModules.bxai.models.middleware.core.RetryMiddleware;
import bxModules.bxai.models.middleware.core.MaxToolCallsMiddleware;
import bxModules.bxai.models.middleware.core.GuardrailMiddleware;

agent = aiAgent(
    name      : "SafeAgent",
    tools     : [ searchTool, sqlTool ],
    middleware: [
        new LoggingMiddleware( logToConsole: true ),
        new RetryMiddleware( maxRetries: 3 ),
        new MaxToolCallsMiddleware( maxCalls: 5 ),
        new GuardrailMiddleware(
            blockedTools: [ "dropTable" ],
            argPatterns : { runSql: [ { query: "(?i)drop|truncate|delete" } ] }
        )
    ]
)
```

| Class | Constructor arguments (defaults) |
|-------|----------------------------------|
| `LoggingMiddleware` | `logToFile=true, logToConsole=false, logLevel="info", prefix="[AI Middleware]"` |
| `RetryMiddleware` | `maxRetries=3, initialDelay=1000, backoffMultiplier=2, maxDelay=30000, nonRetryableTypes="InvalidInput,MaxInteractionsExceeded"` |
| `MaxToolCallsMiddleware` | `maxCalls=10` (per run) |
| `GuardrailMiddleware` | `blockedTools=[], argPatterns={}` (`{ tool: [ { param: regex } ] }`) |
| `FlightRecorderMiddleware` | `mode="passthrough"\|"record"\|"replay", fixturePath="", fixtureDir="/.agents/flight-recorder", recordTools=true, strict=true` |
| `HumanInTheLoopMiddleware` | See next section |
| `RunControlMiddleware` | Internal, always attached to every agent. Backs `cancelRun`/`steerRun`. |

Record then replay an agent offline (zero live calls):

```javascript
aiAgent( middleware: new FlightRecorderMiddleware( mode: "record" ) ).run( "Weather in London?" )
aiAgent( middleware: new FlightRecorderMiddleware( mode: "replay", fixturePath: "tests/fixtures/london.json" ) )
```

Security middleware (`InputSanitizerMiddleware`, `OutputGuardMiddleware`, `LLMGuardMiddleware`) lives in `models.middleware.security`.

## Human in the Loop (HITL)

`HumanInTheLoopMiddleware` pauses a tool call until a human decides.

```javascript
init( toolsRequiringApproval = [], mode = "cli", showArguments = true,
      approvalCallback, policy, gateway, decisionStore )
```

| Setup | Behavior |
|-------|----------|
| default (`mode: "cli"`) | Blocking stdin/stdout prompt via an auto-attached `CliGateway` |
| `gateway: aiGateway( ... )` | Approval request is presented through that gateway; run suspends until a decision arrives |
| `mode: "web"` (no gateway) | Run suspends and returns an `AiMiddlewareResult`; you present the approval yourself |

Any middleware that can suspend (a gateway other than `cli`, or `mode: "web"`) REQUIRES a `checkpointer:` on the agent, or attaching it throws `HumanInTheLoopMiddleware.NoCheckpointer`.

```javascript
import bxModules.bxai.models.middleware.core.HumanInTheLoopMiddleware;

agent = aiAgent(
    name        : "OrderAgent",
    tools       : [ placeOrderTool ],
    middleware  : new HumanInTheLoopMiddleware( toolsRequiringApproval: [ "placeOrder" ], mode: "web" ),
    checkpointer: aiMemory( "cache" )
)

result = agent.run( "Order 3 widgets", {}, { threadId: "order-42" } )

if ( isObject( result ) && result.isSuspended() ) {
    // show result.getData() to a human, then later:
    answer = agent.resume( "approve", "order-42" )
    // or: agent.resume( "reject", "order-42", {}, "alice", "too expensive" )
    // or: agent.resume( "edit", "order-42", { /* corrected data */ } )
}
```

`resume( decision, threadId, editedData = {}, decidedBy = "", reason = "" )` and the streaming mirror `resumeStream( onChunk, decision, threadId, editedData, decidedBy, reason )`. `resume` throws `AiAgent.NoCheckpointer` or `AiAgent.CheckpointNotFound` when it cannot continue. The decision strings are `approve`, `reject`, `edit`, `cancel`, `approve_always`, `approve_session`.

**Batched approvals:** when the model requests several tool calls at once, `decision` may be one string applied to all pending calls, or an array of per-call structs `{ decision, editedData?, decidedBy?, reason? }` in the original order. Calls that did not need approval are not re-run.

**Policies** decide which calls need approval (pass `policy:`; default is by tool name). In `models.hitl.policies`:

| Policy | Constructor |
|--------|-------------|
| `ToolNameApprovalPolicy` | `( toolNames = [] )` |
| `CallbackApprovalPolicy` | `( callback )`, `callback( context )` returns boolean |
| `RiskLevelApprovalPolicy` | `( minLevel="high", defaultLevel="low" )`, levels `low, medium, high, critical`, read from `@riskLevel( "high" )` on a tool class's `doInvoke()` |
| `AnnotationApprovalPolicy` | `( annotationName="requiresApproval" )`, reads `@requiresApproval` on `doInvoke()` |
| `CompositeApprovalPolicy` | `( policies = [], mode="any"\|"all" )` |

**Durable grants:** `approve_always` is stored in an `IDecisionStore`; `approve_session` is in-memory per thread and tool. Create one with `aiDecisionStore( store, config )` where `store` is `cache`, `jdbc`, or `file`, and pass it as `decisionStore:`. Omitted, it uses `settings.hitl.decisionStore` (default `cache`).

```javascript
new HumanInTheLoopMiddleware(
    policy       : new RiskLevelApprovalPolicy( minLevel: "high" ),
    gateway      : aiGateway( "mock" ),
    decisionStore: aiDecisionStore( "file", { directoryPath: "/data/grants" } )
)
```

## Run Control

Every run has a `threadId`: pass `options: { threadId }` to `run()`/`stream()`, otherwise a UUID is generated. From anywhere (a webhook, an admin endpoint) address the in-flight run by that id. Both return `true` if a run was in flight and `false` otherwise, and take effect at the run's next LLM or tool checkpoint, not mid-token.

```javascript
future = asyncRun( () -> agent.run( "Long research task", {}, { threadId: "job-7" } ) )

agent.steerRun( "job-7", "Focus on 2025 data only" )       // splice a user message into the running turn
agent.cancelRun( "job-7", "User pressed stop" )             // reason is optional
```

## Gateways

A gateway connects an agent to a channel (CLI, HTTP, chat platforms). Core gateways: `cli`, `http`, `mock` (for tests). Other names resolve through `aiGatewayRegistry()` (e.g. external gateway modules).

| BIF | Purpose |
|-----|---------|
| `aiGateway( name, options = {}, register = false, module = "" )` | Create/configure a gateway. HTTP options: `secret`, `callbackUrl`, `toleranceSeconds`, `requestTTLSeconds` |
| `aiGatewayRegistry()` | Singleton registry: `register( gateway, module )`, `get( key )`, `has( key )`, `listGateways()`, `unregister( key )` |
| `aiGatewaySession( agent, gateways, policy = "queue", maxQueueDepth = 50, checkpointer )` | Wires one agent to one or more gateways. Call `.start()` / `.stop()` |

`gateways` takes instances or names (`[ "cli" ]`). The `policy` decides what happens when a message arrives on a thread that already has a turn running:

| Policy | Behavior |
|--------|----------|
| `reject` | Reply that a response is already in progress |
| `queue` | Buffer (up to `maxQueueDepth`, 0 = unlimited) and run after the current turn |
| `steer` | Splice into the running turn via `steerRun()` |
| `interrupt` | `cancelRun()` the current turn, then queue the new message |

```javascript
agent = aiAgent(
    name        : "Support",
    checkpointer: aiMemory( "cache" ),
    middleware  : new HumanInTheLoopMiddleware( toolsRequiringApproval: [ "refund" ], gateway: aiGateway( "cli" ) )
)

aiGatewaySession( agent: agent, gateways: [ "cli" ], policy: "steer" ).start()
```

**HTTP front controller** (`models.gateway.http.GatewayRequestProcessor`, all static, each returns `{ statusCode, body, contentType, headers }`). The HTTP gateway must be registered first: `aiGatewayRegistry().register( aiGateway( "http", { secret: "..." } ) )`.

| Method | Use |
|--------|-----|
| `processInbound( gatewayName, rawBody, headers = {}, session )` | Verify signature, parse, and with a `session` dispatch (returns 202) |
| `processHandshake( gatewayName, params = {} )` | Answer a platform's URL verification GET. Only for gateways declaring the `verifyHandshake` capability (405 otherwise) |
| `readInteraction( requestID )` | Read a pending HITL interaction |
| `submitDecision( requestID, rawBody, headers = {} )` | Submit a signed human decision |

Pass the exact raw body string, since signatures are computed over it.

## Untrusted Content: `aiFence()`

`aiFence( content, label = "external", withPreamble = false )` wraps untrusted text (RAG documents, tool or web output) in boundary markers so the model treats it as data, not instructions.

```javascript
context = aiFence( retrievedDoc, "knowledge-base", withPreamble: true )
agent.run( "Answer using this context: #context#" )
```

## Common Pitfalls

- Do NOT call `.build()` on `aiAgent()`, it doesn't exist
- Do NOT call `.withMemory()`: pass `memory:` in the constructor or use `.addMemory()` / `.setMemory()`
- `aiMemory( "windowed" )` throws `InvalidMemoryType`: the type is `"window"`
- `agent.stream()` takes the callback first, then the input
- `mcpServers` entries have no `toolNames` or `apiKey` key: use `token`
- A suspended `run()` returns an `AiMiddlewareResult`, not a string: check `isSuspended()`
- A HITL gateway or `mode: "web"` without an agent `checkpointer` throws at attach time
- Always give agents clear, specific `instructions` and sub-agents a clear `description`
- Use `availableSkills` (lazy) for large skill libraries; use `skills` (always-on) only for core rules
