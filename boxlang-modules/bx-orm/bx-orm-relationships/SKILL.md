---
name: bx-orm-relationships
description: "Use this skill when defining relationships between BoxLang ORM entities (bx-orm 2.x, Hibernate 7.4): one-to-one, one-to-many, many-to-one, many-to-many, fkcolumn, linktable, inversejoincolumn, inverse and mappedBy, lazy and fetch, cascade options, singularName and the generated has/add/remove methods, orderBy and where on collections, struct-keyed collections, value collections (fieldtype=collection), batch size and collection caching."
---

# bx-orm: Entity Relationships

> BoxLang is the AI-native software productivity platform for building, modernizing and running applications, with developers and AI agents working together.

## Relationship Overview

| Type | Use Case | Example |
| --- | --- | --- |
| `one-to-one` | Single associated record | User → Address |
| `one-to-many` | Parent with collection | User → Posts |
| `many-to-one` | Child pointing to parent | Post → Author |
| `many-to-many` | Multi on both sides | Author ↔ Book |

Every relationship property uses `fieldtype` plus `class` (alias `cfc`): an
entity name, class name or class path on the same datasource.

## One-to-Many and Many-to-One (Bidirectional)

```javascript
// User.bx: the collection side is the inverse side
class persistent="true" entityName="User" {
    property name="id" fieldtype="id" generator="native";
    property name="posts"
        fieldtype    = "one-to-many"
        class        = "Post"
        fkcolumn     = "author_id"   // FK column in the posts table
        inverse      = "true"        // Post.author owns the FK
        singularName = "post"
        cascade      = "all-delete-orphan";
}

// Post.bx: the owning side holds the FK column
class persistent="true" entityName="Post" {
    property name="id" fieldtype="id" generator="native";
    property name="author" fieldtype="many-to-one" class="User"
        fkcolumn="author_id";
}
```

Instead of `inverse="true"`, `mappedBy="author"` on the collection names the
owning property. Both tell Hibernate the collection does not write the FK.

```javascript
user  = entityLoadByPK( "User", 1 );
posts = user.getPosts();      // array of Post entities
user.hasPost();               // true if the collection has any items
user.hasPost( somePost );     // true if somePost is in the collection
user.addPost( newPost );      // returns the entity, for chaining
user.removePost( oldPost );
newPost.setAuthor( user );    // set the owning side too
```

## Generated Relationship Methods

| Method | Generated for |
| --- | --- |
| `has<Name>( [entity] )` | All relationships (no argument on to-one) |
| `add<Name>( entity )` | `one-to-many`, `many-to-many` |
| `remove<Name>( entity )` | `one-to-many`, `many-to-many` |

`<Name>` is the property name, or `singularName` when set (`posts` with
`singularName="post"` gives `hasPost()`, `addPost()`, `removePost()`).
Getters and setters (`getPosts()`, `setPosts()`) always use the property
name. Methods you write yourself are never replaced. In 2.x a to-many
`getX()` returns a snapshot, so `getPosts().each( p => removePost( p ) )`
is safe.

## One-to-One

```javascript
// Shared primary key: no fkcolumn, both rows have the same id
property name="profile" fieldtype="one-to-one" class="Profile" cascade="all";

// Profile.bx: its id comes from the owner; constrained adds the PK FK
property name="id" fieldtype="id" generator="foreign"
    params="{ property = 'user' }";
property name="user" fieldtype="one-to-one" class="User" constrained="true";

// Foreign-key one-to-one: with fkcolumn it is mapped as a many-to-one
property name="address" fieldtype="one-to-one" class="Address"
    fkcolumn="address_id";
```

## Many-to-Many

```javascript
// Author.bx: owning side writes the link rows
property name="books"
    fieldtype         = "many-to-many"
    class             = "Book"
    linktable         = "author_books"
    fkcolumn          = "author_id"    // this entity's FK in the link table
    inversejoincolumn = "book_id"      // the other entity's FK
    singularName      = "book";

// Book.bx: inverse side, same link table, columns swapped
property name="authors"
    fieldtype         = "many-to-many"
    class             = "Author"
    linktable         = "author_books"
    fkcolumn          = "book_id"
    inversejoincolumn = "author_id"
    inverse           = "true"
    singularName      = "author";
```

`linkschema` and `linkcatalog` place the link table. A `one-to-many` with a
`linktable` is mapped as a unique many-to-many through that table.

## Relationship Annotations

