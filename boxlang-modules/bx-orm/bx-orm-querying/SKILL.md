---
name: bx-orm-querying
description: "Use this skill when querying ORM entities in BoxLang with bx-orm: entityLoad(), entityLoadByPK(), entityLoadByExample(), the OrFail/OrNew/OrSave and read-only loaders, ormExecuteQuery() and HQL parameters and options, HQL through bx:query dbtype=\"hql\" and queryExecute(), unique results, pagination, streaming, query caching and eviction, entityToQuery(), and entity lifecycle BIFs (entityNew, entitySave, entityDelete, entityMerge, entityReload)."
---

# bx-orm: Querying & Entity BIFs

> BoxLang is the AI-native software productivity platform for building, modernizing and running applications, with developers and AI agents working together.

Written for bx-orm 2.x (Hibernate 7.4). There are three ways to query:

- **Filter loads** (`entityLoad()` and friends) for equality lookups.
- **HQL** (`ormExecuteQuery()`, or `bx:query` / `queryExecute()` with
  `dbtype="hql"`) for anything else.
- **`entityCriteria()`**, the fluent builder: see the `bx-orm-criteria` skill.

## Entity Lifecycle BIFs

```javascript
user = entityNew( "User", { username : "alice", email : "a@example.com" } )

transaction {
    entitySave( user )                       // written when the tx commits
    entitySave( [ order, invoice ], { flush : true } ) // arrays, flush now
    entityDelete( oldUser )                  // also takes an array
}

user       = entityReload( user )            // re-read from the database
mergedUser = entityMerge( detachedUser )     // use the returned instance
qry        = entityToQuery( usersArray, "User" )
```

`entityNew()` only sets keys that are declared properties; other keys are
skipped without an error.

## `entityLoad()`: by ID or Filter

`entityLoad( entityName, [idOrFilter], [uniqueOrOrder], [options] )`

```javascript
allUsers = entityLoad( "User" )                       // every row
active   = entityLoad( "User", { status : "active" } ) // AND of equalities
sorted   = entityLoad( "User", {}, "lastName asc, firstName" )
alice    = entityLoad( "User", { email : "a@example.com" }, true ) // or null
user     = entityLoad( "User", 42, true )             // by id: entity or null
asArray  = entityLoad( "User", 42 )                   // by id: [] or [ user ]

page = entityLoad( "User", { status : "active" }, "createdDate desc", {
    maxResults : 20,
    offset     : 40
} )
```

- The third argument is `true`/`false` (unique) or a sort string. A struct
  there is treated as the options.
- A filter only does `AND` equality. A to-one association can be matched with
  an id or an entity: `{ manufacturer : 42 }`.
- Nothing found: a unique load returns `null`, any other load returns `[]`.
- `unique` is strict: several matches raise `orm.query.nonUnique`.

### `entityLoad()` Options

| Option | Description |
| --- | --- |
| `unique` | Return one entity (or `null`) |
| `uniqueFirst` | Return the first match even if several match |
| `maxResults` | Limit the rows returned |
| `offset` | Skip this many rows |
| `ignoreCase` | Sort text properties without regard to case |
| `cacheable` | Use the second-level query cache |
| `cacheName` | Query cache region (implies `cacheable`) |
| `timeout` | Query timeout in seconds |
| `readOnly` | Entities are not dirty-checked, changes never saved |
| `asStream` | Return a Java `Stream` (not with `unique`) |

For a load by id only `readOnly` and `asStream` apply. Without a sort, the
entity's `defaultSort` annotation is used.

## Other Loaders

```javascript
user  = entityLoadByPK( "User", 42 )             // entity or null
line  = entityLoadByPK( "OrderItem", { orderId : 1, productId : 5 } )
users = entityLoadByPK( "User", [ 3, 1, 99 ] )   // [ user3, user1, null ]
rpt   = entityLoadByPK( "Report", id, { readOnly : true } )

order = entityLoadOrFail( "Order", url.id )      // orm.notFound if missing
user  = entityLoadOrFail( "User", { email : form.email } )
order = entityLoadByPKOrFail( "Order", url.id )

user = entityLoadOrNew( "User", { email : e }, { status : "invited" } )
transaction {
    tag = entityLoadOrSave( "Tag", { slug : "boxlang" }, { name : "BoxLang" } )
}

orders = entityLoadReadOnly( "Order", { status : "shipped" }, "createdDate" )
rows   = entityLoadAsStruct( "User", { active : true }, "role.name" )
```

- `entityLoadByPK()` returns one entity (or `null`) for one id, and an array
  in id order for an array of ids. Its third argument is an options struct
  (`lock`, `timeout`, `skipLocked`, `readOnly`); a boolean there is ignored.
- `entityLoadOrNew()` does not save; `entityLoadOrSave()` does. Put a unique
  constraint on the filter columns, since two requests can both insert.
- `entityLoadByExample( sample, [unique] )` matches every non-null plain
  property of a sample entity. Ids, version and associations are ignored, and
  `unique=true` returns the first match (no non-unique error):
  `entityLoadByExample( entityNew( "User", { role : "admin" } ) )`.

