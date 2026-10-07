---
name: bx-ai-rag
description: "Use this skill when building RAG (Retrieval-Augmented Generation) systems with BoxLang AI: aiDocuments() loaders, chunking and toMemory() ingestion, aiEmbed() embeddings and providers, vector memory stores, retrieval with getRelevant(), and exposing retrieval to agents as a tool."
---

# bx-ai: RAG (Retrieval-Augmented Generation)

> BoxLang is the AI-native software productivity platform for building, modernizing and running applications, with developers and AI agents working together.

RAG enhances AI responses by grounding them in your own documents, reducing hallucinations and keeping answers current without model retraining.

## RAG Workflow

```
Documents -> Load -> Chunk -> Embed -> Vector DB
                                       |
User Query -> Embed -> Vector Search -> Retrieve -> Inject into Context -> AI
```

## Quick Start: Complete RAG System

```javascript
// 1. Create vector memory (ChromaDB)
vectorMemory = aiMemory( "chroma", config: {
    collection       : "knowledge_base",
    embeddingProvider: "openai",
    embeddingModel   : "text-embedding-3-small",
    host             : "localhost",
    port             : 8000
})

// 2. Ingest documents: load, chunk, embed and store in one call
report = aiDocuments( "/path/to/docs", {
    type      : "directory",
    recursive : true,
    extensions: [ "md", "txt", "pdf" ]
}).toMemory(
    memory  = vectorMemory,
    options = { chunkSize: 1000, overlap: 200 }
)

println( "Ingested #report.documentsIn# docs, #report.chunksOut# chunks, stored #report.stored#" )

// 3. Retrieve relevant chunks and ground the answer
hits    = vectorMemory.getRelevant( "How do I configure the ORM datasource?", 5 )
context = hits.map( h -> h.text ).toList( "\n\n" )

answer = aiChat(
    "Answer using only this context:\n\n#context#\n\nQuestion: How do I configure the ORM datasource?"
)
```

An agent's memory is loaded with `getAll()`, which does not run a semantic search. To let an agent query a knowledge base, expose retrieval as a tool:

```javascript
searchDocs = aiTool(
    "search_docs",
    "Search the company documentation for relevant passages",
    ( query ) -> vectorMemory.getRelevant( query, 5 ).map( h -> h.text ).toList( "\n\n" )
).describeQuery( "What to search for" )

agent = aiAgent(
    name        : "KnowledgeBot",
    instructions: "Answer using only the search_docs tool results. If unsure, say so.",
    tools       : [ searchDocs ]
)
agent.run( "How do I configure the ORM datasource?" )
```

## `aiDocuments()`: Loading Documents

```java
aiDocuments( source, config={} )   // returns a fluent loader
```

`config.type` selects the loader. If omitted it is detected: directory, `http(s)://` URL (feed URLs detected), SQL text, or file extension (txt, md, csv, json, xml, rss, atom), defaulting to text.

| `type` (aliases) | Loader | Notable config |
|------|--------|-------|
| `text` (`txt`) | TextLoader | |
| `markdown` (`md`) | MarkdownLoader | `splitByHeaders`, `headerLevel`, `removeCodeBlocks`, `removeImages`, `removeLinks` |
| `csv` | CSVLoader | `delimiter`, `hasHeaders`, `rowsAsDocuments`, `columns`, `skipRows` |
| `json` | JSONLoader | `contentField`, `metadataFields`, `arrayAsDocuments` |
| `xml` | XMLLoader | `elementPath`, `elementsAsDocuments`, `contentElements`, `metadataElements` |
| `log` | LogLoader | `parseStructure`, `skipEmptyLines` |
| `directory` (`dir`) | DirectoryLoader | `recursive`, `extensions`, `excludePatterns`, `includeHidden` (picks a loader per extension, including pdf) |
| `http` (`html`) | HTTPLoader | `contentType`, `method`, `headers`, `timeout` |
| `feed` (`rss`, `atom`) | FeedLoader | `maxItems`, `sinceDate`, `categories`, `includeDescription`, `stripHtml` |
| `sql` (`db`) | SQLLoader | `datasource`, `params`, `contentColumn`, `contentColumns`, `contentTemplate`, `metadataColumns`, `idColumn`, `maxRows`, `rowsAsDocuments` |
| `crawler` (`webcrawler`, `scraper`) | WebCrawlerLoader | `maxPages` (10), `maxDepth` (2), `followExternalLinks`, `allowedDomains`, `delay`, `contentSelector` |

A full class path is also accepted as `type`. An unknown type throws `aiDocuments.UnknownLoaderType`. There is no `file` or `pdf` type key: the text loader reads a file path, not literal text. A single PDF needs `type: "bxModules.bxai.models.loaders.PDFLoader"`, or load it through a directory loader (config: `startPage`, `endPage`).

```javascript
docs = aiDocuments( expandPath( "./docs/readme.md" ) ).load()            // type detected from extension
docs = aiDocuments( "https://example.com/feed.xml", { type: "feed", maxItems: 20 } ).load()
docs = aiDocuments( "SELECT title, body FROM articles", {
    type: "sql", datasource: "mydb", contentColumn: "body"
}).load()
docs = aiDocuments( "https://example.com", { type: "crawler", maxPages: 10 } ).load()
```

