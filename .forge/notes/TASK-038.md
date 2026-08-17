# TASK-038 — Create /forge-sync command and .forge/VERSION stamp

## Outcome

Built `.claude/commands/forge-sync.md` (111 lines) and the `.forge/VERSION` stamp (line 1 `0.3.0`, line 2 `https://github.com/jalegood/forge`). The command implements CONTRACT#interfaces/command-forge-sync end to end: read the stamp, clone the canonical repo to scratch, classify each Forge-managed file into the Contract's four states, present the whole summary before asking about any single file, apply only per-file approvals, then restamp. Assertions went into `.forge/tests/smoke.sh` ahead of the file — a `forge-sync.md`/`VERSION` existence check in the command-files section, plus a dedicated block of `prose.js` assertions and two shape checks on the VERSION lines.

## Decisions

- **The stamp's line 1 is the three-way diff baseline, not decoration.** Distinguishing "local-only customization" from "upstream-updated" from "conflicting" — three of the Contract's four classifications — is impossible with a two-way local-vs-upstream diff. So the command clones twice: HEAD, and the tag matching the stamped version. That is what makes the four states decidable, and it is the reason the artifact exists at all.
- **A missing baseline degrades pessimistically.** If the version tag is not fetchable upstream, every differing file is classified `conflicting` rather than guessed at. A two-way diff cannot separate an engine update from the human's own edit, and erring permissive silently destroys customization.
- **The stamp does not advance when the human skips a file.** The Contract says "updates after a successful sync"; a partial sync is read here as unsuccessful. Stamping a version the project is not at would make skipped files read as local customizations on the next run, converting a deferred update into a permanent divergence. The command reports the hold-back and names the files it is waiting on.
- **Project-owned artifacts are stated as an absolute, in three places** (the file-set section, step 5, and Constraints), and the smoke assertions check each of the eight names individually rather than matching one summary phrase. An overwrite of CONTRACT.md or WORKPLAN.md is unrecoverable, so the rule was made expensive to hollow out with a single edit.
- **Test assertions carry the deliverable, not the task gate.** The gate's `grep -qi "never"` matches any prose and `grep -q "VERSION"` matches any fence — it certifies nothing on its own. This is the vacuous-gate pattern already recorded as OBS-013 (`accepted`); no fifth instance was logged, since the pattern is triaged and awaiting a fix to /forge-plan's gate-authoring rule. Both new assertions were negative-tested by mutating the file and confirming the suite fails.

## Deviations

None from the Contract interface. Sync mechanics beyond that interface are deliberately unspecced (SPEC.md, v0.4 scope decisions), so the clone strategy, the scratch-directory rule, and the restamp policy above are choices made here rather than spec compliance — they are the minimum needed to make the four Contract classifications decidable, not a wider design.

## Observations raised

- **OBS-014** — forge-init.md has no VERSION step despite CONTRACT#interfaces/command-forge-init requiring one, so a freshly scaffolded project has no stamp and `/forge-sync` stops at step 1. Out of this task's diff (a different command file); TASK-039's manual gate asserts the behavior and would fail as planned.
- **OBS-015** — the sync globs cover three file classes, but the Artifacts table marks `wp.js`, `prose.js`, `lib/markdown.js`, `lib/workplan.js`, `migrate-notes.js`, and the three `guard-*.sh` scripts Forge-managed as well. None are syncable, so drift in the workplan projection layer cannot be cured by the command that exists to cure drift. Fixing it means editing the Contract, which needs human approval.

## Files

- `.claude/commands/forge-sync.md` (created)
- `.forge/VERSION` (created)
- `.forge/tests/smoke.sh` (modified — forge-sync existence check, contract assertion block, VERSION shape checks)
- `.forge/STATUS.md` (modified — OBS-014, OBS-015)
