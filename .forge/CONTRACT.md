# Contract

## Data Model

### Artifacts

Forge operates on these file artifacts:

| Artifact  | Path                          | Owner                  | Purpose                                                       |
| --------- | ----------------------------- | ---------------------- | ------------------------------------------------------------- |
| Vision    | `.forge/VISION.md`            | Human (100%)           | Immutable project direction — what, who, pillars              |
| Contract  | `.forge/CONTRACT.md`          | Human (80%) / AI (20%) | Hard constraints, interfaces, rules — the automation boundary |
| Workplan  | `.forge/WORKPLAN.md`          | AI (80%) / Human (20%) | Dependency-ordered task list, one task per session            |
| Templates | `.forge/templates/*.md`       | Forge-managed          | Prompt templates per task type, injected fresh each session   |
| Commands  | `.claude/commands/forge-*.md` | Forge-managed          | Slash command definitions for Claude Code                     |
| Settings  | `.claude/settings.json`       | Human-configured       | Hook definitions for deterministic enforcement                |
| CLAUDE.md | `CLAUDE.md` (project root)    | Human-configured       | Minimal pipeline pointer (3 lines max)                        |
| UX Spec   | `.forge/UX.md`                | Human (70%) / AI (30%) | Screen-level experience spec: flows, states, copy, interactions |
| UX Gate   | `.forge/scripts/check-ux-spec.js` | Forge-managed      | Deterministic ux-spec gate — validates one screen by name     |
| DESIGN.md | `.forge/DESIGN.md`            | Human (Stitch-assisted) | Visual design system: tokens, typography, spacing, component specs. Stitch-generated or hand-authored. <!-- ASSUMED: tool-agnostic markdown artifact mirrors UX.md pattern --> |

### Relationships

- Vision feeds Contract (pillars constrain rules).
- Contract feeds Workplan (tasks reference Contract sections via context manifests).
- Workplan feeds Execution (commands read workplan to find and execute tasks).
- Templates shape Execution (task type determines which template is injected).
- Hooks enforce invariants independently of all other artifacts.

### Context Manifest

A context manifest is a list of Contract section references in a task's `Context` field. Format:

- `CONTRACT#section-name` — references a top-level section (e.g., `CONTRACT#data-model`)
- `CONTRACT#section-name/subsection` — references a subsection
- For multi-file contracts: `filename#section-name` (e.g., `combat#rules/damage-calc`)
- `UX#flows/flow-name/screen-name` — one screen spec from UX.md
- `UX#flows/flow-name` — full flow including all screens from UX.md
- `UX#global` — global copy tone and style notes from UX.md
- `DESIGN#section-name` — references a top-level section of DESIGN.md (e.g., `DESIGN#tokens`) <!-- ASSUMED: same resolution pattern as UX# -->
- `DESIGN#section-name/subsection` — references a subsection (e.g., `DESIGN#components/button`)

Resolution: parse the references, extract matching markdown sections (header through next same-level header), concatenate, inject into prompt template at the `{{context}}` slot. CONTRACT references resolve against `.forge/CONTRACT.md`; UX references resolve against `.forge/UX.md`; DESIGN references resolve against `.forge/DESIGN.md`.

**Budget:** Resolved context must not exceed ~200 lines of Contract content per task. Exceeding this signals the Contract section is too large or the task scope is too broad. One screen per task.

### UX.md Data Model

UX.md is the screen-level experience spec. Structure:

```markdown
# UX Spec

## Global

### Copy Tone
<!-- Voice and energy rules: name what's in bounds and out. -->

### Style Notes
<!-- Global interaction/aesthetic principles only. Screen-specific decisions belong on the screen. -->

## Flows

### Flow: [Name]

**Entry:** [Screen + trigger]
**Exit:** [Screen(s) + condition]
**Emotional arc:** [e.g., anticipation → focus → satisfaction]

#### Screen: [Name]

**Purpose:** One sentence: what does this screen accomplish for the user?
**Emotional intent:** What should the user FEEL at this moment? Be specific.
**Design intention:** The specific decision that elevates this screen above a generic implementation.

##### States

| State | Trigger | Experience |
| ----- | ------- | ---------- |
| ...   | ...     | ...        |

##### Edge Cases

| Condition          | Behavior |
| ------------------ | -------- |
| Empty / first-time |          |
| Error              |          |
```

