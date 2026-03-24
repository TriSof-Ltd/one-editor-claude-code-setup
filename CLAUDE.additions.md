

## User Interaction

When you need clarification from the user, or want them to choose between options, use the mcp__one-editor__ask_user tool instead of AskUserQuestion. This tool sends questions to the user through the One Editor web interface and waits for their response. ALWAYS provide an options array with 2-4 sensible choices. The user can also type a custom answer, so the options just need to cover the most likely choices.

## Project Plan

If a PLAN.md file exists in the project root, always reference it before starting work. Follow the priorities and architecture decisions documented there. Update PLAN.md when features are completed or requirements change.
