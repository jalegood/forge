# Feature Spec: UX Pipeline Extension

## Problem

> _"The 'out of the box' UX design skill lacks that certain something… The spec has column-level
> detail on database tables. The UX spec needs the same level of detail for every screen — states,
> copy, micro-interactions, transitions. I'm looking at it from the perspective of wanting a
> lightweight reusable tool, like Forge, to do the work of capturing all of the important aspects
> of the UX by identifying flows and designing the user journey."_

Forge's CONTRACT.md enforces engineering precision — column-level data models, typed interfaces,
explicit state machines. There is no equivalent for experience. Without a specced artifact,
AI-generated UI defaults to generic: "show a timer" produces a text label; "button navigates
forward" produces a tap target with no motion, no copy voice, no considered feel. The problem is
not implementation quality — it is specification depth. Vague specs produce average output. The
goal is a lightweight, reusable UX contract layer that forces screen-level specificity before any
implementation task begins, without prescribing app-specific structure onto every project.

---

## Design Constraints

- **One new task type only.** `ux-spec` for the design phase. Implementation uses the existing
  `feature` type with a UX context manifest.
- **No app-specific scaffolding in the format.** No haptic palettes, motion principle templates,
  or fixed dimension columns. Different apps have different sensory dimensions; the agent
  identifies which ones apply per screen.
- **Persona-led, not form-led.** The `ux-spec` template asks the agent to reason as a UX
  designer and identify what matters, rather than fill prescribed columns.
- **Two mandatory fields only.** `Emotional intent` and `Design intention` are required on every
  screen regardless of app type. Everything else is agent-determined.
- **Gate stays structural.** Checks for non-empty mandatory fields and absence of placeholder
  language. No external scripts.

---

## Data Model — UX Artifact

### Artifacts (additions)

| Artifact    | Path                              | Owner                  | Purpose                                                         |
| ----------- | --------------------------------- | ---------------------- | --------------------------------------------------------------- |
| UX Spec     | `.forge/UX.md`                    | Human (70%) / AI (30%) | Screen-level experience spec: flows, states, copy, interactions |
| Gate script | `.forge/scripts/check-ux-spec.js` | Forge                  | Deterministic `ux-spec` gate — validates one screen by name     |

### Relationships

- UX.md is authored during `ux-spec` tasks and consumed by `feature` tasks via context manifest.
- UX.md references CONTRACT.md for data shapes and system state machines. It does not duplicate
  them.
- CONTRACT.md defines what the system does. UX.md defines what the user experiences.
- `/forge-plan` reads UX.md alongside VISION.md and CONTRACT.md when generating tasks.
- `/forge-init` creates a stub UX.md with placeholder sections.

### Context Manifest Syntax

```
UX#flows/flow-name/screen-name     — one screen spec
UX#flows/flow-name                 — full flow including all screens
UX#global                          — global copy tone and style notes
```

**Budget:** Same as CONTRACT sections — resolved UX context must not exceed ~200 lines per task.
One screen per task.

---

## Data Model — UX.md Structure

```markdown
# UX Spec

## Global

### Copy Tone

<!-- Voice and energy rules that apply to every screen.
     Be specific: name what's in bounds and what's out of bounds.
     Example: "Active states: imperative and brief. 'Go.' not 'Begin your set.'
               Errors: calm, never alarming. Never use 'failed' — use 'couldn't'." -->

### Style Notes

<!-- Optional. Any global interaction or aesthetic principles that apply across flows.
     Only include what's genuinely global. Screen-specific decisions belong on the screen. -->

## Flows

### Flow: [Name]

**Entry:** [Screen + trigger]
**Exit:** [Screen(s) + condition]
**Emotional arc:** [e.g., anticipation → focus → satisfaction]

#### Screen: [Name]

**Purpose:** <!-- One sentence: what does this screen accomplish for the user? -->
**Emotional intent:** <!-- What should the user FEEL at this moment? Be specific. -->
**Design intention:** <!-- What makes this screen feel considered rather than default? This could
                         be an interaction that subverts convention, or simply the obvious solution
                         executed with unusual precision — exact copy, the right weight of feedback,
                         a transition that matches the emotional beat. Name the specific decision
                         that elevates this screen above a generic implementation. -->

##### States

| State         | Trigger                         | Experience                                                                                                                                                                                |
| ------------- | ------------------------------- | ----------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------- |
| <!-- name --> | <!-- what causes this state --> | <!-- What does the user see, hear, feel? Include any values that govern timing, physics, or sensation numerically. The agent determines which dimensions are relevant to this screen. --> |

##### Edge Cases

| Condition                               | Behavior |
| --------------------------------------- | -------- |
| Empty / first-time                      |          |
| Error                                   |          |
| <!-- others relevant to this screen --> |          |
```

