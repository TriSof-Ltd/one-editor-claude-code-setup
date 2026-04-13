---
name: b44-backend
description: Generate all backend API routes, services, and integration implementations for the converted Base44 app. Creates Hono routes, service layer, email/LLM/PDF endpoints. Requires b44-schema to have run first.
allowed-tools: Bash, Read, Write, Edit, Glob, Grep
---

# Base44 Backend Generator

You are the **Backend Generator**. Your job is to create the full API layer — routes, services, and integration endpoints — following the Hono patterns in the web-app-template.

---

## Prerequisites

1. Verify these exist:
   - `.claude/b44-analysis.json`
   - `detailed-architecture.md`
   - `server/api/db/*Repository.ts` — repositories from b44-schema
   - `server/api/schemas/*.ts` — Zod schemas from b44-schema
   - `server/api/types/*.ts` — TypeScript types from b44-schema

   If repositories don't exist: "Run /b44-schema first."

2. Read `.claude/b44-analysis.json` and `detailed-architecture.md`.
3. Read these template files to match patterns:
   - `server/api/routes/noteRoutes.ts` — route pattern
   - `server/api/services/noteService.ts` — service pattern (if exists)
   - `server/api/index.ts` — route mounting
   - `server/api/utils/auth.ts` — authenticate middleware

---

## Phase 1: Generate Services

For each entity, create `server/api/services/<entity>Service.ts`:

```typescript
import * as <entity>Repo from '../db/<entity>Repository'

export async function list<Entity>s(
  pagination: { limit: number; offset: number },
  filters: { search?: string; sort: string; order: 'asc' | 'desc' }
) {
  const { data, count } = await <entity>Repo.get<Entity>s({
    limit: pagination.limit,
    offset: pagination.offset,
    search: filters.search,
    sort: filters.sort,
    order: filters.order,
  })
  const totalPages = Math.ceil(count / pagination.limit)
  return {
    data,
    total: count,
    page: Math.floor(pagination.offset / pagination.limit) + 1,
    totalPages,
  }
}

export async function get<Entity>(id: string) {
  return <entity>Repo.get<Entity>ById(id)
}

export async function create<Entity>(fields: Parameters<typeof <entity>Repo.create<Entity>>[0]) {
  return <entity>Repo.create<Entity>(fields)
}

export async function update<Entity>(id: string, fields: Parameters<typeof <entity>Repo.update<Entity>>[1]) {
  return <entity>Repo.update<Entity>(id, fields)
}

export async function delete<Entity>(id: string) {
  return <entity>Repo.delete<Entity>(id)
}
```

Add additional methods matching the entity's operations:
- If `filter`: `export async function filter<Entity>s(filters, sort) { ... }`
- If `bulkCreate`: `export async function bulkCreate<Entity>s(items) { ... }`

---

## Phase 2: Generate Routes

For each entity, create `server/api/routes/<entity>Routes.ts`:

