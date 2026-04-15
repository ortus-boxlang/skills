---
name: bx-orm-querying
description: "Use this skill when querying ORM entities: EntityLoad(), EntityLoadByPK(), EntityLoadByExample(), ORMExecuteQuery(), HQL queries, filtering, sorting, pagination, caching query results, and entity lifecycle BIFs (EntitySave, EntityDelete, EntityNew, EntityMerge)."
---

# bx-orm: Querying & Entity BIFs

## Entity Lifecycle BIFs

```javascript
// Create a new in-memory entity
user = entityNew( "User" )
user.setUsername( "alice" )
user.setEmail( "alice@example.com" )

// Persist to the database (within a transaction)
transaction {
    entitySave( user )
}

// Load by primary key
user = entityLoadByPK( "User", 42 )

// Delete
transaction {
    entityDelete( user )
}

// Reload from DB (discards in-memory changes)
entityReload( user )

// Merge a detached entity back into the current session
mergedUser = entityMerge( detachedUser )

// Convert entity to Query object
qry = entityToQuery( usersArray )
```

## `EntityLoad()` — Load by Criteria

```javascript
// Load ALL entities of a type
allUsers = entityLoad( "User" )

// Load by single filter criterion
activeUsers = entityLoad( "User", { status: "active" } )

// Load with sort order
sorted = entityLoad( "User", {}, "lastName ASC, firstName ASC" )

// Load unique (single result)
alice = entityLoad( "User", { email: "alice@example.com" }, true )

// Load with pagination options
page1 = entityLoad(
    "User",
    { status: "active" },
    "createdAt DESC",
    { maxResults: 20, offset: 0 }
)

// Load with caching
cached = entityLoad( "User", { status: "vip" }, false, {
    cacheable: true,
    cacheName: "vipUsers",
    timeout  : 300       // seconds
})
```

### `EntityLoad()` Options Struct

| Option | Type | Description |
|--------|------|-------------|
| `maxResults` | number | Limit results (pagination) |
| `offset` | number | Skip N results (pagination) |
| `cacheable` | boolean | Cache results in secondary cache |
| `cacheName` | string | Cache region name |
| `timeout` | number | Query timeout in seconds |
| `ignoreCase` | boolean | Case-insensitive sort |

## `EntityLoadByPK()` — Load by Primary Key

```javascript
// Load by simple PK
user = entityLoadByPK( "User", 42 )

// Load by composite PK
orderItem = entityLoadByPK( "OrderItem", { orderId: 1, productId: 5 } )

// Handle not-found
user = entityLoadByPK( "User", 999 )
if ( isNull( user ) ) {
    throw( type: "NotFound", message: "User 999 not found" )
}
```

## `EntityLoadByExample()` — Load by Example Entity

```javascript
// Create an example entity with the properties you want to match
example = entityNew( "User" )
example.setStatus( "active" )
example.setRole( "admin" )

// Load entities matching the example
admins = entityLoadByExample( example )
```

## `ORMExecuteQuery()` — HQL Queries

HQL (Hibernate Query Language) uses entity/property names, not table/column names:

```javascript
// Basic HQL
results = ormExecuteQuery( "FROM User" )

// WHERE clause
results = ormExecuteQuery( "FROM User WHERE status = 'active'" )

// Named parameters (preferred over string interpolation)
results = ormExecuteQuery(
    "FROM User WHERE status = :status AND role = :role",
    { status: "active", role: "admin" }
)

// Positional parameters
results = ormExecuteQuery(
    "FROM User WHERE status = ? AND role = ?",
    [ "active", "admin" ]
)

// Unique result
user = ormExecuteQuery(
    "FROM User WHERE email = :email",
    { email: "alice@example.com" },
    true  // unique=true
)

// Pagination
page = ormExecuteQuery(
    "FROM Post ORDER BY createdAt DESC",
    {},
    false,
    { maxResults: 10, offset: 20 }
)

// Aggregate queries
count = ormExecuteQuery( "SELECT COUNT(*) FROM User WHERE status = 'active'", true )

// JOIN queries
posts = ormExecuteQuery(
    "SELECT p FROM Post p JOIN p.author u WHERE u.status = :status ORDER BY p.createdAt DESC",
    { status: "active" }
)
```

## HQL Tips

```javascript
// Use entity names, not table names
// ✅ FROM User                (entity name)
// ❌ FROM users               (table name)

// Use property names, not column names
// ✅ WHERE u.createdAt > :date (property name)
// ❌ WHERE u.created_at > :date (column name)

// Fetching related data to avoid N+1
results = ormExecuteQuery(
    "SELECT DISTINCT u FROM User u LEFT JOIN FETCH u.posts WHERE u.status = 'active'"
)
```

## `EntityNameList()` / `EntityNameArray()`

```javascript
// Get all registered entity names
names = entityNameList()        // "User,Post,Comment,..."
arr   = entityNameArray()       // [ "User", "Post", "Comment", ... ]
```

## Session Management BIFs

```javascript
// Flush the ORM session (write pending changes to DB)
// Usually done automatically within transaction blocks
ORMFlush()
ORMFlushAll()            // flush all datasources

// Clear the session (detach all entities from session)
ORMClearSession()

// Close the current ORM session
ORMCloseSession()
ORMCloseAllSessions()

// Get the underlying Hibernate Session
session = ORMGetSession()

// Get the Hibernate SessionFactory
factory = ORMGetSessionFactory()
```

## Eviction BIFs (Cache Clearing)

```javascript
// Evict a single entity from L2 cache
ORMEvictEntity( "User" )
ORMEvictEntity( "User", 42 )    // specific entity by ID

// Evict a collection (relationship cache)
ORMEvictCollection( "User", "posts" )
ORMEvictCollection( "User", "posts", 42 )  // for user ID 42

// Evict cached queries
ORMEvictQueries()
ORMEvictQueries( "myQueryCache" )  // specific cache region
```

## Common Query Patterns

```javascript
// Paginated list
function getUsers( page=1, pageSize=20, status="" ) {
    var criteria = {}
    if ( len( status ) ) criteria.status = status

    return entityLoad( "User", criteria, "createdAt DESC", {
        maxResults: pageSize,
        offset    : ( page - 1 ) * pageSize
    })
}

// Count all matching entities
function countActiveUsers() {
    return ormExecuteQuery(
        "SELECT COUNT(*) FROM User WHERE status = 'active'", true
    )
}

// Existence check
function userEmailExists( email ) {
    var count = ormExecuteQuery(
        "SELECT COUNT(*) FROM User WHERE email = :email",
        { email: email }, true
    )
    return count > 0
}
```

## Common Pitfalls

- ❌ Never use string concatenation in HQL — always use named/positional parameters (SQL injection)
- ❌ `entityLoad( "User", 42 )` does NOT load by PK — use `entityLoadByPK( "User", 42 )`
- ❌ Using table/column names in HQL — use entity/property names instead
- ✅ Always wrap `entitySave()` and `entityDelete()` in `transaction {}` blocks
- ✅ Use `LEFT JOIN FETCH` in HQL to avoid N+1 on collections
- ✅ Use named parameters (`:name`) over positional (`?`) for readability
