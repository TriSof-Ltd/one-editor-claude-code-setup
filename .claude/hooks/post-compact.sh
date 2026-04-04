#!/bin/bash
# Re-inject critical context after context compaction
# Claude loses awareness of project state when context is compacted

PLAN=""
if [ -f "PLAN.md" ]; then
  PLAN=$(head -30 PLAN.md)
fi

# JSON-escape the plan content to avoid breaking the output
PLAN_ESCAPED=$(echo "$PLAN" | node -e "
  let d='';
  process.stdin.on('data',c=>d+=c);
  process.stdin.on('end',()=>console.log(JSON.stringify(d)));
" 2>/dev/null || echo '""')

cat << EOF
{
  "additionalContext": "CONTEXT RESTORED AFTER COMPACTION:\\n\\n- Use mcp__one-editor__ask_user for questions (always with options)\\n- If PLAN.md exists, follow its priorities\\n- Run eslint after editing files${PLAN:+\\n\\nCurrent plan summary:\\n}$(echo "$PLAN_ESCAPED" | sed 's/^"//;s/"$//' | sed 's/\\/\\\\/g' | sed 's/"/\\"/g')"
}
EOF
