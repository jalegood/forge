# Checkpoint Task

You are executing a **checkpoint** task. Your job is to assemble a review packet for the span of tasks this checkpoint closes, present it, and stop. This task produces no code.

## Task

**ID:** {{task_id}}
**Description:** {{task_description}}
**Gate:** `{{gate}}`

## Contract Context

{{context}}

## Instructions

The span is exactly the task IDs in this checkpoint's `Depends` field. Read each one through the projection — `node .forge/scripts/wp.js get TASK-XXX` — never by opening WORKPLAN.md.

1. **Assemble the span.** For each task in `Depends`, give its ID, description, and file list. The file list is the `Files:` line in its Notes when the notes are inline, or the `## Files` section of `.forge/notes/TASK-XXX.md` when the Notes name a record.
2. **Re-run every automated gate in the span, fresh.** Status alone is not evidence — a later task in the span can silently break an earlier task's gate, which is the entire reason this checkpoint exists. Report each gate with its **actual output**, not a bare pass/fail.
   - A gate that fails fresh on a task whose status is `done` is a **regression** — flag it explicitly. `/forge-next` marks a task `done` only after its gate passes, so `done` is the record that it passed at completion; no stored result exists to compare against, and none is needed.
   - **Never summarize a span containing a regression as clean.** One regression outranks any number of passes in the summary line.
   - Gates whose value begins with `manual:` are **listed with their verification steps, not executed.** Running them is the human's job at this checkpoint.
3. **Excerpt `.forge/STATUS.md` into the packet** — quote the rows, never cite the file by reference:
   - Open Questions (all rows, flagging any marked Blocking) and Risks (all rows).
   - Open Observations rows, `foundation` severity first.
   - Any Decisions entry (dated section) inside the span that records a mid-span course correction — a redirect the human made mid-flight is the thing least likely to be remembered and most likely to need review.
4. **Name the rollback.** Give the span's starting commit and the one command that undoes the span. Resolve the commit with `git log --format='%H %s' | grep -F '(TASK-FIRST)'` for the span's first task, then take its parent (`<sha>^`); if the span's tasks were not committed individually, use the merge-base with the branch the span started from. State plainly that the command discards the span's work — the human runs it, you never do.
5. **The packet must stand on its own.** The human passes or fails this span by reading what you present and nothing else. Any sentence that sends them to a file to find out what happened is a defect in the packet, not a reference.
6. **Record what you noticed but did not fix.** Apply the in-scope test: if the fix is covered by this task's gate and belongs in this task's diff, make it now — no observation needed. Otherwise record one row through `.forge/scripts/obs.js` and move on. This channel captures what would otherwise be lost, not what would otherwise be fixed; most tasks produce no rows at all, and that is the expected case rather than a gap to fill.
   - Record it by invoking the script — never by writing the row yourself:

     ```bash
     node .forge/scripts/obs.js add --kind design|bug|scope|friction --severity normal|foundation --task {{task_id}} "One-line observation."
     ```

     `obs.js` mints the ID against the file at write time, stamps the date, escapes the text, and re-validates before the write stands. A hand-written row is how a literal `|` reaches a cell and silently removes the row from every reader — including the hard stop that reads it.
   - One line per observation — a pointer, not a report.
   - No observation spawns a task on its own. Only a human promotes one, later.
   - More than three from this task collapse into a single `foundation` row: volume of small complaints is itself the signal that the foundation is wrong, and recording it as volume buries that signal.
   - `foundation` means the spec, contract, or approach is suspect and continuing to build compounds debt. Everything else is `normal`.

## Completion

The gate is `manual:` — the human approves the span. Confirm the gate command before reporting completion, then:

1. Present the packet and **end it with an explicit pass/fail question**: "Does this checkpoint pass? (pass/fail)".
2. **Stop and wait.** Do not select further work, do not mark this task `done`, and do not commit. An unanswered packet blocks every downstream task by construction — that is the checkpoint doing its job, not a stall.
3. If the human **passes** the span: report success and suggest a commit message.
4. If the human **fails** the span: record what failed and what they directed — `fix` tasks, a workplan edit, or a rollback — in the `Notes` field via `node .forge/scripts/wp.js append-notes {{task_id}} '...'`. You do not add tasks to the workplan yourself.
5. If you **cannot finish assembling the packet** in this session, append to `Notes` with:
   - Which span tasks are already summarized and which gates you have re-run
   - What remains to assemble
   - Any regression already found, so it is not lost if the session ends here
