# TASK-059 — Convert /forge-next and /forge-status to wp.js projection

## Outcome

Both commands now obtain workplan data through `.forge/scripts/wp.js` instead of reading `.forge/WORKPLAN.md` into context, and `/forge-next` writes back through the same script instead of hand-editing the document. This is where the token reduction from TASK-058 is actually realized: the project's own workplan is 2,177 lines / ~120K tokens, and neither command loads any of it now — `/forge-next` costs the selected task's fields, `/forge-status` costs a fixed-size summary. `/forge-status` shrank to a script invocation plus report formatting; its output shape from CONTRACT#interfaces/command-forge-status is unchanged apart from two additions the script already returns for free (active task, open observations). New assertions in `.forge/tests/smoke.sh` hold the discipline in place.

## Decisions

- **Steps 1 and 2 of `/forge-next` were split rather than merged.** Step 1 is now acquisition (run `wp.js next`, here is the output shape); step 2 is interpretation (what each `Selection:` value means, what to do with `Warning:` lines, what each exit code means). The old step 2 was a three-branch priority ladder the agent had to execute; the ladder now lives in `lib/workplan.js` `selectTask`, and what remains is the human-facing reaction to its verdict.
- **Every selection rule was re-expressed as a reaction, not deleted.** `resume-active` still instructs reading Notes for continuity and reporting "Resuming TASK-XXX"; unmet dependencies still require asking the human before proceeding; exit 2 still stops with the one-active-task explanation. The script warns rather than refuses on unmet deps, matching the contract's "warns the human and asks for confirmation".
- **Mutations use `append-notes` for accumulation and `set notes` for replacement.** The externalization threshold distinguishes them: a short note is appended to whatever is there, while the one-line summary that replaces a record's narrative supersedes prior content. Documenting only one of the two would have made half the protocol unwritable.
- **The lint paragraph was rewritten rather than dropped.** `wp.js` re-runs `check-workplan.js` internally and reverts on failure, so the instruction changed from "run the linter after writing" to "a nonzero exit means the write did not stand" — the obligation survives, the redundant second invocation does not.
- **`/forge-status` still reads STATUS.md directly for Open Questions and Blockers.** `wp.js status` covers observations and blocked *tasks*, but the two human-authored tables are not workplan data and have no projection. The command says so explicitly to stop an agent from double-reading the Observations table.
- **The negative assertion greps for the literal phrase "in full".** Both files avoid that phrase entirely, including in prohibitions ("never the whole file" is used instead), which keeps the test unambiguous — no positive/negative context parsing, and no way for the legacy instruction to creep back in a reworded form.

## Deviations

- **`/forge-next` still does not implement the Observations bullet from CONTRACT#interfaces/command-forge-next** ("Before selecting a task, reads STATUS.md Observations and reports every `open` row with `foundation` severity"). The command file has never mentioned observations — verified across all eleven commits that touched it. This is not an unowned gap: **TASK-053** owns exactly this work (surfacing at session start, appending at completion, and the unattended hard stop on a new `foundation` row), and it is pending on TASK-031. Left alone here because closing it is behavior addition rather than the acquisition-path conversion this task scoped, and because doing it early would strand TASK-053's gate. An observation row was briefly logged for it and then retracted — the channel captures what would otherwise be lost, and scheduled work is not lost.
- **The `/forge-status` rewrite incidentally satisfies half of TASK-055's gate.** That task requires `observation` to appear in both `forge-status.md` and `forge-plan.md`; the former now does, because `wp.js status` returns observations and suppressing them would have been the larger deviation. TASK-055 still owns the `/forge-plan` intake path and the `accepted`-row planning rule.
- **Two output lines were added to the `/forge-status` report format**, which the task notes asked to keep unchanged: an **Active task** line and an **Open observations** block. Both are things `wp.js status` returns unconditionally and both are named in CONTRACT#interfaces/command-forge-status ("Surfaces STATUS.md Observations: `open` rows, `foundation` severity listed first"). Suppressing data the projection already hands over, to preserve a template that predates it, would have made the report worse than the contract requires.

## Files

- `.claude/commands/forge-next.md` — steps 1, 2, 4, and 8 converted to `wp.js`; intro and Constraints updated with the projection rule
- `.claude/commands/forge-status.md` — rewritten around `node .forge/scripts/wp.js status`
- `.forge/tests/smoke.sh` — new "workplan access discipline" section asserting projection on both command files
- `.forge/WORKPLAN.md` — TASK-059 status and Notes

## Follow-up audit (same session, no task ID)

Prompted by a question about the observations deviation above. Findings and changes, recorded here because there is no other durable home for them:

- **The observation channel has no write path at all.** All 7 templates, `forge-next.md`, and `forge-plan.md` contain zero mentions of observations. Only the read side exists (`wp.js`, and `forge-status.md` as of this task), so `/forge-status` reads a table nothing can fill. TASK-053/054/055 own the write path; none had run.
- **`CONTRACT#rules/unattended-execution` hard stops are entirely unimplemented.** `forge-next.md` has no notion of a loop and does not halt on a checkpoint task, a clarify task, a task entering `blocked`, a second consecutive gate failure, or a new `foundation` observation. Headless consecutive runs currently have no brake. Left unfixed — TASK-053 and TASK-037 own parts of it.
- **Two pending gates were false passes** — they would have marked their task `done` in a headless run without the deliverable existing:
  - TASK-031 (`/forge-init` creates the STATUS.md stub): both greps matched the embedded `wp.js` source that TASK-058 pasted into `forge-init.md`. That file is now 88% fenced payload by line count, so any single-token grep against it is unreliable. `/forge-init` creates no STATUS.md stub.
  - TASK-036 (`/forge-plan` inserts checkpoint tasks at cadence): `grep -qi "checkpoint"` matched only the `- **Type:** scaffold | feature | … | checkpoint` enumeration inside a fenced example.
- **TASK-033 also already passes, but genuinely** — its deliverable (`/forge-status` surfacing Open Questions and Blockers) was built as part of this task's rewrite. It is real work awaiting a status change, not a false pass. Flagged for the human; not marked `done`, since only a human closes a task nobody executed.
- **Added `.forge/scripts/prose.js`** — greps a markdown file's prose while ignoring fenced blocks — and repointed TASK-031, 036, 053, and 055 at it so each gate verifies its own deliverable. `.forge/tests/test-prose.sh` covers it and runs from `smoke.sh`. TASK-062's Notes now require `/forge-init` to provision it.
- **Reordered the workplan** so TASK-031 → 053 → 054 → 055 sit immediately before TASK-060. The chain was at lines 461–611 behind roughly twenty tasks, and TASK-046 (the checkpoint that would trigger observation triage) sat *after* all of it. Task content was diffed before and after the move: 62 tasks in, 62 out, every field identical — order only.