---

## Interfaces — New Task Type

### Task Type: `ux-spec`

**Purpose:** Author or complete a screen spec in UX.md. Produces no code.
**Input:** Partially filled UX.md section (or stub from forge-init).
**Output:** Fully specced screen — mandatory fields complete, all States rows complete, all
relevant Edge Cases handled, no placeholder language.
**Default gate:** Structural completeness check (see Gate Patterns).
**Template:** `.forge/templates/ux-spec.md`

Template instructions:

1. **Adopt a UX designer perspective.** Before writing anything, identify which experiential
   dimensions are relevant to this specific screen: motion, copy, layout hierarchy, feedback
   (visual, audio, haptic), empty states, accessibility, transitions. Only spec the dimensions
   that apply. Do not import assumptions from other app types.
2. **Fill `Emotional intent` first.** The feeling the user should have governs every other
   decision. Name the feeling precisely — not "good" or "engaged" but "the relief of handing
   something off" or "the momentum of a streak continuing."
3. **Fill `Design intention`.** Name the specific decision that makes this screen feel considered
   rather than default. This does not require novelty — the obvious solution executed with unusual
   precision qualifies: exact copy, the right weight of feedback, a transition that matches the
   emotional beat. It cannot be left vague, and "it follows standard patterns" is not an answer.
4. **Write copy in the spec, not in the code.** Every piece of user-visible text appears in
   the States table or a copy note on the screen. Placeholder copy (`Label`, `Text here`) fails
   the gate.
5. **Specify any time, physics, or sensation values numerically.** "Smooth," "fast," "subtle"
   are prohibited. Use durations in ms, named easing functions, or explicit physics parameters.
   If a dimension has no measurable value (e.g., layout choice), describe it structurally.
6. **Complete Edge Cases.** At minimum: empty/first-time and error. Add others relevant to this
   screen. Empty rows fail the gate.
7. **Write no implementation code.**

---

## Interfaces — Command Changes

### `/forge-init` changes

- Creates `.forge/UX.md` if absent — stub with Global section (Copy Tone, Style Notes) and one
  placeholder Flow with one placeholder Screen, including all mandatory fields as HTML comments.
- Creates `.forge/templates/ux-spec.md`.
- Creates `.forge/scripts/check-ux-spec.js` (the gate script above).
- Never overwrites existing files (idempotent).
- On completion: tells user to fill in UX.md alongside VISION.md and CONTRACT.md before running
  `/forge-plan`.

### `/forge-plan` changes

- Reads `.forge/UX.md` when present, alongside VISION.md and CONTRACT.md.
- Coverage check: every screen referenced in a planned flow must have a `ux-spec` task gated
  `done` before its `feature` task is unblocked. Missing screen specs are plan-blocking.
- Generates a flow-mapping `ux-spec` task first when UX.md has flows but no screens: enumerate
  all screens before any are individually specced.
  Gate: `grep -c "^#### Screen:" .forge/UX.md | awk '$1 >= N'`
- Context manifests for `ux-spec` tasks: `UX#flows/flow-name` (the stub to complete).
- Context manifests for `feature` tasks implementing a screen: `UX#flows/flow-name/screen-name`
  plus any `CONTRACT#` sections for data shapes the screen consumes.

---

## Rules

### Gate Patterns (UX additions)

| Deliverable Type | Gate Strategy                                        | Example                                                                              |
| ---------------- | ---------------------------------------------------- | ------------------------------------------------------------------------------------ |
| UX spec (UX.md)  | Structural check: mandatory fields + no placeholders | See gate command below                                                               |
| Screen (feature) | `manual:` checklist derived from spec rows           | `manual: [ ] Empty state shows onboarding prompt [ ] Error names the retry action …` |

**`ux-spec` gate command:**

```bash
node .forge/scripts/check-ux-spec.js "Screen Name"
```

`/forge-plan` generates the correct screen name argument per task. The script lives at
`.forge/scripts/check-ux-spec.js` and is created by `/forge-init`:

