---
name: bx-orm-entities
description: "Use this skill when defining BoxLang ORM entities (bx-orm 2.x, Hibernate 7.4): the persistent/entity annotation, entity names, table mapping, entity where filters, defaultSort, soft delete, property annotations, fieldtype, ormType, identifiers and generators, unsavedValue, composite keys, version fields, autoTimestamp, inheritance and mappedSuperClass, static entity methods (User::get()), and this.memento for entityToStruct()."
---

# bx-orm: Entities & Properties

> BoxLang is the AI-native software productivity platform for building, modernizing and running applications, with developers and AI agents working together.

## Defining a Persistent Entity

```javascript
// Minimal entity: entity name = file name, table = entity name
class persistent="true" {}

// Explicit entity name and table
class persistent="true" entityName="Author" table="authors" {}

// `entity` marks the class persistent; a value also sets the name
class entity="Author" table="authors" {}
```

## Entity Annotations

| Annotation | Values / Default | Description |
| --- | --- | --- |
| `persistent` | `false` | Marks the class as an ORM entity |
| `entity` | | Same as `persistent="true"`; a value is the name |
| `entityName` | file name | Entity name used in BIFs and HQL |
| `table` | entity name | Database table |
| `schema` / `catalog` | | Database schema / catalog |
| `datasource` | app ORM datasource | Datasource for this entity |
| `readonly` | `false` | Table is read-only |
| `dynamicInsert` | `false` | INSERT only non-null columns |
| `dynamicUpdate` | `false` | UPDATE only changed columns |
| `selectBeforeUpdate` | | SELECT first, UPDATE only if modified |
| `optimisticLock` | | `all`, `dirty`, `version`, `none` |
| `batchSize` | | Batch fetch size for this entity |
| `cacheUse` | | Second-level cache strategy (see below) |
| `cacheName` | | Second-level cache region |
| `where` | | Raw SQL filter on every load (2.x) |
| `defaultSort` | | Default order, e.g. `"lastName, id desc"` |
| `softDelete` | | `true`/`yes`/`deleted`, `active`, `timestamp` |
| `softDeleteColumn` | `deleted` | Column used by `softDelete` |
| `mappedSuperClass` | `false` | Parent class whose properties are copied |
| `discriminatorColumn` | | Single-table inheritance (root) |
| `discriminatorValue` | | Single-table inheritance (subclass) |
| `joinColumn` | | Joined inheritance (subclass) |

```javascript
class persistent="true" table="notes" where="is_active = 1" softDelete="true"
    defaultSort="title" {}
```

- `cacheUse`: `read-only`, `nonstrict-read-write`, `read-write`,
  `transactional`.
- `where` uses column names (raw SQL). In 1.x it was silently ignored.
- `softDelete` turns `entityDelete()` into an UPDATE and hides deleted rows.
  Do not declare a property for the column; declare it on the root entity
  only. `defaultSort`, `softDelete` and `softDeleteColumn` are 2.x only.

## Properties

Properties are persistent unless marked `persistent="false"`:

```javascript
class persistent="true" entityName="User" table="users" {
    property name="id" fieldtype="id" generator="native" update="false";
    property name="username" ormtype="string" length="50" notnull="true";
    property name="email" ormtype="string" unique="true" index="idx_email";
    property name="isActive" ormtype="boolean" default="true"; // BoxLang side
    property name="status" ormtype="string" dbdefault="'pending'"; // DDL
    property name="createdOn" column="created_on" ormtype="timestamp";
    property name="helper" persistent="false"; // ignored by the ORM
}
```