```typescript
import { Hono } from 'hono'
import { authenticate } from '../utils/auth'
import { create<Entity>Schema, update<Entity>Schema } from '../schemas/<entity>'
import * as <entity>Service from '../services/<entity>Service'

export const <entity>Routes = new Hono()

// GET /api/<entities> — list with pagination
<entity>Routes.get('/', authenticate, async (c) => {
  const url = new URL(c.req.url)
  const page = Math.max(1, parseInt(url.searchParams.get('page') || '1'))
  const limit = Math.min(100, Math.max(1, parseInt(url.searchParams.get('limit') || '50')))
  const offset = (page - 1) * limit
  const search = url.searchParams.get('search') || undefined
  const sort = url.searchParams.get('sort') || 'created_at'
  const order = (url.searchParams.get('order') || 'desc') as 'asc' | 'desc'

  const result = await <entity>Service.list<Entity>s({ limit, offset }, { search, sort, order })
  return c.json(result)
})

// GET /api/<entities>/:id
<entity>Routes.get('/:id', authenticate, async (c) => {
  const data = await <entity>Service.get<Entity>(c.req.param('id'))
  if (!data) return c.json({ error: 'Not found' }, 404)
  return c.json({ data })
})

// POST /api/<entities>
<entity>Routes.post('/', authenticate, async (c) => {
  const body = await c.req.json()
  const parsed = create<Entity>Schema.safeParse(body)
  if (!parsed.success) {
    return c.json({ error: 'Validation failed', details: parsed.error.flatten() }, 400)
  }
  const data = await <entity>Service.create<Entity>(parsed.data)
  return c.json({ data }, 201)
})

// PUT /api/<entities>/:id
<entity>Routes.put('/:id', authenticate, async (c) => {
  const body = await c.req.json()
  const parsed = update<Entity>Schema.safeParse(body)
  if (!parsed.success) {
    return c.json({ error: 'Validation failed', details: parsed.error.flatten() }, 400)
  }
  const data = await <entity>Service.update<Entity>(c.req.param('id'), parsed.data)
  if (!data) return c.json({ error: 'Not found' }, 404)
  return c.json({ data })
})

// DELETE /api/<entities>/:id
<entity>Routes.delete('/:id', authenticate, async (c) => {
  await <entity>Service.delete<Entity>(c.req.param('id'))
  return c.json({ message: 'Deleted' })
})
```

**Add extra endpoints based on entity operations:**

If `filter` operation exists:
```typescript
// GET /api/<entities>/filter?field=value&sort=-created_date
<entity>Routes.get('/filter', authenticate, async (c) => {
  const url = new URL(c.req.url)
  const filters: Record<string, string> = {}
  const reserved = ['sort', 'page', 'limit', 'order']
  for (const [key, value] of url.searchParams.entries()) {
    if (!reserved.includes(key)) filters[key] = value
  }
  const sort = url.searchParams.get('sort') || 'created_at'
  const data = await <entity>Service.filter<Entity>s(filters, sort)
  return c.json({ data })
})
```

If `bulkCreate` operation exists:
```typescript
// POST /api/<entities>/bulk
<entity>Routes.post('/bulk', authenticate, async (c) => {
  const items = await c.req.json()
  if (!Array.isArray(items)) return c.json({ error: 'Expected array' }, 400)
  const data = await <entity>Service.bulkCreate<Entity>s(items)
  return c.json({ data }, 201)
})
```

**IMPORTANT:** Place `/filter` and `/bulk` routes BEFORE `/:id` to avoid route conflicts.

---

## Phase 3: Generate Integration Routes

### 3.1 Email (Resend) — if SendEmail used

Create `server/api/routes/emailRoutes.ts`:

```typescript
import { Hono } from 'hono'
import { authenticate } from '../utils/auth'

export const emailRoutes = new Hono()

emailRoutes.post('/send', authenticate, async (c) => {
  const { to, subject, body } = await c.req.json()

  if (!to || !subject || !body) {
    return c.json({ error: 'Missing required fields: to, subject, body' }, 400)
  }

  const apiKey = process.env.RESEND_API_KEY
  if (!apiKey) {
    console.warn('RESEND_API_KEY not set — email not sent')
    return c.json({ message: 'Email skipped (no API key configured)' })
  }

  const response = await fetch('https://api.resend.com/emails', {
    method: 'POST',
    headers: {
      'Authorization': `Bearer ${apiKey}`,
      'Content-Type': 'application/json',
    },
    body: JSON.stringify({
      from: process.env.EMAIL_FROM || 'noreply@example.com',
      to: Array.isArray(to) ? to : [to],
      subject,
      html: body,
    }),
  })

  if (!response.ok) {
    const err = await response.json().catch(() => ({}))
    return c.json({ error: 'Email send failed', details: err }, 502)
  }

  const result = await response.json()
  return c.json({ message: 'Email sent', id: result.id })
})
```

### 3.2 LLM (Claude API) — if InvokeLLM or ExtractDataFromUploadedFile used

Create `server/api/routes/llmRoutes.ts`:

```typescript
import { Hono } from 'hono'
import { authenticate } from '../utils/auth'

export const llmRoutes = new Hono()

// POST /api/llm/invoke — general LLM call
llmRoutes.post('/invoke', authenticate, async (c) => {
  const { prompt, response_type } = await c.req.json()

  if (!prompt) return c.json({ error: 'Missing prompt' }, 400)

  const apiKey = process.env.ANTHROPIC_API_KEY
  if (!apiKey) {
    return c.json({ error: 'ANTHROPIC_API_KEY not configured' }, 503)
  }

  const response = await fetch('https://api.anthropic.com/v1/messages', {
    method: 'POST',
    headers: {
      'x-api-key': apiKey,
      'anthropic-version': '2023-06-01',
      'Content-Type': 'application/json',
    },
    body: JSON.stringify({
      model: 'claude-sonnet-4-20250514',
      max_tokens: 4096,
      messages: [{ role: 'user', content: prompt }],
    }),
  })

  if (!response.ok) {
    const err = await response.json().catch(() => ({}))
    return c.json({ error: 'LLM call failed', details: err }, 502)
  }

  const message = await response.json()
  const textContent = message.content?.find((b: { type: string }) => b.type === 'text')
  let result = textContent?.text || ''

  if (response_type === 'json') {
    try { result = JSON.parse(result) } catch { /* return raw text */ }
  }

  return c.json({ result })
})

// POST /api/llm/extract — extract data from uploaded document
llmRoutes.post('/extract', authenticate, async (c) => {
  const { file_url, json_schema } = await c.req.json()

  if (!file_url) return c.json({ error: 'Missing file_url' }, 400)

  const apiKey = process.env.ANTHROPIC_API_KEY
  if (!apiKey) {
    return c.json({ error: 'ANTHROPIC_API_KEY not configured' }, 503)
  }

  // Download file and convert to base64
  const fileResponse = await fetch(file_url)
  if (!fileResponse.ok) return c.json({ error: 'Failed to fetch file' }, 400)

  const buffer = Buffer.from(await fileResponse.arrayBuffer())
  const base64 = buffer.toString('base64')
  const mimeType = fileResponse.headers.get('content-type') || 'application/pdf'

  const prompt = json_schema
    ? `Extract data from this document according to this JSON schema: ${JSON.stringify(json_schema)}. Return only valid JSON.`
    : 'Extract all relevant data from this document. Return as structured JSON.'

  const response = await fetch('https://api.anthropic.com/v1/messages', {
    method: 'POST',
    headers: {
      'x-api-key': apiKey,
      'anthropic-version': '2023-06-01',
      'Content-Type': 'application/json',
    },
    body: JSON.stringify({
      model: 'claude-sonnet-4-20250514',
      max_tokens: 4096,
      messages: [{
        role: 'user',
        content: [
          { type: 'document', source: { type: 'base64', media_type: mimeType, data: base64 } },
          { type: 'text', text: prompt },
        ],
      }],
    }),
  })

  if (!response.ok) {
    const err = await response.json().catch(() => ({}))
    return c.json({ error: 'Extraction failed', details: err }, 502)
  }

  const message = await response.json()
  const textContent = message.content?.find((b: { type: string }) => b.type === 'text')

  try {
    return c.json({ data: JSON.parse(textContent?.text || '{}') })
  } catch {
    return c.json({ data: textContent?.text, raw: true })
  }
})
```

### 3.3 PDF (Puppeteer) — if screenshotToPdf or printExact used

Create `server/api/routes/pdfRoutes.ts`:

```typescript
import { Hono } from 'hono'
import { authenticate } from '../utils/auth'

export const pdfRoutes = new Hono()

pdfRoutes.post('/generate', authenticate, async (c) => {
  const { html, filename = 'document', options = {} } = await c.req.json()

  if (!html) return c.json({ error: 'Missing html' }, 400)

  try {
    const puppeteer = await import('puppeteer')
    const browser = await puppeteer.default.launch({
      headless: true,
      args: ['--no-sandbox', '--disable-setuid-sandbox'],
    })
    const page = await browser.newPage()

    await page.setContent(html, { waitUntil: 'networkidle0' })

    const pdfBuffer = await page.pdf({
      format: 'A4',
      printBackground: true,
      margin: { top: '12mm', right: '12mm', bottom: '12mm', left: '12mm' },
      ...options,
    })

    await browser.close()

    return new Response(pdfBuffer, {
      headers: {
        'Content-Type': 'application/pdf',
        'Content-Disposition': `attachment; filename="${filename}.pdf"`,
      },
    })
  } catch (err) {
    console.error('PDF generation failed:', err)
    return c.json({ error: 'PDF generation failed' }, 500)
  }
})
```

---

## Phase 4: Extend Auth

### 4.1 — Add GET /api/auth/me endpoint

Read `server/api/routes/authRoutes.ts` and add:

```typescript
// GET /api/auth/me — returns current user with profile
authRoutes.get('/me', authenticate, async (c) => {
  const user = c.get('user')
  const { rows } = await pool.query(
    `SELECT u.id, u.email, u.full_name, p.role as user_role, u.linked_driver_id
     FROM users u
     LEFT JOIN profiles p ON p.user_id = u.id
     WHERE u.id = $1`,
    [user.id]
  )
  if (!rows[0]) return c.json({ error: 'User not found' }, 404)
  return c.json({ data: rows[0] })
})
```

Import pool if not already imported.

### 4.2 — Add user model fields migration

If the analysis shows `linked_driver_id` or `full_name` on the user object, create a migration:

```sql
-- Extend users table for Base44 auth fields
ALTER TABLE users ADD COLUMN IF NOT EXISTS full_name TEXT;
ALTER TABLE users ADD COLUMN IF NOT EXISTS linked_driver_id UUID;
```

---

## Phase 5: Mount Routes

Edit `server/api/index.ts` to mount all new routes. Read the file first to understand the mounting pattern (it may use `app.route()` or a `mountRoute()` helper).

Add mounts for every entity + integration:

```typescript
import { customerRoutes } from './routes/customerRoutes'
// ... all entity routes

app.route('/api/customers', customerRoutes)
// ... all entity mounts

// Integration routes (only if the integration is used)
import { emailRoutes } from './routes/emailRoutes'
app.route('/api/email', emailRoutes)

import { llmRoutes } from './routes/llmRoutes'
app.route('/api/llm', llmRoutes)

import { pdfRoutes } from './routes/pdfRoutes'
app.route('/api/pdf', pdfRoutes)
```

Match the exact mounting pattern used by existing routes in the file.

---

## Phase 6: Update Environment

Edit `server/.env` to add new env vars (with empty defaults so the app doesn't crash):

```
# Integration API keys (optional — features degrade gracefully without them)
RESEND_API_KEY=
EMAIL_FROM=noreply@example.com
ANTHROPIC_API_KEY=
```

Also install any needed packages:
```bash
# Only if puppeteer is needed
cd server && npm install puppeteer --save 2>/dev/null || true
```

---

## Phase 7: Verify Build

```bash
cd server && npm run build 2>&1 | tail -20
```

Fix any errors. Common issues:
- Import paths wrong
- Missing route exports
- Type mismatches in service layer
- Hono route method signatures

---

## Phase 8: Summary

```
Backend Generation Complete:
- Routes: [N] entity route files + [K] integration route files
- Services: [N] entity service files
- Auth: Extended with GET /api/auth/me
- Integrations: [list mounted integration routes]
- Server build: [pass/fail]

Next step: Run /b44-frontend to convert the frontend.
(Also run /b44-seed if you want test data.)
```

---

## Rules

- Follow the exact Hono route pattern from `noteRoutes.ts`. Match function signatures, error handling, response formats.
- Always validate request bodies with Zod before processing.
- Integration routes must degrade gracefully when API keys are missing (warn, don't crash).
- Place `/filter` and `/bulk` routes BEFORE `/:id` to prevent route conflicts.
- Don't add role-based middleware unless the analysis explicitly shows role restrictions for that entity.
- Run the build check and fix errors before marking complete.
