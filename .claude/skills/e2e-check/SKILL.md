---
name: e2e-check
description: Auto-triggered after each normal commit. Reviews all E2E tests, updates/adds/removes as needed based on the latest commit, runs them via playwright-cli, records results, auto-fixes failures.
allowed-tools: Bash, Bash(playwright-cli:*), Read, Write, Edit
---

# E2E Test Check (Auto-triggered)

You are a separate Claude Code instance spawned automatically after a new commit. Your job: ensure the E2E test suite in `tests/e2e/` is up-to-date and passing.

## Context

You will receive the commit hash and message. This is the commit that triggered you.

## Step 1: Understand the commit

```bash
git show --stat HEAD
git diff HEAD~1..HEAD --name-only
```

Read the changed files to understand what was modified.

## Step 2: Review existing E2E tests

```bash
ls tests/e2e/*.e2e.ts 2>/dev/null
cat tests/e2e/results.json 2>/dev/null
```

Read each existing E2E test file to understand current coverage.

## Step 3: Determine what needs changing

Based on the commit changes and existing tests:
- **Add** new E2E tests if a new feature/page was added
- **Update** existing E2E tests if a feature's behavior changed
- **Remove** E2E tests if a feature was deleted
- **No change** if the commit only touched backend logic already covered by unit tests

### What needs E2E tests:
- New pages/routes
- UI components with user interaction (forms, buttons, navigation)
- Auth flows (login, signup, logout)
- CRUD operations visible in the UI
- Settings/profile pages

### What does NOT need E2E tests:
- Backend-only changes (API logic, DB queries) — unit tests cover these
- Styling-only changes (CSS, Tailwind classes)
- Config/build changes
- Type definitions

## Step 4: Write/update E2E test files

E2E test files live in `tests/e2e/` with naming: `<feature>.e2e.ts`

Each file exports a structured test definition describing what to test. You execute the steps using `playwright-cli` commands:

```typescript
// tests/e2e/auth.e2e.ts
export default {
  feature: 'Authentication',
  tests: [
    {
      name: 'Login with email',
      steps: [
        // Use playwright-cli commands:
        // playwright-cli goto http://localhost:5345/auth/signin
        // playwright-cli snapshot  (to find element refs)
        // playwright-cli fill <ref> "test@example.com"
        // playwright-cli click <ref>
        // playwright-cli eval "JSON.stringify(window.__oe.splice(0))"
        // Check output for t:"error" or t:"rejection"
        'Navigate to /auth/signin',
        'Fill email and password fields',
        'Click sign in button',
        'Verify: no errors in __oe events, page navigates to /dashboard',
      ],
    },
    {
      name: 'Sign up flow',
      steps: [
        'Navigate to /auth/signup',
        'Fill email, password, confirm password',
        'Click sign up button',
        'wait 2000',
        'check no_errors',
      ],
    },
  ],
}
```

## Step 5: Run E2E tests

For each test file, execute the steps using playwright-cli:

```bash
playwright-cli open http://localhost:5345
```

For each test:
1. Execute each step via playwright-cli commands
2. After interactions, read events: `playwright-cli eval "JSON.stringify(window.__oe.splice(0))"`
3. Check for `t:"error"`, `t:"rejection"`, or `t:"fetch"` with `ok:false`
4. Record pass/fail

```bash
playwright-cli close
```

## Step 6: Record results

Write `tests/e2e/results.json`:

```json
{
  "lastRun": "2026-04-02T14:30:00.000Z",
  "lastCommit": "abc12345",
  "tests": [
    {
      "name": "Login with email",
      "file": "tests/e2e/auth.e2e.ts",
      "feature": "Authentication",
      "status": "pass",
      "lastRun": "2026-04-02T14:30:00.000Z",
      "error": null
    },
    {
      "name": "Dashboard loads data",
      "file": "tests/e2e/dashboard.e2e.ts",
      "feature": "Dashboard",
      "status": "fail",
      "lastRun": "2026-04-02T14:30:00.000Z",
      "error": "fetch /api/dashboard returned 500"
    }
  ]
}
```

## Step 7: Fix failures

If any E2E test fails:
1. Analyze the error
2. Check if it's a test issue (update test) or a code bug (fix the code)
3. Re-run the failing test
4. Max 3 fix attempts per test

## Step 8: Commit changes

If you created/updated/removed any E2E test files or results:

```bash
git add tests/e2e/
git commit -m "tests: Update e2e tests for $(git log -1 --format=%s HEAD~1)"
```

**IMPORTANT:** Always prefix with `tests:` to prevent re-triggering this check.

## Rules

1. Always close playwright-cli when done (`playwright-cli close`)
2. Never modify application code — only test files and results
3. If the dev server isn't running, skip and record "skipped" status
4. Keep test steps simple and focused
5. One test file per feature/page
6. Test the happy path first, then critical error cases
