# bx-playwright Skills

Skills for [bx-playwright](https://github.com/ortus-boxlang/bx-playwright): fluent browser automation and testing for BoxLang, powered by Microsoft Playwright.

## Available Skills

| Skill | Load When... |
|-------|--------------|
| [bx-playwright-setup](./bx-playwright-setup/SKILL.md) | Installing, the `bxPlaywright` CLI, module settings, profiles, environment variables, CI |
| [bx-playwright-browsing](./bx-playwright-browsing/SKILL.md) | `playwright()`, `visit()`, smart selectors, actions, locators, waits, popups, downloads |
| [bx-playwright-assertions](./bx-playwright-assertions/SKILL.md) | Inline `assert*()` and `expect()` assertions, soft assertions, typed errors |
| [bx-playwright-network](./bx-playwright-network/SKILL.md) | Mocking with `intercept()`, events, `request()` API testing, saved sessions |
| [bx-playwright-rendering](./bx-playwright-rendering/SKILL.md) | Screenshots, PDFs, `render()`, `content()`, the `bx:playwrightRender` component |
| [bx-playwright-testing](./bx-playwright-testing/SKILL.md) | TestBox `BrowserSpec` and browser matchers, ColdBox `BrowserTestCase` (`visitRoute`, `assertRouteIs`, `loginAs`), retries, artifacts, page objects, components, macros, accessibility, visual regression |
| [bx-playwright-ai](./bx-playwright-ai/SKILL.md) | AI snapshots with refs, `aiTools()` for bx-ai agents, MCP, codegen, `help()` |

## Combining Skills

- **End-to-end tests** → `bx-playwright-testing` (start with `BrowserSpec` or `BrowserTestCase`) + `bx-playwright-browsing` + `bx-playwright-assertions` + `boxlang-dev-boxlang-testing`
- **Scraping or PDF generation** → `bx-playwright-browsing` + `bx-playwright-rendering`
- **Agents that browse** → `bx-playwright-ai` + `bx-ai-agents` + `bx-ai-tools`

## Critical Rules (Apply to All bx-playwright Skills)

- ✅ The entry point is the `playwright()` BIF. Nothing starts until it is used.
- ✅ Every action returns the page (or locator): chain them.
- ✅ Close what you open: `browse()` and the one-shot helpers close for you; otherwise `page.close()` (context) or `page.quit()` / `pw.close()` (everything).
- ✅ Assertions wait (web-first). Never add `sleep()` before them.
- ❌ Do not share a `playwright()` manager across threads. Create one per thread.
- ❌ Do not use `$()` or Playwright Java methods when a DSL method exists; `getJava()` is the escape hatch.