**Mandatory fields on every screen:** `Emotional intent` and `Design intention`. Everything else is agent-determined per screen type.

**Boundaries:** UX.md describes user experience. CONTRACT.md owns system state machines, data shapes, business rules, and API contracts. UX.md references CONTRACT.md — it does not duplicate it.

### DESIGN.md Data Model

<!-- ASSUMED: tool-agnostic visual system spec; Stitch is one authoring path, not a dependency -->

DESIGN.md is the visual design system spec. It captures design tokens and component rules that feature tasks consume during implementation. Structure:

```markdown
# Design System

## Tokens

### Colors
<!-- Seed colors, semantic color roles (e.g., primary, surface, error) -->

### Typography
<!-- Type scale: font families, sizes, weights, line heights -->

### Spacing
<!-- Base unit and named sizes (e.g., sm: 8px, md: 16px, lg: 24px) -->

### Radius
<!-- Corner radius values by component tier -->

## Components

### [Component Name]
<!-- Visual spec: default state, variants, token references -->

## Style Notes
<!-- Aesthetic rationale and cross-component rules -->
```

**Authoring:** DESIGN.md may be generated by Google Stitch (stitch.withgoogle.com), exported from other design tools, or hand-authored. Forge treats it as a file artifact with a defined structure — no dependency on any specific tool.

**Boundaries:** DESIGN.md owns visual system decisions — tokens, component visual specs. UX.md owns behavioral decisions — flows, states, interactions, copy, emotional intent. Feature tasks that implement a screen reference both when applicable. DESIGN.md does not duplicate token values that appear in code — it specifies intent; implementation maps intent to constants.

## State Machines

### Task Lifecycle

```
pending ──→ active ──→ done
  │            │
  │            └──→ blocked
  │                   │
  └───────────────────┘ (when blocker resolves)
```

- **pending:** Not yet started. All dependencies must be `done` to become unblocked.
- **active:** Currently being executed in a session. Exactly 0 or 1 tasks may be `active` at any time.
- **done:** Gate passed. Code committed. Terminal state.
- **blocked:** Cannot proceed. Requires a `clarify` task or dependency resolution. Returns to `pending` when unblocked.

Valid transitions: `pending→active`, `active→done`, `active→blocked`, `blocked→pending`.

### Session Lifecycle

```
start ──→ execute ──→ gate ──→ commit ──→ clear
                       │
                       └──→ notes ──→ commit/stash ──→ clear
```

**End of session (gate passes):**

1. `forge-next` marks task `done` in WORKPLAN.md
2. Human commits code + updated WORKPLAN.md together
3. Human runs `/clear`

**End of session (incomplete):**

1. `forge-next` writes a `Notes` entry: what was done, what remains, decisions made
2. Human commits partial progress or stashes
3. Task stays `active`
4. Human runs `/clear`

**Start of session:**

1. `forge-next` reads WORKPLAN.md
2. If resuming an `active` task, `Notes` field provides continuity
3. Fresh context window — full reasoning capacity

## Interfaces

### Command: `/forge-init`

