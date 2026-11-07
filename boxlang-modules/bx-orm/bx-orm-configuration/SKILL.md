---
name: bx-orm-configuration
description: "Use this skill when configuring bx-orm 2.x (Hibernate 7.4) in BoxLang: Application.bx ormSettings, enabling the ORM, datasources, dbcreate options, Hibernate 7 dialects, entity paths, naming strategies, raw Hibernate properties, named SQL functions, event handling, session settings, the BoxCache-backed second-level cache, the .bxorm boot cache (ormManifest auto/trust) and the boxlang module:orm CLI (generate, info, validate, entities, clear)."
---

# bx-orm: Configuration

> BoxLang is the AI-native software productivity platform for building, modernizing and running applications, with developers and AI agents working together.

This skill targets bx-orm 2.x, which runs on Hibernate ORM 7.4 and needs
BoxLang 1.18.0+, Java 21+ and a JDBC driver module (for example `bx-mysql`).
Install with `box install bx-orm@2`; pin `bx-orm@1` to stay on 1.x. All
configuration lives in `this.ormSettings`: the module itself has no settings to
set in `boxlang.json`.

## Enabling ORM in `Application.bx`

```javascript
class {

    this.name       = "myApp"
    this.datasource = "myApp"  // default datasource for ORM

    this.ormEnabled  = true
    this.ormSettings = {
        // always set: without it the whole application root is scanned
        entityPaths       : [ "models/entities" ],

        // schema management
        dbcreate          : "update",      // none | update | dropcreate

        // debugging
        logSQL            : false,
        savemapping       : false,         // write User.orm.xml (debug only)
        ignoreParseErrors : false,

        // session management (these are the defaults)
        autoManageSession : false,         // demarcate writes with transaction{}
        flushAtRequestEnd : false,

        // events: must be true for ANY ORM event to fire
        eventHandling     : true,
        eventHandler      : "models.ORMEventHandler",

        // boot cache: "auto" in dev/CI, "trust" in production
        ormManifest       : getSystemSetting( "ORM_MANIFEST", "auto" )
    }

}
```

## `dbcreate` Options

| Value | Behavior |
| --- | --- |
| `none` (default) | Does not modify the database schema |
| `update` | Incrementally adds missing tables/columns; never drops |
| `dropcreate` | Drops and recreates the schema on every ORM start or reload |
| `validate`, `create`, `create-drop`, `create-only`, `drop`, `truncate` | Hibernate `hbm2ddl.auto` values, passed through (2.x only) |

Use `update` in development and `none` (or `validate`) in production with DB
migrations.

## Key Settings Reference

| Setting | Default | Description |
| --- | --- | --- |
| `entityPaths` | *empty* (app root) | Directory or array of directories to scan for persistent classes. **Always set this.** |
| `datasource` | `this.datasource` | Datasource used by the ORM |
| `dbcreate` | `none` | Schema strategy (see above) |
| `dialect` | auto-discover | Short name or fully qualified Java class (see Dialects) |
| `schema` / `catalog` | | Default database schema / catalog |
| `logSQL` | `false` | Log generated SQL to `orm.log` |
| `autoManageSession` | `false` | `false` opens sessions in manual flush mode: nothing is written until `ormFlush()` or a `transaction{}` commits |
| `flushAtRequestEnd` | `false` | Auto-flush at request end. Keep `false`; use `transaction{}` |
| `eventHandling` | `false` | Must be `true` for entity event methods, the global `eventHandler` and `postNew` |
| `eventHandler` | | Path to the global ORM event handler class |
| `namingstrategy` | `default` | `default` (names as is), `smart` (camelCase to `MACRO_CASE`) or a custom class path |
| `secondaryCacheEnabled` | `false` | Enable the second-level cache |
| `cacheProvider` | `BoxCacheProvider` | BoxLang cache provider for the regions bx-orm creates |
| `cacheConfig` | | Struct of BoxCache properties, or path to a JSON file or `ehcache.xml` |
| `generateMappings` | `true` | `false` reads committed `.orm.xml` files (keep `savemapping : true`). `autoGenMap` is a deprecated alias |
| `savemapping` | `false` | Write each generated mapping beside its entity (`User.bx` gives `User.orm.xml`) |
| `ormManifest` | `off` | Boot cache mode: `off`, `auto` or `trust` (2.x only) |
| `ormManifestLocation` | *empty* (app root) | Parent folder for `.bxorm/`; relative paths resolve against the app root (2.x only) |
| `staticMethods` | `true` | Add `User::get( 1 )`, `User::findWhere()` and friends to entities (2.x only) |
| `sqlFunctions` | `{}` | Named SQL templates callable from HQL and `entityCriteria()` (2.x only) |
| `hibernateProperties` | `{}` | Flat struct of raw Hibernate properties, applied last |
| `ormconfig` | | Path to a flat `hibernate.properties` file, applied before `hibernateProperties` |
| `defaultBatchSize` | `16` | Batch size for lazy collections and proxies |
| `enableThreadedMapping` | `true` | Parallel startup work when there are more than 20 entities |
| `quoteIdentifiers` | `false` | Quote generated table and column names |
| `sqlScript` | | SQL file run right after `dbcreate` creates the tables (`dropcreate`, `create`, `create-drop`) |
| `useDBForMapping` | `false` | Fill untyped property types and missing ids from existing tables at startup (no effect in 1.x) |
| `announceQueryParams` | `false` | Include bound values in `onORMQuery` (see `bx-orm-observability`) |
| `generateStatistics` | `false` | Collect Hibernate statistics (see `bx-orm-observability`) |
| `proxyLazyLoading` | `false` | Accepted but ignored in 2.x: every lazy to-one is a proxy |

