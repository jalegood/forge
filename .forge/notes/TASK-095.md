# TASK-095 — Checkpoint: observation machinery core — Review Packet

Assembled 2026-08-31 during the v0.3-headless unattended run. Reviewed and passed by the run under HEADLESS-RUN.md authority; the human re-reviews at merge.

## Span (4 tasks)

| Task | Description | Files |
| --- | --- | --- |
| TASK-093 | Convert STATUS.md Decisions from a table to dated sections | `.forge/STATUS.md` — the migration; `.forge/CONTRACT.md` — skeleton, normative paragraph, lint scope, table-count, two entry-wording sites; `.forge/templates/clarify.md`, `.forge/templates/checkpoint.md` — writer/reader instructions; `.claude/command |
| TASK-081 | Teach lib/markdown.js to parse tables by column name | .forge/scripts/lib/markdown.js, .forge/tests/test-markdown.sh, .claude/commands/forge-init.md |
| TASK-082 | Build check-status.js and bring the live STATUS.md under it | `.forge/scripts/check-status.js` (new); `.forge/tests/test-check-status.sh` (new, 11 fixtures); `.forge/STATUS.md` — Date column migration; `.forge/scripts/wp.js` — header-keyed readObservations, fail-closed; `.forge/tests/smoke.sh` — suite wired; `. |
| TASK-083 | Build obs.js as the sole Observations writer | `.forge/scripts/obs.js` (new); `.forge/tests/test-obs.sh` (new); `.forge/tests/smoke.sh` — suite wired; `.forge/STATUS.md` — 8 rows swept to `closed` |

## Fresh gate results (re-run at packet time)

```
TASK-093 | PASS | Convert STATUS.md Decisions from a table to dated sections | decisions read as history
TASK-081 | PASS | Teach lib/markdown.js to parse tables by column name | one table parser
TASK-082 | PASS | Build check-status.js and bring the live STATUS.md under it | status lint live
TASK-083 | PASS | Build obs.js as the sole Observations writer | observations have one writer
```

**4/4 pass. Zero regressions.**

## What this span delivered

The Observations subsystem the 2026-08-29 Contract amendment specified now exists in code rather than in prose:

- **STATUS.md is readable again.** The Decisions table (44 rows, cells over 2,100 characters, ~95KB file) became 44 dated sections; the file is now ~58KB and every entry survives a terminal and a diff. Content migrated verbatim, escape-aware.
- **One table parser.** `parseTable` in lib/markdown.js: header-keyed, honors `\|` and backtick spans, skips fenced blocks, and reports a malformed row as a structured error rather than dropping it.
- **STATUS.md has a lint.** `check-status.js` enforces the four tables' columns, row shape, Observation enums, ID monotonicity, `planned:`/`duplicate:` link integrity, and the Decisions heading shape. Wired into smoke.sh and armed in the run's own pre-commit breaker.
- **Observations have one writer.** `obs.js add|set|list|sweep`, write-lint-revert on every mutation. The first live sweep closed 8 rows deterministically.

**The load-bearing fix in this span is not any of the four scripts.** It is that `wp.js`'s `readObservations` was positional: adding the Date column would have shifted every cell one right, read Kind as Severity, matched no `open` row, and silently disarmed the foundation hard stop — reporting a clear queue while a halting row sat in the file. That is the precise failure `CONTRACT#data-model/markdown-table-parsing` was written about, and it was live in this repo until TASK-082 converted the reader and made it fail closed.

## STATUS.md excerpt

### Open Questions

