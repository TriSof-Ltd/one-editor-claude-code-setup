---
name: run-e2e
description: Run E2E tests manually. Triggered by "Run E2E Tests" button. Runs only failing tests by default, fixes failures, updates results.json.
allowed-tools: Bash, Bash(playwright-cli:*), Read, Write, Edit
---

# Run E2E Tests

Run E2E tests and fix any failures. By default, only re-runs failing tests.

## Step 1: Check current results

```bash
cat tests/e2e/results.json 2>/dev/null
```

Identify tests with `"status": "fail"`. If none are failing, run ALL tests instead.

## Step 2: List test files

```bash
ls tests/e2e/*.e2e.ts 2>/dev/null
```

Read each test file that needs running.

## Step 3: Run tests via playwright-cli

```bash
playwright-cli open http://localhost:5345
```

For each test to run:
1. Execute each step (goto, fill, click, etc.)
2. After interactions: `playwright-cli eval "JSON.stringify(window.__oe.splice(0))"`
3. Check for errors: `t:"error"`, `t:"rejection"`, `t:"fetch"` with `ok:false`
4. Record pass/fail with details

```bash
playwright-cli close
```

## Step 4: Fix failures

For each failing test:
1. Analyze the error — is it a test issue or a code bug?
2. If test issue: update the test file
3. If code bug: fix the application code
4. Re-run that specific test
5. Max 3 attempts per test

## Step 5: Update results

Update `tests/e2e/results.json` with fresh results for all tests that were run. Keep results for tests that weren't re-run.

## Step 6: Commit

```bash
git add tests/e2e/
git diff --cached --quiet || git commit -m "tests: Fix e2e test failures"
```

## Step 7: Report

Summary: N tests run, N passed, N failed. Details for any remaining failures.
