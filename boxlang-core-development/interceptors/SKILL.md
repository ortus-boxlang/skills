---
name: boxlang-interceptors
description: Use this skill when creating BoxLang interceptors: Observer/Intercepting Filter patterns, interceptor pools, BoxLang class vs Java interceptors, lambda interceptors, registration via BIFs/InterceptorService/ModuleConfig, interception points, and announcing custom events.
---

# BoxLang Interceptors

## Overview

BoxLang's interceptor system implements the **Observer** and **Intercepting Filter**
design patterns. Interceptors listen for named events (interception points) announced
by the runtime, modules, or application code. They enable cross-cutting concerns
like logging, security, AOP, routing, and content manipulation without modifying
core code.

## Interceptor Pools

Three pools exist in the runtime. Each pool is an independent event emitter:

| Pool | Scope | Use Case |
|------|-------|---------|
| **Global Runtime** | Entire BoxLang process | Module events, parse events, global AOP |
| **Application Request Listener** | Per-application request lifecycle | Auth, routing, request logging |
| **CacheProviders** | Per cache instance | Cache event hooks |

## Creating a BoxLang Class Interceptor

Method names in the class directly correspond to interception point names:

```boxlang
// interceptors/RequestLogger.bx
class {

    // Auto-injected by the runtime
    property name="name"              setter="false"
    property name="properties"        setter="false"
    property name="log"               setter="false"  // module logger
    property name="interceptorService" setter="false"
    property name="boxRuntime"        setter="false"
    property name="moduleRecord"      setter="false"  // if module-based

    /**
     * Called when the interceptor is registered.
     * Use this to validate properties and set up resources.
     */
    function configure() {
        // Access settings passed at registration time
        log.info( "RequestLogger interceptor configured. Level: #properties.logLevel ?: 'INFO'#" )
    }

    // ---------------------------------------------------------------
    // Interception point methods — name must EXACTLY match the event
    // ---------------------------------------------------------------

    /**
     * Fires before every HTTP request.
     * @event Struct with request context data (mutable)
     */
    function onRequestStart( struct event={} ) {
        log.info( "→ #cgi.request_method# #cgi.script_name##cgi.query_string ?: ''#" )
        event.requestStartTime = getTickCount()
    }

    /**
     * Fires after every HTTP request.
     */
    function onRequestEnd( struct event={} ) {
        var elapsed = getTickCount() - (event.requestStartTime ?: getTickCount())
        log.info( "← #cgi.script_name# completed in #elapsed#ms" )
    }

    /**
     * Fires when an unhandled exception occurs.
     */
    function onException( struct event={} ) {
        var ex = event.exception ?: {}
        log.error( "Exception: #ex.message ?: 'unknown'# | #ex.stackTrace ?: ''#" )
    }

}
```

## Creating a Java Interceptor

```java
// src/main/java/com/example/interceptors/RequestLogger.java
package com.example.interceptors;

import ortus.boxlang.runtime.events.BaseInterceptor;
import ortus.boxlang.runtime.events.InterceptionPoint;
import ortus.boxlang.runtime.scopes.Key;
import ortus.boxlang.runtime.types.IStruct;

@ortus.boxlang.runtime.events.Interceptor
public class RequestLogger extends BaseInterceptor {

    @Override
    public void configure() {
        // this.properties is available for config
        // this.log is available for logging
        // this.interceptorService is available
        // this.boxRuntime is available
    }

    // @InterceptionPoint marks this method as an event handler
    @InterceptionPoint
    public void onRequestStart( IStruct event ) {
        String method = (String) event.getOrDefault( Key.of("requestMethod"), "GET" );
        this.log.info( "Request started: " + method );
        event.put( Key.of("startTime"), System.currentTimeMillis() );
    }

    @InterceptionPoint
    public void onRequestEnd( IStruct event ) {
        Long startTime = (Long) event.getOrDefault( Key.of("startTime"), System.currentTimeMillis() );
        long elapsed   = System.currentTimeMillis() - startTime;
        this.log.info( "Request completed in " + elapsed + "ms" );
    }

    @InterceptionPoint
    public void preFunctionInvoke( IStruct event ) {
        // event contains: functionName, arguments, context
        String fnName = event.getAsString( Key.of("functionName") );
        this.log.debug( "Invoking function: " + fnName );
    }

}
```

## Lambda and Closure Interceptors

Closures/lambdas **must** explicitly specify which events they handle:

```boxlang
// Closure interceptor — must specify states
var myListener = function( struct event={} ) {
    writeOutput( "Request started!" )
}

// Register for specific events
boxRegisterInterceptor(
    myListener,
    ["onRequestStart", "onRequestEnd"]
)

// Lambda form
boxRegisterInterceptor(
    (event) -> logEvent( event ),
    ["onHTTPRequest"]
)
```

## Registering Interceptors

### Method 1: ModuleConfig.bx (Recommended for Modules)

```boxlang
// ModuleConfig.bx
class {

    this.interceptors = [
        {
            // Full invocation path to the interceptor class
            class      : "#moduleRecord.invocationPath#.interceptors.RequestLogger",
            properties : {
                logLevel  : "INFO",
                maxErrors : 100
            }
        },
        {
            class      : "#moduleRecord.invocationPath#.interceptors.SecurityFilter",
            properties : { enabled: true }
        }
    ]

}
```

### Method 2: BIF Registration

