---
name: bx-mail
description: Use this skill when sending email in BoxLang with the bx-mail module: bx:mail component, attachments with bx:mailparam, multipart emails with bx:mailpart, SMTP configuration in boxlang.json, S/MIME signing and encryption, and server-level mail settings.
---

# bx-mail: Email Sending

## Installation

```bash
install-bx-module bx-mail
# CommandBox
box install bx-mail
```

## Simple Email (Script Syntax)

```javascript
bx:mail
    from="sender@example.com"
    to="recipient@example.com"
    subject="Hello from BoxLang!"
{
    writeOutput( "This is the email body." )
}
```

## Email with Inline Options

```javascript
bx:mail
    from="noreply@myapp.com"
    to="user@example.com"
    subject="Your Order Confirmation"
    server="smtp.myapp.com"
    port=587
    username="smtp-user"
    password="smtp-secret"
    useTLS=true
    type="html"
{
    writeOutput( "<h1>Thank you for your order!</h1><p>Order #12345 confirmed.</p>" )
}
```

## Email with File Attachment (`bx:mailparam`)

```javascript
// Template syntax
```

```html
<bx:mail
    from="reports@myapp.com"
    to="manager@example.com"
    subject="Monthly Report"
    mimeAttach="/app/reports/march-2026.pdf"
>
Please find your monthly report attached.
</bx:mail>
```

```javascript
// Script syntax — explicit attachment via bx:mailparam
bx:mail from="reports@myapp.com" to="manager@example.com" subject="Monthly Report" {
    writeOutput( "Please find your monthly report attached." )
    bx:mailparam
        file="/app/reports/march-2026.pdf"
        fileName="March-2026-Report.pdf"
        type="application/pdf"
        disposition="attachment"
}
```

## Multipart Email (Text + HTML + Attachment)

```html
<bx:mail from="app@example.com" to="user@example.com" subject="Welcome!">

    <bx:mailpart type="text">
        Welcome to MyApp! Visit https://myapp.com to get started.
    </bx:mailpart>

    <bx:mailpart type="html">
        <h1>Welcome to MyApp!</h1>
        <p>Click <a href="https://myapp.com">here</a> to get started.</p>
    </bx:mailpart>

    <bx:mailparam
        file="/app/assets/welcome-guide.pdf"
        fileName="Welcome-Guide.pdf"
        type="application/x-pdf"
        disposition="attachment"
    />

</bx:mail>
```

## Custom Headers

```javascript
bx:mail from="app@example.com" to="user@example.com" subject="Reset Password" {
    bx:mailparam name="X-Priority"        value="1"
    bx:mailparam name="X-Mailer"          value="MyApp v2.0"
    bx:mailparam name="List-Unsubscribe"  value="<mailto:unsubscribe@myapp.com>"
    writeOutput( "Click here to reset your password." )
}
```

## SMTP Configuration (boxlang.json)

```json
{
  "modules": {
    "mail": {
      "settings": {
        "mailServers": [
          {
            "smtp": "smtp.sendgrid.net",
            "port": 587,
            "username": "apikey",
            "password": "${SENDGRID_API_KEY}",
            "tls": true,
            "ssl": false
          }
        ]
      }
    }
  }
}
```

## S/MIME Signing

```javascript
bx:mail
    from="sender@example.com"
    to="recipient@example.com"
    subject="Signed Email"
    sign=true
    keystore="/app/certs/keystore.jks"
    keystorePassword="keystorePass"
    keyAlias="myKey"
    keyPassword="keyPass"
{
    writeOutput( "This email is digitally signed." )
}
```

## Common Pitfalls

- ✅ Prefer configuring SMTP in `boxlang.json` over hardcoding server/port/credentials in each `bx:mail` call
- ❌ Don't put plaintext SMTP passwords in source code — use environment variables
- ✅ Use `type="html"` for HTML emails, otherwise the body renders as plain text
- ✅ For multipart emails (text + HTML), use `bx:mailpart` — don't set `type` on the outer `bx:mail`
- ❌ `mimeAttach` only supports a single file — use `bx:mailparam` for multiple attachments
