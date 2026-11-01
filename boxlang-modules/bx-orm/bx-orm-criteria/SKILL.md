---
name: bx-orm-criteria
description: "Use this skill when building fluent ORM queries in BoxLang with bx-orm 2.x entityCriteria(): conditions (isEq, like, between, isIn, isNull, not* forms), anyOf/allOf groups, c.restrictions, joins and aliases (joinTo/createAlias, withClause, with{Association}), fetch, subqueries, projections, asStruct/asQuery/asStream results, resultTransformer, ordering, paging, terminals (list, get, count, paginate, each, chunk), bulk updateAll/deleteAll, row locking, and inspecting SQL with getSQL()."
---

# bx-orm: Criteria Queries

> BoxLang is the AI-native software productivity platform for building, modernizing and running applications, with developers and AI agents working together.

`entityCriteria( entityName )` builds a query one method at a time, then runs
it with a terminal method. There is no query string, property names are
checked as you add them, and values are always bound as parameters.

**bx-orm 2.x only.** It does not exist in bx-orm 1.x: use `entityLoad()` or
`ormExecuteQuery()` there (see `bx-orm-querying`). It uses cborm's method
names, so cborm criteria code reads the same.

```javascript
users = entityCriteria( "User" )
    .isEq( "active", true )
    .like( "lastName", "Sm%" )
    .order( "lastName" )
    .list()

c = User::criteria()      // same thing, from the static entity method
```

## How It Works

- **Building methods** add to the criteria and return it, so they chain.
- **Terminal methods** run the query and return the result. One criteria can
  run several queries. `copy()` (alias `clone()`) branches it.
- Method names are case-insensitive and take positional or named arguments:
  `isEq( property = "make", value = "Ford" )`.
- A misspelled property fails at once with `orm.property.unknown`:
  `Vehicle has no property [mkae]. Did you mean [make]?`
- Values are converted to the property's type: `isEq( "id", "42" )` works.

## Conditions

All conditions are combined with `and`.

| Method (aliases) | Meaning |
| --- | --- |
| `isEq( p, v )` (`eq`) | `p = v`; a `null` value means `is null` |
| `ne( p, v )` (`isNe`) | `p <> v`; `null` means `is not null` |
| `isGt`, `isGe`, `isLt`, `isLe` | Also `gt`, `ge`/`gte`, `lt`, `le`/`lte` |
| `like( p, pattern )` | You supply the `%` wildcards |
| `ilike( p, pattern )` | Case-insensitive `like` |
| `between( p, min, max )` | Inclusive range |
| `isIn( p, values )` (`in`) | Array, list or subquery; empty matches none |
| `isNotIn( p, values )` | The opposite |
| `isNull( p )`, `isNotNull( p )` | Null checks |
| `isTrue( p )`, `isFalse( p )` | Boolean properties |
| `isEmpty( p )`, `isNotEmpty( p )` | To-many collections |
| `sizeEq( p, n )` ... `sizeLe` | Collection size |
| `eqProperty( p, other )` ... | Also `ne`, `gt`, `ge`, `lt`, `leProperty` |
| `idEq( id )` | Id; a struct for a composite id |
| `sql( fragment, params )` | Native SQL condition, see below |

### `where()` Shorthands, Groups and Negation

```javascript
c.where( "make", "Honda" )                    // isEq
c.where( "price", ">=", 20000 )               // = != > >= < <= like ilike in
c.where( { make : "Honda", year : 2024 } )    // several isEq; array = isIn

// make = Honda OR make = Toyota
c.anyOf( ( c ) => c.isEq( "make", "Honda" ).isEq( "make", "Toyota" ) )

// (make = Honda AND model like R%) OR year < 2000
c.anyOf( ( c ) => c
    .allOf( ( a ) => a.isEq( "make", "Honda" ).like( "model", "R%" ) )
    .isLt( "year", 2000 )
)

// several closures are alternatives; each one's conditions must all match
c.anyOf(
    ( c ) => c.isEq( "make", "Honda" ).isEq( "model", "Civic" ),
    ( c ) => c.isEq( "make", "Ford" )
)

c.notLike( "make", "Hon%" )                   // any condition + "not" prefix
c.notIn( "status", [ "banned", "deleted" ] )  // notBetween, notEq, ...
c.not( ( c ) => c.isEq( "make", "Honda" ).isEq( "model", "Civic" ) )
```

