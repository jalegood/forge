# TASK-036 — Update /forge-plan to insert checkpoint tasks at cadence

## Outcome

`/forge-plan` now generates `checkpoint` tasks. Step 4 gained a **Checkpoint cadence** subsection, applied once the DAG is ordered: a checkpoint lands at each dependency-phase boundary or after every 5 consecutive non-checkpoint tasks, whichever comes first, with the run length resetting at each checkpoint. Each inserted checkpoint carries the whole span in `Depends`, and downstream tasks depend on the checkpoint rather than on the span's individual tasks — that substitution is what makes the DAG halt until a human passes the packet. `checkpoint` was also missing from the command's task-types table entirely, so it was not a type `/forge-plan` could emit at all before this change.

The gate as declared (`prose.js forge-plan.md "checkpoint" "cadence"`) is two bare words, so the real assertions went into `smoke.sh`, which the gate runs first. That block checks both cadence triggers, which one wins, that counting excludes checkpoints, that `Depends` names every task in the span, that downstream tasks depend on the checkpoint, and that the gate is `manual:`. Verified failing before implementation and passing after.

## Decisions

- **Assertions live in `smoke.sh`, not in the declared gate.** The task's own gate string is too weak to distinguish the deliverable from a passing mention of two words. Putting them in `smoke.sh` also means every other gate that runs the suite picks them up — the pattern the forge-spec and forge-status blocks already established.
- **Asserted through `prose.js` rather than `grep`.** `forge-plan.md` fences its task-format block, whose `Type` line already listed `checkpoint` in the enum. A plain grep would have matched that fenced template and reported the generation rule present when only the enum was.
- **A generated checkpoint's `Context` is `CONTRACT#rules/checkpoint-cadence`, and nothing else.** The span arrives through `Depends`, so enumerating it in the manifest would duplicate state that is already load-bearing elsewhere. This resolves cleanly under `check-workplan.js` invariant 5.
- **Cadence counts forward from the last preserved checkpoint.** Step 3 preserves `done` and `active` tasks verbatim; without this, a re-run would re-span a checkpoint a human had already passed. Stated explicitly in the new subsection.
- **The gate text names the span** (`manual: Review TASK-004..TASK-008 — ...`). `check-workplan.js` invariant 7 only enforces the `manual:` prefix; naming the span is what makes the workplan readable without opening the checkpoint's template.

## Deviations

- Added `checkpoint` to the DESIGN and SPEC manifest exclusion lists in step 5, and a Checkpoint span row to the gate table in step 6. Both are past the literal task description, but both enumerate task types by name and were made incomplete by this task introducing a type to the file. Leaving them would have shipped a known inconsistency in the same document the task edits.

## Files

- `.claude/commands/forge-plan.md` — checkpoint cadence subsection (step 4), `checkpoint` row in the task-types table, gate table row (step 6), `checkpoint` added to the DESIGN and SPEC manifest exclusion lists (step 5)
- `.forge/tests/smoke.sh` — new "forge-plan checkpoint cadence" assertion block
- `.forge/STATUS.md` — OBS-012
- `.forge/WORKPLAN.md` — TASK-036 status and notes, via `wp.js`
