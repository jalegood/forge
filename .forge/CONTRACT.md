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
| UX Spec   | `.forge/UX.md`                | Human (70%) / AI (30%) | Screen-level experience spec: flows, states, copy, interactions. Created only if the project has a user-facing interface (see Interfaces/`/forge-init`). |
| UX Gate   | `.forge/scripts/check-ux-spec.js` | Forge-managed      | Deterministic ux-spec gate — validates one screen by name. Created only if the project has a user-facing interface. |
| DESIGN.md | `.forge/DESIGN.md`            | Human (100%) | Visual design system: tokens, typography, spacing, component specs. Hand-authored markdown. Created only if the project has a user-facing interface. |
| Spec      | `.forge/SPEC.md`, `.forge/specs/*.md` | Human (60%) / AI (40%) | Behavioral spec: what the system should do — requirements, acceptance criteria, flows, rationale. Lives beside the Contract; Contract wins on conflict |
| Status    | `.forge/STATUS.md`            | AI (60%) / Human (40%) | Living project log: open questions, decisions, risks, blockers          |
| Workplan Lint | `.forge/scripts/check-workplan.js` | Forge-managed    | Deterministic workplan invariant checker                                 |
| Spec Gate | `.forge/scripts/check-spec.js` | Forge-managed         | Deterministic spec readiness gate                                        |
| Unattended Guards | `.forge/scripts/guard-push.sh`, `.forge/scripts/guard-branch.sh`, `.forge/scripts/guard-secrets.sh` | Forge-managed | Deterministic PreToolUse hooks: block `git push`, block off-branch commits during unattended runs, block commits matching common secret patterns |
| Version   | `.forge/VERSION`              | Forge-managed          | Engine version stamp + canonical repo pointer, consumed by `/forge-sync` |
| Task Records | `.forge/notes/TASK-XXX.md`   | AI (90%) / Human (10%) | Durable per-task narrative: outcome, decisions, deviations, files. Manifest-addressable. Self-sufficient without git |
| Workplan Script | `.forge/scripts/wp.js`     | Forge-managed          | Deterministic workplan query and mutation — task selection, status projection, targeted field writes, gate-discrimination probe at `pending → active` |
| Markdown Resolver | `.forge/scripts/lib/markdown.js` | Forge-managed    | Shared fence-aware heading parser and manifest-reference resolver; every check script consumes it |
| Workplan Parser | `.forge/scripts/lib/workplan.js` | Forge-managed     | The one parser for the WORKPLAN.md format, shared by `check-workplan.js` and `wp.js` |
| Prose Gate Helper | `.forge/scripts/prose.js`  | Forge-managed          | Greps a markdown file's prose while ignoring fenced payloads, so a gate cannot pass on text inside an embedded script |
| Notes Migration | `.forge/scripts/migrate-notes.js` | Forge-managed    | One-shot externalization of oversized inline Notes into task records, for workplans predating the threshold |

### Relationships

- Vision feeds Contract (pillars constrain rules).
- Contract feeds Workplan (tasks reference Contract sections via context manifests).
- Workplan feeds Execution (commands read workplan to find and execute tasks).
- Templates shape Execution (task type determines which template is injected).
- Hooks enforce invariants independently of all other artifacts.
- Spec feeds Workplan alongside Contract (behavior detail from SPEC, hard constraints from CONTRACT; Contract wins on conflict — see Rules/Spec Precedence).
- Status logs open questions, decisions, risks, and blockers across all layers; checkpoint review packets embed it.

### Context Manifest

A context manifest is a list of Contract section references in a task's `Context` field. Format:

- `CONTRACT#section-name` — references a top-level section (e.g., `CONTRACT#data-model`)
- `CONTRACT#section-name/subsection` — references a subsection
- For multi-file contracts: `filename#section-name` (e.g., `combat#rules/damage-calc`)
- `UX#flows/flow-name/screen-name` — one screen spec from UX.md
- `UX#flows/flow-name` — full flow including all screens from UX.md
- `UX#global` — global copy tone and style notes from UX.md
- `DESIGN#section-name` — references a top-level section of DESIGN.md (e.g., `DESIGN#tokens`). Resolved by the shared resolver like every other prefix, matching plain heading slugs — unlike UX#, DESIGN headings carry no `Flow:`/`Screen:` label prefix to strip
- `DESIGN#section-name/subsection` — references a subsection (e.g., `DESIGN#components/button`)
- `SPEC#section-name` — references a top-level section of SPEC.md (e.g., `SPEC#requirements`)
- `SPEC#section-name/subsection` — references a subsection (e.g., `SPEC#requirements/req-login`)
- `specs/name#section-name` — references a section of a per-feature spec file `.forge/specs/name.md`
- `notes/TASK-XXX#section-name` — references a section of a task record `.forge/notes/TASK-XXX.md` (e.g., `notes/TASK-029#deviations`)

Resolution: parse the references, extract matching markdown sections (header through next same-level header), concatenate, inject into prompt template at the `{{context}}` slot. CONTRACT references resolve against `.forge/CONTRACT.md`; UX references resolve against `.forge/UX.md`; DESIGN references resolve against `.forge/DESIGN.md`; SPEC references resolve against `.forge/SPEC.md`; `specs/name#` references resolve against `.forge/specs/name.md`.

**Requirement-heading matching:** requirement headings are the one exception to standard slug matching. A `### [req-slug] Requirement Name` heading under `## Requirements` matches the subsection reference `req-slug` by comparing the bracketed portion alone — strip the brackets, lowercase, compare directly — ignoring the trailing name text. So `SPEC#requirements/req-login` matches `### [req-login] User Login` however the name is later reworded, which is the point: requirement names are prose and change, slugs are identifiers and do not.

**Budget:** Resolved context must not exceed ~200 lines of Contract content per task. Exceeding this signals the Contract section is too large or the task scope is too broad. One screen per task.

### UX.md Data Model

UX.md is the screen-level experience spec. Structure:

