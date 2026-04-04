#!/bin/bash
# Post-compaction hook: Generate handoff document and trigger context reset.
# Instead of continuing with degraded context, we write a structured handoff
# and signal the bridge to kill the session and start fresh.

# Generate handoff document
HANDOFF_FILE=".claude/handoff.md"
mkdir -p .claude

{
  echo "# Handoff Document"
  echo "Generated: $(date -u +%Y-%m-%dT%H:%M:%SZ)"
  echo ""

  # What's done (completed items from PLAN.md)
  echo "## What's Done"
  if [ -f "PLAN.md" ]; then
    grep -E '^\s*- \[x\]' PLAN.md 2>/dev/null | head -20 || echo "No completed items found"
  else
    echo "No PLAN.md found"
  fi
  echo ""

  # Current state
  echo "## Current State"
  echo "### Recent Commits"
  echo '```'
  git log --oneline -10 2>/dev/null || echo "No git history"
  echo '```'
  echo ""

  echo "### Uncommitted Changes"
  echo '```'
  git diff --stat 2>/dev/null | tail -5 || echo "None"
  echo '```'
  echo ""

  # Test status
  echo "### Test Status"
  if [ -f "tests/evaluation.json" ]; then
    echo "Evaluation:"
    cat tests/evaluation.json 2>/dev/null | head -20
  fi
  if [ -f "tests/e2e/results.json" ]; then
    echo "E2E:"
    cat tests/e2e/results.json 2>/dev/null | head -10
  fi
  echo ""

  # Sprint contract
  if [ -f ".claude/sprint-contract.md" ]; then
    echo "## Active Sprint Contract"
    cat .claude/sprint-contract.md
    echo ""
  fi

  # Evaluator feedback
  if [ -f ".claude/evaluator-feedback.md" ]; then
    echo "## Pending Evaluator Feedback"
    cat .claude/evaluator-feedback.md
    echo ""
  fi

  # What's next (unchecked items from PLAN.md)
  echo "## What's Next"
  if [ -f "PLAN.md" ]; then
    grep -E '^\s*- \[ \]' PLAN.md 2>/dev/null | head -10 || echo "No pending items"
  fi

} > "$HANDOFF_FILE" 2>/dev/null

# Signal the bridge to perform a context reset
curl -s -X POST http://localhost:8766/hooks/context_reset \
  -H "Content-Type: application/json" \
  -d '{"reason":"compaction"}' 2>/dev/null || true

# Return minimal context for the current session's final moments
PLAN=""
if [ -f "PLAN.md" ]; then
  PLAN=$(head -20 PLAN.md 2>/dev/null | tr '"' "'" | tr '\n' ' ' | head -c 500)
fi

cat << JSONEOF
{
  "additionalContext": "Context reset in progress. Handoff document written to .claude/handoff.md. Session will restart shortly."
}
JSONEOF
