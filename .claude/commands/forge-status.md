# /forge-status

Report project progress. This is a **read-only** command — do not modify any files.

Workplan data comes from `.forge/scripts/wp.js`, never from reading `.forge/WORKPLAN.md` yourself (CONTRACT#rules/workplan-access-discipline). The workplan is the DAG, and it grows without bound; a status report that loads two thousand lines of it into context to count four numbers is a defect. The script does the counting deterministically and returns only the summary.

## Steps

1. **Project the workplan.** Run:

   ```bash
   node .forge/scripts/wp.js status
   ```

   This single invocation returns everything the report needs: task counts by status, the active task, the next unblocked pending task, `clarify`-type tasks awaiting input, blocked tasks, and open STATUS.md observations with `foundation` severity listed first. Add `--json` if you would rather consume it structurally.

   Do not open `.forge/WORKPLAN.md` to verify or supplement this output. The script is the source of truth for workplan state — it applies the same unblocked-ness rule the contract specifies (a task is unblocked when its `Depends` field is `none` or every listed TASK-ID has status `done`).

   If the script exits nonzero, report its error verbatim. Exit code 1 means the workplan is missing or empty — tell the user to run `/forge-plan`.

2. **Read STATUS.md for the human-authored items** — only if `.forge/STATUS.md` exists:
   - `## Open Questions` — list every unanswered row by its ID, flagging any marked Blocking
   - `## Blockers` — list every open row

   Observations are already covered by step 1; do not re-read the `## Observations` table.

3. **Format the report** using the output shape below. Do not paraphrase the script's numbers — report what it returned.

## Output Format

```
## Forge Status

**Progress:** X/N tasks done (Y pending, Z active, W blocked)

**Active task:** TASK-XXX — Description
  (or omit this line when nothing is active)

**Next unblocked task:** TASK-XXX — Description
  (or "All pending tasks are blocked" / "All tasks complete")

**Clarify tasks awaiting input:**
  - TASK-XXX — Description
  (or "None")

**Open observations:**
  - [foundation] OBS-X (TASK-YYY) — Observation
  (or omit when none)

**Open questions:**
  - Q-XXX — Question (Blocking)
  (or omit when none)

**Blockers:**
  - Blocker
  (or omit when none)
```

## Constraints

- **Read-only.** Do not modify WORKPLAN.md or any other file. `wp.js status` is a pure projection — it never writes.
- **Projection, not reading.** Workplan state arrives through `wp.js`. Reading the workplan document directly defeats the purpose of this command.
- **No side effects.** Only read and report.
