#!/bin/bash
# Run validation + lint/format after Claude edits or writes a file
# Input: JSON on stdin with tool_input.file_path

FILE_PATH=$(cat | node -e "
  let d='';
  process.stdin.on('data',c=>d+=c);
  process.stdin.on('end',()=>{
    try{
      const j=JSON.parse(d);
      console.log(j.tool_input?.file_path||j.tool_input?.file||'');
    }catch{console.log('')}
  });
" 2>/dev/null)

# Skip if no file path or non-source file
if [ -z "$FILE_PATH" ]; then exit 0; fi
if [ ! -f "$FILE_PATH" ]; then exit 0; fi

EXT="${FILE_PATH##*.}"

# Portable sed -i (works on both GNU and BSD/macOS sed)
sedi() {
  if sed --version 2>/dev/null | grep -q GNU; then
    sed -i "$@"
  else
    sed -i '' "$@"
  fi
}

# ── Fix literal \n corruption ──
# Claude's Write tool sometimes produces files with literal \n instead of newlines
# Detect: if file has very few lines but is large, or contains literal \n sequences
if [[ "$EXT" =~ ^(ts|tsx|js|jsx|mjs|cjs)$ ]]; then
  LINE_COUNT=$(wc -l < "$FILE_PATH" 2>/dev/null | tr -d ' ')
  BYTE_COUNT=$(wc -c < "$FILE_PATH" 2>/dev/null | tr -d ' ')
  # If file has < 5 lines but > 200 bytes, likely has literal \n
  if [ "${LINE_COUNT:-0}" -lt 5 ] 2>/dev/null && [ "${BYTE_COUNT:-0}" -gt 200 ] 2>/dev/null; then
    if grep -qF '\n' "$FILE_PATH" 2>/dev/null; then
      # Fix: replace literal \n with actual newlines
      sedi 's/\\n/\n/g' "$FILE_PATH"
    fi
  fi
fi

# ── Lint/format ──
case "$EXT" in
  ts|tsx|js|jsx|mjs|cjs)
    if command -v npx &>/dev/null && [ -f "node_modules/.bin/eslint" ]; then
      npx eslint --fix "$FILE_PATH" 2>/dev/null
    fi
    ;;
  css|scss)
    if [ -f "node_modules/.bin/stylelint" ]; then
      npx stylelint --fix "$FILE_PATH" 2>/dev/null
    fi
    ;;
esac

# Run prettier if installed (config alone isn't enough)
if [ -f "node_modules/.bin/prettier" ]; then
  npx prettier --write "$FILE_PATH" 2>/dev/null
fi

exit 0