| Annotation | Example | Description |
| --- | --- | --- |
| `column` | `"user_id"` | Column name (defaults to property name) |
| `type` | `string`, `numeric` | BoxLang type; used as `ormType` if unset |
| `ormType` | `string`, `integer` | Hibernate type of the column |
| `sqlType` | `nvarchar(100)` | Vendor SQL type, DDL only |
| `fieldtype` | `column` (default) | See field types below |
| `length` / `precision` / `scale` | `255` | Column size |
| `notnull` / `unique` | `true` | Constraints |
| `uniquekey` / `index` | `"uk_name"` | Named unique key / index |
| `default` | `"draft"` | BoxLang default, not a DB default |
| `dbdefault` | `"'pending'"` | DB column default (quote strings) |
| `insert` / `update` | `false` | Leave out of INSERT / UPDATE |
| `formula` | `"(SELECT ...)"` | Read-only computed SQL value |
| `autoTimestamp` | `create`, `update` | Set on insert / insert+update (2.x) |
| `optimisticLock` | `false` | Leave column out of the version check |

`fieldtype` values: `column`, `id`, `version`, `timestamp`, `collection`,
`one-to-one`, `one-to-many`, `many-to-one`, `many-to-many`. Any other value
(such as `primary`) stops the ORM from starting with an `orm.config` error.

Common `ormType` values and what they map to (2.x):

- `string`/`varchar`, `text`/`clob`; `char`/`nchar` is a single character
- `integer`/`int`, `long`, `short`/`tinyint`, `biginteger`/`bigint`
- `bigdecimal`/`big_decimal` (exact decimals), `float`
- `numeric`/`decimal`/`number`: a Java `double`
- `boolean`/`bit`, `yes_no`/`yesno`, `true_false`/`truefalse`
- `date`, `datetime`, `timestamp`: all a full timestamp; `time`: time only
- `binary`/`blob`

## Identifiers and Generators

```javascript
property name="id" fieldtype="id" generator="native" update="false";
property name="id" fieldtype="id" generator="identity";   // auto-increment
property name="id" fieldtype="id" generator="uuid" ormtype="string";
property name="id" fieldtype="id" generator="sequence" sequence="seq_users";
property name="id" fieldtype="id" generator="assigned";   // you set the id
property name="id" fieldtype="id" generator="foreign"
    params="{ property = 'owner' }";                     // shared-PK one-to-one
```

Built-in generators: `assigned` (the default when `generator` is omitted),
`foreign`, `guid`, `identity`, `increment`, `native`, `select`, `sequence`,
`sequence-identity`, `uuid`, `uuid2`. Any other value must be a Java class
name on the classpath, otherwise the ORM fails to start. `seqhilo` and `hilo`
are not valid; use `sequence`.

- `native`: identity column on MySQL, MariaDB, SQL Server, Derby; the shared
  `hibernate_sequence` (or `sequence`) on PostgreSQL and Oracle.
