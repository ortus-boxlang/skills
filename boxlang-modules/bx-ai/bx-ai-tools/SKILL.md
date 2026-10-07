---
name: bx-ai-tools
description: "Use this skill when creating AI tools (function calling) with aiTool(): parameter descriptions, tool registries, using tools with aiChat() and agents, the aiToolRegistry() BIF (register, scanClass with @AITool annotations, built-in tool sets), aiGlobalSkills(), and best practices for tool design."
---

# bx-ai: AI Tools (Function Calling)

> BoxLang is the AI-native software productivity platform for building, modernizing and running applications, with developers and AI agents working together.

## `aiTool()` BIF

```java
// Signature
aiTool( name, description="", callable, autoRegister=true )
```

- `name`: unique tool identifier (snake_case recommended), or an existing `ITool` instance (returned as is)
- `description`: what the tool does (clear, imperative language)
- `callable`: lambda/closure called when the AI invokes the tool
- `autoRegister`: when true (default) the tool is also registered in `aiToolRegistry()` under its name. Pass `false` to skip.

The JSON schema is generated from the closure's declared parameters (type, required) plus your descriptions. Types map as: string/any/date to `string`, numeric/integer/float/double to `number`, boolean, array, struct to `object`. Declare typed params (`numeric limit`) for correct schemas.

## Creating Tools

```javascript
// Simple tool: single parameter
weatherTool = aiTool(
    "get_weather",
    "Get the current weather for a given location",
    location -> getWeatherData( location )
)

// Multi-parameter tool: use parameter descriptions
searchTool = aiTool(
    "search_database",
    "Search the products database by keyword and category",
    ( keyword, category ) -> {
        return queryExecute(
            "SELECT * FROM products WHERE name LIKE :kw AND category = :cat",
            { kw: "%#keyword#%", cat: category }
        )
    }
)
```

## Describing Parameters

Use fluent `describe*()` methods to tell the AI what each parameter means. `describeArg( name, description )` is the explicit form, and `describe( "..." )` / `describeFunction( "..." )` set the tool description:

```javascript
// The method name is describe + parameterName
weatherTool = aiTool(
    "get_weather",
    "Get current weather for a location",
    location -> getWeatherAPI( location )
).describeLocation( "City and country, e.g. 'Boston, MA' or 'Paris, France'" )

searchTool = aiTool(
    "search_products",
    "Search the product catalog",
    ( keyword, category, maxResults ) -> {
        return productService.search( keyword, category, maxResults )
    }
)
.describeKeyword(    "Search keyword or product name" )
.describeCategory(   "Product category: electronics, clothing, food, or all" )
.describeMaxResults( "Maximum number of results (1-50)" )
```

## Using Tools with `aiChat()`

```javascript
tools = [
    aiTool( "get_time",   "Get current server time",           () -> now() ),
    aiTool( "get_uptime", "Get server uptime in hours",        () -> getServerUptime() ),
    aiTool( "calc",       "Evaluate a math expression",       expr -> evaluate( expr ) )
        .describeExpr( "Math expression as a string, e.g. '(15 * 3) + 7'" )
]

result = aiChat(
    "What time is it and what is 15% of 320?",
    { tools: tools }
)
```

## Using Tools on an Agent

```javascript
// Pass tools to aiAgent() for reusable agents (tool instances or registry keys)
agent = aiAgent(
    name        : "SystemAgent",
    instructions: "Use the provided tools to answer system questions accurately",
    tools       : [
        aiTool( "get_users",   "List all users",    () -> entityLoad( "User" ) ),
        aiTool( "get_stats",   "Get system stats",  () -> getSystemStats() ),
        aiTool( "send_email",  "Send an email",
            ( to, subject, body ) -> mailService.send( to, subject, body ) )
            .describeTo(      "Recipient email address" )
            .describeSubject( "Email subject line" )
            .describeBody(    "Email body in plain text or HTML" )
    ]
)
```

## `aiToolRegistry()`: Shared Tool Collections

