---
name: bx-yaml
description: "Use this skill when serializing or deserializing YAML in BoxLang with the bx-yaml module: yamlSerialize(), yamlDeserialize(), yamlDeserializeFile(), serializing BoxLang classes to YAML, and custom toYAML() methods."
---

# bx-yaml: YAML Serialization

## Installation

```bash
install-bx-module bx-yaml
# CommandBox
box install boxlang-yaml
```

## BIFs

| BIF | Description |
|-----|-------------|
| `yamlSerialize( content, [filepath], [charset] )` | Serialize a BoxLang value to a YAML string (or file) |
| `yamlDeserialize( content )` | Parse a YAML string into a BoxLang value |
| `yamlDeserializeFile( filepath, [charset] )` | Parse a YAML file into a BoxLang value |

## Basic Usage

```javascript
// Serialize a struct to YAML
yaml = yamlSerialize( { name: "Luis", age: 21, city: "Orlando" } )

// Serialize nested structures
yaml = yamlSerialize({
    name    : "Luis",
    age     : 21,
    address : { street: "1234 Main St", city: "Orlando", state: "FL" },
    tags    : [ "admin", "developer" ]
})

// Serialize to a file
yamlSerialize( appConfig, "/app/config/settings.yml" )

// Deserialize YAML string back to BoxLang value
data = yamlDeserialize( yaml )
println( data.name )      // Luis
println( data.address.city ) // Orlando

// Deserialize from a file
config = yamlDeserializeFile( "/app/config/settings.yml" )
```

## Config File Pattern

```javascript
// Read environment config
env = server.system.environment.APP_ENV ?: "development"
config = yamlDeserializeFile( "/app/config/#env#.yml" )

// Access nested config values
dbHost = config.database.host
dbPort = config.database.port
```

## Serializing BoxLang Classes

By default, a class with `serializable = true` (or no annotation) is serialized using its properties:

```javascript
class serializable=true {
    property name="username" type="string"
    property name="email"    type="string"
    property name="password" type="string" yamlExclude=true  // excluded from YAML
}

user = new User().setUsername( "alice" ).setEmail( "alice@example.com" )
yaml = yamlSerialize( user )
// username and email are included; password is excluded
```

### Custom `toYAML()` Method

```javascript
class {
    function init( name, age, city ) {
        variables.name = name
        variables.age  = age
        variables.city = city
    }

    // Only expose name and city (not age)
    function toYAML() {
        return { name: variables.name, city: variables.city }
    }
}

person = new Person( "Luis", 21, "Orlando" )
yaml = yamlSerialize( person )
// Calls toYAML() — only name and city appear in output
```

## Property-Level Exclusion Options

- `yamlExclude=true` on a property — exclude this property from YAML serialization
- `serializable=false` on the class — prevents the whole class from being serialized
- `yamlExclude` list on the class — list of property names to exclude

## Common Pitfalls

- ✅ Use `yamlDeserializeFile()` for reading config files rather than `fileRead()` + `yamlDeserialize()`
- ❌ YAML is whitespace-sensitive — don't manually construct YAML strings; always use `yamlSerialize()`
- ✅ Use the `yamlExclude` annotation to prevent sensitive fields (passwords, tokens) from being serialized
