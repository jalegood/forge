# /forge-plan

Read `.forge/VISION.md` and `.forge/CONTRACT.md`, then generate or update `.forge/WORKPLAN.md`.
This command is **idempotent** — safe to re-run at any point.

**Planning scope:** If the user provides text after the command (e.g., a file reference or description), treat it as the planning input that scopes what to plan. If no input is provided, plan the full set of deliverables implied by VISION.md and CONTRACT.md.

## Steps

### 1. Detect run type

Check whether `.forge/WORKPLAN.md` exists and contains any tasks with status `done` or `active`.

- **First run:** file is absent, or all tasks are `pending`.
- **Subsequent run:** at least one task is `done` or `active`.

### 2. First-run scaffold (first run only)

Create any missing files. Never overwrite files that already exist.

**`.forge/VISION.md`** — if absent, create with this template:

```markdown
# Vision

## What
<!-- What this project builds, in 1-2 sentences -->

## Who
<!-- Target users or stakeholders -->

## Pillars
<!-- 3-5 core principles that constrain every design decision -->
```

**`.forge/CONTRACT.md`** — if absent, create with this template:

```markdown
# Contract

## Data Model
<!-- Key entities, their fields, and relationships -->

## State Machines
<!-- Task or object lifecycles as ASCII or mermaid state diagrams -->

## Interfaces
<!-- Command definitions, API shapes, file formats -->

## Rules
<!-- Hard constraints on behavior, sizing, and validation -->

## Boundaries
<!-- What this system does not do; what requires human approval -->
```

**`.forge/templates/scaffold.md`** — if absent:

```markdown
# Scaffold Task

## Context

{{context}}

## Task

**ID:** {{task_id}}
**Description:** {{task_description}}
**Gate:** `{{gate}}`

## Instructions

1. Create or configure the files and structure described in the Context above.
2. Match shapes, formats, and content exactly as specified — no extras.
3. When done, run the gate command below.

## Completion

Run the gate: `{{gate}}`

- **Passes:** mark {{task_id}} as `done` in WORKPLAN.md, report success, suggest a commit message.
- **Fails:** diagnose the failure, fix it, re-run.
- **Incomplete:** write to Notes: what was done, what remains, any blockers encountered.
```

**`.forge/templates/feature.md`** — if absent:

```markdown
# Feature Task

## Context

{{context}}

## Task

**ID:** {{task_id}}
**Description:** {{task_description}}
**Gate:** `{{gate}}`

## Instructions

1. Verify the Contract spec is clear before writing any code.
2. One concern only — touch one endpoint, one component, or one data flow.
3. Contract is law — implement exactly what's specified, nothing more.
4. Match interfaces exactly — downstream tasks depend on correct shapes.
5. No premature abstractions, no speculative additions.
6. When done, run the gate command below.

## Completion

Run the gate: `{{gate}}`

- **Passes:** mark {{task_id}} as `done` in WORKPLAN.md, report success, suggest a commit message.
- **Fails:** diagnose the failure, fix it, re-run.
- **Incomplete:** write to Notes: what was done, what remains, any blockers encountered.
```

**`.forge/templates/clarify.md`** — if absent:

```markdown
# Clarify Task

## Context

{{context}}

## Task

**ID:** {{task_id}}
**Description:** {{task_description}}
**Gate:** `{{gate}}`

## Instructions

1. Read the Contract section(s) listed in Context.
2. Identify the specific ambiguity or gap — quote it.
3. Propose a resolution. Do not resolve unilaterally — present options if there is real uncertainty.
4. Once the human approves, update CONTRACT.md with the resolved language.
5. Remove any `<!-- UNRESOLVED -->` markers that have been addressed.

## Completion

Run the gate: `{{gate}}`

- **Passes:** mark {{task_id}} as `done` in WORKPLAN.md, report success, suggest a commit message.
- **Fails:** diagnose, fix, re-run.
- **Incomplete:** write to Notes: what was done, what remains, any blockers encountered.
```

**`.forge/templates/refactor.md`** — if absent:

```markdown
# Refactor Task

## Context

{{context}}

## Task

**ID:** {{task_id}}
**Description:** {{task_description}}
**Gate:** `{{gate}}`

## Instructions

1. Identify the structural issue. State clearly what property will be preserved.
2. Make the structural change — behavior must not change.
3. Run existing tests. If tests fail, stop and diagnose before continuing.
4. No feature changes, no scope expansion.

## Completion

Run the gate: `{{gate}}`

- **Passes:** mark {{task_id}} as `done` in WORKPLAN.md, report success, suggest a commit message.
- **Fails:** diagnose, fix, re-run.
- **Incomplete:** write to Notes: what was done, what remains, any blockers encountered.
```

**`.forge/templates/fix.md`** — if absent:

```markdown
# Fix Task

## Context

{{context}}

## Task

**ID:** {{task_id}}
**Description:** {{task_description}}
**Gate:** `{{gate}}`

## Instructions

1. Reproduce the failure — confirm the gate currently fails before changing anything.
2. Identify the root cause. Do not patch symptoms.
3. Apply the minimal fix that makes the gate pass.
4. No unrelated changes.

## Completion

Run the gate: `{{gate}}`

- **Passes:** mark {{task_id}} as `done` in WORKPLAN.md, report success, suggest a commit message.
- **Fails:** diagnose further, fix, re-run.
- **Incomplete:** write to Notes: what was done, what remains, any blockers encountered.
```

**`.forge/templates/investigate.md`** — if absent:

```markdown
# Investigate Task

## Context

{{context}}

## Task

**ID:** {{task_id}}
**Description:** {{task_description}}
**Gate:** `{{gate}}`

## Instructions

1. Define what you are trying to learn. State the question explicitly.
2. Gather evidence — read code, run commands, inspect artifacts.
3. Write findings in Notes: what you learned, what you ruled out, what remains unknown.
4. Propose next steps (a fix task, a clarify task, or a design change).

## Completion

Gate is `manual:` — present your findings to the human and ask for pass/fail confirmation.

- **Passes:** mark {{task_id}} as `done` in WORKPLAN.md.
- **Incomplete:** write to Notes: what was investigated, what remains open.
```

**`.claude/settings.json`** — write only if this file does not already exist:

```json
{
  "hooks": {
    "PostToolUse": [
      {
        "matcher": "Write|Edit",
        "hooks": [
          {
            "type": "command",
            "command": "echo 'File written — add lint/format command here for your stack'"
          }
        ]
      }
    ]
  }
}
```

> Note: The `PreToolUse` commit-blocking hook is intentionally omitted until test infrastructure exists. Add it manually once tests are in place.

**`CLAUDE.md`** — append the integration block if not already present:

```markdown
## Forge

- Pipeline: .forge/ (VISION.md, CONTRACT.md, WORKPLAN.md)
- Workflow: /forge-next → review → commit → /clear
- Do not modify CONTRACT.md without asking first
```

> If `CLAUDE.md` does not exist, create it with only the integration block. If it already exists, check whether it contains `Pipeline: .forge/` — if not, append the block at the end. Never overwrite or truncate existing content.

### 3. Read context

Read the following files in full:

- **`.forge/VISION.md`** — What, Who, Pillars
- **`.forge/CONTRACT.md`** — all sections: Data Model, State Machines, Interfaces, Rules, Boundaries
- **`.forge/WORKPLAN.md`** (if it exists) — to identify tasks to preserve

If VISION.md is still a template stub (contains `<!-- What this project builds`), stop and tell the user to fill in VISION.md and CONTRACT.md before running `/forge-plan`.

### 3b. Validate Contract coverage (Contract-First check)

Before generating any tasks, verify that every planned deliverable has Contract coverage.

For each deliverable implied by the planning input, identify the CONTRACT section(s) that specify it — interface, rule, or data model. Coverage means the section specifies the *what*, not merely mentions that something exists.

**If the planning input already contains proposed CONTRACT language** (e.g., the user points to a spec document with exact rule/interface text): surface that language directly as the proposed amendment — do not re-draft it.

