---
name: bx-esapi
description: Use this skill for OWASP ESAPI encoding, decoding, and HTML sanitization in BoxLang: encodeFor(), encodeForHTML(), encodeForJavaScript(), encodeForSQL(), encodeForURL(), decodeFrom(), htmlSanitize() with AntiSamy, and context-aware output encoding to prevent XSS/injection.
---

# bx-esapi: OWASP ESAPI Security Module

## Installation

```bash
install-bx-module bx-esapi
# CommandBox
box install bx-esapi
```

## Encoding BIFs

| BIF | Description |
|-----|-------------|
| `encodeFor( context, value )` | Encode for a named context (see list below) |
| `encodeForHTML( value, [canonicalize] )` | Encode for HTML body content |
| `encodeForHTMLAttribute( value, [canonicalize] )` | Encode for HTML attribute values |
| `encodeForJavaScript( value, [canonicalize] )` | Encode for inline JavaScript |
| `encodeForCSS( value, [canonicalize] )` | Encode for CSS values |
| `encodeForURL( value, [canonicalize] )` | URL-encode a value |
| `encodeForSQL( value, dialect, [canonicalize] )` | Encode for SQL contexts |
| `encodeForXML( value, [canonicalize] )` | Encode for XML content |
| `encodeForXMLAttribute( value, [canonicalize] )` | Encode for XML attribute values |
| `encodeForXPath( value, [canonicalize] )` | Encode for XPath queries |
| `encodeForLDAP( value, [canonicalize] )` | Encode for LDAP queries |
| `encodeForDN( value, [canonicalize] )` | Encode for LDAP Distinguished Names |

### Available `encodeFor()` Contexts

`CSS`, `DN`, `HTML`, `HTMLAttribute`, `JavaScript`, `LDAP`, `SQL`, `URL`, `XML`, `XMLAttribute`, `XPath`

## Output Encoding (XSS Prevention)

```html
<!-- HTML body -->
<bx:output>
    <h2>#encodeForHTML( user.displayName )#</h2>
    <p>#encodeForHTML( user.bio )#</p>
</bx:output>

<!-- HTML attribute -->
<bx:output>
    <a href="#encodeForHTMLAttribute( user.profileUrl )#">Profile</a>
    <img src="/img/avatar.png" alt="#encodeForHTMLAttribute( user.displayName )#" />
</bx:output>

<!-- Inline JavaScript -->
<bx:output>
    <script>
        var username = "#encodeForJavaScript( user.username )#";
        var userId   = #encodeForJavaScript( user.id )#;
    </script>
</bx:output>

<!-- URL parameters -->
<bx:output>
    <a href="/search?q=#encodeForURL( form.searchTerm )#">Search</a>
</bx:output>
```

## Generic `encodeFor()`

```javascript
// Using the generic BIF
safeHtml    = encodeFor( "HTML", user.comment )
safeJs      = encodeFor( "JavaScript", user.name )
safeUrl     = encodeFor( "URL", queryParam )
safeAttr    = encodeFor( "HTMLAttribute", user.title )
```

## Decoding BIFs

```javascript
// Decode from specific contexts
decoded = decodeFromHTML( "&lt;script&gt;" )          // Returns: <script>
decoded = decodeFromURL( "hello%20world" )             // Returns: hello world
decoded = decodeFromBase64( encodedString )
decoded = decodeFrom( "HTML", "&lt;p&gt;content&lt;/p&gt;" )
```

## Canonicalization

Canonicalization normalizes encoded input before encoding. Useful to detect double-encoded attacks:

```javascript
// With canonicalize=true: first decodes, then re-encodes
// With canonicalize=false (default): encode as-is
safe = encodeForHTML( userInput, true )
```

## HTML Sanitization with AntiSamy

```javascript
// Sanitize HTML with AntiSamy (built-in safelists)
// Removes dangerous tags while allowing safe formatting
clean = htmlSanitize( userHtmlInput )

// Use specific AntiSamy policy
clean = htmlSanitize( userHtmlInput, "antisamy-slashdot" )
// Policies: antisamy (default), antisamy-slashdot, antisamy-ebay, antisamy-myspace, antisamy-anythinggoes
```

## Common Encoding Patterns

```javascript
// Form output — always encode when displaying user data
function renderUserProfile( user ) {
    return "
        <div class='profile'>
            <h1>#encodeForHTML( user.name )#</h1>
            <p class='bio'>#encodeForHTML( user.bio )#</p>
            <a href='#encodeForHTMLAttribute( user.website )#'>
                #encodeForHTML( user.websiteLabel )#
            </a>
        </div>
    "
}

// URL building
function buildSearchUrl( term, category ) {
    return "/search?q=#encodeForURL( term )#&category=#encodeForURL( category )#"
}
```

## Common Pitfalls

- ❌ Never use `encodeForHTML()` inside JavaScript — use `encodeForJavaScript()` instead
- ❌ Never use `encodeForHTML()` inside HTML attribute values — use `encodeForHTMLAttribute()`
- ✅ Always encode user-supplied data at **output time** in the context where it's used
- ✅ Use `htmlSanitize()` (AntiSamy) when you want to allow SOME HTML but not arbitrary markup
- ❌ `encodeForSQL()` should not replace parameterized queries — use `queryExecute()` with proper params instead
- ✅ Use `canonicalize=true` when processing input that may have been double-encoded
