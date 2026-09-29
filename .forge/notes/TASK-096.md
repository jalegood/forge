# TASK-096 — Checkpoint: observation machinery integrated — Review Packet

Assembled 2026-08-31 during the v0.3-headless unattended run. Reviewed and passed by the run under HEADLESS-RUN.md authority; the human re-reviews at merge.

## Span (5 tasks)

| Task | Description | Files |
| --- | --- | --- |
| TASK-084 | Integrate obs.js into /forge-next | .claude/commands/forge-next.md |
| TASK-085 | Project the observation backlog through /forge-status | .claude/commands/forge-status.md, .forge/tests/smoke.sh |
| TASK-086 | Close the accepted-observation loop in /forge-plan | .claude/commands/forge-plan.md |
| TASK-087 | Delegate observation recording in the templates to obs.js | .forge/templates/*.md, .forge/tests/test-templates.sh, .claude/commands/forge-init.md |
| TASK-088 | Ship the observation machinery in /forge-init | `.forge/scripts/hook-status-lint.sh` (new); `.claude/commands/forge-init.md` — STATUS stub (Date column, Decisions shape, column-exactness warning), settings payload, three embedded script payloads, created-files list; `.claude/se |

## Fresh gate results (re-run at packet time)

```
TASK-084 | PASS | Integrate obs.js into /forge-next | the loop closes at forge-next
TASK-085 | PASS | Project the observation backlog through /forge-status | status reads the queue
TASK-086 | PASS | Close the accepted-observation loop in /forge-plan | accepted rows reach planned
TASK-087 | PASS | Delegate observation recording in the templates to obs.js | templates carry judgment not format
TASK-088 | PASS | Ship the observation machinery in /forge-init | scaffolds get the machinery
```

**5/5 pass. Zero regressions.**

## What this span delivered

Every consumer of the Observations channel now goes through `obs.js`, and a new project receives the whole subsystem:

- **`/forge-next`** sweeps before selection, reports open `foundation` rows from the projection, carries the guided triage flow on the exit-3 halt (present, recommend, apply via `obs.js set`, retry — or write a triage packet to disk and stop when unattended), records findings via `obs.js add`, and states the two permitted auto-dispositions plus the never-`foundation` rule.
- **`/forge-status`** projects the backlog: `foundation` rows first with the raising task's description and age, the `accepted` awaiting-planning queue, and counts by disposition.
- **`/forge-plan`** advances an `accepted` row to `planned:TASK-XXX` when it generates the task — the loop that previously let accepted rows sit unseen.
- **All eight templates** invoke `obs.js add` and no longer print the row layout; the test now *rejects* any reappearance of it.
- **`/forge-init`** ships `check-status.js`, `obs.js`, and the new `hook-status-lint.sh`, with a STATUS stub whose columns match the Data Model exactly.

**One thing to look at closely.** `hook-status-lint.sh` is new machinery introduced mid-span rather than planned: `CONTRACT#boundaries/hook-configuration` mandated the hook and the exit-2 translation, but no artifact existed to do it. It is small, tested three ways (clean file, unrelated file, malformed file), and now carries a Contract Artifacts row — but it is the one thing in this span the workplan did not name in advance.

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

No `foundation` rows open; both remaining rows are previously-triaged `normal` ones.

## Rollback

Span starts at the TASK-084 commit; the rollback point is its parent:

```
git reset --hard cc02054^
```

**This discards the whole span** — every command-side integration and the scaffold payloads. The human runs it; the run never does.

## Verdict

**PASS.** 5/5 gates green fresh, no regressions, no open foundation rows. The subsystem is now end-to-end: recorded through one writer, validated by a lint, swept deterministically, surfaced where attention already is, and shipped to new projects.
