---
name: boxlang-cfml-migration
description: "Use this skill when helping developers migrate from CFML (Adobe ColdFusion or Lucee) to BoxLang, understanding key syntax and behavioral differences, using the bx-compat-cfml compatibility module, converting CFML file types, fixing common migration issues (scopes, annotations, query params, date handling), and writing code that works on both runtimes. Also use it when an app contains a MIGRATION.md or an AGENTS.md written by the BoxLang Migration Assistant, or migration tickets labelled boxlang-migration, to work through the open items in order and verify them with boxlang check and the feature audit."
---

# BoxLang for CFML Developers

> BoxLang is the AI-native software productivity platform for building, modernizing and running applications, with developers and AI agents working together.

## Overview

BoxLang is a new language with a **dual parser** — it can parse and run CFML file types (`.cfc`, `.cfm`, `.cfs`) while also offering a modern native syntax via `.bx` / `.bxs` / `.bxm` files. For full CFML behavioral parity, install the `bx-compat-cfml` compatibility module.

---

## Migration Workflow

Work in this order. Each step has a command you can run to verify it.

1. **Assess.** Find out what compiles and what is missing before changing code:

```bash
# Parse every file with the real BoxLang compiler (BoxLang 1.17+)
boxlang check --source ./ --format json

# Audit every BIF, component and member method the app uses
boxlang featureaudit --source ./ --missing
```

   In the audit report, a row with `Missing=true` and a `Module` value needs that module (a trailing `+` marks a BoxLang+ module). A row with `Missing=true` and no module is a real gap that needs code changes.

2. **Fix files that do not compile.** These block everything else. Fix one file at a time and run `boxlang check --source <file>` after each change.
3. **Replace the real gaps.** For each unsupported feature, replace it with a BoxLang equivalent or a module, at every location the audit lists.
4. **Add the modules.** Add `bx-compat-cfml` plus every module the audit names to `server.json` or `box.json` (see the modules skill).
5. **Bring the server settings.** Datasources, mail servers and mappings come from a CFConfig export of the old server, which CommandBox applies on start.
6. **Start and test.** Start the app on BoxLang with CommandBox, then test the key pages, datasources, mail, scheduled tasks and file paths.
7. **Then modernize** (optional). Convert files to native BoxLang syntax with `boxlang cftranspile` when you are ready, and remove `bx-compat-cfml` once nothing needs it.

Keep behavior unchanged while migrating. Do not rewrite code that already works on BoxLang.

### Apps prepared by the BoxLang Migration Assistant

