---
name: bx-orm-observability
description: "Use this skill when monitoring or debugging bx-orm 2.x activity in BoxLang: the onORMQuery, onORMFlush and onORMException interception points, slow SQL and bound parameters, config-load, post_new and criteria interception points, Hibernate statistics via ORMService.getStatistics, orm.log SQL and startup metrics, ormDiagnostics(), ormGetSessionStatistics() and orm.* error types."
---

# bx-orm: Observability

> BoxLang is the AI-native software productivity platform for building, modernizing and running applications, with developers and AI agents working together.

bx-orm announces events for SQL, flushes and failures through BoxLang's
interceptor service. Use them to build debuggers, monitors and slow query logs
without reaching into Hibernate.

There is no cost when nothing listens: JDBC objects are only wrapped when a
listener exists as a connection is acquired, and payloads are built lazily.

## Events

| Event | Fires | Payload |
| --- | --- | --- |
| `onORMQuery` | After each JDBC statement. Selects fire when the result set closes, once the row count is known | `sql`, `kind`, `elapsedNanos`, `rows`, `datasource`, `appName`, `hql`, `entityName`, `error`, `params` |
| `onORMFlush` | After each session flush | `inserts`, `updates`, `deletes`, `elapsedNanos`, `datasource`, `appName` |
| `onORMException` | When a statement fails | `error`, `sql`, `datasource`, `appName` |

### `onORMQuery` payload

| Key | Description |
| --- | --- |
| `sql` | SQL text sent to the driver |
| `kind` | `select`, `insert`, `update`, `delete`, `ddl` or `other` |
| `elapsedNanos` | Execution time in nanoseconds (excludes reading rows) |
| `rows` | Rows returned (select), rows affected (DML), `-1` when unknown (DDL) |
| `datasource` | Datasource name |
| `appName` | Unique ORM application name |
| `hql` | HQL behind the statement when it came from `ormExecuteQuery()`, else `null` |
| `entityName` | Entity being loaded when it came from `entityLoad()` or `entityLoadByPK()`, else `null` |
| `error` | The `Throwable` if the statement failed, else `null` |
| `params` | Ordered array of bound values. **Only present when `announceQueryParams=true`** |

A failed statement fires `onORMQuery` with `error` set and `onORMException`.
That includes SQL rejected when the statement is prepared. Startup DDL (for
example `dbcreate="dropcreate"`) is announced too when the listener registers
before the application starts.

`onORMFlush` counts are statements run during the flush, not entities, so JDBC
batching can make them differ from the number of entities changed.

### Other interception points

| Point | When | Payload |
| --- | --- | --- |
| `ORMPreConfigLoad` | Before bx-orm reads an application's `ormSettings` | `properties`, `context` |
| `ORMPostConfigLoad` | After bx-orm reads an application's `ormSettings` | `properties`, `context` |
| `post_new` | When `entityNew()` creates an entity | `entityName`, `entity`, `context` |
| `beforeCriteriaBuilderList` / `afterCriteriaBuilderList` | Around criteria `list()` (2.x only) | `criteriaBuilder`, `results` (after) |
| `beforeCriteriaBuilderCount` / `afterCriteriaBuilderCount` | Around criteria `count()` (2.x only) | `criteriaBuilder`, `count` (after) |
| `beforeCriteriaBuilderGet` / `afterCriteriaBuilderGet` | Around criteria `get()` (2.x only) | `criteriaBuilder`, `result` (after) |
| `onCriteriaBuilderAddition` | When a condition is added to a criteria (2.x only) | `criteriaBuilder`, `type` |

`properties` is the application's `ormSettings` struct. Entity lifecycle events
(`preInsert`, `postCommit`, ...) are not interception points: they go to entity
methods and the global `eventHandler`, and only when `eventHandling=true` (1.x
fired them regardless). `post_new` itself is announced on every `entityNew()`.

## Listening

```javascript
// OrmWatcher.bx
class {

    function onORMQuery( data ) {
        // 100 ms
        if ( data.elapsedNanos > 100000000 ) {
            writeLog( text="Slow ORM #data.kind#: #data.sql#", type="warning" );
        }
    }

    function onORMException( data ) {
        writeLog( text="ORM failure on #data.datasource#: #data.error.getMessage()#", type="error" );
    }

}
```

