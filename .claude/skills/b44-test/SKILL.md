---
name: b44-test
description: Generate API endpoint tests and component tests for the converted Base44 app. Creates vitest tests for all backend routes and key frontend components. Requires b44-backend and b44-frontend to have run first.
allowed-tools: Bash, Read, Write, Edit, Glob, Grep
---

# Base44 Test Generator

You are the **Test Generator**. Your job is to create comprehensive tests for the converted application — API endpoint tests for every entity and component tests for key dialogs.

---

## Prerequisites

1. Verify these exist:
   - `.claude/b44-analysis.json`
   - `server/api/routes/*Routes.ts` — backend routes
   - `src/pages/dashboard/*/index.tsx` — converted pages

   If routes don't exist: "Run /b44-backend and /b44-frontend first."

2. Read `.claude/b44-analysis.json` for entity list.
3. Check existing test patterns:
   ```bash
   ls server/api/__tests__/ 2>/dev/null
   cat server/vitest.config.ts 2>/dev/null || cat server/vitest.config.js 2>/dev/null
   ```

---

## Phase 1: API Endpoint Tests

For each entity, create `server/api/__tests__/<entity>.test.ts`:

```typescript
import { describe, it, expect, beforeAll } from 'vitest'

const API_URL = process.env.API_URL || 'http://localhost:3030'
let authToken: string

// Helper to get auth token
async function getAuthToken(): Promise<string> {
  const response = await fetch(`${API_URL}/api/auth/login`, {
    method: 'POST',
    headers: { 'Content-Type': 'application/json' },
    body: JSON.stringify({ email: 'admin@example.com', password: 'admin123' }),
  })
  const data = await response.json()
  return data.token || data.data?.token || ''
}

function authHeaders() {
  return {
    'Authorization': `Bearer ${authToken}`,
    'Content-Type': 'application/json',
  }
}

beforeAll(async () => {
  authToken = await getAuthToken()
})

describe('<Entity> API', () => {
  let createdId: string

  // AUTH TESTS
  it('GET /api/<entities> requires authentication', async () => {
    const response = await fetch(`${API_URL}/api/<entities>`)
    expect(response.status).toBe(401)
  })

  // LIST TEST
  it('GET /api/<entities> returns paginated list', async () => {
    const response = await fetch(`${API_URL}/api/<entities>`, {
      headers: authHeaders(),
    })
    expect(response.status).toBe(200)
    const body = await response.json()
    expect(body).toHaveProperty('data')
    expect(body).toHaveProperty('total')
    expect(body).toHaveProperty('page')
    expect(Array.isArray(body.data)).toBe(true)
  })

  // PAGINATION TEST
  it('GET /api/<entities>?page=1&limit=2 respects pagination', async () => {
    const response = await fetch(`${API_URL}/api/<entities>?page=1&limit=2`, {
      headers: authHeaders(),
    })
    expect(response.status).toBe(200)
    const body = await response.json()
    expect(body.data.length).toBeLessThanOrEqual(2)
  })

  // CREATE - VALIDATION FAIL
  it('POST /api/<entities> validates required fields', async () => {
    const response = await fetch(`${API_URL}/api/<entities>`, {
      method: 'POST',
      headers: authHeaders(),
      body: JSON.stringify({}),
    })
    expect(response.status).toBe(400)
  })

  // CREATE - SUCCESS
  it('POST /api/<entities> creates a record', async () => {
    const response = await fetch(`${API_URL}/api/<entities>`, {
      method: 'POST',
      headers: authHeaders(),
      body: JSON.stringify({
        // Include all required fields with valid test values
        <required_field>: '<test_value>',
      }),
    })
    expect(response.status).toBe(201)
    const body = await response.json()
    expect(body.data).toHaveProperty('id')
    expect(body.data.<required_field>).toBe('<test_value>')
    createdId = body.data.id
  })

  // GET BY ID
  it('GET /api/<entities>/:id returns the record', async () => {
    const response = await fetch(`${API_URL}/api/<entities>/${createdId}`, {
      headers: authHeaders(),
    })
    expect(response.status).toBe(200)
    const body = await response.json()
    expect(body.data.id).toBe(createdId)
  })

  // GET BY ID - NOT FOUND
  it('GET /api/<entities>/nonexistent returns 404', async () => {
    const response = await fetch(`${API_URL}/api/<entities>/00000000-0000-0000-0000-000000000000`, {
      headers: authHeaders(),
    })
    expect(response.status).toBe(404)
  })

  // UPDATE
  it('PUT /api/<entities>/:id updates the record', async () => {
    const response = await fetch(`${API_URL}/api/<entities>/${createdId}`, {
      method: 'PUT',
      headers: authHeaders(),
      body: JSON.stringify({ <required_field>: '<updated_value>' }),
    })
    expect(response.status).toBe(200)
    const body = await response.json()
    expect(body.data.<required_field>).toBe('<updated_value>')
  })

  // DELETE
  it('DELETE /api/<entities>/:id deletes the record', async () => {
    const response = await fetch(`${API_URL}/api/<entities>/${createdId}`, {
      method: 'DELETE',
      headers: authHeaders(),
    })
    expect(response.status).toBe(200)
  })

  // VERIFY DELETE
  it('GET /api/<entities>/:id returns 404 after delete', async () => {
    const response = await fetch(`${API_URL}/api/<entities>/${createdId}`, {
      headers: authHeaders(),
    })
    expect(response.status).toBe(404)
  })
})
```

