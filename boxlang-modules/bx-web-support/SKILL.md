---
name: bx-web-support
description: Use this skill for testing web-context code outside a web server in BoxLang with bx-web-support: mockServerGet/Post/Put/Delete/Patch, mockRequestNew, mockRequestRun, setting request headers/body/path, and testing handlers that depend on getHTTPRequestData(), form scope, URL scope, and other web BIFs.
---

# bx-web-support: Web Context Mocking for Testing

## Installation

```bash
install-bx-module bx-web-support
# CommandBox
box install bx-web-support
```

> **IMPORTANT**: This module is for **CLI and testing only**. Do NOT install it in a web runtime — it will cause JAR conflicts with the web server's request handling. It should be installed as a test/development dependency only.

## Purpose

`bx-web-support` lets you simulate HTTP requests and web contexts when running BoxLang scripts in CLI mode or unit tests. This allows you to test handlers and components that rely on web-specific BIFs like `getHTTPRequestData()`, `form`, `url`, `CGI`, and request scopes.

## BIFs

| BIF | Description |
|-----|-------------|
| `mockServerGet( path )` | Create a mock GET request |
| `mockServerPost( path )` | Create a mock POST request |
| `mockServerPut( path )` | Create a mock PUT request |
| `mockServerDelete( path )` | Create a mock DELETE request |
| `mockServerPatch( path )` | Create a mock PATCH request |
| `mockRequestNew()` | Create a blank request builder |
| `mockRequestRun( request )` | Execute the mock request and return a response |

## Fluent Request Builder

All `mockServer*()` BIFs return a fluent request builder with the following methods:

| Method | Description |
|--------|-------------|
| `.setRequestMethod( method )` | Override the HTTP method |
| `.setRequestPath( path )` | Set the request path |
| `.addRequestHeader( name, value )` | Add a request header |
| `.setRequestBody( bodyString )` | Set the request body (JSON, form-encoded, etc.) |
| `.addQueryParam( name, value )` | Add a URL query parameter |
| `.addFormField( name, value )` | Add a form field (for POST) |
| `.run()` | Execute the request and return the response |

---

## Basic Usage

### Simulating a GET Request

```javascript
// Simulate GET /api/users?status=active
response = mockServerGet( "/api/users" )
    .addQueryParam( "status", "active" )
    .addRequestHeader( "Accept", "application/json" )
    .run()

writeOutput( response.statusCode )   // 200
writeOutput( response.body )         // JSON response body
```

### Simulating a POST with JSON Body

```javascript
response = mockServerPost( "/api/users" )
    .addRequestHeader( "Content-Type", "application/json" )
    .addRequestHeader( "Authorization", "Bearer mytoken123" )
    .setRequestBody( serializeJSON({ name: "Alice", email: "alice@example.com" }) )
    .run()

writeOutput( response.statusCode )   // 201
var result = deserializeJSON( response.body )
```

### Simulating a PUT Request

```javascript
response = mockServerPut( "/api/users/42" )
    .addRequestHeader( "Content-Type", "application/json" )
    .setRequestBody( serializeJSON({ name: "Alice Updated" }) )
    .run()
```

### Simulating a Form POST

```javascript
response = mockServerPost( "/login" )
    .addFormField( "username", "alice" )
    .addFormField( "password", "secret123" )
    .addRequestHeader( "Content-Type", "application/x-www-form-urlencoded" )
    .run()
```

---

## Inside the Handler (Web Context Available)

When a mock request is running, the full web context is available inside your handler:

```javascript
// Your handler code (handler.bx)
function handleRequest() {
    var requestData = getHTTPRequestData()   // Contains body, method, headers
    var payload     = deserializeJSON( requestData.content )
    var authHeader  = requestData.headers[ "Authorization" ] ?: ""

    url.status  // Available from query params set via addQueryParam()
    form.name   // Available from form fields set via addFormField()
}
```

---

## Testing in TestBox

```javascript
component extends="testbox.system.BaseSpec" {

    function run() {
        describe( "UsersAPI", () => {

            it( "returns 200 for GET /api/users", () => {
                var response = mockServerGet( "/api/users" )
                    .addRequestHeader( "Accept", "application/json" )
                    .run()

                expect( response.statusCode ).toBe( 200 )
                var body = deserializeJSON( response.body )
                expect( body ).toBeTypeOf( "array" )
            })

            it( "creates a user via POST /api/users", () => {
                var response = mockServerPost( "/api/users" )
                    .addRequestHeader( "Content-Type", "application/json" )
                    .setRequestBody( serializeJSON({ name: "Test User", email: "test@example.com" }) )
                    .run()

                expect( response.statusCode ).toBe( 201 )
                var body = deserializeJSON( response.body )
                expect( body.id ).notToBeEmpty()
            })

            it( "returns 404 for unknown resource", () => {
                var response = mockServerGet( "/api/nonexistent" ).run()
                expect( response.statusCode ).toBe( 404 )
            })

        })
    }
}
```

---

## box.json: Test-Only Dependency

```json
{
  "devDependencies": {
    "bx-web-support": "*"
  }
}
```

## Common Pitfalls

- ❌ **Never install bx-web-support in a production web runtime** — it conflicts with the real web server adapters
- ✅ Install as a dev/test dependency (`devDependencies` in box.json) so it isn't bundled in production
- ✅ Use `mockServerPost` + `addFormField` for simulating form submissions (not `setRequestBody`)
- ✅ Use `mockServerPost` + `setRequestBody` for JSON API requests
- ❌ `mockRequestNew()` creates a blank request with no method or path set — use the named helpers instead
- ✅ The web context (form, url, CGI, getHTTPRequestData) is fully populated during request execution
