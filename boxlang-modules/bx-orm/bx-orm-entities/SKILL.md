---
name: bx-orm-entities
description: "Use this skill when defining BoxLang ORM entities: the persistent annotation, entity names, table mapping, property annotations, fieldtype, ormType, identifiers/primary keys, composite keys, version fields, and entity inheritance."
---

# bx-orm: Entities & Properties

## Defining a Persistent Entity

```javascript
// Minimal entity — table name defaults to class file name
class persistent="true" {

}

// With explicit entity name and table
class persistent="true" entityName="Author" table="authors" {

}
```

## Entity Annotations

| Annotation | Type | Default | Description |
|------------|------|---------|-------------|
| `persistent` | boolean | `false` | Marks the class as an ORM entity |
| `entityName` | string | class name | Override the entity name |
| `table` | string | entity name | Override the database table name |
| `schema` | string | | Database schema name |
| `catalog` | string | | Database catalog name |
| `datasource` | string | `this.datasource` | Override datasource per entity |
| `readonly` | boolean | `false` | Map to an existing table read-only |
| `dynamicInsert` | boolean | `false` | Only INSERT non-null columns |
| `dynamicUpdate` | boolean | `false` | Only UPDATE changed columns |
| `cacheUse` | string/boolean | | Enable L2 caching for this entity |
| `cacheName` | string | entity name | L2 cache region name |
| `batchSize` | number | | Hibernate batch fetch size |

## Defining Properties

All properties inside a `persistent=true` class are persistent by default:

```javascript
class persistent="true" entityName="User" table="users" {

    // Primary key
    property name="id" fieldtype="id" type="numeric" generator="native";

    // Basic string column
    property name="username" type="string";

    // With explicit column name
    property name="createdAt" column="created_at" type="date" ormtype="timestamp";

    // Non-persistent (ignored by ORM)
    property name="transientHelper" persistent="false";

    // With default value (BoxLang side only, not DB-level)
    property name="isActive" type="boolean" default="true";

    // With DB-level default
    property name="createdOn" ormtype="datetime" dbdefault="'2024-01-01'";

    // Not-null constraint
    property name="email" type="string" notnull="true";

}
```

## Property Annotations Reference

| Annotation | Examples | Description |
|------------|----------|-------------|
| `name` | `"userId"` | Property name |
| `column` | `"user_id"` | Database column name |
| `type` | `string`, `numeric`, `date` | BoxLang data type |
| `ormType` | `big_decimal`, `timestamp`, `text` | Hibernate type |
| `sqlType` | `nvarchar(100)` | Vendor-specific SQL type (DDL only) |
| `fieldtype` | `id`, `column`, `one-to-many`, etc. | Field behavior |
| `notnull` | `true` | NOT NULL constraint |
| `length` | `255` | VARCHAR length |
| `default` | `"active"` | BoxLang property default |
| `dbdefault` | `"'pending'"` | Database column default |
| `persistent` | `false` | Exclude this property from ORM |
| `insert` | `false` | Exclude from INSERT |
| `update` | `false` | Exclude from UPDATE |
| `unique` | `true` | Unique constraint |
| `index` | `"idx_email"` | Create an index |

## Identifiers (Primary Keys)

```javascript
// Auto-increment (native — recommended)
property name="id" fieldtype="id" type="numeric" generator="native";

// UUID primary key
property name="id" fieldtype="id" type="string" generator="uuid";

// Assigned (you set the ID manually)
property name="id" fieldtype="id" type="string" generator="assigned";

// Sequence (for Oracle/PostgreSQL)
property name="id"
    fieldtype="id"
    type="numeric"
    generator="sequence"
    sequence="seq_users";
```

Generator values: `native`, `identity`, `uuid`, `assigned`, `sequence`, `increment`, `hilo`.

## Composite Primary Keys

```javascript
class persistent="true" entityName="OrderItem" table="order_items" {

    property name="orderId"   fieldtype="id" type="numeric" column="order_id";
    property name="productId" fieldtype="id" type="numeric" column="product_id";

    property name="quantity" type="numeric";
    property name="price"    type="numeric" ormtype="big_decimal";

}
```

## Version / Optimistic Locking

```javascript
class persistent="true" entityName="Product" {

    property name="id"      fieldtype="id" generator="native";
    property name="name"    type="string";
    property name="version" fieldtype="version" type="numeric";

}
// Hibernate increments version on every update.
// Throws StaleObjectStateException if two sessions modify the same row.
```

## Timestamp Auto-Fields

```javascript
property name="createdAt"  fieldtype="timestamp" generated="insert";
property name="updatedAt"  fieldtype="timestamp" generated="always";
```

## Full Entity Example

```javascript
class persistent="true" entityName="Post" table="blog_posts" {

    property name="id"
        fieldtype = "id"
        type      = "numeric"
        generator = "native";

    property name="title"
        type     = "string"
        length   = 200
        notnull  = "true";

    property name="body"
        type    = "string"
        ormtype = "text";

    property name="status"
        type    = "string"
        length  = 20
        default = "draft";

    property name="publishedAt"
        column  = "published_at"
        type    = "date"
        ormtype = "timestamp";

    property name="createdAt"
        column    = "created_at"
        ormtype   = "datetime"
        insert    = "true"
        update    = "false"
        dbdefault = "CURRENT_TIMESTAMP";

}
```

## Common Pitfalls

- ❌ Do NOT omit `generator` on `fieldtype="id"` — use `native` for auto-increment
- ❌ Do NOT use `type="date"` when you need full datetime — use `ormtype="timestamp"`
- ❌ Quote datetime `dbdefault` values: `dbdefault="'2024-01-01'"` (MySQL requires single-quoted strings)
- ✅ Use `persistent="false"` for calculated properties or transient helpers
- ✅ Use `dynamicUpdate="true"` on large entities where only a few columns change per save
- ✅ Use `insert="false" update="false"` on columns that are managed by DB triggers
