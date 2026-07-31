#!/usr/bin/env bash
set -e

# Validates check-ux-spec.js's vague-term check is scoped to the Experience
# column only (TASK-043) — State/Trigger labels may legitimately contain
# words like "slow" or "fast" without violating precision.

SCRIPT="$(pwd)/.forge/scripts/check-ux-spec.js"
TMPDIR=$(mktemp -d)
mkdir -p "$TMPDIR/.forge"

# --- Fixture 1: vague word in State column, precise Experience — must PASS ---
cat > "$TMPDIR/.forge/UX.md" << 'EOF'
# UX Spec

## Flows

### Flow: Checkout

#### Screen: Pass Case

**Purpose:** Confirm order details before paying.
**Emotional intent:** Confidence that nothing was missed.
**Design intention:** Line items animate in with ease-out 250ms so the total feels earned.

##### States

| State | Trigger | Experience |
| ----- | ------- | ---------- |
| Slow network | Fetch takes >2s | Skeleton rows fade in at opacity 0->1 over 200ms |

##### Edge Cases

| Condition          | Behavior |
| ------------------ | -------- |
| Empty / first-time | Show empty-cart illustration |
| Error              | Inline banner, retry button |
EOF

echo "Fixture 1: vague word outside Experience column must PASS..."
( cd "$TMPDIR" && node "$SCRIPT" "Pass Case" )
echo "  OK"

# --- Fixture 2: vague word inside Experience column — must FAIL ---
cat > "$TMPDIR/.forge/UX.md" << 'EOF'
# UX Spec

## Flows

### Flow: Checkout

#### Screen: Fail Case

**Purpose:** Confirm order details before paying.
**Emotional intent:** Confidence that nothing was missed.
**Design intention:** Line items animate in with ease-out 250ms so the total feels earned.

##### States

| State | Trigger | Experience |
| ----- | ------- | ---------- |
| Loading | Fetch triggered | Smooth fade-in |

##### Edge Cases

| Condition          | Behavior |
| ------------------ | -------- |
| Empty / first-time | Show empty-cart illustration |
| Error              | Inline banner, retry button |
EOF

echo "Fixture 2: vague word inside Experience column must FAIL..."
if ( cd "$TMPDIR" && node "$SCRIPT" "Fail Case" ) 2>/dev/null; then
  echo "  FAILED: expected rejection but script passed"
  rm -rf "$TMPDIR"
  exit 1
fi
echo "  OK (correctly rejected)"

rm -rf "$TMPDIR"
echo ""
echo "All check-ux-spec.js fixtures passed."
