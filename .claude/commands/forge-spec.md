# /forge-spec

Turn raw planning input into a behavioral spec — `.forge/SPEC.md` or `.forge/specs/<feature>.md` — by interviewing first and drafting second.

`$ARGUMENTS` is the planning input: raw idea text, a pasted ticket, or a file reference. If it names a file, read that file and treat its contents as the input. If `$ARGUMENTS` is empty, ask the user what they want specced before doing anything else.

**The interview is the point of this command.** A question you do not ask becomes an assumption, and an assumption in a spec propagates into every task `/forge-plan` generates from it. Drafting from unstated assumptions is the failure this command exists to prevent — a fast draft that skipped the interview is worse than no draft, because it looks finished.

This command is **idempotent** on the artifact: re-running it against an existing spec extends and revises it rather than replacing it.

## Steps

### 1. Read context

Read, in this order:

- **`$ARGUMENTS`** — the planning input, in full. This is the primary source; everything below is the frame it lands in.
- **`.forge/VISION.md`** — What, Who, Pillars. Tells you whose problem this is and what the project refuses to become.
- **`.forge/CONTRACT.md`** — all sections. The Contract states the hard constraints the spec must live inside.
- **`.forge/SPEC.md`** and **`.forge/specs/*.md`** (if they exist) — what is already specced, so you extend rather than duplicate or contradict.
- **`.forge/STATUS.md`** — Open Questions (an unknown may already be logged), and Decisions (a question already settled must not be re-asked as if open).

If `.forge/CONTRACT.md` does not exist, stop and tell the user to run `/forge-init` first.

