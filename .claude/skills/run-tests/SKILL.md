---
name: run-tests
description: Triggered when the user clicks "Run Tests". Analyze all changes since last test run, write missing unit and E2E tests, run them, fix failures, and update tests/tracking.json.
allowed-tools: Bash, Read, Write, Edit, Bash(playwright-cli:*)
---

# Run Tests

This skill is triggered when the user clicks the "Run Tests" button. Your job: ensure all recent code changes have test coverage, all tests pass, and results are tracked.

## Step 1: Determine what changed

```bash
# Read last tested commit
cat tests/tracking.json 2>/dev/null | node -e "let d='';process.stdin.on('data',c=>d+=c);process.stdin.on('end',()=>{try{console.log(JSON.parse(d).lastTestedCommit)}catch{console.log('none')}})"

# See commits since then
git log --oneline <lastTestedCommit>..HEAD

# See changed files
git diff --name-only <lastTestedCommit>..HEAD
```

If no tracking exists, analyze all code.

## Step 2: Write missing unit tests

For each changed file in `server/api/routes/`:
- Check if `server/api/__tests__/<name>.test.ts` exists
- If not, create it using the setup helper:

```typescript
import { describe, it, expect } from 'vitest'
import { createTestApp, request } from './setup'
const app = createTestApp()

describe('ROUTE endpoints', () => {
  it('returns 401 without auth', ...)
  it('returns 400 with invalid input', ...)
  it('returns 200/201 with valid input', ...)
  it('returns 404 for missing resource', ...)
})
```

## Step 3: Run unit tests

```bash
cd server && npm run test:run 2>&1
```

If failures: analyze, fix, rerun. Max 3 attempts.

## Step 4: Run E2E tests (if frontend changed)

Check if any `src/` files changed. If yes:

```bash
playwright-cli open http://localhost:5345
playwright-cli eval "JSON.stringify(window.__oe.splice(0))"
# Navigate to affected pages, interact, check events
playwright-cli close
```

Look for `t:"error"`, `t:"rejection"`, or `t:"fetch"` with `ok:false`.

## Step 5: Update tracking

Create/update `tests/tracking.json`:

```json
{
  "lastTestRun": "2026-03-28T...",
  "lastTestedCommit": "<HEAD hash>",
  "unitTests": { "total": N, "passed": N, "failed": N },
  "e2eTests": { "total": N, "passed": N, "failed": N },
  "status": "pass"
}
```

## Step 6: Commit test files

```bash
git add tests/ server/api/__tests__/
git commit -m "Add/update tests for recent changes"
```

## Step 7: Report

Tell the user exactly:
- How many unit tests written/run
- How many E2E checks performed
- Pass/fail status
- Any issues that could not be auto-fixed