```js
#!/usr/bin/env node
// Usage: node .forge/scripts/check-ux-spec.js "Screen Name"
const fs = require('fs');
const screenName = process.argv[2];
if (!screenName) { console.error('Usage: check-ux-spec.js "Screen Name"'); process.exit(1); }

const spec = fs.readFileSync('.forge/UX.md', 'utf8');
const escaped = screenName.replace(/[.*+?^${}()|[\]\\]/g, '\\$&');
const pattern = new RegExp(`#### Screen: ${escaped}([\\s\\S]+?)(?=\\n#### |\\n### |\\n## |$)`);
const section = spec.match(pattern)?.[1] ?? '';

if (!section) { console.error(`Screen not found: "${screenName}"`); process.exit(1); }

const bad = ['<!--', 'TBD', 'TODO', 'smooth', 'fast', 'subtle', 'specify'];
const missing = [];
if (!section.match(/\*\*Emotional intent\*\*:\s*\S/)) missing.push('Emotional intent');
if (!section.match(/\*\*Design intention\*\*:\s*\S/)) missing.push('Design intention');
if ((section.match(/\| .+ \| .+ \| .+ \|/g) ?? []).length < 2) missing.push('States rows');
bad.forEach(w => { if (section.toLowerCase().includes(w.toLowerCase())) missing.push('placeholder: ' + w); });

if (missing.length) { console.error('Spec incomplete:', missing.join(', ')); process.exit(1); }
console.log(`Spec complete: "${screenName}"`);
```

**`feature` gate for a screen implementation:**
The feature template, when given a context manifest containing `UX#` sections, must generate
the `manual:` gate description as a checklist: one item per States row (the most testable
aspect of the Experience cell) plus the Design intention. Every item references a specific spec
value — no vague language.

---

### UX-Spec-First

No `feature` task implementing a screen may be `active` unless its corresponding `ux-spec` task
is `done`. Enforced by the DAG: every screen `feature` task's `Depends` field must include its
`ux-spec` task ID. `/forge-plan` generates this dependency automatically.

---

### UX Spec Precision

Values that govern time, physics, or sensation are always numeric or reference a named pattern:

| ❌ Prohibited      | ✅ Required                            |
| ------------------ | -------------------------------------- |
| "smooth animation" | "ease-out 250ms"                       |
| "fast transition"  | "slide-up 300ms spring(0.8)"           |
| "subtle feedback"  | "opacity pulse 0→0.4→0 over 600ms"     |
| "feels snappy"     | "spring tension:180 friction:12 200ms" |

Prose is permitted only in Emotional intent, Design intention, and Copy Tone. All other cells that
involve measurable qualities are numeric or structured.

**Rationale:** The implementation agent translates spec cells to code constants. "Smooth" produces
an invented value. "ease-out 250ms" produces `ANIMATION.TRANSITION_DURATION = 250`. The spec
precision directly determines the implementation precision.

---

## Boundaries — What UX.md Does Not Own

- **System state machines** — valid states and legal transitions. CONTRACT.md owns these. UX.md
  describes their user-visible interpretation.
- **Data shapes** — field names, types, nullability. CONTRACT.md. UX.md references them.
- **Business rules** — what the system is allowed to do. CONTRACT.md. UX.md reflects their
  user-visible consequences.
- **API contracts** — endpoint shapes, response formats. CONTRACT.md.

When a `feature` task needs both the screen spec and a data shape:

```
Context: UX#flows/active-workout/active-set, CONTRACT#data-model/workout-session
```

Duplication between UX.md and CONTRACT.md is always wrong. One of them is out of date.

---

## Workplan Shape for a UX-Primary Feature

```
TASK-001: ux-spec   — Map all flows and screen inventory       (gate: screen count ≥ N)
TASK-002: ux-spec   — [Flow]: [Screen A]                       (Depends: TASK-001)
TASK-003: ux-spec   — [Flow]: [Screen B]                       (Depends: TASK-001)
TASK-004: ux-spec   — [Flow]: [Screen C]                       (Depends: TASK-001)
TASK-005: feature   — Implement [Screen A]                     (Depends: TASK-002)
TASK-006: feature   — Implement [Screen B]                     (Depends: TASK-003)
TASK-007: feature   — Implement [Screen C]                     (Depends: TASK-004)
```

TASK-002 through TASK-004 are independent and can run in parallel sessions.
Each `feature` task waits only for its paired spec — not for other screens.

All screens are fully designed before any are built. Mid-implementation design changes that
would cascade into already-shipped screens are structurally prevented.