`aiToolRegistry()` returns a singleton registry. Keys are `name` or `name@module`. Tools can be referenced by key string in `tools` arrays (e.g. `tools: [ "now@bxai" ]`).

```javascript
registry = aiToolRegistry()

// Register an ITool, or build one from name/description/callback
registry.register( aiTool( "weather", "Get weather", loc -> getWeather( loc ), false ) )
registry.register(
    name       : "stocks",
    description: "Get stock price",
    callback   : sym -> getStock( sym )
)

registry.has( "weather" )
registry.get( "weather" )
registry.getAll()           // array of tools
registry.listTools()        // struct keyed by registry key: name, description, module
registry.unregister( "stocks" )

// Share across agents
agentA = aiAgent( name: "A", tools: registry.getAll() )
```

### Annotation scanning with `@AITool`

`scanClass( instance, module="" )` registers every function annotated `@AITool` and returns the tools. The annotation value (or javadoc hint) is the tool description, a struct annotation value with `name` and `description` keys overrides them, and param javadoc hints become argument descriptions. `scan( packagePath, module="" )` does the same for every `.bx` class under a package path.

```javascript
class {
    /**
     * @city City name, e.g. Boston
     */
    @AITool( "Get the current weather for a city" )
    function getWeather( required string city ) {
        return weatherApi.lookup( city )
    }
}
```

```javascript
aiToolRegistry().scanClass( new WeatherTools(), "myapp" )   // key: getWeather@myapp
agent = aiAgent( name: "W", tools: [ "getWeather@myapp" ] )
```

### Built-in tool sets

Registered into the registry at module load under the `bxai` module: core tools (`print`, `log`, `sendEmail`, `now`, `httpGet`), audio (`speak`, `transcribe`, `translate`), image (`generateImage`) and web search tools. Filesystem tools are opt-in so you can restrict paths:

```javascript
import bxModules.bxai.models.tools.filesystem.FileSystemTools

aiToolRegistry().scanClass( new FileSystemTools( allowedPaths: [ "/data" ] ), "bxai" )
// readFile@bxai, writeFile@bxai, editFile@bxai, listDirectory@bxai, searchFiles@bxai, ...
```

With no `allowedPaths`, all paths are allowed. Use with caution.

## `aiGlobalSkills()`: Application-Wide Skills

`aiGlobalSkills()` takes no arguments and returns the array of skills auto-discovered from the `skillsDirectory` setting (default `/.agents/skills`, controlled by `autoLoadSkills`). Every agent created with `aiAgent()` gets them automatically. Load individual skills with `aiSkill( path )`.

```javascript
skills = aiGlobalSkills()
```

## Tool Design Best Practices

- **Name tools clearly**: use snake_case verbs: `get_weather`, `search_products`, `send_email`
- **Write actionable descriptions**: describe what the tool DOES, not what it IS
  - ✅ "Get the current weather for a city and country"
  - ❌ "Weather tool"
- **Describe every parameter**: vague parameters lead to incorrect AI usage
- **Return structured data**: structs and arrays are easier for AI to reason about than raw strings
- **Keep tools focused**: one tool, one responsibility
- **Handle errors gracefully**: return an error struct rather than throwing exceptions

```javascript
// Good error handling in a tool
dbTool = aiTool(
    "query_user",
    "Look up a user by ID",
    userId -> {
        try {
            var user = entityLoadByPK( "User", userId )
            return isNull( user ) ? { found: false } : { found: true, data: user.getMemento() }
        } catch ( any e ) {
            return { error: true, message: e.message }
        }
    }
).describeUserId( "Numeric user ID" )
```

## Common Pitfalls

- ❌ Avoid throwing exceptions inside tools: return error structs instead
- ❌ Do not pass `tools` in the `options` argument of `aiChat()`: it belongs in `params` (2nd argument)
- `aiTool()` auto-registers by name, so reusing a name overwrites the earlier registration
- ✅ Always describe parameters for tools that take arguments
- ✅ Test tools independently before connecting them to agents
