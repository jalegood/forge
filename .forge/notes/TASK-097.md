# TASK-097 — Checkpoint: v0.3+ projection and repairs — Review Packet

Assembled 2026-08-31 during the v0.3-headless unattended run. Reviewed and passed by the run under HEADLESS-RUN.md authority; the human re-reviews at merge.

## Span (4 tasks)

| Task | Description | Files |
| --- | --- | --- |
| TASK-089 | Give /forge-init its missing VERSION step | .claude/commands/forge-init.md, .forge/tests/test-init-scripts.sh |
| TASK-090 | Widen forge-sync.md's managed globs to the Contract's set | .claude/commands/forge-sync.md |
| TASK-091 | Emit the workplan graph from wp.js | .forge/scripts/wp.js, .forge/tests/test-wp.sh, .claude/commands/forge-init.md |
| TASK-092 | Make /forge-status graph-aware | .claude/commands/forge-status.md |

## Fresh gate results (re-run at packet time)

```
TASK-089 | PASS | Give /forge-init its missing VERSION step | init stamps the engine version
TASK-090 | PASS | Widen forge-sync.md's managed globs to the Contract's set | sync sees every managed script
TASK-091 | PASS | Emit the workplan graph from wp.js | the DAG is visible
TASK-092 | PASS | Make /forge-status graph-aware | position not just counts
```

**4/4 pass. Zero regressions.**

## What this span delivered

- **OBS-014 closed (TASK-089).** `/forge-init` had no VERSION step at all, so every scaffolded project was unable to run `/forge-sync` — it stops at step 1 without the stamp. The step now exists, and the test asserts both that it exists and that the live file holds the two positional lines.
- **OBS-015 closed (TASK-090).** `/forge-sync`'s managed globs covered `check-*.js` only, at three sites, while the Artifacts table marks ten scripts Forge-managed — so drift in `wp.js`, `obs.js`, `lib/`, and every guard was permanent by construction. All three sites now match the Contract set.
- **The DAG is projectable (TASK-091).** `wp.js graph` emits nodes and edges with longest-path depth, a startable flag computed by the same unblocked-ness rule selection uses, and fan-in/out; `--mermaid` renders it with no rendering code. This is ideas/ux-nearterm.md item 1, the doc's highest-leverage item, and the data model every later view consumes.
- **`/forge-status` reports position, not just counts (TASK-092).** Depth, width, the full startable set, and choke points.

## Current graph (the projection, on this workplan)

```
Graph: 98 tasks, 137 edges, 6 not done
  depth 6 (1): TASK-049*
  depth 15 (1): TASK-097
  depth 16 (1): TASK-039
  depth 17 (1): TASK-040
  depth 18 (2): TASK-041 TASK-052
  * = startable now
```

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

No `foundation` rows open.

## Rollback

Span starts at the TASK-089 commit; the rollback point is its parent:

```
git reset --hard f40a650^
```

**This discards the whole span.** The human runs it; the run never does.

## Verdict

**PASS.** 4/4 gates green fresh, no regressions, no open foundation rows. Two long-standing observation-backlog defects closed, and the projection layer the near-term UX doc argued for exists as data rather than pixels.
