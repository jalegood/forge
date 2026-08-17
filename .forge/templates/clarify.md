# Clarify Task

You are executing a **clarify** task. Your job is to resolve an ambiguity or open question in the Contract.

## Task

**ID:** {{task_id}}
**Description:** {{task_description}}
**Gate:** `{{gate}}`

## Contract Context

The following Contract sections contain the ambiguity or `<!-- UNRESOLVED -->` item to address.

{{context}}

## Instructions

1. **Identify the ambiguity.** Locate the specific `<!-- UNRESOLVED: ... -->` comment or unclear requirement in the context above.
2. **Present options.** Lay out 2-3 concrete options for resolving the ambiguity. For each option, state:
   - What it means concretely
   - Trade-offs (complexity, flexibility, constraints)
   - Your recommendation and why
3. **Wait for the human.** This task requires a human decision. Present your analysis and options clearly, then ask the human to choose.
4. **Apply the decision.** Once the human decides, update CONTRACT.md:
   - Remove the `<!-- UNRESOLVED -->` comment
   - Replace it with the resolved specification
   - Ensure the resolution is testable (can you write an assertion for it?)
5. **Log the decision in `.forge/STATUS.md`.** The Contract edit records *what* the answer is; the Decisions table records *why it is that answer* — and it is the only place the reasoning survives the session.
   - Append a row to the Decisions table: `| YYYY-MM-DD | What was decided | Why | Alternatives rejected |`. Use today's real date.
   - **The rejected alternatives are mandatory, not decoration.** The options from step 2 the human turned down go in that column, each with the reason it lost. Omit them and the next session re-opens the settled question and re-derives the same answers.
   - **If the ambiguity was tracked as an Open Questions row, delete that row.** The question *moves* to Decisions — it does not exist in both tables. A resolved question left sitting under Open Questions is indistinguishable from an unresolved one to everyone who reads that table, including `/forge-status`.
   - If no Open Questions row existed, still write the Decisions row. The trigger is a decision being made, not a question having been filed.
6. **Record what you noticed but did not fix.** Apply the in-scope test: if the fix is covered by this task's gate and belongs in this task's diff, make it now — no observation needed. Otherwise append one row to the Observations table in `.forge/STATUS.md` and move on. This channel captures what would otherwise be lost, not what would otherwise be fixed; most tasks produce no rows at all, and that is the expected case rather than a gap to fill.
   - Row format: `| OBS-XXX | {{task_id}} | design/bug/scope/... | normal or foundation | One-line observation. | open |`, where `OBS-XXX` is the highest existing OBS id plus one.
   - One line per observation — a pointer, not a report.
   - No observation spawns a task on its own. Only a human promotes one, later.
   - More than three from this task collapse into a single `foundation` row: volume of small complaints is itself the signal that the foundation is wrong, and recording it as volume buries that signal.
   - `foundation` means the spec, contract, or approach is suspect and continuing to build compounds debt. Everything else is `normal`.

## Completion

When the ambiguity is resolved:

1. Run the gate command: `{{gate}}`
2. If the gate **passes**: report success and suggest a commit message.
3. If the gate **fails**: diagnose the failure, fix it, and re-run the gate.
4. If you **cannot complete** the task (e.g., awaiting human decision), update the `Notes` field in WORKPLAN.md with:
   - The options you presented
   - Which option(s) the human is considering
   - Any context that would help the next session