```markdown
# UX Spec

## Global

### Copy Tone
<!-- Voice and energy rules: name what's in bounds and out. -->

### Interaction Notes
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
<!-- Example: | Loading | Fetch triggered | Skeleton fade-in, opacity 0→1 over 200ms | -->

##### Edge Cases

| Condition          | Behavior |
| ------------------ | -------- |
| Empty / first-time |          |
| Error              |          |
```

**Mandatory fields on every screen:** `Emotional intent` and `Design intention`. Everything else is agent-determined per screen type.

**Boundaries:** UX.md describes user experience. CONTRACT.md owns system state machines, data shapes, business rules, and API contracts. UX.md references CONTRACT.md — it does not duplicate it.

### DESIGN.md Data Model

DESIGN.md is the visual design system spec. It captures design tokens and component rules that feature tasks consume during implementation. Structure:

```markdown
# Design System

## Tokens

### Colors
<!-- Seed colors, semantic color roles (e.g., primary, surface, error) -->
<!-- Example: primary: #4F46E5, surface: #FFFFFF, error: #DC2626 -->

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

**Authoring:** DESIGN.md is hand-authored markdown — copy in values from whatever source you use (a design tool export, your own conventions, or by hand). Forge treats it as a file artifact with a defined structure; there is no tool integration.

**Boundaries:** DESIGN.md owns visual system decisions — tokens, component visual specs. UX.md owns behavioral decisions — flows, states, interactions, copy, emotional intent. Feature tasks that implement a screen reference both when applicable. DESIGN.md does not duplicate token values that appear in code — it specifies intent; implementation maps intent to constants.

### SPEC Data Model

SPEC.md is the behavioral specification: what the system should do and why. It lives beside the Contract and carries meaningfully different information — the Contract states hard constraints and interfaces (testable invariants); the Spec states intended behavior, acceptance criteria, and rationale. Structure:

```markdown
# Spec

## Overview

<!-- What this feature/system does, in one paragraph. Why it exists. -->

## Requirements

### [REQ-slug] Requirement Name

<!-- EARS-style statement: WHEN <trigger>, THE SYSTEM SHALL <response>. -->
<!-- Acceptance criteria: bullet list, each independently testable. -->

## Flows

<!-- Behavioral sequences that span requirements. References UX.md screens where applicable. -->

## Non-Goals

<!-- What this spec deliberately excludes. Prevents scope creep during execution. -->
```

**Scaling:** Small projects use a single `.forge/SPEC.md`. When SPEC.md exceeds ~300 lines, split into per-feature files under `.forge/specs/` (e.g., `.forge/specs/auth.md`), referenced as `specs/auth#requirements`. <!-- ASSUMED: 300-line threshold mirrors the Contract's scoped-planning guidance -->

**Boundaries:** CONTRACT.md owns hard constraints — data shapes, interfaces, invariants, state machines. SPEC.md owns behavior — requirements, acceptance criteria, flows, rationale. UX.md owns screen-level experience. SPEC references CONTRACT concepts; it never redefines them. Open questions raised while speccing go to STATUS.md, not inline prose.

### STATUS.md Data Model

STATUS.md is the living project log — the single place for open questions, decisions, risks, and blockers. Structure:

```markdown
# Status

## Open Questions

| ID | Question | Blocking? | Raised |
| -- | -------- | --------- | ------ |

## Decisions

| Date | Decision | Why | Alternatives rejected |
| ---- | -------- | --- | --------------------- |

## Risks

| Risk | Impact | Mitigation |
| ---- | ------ | ---------- |

## Blockers

| Blocker | Blocking tasks | Needs |
| ------- | -------------- | ----- |

## Observations

| ID | Raised by | Kind | Severity | Observation | Disposition |
| -- | --------- | ---- | -------- | ----------- | ----------- |
```

**Writers:** `/forge-spec` appends open questions raised during intake. `clarify` tasks move resolved questions to Decisions (dated, with rationale). `/forge-next` appends a Blockers row when marking a task `blocked`. The human edits freely. **Readers:** `/forge-status` surfaces open questions and blockers; `checkpoint` review packets embed the file. A status file nothing reads goes stale — these integrations are mandatory, not optional.

**Observations:** Any task may append an Observations row for something noticed but outside its scope. The governing test is: **if the fix is covered by this task's gate and belongs in this task's diff, make it — no observation needed. Otherwise log one line and move on.** The channel exists to capture what would otherwise be lost, not to intercept what would otherwise be fixed.

Constraints, all mandatory:

- **One line per observation.** A pointer, not a report.
- **No observation auto-spawns a task.** Only a human promotes one, at a checkpoint or ad hoc. Agents never create `clarify` or `investigate` tasks from their own observations.
- **More than three observations from a single task collapse into one `foundation` observation.** Volume of small complaints is itself the signal that the foundation is wrong; recording it as volume buries that signal.
- **`foundation` severity** means the spec, contract, or approach is suspect and continuing to build compounds debt. Everything else is `normal`.

**Observation readers:** `/forge-next` reports open `foundation` rows before selecting a task — this is the primary loop closure, because `/forge-next` is the command that actually runs every session. `checkpoint` packets list all open rows for triage. `/forge-status` lists them. `/forge-plan` consumes `accepted` rows as planning input when it happens to run — secondary, never the only path.

### Task Record Data Model

A task record is the durable narrative for one task, at `.forge/notes/TASK-XXX.md`. WORKPLAN.md holds the DAG; records hold everything else. Structure:

```markdown
# TASK-XXX — Description

## Outcome
<!-- What was built. 2-4 sentences. -->

## Decisions
<!-- Choices made during execution and why. One bullet each. -->

## Deviations
<!-- Where implementation departed from spec or contract, and why. -->

## Files
<!-- Paths created or modified. -->
```

**Externalization threshold:** `/forge-next` writes a record when a task's notes would exceed 3 lines. Shorter notes stay inline — a file per one-line note is churn, not structure.

