# /forge-status

Report project progress. This is a **read-only** command — do not modify any files.

Workplan data comes from `.forge/scripts/wp.js`, never from reading `.forge/WORKPLAN.md` yourself (CONTRACT#rules/workplan-access-discipline). The workplan is the DAG, and it grows without bound; a status report that loads two thousand lines of it into context to count four numbers is a defect. The script does the counting deterministically and returns only the summary.

## Steps

1. **Project the workplan.** Run:

   ```bash
   node .forge/scripts/wp.js status
   ```

   This single invocation returns the workplan side of the report: task counts by status, the active task, the next unblocked pending task, `clarify`-type tasks awaiting input, and blocked tasks. Add `--json` if you would rather consume it structurally.

   Do not open `.forge/WORKPLAN.md` to verify or supplement this output. The script is the source of truth for workplan state — it applies the same unblocked-ness rule the contract specifies (a task is unblocked when its `Depends` field is `none` or every listed TASK-ID has status `done`).

   Then project the **shape** of the remaining work:

   ```bash
   node .forge/scripts/wp.js graph
   ```

   Counts say how much is left; the graph says where the reader stands in it. Report four things from it:

   - **Depth and width** — how many layers of remaining work there are, and how wide the current layer is.
   - **The full startable set**, not just the first one. A queue of one is correct for an unattended span, where selection is deterministic and there is no choice to make. It is a real loss for a human deciding where to spend a session: ten equally startable tasks look like one.
   - **Choke points** — high fan-in tasks, typically checkpoints, where the graph narrows to a single node every downstream task waits behind.
   - **Blocked-by** for anything blocked: which unfinished dependency is holding it.

   This is two traversals over the same structure the script already returns — no second source of truth, and nothing here re-derives what `wp.js status` reported.

   If the script exits nonzero, report its error verbatim. Exit code 1 means the workplan is missing or empty — tell the user to run `/forge-plan`.

2. **Project the observation backlog.** Run:

   ```bash
   node .forge/scripts/obs.js list --json
   ```

   Never read the `## Observations` table yourself — `obs.js list` is the projection, and it computes each row's age in days, which is triage input in its own right: a row that has survived twenty tasks is evidence about the observation, not merely about the backlog.

   Report three things from it:
   - **Open `foundation` rows first.** Each with the description of the task that raised it and its age in days. Look the raising task's description up through `node .forge/scripts/wp.js get TASK-XXX` — **a bare ID is not a report.** The reader must be able to act on what you print without opening another file or running another command.
   - **The `accepted` queue awaiting planning** — rows a human agreed to that no task covers yet. `accepted` is not terminal and not silent; this queue is what keeps it from becoming a dead letter.
   - **Backlog counts by disposition** — one line, so the shape of the queue is visible without listing every settled row.

3. **Read STATUS.md for the human-authored items** — only if `.forge/STATUS.md` exists:
   - `## Open Questions` — list every unanswered row by its ID, flagging any marked Blocking
   - `## Blockers` — list every open row

4. **Format the report** using the output shape below. Do not paraphrase the script's numbers — report what it returned.

## Output Format

```
## Forge Status

**Progress:** X/N tasks done (Y pending, Z active, W blocked)

**Active task:** TASK-XXX — Description
  (or omit this line when nothing is active)

**Next unblocked task:** TASK-XXX — Description
  (or "All pending tasks are blocked" / "All tasks complete")

**Shape:** N layers deep, M startable now
  - Startable: TASK-XXX, TASK-YYY, TASK-ZZZ
  - Choke point: TASK-XXX (N tasks wait behind it)
  (omit the choke-point line when there is none)

**Clarify tasks awaiting input:**
  - TASK-XXX — Description
  (or "None")

**Blocked tasks:**
  - TASK-XXX — Description
  (or omit when none)

**Open observations:**
  - [foundation] OBS-X (TASK-YYY: description) — Observation — Nd open
  (or omit when none)

**Accepted, awaiting planning:**
  - OBS-X — Observation — Nd open
  (or omit when none)

**Observation backlog:** N open, N accepted, N planned, N closed, N declined, N duplicate
  (or omit when the table is empty)

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
