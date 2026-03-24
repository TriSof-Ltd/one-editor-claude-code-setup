---
name: plan-project
description: Plan a project before building. Asks clarifying questions and creates PLAN.md. Use when starting a new project or major feature.
allowed-tools: Read, Write, Glob, Grep
---

# Plan Project

You are in PLANNING MODE. Your job is to understand what the user wants BEFORE writing any code.

DO NOT write code. DO NOT create or modify any files except PLAN.md.

## Process

1. **Analyze** the user's description carefully. Identify what is clear and what is ambiguous.

2. **Ask clarifying questions** ONE AT A TIME using the `mcp__one-editor__ask_user` tool. ALWAYS provide an `options` array with 2-4 sensible choices. The user can also type a custom answer.

   Cover these areas:
   - **Core features**: What are the must-have vs nice-to-have features?
   - **User experience**: How should key user flows work?
   - **Data model**: What data needs to be stored and how does it relate?
   - **Design**: Visual style preferences, layout, responsive requirements?
   - **Integrations**: External services, APIs, authentication needed?
   - **Priorities**: What should be built first? What defines the MVP?
   - **Missing requirements**: Things the user hasn't mentioned but should decide on
   - **Contradictions**: Anything ambiguous or contradictory that needs clarification

   Ask between 5-10 questions depending on project complexity. Each question should have clear options.

3. **Create PLAN.md** in the project root with these sections:

   ```
   # Project Plan

   ## Overview
   2-3 sentence summary of what we're building.

   ## Features
   ### MVP (Build First)
   - Feature 1
   - Feature 2

   ### Future
   - Feature 3
   - Feature 4

   ## Architecture
   Technical approach, component structure, data model.

   ## Design
   Visual direction, layout approach, responsive strategy.

   ## Build Order
   1. First thing to build
   2. Second thing to build
   3. ...

   ## Open Questions
   - Anything still unresolved
   ```

4. **Show a brief summary** of the plan in your response. Tell the user to review PLAN.md and send their next message to start building.

## Rules
- Ask questions via `mcp__one-editor__ask_user` tool. If unavailable, ask in your response text.
- ALWAYS provide options with every question.
- Do NOT start coding. Only create PLAN.md.
- Keep the plan practical and actionable, not theoretical.
