---
name: bx-orm-transactions
description: "Use this skill for bx-orm 2.x (Hibernate 7.4) transactions and session flushing in BoxLang: how ORM work rides the transaction{} connection, mixing entitySave() and queryExecute() in one commit/rollback, transactionCommit(), transactionRollback(), what a rollback does to the ORM session, savepoint limits, nested transactions and enableNestedTransactions, isolation levels, multi-datasource transactions, locking, postCommit, ORMFlush(), ORMClearSession(), ORM writes outside a transaction block, autoManageSession/flushAtRequestEnd, and how 1.x differed."
---

# bx-orm: Transactions & Session Management

> BoxLang is the AI-native software productivity platform for building, modernizing and running applications, with developers and AI agents working together.

## How Transactions Work in 2.x

- The ORM runs no Hibernate transaction of its own. Inside `transaction{}`,
  ORM SQL goes over the BoxLang transaction's JDBC connection.
- ORM writes and `queryExecute()` on the same datasource commit together and
  roll back together. BoxLang does the real commit or rollback.
- On commit (and at the end of the block) bx-orm flushes the ORM session, so
  pending `entitySave()`/`entityDelete()` work is written, then committed.
- On rollback bx-orm clears the ORM session: pending writes are dropped and
  every loaded entity is detached.
- ORM queries inside a transaction (`entityLoad()` with a filter, HQL,
  criteria) flush first, so they see the transaction's own writes.

## Basic `transaction {}` Block

```javascript
// Clean exit: flush + commit. Uncaught exception: rollback.
transaction {
    var user = entityNew( "User", { username : "alice" } )
    entitySave( user )

    var profile = entityNew( "Profile", { bio : "Developer" } )
    profile.setUser( user )
    entitySave( profile )
    // both rows commit together when the block ends
}
```

## Mixing ORM and `queryExecute()`

```javascript
transaction {
    var order = entityLoadByPK( "Order", orderId )
    order.setStatus( "shipped" )

    // Native SQL does NOT flush the ORM session: flush first if the
    // SQL must see the pending ORM change.
    ormFlush()
    queryExecute(
        "UPDATE inventory SET reserved = reserved - 1 WHERE sku = :sku",
        { sku : order.getSku() }
    )
    // Any exception from here on rolls back BOTH statements
}
```

- Read-your-writes covers ORM queries only. Call `ormFlush()` (or
  `entitySave( e, { flush : true } )`) before native SQL that must read or
  update rows the ORM has not written yet.
- Inside the transaction, `queryExecute()` sees flushed ORM rows even though
  they are not committed yet: both use the same connection.

## Rollback and the ORM Session

```javascript
try {
    transaction {
        var user = entityNew( "User", { username : "bob" } )
        entitySave( user )
        queryExecute( "INSERT INTO audit ( msg ) VALUES ( 'new user' )" )
        throw( type : "Signup.Failed", message : "boom" )
    }
} catch ( "Signup.Failed" e ) {
    // user row and audit row are both rolled back
}

// Manual rollback for a business rule
transaction {
    var account = entityLoadByPK( "Account", 1 )
    if ( account.getBalance() < amount ) {
        transactionRollback()
    } else {
        account.setBalance( account.getBalance() - amount )
    }
}
```

- A rollback clears the session for every ORM datasource, not just the
  transaction's one.
- Objects you still hold are detached and keep their in-memory values, even
  a generated id for a row that no longer exists. Reload them with
  `entityLoadByPK()` instead of saving them again.
- Use `postCommit( entity, action )` for side effects (emails, cache
  clears). It fires after the commit and never for rolled-back writes.

## `transactionCommit()` and `transactionRollback()`

```javascript
transaction {
    entitySave( batch1 )
    transactionCommit()     // flush + real commit; a new unit begins

    entitySave( batch2 )
    transactionRollback()   // undoes batch2 only; batch1 stays committed
}
```

- `transactionCommit()` takes no arguments. It commits everything so far,
  including nested blocks.
- `transactionRollback()` undoes work since the last commit (or the start).
  `transactionRollback( "name" )` rolls back to a BoxLang savepoint (below).
- Both are also available as `transaction action="commit"` and
  `action="rollback"`.

## Outside a `transaction {}` Block

With the default `autoManageSession : false`, sessions use Hibernate's
`MANUAL` flush mode:

- `entitySave()` and entity changes are queued, not written, until you call
  `ormFlush()`, pass `{ flush : true }`, or a later `transaction{}` in the
  same request commits (that flush includes the queued work).
- Exception: a new entity with a database-generated id (`identity`, or
  `native` on MySQL, MariaDB, SQL Server) is inserted during `entitySave()`
  so `getId()` works right away.
- Each statement runs on a pooled autocommit connection, so whatever is
  written outside a transaction is committed at once and cannot be rolled
  back.
- At request end the sessions are closed without a flush, so queued work is
  lost, unless `flushAtRequestEnd` and `autoManageSession` are both `true`.

