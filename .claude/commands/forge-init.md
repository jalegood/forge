# /forge-init

Bootstrap a new Forge project by creating all required scaffold files. Safe to re-run — never overwrites existing files.

## Steps

### 1. Create `.forge/VISION.md` if absent

Check if `.forge/VISION.md` exists. If it does **not** exist, create it with this stub:

```markdown
# Vision

## What

<!-- Describe what this project builds. One paragraph. -->

## Who

<!-- Describe the primary user or stakeholder. One sentence. -->

## Pillars

<!-- 3-5 non-negotiable principles that constrain all decisions. Bullet list. -->
```

If it exists, skip — do not overwrite.

### 2. Create `.forge/CONTRACT.md` if absent

Check if `.forge/CONTRACT.md` exists. If it does **not** exist, create it with this stub:

```markdown
# Contract

## Data Model

<!-- Artifacts, relationships, and context manifest format. -->

## State Machines

<!-- Task lifecycle and session lifecycle state machines. -->

## Interfaces

<!-- Command interfaces: /forge-init, /forge-plan, /forge-next, /forge-status -->
<!-- Prompt template interface and task types. -->

## Rules

<!-- Task sizing, context budget, manifest completeness, session boundary protocol, -->
<!-- contract amendment protocol, mid-task scope splitting, CLAUDE.md minimalism, -->
<!-- workplan integrity, contract-first, test-first convention, traceability, gate patterns. -->

## Boundaries

<!-- What Forge does not do, what requires human approval, hook configuration, platform constraints. -->
```

If it exists, skip — do not overwrite.

### 3. Create `.forge/SPEC.md` if absent

Check if `.forge/SPEC.md` exists. If it does **not** exist, create it with this stub:

```markdown
# Spec

<!-- When this file exceeds ~300 lines, split into per-feature files under .forge/specs/ -->
<!-- (e.g., .forge/specs/auth.md), referenced from tasks as specs/auth#requirements. -->

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

If it exists, skip — do not overwrite.

### 4. Create `.forge/STATUS.md` if absent

Check if `.forge/STATUS.md` exists. If it does **not** exist, create it with this stub — five tables, headers only, no rows:

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

All five tables are mandatory. `check-workplan.js` resolves `STATUS#observations` and `/forge-next` halts on open `foundation` rows, so a stub missing the Observations table silently disables that hard stop. Emit the header rows even though every table starts empty — writers append rows, they do not create tables.

If it exists, skip — do not overwrite.

### 5. Create `.forge/templates/` with all 7 template files if absent

Check for each of the following files. For any that do **not** exist, create them with the stub below. If a file exists, skip it — do not overwrite.

**`.forge/templates/scaffold.md`** — if absent, create:

<!-- forge-init:embed .forge/templates/scaffold.md -->

```markdown
# Scaffold Task

You are executing a **scaffold** task. Your job is to set up project structure, configuration, and boilerplate.

## Task

**ID:** {{task_id}}
**Description:** {{task_description}}
**Gate:** `{{gate}}`

## Contract Context

The following Contract sections are relevant to this task. Stay within these constraints.

{{context}}

## Instructions

1. **Read before writing.** Check what already exists. Don't overwrite working files.
2. **Structure first.** Create directories, config files, and boilerplate in a logical order.
3. **Follow conventions.** Match any existing project patterns (naming, file organization, code style).
4. **Keep it minimal.** Scaffold only what's needed. Don't add features, utilities, or abstractions that aren't in the task description.
5. **Wire things up.** Ensure new files are properly referenced (imports, config entries, package.json scripts).
6. **Record what you noticed but did not fix.** Apply the in-scope test: if the fix is covered by this task's gate and belongs in this task's diff, make it now — no observation needed. Otherwise append one row to the Observations table in `.forge/STATUS.md` and move on. This channel captures what would otherwise be lost, not what would otherwise be fixed; most tasks produce no rows at all, and that is the expected case rather than a gap to fill.
   - Row format: `| OBS-XXX | {{task_id}} | design/bug/scope/... | normal or foundation | One-line observation. | open |`, where `OBS-XXX` is the highest existing OBS id plus one.
   - One line per observation — a pointer, not a report.
   - No observation spawns a task on its own. Only a human promotes one, later.
   - More than three from this task collapse into a single `foundation` row: volume of small complaints is itself the signal that the foundation is wrong, and recording it as volume buries that signal.
   - `foundation` means the spec, contract, or approach is suspect and continuing to build compounds debt. Everything else is `normal`.

## Completion

When you believe the scaffold is complete:

1. Run the gate command: `{{gate}}`
2. If the gate **passes**: report success and suggest a commit message.
3. If the gate **fails**: diagnose the failure, fix it, and re-run the gate.
4. If you **cannot complete** the task in this session, update the `Notes` field in WORKPLAN.md with:
   - What was done
   - What remains
   - Any decisions or blockers encountered
```

**`.forge/templates/feature.md`** — if absent, create:

<!-- forge-init:embed .forge/templates/feature.md -->

```markdown
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

Follow this test-first ordering strictly:

1. **Write tests** that specify the expected behavior. Tests come before implementation — express what the feature must do, not how.
2. **Run the test command** to confirm the tests exercise new behavior (they may fail or be skipped — that's expected at this stage).
3. **Write implementation** to satisfy the tests. Stop when tests pass.
4. **One concern only.** This task should touch one API endpoint, one component, or one data flow. If you find yourself reaching into unrelated areas, stop — that's a separate task.
5. **Contract is law.** The context above defines what this feature must do. Don't invent requirements beyond what's specified. Don't skip requirements that are specified.
6. **Interfaces matter.** Match the shapes, types, and contracts defined above. Downstream tasks depend on your interfaces being correct.
7. **Keep it tight.** No premature abstractions, no "while I'm here" improvements, no speculative generality.
8. **Record what you noticed but did not fix.** Apply the in-scope test: if the fix is covered by this task's gate and belongs in this task's diff, make it now — no observation needed. Otherwise append one row to the Observations table in `.forge/STATUS.md` and move on. This channel captures what would otherwise be lost, not what would otherwise be fixed; most tasks produce no rows at all, and that is the expected case rather than a gap to fill.
   - Row format: `| OBS-XXX | {{task_id}} | design/bug/scope/... | normal or foundation | One-line observation. | open |`, where `OBS-XXX` is the highest existing OBS id plus one.
   - One line per observation — a pointer, not a report.
   - No observation spawns a task on its own. Only a human promotes one, later.
   - More than three from this task collapse into a single `foundation` row: volume of small complaints is itself the signal that the foundation is wrong, and recording it as volume buries that signal.
   - `foundation` means the spec, contract, or approach is suspect and continuing to build compounds debt. Everything else is `normal`.

## Completion

When you believe the feature is complete:

1. Run the gate command: `{{gate}}`
2. If the gate **passes**: report success and suggest a commit message.
3. If the gate **fails**: diagnose the failure, fix it, and re-run the gate.
4. If you **cannot complete** the task in this session, update the `Notes` field in WORKPLAN.md with:
   - What was done
   - What remains
   - Any decisions or blockers encountered
```

**`.forge/templates/fix.md`** — if absent, create:

<!-- forge-init:embed .forge/templates/fix.md -->

```markdown
# Fix Task

You are executing a **fix** task. Your job is to fix a broken gate or bug from a previous task.

## Task

**ID:** {{task_id}}
**Description:** {{task_description}}
**Gate:** `{{gate}}`

## Contract Context

The following Contract sections define the expected behavior that is currently broken.

{{context}}

## Instructions

Follow this test-first ordering strictly:

1. **Reproduce first.** Run the failing gate command or test to see the actual error. Don't guess at the problem.
2. **Read the diagnostics.** Check the `Notes` field from the previous task — it may contain error output or a diagnosis.
3. **Write a failing test** that captures the bug behavior. This anchors the fix and prevents regression. Skip this step only if an existing test already isolates the failure.
4. **Root cause, not symptoms.** Find why it broke, not just what broke. A surface fix that passes the gate but leaves the underlying issue will fail again downstream.
5. **Minimal fix.** Change only what's necessary to fix the issue. Don't refactor, don't improve, don't clean up surrounding code.
6. **Verify the original gate.** The gate for this fix task should include the original failing command. Make sure that specific command passes.
7. **Record what you noticed but did not fix.** Apply the in-scope test: if the fix is covered by this task's gate and belongs in this task's diff, make it now — no observation needed. Otherwise append one row to the Observations table in `.forge/STATUS.md` and move on. This channel captures what would otherwise be lost, not what would otherwise be fixed; most tasks produce no rows at all, and that is the expected case rather than a gap to fill.
   - Row format: `| OBS-XXX | {{task_id}} | design/bug/scope/... | normal or foundation | One-line observation. | open |`, where `OBS-XXX` is the highest existing OBS id plus one.
   - One line per observation — a pointer, not a report.
   - No observation spawns a task on its own. Only a human promotes one, later.
   - More than three from this task collapse into a single `foundation` row: volume of small complaints is itself the signal that the foundation is wrong, and recording it as volume buries that signal.
   - `foundation` means the spec, contract, or approach is suspect and continuing to build compounds debt. Everything else is `normal`.

## Completion

When the fix is applied:

1. Run the gate command: `{{gate}}`
2. If the gate **passes**: report success and suggest a commit message.
3. If the gate **fails**: diagnose further. If you're stuck, write a detailed diagnostic to `Notes` so the next session can pick up.
4. If you **cannot complete** the task in this session, update the `Notes` field in WORKPLAN.md with:
   - The root cause (if identified)
   - What you tried
   - What remains to investigate
```

**`.forge/templates/clarify.md`** — if absent, create:

<!-- forge-init:embed .forge/templates/clarify.md -->

```markdown
# Clarify Task

You are executing a **clarify** task. Your job is to resolve an ambiguity or open question in the Contract.

## Task

**ID:** {{task_id}}
**Description:** {{task_description}}
**Gate:** `{{gate}}`

## Contract Context

The following Contract sections contain the ambiguity or `<!-- UNRESOLVED -->` item to address.

{{context}}

## Instructions

1. **Identify the ambiguity.** Locate the specific `<!-- UNRESOLVED: ... -->` comment or unclear requirement in the context above.
2. **Present options.** Lay out 2-3 concrete options for resolving the ambiguity. For each option, state:
   - What it means concretely
   - Trade-offs (complexity, flexibility, constraints)
   - Your recommendation and why
3. **Wait for the human.** This task requires a human decision. Present your analysis and options clearly, then ask the human to choose.
4. **Apply the decision.** Once the human decides, update CONTRACT.md:
   - Remove the `<!-- UNRESOLVED -->` comment
   - Replace it with the resolved specification
   - Ensure the resolution is testable (can you write an assertion for it?)
5. **Log the decision in `.forge/STATUS.md`.** The Contract edit records *what* the answer is; the Decisions section records *why it is that answer* — and it is the only place the reasoning survives the session.
   - Add a dated section at the top of `## Decisions` (newest first): `### YYYY-MM-DD — Short title`, then the decision as prose, then a `**Why:**` paragraph, then a `**Rejected alternatives:**` paragraph. Use today's real date.
   - **The rejected alternatives are mandatory, not decoration.** The options from step 2 the human turned down go in that paragraph, each with the reason it lost. Omit them and the next session re-opens the settled question and re-derives the same answers.
   - **If the ambiguity was tracked as an Open Questions row, delete that row.** The question *moves* to Decisions — it does not exist in both places. A resolved question left sitting under Open Questions is indistinguishable from an unresolved one to everyone who reads that table, including `/forge-status`.
   - If no Open Questions row existed, still write the Decisions entry. The trigger is a decision being made, not a question having been filed.
6. **Record what you noticed but did not fix.** Apply the in-scope test: if the fix is covered by this task's gate and belongs in this task's diff, make it now — no observation needed. Otherwise append one row to the Observations table in `.forge/STATUS.md` and move on. This channel captures what would otherwise be lost, not what would otherwise be fixed; most tasks produce no rows at all, and that is the expected case rather than a gap to fill.
   - Row format: `| OBS-XXX | {{task_id}} | design/bug/scope/... | normal or foundation | One-line observation. | open |`, where `OBS-XXX` is the highest existing OBS id plus one.
   - One line per observation — a pointer, not a report.
   - No observation spawns a task on its own. Only a human promotes one, later.
   - More than three from this task collapse into a single `foundation` row: volume of small complaints is itself the signal that the foundation is wrong, and recording it as volume buries that signal.
   - `foundation` means the spec, contract, or approach is suspect and continuing to build compounds debt. Everything else is `normal`.

## Completion

When the ambiguity is resolved:

1. Run the gate command: `{{gate}}`
2. If the gate **passes**: report success and suggest a commit message.
3. If the gate **fails**: diagnose the failure, fix it, and re-run the gate.
4. If you **cannot complete** the task (e.g., awaiting human decision), update the `Notes` field in WORKPLAN.md with:
   - The options you presented
   - Which option(s) the human is considering
   - Any context that would help the next session
```

**`.forge/templates/refactor.md`** — if absent, create:

<!-- forge-init:embed .forge/templates/refactor.md -->

```markdown
# Refactor Task

You are executing a **refactor** task. Your job is to improve code structure without changing behavior.

## Task

**ID:** {{task_id}}
**Description:** {{task_description}}
**Gate:** `{{gate}}`

## Contract Context

The following Contract sections define the interfaces and rules that must be preserved.

{{context}}

## Instructions

1. **Behavior stays the same.** This is a refactor, not a feature. All existing tests must continue to pass. All interfaces must remain compatible.
2. **Read first.** Understand the current structure before changing it. Identify what's wrong and why the refactor is needed.
3. **One structural change.** Don't refactor everything — address the specific concern in the task description.
4. **Tests are your safety net.** Run existing tests frequently. If tests don't exist for the code you're changing, write them first (as characterization tests), then refactor.
5. **Small steps.** Make incremental changes and verify after each step. Don't rewrite entire files in one pass.
6. **Record what you noticed but did not fix.** Apply the in-scope test: if the fix is covered by this task's gate and belongs in this task's diff, make it now — no observation needed. Otherwise append one row to the Observations table in `.forge/STATUS.md` and move on. This channel captures what would otherwise be lost, not what would otherwise be fixed; most tasks produce no rows at all, and that is the expected case rather than a gap to fill.
   - Row format: `| OBS-XXX | {{task_id}} | design/bug/scope/... | normal or foundation | One-line observation. | open |`, where `OBS-XXX` is the highest existing OBS id plus one.
   - One line per observation — a pointer, not a report.
   - No observation spawns a task on its own. Only a human promotes one, later.
   - More than three from this task collapse into a single `foundation` row: volume of small complaints is itself the signal that the foundation is wrong, and recording it as volume buries that signal.
   - `foundation` means the spec, contract, or approach is suspect and continuing to build compounds debt. Everything else is `normal`.

