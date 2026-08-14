# /forge-plan

Read `.forge/VISION.md` and `.forge/CONTRACT.md`, then generate or update `.forge/WORKPLAN.md`.
This command is **idempotent** — safe to re-run at any point.

**Planning scope:** If the user provides text after the command (e.g., a file reference or description), treat it as the planning input that scopes what to plan. If no input is provided, plan the full set of deliverables implied by VISION.md and CONTRACT.md.

## Steps

### 1. Read context

Read the following files in full:

- **`.forge/VISION.md`** — What, Who, Pillars
- **`.forge/CONTRACT.md`** — all sections: Data Model, State Machines, Interfaces, Rules, Boundaries
- **`.forge/SPEC.md`** (if it exists) — Overview, Requirements, Flows, Non-Goals
- **`.forge/specs/*.md`** (if any exist) — same structure as SPEC.md, per feature
- **`.forge/UX.md`** (if it exists) — Flows, screens, global copy tone
- **`.forge/DESIGN.md`** (if it exists) — tokens, components, style notes
- **`.forge/STATUS.md`** (if it exists) — blocking open questions
- **`.forge/WORKPLAN.md`** (if it exists) — to identify tasks to preserve

If VISION.md is still a template stub (contains `<!-- What this project builds`), stop and tell the user to fill in VISION.md and CONTRACT.md before running `/forge-plan`.

### 2. Validate Contract readiness

Before generating any tasks, run two checks. Resolve all issues from both before proceeding — do not stop between them.

**Coverage check:** For each deliverable implied by the planning input, identify the CONTRACT section(s) that specify it — interface, rule, or data model. Coverage means the section specifies the _what_, not merely mentions that something exists.

**Unknown check:** Scan CONTRACT.md for plan-blocking unknowns:

- Any `<!-- UNRESOLVED -->` marker
- Any technology choice, external dependency, or interface without documented rationale or constraints
- Any rule that references a concept defined nowhere in CONTRACT

Classify each unknown:

- **Plan-blocking** — resolving it differently would change which tasks exist, their order, or their gates. Treat like a coverage gap.
- **Implementation-detail** — only affects how one task executes internally. Defer to a `clarify` task; do not block here.

**If coverage gaps or plan-blocking unknowns exist:** Draft the missing or resolved CONTRACT language. If the planning input already contains proposed language, extract it directly — do not re-draft. Write changes to CONTRACT.md, annotating inferred resolutions with `<!-- ASSUMED: reason -->`. Then continue immediately to step 3.

**If all work is covered and no plan-blocking unknowns remain:** proceed to step 3.

This is the Contract-First invariant — see CONTRACT#rules/contract-first.

**Spec conflict check (when SPEC.md or `.forge/specs/*.md` exist):** Compare each requirement's stated behavior against the CONTRACT sections that constrain the same deliverable. Where SPEC and CONTRACT disagree — a requirement implies a data shape, interface, or rule that CONTRACT states differently — the Contract wins (CONTRACT#rules/spec-precedence). Do not silently resolve the conflict in either document:

1. Append a row to `.forge/STATUS.md` Open Questions describing the conflict (which SPEC requirement, which CONTRACT section, what disagrees).
2. Generate a `clarify` task to resolve it (amend SPEC.md or CONTRACT.md, whichever is wrong) before any task implementing the conflicting requirement is unblocked.
3. Do not generate a `feature`/`fix` task for a requirement with an unresolved conflict — it is plan-blocking for that requirement only, not for the whole plan.

### 3. Identify tasks to preserve

On **subsequent runs**, collect all tasks with status `done` or `active`. These will be written back verbatim — do not alter their description, status, context, gate, or notes in any way.

### 4. Generate tasks

Analyze VISION.md and CONTRACT.md to determine the full set of deliverables. For each deliverable:

**Task format:**

```markdown
## [TASK-XXX] Description

- **Status:** pending
- **Type:** scaffold | feature | clarify | refactor | fix | investigate | ux-spec | checkpoint
- **Depends:** none | TASK-001, TASK-002
- **Context:** CONTRACT#section-name, CONTRACT#section-name/subsection
- **Gate:** shell command or manual: description
- **Notes:**
```

**Task ID assignment:** Unique IDs from a monotonic counter — `max(existing) + 1`, recomputed against the current file on every write, never inferred from the last ID you read earlier in the session. Gaps are normal (deleted or abandoned tasks). IDs carry no ordering meaning.

**Task placement:** Place each new task block so that every task in its `Depends` appears earlier in the file. This is a hard requirement, not a formatting preference — file order must remain a valid topological sort of the DAG. A task whose dependencies are all `done` may go at the end; a task that an existing `pending` task depends on must be inserted above that task, not appended. See CONTRACT#rules/task-ordering.

