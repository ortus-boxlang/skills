---
name: bx-playwright-rendering
description: "Use this skill when producing screenshots, PDFs, images or rendered HTML with bx-playwright: one-shot playwright().screenshot(), pdf(), content() and render(), page and locator screenshots, PDF options (format, margin, landscape, header/footer templates), and the bx:playwrightRender component that renders its body to PDF, PNG, JPEG or WebP with Chromium."
---

# bx-playwright: Screenshots, PDFs and Rendering

## One-shot Helpers (start and stop the browser for you)

```js
playwright().screenshot( "https://boxlang.io", "home.png", { fullPage : true } )
playwright().pdf( "https://boxlang.io", "home.pdf", { format : "A4" } )
html  = playwright().content( "https://boxlang.io" )              // HTML after JavaScript
bytes = playwright().render( "<h1>Hi</h1>", { type : "png" } )    // no path: returns bytes
path  = playwright().render( invoiceHtml, { type : "pdf", path : "invoice.pdf", format : "A4", margin : { top : "1cm", bottom : "1cm" } } )
card  = playwright().render( cardHtml, { type : "png", viewport : { width : 1200, height : 630 } } )
```

`render()` options: `type` (pdf, png, jpeg, webp), `path`, `baseURL` (resolves relative assets), `waitFor` (selector), `waitUntil`, `viewport`, `device`, `colorScheme`, plus PDF or screenshot options. Defaults come from the `render` setting.

## From a Page or Locator

```js
page.screenshot( "page.png", { fullPage : true, type : "jpeg", quality : 80 } )
bytes = page.screenshot()                              // no path: bytes
page.locator( "@chart" ).screenshot( "chart.png" )
page.pdf( "page.pdf", { format : "Letter", landscape : true, printBackground : true, margin : { top : "1cm", right : "1cm", bottom : "1cm", left : "1cm" } } )
```

PDF options: `format`, `landscape`, `margin`, `printBackground`, `displayHeaderFooter`, `headerTemplate`, `footerTemplate`, `scale`, `pageRanges`, `width`, `height`, `preferCSSPageSize`. PDFs require Chromium (profile `print`); other browsers throw `Playwright.InvalidOption`.

## bx:playwrightRender Component

```html
<bx:playwrightRender type="pdf" path="invoice.pdf" format="A4" margin="1cm">
	<h1>Invoice #invoice.id#</h1>
</bx:playwrightRender>
```

```js
bx:playwrightRender type="png" variable="card" viewport="1200x630" {
	writeOutput( socialCardHtml )
}
```

- `path` and/or `variable` is required (else `Playwright.InvalidOption`). `variable` receives the path when `path` is set, otherwise the bytes.
- `margin="1cm"` applies to all sides; a struct sets each side. `viewport="WxH"` or a struct.
- Other attributes: `type`, `baseURL`, `waitFor`, `waitUntil`, `format`, `landscape`, `printBackground`, `headerTemplate`, `footerTemplate`, `displayHeaderFooter`, `scale`, `pageRanges`, `fullPage`, `omitBackground`, `quality`, `device`, `colorScheme`, `locale`, `timezone`, `profile`, `options` (struct of extra render options).
