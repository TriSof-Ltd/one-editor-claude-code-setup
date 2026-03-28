---
name: endpoint-test
description: Write and run unit tests for backend API endpoints. Every endpoint must have corresponding tests. Use when creating new API routes, modifying existing endpoints, or when the user asks to add tests.
allowed-tools: Bash, Read, Write, Edit
---

# Endpoint Test (Unit Tests)

Every API endpoint MUST have corresponding unit tests. When you create or modify an endpoint, write tests for it immediately.

## Test Framework

- **Runner**: vitest (already configured in `server/vitest.config.ts`)
- **Test location**: `server/api/__tests__/<feature>.test.ts`
- **Helpers**: `server/api/__tests__/setup.ts` provides `createTestApp()` and `request()`
- **Run tests**: `cd server && npm run test:run`

## Test Setup Helper

```typescript
import { describe, it, expect } from 'vitest'
import { createTestApp, request, authHeader } from './setup'

const app = createTestApp()
```

`createTestApp()` builds a fresh Express app with all routes and middleware — no server.listen(), no database connection required for route-level tests.

`request(app)` returns `{ get, post, put, patch, delete }` — each returns `{ status, body, headers }`.

## What to Test for Every Endpoint

### 1. Happy path
The endpoint works correctly with valid input.

```typescript
it('creates a note', async () => {
  const res = await request(app).post('/api/notes', { title: 'Test' }, { headers: authHeader('valid-token') })
  expect(res.status).toBe(201)
  expect(res.body.data).toHaveProperty('id')
})
```

### 2. Auth required
Protected endpoints reject unauthenticated requests.

```typescript
it('rejects unauthenticated request', async () => {
  const res = await request(app).get('/api/notes')
  expect(res.status).toBe(401)
})
```

### 3. Validation
Invalid input returns 400, not 500.

```typescript
it('rejects empty title', async () => {
  const res = await request(app).post('/api/notes', { title: '' }, { headers: authHeader('valid-token') })
  expect(res.status).toBe(400)
  expect(res.body).toHaveProperty('error')
})
```

### 4. Not found
Missing resources return 404.

```typescript
it('returns 404 for non-existent note', async () => {
  const res = await request(app).get('/api/notes/999', { headers: authHeader('valid-token') })
  expect(res.status).toBe(404)
})
```

### 5. Edge cases
- Very long strings
- Special characters in input
- Missing optional fields
- Duplicate creation
- Concurrent requests

## File Naming Convention

| Route file | Test file |
|---|---|
| `api/routes/noteRoutes.ts` | `api/__tests__/notes.test.ts` |
| `api/routes/authRoutes.ts` | `api/__tests__/auth.test.ts` |
| `api/routes/uploadRoutes.ts` | `api/__tests__/uploads.test.ts` |
| `api/middleware/validate.ts` | `api/__tests__/validate.test.ts` |

## Test Template

When creating tests for a new endpoint, use this template:

```typescript
import { describe, it, expect } from 'vitest'
import { createTestApp, request, authHeader } from './setup'

describe('FEATURE_NAME endpoints', () => {
  const app = createTestApp()

  describe('GET /api/RESOURCE', () => {
    it('returns 401 without auth', async () => {
      const res = await request(app).get('/api/RESOURCE')
      expect(res.status).toBe(401)
    })

    it('returns list with auth', async () => {
      const res = await request(app).get('/api/RESOURCE', { headers: authHeader('TOKEN') })
      expect(res.status).toBe(200)
      expect(Array.isArray(res.body.data)).toBe(true)
    })
  })

  describe('POST /api/RESOURCE', () => {
    it('returns 401 without auth', async () => {
      const res = await request(app).post('/api/RESOURCE', { field: 'value' })
      expect(res.status).toBe(401)
    })

    it('returns 400 with invalid data', async () => {
      const res = await request(app).post('/api/RESOURCE', {}, { headers: authHeader('TOKEN') })
      expect(res.status).toBe(400)
    })

    it('creates resource with valid data', async () => {
      const res = await request(app).post('/api/RESOURCE', { field: 'value' }, { headers: authHeader('TOKEN') })
      expect(res.status).toBe(201)
    })
  })

  describe('PUT /api/RESOURCE/:id', () => {
    it('returns 404 for non-existent resource', async () => {
      const res = await request(app).put('/api/RESOURCE/nonexistent', { field: 'new' }, { headers: authHeader('TOKEN') })
      expect(res.status).toBe(404)
    })
  })

  describe('DELETE /api/RESOURCE/:id', () => {
    it('returns 401 without auth', async () => {
      const res = await request(app).delete('/api/RESOURCE/1')
      expect(res.status).toBe(401)
    })
  })
})
```

## Running Tests

```bash
# Run all backend tests once
cd server && npm run test:run

# Run a specific test file
cd server && npx vitest run api/__tests__/notes.test.ts

# Run tests matching a pattern
cd server && npx vitest run --reporter=verbose 2>&1
```

## Rules

1. **Every new endpoint gets tests.** No exceptions. Write tests immediately after creating the route.
2. **Always test auth.** Every protected endpoint must have a "rejects without auth" test.
3. **Always test validation.** Every endpoint with a Zod schema must have "rejects invalid input" tests.
4. **Run tests after writing them.** Don't just write — verify they pass: `cd server && npm run test:run`
5. **Fix failing tests before moving on.** Never leave tests in a broken state.
6. **Tests must be independent.** Each test should work in isolation. Don't depend on test execution order.
