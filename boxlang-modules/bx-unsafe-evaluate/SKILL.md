---
name: bx-unsafe-evaluate
description: "Use this skill when you need the evaluate() BIF in BoxLang for legacy CFML migration or dynamic expression evaluation. This module is explicitly opt-in due to security risks and should be avoided in new code."
---

# bx-unsafe-evaluate: Dynamic Code Evaluation

## Installation

```bash
install-bx-module bx-unsafe-evaluate
# CommandBox
box install bx-unsafe-evaluate
```

## BIF

```javascript
// evaluate( expression )
// Evaluates the expression dynamically from left to right
// Returns the result of the rightmost expression
result = evaluate( expression )
```

## Usage

```javascript
// Dynamic property access
name     = "boxlang"
lastName = "majano"
op       = "eq"

result = evaluate( "#name# #op# #name#" )  // true

// Accessing dynamic variable names
variables.userAge   = 30
variables.userEmail = "test@example.com"

fieldName = "userAge"
value     = evaluate( fieldName )   // Returns 30
```

## Security Warning

{% hint style="danger" %}
`evaluate()` is **explicitly discouraged** for new code. It executes arbitrary BoxLang expressions, which creates serious injection vulnerabilities if any user-controlled input reaches it.
{% endhint %}

### Safer Alternatives for Common Use Cases

```javascript
// ❌ UNSAFE: dynamic variable access via evaluate()
result = evaluate( userControlledInput )

// ✅ SAFE: use struct key access instead
data = { name: "Luis", age: 30 }
key  = "name"
result = data[ key ]    // Direct struct access — no evaluate() needed

// ✅ SAFE: use variables scope access
fieldName = "myVar"
result    = variables[ fieldName ]

// ✅ SAFE: use invoke() for dynamic method calls
result = invoke( obj, methodName, args )
```

## When `evaluate()` Is Acceptable

The ONLY justifiable use case is **legacy CFML migration** — where existing code relies on `evaluate()` and refactoring would take significant time. In all such cases, plan to remove it:

```javascript
// Legacy code being migrated — evaluate() kept temporarily
// TODO: Replace with variables[ fieldName ] when all callers are updated
result = evaluate( fieldName )
```

## Common Pitfalls

- ❌ **Never** pass user input (form fields, URL params, request data) to `evaluate()`
- ❌ Don't use it in new features — there is always a safer alternative
- ✅ Use `variables[ dynamicKey ]` for dynamic variable access
- ✅ Use `invoke( object, methodName, args )` for dynamic method dispatch
- ✅ Remove any `evaluate()` calls as part of code modernization
