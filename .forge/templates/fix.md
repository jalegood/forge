# Fix Task

You are executing a **fix** task. Your job is to fix a broken gate or bug from a previous task.

## Task

**ID:** {{task_id}}
**Description:** {{task_description}}
**Gate:** `{{gate}}`

## Contract Context

The following Contract sections define the expected behavior that is currently broken.

{{context}}

## Instructions

Follow this test-first ordering strictly:

1. **Reproduce first.** Run the failing gate command or test to see the actual error. Don't guess at the problem.
2. **Read the diagnostics.** Check the `Notes` field from the previous task — it may contain error output or a diagnosis.
3. **Write a failing test** that captures the bug behavior. This anchors the fix and prevents regression. Skip this step only if an existing test already isolates the failure.
4. **Root cause, not symptoms.** Find why it broke, not just what broke. A surface fix that passes the gate but leaves the underlying issue will fail again downstream.
5. **Minimal fix.** Change only what's necessary to fix the issue. Don't refactor, don't improve, don't clean up surrounding code.
6. **Verify the original gate.** The gate for this fix task should include the original failing command. Make sure that specific command passes.
7. **Record what you noticed but did not fix.** Apply the in-scope test: if the fix is covered by this task's gate and belongs in this task's diff, make it now — no observation needed. Otherwise record one row through `.forge/scripts/obs.js` and move on. This channel captures what would otherwise be lost, not what would otherwise be fixed; most tasks produce no rows at all, and that is the expected case rather than a gap to fill.
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

When the fix is applied:

1. Run the gate command: `{{gate}}`
2. If the gate **passes**: report success and suggest a commit message.
3. If the gate **fails**: diagnose further. If you're stuck, write a detailed diagnostic to `Notes` so the next session can pick up.
4. If you **cannot complete** the task in this session, update the `Notes` field in WORKPLAN.md with:
   - The root cause (if identified)
   - What you tried
   - What remains to investigate