```javascript
// Application.bx: keep both false and use transaction{} for writes
this.ormSettings = {
    autoManageSession : false, // default: MANUAL flush mode
    flushAtRequestEnd : false  // only applies with autoManageSession true
}

// Works, but each flush commits on its own: prefer transaction{}
entitySave( entityNew( "Log", { msg : "hello" } ), { flush : true } )
```

## Flushing and Generated IDs

```javascript
ormFlush()                 // default datasource session
ormFlush( "auditDB" )      // one datasource's session
ormFlushAll()              // every open session in this request
entitySave( [ a, b ], { flush : true } )
entityDelete( order, { flush : true } )
```

- You do not need `ormFlush()` to relate a new parent and child: save the
  parent first (or cascade) and the flush writes them in order. Identity
  ids are set by `entitySave()` itself.
- `ormClearSession()` detaches everything without flushing, and
  `ormCloseSession()` closes without flushing: pending changes are lost.
- `entityReload( entity )` re-reads the row, discarding in-memory changes.

## Nested Transactions

```javascript
transaction {
    entitySave( customer )
    transaction {          // joins the outer transaction by default
        entitySave( invoice )
        transactionCommit() // commits customer AND invoice
    }
}
```

- Nesting is BoxLang's decision. With the default
  `enableNestedTransactions = false` (runtime setting), a nested block is
  part of the outer transaction: a nested commit commits the outer work, a
  nested rollback or exception rolls back everything, and the nested
  block's own `datasource` and `isolation` attributes are not applied.
- With the experimental `enableNestedTransactions = true`, BoxLang scopes a
  child commit or rollback with savepoints, and bx-orm flushes the session
  when the child block ends. bx-orm follows whatever BoxLang commits.

## Savepoints

- bx-orm 2.x has no partial rollback of ORM work. The docs treat savepoints
  as BoxLang's, available with `enableNestedTransactions` on.
- Any `transactionRollback()`, including one to a savepoint, clears the
  whole ORM session, so unflushed ORM work from before the savepoint is
  dropped as well.
- For partial undo, split the work into separate `transaction{}` blocks or
  use native SQL with `transactionSetSavepoint()`.

## Multiple Datasources

```javascript
// Each block is its own transaction: no two-phase commit
transaction datasource="primaryDB" {
    entitySave( user )
}
transaction datasource="auditDB" {
    entitySave( auditLog )
}
```

- A transaction binds to its `datasource` attribute, or to the first
  datasource that asks it for a connection.
- ORM sessions on other datasources are flushed on commit and cleared on
  rollback, but their SQL runs on separate autocommit connections and is
  not rolled back.

## Isolation Levels and Locking

```javascript
transaction isolation="serializable" {
    var account = entityLoadByPK( "Account", 1, { lock : "write" } )
    account.setBalance( account.getBalance() - 100 )
}
```

- `isolation` accepts `read_uncommitted`, `read_committed`,
  `repeatable_read` or `serializable`. It is set on the shared connection,
  so it applies to ORM work on that datasource. Omit it to use the database
  default.
- Pessimistic locks (`entityLock()`, the `lock` option of
  `entityLoadByPK()` and `ormExecuteQuery()`, criteria `lock()`) need a
  transaction; outside one they raise `orm.argument`. Locks are released on
  commit or rollback.
- For report-style reads, `ormReadOnly( closure )` or `entityLoadReadOnly()`
  skips dirty checking.

## Differences from 1.x

- 1.x ran its own Hibernate transaction on a separate connection for every
  ORM datasource, so ORM writes could commit or roll back independently of
  `queryExecute()` in the same `transaction{}`.
- Read-your-writes (ORM queries flushing first inside a transaction) is new
  in 2.x. Check code that relied on ORM writes committing separately.
- Current BoxLang's `transactionCommit()` takes no transaction name, so the
  1.x docs example `transactionCommit( "inner" )` does not scope a commit.

## Common Pitfalls

- ❌ Calling `queryExecute()` against rows the ORM changed without
  `ormFlush()` first: native SQL does not trigger a flush
- ❌ Re-saving entities from a rolled-back transaction: they are detached and
  may carry stale ids. Reload them
- ❌ Expecting work outside `transaction{}` to be saved at request end: with
  default settings queued changes are discarded
- ❌ Relying on savepoints to keep part of the ORM work: any rollback clears
  the whole session
- ❌ Expecting a nested `transactionCommit()` to commit only the inner block:
  by default it commits the outer work too
- ❌ Expecting one `transaction{}` to roll back writes on two datasources
- ❌ `ormClearSession()` or `ormCloseSession()` with pending changes: they are
  discarded, not flushed
- ✅ Wrap every write path (including service methods) in `transaction{}`
  and let exceptions roll it back; no closing `transactionCommit()` needed
- ✅ Use `postCommit()` for side effects that must only follow a real commit
- ✅ Take locks only inside `transaction{}`
