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
5. **Propose next steps.** Based on your findings, recommend specific follow-up tasks (fix, refactor, or new feature tasks) with enough detail that they could be added to the workplan.

## Completion

When the investigation is complete:

1. Run the gate command: `{{gate}}`
2. If the gate is `manual:`, present your findings and proposed next steps to the human for review.
3. Ensure the `Notes` field in WORKPLAN.md contains:
   - Root cause or key findings
   - Evidence (error messages, log excerpts, relevant code paths)
   - Proposed follow-up tasks with brief descriptions
4. If you **cannot complete** the investigation in this session, update `Notes` with:
   - What you've learned so far
   - What remains to explore
   - Any hypotheses to test next
