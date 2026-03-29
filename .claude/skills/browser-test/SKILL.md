---
name: browser-test
description: End-to-end test the running web app in a real headless browser. Use after making UI changes, adding features, fixing bugs, or when the user asks to test/verify the app. Uses structured [OE] events from the console instead of screenshots.
allowed-tools: Bash(playwright-cli:*)
---

# Browser Test (E2E)

Test the user's running web app using playwright-cli. The app instruments fetch, routing, and errors automatically — every action produces structured `[OE]` events in the console. Read those events to verify behavior. No screenshots needed.

## When to Use

- After building or modifying UI components
- After adding/changing routes or navigation
- After modifying forms or interactive elements
- After fixing bugs (verify the fix + check for regressions)
- When the user asks to test or verify the app
- Before telling the user a feature is "done"

## Prerequisites

The Vite dev server must be running at `http://localhost:5345`. Check with `pm2 list`.

## How It Works

The app's `index.html` automatically patches `fetch`, `XMLHttpRequest`, `history.pushState`, `window.onerror`, and `unhandledrejection`. Every event is:
1. Logged to console as `[OE] {"t":"fetch","m":"POST","u":"/api/notes","s":201,...}`
2. Stored in `window.__oe` array for batch reading

After each interaction, read new events with:
```bash
playwright-cli eval "JSON.stringify(window.__oe.splice(0))"
```
This reads AND clears the buffer — you only get events since the last read.

## Event Types

| `t` value | Meaning | Key fields |
|-----------|---------|------------|
| `fetch` | API call completed | `m`=method, `u`=url, `s`=status, `d`=duration_ms, `ok`, `b`=body preview |
| `fetch_err` | API call failed (network) | `m`, `u`, `err`=error message |
| `xhr` | XMLHttpRequest completed | same as fetch |
| `xhr_err` | XMLHttpRequest failed | same as fetch_err |
| `error` | Uncaught JS error | `msg`, `src`=file:line, `stack` |
| `rejection` | Unhandled promise rejection | `msg`, `stack` |

## Testing Workflow

### Step 1: Open and check initial load

```bash
playwright-cli open http://localhost:5345
playwright-cli eval "JSON.stringify(window.__oe.splice(0))"
```

Check: any `t:"error"` or `t:"rejection"`? Any `t:"fetch"` with `ok:false`?

### Step 2: Interact and verify

```bash
playwright-cli snapshot                    # find element refs
playwright-cli click e12                   # interact
playwright-cli eval "JSON.stringify(window.__oe.splice(0))"   # what happened?
```

After clicking a "Create" button, you should see:
```json
[{"t":"fetch","m":"POST","u":"/api/notes","s":201,"d":89,"ok":true,"b":"{\"id\":5}"},
 {"t":"route","from":"/notes","to":"/notes/5"}]
```

### Step 3: Check for backend errors

If any fetch shows `s:500` or `ok:false`, check the Express server logs:

```bash
pm2 logs $(pm2 jlist | node -e "let d='';process.stdin.on('data',c=>d+=c);process.stdin.on('end',()=>{const l=JSON.parse(d);const s=l.find(p=>p.name.endsWith('-server'));console.log(s?s.name:'dev-server')})") --err --lines 30 --nostream 2>&1
```

Look for stack traces, database errors, unhandled rejections.

### Step 4: Test edge cases (adversarial)

Try to break the app:
- Submit empty forms → check for validation errors (NOT 500s)
- Enter `<script>alert(1)</script>` in text fields → check XSS handling
- Enter very long strings (1000+ chars)
- Double-click submit buttons rapidly → check for duplicate submissions
- Navigate directly to protected routes without auth
- Navigate to non-existent routes → should show 404, not crash

### Step 5: Test all routes

```bash
playwright-cli goto http://localhost:5345/dashboard
playwright-cli eval "JSON.stringify(window.__oe.splice(0))"
playwright-cli goto http://localhost:5345/settings
playwright-cli eval "JSON.stringify(window.__oe.splice(0))"
```

Every route should: load without errors, make correct API calls, show expected content.

### Step 6: Close

```bash
playwright-cli close
```

Always close to free RAM.

## Decision Rules

| Event | Verdict | Action |
|-------|---------|--------|
| `fetch` with `ok:true` | PASS | Continue |
| `fetch` with `s:400` | Check | Expected validation error? If yes: PASS. If no: fix. |
| `fetch` with `s:401/403` | Check | Expected auth error? If yes: PASS. If no: fix auth. |
| `fetch` with `s:500` | FAIL | Check pm2 logs, fix backend, retest |
| `fetch_err` (network) | FAIL | Server down? Check pm2 status |
| `error` or `rejection` | FAIL | Fix the JS error, retest |
| No events after action | WARN | Action may not have triggered anything — use snapshot to verify DOM |

**Route changes**: Vite resets JS context on SPA navigation, so route events don't appear in `__oe`. Instead, check the `Page URL:` line that playwright-cli prints after every interaction.

## Fix-and-Retest Loop

1. Note the failure in test-results.md
2. Fix the code
3. Wait 2s for HMR to rebuild
4. `playwright-cli eval "window.__oe.splice(0)"` — clear stale events
5. Retest the specific scenario
6. Update test-results.md

## Tracking Results

Write to `test-results.md` in the project root:

```markdown
## E2E Test — [date]

### Page Load: /
- [PASS] No JS errors
- [PASS] GET /api/health → 200 (45ms)

### Create Note
- [PASS] POST /api/notes → 201 (89ms)
- [PASS] Route changed to /notes/5

### Delete Note
- [FAIL] DELETE /api/notes/5 → 500 (12ms)
  - Backend: "relation notes does not exist"
  - Fixed: ran migration
  - Retested: PASS

### Edge Cases
- [PASS] Empty form → 400 validation error (not 500)
- [PASS] XSS input sanitized
- [PASS] Direct /admin route → redirected to /auth/signin
```

## Commands Quick Reference

| Command | Purpose |
|---------|---------|
| `open URL` | Launch browser and navigate |
| `eval "JS"` | Run JavaScript, read `window.__oe` |
| `snapshot` | DOM accessibility tree (find element refs) |
| `click REF` | Click element |
| `fill REF "text"` | Fill input |
| `console` | Full console output (alternative to eval) |
| `goto URL` | Navigate to URL |
| `go-back` | Browser back |
| `close` | Close browser, free RAM |
