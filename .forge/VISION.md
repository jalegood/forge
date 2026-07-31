# Vision

**What:** A spec-to-ship development pipeline for Claude Code that turns the human into the architect and gate reviewer while AI handles execution between defined checkpoints.

**Who:** Developers using Claude Code who need a repeatable, reliable rhythm for building software across multiple sessions — especially those burned by context degradation, session drift, and inconsistent AI output on multi-step projects.

**Pillars:**

1. **One task, one session, one commit.** Sessions are cheap. Context quality is not. Every task completes in a single clean session.
2. **Deterministic enforcement over instruction-following.** Hooks and scripts enforce quality. CLAUDE.md reminds. If it matters, it must not depend on Claude reading a rule.
3. **Git is the memory.** Commits are checkpoints. The workplan is the log. Everything else is ephemeral.
4. **Progressive context, not total context.** Each task sees only the Contract and Spec sections it needs. The full spec never enters the context window.
5. **You are the architect.** You own the Vision, Contract, and Spec. AI derives plans and writes code. You review gates. The automation boundary is the Contract.
6. **Checkpoints over keystrokes.** Human attention concentrates at defined checkpoints — plan review, quality checkpoints, merges. Between checkpoints, the pipeline may run unattended on a work branch without losing the one-task-one-session-one-commit rhythm.
