---
name: boxlang-runtime-architecture
description: Use this skill when understanding BoxLang internals: BoxRuntime services, IBoxContext hierarchy, scope chain resolution, DynamicObject, type system (IBoxType), parsing pipeline (source to bytecode), class loader isolation, virtual threads, or using --bx-printast for AST debugging.
---

# BoxLang Runtime Architecture

## Overview

BoxLang is a dynamic JVM language (JRE 21+) that compiles source to Java bytecode
at runtime. The central singleton `BoxRuntime` acts as a service locator providing
access to all core services. Understanding the architecture is essential for building
modules, BIFs, interceptors, and custom language extensions.

## BoxRuntime — The Central Singleton

```java
import ortus.boxlang.runtime.BoxRuntime;

// Get the singleton instance
BoxRuntime runtime = BoxRuntime.getInstance();

// Start programmatically (e.g., in tests or embedding scenarios)
BoxRuntime runtime = BoxRuntime.getInstance( true );  // true = start immediately

// Core service accessors
runtime.getInterceptorService()    // Event system
runtime.getModuleService()         // Module management
runtime.getCacheService()          // Cache providers
runtime.getAsyncService()          // Executors, futures
runtime.getSchedulerService()      // Cron scheduling
runtime.getDataSourceService()     // JDBC connections
runtime.getFunctionService()       // BIF registry
runtime.getComponentService()      // Component/tag registry
runtime.getClassLocator()          // Class resolution
runtime.getConfiguration()         // Runtime config
runtime.getTypeService()           // Type system
```

## Key Services

### InterceptorService

Manages the global event bus. See `interceptors` skill for full details.

```java
InterceptorService svc = runtime.getInterceptorService();
svc.announce( Key.of("myEvent"), dataStruct );
svc.register( myInterceptor );
svc.unregister( myInterceptor );
```

### ModuleService

```java
ModuleService moduleSvc = runtime.getModuleService();

// Check if a module is loaded
boolean loaded = moduleSvc.hasModule( Key.of("bx-redis") );

// Get module record
ModuleRecord record = moduleSvc.getModuleRecord( Key.of("bx-redis") );
String version = record.version;
String physPath = record.physicalPath;
IStruct settings = record.settings;

// List all loaded modules
Set<Key> modules = moduleSvc.getLoadedModules();
```

### FunctionService (BIF Registry)

```java
FunctionService fnSvc = runtime.getFunctionService();

// Register a custom BIF at runtime
fnSvc.registerGlobalFunction( Key.of("myBif"), new MyBIF() );

// Check if a BIF exists
boolean exists = fnSvc.hasGlobalFunction( Key.of("len") );

// Get a BIF instance
BIF len = fnSvc.getGlobalFunction( Key.of("len") );
```

### AsyncService

```java
AsyncService asyncSvc = runtime.getAsyncService();

// Create a named executor
IBoxExecutor executor = asyncSvc.newExecutor( "myPool", ExecutorType.FIXED, 4 );

// Get an existing executor
IBoxExecutor exec = asyncSvc.getExecutor( "boxlang-tasks" );

// Create a future
BoxFuture<Object> future = asyncSvc.newFuture( () -> expensiveWork() );
```

## IBoxContext — Execution Context Hierarchy

Every BoxLang execution has a context. Contexts form a linked chain for scope resolution.

```
BoxRuntime
  └── ScriptingRequestBoxContext     (CLI / script execution)
      └── FunctionBoxContext         (inside a function call)
          └── ClosureBoxContext      (inside a closure)
              └── LambdaBoxContext   (inside a lambda)

  └── WebRequestBoxContext           (HTTP request)
      └── ApplicationBoxContext      (Application.bx scope)
          └── SessionBoxContext      (Session scope)
              └── FunctionBoxContext
```

