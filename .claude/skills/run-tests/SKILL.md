---
name: run-tests
description: Run all unit tests. Triggered by "Run Unit Tests" button. Runs vitest, reports results, fixes failures.
allowed-tools: Bash, Read, Write, Edit
---

# Run Unit Tests

Run all backend unit tests and report results.

## Step 1: Run tests

```bash
cd server && npx vitest run --reporter=verbose 2>&1
```

## Step 2: Handle results

If all pass: report total count and "All unit tests passed."

If any fail:
1. Read the failing test file and the source it tests
2. Determine if the bug is in the source code or the test
3. Fix it
4. Re-run: `cd server && npx vitest run --reporter=verbose 2>&1`
5. Max 3 fix attempts

## Step 3: Check for missing tests

```bash
# Find server routes/services without test files
ls server/api/routes/ server/api/services/ 2>/dev/null
ls server/api/__tests__/ 2>/dev/null
```

For any testable file without a test:
- Create `server/api/__tests__/<name>.test.ts`
- Test: auth (401), validation (400), happy path (200/201), not found (404)
- Use vitest (`describe`, `it`, `expect`)

## Step 4: Commit new tests

```bash
git add server/api/__tests__/
git diff --cached --quiet || git commit -m "Add missing unit tests"
```

## Step 5: Report

Summary: N total tests, N passed, N failed. List any that couldn't be fixed.
