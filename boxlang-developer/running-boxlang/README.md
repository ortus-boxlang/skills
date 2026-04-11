# Running BoxLang — Deployment Targets

Skills for running BoxLang across every supported runtime and platform: from
interactive CLI scripts and local development servers through cloud functions,
containers, native binaries, and embedded devices.

Install all running-boxlang skills:

```bash
npx skills add ortus-boxlang/skills/boxlang-developer/running-boxlang
```

| Skill | What It Covers | Install |
|-------|----------------|---------|
| `aws-lambda` | Lambda.bx handler, SAM CLI, environment variables, performance optimization, connection pooling, multi-function routing | `npx skills add ortus-boxlang/skills/boxlang-developer/running-boxlang/aws-lambda` |
| `chromebook` | Linux dev environment, Java 21, BoxLang + VS Code setup, ARM/Intel Chromebook troubleshooting | `npx skills add ortus-boxlang/skills/boxlang-developer/running-boxlang/chromebook` |
| `cli-scripting` | CLI scripts/classes, argument parsing, BoxLang REPL, action commands (`compile`, `cftranspile`, `featureaudit`), CLI BIFs | `npx skills add ortus-boxlang/skills/boxlang-developer/running-boxlang/cli-scripting` |
| `commandbox` | Enterprise servlet deployment, `server.json` for BoxLang, SSL, rewrites, BoxLang+/++ subscriptions, production config | `npx skills add ortus-boxlang/skills/boxlang-developer/running-boxlang/commandbox` |
| `compiled-native-binaries` | MatchBox `--target native`, cross-compilation, binary size optimization, Native Fusion for Rust BIFs | `npx skills add ortus-boxlang/skills/boxlang-developer/running-boxlang/compiled-native-binaries` |
| `digitalocean-app` | DigitalOcean App Platform, BoxLang starter kit, GitHub auto-deploy, MiniServer + multi-stage Docker architecture | `npx skills add ortus-boxlang/skills/boxlang-developer/running-boxlang/digitalocean-app` |
| `docker` | Image variants, MiniServer web runtime, environment variables, health checks, volume mounts, Docker Compose, production patterns | `npx skills add ortus-boxlang/skills/boxlang-developer/running-boxlang/docker` |
| `esp32` | MatchBox `--target esp32`, flashing firmware, watch mode, hardware BIFs, FreeRTOS task constraints | `npx skills add ortus-boxlang/skills/boxlang-developer/running-boxlang/esp32` |
| `github-actions` | `setup-boxlang` action, inputs/outputs, module installation, CommandBox integration, multi-engine testing, workflow templates | `npx skills add ortus-boxlang/skills/boxlang-developer/running-boxlang/github-actions` |
| `google-cloud-functions` | GCF Gen 2, handler structure, `FunctionRunner`, URI routing, environment variables, local development with GCF invoker | `npx skills add ortus-boxlang/skills/boxlang-developer/running-boxlang/google-cloud-functions` |
| `jsr-223` | JSR-223 scripting API, evaluating BoxLang from Java, Bindings data sharing, rules engines, template processors | `npx skills add ortus-boxlang/skills/boxlang-developer/running-boxlang/jsr-223` |
| `matchbox` | Rust-based JVM-free BoxLang, compilation targets (`native`, `wasm`, `js`, `esp32`), philosophy and tradeoffs | `npx skills add ortus-boxlang/skills/boxlang-developer/running-boxlang/matchbox` |
| `miniserver` | Undertow-based web server, `miniserver.json` config, health checks, warmup URLs, environment variable overrides | `npx skills add ortus-boxlang/skills/boxlang-developer/running-boxlang/miniserver` |
| `spring-boot` | Spring Boot starter dependency, MVC view resolution, template structure, Spring Model attributes, `application.properties` | `npx skills add ortus-boxlang/skills/boxlang-developer/running-boxlang/spring-boot` |
| `wasm-container` | MatchBox `--target wasm`, Wasmtime/WasmEdge runners, minimal OCI WASM containers, Fastly Compute, Cloudflare Workers | `npx skills add ortus-boxlang/skills/boxlang-developer/running-boxlang/wasm-container` |
| `wasm-in-the-browser` | MatchBox `--target js`/`--target wasm`, browser integration, Webpack/Vite bundlers, Node.js projects | `npx skills add ortus-boxlang/skills/boxlang-developer/running-boxlang/wasm-in-the-browser` |