- **Reads:** nothing (creates from built-in templates only)
- **Does:**
  - Creates `.forge/VISION.md` if absent (stub template with What/Who/Pillars sections)
  - Creates `.forge/CONTRACT.md` if absent (stub template with all top-level sections)
  - Creates `.forge/templates/` directory with all 7 template files if absent: scaffold.md, feature.md, clarify.md, refactor.md, fix.md, investigate.md, ux-spec.md
  - Creates `.forge/scripts/check-ux-spec.js` if absent (the ux-spec gate script)
  - Creates `.forge/UX.md` if absent — stub with Global section (Copy Tone, Style Notes) and one placeholder Flow with one placeholder Screen, including mandatory fields as HTML comments
  - Creates `.forge/DESIGN.md` if absent — stub with Tokens (Colors, Typography, Spacing, Radius) and Components sections, each with HTML comment placeholders <!-- ASSUMED: mirrors UX.md stub pattern; Stitch-generated or hand-authored -->
  - Writes `.claude/settings.json` if absent (PostToolUse lint hook; PreToolUse commit hook disabled by default)
  - Appends the Forge integration block to `CLAUDE.md` if not already present
  - Never overwrites any file that already exists
  - On completion: tells the user to fill in VISION.md, CONTRACT.md, and UX.md before running `/forge-plan`
- **Outputs:** Scaffold files listed above
- **When to run:** Once, at project setup. Safe to re-run — idempotent due to no-overwrite rule.
- **Template refresh:** To update templates to the latest versions, delete `.forge/templates/` and re-run `/forge-init`.

### Command: `/forge-plan`

