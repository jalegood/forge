# /forge-next

Read `.forge/WORKPLAN.md`, select the next task, resolve its context manifest from `.forge/CONTRACT.md`, inject into the prompt template, and execute the task.

If `$ARGUMENTS` is present (e.g., the user typed `/forge-next TASK-012`), treat it as the target task ID.

## Steps

### 1. Read WORKPLAN.md

Read `.forge/WORKPLAN.md` in full. Parse each task entry:

```markdown
## [TASK-XXX] Description

- **Status:** pending | active | done | blocked
- **Type:** scaffold | feature | clarify | refactor | fix | investigate | ux-spec | checkpoint
- **Depends:** none | comma-separated TASK-IDs
- **Context:** manifest references
- **Gate:** shell command or manual: prefix
- **Notes:** free text (may be multi-line)
```

If `.forge/WORKPLAN.md` does not exist or contains no tasks, tell the user: "No workplan found. Run `/forge-plan` to generate one." Stop.

### 2. Select the target task

Follow this priority order:

**A. Explicit task ID argument:**
If the user provided a task ID argument:

- Locate that task in the workplan.
- If the specified task is already `active`, treat this as a resume (proceed to B).
- If a _different_ task is currently `active`, warn: "TASK-XXX is currently active. Only one task can be active at a time. Complete or block it before starting a new task." Stop and wait for the user to decide.
- If the specified task's `Depends` are not all `done` (and Depends is not `none`), warn: "TASK-XXX has unmet dependencies: [list each with its status]." Ask for confirmation before proceeding.
- Otherwise, select it.

**B. Resume active task:**
If no argument was provided (or the argument matches the active task) and a task has status `active`:

- Select that task.
- Read its `Notes` field carefully — this provides continuity from the previous session.
- Report: "Resuming TASK-XXX — [description]" and display the Notes content if non-empty.

**C. Next unblocked pending task:**
If no argument and no active task:

- Scan tasks in file order. A task is **unblocked** when its `Depends` field is `none` or every listed task ID has status `done`.
- Select the first unblocked `pending` task.
- If no unblocked pending task exists, report: "No unblocked tasks available. Run `/forge-status` to see what's blocked." Stop.

### 3. Resolve the context manifest

Parse the selected task's `Context` field into a list of references. Each reference uses the format:

- `CONTRACT#section-name` — a top-level section from `.forge/CONTRACT.md`
- `CONTRACT#section-name/subsection` — a subsection within a parent
- `filename#section-name` — for multi-file contracts (file is `.forge/filename.md`)
- `UX#global` — the `## Global` section from `.forge/UX.md`
- `UX#flows/flow-name` — a full flow (header through end of flow) from `.forge/UX.md`
- `UX#flows/flow-name/screen-name` — one screen spec from `.forge/UX.md`
- `DESIGN#section-name` — a top-level section from `.forge/DESIGN.md` (e.g., `DESIGN#tokens`)
- `DESIGN#section-name/subsection` — a subsection within DESIGN.md (e.g., `DESIGN#components/button`)
- `SPEC#section-name` — a top-level section from `.forge/SPEC.md` (e.g., `SPEC#requirements`)
- `SPEC#section-name/subsection` — a subsection within SPEC.md (e.g., `SPEC#requirements/req-login`)
- `specs/name#section-name` — a top-level section from a per-feature spec file `.forge/specs/name.md` (e.g., `specs/auth#requirements`)
- `specs/name#section-name/subsection` — a subsection within that per-feature spec file
- `notes/TASK-XXX#section-name` — a section of a task record `.forge/notes/TASK-XXX.md` (e.g., `notes/TASK-029#deviations`)