**Boundary check while reading** (CONTRACT#data-model/spec-data-model): CONTRACT.md owns hard constraints — data shapes, interfaces, invariants, state machines. SPEC.md owns behavior — requirements, acceptance criteria, flows, rationale. The spec references Contract concepts by name; it never restates or redefines them. If the input implies a change to a data shape, an interface, or an invariant, that is Contract work, and it is not yours: note it for the report in step 7. **This command never writes or modifies CONTRACT.md.**

### 2. Choose the target file

- No `.forge/specs/` directory and `.forge/SPEC.md` under ~300 lines → target is `.forge/SPEC.md`.
- `.forge/SPEC.md` already over ~300 lines, or `.forge/specs/` already exists → target is `.forge/specs/<feature>.md`, where `<feature>` is a short slug naming the feature (`auth`, `billing`). Tasks will reference it as `specs/<feature>#requirements`.
- The input clearly describes one bounded feature and the project already splits per feature → use the per-feature file even if SPEC.md is short.

Tell the user which file you are targeting before the interview, not after — the choice changes how broadly you scope the questions.

### 3. Run the intake interview — before drafting

Ask the clarifying questions a senior engineer would ask before writing a line of this spec. Five categories must be **covered** before you draft (SPEC#requirements/req-intake-coverage):

| Category              | What it resolves                                                                  |
| --------------------- | --------------------------------------------------------------------------------- |
| **Target user**       | Who has this problem, and in what situation. Not a persona label — a real seat.   |
| **Success criteria**  | What observably changes when this works. The thing a gate could later assert.      |
| **Edge cases**        | Empty, huge, concurrent, malformed, offline, permission-denied — whichever apply.  |
| **Integration points** | What this touches: existing interfaces, external services, data already in flight. |
| **Non-goals**         | What this deliberately excludes. The scope creep you are pre-committing to refuse. |

**Coverage is adaptive, not a checklist.** Each category is resolved by exactly one of:

1. **A specific passage of the input.** Quote it to yourself — a general impression of the input does not resolve a category. If you cannot point at the sentence that answers it, it is unresolved.
2. **An interview answer** from the user.

A category the input already answers is **not re-asked**. Asking a question whose answer is verbatim in the input is ceremony, not diligence, and it trains the user to stop reading your questions carefully. State what you took from the input and move on: "Target user: on-call engineers paging through alerts at 3am — taken from your second paragraph."

**How to ask:**

- Batch the questions. One message with the open questions grouped by category, not five round trips.
- Ask what you cannot infer. Never ask what the Contract already answers.
- Where you have a defensible default, propose it rather than asking open-endedly: "Non-goal — I'm assuming no bulk import in v1. Correct?" A question with a proposed answer is cheap for the user to process; an open question is not.
- If the user answers some questions and ignores others, ask the remainder once more. If they decline again, carry those as unresolved unknowns (step 5) rather than guessing.

**Drafting begins only after every category is resolved, or explicitly carried as an unresolved unknown** with an annotation and a STATUS.md row. There is no third state — a category you neither resolved nor recorded is an assumption you smuggled in.

### 4. Draft the spec

Write the target file per the SPEC Data Model (CONTRACT#data-model/spec-data-model):

```markdown
# Spec

## Overview

<!-- What this feature/system does, in one paragraph. Why it exists. -->

## Requirements

### [req-slug] Requirement Name

<!-- EARS-style statement: WHEN <trigger>, THE SYSTEM SHALL <response>. -->
<!-- Acceptance criteria: bullet list, each independently testable. -->

## Flows

<!-- Behavioral sequences that span requirements. References UX.md screens where applicable. -->

## Non-Goals

<!-- What this spec deliberately excludes. Prevents scope creep during execution. -->
```

**Requirements** are the substance. Each one gets:

- A heading `### [req-slug] Requirement Name`. The bracketed slug is what task manifests reference as `SPEC#requirements/req-slug` — keep it short, stable, and unique within the file. Never leave the literal `[REQ-slug]` placeholder text; `/forge-plan` reads that as an unedited stub and treats the file as having zero requirements.
- An **EARS-style statement**: `WHEN <trigger>, THE SYSTEM SHALL <response>`. One trigger, one response. If you need "and" between two responses, that is two requirements.
- **Acceptance criteria** as a bullet list, each bullet independently testable. "Fast" is not testable; "returns within 200ms at p95" is. These bullets are what a task's gate will later assert against, so write them as things a check could pass or fail.

**Non-Goals** are not optional filler. Every non-goal the interview surfaced goes here, in the user's terms. This section is what stops a downstream `feature` task from quietly widening.

**Flows** cover behavior that spans requirements — the sequence, not the pieces. Reference `UX.md` screens by name where the project has them. Omit the section's content if the spec has no cross-requirement sequences; keep the heading.

When revising an existing spec, preserve requirement slugs that already exist — a slug is an address, and task manifests point at it.

### 5. Annotate every inference and every unknown

Two markers, two different meanings (CONTRACT#interfaces/command-forge-spec):

- `<!-- ASSUMED: reason -->` — you inferred something the input did not state and the user did not confirm, and you are proceeding on it. The reason is the justification, not a restatement: `<!-- ASSUMED: matches the existing session timeout in CONTRACT#rules/auth -->`, not `<!-- ASSUMED: seems right -->`.
- `<!-- UNRESOLVED: ... -->` — you could not resolve it, asking did not settle it, and no defensible default exists. The spec carries the hole visibly rather than papering over it.

Annotate at the point of use — beside the requirement, criterion, or flow step it affects. A marker collected in a list at the bottom of the file is invisible to the agent reading one `SPEC#requirements/req-slug` section.

Do not use these markers to launder a question you simply did not ask. That is what step 6 checks.

### 6. Record unresolved unknowns in STATUS.md, then re-check for disqualification

**Every `<!-- UNRESOLVED -->` marker gets a row** in `.forge/STATUS.md` Open Questions (CONTRACT#data-model/status.md-data-model). Determine the next ID as `Q-XXX` where `XXX` is `max(existing Q ids) + 1`, and append:

```markdown
| Q-XXX | The question, stated so someone else could answer it without re-reading the spec. | Yes or No | YYYY-MM-DD |
```

`Blocking?` is `Yes` when the unknown is **plan-blocking** — resolving it differently would change which tasks exist, their order, or their gates (the same classification `/forge-plan` applies in its unknown check). `No` when it only affects how one task executes internally.

STATUS.md is hand-edited markdown — append to it directly.

**Then apply the disqualification check** (SPEC#requirements/req-intake-disqualification), before you show the draft to anyone:

> Is there a plan-blocking unknown that was neither asked about during the interview nor annotated in the draft?

If yes, **withhold the draft**. Do not present it, do not describe it as complete, do not offer it "with caveats." Go back to step 3, ask the questions you missed, and draft again with the answers. A disqualified draft presented anyway is the exact failure mode this command exists to prevent: it looks finished, so nobody looks harder.

Implementation-detail unknowns never disqualify a draft — they carry `<!-- ASSUMED: reason -->` and move on. Only plan-blocking ones do.

### 7. Run the readiness gate

```bash
node .forge/scripts/check-spec.js .forge/SPEC.md
```

(or the per-feature path you targeted in step 2).

`check-spec.js` is deterministic and structural. Fix every failure it reports and re-run until it exits 0:

- **Missing section** — add it. Overview, Requirements, and Non-Goals are all required.
- **No requirement headings** / **empty or placeholder-only requirement** — a requirement whose body is nothing but HTML comments is a stub, not a requirement. Write it or delete it.
- **No acceptance criteria** — at least one requirement needs an "Acceptance criteria" line followed by a bullet list. In practice every requirement should have one.
- **Placeholder text (TODO/TBD)** — resolve it or convert it into a proper `<!-- UNRESOLVED: ... -->` marker with a STATUS.md row.

**Unresolved markers are the one failure you do not fix by editing.** The script fails on any `<!-- UNRESOLVED -->` by default, and deleting a marker to make the gate pass destroys the record of the hole — the opposite of what step 5 is for. Instead: confirm each marker has its STATUS.md Open Questions row from step 6, then re-run with the count you are deliberately carrying:

```bash
node .forge/scripts/check-spec.js .forge/SPEC.md --max-unresolved 2
```

Report that count in step 8. Carrying unknowns is a decision the human is making, so it has to be visible to them; a silently passing gate would hide it.

### 8. Report and hand off

Tell the user:

- **Which file** was written, and whether it was created or revised.
- **Requirements added**, by slug and name — these are the addresses task manifests will use.
- **What you assumed**: every `<!-- ASSUMED -->` marker, one line each. This is the list most worth their attention, because each entry is something they never actually said.
- **What is unresolved**: every `<!-- UNRESOLVED -->` marker with its `Q-XXX` id, flagged plan-blocking or not.
- **Any Contract work you noticed** in step 1 — where the input implied a change to a data shape, interface, or invariant. Name it; do not act on it.
- **Gate result**, including the `--max-unresolved` count if you used one.

Then say:

> **Review the spec before running `/forge-plan`.** Check the assumptions above first — each one is a decision made on your behalf. `/forge-plan` treats a requirement with an unresolved plan-blocking question as a coverage gap, so resolve those rows in STATUS.md, or expect a `clarify` task for each.

## Constraints

- **Interview before draft.** Not during, not after. The five categories are covered before the first requirement is written.
- **Adaptive, not ceremonial.** A category the input already answers is not re-asked — but "the input feels like it covers this" is not coverage. Point at the passage.
- **Never writes or modifies CONTRACT.md.** Contract changes are the human's call, and `/forge-plan` is where coverage gaps get drafted. This command writes the spec file and appends STATUS.md Open Questions rows — nothing else.
- **Contract wins on conflict** (CONTRACT#rules/spec-precedence). If a requirement you are about to write contradicts a Contract section, do not resolve it in the spec's favor. Write the requirement to match the Contract, and log the conflict as an Open Question.
- **Markers are load-bearing.** `ASSUMED` and `UNRESOLVED` are how downstream tasks find out what was never actually decided. Stripping one to make a gate pass is a defect.
- **No task generation.** This command produces a spec. `/forge-plan` turns it into work.
