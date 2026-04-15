---
name: bx-orm-configuration
description: "Use this skill when configuring bx-orm in BoxLang: Application.bx ormSettings, enabling the ORM, datasource setup, dbcreate options, dialect selection, entity paths, event handling, session management settings, and secondary cache configuration."
---

# bx-orm: Configuration

## Enabling ORM in `Application.bx`

```javascript
class {

    this.datasource = "myApp"  // default datasource for ORM

    this.ORMenabled = true
    this.ormSettings = {
        // required — always specify to avoid startup performance hit
        entityPaths          : [ "models/entities" ],

        // database schema management
        dbcreate             : "update",      // none | update | dropcreate

        // performance & debugging
        logSQL               : false,
        savemapping          : false,         // save .hbmxml files (debug only)
        ignoreParseErrors    : false,

        // session management (recommended settings)
        autoManageSession    : false,         // manage sessions yourself via transaction{}
        flushAtRequestEnd    : false,         // don't auto-flush; use explicit transactions

        // event system
        eventHandling        : false,
        eventHandler         : "",            // path to global event handler class
    }

}
```

## `dbcreate` Options

| Value | Behavior |
|-------|----------|
| `none` (default) | Does not modify the database schema |
| `update` | Incrementally adds missing tables/columns; never drops |
| `dropcreate` | Drops and recreates the entire schema on every ORM reload |

**Recommendation**: Use `update` in development, `none` in production (use DB migrations instead).

## Key Settings Reference

| Setting | Default | Description |
|---------|---------|-------------|
| `entityPaths` | (app directory) | Directories to scan for persistent classes. **Always set this.** |
| `datasource` | `this.datasource` | Overrides the application datasource for ORM |
| `dbcreate` | `none` | Schema management strategy |
| `dialect` | auto | Hibernate SQL dialect (usually auto-detected) |
| `logSQL` | `false` | Log generated SQL to console (debug) |
| `flushAtRequestEnd` | `true` | Auto-flush at request end — set `false` in production |
| `autoManageSession` | `true` | Let engine manage sessions — set `false` for explicit transactions |
| `eventHandling` | `false` | Enable ORM lifecycle events |
| `eventHandler` | | Path to global ORM event handler class |
| `secondaryCacheEnabled` | `false` | Enable L2 cache (Ehcache) |
| `cacheConfig` | | Path to Ehcache XML config file |
| `namingstrategy` | `default` | Naming convention: `default`, `smart`, or custom class |
| `sqlScript` | | Path to SQL file executed after ORM init (seed data) |
| `savemapping` | `false` | Write Hibernate `.hbmxml` mapping files (debugging) |

## Production-Ready Configuration

```javascript
class {

    this.datasource = "myApp"

    this.ORMenabled = true
    this.ormSettings = {
        entityPaths          : [ "models" ],
        dbcreate             : "none",          // use DB migrations in production
        flushAtRequestEnd    : false,           // explicit transactions only
        autoManageSession    : false,           // manage sessions yourself
        eventHandling        : true,
        eventHandler         : "models.ORMEventHandler",
        secondaryCacheEnabled: true,
        cacheProvider        : "Ehcache",
        cacheConfig          : "./config/ehcache.xml",
        logSQL               : false,
        ignoreParseErrors    : false
    }

}
```

## Dialect Configuration

Let Hibernate auto-detect (works 95% of the time), or specify explicitly:

```javascript
this.ormSettings = {
    dialect: "MySQL57InnoDB"    // explicit dialect
    // dialect: "PostgreSQL9"
    // dialect: "SQLServer2008"
    // dialect: "Oracle10g"
    // dialect: "H2"
}
```

Common dialects: `MySQL5InnoDB`, `MySQL57InnoDB`, `MariaDB`, `PostgreSQL9`, `SQLServer2008`, `Oracle10g`, `H2`, `HSQL`.

## Multiple Datasources

```javascript
this.ormSettings = {
    entityPaths: [ "models/primary", "models/reporting" ],
    datasource : "primary"   // default; individual entities can override
}
```

Override per-entity:

```javascript
class persistent="true" datasource="reporting" {
    // ...
}
```

## ORM Reload (Development)

Force a full reload of ORM mappings (clears entity cache):

```javascript
ORMReload()
```

Useful after adding entities or changing mappings during development.

## Common Pitfalls

- ❌ Do NOT omit `entityPaths` — it will scan the entire application tree (very slow)
- ❌ Do NOT use `flushAtRequestEnd=true` in production — leads to unpredictable saves
- ❌ Do NOT use `autoManageSession=true` when using explicit `transaction{}` blocks
- ✅ Always use explicit `transaction {}` blocks to demarcate database writes
- ✅ Set `logSQL=true` temporarily to debug unexpected queries
- ✅ Use `savemapping=true` temporarily to inspect Hibernate XML mappings when debugging
