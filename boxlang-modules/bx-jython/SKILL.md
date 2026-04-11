---
name: bx-jython
description: Use this skill when executing Python code inside BoxLang with the bx-jython module: jythonEval(), jythonEvalFile(), the bx:jython component, variable bindings from the BoxLang variables scope, and inter-language result handling.
---

# bx-jython: Execute Python in BoxLang

## Installation

```bash
install-bx-module bx-jython
# CommandBox
box install bx-jython
```

## BIFs

| BIF | Description |
|-----|-------------|
| `jythonEval( code )` | Execute a Python code string |
| `jythonEvalFile( path )` | Execute a Python file |

## Basic Usage

```javascript
// Execute inline Python
jythonEval( "print('Hello from Python!')" )

// Execute Python from a file
jythonEvalFile( "/app/scripts/process.py" )

// Python with arithmetic
jythonEval( "
result = 5 * 10
print('Result:', result)
" )
```

## Variable Bindings

BoxLang automatically binds all `variables` scope values into the Python engine. Use them as native Python variables:

```javascript
// Set variables in BoxLang
variables.name    = "Luis Majano"
variables.message = "Hello from BoxLang"

// These are available directly in Python
jythonEval( "print(name)" )            // Luis Majano
jythonEval( "print(message.upper())" ) // HELLO FROM BOXLANG
```

## Using Python Modules (Files)

```python
# /app/scripts/mathutils.py
def factorial(n):
    if n <= 1:
        return 1
    return n * factorial(n - 1)

def fibonacci(n):
    a, b = 0, 1
    for _ in range(n):
        a, b = b, a + b
    return a
```

```javascript
// Load the Python module
jythonEvalFile( "/app/scripts/mathutils.py" )

// Call the Python function
result = jythonEval( "factorial(10)" )
fib    = jythonEval( "fibonacci(20)" )
println( result )  // 3628800
println( fib )     // 6765
```

## `bx:jython` Component

Use the component for larger multi-line Python blocks captured in a variable:

```javascript
bx:jython variable="result" {
    writeOutput( "
x = 10
y = 20
sum = x + y
product = x * y
print(f'Sum: {sum}, Product: {product}')
" )
}
```

## Capturing the Result

The `jythonEval()` / `jythonEvalFile()` functions return a struct:

```javascript
engineResult = jythonEval( "42 + 8" )

engineRef  = engineResult.engine       // Reference to the Jython engine
globalScope = engineResult.globalScope // JSR223 global scope
engineScope = engineResult.engineScope // JSR223 engine scope
```

## Common Patterns

```javascript
// Use Python for math/scientific processing not easily available in BoxLang
variables.numbers = [1, 2, 3, 4, 5, 6, 7, 8, 9, 10]
jythonEvalFile( "/app/scripts/statistics.py" )
mean   = jythonEval( "mean(numbers)" )
stddev = jythonEval( "std_dev(numbers)" )
```

## Common Pitfalls

- ✅ All variables in the BoxLang `variables` scope are automatically accessible in Python — no explicit passing needed
- ❌ Python uses indentation for blocks — ensure your code strings use consistent indentation
- ✅ Use `jythonEvalFile()` for complex Python logic; use `jythonEval()` for quick invocations
- ❌ Jython runs Python 2.7 syntax (Jython's Python compatibility level) — not Python 3.x
