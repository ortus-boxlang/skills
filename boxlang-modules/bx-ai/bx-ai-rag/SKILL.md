---
name: bx-ai-rag
description: Use this skill when building RAG (Retrieval-Augmented Generation) systems with BoxLang AI: aiDocuments() for loading and chunking documents, aiEmbed() for embeddings, vector memory providers, ingesting documents into vector stores, and wiring RAG into agents.
---

# bx-ai: RAG (Retrieval-Augmented Generation)

RAG enhances AI responses by grounding them in your own documents, reducing hallucinations and keeping answers current without model retraining.

## RAG Workflow

```
Documents → Load → Chunk → Embed → Vector DB
                                       ↓
User Query → Embed → Vector Search → Retrieve → Inject into Context → AI
```

## Quick Start: Complete RAG System

```javascript
// 1. Create vector memory (ChromaDB — production)
vectorMemory = aiMemory( "chroma", config: {
    collection       : "knowledge_base",
    embeddingProvider: "openai",
    embeddingModel   : "text-embedding-3-small",
    serverUrl        : "http://localhost:8000"
})

// 2. Ingest documents
result = aiDocuments( "/path/to/docs", {
    type      : "directory",
    recursive : true,
    extensions: [ "md", "txt", "pdf" ]
}).toMemory(
    memory = vectorMemory,
    options = { chunkSize: 1000, overlap: 200 }
)

println( "Ingested #result.documentsIn# docs — #result.chunksOut# chunks" )

// 3. Create a RAG-enabled agent
agent = aiAgent(
    name        : "KnowledgeBot",
    description : "AI assistant with access to company knowledge base",
    instructions: "Answer questions using only the provided documentation. If unsure, say so.",
    memory      : vectorMemory
)

// 4. Query — agent automatically retrieves relevant chunks
response = agent.run( "How do I configure the ORM datasource?" )
println( response )
```

## `aiDocuments()` — Loading Documents

```javascript
// From a string
doc = aiDocuments( "BoxLang is a modern JVM language", { type: "text" } )

// From a single file
doc = aiDocuments( expandPath( "./docs/readme.md" ), { type: "file" } )

// From a directory (recursive)
docs = aiDocuments( expandPath( "./docs" ), {
    type      : "directory",
    recursive : true,
    extensions: [ "md", "txt", "html" ]
})

// From a URL
docs = aiDocuments( "https://boxlang.ortusbooks.com", { type: "url" } )

// From a PDF
docs = aiDocuments( expandPath( "./manual.pdf" ), { type: "pdf" } )
```

## Chunking Options

```javascript
docs.toMemory(
    memory = vectorMemory,
    options = {
        chunkSize     : 1000,   // target chunk size in characters
        overlap       : 200,    // character overlap between chunks (for context continuity)
        chunkSeparator: "\n\n"  // split on paragraph breaks
    }
)
```

| Option | Recommended | Description |
|--------|-------------|-------------|
| `chunkSize` | 500–1500 | Larger = more context per chunk; smaller = more precise retrieval |
| `overlap` | 10–20% of chunkSize | Prevents splitting mid-sentence at chunk boundaries |
| `chunkSeparator` | `"\n\n"` | Natural split point for prose |

## `aiEmbed()` — Generating Embeddings

```javascript
// Embed a single string
embedding = aiEmbed( "BoxLang is a JVM language", {
    provider: "openai",
    model   : "text-embedding-3-small"
})
// Returns: array of floats (the embedding vector)

// Embed multiple texts at once (batch)
embeddings = aiEmbed( [ "text one", "text two", "text three" ], {
    provider: "openai",
    model   : "text-embedding-3-small"
})
```

## Vector Memory Providers

```javascript
// In-memory (dev/testing — data lost on restart)
mem = aiMemory( "in-memory-vector", config: {
    embeddingProvider: "openai"
})

// ChromaDB
mem = aiMemory( "chroma", config: {
    collection       : "my_collection",
    embeddingProvider: "openai",
    serverUrl        : "http://localhost:8000"
})

// Pinecone
mem = aiMemory( "pinecone", config: {
    index            : "my-index",
    embeddingProvider: "openai",
    apiKey           : server.system.environment.PINECONE_KEY,
    environment      : "us-east1-gcp"
})

// Weaviate
mem = aiMemory( "weaviate", config: {
    class            : "Document",
    embeddingProvider: "openai",
    serverUrl        : "http://localhost:8080"
})
```

## Manual Retrieval

```javascript
// Add documents manually
vectorMemory.add( "BoxLang supports closures, lambdas, and functional programming" )
vectorMemory.add( "The ORM module uses Hibernate under the hood" )

// Retrieve top-K semantically similar entries
results = vectorMemory.getRelevant( "How do I use functional programming?", 3 )

// Inject retrieved context into a prompt
context = results.map( r -> r.content ).toList( "\n\n" )

response = aiChat(
    "Answer using only this context:\n\n#context#\n\nQuestion: How do I use functional programming in BoxLang?",
    { temperature: 0.2 }
)
```

## Re-indexing / Updating Documents

```javascript
// Clear and re-ingest when documents change
vectorMemory.clear()

aiDocuments( "/docs", { type: "directory", recursive: true } )
    .toMemory( memory = vectorMemory, options = { chunkSize: 800 } )
```

## Multi-Tenant RAG

```javascript
// Isolate vector stores per user
userMemory = aiMemory( "chroma",
    key   : createUUID(),
    userId: auth.userId,
    config: {
        collection       : "user_documents",
        embeddingProvider: "openai"
    }
)

// Each user only searches their own documents
aiDocuments( userUploadedFile, { type: "file" } )
    .toMemory( memory = userMemory )

agent = aiAgent( name: "PersonalBot", memory: userMemory )
```

## Best Practices

- ✅ Set `chunkSize` based on your model's context window — stay well under the limit
- ✅ Use `overlap: 10–20%` of `chunkSize` to avoid mid-sentence cuts
- ✅ Use smaller, focused embedding models (`text-embedding-3-small`) for cost efficiency
- ✅ Re-ingest documents on a schedule (cron) when source documents update frequently
- ✅ Use multi-tenant isolation in any app where different users upload different docs
- ❌ Avoid vectorizing very short strings (< 50 chars) — embeddings lose quality
- ❌ Do NOT mix unrelated domains in one vector collection without metadata filtering
