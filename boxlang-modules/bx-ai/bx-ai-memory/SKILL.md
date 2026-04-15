---
name: bx-ai-memory
description: "Use this skill when implementing memory in BoxLang AI: aiMemory() types (windowed, summary, session, file, cache, JDBC, vector), multi-tenant isolation with userId and conversationId, using memory with agents and pipelines, and choosing the right memory type."
---

# bx-ai: Memory Systems

## `aiMemory()` BIF

```java
// Signature
aiMemory( type, key="", userId="", conversationId="", config={} )
```

- `type` — memory type name (see table below)
- `key` — unique identifier for this memory instance
- `userId` — tenant user identifier (multi-tenant isolation)
- `conversationId` — isolate separate conversations for the same user
- `config` — type-specific configuration struct

## Memory Types

| Type | Best For | Persistence |
|------|----------|-------------|
| `windowed` | Last N messages | In-memory |
| `summary` | Long conversations (auto-summarizes) | In-memory |
| `session` | Single request/session | In-memory |
| `file` | Simple persistence across restarts | File system |
| `cache` | Fast shared memory | CacheBox |
| `jdbc` | Multi-server production use | Database |
| `chroma` | Semantic search (vector) | ChromaDB |
| `pinecone` | Semantic search (vector) | Pinecone |
| `weaviate` | Semantic search (vector) | Weaviate |
| `in-memory-vector` | Dev/test semantic search | In-memory |

## Creating Memory

```javascript
// Windowed: keeps last N messages
memory = aiMemory( "windowed", config: { maxMessages: 20 } )

// Summary: automatically compresses old messages into a summary
memory = aiMemory( "summary", config: {
    maxMessages    : 10,         // keep last 10 messages before summarizing
    summaryProvider: "openai"    // which provider does the summarization
})

// Session: lives for the duration of the current request
memory = aiMemory( "session" )

// File: persists conversations to disk
memory = aiMemory( "file", config: {
    filePath: expandPath( "./data/conversations" )
})

// JDBC: stored in a database table (production-ready)
memory = aiMemory( "jdbc", config: {
    datasource: "myApp",
    table     : "ai_conversations"
})

// Cache: uses CacheBox for shared, fast access
memory = aiMemory( "cache", config: {
    cacheName: "default"
})
```

## Multi-Tenant Isolation

All memory types support isolation via `userId` and `conversationId`:

```javascript
// Isolate per user
memory = aiMemory( "windowed",
    key   : createUUID(),
    userId: "user-alice",
    config: { maxMessages: 10 }
)

// Isolate per conversation (same user, different chats)
supportMemory = aiMemory( "windowed",
    key           : createUUID(),
    userId        : "user-alice",
    conversationId: "support-ticket-456",
    config        : { maxMessages: 20 }
)

salesMemory = aiMemory( "windowed",
    key           : createUUID(),
    userId        : "user-alice",
    conversationId: "sales-inquiry-789",
    config        : { maxMessages: 20 }
)
```

## Using Memory with an Agent

```javascript
// Create a persistent memory instance
memory = aiMemory( "windowed",
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
// → Agent remembers both earlier messages
```

## Memory API

```javascript
// Direct memory manipulation
memory.add( "user", "My name is Alice" )
memory.add( "assistant", "Hello Alice, how can I help?" )

// Get all messages
messages = memory.getMessages()

// Get recent N messages
recent = memory.getMessages( 5 )

// Clear memory
memory.clear()

// Get memory size
count = memory.size()
```

## Vector Memory (Semantic Search)

For RAG and semantic retrieval, see the [RAG skill](../bx-ai-rag/SKILL.md). Quick reference:

```javascript
// In-memory vector store (dev/testing)
vectorMem = aiMemory( "in-memory-vector", config: {
    embeddingProvider: "openai",
    embeddingModel   : "text-embedding-3-small"
})

// ChromaDB (production)
vectorMem = aiMemory( "chroma", config: {
    collection       : "knowledge_base",
    embeddingProvider: "openai",
    serverUrl        : "http://localhost:8000"
})

// Multi-tenant vector memory
aliceMem = aiMemory( "chroma",
    key   : createUUID(),
    userId: "alice",
    config: { collection: "user_notes", embeddingProvider: "openai" }
)

// Add documents
vectorMem.add( "BoxLang is a modern JVM language" )

// Retrieve semantically similar content
results = vectorMem.getRelevant( "What language runs on the JVM?", 5 )
```

## Choosing the Right Memory Type

- **Development / testing** → `windowed` or `in-memory-vector`
- **Single user, single server** → `file` or `cache`
- **Multi-server production** → `jdbc`
- **RAG / document search** → `chroma`, `pinecone`, or `weaviate`
- **Long conversations** → `summary` to avoid context overflow
- **Multi-tenant apps** → any type with `userId` + `conversationId`

## Common Pitfalls

- ❌ Do NOT store API keys or secrets in memory
- ❌ Do NOT use `session` memory for multi-turn conversations across requests
- ✅ Always set `userId` in multi-user applications to prevent data leakage
- ✅ Use `summary` memory for customer support bots with long conversations
- ✅ Reuse the same memory instance across multiple `agent.run()` calls for continuity
