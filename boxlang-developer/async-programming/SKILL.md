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

## Executor Types and Runtime Configuration

### Pre-Configured Runtime Executors

BoxLang provides three pre-configured executors accessible via `executorGet()`:

```boxlang
// Access pre-configured runtime executors
var ioExecutor        = executorGet( "io-tasks" )        // Virtual threads for I/O
var cpuExecutor       = executorGet( "cpu-tasks" )       // Scheduled pool for CPU work
var scheduledExecutor = executorGet( "scheduled-tasks" ) // For scheduled tasks

// Use directly
var future = ioExecutor.submit( () => fetchFromAPI( url ) )
var result = future.get()
```

**Runtime Executor Configuration** (`boxlang.json`):

```json
{
    "executors": {
        "io-tasks":        { "type": "virtual" },
        "cpu-tasks":       { "type": "scheduled", "threads": 10 },
        "scheduled-tasks": { "type": "scheduled", "threads": 10 }
    }
}
```

### Creating Custom Executors

BoxLang supports seven executor types via `executorNew()`:

```boxlang
// Virtual threads — best for I/O-bound tasks (default, JVM 21+)
var ioPool = executorNew( "virtual", "my-io-pool" )

// Fixed thread pool — CPU-bound tasks with predictable concurrency
var cpuPool = executorNew( type="fixed", name="cpu-pool", threads=8 )

// Cached pool — grows/shrinks dynamically for bursty workloads
var dynPool = executorNew( "cached", "burst-pool" )

// Single thread — sequential guaranteed-order execution
var seqPool = executorNew( "single", "sequential-processor" )

// Fork-join — recursive divide-and-conquer algorithms
var fjPool = executorNew( type="fork_join", name="fj-pool", parallelism=8 )

// Work-stealing — auto load-balancing across threads
var wsPool = executorNew( type="work_stealing", name="load-balanced", parallelism=8 )
```

### Scheduled Execution API

The `scheduled` executor type provides `scheduleOnce`, `scheduleAtFixedRate`, and `scheduleWithFixedDelay`:

```boxlang
var executor = executorNew( type="scheduled", name="scheduler", threads=5 )

// Run once after a delay
var future = executor.scheduleOnce(
    () => performMaintenance(),
    5,        // delay value
    "seconds" // time unit
)

// Run at a fixed rate (regardless of task duration)
var future = executor.scheduleAtFixedRate(
    () => healthCheck(),
    0,        // initial delay
    30,       // period
    "seconds"
)

// Run with fixed delay BETWEEN executions (waits for task to finish first)
var future = executor.scheduleWithFixedDelay(
    () => processQueue(),
    10,       // initial delay
    5,        // delay between completions
    "seconds"
)

// Submit a callable and get result
var resultFuture = executor.submit( () => complexCalculation() )
var result = resultFuture.get()

// Shutdown executor when done
executor.shutdown()
```

### Executor Statistics

```boxlang
var stats = executor.getStatistics()
writeOutput( "Active threads:   #stats.activeCount#" )
writeOutput( "Completed tasks:  #stats.completedTaskCount#" )
writeOutput( "Pool size:        #stats.poolSize#" )
writeOutput( "Is shutdown:      #executor.isShutdown()#" )
```

## References

- [Async Programming](https://boxlang.ortusbooks.com/boxlang-framework/async-programming)
- [Scheduling](https://boxlang.ortusbooks.com/boxlang-framework/scheduled-tasks)
- [Threading](https://boxlang.ortusbooks.com/boxlang-language/threading)
- [Locking](https://boxlang.ortusbooks.com/boxlang-language/locking)
