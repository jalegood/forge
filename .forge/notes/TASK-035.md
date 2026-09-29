# TASK-035 — Create checkpoint.md template and add to /forge-init template set

## Outcome

`checkpoint` was the one task type in `CONTRACT#interfaces/task-types` with no prompt template, so `/forge-next` would have hit its "Template file missing" hard stop the moment a checkpoint task was selected. Created `.forge/templates/checkpoint.md` and embedded the same body in `/forge-init` as an eighth template block, bringing the unconditional set to seven (ux-spec remains conditional on the UI question). The template instructs the agent to assemble the span from the checkpoint's `Depends` field via `wp.js get`, re-run every automated gate fresh, excerpt STATUS.md rather than cite it, name the rollback commit and command, and end with an explicit pass/fail question and a full stop. It produces no code.

## Decisions

- **The span is read through `wp.js get`, one task at a time, not by opening WORKPLAN.md.** A checkpoint touches every task in its span, which is exactly the shape of read that `CONTRACT#rules/workplan-access-discipline` exists to prevent — the one command with a legitimate reason to want the whole file is the one that must not read it.
- **Regression detection is phrased as "fails fresh on a `done` task,"** carrying TASK-064's resolution of `req-checkpoint-fresh-gates` into the template's own wording. The template states *why* — `done` is itself the record that the gate passed — so an agent reading only this template does not go looking for a stored gate result that does not exist.
- **"Never summarize a span containing a regression as clean" is stated as an ordering rule** ("one regression outranks any number of passes in the summary line") rather than a prohibition. The failure mode is a packet whose headline says "12 of 13 gates pass" while burying the regression, and a bare prohibition does not tell the agent what to write instead.
- **Step 5 makes self-containment a defect test rather than an aspiration:** any sentence sending the human to a file to learn what happened is a defect in the packet. `req-checkpoint-self-contained` is otherwise unfalsifiable at authoring time — an agent cannot check "could a human judge this without opening anything" but can check "did I write a pointer."
- **`checkpoint` was added to `test-templates.sh`'s `TEMPLATES` array.** The observation step is mandatory in every template per `CONTRACT#interfaces/prompt-template-interface`, and both copies of a new template drift immediately if nothing asserts them. This also closes OBS-002, which was declined on the grounds that this task was its deliverable.
- **The rollback commit is resolved from `git log` by the task-ID commit suffix, with a merge-base fallback** for spans that were not committed per task. The template states that the human runs the rollback and the agent never does, since the resolved command is destructive.

## Deviations

- `CONTRACT#interfaces/prompt-template-interface` says templates are ~30-50 lines; this one is ~55. The packet contents are enumerated across `Rules/Checkpoint Cadence` and `req-checkpoint-self-contained` — span tasks with file lists, fresh gate output, manual gate steps, four STATUS.md excerpts, rollback, and the pass/fail stop — and dropping any of them drops an acceptance criterion. The overage is the enumeration, not commentary.

## Files

- `.forge/templates/checkpoint.md` (new)
- `.claude/commands/forge-init.md`
- `.forge/tests/test-templates.sh`
- `.forge/STATUS.md`