The [BoxLang Migration Assistant](https://boxlang.ortusbooks.com/getting-started/overview/running-coldfusion-cfml-apps) desktop app runs the assessment above and writes these files into the app. When you find them, use them:

| File | What it holds |
|---|---|
| `MIGRATION.md` | The migration checklist: every item with its status, steps, acceptance criteria and file locations. Regenerated on every run, so do not edit it by hand. |
| `AGENTS.md` | A block between the assistant's markers with the source engine, the compile and audit results, the modules and the skills to read. Keep your own content outside the markers. |
| `server.json`, `box.json` | Start the app on BoxLang with the modules it needs. |
| `.agents/skills/` | This skill and the modules skill. |

Teams may also have imported the checklist as Jira or GitHub tickets labelled `boxlang-migration`. Each ticket carries its steps, acceptance criteria, locations and a short AI prompt.

When working from the checklist or the tickets:

- Work the open items in the order they are listed: compile errors, then gaps, then modules.
- Handle one item at a time, and report what you changed for each.
- Verify each item with `boxlang check` on the changed files. Re-run the feature audit (or the assistant) to confirm a gap is gone.
- Items marked for "your team" (testing key pages, datasources and services, production setup, rollback) need a person. Do not mark them done.

---

## The `bx-compat-cfml` Compatibility Module

The module patches BoxLang to behave like Adobe ColdFusion or Lucee for legacy code:

```bash
# CommandBox install
install bx-compat-cfml

# Auto-install via server.json script
{
    "scripts": {
        "onServerInitialInstall": "install bx-compat-cfml"
    }
}
```

What it enables/restores:

- `client` scope support
- `cfsqltype` / `cf_sql_*` query param syntax
- `blockfactor` query option (instead of `fetchSize`)
- Date comparison at second-level precision (instead of millisecond)
- CFML tag prefix `<cfXXX>` alongside `<bx:XXX>`
- Legacy BIF names (`asc`, `chr`, `serializeJSON`, etc.)

> If CFML files start up without this module, BoxLang will still parse them — but behavioral differences (listed below) will apply.

---

## File Types

BoxLang parses all traditional CFML file types:

| Extension | Type | Notes |
|-----------|------|-------|
| `.cfc` | Component / Class | CFML classes |
| `.cfs` | Script | CFML scripts |
| `.cfm` | Template | CFML templates |
| `.bx` | Class | Native BoxLang class |
| `.bxs` | Script | Native BoxLang script |
| `.bxm` | Template | Native BoxLang template |

---

## Components → Classes

CFML components become classes in BoxLang. `component` and `class` keywords are interchangeable, but `.bx` files use `class`:

```js
// CFML (.cfc)
component {
    property name="firstName";
}

// BoxLang (.bx)
class {
    property name="firstName";
}
```

---

## Tags → Components (Template Prefix Change)

BoxLang uses a `<bx:` prefix in templates instead of `<cf`:

```xml
<!-- CFML -->
<cfif expression>
    <cfelse>
</cfif>

<!-- BoxLang -->
<bx:if expression>
    <bx:else>
</bx:if>
```

---

## Default Assignment Scope in Functions

| File Type | Default function assignment scope |
|-----------|----------------------------------|
| `.cfm` / `.cfc` | `variables` (CFML behavior) |
| `.bx` / `.bxs` / `.bxm` | `local` (BoxLang behavior) |

```js
// In a .cfc — assigns to variables scope (CFML compat)
function foo() {
    x = 42  // variables.x
}

// In a .bx — assigns to local scope (BoxLang default)
function foo() {
    x = 42  // local.x
}
```

---

## Function `output` Annotation Default

| File Type | Default `output` |
|-----------|-----------------|
| `.cfm` / `.cfc` | `true` |
| `.bx` / `.bxs` / `.bxm` | `false` |

---

## Accessors Are `true` by Default

BoxLang enables accessors automatically — no need to declare `accessors="true"` on CFML classes:

```js
class {
    property name="fullName";
}

var user = new User()
user.setFullName( "Luis" )         // generated setter
println( user.getFullName() )      // generated getter
```

### Invoke Implicit Accessors

BoxLang also enables **implicit accessor invocation** by default — property-style access calls the getter/setter transparently:

```js
user.fullName = "Luis Majano"   // calls setFullName()
println( user.fullName )        // calls getFullName()
```

---

## Annotations (Documentation Comments)

In CFML, doc comment annotations affect function/argument behavior. In BoxLang, doc comments are documentation **only** — move behavioral annotations to proper `@annotation` syntax:

```js
// CFML
/**
 * @output false
 * @brad wood
 * @myService my hint here
 * @myService.inject
 */
function foo( required any myService ) {}

// BoxLang
/**
 * @myService my hint here
 */
@output( false )
@brad( "wood" )
@myService.inject
function foo( required any myService ) {}
```

---

## Multiple Catch Types

BoxLang supports catching multiple exception types in one `catch` block:

```js
try {
    // ...
} catch ( foo.Exception | bar.Exception | com.luis.majano e ) {
    println( e.message )
}
```

---

## `castAs` Operator

Use `castAs` instead of `javaCast()`:

```js
// CFML
javaCast( "int", myValue )

// BoxLang
myValue castAs "int"
```

---

## Import and Object Resolvers

BoxLang's `import` supports class aliases and resolver prefixes:

```js
// Standard import
import models.User

// With alias (avoids name collisions)
import java:org.apache.User as jUser
import models.User

var oUser = new jUser()
var appUser = new User()

// Resolvers in extends/implements
class implements="java:java.io.Serializable" {
    // ...
}
```

Built-in resolvers: `bx:` (default), `java:`

---

## No `client` Scope (Without Compat Module)

BoxLang does not implement a native `client` scope. Use `session` instead — sessions can be backed by any cache provider and distributed. Install `bx-compat-cfml` if you need `client` scope for legacy code.

---

## BIF Renames

| CFML | BoxLang |
|------|---------|
| `asc()` | `ascii()` |
| `chr()` | `char()` |
| `serializeJSON()` | `jsonSerialize()` |
| `deserializeJSON()` | `jsonDeserialize()` |
| `getComponentMetadata()` | `getClassMetadata()` |

---

## `createObject` Type Change

```js
// CFML
createObject( "component", "models.User" )

// BoxLang
createObject( "class", "models.User" )
```

---

## JDBC Query Changes

### `sqltype` replaces `cfsqltype`

```js
// CFML
queryExecute(
    "SELECT * FROM users WHERE id = :id",
    { id: { value: arguments.id, cfsqltype: "cf_sql_numeric" } }
)

// BoxLang (preferred)
queryExecute(
    "SELECT * FROM users WHERE id = :id",
    { id: { value: id, sqltype: "numeric" } }
)
```

| Syntax | BoxLang Core Behavior |
|--------|-----------------------|
| `sqltype: "numeric"` | ✅ Preferred |
| `sqltype: "cf_sql_numeric"` | Silently treated as `"numeric"` |
| `cfsqltype: "cf_sql_numeric"` | ❌ Error in core; OK with `bx-compat-cfml` |

### `fetchSize` replaces `blockfactor`

```js
// CFML
queryExecute( "SELECT * FROM bigTable", {}, { blockfactor: 100 } )

// BoxLang
queryExecute( "SELECT * FROM bigTable", {}, { fetchSize: 100 } )
```

---

## `cflock type="exclusive"` (v1.17.6+)

Earlier CF-transpiled locks written with `type="exclusive"` were compiled as read locks. This is fixed: `write` and `exclusive` map to exclusive, `readonly` stays read, anything else defaults to read. Expect more lock contention in code that unknowingly relied on the old behavior.

## Date and Time Handling

BoxLang uses `java.time.ZonedDateTime` (not `java.util.Date`) for all date/time values. This means:

- **Precision**: millisecond-level (CFML was second-level)
- **Timezone-aware** by default
- Greater internationalization accuracy

```js
// If you need to pass a date to Java code requiring java.util.Date
var legacyDate = toLegacyDate( myDate )
```

BoxLang 1.18 adds single-unit setters as BIFs and member methods: `dateSetYear()`, `dateSetMonth()`, `dateSetDay()`, `dateSetHour()`, `dateSetMinute()`, `dateSetSecond()` (or `myDate.setDay( 15 )`). They mutate in place and return the date; out-of-range values roll over.

With `bx-compat-cfml`, date comparison functions revert to second-level precision to match legacy behavior.

### Date Addition Rounding

BoxLang correctly rounds date additions to the millisecond. Legacy engines incorrectly rounded sub-second additions to the minute:

```js
var epochDate = parseDateTime( "1970-01-01T00:00:00.000Z" )
var updatedDate = dateAdd( "s", 500/1000, epochDate )
// BoxLang: "1970-01-01T00:00:01.000Z" ✅
// Legacy CFML engines: "1970-01-01T00:01:00.000Z" ❌ (wrong)
```

---

## `structCopy` Behavior Change (Lucee)

Lucee's `structCopy( cfc )` returned a shallow copy of the CFC. BoxLang returns a struct representation of the properties instead. Use `duplicate()` for a shallow CFC copy:

```js
// Lucee
var copy = structCopy( myCFC )  // returned CFC copy — no longer works this way

// BoxLang
var copy = myCFC.duplicate()    // correct shallow copy
```

---

## `getCurrentTemplatePath()` and Relative Includes

BoxLang makes template path resolution consistent across all cases. The "current template path" and relative lookups always resolve to the **original source file on disk** of the executing code — regardless of whether it's an injected UDF, a closure, or a direct include.

Adobe CF and Lucee disagree with each other for injected UDFs; BoxLang picks one sane, consistent rule.

---

## Auto-casting of Arguments and Return Types

When a function argument or return value is typed as `numeric`, BoxLang actively casts the value to a real number (not a string that looks like one). This is transparent in most cases but can affect:

- `getClass()` checks on the underlying Java type
- Passing values directly to Java methods expecting a specific numeric type

---

## Migration Checklist

- [ ] Run `boxlang check` and `boxlang featureaudit` (or the BoxLang Migration Assistant) before changing code
- [ ] Install `bx-compat-cfml` for legacy CFML apps before making any changes
- [ ] Replace `cfsqltype` with `sqltype` and strip `cf_sql_` prefix
- [ ] Replace `blockfactor` query option with `fetchSize`
- [ ] Move doc comment annotations (`@output false`, etc.) to proper `@annotation` syntax in `.bx` files
- [ ] Replace `createObject("component", ...)` with `createObject("class", ...)`
- [ ] Update BIF calls: `serializeJSON` → `jsonSerialize`, `chr` → `char`, etc.
- [ ] Replace `<cf` tag prefix with `<bx:` in templates being migrated to `.bxm`
- [ ] Use `toLegacyDate()` only when passing dates to Java APIs requiring `java.util.Date`
- [ ] Replace `structCopy( cfc )` with `myCFC.duplicate()` if coming from Lucee
- [ ] Verify function default scoping — `.bx` functions default to `local`, not `variables`
- [ ] Verify `output` annotation behavior — `.bx` functions default to `output=false`
- [ ] Leverage `castAs` operator instead of `javaCast()` in new BoxLang code
- [ ] Use `import java:ClassName as alias` to resolve class name collisions
