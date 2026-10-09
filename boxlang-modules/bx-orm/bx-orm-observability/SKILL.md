---
name: bx-orm-observability
description: "Use this skill when monitoring or debugging bx-orm activity in BoxLang: listening to ORM queries, flushes and exceptions with the onORMQuery, onORMFlush and onORMException interception points, capturing slow SQL, bound parameters, and reading Hibernate statistics with ORMService.getStatistics."
---

# bx-orm: Observability

> BoxLang is the AI-native software productivity platform for building, modernizing and running applications, with developers and AI agents working together.

bx-orm announces events for SQL, flushes and failures through BoxLang's interceptor service. Use them to build debuggers, monitors and slow query logs without reaching into Hibernate.

There is no cost when nothing listens: JDBC objects are only wrapped when a listener exists as a connection is acquired, and payloads are built lazily.

## Events

| Event | Fires | Payload |
|-------|-------|---------|
| `onORMQuery` | After each JDBC statement. Selects fire when the result set closes, once the row count is known | `sql`, `kind`, `elapsedNanos`, `rows`, `datasource`, `appName`, `hql`, `entityName`, `error`, `params` |
| `onORMFlush` | After each session flush | `inserts`, `updates`, `deletes`, `elapsedNanos`, `datasource`, `appName` |
| `onORMException` | When a statement fails | `error`, `sql`, `datasource`, `appName` |

### `onORMQuery` payload

| Key | Description |
|-----|-------------|
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

A failed statement fires `onORMQuery` with `error` set and `onORMException`. That includes SQL rejected when the statement is prepared. Startup DDL (for example `dbcreate="dropcreate"`) is announced too when the listener registers before the application starts.

`onORMFlush` counts are statements run during the flush, not entities, so JDBC batching can make them differ from the number of entities changed.

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

Set in `this.ormSettings`. Both default to `false`.

| Setting | Description |
|---------|-------------|
| `announceQueryParams` | Include bound parameter values in `onORMQuery`. Values can be sensitive, so enable only where you need them |
| `generateStatistics` | Collect Hibernate statistics at startup for `ORMService.getStatistics()` |

## Statistics

`ORMService` is a global service, so it is reached through the runtime (Java interop):

```javascript
import java:ortus.boxlang.runtime.BoxRuntime;

ormService = BoxRuntime::getInstance().getGlobalService( "ORMService" );

stats = ormService.getStatistics( appName );
// { appName, datasources : { myDS : { enabled, queryExecutionCount, ... } } }

// switch collection on or off at runtime, counters start from zero when enabled
ormService.setStatisticsEnabled( appName, true );
```

When statistics are not collected, each datasource entry is only `{ enabled : false }`.

## Common Pitfalls

- ❌ Do NOT turn on `announceQueryParams` in production without considering sensitive data in the values
- ❌ Do NOT assume flush counts are entity counts, they are statement counts
- ❌ Do NOT register the listener after startup if you need startup DDL, it will already have run
- ✅ Keep listeners cheap: they run synchronously on the thread executing the statement
- ✅ Use `kind` and `elapsedNanos` for slow query logs, `hql` and `entityName` to find the caller
