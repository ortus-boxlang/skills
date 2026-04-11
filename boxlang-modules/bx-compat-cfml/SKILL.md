---
name: bx-compat-cfml
description: Use this skill to migrate ColdFusion (Adobe CF) or Lucee CFML applications to BoxLang using the bx-compat-cfml module: zero-code migration, engine configuration, null handling differences, type coercion modes, server scope population, JSON parsing behavior, and identifying incompatibilities.
---

# bx-compat-cfml: CFML Compatibility Layer

## Installation

```bash
install-bx-module bx-compat-cfml
# CommandBox
box install bx-compat-cfml
```

## Purpose

`bx-compat-cfml` enables near-zero-code migration of existing Adobe ColdFusion or Lucee CFML applications to BoxLang. It adjusts BoxLang's behavior to match your source engine's quirks around:

- Null handling and empty-string coercion
- Type coercion and comparison behavior
- Server scope population
- JSON parsing and serialization
- Query null handling
- Function return-value behavior
- ColdFusion/Lucee-specific BIFs and component behaviors

## Configuration (boxlang.json)

```json
{
  "modules": {
    "compat-cfml": {
      "settings": {
        "engine": "lucee"
      }
    }
  }
}
```

### Engine Options

| Value | Description |
|-------|-------------|
| `"lucee"` | Emulates Lucee CFML behavior |
| `"adobe"` | Emulates Adobe ColdFusion behavior |

## Behavioral Differences Emulated

### Null Handling

```javascript
// Adobe CF: null is returned as empty string ""
// Lucee: null is returned as actual null value

// With engine: "adobe"
var result = queryExecute( "SELECT NULL AS val", {}, { returntype: "array" } )
result[1].val == ""      // true — null-to-empty-string conversion

// With engine: "lucee" OR native BoxLang
result[1].val == null    // true — null stays null
```

### Type Coercion

```javascript
// Adobe CF: stricter implicit numeric coercion
// engine: "adobe" emulates Adobe's behavior

// Numeric comparison with strings
"10" > "9"    // Adobe: false (numeric compare: 10 > 9 = true)
"10" > "9"    // Lucee: false (string compare: "1" < "9")
```

### Server Scope

```javascript
// engine: "adobe" populates server scope with Adobe CF-compatible values
// engine: "lucee"  populates server scope with Lucee CF-compatible values

server.ColdFusion.ProductName    // "ColdFusion" (adobe) or "Lucee" (lucee)
server.ColdFusion.ProductVersion // Engine-specific version string
```

### JSON Parsing

```javascript
// Adobe CF: integers parsed from JSON as Integer type
// Lucee: integers parsed as Double

// engine: "adobe"
var data = deserializeJSON( '{"count": 5}' )
isInteger( data.count )   // true

// engine: "lucee"
isDouble( data.count )    // true
```

## Migration Workflow

### Step 1: Install and Configure

```bash
install-bx-module bx-compat-cfml
```

```json
{
  "modules": {
    "compat-cfml": {
      "settings": {
        "engine": "lucee"
      }
    }
  }
}
```

### Step 2: Run Your Application

BoxLang directly runs `.cfc` and `.cfm` files — no conversion needed. Start your application and observe which behaviors differ.

### Step 3: Identify Remaining Issues

Typical remaining issues after enabling the compat module:
- Custom CF tags (`.cftag`) that have no BoxLang equivalent
- Rarely-used Adobe-specific BIFs not in compat layer
- JDBC DataSource configuration differences

### Step 4: Incremental BoxLang Migration

Once the app runs with compat, start converting files to native BoxLang:

```
file.cfc → file.bx        (ColdFusion component → BoxLang class)
file.cfm → file.bxm       (ColdFusion template → BoxLang template)
```

Remove the compat module once all files are converted and all tests pass.

## Key Compatibility Notes

### Adobe CF-Specific BIFs Provided

The compat module adds Adobe CF-compatible versions of BIFs that behave differently in native BoxLang:

- `isJSON()` — Adobe compatibility
- `serializeJSON()` — Preserves Adobe CF serialization quirks
- `queryNew()` — Column type handling
- `structNew("ordered")` — Ordered struct behavior
- Application lifecycle method names (`onSessionStart`, `onCFCRequest`, etc.)

### Lucee-Specific BIFs Provided

- `getApplicationMetadata()` — Lucee-style return format
- Null-safe behavior for various BIFs

## Common Pitfalls

- ✅ Always specify the correct `engine` — "lucee" and "adobe" have meaningfully different behaviors
- ❌ This module covers ~95% of migration cases; some Adobe-only features (e.g., `<cfgrid>`, old forms) have no equivalent
- ✅ Use this as a **migration aid**, not a permanent target — aim to remove it once your code is converted to native BoxLang
- ❌ Don't enable both `engine: "lucee"` and `engine: "adobe"` simultaneously — choose the source engine
- ✅ Check BoxLang compatibility docs at https://boxlang.ortusbooks.com for a full list of covered behaviors