**If unspecified work exists:**

1. Draft the missing CONTRACT language for each gap (or extract it from the planning input).
2. Present it to the human with the proposed language and two options:
   - **"Apply it yourself"** — edit CONTRACT.md directly, then run: `/forge-plan "generate tasks for: CONTRACT#section/name, ..."` using the actual anchors for the added sections.
   - **"Apply it for me"** — reply with approval and the agent will write the changes to CONTRACT.md, then immediately continue to generate tasks.
3. Stop. Await the human's choice before proceeding.

**If all work is covered:** proceed to step 4.

This is the Contract-First invariant — see CONTRACT#rules/contract-first.

### 4. Identify tasks to preserve

On **subsequent runs**, collect all tasks with status `done` or `active`. These will be written back verbatim — do not alter their description, status, context, gate, or notes in any way.

### 5. Generate tasks

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

| Type | Purpose | Gate style |
|---|---|---|
| `scaffold` | Setup, config, boilerplate | Structural file/content checks |
| `feature` | Vertical slice of functionality | Test suite + build |
| `clarify` | Resolve `<!-- UNRESOLVED -->` in CONTRACT.md | Contract updated, ambiguity removed |
| `refactor` | Improve structure, preserve behavior | Existing tests still pass |
| `fix` | Repair broken gate or bug | Original failing command now passes |
| `investigate` | Diagnose issues, explore unknowns | `manual:` gate |

**Dependency DAG:** No task may appear before all of its `Depends` entries in the file. Within the same dependency level, order by implementation risk — lower risk first.

### 6. Generate context manifests

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

### 7. Generate gates

Each gate validates the deliverable structurally:

| Deliverable | Gate strategy | Example |
|---|---|---|
| Code | Test suite + build | `npm test && npm run build` |
| Config/JSON | Parse + key check | `node -e "JSON.parse(require('fs').readFileSync('f.json','utf8'))"` |
| Markdown artifact | Required content + line count | `grep -q '{{context}}' file.md && test $(wc -l < file.md) -gt 10` |
| Human judgment | `manual:` prefix | `manual: Verify the workflow completes 2-3 full cycles` |

Prefer automated gates. Use `manual:` only when no structural check is possible.

**Test-first enforcement for `feature` and `fix` tasks:**

Gates for `feature` and `fix` tasks **must** include a test command. This is non-negotiable — it enforces the test-first convention at the gate level.

- If a test runner exists (e.g., `npm test`, `pytest`, `go test ./...`), use it: `npm test && npm run build`
- If no test runner is detected yet, use a placeholder that will fail until tests are added: `test -f package.json && npm test`
- **Never generate a `feature` or `fix` gate that contains only structural checks** (grep, file existence, line counts) — those are for `scaffold` tasks.

When generating a gate for a `feature` or `fix` task, verify: does this gate command invoke a test suite? If not, revise it before writing to WORKPLAN.md.

### 8. Write WORKPLAN.md

Write to `.forge/WORKPLAN.md`:

1. All `done` and `active` tasks, in their original order, byte-for-byte identical.
2. All newly generated `pending` tasks, ordered by the dependency DAG.

### 9. Report and prompt human review

Tell the user:
- First run or subsequent run
- How many tasks were generated (or regenerated)
- Which tasks were preserved unchanged

Then say:

> **Review `.forge/WORKPLAN.md` before proceeding.** Verify:
> - Each task is sized for one session (no "and"-connected concerns)
> - Each manifest lists everything needed to execute independently
> - Dependencies are correct — no task depends on something later in the file
> - Gates are automatable where possible
>
> Edit the workplan as needed, then run `/forge-next` to begin execution.

## Constraints

- **Never overwrite** files that already exist during scaffold (VISION.md, CONTRACT.md, settings.json).
- **Never modify** `done` or `active` tasks on re-run — preserve them exactly.
- **No side effects** beyond writing WORKPLAN.md (and scaffold files on first run).
- **Human reviews before execution** — this command does not run any tasks.
