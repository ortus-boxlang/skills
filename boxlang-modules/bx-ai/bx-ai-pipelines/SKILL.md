---
name: bx-ai-pipelines
description: Use this skill when building AI pipelines with BoxLang AI: aiMessage() templates, aiModel() in pipelines, aiTransform() steps, chaining with .to() and .transform(), the _input system variable, multi-model pipelines, streaming pipelines, and structured output in pipelines.
---

# bx-ai: AI Pipelines

Pipelines chain AI operations together — message templates → model calls → transforms — into reusable, composable workflows.

## Core Pipeline BIFs

| BIF | Role |
|-----|------|
| `aiMessage()` | Build prompt templates with `${variable}` placeholders |
| `aiModel()` | AI model step; executes the prompt |
| `aiTransform()` | Transform step; processes input with a closure |
| `aiRunnableSequence()` | Combine steps into an explicit sequence |

## Building a Pipeline: Three Ways

### Method 1: Fluent `.to()` Chaining (Most Common)

```javascript
pipeline = aiMessage()
    .user( "Translate '${text}' to ${language}" )
    .to( aiModel( provider: "openai" ) )
    .to( aiTransform( r -> r.content ) )

result = pipeline.run({
    text    : "Hello, world!",
    language: "Spanish"
})
// → "¡Hola, mundo!"
```

### Method 2: Helper Methods

```javascript
// .toDefaultModel() — connect to configured default model
pipeline = aiMessage().user( "Summarize: ${text}" ).toDefaultModel()

// .toModel( provider ) — connect to a specific model
pipeline = aiMessage().user( "Fix this code: ${code}" ).toModel( "claude" )

// .transform( fn ) — shorthand for .to( aiTransform( fn ) )
pipeline = aiMessage()
    .user( "List 5 items about ${topic}" )
    .toDefaultModel()
    .transform( r -> r.content.split( "\n" ) )  // returns array of lines
```

### Method 3: Explicit Sequence

```javascript
import bxModules.bxai.models.runnables.AiRunnableSequence;

steps = [
    aiMessage().user( "Analyze: ${input}" ),
    aiModel( provider: "openai" ),
    aiTransform( r -> r.content )
]

pipeline = new AiRunnableSequence( steps )
// or:
pipeline = aiRunnableSequence( steps )
```

## `aiMessage()` — Prompt Templates

```javascript
// System + user messages
prompt = aiMessage()
    .system( "You are an expert ${language} developer." )
    .user( "Explain ${concept} in simple terms." )

// Assistant message (few-shot examples)
prompt = aiMessage()
    .system( "Convert temperatures precisely." )
    .user( "32F" )
    .assistant( "0°C" )
    .user( "${input}" )

// Run directly (no pipeline)
result = prompt.run({ language: "BoxLang", concept: "closures" })
```

## `aiTransform()` — Transform Steps

```javascript
// Extract content from AI response
extractContent = aiTransform( response -> response.content )

// Parse JSON from response
parseJSON = aiTransform( response -> deserializeJSON( response.content ) )

// Map to domain object
toPerson = aiTransform( response -> {
    var data = deserializeJSON( response.content )
    return new Person( data.name, data.age )
})

// Chain transforms
pipeline = aiMessage().user( "List 5 countries as JSON array" )
    .toDefaultModel()
    .transform( r -> r.content )
    .transform( json -> deserializeJSON( json ) )
    .transform( arr -> arr.map( c -> c.uCase() ) )
```

## The `${_input}` System Variable

When chaining AI stages, the previous stage's output is automatically available as `${_input}`:

```javascript
// Code generation → review pipeline
pipeline = aiMessage( "Write code to ${task}" )
    .toDefaultModel()
    .pipe(
        // _input = the generated code from the previous stage
        aiMessage( "Review this code for bugs and security issues:\n\n${_input}" )
            .toModel( "claude" )
    )

result = pipeline.run({ task: "validate an email address" })
```

## Multi-Model Pipeline

Different models for different steps:

```javascript
pipeline = aiMessage()
    .user( "Draft a blog post about: ${topic}" )
    .to( aiModel( provider: "openai", params: { model: "gpt-4o", temperature: 0.8 } ) )
    .transform( r -> r.content )
    .pipe(
        // Use Claude to edit/critique the draft (referenced via _input)
        aiMessage()
            .system( "You are a professional editor." )
            .user( "Edit and improve this blog post:\n\n${_input}" )
            .to( aiModel( provider: "claude" ) )
    )
    .transform( r -> r.content )

finalPost = pipeline.run({ topic: "Introduction to BoxLang ORM" })
```

## Streaming Pipeline

```javascript
pipeline = aiMessage().user( "Write a detailed guide on ${topic}" )
    .toDefaultModel()

pipeline.stream(
    { topic: "BoxLang async programming" },
    chunk -> print( chunk )
)
```

## Structured Output in Pipelines

```javascript
// Output as a typed class
pipeline = aiMessage()
    .user( "Extract person from: ${text}" )
    .toDefaultModel()
    .transform( r -> aiPopulate( new Person(), r.content ) )

person = pipeline.run({ text: "John Smith, 35, Software Engineer" })
println( person.getName() )    // "John Smith"
println( person.getAge() )     // 35

// Output as a struct template
pipeline = aiMessage()
    .user( "Extract person info from: ${text}" )
    .toDefaultModel()
    .to( aiTransform( r -> {
        return aiPopulate( { name: "", age: 0, role: "" }, r.content )
    }))
```

## Reusing Pipelines

Pipelines are **immutable** — each `.to()` call creates a new sequence. This makes them safe to reuse and share:

```javascript
// Build once
translatePipeline = aiMessage()
    .user( "Translate '${text}' to ${language}" )
    .toDefaultModel()
    .transform( r -> r.content )

// Reuse many times
spanish = translatePipeline.run({ text: "Hello", language: "Spanish" })
french  = translatePipeline.run({ text: "Hello", language: "French" })
german  = translatePipeline.run({ text: "Hello", language: "German" })
```

## Common Pitfalls

- ❌ Do NOT use `.to( aiTransform( closure ) )` verbose form — prefer `.transform( closure )`
- ❌ Do NOT think pipelines are stateful — they are immutable and reusable
- ✅ Use `${_input}` to chain AI stages without explicit transform steps
- ✅ Use multi-model pipelines to use cheap models for drafting and expensive models for refinement
- ✅ Always end a pipeline with `.transform( r -> r.content )` if you want a plain string result
