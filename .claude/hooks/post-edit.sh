#!/bin/bash
# Run lint/format checks after Claude edits or writes a file
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

EXT="${FILE_PATH##*.}"
case "$EXT" in
  ts|tsx|js|jsx|mjs|cjs)
    # Run eslint on the specific file (auto-fix)
    if command -v npx &>/dev/null && [ -f "node_modules/.bin/eslint" ]; then
      npx eslint --fix "$FILE_PATH" 2>/dev/null
    fi
    ;;
  css|scss)
    # Run stylelint if available
    if [ -f "node_modules/.bin/stylelint" ]; then
      npx stylelint --fix "$FILE_PATH" 2>/dev/null
    fi
    ;;
esac

# Run prettier if available (any file type)
if [ -f "node_modules/.bin/prettier" ] || [ -f ".prettierrc" ] || [ -f ".prettierrc.json" ]; then
  npx prettier --write "$FILE_PATH" 2>/dev/null
fi

exit 0
