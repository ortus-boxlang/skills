# CommandBox Skills

Skills for working with [CommandBox](https://www.ortussolutions.com/products/commandbox) — the CFML/BoxLang CLI, package manager, and embedded server from Ortus Solutions (v6.3+).

Each sub-skill covers a distinct CommandBox feature area and is loaded automatically by the agent when relevant.

## Skills

| Skill | What It Covers |
|-------|----------------|
| [`commandbox-setup`](./commandbox-setup/SKILL.md) | Installation (macOS/Linux/Windows/Homebrew), upgrading, Java configuration, `commandbox.properties`, light vs thin binaries |
| [`commandbox-usage`](./commandbox-usage/SKILL.md) | CLI commands, named/positional parameters, flags, system settings (`${VAR:default}`), env vars, backtick expressions, piping, recipes, REPL, aliases, exit codes, `watch` |
| [`commandbox-package-management`](./commandbox-package-management/SKILL.md) | `box.json` schema, ForgeBox / Git / HTTP / folder / S3 / Gist / Java endpoints, semver ranges, dependencies vs devDependencies, lock files, package scripts, artifacts cache, publishing |
| [`commandbox-embedded-server`](./commandbox-embedded-server/SKILL.md) | Undertow server configuration via `server.json`, server profiles, JVM/heap settings, SSL/TLS, URL rewrites, server rules, multi-site support, basic auth, aliases, OS service, server scripts |
| [`commandbox-task-runners`](./commandbox-task-runners/SKILL.md) | Task CFC anatomy, lifecycle events, interactive jobs DSL, progress bars, ANSI print helpers, threading/async, file watching, running sub-commands, property files, ad-hoc JARs/modules |
| [`commandbox-developing`](./commandbox-developing/SKILL.md) | Custom commands, namespace conventions, parameter annotations, WireBox DI, module structure, `ModuleConfig.cfc`, interceptors, core interception points, injection DSL, sharing/publishing |
| [`commandbox-config-settings`](./commandbox-config-settings/SKILL.md) | Global config management, `config set/show/clear`, server defaults, ForgeBox API token, custom endpoints, proxy settings, env var overrides (`box_config_*`), setting sync |
| [`commandbox-deploying`](./commandbox-deploying/SKILL.md) | Production `server.json`, Docker (`ortussolutions/commandbox`), GitHub Actions (`setup-commandbox`), Heroku/Dokku buildpack, Amazon Lightsail/VPS, systemd service, CFConfig integration |
| [`commandbox-testing`](./commandbox-testing/SKILL.md) | `testbox run` flags, `box.json` testbox config, test watcher, CI integration, output formats, code coverage, TestBox CLI patterns |

## Install

```bash
# All CommandBox skills
npx skills add ortus-boxlang/skills/commandbox

# Single skill
npx skills add ortus-boxlang/skills/commandbox/commandbox-embedded-server
npx skills add ortus-boxlang/skills/commandbox/commandbox-package-management
npx skills add ortus-boxlang/skills/commandbox/commandbox-task-runners
```

## Usage

Skills are loaded automatically when relevant. Examples:

- "How do I configure SSL for my CommandBox server?" → loads `commandbox-embedded-server`
- "How do I publish a ForgeBox package?" → loads `commandbox-package-management`
- "How do I run TestBox tests from the CLI?" → loads `commandbox-testing`
- "Deploy CommandBox to Docker" → loads `commandbox-deploying`
- "Write a task runner that watches files" → loads `commandbox-task-runners`
- "Create a custom CommandBox command" → loads `commandbox-developing`

## Resources

| Resource | Link |
|----------|------|
| CommandBox Documentation | https://commandbox.ortusbooks.com/ |
| CommandBox GitHub | https://github.com/Ortus-Solutions/commandbox |
| ForgeBox | https://forgebox.io |
| Ortus Community | https://community.ortussolutions.com/ |
