---
name: bx-rss
description: "Use this skill to parse and create RSS/Atom feeds in BoxLang with the bx-rss module: rss() BIF to fetch feeds, bx:feed component with action read/create, filtering items, limiting results, creating RSS 2.0 and Atom feeds, and handling iTunes podcast extensions."
---

# bx-rss: RSS / Atom Feed Processing

## Installation

```bash
install-bx-module bx-rss
# CommandBox
box install bx-rss
```

## Supported Formats

- RSS 2.0
- RSS 1.0 (RDF)
- Atom
- iTunes Podcast extensions
- Media RSS extensions

---

## BIF: `rss()`

```javascript
// Fetch and parse a feed
feed = rss( "https://blog.example.com/feed.rss" )

// Access channel metadata
writeOutput( "Title: " & feed.channel.title )
writeOutput( "Link: " & feed.channel.link )
writeOutput( "Description: " & feed.channel.description )

// Access items (array)
for ( var item of feed.items ) {
    writeOutput( item.title & " — " & item.publishedDate )
    writeOutput( item.link )
    writeOutput( item.description )
}
```

## Component: `bx:feed` — Reading

```javascript
// Script syntax
bx:feed action="read" source="https://blog.example.com/feed.rss" result="feed" {
}

// Tag syntax
bx:feed action="read" source="https://blog.example.com/feed.rss" result="feed"

// With limit and filtering
bx:feed
    action="read"
    source="https://news.example.com/rss.xml"
    result="feed"
    maxItems=10
    filter="boxlang"

// From local file
bx:feed action="read" source="/app/data/cached-feed.xml" result="feed"
```

## Component: `bx:feed` — Creating

```javascript
// Create an RSS 2.0 feed
bx:feed action="create" result="feedXml" type="rss" {
    // Channel metadata passed via attributes of bx:feed or as nested struct
}

// Programmatic creation
var feedDefinition = {
    type        : "rss",
    version     : "2.0",
    title       : "My Blog",
    link        : "https://blog.example.com",
    description : "Latest posts from My Blog",
    xmlUrl      : "https://blog.example.com/feed.rss",
    items       : []
}

// Add items
for ( var post of posts ) {
    arrayAppend( feedDefinition.items, {
        title       : post.title,
        link        : "https://blog.example.com/post/" & post.slug,
        description : post.summary,
        publishedDate : post.publishedAt,
        author      : post.authorEmail,
        guid        : "https://blog.example.com/post/" & post.slug,
        categories  : [ post.category ]
    })
}

bx:feed action="create" result="feedXml" {
    // Set structure via variables.feedDefinition
}

// Write to file
fileWrite( "/app/public/feed.rss", feedXml )

// Or stream to browser
content type="application/rss+xml"
writeOutput( feedXml )
```

## Atom Feed Creation

```javascript
var feedDefinition = {
    type        : "atom",
    version     : "1.0",
    title       : "My Blog (Atom)",
    link        : "https://blog.example.com",
    xmlUrl      : "https://blog.example.com/atom.xml",
    description : "Latest posts",
    items       : []
}
```

## iTunes Podcast Feed

```javascript
var feedDefinition = {
    type    : "rss",
    version : "2.0",
    title   : "My Podcast",
    link    : "https://mypodcast.com",
    description : "Weekly tech discussions",
    // iTunes-specific
    itunes  : {
        author       : "Jane Doe",
        image        : "https://mypodcast.com/cover.jpg",
        category     : "Technology",
        explicit     : "no",
        owner        : { name: "Jane Doe", email: "jane@mypodcast.com" }
    },
    items   : [
        {
            title       : "Episode 42: BoxLang Deep Dive",
            description : "We talk about BoxLang internals",
            enclosure   : {
                url    : "https://mypodcast.com/ep42.mp3",
                type   : "audio/mpeg",
                length : 52428800
            },
            publishedDate : "2025-01-15",
            guid        : "podcast-ep-42",
            itunes      : {
                duration : "54:22",
                episode  : 42
            }
        }
    ]
}
```

## Feed Aggregator Pattern

```javascript
function aggregateFeeds( feedUrls, maxPerFeed ) {
    var allItems = []

    for ( var url of feedUrls ) {
        try {
            bx:feed action="read" source=url result="feed" maxItems=maxPerFeed
            for ( var item of feed.items ) {
                item.source = feed.channel.title
                arrayAppend( allItems, item )
            }
        } catch ( any e ) {
            // Skip broken feeds
        }
    }

    // Sort by date, newest first
    allItems.sort( ( a, b ) -> {
        return dateCompare( b.publishedDate, a.publishedDate )
    })

    return allItems
}
```

## Output Feed as RSS Endpoint

```javascript
// In a web handler (ColdBox or simple template)
function feed( event, rc, prc ) {
    var posts = postService.getLatestPosts( 20 )

    var feedData = {
        channel : {
            title       : "My Blog",
            link        : event.getHTTPBasePath(),
            description : "Latest posts"
        },
        items : posts.map( ( p ) => ({
            title       : p.title,
            link        : event.buildLink( "blog.post.#p.slug#" ),
            description : p.excerpt,
            publishedDate : p.publishedAt,
            guid        : p.id
        }))
    }

    bx:feed action="create" result="prc.feedXml" feedProperties=feedData

    event.renderData( type: "plain", data: prc.feedXml )
        .setHTTPHeader( name: "Content-Type", value: "application/rss+xml; charset=utf-8" )
}
```

## Common Pitfalls

- ✅ Always wrap feed reads in try/catch — remote URLs can fail or be malformed
- ❌ Don't assume `publishedDate` is always populated — some feeds omit it
- ✅ Use `maxItems` to limit memory usage when parsing large feeds
- ❌ Don't hot-load live feeds on every request — cache feed results to avoid rate limits and latency
- ✅ Set `Content-Type: application/rss+xml` when serving feeds to browsers/RSS readers
