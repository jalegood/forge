# TASK-063 — Make the foundation-observation hard stop mechanical in wp.js

## Outcome

`wp.js next` now refuses to select a task while an open `foundation`-severity row exists in STATUS.md Observations, exiting 2 and printing the offending rows with the reason and the two ways out. `CONTRACT#rules/unattended-execution` was amended to say the stop is mechanical rather than advisory, and `/forge-next` step 2 gained a third exit-2 case explaining it. Hard stop 4 previously existed only as a sentence an agent was expected to act on against its own momentum; it now has the same standing as rules 1 and 3, which the branch and push guard hooks enforce.

## Decisions

- **Refusal lives in `wp.js next`, not in the `/forge-next` prompt.** Task selection is the chokepoint every headless iteration passes through, and it was already deterministic and script-owned (Vision pillar 2). Enforcing at the prompt layer would have reproduced the defect being fixed: an instruction the executing agent can decline to follow.
- **`resume-active` is exempt.** The contract has the current task finish cleanly first, so refusal applies to selecting *new* work. Without the exemption, a foundation observation logged mid-task would strand that task — unresumable — which is a worse failure than the one being prevented.
- **The designed exit is triage, not override.** Moving the row's Disposition off `open` to `accepted` or `declined` is what clears the stop, which is what turns the Observations table into a queue rather than a log. `--force` exists for the human who has read the row and chooses to continue; `/forge-next` explicitly forbids the agent from passing it or from editing a Disposition to clear its own path.
- **Severity is the only trigger.** `normal`-severity rows never halt, no matter how many accumulate. The contract already routes volume into severity — more than three observations from one task collapse into a single `foundation` row — so counting rows here would double-count that signal.
- **The halt reports rows inline rather than pointing at STATUS.md.** A halt whose reason requires opening another file is one an operator skips reading.

## Deviations

- **The `--force` flag on `next` is new surface the task notes did not name.** Without it the only exit from a stop would be editing STATUS.md, which is a poor fit for the human who has already decided to continue; the contract amendment names the flag, so the two are consistent.
- **`.claude/commands/forge-init.md` was re-embedded.** It carries `wp.js` verbatim as an embed payload, so changing the script broke `test-init-scripts.sh` until the block was re-copied. Mechanical, but it means every `wp.js` change is a two-file change.
- **A wording change in `/forge-next` was forced by a test written one task earlier.** The phrase "relay them in full" tripped the blanket `in full` assertion added in TASK-059 to keep the old "read WORKPLAN.md in full" instruction from returning. The assertion is deliberately literal and the prose changed instead — worth knowing before someone loosens the test to accommodate a future sentence.

## Verification

Seven new cases in `test-wp.sh` cover: halt on open `foundation` row, no bypass via explicit task ID, `--force` override, `resume-active` exemption, stop clearing when the row is triaged to `accepted`, `normal` severity never halting, and `status` remaining a pure read that reports the stop without enforcing it. All six suites pass. Live-fire checked against this repo's own workplan by appending a temporary `foundation` row: selection halted with exit 2, `--force` proceeded, and the row was removed with STATUS.md verified byte-identical afterward.

## Files

- `.forge/CONTRACT.md` — Rules/Unattended Execution: the mechanical-enforcement paragraph for hard stop 4
- `.forge/scripts/wp.js` — halt in `cmdNext`, `--force` parsing, usage text
- `.forge/tests/test-wp.sh` — seven hard-stop cases
- `.claude/commands/forge-next.md` — third exit-2 case in step 2
- `.claude/commands/forge-init.md` — re-embedded `wp.js` payload
- `.forge/WORKPLAN.md` — TASK-063
