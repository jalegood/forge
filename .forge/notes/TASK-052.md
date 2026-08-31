# TASK-052 — Investigate node-schema model for Forge's own machinery

## Outcome

**No-go for v0.4.** The schema was written and Forge's machinery re-expressed in it: the deterministic tier fits cleanly, the task types fit as blueprints, and **five escape hatches** are required to describe the rest — two of them covering the mechanisms this run spent most of its effort building. The brainstorm proposed exactly this test and named the failure condition itself: "If describing forge in it requires escape hatches, you've learned that for the price of a YAML file." It did. Two ideas from the exercise survive and are worth keeping without any schema.

## The test as run

Schema fields per the brainstorm: `id`, `consumes`, `produces`, `power` (script/ai/human), `mutates`, `gate`, `tags`. Re-expressed: 16 item types, 8 scripts, 3 commands, 3 representative task types. Throwaway YAML written and discarded; the findings are the deliverable.

## What fit

- **The deterministic tier fits cleanly.** Every script is an honest function over items: `check-workplan :: Workplan -> GateResult`, `wp-select :: Workplan -> Task`, `obs-add :: Observation -> Status (mutates Status)`. No strain anywhere.
- **`resolve` is the real primitive the brainstorm predicted.** `(Manifest, Contract, Spec, UX, Design) -> ResolvedContext`, budget-capped and deliberately lossy, is a genuinely general operation currently buried inside step 3 of one command. This is the single most valuable observation the exercise produced, and it needs no schema to act on.
- **Task types fit as blueprints.** `feature`, `fix`, `scaffold` are clean `(ResolvedContext, Template) -> Diff` nodes with a gate spec.

## The five escape hatches

1. **`/forge-next` is not a node; it is a seven-step pipeline** (sweep → report → select → resolve → activate → execute → gate → record) spanning all three power sources. One node with `power: ai` is a lie; seven nodes is a graph larger and less legible than the prose it would replace.
2. **`power` cannot be a single value.** `clarify` is AI-drafts → human-decides → AI-applies. So is `checkpoint`, and so is every `manual:` gate. Mixed power inside one unit is Forge's common case, not its edge case — which is notable, because `power` was supposed to be the schema's *load-bearing* field.
3. **The gate-discrimination probe has no slot.** The schema's `gate` validates what a node produced. The probe validates that the gate *would fail* before the node runs — a second-order precondition evaluated at a state transition, not on any item. Forge's most novel mechanism (TASK-074) is invisible to the model.
4. **The foundation halt is a global interrupt, not an edge.** Any selection can be refused by state the node does not consume. Writing `consumes: [Status]` on every node would misdescribe it: the node does not read STATUS.md, the *runner* does, and the result is a halt rather than a transformation.
5. **Rework is a cycle**, as the brainstorm predicted. A DAG over task instances grows at runtime, which makes it an append-only event log wearing a DAG costume.

Escape hatches 3 and 4 are the decisive ones. They are not awkward corners — they are the two mechanisms that make unattended execution safe, and they are precisely what a "generic runner over the schema" would have to special-case. An abstraction that cannot express the safety machinery is not the abstraction for a pipeline whose whole value is safety machinery.

## What survives, and is worth keeping

- **`mutates` as a documentation discipline, not a schema field.** Writing it out immediately exposed that `/forge-plan` mutates three artifacts while its own prose claimed "no side effects beyond WORKPLAN.md" — the exact defect TASK-077 fixed independently this run. Every command's Outputs line should name every artifact it writes. Worth a Contract rule; not worth a runtime.
- **Power source as a lens, already owned.** "Push work down the cost ladder as confidence rises" is Vision pillar 2 restated. It needs no new dimension — this run moved three things down that ladder (the gate probe, the status lint, the observation writer) without any schema.

Both are free. The runner, the item catalog, and the plant graph are not, and the two ideas do not depend on them.

## Recommendation

Do not build the node schema, the generic runner, the item catalog, or the plant graph in v0.4. Extract `resolve` as a shared primitive if a second consumer ever appears — not before, because one caller is not an abstraction. Revisit only if a second pipeline exists to describe; a model of one system is that system with extra indirection, which is the abstraction-bloat failure mode `claude-code-workflow-pitfalls.md` names and the brainstorm itself conceded.

## Files

No repository files changed — investigation only. The throwaway YAML was written to a scratch directory and discarded, as scoped.
