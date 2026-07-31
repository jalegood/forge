# Status

## Open Questions

| ID | Question | Blocking? | Raised |
| -- | -------- | --------- | ------ |
| Q-001 | Should Forge be repackaged as a Claude Code plugin (engine centralized, `.forge/` stays project-owned)? Tracked by TASK-041. | No | 2026-07-24 |
| Q-002 | Checkpoint cadence default is 5 tasks (`<!-- ASSUMED -->` in CONTRACT). Right default, or should it be per-project config? | No | 2026-07-24 |
| Q-003 | Single SPEC.md vs per-feature `.forge/specs/` — split threshold assumed at ~300 lines. Validate against a real project. | No | 2026-07-24 |

## Decisions

| Date | Decision | Why | Alternatives rejected |
| ---- | -------- | --- | --------------------- |
| 2026-07-24 | SPEC becomes a first-class artifact beside CONTRACT, with `SPEC#`/`specs/name#` manifest refs; Contract wins on conflict | Proven reliability gain in downstream forge projects; matches 2026 SDD consensus (per-feature specs in Spec Kit/Kiro) | Merging spec content into CONTRACT (conflates constraints with behavior); spec as free-form doc outside the manifest system (agent never sees it) |
| 2026-07-24 | Workplan invariants move from command prose to a deterministic lint script (`check-workplan.js`) | Forge principle #2: deterministic enforcement over instruction-following; prerequisite for safe unattended runs | Keeping invariants as instructions in forge-plan/forge-next only |
| 2026-07-24 | `checkpoint` task type + Unattended Execution rule: auto-commit allowed on work branches between checkpoints; human reviews the span, merges, and pushes | Per-task human review had become the bottleneck and trends toward rubber-stamping; checkpoints concentrate attention where it matters | Full autonomy (no quality floor); status quo per-task review (doesn't scale) |
| 2026-07-24 | Drift fix: `/forge-sync` + `.forge/VERSION` now; plugin packaging deferred to investigation (TASK-041) | Sync solves today's drift without restructuring distribution; plugin conversion is a bigger contract change | Immediate plugin conversion (premature before sync semantics are proven) |
| 2026-07-24 | Relaxed stale 2025-era boundaries: sub-agent blanket ban softened, 4-command budget cap lifted (now 6 commands) | Original rationales (7x token cost, sequential subagents, command character budget) are dated per July 2026 research | Keeping defensive constraints whose premises expired |

## Risks

| Risk | Impact | Mitigation |
| ---- | ------ | ---------- |
| Unattended spans amplify weak gates — a permissive gate ships 5 tasks of bad work instead of 1 | Bad code reaches checkpoint review, wasting a span | Workplan lint invariant #6 (feature/fix gates must invoke tests); checkpoint packet shows gate output, not just pass/fail |
| SPEC/CONTRACT duplication creeps in over time | Two sources of truth; agent follows whichever it read last | Spec Precedence rule; `/forge-plan` completeness check spans both; conflicts become clarify tasks |
| STATUS.md goes stale if nothing reads it | Dead artifact, wasted ceremony | Mandatory integrations: forge-status surfaces it, checkpoints embed it, clarify tasks write to it |

## Blockers

| Blocker | Blocking tasks | Needs |
| ------- | -------------- | ----- |