```boxlang
// Global runtime interceptor
boxRegisterInterceptor( new interceptors.MyInterceptor() )

// With properties
boxRegisterInterceptor(
    new interceptors.AuditLog(),
    [],           // states: empty = listen to all matching methods
    { logPath: "/var/log/audit.log" }
)

// Application request listener (web context)
boxRegisterRequestInterceptor( new interceptors.AuthFilter() )
```

### Method 3: InterceptorService API (Java)

```java
InterceptorService service = BoxRuntime.getInstance().getInterceptorService();

// Register a Java-based interceptor
service.register( new RequestLogger() );

// Register with properties
IStruct props = new Struct();
props.put( Key.of("logLevel"), "DEBUG" );
service.register( new RequestLogger(), props );

// Register a BoxLang class
IClassRunnable bxInterceptor = (IClassRunnable) context.loadClass("interceptors.MyBxInterceptor");
service.register( bxInterceptor );

// Register a closure for specific states
service.register(
    (IInterceptorLambda) event -> System.out.println("Event: " + event),
    Key.of("onRequestStart"), Key.of("onRequestEnd")
);
```

## Common Interception Points

### Runtime Events

| Event | When | Payload Keys |
|---|---|---|
| `afterRuntimeStart` | Runtime fully started | `runtime` |
| `beforeRuntimeShutdown` | Before shutdown | `runtime` |
| `afterModuleLoad` | After a module loads | `moduleName`, `moduleRecord` |
| `beforeModuleUnload` | Before a module unloads | `moduleName` |
| `onParse` | Before source is parsed | `source`, `result` |
| `afterParse` | After source is parsed | `source`, `AST` |

### Request Events (Web Context)

| Event | When | Notes |
|---|---|---|
| `onRequestStart` | Before application `onRequestStart` | v1.11+: fires before Application.bx lifecycle |
| `onHTTPRequest` | For every HTTP request | Includes request metadata |
| `onRequestEnd` | After request completes | Includes timing info |
| `onException` | Unhandled exception | Includes exception struct |
| `onSessionStart` | New session created | Session struct available |
| `onSessionEnd` | Session expires or invalidated | Session data available |

### Function Events

| Event | When | Payload |
|---|---|---|
| `preFunctionInvoke` | Before any function call | `functionName`, `arguments`, `context` |
| `postFunctionInvoke` | After any function call | `functionName`, `result` |

## Announcing Custom Events

You can announce your own events for other interceptors to listen to:

```boxlang
// Announce a custom event with a data payload
boxAnnounce( "onUserRegistered", {
    userId  : newUser.getId(),
    email   : newUser.getEmail(),
    source  : "web"
})

// Listeners elsewhere can react to this:
// function onUserRegistered( struct event={} ) {
//     sendWelcomeEmail( event.email )
//     createDefaultWorkspace( event.userId )
// }
```

```java
// Java: announce via InterceptorService
IStruct data = new Struct();
data.put( Key.of("userId"), userId );
data.put( Key.of("email"),  email );

BoxRuntime.getInstance()
    .getInterceptorService()
    .announce( Key.of("onUserRegistered"), data );
```

## Use Cases

### A/B Routing and Feature Flags (pre-request)

```boxlang
// interceptors/FeatureFlagRouter.bx
// v1.11+: fires BEFORE Application.bx onRequestStart — enables rerouting
class {
    function onRequestStart( struct event={} ) {
        var userId = session.userId ?: ""
        if ( len(userId) && featureFlags.isEnabled("new-ui", userId) ) {
            event.overridePath = "/new-ui" & cgi.path_info
        }
    }
}
```

### Maintenance Mode

```boxlang
// interceptors/MaintenanceMode.bx
class {
    function onRequestStart( struct event={} ) {
        if ( application.maintenanceMode && !isAdminIp( cgi.remote_addr ) ) {
            include "maintenance.bxm"
            abort
        }
    }
}
```

### AOP Method Tracing

```boxlang
// interceptors/MethodTracer.bx
class {
    function preFunctionInvoke( struct event={} ) {
        var fn    = event.functionName ?: "unknown"
        var start = getTickCount()
        event.traceStart = start
        log.debug( "→ #fn# called" )
    }

    function postFunctionInvoke( struct event={} ) {
        var elapsed = getTickCount() - (event.traceStart ?: getTickCount())
        log.debug( "← #event.functionName ?: 'unknown'# completed in #elapsed#ms" )
    }
}
```

### Content Manipulation

```boxlang
// interceptors/HtmlMinifier.bx
class {
    function onRequestEnd( struct event={} ) {
        // Minify HTML output before sending to client
        var output = event.output ?: ""
        if ( len(output) ) {
            event.output = minifyHtml( output )
        }
    }
}
```

## Unregistering Interceptors

```boxlang
// Unregister by reference
boxUnregisterInterceptor( myInterceptorInstance )

// Via InterceptorService (Java)
BoxRuntime.getInstance().getInterceptorService().unregister( myInterceptor )
```

## References

- [Interceptors](https://boxlang.ortusbooks.com/boxlang-framework/interceptors)
- [BaseInterceptor](https://github.com/ortus-boxlang/BoxLang/blob/development/src/main/java/ortus/boxlang/runtime/events/BaseInterceptor.java)
- [InterceptorService](https://github.com/ortus-boxlang/BoxLang/blob/development/src/main/java/ortus/boxlang/runtime/services/InterceptorService.java)
- [BoxLang Source](https://github.com/ortus-boxlang/BoxLang)
