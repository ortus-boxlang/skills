---
name: bx-pdf
description: "Use this skill when generating PDF documents in BoxLang with the bx-pdf module: bx:document component, headers/footers with bx:documentitem, multi-section PDFs with bx:documentsection, saving to file, capturing PDF as binary variable, encryption, and page settings."
---

# bx-pdf: PDF Generation

## Installation

```bash
install-bx-module bx-pdf
# CommandBox
box install bx-pdf
```

## Components

| Component | Purpose |
|-----------|---------|
| `bx:document` | Outer wrapper — generates the PDF |
| `bx:documentitem` | Header, footer, or page break inside a document |
| `bx:documentsection` | A named section (gets its own bookmark, headers/footers) |

## Generate PDF to File

```html
<bx:document format="pdf" filename="/app/output/report.pdf" overwrite="true">
    <h1>My Report</h1>
    <p>Generated on #dateFormat( now(), "YYYY-MM-DD" )#</p>
</bx:document>
```

## Generate PDF to Binary Variable

```javascript
// Script syntax — capture as variable
bx:document format="pdf" variable="pdfBinary" {
    bx:documentsection name="Summary" {
        writeOutput( "<h1>Executive Summary</h1>" )
        include "/app/views/summary.bxm"
    }
}

// Write to file
fileWrite( "/app/reports/summary.pdf", pdfBinary )
```

## Headers, Footers, and Page Breaks

```html
<bx:document format="pdf" filename="/app/docs/manual.pdf">

    <!-- Global header for all sections -->
    <bx:documentitem type="header">
        <img src="/assets/logo.png" height="40" /> My Company Manual
    </bx:documentitem>

    <!-- Global footer with page numbers -->
    <bx:documentitem type="footer">
        <bx:output>
            Page #bxdocument.currentpagenumber# of #bxdocument.totalpages#
        </bx:output>
    </bx:documentitem>

    <!-- Section 1 -->
    <bx:documentsection name="Introduction">
        <h1>Introduction</h1>
        <p>Welcome to the manual.</p>
    </bx:documentsection>

    <!-- Page break before section 2 -->
    <bx:documentsection name="Chapter 1">
        <h1>Chapter 1</h1>
        <p>Chapter content here.</p>
    </bx:documentsection>

</bx:document>
```

## Include External HTML/Image Sources

```html
<!-- Include from absolute file path -->
<bx:documentsection srcfile="/app/views/chapter1.html">

<!-- Include from URL relative to web root -->
<bx:documentsection src="/views/chapter2.html">

<!-- Include static image -->
<bx:documentsection src="https://example.com/page-to-capture">
```

## Page Layout Options

```javascript
bx:document
    format="pdf"
    filename="/app/reports/landscape.pdf"
    orientation="landscape"   // "portrait" (default) or "landscape"
    pageType="letter"         // "A4", "letter", "legal", etc.
    marginTop=1
    marginBottom=1
    marginLeft=1.25
    marginRight=1.25
    unit="in"                 // "in" (default) or "cm"
    scale=100                 // percentage scale
    fontEmbed=true
{
    writeOutput( "<h1>Landscape Report</h1>" )
}
```

## Encryption & Password Protection

```javascript
bx:document
    format="pdf"
    filename="/app/secure/protected.pdf"
    encryption="128-bit"
    openpassword="openme"
    ownerpassword="adminonly"
{
    writeOutput( "<h1>Confidential</h1>" )
}
```

## Serving PDF to Browser (Web Context)

```javascript
// No filename or variable — streams directly to browser
bx:document format="pdf" saveAsName="invoice-#invoiceId#.pdf" {
    include "/app/views/invoice.bxm"
}
```

## Common Pitfalls

- ✅ Use `overwrite=true` when writing to a file, otherwise you'll get an error if the file exists
- ❌ Streaming to browser (`no filename, no variable`) only works in a web runtime context
- ✅ Use `bx:documentsection` to create bookmarks and control per-section headers/footers
- ❌ `bx:documentitem type="pagebreak"` inserts an explicit break — sections already add breaks automatically
- ✅ Use absolute paths for `srcfile` — relative paths may not resolve correctly in all contexts
- ❌ HTML features like JavaScript, CSS animations, and iframes are not rendered in the PDF
