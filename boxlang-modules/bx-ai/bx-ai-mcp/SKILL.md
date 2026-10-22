---
name: bx-ai-mcp
description: "Use this skill when consuming or exposing MCP (Model Context Protocol) servers with bx-ai: the MCP() BIF for HTTP URLs and stdio child processes (MCP( { command: [ ... ] } )), MCPResponse, discovery and tool calls, giving MCP tools to agents and models (mcpServers, withMCPServer, withMCPServers, prefix, toolFilter, closeMCPServers), stdio lifecycle, restarts, timeouts and security (allowedCommands, commandGuard), client events and stats, creating MCP servers with MCPServer(), and securing them (withRateLimit, withTrustedProxies, withAllowedIPs, withApiKeyProvider, withBasicAuth)."
---

# bx-ai: MCP Clients and Servers

> BoxLang is the AI-native software productivity platform for building, modernizing and running applications, with developers and AI agents working together.

## `MCP()` BIF: the Client

```javascript
MCP( mcpServer )
```

The argument picks the transport. Both clients implement `IMCPClient`, have the same methods and return the same `MCPResponse`.

| You pass | You get | The server is |
|----------|---------|---------------|
| A URL string | `MCPHttpClient` | A web service (HTTP, SSE answers are read) |
| A struct with `command` | `MCPStdioClient` | A program the client launches and talks to over stdin and stdout |

Never create the client classes with `new`. `MCPClient` was renamed to `MCPHttpClient`; the BIF is the only way to build them.

```javascript
// HTTP
client = MCP( "http://localhost:3000" ).withTimeout( 5000 ).withBearerToken( "secret" )

// Stdio: a child process
client = MCP( { command: [ "bxplaywright", "mcp" ], env: { HEADLESS: "true" } } )

tools  = client.listTools()
result = client.send( "searchDocs", { query: "BoxLang" } )
client.close()
```

## Methods (both transports)

| Method | Purpose |
|--------|---------|
| `listTools( cursor="" )` | Tools. Pass the `nextCursor` of a previous answer for the next page |
| `send( tool, args={} )` | Call a tool |
| `listResources()`, `readResource( uri )` | Resources |
| `listPrompts()`, `getPrompt( name, args={} )` | Prompts |
| `getCapabilities()` | What the server answered to `initialize` |
| `withTimeout( ms )` | Milliseconds to wait for each answer (default 30000) |
| `onSuccess( fn )`, `onError( fn )` | Callbacks that receive each `MCPResponse` |
| `getStats()`, `getSummary()`, `resetStats()` | Call statistics |
| `close()` | Release the client. No-op for HTTP, shuts the child process down for stdio |

## `MCPResponse`

Every call returns one. **Nothing throws from a call**, a failure is a response.

| Method | Meaning |
|--------|---------|
| `isSuccess()` / `hasError()` | The call worked / failed |
| `getData()` | The result (empty struct on failure). Tools are in `listTools().getData().tools` |
| `getError()` | The message, empty on success |
| `getStatusCode()` | HTTP status. Stdio: `200` for an answer, `0` when none came |
| `getHeaders()` | HTTP headers, empty for stdio |

```javascript
response = client.send( "search", { query: "BoxLang" } )
if ( response.isSuccess() ) {
    println( response.getData() )
} else {
    println( "Failed: #response.getError()#" )
}
```

## HTTP-only Methods

`withBearerToken( token )`, `withAuth( user, pass )`, `withHeaders( struct )`, and the controls for URLs you do not fully trust, all off by default:

| Method | Effect |
|--------|--------|
| `withUrlGuard( fn )` | `( url ) => boolean`, called before every request. `false` or a throw refuses it |
| `withRedirects( false )` | A redirect becomes a failed response |
| `withMaxResponseBytes( n )` | Refuse an answer longer than `n` characters |
| `withHandshake()` | Send `initialize` and `notifications/initialized` once, keep the `Mcp-Session-Id` |
| `withHttpVersion( "HTTP/1.1" )` | Default is `HTTP/2`; use `HTTP/1.1` for a plain http server that mishandles the upgrade |

## Stdio Servers (Child Processes)

```javascript
client = MCP( {
    command     : [ "npx", "-y", "@modelcontextprotocol/server-github" ],
    env         : { GITHUB_PERSONAL_ACCESS_TOKEN: token },
    cwd         : "/srv/work",
    inheritEnv  : true,
    maxRestarts : 2,
    commandGuard: ( command ) => true,
    timeout     : 60000
} )
```

| Key | Default | Notes |
|-----|---------|-------|
| `command` | required | Array: executable then arguments. Never a shell string. No shell is ever used |
| `env` | `{}` | Added to the child environment |
| `cwd` | current dir | |
| `inheritEnv` | `true` | `false` starts with only `env`. Then pass `PATH` (and often `HOME`) in `env`: `npx` fails with `'node': No such file or directory` without it |
| `maxRestarts` | `2` | Consecutive relaunches of a dead server before giving up. Resets after an answer |
| `commandGuard` | none | `( command ) => boolean`, called before every launch |
| `timeout` | `30000` | Milliseconds, per request and for the handshake |