- **Reads:** `.forge/VISION.md` (What/Who/Pillars format), `.forge/CONTRACT.md` (sections: Data Model, State Machines, Interfaces, Rules, Boundaries), `.forge/UX.md` (when present — Flows, screens), `.forge/DESIGN.md` (when present — tokens, components), `.forge/WORKPLAN.md` (if exists)
- **Does:**
  - Assumes scaffold has already run (via `/forge-init`). Always reads context and validates/generates the workplan.
  - Runs a two-check Contract readiness validation before generating any tasks:
    1. **Coverage check** — every planned deliverable has a Contract section specifying its interface, rule, or data model (not merely mentioning it exists).
    2. **Unknown check** — scans CONTRACT.md for plan-blocking unknowns: `<!-- UNRESOLVED -->` markers, technology choices without documented rationale, external dependencies without constraints, rules referencing undefined concepts. Classifies each as *plan-blocking* (would change which tasks exist, their order, or their gates — treated like a coverage gap) or *implementation-detail* (only affects one task's internals — deferred to a `clarify` task). Both checks resolve together in a single pass; gaps and plan-blocking unknowns are written to CONTRACT.md with `<!-- ASSUMED: reason -->` annotations, then task generation proceeds immediately.
  - Regenerates only `pending` tasks; preserves `done` and `active` tasks exactly as-is.
  - Orders tasks as a dependency DAG — no task runs before its `Depends` entries are all `done`.
  - **UX coverage:** When UX.md is present and has flows, every screen referenced in a planned flow must have a `ux-spec` task gated `done` before its `feature` task is unblocked. Missing screen specs are plan-blocking. When UX.md has flows but no screens yet, generates a flow-mapping `ux-spec` task first to enumerate all screens before any are individually specced. Gate for the mapping task: `grep -c "^#### Screen:" .forge/UX.md | awk '$1 >= N'` (N = expected count).
  - **UX task DAG shape:** TASK-A (map all screens) → TASK-B, TASK-C, TASK-D (one ux-spec per screen, independent) → TASK-E, TASK-F, TASK-G (one feature per screen, depends only on its paired ux-spec).
  - **DESIGN coverage:** When DESIGN.md is present and has tokens, feature tasks implementing screens include `DESIGN#tokens` in their context manifests. When DESIGN.md has component specs relevant to a screen, widen to include `DESIGN#components/[name]`. <!-- ASSUMED: additive to existing manifest rules; does not gate on DESIGN.md presence -->
- **Output task format:** Each task in WORKPLAN.md uses this structure: `## [TASK-XXX] Description` followed by fields — Status (`pending` for new tasks), Type (`scaffold|feature|clarify|refactor|fix|investigate|ux-spec`), Depends (`none` or comma-separated task IDs), Context (manifest references like `CONTRACT#section-name` or `UX#flows/flow-name/screen-name`), Gate (shell command or `manual:` prefix), Notes (empty for new tasks). Task IDs are sequential and unique (TASK-001, TASK-002, ...).
- **Task sizing:** One task per concern. If a description uses "and" connecting two distinct pieces of work, split it. Each task should complete in a single clean session.
- **Manifest generation:** Each task's Context field must list all Contract sections needed to execute independently (see Manifest Completeness rule). Context manifests for `ux-spec` tasks reference `UX#flows/flow-name` (the stub to complete). Context manifests for `feature` tasks implementing a screen reference `UX#flows/flow-name/screen-name` plus any `CONTRACT#` sections for data shapes the screen consumes.
- **Outputs:** Updated `.forge/WORKPLAN.md`
- **Human action required:** Review and edit the workplan before proceeding

### Command: `/forge-next`

- **Reads:** `.forge/WORKPLAN.md`, `.forge/CONTRACT.md` (referenced sections only), `.forge/UX.md` (when referenced in context manifests), `.forge/DESIGN.md` (when referenced in context manifests), `.forge/templates/`
- **Task format:** Parses WORKPLAN.md entries: `## [TASK-XXX] Description` followed by Status, Type, Depends, Context, Gate, Notes fields.
- **Task selection:** If a task is already `active`, resumes it (the `Notes` field provides continuity from the previous session). Otherwise, finds the next unblocked `pending` task, or accepts a specific task ID (e.g., `/forge-next TASK-012`). A task is **unblocked** when its `Depends` field is `none` or all listed task IDs have status `done`. If a specified task has unmet dependencies, warns the human and asks for confirmation.
- **Does:**
  1. Selects the target task (see Task selection above)
  2. Resolves the context manifest: parses the `Context` field references (e.g., `CONTRACT#interfaces/command-forge-status`), extracts matching markdown sections from the appropriate file — CONTRACT.md for `CONTRACT#` references, UX.md for `UX#` references, DESIGN.md for `DESIGN#` references (each section runs from its header through the next same-level header), concatenates them
  3. Marks task `active` in WORKPLAN.md
  4. Loads the prompt template from `.forge/templates/{type}.md` matching the task's Type field. If the file does not exist, stop and tell the user: "Template file missing. Run `/forge-init` to create project templates." Do not proceed with inline fallbacks.
  5. Injects resolved context into the template at `{{context}}`, plus task details into `{{task_id}}`, `{{task_description}}`, `{{gate}}`
  6. Executes the task following the template instructions
  7. Runs the gate command. If the gate starts with `manual:`, presents the description to the human and asks for pass/fail confirmation instead of running a shell command.
  8. On pass: marks `done`, runs `git diff --name-only HEAD` (or staged files if not yet committed) to collect touched files, appends `Files: <comma-separated list>` to the task's Notes field, suggests commit message ending with `(TASK-XXX)`
  9. On fail: keeps `active`, writes diagnostic to `Notes`
- **Outputs:** Executed code changes, gate result, updated WORKPLAN.md

### Command: `/forge-status`

- **Reads:** `.forge/WORKPLAN.md`
- **Task format:** Parses task entries: `## [TASK-XXX] Description` followed by Status, Type, Depends, Context, Gate, Notes fields.
- **Does:**
  - Counts tasks by status: `pending`, `active`, `done`, `blocked`
  - Identifies next unblocked task: first `pending` task whose `Depends` are all `done` or `none`
  - Lists any `clarify`-type tasks that are `pending` or `active` (these need human decisions)
- **Outputs:** Progress summary to the user — task counts by status, next unblocked task ID and description, clarify tasks awaiting input (if any). Read-only — no file modifications, no side effects.

### Prompt Template Interface

Each template in `.forge/templates/` must contain:

- A `{{context}}` slot for resolved Contract content
- Task-type-specific instructions
- A reminder to run the gate command before reporting completion
- An instruction to update `Notes` if work is incomplete

Templates are ~30-50 lines. They are injected fresh each session.

### Task Types

| Type          | Purpose                                   | Default Gate Style                       |
| ------------- | ----------------------------------------- | ---------------------------------------- |
| `scaffold`    | Project setup, config, boilerplate        | Structural checks                        |
| `feature`     | Vertical slice of functionality           | Test suite + build                       |
| `ux-spec`     | Author or complete a screen spec in UX.md. Produces no code. | `node .forge/scripts/check-ux-spec.js "Screen Name"` |
| `clarify`     | Resolve implementation-detail unknowns deferred from planning | Decision documented, unblocks dependent task |
| `refactor`    | Improve structure, preserve behavior      | Existing tests pass                      |
| `fix`         | Repair broken gate or bug                 | Original failing command passes          |
| `investigate` | Diagnose issues, explore unknowns         | `manual:` — findings documented in Notes |

Each type has a corresponding prompt template in `.forge/templates/`. The task type determines which template `/forge-next` loads for execution.

### CLAUDE.md Integration Block

Exactly 3 lines in the project's CLAUDE.md:

```markdown
## Forge

- Pipeline: .forge/ (VISION.md, CONTRACT.md, WORKPLAN.md)
- Workflow: /forge-next → review → commit → /clear
- Do not modify CONTRACT.md without asking first
```

## Rules

### Task Sizing

- Every task must be completable in a single clean Claude Code session (one focused prompt + one review/correction cycle).
- One task touches one concern (one endpoint, one component, one migration).
- If a task description contains "and" connecting two distinct pieces of work, it must be split.
- Scaffold tasks may be larger (boilerplate is low-risk). Feature tasks must be tight.

### Context Budget

- Resolved context per task must not exceed ~200 lines of Contract content.
- If a single Contract section exceeds ~200 lines, it must be broken into subsections.
- The full Contract never enters the context window during execution — only manifested sections.

### Manifest Completeness

A task's context manifest must include all Contract sections needed to execute the task independently. The test: could an agent with no prior knowledge of the project produce the correct deliverable using only the resolved context?

When an interface section references concepts defined elsewhere (task statuses, data formats, transition rules), either:

- **Inline** the essential details into the interface section (preferred — keeps manifests lean), or
- **Widen** the manifest to include the referenced sections

`/forge-plan` should generate manifests that pass this test. The human reviewer should verify: read only the resolved context for a task and ask whether it's sufficient to do the work.

### Session Boundary Protocol

- `/clear` between tasks is a structural requirement, not optional hygiene.
- Git commit is the persistence boundary.
- Every session starts by reading WORKPLAN.md (the `forge-next` command does this automatically).
- Notes field provides continuity between sessions — conversation history does not.

### Contract Amendment Protocol

The Contract will change during execution as implementation reveals new understanding. When amending the Contract:

1. **Identify the change.** Note which specific sections are affected.
2. **Update CONTRACT.md.** Make the change directly. Precision matters — downstream tasks reference specific sections.
3. **Assess impact on the Workplan:**
   - `done` tasks whose Context referenced changed sections may need `fix` tasks to reconcile.
   - `active` tasks should be evaluated — if the change invalidates current work, update Notes and consider restarting the task.
   - `pending` tasks with Context referencing changed sections may need re-scoping or regeneration.
4. **Update the Workplan.** Either add corrective tasks manually, or run `/forge-plan` to regenerate pending tasks (done and active tasks are preserved).
5. **Commit together.** The Contract change and workplan updates are a single commit.

Do not let the Contract drift from reality. A wrong Contract causes compounding errors — every future task that references stale sections builds on false assumptions.

### Mid-Task Scope Splitting

When a task turns out to be larger than expected during execution:

1. Stop. Do not continue past 3 exchanges.
2. Write what was accomplished and what remains to the task's `Notes` field.
3. Commit partial progress.
4. Edit WORKPLAN.md: shrink the current task description to what was completed, add a new task for the remainder with appropriate dependencies.
5. `/clear` and continue with the new task.

Splitting mid-session is a normal workflow event, not a failure.

### CLAUDE.md Minimalism

- CLAUDE.md contains at most 3 lines of Forge configuration.
- Behavioral enforcement belongs in hooks and prompt templates, not CLAUDE.md.
- Every CLAUDE.md line competes for ~100 remaining instruction slots.

### Workplan Integrity

- WORKPLAN.md is a single file with a unified DAG, even when the Contract is split across multiple files.
- `forge-plan` preserves `done` and `active` tasks on re-run; only regenerates `pending` tasks.
- Task IDs are sequential and unique (TASK-001, TASK-002, ...).

### Contract-First

Every task must derive from a Contract section that covers its deliverable. The Contract must specify the interface, rule, or data model governing the deliverable — not merely mention that something exists.

A task without Contract coverage cannot be correctly sized, manifested, or gated.

If planned work has no Contract coverage:

1. The agent drafts the missing CONTRACT language (or surfaces it from the planning input if already present).
2. The agent writes the changes to CONTRACT.md, annotating inferred resolutions with `<!-- ASSUMED: reason -->`. Claude Code's native file-write confirmation is the approval mechanism.
3. Task generation proceeds immediately after CONTRACT.md is updated.

No implementation tasks are generated until coverage exists.

This is the spec-first invariant: the Contract is the spec, tasks are implementations, gates are test runs. Work not covered by the Contract is out of scope — not skipped, but deferred until specified.

**Exemptions:** `/forge-plan` on a brand-new project may scaffold stub tasks to prompt the human to fill in VISION.md and CONTRACT.md before substantive planning begins.

### Test-First Convention

`feature` and `fix` tasks follow test-first development:

1. Write tests that specify expected behavior before writing implementation.
2. Run the test command to confirm tests exercise new behavior.
3. Write implementation to satisfy the tests.
4. Run the full gate command.

**Enforcement:**

- Gate commands for `feature` and `fix` tasks must include a test command (e.g., `npm test && npm run build`). `/forge-plan` generates these; the human verifies.
- The PreToolUse commit hook blocks commits when the test command fails. This is enabled after test infrastructure exists.
- Test-first *ordering* is a convention. The human reviewer verifies it by reading the diff — tests should appear as additions alongside or before implementation code.

**Exemptions:** `scaffold` tasks (create test infrastructure), `investigate` tasks (manual gates), `clarify` tasks (no code). `refactor` tasks already have tests — write characterization tests first if coverage is insufficient.

### Traceability

Task IDs are the traceability anchor. Every task leaves a grep-able trail:

**Commit messages** must end with `(TASK-XXX)`:

```text
Add user auth middleware (TASK-012)
```

`/forge-next` generates this format automatically when suggesting commit messages.

**File manifest** — when `/forge-next` marks a task `done`, it appends a `Files` line to the task's Notes listing the files created or modified (derived from `git diff --name-only` against the task's starting commit). This records the requirement→file mapping inside WORKPLAN.md without relying on code annotations.