**Source file routing:** `CONTRACT#` references resolve against `.forge/CONTRACT.md`. `UX#` references resolve against `.forge/UX.md`. `DESIGN#` references resolve against `.forge/DESIGN.md`. `SPEC#` references resolve against `.forge/SPEC.md`. `specs/name#` references resolve against `.forge/specs/name.md` (the `name` segment names the file, not a heading). `notes/TASK-XXX#` references resolve against `.forge/notes/TASK-XXX.md` (likewise, `TASK-XXX` names the file).

**For each reference, extract the matching markdown section from the appropriate file:**

1. **Slugify and match headers.** To match a reference segment to a markdown heading:
   - Take the heading text (strip `#` markers, formatting characters like backticks, asterisks)
   - Lowercase it, replace runs of non-alphanumeric characters with single hyphens, trim leading/trailing hyphens
   - Compare to the reference segment

   Examples of slug matches:
   - `data-model` matches `## Data Model`
   - `interfaces` matches `## Interfaces`
   - `command-forge-next` matches `### Command: `/forge-next``
   - `task-lifecycle` matches `### Task Lifecycle`
   - `context-manifest` matches `### Context Manifest`

   **UX.md heading patterns** use prefixed labels — strip the prefix when slugifying:
   - `flow-name` matches `### Flow: Flow Name` (strip "Flow: " prefix, slugify "Flow Name" → `flow-name`)
   - `screen-name` matches `#### Screen: Screen Name` (strip "Screen: " prefix, slugify "Screen Name" → `screen-name`)
   - `global` matches `## Global`

2. **Navigate nested references.** For `CONTRACT#parent/child`:
   - First find the heading matching `parent` (e.g., `## Interfaces`)
   - Then within that section, find the sub-heading matching `child` (e.g., `### Command: /forge-next`)

   For `UX#flows/flow-name`:
   - Find `## Flows` in UX.md, then within it find `### Flow:` whose name slugifies to `flow-name`
   - Extract from that `### Flow:` heading through the next `###` or `##` or `#`

   For `UX#flows/flow-name/screen-name`:
   - Navigate to the flow as above, then within it find `#### Screen:` whose name slugifies to `screen-name`
   - Extract from that `#### Screen:` heading through the next `####`, `###`, `##`, or `#`

   For `UX#global`:
   - Find `## Global` in UX.md and extract through the next `##` or `#`

   For `DESIGN#section-name`:
   - Find the heading matching `section-name` in DESIGN.md using standard slug matching (no prefix stripping — headings are plain text like `## Tokens`, `## Components`)
   - Extract from that heading through the next same-level or higher heading

   For `DESIGN#section-name/subsection`:
   - Same nested navigation as `CONTRACT#parent/child`, but resolved against `.forge/DESIGN.md`
   - First find the heading matching `section-name`, then within it find the sub-heading matching `subsection`

   For `SPEC#section-name` / `SPEC#section-name/subsection`:
   - Same standard slug matching and nested navigation as `CONTRACT#`, but resolved against `.forge/SPEC.md`
   - **Requirement headings are the one exception to standard slug matching.** A `### [req-slug] Requirement Name` heading under `## Requirements` matches subsection reference `req-slug` by comparing only the bracketed portion — strip the brackets, lowercase, compare directly — ignoring the trailing "Requirement Name" text. So `SPEC#requirements/req-login` matches `### [req-login] User Login` regardless of what "User Login" says.

   For `specs/name#section-name` / `specs/name#section-name/subsection`:
   - The `name` segment selects the file: `.forge/specs/name.md` (e.g., `specs/auth#requirements` resolves against `.forge/specs/auth.md`)
   - Within that file, resolve `section-name` (and optional `subsection`) using the same standard slug matching and nested navigation as `CONTRACT#`
   - If `.forge/specs/name.md` does not exist, treat the reference as unresolved (see below)

   For `notes/TASK-XXX#section-name`:
   - The `TASK-XXX` segment selects the file: `.forge/notes/TASK-XXX.md` (e.g., `notes/TASK-029#deviations` resolves against `.forge/notes/TASK-029.md`)
   - Within that file, resolve `section-name` using the same standard slug matching as `CONTRACT#`. Record headings are the plain Task Record Data Model sections — `## Outcome`, `## Decisions`, `## Deviations`, `## Files`
   - If `.forge/notes/TASK-XXX.md` does not exist, treat the reference as unresolved (see below)
   - **A record is read only when a task declares it.** Do not open `.forge/notes/` on your own initiative to fill in background on a prior task — an undeclared lookup is one an agent may skip, which is why cross-task record access runs through the manifest