## Completion

When the refactor is complete:

1. Run the gate command: `{{gate}}`
2. If the gate **passes**: report success and suggest a commit message.
3. If the gate **fails**: diagnose the failure, fix it, and re-run the gate.
4. If you **cannot complete** the task in this session, update the `Notes` field in WORKPLAN.md with:
   - What was done
   - What remains
   - Any decisions or blockers encountered
```

**`.forge/templates/investigate.md`** — if absent, create:

<!-- forge-init:embed .forge/templates/investigate.md -->

```markdown
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
5. **Record what you noticed but did not fix.** Apply the in-scope test: if the fix is covered by this task's gate and belongs in this task's diff, make it now — no observation needed. Otherwise append one row to the Observations table in `.forge/STATUS.md` and move on. This channel captures what would otherwise be lost, not what would otherwise be fixed; most tasks produce no rows at all, and that is the expected case rather than a gap to fill.
   - Row format: `| OBS-XXX | {{task_id}} | design/bug/scope/... | normal or foundation | One-line observation. | open |`, where `OBS-XXX` is the highest existing OBS id plus one.
   - One line per observation — a pointer, not a report.
   - No observation spawns a task on its own. Only a human promotes one, later.
   - More than three from this task collapse into a single `foundation` row: volume of small complaints is itself the signal that the foundation is wrong, and recording it as volume buries that signal.
   - `foundation` means the spec, contract, or approach is suspect and continuing to build compounds debt. Everything else is `normal`.

## Completion

When the investigation is complete:

1. Run the gate command: `{{gate}}`
2. If the gate is `manual:`, present your findings and proposed next steps to the human for review.
3. Ensure the `Notes` field in WORKPLAN.md contains:
   - Root cause or key findings
   - Evidence (error messages, log excerpts, relevant code paths)
   - Recommended next steps, written as findings for the human — you do not add tasks to the workplan yourself
4. If you **cannot complete** the investigation in this session, update `Notes` with:
   - What you've learned so far
   - What remains to explore
   - Any hypotheses to test next
```

**`.forge/templates/checkpoint.md`** — if absent, create:

<!-- forge-init:embed .forge/templates/checkpoint.md -->

```markdown
# Checkpoint Task

You are executing a **checkpoint** task. Your job is to assemble a review packet for the span of tasks this checkpoint closes, present it, and stop. This task produces no code.

## Task

**ID:** {{task_id}}
**Description:** {{task_description}}
**Gate:** `{{gate}}`

## Contract Context

{{context}}

## Instructions

The span is exactly the task IDs in this checkpoint's `Depends` field. Read each one through the projection — `node .forge/scripts/wp.js get TASK-XXX` — never by opening WORKPLAN.md.

1. **Assemble the span.** For each task in `Depends`, give its ID, description, and file list. The file list is the `Files:` line in its Notes when the notes are inline, or the `## Files` section of `.forge/notes/TASK-XXX.md` when the Notes name a record.
2. **Re-run every automated gate in the span, fresh.** Status alone is not evidence — a later task in the span can silently break an earlier task's gate, which is the entire reason this checkpoint exists. Report each gate with its **actual output**, not a bare pass/fail.
   - A gate that fails fresh on a task whose status is `done` is a **regression** — flag it explicitly. `/forge-next` marks a task `done` only after its gate passes, so `done` is the record that it passed at completion; no stored result exists to compare against, and none is needed.
   - **Never summarize a span containing a regression as clean.** One regression outranks any number of passes in the summary line.
   - Gates whose value begins with `manual:` are **listed with their verification steps, not executed.** Running them is the human's job at this checkpoint.
3. **Excerpt `.forge/STATUS.md` into the packet** — quote the rows, never cite the file by reference:
   - Open Questions (all rows, flagging any marked Blocking) and Risks (all rows).
   - Open Observations rows, `foundation` severity first.
   - Any Decisions entry (dated section) inside the span that records a mid-span course correction — a redirect the human made mid-flight is the thing least likely to be remembered and most likely to need review.
4. **Name the rollback.** Give the span's starting commit and the one command that undoes the span. Resolve the commit with `git log --format='%H %s' | grep -F '(TASK-FIRST)'` for the span's first task, then take its parent (`<sha>^`); if the span's tasks were not committed individually, use the merge-base with the branch the span started from. State plainly that the command discards the span's work — the human runs it, you never do.
5. **The packet must stand on its own.** The human passes or fails this span by reading what you present and nothing else. Any sentence that sends them to a file to find out what happened is a defect in the packet, not a reference.
6. **Record what you noticed but did not fix.** Apply the in-scope test: if the fix is covered by this task's gate and belongs in this task's diff, make it now — no observation needed. Otherwise append one row to the Observations table in `.forge/STATUS.md` and move on. This channel captures what would otherwise be lost, not what would otherwise be fixed; most tasks produce no rows at all, and that is the expected case rather than a gap to fill.
   - Row format: `| OBS-XXX | {{task_id}} | design/bug/scope/... | normal or foundation | One-line observation. | open |`, where `OBS-XXX` is the highest existing OBS id plus one.
   - One line per observation — a pointer, not a report.
   - No observation spawns a task on its own. Only a human promotes one, later.
   - More than three from this task collapse into a single `foundation` row: volume of small complaints is itself the signal that the foundation is wrong, and recording it as volume buries that signal.
   - `foundation` means the spec, contract, or approach is suspect and continuing to build compounds debt. Everything else is `normal`.

## Completion

The gate is `manual:` — the human approves the span. Confirm the gate command before reporting completion, then:

1. Present the packet and **end it with an explicit pass/fail question**: "Does this checkpoint pass? (pass/fail)".
2. **Stop and wait.** Do not select further work, do not mark this task `done`, and do not commit. An unanswered packet blocks every downstream task by construction — that is the checkpoint doing its job, not a stall.
3. If the human **passes** the span: report success and suggest a commit message.
4. If the human **fails** the span: record what failed and what they directed — `fix` tasks, a workplan edit, or a rollback — in the `Notes` field via `node .forge/scripts/wp.js append-notes {{task_id}} '...'`. You do not add tasks to the workplan yourself.
5. If you **cannot finish assembling the packet** in this session, append to `Notes` with:
   - Which span tasks are already summarized and which gates you have re-run
   - What remains to assemble
   - Any regression already found, so it is not lost if the session ends here
```

### 6. Ask whether the project has a user-facing interface, then create `.forge/UX.md` if needed

Ask the human: **"Does this project have a user-facing interface (UI/UX)?"**

If the answer is unclear, ask again — do not guess a default.

- **If no:** skip this step, step 7 (`DESIGN.md`), and step 8 (`check-ux-spec.js`) entirely. Do not create `.forge/UX.md`, `.forge/DESIGN.md`, or `.forge/scripts/check-ux-spec.js`. Proceed to step 9.
- **If yes:** continue below.

Check if `.forge/UX.md` exists. If it does **not** exist, create it with this stub:

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
**Emotional intent:** <!-- What should the user FEEL at this moment? Be specific. -->
**Design intention:** <!-- The specific decision that elevates this screen above a generic implementation. -->

##### States

| State | Trigger | Experience |
| ----- | ------- | ---------- |
|       |         |            |

<!-- Example: | Loading | Fetch triggered | Skeleton fade-in, opacity 0→1 over 200ms | -->

##### Edge Cases

| Condition          | Behavior |
| ------------------ | -------- |
| Empty / first-time |          |
| Error              |          |
```

If it exists, skip — do not overwrite.

Also create `.forge/templates/ux-spec.md` if absent (only reached when step 6 was answered "yes" — skipped otherwise):

<!-- forge-init:embed .forge/templates/ux-spec.md -->

```markdown
# UX Spec Task

You are executing a **ux-spec** task. Your job is to author or complete a screen spec in UX.md. This task produces no code — only a completed screen specification.

## Task

**ID:** {{task_id}}
**Description:** {{task_description}}
**Gate:** `{{gate}}`

## Contract Context

The following sections are relevant to this task. The UX.md stub to complete is included below.

{{context}}

## Instructions

1. **Read the stub.** Locate the screen referenced in the task description within `.forge/UX.md`.
2. **Complete all mandatory fields.** Every screen must have `**Emotional intent:**` and `**Design intention:**` filled with specific, non-placeholder language.
3. **Fill in States.** Every state row must have a specific, measurable Experience value. No vague terms like "smooth", "fast", or "subtle" — use numeric values (e.g., "ease-out 250ms") for anything involving time, physics, or sensation.
4. **Fill in Edge Cases.** At minimum: Empty/first-time behavior and Error behavior.
5. **Precision rule.** Prose is permitted only in Emotional intent, Design intention, and Copy Tone. All cells involving measurable qualities must be numeric or reference a named pattern.
6. **Record what you noticed but did not fix.** Apply the in-scope test: if the fix is covered by this task's gate and belongs in this task's diff, make it now — no observation needed. Otherwise append one row to the Observations table in `.forge/STATUS.md` and move on. This channel captures what would otherwise be lost, not what would otherwise be fixed; most tasks produce no rows at all, and that is the expected case rather than a gap to fill.
   - Row format: `| OBS-XXX | {{task_id}} | design/bug/scope/... | normal or foundation | One-line observation. | open |`, where `OBS-XXX` is the highest existing OBS id plus one.
   - One line per observation — a pointer, not a report.
   - No observation spawns a task on its own. Only a human promotes one, later.
   - More than three from this task collapse into a single `foundation` row: volume of small complaints is itself the signal that the foundation is wrong, and recording it as volume buries that signal.
   - `foundation` means the spec, contract, or approach is suspect and continuing to build compounds debt. Everything else is `normal`.

## Completion

When the screen spec is complete:

1. Run the gate command: `{{gate}}`
2. If the gate **passes**: report success and suggest a commit message.
3. If the gate **fails**: read the validation errors, fix the offending fields, and re-run.
4. If you **cannot complete** the task in this session, update the `Notes` field in WORKPLAN.md with:
   - What was completed
   - What remains
   - Any decisions or blockers encountered
```

If it exists, skip — do not overwrite.

### 7. Create `.forge/DESIGN.md` if absent

Only run this step if step 6 was answered "yes". If it was answered "no", this step was already skipped.

Check if `.forge/DESIGN.md` exists. If it does **not** exist, create it with this stub:

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

<!-- Aesthetic rationale and cross-cutting component rules -->
```

If it exists, skip — do not overwrite.

### 8. Create `.forge/scripts/check-ux-spec.js` if absent

Only run this step if step 6 was answered "yes". If it was answered "no", this step was already skipped.

Check if `.forge/scripts/check-ux-spec.js` exists. If it does **not** exist, create `.forge/scripts/` directory if needed, then create `check-ux-spec.js` with:

<!-- forge-init:embed .forge/scripts/check-ux-spec.js -->

```javascript
#!/usr/bin/env node
// check-ux-spec.js — validate one screen spec in .forge/UX.md by screen name
// Usage: node .forge/scripts/check-ux-spec.js "Screen Name"
// Exit 0 = valid, Exit 1 = invalid (errors printed to stderr)

const fs = require('fs');
const path = require('path');
const { parseHeadings, normalizeSlug, findHeading, sectionRange, findRoot } = require('./lib/markdown');

const screenName = process.argv[2];
if (!screenName) {
  console.error('Usage: node .forge/scripts/check-ux-spec.js "Screen Name"');
  process.exit(1);
}

// Nearest ancestor of the working directory holding .forge/ (TASK-072).
const uxPath = path.join(findRoot(), '.forge', 'UX.md');
if (!fs.existsSync(uxPath)) {
  console.error('Error: .forge/UX.md not found');
  process.exit(1);
}

const content = fs.readFileSync(uxPath, 'utf8').replace(/\r\n/g, '\n');

// Find the screen's "#### Screen: <name>" heading and extract through the next
// heading at the same level or higher. Scanning goes through lib/markdown.js so
// that `#`-prefixed lines inside ``` fences are not mistaken for headings — a
// quoted spec skeleton inside a screen used to truncate the section early.
const headings = parseHeadings(content);
const screenHeading = findHeading(headings, normalizeSlug(screenName), { level: 4, prefix: 'Screen' });
if (!screenHeading) {
  console.error(`Error: Screen "${screenName}" not found in UX.md`);
  process.exit(1);
}

// Body excludes the heading line itself, matching the previous implementation.
const { start, end } = sectionRange(headings, screenHeading, content.length);
const nl = content.indexOf('\n', start);
const bodyStart = nl === -1 || nl > end ? end : nl;
const screenContent = content.slice(bodyStart, end);

const errors = [];

// Check mandatory fields are present and not placeholders
const mandatoryFields = ['**Emotional intent:**', '**Design intention:**'];
for (const field of mandatoryFields) {
  const idx = screenContent.indexOf(field);
  if (idx === -1) {
    errors.push(`Missing mandatory field: ${field}`);
  } else {
    const afterField = screenContent.slice(idx + field.length).trim();
    const firstLine = afterField.split('\n')[0].trim();
    if (!firstLine || firstLine.startsWith('<!--') || firstLine === 'TODO' || firstLine === 'TBD') {
      errors.push(`${field} is empty or placeholder`);
    }
  }
}

// Sub-sections are located the same fence-aware way as the screen itself, so a
// quoted "##### States" inside a fence is not mistaken for the real one.
const subHeadings = parseHeadings(screenContent);

