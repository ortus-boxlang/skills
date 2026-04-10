# BoxLang Skills

AI agent skills for [BoxLang](https://boxlang.ortusbooks.com/) — a Modern Dynamic JVM Language.
Installable via the [skills.sh](https://skills.sh) ecosystem (`npx skills`).

## Categories

### `boxlang-developer` — Building Applications with BoxLang

Skills for developers writing BoxLang applications: language syntax, OOP, async
programming, web development, database access, caching, Java integration, modules,
and deployment.

| Skill | Description |
|-------|-------------|
| `language-fundamentals` | Core syntax, types, scopes, operators, control flow, and modern features |
| `classes-and-oop` | Classes, inheritance, interfaces, properties, and annotations |
| `functional-programming` | Lambdas, closures, higher-order functions, and array/struct pipelines |
| `async-programming` | BoxFuture, executors, schedulers, threads, and parallel pipelines |
| `web-development` | Application.bx lifecycle, HTTP, REST, sessions, and routing |
| `database-access` | Queries, datasources, transactions, and stored procedures |
| `caching` | Cache providers, distributed caching, and output caching |
| `java-integration` | Java interop, createObject, type conversion, and JSR-223 |
| `modules-and-packages` | Installing, configuring, and using BoxLang modules |
| `deployment` | CommandBox, Docker, AWS Lambda, GitHub Actions, and BVM |

### `boxlang-core-development` — Extending the BoxLang Runtime

Skills for developers building BoxLang modules, contributing to the runtime, and
creating custom built-in functions, interceptors, and components.

| Skill | Description |
|-------|-------------|
| `module-development` | Module structure, ModuleConfig.bx lifecycle, Gradle build, and ForgeBox publishing |
| `bif-development` | Creating custom built-in functions with `@BoxBIF` and the `invoke()` method |
| `interceptors` | Event-driven interceptors, registration patterns, and interception points |
| `component-development` | Custom BoxLang components/tags, attribute handling, and component paths |
| `runtime-architecture` | BoxRuntime services, context hierarchy, type system, and parsing pipeline |

---

## Installation

Install all BoxLang skills:

```bash
npx skills add ortus-boxlang/boxlang-skills
```

Install only developer skills:

```bash
npx skills add ortus-boxlang/boxlang-skills/boxlang-developer
```

Install only core development skills:

```bash
npx skills add ortus-boxlang/boxlang-skills/boxlang-core-development
```

Install a single skill:

```bash
npx skills add ortus-boxlang/boxlang-skills/boxlang-developer/language-fundamentals
```

---

## Resources

- [BoxLang Documentation](https://boxlang.ortusbooks.com/)
- [BoxLang GitHub](https://github.com/ortus-boxlang/BoxLang)
- [BoxLang Module Template](https://github.com/ortus-boxlang/boxlang-module-template)
- [Ortus Community](https://community.ortussolutions.com/)
- [skills.sh](https://skills.sh)
