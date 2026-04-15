---
name: bx-orm-relationships
description: "Use this skill when defining relationships between ORM entities: one-to-one, one-to-many, many-to-one, many-to-many, lazy loading, cascade options, foreign keys, link tables, singular names, and inverse relationships."
---

# bx-orm: Entity Relationships

## Relationship Overview

| Type | Use Case | Example |
|------|----------|---------|
| `one-to-one` | Single associated record | User → Address |
| `one-to-many` | Parent with collection | User → Posts |
| `many-to-one` | Child pointing to parent | Post → Author |
| `many-to-many` | Bidirectional multi | Author ↔ Book |

Every relationship property uses `fieldtype` to declare its kind.

## One-to-One

```javascript
// Contact.bx — has one Address
class persistent="true" entityName="Contact" {

    property name="id"      fieldtype="id" generator="native";
    property name="name"    type="string";

    // One-to-one: each Contact has exactly one Address
    property name="address"
        fieldtype = "one-to-one"
        class     = "Address";

}
```

Set `lazy="false"` to eagerly load the related entity:

```javascript
property name="address"
    fieldtype = "one-to-one"
    class     = "Address"
    lazy      = "false";
```

## One-to-Many

```javascript
// User.bx — has many Posts
class persistent="true" entityName="User" {

    property name="id"    fieldtype="id" generator="native";
    property name="email" type="string";

    // One-to-many: a User has many Posts
    property name="posts"
        fieldtype   = "one-to-many"
        class       = "Post"
        fkcolumn    = "author_id"   // FK column in the posts table
        lazy        = "true"
        singularName= "post";       // enables addPost(), removePost()

}
```

Accessing the collection:

```javascript
user = entityLoadByPK( "User", 1 )
posts = user.getPosts()       // returns array of Post entities
user.addPost( newPost )       // uses singularName
user.removePost( oldPost )    // uses singularName
user.hasPosts()               // boolean
```

## Many-to-One

```javascript
// Post.bx — belongs to one Author (User)
class persistent="true" entityName="Post" {

    property name="id"    fieldtype="id" generator="native";
    property name="title" type="string";

    // Many-to-one: many Posts share one Author
    property name="author"
        fieldtype = "many-to-one"
        class     = "User"
        fkcolumn  = "author_id";

}
```

```javascript
post   = entityLoadByPK( "Post", 42 )
author = post.getAuthor()     // returns User entity
```

## Many-to-Many

```javascript
// Author.bx — can write many Books; Books can have many Authors
class persistent="true" entityName="Author" {

    property name="id"   fieldtype="id" generator="native";
    property name="name" type="string";

    property name="books"
        fieldtype   = "many-to-many"
        class       = "Book"
        linktable   = "author_books"   // join table
        fkcolumn    = "author_id"      // this entity's FK in join table
        inversejoin = "book_id"        // other entity's FK in join table
        singularName= "book";

}
```

```javascript
// Book.bx — inverse side
class persistent="true" entityName="Book" {

    property name="id"      fieldtype="id" generator="native";
    property name="title"   type="string";

    property name="authors"
        fieldtype   = "many-to-many"
        class       = "Author"
        linktable   = "author_books"
        fkcolumn    = "book_id"
        inversejoin = "author_id"
        singularName= "author";

}
```

## Relationship Property Annotations

| Annotation | Description |
|------------|-------------|
| `fieldtype` | Relationship type: `one-to-one`, `one-to-many`, `many-to-one`, `many-to-many` |
| `class` | FULLY qualified path or entity name of the related class |
| `fkcolumn` | Foreign key column name |
| `linktable` | Join table name (many-to-many only) |
| `inversejoin` | FK column for the other entity in the join table |
| `lazy` | `"true"` (default) or `"false"` for eager loading |
| `cascade` | `"all"`, `"save-update"`, `"delete"`, `"none"` |
| `singularName` | Singular form — enables `addX()`, `removeX()`, `hasX()` methods |
| `orderBy` | Default sort column(s) for collections |
| `where` | SQL WHERE clause to filter the collection |
| `fetch` | `"select"` or `"join"` fetching strategy |

## Cascade Options

```javascript
// Cascade save/delete to child records
property name="posts"
    fieldtype = "one-to-many"
    class     = "Post"
    fkcolumn  = "user_id"
    cascade   = "all";         // save, update, and delete cascade

// Cascade save only (not delete)
property name="address"
    fieldtype = "one-to-one"
    class     = "Address"
    cascade   = "save-update";
```

| Cascade Value | Behavior |
|--------------|----------|
| `none` | No cascade |
| `save-update` | Cascade save and update operations |
| `delete` | Cascade delete only |
| `all` | Cascade save, update, and delete |
| `all-delete-orphan` | `all` + delete orphaned records |

## Lazy vs Eager Loading

```javascript
// Lazy (default) — related entity loaded only when accessed
property name="posts" fieldtype="one-to-many" class="Post" lazy="true";

// Eager — loads related entity in the same SQL query
property name="address" fieldtype="one-to-one" class="Address" lazy="false";
```

**Recommendation**: Use `lazy="true"` (default) for collections (one-to-many, many-to-many) and consider `lazy="false"` only for single-record relationships (one-to-one) where you always need the related data.

## N+1 Problem Prevention

Use `batchSize` to batch-load related entities:

```javascript
// Entity-level batchSize
class persistent="true" entityName="Post" batchSize="20" {
    // ...
}

// Relationship-level batchSize
property name="comments"
    fieldtype = "one-to-many"
    class     = "Comment"
    fkcolumn  = "post_id"
    batchSize = "20";
```

## Common Pitfalls

- ❌ Do NOT forget `fkcolumn` on one-to-many and many-to-one — Hibernate cannot infer it
- ❌ Do NOT use `lazy="false"` on large collections — will load thousands of records
- ❌ Do NOT forget `linktable` on many-to-many — it is required
- ✅ Always set `singularName` on collection relationships for clean `addX()` / `removeX()` API
- ✅ Use `cascade="all-delete-orphan"` on owned one-to-many collections (e.g., order → line items)
- ✅ Define both sides of many-to-many relationships with matching `linktable` values
