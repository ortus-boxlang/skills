---
name: bx-ini
description: "Use this skill when reading or writing INI configuration files in BoxLang with the bx-ini module: getIniFile(), getProfileString(), setProfileString(), getProfileSections(), removeProfileSection(), and fluent IniFile object methods."
---

# bx-ini: INI File Handling

## Installation

```bash
install-bx-module bx-ini
# CommandBox
box install bx-ini
```

## BIFs

| BIF | Description |
|-----|-------------|
| `getIniFile( file )` | Open (or create) an INI file, returns an IniFile object |
| `getProfileString( iniFile, section, entry )` | Get a single entry value |
| `setProfileString( iniFile, section, entry, value )` | Set a single entry value |
| `getProfileSection( iniFile, section )` | Get an entire section as a struct |
| `getProfileSections( iniFile )` | Get all sections as a struct of structs |
| `removeProfileSection( iniFile, section )` | Remove an entire section |
| `removeProfileString( iniFile, section, entry )` | Remove a single entry |

## Reading an INI File

```ini
# /app/config/app.ini
[General]
appName=MyApplication
version=1.2.3
debug=false

[Database]
host=localhost
port=5432
dbname=myapp

[Logging]
logLevel=DEBUG
logFile=/var/log/myapp.log
```

```javascript
// Read individual values
appName = getProfileString( "/app/config/app.ini", "General", "appName" )
host    = getProfileString( "/app/config/app.ini", "Database", "host" )
port    = getProfileString( "/app/config/app.ini", "Database", "port" )

// If entry doesn't exist, returns empty string
missingValue = getProfileString( "/app/config/app.ini", "General", "nonExistent" )
// Returns ""

// Read entire section as a struct
dbConfig = getProfileSection( "/app/config/app.ini", "Database" )
// { host: "localhost", port: "5432", dbname: "myapp" }

// Read all sections
allConfig = getProfileSections( "/app/config/app.ini" )
// { General: {...}, Database: {...}, Logging: {...} }
```

## Writing an INI File

```javascript
// Write a single value (creates section + key if not present)
setProfileString( "/app/config/app.ini", "General", "debug", "true" )

// Create a new section and populate it
setProfileString( "/app/config/app.ini", "Cache", "enabled", "true" )
setProfileString( "/app/config/app.ini", "Cache", "ttl", "300" )
setProfileString( "/app/config/app.ini", "Cache", "provider", "redis" )
```

## Fluent IniFile Object API

```javascript
// Get the IniFile object for fluent chaining
var ini = getIniFile( "/app/config/settings.ini" )

// Create a section
ini.createSection( "MySettings" )

// Set entries
ini.setEntry( "MySettings", "timeout", "30" )
ini.setEntry( "MySettings", "retries", "3" )
ini.setEntry( "MySettings", "endpoint", "https://api.example.com" )

// Read entries
timeout = ini.getEntry( "MySettings", "timeout" )

// Remove a single entry
ini.removeEntry( "MySettings", "retries" )

// Remove an entire section
ini.removeSection( "OldSettings" )
```

## Config File Pattern

```javascript
// Load per-environment config
env    = server.system.environment.APP_ENV ?: "development"
config = getProfileSections( "/app/config/#env#.ini" )

// Access config
println( config.Database.host )
println( config.General.appName )
```

## Common Pitfalls

- ✅ All values returned from INI files are strings — convert to numeric/boolean as needed: `val( port )`
- ❌ INI files do not support nested sections — use YAML (`bx-yaml`) for hierarchical config
- ✅ `getIniFile()` creates the file if it doesn't exist — safe for first-time setup
- ✅ `getProfileString()` returns an empty string for missing entries — always check if empty when the value is required