**For each entity**, customize:
- The required fields in the CREATE test (from analysis entity.fields where required=true)
- The test values (realistic but clearly test data)
- Any role-restricted endpoints (add 403 tests)
- Any special endpoints (filter, bulk)

### Integration endpoint tests

If integration routes exist, add `server/api/__tests__/integrations.test.ts`:

```typescript
describe('Integration Endpoints', () => {
  it('POST /api/email/send validates required fields', async () => {
    const response = await fetch(`${API_URL}/api/email/send`, {
      method: 'POST',
      headers: authHeaders(),
      body: JSON.stringify({}),
    })
    expect(response.status).toBe(400)
  })

  it('POST /api/llm/invoke validates prompt', async () => {
    const response = await fetch(`${API_URL}/api/llm/invoke`, {
      method: 'POST',
      headers: authHeaders(),
      body: JSON.stringify({}),
    })
    expect(response.status).toBe(400)
  })
})
```

---

## Phase 2: Run API Tests

```bash
cd server && npm run test:run 2>&1
```

**IMPORTANT:** The dev server must be running for integration tests. Check first:
```bash
curl -s http://localhost:3030/api/health 2>/dev/null || echo "Server not running"
```

If tests fail:
1. Read the error output
2. Fix the test or the code (prefer fixing tests for assertion issues, fix code for real bugs)
3. Re-run tests
4. Repeat up to 3 times

---

## Phase 3: Component Tests (Key Dialogs)

For the 3-5 most important dialog components, create `src/components/<entity>/__tests__/<Component>.test.tsx`:

```typescript
import { describe, it, expect, vi } from 'vitest'
import { render, screen } from '@testing-library/react'
import { Provider } from 'react-redux'
import { configureStore } from '@reduxjs/toolkit'
import <ComponentName> from '../<ComponentName>'

// Create a minimal mock store
function createMockStore() {
  return configureStore({
    reducer: {
      <entity>s: (state = { items: [], isLoading: false, error: null }) => state,
      auth: (state = { user: { id: '1', email: 'test@test.com', user_role: 'admin' } }) => state,
    },
  })
}

describe('<ComponentName>', () => {
  it('renders without crashing', () => {
    const store = createMockStore()
    render(
      <Provider store={store}>
        <<ComponentName> open={true} onOpenChange={vi.fn()} />
      </Provider>
    )
    // Check that key elements are present
    expect(screen.getByRole('dialog')).toBeInTheDocument()
  })

  it('displays form fields', () => {
    const store = createMockStore()
    render(
      <Provider store={store}>
        <<ComponentName> open={true} onOpenChange={vi.fn()} />
      </Provider>
    )
    // Check for key form fields
    expect(screen.getByLabelText(/<required_field_label>/i)).toBeInTheDocument()
  })
})
```

Only generate component tests for:
- Create dialogs (most important — validates form rendering)
- Main page components (verifies they render with store data)
- Skip utility components, list items, and simple display components

---

## Phase 4: Run All Tests

```bash
cd server && npm run test:run 2>&1
```

Report results:
```
Test Results:
- Total: [N] tests
- Passed: [N]
- Failed: [N]
- [list any failures with brief description]
```

---

## Phase 5: Summary

```
Test Generation Complete:
- API test files: [N] (one per entity + integrations)
- Component test files: [M] (key dialogs)
- Total test cases: [T]
- Pass rate: [X/T]

All b44-* skills complete! The converted app is ready.
Verify by accessing the app in the browser and testing key workflows.
```

---

## Rules

- Tests must be integration tests (hitting the real API), not mocked unit tests.
- Use realistic but clearly fake test data (no real emails or phone numbers).
- Each test file is self-contained — creates its own test data.
- Clean up: DELETE tests should clean up created records.
- Don't test shadcn/ui components themselves — only test the custom app components.
- If the dev server isn't running, note it and skip API tests (they need a running server).
- Focus on the critical paths: CRUD for each entity, auth, validation.
