# Design: Template Drift & forge-init

## 1. Template drift

### Problem

Template content is defined inline in `forge-plan.md` and written to `.forge/templates/` once on first run. `forge-next` reads templates from disk at execution time. Because `forge-plan` never overwrites existing files, improvements made to templates in `forge-plan.md` do not propagate to projects that have already been bootstrapped. Projects silently diverge from upstream.

The secondary drift direction — users editing local template files — is actually desirable (per-project customization), but the current design makes no distinction between intentional local overrides and stale upstream copies.

Critically, the current design is the worst of all worlds from a token perspective: all 6 templates are embedded in `forge-plan.md` and therefore loaded into context on **every** `/forge-plan` run — not just the first. The templates are then written to disk as drift-prone copies, and `forge-next` pays additional overhead reading one template per task execution. The 6-template cost is paid repeatedly across the workflow rather than once.

### Options considered

| Option                                 | How it works                                                                     | Drift                                                    | Per-project customization              | Token overhead                                             |
| -------------------------------------- | -------------------------------------------------------------------------------- | -------------------------------------------------------- | -------------------------------------- | ---------------------------------------------------------- |
| **Status quo**                         | Templates in forge-plan.md, written once to disk, read by forge-next             | Upstream changes don't propagate                         | Yes, by editing local files            | 6 templates on every forge-plan run + 1 per forge-next run |
| **Inline into forge-next**             | All templates embedded in forge-next.md, disk files removed                      | None                                                     | No                                     | 6 templates on every forge-next run                        |
| **Overwrite on forge-plan rerun**      | forge-plan always overwrites template files                                      | Resolved on rerun                                        | Fragile — rerun wipes local edits      | 6 templates on every forge-plan run + 1 per forge-next run |
| **Convention over configuration**      | Templates embedded in forge-next.md as defaults; local file overrides if present | None                                                     | Yes, by creating a local override file | 6 templates on every forge-next run                        |
| **Move to forge-init** _(recommended)_ | Templates in forge-init.md, written once to disk, read by forge-next             | Low — forge-init is run once and templates rarely change | Yes, by editing local files            | 6 templates once per project lifetime                      |

### Recommended approach

Move template definitions into `forge-init.md` and remove them from `forge-plan.md` entirely. Templates are written to disk on project setup and read individually by `forge-next` at task execution time.

- The 6-template overhead is paid exactly once per project (forge-init), not on every planning or execution run
- `forge-plan` becomes lean — no template content at all
- `forge-next` reads one template per task, as today
- Per-project customization is preserved — local files can be edited freely
- Drift risk is low in practice: `forge-init` runs once and templates only go stale if forge itself is updated, which is infrequent once stable
- Refresh procedure when templates do change upstream: delete `.forge/templates/` and rerun `/forge-init`

Convention-over-configuration (embedding in `forge-next`) was considered but rejected for cost-conscious users: `forge-next` runs once per task, so embedding all 6 templates there multiplies the overhead across every task execution — strictly worse than paying it once at init time.

---

## 2. forge-init command

### Problem

`forge-plan` currently conflates two unrelated responsibilities:

1. **Scaffolding** — one-time creation of VISION.md, CONTRACT.md, CLAUDE.md, settings.json, and template files
2. **Planning** — Contract-First validation and WORKPLAN.md generation

On first run these happen together, which is convenient. On every subsequent run, the full scaffold logic and all template content load into context unnecessarily. For a mature project running `/forge-plan` to replan a small feature, the overhead is significant relative to the actual work being done.

### Proposed split

| Command       | Responsibility                                          | When run                                |
| ------------- | ------------------------------------------------------- | --------------------------------------- |
| `/forge-init` | Scaffold project files; never overwrites existing files | Once, at project setup                  |
| `/forge-plan` | Contract-First check; generate/update WORKPLAN.md       | Repeatedly, whenever planning is needed |

### Benefits

- `forge-plan` becomes focused and lean — no scaffold logic, no template definitions
- `forge-init` is a clear entry point for new projects; its single-run nature is explicit in the name
- Aligns with the pitfalls finding that command file size directly affects context overhead on every invocation
- `forge-init` is the optimal home for templates: the 6-template overhead is paid once at setup rather than repeatedly across planning and execution runs. `forge-plan` stays lean for frequent replanning; `forge-next` reads one template per task — the most token-efficient arrangement possible

### Tradeoffs

- One additional command to distribute and document
- Existing projects bootstrapped with the current `forge-plan` are unaffected (scaffold already ran), but `forge-init` won't exist for them — low impact since they don't need it
- The "first-run detection" logic in `forge-plan` can be removed entirely, simplifying the command

### Changes required

1. **Create `.claude/commands/forge-init.md`** — extract all scaffold logic from `forge-plan` step 2: VISION.md, CONTRACT.md, CLAUDE.md, settings.json, and all 6 templates. Add a clear completion message directing the user to fill in VISION.md and CONTRACT.md, then run `/forge-plan`.

2. **Simplify `forge-plan.md`** — remove step 2 (first-run scaffold) entirely. Remove the first-run/subsequent-run detection in step 1. The command always assumes scaffold has run and proceeds directly to reading context and validating/generating the workplan.

3. **Update `forge-next.md`** — add override check in step 5: read `.forge/templates/{type}.md` if present, otherwise use built-in template content. Embed all 6 template definitions as built-in fallbacks.

4. **Update distribution guidance** — the bundle is now: `.claude/commands/` (4 files) + `CLAUDE.md` merge. No `.forge/` files need to be distributed; `forge-init` creates them all.
