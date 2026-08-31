# /forge-sync

Update this project's **Forge-managed** files to the canonical versions from the Forge repository, one approved file at a time. Project-owned artifacts are never touched.

Forge ships as files copied into a project, so a project installed months ago runs whatever the engine looked like then. Sync is the cure for that drift — and it is dangerous in exactly one direction, which shapes the whole command: the engine files are replaceable, but `CONTRACT.md`, `WORKPLAN.md`, `SPEC.md`, and their siblings hold work that exists nowhere else. An overwrite there is unrecoverable. So the file sets are kept strictly apart, and nothing is written without the human saying yes to that specific file.

## The two file sets

**Forge-managed — eligible for sync** (CONTRACT#data-model/artifacts):

- `.claude/commands/forge-*.md` — the slash command definitions
- `.forge/templates/*.md` — the prompt templates
- `.forge/scripts/*.js` — every engine script (the gate scripts, `wp.js`, `obs.js`, `prose.js`, `migrate-notes.js`)
- `.forge/scripts/lib/*.js` — the shared modules those scripts require
- `.forge/scripts/*.sh` — the hook scripts (`guard-push.sh`, `guard-branch.sh`, `guard-secrets.sh`, `hook-status-lint.sh`)

**Project-owned — never touched by this command, under any circumstance:**

`.forge/VISION.md`, `.forge/CONTRACT.md`, `.forge/SPEC.md`, `.forge/specs/`, `.forge/WORKPLAN.md`, `.forge/STATUS.md`, `.forge/UX.md`, `.forge/DESIGN.md`, and `.forge/notes/`.

These are untouchable. Do not read them for comparison, do not offer to update them, do not mention them as candidates. If a canonical copy of one exists upstream, ignore it — upstream ships stubs, and this project's copies are the actual work. There is no approval prompt that unlocks this; a human who wants an upstream stub can copy it in themselves.

## Steps

### 1. Read the version stamp

```bash
cat .forge/VERSION
```

Line 1 is the **engine version** this project last synced to. Line 2 is the **canonical repository URL**. If `.forge/VERSION` is missing or either line is unreadable, stop and tell the human — without the stamp there is no baseline, and without a baseline every classification in step 3 collapses into "differs somehow", which is not enough to approve an overwrite against.

### 2. Fetch the canonical files

Clone the canonical repository shallowly into a scratch directory — never into the project tree:

```bash
git clone --depth 1 <repo-url-from-VERSION-line-2> "$TMPDIR/forge-sync-head"
```

Also fetch the **baseline**: the canonical files as they stood at the engine version on line 1, which is what this project was installed from.

```bash
git clone --depth 1 --branch v<version-from-VERSION-line-1> <repo-url> "$TMPDIR/forge-sync-base"
```

If that tag does not exist upstream, say so and continue **without** a baseline — step 3 then degrades as described there. Do not guess at a nearby tag.

If the clone fails outright (no network, bad URL, private repo), report the error verbatim and stop. A sync that cannot see upstream has nothing to offer.

### 3. Classify every managed file

For each file matching the three managed globs — the union of what exists locally and what exists upstream — compare three copies: **base** (baseline clone), **local** (this project), **upstream** (HEAD clone).

| Classification | Condition | What it means |
| --- | --- | --- |
| **unchanged** | local == upstream | Nothing to do. |
| **local-only customization** | local != base, upstream == base | The human edited it; upstream has not moved. Leave it alone. |
| **upstream-updated** | local == base, upstream != base | A clean engine update. This is the ordinary case. |
| **conflicting** | local, base, and upstream all differ | The human edited it *and* upstream moved. Applying loses the local edit. |

A file present upstream but absent locally is **new upstream** — offer it as an addition. A file present locally but absent upstream is a **local addition** — report it and leave it; it is not the engine's to delete.

**Without a baseline** (step 2 could not fetch the tag), only two states are distinguishable: identical, or different. Classify every differing file as **conflicting**. This is deliberately pessimistic — a two-way diff cannot tell an engine update from the human's own edit, and guessing wrong in the permissive direction silently destroys their customization.

### 4. Present the summary

Report every file with its classification, grouped, before asking about any of them. The human decides against the whole picture, not one prompt at a time with no idea how many follow:

```
## Forge Sync — 0.3.0 → 0.4.1

Unchanged (6): forge-plan.md, forge-status.md, feature.md, fix.md, refactor.md, check-spec.js

Upstream-updated (2):
  - .claude/commands/forge-next.md      (+41 / -12)
  - .forge/templates/checkpoint.md      (+8 / -0)

Local-only customization (1):
  - .forge/templates/feature.md          — kept, upstream has not changed it

Conflicting (1):
  - .forge/scripts/wp.js                 — local edits + upstream changes

New upstream (1):
  - .forge/templates/investigate.md      — not present locally
```

### 5. Ask file by file, and apply only what is approved

Walk the actionable files one at a time — upstream-updated, conflicting, and new upstream. For each, show the diff between local and upstream, then ask: **apply, skip, or show more?** Wait for the answer before moving on.

- **Local-only customizations are never offered and never overwritten.** Report them as kept, and move on.
- **Conflicting files carry an explicit warning** naming what is lost: applying replaces the local file wholesale, including the human's edits. Show the diff before asking, not after. If they want to merge by hand instead, that is a "skip" — sync does not do three-way merges.
- **Approval is per file and does not carry.** A yes on `forge-next.md` says nothing about `check-workplan.js`. Never batch, never infer a blanket approval, and never re-interpret an earlier yes as covering a later file.
- Apply an approved update by replacing the local file with the upstream copy. Never write to a path outside the three managed globs.

### 6. Restamp the version

Update `.forge/VERSION` line 1 to the upstream engine version **only after a successful sync** — meaning every actionable file was either applied or already unchanged. Leave line 2 as it is unless the canonical URL itself moved.

If the human skipped anything, do **not** advance the stamp. The stamp is the baseline for the next run's three-way diff, and stamping a version the project is not actually at would make the skipped files read as local customizations next time — quietly converting a deferred update into a permanent divergence. Say plainly that the stamp was held back, and which files it is waiting on.

Report what changed, what was skipped, and whether the stamp advanced.

## Constraints

- **Project-owned artifacts are untouchable.** `VISION.md`, `CONTRACT.md`, `SPEC.md`, `specs/`, `WORKPLAN.md`, `STATUS.md`, `UX.md`, `DESIGN.md`, `notes/` — this command never modifies them, and no approval unlocks that. Sync updates the engine, not the project.
- **Nothing is written without per-file approval.** Local customizations are never silently overwritten. Neither is anything else.
- **Only the managed globs are writable:** `.claude/commands/forge-*.md`, `.forge/templates/*.md`, `.forge/scripts/*.js`, `.forge/scripts/lib/*.js`, `.forge/scripts/*.sh`, plus `.forge/VERSION` itself. The globs track what the Artifacts table marks Forge-managed rather than a narrower hand-maintained list: a script marked Forge-managed but excluded from sync drifts permanently in every installed project, which is what a `check-*.js`-only glob did to `wp.js`, `prose.js`, `lib/`, and the guards (OBS-015).
- **The clone goes to a scratch directory,** never into the project tree, and is cleaned up when the command finishes.
- **No auto-commit.** Sync leaves the changes in the working tree for the human to review and commit.
- **A failed fetch is a stop, not a fallback.** Do not reconstruct upstream files from memory or write a "best guess" version of any managed file.
