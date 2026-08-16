# UX Spec Task

You are executing a **ux-spec** task. Your job is to author or complete a screen spec in UX.md. This task produces no code — only a completed screen specification.

## Task

**ID:** {{task_id}}
**Description:** {{task_description}}
**Gate:** `{{gate}}`

## Contract Context

The following sections are relevant to this task. The UX.md stub to complete is included below.

{{context}}

## Instructions

1. **Read the stub.** Locate the screen referenced in the task description within `.forge/UX.md`.
2. **Complete all mandatory fields.** Every screen must have `**Emotional intent:**` and `**Design intention:**` filled with specific, non-placeholder language.
3. **Fill in States.** Every state row must have a specific, measurable Experience value. No vague terms like "smooth", "fast", or "subtle" — use numeric values (e.g., "ease-out 250ms") for anything involving time, physics, or sensation.
4. **Fill in Edge Cases.** At minimum: Empty/first-time behavior and Error behavior.
5. **Precision rule.** Prose is permitted only in Emotional intent, Design intention, and Copy Tone. All cells involving measurable qualities must be numeric or reference a named pattern.
6. **Record what you noticed but did not fix.** Apply the in-scope test: if the fix is covered by this task's gate and belongs in this task's diff, make it now — no observation needed. Otherwise append one row to the Observations table in `.forge/STATUS.md` and move on. This channel captures what would otherwise be lost, not what would otherwise be fixed; most tasks produce no rows at all, and that is the expected case rather than a gap to fill.
   - Row format: `| OBS-XXX | {{task_id}} | design/bug/scope/... | normal or foundation | One-line observation. | open |`, where `OBS-XXX` is the highest existing OBS id plus one.
   - One line per observation — a pointer, not a report.
   - No observation spawns a task on its own. Only a human promotes one, later.
   - More than three from this task collapse into a single `foundation` row: volume of small complaints is itself the signal that the foundation is wrong, and recording it as volume buries that signal.
   - `foundation` means the spec, contract, or approach is suspect and continuing to build compounds debt. Everything else is `normal`.

## Completion

When the screen spec is complete:

1. Run the gate command: `{{gate}}`
2. If the gate **passes**: report success and suggest a commit message.
3. If the gate **fails**: read the validation errors, fix the offending fields, and re-run.
4. If you **cannot complete** the task in this session, update the `Notes` field in WORKPLAN.md with:
   - What was completed
   - What remains
   - Any decisions or blockers encountered