Aliases: `or`, `$or`, `orWhere`, `disjunction` for `anyOf`; `and`, `$and`,
`conjunction` for `allOf`.

### `c.restrictions` (cborm Style)

`c.restrictions` builds a condition without adding it. Pass the results to
`add()`, `or()`, `and()` or `not()`; they mix with closures.

```javascript
c = entityCriteria( "User" )
r = c.restrictions
c.or( r.isEq( "role", "admin" ), r.isGt( "age", 30 ) )
c.add( r.like( "name", "A%" ), r.isNotNull( "email" ) )
c.not( r.isEq( "status", "banned" ) )
```

### Native SQL and Functions in Paths

```javascript
// ? params are bound in order; {alias}.column and {property} are expanded
c.sql( "upper({alias}.first_name) = ?", [ "LUIS" ] )
c.sql( "lower({make}) = ? or {model} = ?", [ "ford", "Civic" ] )

// any property argument can be a function call (incl. sqlFunctions)
c.isEq( "year(createdDate)", 2025 ).order( "lower(customer.name)" )
```

Function arguments must be paths, nested calls, numbers or quoted strings
(`'none'`); pass other values as the condition value.

## Joins and Aliases

A dotted path joins automatically: `isEq( "manufacturer.name", "Ford" )`.

- Conditions use an **inner** join; inside `anyOf()` and `not()`, and for
  ordering and projections, a **left** join. A path is joined once and reused.
- `manufacturer.id` compares the foreign key with no join. An association can
  be compared with an id or an entity: `isEq( "manufacturer", 42 )`.
- The root alias is `this` (`this.name`).

```javascript
entityCriteria( "Vehicle" )
    .joinTo( "manufacturer", "m" )       // alias: createAlias
    .isEq( "m.name", "Honda Motor Co." )

c.leftJoin( "manufacturer", "m" )        // innerJoin, rightJoin, fullJoin
c.joinTo( "manufacturer", "m", "left" )  // inner/left/right/full, c.LEFT_JOIN

// withClause (closure or c.restrictions.*): conditions go in the join's ON,
// so a left join keeps rows without a match
c.joinTo( "manufacturer", "m", "left", ( j ) => j.isTrue( "m.active" ) )

// with{Association}(): unqualified paths start at the association
entityCriteria( "Vehicle" )
    .withManufacturer( ( m ) => m.like( "name", "Honda%" ) )
    .isEq( "model", "Civic" )

entityCriteria( "Vehicle" )
    .withManufacturer( "left" )   // cborm: createCriteria( "manufacturer" )
        .like( "name", "Honda%" )
    .end()
    .isEq( "model", "Civic" )

// load the association with the rows (no N+1)
vehicles = entityCriteria( "Vehicle" ).fetch( "manufacturer" ).list()
```

Through a to-many condition each root is returned once, and `count()` counts
each root once.

## Subqueries

`subquery( entityName, alias )` (alias `createSubcriteria`,
`detachedCriteria`): unqualified paths start at the subquery's entity, and
`this` is the outer root.

```javascript
c = entityCriteria( "Manufacturer" )

// manufacturers that make a Honda / that have no vehicles
c.exists( c.subquery( "Vehicle", "v" )
    .eqProperty( "v.manufacturer", "this" ).isEq( "make", "Honda" ) )
c.notExists( c.subquery( "Vehicle", "v" )
    .eqProperty( "v.manufacturer", "this" ) )

// isIn with the subquery's projection
c.isIn( "id", c.subquery( "Vehicle", "v" ).isEq( "make", "Ford" )
    .project( ( p ) => p.property( "manufacturer.id" ) ) )

counted = c.subquery( "Vehicle", "v" )
    .eqProperty( "v.manufacturer", "this" )
    .project( ( p ) => p.rowCount() )
c.subLe( 2, counted )                    // at least 2 vehicles
```

