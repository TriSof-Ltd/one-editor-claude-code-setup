---
name: browser-test
description: Test the running web app in a real headless browser. Use after making UI changes, adding features, fixing bugs, or when the user asks to test/verify the app. Navigates pages, fills forms, checks console errors, network failures, and tracks results.
allowed-tools: Bash(playwright-cli:*)
---

# Browser Test

Test the user's running web app using Playwright CLI in a real headless browser. Use this after code changes to verify everything works.

## When to Use

- After building or modifying UI components
- After adding/changing routes or navigation
- After modifying forms or interactive elements
- After fixing bugs (verify the fix + check for regressions)
- When the user asks to test or verify the app
- Before telling the user a feature is "done"

## Prerequisites

The Vite dev server must be running at `http://localhost:5345`. Check with `pm2 list` — look for the `*-client` process. If it's not running, start it first.

## Testing Workflow

### Step 1: Open the browser and navigate

```bash
playwright-cli open http://localhost:5345
```

The browser runs headless by default (no `--headless` flag needed).

### Step 2: Take a snapshot to see what rendered

```bash
playwright-cli snapshot
```

Read the snapshot YAML file to see element refs (e.g., `e5`, `e12`). Only read when you need to find elements.

### Step 3: Check for console errors

```bash
playwright-cli console
```

Look for JavaScript errors, unhandled rejections, failed imports. Fix any errors found.

### Step 4: Check for network failures

```bash
playwright-cli network
```

Look for 4xx/5xx status codes, failed fetch requests, CORS errors.

### Step 5: Test interactions

Use element refs from the snapshot:

```bash
playwright-cli click e12
playwright-cli fill e8 "test@example.com"
playwright-cli fill e9 "password123"
playwright-cli click e15
playwright-cli snapshot   # check result
```

### Step 6: Test edge cases (adversarial testing)

Try to break the app:
- Submit empty forms
- Enter invalid data (wrong email format, special characters, very long strings)
- Double-click submit buttons rapidly
- Navigate away and back
- Test with no network data (empty states)
- Click elements that should be disabled
- Type very long strings (1000+ characters)
- Use special characters in inputs (<script>, ', ", &, etc.)

### Step 7: Test navigation/routing

```bash
playwright-cli goto http://localhost:5345/about
playwright-cli snapshot
playwright-cli go-back
playwright-cli snapshot
```

Test all routes. Verify direct URL access works (not just link clicks).

### Step 8: Take a screenshot if needed

```bash
playwright-cli screenshot
```

Only when visual verification is needed. Screenshots cost more tokens than snapshots.

### Step 9: Close when done

```bash
playwright-cli close
```

Always close to free RAM (~120MB).

## Tracking Results

After testing, write findings to `test-results.md` in the project root:

```markdown
## Test Run — [date and time]

### Page Load
- [PASS] Home page renders correctly
- [FAIL] Console error: "Cannot read property 'map' of undefined" in Dashboard.tsx
  - Fixed: Added null check on line 42
  - Retested: PASS

### Forms
- [PASS] Login form submits with valid data
- [FAIL] No validation error on empty email
  - Fixed: Added required attribute
  - Retested: PASS

### Navigation
- [PASS] All routes render without errors
- [PASS] Back/forward navigation works

### Edge Cases
- [PASS] Empty form submission shows errors
- [FAIL] Double-click creates duplicate entries
  - Fixed: Added loading state to disable button
  - Retested: PASS

### Console Errors: 0
### Network Failures: 0
```

## Fix-and-Retest Loop

When you find an issue:
1. Note it in test-results.md as [FAIL]
2. Fix the code
3. Wait 2 seconds for HMR to rebuild
4. Retest the specific failing scenario
5. Update test-results.md with the fix and retest result
6. Maximum 3 fix attempts per issue before marking as known issue

## Resource Notes

- Browser runs headless by default — no flags needed
- Always `playwright-cli close` when done (frees ~120MB RAM)
- Prefer `snapshot` over `screenshot` (10x fewer tokens)
- Don't keep the browser open between separate tasks
- One browser session per test run
- If browser seems stuck, run `playwright-cli close` then re-open

## Commands Quick Reference

| Command | Purpose |
|---------|---------|
| `open URL` | Launch browser and navigate |
| `snapshot` | Accessibility tree (structured, cheap) |
| `screenshot` | Visual capture (expensive, use sparingly) |
| `click REF` | Click element |
| `dblclick REF` | Double-click element |
| `fill REF "text"` | Clear input and type text |
| `type REF "text"` | Type text without clearing first |
| `hover REF` | Hover over element |
| `select REF "value"` | Select dropdown option |
| `check REF` / `uncheck REF` | Toggle checkbox |
| `console` | Show console log/warn/error |
| `network` | Show network requests |
| `goto URL` | Navigate to URL |
| `go-back` / `go-forward` | Browser history navigation |
| `reload` | Refresh page |
| `close` | Close browser and free RAM |
| `press KEY` | Press keyboard key (Enter, Tab, Escape) |
| `eval "js code"` | Run JavaScript on the page |
| `upload REF "path"` | Upload file to file input |
| `resize W H` | Change viewport size |
| `run-code "code"` | Run Playwright code snippet |
