# TASK-076 — Repair three gates that cannot fail

## Outcome

Three structurally unfailable checks repaired: (1) forge-plan.md's VISION stub detection literal now matches the stub forge-init actually writes (`Describe what this project builds`); (2) the screen-mapping gate form `grep -c ... | awk '$1 >= N'` — whose pipeline exit is awk's unconditional 0 — replaced with `test $(grep -c ...) -ge N` at both forge-plan.md sites and in CONTRACT#interfaces/command-forge-plan; (3) check-spec.js now rejects a missing or non-numeric `--max-unresolved` value as a usage error instead of letting `count > NaN` silently disable the unresolved-marker check.

## Decisions

- Test-first honored on item 3: fixture 5c (missing value, non-numeric value) written first and confirmed failing against the unfixed script.
- The CONTRACT edit is the amendment the task notes pre-authorized; verified no existing workplan task carries the awk gate form, so no downstream fix tasks are owed.
- check-spec.js's forge-init payload re-copied (it became marker-diffed in TASK-069).

## Files

- `.claude/commands/forge-plan.md` — stub literal, two awk sites
- `.forge/CONTRACT.md` — mapping-gate form
- `.forge/scripts/check-spec.js` — Number.isFinite guard
- `.forge/tests/test-check-spec.sh` — fixture 5c
- `.claude/commands/forge-init.md` — check-spec.js payload re-copy
