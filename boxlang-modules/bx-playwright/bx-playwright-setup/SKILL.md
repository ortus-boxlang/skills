---
name: bx-playwright-setup
description: "Use this skill when installing or configuring bx-playwright (BoxLang browser automation with Playwright): the bx-playwright vs bx-playwright-full distributions, the bxPlaywright CLI (install, doctor, devices, profiles, codegen, show-trace, mcp), module settings in boxlang.json, built-in and custom profiles, BX_PLAYWRIGHT_* environment variables, and CI setup."
---

# bx-playwright: Setup, CLI and Configuration

## Install

Requires BoxLang 1.17+ and Java 21+. Two distributions, same module name (`playwright`) and API:

| Module | Size | Node.js |
|---|---|---|
| `bx-playwright` | ~4 MB | Downloaded by `bxPlaywright install` for the current OS |
| `bx-playwright-full` | ~206 MB | Bundled for every platform (offline) |

```bash
install-bx-module bx-playwright
bxPlaywright install                    # driver + Node.js + Chromium
bxPlaywright install firefox webkit     # more browsers ("all" for every browser)
bxPlaywright install chromium --with-deps   # Linux CI: also OS packages
bxPlaywright doctor                     # check everything, prints fixes
```

Everything lives in `~/.boxlang/playwright` (setting `home` or `BX_PLAYWRIGHT_HOME`).

## CLI

`bxPlaywright <verb>` (same as `boxlang module:playwright <verb>`). `--json` gives machine readable output. Exit code 0 = success.

| Verb | Does |
|---|---|
| `install [browsers...] [--with-deps] [--only-shell] [--force] [--skip-node]` | Driver, Node.js, browsers (default chromium) |
| `install-node [--force]`, `install-deps`, `uninstall [--all]` | Parts of the install |
| `doctor`, `version`, `devices`, `profiles [name]`, `clean` | Inspect and maintain |
| `codegen [url] [--output=file.bxs]` | Record actions as BoxLang code (`--target=java` etc. for other languages) |
| `open [url]`, `screenshot <url> <file>`, `pdf <url> <file>`, `show-trace [zip]`, `mcp`, `run <args>` | Playwright CLI tools |
| `help [verb] [--json]`, `completions` | Help and bash completions |

## Settings (`boxlang.json`)

```json
{
	"modules": {
		"playwright": {
			"settings": {
				"baseURL": "http://localhost:8080",
				"headless": true,
				"timeouts": { "action": 30000, "navigation": 30000, "assertion": 5000 },
				"profiles": { "staging": { "extends": "desktop", "baseURL": "https://staging.example.com" } }
			}
		}
	}
}
```

| Setting | Default | Purpose |
|---|---|---|
| `home`, `browsersPath` | `~/.boxlang/playwright`, `{home}/browsers` | Storage |
| `nodePath`, `nodeVersion`, `nodeDownloadURL` | auto | Node.js resolution and mirror |
| `defaultProfile` | `default` | Profile used by `playwright()` |
| `browser`, `channel`, `headless`, `slowMo` | `chromium`, ``, `true`, `0` | Browser launch |
| `baseURL`, `viewport`, `device`, `locale`, `timezone`, `colorScheme`, `ignoreHTTPSErrors` | | Context |
| `timeouts` | action/navigation 30000, assertion 5000 | Milliseconds |
| `testIdAttribute` | `data-testid` | `@name` selectors |
| `artifacts` | all `off` | `{ directory, screenshot, trace, video }` policies |
| `snapshots` | `{ threshold : 0.2 }` | Visual regression |
| `render` | `{ format : "A4", printBackground : true, waitUntil : "networkidle" }` | Rendering defaults |
| `launchOptions`, `contextOptions` | `{}` | Any raw Playwright option |
| `profiles` | `{}` | Custom profiles |

## Profiles

```js
playwright( "mobile" )                          // iPhone 15, webkit
playwright( [ "android", "dark" ] )             // merged left to right
playwright( "tablet", { locale : "es-ES" } )    // plus overrides
playwright( { headless : false } )              // options only
```

Built-in: `default`, `chromium`, `firefox`, `webkit`, `chrome`, `chrome-beta`, `edge`, `hd`, `laptop`, `macbook`, `desktop`, `4k`, `mobile`/`iphone`, `iphone-se`, `mobile-landscape`, `android`/`pixel`, `galaxy`, `tablet`/`ipad`, `android-tablet`, `dark`, `light`, `reduced-motion`, `high-contrast`, `headed`, `debug`, `record`, `ci`, `offline`, `print`, `screenshot`.

Custom profiles take any setting plus `extends` (a name or a list). A custom profile with a built-in name replaces it.

## Resolution Order (last wins)

1. Module settings
2. Profiles (requested, or `defaultProfile`)
3. Environment: `BX_PLAYWRIGHT_BROWSER`, `BX_PLAYWRIGHT_HEADLESS`, `BX_PLAYWRIGHT_BASEURL`, `BX_PLAYWRIGHT_UPDATE_SNAPSHOTS` (`BX_PLAYWRIGHT_PROFILE` picks the default profile)
4. Options passed to `playwright()`, `newContext()` or `newPage()`

## CI

```bash
install-bx-module bx-playwright
bxPlaywright install chromium --with-deps
BX_PLAYWRIGHT_PROFILE=ci boxlang run-tests.bxs
```

Cache `~/.boxlang/playwright` between runs.
