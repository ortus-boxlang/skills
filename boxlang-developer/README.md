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
| `async-programming` | `BoxFuture`, `futureNew`, `asyncRun`, `asyncAll`, `asyncAny`, `asyncAllApply`, executors, schedulers, `thread` component, `bx:lock`, file watchers | `npx skills add ortus-boxlang/skills/boxlang-developer/async-programming` |
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
| `running-boxlang` | Deployment targets: CLI scripting, MiniServer, CommandBox, Docker, AWS Lambda, GCF, Spring Boot, WASM, MatchBox, native binaries | `npx skills add ortus-boxlang/skills/boxlang-developer/running-boxlang` |
| `security` | OWASP Top 10, injection prevention, file upload safety, secret management, secure coding patterns | `npx skills add ortus-boxlang/skills/boxlang-developer/security` |
| `templating` | `.bxm` markup files, output expressions, `bx:output`/`bx:loop`/`bx:if`/`bx:include`/`bx:script`, building views | `npx skills add ortus-boxlang/skills/boxlang-developer/templating` |
| `testing` | TestBox BDD (`describe`/`it`), xUnit, expectations, `$assert`, life-cycle hooks, MockBox, mock data, async/exception testing | `npx skills add ortus-boxlang/skills/boxlang-developer/testing` |
| `web-development` | `Application.bx` lifecycle, request/response, sessions, forms, REST APIs, HTTP client, CSRF, SSE, MiniServer config | `npx skills add ortus-boxlang/skills/boxlang-developer/web-development` |
| `zip` | Creating/extracting/listing/modifying ZIP archives via `bx:zip`, compression levels, encryption, backup workflows | `npx skills add ortus-boxlang/skills/boxlang-developer/zip` |