Extra methods on the stdio client: `isRunning()`, `getProtocolVersion()`, `getStderrTail()` (last 50 stderr lines), `getBaseURL()` (`stdio:<executable>`).

**Lifecycle**
- Started on the first call (not at construction), one process per client, then the MCP handshake (`initialize`, `notifications/initialized`; versions `2025-06-18`, `2025-03-26`, `2024-11-05`)
- One reader thread matches answers to callers by JSON-RPC id, so threads can share a client
- The first call also waits for the launch and the handshake, inside `timeout`. A program that downloads itself on its first run (`npx -y pkg`) needs a larger one, for example `timeout: 120000`
- A request that gets no answer in `timeout` fails and a `notifications/cancelled` is sent. The client keeps working
- If the process dies, the call in flight fails (it is never repeated, a tool call could run twice). The next call starts the server again, up to `maxRestarts` times in a row. A restarted server starts empty
- stderr goes to the `ai` log (debug), never into the protocol. Lines on stdout that are not JSON-RPC are skipped
- `close()` closes stdin, waits 2s, terminates the process and the processes it started, waits 2s, kills. It does not wait for a write stuck on a server that does not read. Live clients are also closed on module unload and JVM exit, but a client you never close keeps its process until then

**Security**: a stdio client runs a program. Never build `command` from user input.
- Module setting `mcp.stdio.allowedCommands`. Empty allows any. A command without a directory (`npx`, `npx.cmd`) is matched by name, case-insensitive. A command with a directory (`/usr/bin/npx`, `./npx`) must be listed with that exact path. The list limits the program, not its arguments (an allowed `node` can still run any code), and an unreadable setting refuses the command
- `commandGuard` for rules a list cannot say. It sees only the command array, not `env` or `cwd`, so validate those yourself
- A refused command throws `MCPCommandRefused`, also from `withMCPServer` and `aiAgent()`. A bad config throws `InvalidArgument`, and so does any option a stdio server does not have, such as the typo `commandGaurd`
- On Windows a `.cmd` or `.bat` file (`npx.cmd`) runs through `cmd.exe`: never pass untrusted text as its arguments
- `inheritEnv: false` stops secrets in your environment reaching the server

## Giving MCP Tools to Agents and Models

`aiAgent()` and `aiModel()` take `mcpServers`, and both have `withMCPServer( server, config )` and `withMCPServers( servers )`. The tools the server lists are wrapped and added.

```javascript
agent = aiAgent(
    name      : "OpsAgent",
    model     : aiModel( provider: "openai" ),
    mcpServers: [
        "https://docs.example.com/mcp",                                          // URL
        { url: "https://api.example.com/mcp", token: apiToken, prefix: "api" },  // HTTP struct
        { command: [ "bxplaywright", "mcp" ], prefix: "browser" },               // stdio struct
        MCP( { command: [ "bxplaywright", "mcp" ] } )                            // ready-made client
    ]
)

agent.run( "Check the docs" )
agent.closeMCPServers()   // closes the clients the agent built itself
```

Registration options (in the struct, or in the second argument of `withMCPServer`):

| Option | Effect |
|--------|--------|
| `prefix` | Tools are exposed as `prefix__name`; the server still gets the original name |
| `toolFilter` | Array of tool names. Only these are exposed (without it, every tool is) |
| `timeout` | Milliseconds |

HTTP structs also take `token`, `user` + `password`, `headers`, `urlGuard`, `redirects`, `maxResponseBytes`, `handshake`, `httpVersion`. **Using one of those with a stdio struct throws `InvalidArgument`.**

- A server that cannot be reached, cannot start or fails the handshake is logged to the `ai` log and the agent carries on **without its tools** (no throw). A refused command does throw
- `closeMCPServers()` leaves clients you passed in ready-made alone: close those yourself
- `listMCPServers()` lists connected servers (`url` is `stdio:<executable>` for stdio) with their tool names

## Events and Stats

`onMCPClientRequest`, `onMCPClientResponse`, `onMCPClientError`. The data has `client`, `baseURL` (`stdio:<executable>` for stdio), `transport` (`http` or `stdio`), `operation` (`tool`, `resource`, `prompt`, `discovery`), `name`, and `executionTime`, `response` or `error`. The stdio handshake fires no events and is not counted.

```javascript
BoxRegisterInterceptor( ( event ) => {
    println( "#event.transport# #event.name# #event.executionTime#ms" )
}, "onMCPClientResponse" )
```

`client.getSummary()` returns `totalCalls`, `successRate`, `avgResponseTime`, `totalToolCalls`, `totalErrors` and more.

## `MCPServer()`: Exposing Tools

