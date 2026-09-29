# TASK-062 — Make /forge-init provision check-workplan.js and lib/markdown.js

## Outcome

`/forge-init` now creates `.forge/scripts/lib/markdown.js` and `.forge/scripts/check-workplan.js` as a new unconditional step 10, following the `check-ux-spec.js` embedding precedent. Before this, neither file was provisioned anywhere, so every project except this one ran `/forge-next` and `/forge-plan` with a lint step that fails on "module not found" — at a point both commands document as a hard block. A new drift test, `.forge/tests/test-init-scripts.sh`, diffs each embedded payload against the live script and fails on any difference. The provisioned scripts were verified end-to-end by extracting them into a scratch project and running the lint there: it passed a valid workplan and correctly rejected an unresolvable context reference.

## Decisions

- **Inlined both scripts, growing forge-init.md from 670 to 1,152 lines.** Put to the human as a scope question; they chose inlining over deferring to plugin packaging (TASK-041). Inlining keeps the Contract's "Reads: nothing (creates from built-in templates only)" true and fixes the bug now, at the cost of a command file that roughly doubled.
- **Appended as step 10 rather than inserted before the step 5 interface question.** Inserting mid-file would have required renumbering five headings and nine cross-references, and those references are ambiguous — `### 5` (the UI question) and item 5 of the trailing next-steps list are both called "step 5" in prose. A botched renumber is a worse defect than imperfect step ordering. Only `### 10. Report completion` was renumbered, to 11; nothing references step 10 or 11.
- **The test diffs content rather than grepping for filenames.** An embedded copy is a second copy of a live file that nothing executes, so it can go stale silently. `grep -q check-workplan.js` would pass against a payload three versions old. Verified the test is not vacuous by appending a line to `markdown.js` and confirming a nonzero exit, then reverting.
- **Marked each payload with `<!-- forge-init:embed <path> -->`.** The test keys on these markers rather than on prose or fence position, so rewording the surrounding instructions cannot silently disable the check. The marker also signals to a human editor that the block is machine-verified.
- **Line endings normalized (`tr -d '\r'`) before diffing.** This repo checks out CRLF on Windows while the scripts are stored LF; without normalization the test would fail on every machine for the wrong reason.

## Deviations

- **CONTRACT.md was amended before the task ran, not during it.** The `/forge-init` interface bullet named `check-workplan.js` but not `lib/markdown.js`, which TASK-050 extracted after that bullet was written. The human approved tightening it to name both as a separate one-line edit, so the task began with full Contract coverage rather than drafting it mid-execution. The task's own Notes had flagged this as non-blocking.

## Verification beyond the gate

The gate proves the embedded copies match the originals; it does not prove a provisioned project works. Checked separately by building a scratch project from the embedded payloads alone: `node .forge/scripts/check-workplan.js` validated a well-formed workplan (exit 0, manifest reference resolved against a stub CONTRACT.md) and rejected `CONTRACT#no-such-section` with a correct error (exit 1). The scratch project was deleted afterward.

## Files

- `.claude/commands/forge-init.md` — new unconditional step 10 embedding both scripts with `forge-init:embed` markers; former step 10 renumbered to 11; both paths added to the created-files summary list
- `.forge/tests/test-init-scripts.sh` — new drift test (created; untracked before this commit)
- `.forge/CONTRACT.md` — `Interfaces/Command: /forge-init` bullet tightened to name `lib/markdown.js` alongside `check-workplan.js`
- `.forge/WORKPLAN.md` — TASK-062 status and Notes

Note: `.claude/commands/forge-next.md` also appears in this span's diff, from the fence-awareness caveat added to its step 3 outside any task.
