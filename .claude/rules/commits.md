# Commit Rules

## Commit Size
- Keep commits small and focused. One logical change per commit.
- A commit should do ONE thing: add a feature, fix a bug, refactor a piece of code.
- Include the unit tests for that change in the SAME commit (not separate).

## Commit Types

Every commit you make is one of three types:

### Normal commits
Feature work, bug fixes, refactors — any code change plus its unit tests.
```
Add user dashboard page
Fix login redirect bug
Refactor auth middleware to use JWT
```

### Tests commits
E2E/unit test updates ONLY. Created by the automated testing system.
Prefix with `tests:` — does NOT trigger evaluator.
```
tests: Update auth e2e tests for new login flow
tests: Add dashboard e2e tests
```

### Sprint commits
Sprint contract creation/updates. Prefix with `sprint:` — does NOT trigger evaluator.
```
sprint: Contract for user dashboard
sprint: Update contract outcome for auth feature
```

## Before EVERY commit — MANDATORY build check
Before running `git commit`, you MUST:
1. Run `npm run build 2>&1 | tail -5` — must show "built in" (Vite success)
2. Run `cd server && npm run build 2>&1` — must exit without errors
3. If either fails: FIX the error, then try committing again
4. NEVER commit code that doesn't build

## Important
- Normal commits trigger an automatic E2E test evaluation (a separate Claude instance checks if e2e tests need updating).
- Tests commits do NOT trigger E2E evaluation (prevents infinite loops).
- Never prefix a non-test commit with `tests:`.
- Never include feature code in a `tests:` commit.
