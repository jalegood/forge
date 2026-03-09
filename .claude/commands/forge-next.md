# /forge-next

Read `.forge/WORKPLAN.md`, select the next task, resolve its context manifest from `.forge/CONTRACT.md`, inject into the prompt template, and execute the task.

If `$ARGUMENTS` is present (e.g., the user typed `/forge-next TASK-012`), treat it as the target task ID.

## Steps

### 1. Read WORKPLAN.md

Read `.forge/WORKPLAN.md` in full. Parse each task entry:

```markdown
## [TASK-XXX] Description

- **Status:** pending | active | done | blocked
- **Type:** scaffold | feature | clarify | refactor | fix | investigate
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

- `CONTRACT#section-name` — a top-level section
- `CONTRACT#section-name/subsection` — a subsection within a parent
- `filename#section-name` — for multi-file contracts (file is `.forge/filename.md`)

**For each reference, extract the matching markdown section from the contract file:**

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

2. **Navigate nested references.** For `CONTRACT#parent/child`:
   - First find the heading matching `parent` (e.g., `## Interfaces`)
   - Then within that section, find the sub-heading matching `child` (e.g., `### Command: /forge-next`)

3. **Extract section content.** Capture everything from the matched heading (inclusive) through just before the next heading at the **same level or higher**. A `###` section ends at the next `###`, `##`, or `#`.

4. **Concatenate** all resolved sections in the order they appear in the Context field, separated by a blank line.

**If a reference cannot be resolved** (no matching heading found), warn: "Could not resolve context reference: [ref]. Check that CONTRACT.md headings match." Continue with the references that did resolve.

**Budget check:** If the resolved context exceeds ~200 lines, note this to the user but proceed.

### 4. Mark task active in WORKPLAN.md

If the task is not already `active`, update its status in `.forge/WORKPLAN.md`:

Change `- **Status:** pending` to `- **Status:** active` for this task.

Do this **before** beginning execution — if the session is interrupted, the task should already be marked active.

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
2. Collect touched files: run `git diff --name-only HEAD` (or `git diff --name-only --cached` if changes are staged but not committed). Take the resulting file list and append a `Files:` line to the task's Notes field in WORKPLAN.md:
   ```
   - **Notes:** Files: path/to/file1.md, path/to/file2.ts
   ```
   If the Notes field already has content, append on a new line after existing content.
3. Report success to the user.
4. Suggest a commit message:
   ```
   [Description] (TASK-XXX)
   ```
   Example: `Implement /forge-next command (TASK-004)`

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

## Constraints

- **One active task at a time.** Exactly 0 or 1 tasks may have status `active`. Do not activate a new task while another is active.
- **Context budget.** Resolved context should not exceed ~200 lines of Contract content per task.
- **Contract is read-only.** Do not modify CONTRACT.md unless the human explicitly approves.
- **Notes are continuity.** When resuming an active task, the Notes field is your only link to previous sessions. Read it carefully before starting work.
- **No auto-commit.** Suggest a commit message but never commit automatically. The human is the final gate.
- **Template drives execution.** After step 5, the filled template's instructions govern what you do. The template includes its own completion protocol — follow it.
