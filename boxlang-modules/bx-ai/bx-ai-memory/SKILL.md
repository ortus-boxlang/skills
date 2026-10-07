---
name: bx-ai-memory
description: "Use this skill when implementing memory in BoxLang AI: aiMemory() types (window, summary, session, file, cache, jdbc, hybrid, vector stores), multi-tenant isolation with userId and conversationId, the memory API, using memory with agents, and choosing the right memory type."
---

# bx-ai: Memory Systems

> BoxLang is the AI-native software productivity platform for building, modernizing and running applications, with developers and AI agents working together.

## `aiMemory()` BIF

```java
// Signature
aiMemory( memory, key=createUUID(), userId="", conversationId="", config={} )
```

- `memory`: memory type name (see table below). Defaults to the `memory.provider` module setting (`window`)
- `key`: unique identifier for this memory instance
- `userId`: tenant user identifier. If set, the instance is bound to it
- `conversationId`: isolate separate conversations. If set, the instance is bound to it
- `config`: type-specific configuration struct

## Memory Types

| Type key (aliases) | Best For | Persistence |
|------|----------|-------------|
| `window` (`buffered`, `buffer`) | Last N messages | In-memory |
| `summary` | Long conversations (auto-summarizes) | In-memory |
| `session` | BoxLang session scope | Session |
| `file` | Simple persistence across restarts | File system |
| `cache` | Fast shared memory | BoxLang cache |
| `jdbc` (`database`, `db`) | Multi-server production use | Database |
| `hybrid` | Recent messages plus semantic search | Window + vector store |
| `boxvector` | Dev/test semantic search | In-memory |
| `chroma`, `milvus`, `mysql`, `typesense`, `postgres` (`pgvector`), `pinecone`, `qdrant`, `opensearch`, `weaviate` | Semantic search (vector) | The named store |

A full class path is also accepted as the type. An unknown type throws `InvalidMemoryType`.

## Creating Memory

```javascript
// Window: keeps last N messages (default 100)
memory = aiMemory( "window", config: { maxMessages: 20 } )

// Summary: compresses old messages into an AI summary.
// maxMessages (default 20) is the trigger, summaryThreshold (default 10) is how many
// recent messages are kept verbatim and must be < maxMessages.
memory = aiMemory( "summary", config: {
    maxMessages     : 20,
    summaryThreshold: 10,
    summaryProvider : "openai",     // default openai
    summaryModel    : "gpt-4o-mini" // default gpt-4o-mini
})

// Summary, token-based trigger (maxTokens and maxMessages are mutually exclusive, so zero maxMessages)
memory = aiMemory( "summary", config: { maxTokens: 4000, maxMessages: 0 } )

// Session: stored in the BoxLang session scope
memory = aiMemory( "session" )

// File: persists conversations as JSON files in a directory
memory = aiMemory( "file", config: {
    directoryPath: expandPath( "./data/conversations" )
})

// JDBC: stored in a database table (default table bx_ai_memories)
memory = aiMemory( "jdbc", config: {
    datasource: "myApp",
    table     : "ai_conversations"
})

// Cache: stored in a BoxLang cache
memory = aiMemory( "cache", config: { cacheName: "default" } )
```

## Multi-Tenant Isolation

Pass `userId` and `conversationId` to bind a memory instance to a tenant and conversation:

```javascript
memory = aiMemory( "window",
    key           : createUUID(),
    userId        : "user-alice",
    conversationId: "support-ticket-456",
    config        : { maxMessages: 20 }
)
```

## Using Memory with an Agent

```javascript
// Create a persistent memory instance
memory = aiMemory( "window",
    key   : "chat-#session.sessionId#",
    userId: auth.getCurrentUserId(),
    config: { maxMessages: 30 }
)

agent = aiAgent(
    name        : "SupportBot",
    instructions: "You are a helpful support agent. Remember the user's context.",
    memory      : memory
)

// Each run() call uses and updates the memory
agent.run( "I'm having trouble with my subscription." )
agent.run( "It's been broken for 3 days." )
agent.run( "Can you summarize my issue?"  )
// Agent remembers both earlier messages
```

## Memory API

```javascript
// add() accepts a string (user message), a struct { role, content }, an array, an AiMessage, or a Document
memory.add( "My name is Alice" )
memory.add( { role: "assistant", content: "Hello Alice, how can I help?" } )

messages = memory.getAll()          // all messages
recent   = memory.getRecent( 5 )    // last 5 messages
users    = memory.getByRole( "user" )
hits     = memory.search( "Alice" ) // text search
count    = memory.count()
memory.isEmpty()
memory.setSystemMessage( "You are concise." )
memory.clear()

// Compress history into a summary (available on every conversation memory type)
memory.summarize( { keepRecent: 5 } )

// Save / restore
data = memory.export()
memory.import( data )
```

## Vector Memory (Semantic Search)

For RAG and document loading, see the [RAG skill](../bx-ai-rag/SKILL.md).

```javascript
// In-memory vector store (dev/testing)
vectorMem = aiMemory( "boxvector", config: {
    embeddingProvider: "openai",
    embeddingModel   : "text-embedding-3-small"
})

// ChromaDB (config keys: host, port, protocol, tenant, database, timeout)
vectorMem = aiMemory( "chroma", config: {
    collection       : "knowledge_base",
    embeddingProvider: "openai",
    host             : "localhost",
    port             : 8000
})

vectorMem.add( "BoxLang is a modern JVM language" )

// getRelevant( query, limit=5, filter={}, minScore=0.0 )
results = vectorMem.getRelevant( "What language runs on the JVM?", 5 )
```

Common vector config keys: `collection`, `embeddingProvider`, `embeddingModel`, `dimensions`, `metric` (`cosine`, `euclidean`, `dot_product`), `embeddingOptions`, `cache` (cache embeddings), `cacheName`.

### Hybrid memory

`hybrid` combines a window of recent messages with semantic search over a vector store. Config keys: `recentLimit` (5), `semanticLimit` (5), `totalLimit` (10), `recentWeight` (0.6), `vectorProvider` (default `BoxVectorMemory`), `vectorConfig`.

```javascript
memory = aiMemory( "hybrid", config: {
    vectorProvider: "chroma",
    vectorConfig  : { collection: "chat", embeddingProvider: "openai" }
})
memory.getRelevant( "what did we decide about pricing?", 5 )
```

## Choosing the Right Memory Type

- **Development / testing**: `window` or `boxvector`
- **Single user, single server**: `file` or `cache`
- **Multi-server production**: `jdbc`
- **RAG / document search**: `chroma`, `pinecone`, `weaviate`, `postgres`, `qdrant`, etc.
- **Long conversations**: `summary` to avoid context overflow
- **Recency plus relevance**: `hybrid`
- **Multi-tenant apps**: any type with `userId` + `conversationId`

## Common Pitfalls

- ❌ Do NOT store API keys or secrets in memory
- ❌ Do NOT set both `maxTokens` and `maxMessages` on `summary` memory (throws `InvalidConfiguration`)
- ✅ Always set `userId` in multi-user applications to prevent data leakage
- ✅ Use `summary` memory for customer support bots with long conversations
- ✅ Reuse the same memory instance across multiple `agent.run()` calls for continuity
