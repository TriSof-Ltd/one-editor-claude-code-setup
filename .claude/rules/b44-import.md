# Base44 Import Mode

If `.base44-source/` exists in the project root, this is a Base44 import project.

## On First Message

When the user sends their first message (or any message while `.claude/b44-analysis.json` does NOT exist yet):

1. **Greet them** — "This project was imported from a Base44 app. I'll analyze the source and ask you some questions before converting it."
2. **Run /b44-analyze** — This scans `.base44-source/`, extracts all entities, pages, integrations, and auth patterns, then asks 3-5 clarifying questions.
3. **Wait for answers** — Ask questions one at a time. Don't proceed until all are answered.
4. **Show summary** — After questions, show what was found: entities, pages, integrations, routes.
5. **Ask to proceed** — "Ready to start the conversion? Say **start** when you're ready."

## When User Says "Start"

Run the conversion skills in order:
1. `/b44-scope` — generates scope.md + detailed-architecture.md
2. `/b44-schema` — database migrations, types, schemas, repositories
3. `/b44-backend` — API routes, services, integrations
4. `/b44-seed` — seed data (parallel with backend)
5. `/b44-frontend` — convert pages, components, Redux store
6. `/b44-test` — generate tests

Commit after each major phase.

## Important

- Do NOT start converting before the user says "start"
- Do NOT skip the Q&A — the user needs to confirm scope before implementation
- If `.claude/b44-analysis.json` already exists, skip to the scope/conversion phase
- This rule only applies when `.base44-source/` exists — ignore for normal projects
