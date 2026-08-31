# /forge-next

Select the next task via the `.forge/scripts/wp.js` projection, resolve its context manifest from `.forge/CONTRACT.md`, inject into the prompt template, and execute the task.

Workplan reads and writes both go through `wp.js` — the command never loads `.forge/WORKPLAN.md` into context and never hand-edits it (CONTRACT#rules/workplan-access-discipline).

If `$ARGUMENTS` is present (e.g., the user typed `/forge-next TASK-012`), treat it as the target task ID.

## Steps

### 1. Report open foundation observations, then project the workplan

**Before selecting a task**, check for open `foundation`-severity rows in STATUS.md Observations and report every one of them to the user (CONTRACT#interfaces/command-forge-next, Observations). Do this regardless of what selection turns out to be — including a resume:

```bash
node .forge/scripts/wp.js status --json
```

Filter the `observations` array to entries with `severity: "foundation"`. If any exist, relay each verbatim (id, raised by, observation text) before continuing to task selection. This report is independent of the mechanical halt below: `wp.js next` itself refuses to select *new* work while an open foundation row exists, but that refusal is exempted on `resume-active` (CONTRACT#rules/unattended-execution, hard stop 4) — so a resume would otherwise surface nothing. This step closes that gap by reporting unconditionally, before the selection call, whether or not that call ends up halting.

Do **not** open `.forge/WORKPLAN.md`. Task selection is entirely deterministic — unblocked-ness, dependency satisfaction, active-task resume, explicit-ID override — so it runs in a script, and the script returns only the selected task (CONTRACT#rules/workplan-access-discipline). The workplan grows without bound; the per-session cost of this command must not grow with it.

Run:

```bash
node .forge/scripts/wp.js next
```

If the user supplied a task ID (e.g., the user typed `/forge-next TASK-012`), pass it through:

```bash
node .forge/scripts/wp.js next TASK-012
```

The script emits exactly the fields this command needs:

```
Task: TASK-XXX — Description
Selection: next-unblocked | resume-active | explicit
Status: pending | active | done | blocked
Type: scaffold | feature | clarify | refactor | fix | investigate | ux-spec | checkpoint
Depends: none | comma-separated TASK-IDs
Context: manifest references
Gate: shell command or manual: prefix
Warning: ...            (zero or more)
Notes:
<verbatim, possibly multi-line>
```

Add `--json` if you would rather consume the fields structurally. Either way, this output is the whole of your knowledge of the workplan for this session — do not go read the document to fill in around it.

### 2. Interpret the selection

The script has already applied every selection rule; your job is to react to what it returned.

**Exit code 0 — a task was selected.** The `Selection:` line says why:

- `next-unblocked` — no task was active, and this is the first `pending` task whose `Depends` are all `done` or `none`.
- `resume-active` — a task was already `active`, so this is a resume (this also covers the case where the user named the active task explicitly). Read the `Notes:` block carefully — it is your only link to the previous session. Report: "Resuming TASK-XXX — [description]" and display the Notes content if non-empty.
- `explicit` — the user named this task and it was free to start.

**Any `Warning:` lines must be surfaced to the user before you begin work.** The script warns rather than refuses, and the human decides:

- Unmet dependencies (`TASK-XXX has unmet dependencies: ...`) — relay it and ask for confirmation before proceeding.
- Already `done`, or currently `blocked` — relay it and ask for confirmation before proceeding.

**Exit code 2 — nothing to select.** Report the script's message and stop. Three cases produce it:

- A _different_ task is currently `active`. Only one task can be active at a time — the human must complete or block it before starting a new one.
- No unblocked pending task exists. Point the user at `/forge-status` to see what is blocked.
- **An open `foundation`-severity observation exists in STATUS.md.** This is hard stop 4 from CONTRACT#rules/unattended-execution: the spec, contract, or approach is suspect, and continuing to build compounds debt. The script prints the offending rows — relay every one of them verbatim. Clearing the stop is a human judgment: they triage the row's Disposition to `accepted` or `declined`, or they re-run with `--force`. **Do not pass `--force` yourself, and do not edit the row's Disposition to clear your own path.** A halt an agent can lift is not a halt, and this is the one stop that exists to interrupt your momentum rather than support it.

**Exit code 1 — usage or lookup error.** The named task ID does not exist, or `.forge/WORKPLAN.md` is missing or has no tasks. Report the message verbatim; for a missing workplan, tell the user to run `/forge-plan`.

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

1. **Match headers by alphanumeric compaction** (normative rule: CONTRACT#data-model/context-manifest):
   - Take the heading text (strip `#` markers, formatting characters like backticks, asterisks)
   - Reduce **both** the heading text and the reference segment to lowercase alphanumerics — strip every other character outright rather than turning it into hyphens
   - Compare the compacted forms directly

   Compacting both sides is what lets the mixed punctuation live in real Context fields match: `claudemd-integration-block` and `CLAUDE.md Integration Block` both compact to `claudemdintegrationblock`. A hyphen-preserving slugify would report a correct reference as unresolvable.

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

If the task is not already `active`, mark it through the same script — never by hand-editing the document:

```bash
node .forge/scripts/wp.js set TASK-XXX status active
```

`wp.js set` rewrites exactly the one field line, leaves the rest of the file byte-identical, enforces the lifecycle transitions from CONTRACT#state-machines/task-lifecycle and the one-active-task constraint, re-runs `check-workplan.js`, and reverts the write if the lint fails. A nonzero exit means the mutation did not stand: diagnose what it reported and fix that before continuing to step 5.

**Exit 4 — the gate-discrimination probe refused the transition.** `wp.js` ran the task's gate against the pre-work tree and it already passed, so the gate cannot verify this task's work (CONTRACT#rules/gate-discrimination). This refusal is distinct from a lint rejection or an invalid transition (both exit 1), and it has exactly two legitimate routes out — distinguishing them is your job, because they look identical from the exit code:

1. **The gate is wrong.** It asserts a topic the file already mentions, or a count an append-only artifact has outgrown. Repair it while the task is still `pending` — `node .forge/scripts/wp.js set TASK-XXX gate '<discriminating gate>'`, naming the change this task makes (a `prose.js` phrase, the new fixture, the new test) — then retry the activation. The repaired gate lands in this task's diff, which is what makes the repair reviewable at the checkpoint rather than invisible.
2. **The gate is right and the work already exists.** A prior task absorbed this task's scope — the OBS-008 condition. This is a scope finding, not a gate defect: report it to the human and stop. Do not silently mark the task `done` (that is what happened to TASK-033), and do not invent a stricter gate just to have something to pass.

**Never pass `--force`** — it is the human's override (CONTRACT#rules/gate-discrimination, obligation 2). A vacuous gate you force past ships this task unverified while reading as verified, which is the exact failure the probe exists to stop.

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

#### Checkpoint tasks

When the selected task's Type is `checkpoint`, execution produces no code. It assembles the **review packet** for the span this checkpoint closes, presents it, and stops (CONTRACT#interfaces/command-forge-next, Checkpoint tasks). `.forge/templates/checkpoint.md` drives the assembly; what follows is what this command guarantees around it.

**The span is exactly the task IDs in the checkpoint's `Depends` field.** Do not reconstruct it from `git log`, and do not take it as "everything since the last checkpoint" — `/forge-plan` already recorded the span in `Depends` (CONTRACT#rules/checkpoint-cadence), and a re-derived span quietly omits or over-claims tasks. Read each one through the projection, `node .forge/scripts/wp.js get TASK-XXX`.

The packet contains, in order:

1. **The span's tasks** — ID, description, and file list for each. The file list is the `Files:` line in the task's Notes when the notes are inline, or the `## Files` section of `.forge/notes/TASK-XXX.md` when the Notes name a record.
2. **Fresh gate results.** Re-run every automated gate in the span now, at packet-assembly time, and report each with its **actual output** rather than a bare pass/fail (SPEC#requirements/req-checkpoint-fresh-gates). Task status is not evidence: a later task in the span can break an earlier task's gate, and catching that is the reason this checkpoint exists.
   - A gate that fails fresh on a task whose status is `done` is a **regression** — flag it explicitly. `done` already means the gate passed at completion (step 8 marks `done` only after a pass), so nothing needs to have stored the earlier result.
   - **A span containing a regression is never summarized as clean.** One regression outranks any number of passes in the summary line.
   - Gates whose value begins with `manual:` are **listed with their verification steps, not executed.** Running them is the human's job at this checkpoint.
3. **STATUS.md, quoted into the packet.** Open Questions (all rows, flagging any marked Blocking), Risks (all rows), open Observations with `foundation` severity first, and any Decisions entry dated inside the span. Quote the rows and entries — a packet that sends the human to a file to find out what happened is defective (CONTRACT#data-model/status.md-data-model).
4. **The rollback.** Name the span's starting commit and the single command that undoes the span, and say plainly that it discards the span's work. The human runs it; you never do.

**The checkpoint's own gate is always `manual:`.** Step 7 runs no shell command for it — present the packet, end with "Does this checkpoint pass? (pass/fail)", and **stop**. Do not select further work, do not mark the task `done`, and do not commit before the human answers. A checkpoint is a hard stop for the unattended loop (CONTRACT#rules/unattended-execution, hard stop 4): an unanswered packet halts every downstream task by construction, which is the checkpoint working rather than a stall.

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
- **`checkpoint` tasks always take this branch** — their gate is `manual:` by construction, and what gets presented is the review packet from step 6, ending in "Does this checkpoint pass? (pass/fail)".

### 8. Handle the result

**Recording observations produced during execution:** Regardless of which branch below applies, check whether anything noticed during execution was out of scope for this task (CONTRACT#data-model/status.md-data-model, Observations). The governing test: if the fix was covered by this task's gate and belonged in this task's diff, you already made it — no observation needed. Otherwise:

- **One line per observation.** A pointer, not a report.
- **Never promote one to a task.** Observations never spawn `clarify` or `investigate` tasks — only a human does that, later, at a checkpoint or ad hoc.
- **More than three from this task collapse into one.** If execution surfaced more than three separate candidates, don't append four-plus rows — write a single `foundation`-severity row instead. Volume of small complaints is itself the signal that the foundation is wrong, and recording it as volume buries that signal.
- **`foundation` severity** means the spec, contract, or approach is suspect and continuing to build compounds debt (this is also what feeds CONTRACT#rules/unattended-execution hard stop 4 for the *next* session). Everything else is `normal`.
- **Determine the next ID** — `OBS-XXX` where `XXX` is `max(existing OBS ids in .forge/STATUS.md) + 1`.
- **Append directly to `.forge/STATUS.md`'s Observations table.** STATUS.md is hand-edited markdown, not projected through `wp.js` — that access discipline is specific to WORKPLAN.md (CONTRACT#rules/workplan-access-discipline) and does not extend here:

  ```markdown
  | OBS-XXX | TASK-XXX | design/bug/scope/... | normal or foundation | One-line observation. | open |
  ```

If execution produced nothing worth logging, skip this — most tasks generate no observations, and that is the expected case, not a gap to fill.

**Gate passes:**

1. Mark the task `done`:

   ```bash
   node .forge/scripts/wp.js set TASK-XXX status done
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

**3 lines or fewer** — it stays inline. Append it to the task's Notes field, with the file list as a `Files:` line:

```bash
node .forge/scripts/wp.js append-notes TASK-XXX 'Fixed the off-by-one in the slug matcher; no deviations.'
node .forge/scripts/wp.js append-notes TASK-XXX 'Files: .forge/scripts/lib/markdown.js, .forge/tests/test-markdown.sh'
```

which leaves the workplan reading:

```markdown
- **Notes:** Fixed the off-by-one in the slug matcher; no deviations.
  Files: .forge/scripts/lib/markdown.js, .forge/tests/test-markdown.sh
```

`append-notes` preserves whatever the Notes field already held and indents the addition as a continuation line, so existing content is never clobbered. A separate file for a one-line note is churn, not structure.

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

Then replace the task's Notes field with a **one-line summary plus the record path** (`set`, not `append-notes` — the summary supersedes whatever was there):

```bash
node .forge/scripts/wp.js set TASK-029 notes 'Implemented SPEC# resolution; one deviation on req-slug matching. Record: .forge/notes/TASK-029.md'
```

which leaves the workplan reading:

```markdown
- **Notes:** Implemented SPEC# resolution; one deviation on req-slug matching. Record: .forge/notes/TASK-029.md
```

**The summary is load-bearing.** A bare pointer relocates the problem instead of solving it: an agent that cannot tell what a record contains either opens it every time (no savings) or never opens it (information lost). The summary must name what is inside — the deliverable, and whether there are decisions or deviations worth reading. `Record: .forge/notes/TASK-029.md` alone is not acceptable output.

**Records must stand alone without git.** Forge runs against projects where `.forge/` is never committed, so `git log --grep` retrieves nothing about tasks and the record is the only archaeological artifact. A record that says "see the commit message" or "see the diff" is defective — write what the commit would have said, in the record.

**Task is blocked (cannot proceed):**

If during execution you determine the task cannot proceed — a dependency is missing, a Contract section is ambiguous, or the task requires human decisions that aren't available:

1. Mark the task `blocked`:

   ```bash
   node .forge/scripts/wp.js set TASK-XXX status blocked
   ```
2. Record what is blocking and what needs to happen to unblock, via `node .forge/scripts/wp.js append-notes TASK-XXX '...'`.
3. Suggest a `clarify` or `fix` task if appropriate.

**Checkpoint fails (the human failed the span):**

1. Mark the checkpoint `blocked`. The span did not pass, and leaving it `active` would keep the one-active-task constraint from letting any `fix` task run:

   ```bash
   node .forge/scripts/wp.js set TASK-XXX status blocked
   ```
2. Append a row to `.forge/STATUS.md`'s Blockers table naming what failed, which tasks it blocks, and what has to happen to clear it (CONTRACT#data-model/status.md-data-model — `/forge-next` is the named writer of this table):

   ```markdown
   | What failed at the checkpoint | TASK-XXX, TASK-YYY | What has to happen to pass the span |
   ```
3. Record what the human directed — `fix` tasks, a workplan edit, or a rollback — via `node .forge/scripts/wp.js append-notes TASK-XXX '...'`.
4. **Do not add the `fix` tasks yourself.** A failed checkpoint produces them (CONTRACT#rules/checkpoint-cadence), but the human writes them into the workplan, the same way an observation only ever becomes work through a human. The checkpoint returns to `pending` once they say it is ready to re-run.

**Gate fails / Task incomplete:**

1. Keep the task `active` (do not change status).
2. Append to the task's `Notes` field with `node .forge/scripts/wp.js append-notes TASK-XXX '...'`:
   - What was accomplished
   - What remains to be done
   - Any decisions made or blockers encountered
3. Report the current state to the user.
4. The human will commit partial progress or stash, then run `/clear`.

**Workplan lint:** Whichever branch above applies, every `wp.js` mutation re-runs `node .forge/scripts/check-workplan.js` and reverts itself if the lint fails, so a nonzero exit from `wp.js` means the write did not stand. Diagnose the reported violation, fix it, and re-run the mutation until it exits 0 before reporting to the user.

## Constraints

- **Projection, not reading.** Workplan state arrives through `.forge/scripts/wp.js` and changes go back through it. Opening `.forge/WORKPLAN.md` to read it, or editing it by hand, defeats the access discipline this command exists to keep (CONTRACT#rules/workplan-access-discipline). Editing the file directly is still the human's prerogative — it stays plain markdown — but it is not yours.
- **One active task at a time.** Exactly 0 or 1 tasks may have status `active`. Do not activate a new task while another is active; `wp.js` enforces this on both selection and write.
- **Context budget.** Resolved context should not exceed ~200 lines of Contract content per task.
- **Contract is read-only.** Do not modify CONTRACT.md unless the human explicitly approves.
- **Notes are continuity.** When resuming an active task, the Notes field is your only link to previous sessions. Read it carefully before starting work.
- **Records are the durable narrative.** WORKPLAN.md holds the DAG; `.forge/notes/TASK-XXX.md` holds everything else. Records are read only when a task declares one in its Context field (`notes/TASK-XXX#section-name`) — never open `.forge/notes/` on your own initiative.
- **No auto-commit.** Suggest a commit message but never commit automatically. The human is the final gate.
- **Template drives execution.** After step 5, the filled template's instructions govern what you do. The template includes its own completion protocol — follow it.
