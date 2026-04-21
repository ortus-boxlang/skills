# BoxLang Developer Skills

Skills for developers building applications with BoxLang. These cover the full
spectrum from language fundamentals through web development, data access, caching,
Java integration, and deployment.

Install all developer skills:

```bash
npx skills add ortus-boxlang/skills/boxlang-developer
```

| Skill | What It Covers | Install |
|-------|----------------|---------|
| `application-descriptor` | `Application.bx` discovery, multi-app isolation, lifecycle callbacks, app-level `this.*` settings, and app-scoped `this.schedulers`/`this.watchers` wiring | `npx skills add ortus-boxlang/skills/boxlang-developer/application-descriptor` |
| `async-programming` | `BoxFuture`, `futureNew`, `asyncRun`, `asyncAll`, `asyncAny`, `asyncAllApply`, executors, schedulers, `thread` component, `bx:lock`, file watchers | `npx skills add ortus-boxlang/skills/boxlang-developer/async-programming` |
| `file-watchers` | Filesystem watcher lifecycle (`watcherNew`/`watcherStart`/`watcherStop`), listener styles (closure/struct/class), event payload handling, debounce/throttle tuning, watcher stats and safety patterns | `npx skills add ortus-boxlang/skills/boxlang-developer/file-watchers` |
| `best-practices` | Naming conventions, scoping, function structure, error handling, performance, and maintainability guidelines | `npx skills add ortus-boxlang/skills/boxlang-developer/best-practices` |
| `caching` | Cache providers, named regions, `cachePut`/`cacheGet`, output caching, Redis, Couchbase, TTL policies, distributed locking | `npx skills add ortus-boxlang/skills/boxlang-developer/caching` |
| `cfml-migration` | Key syntax and behavioral differences, `bx-compat-cfml` module, converting file types, fixing common migration issues | `npx skills add ortus-boxlang/skills/boxlang-developer/cfml-migration` |
| `classes-and-oop` | Classes, inheritance, interfaces, abstract classes, properties, constructors, static members, annotations, `final` constructs | `npx skills add ortus-boxlang/skills/boxlang-developer/classes-and-oop` |
| `code-documenter` | Javadoc-style function/class comments, argument and return-type docs, DocBox-compatible annotations | `npx skills add ortus-boxlang/skills/boxlang-developer/code-documenter` |
| `code-reviewer` | Code quality, correctness, security vulnerabilities, performance, style — structured review feedback | `npx skills add ortus-boxlang/skills/boxlang-developer/code-reviewer` |
| `configuration` | `boxlang.json` runtime settings, datasources, caches, executors, modules, logging, security, schedulers | `npx skills add ortus-boxlang/skills/boxlang-developer/configuration` |
| `database-access` | `queryExecute`, `bx:query`, datasource config, parameterized queries, transactions, stored procedures, SQL injection prevention | `npx skills add ortus-boxlang/skills/boxlang-developer/database-access` |
| `deployment` | CommandBox, Docker, AWS Lambda, GitHub Actions CI/CD, BVM, `boxlang.json` runtime config, environment variable overrides | `npx skills add ortus-boxlang/skills/boxlang-developer/deployment` |
| `docbox` | API documentation generation: CLI, HTML/JSON/UML/CommandBox strategies, themes, multiple sources, custom strategies | `npx skills add ortus-boxlang/skills/boxlang-developer/docbox` |
| `file-handling` | `fileRead`/`fileWrite`/`fileCopy`/`fileMove`, directory operations, streaming large files, file uploads, CSV/JSON from disk | `npx skills add ortus-boxlang/skills/boxlang-developer/file-handling` |
| `functional-programming` | Closures vs lambdas (`=>`/`->`), higher-order functions, `map`/`filter`/`reduce`/`flatMap`/`groupBy`, destructuring, spread | `npx skills add ortus-boxlang/skills/boxlang-developer/functional-programming` |
| `interceptors` | Interceptor/event system, `announce()`/`announceAsync()`, pre/post hooks, security guards, `BoxRegisterInterceptor()` | `npx skills add ortus-boxlang/skills/boxlang-developer/interceptors` |
| `java-integration` | `createObject`, static methods, type conversion, closures as functional interfaces, JARs, JSR-223 scripting | `npx skills add ortus-boxlang/skills/boxlang-developer/java-integration` |
| `language-fundamentals` | File types (`.bx`/`.bxs`/`.bxm`), variables, scopes, operators, control flow, exception handling, type system, destructuring | `npx skills add ortus-boxlang/skills/boxlang-developer/language-fundamentals` |
| `modules-and-packages` | `box install`, module config, BoxLang+ premium modules (`bx-pdf`, `bx-redis`, `bx-csv`, `bx-spreadsheet`), ORM, mail | `npx skills add ortus-boxlang/skills/boxlang-developer/modules-and-packages` |
| `scheduled-tasks` | Scheduler DSL (`BaseScheduler`/`ScheduledTask`), scheduler lifecycle BIFs, cron/frequency APIs, task grouping, timezone handling, and `bx:schedule` HTTP-driven tasks | `npx skills add ortus-boxlang/skills/boxlang-developer/scheduled-tasks` |
| `runtime-*` | Deployment/runtime targets are now individual skills such as `runtime-miniserver`, `runtime-commandbox`, `runtime-docker`, `runtime-aws-lambda`, and more | `npx skills add ortus-boxlang/skills/boxlang-developer/runtime-miniserver` |
| `runtime-desktop` | Desktop architecture with Electron + MiniServer, `runtime/Package.bx`, `miniserver.json` dev control, `.boxlang-dev.json` vs `.boxlang.json`, required `/app` and `/public` mappings, and Java 21+ host requirements | `npx skills add ortus-boxlang/skills/boxlang-developer/runtime-desktop` |
| `security` | OWASP Top 10, injection prevention, file upload safety, secret management, secure coding patterns | `npx skills add ortus-boxlang/skills/boxlang-developer/security` |
| `templating` | `.bxm` markup files, output expressions, `bx:output`/`bx:loop`/`bx:if`/`bx:include`/`bx:script`, building views | `npx skills add ortus-boxlang/skills/boxlang-developer/templating` |
| `testing` | TestBox BDD (`describe`/`it`), xUnit, expectations, `$assert`, life-cycle hooks, MockBox, mock data, async/exception testing | `npx skills add ortus-boxlang/skills/boxlang-developer/testing` |
| `web-development` | `Application.bx` lifecycle, request/response, sessions, forms, REST APIs, HTTP client, CSRF, SSE, MiniServer config | `npx skills add ortus-boxlang/skills/boxlang-developer/web-development` |
| `zip` | Creating/extracting/listing/modifying ZIP archives via `bx:zip`, compression levels, encryption, backup workflows | `npx skills add ortus-boxlang/skills/boxlang-developer/zip` |
