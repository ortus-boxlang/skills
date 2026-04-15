---
name: boxlang-java-integration
description: "Use this skill when integrating BoxLang with Java: createObject, static method calls, type conversion, importing classes, passing closures as functional interfaces, including JARs, JSR-223 scripting, or using Java libraries from BoxLang code."
---

# BoxLang Java Integration

## Overview

BoxLang compiles to Java bytecode and runs on JRE 21+. It has 100% Java
interoperability — any Java library, class, or framework can be used directly
from BoxLang code. Type conversion between BoxLang and Java types is automatic
in most cases.

## Creating Java Objects

```boxlang
// createObject("java", "fully.qualified.ClassName")
var list   = createObject( "java", "java.util.ArrayList" )
var map    = createObject( "java", "java.util.HashMap" )
var date   = createObject( "java", "java.util.Date" )
var sb     = createObject( "java", "java.lang.StringBuilder" )

// Initialize with constructor arguments
var uuid   = createObject( "java", "java.util.UUID" ).randomUUID()

// Using new() shorthand
var list   = new java.util.ArrayList()
var map    = new java.util.HashMap()
```

## Static Methods and Fields

```boxlang
// Static method call: ClassName.method()
var uuid      = createObject( "java", "java.util.UUID" ).randomUUID()
var maxInt    = createObject( "java", "java.lang.Integer" ).MAX_VALUE
var sysProps  = createObject( "java", "java.lang.System" ).getProperties()

// Java Math
var pi      = createObject( "java", "java.lang.Math" ).PI
var sqrt2   = createObject( "java", "java.lang.Math" ).sqrt( 2 )
var abs     = createObject( "java", "java.lang.Math" ).abs( -42 )
```

## Importing Java Classes

```boxlang
// Import for shorthand use
import java.util.ArrayList
import java.util.HashMap
import java.util.concurrent.ConcurrentHashMap
import java.time.LocalDateTime
import java.time.format.DateTimeFormatter

// After import, use short name
var list    = new ArrayList()
var map     = new ConcurrentHashMap()
var now     = LocalDateTime.now()
var fmt     = DateTimeFormatter.ofPattern( "yyyy-MM-dd HH:mm:ss" )
var dateStr = now.format( fmt )
```

## Working with Java Objects

```boxlang
// ArrayList
var list = new java.util.ArrayList()
list.add( "apple" )
list.add( "banana" )
list.add( "cherry" )
list.size()           // 3
list.get( 0 )         // "apple"
list.contains( "banana" )  // true
list.remove( 0 )
list.toArray()        // returns Java Object[]

// HashMap
var map = new java.util.HashMap()
map.put( "name",  "Ada Lovelace" )
map.put( "email", "ada@example.com" )
map.get( "name" )       // "Ada Lovelace"
map.containsKey( "age" )  // false
map.keySet()            // Java Set of keys

// StringBuilder
var sb = new java.lang.StringBuilder()
sb.append( "Hello" )
sb.append( ", " )
sb.append( "World!" )
sb.toString()   // "Hello, World!"
```

## Automatic Type Conversion

BoxLang automatically converts between its types and Java types:

| BoxLang Type | Java Type |
|---|---|
| String | `java.lang.String` |
| Numeric (integer) | `int`, `long`, `java.lang.Integer` |
| Numeric (float) | `double`, `java.lang.Double` |
| Boolean | `boolean`, `java.lang.Boolean` |
| Array | `java.util.List` or `Object[]` |
| Struct | `java.util.Map` |
| Date | `java.util.Date`, `java.time.LocalDateTime` |
| Closure/Lambda | Java functional interface (auto-proxied) |

```boxlang
// BoxLang array → Java List
var bxArray  = [1, 2, 3]
var javaList = createObject( "java", "java.util.ArrayList" ).init( bxArray )

// Java List → BoxLang array (automatic when assigned)
var backToArray = javaList.toArray()
```

## Passing Closures as Java Functional Interfaces

BoxLang closures are automatically proxied to Java functional interfaces:

```boxlang
import java.util.Arrays
import java.util.Comparator

// Sort a Java list using a BoxLang lambda as Comparator
var names = new java.util.ArrayList()
names.add( "Charlie" )
names.add( "Alice" )
names.add( "Bob" )

names.sort( (a, b) -> a.compareTo( b ) )   // BoxLang lambda → Comparator
names  // ["Alice", "Bob", "Charlie"]

// Runnable
var thread = new java.lang.Thread( () -> {
    println( "Running in Java thread!" )
})
thread.start()
thread.join()

// Java Stream API with BoxLang lambdas
import java.util.stream.Collectors

var nums     = new java.util.ArrayList()
[1,2,3,4,5,6].each( (n) -> nums.add(n) )
var evenNums = nums.stream()
    .filter( (n) -> n % 2 == 0 )
    .map( (n) -> n * n )
    .collect( Collectors.toList() )
```

## Handling Java Exceptions

```boxlang
try {
    var conn = DriverManager.getConnection( url, user, pass )
} catch ( "java.sql.SQLException" e ) {
    writeOutput( "SQL error: #e.message#" )
} catch ( "java.lang.ClassNotFoundException" e ) {
    writeOutput( "Driver not found: #e.message#" )
} catch ( any e ) {
    writeOutput( "Java error: #e.type# — #e.message#" )
}
```

## Including Java Libraries (JARs)

### Via `Application.bx`

```boxlang
class {
    this.javaSettings = {
        loadPaths            : [ "lib/", "lib/vendor.jar" ],
        loadColdFusionClassPath : false,
        reloadOnChange       : false
    }
}
```

### Via Module `libs/` Folder

Drop JARs into the module's `libs/` directory — they are scoped to that module:

```
my-module/
├── ModuleConfig.bx
├── libs/
│   ├── my-library-1.2.3.jar
│   └── dependency.jar
```

### Via Maven (Gradle-based modules)

```groovy
// build.gradle
dependencies {
    implementation "com.example:my-library:1.2.3"
}
```

## Java Time API

```boxlang
import java.time.LocalDate
import java.time.LocalDateTime
import java.time.ZonedDateTime
import java.time.ZoneId
import java.time.format.DateTimeFormatter
import java.time.temporal.ChronoUnit

var now      = LocalDateTime.now()
var today    = LocalDate.now()
var utcNow   = ZonedDateTime.now( ZoneId.of( "UTC" ) )

// Format
var fmt    = DateTimeFormatter.ofPattern( "yyyy-MM-dd HH:mm:ss" )
var str    = now.format( fmt )

// Parse
var parsed = LocalDate.parse( "2024-01-15" )

// Arithmetic
var nextWeek = now.plus( 7, ChronoUnit.DAYS )
var daysBetween = ChronoUnit.DAYS.between( today, LocalDate.of(2025,1,1) )
```

## JSR-223: BoxLang as a Java Scripting Engine

Use BoxLang from inside a Java application:

```java
// Java code
import javax.script.ScriptEngineManager;
import javax.script.ScriptEngine;

ScriptEngineManager manager = new ScriptEngineManager();
ScriptEngine engine = manager.getEngineByName("BoxLang");

engine.put("greeting", "Hello from Java!");
engine.eval("println( greeting )");

Object result = engine.eval("return 1 + 2");
System.out.println(result);  // 3
```

## Reflection and Introspection

```boxlang
// Get Java class from a BoxLang object
var obj   = new java.util.ArrayList()
var clazz = obj.getClass()
var name  = clazz.getName()   // "java.util.ArrayList"

// List methods
var methods = clazz.getMethods()
for ( var method in methods ) {
    writeOutput( method.getName() & "<br>" )
}

// Check instanceof
if ( isInstanceOf( obj, "java.util.List" ) ) {
    // ...
}
```

## Common Java Libraries in BoxLang

```boxlang
// Apache Commons Lang
import org.apache.commons.lang3.StringUtils
StringUtils.isBlank( "  " )    // true
StringUtils.capitalize( "hello" )  // "Hello"

// Google Guava
import com.google.common.collect.ImmutableList
var list = ImmutableList.of( "a", "b", "c" )

// Jackson JSON (if bundled)
import com.fasterxml.jackson.databind.ObjectMapper
var mapper = new ObjectMapper()
var json   = mapper.writeValueAsString( myStruct )
var parsed = mapper.readValue( json, createObject("java","java.util.Map").getClass() )
```

## References

- [Java Integration](https://boxlang.ortusbooks.com/boxlang-language/java-integration)
- [JSR-223](https://boxlang.ortusbooks.com/getting-started/overview#jsr-223)
- [JRE 21 Virtual Threads](https://openjdk.org/jeps/444)