All 1.x setting names are still read by 2.x.

## Dialects

Leave `dialect` unset: Hibernate 7 inspects the datasource and detects the
database version itself (SQLite included). To force one, use the plain database
name or a fully qualified class:

```javascript
this.ormSettings = {
    dialect : "MySQL"   // or MariaDB, PostgreSQL, SQLServer, Oracle, H2, Derby
    // dialect : "org.hibernate.dialect.PostgreSQLDialect"
}
```

Hibernate 7 removed the version-specific dialects. Legacy names such as
`MySQL57InnoDB`, `PostgreSQL9`, `SQLServer2008` or `Oracle10g`, and Hibernate 5
classes such as `org.hibernate.dialect.MySQL5InnoDBDialect`, still work but map
to the current dialect with a one-time deprecation warning. Derby, SQLite,
Firebird, Informix and similar come from the bundled community dialects (SQLite
still needs its JDBC driver on the classpath). FrontBase, McKoi, Pointbase,
Progress, JDataStore and Interbase are no longer supported.

## Raw Hibernate Settings and SQL Functions

```javascript
this.ormSettings = {
    // escape hatch for any Hibernate property; wins over ormconfig
    hibernateProperties : {
        "hibernate.jdbc.batch_size"         : 25,
        "hibernate.default_batch_fetch_size": 25
    },
    // callable from HQL and criteria paths: nameLen( u.lastName )
    sqlFunctions : {
        nameLen : { sql : "char_length(?1)", returns : "integer" },
        shout   : "upper(?1)"
    }
}
```

An invalid `sqlFunctions` entry stops startup with an `orm.config` error.
`ormGetSQLFunctions()` lists what is registered.

## Second-Level Cache

In 2.x every cache region is a BoxLang BoxCache cache; no cache library to
install. Turn it on, then mark entities with `cacheUse` and `cacheName`:

```javascript
this.ormSettings = {
    secondaryCacheEnabled : true,
    cacheConfig           : {
        maxObjects : 1000,                                       // every region
        regions    : { "countries" : { defaultTimeout : 0 } }    // per region
    }
}
```

```javascript
class persistent="true" table="countries" cacheUse="read-only" cacheName="countries" {
    property name="code" fieldtype="id" generator="assigned";
    property name="name";
}
```

- A BoxLang cache already defined with a region's name (for example in
  `boxlang.json`) is used as is.