**Discovery:**

- Find commits: `git log --oneline --grep="TASK-007"`
- Find files: look at the `Files` line in the task's Notes, or `git log --name-only --grep="TASK-007"`
- Full diff: `git log -p --grep="TASK-007"`

### Gate Patterns

Gates validate deliverable structure, not quality. Different deliverable types require different gate strategies:

| Deliverable Type            | Gate Strategy                                           | Example                                                             |
| --------------------------- | ------------------------------------------------------- | ------------------------------------------------------------------- |
| Code                        | Test suite / build command                              | `npm test && npm run build`                                         |
| Config / JSON               | Parse validation + key check                            | `node -e "JSON.parse(require('fs').readFileSync('f.json','utf8'))"` |
| Markdown artifacts          | Structural check (required sections, slots, line count) | `grep -q '{{context}}' file.md && test $(wc -l < file.md) -gt 10`   |
| UX spec (UX.md)             | Mandatory fields + no placeholder language              | `node .forge/scripts/check-ux-spec.js "Screen Name"`                |
| Human-judgment deliverables | `manual:` prefix — not automated                        | `manual: Verify the workflow completes 2-3 full cycles`             |

**The `manual:` gate type:** When a gate value starts with `manual:`, `/forge-next` does not run a shell command. Instead, it presents the description to the human and asks for pass/fail confirmation. Use this for deliverables that cannot be structurally validated (e.g., end-to-end workflow validation, UX review).

