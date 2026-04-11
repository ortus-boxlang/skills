---
description: Scaffold a complete BoxLang module directory and files. Usage: /boxlang-agent-skills:new-module my-module-name
---

Scaffold a complete BoxLang module named `$ARGUMENTS`.

## Directory structure to create

```
$ARGUMENTS/
├── ModuleConfig.bx
├── box.json
├── bifs/
├── components/
├── interceptors/
├── models/
└── libs/
```

## `ModuleConfig.bx`

```boxlang
/**
 * Module descriptor for $ARGUMENTS
 */
class {

    this.title          = "$ARGUMENTS"
    this.author         = ""
    this.webURL         = ""
    this.description    = ""
    this.version        = "1.0.0"
    this.boxlangVersion = ">=1.0.0"

    /**
     * Module settings — override via boxlang.json modules.$ARGUMENTS.settings
     */
    this.settings = {
        // example : "value"
    }

    /**
     * Interceptors to register on load
     */
    this.interceptors = [
        // { class: "#moduleRecord.invocationPath#.interceptors.MyInterceptor", properties: {} }
    ]

    /**
     * Component (custom tag) paths to register
     */
    this.componentPaths = [
        // "#moduleRecord.physicalPath#/components"
    ]

    /**
     * Called first after module metadata is loaded.
     * Validate and compute settings here.
     */
    function configure() {
    }

    /**
     * Called after the module is fully registered.
     * Initialize resources and register services here.
     */
    function onLoad() {
        log.info( "Module [$ARGUMENTS] loaded. Version: #this.version#" )
    }

    /**
     * Called on server shutdown or module hot-reload.
     * Release resources and close connections here.
     */
    function onUnload() {
        log.info( "Module [$ARGUMENTS] unloaded." )
    }

}
```

## `box.json`

```json
{
    "name"         : "$ARGUMENTS",
    "slug"         : "$ARGUMENTS",
    "version"      : "1.0.0",
    "author"       : "",
    "type"         : "boxlang-module",
    "description"  : "",
    "homepage"     : "",
    "repository"   : { "type": "git", "url": "" },
    "license"      : [ { "type": "Apache-2.0" } ],
    "dependencies" : {},
    "devDependencies": {}
}
```

## After scaffolding

Tell the user:
- Place the module folder inside BoxLang's `modules/` directory for auto-discovery
- Run `box install` inside the module to pull ForgeBox dependencies
- Use `/boxlang-agent-skills:new-bif <package.BifName>` to add BIFs
- Use `/boxlang-agent-skills:new-component <package.ComponentName>` to add components
- For a full Gradle build with CI/CD and publishing: clone https://github.com/ortus-boxlang/boxlang-module-template
