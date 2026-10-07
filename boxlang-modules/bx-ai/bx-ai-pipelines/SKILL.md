---
name: bx-ai-pipelines
description: "Use this skill when building AI pipelines with BoxLang AI: aiMessage() templates, aiModel() steps, aiTransform() steps and extractors, aiParallel(), chaining with .to() and .transform(), the _input system variable, multi-model pipelines, streaming pipelines, and structured output in pipelines."
---

# bx-ai: AI Pipelines

> BoxLang is the AI-native software productivity platform for building, modernizing and running applications, with developers and AI agents working together.

Pipelines chain AI operations together (message templates, model calls, transforms) into reusable, composable workflows. Every step is an `IAiRunnable` with `run( input, params, options )`, `stream( onChunk, input, params, options )` and `runAsync( input, params, options )` (returns a `BoxFuture`).

## Core Pipeline BIFs

| BIF | Role |
|-----|------|
| `aiMessage( message? )` | Build prompt templates with `${variable}` placeholders |
| `aiModel( provider, apiKey, tools, params, options, middleware, skills, mcpServers )` | AI model step; executes the prompt |
| `aiTransform( transformer, config={} )` | Transform step; closure, built-in extractor name, or class |
| `aiParallel( runnables )` | Run a struct of named runnables concurrently |

## Output of a Model Step

By default (`returnFormat` module setting is `single`) a model step returns the reply content as a **string**, not a response struct. Use these fluent helpers on a model/runnable to change it: `.singleMessage()`, `.allMessages()`, `.asJson()`, `.asXml()`, `.rawResponse()`.

## Building a Pipeline: Three Ways

### Method 1: Fluent `.to()` Chaining

```javascript
pipeline = aiMessage()
    .user( "Translate '${text}' to ${language}" )
    .to( aiModel( provider: "openai" ) )
    .to( aiTransform( r -> r.trim() ) )

result = pipeline.run({
    text    : "Hello, world!",
    language: "Spanish"
})
```

### Method 2: Helper Methods

```javascript
// .toDefaultModel(): connect to the configured default model
pipeline = aiMessage().user( "Summarize: ${text}" ).toDefaultModel()

// .toModel( provider, apiKey, tools, params ): connect to a specific provider
pipeline = aiMessage().user( "Fix this code: ${code}" ).toModel( "claude" )

// .transform( fn ): shorthand for .to( aiTransform( fn ) )
pipeline = aiMessage()
    .user( "List 5 items about ${topic}" )
    .toDefaultModel()
    .transform( r -> r.listToArray( char( 10 ) ) )

// .pipe( next ) is an alias of .to( next )
```

### Method 3: Explicit Sequence

```javascript
import bxModules.bxai.models.runnables.AiRunnableSequence;

pipeline = new AiRunnableSequence( [
    aiMessage().user( "Analyze: ${input}" ),
    aiModel( provider: "openai" ),
    aiTransform( r -> r.trim() )
] )
```

There is no `aiRunnableSequence()` BIF. A sequence also offers `getSteps()`, `count()` and `print()`.

## `aiMessage()`: Prompt Templates

Role methods (`system`, `user`, `assistant`, ...) add a message with that role. `${name}` placeholders are bound at `run()` time.

```javascript
prompt = aiMessage()
    .system( "You are an expert ${language} developer." )
    .user( "Explain ${concept} in simple terms." )

// Few-shot examples
prompt = aiMessage()
    .system( "Convert temperatures precisely." )
    .user( "32F" )
    .assistant( "0C" )
    .user( "${input}" )

// Calling run() on a message only renders it: it returns the formatted messages array, not an AI reply
messages = prompt.run({ language: "BoxLang", concept: "closures" })
```

Other helpers: `bind( struct )`, `format( bindings )`, `history( messages )`, `image()`, `audio()`, `video()`, `document()`, `pdf()` (and `embed*` variants), `addUntrusted( content, label, role )`.

## `aiTransform()`: Transform Steps

```javascript
// Closure
toUpper = aiTransform( text -> text.uCase() )

// Built-in extractors by name: "json", "code", "xml" (each takes an optional config struct)
extractJson = aiTransform( "json" )
extractSql  = aiTransform( "code", { language: "sql" } )

// Chain transforms
pipeline = aiMessage().user( "List 5 countries as a JSON array. Reply with JSON only." )
    .toDefaultModel()
    .to( aiTransform( "json" ) )
    .transform( arr -> arr.map( c -> c.uCase() ) )
```

