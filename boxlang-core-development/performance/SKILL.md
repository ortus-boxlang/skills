---
name: boxlang-core-dev-performance
description: "Use this skill when writing or reviewing performance-sensitive BoxLang core Java code (BIFs, components, runtime services, hot paths): String.substring() allocation, startsWith with offset, regionMatches, regex precompiling, Key allocation, StringBuilder, boxing, streams, virtual-thread pinning, and measuring with JMH before optimizing."
---

# BoxLang Core Performance

> BoxLang is the AI-native software productivity platform for building, modernizing and running applications, with developers and AI agents working together.

## Overview

BIFs, components, and runtime code run under load, often inside tight loops.
Code that looks like it only reads data can allocate heavily. This skill lists
the patterns that have bitten core string BIFs and how to avoid them.

**Rule zero:** measure first. Apply these patterns to hot paths and BIFs, not to
one-off setup code. Readability wins unless a profile or benchmark says otherwise.

## Strings

### `substring()` is not free

`String.substring()` allocates a new `String` and copies the characters. On a
large input inside a loop this is expensive. Reading code that calls it often
looks harmless.

```java
// BAD: allocates a new String on every iteration
for ( int i = 0; i < input.length(); i++ ) {
    if ( input.substring( i ).startsWith( prefix ) ) {
        count++;
    }
}

// GOOD: no allocation, compares in place
for ( int i = 0; i < input.length(); i++ ) {
    if ( input.startsWith( prefix, i ) ) {
        count++;
    }
}
```

Allocation-free alternatives:

| Instead of | Use |
|------------|-----|
| `s.substring( n ).startsWith( p )` | `s.startsWith( p, n )` |
| `s.substring( a, b ).equals( p )` | `s.regionMatches( a, p, 0, p.length() )` (check `b - a == p.length()`) |
| `s.substring( a, b ).equalsIgnoreCase( p )` | `s.regionMatches( true, a, p, 0, p.length() )` |
| `s.substring( n ).indexOf( x )` | `s.indexOf( x, n )` (result is absolute, not relative to `n`) |
| `s.substring( n ).endsWith( p )` | `s.endsWith( p )` if `n` is only trimming the front; otherwise `regionMatches` |
| `s.substring( i, i + 1 )` | `s.charAt( i )` |
| `s.substring( 0, 4 ).equalsIgnoreCase( "http" )` | `s.regionMatches( true, 0, "http", 0, 4 )` |

Remember `regionMatches` returns `false` if the region runs past the end of the
string, so you rarely need a separate length check.

If you need the substring more than once, take it once and reuse it. One
`substring()` outside a loop is fine.

### Case-insensitive search allocates twice

`a.toLowerCase().indexOf( b.toLowerCase() )` creates two new strings per call.
In a loop, lowercase once outside it, or use `regionMatches( true, ... )` for
prefix and region checks.

### Build strings with `StringBuilder`

- Never use `+` or `+=` on a `String` inside a loop.
- Presize when you know the rough length: `new StringBuilder( input.length() )`.
- Append characters and ranges directly: `sb.append( s, start, end )` avoids the intermediate substring.
- Avoid `String.format()` in hot paths. It parses the format string on every call.
- Prefer `String.join()` or a `StringJoiner` over manual delimiter handling.

### Regex

- Never call `String.split()`, `replaceAll()`, or `matches()` with a non-trivial
  regex in a hot path. Each call compiles a `Pattern`.
- Precompile as a `private static final Pattern`.
- For single-character delimiters, a manual `indexOf` loop or `split( "x" )` with a
  literal that is not a regex metacharacter has a fast path in the JDK.
- Prefer `String.replace( CharSequence, CharSequence )` over `replaceAll()` when
  you do not need a pattern. It does not compile a regex.

```java
// Precompiled once per class, reused for every call
private static final Pattern DECIMAL_SPLIT_PATTERN = Pattern.compile( "\\." );
```

## BoxLang-Specific

### `Key` allocation

`Key.of( String )` allocates a new `Key` on every call. A `Key` precomputes its
hash code, which makes lookups fast, but creating one per call throws that win away.

```java
// BAD: new Key on every invocation
public Object _invoke( IBoxContext context, ArgumentsScope arguments ) {
    String str = arguments.getAsString( Key.of( "str" ) );
}

// GOOD: reuse a shared Key
// Common names already exist as constants on Key (Key.string, Key.value, Key.array ...)
public Object _invoke( IBoxContext context, ArgumentsScope arguments ) {
    String str = arguments.getAsString( Key.string );
}

// GOOD: for names that are not on Key, hold your own constant
private static final Key delimsKey = Key.of( "delimiter_list1" );
```