## `ormExecuteQuery()`: HQL

`ormExecuteQuery( hql, [params], [unique], [options] )`

HQL uses entity and property names, not table and column names. Names are
case-insensitive in 2.x (`from user where firstname = ?` works).

```javascript
// Named parameters (struct)
users = ormExecuteQuery(
    "from User where status = :status and role = :role",
    { status : "active", role : "admin" }
)

// Positional parameters (array)
users = ormExecuteQuery( "from User where status = ? and role = ?",
    [ "active", "admin" ] )

// Arrays expand for IN; entities bind as their id
cars = ormExecuteQuery( "from Auto where make in (:makes)",
    { makes : [ "Toyota", "Honda" ] } )
posts = ormExecuteQuery( "from Post p where p.author = :author",
    { author : userEntity } )

// Unique: one object or null; several rows raise orm.query.nonUnique
user = ormExecuteQuery( "from User where email = :e", { e : email }, true )

// Shorter forms: a boolean as 2nd arg means unique, a struct as 3rd = options
total = ormExecuteQuery( "select count(*) from User", true )
page  = ormExecuteQuery( "from Post order by createdDate desc", [],
    { maxResults : 10, offset : 20 } )

// UPDATE / DELETE return the affected row count (no events, no L2 cache)
rows = ormExecuteQuery( "update Auto set discontinued = true where make = :m",
    { m : "Yugo" } )
```

- Do not mix `:name` and `?` in one query. A JPA-style `?1` is accepted, but
  values are always bound in the order the placeholders appear.
- Each `:name` needs a value (`orm.query.parameter` otherwise). Unused keys in
  the struct are logged as a warning.
- A projection (`select u.id, u.name ...`) returns one array of values per row.

### `ormExecuteQuery()` Options

| Option | Description |
| --- | --- |
| `unique` / `uniqueFirst` | One result; `uniqueFirst` takes the first row |
| `maxResults` / `offset` | Paging |
| `readOnly` | Results are not dirty-checked |
| `datasource` | Run against another ORM datasource |
| `cacheable` / `cacheName` | Query cache (`cacheName` alias `cacheRegion`) |
| `timeout` | Query timeout in seconds |
| `fetchSize` | JDBC fetch size |
| `comment` | SQL comment (needs `hibernate.use_sql_comments`) |
| `hints` | Struct of Hibernate query hints |
| `lock` | `read`, `write` or `force`; needs `transaction{}` |
| `lockTimeout` / `skipLocked` | Lock wait in seconds; skip locked rows |
| `asStream` | Return a Java `Stream` (not with `unique` or DML) |

### Streaming

```javascript
names = ormExecuteQuery( "from Auto where make = :m", { m : "Toyota" },
        false, { asStream : true } )
    .filter( ( a ) => a.getYear() > 2020 )
    .map( ( a ) => a.getModel() )
    .toList()
```

A stream holds a database cursor: consume it in the same request.

Functions registered in `ormSettings.sqlFunctions` are callable by name in
HQL (`where nameLen( u.lastName ) > 10`); `ormGetSQLFunctions()` lists them.

## HQL in `bx:query` and `queryExecute()`

With `dbtype="hql"`, the query component (`<cfquery>` in CFML templates) and
`queryExecute()` run HQL exactly like `ormExecuteQuery()` and return the same
thing: an array of entities, or of rows for a projection. **Not a query
object.** Without `dbtype="hql"` they run SQL as usual.

```html
<bx:query name="toyotas" dbtype="hql">
    FROM Auto WHERE make = <bx:queryparam value="#form.make#" sqltype="varchar">
</bx:query>

<bx:set opts = { offset : 25, readOnly : true }>
<bx:query name="cars" dbtype="hql" maxrows="25" ormoptions="#opts#"
    result="info">
    FROM Auto
    WHERE id IN ( <bx:queryparam value="#url.ids#" sqltype="integer"
        list="true"> )
</bx:query>
```

```javascript
cars = queryExecute(
    "FROM Auto WHERE make = :make ORDER BY model",
    { make : "Toyota" },
    {
        dbtype     : "hql",
        maxrows    : 25,
        timeout    : 10,
        ormoptions : { offset : 25, readOnly : true },
        result     : "info"
    }
)
// info = { sql : "<the HQL>", recordCount, executionTime, cached }
```

- `<bx:queryparam>` (`<cfqueryparam>`) binds a positional parameter. With a
  `sqltype` (`cfsqltype`) the value is cast first, so a string id from a form
  matches an integer property. `list="true"` binds a list for `IN ( ... )`.
- `params` takes named (struct) or positional (array) parameters, as in
  `ormExecuteQuery()`. A `{ value, sqltype }` struct is cast the same way.
  Do not combine body queryparams with the `params` attribute.
- `ormoptions` takes the `ormExecuteQuery()` options (`maxResults`, `offset`,
  `readOnly`, `unique`, `cacheable`, ...). `maxrows`, `timeout` and
  `datasource` apply too; `ormoptions` wins on conflicts.
