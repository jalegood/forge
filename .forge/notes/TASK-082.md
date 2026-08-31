# TASK-082 — Build check-status.js and bring the live STATUS.md under it

## Outcome

`check-status.js` validates STATUS.md deterministically: the four tables' columns against the Data Model skeletons in order, every row's cell count (a malformed row is an error, never a dropped row), Observation ID uniqueness/monotonicity, the Kind/Severity/Disposition enums, `planned:`→existing-task and `duplicate:`→non-duplicate-row link integrity, ISO dates, the accepted-age warning, and the Decisions dated-section heading shape. The live Observations table gained its mandated Date column in the same diff (dates recovered from each row's introducing commit), and passes.

## Decisions

- **wp.js's `readObservations` converted to the header-keyed parser in this diff** — not optional: positional reading would have shifted every cell one right when Date landed, read Kind as Severity, matched no `open` row, and silently disarmed the foundation halt. This is the exact scenario `CONTRACT#data-model/markdown-table-parsing` documents, including why test-wp.sh's six-column fixtures must keep passing (they now simply lack a Date cell).
- **wp.js fails closed on a malformed Observations table** (usage-error exit with a pointer at check-status.js) rather than proceeding on partial rows — a malformed row may *be* the open foundation row.
- **Accepted-age "one checkpoint span" operationalized as 7 days** (cadence of 5, one task per session); a constant with the reasoning in a comment.
- **Live-file coverage is fixture 11** — the suite ends by linting the real STATUS.md, so the migration and the lint land green together (the headless-run pre-commit breaker arms check-status.js the moment the file exists).
- OBS-001..009's recovered date is 2026-08-16 (the triage commit that introduced their rows), not the dates their raising tasks ran — the row's Date column records when the row was recorded, which is what the age computation wants.

## Files

- `.forge/scripts/check-status.js` (new)
- `.forge/tests/test-check-status.sh` (new, 11 fixtures)
- `.forge/STATUS.md` — Date column migration
- `.forge/scripts/wp.js` — header-keyed readObservations, fail-closed
- `.forge/tests/smoke.sh` — suite wired
- `.claude/commands/forge-init.md` — wp.js payload re-copied
