# TASK-088 — Ship the observation machinery in /forge-init

## Outcome

A scaffolded project now receives the observation machinery whole: `check-status.js`, `obs.js`, and a new `hook-status-lint.sh` are embedded as marker-diffed payloads; the STATUS.md stub carries the Date column and the dated-section Decisions shape so its columns match the Data Model exactly; and the settings.json payload wires the PostToolUse status-lint hook, which this repo's own settings.json now carries too.

## Decisions

- **The hook is a wrapper script, not an inline `node check-status.js`.** `CONTRACT#interfaces/script-exit-codes` requires hooks to exit **2** to block while the lint keeps its own exit 1; a hook invoking the script directly would report a malformed table and prevent nothing. The wrapper also scopes itself to STATUS.md edits, so it costs nothing on every other write.
- **The wrapper resolves `check-status.js` next to itself** (`dirname "$0"`), not through the shell's cwd — a hook fires from whatever directory the tool call ran in. Same lesson as TASK-072.
- **Gate repaired mid-task and recorded here** (CONTRACT#rules/gate-discrimination, obligation 3): the authored clause `grep -q "check-status" .claude/settings.json` asserted an implementation the Contract forbids — settings.json names the *wrapper*. Repaired to assert `hook-status-lint` in both settings.json and forge-init.md, which is strictly more specific and still failed pre-work.
- **Contract Artifacts gained a Status Hook row** and the provisioning bullet went from nine scripts to ten, since a Forge-managed script absent from the Artifacts table is one `/forge-sync` can never sync (the OBS-015 failure mode).
- The stub's Decisions section is an HTML comment showing the dated-section shape rather than an empty table — there is no header row to emit when the container is sections.

## Files

- `.forge/scripts/hook-status-lint.sh` (new)
- `.claude/commands/forge-init.md` — STATUS stub (Date column, Decisions shape, column-exactness warning), settings payload, three embedded script payloads, created-files list
- `.claude/settings.json` — status-lint hook (dogfood; arms next session)
- `.forge/tests/test-init-scripts.sh` — three payloads covered
- `.forge/tests/test-check-status.sh` — fixture 12 covers the wrapper's three paths
- `.forge/CONTRACT.md` — Status Hook artifact row, ten-script provisioning bullet
