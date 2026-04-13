# BoxLang Skills

> AI agent skills for [BoxLang](https://boxlang.ortusbooks.com/) — a Modern Dynamic JVM Language built on JRE 21+.

This repository provides reusable **AI skills** for BoxLang development, compatible with any agent that supports the [skills.sh](https://skills.sh) open standard — including Claude Code, Cursor, Copilot, and more.

Skills inject BoxLang domain knowledge directly into your AI agent so it can write accurate, idiomatic BoxLang code for you.

---

## What Are Skills?

Skills are Markdown files (`SKILL.md`) that give your AI agent expert-level context on a specific topic. They are discovered and loaded automatically by the agent when relevant — a query about async programming loads the async skill, a question about deployment loads the deployment skill, and so on.

Each skill in this repo contains:

- Language syntax and idioms with working code examples
- API references and BIF signatures
- Configuration patterns
- Best practices and gotchas

---

## Quick Install

Requires [Node.js](https://nodejs.org) — no installation needed, just `npx`:

```bash
# Install ALL BoxLang skills (all categories)
npx skills add ortus-boxlang/skills
```

That's it. Your AI agent now has BoxLang and CommandBox expertise.

## Claude Plugin Install

Install this repository as a Claude plugin:

```bash
claude plugin install https://github.com/ortus-boxlang/skills
```

If you use plugin marketplace commands:

```bash
/plugin marketplace add ortus-boxlang/skills
/plugin install boxlang-agent-skills@ortus-boxlang
```

---

## Categories

### `boxlang-developer` — Building Applications with BoxLang

For developers writing BoxLang applications: web apps, APIs, database access,
async pipelines, caching, Java interop, module usage, and deployment.

```bash
npx skills add ortus-boxlang/skills/boxlang-developer
```

| Skill | What It Covers |
|-------|----------------|
| [`async-programming`](./boxlang-developer/async-programming/SKILL.md) | `BoxFuture`, `futureNew`, `asyncRun`, `asyncAll`, `asyncAny`, `asyncAllApply`, executors (`io-tasks`/`cpu-tasks`/`scheduled-tasks`), schedulers, `thread` component, `bx:lock` |
| [`best-practices`](./boxlang-developer/best-practices/SKILL.md) | Naming conventions, scoping, function structure, error handling, performance, and maintainability guidelines |
| [`caching`](./boxlang-developer/caching/SKILL.md) | Cache providers, named regions, `cachePut`/`cacheGet`, output caching, Redis, Couchbase, TTL policies, distributed locking |
| [`cfml-migration`](./boxlang-developer/cfml-migration/SKILL.md) | Key syntax and behavioral differences, `bx-compat-cfml` module, converting file types, fixing common migration issues |
| [`classes-and-oop`](./boxlang-developer/classes-and-oop/SKILL.md) | Classes, inheritance, interfaces, abstract classes, properties, constructors, static members, annotations, `final` constructs, method chaining |
| [`code-documenter`](./boxlang-developer/code-documenter/SKILL.md) | Javadoc-style function/class comments, argument and return-type docs, DocBox-compatible annotations |
| [`code-reviewer`](./boxlang-developer/code-reviewer/SKILL.md) | Code quality, correctness, security vulnerabilities, performance, style — structured review feedback |
| [`configuration`](./boxlang-developer/configuration/SKILL.md) | `boxlang.json` runtime settings, datasources, caches, executors, modules, logging, security, schedulers |
| [`database-access`](./boxlang-developer/database-access/SKILL.md) | `queryExecute`, `bx:query`, datasource config, parameterized queries, transactions, stored procedures, SQL injection prevention |
| [`deployment`](./boxlang-developer/deployment/SKILL.md) | CommandBox, Docker, AWS Lambda, GitHub Actions CI/CD, BVM, `boxlang.json` runtime config, environment variable overrides |
| [`docbox`](./boxlang-developer/docbox/SKILL.md) | API documentation generation: CLI, HTML/JSON/UML/CommandBox strategies, themes, multiple sources, custom strategies |
| [`file-handling`](./boxlang-developer/file-handling/SKILL.md) | `fileRead`/`fileWrite`/`fileCopy`/`fileMove`, directory operations, streaming large files, file uploads, CSV/JSON from disk |
| [`functional-programming`](./boxlang-developer/functional-programming/SKILL.md) | Closures (`=>`) vs lambdas (`->`), higher-order functions, `map`/`filter`/`reduce`/`flatMap`/`groupBy`, destructuring, spread |
| [`interceptors`](./boxlang-developer/interceptors/SKILL.md) | Interceptor/event system, `announce()`/`announceAsync()`, pre/post hooks, security guards, `BoxRegisterInterceptor()` |
| [`java-integration`](./boxlang-developer/java-integration/SKILL.md) | `createObject`, static method calls, type conversion, closures as functional interfaces, JARs, JSR-223 scripting |
| [`language-fundamentals`](./boxlang-developer/language-fundamentals/SKILL.md) | File types (`.bx`/`.bxs`/`.bxm`), variables, scopes, operators, control flow, exception handling, type system, destructuring, spread |
| [`modules-and-packages`](./boxlang-developer/modules-and-packages/SKILL.md) | `box install`, module config, BoxLang+ premium modules (`bx-pdf`, `bx-redis`, `bx-csv`, `bx-spreadsheet`), ORM, mail |
| [`running-boxlang`](./boxlang-developer/running-boxlang/README.md) | 16 deployment-target sub-skills: CLI scripting, MiniServer, CommandBox, Docker, AWS Lambda, GCF, Spring Boot, WASM, MatchBox, native binaries, and more |
| [`security`](./boxlang-developer/security/SKILL.md) | OWASP Top 10, injection prevention, file upload safety, secret management, secure coding patterns |
| [`templating`](./boxlang-developer/templating/SKILL.md) | `.bxm` markup files, output expressions, `bx:output`/`bx:loop`/`bx:if`/`bx:include`/`bx:script`, building views |
| [`testing`](./boxlang-developer/testing/SKILL.md) | TestBox BDD (`describe`/`it`), xUnit, expectations, `$assert`, life-cycle hooks, MockBox, mock data, async/exception testing |
| [`web-development`](./boxlang-developer/web-development/SKILL.md) | `Application.bx` lifecycle, request/response, sessions, forms, REST APIs, HTTP client, CSRF, Server-Sent Events, MiniServer config |
| [`zip`](./boxlang-developer/zip/SKILL.md) | `bx:zip` component: creating/extracting/listing/modifying archives, compression levels, encryption, backup workflows |

### `boxlang-core-development` — Extending the BoxLang Runtime

For developers building BoxLang modules, contributing to the core runtime, and
creating custom built-in functions, interceptors, and components.

```bash
npx skills add ortus-boxlang/skills/boxlang-core-development
```

| Skill | What It Covers |
|-------|----------------|
| [`async-tasks`](./boxlang-core-development/async-tasks/SKILL.md) | `BoxFuture`, `AsyncService`, executor types, `BaseScheduler`, `ScheduledTask` fluent API, cron constraints, task lifecycle callbacks, registering schedulers via `ModuleConfig.bx` |
| [`bif-development`](./boxlang-core-development/bif-development/SKILL.md) | `@BoxBIF` annotation, `invoke()` method, argument typing, `@BoxMember` for member functions, Java BIF classes, runtime service access |
| [`component-development`](./boxlang-core-development/component-development/SKILL.md) | Custom tags/components, `onStartTag`/`onEndTag`, body content, attribute declarations, registering component paths in modules |
| [`interceptors`](./boxlang-core-development/interceptors/SKILL.md) | Observer/Intercepting Filter patterns, 3 interceptor pools, BoxLang/Java/lambda interceptors, registration, interception points, custom events |
| [`logging`](./boxlang-core-development/logging/SKILL.md) | `LoggingService`, `BoxLangLogger` (trace/debug/info/warn/error), pre-configured loggers, named loggers, parameterized messages, `boxlang.json` logging config |
| [`module-development`](./boxlang-core-development/module-development/SKILL.md) | `ModuleConfig.bx` lifecycle (`configure`/`onLoad`/`onUnload`), settings, Gradle build, ForgeBox publishing |
| [`runtime-architecture`](./boxlang-core-development/runtime-architecture/SKILL.md) | `BoxRuntime` services, `IBoxContext` hierarchy, scope chain, `DynamicObject`, type system, parsing pipeline (source → AST → bytecode), virtual threads |

---

### `commandbox` — CommandBox CLI, Package Manager & Embedded Server

For developers using [CommandBox](https://www.ortussolutions.com/products/commandbox) — the CFML/BoxLang CLI, package manager,
and embedded Undertow server from Ortus Solutions.

```bash
npx skills add ortus-boxlang/skills/commandbox
```

| Skill | What It Covers |
|-------|----------------|
| [`commandbox-setup`](./commandbox/commandbox-setup/SKILL.md) | Installation (macOS/Linux/Windows/Homebrew), upgrading, Java configuration, `commandbox.properties`, light vs thin binaries |
| [`commandbox-usage`](./commandbox/commandbox-usage/SKILL.md) | CLI commands, named/positional parameters, flags, system settings (`${VAR:default}`), env vars, backtick expressions, piping, recipes, REPL, aliases, exit codes, `watch` |
| [`commandbox-package-management`](./commandbox/commandbox-package-management/SKILL.md) | `box.json` schema, ForgeBox / Git / HTTP / folder / S3 / Gist / Java endpoints, semver ranges, dependencies vs devDependencies, lock files, package scripts, artifacts cache, publishing |
| [`commandbox-embedded-server`](./commandbox/commandbox-embedded-server/SKILL.md) | Undertow server configuration via `server.json`, server profiles, JVM/heap settings, SSL/TLS, URL rewrites, server rules, multi-site support, basic auth, aliases, OS service, server scripts |
| [`commandbox-task-runners`](./commandbox/commandbox-task-runners/SKILL.md) | Task CFC anatomy, lifecycle events, interactive jobs DSL, progress bars, ANSI print helpers, threading/async, file watching, running sub-commands, property files, ad-hoc JARs/modules |
| [`commandbox-developing`](./commandbox/commandbox-developing/SKILL.md) | Custom commands, namespace conventions, parameter annotations, WireBox DI, module structure, `ModuleConfig.cfc`, interceptors, core interception points, injection DSL, sharing/publishing |
| [`commandbox-config-settings`](./commandbox/commandbox-config-settings/SKILL.md) | Global config management, `config set/show/clear`, server defaults, ForgeBox API token, custom endpoints, proxy settings, env var overrides (`box_config_*`), setting sync |
| [`commandbox-deploying`](./commandbox/commandbox-deploying/SKILL.md) | Production `server.json`, Docker (`ortussolutions/commandbox`), GitHub Actions (`setup-commandbox`), Heroku/Dokku buildpack, Amazon Lightsail/VPS, systemd service, CFConfig integration |
| [`commandbox-testing`](./commandbox/commandbox-testing/SKILL.md) | `testbox run` flags, `box.json` testbox config, test watcher, CI integration, output formats, code coverage, TestBox CLI patterns |

---

## Install Individual Skills

```bash
# Single skill from boxlang-developer
npx skills add ortus-boxlang/skills/boxlang-developer/language-fundamentals
npx skills add ortus-boxlang/skills/boxlang-developer/async-programming
npx skills add ortus-boxlang/skills/boxlang-developer/web-development
npx skills add ortus-boxlang/skills/boxlang-developer/database-access
npx skills add ortus-boxlang/skills/boxlang-developer/caching
npx skills add ortus-boxlang/skills/boxlang-developer/java-integration
npx skills add ortus-boxlang/skills/boxlang-developer/modules-and-packages
npx skills add ortus-boxlang/skills/boxlang-developer/deployment
npx skills add ortus-boxlang/skills/boxlang-developer/classes-and-oop
npx skills add ortus-boxlang/skills/boxlang-developer/functional-programming

# Single skill from boxlang-core-development
npx skills add ortus-boxlang/skills/boxlang-core-development/module-development
npx skills add ortus-boxlang/skills/boxlang-core-development/bif-development
npx skills add ortus-boxlang/skills/boxlang-core-development/interceptors
npx skills add ortus-boxlang/skills/boxlang-core-development/component-development
npx skills add ortus-boxlang/skills/boxlang-core-development/runtime-architecture

# Single skill from commandbox
npx skills add ortus-boxlang/skills/commandbox/commandbox-setup
npx skills add ortus-boxlang/skills/commandbox/commandbox-usage
npx skills add ortus-boxlang/skills/commandbox/commandbox-package-management
npx skills add ortus-boxlang/skills/commandbox/commandbox-embedded-server
npx skills add ortus-boxlang/skills/commandbox/commandbox-task-runners
npx skills add ortus-boxlang/skills/commandbox/commandbox-developing
npx skills add ortus-boxlang/skills/commandbox/commandbox-config-settings
npx skills add ortus-boxlang/skills/commandbox/commandbox-deploying
npx skills add ortus-boxlang/skills/commandbox/commandbox-testing
```

---

## Managing Skills

```bash
# List installed skills
npx skills list

# Update all skills to latest
npx skills update

# Remove a skill
npx skills remove boxlang-language-fundamentals

# Search for skills
npx skills find boxlang
```

---

## Direct / Manual Installation

If you prefer not to use the `npx skills` CLI — or if you are adding skills to a tool that supports its own marketplace or custom knowledge files — you can download individual `SKILL.md` files directly from this repository and place them wherever your tool expects them.

### Claude Projects (Support Files)

[Claude Projects](https://support.anthropic.com/en/articles/9517075-what-are-projects) let you attach files as **project knowledge** that Claude reads at the start of every conversation. Add any `SKILL.md` from this repo as a support file to give Claude deep BoxLang expertise without any CLI tooling.

1. Open the Project in Claude.ai → **Project Knowledge** → **Add content**
2. Paste the raw content of the skill file you want, e.g.:
   - `boxlang-developer/language-fundamentals/SKILL.md`
   - `boxlang-developer/web-development/SKILL.md`
   - `boxlang-core-development/module-development/SKILL.md`
   - `commandbox/commandbox-embedded-server/SKILL.md`
   - `commandbox/commandbox-package-management/SKILL.md`

Raw file URLs follow this pattern:

```
https://raw.githubusercontent.com/ortus-boxlang/skills/main/<category>/<skill>/SKILL.md
```

Example:

```
https://raw.githubusercontent.com/ortus-boxlang/skills/main/boxlang-developer/language-fundamentals/SKILL.md
```

### Claude Code (`.claude/` directory)

[Claude Code](https://docs.anthropic.com/en/docs/claude-code) automatically picks up Markdown files placed in `.claude/skills/` inside your project. Copy any `SKILL.md` directly:

To install this repo as a Claude Code plugin marketplace, use the `/plugin` command:

```bash
/plugin marketplace add ortus-boxlang/skills
/plugin install boxlang-agent-skills@boxlang-agent-skills
```

Or add a single skill file manually:

```bash
# Add a single skill manually
mkdir -p .claude/skills
curl -o .claude/skills/boxlang-language-fundamentals.md \
  https://raw.githubusercontent.com/ortus-boxlang/skills/main/boxlang-developer/language-fundamentals/SKILL.md
```

Or use the `npx skills` CLI which handles this automatically (see **Quick Install** above).

### Other Marketplaces & Manual Placement

| Tool | Where to place the skill file |
|------|-------------------------------|
| Claude Code | `.claude/skills/<name>.md` (project) or `~/.claude/skills/<name>.md` (global) |
| Cursor | `.cursor/rules/<name>.mdc` |
| GitHub Copilot | append to `.github/copilot-instructions.md` |
| OpenHands | `.openhands/instructions.md` |
| Codex | `.codex/<name>.md` |
| Windsurf | `.windsurf/rules/<name>.md` |

---

## Supported Agents

The `npx skills` CLI detects which agents you have installed and places skills in the right location automatically:

| Agent | Skills Location |
|-------|----------------|
| Claude Code | `~/.claude/skills/` (personal) or `.claude/skills/` (project) |
| Cursor | `.cursor/rules/` |
| GitHub Copilot | `.github/copilot-instructions.md` |
| OpenHands | `.openhands/` |
| Codex | `.codex/` |
| Windsurf | `.windsurf/rules/` |

For manual placement and Claude Project support files, see **Direct / Manual Installation** above.

---

## About BoxLang

[BoxLang](https://boxlang.ortusbooks.com/) is a modern, dynamic JVM language (JRE 21+) designed for rapid application development. It features:

- **Multi-runtime deployment** — web servers, CLI scripts, AWS Lambda, Docker, WASM, Spring Boot, Android
- **Complete Java interoperability** — use any Java library directly, compile to Java bytecode
- **Modern language features** — lambdas, closures, destructuring, spread syntax, optional chaining, virtual threads
- **CFML compatibility** — migrate existing ColdFusion/Lucee applications via `bx-compat-cfml`
- **Rich module ecosystem** — PDF, Redis, CSV, spreadsheets, ORM, LDAP, mail, image processing, and more
- **Open source** — Apache 2.0 license, commercially supported by [Ortus Solutions](https://www.ortussolutions.com/)

---

## Resources

| Resource | Link |
|----------|------|
| BoxLang Documentation | https://boxlang.ortusbooks.com/ |
| BoxLang GitHub | https://github.com/ortus-boxlang/BoxLang |
| CommandBox Documentation | https://commandbox.ortusbooks.com/ |
| CommandBox GitHub | https://github.com/Ortus-Solutions/commandbox |
| Module Template | https://github.com/ortus-boxlang/boxlang-module-template |
| ForgeBox (packages) | https://forgebox.io |
| Ortus Community | https://community.ortussolutions.com/ |
| BoxLang Slack | https://boxlang.io/slack |
| skills.sh | https://skills.sh |

---

## Contributing

Contributions are welcome! To add or improve a skill:

1. Fork this repository
2. Create or edit the relevant `SKILL.md` file
3. Verify the frontmatter has a `name` and `description`
4. Submit a pull request

Skills should contain accurate, working code examples verified against the [BoxLang documentation](https://boxlang.ortusbooks.com/).