The cborm forms compare a property (`propertyEq`, `propertyGt`,
`propertyIn`, `propertyNotIn`, ...) or a value (`subEq`, `subLe`, `subIn`,
...) with a subquery. Quantified forms compare with every or some row:
`propertyGeAll( "price", prices )`, `subLtSome( 10, prices )`.

## Projections and Result Shapes

```javascript
totals = entityCriteria( "Order" )
    .project( ( p ) => p.group( "status" ).count( "id", "orders" )
        .sum( "total", "revenue" ) )
    .order( "revenue desc" )             // a projection alias works too
    .asStruct()
    .list()                // [ { status, orders, revenue }, ... ]

// cborm form: values are "property[:alias]" lists
c.withProjections( groupProperty = "make", count = "vin:total" )
```

Projection methods: `property`, `group` (`groupProperty`), `sum`, `avg`,
`min`, `max`, `count`, `countDistinct`, `rowCount( [alias] )`, `id( [alias] )`.
One projection gives plain values; several give an array per row, or a
struct per row with `asStruct()`.

| Method | `list()` returns |
| --- | --- |
| (default) | Entities |
| `asStruct()` | Structs: projections, or id and plain properties |
| `asStruct( includes, [opts] )` | `entityToStruct()`-style structs |
| `asQuery()` | A query object |
| `asStream()` | A Java stream |
| `asDistinct()` | Distinct rows |
| `resultTransformer( c.X )` | cborm constants, see below |

- `asStruct()` dates are ISO 8601 strings, not date objects.
- `asStruct( "id,name,role.name,orders" )` reads with projection queries,
  without loading entities. Not allowed with `each()` or `chunk()`.
- `resultTransformer()` accepts `c.DISTINCT_ROOT_ENTITY` (drop repeated
  roots), `c.ROOT_ENTITY` (entities), `c.ALIAS_TO_ENTITY_MAP` (structs) and
  `c.PROJECTION`, for cborm code. A to-many condition already returns each
  root once, so it is rarely needed.

## Ordering, Paging and Options

```javascript
c.order( "lastName" )                    // asc by default (alias orderBy)
c.order( "lastName", "desc" )
c.order( "lastName", "asc", true )       // ignore case
c.orderBy( "make desc, model asc" )
c.orderByDesc( "createdDate" )
c.firstResult( 20 ).maxResults( 10 )     // aliases offset/skip, limit/take
```

Without `order()`, entity results use the entity's `defaultSort`.

| Option | Effect |
| --- | --- |
| `cache( [region] )` | Query cache (alias `cacheable`); `cache( false )` off |
| `readOnly()` | Loaded entities are never saved |
| `timeout( seconds )` | Query timeout |
| `fetchSize( n )` | JDBC fetch size |
| `comment( text )` | SQL comment |
| `queryHint( name, value )` | Hibernate query hint |
| `lock( [mode], [opts] )` | Row lock, see below |

## Terminal Methods

| Method | Returns |
| --- | --- |
| `list()` | Rows; cborm args `list( max, offset, timeout, sortOrder, ... )` |
| `count( [property] )` | Matching roots, or distinct values of a property |
| `exists()` | Whether any row matches |
| `get( [uniqueFirst] )` | One row or null; several: `orm.query.nonUnique` |
| `getOrFail()` | Like `get()`; none is `orm.notFound` |
| `first()` / `firstOrFail()` | First row in order, or null / error |
| `paginate( page, maxRows )` | `{ results, pagination }` |
| `simplePaginate( page, maxRows )` | `{ results, pagination : { hasMore } }` |
| `pluck( property )` | One property's values |
| `sum`, `avg`, `min`, `max( p )` | An aggregate |
| `each( fn, [size] )` | Calls `fn` per row; returns the count |
| `chunk( size, fn )` | Calls `fn` per batch; returns the count |
| `updateAll( values )` / `deleteAll()` | One bulk statement; row count |