Loader fluent methods (all return the loader): `chunkSize( n )`, `overlap( n )`, `encoding( e )`, `recursive()`, `extensions( [] )`, `delimiter( d )`, `filter( predicate )`, `map( transformer )`, `onProgress( ( completed, total, doc ) => {} )`. Terminal methods: `load()` (array of `Document`), `loadAndChunk( options )`, `loadBatch( size )`, `each( callback )`, `toMemory( memory, options )`. `getErrors()` returns load errors. Each `Document` has `getContent()`, `getMetadata()`, `getId()`.

## Chunking

`toMemory()` options (defaults): `chunkSize` (0 = no chunking), `overlap` (0), `strategy` (`recursive`), `trackTokens` (true), `trackCost` (true), `async` (false, fan-out when `memory` is an array), `batchSize` (100), `continueOnError` (true). `overlap` must be less than `chunkSize`.

```javascript
report = docs.toMemory( memory = vectorMemory, options = { chunkSize: 1000, overlap: 200, strategy: "paragraphs" } )
// report keys: documentsIn, chunksOut, stored, skipped, tokenCount, estimatedCost, errors, memorySummary, duration
```

`aiChunk( text, options )` chunks a string directly. Strategies: `recursive` (default), `characters`, `words`, `sentences`, `paragraphs`.

| Option | Recommended | Description |
|--------|-------------|-------------|
| `chunkSize` | 500-1500 | Larger = more context per chunk; smaller = more precise retrieval |
| `overlap` | 10-20% of chunkSize | Prevents splitting mid-sentence at chunk boundaries |

## `aiEmbed()`: Generating Embeddings

```java
aiEmbed( input, params={}, options={} )
```

`input` is a string or an array of strings. Set the model in `params` and the provider in `options`. `options.returnFormat`: `raw` (full API response), `embeddings` (array of vectors), `first` (single vector).

```javascript
vector = aiEmbed(
    input  : "BoxLang is a JVM language",
    params : { model: "text-embedding-3-small" },
    options: { provider: "openai", returnFormat: "first" }
)

vectors = aiEmbed(
    [ "text one", "text two" ],
    { model: "text-embedding-3-small" },
    { provider: "openai", returnFormat: "embeddings" }
)
```

Providers that implement embeddings include openai, ollama, cohere, voyage (embeddings only, default `voyage-3`), cloudflare (default `@cf/baai/bge-base-en-v1.5`, needs `accountId`), gemini, mistral, huggingface, minimax, deepseek, openrouter and bedrock. Other providers throw `UnsupportedCapability`.

Bedrock picks the request shape from the model ID: `amazon.titan-embed-text-v1`/`v2` (one text per call; v2 accepts `dimensions` and `normalize` params) and `cohere.embed-*` (batched up to 96 texts, `input_type` param, default `search_document`).

## Vector Memory Providers

Vector stores are created with `aiMemory()`. Type keys: `boxvector` (in-memory, dev/test), `chroma`, `milvus`, `mysql`, `typesense`, `postgres` (`pgvector`), `pinecone`, `qdrant`, `opensearch`, `weaviate`. See the memory skill for config. Common config: `collection`, `embeddingProvider`, `embeddingModel`, `dimensions`, `metric`, `cache`.

```javascript
mem = aiMemory( "boxvector", config: { embeddingProvider: "openai" } )
mem = aiMemory( "chroma", config: { collection: "my_collection", embeddingProvider: "openai", host: "localhost", port: 8000 } )
```

## Manual Retrieval

```javascript
vectorMemory.add( "BoxLang supports closures, lambdas, and functional programming" )
vectorMemory.add( "The ORM module uses Hibernate under the hood" )

// getRelevant( query, limit=5, filter={}, minScore=0.0 ) returns [{ id, text, score, metadata, embedding }]
results = vectorMemory.getRelevant( "How do I use functional programming?", 3 )
```

Also available: `addWithId`, `upsert`, `getById`, `remove( id )`, `removeWhere( filter )`, `findSimilar( embedding, limit )`.

## Re-indexing / Updating Documents

```javascript
vectorMemory.clear()

aiDocuments( "/docs", { type: "directory", recursive: true } )
    .toMemory( memory = vectorMemory, options = { chunkSize: 800 } )
```

## Multi-Tenant RAG

```javascript
userMemory = aiMemory( "chroma",
    key   : createUUID(),
    userId: auth.userId,
    config: { collection: "user_documents", embeddingProvider: "openai" }
)

aiDocuments( userUploadedFile ).toMemory( memory = userMemory )
```

## Best Practices

- ✅ Set `chunkSize` based on your model's context window, staying well under the limit
- ✅ Use `overlap: 10–20%` of `chunkSize` to avoid mid-sentence cuts
- ✅ Use smaller, focused embedding models (`text-embedding-3-small`) for cost efficiency
- ✅ Re-ingest documents on a schedule (cron) when source documents update frequently
- ✅ Use multi-tenant isolation in any app where different users upload different docs
- ❌ Avoid vectorizing very short strings (< 50 chars): embeddings lose quality
- ❌ Do NOT mix unrelated domains in one vector collection without metadata filtering