3. **Extract section content.** Capture everything from the matched heading (inclusive) through just before the next heading at the **same level or higher**. A `###` section ends at the next `###`, `##`, or `#`.

   **Lines inside ``` fences are not headings.** Any section that fences a markdown example — a file template, a document skeleton, a sample artifact — holds heading-like lines inside the fence. A scan that ignores fences stops at the first one and truncates the section silently: the reference still resolves, so no unresolved-reference warning fires and the loss is invisible. Track fence state while extracting — toggle on each ``` line, and ignore headings while inside a fence. If `.forge/scripts/lib/markdown.js` is present in the project, prefer its `resolveRef`, which already handles this.

4. **Concatenate** all resolved sections in the order they appear in the Context field, separated by a blank line.

**If a reference cannot be resolved** (no matching heading found), warn: "Could not resolve context reference: [ref]. Check that CONTRACT.md headings match." Continue with the references that did resolve.

**Budget check:** If the resolved context exceeds ~200 lines, note this to the user but proceed.

### 4. Mark task active in WORKPLAN.md

If the task is not already `active`, update its status in `.forge/WORKPLAN.md`:

Change `- **Status:** pending` to `- **Status:** active` for this task.

Do this **before** beginning execution — if the session is interrupted, the task should already be marked active.

**Workplan lint:** Immediately after writing, run `node .forge/scripts/check-workplan.js`. A nonzero exit blocks proceeding — diagnose the reported violation, fix WORKPLAN.md, and re-run the script until it exits 0 before continuing to step 5.

### 5. Load and fill the prompt template

1. Read `.forge/templates/{type}.md` where `{type}` is the task's Type field (e.g., `feature`, `scaffold`, `clarify`). If the file does not exist, stop and tell the user: "Template file missing. Run `/forge-init` to create project templates." Do not proceed with inline fallbacks.

2. Replace template slots with resolved values:
   - `{{context}}` → the concatenated resolved context from step 3
   - `{{task_id}}` → the task ID (e.g., `TASK-004`)
   - `{{task_description}}` → the description text from the task header (`## [TASK-XXX] Description` — the Description part)
   - `{{gate}}` → the task's Gate field value

The filled template is now your **execution prompt**.

### 6. Execute the task

Follow the filled template's Instructions section to implement the task. This is the main work phase — write code, create files, configure artifacts, make changes as directed by the template.

**Rules during execution:**

- Stay within the scope defined by the task description and resolved context.
- Do not modify CONTRACT.md without asking the human first.
- If the task grows beyond what can be completed in this session, stop and proceed to step 8 (incomplete handling).

### 7. Run the gate

When you believe the task is complete, run the gate from the task's Gate field.

**Automated gate** (no `manual:` prefix):

- Run the gate command in the shell.
- If it **passes** (exit code 0 and produces expected output): proceed to step 8, gate passed.
- If it **fails**: diagnose the failure, fix the issue, and re-run. Repeat until it passes or you determine the task cannot be completed this session.

**Manual gate** (Gate field starts with `manual:`):

- Do not run a shell command.
- Present the gate description (everything after `manual:`) to the human.
- Ask: "Does this gate pass? (yes/no)"
- Proceed based on their answer.

### 8. Handle the result

**Gate passes:**

1. Mark the task `done` in `.forge/WORKPLAN.md`:
   ```
   - **Status:** done
   ```