// Check States table exists and has at least one data row
const statesHeading = findHeading(subHeadings, normalizeSlug('States'), { level: 5 });
if (!statesHeading) {
  errors.push('Missing section: ##### States');
} else {
  const statesRange = sectionRange(subHeadings, statesHeading, screenContent.length);
  const statesBody = screenContent.slice(statesRange.start, statesRange.end);
  const dataRows = statesBody.split('\n').filter(line => {
    const trimmed = line.trim();
    return trimmed.startsWith('|') && !trimmed.includes('---') && !/^\|\s*State\s*\|/i.test(trimmed);
  });
  if (dataRows.length === 0) {
    errors.push('States table has no data rows');
  }

  // Reject vague terms in the Experience column only (3rd cell) — State/Trigger labels
  // may legitimately contain words like "slow" or "fast" without violating precision.
  const experienceCells = dataRows.map(row => {
    const cells = row.split('|');
    return cells[3] !== undefined ? cells[3].trim() : '';
  });
  const vagueTerms = ['smooth', 'fast', 'subtle', 'snappy', 'quick', 'slow', 'nice', 'clean', 'simple'];
  for (const term of vagueTerms) {
    const regex = new RegExp(`\\b${term}\\b`, 'i');
    if (experienceCells.some(cell => regex.test(cell))) {
      errors.push(`Vague term "${term}" found in States table Experience column — use numeric/named values (e.g., "ease-out 250ms")`);
    }
  }
}

// Check Edge Cases section exists
if (!findHeading(subHeadings, normalizeSlug('Edge Cases'), { level: 5 })) {
  errors.push('Missing section: ##### Edge Cases');
}

if (errors.length > 0) {
  console.error(`Screen "${screenName}" spec validation failed:\n`);
  errors.forEach(e => console.error(`  - ${e}`));
  process.exit(1);
}

console.log(`Screen "${screenName}" spec is valid.`);
process.exit(0);
```

If `.forge/scripts/check-ux-spec.js` exists, skip — do not overwrite.

### 9. Create `.claude/settings.json` if absent

Check if `.claude/settings.json` exists. If it does **not** exist, create `.claude/` directory if needed, then create `settings.json` with:

```json
{
  "hooks": {
    "PostToolUse": [
      {
        "matcher": "Write|Edit|MultiEdit",
        "hooks": [
          {
            "type": "command",
            "command": "echo 'File saved.'",
            "description": "Placeholder lint hook — replace with project linter (e.g., eslint --fix, ruff format)"
          }
        ]
      }
    ],
    "PreToolUse": [
      {
        "matcher": "Bash",
        "hooks": [
          {
            "type": "command",
            "command": "exit 0",
            "description": "Commit gate — disabled by default. Enable after test infrastructure exists by replacing with: npm test or equivalent."
          }
        ]
      },
      {
        "matcher": "Bash",
        "hooks": [
          {
            "type": "command",
            "command": "bash .forge/scripts/guard-push.sh"
          },
          {
            "type": "command",
            "command": "bash .forge/scripts/guard-branch.sh"
          },
          {
            "type": "command",
            "command": "bash .forge/scripts/guard-secrets.sh"
          }
        ]
      }
    ]
  }
}
```

The three unattended-execution guards in that second `PreToolUse` entry are **enabled by default**, unlike the commit gate above them (CONTRACT#boundaries/hook-configuration). The commit gate waits on test infrastructure that a fresh project does not have yet; the guards depend on nothing and enforce CONTRACT#rules/unattended-execution rules 1 and 3 mechanically, rather than by instruction-following. Step 11 creates the scripts themselves — `guard-push.sh`, `guard-branch.sh`, and `guard-secrets.sh`.

Two of the three are inert in ordinary use, by design:

- `guard-push.sh` blocks `git push` always. Publishing is human-only.
- `guard-branch.sh` blocks `git commit` on the repository's default branch **only when the environment variable `FORGE_UNATTENDED=1` is set**. Interactive sessions never set it, so committing straight to the default branch — the normal, human-reviewed habit on a personal project — is untouched. The flag is set by the headless launcher that drives an unattended span, never typed by a human before a run: a forgotten `export` would restore default-branch committing in exactly the case where nobody is watching to catch it.
- `guard-secrets.sh` blocks `git commit` when the staged diff adds a line matching a conservative secret pattern. A floor, not a substitute for a dedicated scanner.

If `.claude/settings.json` exists, skip — do not overwrite.

### 10. Append Forge integration block to `CLAUDE.md` if absent

Check if `CLAUDE.md` exists in the project root.

- If `CLAUDE.md` does **not** exist, create it with exactly:

```markdown
## Forge

- Pipeline: .forge/ (VISION.md, CONTRACT.md, WORKPLAN.md)
- Workflow: /forge-next → review → commit → /clear
- Do not modify CONTRACT.md without asking first
```

- If `CLAUDE.md` exists, check whether it already contains `Pipeline: .forge/`. If it does, skip — do not append. If it does not contain that line, append the integration block to the end of the file (preceded by a blank line).

### 11. Create the `.forge/scripts/` engine scripts if absent

Unconditional — these are not gated on the step 6 interface question. `/forge-next` and `/forge-plan` both run the workplan lint after every WORKPLAN.md write and treat a nonzero exit as a hard block, and `/forge-next` and `/forge-status` reach the workplan only through `wp.js` (CONTRACT#rules/workplan-access-discipline), so a project without these files cannot complete a task.

Create `.forge/scripts/lib/` (both the `scripts` and `lib` directories) if needed.

The blocks below are exact copies of the engine's scripts. Copy them verbatim — they are diffed against the originals by `.forge/tests/test-init-scripts.sh`, and the `<!-- forge-init:embed -->` markers are what that test keys on. Do not edit the payloads in place; if a script changes, re-copy the whole block.

The last three are the unattended-execution guards wired up in step 9 — `guard-push.sh`, `guard-branch.sh`, and `guard-secrets.sh`. They are as unconditional as the rest: the hook entries created in step 9 name them by path, so a project that skips them has three `PreToolUse` hooks pointing at nothing.

Order matters only in that the two `lib/` modules must exist before the scripts that require them; create all of them.
If `.forge/scripts/lib/markdown.js` does **not** exist, create it with:

<!-- forge-init:embed .forge/scripts/lib/markdown.js -->

```javascript
// markdown.js — shared markdown section resolution (CONTRACT#data-model/context-manifest)
//
// One implementation of "find a heading, extract through the next same-or-higher
// heading". Previously duplicated in check-ux-spec.js (ad-hoc regex, not
// fence-aware) and check-workplan.js (level-scoped, fence-aware). The
// fence-aware version is the correct one and is what lives here — CONTRACT.md
// alone holds fenced blocks containing heading-like lines, so a scanner that
// ignores fences truncates real sections early.
//
// Exports: parseHeadings, normalizeSlug, headingCompact, sectionRange,
//          findHeading, resolveSegments, resolveRef, createLoader

'use strict';

const fs = require('fs');
const path = require('path');

// --- Slug comparison ---
// Compacts to lowercase alnum-only. Deliberately looser than a strict
// hyphen-slug: it tolerates the mixed "x.md-data-model" / "xmd-data-model"
// punctuation already present in this project's hand-written Context fields.

function normalizeSlug(s) {
  return s.trim().toLowerCase().replace(/[^a-z0-9]/g, '');
}

// UX.md headings carry a "Flow: " / "Screen: " label prefix that is part of the
// document convention, not part of the name being referenced.
//
// A heading that opens with a bracketed token — `### [req-login] User Login` —
// compacts to the bracketed token alone (CONTRACT#data-model/context-manifest,
// requirement-heading matching). The trailing text is a prose name that gets
// reworded; the slug is the identifier and does not. Matching the whole heading
// would make every manifest reference break on the next copy edit. The rule is
// about the bracket, not about SPEC.md — per-feature files under `.forge/specs/`
// carry the same heading shape.
function headingCompact(text) {
  const stripped = text.trim().replace(/^(Flow|Screen):\s*/, '');
  const bracketed = /^\[([^\]]+)\]/.exec(stripped);
  return normalizeSlug(bracketed ? bracketed[1] : stripped);
}

// --- Heading scan ---
// Returns [{ level, text, index }] where index is the offset of the heading
// line's first character. Lines inside ``` fences are not headings.

