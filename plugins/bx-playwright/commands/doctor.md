---
name: bx-playwright-cmd-doctor
description: Check the bx-playwright installation and fix what is missing. Usage: /bx-playwright:doctor
category: diagnostics
---

Check that bx-playwright is ready to drive a browser, then fix or explain each problem.

## Steps

1. Run `bxplaywright doctor --json`.
   - If `bxplaywright` is not found, the module is not installed (or BoxLang's bin folder is not on the PATH). Tell the user to run `install-bx-module bx-playwright`, then `bxplaywright install`, and stop.
2. The JSON is `{ "ok": boolean, "checks": [ { "check", "status", "message", "fix"? } ] }`. `status` is `ok`, `warn` or `fail`.
3. If `ok` is true and nothing is `warn`, say so in one line and stop.
4. For every `fail` and `warn` check, show the check, its message and its `fix` command.
5. Ask before running any `fix` command: they download the driver, Node.js or browsers into `~/.boxlang/playwright`. `bxplaywright install chromium --with-deps` also installs OS packages (Linux, needs sudo).
6. After fixes, run `bxplaywright doctor` again and report the result.

The `bx-playwright-setup` skill covers distributions, settings, profiles and CI setup.
