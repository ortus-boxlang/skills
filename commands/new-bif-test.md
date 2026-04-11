---
description: Scaffold a JUnit 5 test for a BoxLang BIF. Usage: /boxlang-agent-skills:new-bif-test com.example.bifs.MyFunction
---

Create a JUnit 5 test class for the BoxLang BIF `$ARGUMENTS`.

## Rules

- Add the Apache 2.0 file header — read `workbench/CodeHeader.txt` from the BoxLang source root for the exact text
- Mirror the BIF package under the test source root: `src/test/java/<package/path>/<ClassName>Test.java`
- Use Google Truth for all assertions: `import static com.google.common.truth.Truth.assertThat`
- Also import `static org.junit.Assert.assertTrue` for instanceof checks

## Standard class structure

```java
static BoxRuntime  instance;
IBoxContext        context;
IScope             variables;
static Key         result = new Key( "result" );

@BeforeAll
public static void setUp() {
    instance = BoxRuntime.getInstance( true );
}

@AfterAll
public static void teardown() {
}

@BeforeEach
public void setupEach() {
    context   = new ScriptingRequestBoxContext( instance.getRuntimeContext() );
    variables = context.getScopeNearby( VariablesScope.name );
}
```

## Required imports

```java
import ortus.boxlang.runtime.BoxRuntime;
import ortus.boxlang.runtime.context.IBoxContext;
import ortus.boxlang.runtime.context.ScriptingRequestBoxContext;
import ortus.boxlang.runtime.scopes.IScope;
import ortus.boxlang.runtime.scopes.Key;
import ortus.boxlang.runtime.scopes.VariablesScope;
import org.junit.jupiter.api.*;
import static com.google.common.truth.Truth.assertThat;
import static org.junit.Assert.assertTrue;
```

## Test method pattern

Each test must:
- Be annotated with `@DisplayName( "It should ..." )` and `@Test`
- Call `instance.executeSource( "...boxlang script...", context )` — store output in the `result` variable
- Assert via `variables.get( result )` or `variables.getAsString( result )` etc.

## Test coverage to generate

1. Happy-path invocation: basic call with valid input, assert correct return value
2. Member function variant (if the BIF has `@BoxMember`): call as `value.methodName()`
3. Null / empty input: assert graceful return (empty string, 0, false — not an exception)
4. Edge cases relevant to the BIF logic (e.g., boundary values, special characters)
5. Exception test (if applicable): wrap with `assertThrows`
