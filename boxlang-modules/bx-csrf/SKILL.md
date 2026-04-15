---
name: bx-csrf
description: "Use this skill for CSRF (Cross-Site Request Forgery) protection in BoxLang web apps: CSRFGenerateToken(), CSRFVerifyToken(), CSRFHiddenField(), CSRFRotate(), token scoping with keys, auto-verification, token expiration, and boxlang.json configuration."
---

# bx-csrf: CSRF Protection

## Installation

```bash
install-bx-module bx-csrf
# CommandBox
box install bx-csrf
```

## BIFs

| BIF | Description |
|-----|-------------|
| `CSRFGenerateToken( [key], [forceNew] )` | Generate a CSRF token (optionally scoped to a key) |
| `CSRFVerifyToken( token, [key] )` | Verify a CSRF token (returns boolean) |
| `CSRFHiddenField( [key], [forceNew] )` | Generate a ready-to-embed `<input type="hidden">` HTML field |
| `CSRFRotate()` | Rotate/invalidate all current tokens, forcing regeneration |

## Basic Form Protection

```html
<!-- In your form template -->
<form method="POST" action="/submit">
    <!-- Embed the token as a hidden field -->
    <bx:output>#CSRFHiddenField()#</bx:output>
    <!-- Renders: <input type="hidden" name="csrf" value="...token..."> -->

    <input type="text" name="email" />
    <button type="submit">Submit</button>
</form>
```

```javascript
// In your form handler
function processForm() {
    // Verify the submitted token
    if ( !CSRFVerifyToken( form.csrf ) ) {
        throw( type: "Security.CSRFTokenInvalid", message: "Invalid CSRF token" )
    }

    // Safe to process form data
    // ...
}
```

## Scoped Tokens (Per-Form)

Use scoped tokens when you have multiple forms on the same page or need per-action tokens:

```javascript
// Generate a scoped token (named "deleteUser")
token = CSRFGenerateToken( "deleteUser" )

// Verify the scoped token
if ( !CSRFVerifyToken( form.csrf, "deleteUser" ) ) {
    throw( type: "Security.CSRFTokenInvalid", message: "Invalid delete token" )
}
```

```html
<!-- Scoped hidden field -->
<bx:output>#CSRFHiddenField( "deleteUser" )#</bx:output>
```

## AJAX / API Requests (Header-Based)

```javascript
// Client-side: include token in X-CSRF-Token header
// fetch("/api/update", {
//   method: "POST",
//   headers: { "X-CSRF-Token": csrfToken },
//   body: JSON.stringify(data)
// })

// Server-side: auto-verification (configure in boxlang.json)
// Or manually:
if ( !CSRFVerifyToken( getHTTPRequestData().headers[ "X-CSRF-Token" ] ?: "" ) ) {
    throw( type: "Security.CSRFTokenInvalid", message: "Missing or invalid CSRF token" )
}
```

## Token Rotation

```javascript
// Rotate all tokens (e.g., after login/logout)
CSRFRotate()
// All existing tokens are immediately invalidated
// Next call to CSRFGenerateToken() creates a fresh token
```

## Configuration (boxlang.json)

```json
{
  "modules": {
    "csrf": {
      "settings": {
        "cacheStorage"     : "session",   // Cache for token storage (default: session)
        "rotationInterval" : 30,          // Token lifetime in minutes (0 = never expire)
        "timeoutSkew"      : 120,         // Seconds before expiry to force-rotate
        "reapFrequency"    : 1,           // Minutes between expired-token cleanup
        "autoVerify"       : false,       // Auto-verify tokens on state-changing requests
        "headerName"       : "x-csrf-token",
        "verifyMethods"    : ["POST", "PUT", "PATCH", "DELETE"]
      }
    }
  }
}
```

### Auto-Verification

When `autoVerify: true`, every `POST/PUT/PATCH/DELETE` request is automatically checked for a valid CSRF token in the `x-csrf-token` header. No manual verification code needed.

## Common Pitfalls

- ✅ Always include the CSRF token for any state-changing request (POST, PUT, DELETE, PATCH)
- ❌ GET requests should NEVER change state — CSRF protection only applies to non-GET methods
- ✅ Use scoped tokens (`key` param) to differentiate between multiple forms on the same page
- ❌ Don't skip `CSRFRotate()` after login/logout — stale tokens from old sessions are a risk
- ✅ For SPA/AJAX apps, retrieve the token server-side and embed it in the page on initial render
