# Testing Rules

## Backend Endpoints
- Every API endpoint MUST have corresponding unit tests in `server/api/__tests__/`.
- When you create a new route file, immediately create its test file.
- Test at minimum: auth required (401), validation (400), happy path (200/201), not found (404).
- Run `cd server && npm run test:run` after writing tests to verify they pass.

## Browser E2E
- After making UI changes, use the browser-test skill to verify.
- Read `window.__oe` events instead of taking screenshots.
- Check for `t:"error"` and `t:"rejection"` events after every navigation.
- If any fetch returns `s:500`, check `pm2 logs` for the backend error.

## Before Merging to Main
- All backend tests must pass: `cd server && npm run test:run`
- Build must succeed: `npm run build`
- Never merge with failing tests.