Extractor config keys: `json` (`extractPath`, `returnRaw`, `strictMode`, `stripMarkdown`, `validateSchema`, `schema`), `code` (`language`, `multiple`, `returnMetadata`, `stripComments`, `trim`, `strictMode`), `xml` (`xPath`, `returnRaw`, `strictMode`, `caseSensitive`). `TextCleanerTransformer` (`stripHTML`, `stripMarkdown`, `removeEmojis`, `trim`, ...) can be used by passing its class path: `aiTransform( "bxModules.bxai.models.transformers.TextCleanerTransformer" )`. A custom class must implement `ITransformer` (`configure()`, `transform()`).

## The `${_input}` System Variable

The previous step's output is available in the next message template as `${_input}`. When the previous output is a struct, its keys are also available as `${_input_keyName}`.

```javascript
pipeline = aiMessage( "Write code to ${task}" )
    .toDefaultModel()
    .pipe(
        aiMessage( "Review this code for bugs and security issues:\n\n${_input}" )
            .toModel( "claude" )
    )

result = pipeline.run({ task: "validate an email address" })
```

## Multi-Model Pipeline

```javascript
pipeline = aiMessage()
    .user( "Draft a blog post about: ${topic}" )
    .to( aiModel( provider: "openai", params: { model: "gpt-4o", temperature: 0.8 } ) )
    .pipe(
        aiMessage()
            .system( "You are a professional editor." )
            .user( "Edit and improve this blog post:\n\n${_input}" )
            .to( aiModel( provider: "claude" ) )
    )

finalPost = pipeline.run({ topic: "Introduction to BoxLang ORM" })
```

## Parallel Steps with `aiParallel()`

`aiParallel( struct )` runs each named runnable concurrently with the same input and returns a struct keyed by those names. It does not support `stream()`.

```javascript
results = aiParallel({
    summary : aiMessage( "Summarize: ${_input}" ).toDefaultModel(),
    keywords: aiMessage( "Extract keywords from: ${_input}" ).toDefaultModel()
}).run( documentText )
// results.summary, results.keywords

// Or fan out inside a pipeline, then merge
pipeline = aiMessage( "Analyze: ${text}" )
    .to( aiParallel({ researcher: researchAgent, writer: writerAgent }) )
    .transform( r -> "Research: #r.researcher#" & char( 10 ) & "Draft: #r.writer#" )
```

## Streaming Pipeline

`stream()` takes the callback first. In a sequence, all steps except the last run normally and the last step streams.

```javascript
pipeline = aiMessage().user( "Write a detailed guide on ${topic}" )
    .toDefaultModel()

pipeline.stream(
    chunk -> print( chunk ),
    { topic: "BoxLang async programming" }
)
```

## Structured Output in Pipelines

`.structuredOutput( schema )` on a model (class instance, struct template, or `[ classInstance ]` for arrays) makes the model return populated data. `.schema( jsonSchema )` takes a raw JSON schema and `.structuredOutputs( [ { name, schema } ] )` returns several named shapes.

```javascript
pipeline = aiMessage()
    .user( "Extract person from: ${text}" )
    .to( aiModel().structuredOutput( new Person() ) )

person = pipeline.run({ text: "John Smith, 35, Software Engineer" })

// Struct template
pipeline = aiMessage()
    .user( "Extract person info from: ${text}" )
    .to( aiModel().structuredOutput( { name: "", age: 0, role: "" } ) )
```

You can also parse a reply yourself with `aiPopulate( target, data )` where `data` is a JSON string or struct.

## Reusing Pipelines

Pipelines are **immutable**: each `.to()` call creates a new sequence, so they are safe to reuse and share.

```javascript
translatePipeline = aiMessage()
    .user( "Translate '${text}' to ${language}" )
    .toDefaultModel()

spanish = translatePipeline.run({ text: "Hello", language: "Spanish" })
french  = translatePipeline.run({ text: "Hello", language: "French" })

// Async
future = translatePipeline.runAsync({ text: "Hello", language: "German" })
```

## Common Pitfalls

- ❌ Do NOT expect a response struct from a model step by default: it returns the content string (use `.rawResponse()` for the full response)
- ❌ Do NOT call `run()` on an `aiMessage()` expecting an AI answer: it only renders messages
- ❌ Do NOT use `aiRunnableSequence()`: construct `AiRunnableSequence` directly
- ❌ Do NOT think pipelines are stateful: they are immutable and reusable
- ✅ Use `${_input}` to chain AI stages without explicit transform steps
- ✅ Use multi-model pipelines to use cheap models for drafting and expensive models for refinement