| ID    | Question                                                                                                                                                                                                                                                                                                                                                                                                                                                | Blocking? | Raised     |
| ----- | ------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------- | --------- | ---------- |
| Q-001 | Should Forge be repackaged as a Claude Code plugin (engine centralized, `.forge/` stays project-owned)? Tracked by TASK-041.                                                                                                                                                                                                                                                                                                                            | No        | 2026-07-24 |
| Q-002 | Checkpoint cadence default is 5 tasks (`<!-- ASSUMED -->` in CONTRACT). Right default, or should it be per-project config?                                                                                                                                                                                                                                                                                                                              | No        | 2026-07-24 |
| Q-003 | Single SPEC.md vs per-feature `.forge/specs/` — split threshold assumed at ~300 lines. **Not** validated by TASK-048: this project's SPEC.md is 96 lines, so the threshold remains untested (see 2026-08-17 Decisions).                                                                                                                                                                                                                                 | No        | 2026-07-24 |
| Q-004 | Record externalization threshold is 3 lines. Right cutoff, or should it be character-based, or per-project config? Validate against the migrated 67-task work project (TASK-060).                                                                                                                                                                                                                                                                       | No        | 2026-08-14 |
| Q-006 | Should tasks group into features, derived from their `specs/X#` manifest refs rather than a declared field, to drive feature-aligned checkpoint cadence, per-feature `/forge-status`, and a requirement-coverage lint? Gated by Q-003 — no `.forge/specs/` split means no natural feature identity — and would subsume Q-002's assumed cadence of 5. Evaluation trigger: TASK-046's span, asking whether a five-task window was a coherent review unit. | No        | 2026-08-16 |

### Risks

| Risk                                                                                           | Impact                                                     | Mitigation                                                                                                                |
| ---------------------------------------------------------------------------------------------- | ---------------------------------------------------------- | ------------------------------------------------------------------------------------------------------------------------- |
| Unattended spans amplify weak gates — a permissive gate ships 5 tasks of bad work instead of 1 | Bad code reaches checkpoint review, wasting a span         | Workplan lint invariant #6 (feature/fix gates must invoke tests); checkpoint packet shows gate output, not just pass/fail |
| SPEC/CONTRACT duplication creeps in over time                                                  | Two sources of truth; agent follows whichever it read last | Spec Precedence rule; `/forge-plan` completeness check spans both; conflicts become clarify tasks                         |
| STATUS.md goes stale if nothing reads it                                                       | Dead artifact, wasted ceremony                             | Mandatory integrations: forge-status surfaces it, checkpoints embed it, clarify tasks write to it                         |

### Open observations

```
OBS-008 [normal/scope] open Â· 15d Â· TASK-033
  TASK-059's forge-status.md rewrite already contained TASK-033's whole deliverable, so this task's gate passed before any work began â€” a prior task absorbed a later one's scope with no workplan signal.
OBS-017 [normal/design] open Â· 14d Â· TASK-067
  TASK-067's gate clause `test $(grep -c "^| 2026-" .forge/STATUS.md) -gt 24` was already satisfied by the 33 pre-existing dated rows, so it asserted nothing about the row this task adds â€” a fourth vacuous-gate instance after OBS-010's three.
```

No `foundation` rows open. Both remaining rows are `normal` and previously triaged: OBS-008 parked for v0.4 by the human (2026-08-16); OBS-017 names a decayed count-gate on a `done` task — zero forward risk, and its subject (the `^| 2026-` row count) no longer even exists after TASK-093.

### Decisions dated inside the span

- 2026-08-30 — OBS-019 recorded and planned as TASK-098 in the same checkpoint session (TASK-046)
- 2026-08-30 — The manifest heading-matching rule is now normative in the Contract: alphanumeric compaction on b…
- 2026-08-30 — Four Contract passages reconciled with their own commands (TASK-077)
- 2026-08-30 — Resolves Q-007: the template-payload content diff is built, not narrowed away (TASK-070)
- 2026-08-30 — Headless planning pass: the 2026-08-29 Observations amendment and the ideas/ intake become 17 tas…
- 2026-08-30 — Observation backlog triaged under headless-run authority: OBS-003→planned:TASK-070, OBS-005→plann…
- 2026-08-30 — Headless-run fault tolerance designed and installed (branch v0.3-headless)

## Rollback

Span starts at the TASK-093 commit; the rollback point is its parent:

```
git reset --hard 2a49c43^
```

**This discards the whole span** — the Decisions migration, the parser, the lint, and obs.js. The human runs it; the run never does.

## Verdict

**PASS.** 4/4 gates green fresh, no regressions, no open foundation rows, no blocking questions. The chain sequenced correctly: migration before lint before writer, so each was built once against the final shape.
