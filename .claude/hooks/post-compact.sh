#!/bin/bash
# Re-inject critical context after context compaction
# Claude loses awareness of project state when context is compacted

PLAN=""
if [ -f "PLAN.md" ]; then
  PLAN=$(head -30 PLAN.md)
fi

cat << EOF
{
  "additionalContext": "CONTEXT RESTORED AFTER COMPACTION:\n\n- Use mcp__one-editor__ask_user for questions (always with options)\n- If PLAN.md exists, follow its priorities\n- Run eslint after editing files\n${PLAN:+\nCurrent plan summary:\n$PLAN}"
}
EOF
