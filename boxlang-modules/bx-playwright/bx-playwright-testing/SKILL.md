---
name: bx-playwright-testing
description: "Use this skill when writing browser tests with bx-playwright in BoxLang: TestBox's BrowserSpec (testbox.system.BrowserSpec, browse(), this.playwright(), browserProfile and baseURL annotations), the TestBox browser matchers (toSee, toHaveTitle, toHavePath, toHaveURL, toHaveText, toBeVisible, toBeHidden, toHaveCount, toHaveValue), automatic screenshot/trace/video attachments, spec retries and the --failed and --web-server runner options, ColdBox's BrowserTestCase (routeURL, visitRoute, assertRouteIs), logged-in tests with saved sessions, plain TestBox specs with playwright().browse(), artifact policies, debugging with traces, page objects (models.PageObject@playwright), page components, macros, console error and smoke checks, axe-core accessibility audits, and visual regression with assertScreenshotMatches()."
---

# bx-playwright: Testing, Page Objects and Quality

> BoxLang is the AI-native software productivity platform for building, modernizing and running applications, with developers and AI agents working together.

Pick the base class by what you test:

| You test... | Extend | Gives you |
|---|---|---|
| Any web app from TestBox | `testbox.system.BrowserSpec` | `browse()`, bundle browser, browser matchers, attachments |
| A ColdBox app | `coldbox.system.testing.BrowserTestCase` | All of the above plus `routeURL()`, `visitRoute()`, `assertRouteIs()` |
| Older TestBox, or another framework | `testbox.system.BaseSpec` | `playwright( "ci" ).browse()` by hand (see [Plain TestBox](#plain-testbox-fallback)) |

All of them are BoxLang only. When bx-playwright is not installed (or the engine is not BoxLang), browser specs are **skipped** with an install hint, not failed.

## TestBox BrowserSpec (recommended)

```js
// tests/specs/browser/LoginSpec.bx
@baseURL( "http://localhost:8080" )
@browserProfile( "ci" )
class extends="testbox.system.BrowserSpec" {

	function run() {
		describe( "Login", () => {
			it( "signs in", () => {
				browse( ( page ) => {
					page.visit( "/login" )
						.fill( "Email", "luis@ortus.com" )
						.fill( "Password", "secret" )
						.click( "Sign in" )
					expect( page ).toHavePath( "/dashboard" )
					expect( page ).toSee( "Welcome" )
				} )
			} )
		} )
	}

}
```

Class annotations, written as BoxLang annotations above `class` (never inline attributes in `.bx` files):

- `browserProfile`: bx-playwright profiles for the bundle browser, a list such as `ci` or `ci,mobile`.
- `baseURL`: relative `visit()` calls resolve against it. Default: the runner's `--web-server-url` when the runner started a web server, else bx-playwright's own `baseURL` setting or `BX_PLAYWRIGHT_BASEURL`.

How it behaves:

- One browser per bundle, started on first use, closed after the bundle by `closeBrowser()` (it carries `@afterAll`, so your own `beforeAll()` / `afterAll()` need no `super` calls).
- Safety net: when an `afterAll()` throws or a spec calls `abort`, the bundle browser stays open until the next test run that opens a browser, which closes it first. bx-playwright closes any instance still open when the module unloads or the JVM shuts down.
- Every `browse()` call gets fresh pages, each in its own isolated browser context, closed when the callback ends.
- `browse()` returns the callback result.
- Do not use `asyncAll` in suites that browse: browser specs are not thread safe.

### browse()

```js
browse( ( page ) => page.visit( "/" ).assertSee( "Welcome" ) )

// One isolated page (own cookies and storage) per declared argument
browse( ( admin, guest ) => {
	admin.visit( "/admin" )
	guest.visit( "/admin" )
	expect( guest ).notToSee( "Dashboard" )
} )

// Second argument: newContext() options for this call
browse( ( page ) => {
	page.visit( "/" )
}, { viewport : { width : 390, height : 844 }, timeouts : { assertion : 2000 } } )
```

### this.playwright() and browserAvailable()

```js
pw = this.playwright()            // the bundle manager (closed for you after the bundle)
ctx = pw.newContext()             // manual contexts when browse() is not enough
// playwright() without `this.` is the bx-playwright BIF: a NEW manager the bundle does not close

it( title = "needs a browser", skip = !browserAvailable(), body = () => { ... } )
```

### Browser Matchers

Registered automatically for `BrowserSpec` and `BrowserTestCase` bundles. In any other BoxLang spec: `addMatchers( new testbox.system.browser.BrowserMatchers() )`.

| Matcher | Target | Checks |
|---|---|---|
| `toHaveTitle( title )` | page | Exact title, or a `page.regex()` |
| `toHaveURL( url )` | page | Full URL, or a `page.regex()` |
| `toHavePath( path )` | page | URL path only (ignores scheme, host, query, hash), case sensitive |
| `toSee( text )` | page or locator | Visible text (like `assertSee()`) |
| `toHaveText( text )` | locator | Exact text of the first element (whitespace normalized), or regex |
| `toBeVisible()` | locator | First element visible |
| `toBeHidden()` | locator | First element hidden or absent |
| `toHaveCount( count )` | locator | Exact number of matches |
| `toHaveValue( value )` | locator | Input, textarea or select value, or regex |

Every matcher has a `not` form (`notToSee`, `notToHaveCount`, `notToBeVisible`, ...).

```js
expect( page ).toHaveTitle( "Dashboard" )
expect( page ).toHaveTitle( page.regex( "^Dash" ) )
expect( page ).toHaveURL( "http://localhost:8080/dashboard?tab=1" )
expect( page ).toHavePath( "/dashboard" )
expect( page ).toSee( "Welcome" )
expect( page ).notToSee( "Error" )
expect( page.locator( "h1" ) ).toHaveText( "Todos" )
expect( page.locator( ".todo" ) ).toHaveCount( 3 )
expect( page.locator( "@spinner" ) ).toBeHidden()
expect( page.locator( "@error" ) ).notToBeVisible()
expect( page.locator( "#email" ) ).toHaveValue( "luis@ortus.com" )
```

- They are web-first: they retry until they pass or the bx-playwright assertion timeout (`timeouts.assertion`, 5000 ms) expires. Negated forms wait too. Never `sleep()` before them.
- A failure is a TestBox failure that carries bx-playwright's message (expected, received, call log).
- A matcher refuses values that are not bx-playwright pages or locators, except `toHavePath()`, which falls back to TestBox's Data Navigator `toHavePath()` for structs and other data.
- bx-playwright's own inline assertions (`page.assertSee()`, `page.expect().toHaveText()`) also work in specs: `Playwright.AssertionFailed` counts as a spec **failure** (other `Playwright.*` errors count as errors).

### Automatic Attachments

When a `browse()` callback throws, its contexts close with `failed = true`, so the artifact policies keep their files, and the kept screenshots, trace and videos are attached to the spec with `attach()` (types `screenshot`, `trace`, `video`). The exception is rethrown unchanged. Reporters list attachments: JSON report, links in the Simple report, `[[ATTACHMENT|path]]` lines in JUnit `<system-out>`, and text/console/stream output under failed specs.

Turn artifacts on with a profile (`@browserProfile( "ci" )`) or per call:

```js
browse( ( page ) => { ... }, {
	artifacts : { screenshot : "only-on-failure", trace : "retain-on-failure", video : "retain-on-failure" }
} )
```

Attach your own files from any spec: `attach( path, type = "file", name = "" )`, for example `attach( logPath, "log" )`.

### Retries, --failed and --web-server

```js
it( title = "flaky checkout", retries = 2, body = () => { ... } )      // spec wins
@retries( 1 )                                                         // bundle annotation, above class
class extends="testbox.system.BrowserSpec" { ... }
```

```bash
./testbox/run --directory=tests.specs.browser --retries=2       # global default
./testbox/run --failed                                          # rerun only what failed last run
./testbox/run --web-server="boxlang-miniserver --port 8080" \
              --web-server-url=http://localhost:8080 --web-server-timeout=60
```

- Precedence: `it( ..., retries )` > bundle `retries` annotation > `--retries`. A retry reruns `beforeEach()`, body and `afterEach()`. Skipped specs are never retried. Output shows "(passed after N attempts)".
- `--failed` reads `{reportpath}/.testbox-failed.json`, which every run writes. Bundles that failed outside of a spec (`beforeAll()`, `afterAll()`) are listed under `bundleErrors` and never rerun: fix them and run them directly. In the web runner, the HTML reports offer a **Run Failed (N)** button instead, built from the report (no state). Both use `TestResult.getFailedTargets()`.
- `--web-server` starts the command, waits until `--web-server-url` answers (status below 500), runs the tests, then stops the server and its child processes. It exits with code 1 when the server does not answer in time. The URL becomes the default `baseURL` of `BrowserSpec` bundles.

## ColdBox BrowserTestCase

It loads your ColdBox app like any integration test (`appMapping`, `webMapping`, `configMapping`, ...) and drives a real browser against the running app. Everything in the BrowserSpec section above applies.

```js
@appMapping( "/root" )
@baseURL( "http://127.0.0.1:8080" )
@browserProfile( "ci" )
class extends="coldbox.system.testing.BrowserTestCase" {

	function beforeAll() {
		super.beforeAll()
		// Log in once through the real login page, reused by browse( ..., { session : "admin" } )
		this.playwright().session( "admin", ( page ) => {
			visitRoute( page, "login" )
				.fill( "Email", "admin@example.com" )
				.fill( "Password", getSystemSetting( "TEST_ADMIN_PASSWORD" ) )
				.click( "Sign in" )
		} )
	}

	function run() {
		describe( "Users", () => {
			it( "shows a user to an admin", () => {
				browse( ( page ) => {
					visitRoute( page, "users.show", { id : 5 } )
					assertRouteIs( page, "users.show" )
					expect( page ).toSee( "User 5" )
				}, { session : "admin" } )
			} )
		} )
	}

}
```

| Helper | Does |
|---|---|
| `routeURL( name, params = {} )` | Path of a named route (no scheme or host), built by `event.route()`. Module routes: `name@module` or `module:name`. Throws `InvalidArgumentException` for unknown routes |
| `visitRoute( page, name, params = {} )` | `page.visit( routeURL( name, params ) )`, returns the page. Needs no browser support itself: pages come from `browse()` |
| `assertRouteIs( page, name, params = {} )` | Waits for the page to be on the route. No params: any placeholder value matches, and a route with optional placeholders (`/posts/:id?`) matches with and without them. With params: the exact path. Ignores case, trailing slash, query and hash. Fails with `TestBox.AssertionFailed` |

```js
routeURL( "users.show", { id : 5 } )    // /users/5/
routeURL( "home@blog" )                 // /blog/home/
assertRouteIs( page, "users.show", { id : 5 } )
```

### Logged-In Tests: Saved Sessions

ColdBox has no test-only login endpoints (no backdoor). Log in once through your real login page with `this.playwright().session( name, setup, options )`, then start any `browse()` already logged in with `{ session : name }`:

- The setup page always starts clean; cookies and local storage are saved under the name in the bx-playwright home (`{home}/sessions`, outside the project: never commit them).
- The session is reused until it is stale: `maxAge` (minutes, default `0` = never expires) or `refresh : true` logs in again. Keep `maxAge` below the app session timeout.
- One session per role (`"admin"`, `"editor"`); pages of a `browse()` without the option start logged out, and every page has its own cookies.
- Seed dedicated test users; read passwords from environment variables or CI secrets.
- Test logout like users do: click the link, then `assertRouteIs( page, "login" )`.

## Plain TestBox (fallback)

Use when `BrowserSpec` is not available (older TestBox) or in another framework. You manage the manager and artifacts yourself.

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

bx-playwright's `browse()` closes the context with `failed = true` when the callback throws, so failure artifacts are kept (but not attached to the spec).

## Artifacts

Policies for `screenshot`, `trace`, `video`: `off`, `on`, `only-on-failure`, `retain-on-failure`. Set them with the `artifacts` setting, a profile (`ci`, `record`, `debug`) or per context:

```js
ctx  = pw.newContext( { artifacts : { trace : "retain-on-failure", screenshot : "only-on-failure", video : "retain-on-failure" } } )
page = ctx.newPage()
// ...
kept = ctx.close( failed = true )   // { screenshots : [], trace : "path.zip", videos : [], directory }
```

View traces: `bxPlaywright show-trace path/trace.zip`. Debug: `playwright( "debug" )` or `@browserProfile( "debug" )` (headed, slowMo, all artifacts), `BX_PLAYWRIGHT_HEADLESS=false`, `page.snapshot()`, `bxPlaywright codegen <url>`.

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
- A mismatch throws `Playwright.AssertionFailed` (a spec failure in TestBox) and writes `<name>-actual.png` and `<name>-diff.png`.
- Options: `threshold` (0.2), `maxDiffPixels`, `maxDiffPixelRatio`, `mask`, `directory`, screenshot options. Use the `screenshot` profile for stable images.
