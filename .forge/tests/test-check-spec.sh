#!/usr/bin/env bash
set -e

# Validates check-spec.js's spec readiness gate (TASK-030): required sections
# present, at least one requirement with acceptance criteria, no unresolved
# markers above threshold, no placeholder/TODO text in Requirements.

SCRIPT="$(pwd)/.forge/scripts/check-spec.js"
TMPDIR=$(mktemp -d)
mkdir -p "$TMPDIR/.forge"

# --- Fixture 1: well-formed spec — must PASS ---
cat > "$TMPDIR/.forge/spec-pass.md" << 'EOF'
# Spec

## Overview

What this system does, in one paragraph.

## Requirements

### [req-login] User Login

WHEN a user submits valid credentials, THE SYSTEM SHALL create a session.

Acceptance criteria:

- A valid login redirects to the dashboard.
- An invalid login shows an error and does not create a session.

## Flows

Login flow references [req-login].

## Non-Goals

- Social login providers.
EOF

echo "Fixture 1: well-formed spec must PASS..."
( cd "$TMPDIR" && node "$SCRIPT" .forge/spec-pass.md )
echo "  OK"

# --- Fixture 2: missing required section (no Non-Goals) — must FAIL ---
cat > "$TMPDIR/.forge/spec-missing-section.md" << 'EOF'
# Spec

## Overview

What this system does.

## Requirements

### [req-login] User Login

WHEN a user submits valid credentials, THE SYSTEM SHALL create a session.

Acceptance criteria:

- A valid login redirects to the dashboard.
EOF

echo "Fixture 2: missing required section must FAIL..."
if ( cd "$TMPDIR" && node "$SCRIPT" .forge/spec-missing-section.md ) 2>/dev/null; then
  echo "  FAILED: expected rejection but script passed"
  rm -rf "$TMPDIR"
  exit 1
fi
echo "  OK (correctly rejected)"

# --- Fixture 3: unfilled stub — no acceptance criteria, placeholder-only requirement — must FAIL ---
cat > "$TMPDIR/.forge/spec-stub.md" << 'EOF'
# Spec

## Overview

<!-- What this feature/system does, in one paragraph. Why it exists. -->

## Requirements

### [REQ-slug] Requirement Name

<!-- EARS-style statement: WHEN <trigger>, THE SYSTEM SHALL <response>. -->
<!-- Acceptance criteria: bullet list, each independently testable. -->

## Non-Goals

<!-- What this spec deliberately excludes. Prevents scope creep during execution. -->
EOF

echo "Fixture 3: unfilled stub must FAIL..."
if ( cd "$TMPDIR" && node "$SCRIPT" .forge/spec-stub.md ) 2>/dev/null; then
  echo "  FAILED: expected rejection but script passed"
  rm -rf "$TMPDIR"
  exit 1
fi
echo "  OK (correctly rejected)"

# --- Fixture 4: TODO placeholder text in a requirement — must FAIL ---
cat > "$TMPDIR/.forge/spec-todo.md" << 'EOF'
# Spec

## Overview

What this system does.

## Requirements

### [req-login] User Login

TODO: write the EARS statement.

Acceptance criteria:

- A valid login redirects to the dashboard.

## Non-Goals

- Social login providers.
EOF

echo "Fixture 4: TODO text in a requirement must FAIL..."
if ( cd "$TMPDIR" && node "$SCRIPT" .forge/spec-todo.md ) 2>/dev/null; then
  echo "  FAILED: expected rejection but script passed"
  rm -rf "$TMPDIR"
  exit 1
fi
echo "  OK (correctly rejected)"

# --- Fixture 5: unresolved marker present, default threshold zero — must FAIL ---
cat > "$TMPDIR/.forge/spec-unresolved.md" << 'EOF'
# Spec

## Overview

What this system does.

## Requirements

### [req-login] User Login

WHEN a user submits valid credentials, THE SYSTEM SHALL create a session.

<!-- UNRESOLVED: does a session expire? -->

Acceptance criteria:

- A valid login redirects to the dashboard.

## Non-Goals

- Social login providers.
EOF

echo "Fixture 5: unresolved marker over default threshold must FAIL..."
if ( cd "$TMPDIR" && node "$SCRIPT" .forge/spec-unresolved.md ) 2>/dev/null; then
  echo "  FAILED: expected rejection but script passed"
  rm -rf "$TMPDIR"
  exit 1
fi
echo "  OK (correctly rejected)"

echo "Fixture 5b: same file passes with --max-unresolved 1..."
( cd "$TMPDIR" && node "$SCRIPT" .forge/spec-unresolved.md --max-unresolved 1 )
echo "  OK"

# A missing or non-numeric threshold value must be a usage error, not a silent
# skip: Number(undefined) is NaN, and `count > NaN` is always false, so before
# TASK-076 the flag with no value disabled the unresolved-marker check entirely
# while reading as strictness.
echo "Fixture 5c: --max-unresolved with a missing or malformed value is a usage error..."
if ( cd "$TMPDIR" && node "$SCRIPT" .forge/spec-unresolved.md --max-unresolved ) 2>/dev/null; then
  echo "FAIL: --max-unresolved with no value must exit nonzero, not silently disable the check"
  exit 1
fi
if ( cd "$TMPDIR" && node "$SCRIPT" .forge/spec-unresolved.md --max-unresolved lots ) 2>/dev/null; then
  echo "FAIL: --max-unresolved with a non-numeric value must exit nonzero"
  exit 1
fi
echo "  OK"

# --- Fixture 6: fenced block containing heading-like lines — must PASS ---
# Section scoping must ignore `#` lines inside ``` fences (mirrors TASK-050's
# fix to check-ux-spec.js) — a quoted spec skeleton must not truncate the
# Requirements section early.
cat > "$TMPDIR/.forge/spec-fenced.md" << 'EOF'
# Spec

## Overview

What this system does.

## Requirements

### [req-login] User Login

WHEN a user submits valid credentials, THE SYSTEM SHALL create a session.

Authors sometimes quote a spec skeleton inline:

```md
## Requirements

### [req-example] Example
```

Acceptance criteria:

- A valid login redirects to the dashboard.

## Non-Goals

- Social login providers.
EOF

echo "Fixture 6: heading-like lines inside a fence must not truncate the section..."
( cd "$TMPDIR" && node "$SCRIPT" .forge/spec-fenced.md )
echo "  OK"

# --- Real instance: the project's own .forge/SPEC.md must PASS ---
# A gate script that has never run against a genuine instance is untested.
echo "Real instance: .forge/SPEC.md must PASS..."
node "$SCRIPT" .forge/SPEC.md
echo "  OK"

rm -rf "$TMPDIR"
echo ""
echo "All check-spec.js fixtures passed."