```javascript
page = entityCriteria( "Order" )
    .isGe( "createdDate", dateAdd( "d", -30, now() ) )
    .orderByDesc( "createdDate" )
    .paginate( page = 2, maxRows = 25 )
// pagination : { page, maxRows, offset, totalRecords, totalPages }

entityCriteria( "User" ).isFalse( "verified" ).chunk( 500, ( users ) => {
    users.each( ( u ) => u.setReminderSent( true ) )
} )
```

`each()` and `chunk()` read in batches (100 by default for `each()`), and
flush and clear the session after each batch, so changes are saved and
memory stays flat.

### Bulk Updates, Deletes and Locks

```javascript
count = entityCriteria( "Order" )
    .isEq( "status", "pending" )
    .isLt( "createdDate", dateAdd( "d", -30, now() ) )
    .updateAll( { status : "expired", note : null } )

count = entityCriteria( "Session" ).isLt( "expires", now() ).deleteAll()

transaction {
    jobs = entityCriteria( "Job" ).isEq( "status", "new" )
        .lock( "write", { skipLocked : true } )   // read, write, force
        .maxResults( 10 )
        .list()
}
```

Bulk statements fire no events, do not cascade, skip versions and
`autoTimestamp`, and leave loaded entities stale. `deleteAll()` on a
`softDelete` entity marks rows deleted.

## Flow Helpers

```javascript
entityCriteria( "User" )
    .when( len( search ), ( c ) => c.like( "lastName", search & "%" ) )
    .unless( showDeleted, ( c ) => c.isFalse( "isDeleted" ) )
    .apply( activeUsers )        // reusable: ( c ) => c.isTrue( "active" )
    .list()
```

`when()` and `unless()` take an optional third "otherwise" closure;
`peek( fn )` runs a closure and keeps chaining.

## Seeing the Query

- `getSQL( [executable], [format] )`: the SQL, without running it.
  `executable = true` inlines the values; paging is not included.
- `getHQL()`: the HQL it compiles to. `peekSQL( fn )` passes the SQL to a
  closure and keeps chaining.
- `writeDump( c )` / `toString()`: the calls, HQL, params and SQL.
- cborm SQL log: `startSqlLog()`, `logSQL( label )`, `getSqlLog()`,
  `stopSqlLog()`.

```javascript
writeOutput( entityCriteria( "User" ).isEq( "active", true ).getSQL( true ) )
```

## Common Pitfalls

- ❌ Calling `entityCriteria()` on bx-orm 1.x: it is 2.x only
- ❌ `count()` then `list()` on a projected criteria: `count()` clears the
  projections and `asStruct()`/`asQuery()` (cborm behavior). Count on a
  `copy()`, or set the shape after counting
- ❌ `like( "name", "Sm" )` without `%`: it is an exact match
- ❌ `get()` when several rows can match: `orm.query.nonUnique`; use
  `first()` or `get( true )`
- ❌ `lock()` outside `transaction {}`: `orm.argument`
- ❌ A `withClause` path that needs another join: `orm.argument`; use the new
  alias or earlier aliases, and put other conditions in the `where`
- ❌ `rightJoin` / `fullJoin` on MySQL or MariaDB (no full join support)
- ❌ `updateAll()` / `deleteAll()` with `maxResults()` or `firstResult()`
- ❌ Expecting `updateAll()`/`deleteAll()` to run events or cascades:
  `deleteAll()` can hit foreign keys, and loaded entities need
  `entityReload()` or `ormClearSession()`
- ❌ Holding entities across `each()`/`chunk()` batches: the session is
  cleared after every batch
- ❌ Running a `subquery()` on its own: pass it to `exists()`, `isIn()`, ...
- ❌ Reading `asStruct()` dates as date objects: they are ISO 8601 strings
- ✅ Paginate with an explicit `order()` so pages are stable
- ✅ Use `fetch()` for associations you read in a loop
- ✅ Use `getSQL()` or `writeDump()` to check what a criteria will run
