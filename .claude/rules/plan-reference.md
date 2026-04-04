# Plan Reference Rules

If a PLAN.md file exists in the project root:

## Before Starting Work
1. Read PLAN.md first — understand the full plan before touching code
2. Identify which phase you're in and which tasks are next
3. Write a sprint contract to `.claude/sprint-contract.md` before building each feature (see sprint-contracts.md)
4. Follow the architecture decisions (database schema, API routes, components)
5. Follow the build order — don't skip ahead to later phases
6. Check if `.claude/evaluator-feedback.md` exists — if so, address that feedback FIRST before continuing

## While Working
5. Work through checkboxes in order within each phase
6. After completing a task, update PLAN.md: change `- [ ]` to `- [x]`
7. Run the **Verify** step at the end of each phase before moving to the next
8. If a verify step fails, fix the issue before proceeding

## When Things Change
9. If the user requests something that conflicts with the plan, ask which to follow
10. If requirements change, update PLAN.md sections (don't just ignore the plan)
11. If you discover something the plan missed, add it as a new checkbox in the right phase

## Out of Scope
12. If the user asks for something listed in "Out of Scope", point it out and confirm they want it
13. Don't add features that aren't in the plan unless the user explicitly asks

## Commits
14. Follow the Commit Strategy section — commit after each logical chunk
15. Don't make one giant commit at the end
