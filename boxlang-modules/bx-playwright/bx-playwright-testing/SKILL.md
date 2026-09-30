---
name: bx-playwright-testing
description: "Use this skill when writing browser tests with bx-playwright in BoxLang: using it inside TestBox specs, artifact policies (screenshots, traces, videos kept on failure), debugging with the debug profile and trace viewer, page objects (models.PageObject@playwright), page components (models.PageComponent@playwright), macros, console error and smoke checks, axe-core accessibility audits, and visual regression with assertScreenshotMatches()."
---

# bx-playwright: Testing, Page Objects and Quality

## In a Spec

```js
describe( "Login", () => {
	it( "signs in", () => {
		playwright( "ci" ).browse( ( page ) => {
			page.visit( "http://localhost:8080/login" )
				.fill( "Email", "luis@ortus.com" )
				.fill( "Password", "secret" )
				.click( "Sign in" )
				.assertPathIs( "/dashboard" )
		} )
	} )
} )
```

`browse()` closes the context with `failed = true` when the callback throws, so failure artifacts are kept.

## Artifacts

Policies for `screenshot`, `trace`, `video`: `off`, `on`, `only-on-failure`, `retain-on-failure`. Set them with the `artifacts` setting, a profile (`ci`, `record`, `debug`) or per context:

```js
ctx  = pw.newContext( { artifacts : { trace : "retain-on-failure", screenshot : "only-on-failure", video : "retain-on-failure" } } )
page = ctx.newPage()
// ...
kept = ctx.close( failed = true )   // { screenshots : [], trace : "path.zip", videos : [], directory }
```

View traces: `bxPlaywright show-trace path/trace.zip`. Debug: `playwright( "debug" )` (headed, slowMo, all artifacts), `BX_PLAYWRIGHT_HEADLESS=false`, `page.snapshot()`, `bxPlaywright codegen <url>`.

## Page Objects

```js
// pages/LoginPage.bx
class extends="models.PageObject@playwright" {
	url      = "/login"
	elements = { email : "#email", password : "input[type=password]", submit : "button" }

	function at() {
		page.assertTitle( "Login" )          // `page` is the bound Page
	}

	function loginAs( required string email, string password = "secret" ) {
		page.fill( "@email", email ).fill( "@password", password ).click( "@submit" )
		return page.on( new pages.DashboardPage() )
	}
}
```

```js
home = page.visit( new pages.LoginPage() ).loginAs( "luis@ortus.com" )   // visit: navigate + bind + at()
home.assertSee( "Dashboard" )                                             // page methods work on page objects
page.on( new pages.LoginPage() )                                          // bind + at() without navigating
home.element( "heading" ).text()                                          // Locator for an alias
```

`elements` become `@name` selectors on the bound page.

## Components

```js
// pages/UserMenu.bx
class extends="models.PageComponent@playwright" {
	selector = "nav.user"
	elements = { logout : "a.logout" }
	function name() {
		return text( "span" )
	}
}
```

```js
page.within( new pages.UserMenu(), ( menu ) => menu.click( "@logout" ) )
menu = page.component( new pages.UserMenu() )
```

All actions and assertions work on a component, scoped to its root.

## Macros

```js
playwright().macro( "loginAs", ( page, email ) => page.visit( "/login" ).fill( "Email", email ).click( "Sign in" ) )
page.loginAs( "a@b.com" ).assertSee( "Welcome" )                         // return nothing to keep chaining
playwright().macro( "shout", ( locator ) => uCase( locator.text() ), "locator" )
playwright().removeMacro( "loginAs" )
```

Macros are global. Unknown methods throw `Playwright.InvalidOption` listing registered macros.

## Quality Checks

```js
page.assertNoConsoleErrors( [ "favicon.ico" ] )                         // ignore by substring
page.assertNoSmoke( [ "/", "/about", "/pricing" ] )                     // HTTP < 400 and no JS errors, all reported at once
violations = page.accessibility( { tags : [ "wcag2a", "wcag2aa" ] } )   // axe-core: [ { id, impact, help, helpUrl, nodes } ]
page.assertNoAccessibilityIssues( { impact : "serious", exclude : [ "color-contrast" ] } )
```

## Visual Regression

```js
page.assertScreenshotMatches( "dashboard", { fullPage : true, mask : [ "@clock" ] } )
page.locator( "@chart" ).assertScreenshotMatches( "chart", { maxDiffPixelRatio : 0.01 } )
```

- First run (or `update : true`, or `BX_PLAYWRIGHT_UPDATE_SNAPSHOTS=true`) writes the baseline to `tests/snapshots/<name>.png` (setting `snapshots.directory`).
- A mismatch throws `Playwright.AssertionFailed` and writes `<name>-actual.png` and `<name>-diff.png`.
- Options: `threshold` (0.2), `maxDiffPixels`, `maxDiffPixelRatio`, `mask`, `directory`, screenshot options. Use the `screenshot` profile for stable images.
