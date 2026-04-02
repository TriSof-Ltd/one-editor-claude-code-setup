---
name: deploy
description: Run all unit tests and E2E tests, then merge dev to main for production deployment. Use when the user says "deploy", "push to production", "merge to main", or "ship it". Only merges if ALL tests pass.
allowed-tools: Bash, Bash(playwright-cli:*), Read
---

# Deploy to Production

Merge `dev` branch to `main` ONLY after ALL tests pass. Main branch is production.

## Workflow

### Step 1: Ensure on dev branch

```bash
git checkout dev
git status
```

Must be clean — commit any uncommitted changes first.

### Step 2: Run all unit tests

```bash
cd server && npm run test:run 2>&1
```

**ALL tests must pass.** If any fail: STOP. Fix the failing tests first. Do NOT proceed.

### Step 3: Run all E2E tests

Check if dev server is running:
```bash
pm2 list 2>/dev/null | grep -q "online" && echo "RUNNING" || echo "NOT RUNNING"
```

If running:
```bash
# Read existing E2E test files
ls tests/e2e/*.e2e.ts 2>/dev/null
```

Open browser and run each E2E test:
```bash
playwright-cli open http://localhost:5345
# Execute test steps...
playwright-cli eval "JSON.stringify(window.__oe.splice(0))"
# Check for errors...
playwright-cli close
```

**ALL E2E tests must pass.** If any fail: STOP. Fix first.

### Step 4: Build check

```bash
npm run build 2>&1
cd server && npm run build 2>&1
```

Build must succeed. TypeScript errors = STOP.

### Step 5: Merge to main

```bash
git checkout main
git merge dev --no-ff -m "Merge dev: [brief description of changes]"
git push origin main
git checkout dev
```

### Step 6: Confirm

Tell the user: "Deployed to production. All tests passed."

## Rules

1. **Never merge with failing tests.** No exceptions.
2. **Never force-push to main.**
3. **Always go back to dev after merging.**
4. **Run BOTH unit and E2E tests** — not just one.
