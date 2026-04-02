# Testing Rules

## Unit Tests — Baked Into Every Commit

Unit tests are NOT a separate step. They are part of writing code.

When you create or modify any of these, write/update the unit test in the SAME commit:
- **Services** (`server/api/services/*`) — business logic
- **Repositories** (`server/api/db/*`) — data access
- **Schemas** (`server/api/schemas/*`) — validation
- **Middleware** (`server/api/middleware/*`) — error handling, auth
- **Utilities** (`server/api/utils/*`, `src/lib/utils.ts`) — pure helpers
- **Redux slices/selectors** — pure reducer logic

Test files go in `server/api/__tests__/`. Use vitest. Test at minimum:
- Auth required (401), validation (400), happy path (200/201), not found (404)

Run `cd server && npm run test:run` after writing tests to verify they pass.

### What NOT to unit test
- UI components, pages, layout — test via E2E
- Type definitions, config files, entry files — nothing to execute
- Re-export barrels, scripts — no logic

## E2E Tests — Managed Automatically

E2E tests live in `tests/e2e/` (one file per feature/page). They are managed by a separate Claude Code instance that runs automatically after each commit you make.

**You do NOT need to write E2E tests manually.** The system handles it.

E2E test files use `playwright-cli` to interact with the running app at `http://localhost:5345`.

## Before Merging to Main

- All unit tests must pass: `cd server && npm run test:run`
- All E2E tests must pass: check `tests/e2e/results.json`
- Build must succeed: `npm run build`
- Never merge with failing tests.
