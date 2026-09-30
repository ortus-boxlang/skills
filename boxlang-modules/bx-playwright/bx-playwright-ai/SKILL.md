---
name: bx-playwright-ai
description: "Use this skill when connecting AI agents to a browser with bx-playwright: accessibility snapshots in ai mode with element refs (page.snapshot, ref=e12 selectors), playwright().aiTools() for bx-ai agents, aiToolDefinitions() and models.AiBrowser for other frameworks, the Playwright MCP server (bxPlaywright mcp), recording BoxLang code with bxPlaywright codegen, and API self-description with help()."
---

# bx-playwright: AI Agents

## Snapshots With Element Refs

```js
println( page.snapshot( options = { mode : "ai" } ) )
// - heading "Sign in" [level=1] [ref=e2]
// - textbox "Email" [ref=e5]
// - button "Sign in" [ref=e7]
page.fill( "ref=e5", "luis@ortus.com" ).click( "ref=e7" )
```

`page.snapshot()` without options gives the plain accessibility YAML (also used by `toMatchAriaSnapshot()`). `page.snapshot( "@form" )` limits it to an element.

## Tools for bx-ai Agents

```js
agent = aiAgent(
	name         : "Browser",
	instructions : "Use the browser tools to complete the task. Act on element refs from the snapshots.",
	tools        : playwright( { baseURL : "http://localhost:8080" } ).aiTools()
)
agent.run( "Log in as luis@ortus.com with password secret and tell me how many todos I have" )
```

| Tool | Arguments |
|---|---|
| `browser_visit` | `url` |
| `browser_snapshot` | |
| `browser_click` | `target` (ref like `e12` or button/link text) |
| `browser_fill` | `target`, `value` |
| `browser_select` | `target`, `value` |
| `browser_press` | `key` |
| `browser_back` | |
| `browser_text` | `target` (optional) |
| `browser_screenshot` | `path` |
| `browser_close` | |

Each action returns `URL`, `Title` and the ai snapshot. Errors come back as text (`Error [Playwright.Timeout]: ... Fix: ...`) so the agent can recover. The tools share one page. `aiTools()` throws `Playwright.NotInstalled` without bx-ai.

Other frameworks: `playwright().aiToolDefinitions()` returns `[ { name, description, arguments : { name : description }, handler } ]`. Direct use:

```js
browser = new models.AiBrowser@playwright( playwright() )
state   = browser.visit( "https://boxlang.io" )
state   = browser.click( "Docs" )
browser.close()
```

## MCP and Codegen

- `bxPlaywright mcp` starts Playwright's MCP server for MCP clients (Claude, Cursor, ...).
- `bxPlaywright codegen http://localhost:8080 --output=flow.bxs` records a session and writes bx-playwright code (`page.byRole( "button", { name : "Save" } ).click()` style). Untranslatable lines are kept as `// TODO translate:` comments.

## Self Description

- `page.help()`, `page.help( "fill" )`, `playwright().help()`: methods, arguments and descriptions from the docblocks.
- `bxPlaywright help --json`, `bxPlaywright doctor --json`, `bxPlaywright devices --json`.
- Every error has a `type` and a `detail` with the fix.
