# bx-orm Skills

Skills for BoxLang ORM (bx-orm) — a Hibernate-backed Object-Relational Mapping module for BoxLang applications.

## Available Skills

| Skill Folder | Trigger | Description |
|---|---|---|
| `bx-orm-configuration/` | ORM setup, `ormSettings`, Application.bx ORM config | Configure ORM in `Application.bx`: datasource, `dbcreate`, dialect, caching, event handling, entity locations |
| `bx-orm-entities/` | persistent entity, `@Entity`, property annotations, identifiers | Define persistent entity classes with `persistent=true`, property types, identity generators, composite keys, version fields |
| `bx-orm-relationships/` | one-to-many, many-to-one, many-to-many, one-to-one, fieldtype | Map relationships between entities: all four relationship types, cascade options, lazy/eager loading, join columns |
| `bx-orm-querying/` | EntityLoad, EntityLoadByPK, ORMExecuteQuery, HQL, pagination | Query and load entities: `entityLoad()`, `entityLoadByPK()`, HQL with parameters, pagination, caching, session BIFs |
| `bx-orm-transactions/` | transaction block, ORMFlush, transactionRollback, entitySave | Manage transactions: `transaction{}` blocks, savepoints, `ORMFlush()`, error handling, multi-datasource, session lifecycle |

## When to Combine Skills

- **New entity with relationships** → `bx-orm-entities` + `bx-orm-relationships`
- **Data access layer** → `bx-orm-querying` + `bx-orm-transactions`
- **Initial setup** → `bx-orm-configuration` first, then `bx-orm-entities`
- **Full CRUD service** → All five skills

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
