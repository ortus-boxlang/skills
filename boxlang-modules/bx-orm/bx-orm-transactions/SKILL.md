---
name: bx-orm-transactions
description: "Use this skill for ORM transactions and session management in BoxLang: transaction{} blocks, automatic flush/rollback, transactionCommit(), transactionRollback(), savepoints, ORMFlush(), ORMClearSession(), multi-entity saves, error handling within transactions."
---

# bx-orm: Transactions & Session Management

## Basic `transaction {}` Block

```javascript
// All entitySave/entityDelete calls within the block are committed atomically.
// On uncaught exception: automatic rollback
// On clean exit: automatic commit

transaction {
    var user = entityNew( "User" )
    user.setUsername( "alice" )
    user.setEmail( "alice@example.com" )
    entitySave( user )
}
```

## Error Handling with Try/Catch

```javascript
transaction {
    try {
        var order = entityLoadByPK( "Order", orderId )
        order.setStatus( "processed" )
        entitySave( order )

        var payment = entityNew( "Payment" )
        payment.setOrder( order )
        payment.setAmount( order.getTotal() )
        entitySave( payment )

        transactionCommit()
    } catch ( any e ) {
        transactionRollback()
        rethrow
    }
}
```

## `transactionCommit()` and `transactionRollback()`

```javascript
// Manual commit within a transaction block
transactionCommit()     // explicitly commit now (can use again later)

// Manual rollback (rolls back everything since last commit or start)
transactionRollback()

// Rollback to a named savepoint
transactionRollback( "mySavepoint" )
```

## Savepoints

```javascript
transaction {
    // Save base state
    entitySave( user )

    // Set a savepoint after first operation
    transactionSetSavePoint( "afterUserSave" )

    try {
        entitySave( profile )
        entitySave( settings )
        transactionCommit()
    } catch ( any e ) {
        // Partial rollback — only undo after the savepoint
        transactionRollback( "afterUserSave" )
        // user is still saved, profile/settings are not
        transactionCommit()
    }
}
```

## `ORMFlush()` — Explicit Flush

```javascript
// ORMFlush() writes pending session changes to the DB within the current
// transaction, without committing. Useful to force ordering or get generated IDs.

transaction {
    var parent = entityNew( "Category" )
    parent.setName( "Electronics" )
    entitySave( parent )

    // Flush to get the auto-generated ID of parent
    ORMFlush()

    var child = entityNew( "Product" )
    child.setName( "Laptop" )
    child.setCategory( parent )  // parent.getId() is now available
    entitySave( child )
}
```

## Session Management

```javascript
// Reload entity from DB (discards in-memory changes)
entityReload( entity )

// Clear the entire session (detach all entities)
ORMClearSession()

// Force close the session early (usually not needed)
ORMCloseSession()
ORMCloseAllSessions()    // close all datasource sessions
```

## Multi-Datasource Transactions

```javascript
// Specify datasource on the transaction block
transaction datasource="secondaryDB" {
    entitySave( archiveRecord )
}

// Each datasource is its own independent transaction
transaction datasource="primaryDB" {
    entitySave( user )
}

transaction datasource="auditDB" {
    entitySave( auditLog )
}
```

## Nested Transactions

```javascript
// BoxLang joins existing transactions by default (does NOT create a new transaction)
transaction {
    doMainWork()

    // This joins the outer transaction — NOT a separate transaction
    transaction {
        doSubWork()
    }

    // Commit covers both main and sub work
}
```

## Service Layer Pattern

```javascript
class UserService {

    function createUserWithProfile( userData, profileData ) {
        transaction {
            try {
                var user = entityNew( "User" )
                entityPopulate( user, userData )
                entitySave( user )

                // Flush so profile can reference the new user ID
                ORMFlush()

                var profile = entityNew( "Profile" )
                entityPopulate( profile, profileData )
                profile.setUser( user )
                entitySave( profile )

                transactionCommit()
                return user
            } catch ( any e ) {
                transactionRollback()
                throw( type: "UserService.CreateFailed", message: e.message, cause: e )
            }
        }
    }

    function bulkUpdate( ids, status ) {
        transaction {
            for ( var id in ids ) {
                var entity = entityLoadByPK( "User", id )
                if ( !isNull( entity ) ) {
                    entity.setStatus( status )
                    entitySave( entity )
                }
            }
        }
    }
}
```

## Transaction Isolation Levels

Most JPA/Hibernate setups default to the database-level isolation. You can influence this via Hibernate's session settings if needed, but for most use-cases rely on the database default (typically `READ COMMITTED`).

## Common Pitfalls

- ❌ Never call `entitySave()` or `entityDelete()` outside a `transaction {}` block — changes may not persist reliably
- ❌ `transactionCommit()` inside a catch block without a prior `transactionRollback()` will commit the bad state
- ✅ Put `transactionRollback()` BEFORE re-throwing in catch blocks
- ✅ Use `ORMFlush()` to get auto-generated IDs before relating them to child entities
- ✅ Nested `transaction {}` blocks JOIN the outer transaction — they do not create a new isolated transaction
- ✅ Use `transactionSetSavePoint()` for partial-rollback logic within a larger transaction
- ❌ Calling `ORMClearSession()` inside a transaction without flushing first will silently discard pending changes