```java
import ortus.boxlang.runtime.context.IBoxContext;
import ortus.boxlang.runtime.context.FunctionBoxContext;
import ortus.boxlang.runtime.context.ScriptingRequestBoxContext;

// Traverse parent contexts
IBoxContext current = context;
while ( current != null ) {
    System.out.println( current.getClass().getSimpleName() );
    current = current.getParent();
}

// Find a scope nearby (walks up the context chain)
IScope localScope   = context.getScopeNearby( LocalScope.name );
IScope sessionScope = context.getScopeNearby( SessionScope.name );

// Resolve a variable (checks all scopes in order)
ScopeSearchResult result = context.scopeFindNearby( Key.of("myVar"), null );
if ( result != null ) {
    Object value = result.value();
    IScope foundIn = result.scope();
}

// Invoke a BIF from Java code
Object result = context.invokeFunction( Key.of("len"), new Object[]{ "hello" } );
```

## Scope Chain Resolution Order

When BoxLang resolves an unqualified variable name, it searches these scopes in order:

1. `local` — declared with `var` in current function
2. `arguments` — function parameters
3. `variables` — class/component private scope
4. Named scopes: `url`, `form`, `cgi`, `cookie`
5. `request` — per-request shared scope
6. `session` — user session
7. `application` — application-wide
8. `server` — server-wide

## DynamicObject — BoxLang's Java Object Wrapper

`DynamicObject` wraps Java objects and provides BoxLang-style method invocation:

```java
import ortus.boxlang.runtime.dynamic.DynamicObject;

// Wrap any Java object
DynamicObject wrapped = DynamicObject.of( new java.util.ArrayList() );

// Invoke methods
wrapped.invoke( context, "add", new Object[]{ "item" } );
Object size = wrapped.invoke( context, "size", new Object[]{} );

// Get/set fields
Object field = wrapped.getField( Key.of("fieldName") );
wrapped.setField( Key.of("fieldName"), value );
```

## IBoxType — BoxLang Native Types

All BoxLang values implement `IBoxType`:

```java
import ortus.boxlang.runtime.types.*;
import ortus.boxlang.runtime.types.IType;

// Core type classes
BoxArray   bxArray  = new BoxArray();            // Array
BoxStruct  bxStruct = BoxStruct.of("k","v");     // Struct
BoxString  bxStr    = BoxString.of("hello");     // String (immutable)
BoxInteger bxInt    = BoxInteger.of(42);         // Integer
BoxDouble  bxDbl    = BoxDouble.of(3.14);        // Double
BoxBoolean bxBool   = BoxBoolean.of(true);       // Boolean
BoxNull    bxNull   = BoxNull.INSTANCE;          // Null singleton

// Check type
if ( value instanceof BoxArray arr ) {
    // work with array
}
if ( value instanceof IStruct struct ) {
    // work with struct
}

// Key — interned string for scope/struct access
Key nameKey = Key.of("name");     // interned (fast equality)
Key idKey   = Key.of("id");
```

## Parsing Pipeline

Source code → AST → Java Bytecode:

```
Source (.bx / .bxs / .bxm / .cfm / .cfc)
    │
    ▼
Lexer (ANTLR4)          → Token stream
    │
    ▼
Parser (ANTLR4)         → Parse tree
    │
    ▼
AST Builder             → BoxLang AST (BoxNode tree)
    │
    ▼
Transpiler/Transformer  → Java AST (JavaParser)
    │
    ▼
Java Compiler           → Java bytecode (.class)
    │
    ▼
ClassLoader             → Loaded & executed by JVM
```

### Debug the AST

```bash
# Print the AST for a file
boxlang --bx-printast myScript.bxs

# Print AST from stdin
echo 'var x = 1 + 2' | boxlang --bx-printast -

# Print AST with file path context
boxlang --bx-printast /path/to/file.bxs
```

### Compiled Class Caching

Once compiled, the generated `.class` files are cached by the ClassLoader.
Re-compilation only happens when the source timestamp changes or when
`reloadOnChange=true` is configured.

## ClassLoader Isolation

Each module gets its own isolated ClassLoader for the `libs/` directory:

```
BoxLang Runtime ClassLoader
├── Core BIFs & Runtime Classes
├── Module A ClassLoader
│   └── libs/moduleA-dependency.jar
├── Module B ClassLoader
│   └── libs/moduleB-dependency.jar  (no conflict with Module A)
└── Application ClassLoader
    └── Application-specific JARs (this.javaSettings)
```

