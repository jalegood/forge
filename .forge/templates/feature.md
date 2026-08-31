# Feature Task

You are executing a **feature** task. Your job is to implement a vertical slice of functionality.

## Task

**ID:** {{task_id}}
**Description:** {{task_description}}
**Gate:** `{{gate}}`

## Contract Context

The following Contract sections are relevant to this task. Stay within these constraints.

{{context}}

## Instructions

Follow this test-first ordering strictly:

1. **Write tests** that specify the expected behavior. Tests come before implementation — express what the feature must do, not how.
2. **Run the test command** to confirm the tests exercise new behavior (they may fail or be skipped — that's expected at this stage).
3. **Write implementation** to satisfy the tests. Stop when tests pass.
4. **One concern only.** This task should touch one API endpoint, one component, or one data flow. If you find yourself reaching into unrelated areas, stop — that's a separate task.
5. **Contract is law.** The context above defines what this feature must do. Don't invent requirements beyond what's specified. Don't skip requirements that are specified.
6. **Interfaces matter.** Match the shapes, types, and contracts defined above. Downstream tasks depend on your interfaces being correct.
7. **Keep it tight.** No premature abstractions, no "while I'm here" improvements, no speculative generality.
8. **Record what you noticed but did not fix.** Apply the in-scope test: if the fix is covered by this task's gate and belongs in this task's diff, make it now — no observation needed. Otherwise record one row through `.forge/scripts/obs.js` and move on. This channel captures what would otherwise be lost, not what would otherwise be fixed; most tasks produce no rows at all, and that is the expected case rather than a gap to fill.
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

When you believe the feature is complete:

1. Run the gate command: `{{gate}}`
2. If the gate **passes**: report success and suggest a commit message.
3. If the gate **fails**: diagnose the failure, fix it, and re-run the gate.
4. If you **cannot complete** the task in this session, update the `Notes` field in WORKPLAN.md with:
   - What was done
   - What remains
   - Any decisions or blockers encountered