- Automated gates are always preferred. Use `manual:` only when no structural check is possible.
- If a task seems to need a `manual:` gate, first consider whether it can be split into an automatable structural task and a smaller manual verification task.

### UX-Spec-First

No `feature` task implementing a screen may be `active` unless its corresponding `ux-spec` task is `done`. Enforced by the DAG: every screen `feature` task's `Depends` field must include its `ux-spec` task ID. `/forge-plan` generates this dependency automatically.

The `feature` template, when given a context manifest containing `UX#` sections, must generate the `manual:` gate description as a checklist: one item per States row (the most testable aspect of the Experience cell) plus the Design intention. Every item references a specific spec value — no vague language.

### UX Spec Precision

Values that govern time, physics, or sensation in UX.md are always numeric or reference a named pattern:

| Prohibited         | Required                              |
| ------------------ | ------------------------------------- |
| "smooth animation" | "ease-out 250ms"                      |
| "fast transition"  | "slide-up 300ms spring(0.8)"          |
| "subtle feedback"  | "opacity pulse 0→0.4→0 over 600ms"   |
| "feels snappy"     | "spring tension:180 friction:12 200ms" |

Prose is permitted only in Emotional intent, Design intention, and Copy Tone. All other cells involving measurable qualities are numeric or structured. `check-ux-spec.js` rejects vague terms (`smooth`, `fast`, `subtle`) at the gate.