This prevents JAR version conflicts between modules — each module's `libs/`
directory is visible only to that module.

## Key Java Packages

| Package | Contents |
|---|---|
| `ortus.boxlang.runtime` | `BoxRuntime`, configuration |
| `ortus.boxlang.runtime.bifs` | BIF base classes, annotations |
| `ortus.boxlang.runtime.context` | Context classes, scope resolution |
| `ortus.boxlang.runtime.scopes` | Scope implementations, `Key` |
| `ortus.boxlang.runtime.types` | `BoxArray`, `BoxStruct`, `IStruct`, etc. |
| `ortus.boxlang.runtime.events` | `BaseInterceptor`, `InterceptorService` |
| `ortus.boxlang.runtime.services` | All service classes |
| `ortus.boxlang.runtime.modules` | `ModuleRecord`, `ModuleService` |
| `ortus.boxlang.runtime.dynamic` | `DynamicObject`, Java interop |
| `ortus.boxlang.runtime.loader` | Class loading, bytecode generation |
| `ortus.boxlang.compiler.ast` | AST node classes |

## Virtual Threads and Project Loom

BoxLang uses JRE 21 virtual threads (Project Loom) for its default executor:

```java
// Virtual thread executor (default in BoxLang)
// - Lightweight: millions can coexist
// - Ideal for I/O-bound work (HTTP, DB, file I/O)
// - Automatically unmounted during blocking operations

ExecutorService virtualExec = Executors.newVirtualThreadPerTaskExecutor();

// BoxLang's AsyncService uses virtual threads by default:
// Type.VIRTUAL → Executors.newVirtualThreadPerTaskExecutor()
// Type.FIXED   → Executors.newFixedThreadPool(n)
// Type.CACHED  → Executors.newCachedThreadPool()
```

## Java CDS (Class Data Sharing)

BoxLang supports Java CDS archives for faster startup:

```bash
# Generate a CDS archive
java -Xshare:dump -XX:SharedArchiveFile=boxlang.jsa -jar boxlang.jar

# Use the archive on startup (significantly faster cold starts)
java -Xshare:on -XX:SharedArchiveFile=boxlang.jsa -jar boxlang.jar
```

## Runtime Configuration Access

```java
// Get boxlang.json configuration
BoxLangConfiguration config = runtime.getConfiguration();

boolean debugMode   = config.debugMode;
String  timezone    = config.timezone;
IStruct modules     = config.modules;
IStruct caches      = config.caches;
IStruct datasources = config.datasources;

// Get a module's settings
IStruct moduleSettings = config.modules
    .getAsStruct( Key.of("bx-redis") )
    .getAsStruct( Key.of("settings") );
```

## Embedding BoxLang in a Java Application

```java
import ortus.boxlang.runtime.BoxRuntime;
import ortus.boxlang.runtime.context.ScriptingRequestBoxContext;
import ortus.boxlang.runtime.scopes.Key;

// Start the runtime
BoxRuntime runtime = BoxRuntime.getInstance( true );

// Create a scripting context
ScriptingRequestBoxContext context = new ScriptingRequestBoxContext( runtime.getRuntimeContext() );

// Set variables
context.getScope( VariablesScope.name ).put( Key.of("greeting"), "Hello!" );

// Execute BoxLang code
runtime.executeStatement( "println( greeting )", context );

// Execute a file
runtime.executeTemplate( "/path/to/script.bxs", context );

// Shutdown
runtime.shutdown();
```

## References

- [BoxLang Source](https://github.com/ortus-boxlang/BoxLang)
- [BoxRuntime.java](https://github.com/ortus-boxlang/BoxLang/blob/development/src/main/java/ortus/boxlang/runtime/BoxRuntime.java)
- [IBoxContext](https://github.com/ortus-boxlang/BoxLang/blob/development/src/main/java/ortus/boxlang/runtime/context/IBoxContext.java)
- [BoxLang Overview](https://boxlang.ortusbooks.com/getting-started/overview)
- [JEP 444 — Virtual Threads](https://openjdk.org/jeps/444)