| Annotation | Description |
| --- | --- |
| `fieldtype` | `one-to-one`, `one-to-many`, `many-to-one`, `many-to-many` |
| `class` / `cfc` | Related entity (required) |
| `fkcolumn` | FK column (comma list for multi-column keys) |
| `linktable` | Join table; requires `fkcolumn` |
| `inversejoincolumn` | The other entity's FK column in the link table |
| `linkschema` / `linkcatalog` | Schema / catalog of the link table |
| `inverse` | `true`: this side does not write the FK |
| `mappedBy` | Owning property on the other entity |
| `lazy` | `true`, `false`, `proxy`, `no-proxy`, `extra` |
| `fetch` | To-one only: `select` (default) or `join` |
| `cascade` | Comma list, see below (default `none`) |
| `singularName` | Name used by the has/add/remove methods |
| `orderBy` | Raw SQL `ORDER BY` for a to-many collection |
| `where` | Raw SQL filter on a to-many collection |
| `type` | Collection type: `array` (default) or `struct` |
| `batchSize` | Collections fetched per round trip |
| `constrained` | `one-to-one` only: PK is also an FK to the target |
| `missingRowIgnored` | `many-to-one`: a dangling FK loads as null |
| `notnull` | Required to-one association |
| `cacheUse` / `cacheName` | Cache a to-many collection (2.x) |

`orderBy` and `where` use column names, not property names.

## Cascade Options

| Value | Behavior (2.x) |
| --- | --- |
| `none` | No cascade (default) |
| `save-update` | `entitySave()` persists new and merges detached children |
| `persist` / `create` | Persist new children only |
| `merge` | Merge children with the owner |
| `delete` / `remove` | Delete children with the owner |
| `delete-orphan` | Delete, plus delete children removed from the collection |
| `all` | All operations |
| `all-delete-orphan` | `all` plus orphan removal |
| `refresh`, `evict`, `lock`, `replicate` | Cascade that operation |

Combine values with commas: `cascade="save-update,delete"`. Hibernate 7
removed the `save-update` style, so 2.x maps it to persist plus merge (1.x
used Hibernate 5's own `save-update`, and `persist` was its alias).
Unknown values are ignored silently.
Orphan removal applies to to-many collections only.

## Lazy vs Eager Loading

```javascript
// Lazy (default): loaded on first access
property name="posts" fieldtype="one-to-many" class="Post"
    fkcolumn="author_id" lazy="true";

// Eager to-one
property name="address" fieldtype="one-to-one" class="Address" lazy="false";

// Eager to-one, fetched with a SQL join (no `lazy` attribute)
property name="manufacturer" fieldtype="many-to-one" class="Manufacturer"
    fkcolumn="FK_manufacturer" fetch="join";
```

Associations are lazy unless `lazy="false"`, including to-one ones.

- In 2.x every lazy to-one (`true`, `proxy`, `no-proxy`) is a lazy proxy, and
  the `proxyLazyLoading` setting has no effect. In 1.x `proxyLazyLoading`
  decided whether `lazy="true"` became `proxy`.
- `lazy="extra"` works like `true` in 2.x (Hibernate 7 has no extra-lazy
  collections, so `size()` loads the collection). In 1.x it was extra-lazy.
- `fetch="join"` makes a to-one eager only when `lazy` is not set (`lazy`
  wins). bx-orm 2.x ignores `fetch` on to-many collections; use `lazy`.

## Struct and Value Collections

```javascript
// Entity collection keyed by a column (struct instead of array)
property name="itemsByCode" fieldtype="one-to-many" class="Item"
    fkcolumn="shelfId" type="struct" structKeyColumn="itemCode"
    structKeyType="string";

// Value collection (2.x): plain values in their own table
property name="tags" fieldtype="collection" type="array"
    table="article_tags" fkcolumn="article_id"
    elementColumn="tag" elementType="string";
```

`structKeyColumn` is required for `type="struct"`. `structKeyFormula` can
compute the key with SQL. A value collection with `type="struct"` also takes
`structKeyColumn`/`structKeyType`.

## N+1 Prevention

```javascript
class persistent="true" entityName="Post" batchSize="20" {}  // entity level

property name="comments" fieldtype="one-to-many" class="Comment"
    fkcolumn="post_id" batchSize="50";                          // collection
```

Without a collection `batchSize`, the `defaultBatchSize` ORM setting (16)
applies.

## Common Pitfalls

- ❌ Do NOT write `inversejoin`: the annotation is `inversejoincolumn`
  (unknown annotations are ignored)
- ❌ Do NOT use `linktable` without `fkcolumn`: the ORM fails to start
- ❌ Do NOT leave both sides of a bidirectional pair owning: mark the
  collection (or one many-to-many side) `inverse="true"` or use `mappedBy`
- ❌ Do NOT use `lazy="false"` on large collections: every load pulls them
- ❌ Do NOT expect `lazy="extra"` to count without loading in 2.x
- ✅ Declare `fkcolumn` explicitly; an owning one-to-many without it borrows
  the target's back-reference FK, or falls back to a join table with a warning
- ✅ Set `singularName` on collections for `addPost()` / `removePost()`
- ✅ Use `cascade="all-delete-orphan"` on owned children (order → line items)
- ✅ Set both sides in memory (`addPost()` and `setAuthor()`) on
  bidirectional pairs