**Rationale:** The implementation agent translates spec cells to code constants. "Smooth" produces an invented value. "ease-out 250ms" produces `ANIMATION.TRANSITION_DURATION = 250`. Spec precision directly determines implementation precision.

## Boundaries

### What Forge Does Not Do

- **No sub-agents.** Unreliable context inheritance, 7x token cost.
- **No hidden state.** Everything is readable markdown files.
- **No conversation continuity dependence.** Every session is self-contained.
- **No auto-commit or auto-push.** The human is the final gate.
- **No lock-in.** The files are useful even without the commands.

### What Requires Human Approval

- Any modification to CONTRACT.md — approval occurs through Claude Code's native file-write confirmation. `/forge-plan` may write `<!-- ASSUMED: reason -->` annotations directly during validation; substantive amendments (outside of planning) follow the Contract Amendment Protocol.
- Workplan review after `/forge-plan` generates or regenerates tasks.
- The commit step after gate passes — human reviews code before committing.
- Resolving `clarify` tasks (these require human decisions).

### Hook Configuration

`/forge-plan` writes `.claude/settings.json` during initial scaffold **only if the file does not already exist**. The default configuration:

- **PostToolUse (file edit):** Auto-lint/format after every file write (~200ms, non-blocking). Configured for the detected tech stack, or a no-op placeholder if no linter is detected.
- **PreToolUse (git commit):** Block commits unless test suite passes (exit 0 required). **Disabled by default** — enabled by a later workplan task after test infrastructure exists.

This avoids broken hooks on first run while ensuring deterministic enforcement is available as early as possible. The human may edit `settings.json` at any time to adjust hook behavior.

### Platform Constraints

- Slash commands have a character budget — excess commands may be silently excluded.
- Forge uses exactly 4 commands to minimize budget consumption: forge-init, forge-plan, forge-next, forge-status.
- Users should run `/context` to verify commands loaded if behavior seems wrong.
