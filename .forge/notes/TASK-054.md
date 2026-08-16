# TASK-054 — Add the observation step to all prompt templates

## Outcome

Every prompt template now closes its Instructions list with the same observation step, satisfying CONTRACT#interfaces/prompt-template-interface's requirement that each template carry "an instruction to record out-of-scope findings as STATUS.md Observations rows, applying the in-scope fix test rather than logging reflexively." The step is byte-identical across all templates — only its list number changes — and it carries the in-scope fix test, the STATUS.md row format, and the three anti-ceremony constraints from CONTRACT#data-model/status.md-data-model.

Fourteen copies were updated, not seven: the seven live templates under `.forge/templates/`, plus the seven template bodies embedded in `/forge-init`, which are what a *new* Forge project receives. A new test, `.forge/tests/test-templates.sh`, pins both sets and runs from `smoke.sh`.

## Decisions

- **The step reads as an instruction to fix, not a prohibition on acting.** The wording is "Record what you noticed but did not fix" followed by the in-scope test — if the fix is covered by this task's gate and belongs in this task's diff, make it now. Framing it as "record, never act" would push agents to write memos instead of one-line fixes, which is the failure mode the task was written to avoid.
- **Added the sentence that most tasks produce no rows.** CONTRACT#interfaces/prompt-template-interface asks for the fix test "rather than logging reflexively"; without stating that an empty Observations table is the expected outcome, a template that ends by asking for observations reads as a quota.
- **The row format is inline code, not a fenced block.** The template bodies live inside ```markdown fences in `forge-init.md`, so a nested fence would terminate the outer one. A single backticked line carries the same information and survives embedding.
- **Extended the change to `/forge-init`'s embedded templates.** The task gate only inspects `.forge/templates/*.md`, but those blocks are the same artifact for every project that has not been built yet — leaving them alone would ship a contract-violating template set to every new project while this repo's own copies complied.
- **Wired the new test into `smoke.sh` rather than leaving it standalone.** `smoke.sh` is the first clause of this task's gate and of several others, so the check runs wherever those gates run. This follows the precedent already set by `test-prose.sh` and `test-markdown.sh`.
- **The test asserts wording, not just the presence of "Observations".** The gate's `grep -l "Observations" | wc -l` clause is satisfied by the word alone. Eight fixed phrases are checked instead, one per mandatory element of the Observations spec, plus a negative check that the prohibition framing has not crept back in.

## Deviations

- **`investigate.md` lost a second piece of language beyond the one the task named.** The task specified replacing instruction 5 ("recommend specific follow-up tasks... with enough detail that they could be added to the workplan"). Its Completion section also listed "Proposed follow-up tasks with brief descriptions" as a Notes field entry — the same orphaned channel, one section down. That became "Recommended next steps, written as findings for the human — you do not add tasks to the workplan yourself." The `forge-init` copy of the same template carried the variant "draft task entries for the human to add to WORKPLAN.md" and was replaced outright by the observation step.
- **The manual-gate line in `investigate.md` was left intact.** "If the gate is `manual:`, present your findings and proposed next steps to the human for review" still stands. A manual gate means a human is present and reading, so that proposal has a real recipient — unlike the workplan-drafting language, which addressed a human who is absent during an unattended span.
- **Gate threshold interpretation.** The task's `-ge 7` threshold anticipated that `checkpoint.md` might have landed via TASK-035. It has not; `.forge/templates/` holds exactly seven files (six unconditional plus `ux-spec.md`), all seven of which now carry the step. When TASK-035 adds `checkpoint.md`, `test-templates.sh`'s `TEMPLATES` array must gain a `checkpoint` entry — the array is explicit, not a glob, so a new template will not be silently exempted, but it will also not be checked until it is listed.

## Files

- `.forge/templates/scaffold.md` — observation step added as instruction 6
- `.forge/templates/feature.md` — added as instruction 8
- `.forge/templates/fix.md` — added as instruction 7
- `.forge/templates/clarify.md` — added as instruction 5
- `.forge/templates/refactor.md` — added as instruction 6
- `.forge/templates/investigate.md` — replaced instruction 5; Completion bullet reworded
- `.forge/templates/ux-spec.md` — added as instruction 6
- `.claude/commands/forge-init.md` — same step added to all seven embedded template bodies
- `.forge/tests/test-templates.sh` — new; pins the step's wording across both copies
- `.forge/tests/smoke.sh` — runs the new test
- `.forge/STATUS.md` — OBS-003 appended
