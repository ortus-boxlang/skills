---
description: Scaffold a new Java BoxLang Component (custom tag). Usage: /boxlang-agent-skills:new-component com.example.components.MyTag
---

Create a new Java BoxLang Component (custom tag) for the fully-qualified class `$ARGUMENTS`.

## Rules

- Derive the Java package from the fully-qualified class name; the simple class name is the last segment
- Add the Apache 2.0 file header — read `workbench/CodeHeader.txt` from the BoxLang source root for the exact text
- Extend `Component` from `ortus.boxlang.runtime.components`
- Annotate with `@BoxComponent( name = "TagName", allowsBody = true/false, requiresBody = false, description = "..." )`
  - Use `allowsBody = true` when the tag wraps content; `false` for self-closing tags
  - Multiple `@BoxComponent` annotations are allowed for aliases
- Declare attributes in the constructor:
  ```java
  declaredAttributes = new Attribute[] {
      new Attribute( Key.of( "attrName" ), "string" ),
      new Attribute( Key.of( "optional" ), "boolean", false ),
      new Attribute( Key.of( "constrained" ), "string", Set.of( Validator.valueOneOf( "a", "b" ) ) )
  };
  ```
- Implement:
  ```java
  public BodyResult _invoke( IBoxContext context, IStruct attributes, ComponentBody body, IStruct executionState )
  ```
- Read attributes with: `attributes.getAsString( Key.of("attr") )`, `attributes.getAsBoolean( Key.of("flag") )`, etc.
- Process body (for tags with body) via: `processBody( context, body )` or `processBody( context, body, outputBuffer )`
- Write output via: `context.writeToBuffer( "..." )`
- Always return `DEFAULT_RETURN` at the end
- Use `this.` prefix for all instance field access
- Use tabs for indentation, max 150 characters per line
- Add `@attribute.attrName Description` Javadoc tags for every declared attribute

## Imports to include

```java
import ortus.boxlang.runtime.components.Attribute;
import ortus.boxlang.runtime.components.BoxComponent;
import ortus.boxlang.runtime.components.Component;
import ortus.boxlang.runtime.context.IBoxContext;
import ortus.boxlang.runtime.scopes.Key;
import ortus.boxlang.runtime.types.IStruct;
```

Add `Validator` and `Set` imports when using value constraints.

## After generating

Tell the user:
- **Source file:** `src/main/java/<package/path>/<ClassName>.java`
- **Test file:** `src/test/java/<package/path>/<ClassName>Test.java` — suggest running `/boxlang-agent-skills:new-component-test <fqn>` to scaffold the test
- **Registration:** In a module, add the components directory to `this.componentPaths` in `ModuleConfig.bx`:
  ```boxlang
  this.componentPaths = [ "#moduleRecord.physicalPath#/components" ]
  ```
