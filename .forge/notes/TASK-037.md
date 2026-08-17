# TASK-037 — Update /forge-next to execute checkpoint tasks with review packet

## Outcome

`.claude/commands/forge-next.md` now specifies checkpoint execution end to end. Step 6 gained a `#### Checkpoint tasks` subsection: the span is exactly the checkpoint's `Depends` field (read task-by-task through `wp.js get`, never reconstructed from `git log`), and the packet is spelled out in four ordered parts — the span's tasks with file lists, fresh gate results, STATUS.md quoted inline, and the named rollback. Step 7's manual-gate branch now states that `checkpoint` tasks always take it and present the packet ending in "Does this checkpoint pass? (pass/fail)". Step 8 gained a **Checkpoint fails** branch that marks the checkpoint `blocked`, appends a STATUS.md Blockers row, and forbids the agent from writing the resulting `fix` tasks itself.

`.forge/tests/smoke.sh` gained a matching assertion block (eight `prose.js` invocations) covering the span-from-Depends rule, all four packet elements, fresh-gate re-running with actual output, regression flagging, the never-summarize-as-clean rule, `manual:` gates being listed rather than executed, the Blockers row, and the loop halt.

## Decisions

- **The span comes from `Depends`, not from `git log`.** The Contract's Interfaces bullet phrases the span as "tasks completed since the last checkpoint", which invites re-derivation; Rules/Checkpoint Cadence says the checkpoint's `Depends` lists every task in its span. The written rule wins — a re-derived span silently omits or over-claims tasks, and `Depends` is already the linted record.
- **A failed checkpoint goes to `blocked`, not `active`.** Neither the Contract nor `checkpoint.md` names a status for a failed span, but the one-active-task constraint decides it: an `active` checkpoint prevents any `fix` task from being selected, so the span could never be repaired. `blocked→pending` (Task Lifecycle) is the path back once the human says it is ready to re-run.
- **Assertions go through `prose.js`, not `grep`.** forge-next.md fences the `wp.js` output block, whose `Type:` line already lists `checkpoint` in the enum. The task's own gate matched that fenced enum, so the real assertions had to ignore fences.
- **Strengthened the gate rather than logging its weakness.** `bash .forge/tests/smoke.sh` is part of this task's gate and smoke.sh was in this task's diff, so the in-scope test says fix it here. OBS-013 records the systemic gate-authoring pattern that keeps producing such gates, which is not fixable from inside this task.

## Deviations

- The Contract's Interfaces bullet lists the packet as "tasks completed since the last checkpoint (from WORKPLAN Notes/Files and `git log`)". The implementation reads the span from `Depends` and uses `git log` only to resolve the rollback commit. This is a reconciliation in favor of Rules/Checkpoint Cadence, not an omission — see the first decision above.

## Files

- `.claude/commands/forge-next.md` — checkpoint execution subsection in step 6, checkpoint note on step 7's manual-gate branch, Checkpoint fails branch in step 8
- `.forge/tests/smoke.sh` — checkpoint-execution assertion block
- `.forge/STATUS.md` — OBS-013
