# TASK-058 — Create wp.js deterministic workplan query and mutation script

## Outcome

`.forge/scripts/wp.js` is the deterministic access path to WORKPLAN.md required by CONTRACT#rules/workplan-access-discipline. It supports five commands — `next [TASK-XXX]`, `get TASK-XXX`, `status`, `set TASK-XXX <field> <value>`, and `append-notes TASK-XXX <text>` — each emitting either readable `Field: value` text or, with `--json`, a structured object. The full task-selection rule set from CONTRACT#interfaces/command-forge-next now lives in code: resume-active, explicit-ID override, unmet-dependency warning, one-active-task refusal, and first-unblocked-pending in file order.

Parsing moved into a new shared module, `.forge/scripts/lib/workplan.js`, and `check-workplan.js` was refactored onto it, so one parser serves both the linter and the tool that writes the file the linter validates. `/forge-init` now provisions all four engine scripts. The commands themselves still read WORKPLAN.md in full — converting them is TASK-059; this task builds the machinery they will call.

## Decisions

- **Parsing extracted to `lib/workplan.js` rather than imported from `check-workplan.js`.** The task's Notes required reusing the existing parser; `check-workplan.js` is a top-level script with side effects (it reads the file and calls `process.exit`), so it cannot be required as a module. Extraction was the only way to satisfy "one parser" — the same move TASK-050 made for markdown resolution.
- **Line-based parser instead of the previous regex-over-the-whole-file.** Mutation needs exact line ranges so `set` can rewrite one field and leave every other byte identical; the test asserts a single-field `set` produces exactly one changed line. The parser is fence-aware, matching `lib/markdown.js`.
- **Fields are multi-line by default.** Any line in a task body that is not itself a field line continues the field above it, so `Notes` carries its full multi-line value. Trailing blank lines are excluded — they belong to document spacing, not the field, and including them would make `set` eat the separator between tasks.
- **Every mutation is re-linted, and reverted on failure.** `wp.js` writes, spawns `check-workplan.js`, and restores the original bytes if the lint fails. This makes the contract's "check-workplan.js must pass after every mutation" an enforced property rather than a convention. A test asserts a lint-breaking `set` leaves the file untouched on disk.
- **Lifecycle transitions enforced on `set status`, with `--force`.** CONTRACT#state-machines/task-lifecycle names the four legal transitions; the script refuses the others so it cannot walk the workplan into a forbidden state. `--force` exists for a human deliberately rewriting history.
- **One-active-task enforced on write, not only on read.** A script that can create a second active task has dropped the invariant it was meant to carry over from `/forge-next`.
- **Exit codes distinguish "nothing to select" from "you asked wrong."** 0 success, 1 usage/validation error, 2 nothing selectable (active-task conflict, no unblocked pending task). Unmet dependencies are a warning on exit 0, not a stop — the contract says warn and ask the human, not refuse.
- **Text output by default, `--json` on request.** Plain `Field: value` lines are cheaper in tokens than JSON for the agent that consumes them, with `Notes:` printed last and verbatim so a multi-line value needs no escaping. `--json` serves tests and any future scripted consumer.

## Deviations

- **`/forge-init` step 10 was rewritten beyond the task's stated scope.** Refactoring `check-workplan.js` onto `lib/workplan.js` broke `test-init-scripts.sh`, which diffs the script payloads embedded in `.claude/commands/forge-init.md` against the live files. Re-syncing the drifted payload was mandatory; while there, the step also gained `lib/workplan.js` (without it the embedded `check-workplan.js` crashes on require in any newly scaffolded project) and `wp.js` (the contract already routes `/forge-next` and `/forge-status` through it). The step header and the step-11 completion list were updated to match, and the drift test now checks all four payloads.
- **No change to `.claude/commands/forge-next.md` or `forge-status.md`.** They still read WORKPLAN.md in full. That conversion is TASK-059's scope and is what actually realizes the token reduction; this task delivers only the script those commands will call.
- **`status` reads STATUS.md Observations but not Open Questions or Blockers.** The task Notes scope `status` to counts, next unblocked, clarify tasks, and open observations. `/forge-status` reads the other STATUS.md sections itself; they are small and need no projection.

## Files

- `.forge/scripts/wp.js` (created)
- `.forge/scripts/lib/workplan.js` (created)
- `.forge/tests/test-wp.sh` (created)
- `.forge/scripts/check-workplan.js` (refactored onto the shared parser)
- `.claude/commands/forge-init.md` (step 10 rebuilt; step 11 list updated)
- `.forge/tests/test-init-scripts.sh` (checks all four embedded payloads)
- `.forge/WORKPLAN.md` (TASK-058 status and notes)
