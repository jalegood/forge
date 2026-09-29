# Factory Brainstorm Session

> User Prompt

```md
Help me brainstorm something. The general idea is thinking about software production as a factory, like in a sim game. Each piece of the software lifecycle is like a different machine that produces a different output. My mental model is like functional nodes, where each node is some specific "gear" in the software lifecycle machine with its own metadata and tags. These are abstract enough that they can be composed together in various shapes, where the "rules" are dictated by a DAG.
The project in context, forge, uses commands `/forge-plan` and `/forge-next` to iterate over a spec and other files to keep the documentation in order while executing tasks sequentially. I think this kind of resembles the node that I'm thinking about. It also has the "human in the loop" element that I like, but I think there's potential to step back even further and manage the factory instead of one machine.
```

---

I read through forge's contract, workplan, and commands — this is a better foundation for the idea than you're giving it credit for. Some threads:

## You already have one DAG. The factory is the other one.

Forge's WORKPLAN is a **work graph**: instances flowing through, `Depends` edges, topologically sorted, consumed once. Factory sims don't have that. What they have is a **plant graph**: machine types wired by port type, static, reused every tick. Iron plate fits any input that accepts iron plate.

Stepping back to "manage the factory" = making the second graph explicit and editable. Right now forge's plant graph is hardcoded inside `/forge-next` — the wiring exists but only as prose in a command file.

## The item catalog is the actual design work

Composition in factory sims works because of typed items, not because of machines. Your CONTRACT already names the types: `Vision`, `Contract`, `Spec`, `UX`, `Design`, `Workplan`, `Task`, `ResolvedContext`, `Diff`, `GateResult`, `Commit`, `ReviewPacket`. Nodes become functions over them:

```
plan     :: (Vision, Contract, Spec) -> Workplan
resolve  :: (Manifest, Contract) -> ResolvedContext   -- budget-capped
execute  :: (Task, Template, ResolvedContext) -> Diff
gate     :: (Diff, GateSpec) -> GateResult
```

If you get the type list right, node composition is nearly free. If you get it wrong, no amount of node metadata saves you. `resolve` is the sleeper here — "manifest refs → concatenated sections under a line budget" is a genuinely general primitive that any node should be able to call, and it's currently buried in step 3 of one command.

## The metadata field that earns its place: who runs it

Beyond the obvious (`consumes`, `produces`, `gate`, `tags`), the load-bearing one is the **power source** — deterministic script, AI, or human. Three wildly different cost/reliability curves, exactly like burner vs. electric in a sim. Optimizing the factory then has a crisp meaning: _push work down the cost ladder as confidence rises._ That's already Forge pillar #2 ("deterministic enforcement over instruction-following"), just not modeled as a dimension.

Second-most-important: `mutates`. Nodes that write back to shared state (WORKPLAN status, STATUS.md) aren't pure functions, and that's where DAG purity actually breaks. Better to declare it than pretend.

## Four mechanics worth stealing

**Bottleneck accounting.** Every factory has exactly one. Yours is human attention, measured in review-minutes. Forge noticed this — checkpoint tasks are literally an admission that per-task review "trends toward rubber-stamping." The factory frame turns that into a number you can design against, and the classic fixes apply: buffer in front of it, batch its input, route low-risk items around it.

**Buffers.** WIP has to sit somewhere between machines running at different rates. STATUS.md is a buffer for unresolved questions. A review queue is a buffer. Without them the line stalls at every human node — with them, human review becomes async instead of a stop-the-line interrupt.

**Byproducts.** This is the strongest extension. Every AI execution emits pollution: `<!-- ASSUMED -->` annotations, undocumented decisions, stale docs. Forge handles this ad hoc; a factory model says a waste stream needs its own processing line or it accumulates and poisons the base. That's an argument for drift-reduction nodes as first-class citizens, not cleanup chores.

**Blueprints.** Stamped subgraphs. `ux-spec → design-check → feature → gate → review` is a blueprint for "ship one screen" — and your CONTRACT already specifies exactly that DAG shape in prose. Your eight task types are proto-blueprints that never got promoted.

## Where the metaphor will bite you

- **Rework isn't a DAG.** Factories are forward-flow; software is dominated by feedback loops. A failed gate → fix → retry is a cycle. Survivable only if the DAG is over _task instances_ and retries spawn new nodes, which means your graph grows at runtime and "the DAG" is really an append-only event log.
- **Items aren't fungible.** Every iron plate is identical; every diff is unique. Ratios and throughput math get much weaker.
- **Throughput is the wrong objective.** A factory optimized for items/min, pointed at software, produces an enormous volume of mediocre code — and unlike a scrap pile you can't delete it, because it's load-bearing. The thing actually worth maximizing is closer to _correct decisions per unit of human attention_. Worth writing that down early, because the sim-game framing pulls hard toward the wrong metric.

## The cheapest way to find out if this is real

Write the node schema, then re-express forge's own machinery in it: 8 task types, 4 commands, 3 scripts. If `/forge-next` can be rebuilt as a generic runner over that schema and the smoke tests still pass, the abstraction is real. If describing forge in it requires escape hatches, you've learned that for the price of a YAML file.

Nice bonus: it makes `/forge-status` a factory view — nodes, WIP, where things are stuck. Which is the sim-game part you actually wanted to look at.