**Inline residue:** the WORKPLAN `Notes` field retains a one-line summary naming what the record contains, then the path. A bare pointer is insufficient: the summary is what lets an agent judge whether opening the record is warranted, without opening it. This is progressive disclosure, the same principle as context manifests.

**Addressing:** records are manifest-addressable as `notes/TASK-XXX#section-name`. A task that genuinely depends on a prior task's record declares it in its Context field, where `check-workplan.js` validates the reference resolves. This is the supported path for cross-task record access — never agent initiative, because an optional lookup step is one an agent may skip.

**Self-sufficiency:** records must stand alone without git. Forge supports projects where `.forge/` is never committed; in those, the record *is* the archaeological artifact and commit history holds nothing about tasks.

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

- **Reads:** nothing (creates from built-in templates only). Asks the human one interactive question before creating UX/DESIGN artifacts (see below) — this is a chat prompt, not a file read.
- **Does:**
  - Creates `.forge/VISION.md` if absent (stub template with What/Who/Pillars sections)
  - Creates `.forge/CONTRACT.md` if absent (stub template with all top-level sections)
  - Creates `.forge/templates/` directory with all 7 unconditional template files if absent: scaffold.md, feature.md, clarify.md, refactor.md, fix.md, investigate.md, checkpoint.md (ux-spec.md is conditional — see below)
  - Creates the Forge-managed scripts under `.forge/scripts/` if absent — `lib/markdown.js`, `lib/workplan.js`, `check-workplan.js`, `wp.js`, `check-spec.js`, `prose.js`, `migrate-notes.js`. All seven are unconditional, and each is load-bearing for a command or a generated gate: `/forge-plan` and `/forge-next` block on the workplan lint, `/forge-next` and `/forge-status` reach the workplan only through `wp.js`, `/forge-spec` gates on `check-spec.js`, generated gates on markdown deliverables call `prose.js`, and `migrate-notes.js` is the remedy a project needs once its workplan predates the externalization threshold. A project missing any of them cannot complete a task whose gate names it.
  - Creates `.forge/SPEC.md` if absent (stub with Overview, Requirements, Flows, Non-Goals sections)
  - Creates `.forge/STATUS.md` if absent (stub with Open Questions, Decisions, Risks, Blockers, and Observations tables)
  - Creates `.forge/VERSION` if absent (engine version stamp + canonical repo URL)
  - **Asks the human:** "Does this project have a user-facing interface (UI/UX)?" before touching any UX/DESIGN artifact. If the answer is unclear, ask again — do not guess.
    - **If yes:** creates `.forge/UX.md` if absent — stub with Global section (Copy Tone, Interaction Notes) and one placeholder Flow with one placeholder Screen, including mandatory fields as HTML comments; creates `.forge/templates/ux-spec.md` if absent (the ux-spec prompt template — pointless boilerplate without UX.md, so it's gated here rather than with the other 7 unconditional templates); creates `.forge/DESIGN.md` if absent — stub with Tokens (Colors, Typography, Spacing, Radius) and Components sections, each with HTML comment placeholders; creates `.forge/scripts/check-ux-spec.js` if absent (the ux-spec gate script)
    - **If no:** skips all four — does not create `.forge/UX.md`, `.forge/templates/ux-spec.md`, `.forge/DESIGN.md`, or `.forge/scripts/check-ux-spec.js`. Downstream, `/forge-plan` already treats these as optional ("if it exists" / "do not gate on DESIGN.md presence") so no other command needs to change.
    - **Changing the answer later:** re-running `/forge-init` asks the question again. Since the no-overwrite rule only skips files that already exist, answering "yes" on a later run creates the four files at that point; answering "no" after they already exist has no effect (existing files are never deleted).
  - Writes `.claude/settings.json` if absent (PostToolUse lint hook; PreToolUse commit hook disabled by default; PreToolUse unattended-execution guards — push guard, branch guard, secret guard — enabled by default, see Boundaries#hook-configuration)
  - Creates `.forge/scripts/guard-push.sh`, `.forge/scripts/guard-branch.sh`, `.forge/scripts/guard-secrets.sh` if absent (the unattended-execution guard scripts referenced by the settings.json hooks above)
  - Appends the Forge integration block to `CLAUDE.md` if not already present
  - Never overwrites any file that already exists
  - On completion: tells the user to fill in VISION.md, CONTRACT.md, and UX.md (if created) before running `/forge-plan`
- **Outputs:** Scaffold files listed above (UX.md, DESIGN.md, check-ux-spec.js conditional on the interactive answer)
- **When to run:** Once, at project setup. Safe to re-run — idempotent due to no-overwrite rule.
- **Template refresh:** To update templates to the latest versions, delete `.forge/templates/` and re-run `/forge-init`.

### Command: `/forge-plan`

- **Reads:** `.forge/VISION.md` (What/Who/Pillars format), `.forge/CONTRACT.md` (sections: Data Model, State Machines, Interfaces, Rules, Boundaries), `.forge/SPEC.md` and `.forge/specs/*.md` (when present — requirements, acceptance criteria), `.forge/UX.md` (when present — Flows, screens), `.forge/DESIGN.md` (when present — tokens, components), `.forge/STATUS.md` (when present — blocking open questions, observations marked accepted), `.forge/WORKPLAN.md` (if exists)
- **Does:**
  - Assumes scaffold has already run (via `/forge-init`). Always reads context and validates/generates the workplan.
  - Runs a two-check Contract readiness validation before generating any tasks:
    1. **Coverage check** — every planned deliverable has a Contract section specifying its interface, rule, or data model (not merely mentioning it exists).
    2. **Unknown check** — scans CONTRACT.md for plan-blocking unknowns: `<!-- UNRESOLVED -->` markers, technology choices without documented rationale, external dependencies without constraints, rules referencing undefined concepts. Classifies each as *plan-blocking* (would change which tasks exist, their order, or their gates — treated like a coverage gap) or *implementation-detail* (only affects one task's internals — deferred to a `clarify` task). Both checks resolve together in a single pass; gaps and plan-blocking unknowns are written to CONTRACT.md with `<!-- ASSUMED: reason -->` annotations, then task generation proceeds immediately.
  - Regenerates only `pending` tasks; preserves `done` and `active` tasks exactly as-is.
  - Orders tasks as a dependency DAG — no task runs before its `Depends` entries are all `done`.
  - **UX coverage:** When UX.md is present and has flows, every screen referenced in a planned flow must have a `ux-spec` task gated `done` before its `feature` task is unblocked. Missing screen specs are plan-blocking. When UX.md has flows but no screens yet, generates a flow-mapping `ux-spec` task first to enumerate all screens before any are individually specced. Gate for the mapping task: `grep -c "^#### Screen:" .forge/UX.md | awk '$1 >= N'` (N = expected count). **Stub detection:** a `### Flow:` or `#### Screen:` heading counts toward "has flows"/"has screens" only if its name is not the literal forge-init stub placeholder (`[Name]`) — the untouched stub must never be treated as authored content.
  - **DESIGN coverage stub detection:** likewise, a `## Tokens` or `### [Component Name]` heading counts as present only if it contains something beyond the forge-init stub's HTML-comment placeholders and literal bracket component name. An untouched DESIGN.md stub must never trigger `DESIGN#tokens`/`DESIGN#components/*` manifest inclusion.

  - **UX task DAG shape:** TASK-A (map all screens) → TASK-B, TASK-C, TASK-D (one ux-spec per screen, independent) → TASK-E, TASK-F, TASK-G (one feature per screen, depends only on its paired ux-spec).
  - **DESIGN coverage:** When DESIGN.md is present and has tokens, feature tasks implementing screens include `DESIGN#tokens` in their context manifests. When DESIGN.md has component specs relevant to a screen, widen to include `DESIGN#components/[name]`.
  - **SPEC coverage:** When SPEC.md (or `.forge/specs/`) is present, `feature` and `fix` task manifests include the `SPEC#` requirement sections their deliverable implements, alongside the `CONTRACT#` sections that constrain it. The manifest completeness test spans both files — behavior detail without its constraint, or constraint without its behavior, fails the test (see Rules/Spec Precedence).
  - **Checkpoint cadence:** Inserts a `checkpoint` task at each dependency-phase boundary or after every 5 consecutive non-checkpoint tasks, whichever comes first, listing the span's tasks in `Depends` (see Rules/Checkpoint Cadence). <!-- ASSUMED: cadence of 5 -->
  - **Gate discrimination:** authors every gate so it fails against the pre-work state and passes after the work (see Rules/Gate Discrimination). A gate asserting a topic word the target file may already contain is rejected at authoring time in favour of one asserting the change, the covering test suite, or `manual:`.
  - **Workplan lint:** After writing WORKPLAN.md, runs `node .forge/scripts/check-workplan.js`. A nonzero exit means the generated plan violates an invariant — fix and re-run before reporting completion.
  - **Observation intake:** Consumes STATUS.md Observations rows marked `accepted` as planning input. Each becomes a candidate task, subject to the same Contract-First coverage requirement as any other deliverable. Rows marked `open` or `declined` are not planned.
- **Output task format:** Each task in WORKPLAN.md uses this structure: `## [TASK-XXX] Description` followed by fields — Status (`pending` for new tasks), Type (`scaffold|feature|clarify|refactor|fix|investigate|ux-spec|checkpoint`), Depends (`none` or comma-separated task IDs), Context (manifest references like `CONTRACT#section-name` or `UX#flows/flow-name/screen-name`), Gate (shell command or `manual:` prefix), Notes (empty for new tasks). Task IDs are unique and assigned from a monotonic counter: the next ID is `max(existing) + 1`, computed at write time against the current file — never inferred from the last ID read earlier in the session. Gaps are normal (deleted or abandoned tasks). An ID's ordinal carries no ordering meaning; see Rules/Task Ordering.
- **Task sizing:** One task per concern. If a description uses "and" connecting two distinct pieces of work, split it. Each task should complete in a single clean session.
- **Manifest generation:** Each task's Context field must list all Contract sections needed to execute independently (see Manifest Completeness rule). Context manifests for `ux-spec` tasks reference `UX#flows/flow-name` (the stub to complete). Context manifests for `feature` tasks implementing a screen reference `UX#flows/flow-name/screen-name` plus any `CONTRACT#` sections for data shapes the screen consumes.
- **Outputs:** Updated `.forge/WORKPLAN.md`
- **Human action required:** Review and edit the workplan before proceeding

### Command: `/forge-next`

- **Reads:** `.forge/WORKPLAN.md` **via `.forge/scripts/wp.js` projection — never in full** (see Rules/Workplan Access Discipline), `.forge/notes/TASK-XXX.md` (only when referenced in a context manifest), `.forge/CONTRACT.md` (referenced sections only), `.forge/SPEC.md` and `.forge/specs/*.md` (when referenced in context manifests), `.forge/UX.md` (when referenced in context manifests), `.forge/DESIGN.md` (when referenced in context manifests), `.forge/STATUS.md` (checkpoint tasks only), `.forge/templates/`
- **Task format:** Parses WORKPLAN.md entries: `## [TASK-XXX] Description` followed by Status, Type, Depends, Context, Gate, Notes fields.
- **Task selection:** If a task is already `active`, resumes it (the `Notes` field provides continuity from the previous session). Otherwise, finds the next unblocked `pending` task, or accepts a specific task ID (e.g., `/forge-next TASK-012`). A task is **unblocked** when its `Depends` field is `none` or all listed task IDs have status `done`. If a specified task has unmet dependencies, warns the human and asks for confirmation.
- **Does:**
  1. Selects the target task (see Task selection above)
  2. Resolves the context manifest: parses the `Context` field references (e.g., `CONTRACT#interfaces/command-forge-status`), extracts matching markdown sections from the appropriate file — CONTRACT.md for `CONTRACT#` references, UX.md for `UX#` references, DESIGN.md for `DESIGN#` references, SPEC.md for `SPEC#` references, `.forge/specs/name.md` for `specs/name#` references (each section runs from its header through the next same-level header), concatenates them
  3. Marks task `active` in WORKPLAN.md via `wp.js set`, which runs the gate-discrimination probe first (Rules/Gate Discrimination). A refused transition means the gate is vacuous — repair the gate as part of this task's diff, or report the prior-task scope overlap it exposes. Do not pass `--force`.
  4. Loads the prompt template from `.forge/templates/{type}.md` matching the task's Type field. If the file does not exist, stop and tell the user: "Template file missing. Run `/forge-init` to create project templates." Do not proceed with inline fallbacks.
  5. Injects resolved context into the template at `{{context}}`, plus task details into `{{task_id}}`, `{{task_description}}`, `{{gate}}`
  6. Executes the task following the template instructions
  7. Runs the gate command. If the gate starts with `manual:`, presents the description to the human and asks for pass/fail confirmation instead of running a shell command.
  8. On pass: marks `done`, runs `git diff --name-only HEAD` (or staged files if not yet committed) to collect touched files, appends `Files: <comma-separated list>` to the task's Notes field, suggests commit message ending with `(TASK-XXX)`
  9. On fail: keeps `active`, writes diagnostic to `Notes`
- **Checkpoint tasks:** When the selected task's Type is `checkpoint`, execution means assembling the review packet (see Rules/Checkpoint Cadence): tasks completed since the last checkpoint (from WORKPLAN Notes/Files and `git log`), gate results, manual test steps if any exist, and the current STATUS.md open questions and risks. The gate is always `manual:` — present the packet and wait for human pass/fail. On block: appends a row to STATUS.md Blockers.
- **Record externalization:** On marking a task `done`, writes the task's narrative to `.forge/notes/TASK-XXX.md` when it would exceed 3 lines, and leaves a one-line summary plus the path in the workplan `Notes` field (see Data Model/Task Record Data Model). Short notes stay inline.
- **Projection, not reading:** Task selection runs through `wp.js`, which returns only the selected task's fields. The command never loads the full workplan into context.
- **Workplan lint:** After any write to WORKPLAN.md, runs `node .forge/scripts/check-workplan.js`; a nonzero exit blocks proceeding until fixed.
- **Observations:** Before selecting a task, reads STATUS.md Observations and reports every `open` row with `foundation` severity. On task completion, appends any observation rows the execution produced, per Data Model/STATUS.md Data Model. Never promotes an observation to a task.
- **Outputs:** Executed code changes, gate result, updated WORKPLAN.md

### Command: `/forge-status`

- **Reads:** `.forge/WORKPLAN.md` **via `.forge/scripts/wp.js` projection — never in full**, `.forge/STATUS.md` (when present)
- **Task format:** Parses task entries: `## [TASK-XXX] Description` followed by Status, Type, Depends, Context, Gate, Notes fields.
- **Does:**
  - Counts tasks by status: `pending`, `active`, `done`, `blocked`
  - Obtains all counts, the next unblocked task, and clarify/observation listings from `.forge/scripts/wp.js` rather than reading and parsing WORKPLAN.md in context
  - Identifies next unblocked task: first `pending` task whose `Depends` are all `done` or `none`
  - Lists any `clarify`-type tasks that are `pending` or `active` (these need human decisions)
  - Surfaces STATUS.md Observations: `open` rows, `foundation` severity listed first
  - Surfaces STATUS.md items when present: open questions (flagging any marked Blocking), and blockers
- **Outputs:** Progress summary to the user — task counts by status, next unblocked task ID and description, clarify tasks awaiting input (if any), open questions and blockers from STATUS.md (if any). Read-only — no file modifications, no side effects.

### Command: `/forge-spec`

- **Reads:** Raw planning input (idea text, pasted ticket, or file reference provided as arguments), `.forge/VISION.md`, `.forge/CONTRACT.md`, existing `.forge/SPEC.md` / `.forge/specs/*.md`, `.forge/STATUS.md`
- **Does:**
  - Runs a structured intake interview **before drafting**: asks the clarifying questions a senior engineer would ask — target user, success criteria, edge cases, integration points, non-goals. Does not proceed on unstated assumptions when a question would resolve them.
  - Drafts the spec per the SPEC Data Model: Overview, Requirements with EARS-style statements (`WHEN <trigger>, THE SYSTEM SHALL <response>`) and testable acceptance criteria, Flows, Non-Goals.
  - Annotates every inference with `<!-- ASSUMED: reason -->` and every unresolvable unknown with `<!-- UNRESOLVED: ... -->`.
  - Appends unresolved unknowns to STATUS.md Open Questions.
  - Runs `node .forge/scripts/check-spec.js <file>` and fixes structural failures before reporting.
- **Outputs:** `.forge/SPEC.md` or `.forge/specs/<feature>.md`, updated `.forge/STATUS.md`
- **Human action required:** Answer interview questions; review the spec before `/forge-plan` consumes it. `/forge-plan` treats a spec with unresolved plan-blocking questions as a coverage gap.

### Command: `/forge-sync`

- **Reads:** `.forge/VERSION` (line 1: engine version; line 2: canonical repo URL), the canonical Forge repository
- **Does:**
  - Fetches the canonical versions of Forge-managed files: `.claude/commands/forge-*.md`, `.forge/templates/*.md`, `.forge/scripts/check-*.js`
  - Diffs each against the local copy and presents a per-file summary: unchanged, local-only customization, upstream-updated, or conflicting
  - Applies only the updates the human approves, file by file
  - **Never touches project-owned artifacts:** VISION.md, CONTRACT.md, SPEC.md, specs/, WORKPLAN.md, STATUS.md, UX.md, DESIGN.md
  - Updates `.forge/VERSION` after a successful sync
- **Outputs:** Updated Forge-managed files (approved subset), updated `.forge/VERSION`
- **Human action required:** Approve or decline each file update. Local customizations are never silently overwritten.

### Prompt Template Interface

Each template in `.forge/templates/` must contain:

- A `{{context}}` slot for resolved Contract content
- Task-type-specific instructions
- A reminder to run the gate command before reporting completion
- An instruction to update `Notes` if work is incomplete
- An instruction to record out-of-scope findings as STATUS.md Observations rows, applying the in-scope fix test rather than logging reflexively

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
| `checkpoint`  | Pause point closing an unattended span. Assembles a review packet: work done, gate results, manual test steps, STATUS excerpt. Produces no code. | `manual:` — human approves the span |

Each type has a corresponding prompt template in `.forge/templates/`. The task type determines which template `/forge-next` loads for execution.

### CLAUDE.md Integration Block

Exactly 3 lines in the project's CLAUDE.md:

```markdown
## Forge

- Pipeline: .forge/ (VISION.md, CONTRACT.md, SPEC.md, WORKPLAN.md, STATUS.md)
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

### Workplan Access Discipline

WORKPLAN.md is the DAG, not the archive. Two invariants:

1. **The record does not live in the workplan.** Notes beyond 3 lines externalize to `.forge/notes/` (see Data Model/Task Record Data Model). The workplan carries id, status, type, depends, context, gate, and a one-line summary per task — nothing else.

2. **Commands project; they do not read in full.** `/forge-next` and `/forge-status` obtain workplan data through `.forge/scripts/wp.js`, which returns only what the operation needs: the selected task, or the status summary. Loading the whole workplan into the context window is a defect, not a default.

Task selection is entirely deterministic — unblocked-ness, dependency satisfaction, active-task resume, explicit-ID override — and therefore belongs in a script, per Vision pillar 2. WORKPLAN.md is the only Forge artifact that ever lacked access discipline; CONTRACT, SPEC, UX, and DESIGN have been manifest-scoped and budget-capped from the start.

**Format boundary:** WORKPLAN.md stays plain, hand-editable markdown. `wp.js` is an accelerator over that format, never a replacement for it — a human must be able to edit the workplan in any text editor, and a reader must be able to understand it without running anything. This preserves Boundaries/What Forge Does Not Do: no hidden state, no lock-in.

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
- Task IDs, file position, and the dependency DAG encode three different orderings — see Rules/Task Ordering.

### Task Ordering

Three orderings coexist in WORKPLAN.md; only one is normative.

- **`Depends` (the DAG)** is the sole source of execution order. Every other ordering derives from it or carries no meaning.
- **File position** is a maintained projection of the DAG: among `pending` and `active` tasks, every `Depends` entry must appear earlier in the file. File order is therefore always a valid topological sort. This is what lets a human read WORKPLAN.md top to bottom without tooling, and it makes a misplaced insertion detectable rather than silent. Violations among `done` tasks are frozen history — the linter reports them as warnings, and they are not rewritten to satisfy the rule.
- **ID ordinal** is identity only. IDs are never renumbered and never used to infer order. Inserting a task means placing it correctly in the file, not renumbering its neighbors.

Adding a task therefore has two independent obligations: mint a unique ID (see Interfaces/`/forge-plan`), and place the block so its dependencies precede it.

**Known limitation:** `max(existing) + 1` is racy. Two sessions minting against different snapshots of WORKPLAN.md will pick the same ID — a scenario v0.3 makes more likely, not less, since parallel sessions and unattended spans are the point. This is detected by Workplan Lint's uniqueness check rather than prevented, which is deliberate: an ID collision is a merge problem, and Forge resolves merge problems at the checkpoint and the human merge.

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

**File manifest** — when `/forge-next` marks a task `done`, it records the files created or modified (derived from `git diff --name-only` against the task's starting commit). Where that list lands follows the externalization threshold in Data Model/Task Record Data Model:

- **Notes kept inline** (3 lines or fewer): a `Files` line is appended to the task's Notes in WORKPLAN.md.
- **Notes externalized** (more than 3 lines): the list goes in the record's `## Files` section, and the workplan `Notes` field holds only the one-line summary plus the record path. The list is *not* duplicated inline — it is mechanically derived, and two copies drift the moment either is hand-edited.

Either way the requirement→file mapping is recorded in a Forge artifact rather than in code annotations.

**Discovery:**

- Find commits: `git log --oneline --grep="TASK-007"`
- Find files: look at the `Files` line in the task's Notes, or the `## Files` section of `.forge/notes/TASK-007.md` when the task externalized its record, or `git log --name-only --grep="TASK-007"`
- Find which task touched a file: `grep -rl "path/to/file" .forge/WORKPLAN.md .forge/notes/`
- Full diff: `git log -p --grep="TASK-007"`

**Git-optional:** Forge supports projects where `.forge/` is never committed — a common setup when Forge runs locally against a work repository whose history is shared. In that mode `git log --grep` retrieves nothing about tasks, and the `.forge/notes/TASK-XXX.md` record is the sole archaeological artifact. Records must therefore be self-sufficient: a record that says "see the commit" is defective. The git-based discovery commands above are an accelerant where history exists, never the primary mechanism.

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
- A gate must also distinguish done from not-done — see Rules/Gate Discrimination. An automated gate that already passes before the work is worse than a `manual:` one, because it reads as verification.

### Gate Discrimination

A gate's job is to tell a finished task from an unfinished one. A gate that already passes against the repository *before* the task's work begins certifies nothing — it is a **vacuous gate**, and the task it guards ships unverified while reading as verified. Four instances are on record (STATUS.md OBS-008, OBS-010, OBS-013, and TASK-034), every one noticed by an agent after the fact and none by a mechanism. That is the failure mode Vision pillar 2 exists to rule out.

**The requirement:** every gate must fail against the pre-work state and pass against the post-work state. Both halves are load-bearing, and only one is currently caught — a gate that never passes blocks its task immediately and loudly, while a gate that always passes is silent.

Three obligations, at three points in the pipeline:

1. **Authoring — `/forge-plan`.** A gate asserts the change the task makes, not the topic the task is about. `grep -qi "checkpoint" <file>` names a topic and is satisfied by any prior mention; `node .forge/scripts/prose.js <file> "<phrase this task adds>"` names a change. Where a deliverable has no phrase stable enough to assert, the gate asserts through the test suite covering that deliverable, or it is `manual:`.

   **Interaction with Rules/Test-First Convention.** A bare test-suite invocation (`bash .forge/tests/smoke.sh`, `npm test`) passes before the work by construction, because the assertions that would fail have not been written yet. Rules/Test-First Convention requires the gate to *include* a test command; this rule requires it not to *stop* there. A `feature` or `fix` gate therefore names the new assertion alongside the suite — the fixture file the task creates, the new test script, the phrase the task adds — so the suite invocation is never what carries discrimination on its own.

2. **Execution — `wp.js`, at the `pending → active` transition.** Marking a task `active` runs its gate first. A gate that passes on the pre-work state means the task must not proceed on it: the transition is refused, the gate and its output are printed, and the exit code distinguishes this refusal from other failures. `manual:` gates are exempt — there is no command to run. `--force` is the human's override, matching `wp.js next --force`; agents do not pass it.

   Placing the probe at the state transition rather than in `/forge-next`'s prose is deliberate. `/forge-next` reaches the workplan only through `wp.js` (Rules/Workplan Access Discipline), so a task cannot enter execution without passing the probe. A step an agent is merely told to run is a step it may skip — which is how all four recorded instances happened.

3. **Repair, not bypass.** A refused transition is fixed by rewriting the gate to discriminate, in the same session and the same diff as the task's work. A gate that passes because a *prior* task already delivered this task's scope is not a gate defect — it is the OBS-008 condition, and it is reported to the human as a scope finding rather than silently absorbed.

**Why not `check-workplan.js`.** The lint parses; it does not execute. Judging a gate vacuous without running it requires an allowlist of side-effect-free commands, and nearly every gate in a Forge project opens with `bash .forge/tests/…`, which no allowlist can clear by inspection. The lint would therefore skip exactly the gates that matter, while reading as coverage. The transition probe runs the real command at the real moment and needs no allowlist.

**Precedence over `manual:` avoidance.** Rules/Gate Patterns prefers automated gates. It does not prefer an automated gate that certifies nothing: where no discriminating automated check exists, the gate is `manual:`.

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

### Spec Precedence

CONTRACT.md and SPEC.md live side by side and carry different information: the Contract states what must be true (constraints, interfaces, invariants); the Spec states what the system should do (behavior, acceptance criteria, rationale).

- **Where they conflict, the Contract wins.** A conflict is not silently resolved — it is logged as an Open Question in STATUS.md and resolved via a `clarify` task that amends one of the two documents.
- **Neither document duplicates the other.** SPEC references Contract concepts by name; it never redefines data shapes or interfaces. If drafting the Spec requires restating a constraint, that constraint belongs in the Contract and the Spec points to it.
- **Manifest completeness spans both.** A `feature` task manifest that pulls a SPEC requirement without the CONTRACT sections constraining it — or vice versa — fails the completeness test. `/forge-plan` verifies both directions.

### Workplan Lint

WORKPLAN.md invariants are enforced deterministically by `.forge/scripts/check-workplan.js`, not by instruction-following. The script validates:

1. Every task has all required fields with valid values (Status, Type, Depends, Context, Gate).
2. Task IDs are unique; every `Depends` entry references an existing task. For `pending` and `active` tasks, each `Depends` entry must additionally appear earlier in the file (Rules/Task Ordering); the same violation in a `done` task is reported as a warning, not an error.
3. No dependency cycles, checked across the whole graph. Invariant 2's file-order check is scoped to non-`done` tasks and therefore does **not** subsume this one — a cycle confined to `done` tasks escapes invariant 2 entirely.
4. At most one task has status `active`.
5. Every Context reference resolves to an existing heading in its source file.
6. `feature` and `fix` gates invoke a test command — not solely structural checks (grep, ls, test -f).
7. `checkpoint` and `investigate` gates use the `manual:` prefix.

`/forge-plan` and `/forge-next` run the script after any WORKPLAN.md write; a nonzero exit blocks proceeding. It may additionally be wired as a PostToolUse hook for edits made outside the commands.

### Embedded Payload Synchronization

`/forge-init` scaffolds a project by writing out copies of Forge-managed files that also exist in the engine repository — script sources and prompt templates alike. Every such copy is a **payload**. A payload that has drifted from its original ships a stale engine to every new project while the dogfood instance stays correct, and the drift is invisible: both files run, they simply disagree.

Three requirements, all mandatory:

1. **Every payload carries a marker.** The line `<!-- forge-init:embed <path> -->` immediately precedes the fenced block, naming the artifact the block reproduces. A test keys on the marker rather than on prose or fence position, so rewording the surrounding instructions cannot silently disable the check.
2. **Payloads are byte-identical to their originals.** A payload is copied whole, never edited in place. Fixing a script or template means changing the original and re-copying the block.
3. **A test enforces 1 and 2 by content diff, not by sampling.** Asserting that a payload contains the few fields a test happens to name keeps only those fields in sync and leaves the rest free to drift — which is worse than no test, because it reads as coverage. `.forge/tests/test-init-scripts.sh` does this for script payloads; template payloads are subject to the same requirement.

This is Vision pillar 2 applied to the engine's own distribution: if it matters, it must not depend on whoever edits `forge-init.md` remembering to re-copy. <!-- ASSUMED: generalizes the marker-and-diff convention TASK-062 established for script payloads to all payloads, closing OBS-003 -->

### Checkpoint Cadence

Checkpoints concentrate human review at span boundaries instead of every task.

- `/forge-plan` inserts a `checkpoint` task at each dependency-phase boundary, or after every 5 consecutive non-checkpoint tasks, whichever comes first. <!-- ASSUMED: cadence of 5; tune per project -->
- A checkpoint's `Depends` lists every task in its span. Downstream tasks depend on the checkpoint, so the DAG halts there until the human passes it.
- The checkpoint review packet contains: tasks completed in the span (descriptions, and each task's file list — from its `Files` line when notes are inline, or its record's `## Files` section when the record was externalized), gate results and test pass state, manual verification steps if any exist, and the current STATUS.md Open Questions and Risks.
- A failed checkpoint produces `fix` tasks (or a workplan edit / branch rollback) before the pipeline continues. The packet names the span's starting commit so rollback is one git command.

### Unattended Execution

Between checkpoints, the loop (e.g., repeated headless `/forge-next` invocations) may run without per-task human review, under these conditions — all mandatory:

1. **Work branch only.** Never on the default branch. The branch is the blast radius.
2. **One commit per task**, message ending `(TASK-XXX)` — the rhythm does not change, only who approves it. Commits during an unattended span do not require per-commit human review; the checkpoint reviews the span.
3. **No pushing.** Publishing is always human.
4. **Hard stops.** The loop halts at: a `checkpoint` task, a `clarify` task, any task entering `blocked`, or a second consecutive gate failure on the same task, or a new `foundation`-severity observation (the current task finishes cleanly first).
5. **Merge is human.** The span reaches the default branch only through checkpoint approval and a human merge.

Rules 1 and 3 are mechanically enforced by the branch guard and push guard hooks, not by instruction-following alone (see Boundaries#hook-configuration).

The `foundation`-observation stop in rule 4 is likewise mechanical, not advisory: `wp.js next` refuses to select a task while an open `foundation`-severity row exists in STATUS.md Observations, exiting 2 and printing the offending rows. A halt that depends on the executing agent noticing its own warning is not a halt — and this is the one stop an agent must trigger against its own momentum, so it is the one that most needs a mechanism. Two consequences follow:

- **Resuming an `active` task is still permitted.** The contract says the current task finishes cleanly first; refusal applies to selecting new work, never to `resume-active`.
- **The human clears the stop by triaging, not by overriding.** Moving the row's Disposition off `open` — to `accepted` or `declined` — is the designed exit, and it is what makes the observation channel a queue rather than a log. `wp.js next --force` exists for the human who has read the row and wants to continue anyway; agents do not pass it.

## Boundaries

### What Forge Does Not Do

- **No sub-agent dependence.** Fresh top-level sessions are the unit of execution. Sub-agents may assist within a task, but the pipeline never requires them to function. <!-- Amended v0.3: the original blanket ban's rationale (broken parallelism, 7x token cost) is dated -->
- **No hidden state.** Everything is readable markdown files.
- **No conversation continuity dependence.** Every session is self-contained.
- **No auto-merge, no auto-push.** Unattended spans may auto-commit to a work branch (see Rules/Unattended Execution); merging to the default branch and pushing remain human actions. The human is the final gate.
- **No lock-in.** The files are useful even without the commands.

### What Requires Human Approval

- Any modification to CONTRACT.md — approval occurs through Claude Code's native file-write confirmation. `/forge-plan` may write `<!-- ASSUMED: reason -->` annotations directly during validation; substantive amendments (outside of planning) follow the Contract Amendment Protocol.
- Workplan review after `/forge-plan` generates or regenerates tasks.
- The commit step after gate passes — human reviews code before committing. During unattended spans this review moves to the checkpoint (see Rules/Unattended Execution).
- Resolving `clarify` tasks (these require human decisions).
- Passing `checkpoint` tasks — the review packet requires explicit human approval.
- Merging an unattended work branch to the default branch.
- Applying `/forge-sync` updates — approved file by file.

### Hook Configuration

`/forge-plan` writes `.claude/settings.json` during initial scaffold **only if the file does not already exist**. The default configuration:

- **PostToolUse (file edit):** Auto-lint/format after every file write (~200ms, non-blocking). Configured for the detected tech stack, or a no-op placeholder if no linter is detected.
- **PreToolUse (git commit):** Block commits unless test suite passes (exit 0 required). **Disabled by default** — enabled by a later workplan task after test infrastructure exists.
- **PreToolUse (unattended-execution guards):** Three deterministic checks, **enabled by default** — unlike the test-gate hook above, these do not depend on test infrastructure existing:
  1. **Push guard** (`guard-push.sh`) — blocks any Bash command matching `git push`. Always active; publishing is human-only (see Boundaries#what-forge-does-not-do).
  2. **Branch guard** (`guard-branch.sh`) — when the environment variable `FORGE_UNATTENDED=1` is set, blocks `git commit` if the current branch is the repository's default branch. Inert in ordinary interactive sessions. The headless/looped invocation driving an unattended span (see Rules#unattended-execution) sets `FORGE_UNATTENDED=1` before invoking `/forge-next`.
  3. **Secret guard** (`guard-secrets.sh`) — blocks `git commit` when the staged diff matches a conservative set of common secret patterns (cloud access keys, private-key headers, common API-key prefixes). A floor, not a substitute for a dedicated scanner.

  Each guard reads the tool call via Claude Code's PreToolUse hook stdin contract and exits **2** to block. Exit 2 is the only blocking code — Claude Code treats every other nonzero exit as a non-blocking error and lets the tool run anyway.

This avoids broken hooks on first run while ensuring deterministic enforcement is available as early as possible. The human may edit `settings.json` at any time to adjust hook behavior.

### Platform Constraints

- Forge ships 6 commands: forge-init, forge-plan, forge-next, forge-status, forge-spec, forge-sync. Commands stay few and lean by design. <!-- Amended v0.3: the 2025-era slash-command character budget concern has eased; leanness is retained as a principle, not a workaround -->
- Users should run `/context` to verify commands loaded if behavior seems wrong.