- Available in bx-orm 2.x and from bx-orm 1.7.3 on 1.x.

## HQL Tips

```javascript
// Entity and property names, never tables and columns
ormExecuteQuery( "from User u where u.createdDate > :d", { d : since } )

// Fetch a collection with the parents to avoid N+1
users = ormExecuteQuery(
    "select distinct u from User u left join fetch u.posts where u.active = true"
)
```

Hibernate 7 parses HQL strictly: a bad query raises `orm.query.syntax` with the
line, column and token, and an unknown name gets a "Did you mean" suggestion.

## Results as Queries and Structs

```javascript
qry  = entityToQuery( entityLoad( "Vehicle", { make : "Ford" } ), "Vehicle" )
rows = entityLoadAsStruct( "User", { active : true }, "role.name" )
data = entityToStruct( user, { includes : "roles.name" } )
```

`entityToQuery()` holds plain properties only (id, columns, version), never
relationship columns. For related values use a criteria projection with
`asQuery()`, or `entityToStruct()` / `entityLoadAsStruct()` with `includes`.

## Query Cache and Eviction

```javascript
// needs secondaryCacheEnabled in ormSettings
active = ormExecuteQuery( "from User where active = true", [], false,
    { cacheName : "activeUsers" } )   // cacheName alone turns caching on
users  = entityLoad( "User", { active : true }, "name", { cacheable : true } )

ormEvictEntity( "User" )                  // L2 data for every User
ormEvictEntity( "User", 42 )              // one id
ormEvictCollection( "User", "posts" )     // a collection, all owners
ormEvictCollection( "User", "posts", 42 )
ormEvictQueries()                         // default query region only
ormEvictQueries( "activeUsers" )          // a named region
ormEvictQueries( "queries", "admin" )     // region on another datasource

entityEvict( user )                       // detach from the SESSION, not L2
```

## Session and Name BIFs

```javascript
ormFlush()                  // or ormFlush( "datasourceName" ); ormFlushAll()
ormClearSession()           // detach everything, unsaved changes dropped
ormCloseSession()           // ormCloseAllSessions() for every datasource
ormIsSessionDirty()         // would a flush write anything?
session = ormGetSession()   // Hibernate 7 Session (ormGetSessionFactory())
total   = ormReadOnly( () => entityLoad( "Order" ).len() ) // read-only loads
names   = entityNameList()  // "Comment,Post,User"; entityNameArray() too
```

See `bx-orm-transactions` for flushing and `transaction{}` behavior.

## Static Entity Methods

Entity classes get static shortcuts to the same BIFs (on by default,
`staticMethods : false` turns them off):

```javascript
user  = User::get( 1 )                         // entityLoadByPK
user  = User::findWhere( { email : email } )   // unique filter load
page  = User::list( { max : 20, offset : 40, sort : "lastName" } )
rows  = User::executeQuery( "from User where role = :r", { r : "admin" } )
c     = User::criteria()                       // entityCriteria( "User" )
```

## bx-orm 1.x Differences

- 1.x `unique` silently returned the first row; `uniqueFirst` does not exist.
- Not in 1.x: `entityCriteria()`, static entity methods, the `OrFail`,
  `OrNew`, `OrSave` and `ReadOnly` loaders, `entityLoadAsStruct()`,
  `entityEvict()`, `entityLock()`, `ormReadOnly()`, `asStream`, `lock`
  options, arrays of ids and options in `entityLoadByPK()`, `sqlFunctions`.
- 1.x `ormExecuteQuery()` ignored `cacheable`, `cacheName` and `timeout`, and
  `entityLoad()` needed `cacheable : true` alongside `cacheName`.
- HQL through `bx:query` / `queryExecute()` with `dbtype="hql"` needs 1.7.3+.

## Common Pitfalls

- ❌ Concatenating values into HQL: always bind `:name` or `?` parameters
- ❌ `entityLoad( "User", 42 )` returns an **array**: pass `true` as the third
  argument or use `entityLoadByPK( "User", 42 )`
- ❌ `unique` on a query that can match several rows: it raises
  `orm.query.nonUnique` in 2.x. Narrow it or pass `uniqueFirst : true`
- ❌ Treating a `dbtype="hql"` result as a query (`.recordCount`, query
  loops): it is an array; use `len()` or the `result` struct
- ❌ `?2 ... ?1` to reorder positional values: numbers are ignored, order wins
- ❌ Table or column names in HQL: use entity and property names
- ❌ Expecting HQL `update`/`delete` to fire events or refresh loaded
  entities: reload them or `ormClearSession()`
- ❌ Confusing `entityEvict()` (session) with `ormEvictEntity()` (L2 cache)
- ✅ Wrap writes in `transaction {}`: with the default `autoManageSession :
  false` nothing is written until a flush or commit
- ✅ Use `left join fetch` (or criteria `fetch()`) to avoid N+1 queries
- ✅ Consume `asStream` results inside the same request
- ✅ Reach for `entityCriteria()` (`bx-orm-criteria`) for dynamic filters
