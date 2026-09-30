---
name: bx-playwright-browsing
description: "Use this skill when driving a browser from BoxLang with bx-playwright: the playwright() BIF, visit(), browse(), newPage()/newContext(), smart selectors (@testId, CSS, visible text), chainable actions (click, fill, check, select, press, upload), finders (byRole, byText, byLabel), locators (nth, filter, texts), within(), frames, waiting, popups, downloads, evaluate, and cleanup."
---

# bx-playwright: Browsing

## Entry Points

```js
pw   = playwright( { baseURL : "http://localhost:8080" } )   // nothing starts yet
page = pw.visit( "/login" )                                   // new context + page + navigation
page = pw.newPage( { colorScheme : "dark" } )                 // context-level overrides
ctx  = pw.newContext( { locale : "es-ES" } )                  // isolated cookies/storage
page = ctx.newPage()

// Scoped: pages and (if new) the manager are closed afterwards
playwright().browse( ( page ) => page.visit( "https://boxlang.io" ).assertSee( "BoxLang" ) )
playwright().browse( ( alice, bob ) => { /* one isolated page per argument */ } )
```

Cleanup: `page.close()` closes the page and its context; `page.quit()` / `pw.close()` close everything. A manager must stay on the thread that created it.

## Smart Selectors

| Selector | Finds |
|---|---|
| `@name` | `[data-testid=name]` or a page object alias |
| `#id`, `.class`, `input[name=email]`, `ul li`, `h1` | CSS (lowercase tag names only) |
| `//div`, `css=`, `xpath=`, `text=`, `role=button[name="Save"]` | Playwright selectors |
| `ref=e12` | Element ref from an AI snapshot |
| anything else | Visible text: `fill()` tries label, placeholder, then name; `click()` tries button or link name, then exact text |

```js
page.visit( "/login" )
	.fill( "Email", "luis@ortus.com" )      // label
	.fill( "Password", "secret" )           // placeholder
	.check( "Remember me" )
	.select( "@role", "editor" )
	.click( "Sign in" )
```

## Actions (all chainable)

`click( sel, options )`, `dblclick`, `hover`, `focus`, `fill( sel, value )`, `type( sel, text, delay )`, `clear`, `press( key )` or `press( sel, key )`, `check`, `uncheck`, `select( sel, valueOrArray )`, `upload( sel, pathOrArray )`, `drag( from, to )`, `scrollTo`, `visit( url, options )`, `back()`, `forward()`, `reload()`, `setContent( html )`.

On a Locator the selector is optional: `page.byLabel( "Email" ).fill( "a@b.com" )`, `page.locator( "#q" ).press( "Enter" )`.

## Finders and Locators

```js
page.byRole( "button", { name : "Save" } ).click()
page.byText( "Welcome" )
page.byLabel( "Email" ); page.byPlaceholder( "Search" ); page.byTestId( "cart" ); page.byAltText( "Logo" ); page.byTitle( "Help" )
page.frame( "#payment" ).fill( "Card number", "4242..." )

todos = page.locator( ".todos li" )
todos.count()                       // no waiting
todos.texts()                       // array of strings
todos.nth( 2 ).text()               // 1-based!
todos.first(); todos.last(); todos.visible()
todos.filter( { hasText : "Ship" } ).click()
todos.all().each( ( item ) => println( item.text() ) )

page.within( "@cart", ( cart ) => cart.click( "Remove" ).assertSee( "Empty" ) )
```

## Reading and Waiting

`url()`, `title()`, `content()`, `text( sel )`, `html( sel )`, `value( sel )`, `attribute( sel, name )`, `isVisible( sel )`, `evaluate( js, arg )`.

Actions and assertions auto-wait. Explicit waits: `waitFor( sel, "visible|hidden|attached|detached" )`, `waitForText( text )`, `waitForUrl( urlOrGlobOrRegex )`, `waitForLoadState( "networkidle" )`, `wait( ms )` (last resort).

```js
popup = page.waitForPopup( () => page.click( "Open report" ) )
file  = page.waitForDownload( () => page.click( "Export" ), "export.csv" )   // { path, suggestedFilename, url }
```

`evaluate()` calls function strings: use `"() => { statements }"` for statements, `"document.title"` for expressions.

## Emulation

`page.setViewport( 500, 400 )`, `page.emulate( { colorScheme : "dark", media : "print" } )`, `page.freezeTime( "2030-05-01T10:00:00" )`, `page.clock()`.

## Discover

`page.help()`, `page.help( "fill" )`, `playwright().help()` list every method with arguments from the docblocks. `getJava()` returns the raw Playwright object.