**Task sizing rules:**

- One task per concern. If a description uses "and" connecting two distinct pieces of work, split it into two tasks.
- Each task must be completable in a single focused Claude Code session (one prompt + one review cycle).
- Scaffold tasks may be slightly larger (boilerplate is low-risk). Feature tasks must be tight.

**Task types:**

| Type          | Purpose                                                       | Gate style                                           |
| ------------- | ------------------------------------------------------------- | ---------------------------------------------------- |
| `scaffold`    | Setup, config, boilerplate                                    | Structural file/content checks                       |
| `feature`     | Vertical slice of functionality                               | Test suite + build                                   |
| `ux-spec`     | Author or complete a screen spec in UX.md. Produces no code. | `node .forge/scripts/check-ux-spec.js "Screen Name"` |
| `clarify`     | Resolve implementation-detail unknowns deferred from planning | Decision documented, unblocks dependent task         |
| `refactor`    | Improve structure, preserve behavior                          | Existing tests still pass                            |
| `fix`         | Repair broken gate or bug                                     | Original failing command now passes                  |
| `investigate` | Diagnose issues, explore unknowns                             | `manual:` gate                                       |

**UX coverage — apply when UX.md is present and has flows:**

**Stub detection first:** a `### Flow:` or `#### Screen:` heading only counts toward "has flows" / "has screens" if its name is not the literal forge-init stub placeholder `[Name]`. An untouched `.forge/UX.md` still contains `### Flow: [Name]` and `#### Screen: [Name]` — treat those as absent, not as real content. This applies before every check below, including the "no `#### Screen:` headings" test in step 1.

Every screen referenced in a planned flow must have a `ux-spec` task with status `done` before its corresponding `feature` task is unblocked. Missing screen specs are plan-blocking — generate `ux-spec` tasks for them now.

UX task DAG shape:

1. **If UX.md has flows but no screens yet** (no `#### Screen:` headings): generate one flow-mapping `ux-spec` task per flow. Its job is to enumerate all screens in UX.md. Gate: `grep -c "^#### Screen:" .forge/UX.md | awk '$1 >= N'` where N is the expected screen count. All per-screen `ux-spec` tasks depend on this mapping task.

2. **If UX.md has flows with screens already defined**: generate one `ux-spec` task per screen (independent — no cross-screen dependencies), then one `feature` task per screen that depends only on its paired `ux-spec` task.

DAG shape: `TASK-A (map screens)` → `TASK-B, TASK-C, TASK-D (one ux-spec per screen, parallel)` → `TASK-E, TASK-F, TASK-G (one feature per screen, depends only on its paired ux-spec)`.

Every screen `feature` task's `Depends` field **must** include its paired `ux-spec` task ID. This is the UX-spec-first invariant.

**SPEC coverage — apply when SPEC.md or `.forge/specs/*.md` is present:**

**Stub detection first:** a `### [REQ-slug] Requirement Name` heading only counts as a real requirement if `[REQ-slug]` has been replaced with an actual slug — the untouched forge-init stub still contains that literal bracket text. Treat an unedited stub as having zero requirements, the same way an unedited VISION.md stub blocks planning in step 1.

Every requirement that implies a `feature` or `fix` deliverable gets a task whose manifest includes the requirement's `SPEC#requirements/req-slug` section (see step 5). A requirement is not itself a separate task type — it is coverage input to the `feature`/`fix` tasks it implies, the same way a Contract interface section is.

**Dependency DAG:** No task may appear before all of its `Depends` entries in the file. Within the same dependency level, order by implementation risk — lower risk first.

### 5. Generate context manifests

For each task, fill the `Context` field with every CONTRACT.md section reference needed to execute the task independently.

**Manifest completeness test — apply to every task before writing:**

> Could an agent with no prior knowledge of this project produce the correct deliverable using only the resolved context from these references?

If the answer is no — a referenced concept is defined elsewhere, a data format is implied but not stated, a transition rule is assumed but not included — then either:

- **Inline** the essential details into the relevant Contract section (preferred, keeps manifests lean), or
- **Widen** the manifest to include the missing sections

Do not generate a task with an incomplete manifest. The completeness test is the primary quality gate on the workplan — incomplete manifests cause cascading failures in every downstream session.

