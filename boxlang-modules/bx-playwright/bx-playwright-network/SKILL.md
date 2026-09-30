---
name: bx-playwright-network
description: "Use this skill when working with the network in bx-playwright: mocking and blocking requests with page.intercept() (respondJson, respond, abort, resume, handle), listening to console, requests, responses, page errors and dialogs, HTTP API testing with playwright().request(), cookies and permissions, and saving/reusing logged-in sessions with playwright().session()."
---

# bx-playwright: Network, APIs and Sessions

## Mock, Block, Modify

```js
page.intercept( "**/api/users" ).respondJson( [ "Luis", "Brad" ] )          // status 200
page.intercept( "**/api/users" ).respondJson( { error : "no" }, 500 )
page.intercept( "**/api/fail" ).respond( 500, "Boom", { "content-type" : "text/plain" } )
page.intercept( "**/*.{png,jpg}" ).abort()
page.intercept( "**/api/**" ).resume( { headers : { "X-Test" : "1" } } )
page.intercept( "**/api/**" ).handle( ( route ) => route.fallback() )     // raw Playwright Route
ctx.intercept( "**/ads/**" ).abort()                                      // every page of a context
```

Terminal methods return the page (or context), so the chain continues: `page.intercept( ... ).respondJson( ... ).visit( "/" )`. Register intercepts before navigating. Patterns: glob, full URL or `page.regex()`.

## Listen

```js
page.onConsole( ( message ) => println( message.type & ": " & message.text ) )   // { type, text, location }
	.onRequest( ( request ) => println( request.method & " " & request.url ) )  // { url, method, resourceType }
	.onResponse( ( response ) => println( response.status ) )                  // { url, status, ok }
	.onPageError( ( error ) => println( error.message ) )                      // { message, stack }
	.onDialog( ( dialog ) => dialog.accept() )                                 // raw Playwright Dialog
```

## API Testing

```js
api = playwright().request( { baseURL : "http://localhost:8080" } )
try {
	response = api.post( "/api/login", { json : { user : "luis" }, headers : { "X-Token" : "abc" }, params : { v : 2 } } )
	api.expect( response ).toBeOK()
	data = response.json()
	missing = api.get( "/api/nope" )          // status 404 does not throw; use failOnStatusCode : true to throw
	println( missing.status() & " " & missing.ok() )
} finally {
	api.close()
}
```

Verbs: `get`, `post`, `put`, `patch`, `delete`. Options: `json`, `form`, `data`, `params`, `headers`, `timeout`, `failOnStatusCode`, `maxRedirects`. Response: `status()`, `ok()`, `url()`, `headers()`, `text()`, `json()`. `context.request()` shares the context cookies.

## Cookies and State

```js
ctx.addCookies( [ { name : "auth", value : "token", url : "http://localhost:8080/" } ] )
ctx.cookies()                     // array of structs
ctx.clearCookies()
ctx.grantPermissions( [ "geolocation" ] )
ctx.setOffline( true )
ctx.saveStorageState( "state.json" )
pw.newPage( { storageState : "state.json" } )
```

## Saved Sessions (log in once)

```js
pw = playwright( { baseURL : "http://localhost:8080" } )
pw.session( "admin", ( page ) => {
	page.visit( "/login" ).fill( "Email", "admin@site.com" ).fill( "Password", "secret" ).click( "Sign in" ).assertPathIs( "/dashboard" )
} )
pw.newPage( { session : "admin" } ).visit( "/admin" ).assertSee( "Admin" )
```

- The setup runs only when the session file is missing, older than `maxAge` minutes, or `refresh : true`.
- Sessions are stored in `{home}/sessions` (they hold cookies; keep them out of the project).
- Using a session that does not exist throws `Playwright.InvalidOption`.
