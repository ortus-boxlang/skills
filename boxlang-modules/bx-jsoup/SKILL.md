---
name: bx-jsoup
description: Use this skill when parsing, querying, or sanitizing HTML in BoxLang with the bx-jsoup module: htmlParse(), htmlClean(), CSS selectors, XSS protection, HTML to JSON/XML conversion, and safe HTML allowlisting.
---

# bx-jsoup: HTML Parsing & Sanitization

## Installation

```bash
install-bx-module bx-jsoup
# CommandBox
box install bx-jsoup
```

## BIFs

| BIF | Description |
|-----|-------------|
| `htmlParse( html )` | Parse HTML into a BoxDocument object for querying |
| `htmlClean( html, [safelist], [baseUri] )` | Sanitize HTML, removing unsafe tags/attributes |

## HTML Parsing with `htmlParse()`

```javascript
// Parse HTML into a document
doc = htmlParse( "<html><head><title>My Page</title></head><body><h1>Hello</h1></body></html>" )

// Access basic properties
title       = doc.title()        // "My Page"
bodyText    = doc.body().text()  // "Hello"
innerHtml   = doc.html()         // inner HTML of body
fullHtml    = doc.outerHtml()    // full document HTML

// CSS selector queries — like jQuery
doc = htmlParse( "<ul><li class='item active'>One</li><li class='item'>Two</li></ul>" )
items   = doc.select( ".item" )           // all elements with class "item"
active  = doc.select( ".item.active" )    // elements with both classes
heading = doc.select( "h1, h2" )          // multiple selectors

// Get by ID
element = doc.getElementById( "main-content" )

// Get by tag
paragraphs = doc.getElementsByTag( "p" )

// Get by attribute
links = doc.getElementsByAttribute( "href" )

// Extract text content (strips all HTML)
plainText = doc.text()
```

## BoxDocument Enhanced Methods

```javascript
doc = htmlParse( htmlContent )

// Convert document to JSON
jsonStr    = doc.toJSON()           // compact JSON
jsonPretty = doc.toJSON( true )     // pretty-printed

// Convert document to XML
xmlStr   = doc.toXML()              // compact XML
xmlPretty = doc.toXML( true, 2 )   // pretty-printed, 2-space indent
```

## HTML Sanitization with `htmlClean()`

`htmlClean()` removes tags and attributes not on the allowlist — protecting against XSS:

```javascript
// Using built-in safelists
// "none"             — strip all HTML
// "simpleText"       — bold, italic, underline only
// "basic"            — basic formatting + links
// "basicWithImages"  — basic + img tags
// "relaxed"          — full formatting, links, images

cleanHtml = htmlClean( userInput, "basic" )

// Example: remove all HTML
plainText = htmlClean( "<script>alert(1)</script><p>Hello</p>", "none" )
// Returns: "Hello"

// Strip scripts but keep basic formatting
safe = htmlClean( "<script>xss()</script><b>Bold</b><p>Text</p>", "basic" )
// Returns: <b>Bold</b><p>Text</p>

// Rewrite relative URLs to absolute
safe = htmlClean( '<a href="/page">Link</a>', "basic", "https://example.com" )
// Returns: <a href="https://example.com/page" rel="nofollow">Link</a>
```

## Common Patterns

```javascript
// Sanitize user-submitted HTML from a rich text editor
function sanitizeRichText( html ) {
    return htmlClean( html, "basicWithImages" )
}

// Extract all links from a page
function extractLinks( html ) {
    var doc   = htmlParse( html )
    var links = doc.select( "a[href]" )
    return links.map( el => el.attr( "href" ) )
}

// Scrape structured data
function scrapePrices( html ) {
    var doc    = htmlParse( html )
    var prices = doc.select( ".price" )
    return prices.map( el => el.text() )
}
```

## Common Pitfalls

- ❌ Never output user-supplied HTML without running it through `htmlClean()` first
- ✅ Use `"basic"` or `"basicWithImages"` for rich text editor output — `"relaxed"` is rarely safe for user input
- ✅ `htmlParse()` is for trusted HTML you want to query; `htmlClean()` is for untrusted HTML you want to render
- ❌ `doc.select()` uses CSS selectors, not XPath — `"#id"`, `".class"`, `"tag"`, `"[attr]"` syntax
