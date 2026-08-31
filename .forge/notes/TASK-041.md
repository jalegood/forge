# TASK-041 — Investigate plugin packaging for Forge distribution

## Outcome

**Recommendation: yes, but as a hybrid — the plugin ships the engine, `/forge-init` still installs the scripts into `.forge/scripts/`.** Plugin packaging solves Forge's single most recurrent defect class outright, and the one constraint that rules out a pure move is a hard one. Scoped as the first v0.4 workstream.

## The case for moving

Forge's current distribution is "copy six markdown files into `.claude/commands/`". One of those files, `forge-init.md`, is 3,607 lines, of which **3,020 (83%) are 22 fenced payloads** transcribing the engine's own scripts and templates. Those payloads are copies of live files that nothing executes, so they go stale silently.

Measured on this repo's own history: **7 of 20 observations ever recorded (35%) are payload or scaffold-distribution defects** — OBS-001, 002, 003, 005, 011, 014, 016. Seven commits since 2026-08-01 changed a script without touching `forge-init.md`, each one a drift window. One of them shipped a *reverted bug fix* to every new project for weeks (OBS-016 / TASK-078: the embedded `check-ux-spec.js` was the pre-TASK-050 implementation).

Three mechanisms now exist purely to contain this: `forge-init:embed` markers, two content-diff tests, and a Contract rule (Embedded Payload Synchronization). **All of that machinery exists because the engine cannot ship files.** A plugin can.

## What plugins can actually do (the facts that decide it)

- **Plugins ship arbitrary support files**, including Node scripts, in directories at the plugin root. Commands and hooks reference them at runtime through **`${CLAUDE_PLUGIN_ROOT}`**. This is the finding the whole decision turned on: had it been false, the payload approach would be forced and this investigation would end here.
- **Manifest** is `.claude-plugin/plugin.json` — `name` required; `version`, `description` strongly recommended; component paths for commands, agents, skills, hooks, MCP/LSP servers.
- **Hooks ship in the plugin** (`hooks/hooks.json`) and **merge additively** with project hooks rather than overriding them. Forge's three guards plus the status-lint hook would arrive with the engine instead of being written into a project's `settings.json` — and a project's own hooks keep working alongside.
- **Marketplaces**: any git repo containing `.claude-plugin/marketplace.json`. `jalegood/forge` can be its own marketplace. Install is `/plugin marketplace add jalegood/forge` then `/plugin install forge@forge`.
- **Updates**: `/plugin update`, keyed on the manifest `version` (or commit SHA when version is omitted), with optional background auto-update.
- **Precedence**: project-level components override same-named plugin components.

## The constraint that forces a hybrid

**44 gate commands in this workplan hardcode `.forge/scripts/` paths** (`check-workplan.js` ×20, `prose.js` ×17, `wp.js` ×4, plus `obs.js`, `check-status.js`, `check-spec.js`). Gates live in WORKPLAN.md, which is **project-owned data written by past tasks** — and `CONTRACT#rules/checkpoint-cadence` has checkpoints **re-run every gate in the span fresh**. Move the scripts to a plugin root and every historical gate breaks, turning every checkpoint into a wall of false regressions.

`${CLAUDE_PLUGIN_ROOT}` does not rescue this: it is documented for hook and MCP command definitions, not guaranteed in the environment of an arbitrary bash gate, and Forge gates are plain shell.

**Therefore:** the scripts must remain resolvable at `.forge/scripts/` inside each project. That is not a defeat — it makes `/forge-init`'s job *copying real files out of the plugin* instead of transcribing them through markdown, which is exactly the improvement worth having.

## Recommended shape

| Layer | Where it lives | Why |
| --- | --- | --- |
| 6 slash commands | plugin `commands/` | The natural component type; no payloads. |
| Engine scripts + templates | plugin `scripts/`, `templates/` — **copied into the project** by `/forge-init` | Keeps the 44 existing gate paths valid; kills all 22 payloads. |
| 3 guards + status-lint hook | plugin `hooks/hooks.json` | Merges additively; arrives with the engine. |
| Vision, Contract, Spec, Workplan, Status, UX, Design | project only, never shipped | Unchanged — the automation boundary does not move. |

## What `/forge-sync` becomes

**Retained, narrowed — not subsumed.** `/plugin update` refreshes the plugin, which covers commands and hooks. It does **not** touch the copies already sitting in a project's `.forge/scripts/` and `.forge/templates/`, and those are what actually execute. `/forge-sync`'s remaining job is precisely that reconciliation: diff each project-local engine file against the installed plugin's copy and apply approved updates, per file. Its Reads line changes from "the canonical repository" to "the installed plugin root"; its no-touch list for project-owned artifacts is unchanged. `.forge/VERSION` stays useful as the record of which engine version a project's copies came from.

## Template override resolution

Forge must implement this itself. `.forge/templates/` is not a Claude Code component path — templates are plain files that `/forge-next` reads by path, so the platform's project-overrides-plugin precedence does not apply automatically. The resolution order to specify (currently unwritten anywhere): **project `.forge/templates/<type>.md` wins; the plugin's copy is the fallback.** That preserves per-project template customization, which the Contract's "Template refresh" note already assumes exists.

## Migration path for existing projects

Non-breaking, and no flag day: a project that has copied commands keeps working, because project-level commands override plugin ones. Install the plugin, delete the six local `forge-*.md` files, re-run `/forge-init` to refresh `.forge/scripts/` from the plugin, commit. `.forge/` content is untouched throughout.

## Costs and the honest caveat

- Plugins require **explicit installation**; the current copy-paste needs none. This is the one real regression in the user experience, and it is small next to seven drift defects.
- `/forge-init` must be rewritten from "transcribe 22 payloads" to "copy files" — a large deletion, and the `forge-init:embed` markers, both content-diff tests, and `CONTRACT#rules/embedded-payload-synchronization` all retire with it.
- Windows path handling for `${CLAUDE_PLUGIN_ROOT}` is untested here and should be verified before committing to the design.

## Go/no-go

**Go, as the first v0.4 workstream**, sequenced ahead of other v0.4 work because every task that touches an engine script until then pays the payload tax. Not started in v0.3: it deletes and rewrites the largest command file in the repo, which is not a change to land in the same release as the machinery it distributes.

## Files

No repository files changed — investigation only. Q-001 resolved with this recommendation; dated Decisions entry logged.