**The test spans SPEC and CONTRACT together** when both exist (CONTRACT#rules/spec-precedence): a manifest that pulls a SPEC requirement's behavior without the CONTRACT sections constraining it, or a CONTRACT constraint without the SPEC requirement describing the behavior it governs, fails the completeness test just as much as a missing UX or DESIGN reference does.

**Context budget:** Resolved context must not exceed ~200 lines of Contract content per task. If a single task's manifest exceeds this, the task scope is too broad or the Contract section needs splitting.

**Reference format:**

- `CONTRACT#section-name` — top-level section
- `CONTRACT#section-name/subsection` — subsection
- `filename#section-name` — for multi-file contracts
- `UX#flows/flow-name/screen-name` — one screen spec from UX.md (use for `feature` tasks implementing a screen)
- `UX#flows/flow-name` — full flow including all screens (use for `ux-spec` mapping tasks)
- `UX#global` — global copy tone and style notes (include when copy or interaction style matters)
- `DESIGN#section-name` — top-level section of DESIGN.md (e.g., `DESIGN#tokens`)
- `DESIGN#section-name/subsection` — subsection of DESIGN.md (e.g., `DESIGN#components/button`)
- `SPEC#section-name` — top-level section of SPEC.md (e.g., `SPEC#requirements`)
- `SPEC#section-name/subsection` — subsection of SPEC.md (e.g., `SPEC#requirements/req-login`)
- `specs/name#section-name` — section of a per-feature spec file `.forge/specs/name.md` (used once SPEC.md has been split per the ~300-line threshold)

**UX manifest rules:**

- `ux-spec` tasks: context is `UX#flows/flow-name` (the flow stub the agent will complete)
- `feature` tasks implementing a screen: context is `UX#flows/flow-name/screen-name` plus any `CONTRACT#` sections for data shapes the screen consumes
- Do not reference `UX#` sections for non-screen tasks

**DESIGN manifest rules:**

- **Stub detection first:** a `## Tokens` section only counts as present if it contains something beyond the forge-init stub's HTML-comment placeholders (`<!-- Seed colors... -->` etc. with no real values below them). A `### [Component Name]` heading with the literal bracket text is not a real component — never widen a manifest based on it. An untouched `.forge/DESIGN.md` must never trigger `DESIGN#tokens` or `DESIGN#components/*` inclusion.
- When DESIGN.md is present and has a `## Tokens` section with real content, `feature` tasks implementing a screen **must** include `DESIGN#tokens` in their context manifests.
- When DESIGN.md has a real (non-placeholder) component spec relevant to the screen (a `### ComponentName` subsection under `## Components`), widen the manifest to also include `DESIGN#components/[name]` for each relevant component.
- Do not reference `DESIGN#` for non-screen tasks (`scaffold`, `ux-spec`, `clarify`, `investigate`).
- Do not gate on DESIGN.md presence — if the file is absent, simply omit DESIGN# refs.

**SPEC manifest rules:**

- **Stub detection first:** same as the SPEC coverage check in step 4 — a `### [REQ-slug] Requirement Name` heading with the literal bracket text is not a real requirement. Never reference it.
- `feature` and `fix` tasks whose deliverable implements a SPEC requirement **must** include that requirement's `SPEC#requirements/req-slug` section (or `specs/name#requirements/req-slug` once split) in their context manifest, alongside the `CONTRACT#` sections constraining the same deliverable. Behavior and constraint travel together — see the completeness test above.
- Once SPEC.md exceeds ~300 lines and is split into `.forge/specs/*.md`, reference the per-feature file (`specs/auth#requirements/req-login`) instead of `SPEC#`.
- Do not reference `SPEC#` for tasks with no corresponding requirement (`scaffold`, `ux-spec`, `clarify`, `investigate`).
- Do not gate task generation on SPEC.md presence — if neither SPEC.md nor `.forge/specs/` exists, simply omit SPEC# refs; CONTRACT.md alone remains sufficient coverage per Contract-First.

### 6. Generate gates

Each gate validates the deliverable structurally:

| Deliverable       | Gate strategy                 | Example                                                                |
| ----------------- | ----------------------------- | ---------------------------------------------------------------------- |
| Code              | Test suite + build            | `npm test && npm run build`                                            |
| Config/JSON       | Parse + key check             | `node -e "JSON.parse(require('fs').readFileSync('f.json','utf8'))"` |
| Markdown artifact | Required content + line count | `grep -q '{{context}}' file.md && test $(wc -l < file.md) -gt 10`      |
| UX spec screen    | check-ux-spec.js              | `node .forge/scripts/check-ux-spec.js "Screen Name"`                   |
| UX screen mapping | Screen count check            | `grep -c "^#### Screen:" .forge/UX.md \| awk '$1 >= N'`                |
| Human judgment    | `manual:` prefix              | `manual: Verify the workflow completes 2-3 full cycles`                |

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

**Workplan lint:** After writing, run `node .forge/scripts/check-workplan.js`. A nonzero exit means the generated plan violates an invariant — diagnose the reported violation, fix WORKPLAN.md, and re-run the script. Repeat until it exits 0 before proceeding to step 8.

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
