---
name: bx-ui-forms
description: "Use this skill to render HTML forms in BoxLang using the bx-ui-forms module: bx:form, bx:input, bx:select, bx:slider, bx:textarea components, form actions and methods, preservedata for sticky forms, input types and labels, and styling considerations."
---

# bx-ui-forms: HTML Form Components

## Installation

```bash
install-bx-module bx-ui-forms
# CommandBox
box install bx-ui-forms
```

> Produces semantic, accessible HTML form markup. No JavaScript framework is bundled — styling is entirely up to the developer.

## Components

| Component | Purpose |
|-----------|---------|
| `bx:form` | Outer `<form>` wrapper |
| `bx:input` | Text, email, password, checkbox, radio, and other input fields |
| `bx:select` | Dropdown select element |
| `bx:slider` | HTML5 range slider |
| `bx:textarea` | Multi-line text area |

---

## Basic Form

```html
<bx:form action="/register" method="POST">

    <bx:input
        type="text"
        name="username"
        label="Username"
        required="true"
        placeholder="Enter your username"
    >

    <bx:input
        type="email"
        name="email"
        label="Email Address"
        required="true"
    >

    <bx:input
        type="password"
        name="password"
        label="Password"
        required="true"
    >

    <bx:input type="submit" value="Register">

</bx:form>
```

## Sticky (Preservedata) Form

When `preservedata="true"`, previously submitted values are re-populated in the form fields after a failed submission:

```html
<bx:form action="/profile/update" method="POST" preservedata="true">

    <bx:input type="text"  name="fullName" label="Full Name" value="#form.fullName ?: user.fullName#">
    <bx:input type="email" name="email"    label="Email"     value="#form.email ?: user.email#">

    <bx:input type="submit" value="Save Changes">

</bx:form>
```

## Select Dropdown

```html
<bx:form action="/search" method="GET">

    <bx:input type="text" name="q" label="Search">

    <bx:select name="category" label="Category">
        <option value="">-- All Categories --</option>
        <option value="tech">Technology</option>
        <option value="science">Science</option>
        <option value="health">Health</option>
    </bx:select>

    <bx:input type="submit" value="Search">

</bx:form>
```

## Checkbox and Radio

```html
<bx:form action="/preferences" method="POST">

    <!-- Checkbox -->
    <bx:input
        type="checkbox"
        name="newsletter"
        label="Subscribe to newsletter"
        value="1"
        checked="#user.newsletter eq 1#"
    >

    <!-- Radio buttons -->
    <bx:input type="radio" name="theme" value="light" label="Light Mode">
    <bx:input type="radio" name="theme" value="dark"  label="Dark Mode">

    <bx:input type="submit" value="Save Preferences">

</bx:form>
```

## Textarea

```html
<bx:form action="/contact" method="POST">

    <bx:input type="text" name="subject" label="Subject">

    <bx:textarea
        name="message"
        label="Message"
        rows="8"
        cols="60"
        placeholder="Enter your message here..."
    ></bx:textarea>

    <bx:input type="submit" value="Send Message">

</bx:form>
```

## Slider (Range Input)

```html
<bx:form action="/filter" method="GET">

    <bx:slider
        name="maxPrice"
        label="Max Price: $#url.maxPrice ?: 500#"
        min="0"
        max="1000"
        step="10"
        value="#url.maxPrice ?: 500#"
    >

    <bx:input type="submit" value="Apply Filter">

</bx:form>
```

## File Upload Form

```html
<bx:form action="/upload" method="POST" enctype="multipart/form-data">

    <bx:input type="file" name="attachment" label="Choose File" accept=".pdf,.docx">

    <bx:input type="submit" value="Upload">

</bx:form>
```

## Hidden Fields and CSRF Integration

```html
<bx:form action="/delete/item/#item.id#" method="POST">

    <!-- Hidden fields -->
    <bx:input type="hidden" name="itemId"  value="#item.id#">
    <bx:input type="hidden" name="csrf"    value="#CSRFGenerateToken()#">

    <bx:input type="submit" value="Delete" class="btn btn-danger">

</bx:form>
```

## `bx:form` Attribute Reference

| Attribute | Description | Default |
|-----------|-------------|---------|
| `action` | Form submission URL | Current page |
| `method` | HTTP method (`GET` or `POST`) | `POST` |
| `enctype` | Encoding type (use `multipart/form-data` for file uploads) | `application/x-www-form-urlencoded` |
| `preservedata` | Re-populate fields from submitted form data | `false` |
| `id` | HTML `id` attribute | — |
| `class` | CSS class(es) | — |

## Common Pitfalls

- ✅ Use `enctype="multipart/form-data"` for any form that includes file uploads
- ❌ `preservedata` only works in a web runtime context where form scope is populated
- ✅ Always add a CSRF token (`CSRFHiddenField()` or `CSRFGenerateToken()`) via a hidden input for POST forms
- ✅ `bx:ui-forms` produces semantic HTML — wire up your own CSS (Bootstrap, Tailwind, etc.) for styling
- ❌ No built-in client-side validation is added — add HTML5 attributes like `required` and `pattern` yourself
