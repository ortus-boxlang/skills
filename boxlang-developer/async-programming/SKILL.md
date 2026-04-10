---
name: boxlang-async-programming
description: Use this skill when writing BoxLang asynchronous code: BoxFuture, runAsync, asyncAll, executors, schedulers, thread components, parallel pipelines, file watchers, or distributed locking with bx:lock.
---

# BoxLang Async Programming

## Overview

BoxLang provides a comprehensive async framework built on Java's CompletableFuture
and Project Loom virtual threads. The `AsyncService` manages executors, schedulers,
and futures. All async primitives integrate seamlessly with the BoxLang runtime.

## BoxFuture Basics

`BoxFuture` extends `CompletableFuture` with BoxLang-friendly chaining:

```boxlang
// Run code asynchronously
var future = runAsync( () -> {
    // Runs in a virtual thread by default
    return fetchDataFromAPI()
})

// Get the result (blocks until complete)
var result = future.get()

// With timeout
var result = future.get( 5, "seconds" )
```

## Chaining with `then` and `onError`

```boxlang
runAsync( () -> fetchUser( userId ) )
    .then( (user) -> enrichWithProfile( user ) )
    .then( (user) -> {
        sendWelcomeEmail( user )
        return user
    })
    .onError( (error) -> {
        logError( error.message )
        return getDefaultUser()
    })
    .get()
```

## Parallel Execution with `asyncAll`

Run multiple futures in parallel and wait for all to complete:

```boxlang
var futures = asyncAll([
    () -> fetchOrders( userId ),
    () -> fetchProfile( userId ),
    () -> fetchPreferences( userId )
])

// futures is an array of BoxFutures
var [orders, profile, prefs] = futures.map( (f) -> f.get() )
```

## Named Executors

```boxlang
// Built-in executor types
// "virtual"  — virtual threads (default, best for I/O-bound work)
// "fixed"    — fixed thread pool (best for CPU-bound work)
// "cached"   — cached pool (elastic, for bursty workloads)
// "scheduled" — for cron/scheduled tasks

// Run on a specific executor
runAsync( () -> cpuIntensiveWork(), "fixed" )

// Access the AsyncService directly
var asyncService = getBoxService( "AsyncService" )
var executor = asyncService.newExecutor( "myPool", "fixed", 4 )  // 4 threads
```

## Async Pipelines

```boxlang
// Sequential pipeline
var result = runAsync( () -> loadRawData() )
    .then( (data) -> parseData( data ) )
    .then( (parsed) -> validate( parsed ) )
    .then( (valid) -> persist( valid ) )
    .onError( (e) -> rollback() )
    .get()

// Mix sequential and parallel stages
var pipeline = runAsync( () -> fetchConfig() )
    .then( (config) -> {
        // Fan out: run two tasks in parallel with the config
        var futures = asyncAll([
            () -> buildReport( config ),
            () -> sendNotifications( config )
        ])
        return futures.map( (f) -> f.get() )
    })
    .get()
```

## Scheduled Tasks

```boxlang
// In Application.bx or a dedicated scheduler component
class {
    function configure() {
        // Register a scheduled task
        task( "cleanupExpiredSessions" )
            .call( () -> sessionService.cleanup() )
            .every( 15, "minutes" )
            .onFailure( (task, error) -> logError( error.message ) )
    }
}

// One-off delayed execution
runAsync( () -> sendReminderEmail( userId ), "scheduled" )
    .delay( 24, "hours" )
```

## The `thread` Component

For explicit thread management:

```boxlang
// Start a named thread
thread name="backgroundWorker" action="run" {
    // Code runs in a new thread
    processLargeDataset( datasetId )
}

// Start multiple threads
thread name="worker1" action="run" {
    processChunk( chunk1 )
}
thread name="worker2" action="run" {
    processChunk( chunk2 )
}

// Wait for threads to finish
thread action="join" name="worker1,worker2" timeout=30000

// Access thread results
var result1 = cfthread.worker1.result
var result2 = cfthread.worker2.result
```

## Distributed Locking with `bx:lock`

`bx:lock` prevents race conditions and supports distributed locking:

```boxlang
// Exclusive lock (one thread at a time)
bx:lock name="userUpdate_#userId#" type="exclusive" timeout=10 {
    // Only one request can be here at a time for this userId
    user = userService.update( userId, data )
}

// Read lock (multiple readers, exclusive writer)
bx:lock name="configCache" type="readonly" timeout=5 {
    var config = cacheGet( "appConfig" )
}
bx:lock name="configCache" type="exclusive" timeout=5 {
    cachePut( "appConfig", freshConfig )
}

// Scoped locks (application, session, request)
bx:lock scope="application" type="exclusive" timeout=10 {
    if ( !application.initialized ) {
        initializeApp()
        application.initialized = true
    }
}
```

## File and Directory Watchers (v1.12+)

```boxlang
// Watch a directory for changes
var watcher = directoryWatcher(
    path     = expandPath( "./config" ),
    onChange = (event) -> {
        // event.type: "create", "modify", "delete"
        // event.path: full path to changed file
        reloadConfig( event.path )
    },
    filter   = "*.json",
    recurse  = false
)

watcher.start()

// Stop later
watcher.stop()
```

## Error Handling in Async Code

```boxlang
// onError continues the chain with a recovery value
var result = runAsync( () -> flakyOperation() )
    .onError( (err) -> {
        logError( err.message )
        return defaultValue   // chain continues with this
    })
    .then( (val) -> process( val ) )
    .get()

// exceptionally (Java-style)
var future = runAsync( () -> riskyWork() )
future.exceptionally( (err) -> fallback )

// Check completion state
if ( future.isDone() ) { ... }
if ( future.isCompletedExceptionally() ) { ... }
if ( future.isCancelled() ) { ... }

// Cancel a future
future.cancel( true )
```

## Async with Timeout and Fallback

```boxlang
var result = runAsync( () -> slowExternalAPI() )
    .orTimeout( 3, "seconds" )
    .onError( (err) -> getCachedResult() )
    .get()
```

## Combining Multiple Futures

```boxlang
// anyOf — complete when any one finishes
var fastest = BoxFuture.anyOf([
    runAsync( () -> fetchFromCDN() ),
    runAsync( () -> fetchFromOrigin() )
]).get()

// allOf — wait for all (returns void; use get() on each future separately)
var futures = [f1, f2, f3]
BoxFuture.allOf( futures ).get()
var results = futures.map( (f) -> f.get() )
```

## Virtual Threads Best Practices

```boxlang
// Virtual threads (default) — ideal for:
// - HTTP calls, database queries, file I/O, any blocking I/O
runAsync( () -> httpClient.get( url ) )           // good
runAsync( () -> queryExecute( sql ) )              // good

// Fixed pool — ideal for CPU-intensive work:
// - Image processing, encryption, data transformation
runAsync( () -> encryptLargeFile( path ), "fixed" )
```

## References

- [Async Programming](https://boxlang.ortusbooks.com/boxlang-framework/async-programming)
- [Scheduling](https://boxlang.ortusbooks.com/boxlang-framework/scheduled-tasks)
- [Threading](https://boxlang.ortusbooks.com/boxlang-language/threading)
- [Locking](https://boxlang.ortusbooks.com/boxlang-language/locking)
