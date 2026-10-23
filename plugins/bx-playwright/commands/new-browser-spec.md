---
name: bx-playwright-cmd-new-browser-spec
description: Scaffold a TestBox @browser spec for a page or flow. Usage: /bx-playwright:new-browser-spec login flow
category: scaffolding
---

Scaffold a browser test for `$ARGUMENTS`, following the `bx-playwright-testing` skill.

## Decide the spec type

- A ColdBox app (`coldbox` in `box.json` dependencies, or a `config/ColdBox.bx`/`.cfc`): `@browser` + `class extends="coldbox.system.testing.BaseTestCase"`, and use `visitRoute()`, `routeURL()` and `assertRouteIs()` for app routes.
- Anything else: `@browser` + `class extends="testbox.system.BaseSpec"`.

Put it under `tests/specs/browser/` (or the project's existing browser spec folder), named after the flow, such as `LoginSpec.bx`.

## Template (TestBox)

```js
@browser
@baseURL( "http://localhost:8080" )
@browserProfile( "ci" )
class extends="testbox.system.BaseSpec" {

	function run() {
		describe( "Login", () => {
			it( "signs in", () => {
				browse( ( page ) => {
					page.visit( "/login" )
						.fill( "Email", "user@example.com" )
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

## Rules

- Write annotations above `class`, never as inline attributes in `.bx` files.
- Read the app's real routes, labels and text before writing steps. Never invent selectors: prefer labels and visible text, then `@testId`.
- Use the browser matchers (`toSee`, `toHavePath`, `toHaveTitle`, `toHaveText`, `toBeVisible`, `toHaveCount`, `toHaveValue`) instead of reading text and comparing.
- Use the app's real base URL. Drop `@baseURL` when the runner starts the web server (`--web-server`).
- When three or more specs share a page, offer a page object (`models.PageObject@bxplaywright`).
- Run the spec and fix it until it passes. If bx-playwright is not installed, the spec is skipped: run `/bx-playwright:doctor`.