- Look for an existing `Key.xxx` constant before creating a new one.
- Never call `Key.of()` inside a loop. Hoist it to a `static final` field.
- Keys built from dynamic runtime strings (user-supplied struct keys) cannot be
  constants, so build them once per operation, not once per iteration.

### Immutable value objects

Pre-compute `hashCode` in the constructor for classes whose fields are all `final`,
and return the cached field. See `ortus.boxlang.runtime.util.NameValuePair` and
`Key` for reference implementations.

### Attempt and Optional wrappers

`Attempt` and `Optional` allocate a wrapper. They are great at API boundaries, but
avoid creating them per element in tight loops. Use a plain null check in the inner
loop.

### Argument access

- Fetch each argument once into a local variable at the top of `_invoke()`.
  Do not call `arguments.get( key )` repeatedly inside a loop.
- Use the typed getters (`getAsString`, `getAsInteger`, `getAsArray`) so you do not
  re-run a caster on every iteration.

### Logging in hot paths

`logger.debug( "x {}", y )` with parameterized messages is cheap when disabled.
String concatenation or building arguments before the call is not. Guard
expensive argument construction with `if ( logger.isDebugEnabled() )`.

## Collections and Allocation

- **Presize** `ArrayList`, `HashMap`, and `StringBuilder` when the size is known or
  cheaply estimated.
- **Avoid boxing** in loops. Prefer `int`/`long`/`double` locals over `Integer`/`Long`/`Double`.
  Beware of `Map<String, Integer>` counters that box on every `merge`.
- **Streams and lambdas** are fine for clarity but add allocation and indirection.
  In a hot BIF, use a plain `for` loop.
- **Do not copy to inspect.** If you only need to read an `Array` or `Struct`, iterate
  it directly rather than calling `toArray()` or building a defensive copy.
- **Hoist invariants** out of loops: `size()`, `length()`, lowercased needles, compiled patterns.
- **Return early** for empty or null inputs before doing any allocation.

## Concurrency

- Prefer lock-free structures (`ConcurrentHashMap`, `LongAdder`, `AtomicReference`)
  over `synchronized` on shared hot paths.
- Inside code that may run on virtual threads, avoid blocking while inside a
  `synchronized` block. It can pin the carrier thread. Use `ReentrantLock` instead.
- Avoid `ThreadLocal` caches holding large objects. Virtual threads make
  per-thread state expensive.
- Do not hold locks while calling user-supplied BoxLang code (closures, callbacks).

## Measuring

1. **Reproduce** the slow case with realistic input sizes. Large strings expose
   `substring()` costs that tiny test strings hide.
2. **Benchmark** with [JMH](https://github.com/openjdk/jmh) for micro-level
   questions ("is `startsWith( p, i )` faster than `substring( i ).startsWith( p )`?").
   Hand-rolled `System.nanoTime()` loops lie because of JIT warm-up and dead-code elimination.
3. **Profile** for system-level questions. Java Flight Recorder
   (`-XX:+FlightRecorder`) and async-profiler show allocation hot spots.
   Watch the allocation profile, not just CPU time.
4. **Keep the benchmark** or add a regression test when you fix a hotspot.

## Review Checklist for Hot-Path Code

- [ ] No `substring()` whose result is only compared or searched
- [ ] No `toLowerCase()` / `toUpperCase()` inside a loop on the same value
- [ ] No `Key.of()` in loops or per-invocation for fixed names
- [ ] No regex compile per call (`split`, `replaceAll`, `matches`)
- [ ] No `+=` string concatenation in loops
- [ ] `StringBuilder` presized where size is known
- [ ] No streams, `Attempt`, or boxing per element in inner loops
- [ ] Invariants hoisted out of loops
- [ ] Early return for null/empty input
- [ ] No blocking inside `synchronized` on virtual-thread paths
- [ ] Verified with a benchmark or profile, not assumed

## References

- [BoxLang Docs](https://boxlang.ortusbooks.com/)
- [JMH](https://github.com/openjdk/jmh)
- [Java Flight Recorder](https://docs.oracle.com/en/java/javase/21/jfr/)
- [JEP 444: Virtual Threads](https://openjdk.org/jeps/444)
- See also: `bif-development`, `runtime-architecture`, `logging`
