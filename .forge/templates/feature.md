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

1. **Tests first.** Write or update tests that express the expected behavior before implementing.
2. **One concern only.** This task should touch one API endpoint, one component, or one data flow. If you find yourself reaching into unrelated areas, stop — that's a separate task.
3. **Contract is law.** The context above defines what this feature must do. Don't invent requirements beyond what's specified. Don't skip requirements that are specified.
4. **Interfaces matter.** Match the shapes, types, and contracts defined above. Downstream tasks depend on your interfaces being correct.
5. **Keep it tight.** No premature abstractions, no "while I'm here" improvements, no speculative generality.

## Completion

When you believe the feature is complete:

1. Run the gate command: `{{gate}}`
2. If the gate **passes**: report success and suggest a commit message.
3. If the gate **fails**: diagnose the failure, fix it, and re-run the gate.
4. If you **cannot complete** the task in this session, update the `Notes` field in WORKPLAN.md with:
   - What was done
   - What remains
   - Any decisions or blockers encountered
