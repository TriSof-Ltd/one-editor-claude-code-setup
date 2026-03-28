---
name: deploy
description: Run all tests and merge dev to main for production deployment. Use when the user says "deploy", "push to production", "merge to main", or "ship it". Only merges if ALL tests pass.
allowed-tools: Bash, Read
---

# Deploy to Production

Merge `dev` branch to `main` ONLY after all tests pass. Main branch is production.

## Workflow

### Step 1: Ensure on dev branch

```bash
git checkout dev
git status
```

Must be clean — commit any uncommitted changes first.

### Step 2: Run backend unit tests

```bash
cd server && npm run test:run 2>&1
```

**ALL tests must pass.** If any fail: STOP. Fix the failing tests first. Do NOT proceed to step 3.

### Step 3: Run frontend build check

```bash
npm run build 2>&1
```

Build must succeed. TypeScript errors = STOP.

### Step 4: Run browser E2E tests (if app is running)

Check if dev server is running:
```bash
pm2 list 2>/dev/null | grep -q "online" && echo "RUNNING" || echo "NOT RUNNING"
```

If running, execute the browser-test skill workflow (open, check events, close).

### Step 5: Check diff scope — only run tests related to changes

```bash
git diff main..dev --name-only
```

If only `server/` files changed → backend tests are sufficient.
If only `src/` files changed → frontend build + browser E2E is sufficient.
If both changed → run everything.
If only non-code files changed (docs, config) → skip tests, proceed.

### Step 6: Merge to main

```bash
git checkout main
git merge dev --no-ff -m "Merge dev: [brief description of changes]"
git push origin main
git checkout dev
```

### Step 7: Confirm

Tell the user: "Deployed to production. All tests passed."

## Rules

1. **Never merge with failing tests.** This is the #1 rule. No exceptions.
2. **Never force-push to main.** Use merge only.
3. **Always go back to dev after merging.** Main is for production code only.
4. **Commit messages matter.** The merge commit should summarize what changed.
5. **If tests are slow**, only run tests related to the diff (step 5).

## Quick Deploy (when user just says "deploy")

```bash
# 1. Check branch
git checkout dev

# 2. Backend tests
cd server && npm run test:run 2>&1
# If FAIL → stop

# 3. Build check
cd .. && npm run build 2>&1
# If FAIL → stop

# 4. Merge
git checkout main && git merge dev --no-ff -m "Merge dev: ..." && git push origin main && git checkout dev
```