```javascript
mcpSrv = MCPServer( "my-tools", "Business tools" )
    .registerTool( aiTool( "getCustomer", "Fetch a customer by id", ( required string id ) => fetchCustomer( id ) ) )
    .registerResource( "config://app", "App config", () => getAppConfig() )
    .registerPrompt( "greet", ( name ) => "Hello #name#", "Greeting prompt" )

response = mcpSrv.handleRequest( requestBody )   // JSON-RPC 2.0 in, out
```

`MCPServer( name="default", description, version, cors, statsEnabled, force )`. Also `registerTools( array )`, `withBasicAuth( user, pass )`, `withApiKeyProvider( provider )`.

**Stdio server** (a client launches it as a child process):

```javascript
// mcp-stdio.bxs
import bxModules.bxai.models.mcp.MCPRequestProcessor
MCPServer( "default" ).registerTool( aiTool( "echo", "Echo", ( msg ) => msg ) )
systemOutput( "starting", true, true )              // stderr, not stdout
MCPRequestProcessor::processStdio( "default" )      // stops when stdin closes
```

Rules: only protocol messages on stdout (use `systemOutput( text, true, true )` for human messages, `println()` writes to stdout); exit when stdin closes.

## Rate Limiting and Trusted Proxies (servers)

Off by default. Checked before authentication, after the IP allowlist and CORS preflight (a preflight is never counted).

```javascript
mcpServer( "myApp" )
    .withTrustedProxies( [ "10.0.0.0/8" ] )
    .withRateLimit( { limit: 100, window: 60, key: "ip", store: "cache", cacheName: "mcpLimits", failOpen: true } )

mcpServer( "myApp" ).withRateLimit( 100 )     // 100 per 60 s, per IP
mcpServer( "myApp" ).withRateLimit( false )   // opt out (also of the module default)
```

- `key`: `"ip"` (default), `"apiKey"` (needs `withApiKeyProvider()` first; only a key the provider accepts is a bucket, others fall back to the IP), `"global"` (one bucket, not `"server"`), or a lambda `( requestData ) => string` (an empty result means not limited)
- `store`: `"cache"` (default, use a dedicated `cacheName`), `"memory"`, a class path, or an instance of a class that implements `bxModules.bxai.models.mcp.ratelimit.IRateLimitStore` (`increment( key, ttlSeconds, amount )`, `get( key )`, `remove( key )`)
- `failOpen`: true (default) lets requests through when the store fails, false answers 503
- Blocked: HTTP 429, JSON-RPC `-32002`, `Retry-After` and `X-RateLimit-Limit/Remaining/Reset` (the `X-RateLimit-*` also on allowed responses)
- Logging never follows traffic: at most 10 warnings per minute per server and one summary line, not a setting. The `onMCPRateLimitHit` event (data: `mcpServer`, `serverName`, `key`, `keyType`, `limit`, `window`, `retryAfter`, `requestData`) shares that budget. Exact numbers are in `server.getStats().security.rateLimitFailures` and `server.getStats().rateLimit`
- `server.hasRateLimit()`, `server.getRateLimiter().status( "ip:1.2.3.4" )` and `.reset( "ip:1.2.3.4" )`
- Module defaults: `mcp.server.rateLimit` (`enabled` false, `limit` 60, `window` 60, `key`, `store`, `cacheName`, `failOpen`) and `mcp.server.trustedProxies`
- `withTrustedProxies( [ ips or CIDRs ] )`: forwarded headers (`X-Forwarded-For`...) only count from those proxies, read from the right. Empty or `[ "*" ]` trusts them from anyone (the old behavior), only safe when clients can reach the server only through your proxy. The IP allowlist and the `ip` limit both use it
- The cache store is exact inside one JVM only, approximate across nodes

## Common Pitfalls

- Set `withTrustedProxies()` in production, otherwise a client can forge `X-Forwarded-For` to dodge an `ip` limit or an IP allowlist
- `server` is a BoxLang scope: the shared rate limit key is `"global"`

- `client.callTool()` and `client.getResource()` do not exist: use `send()` and `readResource()`
- `listTools()` returns an `MCPResponse`, not an array: use `.getData().tools`
- The failure check is `hasError()`, there is no `isError()`
- The BIF is `MCP( ... )`; there is no `startStdio()`, the server entry is `MCPRequestProcessor::processStdio()`
- `command` is an array. `MCP( { command: "bxplaywright mcp" } )` throws `InvalidArgument`
- `withMCPServer( { command: [...], prefix: "x" } )` is fine: `prefix` and `toolFilter` can sit in the struct. `MCP( { command: [...], prefix: "x" } )` throws, they only mean something to agents and models
- Remember `close()` / `agent.closeMCPServers()` for stdio clients, otherwise the child process lives until module unload
- `aiAgent()` takes `name` and `model` (an `aiModel()`), not `agentName` or `aiModel: "openai"`. BoxLang ignores unknown named arguments, so a wrong name fails silently
- `withTimeout( ms )` is in milliseconds
- Do not retry a tool call that changes something unless the tool is safe to repeat
