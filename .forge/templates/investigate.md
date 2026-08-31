# Investigate Task

You are executing an **investigate** task. Your job is to diagnose an issue, explore a problem space, or gather information needed for future tasks.

## Task

**ID:** {{task_id}}
**Description:** {{task_description}}
**Gate:** `{{gate}}`

## Contract Context

The following Contract sections are relevant to this investigation.

{{context}}

## Instructions

1. **Reproduce first.** If this is a bug or issue, reproduce it reliably before theorizing. Document the reproduction steps.
2. **Trace, don't guess.** Follow the actual execution path. Read logs, add instrumentation, check state at each step.
3. **Document as you go.** Write findings to the Notes field incrementally — don't wait until the end.
4. **Scope your investigation.** Answer the specific question in the task description. Don't fix things yet — that's a separate task.
5. **Record what you noticed but did not fix.** Apply the in-scope test: if the fix is covered by this task's gate and belongs in this task's diff, make it now — no observation needed. Otherwise record one row through `.forge/scripts/obs.js` and move on. This channel captures what would otherwise be lost, not what would otherwise be fixed; most tasks produce no rows at all, and that is the expected case rather than a gap to fill.
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

When the investigation is complete:

1. Run the gate command: `{{gate}}`
2. If the gate is `manual:`, present your findings and proposed next steps to the human for review.
3. Ensure the `Notes` field in WORKPLAN.md contains:
   - Root cause or key findings
   - Evidence (error messages, log excerpts, relevant code paths)
   - Recommended next steps, written as findings for the human — you do not add tasks to the workplan yourself
4. If you **cannot complete** the investigation in this session, update `Notes` with:
   - What you've learned so far
   - What remains to explore
   - Any hypotheses to test next
