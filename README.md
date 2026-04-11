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
# Install ALL BoxLang skills (both categories)
npx skills add ortus-boxlang/skills
```

That's it. Your AI agent now has BoxLang expertise.

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
| [`language-fundamentals`](./boxlang-developer/language-fundamentals/SKILL.md) | File types (`.bx`/`.bxs`/`.bxm`), variables, scopes, operators, control flow, exception handling, type system, destructuring, spread syntax |
| [`classes-and-oop`](./boxlang-developer/classes-and-oop/SKILL.md) | Classes, inheritance, interfaces, abstract classes, properties, constructors, static members, annotations, method chaining |
| [`functional-programming`](./boxlang-developer/functional-programming/SKILL.md) | Lambdas, closures, arrow functions, higher-order functions, map/filter/reduce/groupBy/flatMap/zip/chunk/unique and more |
| [`async-programming`](./boxlang-developer/async-programming/SKILL.md) | BoxFuture, `runAsync`, `asyncAll`, executors (virtual/fixed/cached), schedulers, `thread` component, `bx:lock`, file watchers |
| [`web-development`](./boxlang-developer/web-development/SKILL.md) | Application.bx lifecycle, request/response, forms, sessions, REST APIs, HTTP client, CSRF, Server-Sent Events, MiniServer config |
| [`database-access`](./boxlang-developer/database-access/SKILL.md) | `queryExecute`, datasource configuration, parameterized queries, SQL injection prevention, transactions, stored procedures |
| [`caching`](./boxlang-developer/caching/SKILL.md) | Cache providers, named regions, `cachePut`/`cacheGet`, output caching, Redis, Couchbase, TTL policies, distributed locking |
| [`java-integration`](./boxlang-developer/java-integration/SKILL.md) | `createObject`, imports, static methods, type conversion, closures as functional interfaces, including JARs, JSR-223 scripting |
| [`modules-and-packages`](./boxlang-developer/modules-and-packages/SKILL.md) | `box install`, module configuration, BoxLang+ premium modules (bx-pdf, bx-csv, bx-spreadsheet, bx-redis), ORM, mail |
| [`deployment`](./boxlang-developer/deployment/SKILL.md) | CommandBox, Docker, AWS Lambda, GitHub Actions CI/CD, BVM, `boxlang.json` runtime config, environment variable overrides |

### `boxlang-core-development` — Extending the BoxLang Runtime

For developers building BoxLang modules, contributing to the core runtime, and
creating custom built-in functions, interceptors, and components.

```bash
npx skills add ortus-boxlang/skills/boxlang-core-development
```

| Skill | What It Covers |
|-------|----------------|
| [`module-development`](./boxlang-core-development/module-development/SKILL.md) | Module directory structure, `ModuleConfig.bx` lifecycle (`configure`/`onLoad`/`onUnload`), settings, Gradle build, ForgeBox publishing |
| [`bif-development`](./boxlang-core-development/bif-development/SKILL.md) | `@BoxBIF` annotation, `invoke()` method, argument typing, `@BoxMember` for member functions, Java BIF classes, runtime service access |
| [`interceptors`](./boxlang-core-development/interceptors/SKILL.md) | Observer/Intercepting Filter patterns, 3 interceptor pools, BoxLang/Java/lambda interceptors, registration, interception points, custom events |
| [`component-development`](./boxlang-core-development/component-development/SKILL.md) | Custom tags/components, `onStartTag`/`onEndTag`, body content, attribute validation, registering component paths in modules |
| [`runtime-architecture`](./boxlang-core-development/runtime-architecture/SKILL.md) | BoxRuntime service locator, IBoxContext hierarchy, scope chain, DynamicObject, type system, parsing pipeline (source → AST → bytecode), virtual threads |

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

This repo also includes a prebuilt Claude marketplace catalog file at `.claude/skills/boxlang-marketplace.md`.
For marketplace-style JSON manifests, use `.claude/marketplace.json`.

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
