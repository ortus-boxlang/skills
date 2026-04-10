---
name: boxlang-functional-programming
description: Use this skill when working with BoxLang lambdas, closures, arrow functions, higher-order functions, functional array/struct pipelines (map, filter, reduce, flatMap, groupBy, etc.), destructuring, or spread syntax.
---

# BoxLang Functional Programming

## Overview

BoxLang treats functions as first-class values. Functions can be stored in variables,
passed as arguments, returned from other functions, and used in functional pipelines.
BoxLang supports closures, lambdas, and arrow functions with a clean, expressive syntax.

## Closures

A closure captures its surrounding variable scope:

```boxlang
// Closure syntax
var greet = function( required string name ) {
    return "Hello, #name#!"
}

writeOutput( greet( "BoxLang" ) )  // Hello, BoxLang!

// Closure capturing outer variables
function makeCounter() {
    var count = 0
    return function() {
        count++
        return count
    }
}

var counter = makeCounter()
counter()   // 1
counter()   // 2
counter()   // 3
```

## Lambdas

Lambdas are lightweight, expression-body functions (no `return` keyword needed):

```boxlang
// Arrow lambda: (args) -> expression
var double   = (n) -> n * 2
var square   = (n) -> n ^ 2
var add      = (a, b) -> a + b

double( 5 )   // 10
add( 3, 4 )   // 7

// Block-body lambda
var process = (item) -> {
    var result = transform( item )
    return validate( result )
}
```

## Arrow Functions (v1.12+)

```boxlang
// Arrow function with block body: (args) => { body }
var validate = (email) => {
    return email.contains( "@" ) && email.contains( "." )
}

// Concise (expression body)
var toUpper = (s) => s.uCase()
```

## Higher-Order Functions

```boxlang
// Passing functions as arguments
function applyTwice( required function fn, required any value ) {
    return fn( fn( value ) )
}

applyTwice( (n) -> n * 2, 3 )   // 12

// Returning a function
function multiplierOf( required numeric factor ) {
    return (n) -> n * factor
}

var triple = multiplierOf( 3 )
triple( 7 )   // 21
```

## Array Functional Methods

All collection methods accept a closure or lambda as the callback.

### `map` — transform each element

```boxlang
var numbers = [1, 2, 3, 4, 5]
var doubled = numbers.map( (n) -> n * 2 )
// [2, 4, 6, 8, 10]

var users = getUsers()
var names = users.map( (u) -> u.getName() )
```

### `filter` — keep matching elements

```boxlang
var evens = numbers.filter( (n) -> n % 2 == 0 )
// [2, 4]

var activeUsers = users.filter( (u) -> u.isActive() )
```

### `reduce` — fold to a single value

```boxlang
var sum = numbers.reduce( (acc, n) -> acc + n, 0 )
// 15

var index = users.reduce( function( acc, user ) {
    acc[ user.getId() ] = user
    return acc
}, {} )
```

### `each` — iterate with side effects

```boxlang
numbers.each( (n) -> writeOutput( n & " " ) )

users.each( function( user, index ) {
    logService.log( "#index#: #user.getEmail()#" )
})
```

### `flatMap` — map then flatten one level

```boxlang
var sentences = ["hello world", "foo bar"]
var words = sentences.flatMap( (s) -> s.listToArray( " " ) )
// ["hello", "world", "foo", "bar"]
```

### `groupBy` — group elements by a key

```boxlang
var byStatus = users.groupBy( (u) -> u.getStatus() )
// { "active": [...], "inactive": [...] }
```

### `chunk` — split into sub-arrays

```boxlang
var batches = [1,2,3,4,5,6,7].chunk( 3 )
// [[1,2,3],[4,5,6],[7]]
```

### `unique` — remove duplicates

```boxlang
var deduped = [1, 2, 2, 3, 3, 3].unique()
// [1, 2, 3]
```

### `reject` — opposite of filter

```boxlang
var inactive = users.reject( (u) -> u.isActive() )
```

### `zip` — pair elements from two arrays

```boxlang
var keys = ["a", "b", "c"]
var vals = [1, 2, 3]
var pairs = keys.zip( vals )
// [["a",1],["b",2],["c",3]]
```

### `transpose` — flip rows and columns

```boxlang
var matrix = [[1,2,3],[4,5,6]]
var transposed = matrix.transpose()
// [[1,4],[2,5],[3,6]]
```

### `sort` — functional sort

```boxlang
var sorted = users.sort( (a, b) -> a.getLastName().compare( b.getLastName() ) )
```

### `find` and `findAll`

```boxlang
var admin = users.find( (u) -> u.getRole() == "admin" )
var admins = users.findAll( (u) -> u.getRole() == "admin" )
```

## Struct Functional Methods

```boxlang
var config = { host: "localhost", port: 8080, debug: true }

// map — transform values
var upper = config.map( (key, val) -> val.toString().uCase() )

// filter — keep matching entries
var strings = config.filter( (key, val) -> isSimpleValue( val ) && isString( val ) )

// reduce
var summary = config.reduce( (acc, key, val) -> acc & "#key#=#val# ", "" )

// each
config.each( (key, val) -> writeOutput( "#key#: #val#<br>" ) )
```

## Function Composition

```boxlang
// Manual composition
function compose( required function f, required function g ) {
    return (x) -> f( g( x ) )
}

var trim      = (s) -> s.trim()
var toLower   = (s) -> s.lCase()
var normalize = compose( toLower, trim )

normalize( "  Hello World  " )   // "hello world"

// Pipeline using array reduce
var pipeline = [
    (s) -> s.trim(),
    (s) -> s.lCase(),
    (s) -> s.replace( " ", "-" )
]

var slug = pipeline.reduce( (val, fn) -> fn( val ), "  Hello World  " )
// "hello-world"
```

## Partial Application

```boxlang
function partial( required function fn, any ...boundArgs ) {
    return function() {
        var allArgs = boundArgs.append( arguments.toArray(), true )
        return fn( argumentCollection=allArgs )
    }
}

var add     = (a, b) -> a + b
var addFive = partial( add, 5 )
addFive( 3 )   // 8
```

## Destructuring with Functional Code (v1.12+)

```boxlang
// Destructure in lambda parameters
var pairs = [["Alice", 30], ["Bob", 25]]
pairs.each( ([name, age]) -> writeOutput( "#name# is #age#" ) )

// Spread in function calls
var args = [1, 2, 3]
var result = sum( ...args )

// Spread in array literals
var merged = [...getDefaults(), ...getOverrides()]
```

## Memoization Pattern

```boxlang
function memoize( required function fn ) {
    var cache = {}
    return function() {
        var key = serializeJSON( arguments )
        if ( !cache.keyExists( key ) ) {
            cache[ key ] = fn( argumentCollection=arguments )
        }
        return cache[ key ]
    }
}

var expensiveCalc = memoize( (n) -> {
    // ... expensive computation
    return n * n
})
```

## References

- [Closures & Lambdas](https://boxlang.ortusbooks.com/boxlang-language/closures-lambdas)
- [Arrays](https://boxlang.ortusbooks.com/boxlang-language/arrays)
- [Structures](https://boxlang.ortusbooks.com/boxlang-language/structures)
- [Functions](https://boxlang.ortusbooks.com/boxlang-language/functions)
