# /forge-status

Read `.forge/WORKPLAN.md` and report project progress. This is a **read-only** command — do not modify any files.

## Steps

1. **Read** `.forge/WORKPLAN.md` in full.

2. **Parse** each task entry. Tasks follow this format:

   ```markdown
   ## [TASK-XXX] Description

   - **Status:** pending | active | done | blocked
   - **Type:** scaffold | feature | clarify | refactor | fix | investigate | ux-spec | checkpoint
   - **Depends:** none | comma-separated TASK-IDs
   - **Context:** manifest references
   - **Gate:** shell command or manual: prefix
   - **Notes:** free text
   ```

3. **Count tasks by status.** Tally how many tasks are `pending`, `active`, `done`, and `blocked`.

4. **Identify the next unblocked task.** Scan `pending` tasks in order. A task is **unblocked** when its `Depends` field is `none` or every listed TASK-ID has status `done`. Report the first unblocked pending task's ID and description.

5. **List clarify tasks needing input.** Find any task with Type `clarify` that has status `pending` or `active`. These require human decisions.

## Output Format

Report the following to the user:

```
## Forge Status

**Progress:** X/N tasks done (Y pending, Z active, W blocked)

**Next unblocked task:** TASK-XXX — Description
  (or "All pending tasks are blocked" / "All tasks complete")

**Clarify tasks awaiting input:**
  - TASK-XXX — Description
  (or "None")
```

## Constraints

- **Read-only.** Do not modify WORKPLAN.md or any other file.
- **No side effects.** Only read and report.
