---
name: bx-docbox
description: Use this skill to generate API documentation from BoxLang source code using DocBox: CLI usage, programmatic DocBox.addStrategy().generate(), HTML themes (default SPA and frames), JSON output, UML/XMI output, project title configuration, source exclusions, and commandbox integration.
---

# bx-docbox: API Documentation Generator

## Installation

```bash
install-bx-module bx-docbox
# CommandBox
box install bx-docbox
```

## CLI Usage

```bash
# Basic usage
boxlang module:docbox \
    --source=/path/to/source \
    --mapping=myapp \
    --output-dir=/path/to/docs

# With all options
boxlang module:docbox \
    --source=/path/to/source \
    --mapping=myapp \
    --output-dir=/path/to/docs \
    --project-title="My Application API Docs" \
    --theme=default \
    --excludes=tests,build

# CommandBox (when bx-docbox is installed as a box module)
box docbox generate \
    source=./src \
    mapping=myapp \
    outputDir=./docs/api \
    projectTitle="My API"
```

## Output Formats

| Format | Strategy Name | Description |
|--------|---------------|-------------|
| HTML (default SPA) | `"HTML"` | Single-page app layout, modern theme |
| HTML (frames) | `"HTML"` with `theme:"frames"` | Traditional frames layout |
| JSON | `"JSON"` | Raw JSON metadata export |
| UML / XMI | `"UML"` | StarUML-compatible XMI output |

## Programmatic Usage: HTML Documentation

```javascript
// Minimal HTML docs
new docbox.DocBox()
    .addStrategy( "HTML", {
        outputDir    : expandPath( "/app/docs/api" ),
        projectTitle : "My Application API"
    })
    .generate(
        source  : expandPath( "/app/models" ),
        mapping : "app.models"
    )
```

## Multiple Strategies (HTML + JSON)

```javascript
new docbox.DocBox()
    .addStrategy( "HTML", {
        outputDir    : expandPath( "/app/docs/api" ),
        projectTitle : "My Application API",
        theme        : "default"           // "default" or "frames"
    })
    .addStrategy( "JSON", {
        outputDir    : expandPath( "/app/docs/json" ),
        projectTitle : "My Application API"
    })
    .generate(
        source   : expandPath( "/app" ),
        mapping  : "app",
        excludes : "tests,build,node_modules"
    )
```

## Frames Layout Theme

```javascript
// Traditional JavaDoc-style frames layout
new docbox.DocBox()
    .addStrategy( "HTML", {
        outputDir    : expandPath( "/app/docs" ),
        projectTitle : "My Application API",
        theme        : "frames"
    })
    .generate(
        source  : expandPath( "/app" ),
        mapping : "app"
    )
```

## UML / XMI Output

```javascript
// Generate StarUML-compatible XMI
new docbox.DocBox()
    .addStrategy( "UML", {
        outputDir    : expandPath( "/app/docs/uml" ),
        projectTitle : "My Application UML"
    })
    .generate(
        source  : expandPath( "/app/models" ),
        mapping : "app.models"
    )
```

## Excluding Directories or Packages

```javascript
new docbox.DocBox()
    .addStrategy( "HTML", {
        outputDir    : expandPath( "/app/docs/api" ),
        projectTitle : "My Application API"
    })
    .generate(
        source   : expandPath( "/app" ),
        mapping  : "app",
        // Comma-separated paths/packages to exclude
        excludes : "tests,build,app.helpers.internal,app.legacy"
    )
```

## Build Task Integration (Gradle / CommandBox)

```javascript
// build/DocTask.bx (CommandBox task runner)
component {
    function run() {
        print.line( "Generating API documentation..." )

        new docbox.DocBox()
            .addStrategy( "HTML", {
                outputDir    : expandPath( "../docs/api" ),
                projectTitle : "My Framework API"
            })
            .generate(
                source   : expandPath( "../src" ),
                mapping  : "myframework",
                excludes : "tests"
            )

        print.greenLine( "Documentation generated successfully." )
    }
}
```

## Using Annotations in Source Code

DocBox extracts JavaDoc-style annotations from your BoxLang files:

```javascript
/**
 * User service for managing application users.
 *
 * @author John Doe
 * @since 1.0.0
 */
class UserService {

    /**
     * Find a user by their ID.
     *
     * @id      The user's unique identifier
     * @return  The user struct or empty struct if not found
     */
    function findById( required numeric id ) {
        // ...
    }
}
```

## Common Pitfalls

- ✅ The `mapping` must match the dot-notation mapping from your web root to the source directory
- ❌ Don't use absolute OS paths for `mapping` — use logical component paths (e.g., `app.models`)
- ✅ Use `expandPath()` to resolve source and output directories to absolute OS paths
- ❌ Nested `addStrategy()` calls are fluent — they return the DocBox instance; always call `.generate()` last
- ✅ The `excludes` parameter accepts comma-separated path fragments, not regex patterns
- ✅ The HTML "default" theme gives a modern SPA look; "frames" gives a classic JavaDoc layout
