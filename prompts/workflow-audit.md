# Forge Workflow Audit

Forge is a contract-first pipeline for Claude Code: a human owns `.forge/VISION.md` and
`.forge/CONTRACT.md`, `/forge-plan` derives a task DAG into `.forge/WORKPLAN.md`, and
`/forge-next` executes one task per session. Read `.forge/VISION.md` first for the six
pillars — they're your standard for what counts as a smell (e.g. anything that makes a human
read more to make the same decision, or that depends on Claude following an instruction where
a script could enforce it instead).

## Ground truth, in precedence order

1. `.forge/CONTRACT.md` — structural constraints: command Reads/Does/Outputs, data shapes,
   state machines, invariants. Authoritative over everything below.
2. `.forge/SPEC.md` — acceptance criteria the Contract can't express as invariants.
3. `.claude/commands/*.md` — the five command implementations (forge-init, forge-spec,
   forge-plan, forge-next, forge-status). What actually runs.
4. `.forge/scripts/*.js` (+ `lib/`) — the deterministic gates (`check-workplan.js`,
   `check-spec.js`, `check-ux-spec.js`, `wp.js`, `migrate-notes.js`) and shared resolvers
   (`lib/markdown.js`, `lib/workplan.js`). What actually enforces.
5. `.forge/templates/*.md` — the eight task-type templates commands embed or scaffold from.
6. `.forge/STATUS.md` — the project's own running log: Open Questions, Decisions (with
   rejected alternatives — read these, they record why the obvious fix was rejected),
   Risks, Blockers, and an Observations table (OBS-001 through OBS-013) of defects already
   found by prior sessions.

**Read STATUS.md's Observations and Decisions tables before you start hunting.** Thirteen
issues are already logged with dispositions (accepted/declined/open). Don't spend budget
rediscovering those — note if any `open` ones are still unfixed, but your job is to find what
those sessions _didn't_ catch, not to re-report their findings.

## Task

For each of the five workflows (init, spec, plan, next, status), trace it end to end as if
you were executing it: what the command file says it reads/does/outputs, cross-checked
against what CONTRACT.md's Interfaces section claims for that command, against what the
scripts it invokes actually implement, and against the templates it touches. A workflow
"bug" here usually isn't a syntax error — it's a place where two of these layers disagree,
where a gate could pass without the condition it's supposed to verify (this pipeline has a
known pattern of vacuous gates — OBS-008, OBS-010, OBS-013 — check whether other gates share
the shape), or where a command's prose does work its Contract interface doesn't license.

Also flag smells against the six Vision pillars directly — e.g. a rule stated only in command
prose that should be a lint invariant (pillar 2), a command reading more context than its
task needs (pillar 4), duplication between CONTRACT/SPEC/command-prose that could drift
(pillar 3's git-is-memory only works if there's one source per fact).

Optimization opportunities are in scope but secondary to correctness — note them, don't chase
them at the expense of finding real discrepancies.

## Output

One finding per row: `workflow | file:line | bug/smell/optimization | severity | what's wrong
| how you'd confirm it`. Group by workflow. For anything you're not certain reproduces (like
the already-logged OBS-009, which didn't reproduce), say so explicitly rather than asserting
it as fact. End with a one-paragraph read on which workflow is weakest overall and why.
