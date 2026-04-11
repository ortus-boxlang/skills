---
description: Scaffold a JUnit 5 test for a BoxLang Component (custom tag). Usage: /boxlang-agent-skills:new-component-test com.example.components.MyTag
---

Create a JUnit 5 test class for the BoxLang Component `$ARGUMENTS`.

## Rules

- Add the Apache 2.0 file header — read `workbench/CodeHeader.txt` from the BoxLang source root for the exact text
- Mirror the component package under the test source root: `src/test/java/<package/path>/<ClassName>Test.java`
- Use Google Truth for assertions: `import static com.google.common.truth.Truth.assertThat`
- Also import `static org.junit.jupiter.api.Assertions.assertTrue`

## Standard class structure

Components produce output, so capture it with a `ByteArrayOutputStream`:

```java
static BoxRuntime           instance;
ScriptingRequestBoxContext  context;   // ScriptingRequestBoxContext, not just IBoxContext
IScope                      variables;
ByteArrayOutputStream       baos;
static Key                  result = new Key( "result" );

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
    context.setOut( new PrintStream( ( baos = new ByteArrayOutputStream() ), true ) );
    variables = context.getScopeNearby( VariablesScope.name );
}
```

## Required imports

```java
import java.io.ByteArrayOutputStream;
import java.io.PrintStream;
import ortus.boxlang.compiler.parser.BoxSourceType;
import ortus.boxlang.runtime.BoxRuntime;
import ortus.boxlang.runtime.context.ScriptingRequestBoxContext;
import ortus.boxlang.runtime.scopes.IScope;
import ortus.boxlang.runtime.scopes.Key;
import ortus.boxlang.runtime.scopes.VariablesScope;
import org.junit.jupiter.api.*;
import static com.google.common.truth.Truth.assertThat;
import static org.junit.jupiter.api.Assertions.assertTrue;
```

## Test method pattern

Each test must:
- Be annotated with `@DisplayName( "It ..." )` and `@Test`
- Call `instance.executeSource( "...source...", context, BoxSourceType.XXX )`
- Assert either `baos.toString()` for output-producing components or `variables.get( result )` for variable-capturing use

## Test coverage to generate — cover all three syntaxes

1. **CFTEMPLATE** (`BoxSourceType.CFTEMPLATE`): `<cftag attr="val">...</cftag>`
2. **BOXTEMPLATE** (`BoxSourceType.BOXTEMPLATE`): `<bx:tag attr="val">...</bx:tag>`
3. **BOXSCRIPT** (`BoxSourceType.BOXSCRIPT`): `bx:tag attr="val" { ... }`
4. **Variable capture** (if the component supports a `variable` attribute): assert `variables.get( result )` type and value
5. **Edge / validation cases**: omit required attributes, invalid enum values (assert exception or graceful fallback)