2. Collect touched files: run `git diff --name-only HEAD` (or `git diff --name-only --cached` if changes are staged but not committed).
3. Write the task's narrative — what was built, decisions made, deviations taken, files touched. Decide where it goes using the **externalization threshold** below.
4. Report success to the user.
5. Suggest a commit message:
   ```
   [Description] (TASK-XXX)
   ```
   Example: `Implement /forge-next command (TASK-004)`

#### Externalization threshold

Draft the narrative first, then measure it.

**3 lines or fewer** — it stays inline. Append it to the task's Notes field in WORKPLAN.md, with the file list as a `Files:` line:

```markdown
- **Notes:** Fixed the off-by-one in the slug matcher; no deviations.
  Files: .forge/scripts/lib/markdown.js, .forge/tests/test-markdown.sh
```

If the Notes field already has content, append on a new line after existing content. A separate file for a one-line note is churn, not structure.

**More than 3 lines** — externalize it. Write `.forge/notes/TASK-XXX.md` using the Task Record Data Model:

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

Omit a section only when it is genuinely empty (no deviations occurred). The file list from step 2 goes in the record's `## Files` section — do not also duplicate it inline.

Then replace the task's Notes field with a **one-line summary plus the record path**:

```markdown
- **Notes:** Implemented SPEC# resolution; one deviation on req-slug matching. Record: .forge/notes/TASK-029.md
```

**The summary is load-bearing.** A bare pointer relocates the problem instead of solving it: an agent that cannot tell what a record contains either opens it every time (no savings) or never opens it (information lost). The summary must name what is inside — the deliverable, and whether there are decisions or deviations worth reading. `Record: .forge/notes/TASK-029.md` alone is not acceptable output.

**Records must stand alone without git.** Forge runs against projects where `.forge/` is never committed, so `git log --grep` retrieves nothing about tasks and the record is the only archaeological artifact. A record that says "see the commit message" or "see the diff" is defective — write what the commit would have said, in the record.

**Task is blocked (cannot proceed):**

If during execution you determine the task cannot proceed — a dependency is missing, a Contract section is ambiguous, or the task requires human decisions that aren't available:

1. Mark the task `blocked` in `.forge/WORKPLAN.md`:
   ```
   - **Status:** blocked
   ```
2. Update Notes with: what's blocking, what needs to happen to unblock.
3. Suggest a `clarify` or `fix` task if appropriate.

**Gate fails / Task incomplete:**

1. Keep the task `active` in WORKPLAN.md (do not change status).
2. Update the task's `Notes` field in WORKPLAN.md with:
   - What was accomplished
   - What remains to be done
   - Any decisions made or blockers encountered
3. Report the current state to the user.
4. The human will commit partial progress or stash, then run `/clear`.

**Workplan lint:** Whichever branch above applies, run `node .forge/scripts/check-workplan.js` immediately after writing WORKPLAN.md. A nonzero exit blocks proceeding — diagnose the reported violation, fix WORKPLAN.md, and re-run the script until it exits 0 before reporting to the user.

## Constraints

- **One active task at a time.** Exactly 0 or 1 tasks may have status `active`. Do not activate a new task while another is active.
- **Context budget.** Resolved context should not exceed ~200 lines of Contract content per task.
- **Contract is read-only.** Do not modify CONTRACT.md unless the human explicitly approves.
- **Notes are continuity.** When resuming an active task, the Notes field is your only link to previous sessions. Read it carefully before starting work.
- **Records are the durable narrative.** WORKPLAN.md holds the DAG; `.forge/notes/TASK-XXX.md` holds everything else. Records are read only when a task declares one in its Context field (`notes/TASK-XXX#section-name`) — never open `.forge/notes/` on your own initiative.
- **No auto-commit.** Suggest a commit message but never commit automatically. The human is the final gate.
- **Template drives execution.** After step 5, the filled template's instructions govern what you do. The template includes its own completion protocol — follow it.