- `cacheProvider` can name any registered BoxLang provider (for example a Redis
  module's); `ConcurrentHashMap`, `HashTable` and `ehcache` are aliases for
  `BoxCacheProvider`.
- An existing `ehcache.xml` path in `cacheConfig` is read and mapped to BoxCache
  properties; disk stores, listeners and clustering are ignored.
- `cacheUse="transactional"` is rejected at startup; use `read-write`.
- In 1.x, `cacheConfig` was an EHCache XML path and `cacheConfigProperties` a
  struct alternative; 2.x has no `cacheConfigProperties`, use a `cacheConfig`
  struct.

## Boot Cache (`.bxorm/`) (2.x only)

`ormManifest` stores the resolved entity metadata, mappings
(`manifest-{app}.json`) and generated facade classes (`facades-{app}.jar`) in a
`.bxorm/` folder. `{app}` is `this.name` slugified (`My Shop` gives `my-shop`),
so several applications can share one folder.

| Mode | At startup | Use for |
| --- | --- | --- |
| `off` (default) | Discover, parse and map every entity on every boot | Classic behavior |
| `auto` | Boot normally, then write `.bxorm/`; watches entity paths and reloads the ORM on the next request after an edit | Development, CI |
| `trust` | Boot straight from `.bxorm/`: no discovery, parsing or code generation | Production |

A `trust` boot fails closed, naming what changed, when the cache is missing or
its checksum fails, belongs to another app, the bx-orm version changed, an
entity source changed, or a key setting changed (dialect, datasource, naming
strategy, app name, `dbcreate`, `quoteIdentifiers`, `entityPaths`). It never
discovers new entity files: rebuild the cache and deploy `.bxorm/` with the app.
Hibernate's `SessionFactory` build still runs in every mode.

## `boxlang module:orm` CLI (2.x only)

```bash
# build the cache with no server, database or onApplicationStart()
boxlang --bx-config runtime/boxlang.json module:orm generate

boxlang module:orm info                    # cache header per app (default verb)
boxlang module:orm validate                # exit 1 if missing, corrupt or edited
boxlang module:orm entities --app=shop     # entities, class and datasource
boxlang module:orm entity User             # one entity and its mapping XML
boxlang module:orm mappings                # every mapping XML
boxlang module:orm clear --app=shop        # or: clear --all
boxlang module:orm version
```

- `--dir=<path>` sets the app root (default: current directory). If the app
  sets `ormManifestLocation`, `generate` follows it, but the other verbs need
  `--dir` pointing at that folder.
- `--app=<name>` (name or slug) is needed when `.bxorm/` holds several apps.
- Every verb exits `0` or `1`, so it can gate a CI step. The module also
  declares a `bxorm` executable (`bxorm <verb>`).
- `generate` runs only the `Application.bx` pseudo-constructor (web scopes
  empty). Pass the server's `boxlang.json` so its mappings and datasources load.
- Separate tool: `java -cp "boxlang.jar:bx-orm-<version>.jar"
  ortus.boxlang.modules.orm.cli.GenerateMappings --path models` writes
  `.orm.xml` files for `generateMappings : false` setups (1.x writes `.hbm.xml`,
  which 2.x does not read).

## Multiple Datasources

`ormSettings.datasource` (or `this.datasource`) is the default; an entity can
override it with `class persistent="true" datasource="reporting" { ... }`. Each
datasource gets its own Hibernate `SessionFactory`.

## ORM Reload (Development)

`ormReload()` rebuilds the ORM after entity or mapping changes. If the reload
fails, the app keeps running on the previous ORM and
`ormDiagnostics().startupError` shows why. With `ormManifest : "auto"`, edited entities reload on their own.

## 1.x Differences

- 1.x runs Hibernate 5.6: version-specific dialects are real classes there.
- 1.x fires ORM events even with `eventHandling : false`; 2.x honors it.
- 1.x `savemapping` writes `.hbm.xml`; 2.x writes `.orm.xml`.
- 1.x documents only `none`, `update` and `dropcreate` for `dbcreate`, never ran
  `sqlScript`, and ignores `useDBForMapping`.
- No boot cache, `module:orm` CLI, `staticMethods` or `sqlFunctions` in 1.x.

## Common Pitfalls

- ❌ Do NOT omit `entityPaths`: the whole application root is scanned at startup
- ❌ Do NOT use version-specific dialect names in new code; leave `dialect` unset or use the plain database name
- ❌ Do NOT forget `eventHandling : true` when you rely on entity or global events in 2.x
- ❌ Do NOT add entities under `ormManifest : "trust"` without rebuilding `.bxorm/` (`module:orm generate`)
- ❌ Do NOT keep old `.hbm.xml` files with `generateMappings : false` after upgrading; regenerate `.orm.xml`
- ❌ Do NOT turn on `flushAtRequestEnd` or `autoManageSession` in production: writes become unpredictable
- ✅ Demarcate writes with `transaction {}` blocks
- ✅ Run `boxlang module:orm validate` in CI before shipping a `trust` image
- ✅ Call `ormDiagnostics()` after an upgrade or config change to confirm a clean start
- ✅ Set `logSQL : true` or `savemapping : true` temporarily when debugging queries or mappings
