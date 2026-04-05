# Plan & Scope Rules

This project uses two files to track what to build:

- **scope.md** (project root) — The full product vision. Everything this app should eventually become. Updated when the user's vision evolves.
- **PLAN.md** (project root) — The current sprint. What to build RIGHT NOW. Gets checked off as work completes. When done, pull the next phase from scope.md.

## Before Starting Work

1. Read `scope.md` first — understand the full product vision
2. Read `PLAN.md` — identify which tasks are current
3. If PLAN.md is empty or all checked off, pull the next phase from scope.md into PLAN.md
4. Write a sprint contract to `.claude/sprint-contract.md` before building each feature
5. Check if `.claude/evaluator-feedback.md` exists — address that feedback FIRST

## While Working

6. Work through PLAN.md checkboxes in order
7. After completing a task, mark it done: `- [ ]` → `- [x]`
8. Keep commits small and focused
9. Verify each feature works before moving to the next

## When the User Changes Direction

10. If the user describes new features or changes the vision → update `scope.md`
11. If the change affects current work → also update `PLAN.md`
12. If the user says "actually make it X instead of Y" → update scope.md with the new direction
13. Always confirm: "I've updated the scope. Should I continue with the current plan or reprioritize?"

## When PLAN.md is Complete

14. Check scope.md for the next phase
15. Create a new PLAN.md with the next set of tasks
16. Tell the user what you're building next

## Out of Scope

17. If the user asks for something not in scope.md, ask if they want to add it to the scope
18. Don't add features that aren't in scope unless the user explicitly asks
