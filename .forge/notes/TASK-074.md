# TASK-074 — Make the gate-discrimination probe mechanical in wp.js

## Outcome

`wp.js set TASK-XXX status active` now runs the task's gate before performing a `pending → active` transition. A gate that passes against the pre-work tree refuses the transition with exit 4, printing the gate and its output plus the two repair routes (rewrite the gate, or report absorbed scope). The Script Exit Codes table landed in the same diff: the foundation-observation halt in `wp.js next` moved from exit 2 to exit 3, usage text and header document the full 0/1/2/3/4 map.

## Decisions

- **Probe placement:** inside cmdSet's existing `value === 'active'` branch, after the one-active-task check — refusals for a second active task keep their exit 1 and message, so existing consumers see no change there.
- **Gate runner is `bash -c` with cwd = project root and a 300s timeout** — every gate in this project is bash-flavored; `shell: true` would hand gates to cmd.exe on Windows and break `$()` substitutions. A spawn error (bash missing) is a loud exit-1 usage error, not a silent skip — a probe that silently skips is advisory.
- **Exemptions exactly per contract:** `manual:` gates (no command to run), resume of an already-active task (no transition occurs, the branch is never reached), `--force` (the human's override).
- **Fixture discrimination:** the refusal fixture fails with the feature reverted (activation would succeed); the manual/--force fixtures pin the exemptions. Existing fixtures survived because the only successful activations used a failing (`bash tests/test-two.sh` absent) or `manual:` gate — verified rather than assumed.

## Deviations

- None from the amended scope (the 2026-08-30 exit-code addition was planned in).

## Files

- `.forge/scripts/wp.js` — probe, exit-code renumber, usage/header text
- `.forge/tests/test-wp.sh` — probe fixtures, halt assertions moved to exit 3, state restore after the probe block
- `.claude/commands/forge-init.md` — wp.js payload re-copied
