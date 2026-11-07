# bx-orm Skills

Skills for BoxLang ORM (bx-orm), a Hibernate-backed Object-Relational Mapping module for BoxLang applications. They target bx-orm 2.x (Hibernate 7.4) and note where 1.x (Hibernate 5) differs.

## Available Skills

| Skill Folder | Trigger | Description |
|---|---|---|
| `bx-orm-configuration/` | ORM setup, `ormSettings`, Application.bx ORM config | Configure ORM in `Application.bx`: datasource, `dbcreate`, dialect, caching, event handling, entity locations |
| `bx-orm-entities/` | persistent entity, `@Entity`, property annotations, identifiers | Define persistent entity classes with `persistent=true`, property types, identity generators, composite keys, version fields |
| `bx-orm-relationships/` | one-to-many, many-to-one, many-to-many, one-to-one, fieldtype | Map relationships between entities: all four relationship types, cascade options, lazy/eager loading, join columns |
| `bx-orm-querying/` | EntityLoad, EntityLoadByPK, ORMExecuteQuery, HQL, `dbtype="hql"`, pagination | Query and load entities: `entityLoad()`, `entityLoadByPK()`, HQL with parameters, HQL in `bx:query` / `queryExecute()`, pagination, caching, session BIFs |
| `bx-orm-criteria/` | entityCriteria, criteria builder, projections, subqueries | Build queries fluently with `entityCriteria()`: conditions, joins, projections, subqueries, paging, terminal methods |
| `bx-orm-observability/` | onORMQuery, onORMFlush, slow SQL, ORM statistics, announceQueryParams | Listen to ORM queries, flushes and failures via interceptors, capture bound params, read Hibernate statistics |
| `bx-orm-transactions/` | transaction block, ORMFlush, transactionRollback, entitySave | Manage transactions: `transaction{}` blocks, savepoints, `ORMFlush()`, error handling, multi-datasource, session lifecycle |

## When to Combine Skills

- **New entity with relationships** → `bx-orm-entities` + `bx-orm-relationships`
- **Data access layer** → `bx-orm-querying` + `bx-orm-criteria` + `bx-orm-transactions`
- **Dynamic search or filter screens** → `bx-orm-criteria`
- **Initial setup** → `bx-orm-configuration` first, then `bx-orm-entities`
- **Slow query logging or ORM monitoring** → `bx-orm-observability` + `bx-orm-configuration`
- **Full CRUD service** → All the skills above

## Key ORM BIFs Quick Reference

```javascript
// Entity lifecycle
entity  = entityNew( "EntityName" )
entity  = entityLoadByPK( "EntityName", id )
results = entityLoad( "EntityName", criteria, sortOrder, options )
entity  = entityLoadByExample( exampleEntity )
         entitySave( entity )
         entityDelete( entity )
         entityReload( entity )
entity  = entityMerge( detachedEntity )
qry     = entityToQuery( entityArray )

// HQL queries
results = ormExecuteQuery( "FROM Entity WHERE prop = :val", { val: "x" } )
count   = ormExecuteQuery( "SELECT COUNT(*) FROM Entity", true )

// HQL through queryExecute() or bx:query: returns the same array as ormExecuteQuery()
results = queryExecute( "FROM Entity WHERE prop = :val", { val: "x" }, { dbtype: "hql" } )

// Criteria builder
results = entityCriteria( "Entity" ).isEq( "prop", "x" ).list()

// Session & flush
ORMFlush()
ORMFlushAll()
ORMClearSession()
ORMCloseSession()
ORMReload()
session = ORMGetSession()

// Cache eviction
ORMEvictEntity( "EntityName" )
ORMEvictCollection( "EntityName", "collectionProperty" )
ORMEvictQueries()

// Transactions
transaction {
    transactionCommit()
    transactionRollback()
    transactionSetSavePoint( "savepointName" )
    transactionRollback( "savepointName" )
}
```
