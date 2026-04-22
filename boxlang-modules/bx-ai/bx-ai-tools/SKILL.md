---
name: bx-ai-tools
description: "Use this skill when creating AI tools (function calling) with aiTool(): parameter descriptions, tool registries, using tools with aiChat() and agents, the aiToolRegistry() BIF, global skills with aiglobalSkills(), and best practices for tool design."
---

# bx-ai: AI Tools (Function Calling)

## `aiTool()` BIF

```java
// Signature
aiTool( name, description, handler, params={} )
```

- `name` — unique tool identifier (snake_case recommended)
- `description` — what the tool does (clear, imperative language)
- `handler` — lambda/closure called when AI invokes the tool
- `params` — additional parameter schema hints

## Creating Tools

```javascript
// Simple tool — single parameter
weatherTool = aiTool(
    "get_weather",
    "Get the current weather for a given location",
    location -> getWeatherData( location )
)

// Multi-parameter tool — use parameter descriptions
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

Use fluent `describe*()` methods to tell the AI what each parameter means:

```javascript
// The method name is  describe + TitleCase(parameterName)
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
    {},
    { tools: tools }
)
```

## Using Tools on an Agent

```javascript
// Prefer passing tools to aiAgent() for reusable agents
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

## `aiToolRegistry()` — Shared Tool Collections

```javascript
// Build a reusable tool registry
registry = aiToolRegistry()
    .register( aiTool( "weather",  "Get weather", loc -> getWeather( loc ) ) )
    .register( aiTool( "stocks",   "Get stock price", sym -> getStock( sym ) ) )
    .register( aiTool( "currency", "Convert currency",
        ( amount, from, to ) -> convertCurrency( amount, from, to ) ) )

// Share across multiple agents
agentA = aiAgent( name: "A", tools: registry.getTools() )
agentB = aiAgent( name: "B", tools: registry.getTools() )
```

## `aiGlobalSkills()` — Application-Wide Skills

```javascript
// Register skills available to ALL agents in the application
aiGlobalSkills([
    aiSkill( ".agents/skills/company-guidelines/SKILL.md" ),
    aiSkill( ".agents/skills/brand-tone/SKILL.md" )
])
```

## Tool Design Best Practices

- **Name tools clearly** — use snake_case verbs: `get_weather`, `search_products`, `send_email`
- **Write actionable descriptions** — describe what the tool DOES, not what it IS
  - ✅ "Get the current weather for a city and country"
  - ❌ "Weather tool"
- **Describe every parameter** — vague parameters lead to incorrect AI usage
- **Return structured data** — structs and arrays are easier for AI to reason about than raw strings
- **Keep tools focused** — one tool, one responsibility
- **Handle errors gracefully** — return an error struct rather than throwing exceptions

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

- ❌ Do NOT access `arguments` scope inside tool closures — use bare parameter names
  - ❌ `location -> getWeather( arguments.location )`
  - ✅ `location -> getWeather( location )`
- ❌ Avoid throwing exceptions inside tools — return error structs instead
- ✅ Always describe parameters for tools that take arguments
- ✅ Test tools independently before connecting them to agents
