---
name: bx-markdown
description: "Use this skill when converting Markdown to HTML or HTML to Markdown in BoxLang using the bx-markdown module. Covers markdown() and HtmlToMarkdown() BIFs."
---

# bx-markdown: Markdown Support

## Installation

```bash
install-bx-module bx-markdown
# CommandBox
box install bx-markdown
```

## BIFs

### `markdown( txt )` — Markdown → HTML

Converts a Markdown string to HTML using the [Flexmark](https://github.com/vsch/flexmark-java) library.

```javascript
html = markdown( "# Hello World" )
// Returns: <h1>Hello World</h1>

html = markdown( "**Bold** and _italic_ text" )
// Returns: <p><strong>Bold</strong> and <em>italic</em> text</p>

// Multi-line markdown
content = "
# Title

A paragraph with **bold** text.

- Item one
- Item two
- Item three
"
html = markdown( content )
```

### `HtmlToMarkdown( markup )` — HTML → Markdown

Converts an HTML string to Markdown.

```javascript
md = HtmlToMarkdown( "<h1>Hello World</h1>" )
// Returns: # Hello World

md = HtmlToMarkdown( "<p><strong>Bold</strong> and <em>italic</em></p>" )
// Returns: **Bold** and _italic_

// Convert a full HTML page body to Markdown
body = "<h2>Section</h2><p>Content with a <a href='https://boxlang.io'>link</a>.</p>"
md = HtmlToMarkdown( body )
```

## Common Usage Patterns

```javascript
// Render user-authored markdown content safely
post = queryExecute( "SELECT content FROM posts WHERE id = :id", { id: postId }, { returntype: "array" } )
renderedHtml = markdown( post[1].content )
writeOutput( renderedHtml )

// Store HTML from markdown in DB
rawMarkdown = form.postContent
storedHtml  = markdown( rawMarkdown )
queryExecute(
    "INSERT INTO posts (markdown_content, html_content) VALUES (:md, :html)",
    { md: rawMarkdown, html: storedHtml }
)

// Read markdown from a file and render
content = fileRead( "/app/docs/readme.md" )
html = markdown( content )
```

## Common Pitfalls

- ✅ `markdown()` returns an HTML fragment, not a full HTML document — embed it inside your page layout
- ❌ Don't output user-provided markdown directly without sanitizing the resulting HTML (consider pairing with `bx-jsoup` for XSS protection)
- ✅ `HtmlToMarkdown()` is useful for migrating rich-text editor content to a markdown-based system