function parseHeadings(fileContent) {
  const lines = fileContent.split('\n');
  const headings = [];
  let offset = 0;
  let inFence = false;
  for (const line of lines) {
    if (/^\s*```/.test(line)) {
      inFence = !inFence;
    } else if (!inFence) {
      const m = /^(#{1,6})\s+(.*)$/.exec(line);
      if (m) headings.push({ level: m[1].length, text: m[2].trim(), index: offset });
    }
    offset += line.length + 1;
  }
  return headings;
}

// --- Section extraction ---
// A section runs from its heading (inclusive) to just before the next heading
// at the same level or higher.

function sectionRange(headings, match, contentLength) {
  const next = headings.find(h => h.index > match.index && h.level <= match.level);
  return { start: match.index, end: next ? next.index : contentLength };
}

// Find the first heading whose compacted text equals `slug`, within an optional
// scope window and level constraints.
//   scopeStart/scopeEnd — offset window to search (default: whole document)
//   minLevel            — heading must be deeper than this (nested navigation)
//   level               — heading must be exactly this level
//   prefix              — heading text must start with this label (e.g. 'Screen')
function findHeading(headings, slug, opts = {}) {
  const {
    scopeStart = 0,
    scopeEnd = Infinity,
    minLevel = 0,
    level = null,
    prefix = null,
  } = opts;

  return headings.find(h => {
    if (h.index < scopeStart || h.index >= scopeEnd) return false;
    if (h.level <= minLevel) return false;
    if (level !== null && h.level !== level) return false;
    if (prefix !== null && !new RegExp(`^${prefix}:\s*`).test(h.text)) return false;
    return headingCompact(h.text) === slug;
  });
}

// --- Segment navigation ---
// Walks "a/b/c" style reference segments. Each segment is matched within the
// previous segment's section and must be strictly deeper than it, so
// `requirements/req-login` cannot match a `req-login` heading in a sibling
// section. Returns the resolved range on success.
//
// `file` is { content, headings }. `label` is used only in error text.

function resolveSegments(file, segments, label) {
  const ref = label || segments.join('/');
  if (!segments.length) return { ok: false, reason: `"${ref}" has no path segments` };

  let scopeStart = 0;
  let scopeEnd = file.content.length;
  let minLevel = 0;
  let match = null;

  for (const seg of segments) {
    match = findHeading(file.headings, normalizeSlug(seg), { scopeStart, scopeEnd, minLevel });
    if (!match) return { ok: false, reason: `"${ref}" — no heading matching "${seg}" found`, segment: seg };

    const range = sectionRange(file.headings, match, file.content.length);
    scopeStart = range.start;
    scopeEnd = range.end;
    minLevel = match.level;
  }

  return {
    ok: true,
    heading: match,
    start: scopeStart,
    end: scopeEnd,
    section: file.content.slice(scopeStart, scopeEnd),
  };
}

// --- File loading ---
// Reference prefixes name a file under the given base directory: `CONTRACT` ->
// CONTRACT.md, `specs/auth` -> specs/auth.md, `notes/TASK-029` ->
// notes/TASK-029.md. Returns a cached loader; missing files resolve to null.

function createLoader(baseDir) {
  const cache = new Map();
  return function loadFile(relPath) {
    if (cache.has(relPath)) return cache.get(relPath);
    const full = path.join(baseDir, relPath);
    let data = null;
    if (fs.existsSync(full)) {
      const content = fs.readFileSync(full, 'utf8').replace(/\r\n/g, '\n');
      data = { content, headings: parseHeadings(content) };
    }
    cache.set(relPath, data);
    return data;
  };
}

// --- Full reference resolution ---
// "PREFIX#segment/segment" -> resolved section. `loadFile` maps a relative path
// to { content, headings } or null. `displayBase` is cosmetic only: it prefixes
// the file path in error text so messages name the path a human would type.

function resolveRef(ref, loadFile, opts = {}) {
  const displayBase = opts.displayBase || '';
  const hashIdx = ref.indexOf('#');
  if (hashIdx === -1) return { ok: false, reason: `"${ref}" is malformed (missing #)` };
  const prefix = ref.slice(0, hashIdx).trim();
  const refPath = ref.slice(hashIdx + 1).trim();
  if (!prefix || !refPath) return { ok: false, reason: `"${ref}" is malformed` };

  const shown = `${displayBase}${prefix}.md`;
  const file = loadFile(`${prefix}.md`);
  if (!file) return { ok: false, reason: `"${ref}" — source file ${shown} not found` };

  const segments = refPath.split('/').map(s => s.trim()).filter(Boolean);
  const result = resolveSegments(file, segments, ref);
  if (!result.ok) return { ok: false, reason: `${result.reason} in ${shown}` };
  return Object.assign({ file: prefix }, result);
}

// --- Table parsing (CONTRACT#data-model/markdown-table-parsing) ---
// The one table parser: header-keyed, escape-aware, and loud about malformed
// rows. No caller re-implements table splitting — a format with two parsers
// has two behaviors, and a positional reader on a row with the wrong cell
// count silently reads a value out of the middle of some other cell.

// Split one table row into cells. A bare `|` terminates a cell; `\|` is a
// literal pipe; a pipe inside a backtick span is content, not a separator.
function splitTableRow(line) {
  const trimmed = line.trim();
  const cells = [];
  let cur = '';
  let inBacktick = false;
  // strip exactly one leading pipe; the trailing one falls out naturally
  let i = trimmed.startsWith('|') ? 1 : 0;
  for (; i < trimmed.length; i++) {
    const c = trimmed[i];
    if (c === '\\' && trimmed[i + 1] === '|') { cur += '|'; i++; continue; }
    if (c === '`') { inBacktick = !inBacktick; cur += c; continue; }
    if (c === '|' && !inBacktick) { cells.push(cur.trim()); cur = ''; continue; }
    cur += c;
  }
  // content after the last pipe (normally empty for a well-formed row)
  if (cur.trim() !== '') cells.push(cur.trim());
  return cells;
}

function isSeparatorRow(cells) {
  return cells.length > 0 && cells.every(c => /^:?-{2,}:?$/.test(c.replace(/\s/g, '')));
}

// Parse the first markdown table found in `text`. Returns:
//   { ok, columns, rows: [{ lineNumber, cells: {colName: value} }], errors: [{ lineNumber, line, reason }] }
// A row whose cell count differs from the header's is an ERROR, never a
// skipped row — a dropped row is indistinguishable from an absent one, and at
// foundation severity that silently disables the pipeline's one hard stop.
function parseTable(text) {
  const lines = text.split('\n');
  let columns = null;
  const rows = [];
  const errors = [];
  let inFence = false;
  for (let n = 0; n < lines.length; n++) {
    const line = lines[n];
    if (/^\s*(```|~~~)/.test(line)) { inFence = !inFence; continue; }
    if (inFence) continue;
    if (!line.trim().startsWith('|')) {
      if (columns && line.trim() === '') break; // table ended
      continue;
    }
    const cells = splitTableRow(line);
    if (!columns) { columns = cells; continue; }
    if (isSeparatorRow(cells)) continue;
    if (cells.length !== columns.length) {
      errors.push({
        lineNumber: n + 1,
        line,
        reason: `row has ${cells.length} cells, header has ${columns.length} — an unescaped | inside a cell? (escape it as \\|)`,
      });
      continue;
    }
    const rec = {};
    columns.forEach((col, idx) => { rec[col] = cells[idx]; });
    rows.push({ lineNumber: n + 1, cells: rec });
  }
  if (!columns) {
    return { ok: false, columns: [], rows: [], errors: [{ lineNumber: 0, line: '', reason: 'no table found' }] };
  }
  return { ok: errors.length === 0, columns, rows, errors };
}

// Locate the project root: the nearest ancestor of startDir (default: the
// shell's working directory) that contains a .forge directory — the same
// walk-up git performs for .git. Falls back to the installation root (three
// levels above lib/) when no ancestor qualifies, so an absolute-path
// invocation from outside any project still finds the project the script is
// installed in. Entry scripts anchor on this instead of bare process.cwd(),
// which only worked from the repo root (TASK-072).
function findRoot(startDir) {
  let dir = path.resolve(startDir || process.cwd());
  for (;;) {
    if (fs.existsSync(path.join(dir, '.forge'))) return dir;
    const parent = path.dirname(dir);
    if (parent === dir) break;
    dir = parent;
  }
  return path.resolve(__dirname, '..', '..', '..');
}

module.exports = {
  normalizeSlug,
  headingCompact,
  parseHeadings,
  sectionRange,
  findHeading,
  resolveSegments,
  createLoader,
  resolveRef,
  findRoot,
  splitTableRow,
  parseTable,
};
```

If it exists, skip — do not overwrite.

If `.forge/scripts/lib/workplan.js` does **not** exist, create it with:

<!-- forge-init:embed .forge/scripts/lib/workplan.js -->

```javascript
// workplan.js — shared WORKPLAN.md parsing, selection, and mutation
// (CONTRACT#rules/workplan-access-discipline, CONTRACT#state-machines/task-lifecycle)
//
// One parser for the workplan format. check-workplan.js owns validation and
// wp.js owns projection and mutation, but both read the file through here — a
// second, divergent workplan parser is exactly the failure that pushing shared
// markdown resolution into lib/markdown.js was meant to end.
//
// The parser is line-based rather than regex-over-the-whole-file because the
// mutation side needs line ranges: `set` must rewrite one field in place and
// leave every other byte of the file untouched. WORKPLAN.md stays plain,
// hand-editable markdown (Rules/Workplan Access Discipline, Format boundary) —
// this module accelerates access to that format, it does not become it.
//
// Exports: VALID_STATUSES, VALID_TYPES, VALID_TRANSITIONS, FIELD_NAMES,
//          parseWorkplan, readWorkplan, dependsList, contextList, stripBackticks,
//          unmetDeps, selectTask, setField, appendNotes

'use strict';

const fs = require('fs');
const path = require('path');

const VALID_STATUSES = ['pending', 'active', 'done', 'blocked'];
const VALID_TYPES = ['scaffold', 'feature', 'clarify', 'refactor', 'fix', 'investigate', 'ux-spec', 'checkpoint'];

// CONTRACT#state-machines/task-lifecycle. Enforced on mutation so the script
// cannot walk the workplan into a state the state machine forbids; `--force`
// exists for the human who is deliberately rewriting history.
const VALID_TRANSITIONS = {
  pending: ['active'],
  active: ['done', 'blocked'],
  blocked: ['pending'],
  done: [],
};

// Canonical casing for the six fields, keyed by lowercase name.
const FIELD_NAMES = {
  status: 'Status',
  type: 'Type',
  depends: 'Depends',
  context: 'Context',
  gate: 'Gate',
  notes: 'Notes',
};

const HEADER_RE = /^## \[(TASK-\d+)\]\s*(.*)$/;
const FIELD_RE = /^- \*\*([A-Za-z][A-Za-z ]*):\*\*[ \t]?(.*)$/;

function stripBackticks(s) {
  if (!s) return s;
  const m = /^`([\s\S]*)`$/.exec(s.trim());
  return m ? m[1] : s;
}

// --- Parsing ---
// Returns { content, lines, tasks, taskById }. Each task carries its parsed
// field values plus a `fields` map of { name, firstLine, lastLine, valueLines }
// so mutations can target exact line ranges.

function parseWorkplan(rawContent) {
  const content = rawContent.replace(/\r\n/g, '\n');
  const lines = content.split('\n');
  const tasks = [];

  let cur = null;
  let curField = null;
  let inFence = false;

  for (let i = 0; i < lines.length; i++) {
    const line = lines[i];

    if (/^\s*```/.test(line)) {
      inFence = !inFence;
    } else if (!inFence) {
      const h = HEADER_RE.exec(line);
      if (h) {
        if (cur) cur.endLine = i;
        cur = {
          id: h[1],
          description: h[2].trim(),
          order: tasks.length,
          headerLine: i,
          endLine: lines.length,
          fields: new Map(),
        };
        tasks.push(cur);
        curField = null;
        continue;
      }
      if (cur) {
        const f = FIELD_RE.exec(line);
        if (f) {
          curField = {
            name: f[1].trim(),
            firstLine: i,
            lastLine: i,
            valueLines: [f[2]],
          };
          cur.fields.set(curField.name.toLowerCase(), curField);
          continue;
        }
      }
    }

    // Anything else inside a task body continues the field above it. A field's
    // value is therefore multi-line by default, which is what Notes needs.
    if (cur && curField) {
      curField.lastLine = i;
      curField.valueLines.push(line);
    }
  }

  // Trailing blank lines belong to the document's spacing, not to the field.
  for (const t of tasks) {
    for (const f of t.fields.values()) {
      while (f.valueLines.length > 1 && f.valueLines[f.valueLines.length - 1].trim() === '') {
        f.valueLines.pop();
        f.lastLine--;
      }
    }
    t.status = firstLineOf(t, 'status');
    t.type = firstLineOf(t, 'type');
    t.depends = firstLineOf(t, 'depends');
    t.contextRaw = firstLineOf(t, 'context');
    t.gate = stripBackticks(firstLineOf(t, 'gate'));
    t.notes = fullValueOf(t, 'notes');
  }

  return { content, lines, tasks, taskById: new Map(tasks.map(t => [t.id, t])) };
}

function firstLineOf(task, name) {
  const f = task.fields.get(name);
  return f ? f.valueLines[0].trim() : null;
}

// Continuation lines carry two spaces of markdown indentation; strip one level
// so callers see the value a human meant to write, not its list indentation.
function fullValueOf(task, name) {
  const f = task.fields.get(name);
  if (!f) return null;
  const out = [f.valueLines[0].trim()];
  for (const l of f.valueLines.slice(1)) out.push(l.replace(/^ {1,2}/, ''));
  return out.join('\n').replace(/\s+$/, '');
}

function readWorkplan(rootDir) {
  const workplanPath = path.join(rootDir, '.forge', 'WORKPLAN.md');
  if (!fs.existsSync(workplanPath)) return null;
  const wp = parseWorkplan(fs.readFileSync(workplanPath, 'utf8'));
  wp.path = workplanPath;
  return wp;
}

// --- Graph helpers ---

function dependsList(task) {
  if (!task || !task.depends || task.depends === 'none') return [];
  return task.depends.split(',').map(s => s.trim()).filter(Boolean);
}

function contextList(task) {
  if (!task || !task.contextRaw || task.contextRaw.toLowerCase() === 'none') return [];
  return task.contextRaw.split(',').map(s => s.trim()).filter(Boolean);
}

function unmetDeps(task, taskById) {
  return dependsList(task).filter(id => {
    const dep = taskById.get(id);
    return !dep || dep.status !== 'done';
  });
}

// --- Selection ---
// The whole of CONTRACT#interfaces/command-forge-next "Task selection", in one
// deterministic place. Returns { ok, task, selection, warnings } or
// { ok: false, code, error }: code 1 = usage error (no such task), code 2 =
// nothing to select (active-task conflict, or no unblocked pending task).

function selectTask(wp, requestedId) {
  const { tasks, taskById } = wp;
  const activeTasks = tasks.filter(t => t.status === 'active');

  if (activeTasks.length > 1) {
    return {
      ok: false,
      code: 2,
      error: `Multiple active tasks found: ${activeTasks.map(t => t.id).join(', ')}. At most one task may be active — resolve this in WORKPLAN.md before continuing.`,
    };
  }
  const active = activeTasks[0] || null;

  if (requestedId) {
    const task = taskById.get(requestedId);
    if (!task) {
      return { ok: false, code: 1, error: `${requestedId} not found in WORKPLAN.md.` };
    }
    // Naming the active task is a resume, not a conflict.
    if (task.status === 'active') {
      return { ok: true, task, selection: 'resume-active', warnings: [] };
    }
    if (active) {
      return {
        ok: false,
        code: 2,
        error: `${active.id} is currently active. Only one task can be active at a time. Complete or block it before starting a new task.`,
      };
    }

    const warnings = [];
    if (task.status === 'done') {
      warnings.push(`${task.id} is already done — re-running it will redo completed work.`);
    }
    if (task.status === 'blocked') {
      warnings.push(`${task.id} is blocked. Confirm the blocker is resolved before proceeding.`);
    }
    const unmet = unmetDeps(task, taskById);
    if (unmet.length) {
      const detail = unmet
        .map(id => `${id} (${taskById.has(id) ? taskById.get(id).status : 'missing'})`)
        .join(', ');
      warnings.push(`${task.id} has unmet dependencies: ${detail}. Ask the human to confirm before proceeding.`);
    }
    return { ok: true, task, selection: 'explicit', warnings };
  }

  if (active) {
    return { ok: true, task: active, selection: 'resume-active', warnings: [] };
  }

  const next = tasks.find(t => t.status === 'pending' && unmetDeps(t, taskById).length === 0);
  if (!next) {
    return {
      ok: false,
      code: 2,
      error: 'No unblocked tasks available. Run /forge-status to see what is blocked.',
    };
  }
  return { ok: true, task: next, selection: 'next-unblocked', warnings: [] };
}

// --- Mutation ---
// Both mutators return { ok, content } — new file content — or { ok: false,
// error }. They never write; the caller decides, so it can lint before
// committing the change to disk.

function renderField(name, value) {
  const canonical = FIELD_NAMES[name.toLowerCase()] || name;
  const valueLines = String(value).split('\n');
  const head = `- **${canonical}:** ${valueLines[0]}`.replace(/\s+$/, '');
  const rest = valueLines.slice(1).map(l => (l.trim() === '' ? '' : `  ${l.replace(/^\s+/, '')}`));
  return [head, ...rest];
}

function setField(wp, taskId, fieldName, value) {
  const task = wp.taskById.get(taskId);
  if (!task) return { ok: false, error: `${taskId} not found in WORKPLAN.md.` };

  const key = fieldName.toLowerCase();
  if (!FIELD_NAMES[key]) {
    return { ok: false, error: `Unknown field "${fieldName}". Expected one of: ${Object.values(FIELD_NAMES).join(', ')}.` };
  }
  const field = task.fields.get(key);
  if (!field) {
    return { ok: false, error: `${taskId} has no ${FIELD_NAMES[key]} field to set.` };
  }

  const lines = wp.lines.slice();
  lines.splice(field.firstLine, field.lastLine - field.firstLine + 1, ...renderField(key, value));
  return { ok: true, content: lines.join('\n') };
}

function appendNotes(wp, taskId, text) {
  const task = wp.taskById.get(taskId);
  if (!task) return { ok: false, error: `${taskId} not found in WORKPLAN.md.` };
  if (!task.fields.has('notes')) return { ok: false, error: `${taskId} has no Notes field to append to.` };

  const existing = (task.notes || '').replace(/\s+$/, '');
  const addition = String(text).replace(/\s+$/, '');
  const merged = existing === '' ? addition : `${existing}\n${addition}`;
  return setField(wp, taskId, 'notes', merged);
}

module.exports = {
  VALID_STATUSES,
  VALID_TYPES,
  VALID_TRANSITIONS,
  FIELD_NAMES,
  parseWorkplan,
  readWorkplan,
  dependsList,
  contextList,
  stripBackticks,
  unmetDeps,
  selectTask,
  setField,
  appendNotes,
};
```

If it exists, skip — do not overwrite.

If `.forge/scripts/check-workplan.js` does **not** exist, create it with:

<!-- forge-init:embed .forge/scripts/check-workplan.js -->

```javascript
#!/usr/bin/env node
// check-workplan.js — validate .forge/WORKPLAN.md invariants (CONTRACT#rules/workplan-lint)
// Usage: node .forge/scripts/check-workplan.js
// Exit 0 = no errors (warnings may still print). Exit 1 = at least one error.
//
// Severity policy: violations of invariants 2 (file-order) and 3 (cycles) that
// are confined entirely to `done` tasks are warnings, not errors — done tasks
// are frozen history (Rules/Task Ordering). The same is extended here to
// invariants 6/7 (gate quality) for consistency: a `done` or `blocked` task's
// gate is already shipped; a `pending`/`active` task's gate is still correctable.
// Invariants 1, 4, and 5 (structural integrity) have no status exemption.

const fs = require('fs');
const path = require('path');
const { createLoader, resolveRef, findRoot } = require('./lib/markdown');
const {
  VALID_STATUSES,
  VALID_TYPES,
  parseWorkplan,
  dependsList,
} = require('./lib/workplan');

// Nearest ancestor of the working directory holding .forge/, falling back to
// the installed location — works from a subdirectory and by absolute path
// (TASK-072).
const ROOT = findRoot();
const workplanPath = path.join(ROOT, '.forge', 'WORKPLAN.md');

if (!fs.existsSync(workplanPath)) {
  console.error('Error: .forge/WORKPLAN.md not found');
  process.exit(1);
}

const content = fs.readFileSync(workplanPath, 'utf8').replace(/\r\n/g, '\n');

const CODE_EXTENSIONS = ['js', 'ts', 'jsx', 'tsx', 'py', 'rb', 'go', 'java', 'c', 'cpp', 'cs', 'php', 'rs'];

const errors = [];
const warnings = [];

// --- Parse tasks ---
// Parsing lives in lib/workplan.js, shared with wp.js. This script owns the
// invariants, not the format: two parsers for one file is how a linter starts
// disagreeing with the tool that writes the file it lints.

const { tasks, taskById } = parseWorkplan(content);

if (tasks.length === 0) {
  console.error('Error: no tasks found in WORKPLAN.md');
  process.exit(1);
}

// --- Invariant 1: every task has all required fields with valid values ---

for (const t of tasks) {
  if (!t.status) errors.push(`${t.id}: missing required field Status`);
  else if (!VALID_STATUSES.includes(t.status)) errors.push(`${t.id}: invalid Status "${t.status}" (expected one of ${VALID_STATUSES.join(', ')})`);

  if (!t.type) errors.push(`${t.id}: missing required field Type`);
  else if (!VALID_TYPES.includes(t.type)) errors.push(`${t.id}: invalid Type "${t.type}" (expected one of ${VALID_TYPES.join(', ')})`);

  if (!t.depends) errors.push(`${t.id}: missing required field Depends`);
  else if (t.depends !== 'none' && !t.depends.split(',').every(d => /^TASK-\d+$/.test(d.trim()))) {
    errors.push(`${t.id}: Depends must be "none" or a comma-separated list of TASK-IDs, got "${t.depends}"`);
  }

  if (t.contextRaw === null) errors.push(`${t.id}: missing required field Context`);

  if (!t.gate) errors.push(`${t.id}: missing required field Gate`);
}

// --- Invariant 2: unique IDs; Depends references an existing task; for
//     pending/active tasks each Depends entry must appear earlier in the file
//     (the same violation in a done task is a warning, not an error) ---

const idCounts = new Map();
for (const t of tasks) idCounts.set(t.id, (idCounts.get(t.id) || 0) + 1);
for (const [id, count] of idCounts) {
  if (count > 1) errors.push(`Duplicate task ID: ${id} appears ${count} times`);
}

for (const t of tasks) {
  for (const depId of dependsList(t)) {
    const depTask = taskById.get(depId);
    if (!depTask) {
      errors.push(`${t.id}: Depends references nonexistent task ${depId}`);
      continue;
    }
    if (depTask.order >= t.order) {
      const msg = `${t.id}: Depends entry ${depId} does not appear earlier in the file (Rules/Task Ordering)`;
      if (t.status === 'pending' || t.status === 'active') errors.push(msg);
      else warnings.push(`${msg} [warning: ${t.status} task, frozen history]`);
    }
  }
}

// --- Invariant 3: no dependency cycles, checked across the whole graph.
//     A cycle confined entirely to done tasks is a warning (frozen history);
//     any cycle touching a non-done task is an error. Not subsumed by
//     invariant 2, whose file-order check is scoped to pending/active only. ---

function findSCCs(nodeIds, edgesOf) {
  let counter = 0;
  const indices = new Map();
  const lowlink = new Map();
  const onStack = new Set();
  const stack = [];
  const sccs = [];

  function strongconnect(v) {
    indices.set(v, counter);
    lowlink.set(v, counter);
    counter++;
    stack.push(v);
    onStack.add(v);

    for (const w of edgesOf(v)) {
      if (!indices.has(w)) {
        strongconnect(w);
        lowlink.set(v, Math.min(lowlink.get(v), lowlink.get(w)));
      } else if (onStack.has(w)) {
        lowlink.set(v, Math.min(lowlink.get(v), indices.get(w)));
      }
    }

    if (lowlink.get(v) === indices.get(v)) {
      const scc = [];
      let w;
      do {
        w = stack.pop();
        onStack.delete(w);
        scc.push(w);
      } while (w !== v);
      sccs.push(scc);
    }
  }

  for (const v of nodeIds) {
    if (!indices.has(v)) strongconnect(v);
  }
  return sccs;
}

const allIds = tasks.map(t => t.id);
const edgesOf = (id) => dependsList(taskById.get(id)).filter(d => taskById.has(d));
const sccs = findSCCs(allIds, edgesOf);

for (const scc of sccs) {
  const isCycle = scc.length > 1 || edgesOf(scc[0]).includes(scc[0]);
  if (!isCycle) continue;
  const allDone = scc.every(id => taskById.get(id).status === 'done');
  const msg = `Dependency cycle detected: ${scc.join(' -> ')}`;
  if (allDone) warnings.push(`${msg} [warning: cycle confined to done tasks, frozen history]`);
  else errors.push(msg);
}

// --- Invariant 4: at most one task has status active ---

const activeTasks = tasks.filter(t => t.status === 'active');
if (activeTasks.length > 1) {
  errors.push(`Multiple active tasks found: ${activeTasks.map(t => t.id).join(', ')} (at most one task may be active)`);
}

// --- Invariant 5: every Context reference resolves to an existing heading ---
// Same resolution rules as CONTRACT#data-model/context-manifest: the prefix
// before "#" names a file under .forge/ (CONTRACT, UX, DESIGN, SPEC, or a
// specs/name / other multi-file contract); segments after "#" navigate nested
// headings. The resolution itself lives in lib/markdown.js, shared with the
// other gate scripts.

const loadFile = createLoader(path.join(ROOT, '.forge'));

for (const t of tasks) {
  if (!t.contextRaw || t.contextRaw.toLowerCase() === 'none') continue;
  const refs = t.contextRaw.split(',').map(s => s.trim()).filter(Boolean);
  for (const ref of refs) {
    const result = resolveRef(ref, loadFile, { displayBase: '.forge/' });
    if (!result.ok) errors.push(`${t.id}: Context reference ${result.reason}`);
  }
}

// --- Invariant 6: feature/fix gates invoke a test command, not solely
//     structural checks (grep, ls, test -f). Exempt: gates whose only file
//     targets are non-code artifacts (e.g. markdown command/template files) —
//     CONTRACT#rules/gate-patterns designates structural checks as the correct
//     strategy for markdown artifacts, so those gates were never meant to run
//     a test suite in the first place. ---

function hasTestInvocation(gate) {
  return /\btests?\//i.test(gate) ||
    /\bnpm\s+(run\s+)?test\b/i.test(gate) ||
    /\byarn\s+test\b/i.test(gate) ||
    /\bpytest\b/i.test(gate) ||
    /\bjest\b/i.test(gate) ||
    /\bmocha\b/i.test(gate) ||
    /\bgo\s+test\b/i.test(gate) ||
    /\bcargo\s+test\b/i.test(gate) ||
    /\btest-[\w-]+\.sh\b/i.test(gate);
}

function referencesCodeFile(gate) {
  const words = gate.split(/\s+/);
  for (const w of words) {
    const clean = w.replace(/^["'`]+|["'`]+$/g, '').replace(/[,;)]+$/, '');
    const extMatch = /\.([A-Za-z0-9]+)$/.exec(clean);
    if (extMatch && CODE_EXTENSIONS.includes(extMatch[1].toLowerCase())) return true;
  }
  return false;
}

for (const t of tasks) {
  if (!t.gate || t.gate.startsWith('manual:')) continue;
  if (t.type !== 'feature' && t.type !== 'fix') continue;
  if (!hasTestInvocation(t.gate) && referencesCodeFile(t.gate)) {
    const msg = `${t.id}: ${t.type} gate does not invoke a test command (structural checks only) — \`${t.gate}\``;
    if (t.status === 'pending' || t.status === 'active') errors.push(msg);
    else warnings.push(`${msg} [warning: ${t.status} task, frozen history]`);
  }
}

// --- Invariant 7: checkpoint and investigate gates use the manual: prefix ---

for (const t of tasks) {
  if (!t.gate) continue;
  if (t.type !== 'checkpoint' && t.type !== 'investigate') continue;
  if (!t.gate.trim().startsWith('manual:')) {
    const msg = `${t.id}: ${t.type} gate must use the "manual:" prefix — \`${t.gate}\``;
    if (t.status === 'pending' || t.status === 'active') errors.push(msg);
    else warnings.push(`${msg} [warning: ${t.status} task, frozen history]`);
  }
}

// --- Report ---

if (warnings.length > 0) {
  console.log(`${warnings.length} warning(s):`);
  warnings.forEach(w => console.log(`  - ${w}`));
}

if (errors.length > 0) {
  console.error(`${errors.length} error(s):`);
  errors.forEach(e => console.error(`  - ${e}`));
  console.error('\nWorkplan validation FAILED.');
  process.exit(1);
}

console.log(`\nWorkplan validation passed (${tasks.length} tasks, ${warnings.length} warning(s)).`);
process.exit(0);
```

If it exists, skip — do not overwrite.

If `.forge/scripts/wp.js` does **not** exist, create it with:

<!-- forge-init:embed .forge/scripts/wp.js -->

```javascript
#!/usr/bin/env node
// wp.js — deterministic WORKPLAN.md projection and mutation
// (CONTRACT#rules/workplan-access-discipline)
//
// Usage:
//   node .forge/scripts/wp.js next [TASK-XXX] [--json]
//   node .forge/scripts/wp.js get TASK-XXX [--json]
//   node .forge/scripts/wp.js status [--json]
//   node .forge/scripts/wp.js set TASK-XXX <field> <value> [--force]
//   node .forge/scripts/wp.js append-notes TASK-XXX <text>
//
// Why this exists: task selection is entirely deterministic — unblocked-ness,
// dependency satisfaction, active-task resume, explicit-ID override — so it
// belongs in a script rather than in an agent's context window (Vision pillar
// 2). `/forge-next` and `/forge-status` call this instead of reading
// WORKPLAN.md in full; a 2,000-line workplan then never enters context, and the
// per-session cost drops to the selected task alone.
//
// Format boundary: WORKPLAN.md stays plain, hand-editable markdown. Every
// mutation here rewrites exactly the field lines it targets, leaves the rest of
// the file byte-identical, and is re-linted with check-workplan.js before it is
// allowed to stand — a mutation that fails the lint is reverted, not left on
// disk.
//
// Exit codes (CONTRACT#interfaces/script-exit-codes): 0 success · 1 usage or
// validation error · 2 nothing to select · 3 foundation-observation halt · 4
// gate-discrimination probe refusal.

'use strict';

const fs = require('fs');
const path = require('path');
const { spawnSync } = require('child_process');

const {
  VALID_STATUSES,
  VALID_TYPES,
  VALID_TRANSITIONS,
  FIELD_NAMES,
  readWorkplan,
  dependsList,
  contextList,
  unmetDeps,
  selectTask,
  setField,
  appendNotes,
} = require('./lib/workplan');
const { createLoader, resolveRef, findRoot, parseTable } = require('./lib/markdown');

// Nearest ancestor of the working directory holding .forge/, falling back to
// the installed location — works from a subdirectory and by absolute path
// (TASK-072).
const ROOT = findRoot();

const USAGE = `usage: node .forge/scripts/wp.js <command>

  next [TASK-XXX] [--force] [--json]
                               select the task to execute and emit its fields;
                               exits 2 when there is nothing to select, and
                               halts (exit 3) while an open foundation-severity
                               observation exists, unless --force
  get TASK-XXX [--json]        emit one task's fields
  status [--json]              counts, next unblocked task, clarify tasks, open observations
  set TASK-XXX <field> <value> [--force]
                               set Status, Type, Depends, Context, Gate, or Notes;
                               pending -> active runs the task's gate first and
                               refuses (exit 4) a gate that already passes
                               pre-work (CONTRACT#rules/gate-discrimination)
  append-notes TASK-XXX <text> append a line to a task's Notes field

Exit codes follow CONTRACT#interfaces/script-exit-codes: 0 success, 1 usage or
validation error, 2 nothing to select, 3 foundation-observation halt, 4
gate-discrimination probe refusal.`;

function die(message, code) {
  console.error(`wp.js: ${message}`);
  process.exit(code === undefined ? 1 : code);
}

// Locate the bash that gates actually run under (OBS-019, TASK-098). On win32
// a bare spawnSync('bash') resolves through CreateProcess, which searches
// System32 ahead of PATH-shell order and finds WSL's relay from any non-bash
// parent — the relay exits 1, and the probe would silently read every gate as
// "fails pre-work", never refusing. FORGE_BASH overrides; the Git-for-Windows
// install locations come next; PATH `bash` is the non-win32 answer and the
// last resort. A wrong-but-loud result stays loud via the existing
// probe.error path.
function resolveBash() {
  if (process.env.FORGE_BASH) return process.env.FORGE_BASH;
  if (process.platform === 'win32') {
    const candidates = [
      'C:\\Program Files\\Git\\usr\\bin\\bash.exe',
      'C:\\Program Files\\Git\\bin\\bash.exe',
      'C:\\Program Files (x86)\\Git\\usr\\bin\\bash.exe',
    ];
    for (const c of candidates) {
      if (fs.existsSync(c)) return c;
    }
  }
  return 'bash';
}

function loadWorkplan() {
  const wp = readWorkplan(ROOT);
  if (!wp) die('.forge/WORKPLAN.md not found. Run /forge-plan to generate one.');
  if (wp.tasks.length === 0) die('no tasks found in .forge/WORKPLAN.md. Run /forge-plan to generate one.');
  return wp;
}

// --- Rendering ---

function taskJson(task) {
  return {
    id: task.id,
    description: task.description,
    status: task.status,
    type: task.type,
    depends: dependsList(task),
    context: contextList(task),
    gate: task.gate,
    notes: task.notes || '',
  };
}

// Notes come last and are printed verbatim, so a multi-line value needs no
// escaping and the reader never has to guess where the field ends.
function printTask(task, selection, warnings) {
  console.log(`Task: ${task.id} — ${task.description}`);
  if (selection) console.log(`Selection: ${selection}`);
  console.log(`Status: ${task.status}`);
  console.log(`Type: ${task.type}`);
  console.log(`Depends: ${task.depends}`);
  console.log(`Context: ${task.contextRaw}`);
  console.log(`Gate: ${task.gate}`);
  for (const w of warnings || []) console.log(`Warning: ${w}`);
  console.log('Notes:');
  console.log(task.notes && task.notes.trim() ? task.notes : '(none)');
}

// --- STATUS.md observations ---
// Reads the Observations table (CONTRACT#data-model/status-md-data-model) and
// returns open rows, foundation severity first. Missing file or missing section
// is normal, not an error — STATUS.md is optional.

function readObservations() {
  const loadFile = createLoader(path.join(ROOT, '.forge'));
  const result = resolveRef('STATUS#observations', loadFile);
  if (!result.ok) return [];

  // Header-keyed, never positional (CONTRACT#data-model/markdown-table-parsing):
  // the Date column landed after this reader existed, and a positional read
  // would have silently shifted every cell — reading Kind as Severity and
  // never matching 'open', which disarms the foundation halt while every
  // report shows a clear queue. Keying by column name also keeps the six-column
  // fixtures in test-wp.sh valid: they simply have no Date cell.
  const t = parseTable(result.section);
  if (!t.ok) {
    // Fail closed. A malformed row may BE the open foundation row; proceeding
    // as if the queue were clear is the exact failure the lint exists to stop.
    const detail = t.errors.map(e => `  ${e.reason}`).join('\n');
    die(`STATUS.md Observations table is malformed — a dropped row could hide a foundation halt.\n${detail}\nFix the table (node .forge/scripts/check-status.js shows every problem) and retry.`);
  }

  const rows = [];
  for (const r of t.rows) {
    const c = r.cells;
    const disposition = (c['Disposition'] || '');
    if (disposition.toLowerCase() !== 'open') continue;
    rows.push({
      id: c['ID'] || '',
      date: c['Date'] || '',
      raisedBy: c['Raised by'] || '',
      kind: c['Kind'] || '',
      severity: (c['Severity'] || '').toLowerCase(),
      observation: c['Observation'] || '',
      disposition,
    });
  }

  // foundation first — the severity that means "stop and reconsider" must not
  // be buried under routine friction rows.
  return rows.sort((a, b) => {
    const rank = s => (s === 'foundation' ? 0 : 1);
    return rank(a.severity) - rank(b.severity);
  });
}

// --- Commands ---

function cmdNext(args, json) {
  const force = args.includes('--force');
  const rest = args.filter(a => a !== '--force');
  const requestedId = rest.find(a => /^TASK-\d+$/i.test(a));
  if (rest.some(a => !/^TASK-\d+$/i.test(a))) {
    die(`unexpected argument for next: ${rest.find(a => !/^TASK-\d+$/i.test(a))}`);
  }
  const wp = loadWorkplan();
  const result = selectTask(wp, requestedId ? requestedId.toUpperCase() : null);

  if (!result.ok) {
    if (json) {
      console.log(JSON.stringify({ ok: false, error: result.error }, null, 2));
      process.exit(result.code);
    }
    die(result.error, result.code);
  }

  // CONTRACT#rules/unattended-execution rule 4: an open foundation-severity
  // observation halts the loop, mechanically rather than advisorily. This is
  // the one hard stop an agent must trigger against its own momentum, so it
  // cannot rest on the agent reading its own warning.
  //
  // Resume is exempt on purpose — the contract has the current task finish
  // cleanly first, so refusal covers new work only. The designed exit is the
  // human triaging the row off `open`; --force is the deliberate override, and
  // agents do not pass it.
  if (result.selection !== 'resume-active' && !force) {
    const blocking = readObservations().filter(o => o.severity === 'foundation');
    if (blocking.length) {
      const rows = blocking.map(o => `  - ${o.id} (${o.raisedBy}, ${o.kind}) — ${o.observation}`).join('\n');
      const message =
        `halted: ${blocking.length} open foundation-severity observation${blocking.length > 1 ? 's' : ''} ` +
        `(CONTRACT#rules/unattended-execution, hard stop 4).\n${rows}\n` +
        'The spec, contract, or approach is suspect and continuing to build compounds debt. ' +
        'A human triages these — set the Disposition to accepted or declined in STATUS.md — ' +
        'or re-runs with --force to continue anyway.';
      if (json) {
        console.log(JSON.stringify({ ok: false, error: message, halted: 'foundation-observation', observations: blocking }, null, 2));
        process.exit(3);
      }
      die(message, 3);
    }
  }

  if (json) {
    console.log(JSON.stringify({
      ok: true,
      selection: result.selection,
      warnings: result.warnings,
      task: taskJson(result.task),
    }, null, 2));
  } else {
    printTask(result.task, result.selection, result.warnings);
  }
}

function cmdGet(args, json) {
  const id = args[0];
  if (!id) die('get requires a task ID.\n\n' + USAGE);
  const wp = loadWorkplan();
  const task = wp.taskById.get(id.toUpperCase());
  if (!task) die(`${id} not found in WORKPLAN.md.`);

  if (json) console.log(JSON.stringify({ ok: true, task: taskJson(task) }, null, 2));
  else printTask(task, null, []);
}

function cmdStatus(args, json) {
  const wp = loadWorkplan();
  const { tasks, taskById } = wp;

  const counts = {};
  for (const s of VALID_STATUSES) counts[s] = 0;
  for (const t of tasks) if (counts[t.status] !== undefined) counts[t.status]++;

  const active = tasks.find(t => t.status === 'active') || null;
  const next = tasks.find(t => t.status === 'pending' && unmetDeps(t, taskById).length === 0) || null;
  const clarify = tasks.filter(t => t.type === 'clarify' && (t.status === 'pending' || t.status === 'active'));
  const blocked = tasks.filter(t => t.status === 'blocked');
  const observations = readObservations();

  const brief = t => ({ id: t.id, description: t.description, status: t.status, type: t.type });

  if (json) {
    console.log(JSON.stringify({
      ok: true,
      total: tasks.length,
      counts,
      active: active ? brief(active) : null,
      next: next ? brief(next) : null,
      clarify: clarify.map(brief),
      blocked: blocked.map(brief),
      observations,
    }, null, 2));
    return;
  }

  console.log(`Tasks: ${tasks.length} total — ${counts.done} done, ${counts.active} active, ${counts.pending} pending, ${counts.blocked} blocked`);
  console.log(`Active: ${active ? `${active.id} — ${active.description}` : 'none'}`);
  console.log(`Next unblocked: ${next ? `${next.id} — ${next.description}` : 'none'}`);

  console.log(clarify.length ? 'Clarify tasks awaiting input:' : 'Clarify tasks awaiting input: none');
  for (const t of clarify) console.log(`  - ${t.id} (${t.status}) — ${t.description}`);

  console.log(blocked.length ? 'Blocked tasks:' : 'Blocked tasks: none');
  for (const t of blocked) console.log(`  - ${t.id} — ${t.description}`);

  console.log(observations.length ? 'Open observations:' : 'Open observations: none');
  for (const o of observations) {
    console.log(`  - [${o.severity}] ${o.id} (${o.raisedBy}) — ${o.observation}`);
  }
}

// Re-lint after every write. check-workplan.js resolves the workplan from the
// working directory, same as this script, so it validates what was just
// written. A failure means the mutation was wrong: put the file back.
function writeAndLint(wp, content, successMessage) {
  const original = fs.readFileSync(wp.path, 'utf8');
  fs.writeFileSync(wp.path, content);

  const lint = spawnSync(process.execPath, [path.join(__dirname, 'check-workplan.js')], {
    cwd: ROOT,
    encoding: 'utf8',
  });

  if (lint.status !== 0) {
    fs.writeFileSync(wp.path, original);
    const detail = `${lint.stdout || ''}${lint.stderr || ''}`.trim();
    die(`mutation rejected — check-workplan.js failed, so WORKPLAN.md was reverted:\n${detail}`);
  }

  console.log(successMessage);
}

function cmdSet(args) {
  const force = args.includes('--force');
  const rest = args.filter(a => a !== '--force');
  const [rawId, rawField, ...valueParts] = rest;
  if (!rawId || !rawField || valueParts.length === 0) die('set requires a task ID, a field, and a value.\n\n' + USAGE);

  const id = rawId.toUpperCase();
  const key = rawField.toLowerCase();
  const value = valueParts.join(' ');

  if (!FIELD_NAMES[key]) {
    die(`unknown field "${rawField}". Expected one of: ${Object.values(FIELD_NAMES).join(', ')}.`);
  }

  const wp = loadWorkplan();
  const task = wp.taskById.get(id);
  if (!task) die(`${id} not found in WORKPLAN.md.`);

  if (key === 'status') {
    if (!VALID_STATUSES.includes(value)) {
      die(`invalid Status "${value}". Expected one of: ${VALID_STATUSES.join(', ')}.`);
    }
    if (value !== task.status) {
      const allowed = VALID_TRANSITIONS[task.status] || [];
      if (!allowed.includes(value) && !force) {
        die(`invalid transition ${task.status} → ${value} for ${id} (CONTRACT#state-machines/task-lifecycle allows: ${allowed.length ? allowed.join(', ') : 'none'}). Use --force to override.`);
      }
    }
    // The one-active-task constraint is enforced on write, not only on read:
    // a script that can create a second active task has dropped the invariant
    // it was supposed to carry over from /forge-next.
    if (value === 'active') {
      const other = wp.tasks.find(t => t.status === 'active' && t.id !== id);
      if (other && !force) {
        die(`${other.id} is currently active. Only one task can be active at a time. Complete or block it first, or use --force.`);
      }

      // Gate-discrimination probe (CONTRACT#rules/gate-discrimination,
      // obligation 2): a gate that already passes against the pre-work tree
      // certifies nothing, so the task must not proceed on it. Probing at the
      // pending -> active transition rather than in /forge-next's prose is the
      // point — a step an agent is merely told to run is a step it may skip,
      // which is how all recorded vacuous-gate instances shipped.
      //
      // manual: gates are exempt (no command to run). Resuming an already-
      // active task performs no transition and never reaches this branch.
      // --force is the human's override, same as `next --force`; agents repair
      // the gate instead, via `set TASK-XXX gate '<discriminating gate>'` on
      // the still-pending task.
      if (task.status === 'pending' && !force && !/^manual:/.test(task.gate || '')) {
        const probe = spawnSync(resolveBash(), ['-c', task.gate], {
          cwd: ROOT,
          encoding: 'utf8',
          timeout: 300000,
        });
        if (probe.error) {
          die(`gate-discrimination probe could not run the gate (${probe.error.message}). ` +
              `Fix the environment or the gate before activating ${id}.`);
        }
        if (probe.status === 0) {
          const output = `${probe.stdout || ''}${probe.stderr || ''}`.trim();
          die(
            `refused: ${id}'s gate already passes against the pre-work tree, so it cannot ` +
            `verify this task's work (CONTRACT#rules/gate-discrimination).\n` +
            `  Gate: ${task.gate}\n` +
            (output ? `  Output:\n${output.split('\n').map(l => `    ${l}`).join('\n')}\n` : '') +
            `Repair the gate to assert this task's change (wp.js set ${id} gate '<discriminating gate>') and retry. ` +
            `If the gate is right and the work already exists, a prior task absorbed this task's scope — ` +
            `report that to the human instead of proceeding. --force is the human's override.`,
            4
          );
        }
      }
    }
  }

  if (key === 'type' && !VALID_TYPES.includes(value)) {
    die(`invalid Type "${value}". Expected one of: ${VALID_TYPES.join(', ')}.`);
  }

  const result = setField(wp, id, key, value);
  if (!result.ok) die(result.error);

  const before = key === 'status' ? task.status : null;
  writeAndLint(wp, result.content,
    before ? `${id} Status: ${before} → ${value}` : `${id} ${FIELD_NAMES[key]} updated.`);
}

function cmdAppendNotes(args) {
  const [rawId, ...textParts] = args;
  if (!rawId || textParts.length === 0) die('append-notes requires a task ID and text.\n\n' + USAGE);

  const id = rawId.toUpperCase();
  const wp = loadWorkplan();
  if (!wp.taskById.has(id)) die(`${id} not found in WORKPLAN.md.`);

  const result = appendNotes(wp, id, textParts.join(' '));
  if (!result.ok) die(result.error);

  writeAndLint(wp, result.content, `${id} Notes: appended.`);
}

// --- Entry point ---

function main(argv) {
  const json = argv.includes('--json');
  const args = argv.filter(a => a !== '--json');
  const command = args[0];
  const rest = args.slice(1);

  switch (command) {
    case 'next': return cmdNext(rest, json);
    case 'get': return cmdGet(rest, json);
    case 'status': return cmdStatus(rest, json);
    case 'set': return cmdSet(rest);
    case 'append-notes': return cmdAppendNotes(rest);
    case undefined: return die(USAGE);
    default: return die(`unknown command "${command}".\n\n${USAGE}`);
  }
}

main(process.argv.slice(2));
```

If it exists, skip — do not overwrite.
If `.forge/scripts/check-spec.js` does **not** exist, create it with:

<!-- forge-init:embed .forge/scripts/check-spec.js -->

```javascript
#!/usr/bin/env node
// check-spec.js — validate a spec file's structural readiness
// Usage: node .forge/scripts/check-spec.js <file> [--max-unresolved N]
// Exit 0 = valid, Exit 1 = invalid (errors printed to stderr)

const fs = require('fs');
const path = require('path');
const { parseHeadings, findHeading, sectionRange, normalizeSlug } = require('./lib/markdown');

const args = process.argv.slice(2);
const fileArg = args.find(a => !a.startsWith('--'));
const maxUnresolvedFlagIdx = args.indexOf('--max-unresolved');
// A malformed value must be a usage error, never a silent default in either
// direction: Number(undefined) is NaN and `count > NaN` is always false, which
// would skip the unresolved-marker check entirely while reading as strictness
// (TASK-076).
let maxUnresolved = 0;
if (maxUnresolvedFlagIdx !== -1) {
  maxUnresolved = Number(args[maxUnresolvedFlagIdx + 1]);
  if (!Number.isFinite(maxUnresolved) || maxUnresolved < 0) {
    console.error('check-spec.js: --max-unresolved requires a non-negative number.');
    process.exit(1);
  }
}

if (!fileArg) {
  console.error('Usage: node .forge/scripts/check-spec.js <file> [--max-unresolved N]');
  process.exit(1);
}

const specPath = path.isAbsolute(fileArg) ? fileArg : path.join(process.cwd(), fileArg);
if (!fs.existsSync(specPath)) {
  console.error(`Error: ${fileArg} not found`);
  process.exit(1);
}

const content = fs.readFileSync(specPath, 'utf8').replace(/\r\n/g, '\n');
const headings = parseHeadings(content);
const errors = [];

// --- Required top-level sections (CONTRACT#data-model/spec-data-model) ---
const requiredSections = ['Overview', 'Requirements', 'Non-Goals'];
for (const name of requiredSections) {
  if (!findHeading(headings, normalizeSlug(name), { level: 2 })) {
    errors.push(`Missing section: ## ${name}`);
  }
}

// --- Requirements: at least one REQ with acceptance criteria, no placeholder/TODO text ---
const requirementsHeading = findHeading(headings, normalizeSlug('Requirements'), { level: 2 });
if (requirementsHeading) {
  const reqSectionRange = sectionRange(headings, requirementsHeading, content.length);
  const reqSection = content.slice(reqSectionRange.start, reqSectionRange.end);
  const reqHeadings = parseHeadings(reqSection).filter(h => h.level === 3);

  if (reqHeadings.length === 0) {
    errors.push('Requirements section has no requirement headings (### [req-slug] Name)');
  }

  let hasAcceptanceCriteria = false;
  for (const h of reqHeadings) {
    const bracketMatch = /^\[([^\]]+)\]/.exec(h.text);
    const label = bracketMatch ? bracketMatch[1] : h.text;

    const range = sectionRange(reqHeadings, h, reqSection.length);
    const nl = reqSection.indexOf('\n', range.start);
    const bodyStart = nl === -1 || nl > range.end ? range.end : nl;
    const body = reqSection.slice(bodyStart, range.end);
    const withoutComments = body.replace(/<!--[\s\S]*?-->/g, '').trim();

    if (!withoutComments) {
      errors.push(`Requirement [${label}] is empty or placeholder-only (no content outside HTML comments)`);
      continue;
    }

    if (/\bTODO\b/i.test(withoutComments) || /\bTBD\b/i.test(withoutComments)) {
      errors.push(`Requirement [${label}] contains placeholder text (TODO/TBD)`);
    }

    const acIdx = withoutComments.search(/acceptance criteria/i);
    if (acIdx !== -1) {
      const afterAc = withoutComments.slice(acIdx);
      const hasBullet = afterAc.split('\n').some(line => {
        const trimmed = line.trim();
        return (trimmed.startsWith('-') || trimmed.startsWith('*')) && trimmed.replace(/^[-*]\s*/, '').length > 0;
      });
      if (hasBullet) hasAcceptanceCriteria = true;
    }
  }

  if (reqHeadings.length > 0 && !hasAcceptanceCriteria) {
    errors.push('No requirement has acceptance criteria (expected an "Acceptance criteria" line followed by a bullet list in at least one requirement)');
  }
}

// --- Unresolved markers above threshold (default: zero blocking) ---
const unresolvedLines = [];
content.split('\n').forEach((line, i) => {
  if (line.includes('<!-- UNRESOLVED')) unresolvedLines.push(i + 1);
});
if (unresolvedLines.length > maxUnresolved) {
  errors.push(
    `${unresolvedLines.length} unresolved marker(s) exceed the allowed threshold of ${maxUnresolved} (lines: ${unresolvedLines.join(', ')})`
  );
}

if (errors.length > 0) {
  console.error(`Spec "${fileArg}" validation failed:\n`);
  errors.forEach(e => console.error(`  - ${e}`));
  process.exit(1);
}

console.log(`Spec "${fileArg}" is valid.`);
process.exit(0);
```

If it exists, skip — do not overwrite.

If `.forge/scripts/prose.js` does **not** exist, create it with:

<!-- forge-init:embed .forge/scripts/prose.js -->

```javascript
#!/usr/bin/env node
// prose.js — grep a markdown file's prose, ignoring fenced code blocks.
//
// Why this exists: gates assert that a command file *instructs* something, but
// several command files now carry large fenced payloads — `/forge-init` embeds
// four scripts verbatim and is 88% fenced by line count. A plain
// `grep -q "Observations" .claude/commands/forge-init.md` matched a comment
// inside the embedded wp.js source and reported the deliverable present when it
// was never built: TASK-031 passed that way while /forge-init created no
// STATUS.md stub at all. A gate that a headless loop can satisfy without doing
// the work is worse than no gate: it marks the task done and moves on.
//
// That example is historical. TASK-031's fix put both "Observations" and
// "STATUS.md" into forge-init.md's prose, so neither is payload-only there
// anymore; `module.exports` is the current stand-in, and is what test-prose.sh
// asserts against the live file (TASK-066).
//
// Usage: node .forge/scripts/prose.js <file> <pattern>...
// Exits 0 only when every pattern (case-insensitive) matches outside fences.

'use strict';

const fs = require('fs');

const [file, ...patterns] = process.argv.slice(2);
if (!file || patterns.length === 0) {
  console.error('usage: node .forge/scripts/prose.js <file> <pattern>...');
  process.exit(1);
}
if (!fs.existsSync(file)) {
  console.error(`prose.js: ${file} not found.`);
  process.exit(1);
}

const prose = [];
let inFence = false;
for (const line of fs.readFileSync(file, 'utf8').split('\n')) {
  if (/^\s*```/.test(line)) { inFence = !inFence; continue; }
  if (!inFence) prose.push(line);
}
const text = prose.join('\n');

const missing = patterns.filter(p => !new RegExp(p, 'i').test(text));
if (missing.length) {
  console.error(`prose.js: ${file} prose does not match: ${missing.join(', ')}`);
  process.exit(1);
}
```

If it exists, skip — do not overwrite.

If `.forge/scripts/migrate-notes.js` does **not** exist, create it with:

<!-- forge-init:embed .forge/scripts/migrate-notes.js -->

```javascript
#!/usr/bin/env node
// migrate-notes.js — externalize oversized inline Notes into task records
// (CONTRACT#data-model/task-record-data-model, CONTRACT#rules/workplan-access-discipline)
//
// Usage:
//   node .forge/scripts/migrate-notes.js [--dry-run] [--all] [--force]
//
// Why this exists: the externalization threshold only governs notes written
// from now on. Projects that predate it carry the whole debt inline — the
// motivating case is a workplan at 2,177 lines across 67 tasks, most of it
// narrative that CONTRACT#rules/workplan-access-discipline says does not belong
// in the DAG. Without a migration the threshold helps new projects only.
//
// For every task whose Notes exceed 3 lines this writes
// `.forge/notes/TASK-XXX.md` in Task Record Data Model shape and replaces the
// Notes field with a one-line summary plus the record path. Notes of 3 lines or
// fewer are left byte-identical — a file per one-line note is churn.
//
// Summaries are generated mechanically (first sentence of the notes, falling
// back to the task description) rather than by an agent: 67 agent-written
// summaries is its own context problem, and a human can improve any of them
// afterward by hand.
//
// Safety: Forge supports projects where `.forge/` is never committed, so there
// is no git history to recover from. Records are written before WORKPLAN.md is
// touched, a `.bak` is taken immediately before the rewrite, an existing record
// is never overwritten, and a rewrite that fails check-workplan.js is reverted.
//
// Exit codes: 0 success (including nothing to migrate) · 1 usage/safety refusal.

'use strict';

const fs = require('fs');
const path = require('path');
const { spawnSync } = require('child_process');

const { readWorkplan, parseWorkplan, setField } = require('./lib/workplan');
const { findRoot } = require('./lib/markdown');

// Nearest ancestor of the working directory holding .forge/ (TASK-072).
const ROOT = findRoot();
const WORKPLAN_PATH = path.join(ROOT, '.forge', 'WORKPLAN.md');
const NOTES_DIR = path.join(ROOT, '.forge', 'notes');
const BACKUP_PATH = `${WORKPLAN_PATH}.bak`;

const USAGE = `usage: node .forge/scripts/migrate-notes.js [--dry-run] [--all] [--force]

  --dry-run  report what would be migrated and write nothing
  --all      migrate every status, not just done tasks
  --force    migrate even if check-workplan.js does not pass first`;

// The externalization threshold, in lines of the Notes value as it stands in
// the workplan (CONTRACT#data-model/task-record-data-model). "More than 3",
// so a note of exactly 3 lines stays inline.
const THRESHOLD = 3;

// Already-migrated residue: a summary followed by the record path. Recognized
// explicitly rather than relying on the line count alone, so a hand-expanded
// summary that grew past the threshold is still not re-migrated.
const RECORD_POINTER_RE = /Record:\s*\.forge\/notes\/TASK-\d+\.md/i;

const FILES_LINE_RE = /^\s*Files:\s*(.+)$/i;

function die(message) {
  console.error(`migrate-notes.js: ${message}`);
  process.exit(1);
}

// --- Summary generation ---

// A sentence ends at a period followed by whitespace or end-of-value. That
// keeps `.forge/notes/x.md` and `wp.js` intact, which a naive split on "." does
// not — and paths are the most common thing in these notes.
function firstSentence(text) {
  const flat = text.replace(/\s+/g, ' ').trim();
  if (!flat) return '';
  const m = /^(.*?[.!?])(?:\s|$)/.exec(flat);
  return (m ? m[1] : flat).trim();
}

// Long enough to name what the record contains, short enough to stay a summary.
const SUMMARY_MAX = 160;

function truncate(s) {
  if (s.length <= SUMMARY_MAX) return s;
  const cut = s.slice(0, SUMMARY_MAX - 1);
  const space = cut.lastIndexOf(' ');
  return `${(space > 40 ? cut.slice(0, space) : cut).replace(/[.,;:\s]+$/, '')}…`;
}

// The summary is load-bearing: it is what lets a reader judge whether opening
// the record is warranted, without opening it. A bare pointer relocates the
// problem instead of solving it, so there is always prose before the path —
// the description when the notes yield no usable sentence.
function summarize(task, body) {
  const sentence = firstSentence(body.replace(/^\s*[-*]\s+/, ''));
  const text = sentence || task.description || 'Migrated task notes';
  return `${truncate(text)} Record: .forge/notes/${task.id}.md`;
}

// --- Record rendering ---

// A mechanical migration cannot tell a decision from a deviation from a plain
// account of what happened, and guessing would put words in the original
// author's mouth. So the notes land whole under Outcome, with a provenance line
// saying why the record is flat; Decisions and Deviations are omitted rather
// than fabricated. Only a `Files:` line is lifted, because that convention is
// unambiguous.
function buildRecord(task, body, today) {
  const bodyLines = [];
  const files = [];

  for (const line of body.split('\n')) {
    const m = FILES_LINE_RE.exec(line);
    if (m) {
      for (const p of m[1].split(',').map(s => s.trim()).filter(Boolean)) files.push(p);
      continue;
    }
    bodyLines.push(line);
  }

  while (bodyLines.length && bodyLines[bodyLines.length - 1].trim() === '') bodyLines.pop();

  const out = [
    `# ${task.id} — ${task.description}`,
    '',
    `*Migrated from the WORKPLAN.md Notes field on ${today}. The notes are reproduced`,
    'under Outcome as they were written; Decisions and Deviations were not recorded',
    'separately at the time.*',
    '',
    '## Outcome',
    '',
    ...bodyLines,
  ];

  if (files.length) {
    out.push('', '## Files', '', ...files.map(p => `- ${p}`));
  }

  return `${out.join('\n').replace(/\s+$/, '')}\n`;
}

// --- Lint ---

function lint() {
  return spawnSync(process.execPath, [path.join(__dirname, 'check-workplan.js')], {
    cwd: ROOT,
    encoding: 'utf8',
  });
}

// --- Main ---

function main(argv) {
  const dryRun = argv.includes('--dry-run');
  const all = argv.includes('--all');
  const force = argv.includes('--force');
  const unknown = argv.find(a => !['--dry-run', '--all', '--force'].includes(a));
  if (unknown) die(`unexpected argument "${unknown}".\n\n${USAGE}`);

  const wp = readWorkplan(ROOT);
  if (!wp) die('.forge/WORKPLAN.md not found. Run /forge-plan to generate one.');
  if (wp.tasks.length === 0) die('no tasks found in .forge/WORKPLAN.md.');

  // Pre-flight lint. Migrating a workplan that is already broken makes the .bak
  // the only way back, and in these projects nothing stands behind it. The
  // result is kept because it is also what makes the post-write lint below
  // meaningful: a workplan that did not lint before cannot be held to linting
  // after, and treating that as damage would revert a migration that was fine.
  const preClean = lint();
  if (preClean.status !== 0 && !force) {
    const detail = `${preClean.stdout || ''}${preClean.stderr || ''}`.trim();
    die(`refusing to migrate — check-workplan.js does not pass on the current WORKPLAN.md:\n${detail}\n\nFix the workplan first, or re-run with --force.`);
  }
  const wasClean = preClean.status === 0;

  // --- Select candidates ---
  // Done tasks only by default. A pending or active task's Notes are the
  // planner's instructions to the agent that will execute it, and a record is
  // read only when a task declares it in its Context field — so externalizing
  // them puts working instructions somewhere /forge-next will never look. A
  // blocked task's Notes say what is blocking it, which its resumption needs.
  // `--all` is there for the human who has decided otherwise.
  const candidates = [];
  const skipped = [];

  for (const task of wp.tasks) {
    const body = (task.notes || '').replace(/\s+$/, '');
    if (!body) continue;
    if (RECORD_POINTER_RE.test(body)) continue;
    if (body.split('\n').length <= THRESHOLD) continue;
    if (!all && task.status !== 'done') {
      skipped.push({ task, reason: `status is ${task.status} — use --all to include it` });
      continue;
    }
    const recordPath = path.join(NOTES_DIR, `${task.id}.md`);
    if (fs.existsSync(recordPath)) {
      skipped.push({ task, reason: `.forge/notes/${task.id}.md already exists — not overwriting it` });
      continue;
    }
    candidates.push({ task, body, recordPath });
  }

  for (const s of skipped) console.log(`skip ${s.task.id}: ${s.reason}`);

  if (candidates.length === 0) {
    console.log('Nothing to migrate.');
    return;
  }

  for (const c of candidates) {
    const lines = c.body.split('\n').length;
    console.log(`${dryRun ? 'would migrate' : 'migrate'} ${c.task.id}: ${lines} lines -> .forge/notes/${c.task.id}.md`);
  }

  if (dryRun) {
    console.log(`Would migrate ${candidates.length} task(s). Nothing was written.`);
    return;
  }

  // --- Write records first ---
  // Additive and reversible: if anything below fails, the records are the only
  // thing on disk and the workplan still holds the notes they were built from.
  const today = new Date().toISOString().slice(0, 10);
  fs.mkdirSync(NOTES_DIR, { recursive: true });
  for (const c of candidates) {
    fs.writeFileSync(c.recordPath, buildRecord(c.task, c.body, today));
  }

  // --- Then rewrite the workplan ---
  // setField works from parsed line ranges, so the parse is refreshed after
  // each edit rather than tracking how the previous edit shifted the file.
  let content = wp.content;
  for (const c of candidates) {
    const parsed = parseWorkplan(content);
    const result = setField(parsed, c.task.id, 'notes', summarize(c.task, c.body));
    if (!result.ok) die(`could not rewrite ${c.task.id} Notes: ${result.error} (records were written; WORKPLAN.md is unchanged)`);
    content = result.content;
  }

  const original = fs.readFileSync(WORKPLAN_PATH, 'utf8');
  fs.writeFileSync(BACKUP_PATH, original);
  fs.writeFileSync(WORKPLAN_PATH, content);

  const post = lint();
  if (post.status !== 0) {
    const detail = `${post.stdout || ''}${post.stderr || ''}`.trim();
    if (wasClean) {
      fs.writeFileSync(WORKPLAN_PATH, original);
      die(`migration rejected — check-workplan.js failed afterward, so WORKPLAN.md was restored:\n${detail}\n\nThe records under .forge/notes/ were left in place for inspection.`);
    }
    console.log(`warning: check-workplan.js still fails. It failed before the migration too and --force was passed, so this is not attributed to the rewrite:\n${detail}`);
  }

  console.log(`Migrated ${candidates.length} task(s). Backup: .forge/WORKPLAN.md.bak`);
}

main(process.argv.slice(2));
```

If it exists, skip — do not overwrite.

If `.forge/scripts/guard-push.sh` does **not** exist, create it with Blocks `git push` unconditionally.

<!-- forge-init:embed .forge/scripts/guard-push.sh -->

```bash
#!/usr/bin/env bash
# guard-push.sh — PreToolUse hook: block `git push`, unconditionally.
#
# CONTRACT#rules/unattended-execution rule 3: "No pushing. Publishing is always
# human." CONTRACT#boundaries/hook-configuration makes this guard always active
# — it is not gated on FORGE_UNATTENDED, because the rule it enforces is not
# either. An interactive session has a human at the keyboard who can lift the
# hook deliberately; what must not exist is a path where publishing happens
# because nobody remembered it shouldn't.
#
# Reads Claude Code's PreToolUse stdin contract (JSON, `tool_input.command`) and
# exits 2 to block. Exit 2 specifically: Claude Code treats 2 as "block the call
# and feed stderr back to the model", and any other nonzero as a non-blocking
# error that lets the tool run anyway.

set -u

payload=$(cat)

# Prefer the parsed command. If the envelope is unparseable, fall back to the
# raw payload as the haystack rather than allowing the call: a guard that opens
# the gate whenever it cannot read the request is defeatable by anything that
# perturbs the envelope.
command=$(printf '%s' "$payload" | node -e 'let s="";process.stdin.on("data",d=>{s+=d}).on("end",()=>{try{const j=JSON.parse(s);const c=j&&j.tool_input&&j.tool_input.command;if(typeof c==="string")process.stdout.write(c);}catch(e){}});' 2>/dev/null)
[ -n "$command" ] || command="$payload"

# `git push`, allowing global flags in between (`git -C dir push`, `git
# --no-pager push`). The trailing boundary is what keeps `git pushed` and
# `pushState` from matching — a substring test would block prose about pushing.
if printf '%s\n' "$command" | grep -Eq '(^|[^[:alnum:]_-])git([[:space:]]+-[^[:space:]]+([[:space:]]+[^-[:space:]][^[:space:]]*)?)*[[:space:]]+push([[:space:]]|$)'; then
  cat >&2 <<'MSG'
Blocked by guard-push.sh: publishing is human-only.

CONTRACT#rules/unattended-execution rule 3 — "No pushing. Publishing is always
human." Commit the work and hand it to the human to push.
MSG
  exit 2
fi

exit 0
```

If it exists, skip — do not overwrite.

If `.forge/scripts/guard-branch.sh` does **not** exist, create it with Blocks `git commit` on the default branch when `FORGE_UNATTENDED=1`.

<!-- forge-init:embed .forge/scripts/guard-branch.sh -->

```bash
#!/usr/bin/env bash
# guard-branch.sh — PreToolUse hook: during an unattended run, block `git
# commit` on the repository's default branch.
#
# CONTRACT#rules/unattended-execution rule 1: "Work branch only. Never on the
# default branch. The branch is the blast radius."
#
# The guard is armed only by FORGE_UNATTENDED=1 and is otherwise inert, so
# ordinary interactive sessions — where committing straight to main is a normal,
# human-reviewed habit on personal projects — are untouched. Per
# CONTRACT#boundaries/hook-configuration the flag is set by the headless launcher
# that drives the loop, never typed by a human before a run: a forgotten
# `export` would silently restore main-committing behavior in exactly the case
# where nobody is watching to catch it.
#
# Reads Claude Code's PreToolUse stdin contract (JSON, `tool_input.command`) and
# exits 2 to block — Claude Code treats 2 as "block and show stderr to the
# model", and any other nonzero as a non-blocking error.

set -u

payload=$(cat)

# Not an unattended run: this guard has nothing to say. Checked before anything
# else so the interactive path costs one string comparison.
[ "${FORGE_UNATTENDED:-}" = "1" ] || exit 0

command=$(printf '%s' "$payload" | node -e 'let s="";process.stdin.on("data",d=>{s+=d}).on("end",()=>{try{const j=JSON.parse(s);const c=j&&j.tool_input&&j.tool_input.command;if(typeof c==="string")process.stdout.write(c);}catch(e){}});' 2>/dev/null)
[ -n "$command" ] || command="$payload"

printf '%s\n' "$command" | grep -Eq '(^|[^[:alnum:]_-])git([[:space:]]+-[^[:space:]]+([[:space:]]+[^-[:space:]][^[:space:]]*)?)*[[:space:]]+commit([[:space:]]|$)' || exit 0

current=$(git rev-parse --abbrev-ref HEAD 2>/dev/null) || exit 0
[ -n "$current" ] || exit 0

# The default branch is the repo's, not a hardcoded `main`: a project on `trunk`
# or `master` must be protected on its own branch and nowhere else. Ask the
# remote's HEAD first (authoritative where there is a remote), then the local
# init default, then fall back.
default=$(git symbolic-ref --short refs/remotes/origin/HEAD 2>/dev/null | sed 's#^origin/##')
[ -n "$default" ] || default=$(git config --get init.defaultBranch 2>/dev/null)
[ -n "$default" ] || default=main

if [ "$current" = "$default" ]; then
  cat >&2 <<MSG
Blocked by guard-branch.sh: unattended commit on the default branch.

FORGE_UNATTENDED=1 and HEAD is on "$current", the repository's default branch.
CONTRACT#rules/unattended-execution rule 1 — "Work branch only. Never on the
default branch. The branch is the blast radius."

Create a work branch and commit there; the span reaches "$default" only through
checkpoint approval and a human merge (rule 5).
MSG
  exit 2
fi

exit 0
```

If it exists, skip — do not overwrite.

If `.forge/scripts/guard-secrets.sh` does **not** exist, create it with Blocks `git commit` when the staged diff adds a secret-shaped line.

<!-- forge-init:embed .forge/scripts/guard-secrets.sh -->

```bash
#!/usr/bin/env bash
# guard-secrets.sh — PreToolUse hook: block `git commit` when the staged diff
# adds a line matching a conservative secret pattern.
#
# CONTRACT#boundaries/hook-configuration: "A floor, not a substitute for a
# dedicated scanner." The pattern list is deliberately limited to the three
# classes the Contract names — cloud access keys, private-key headers, common
# API-key prefixes — all of which have distinctive fixed prefixes and fixed
# lengths. Generic `password =` style heuristics are excluded on purpose: a
# guard that cries wolf on ordinary code gets disabled, and a disabled guard
# catches nothing.
#
# Scope is the *added* lines of the *staged* diff. Unstaged content is not about
# to be committed, and deleting a line that contains a key is the fix, not the
# offense.
#
# Reads Claude Code's PreToolUse stdin contract (JSON, `tool_input.command`) and
# exits 2 to block — Claude Code treats 2 as "block and show stderr to the
# model", and any other nonzero as a non-blocking error.

set -u

payload=$(cat)

command=$(printf '%s' "$payload" | node -e 'let s="";process.stdin.on("data",d=>{s+=d}).on("end",()=>{try{const j=JSON.parse(s);const c=j&&j.tool_input&&j.tool_input.command;if(typeof c==="string")process.stdout.write(c);}catch(e){}});' 2>/dev/null)
[ -n "$command" ] || command="$payload"

printf '%s\n' "$command" | grep -Eq '(^|[^[:alnum:]_-])git([[:space:]]+-[^[:space:]]+([[:space:]]+[^-[:space:]][^[:space:]]*)?)*[[:space:]]+commit([[:space:]]|$)' || exit 0

# Both greps take -E deliberately: in a basic regular expression GNU grep reads
# `\+` as the repetition operator, so `grep -v '^\+\+\+'` silently discards
# every line and the guard sees an empty diff.
added=$(git diff --cached --unified=0 2>/dev/null | grep -E '^\+' | grep -Ev '^\+\+\+')
[ -n "$added" ] || exit 0

# Each entry is "label|ERE". Anchored prefixes with length constraints, so a
# variable merely named `aws_key` does not trip anything.
patterns='cloud access key (AWS)|(AKIA|ASIA)[0-9A-Z]{16}
private key header|-----BEGIN [A-Z ]*PRIVATE KEY-----
GitHub token|gh[pousr]_[A-Za-z0-9]{36}
Slack token|xox[abprs]-[0-9A-Za-z-]{10,}
Stripe live key|sk_live_[0-9A-Za-z]{16,}
Anthropic API key|sk-ant-[A-Za-z0-9_-]{24,}
Google API key|AIza[0-9A-Za-z_-]{35}'

hits=""
while IFS='|' read -r label regex; do
  [ -n "$regex" ] || continue
  if printf '%s\n' "$added" | grep -Eq -- "$regex"; then
    hits="${hits}  - ${label}
"
  fi
done <<EOF
$patterns
EOF

if [ -n "$hits" ]; then
  cat >&2 <<MSG
Blocked by guard-secrets.sh: the staged diff adds what looks like a secret.

Matched:
${hits}
Unstage the offending lines and move the value to an environment variable or an
ignored file, then commit again. This guard is a floor, not a scanner — if it
fired on a false positive, the value still deserves a second look before it
enters history.
MSG
  exit 2
fi

exit 0
```

If it exists, skip — do not overwrite.

### 12. Report completion

After creating all files, tell the user which files were created (existing files were not overwritten), listing only from this set — and only the ones actually created or modified, not skipped:

- `.forge/VISION.md`
- `.forge/CONTRACT.md`
- `.forge/SPEC.md`
- `.forge/STATUS.md`
- `.forge/templates/scaffold.md`
- `.forge/templates/feature.md`
- `.forge/templates/fix.md`
- `.forge/templates/clarify.md`
- `.forge/templates/refactor.md`
- `.forge/templates/investigate.md`
- `.forge/templates/checkpoint.md`
- `.forge/UX.md` (only if step 6 was answered "yes")
- `.forge/templates/ux-spec.md` (only if step 6 was answered "yes")
- `.forge/DESIGN.md` (only if step 6 was answered "yes")
- `.forge/scripts/check-ux-spec.js` (only if step 6 was answered "yes")
- `.forge/scripts/lib/markdown.js`
- `.forge/scripts/lib/workplan.js`
- `.forge/scripts/check-workplan.js`
- `.forge/scripts/wp.js`
- `.forge/scripts/check-spec.js`
- `.forge/scripts/prose.js`
- `.forge/scripts/migrate-notes.js`
- `.forge/scripts/guard-push.sh`
- `.forge/scripts/guard-branch.sh`
- `.forge/scripts/guard-secrets.sh`
- `.claude/settings.json`
- `CLAUDE.md` (integration block)

Then list next steps, numbered, including only the items that apply:

1. Fill in `.forge/VISION.md` with your project's What, Who, and Pillars.
2. Fill in `.forge/CONTRACT.md` with your project's interfaces, rules, and data model.
3. Fill in `.forge/SPEC.md` with your requirements, or leave it for `/forge-spec` to draft.
4. Fill in `.forge/UX.md` with your screen flows and specs. — **only if step 6 was answered "yes"**
5. Fill in `.forge/DESIGN.md` with your design tokens and component specs. — **only if step 6 was answered "yes"**
6. Run `/forge-plan` to generate a task workplan.

Renumber the remaining steps sequentially if step 4 or 5 above was omitted, so the list has no gaps.

If all applicable files already existed, say: "All Forge files already exist. Nothing was changed."
