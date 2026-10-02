---
name: bx-playwright-assertions
description: "Use this skill when asserting on web pages with bx-playwright: web-first retrying assertions, the inline style (assertSee, assertTitle, assertPathIs, assertVisible, assertCount, assertValue), the expect() style (toHaveText, toBeVisible, toHaveURL, not()), soft assertions with page.soft(), regex matching, assertion timeouts, and the Playwright.AssertionFailed, Playwright.Timeout and other typed errors."
---

# bx-playwright: Assertions and Errors

> BoxLang is the AI-native software productivity platform for building, modernizing and running applications, with developers and AI agents working together.

Assertions retry until they pass or `timeouts.assertion` (5000 ms) expires. Never sleep before them.

## Inline Style (chainable)

```js
page.assertTitle( "Dashboard" )
	.assertTitleContains( "Dash" )
	.assertSee( "Welcome" )
	.assertDontSee( "Error" )
	.assertPathIs( "/dashboard" )        // ignores host, query and hash
	.assertUrlContains( "user=" )
	.assertVisible( "@menu" )
	.assertMissing( "@spinner" )         // hidden or absent
	.assertText( "#total", "$99" )
	.assertValue( "Email", "luis@ortus.com" )
	.assertChecked( "Remember me" )
	.assertCount( ".todos li", 3 )
	.assertAttribute( "a.docs", "href", "/docs" )
```

Also `assertUrlIs`, `assertNotChecked`, `assertEnabled`, `assertDisabled`. On a locator or component, `assertSee`/`assertDontSee` are scoped to it.

## Expect Style

```js
page.expect( "h1" ).toHaveText( "Welcome" )
page.expect().toHaveTitle( "Home" ).toHaveURL( page.regex( "/home$" ) )
page.expect( "@error" ).not().toBeVisible()
page.locator( ".row" ).expect().toHaveCount( 3 )
playwright().expect( someLocator ).toContainText( "x" )
```

Matchers: `toBeVisible`, `toBeHidden`, `toBeEnabled`, `toBeDisabled`, `toBeChecked`, `toBeEditable`, `toBeEmpty`, `toBeFocused`, `toBeAttached`, `toBeInViewport`, `toHaveText`, `toContainText`, `toHaveValue`, `toHaveCount`, `toHaveAttribute( name, value )`, `toHaveClass`, `toContainClass`, `toHaveId`, `toHaveCSS( name, value )`, `toHaveAccessibleName`, `toHaveRole`, `toMatchAriaSnapshot( yaml )`, page: `toHaveTitle`, `toHaveURL`; API responses: `toBeOK`. `not()` negates only the next matcher. Text and URL matchers accept `page.regex( pattern, "i" )`.

## Soft Assertions

```js
page.soft( ( p ) => {
	p.assertTitle( "Store" ).assertSee( "Buy" )
	p.expect( "h1" ).toHaveText( "Store" )
} )   // throws once: "N soft assertion(s) failed: 1) ... 2) ..."
```

## Timeouts

```js
pw.newPage( { timeouts : { assertion : 10000, action : 15000 } } )
```

## Typed Errors

| Type | Meaning |
|---|---|
| `Playwright.AssertionFailed` | Assertion did not pass in time (message has expected, received and the call log) |
| `Playwright.Timeout` | An action waited too long for its element |
| `Playwright.ActionFailed` | Playwright refused an action |
| `Playwright.InvalidOption` | Bad option, value, method, device or selector; `detail` lists valid values |
| `Playwright.InvalidProfile` | Unknown profile or `extends` loop |
| `Playwright.NotInstalled` | Driver, Node.js, browser or bx-ai missing (`bxPlaywright install`) |

```js
try {
	page.click( "Checkout" )
} catch ( "Playwright.Timeout" e ) {
	println( e.message & " Fix: " & e.detail )
}
```
