# BoxLang Core Development Skills

Skills for developers extending the BoxLang runtime: building modules, creating
custom built-in functions (BIFs), writing interceptors, developing custom
components/tags, understanding the runtime architecture, async/scheduled tasks,
and logging.

Install all core development skills:

```bash
npx skills add ortus-boxlang/skills/boxlang-core-development
```

| Skill | What It Covers | Install |
|-------|----------------|---------|
| `async-tasks` | `BoxFuture`, `AsyncService`, executor types, `BaseScheduler`, `ScheduledTask` fluent API, cron constraints, task lifecycle callbacks, registering schedulers via `ModuleConfig.bx` | `npx skills add ortus-boxlang/skills/boxlang-core-development/async-tasks` |
| `bif-development` | `@BoxBIF` annotation, `invoke()` method, argument typing, `@BoxMember` for member functions, Java BIF classes, runtime service access | `npx skills add ortus-boxlang/skills/boxlang-core-development/bif-development` |
| `component-development` | Custom tags/components, `onStartTag`/`onEndTag`, body content, attribute declarations, registering component paths in modules | `npx skills add ortus-boxlang/skills/boxlang-core-development/component-development` |
| `interceptors` | Observer/Intercepting Filter patterns, 3 interceptor pools, BoxLang/Java/lambda interceptors, registration, interception points, custom events | `npx skills add ortus-boxlang/skills/boxlang-core-development/interceptors` |
| `logging` | `LoggingService`, `BoxLangLogger` (trace/debug/info/warn/error), pre-configured loggers, named loggers, parameterized messages, `boxlang.json` logging config | `npx skills add ortus-boxlang/skills/boxlang-core-development/logging` |
| `module-development` | `ModuleConfig.bx` lifecycle (`configure`/`onLoad`/`onUnload`), settings, registering interceptors and BIFs, Gradle build, ForgeBox publishing | `npx skills add ortus-boxlang/skills/boxlang-core-development/module-development` |
| `runtime-architecture` | `BoxRuntime` services, `IBoxContext` hierarchy, scope chain, `DynamicObject`, type system, parsing pipeline (source → AST → bytecode), virtual threads | `npx skills add ortus-boxlang/skills/boxlang-core-development/runtime-architecture` |

## Useful Resources

- [BoxLang GitHub](https://github.com/ortus-boxlang/BoxLang)
- [Module Template](https://github.com/ortus-boxlang/boxlang-module-template)
- [BoxLang Docs](https://boxlang.ortusbooks.com/)
- [Interceptors](https://boxlang.ortusbooks.com/boxlang-framework/interceptors)
- [Modularity](https://boxlang.ortusbooks.com/boxlang-framework/modularity)
- [Async Programming](https://boxlang.ortusbooks.com/boxlang-framework/async-programming)