Register it with `boxRegisterInterceptor()`, naming the events it listens to:

```javascript
boxRegisterInterceptor(
    interceptor : new OrmWatcher(),
    points      : [ "onORMQuery", "onORMException" ]
);
```

## Settings

Set in `this.ormSettings`. All default to `false`.

| Setting | Description |
| --- | --- |
| `announceQueryParams` | Include bound parameter values in `onORMQuery`. Values can be sensitive, so enable only where you need them |
| `generateStatistics` | Collect Hibernate statistics at startup for `ORMService.getStatistics()`. Collection has a small cost |
| `logSQL` | Log every generated SQL statement to `orm.log` |

## Statistics

`ORMService` is a global service, reached through the runtime (Java interop).
Its methods take the ORM app name as a BoxLang `Key`:

```javascript
import java:ortus.boxlang.runtime.BoxRuntime;
import java:ortus.boxlang.runtime.scopes.Key;

ormService = BoxRuntime::getInstance().getGlobalService( "ORMService" );
appKey     = Key::of( appName ); // the appName from an event payload

stats = ormService.getStatistics( appKey );
// { appName, datasources : { myDS : { enabled, queryExecutionCount, ... } } }

// switch collection on or off at runtime, counters start from zero when enabled
ormService.setStatisticsEnabled( appKey, true );
```

When statistics are not collected, each datasource entry is only
`{ enabled : false }`. Enabled entries include `sessionOpenCount`, `flushCount`,
`prepareStatementCount`, `transactionCount`, `queryExecutionCount`,
`queryExecutionMaxTime`, `queryExecutionMaxTimeQueryString`, entity and
collection load/fetch/insert/update/delete counts, and second-level and query
cache hit/miss/put counts.

## Logs

- bx-orm, Hibernate and (with `logSQL : true`) SQL output all go to `orm.log`
  in the BoxLang runtime `logs/` directory.
- At DEBUG level, startup timings are logged per step:

```text
ORM startup metric - entity file discovery: 42ms (187 candidate files found)
ORM startup metric - entity metadata parsing: 310ms (23 persistent entities found, sequential mode)
ORM startup metric - XML mapping generation: 88ms (23 mapping files generated)
ORM startup metric - Hibernate SessionFactory build time [myDatasource]: 1243ms
```

## Diagnostics and Errors (2.x only)

```javascript
diag = ormDiagnostics(); // never throws
if ( diag.status != "running" ) {
    writeDump( diag.startupError ?: diag );
}

stats = ormGetSessionStatistics(); // this request's session, default datasource
// { entityCount, collectionCount, entityKeys : [ "User#5" ], collectionKeys : [ "User.orders#5" ] }
```

- `ormDiagnostics()` returns `status` (`running`, `failed`, `notStarted`,
  `notEnabled`), `applicationName`, `hibernateVersion`, `startupError`
  (`{ at, type, message, detail }`), `datasources` (entity names), `entityCount`,
  `warnings`, key `settings` and this request's open `sessions` (with `dirty`).
- A failed `ormReload()` keeps the previous ORM running; `startupError` says why.
- Every ORM error has a `type` starting with `orm` (`orm.query.syntax`,
  `orm.constraint.unique`, `orm.stale`, `orm.lazy.noSession`, ...). Catch by
  prefix (`catch ( "orm.constraint" e )`) and read context from
  `e.extendedInfo` (entity, property, `hql`, `params`, `sql`). In 1.x you catch
  raw Hibernate exception classes instead.

## Common Pitfalls

- ❌ Do NOT turn on `announceQueryParams` in production without considering sensitive data in the values
- ❌ Do NOT assume flush counts are entity counts, they are statement counts
- ❌ Do NOT register the listener after startup if you need startup DDL, it will already have run
- ❌ Do NOT expect entity lifecycle events (`preInsert`, `postLoad`, ...) as interception points; use `eventHandling` and an event handler
- ✅ Keep listeners cheap: they run synchronously on the thread executing the statement
- ✅ Use `kind` and `elapsedNanos` for slow query logs, `hql` and `entityName` to find the caller
- ✅ Call `ormDiagnostics()` first when the ORM misbehaves; it never throws
