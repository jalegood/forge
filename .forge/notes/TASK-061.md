# TASK-061 — Reconcile Rules/Traceability with record externalization

## Outcome

`Rules/Traceability` now branches on the externalization threshold instead of stating one destination for the file manifest: inline tasks (notes ≤3 lines) keep the `Files` line in workplan Notes, externalized tasks put the list in the record's `## Files` and never duplicate it inline. The Discovery bullet was corrected to name both homes and gained a reverse-lookup command (`grep -rl <path> .forge/WORKPLAN.md .forge/notes/`), since file→task lookup now spans two locations. `Rules/Checkpoint Cadence` and two SPEC.md acceptance criteria that restated the old unconditional wording were aligned in the same pass. The human chose option A (confirm the TASK-057 deviation) and chose to amend Checkpoint Cadence here rather than defer it to TASK-037.

## Decisions

- **Confirmed the TASK-057 deviation rather than overturning it.** The deciding argument is non-duplication of a mechanically derived list — two copies drift the moment either is hand-edited — plus the Task Record Data Model being the more specific statement.
- **The token-savings argument was measured and discarded.** The `Files` lines are 3,182 chars across 27 tasks: 4.5% of this repo's 72KB workplan. The TASK-057 record justified the deviation partly on bloat; that rationale was overstated and the STATUS.md Decisions row says so explicitly rather than quietly restating a better argument.
- **Amended `Rules/Checkpoint Cadence` in this task.** Its packet spec enumerated "Files lines" as a packet ingredient, which option A makes false for externalized tasks. Fixing it here means TASK-037 implements against a correct spec; deferring would have left a known-stale sentence in the Contract for several tasks.
- **Aligned SPEC.md rather than leaving it to Spec Precedence.** Two acceptance criteria ([req-checkpoint-packet], [req-unattended-halt-state]) spelled out "Files line" literally while nominally deferring to the Contract. Precedence would resolve the conflict in the Contract's favor, but a correct implementation would still fail the criteria as written — so the criteria, not just the precedence rule, had to change.
- **No `fix` task was needed for any `done` task.** Amendment protocol step 3 assessment below.

## Deviations

- **Scope reached beyond CONTRACT.md into SPEC.md.** The task described amending `Rules/Traceability`; the same stale wording turned out to be restated in `Rules/Checkpoint Cadence` and twice in SPEC.md. All four were edits to one conflict, so they were fixed together rather than split into follow-up tasks. The Checkpoint Cadence half was put to the human as an explicit choice; the SPEC.md half was not, and was taken as in-scope reconciliation of the same defect.

## Impact assessment (Rules/Contract Amendment Protocol, step 3)

Tasks whose Context references the amended sections:

- **`done` — TASK-009, TASK-015, TASK-048, TASK-057.** None need a reconciling `fix` task. TASK-057's deviation was confirmed, so its deliverable is now Contract-backed. TASK-009's unconditional `Files`-line behavior was already superseded by TASK-057's branch in `forge-next.md`, so the shipped code matches the amended rule. TASK-048 authored the SPEC.md criteria corrected here, which closes its exposure.
- **`pending` — TASK-035, TASK-036, TASK-037, TASK-039, TASK-046, TASK-052.** No Notes edits required. Each resolves its manifest at execution time and will read the corrected text; TASK-037 in particular now finds a packet spec that accounts for externalized records. This is the intended behavior of manifest resolution — amending the source is the propagation mechanism.

## Files

- `.forge/CONTRACT.md` — `Rules/Traceability` File manifest paragraph rewritten as a two-branch rule; Discovery bullet corrected plus a reverse-lookup command added; `Rules/Checkpoint Cadence` packet bullet updated
- `.forge/SPEC.md` — `[req-checkpoint-packet]` and `[req-unattended-halt-state]` acceptance criteria updated to name both file-list homes
- `.forge/STATUS.md` — dated Decisions row recording the resolution, the rejected alternatives, and the corrected bloat rationale
- `.forge/WORKPLAN.md` — TASK-061 status and Notes
