---
description: Scaffold a new Java BIF for BoxLang. Usage: /boxlang-agent-skills:new-bif com.example.bifs.MyFunction
---

Create a new Java BoxLang Built-In Function (BIF) for the fully-qualified class `$ARGUMENTS`.

## Rules

- Derive the Java package from the fully-qualified class name; the simple class name is the last segment
- Add the Apache 2.0 file header — read `workbench/CodeHeader.txt` from the BoxLang source root for the exact text
- Extend `BIF` from `ortus.boxlang.runtime.bifs`
- Annotate with `@BoxBIF( description = "..." )` — write a concise one-line description
- If the function is a natural member function on a type (e.g., a String function), also add `@BoxMember( type = BoxLangType.SOME_TYPE, name = "methodName" )` — omit otherwise
- Declare all arguments in the constructor:
  ```java
  declaredArguments = new Argument[] {
      new Argument( true,  "string", Key.of( "argName" ) ),
      new Argument( false, "string", Key.of( "optionalArg" ), "defaultValue" )
  };
  ```
- Implement `public Object _invoke( IBoxContext context, ArgumentsScope arguments )` (NOT `invoke`)
- Extract arguments with typed helpers: `arguments.getAsString(Key.of("arg"))`, `arguments.getAsBoolean(...)`, etc.
- Add `@argument.argName Description` Javadoc tags for every declared argument
- Use `this.` prefix for all instance field access
- Use tabs for indentation, max 150 characters per line

## Imports to include

```java
import ortus.boxlang.runtime.bifs.BIF;
import ortus.boxlang.runtime.bifs.BoxBIF;
import ortus.boxlang.runtime.context.IBoxContext;
import ortus.boxlang.runtime.scopes.ArgumentsScope;
import ortus.boxlang.runtime.scopes.Key;
import ortus.boxlang.runtime.types.Argument;
```

Add `BoxMember` and `BoxLangType` imports only when adding a member function.

## After generating

Tell the user:
- **Source file:** `src/main/java/<package/path>/<ClassName>.java`
- **Test file:** `src/test/java/<package/path>/<ClassName>Test.java` — suggest running `/boxlang-agent-skills:new-bif-test <fqn>` to scaffold the test
- **In a module:** place the file in the module's `bifs/` directory — it is auto-discovered at load time; no manual registration needed