- `uuid`, `uuid2`, `guid`: a 32-character hex string, so use a string column
  (in 1.x `guid` used the database's own GUID).
- `increment`: not safe when other processes insert into the table.
- `params` takes a struct or JSON string; `selectkey` goes with `select`.

### Unsaved Value (2.x)

Hibernate inserts when the id equals its unsaved value, else updates.
bx-orm declares it for every id: the property `default` if it has one,
otherwise `null`. Set `unsavedValue` when a new id is never null:

```javascript
property name="id" fieldtype="id" ormtype="integer" generator="assigned"
    unsavedValue="0";
```

Because of this, 2.x never instantiates an entity at boot: `init()` runs
only when your code creates the entity, so an `init()` that reads
`application` scope (e.g. WireBox) is safe.

## Composite Primary Keys

```javascript
class persistent="true" entityName="OrderItem" table="order_items" {
    property name="orderId"   fieldtype="id" ormtype="integer";
    property name="productId" fieldtype="id" ormtype="integer";
    property name="quantity"  ormtype="integer";
    property name="price"     ormtype="bigdecimal" precision="10" scale="2";
}

item = entityLoadByPK( "OrderItem", { orderId : 1, productId : 7 } );
```

Generators are ignored on composite-key parts; assign the values yourself.

## Version / Optimistic Locking

```javascript
class persistent="true" entityName="Product" optimisticLock="version" {
    property name="id"       fieldtype="id" generator="uuid" ormtype="string";
    property name="revision" fieldtype="version" ormtype="integer";
    // or a timestamp-based version:
    // property name="lastModified" fieldtype="timestamp";
}
```

A version must be a numeric (`integer`, `long`, `short`) or timestamp type
(`ormtype="numeric"` maps to a double and logs an error). A conflicting update
raises `orm.stale` in 2.x (raw `StaleObjectStateException` in 1.x, where
version columns also had bugs fixed in 2.0).

## Automatic Timestamps (2.x)

```javascript
property name="createdDate" ormtype="timestamp" autoTimestamp="create";
property name="updatedDate" ormtype="timestamp" autoTimestamp="update";
```

Set from the JVM clock at flush; no event handler or `eventHandling` needed.
`create` (also `created`, `insert`) and `update` (also `updated`) are the
only values. Bulk `updateAll()` statements do not set them.

## Inheritance

```javascript
// mappedSuperClass (BaseEntity.bx): shared properties, no parent table
class mappedSuperClass="true" {
    property name="createdDate" ormtype="timestamp";
}
class persistent="true" extends="BaseEntity" {}

// Single table: root declares the discriminator column
class persistent="true" table="payments" discriminatorColumn="type" {}
class persistent="true" extends="Payment" discriminatorValue="card" {}

// Joined: subclass has its own table keyed by joinColumn
class persistent="true" table="payments" {}         // Payment.bx
class persistent="true" extends="Payment" table="card_payments"
    joinColumn="paymentId" {}
```

A subclass joins its persistent parent's hierarchy only when it declares
`joinColumn` or `discriminatorValue`. Only single-table and joined
inheritance are generated (no table-per-class).

## Static Entity Methods (2.x)

Every entity class gets static helpers that call the matching BIF:

```javascript
user  = User::get( 1 );                         // entityLoadByPK()
user  = User::getOrFail( id );                  // orm.notFound if missing
admin = User::findWhere( { email : "a@x.com" } );
total = User::count( { active : true } );
page  = User::list( { max : 20, offset : 40, sort : "lastName" } );
rows  = Order::updateWhere( { status : "shipped" }, { status : "archived" } );
```

Also `getAll`, `read`, `getReference`, `findWhereOrFail`, `findAllWhere`,
`first`, `exists`, `executeQuery`, `criteria`/`newCriteria`, `new`,
`firstOrNew`, `firstOrCreate` and `deleteWhere`. Methods you declare win;
instances can call them (`user.count()`). Turn off with
`ormSettings.staticMethods = false`. `updateWhere()`/`deleteWhere()` run one
statement: no events or cascades, and an empty filter is refused.

## Entities as Structs

`entityToStruct( user, { includes : "role.name" } )` (2.x) honors a
mementifier-style `this.memento` struct on the entity (`defaultIncludes`,
`defaultExcludes`, `neverInclude`, `defaults`, `mappers`, `profiles`).

## Common Pitfalls

- ❌ Do NOT omit `generator` on an auto-generated id: the default is
  `assigned`, which requires you to set the id before saving
- ❌ Do NOT use `generator="hilo"` or `seqhilo`: use `sequence`
- ❌ Do NOT rely on a property named `id` without `fieldtype="id"`: it is
  promoted with a deprecation warning
- ❌ Do NOT use `numeric` for money or versions: it maps to a double; use
  `bigdecimal` (money) or `integer` (versions)
- ❌ Do NOT use `fieldtype="timestamp"` for audit dates: it is an
  optimistic-lock version; use `autoTimestamp`
- ❌ Quote string and date `dbdefault` values: `dbdefault="'2024-01-01'"`
- ❌ Do NOT expect `entityNew( "User", data )` to keep extra keys: 2.x sets
  only declared properties (1.x copied every key)
- ✅ Use `update="false"` on id properties
- ✅ Use `insert="false" update="false"` on columns managed by DB triggers
