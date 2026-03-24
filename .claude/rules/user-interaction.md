# User Interaction Rules

When you need clarification from the user, or want them to choose between options:

1. Use the `mcp__one-editor__ask_user` tool (NOT the built-in AskUserQuestion)
2. ALWAYS provide an `options` array with 2-4 sensible choices
3. The user can type a custom answer, so options just need to cover the most likely choices
4. Ask ONE question at a time — wait for the answer before asking the next

If the `mcp__one-editor__ask_user` tool is not available, ask questions directly in your response text with numbered options.
