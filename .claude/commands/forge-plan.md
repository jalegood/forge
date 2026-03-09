# /forge-plan

Read `.forge/VISION.md` and `.forge/CONTRACT.md`, then generate or update `.forge/WORKPLAN.md`.
This command is **idempotent** — safe to re-run at any point.

**Planning scope:** If the user provides text after the command (e.g., a file reference or description), treat it as the planning input that scopes what to plan. If no input is provided, plan the full set of deliverables implied by VISION.md and CONTRACT.md.

## Steps

### 1. Read context

Read the following files in full:

- **`.forge/VISION.md`** — What, Who, Pillars
- **`.forge/CONTRACT.md`** — all sections: Data Model, State Machines, Interfaces, Rules, Boundaries
- **`.forge/WORKPLAN.md`** (if it exists) — to identify tasks to preserve

If VISION.md is still a template stub (contains `<!-- What this project builds`), stop and tell the user to fill in VISION.md and CONTRACT.md before running `/forge-plan`.

### 2. Validate Contract coverage (Contract-First check)

Before generating any tasks, verify that every planned deliverable has Contract coverage.

For each deliverable implied by the planning input, identify the CONTRACT section(s) that specify it — interface, rule, or data model. Coverage means the section specifies the _what_, not merely mentions that something exists.

**If the planning input already contains proposed CONTRACT language** (e.g., the user points to a spec document with exact rule/interface text): surface that language directly as the proposed amendment — do not re-draft it.

**If unspecified work exists:**

1. Draft the missing CONTRACT language for each gap (or extract it from the planning input).
2. Present it to the human with the proposed language and two options:
   - **"Apply it yourself"** — edit CONTRACT.md directly, then run: `/forge-plan "generate tasks for: CONTRACT#section/name, ..."` using the actual anchors for the added sections.
   - **"Apply it for me"** — reply with approval and the agent will write the changes to CONTRACT.md, then immediately continue to generate tasks.
3. Stop. Await the human's choice before proceeding.

**If all work is covered:** proceed to step 3.

This is the Contract-First invariant — see CONTRACT#rules/contract-first.

### 3. Identify tasks to preserve

On **subsequent runs**, collect all tasks with status `done` or `active`. These will be written back verbatim — do not alter their description, status, context, gate, or notes in any way.

### 4. Generate tasks

Analyze VISION.md and CONTRACT.md to determine the full set of deliverables. For each deliverable:

**Task format:**

```markdown
## [TASK-XXX] Description

- **Status:** pending
- **Type:** scaffold | feature | clarify | refactor | fix | investigate
- **Depends:** none | TASK-001, TASK-002
- **Context:** CONTRACT#section-name, CONTRACT#section-name/subsection
- **Gate:** shell command or manual: description
- **Notes:**
```

**Task ID assignment:** Sequential integers, TASK-001 onward. On subsequent runs, new tasks continue from the highest existing ID + 1.

**Task sizing rules:**

- One task per concern. If a description uses "and" connecting two distinct pieces of work, split it into two tasks.
- Each task must be completable in a single focused Claude Code session (one prompt + one review cycle).
- Scaffold tasks may be slightly larger (boilerplate is low-risk). Feature tasks must be tight.

**Task types:**

| Type          | Purpose                                      | Gate style                          |
| ------------- | -------------------------------------------- | ----------------------------------- |
| `scaffold`    | Setup, config, boilerplate                   | Structural file/content checks      |
| `feature`     | Vertical slice of functionality              | Test suite + build                  |
| `clarify`     | Resolve `<!-- UNRESOLVED -->` in CONTRACT.md | Contract updated, ambiguity removed |
| `refactor`    | Improve structure, preserve behavior         | Existing tests still pass           |
| `fix`         | Repair broken gate or bug                    | Original failing command now passes |
| `investigate` | Diagnose issues, explore unknowns            | `manual:` gate                      |

**Dependency DAG:** No task may appear before all of its `Depends` entries in the file. Within the same dependency level, order by implementation risk — lower risk first.

### 5. Generate context manifests

For each task, fill the `Context` field with every CONTRACT.md section reference needed to execute the task independently.

**Manifest completeness test — apply to every task before writing:**

> Could an agent with no prior knowledge of this project produce the correct deliverable using only the resolved context from these references?

If the answer is no — a referenced concept is defined elsewhere, a data format is implied but not stated, a transition rule is assumed but not included — then either:

- **Inline** the essential details into the relevant Contract section (preferred, keeps manifests lean), or
- **Widen** the manifest to include the missing sections

Do not generate a task with an incomplete manifest. The completeness test is the primary quality gate on the workplan — incomplete manifests cause cascading failures in every downstream session.

**Context budget:** Resolved context must not exceed ~200 lines of Contract content per task. If a single task's manifest exceeds this, the task scope is too broad or the Contract section needs splitting.

**Reference format:**

- `CONTRACT#section-name` — top-level section
- `CONTRACT#section-name/subsection` — subsection
- `filename#section-name` — for multi-file contracts

### 6. Generate gates

Each gate validates the deliverable structurally:

| Deliverable       | Gate strategy                 | Example                                                             |
| ----------------- | ----------------------------- | ------------------------------------------------------------------- |
| Code              | Test suite + build            | `npm test && npm run build`                                         |
| Config/JSON       | Parse + key check             | `node -e "JSON.parse(require('fs').readFileSync('f.json','utf8'))"` |
| Markdown artifact | Required content + line count | `grep -q '{{context}}' file.md && test $(wc -l < file.md) -gt 10`   |
| Human judgment    | `manual:` prefix              | `manual: Verify the workflow completes 2-3 full cycles`             |

Prefer automated gates. Use `manual:` only when no structural check is possible.

**Test-first enforcement for `feature` and `fix` tasks:**

Gates for `feature` and `fix` tasks **must** include a test command. This is non-negotiable — it enforces the test-first convention at the gate level.

- If a test runner exists (e.g., `npm test`, `pytest`, `go test ./...`), use it: `npm test && npm run build`
- If no test runner is detected yet, use a placeholder that will fail until tests are added: `test -f package.json && npm test`
- **Never generate a `feature` or `fix` gate that contains only structural checks** (grep, file existence, line counts) — those are for `scaffold` tasks.

When generating a gate for a `feature` or `fix` task, verify: does this gate command invoke a test suite? If not, revise it before writing to WORKPLAN.md.

### 7. Write WORKPLAN.md

Write to `.forge/WORKPLAN.md`:

1. All `done` and `active` tasks, in their original order, byte-for-byte identical.
2. All newly generated `pending` tasks, ordered by the dependency DAG.

### 8. Report and prompt human review

Tell the user:

- How many tasks were generated (or regenerated)
- Which tasks were preserved unchanged

Then say:

> **Review `.forge/WORKPLAN.md` before proceeding.** Verify:
>
> - Each task is sized for one session (no "and"-connected concerns)
> - Each manifest lists everything needed to execute independently
> - Dependencies are correct — no task depends on something later in the file
> - Gates are automatable where possible
>
> Edit the workplan as needed, then run `/forge-next` to begin execution.

## Constraints

- **Never modify** `done` or `active` tasks on re-run — preserve them exactly.
- **No side effects** beyond writing WORKPLAN.md.
- **Human reviews before execution** — this command does not run any tasks.
