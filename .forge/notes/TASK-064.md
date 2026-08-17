# TASK-064 — Resolve the fresh-gates conflict: records store no gate results

## Outcome

SPEC `req-checkpoint-fresh-gates` required the checkpoint packet to flag "any gate whose fresh result differs from the result recorded when its task completed", but nothing in Forge records a completion-time gate result: `CONTRACT#data-model/task-record-data-model` defines Outcome, Decisions, Deviations, and Files only, `/forge-next` writes no gate output to Notes or records, and tasks under the 3-line externalization threshold have no record at all. The requirement was amended to take the baseline from task status instead: `/forge-next` marks a task `done` only after its gate passes, so `done` already *is* the record that the gate passed at completion, and a gate failing fresh on a `done` task is the flagged regression. No storage was added, no writer changed, and the regression comparison survives intact. Q-005 moved from STATUS.md Open Questions to a dated Decisions row.

## Decisions

- **Derive the baseline from `done` status rather than storing gate results** (human chose this among three options presented). It is not merely cheaper than storing — it is more reliable. `check-workplan.js` validates task status; nothing could validate a hand-written gate-result line against what actually ran, so the stored value could drift from reality in a way the status cannot.
- **Rejected: adding a `## Gate` section to the Task Record Data Model, plus a `Gate-result:` Notes line for inline tasks.** Faithful to the requirement as literally written, but it needs two new writers in `/forge-next`, per-task ceremony, and a lint rule, all to persist a value the DAG already implies. The inline-task case is what makes it genuinely awkward: the fix needs a second home for tasks that never get a record.
- **Rejected: dropping the comparison and reporting fresh results only.** Cheapest, but it discards the requirement's purpose and would force out the acceptance criterion that a span containing a regression is never summarized as clean.
- **Accepted cost:** output *drift* on a still-passing gate is no longer mechanically detectable, since only pass/fail is implied by status. The acceptance criteria now say so explicitly and point at the packet's actual-output reporting as the channel that puts drift in front of the human. This was already the packet's job — the criterion requiring actual output rather than a bare pass/fail predates this task.

## Deviations

- The clarify template's step 4 says to apply the resolution to CONTRACT.md. The fix landed in `.forge/SPEC.md` instead, which the task's own Notes explicitly allowed ("either amend the Task Record Data Model ... or amend the SPEC requirement"). Under Spec Precedence the Contract wins on conflict, so a Contract-side fix would have been the heavier instrument; here the Contract was not wrong about anything — the SPEC had simply asserted a stored artifact the Contract never defined. Nothing in CONTRACT.md was modified.

## Downstream

TASK-035 (build the checkpoint packet) and TASK-037 (execute it in `/forge-next`) are the consumers; both are still `pending` and both declare `SPEC#requirements/req-checkpoint-fresh-gates` in their Context, so they pick up the amended text with no re-scoping. Neither needs a record-model change now, which was the point of the resolution.

## Files

- `.forge/SPEC.md`
- `.forge/STATUS.md`
