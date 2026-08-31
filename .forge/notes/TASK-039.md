# TASK-039 — End-to-end validation of v0.3 pipeline

## Outcome

The v0.3 pipeline was validated in a scratch project built **from `/forge-init`'s embedded payloads alone** — 22 payloads extracted by marker and run without touching this repo's copies, so what was tested is what a new project actually receives. All six gate criteria pass. One defect found and recorded as OBS-020; no blocking failures.

## Method

Extracted every `<!-- forge-init:embed -->` payload into a scratch tree (12 scripts, 8 templates, plus the STATUS/VERSION/CONTRACT/SPEC stubs written per the command's steps), then exercised the pipeline against a three-task fixture workplan carrying a `SPEC#` manifest and a checkpoint task.

## Findings against the gate's six criteria

1. **Scaffold completeness — PASS.** 12 scripts and 8 templates extract and run; `.forge/VERSION` holds exactly two lines (stamp, repo URL). Every script executes from the extracted copy — the payloads are not merely present, they work.
2. **Spec readiness — PASS (mechanical half).** `check-spec.js` validates a scratch SPEC.md with EARS requirements and bracketed req-slugs at its strict default. `check-status.js` accepts the stub, confirming TASK-088's column fix: a stub whose columns disagreed with the Data Model would make every `obs.js` write malformed on arrival.
3. **Planning — PASS.** `check-workplan.js` accepts a plan carrying `SPEC#requirements/req-*` manifests and a `checkpoint` task with a `manual:` gate.
4. **Manifest resolution — PASS.** All three reference forms resolve against the scratch files through `lib/markdown.js`: `SPEC#requirements/req-widget-create` (bracketed req-slug), `CONTRACT#data-model/widget`, `CONTRACT#rules/widget-naming`.
5. **Status surfacing — PASS.** `wp.js status` reports counts, next unblocked, clarify, blocked, observations; `wp.js graph` reports the three-layer shape and the startable set.
6. **Unattended hard stops — PASS, all four exercised live:**
   - **Gate-discrimination probe:** with `widget.js` already present, activating TASK-001 was refused with exit **4** and the gate printed. Removing the file let the same transition proceed — the probe discriminates rather than always-refusing.
   - **Foundation halt:** a `foundation` row raised through `obs.js add` halted `wp.js next` with exit **3**, printing the row.
   - **Triage clears it:** `obs.js set OBS-001 disposition accepted` unblocked selection immediately — the designed exit works without `--force`.
   - **Push guard:** exits **2** on a `git push` payload. (Noted in passing: the guard also blocked the *validation command itself* when the literal appeared in a compound shell line — correct behavior, and a live demonstration that it catches embedded pushes.)

## Defect found

**OBS-020 (normal, design):** `check-workplan.js`'s `hasTestInvocation` recognizes `test-*.sh` and `tests/` but not a root-level `test.sh` / `./test.sh` — a common convention. A project using it cannot satisfy invariant 6 for any `feature`/`fix` task without renaming its runner. Recorded rather than fixed: this task's gate is `manual:` and its deliverable is findings, so the fix belongs in a task of its own (the in-scope test from CONTRACT#data-model/status.md-data-model).

## What this did not validate

The interactive halves of criteria 2 and 4 — `/forge-spec`'s intake interview and `/forge-next`'s checkpoint packet assembly — are agent behaviors driven by command prose, not scripts, and cannot be exercised by running a scratch project's files. Their mechanical halves (the gate script, the manifest resolution, the `manual:` gate handling, packet assembly) are covered here and by `smoke.sh`'s prose assertions; the conversational halves have been exercised repeatedly during this run's own execution, including three checkpoint packets assembled by this pipeline.

## Files

- No repository files changed. Scratch tree was disposable; OBS-020 recorded in `.forge/STATUS.md`.
