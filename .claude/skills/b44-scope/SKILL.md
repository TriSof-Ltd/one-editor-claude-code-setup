---
name: b44-scope
description: Generate scope.md and detailed-architecture.md from a Base44 analysis. Maps entities to PostgreSQL tables, integrations to real services, routes to target conventions. Requires b44-analyze to have run first (reads .claude/b44-analysis.json).
allowed-tools: Bash, Read, Write, Edit, Glob, Grep, mcp__one-editor__ask_user
---

# Base44 Scope & Architecture Generator

You are the **Scope Generator**. Your job is to read the analysis from `b44-analyze` and produce two documents that all implementation skills will follow as their contract.

**You do NOT write application code. You ONLY produce `scope.md` and `detailed-architecture.md`.**

---

## Prerequisites

1. Verify `.claude/b44-analysis.json` exists. If not:
   > "Run /b44-analyze first — it produces the analysis file this skill needs."

2. Read `.claude/b44-analysis.json` completely.

3. Read these template reference files to understand the target patterns:
   - `server/api/routes/noteRoutes.ts` — route handler pattern
   - `server/api/db/noteRepository.ts` — repository pattern
   - `server/api/schemas/notes.ts` — Zod schema pattern
   - `src/store/pages/notes/slice.ts` — Redux slice pattern (if exists)
   - `src/routes/AppRoutes.tsx` — routing pattern
   - `src/lib/apiClient.ts` — API client pattern
   - `server/api/index.ts` — route mounting pattern

---

## Phase 1: Generate scope.md

Write `scope.md` in the project root with this structure:

```markdown
# Project Scope

## What This App Is
[1-2 paragraphs from analysis appDescription + entities + pages context]

## Converted From
Base44 project imported on [date]. Source at `.base44-source/`.

## Features

### Core Features
For each page/feature from the analysis:
- [ ] Feature Name — brief description of what it does
Group logically (e.g., "Job Management", "Customer CRM", "Invoicing")

### Skipped Features
List any features the user chose to skip during analysis Q&A.

## User Roles

| Role | Access | Description |
|------|--------|-------------|
For each role from analysis auth.roles, list which pages they can access.

## Data Model

### Entities
| Entity | Table Name | Key Fields | Relationships |
|--------|-----------|------------|---------------|
For each entity from analysis, summarize key fields and FKs.

## Integration Mapping

| Base44 Integration | Target Service | Backend Endpoint |
|-------------------|---------------|-----------------|
| SendEmail | Resend | POST /api/email/send |
| UploadFile | Supabase Storage / Local | POST /api/uploads |
| InvokeLLM | Claude API | POST /api/llm/invoke |
| ExtractDataFromUploadedFile | Claude API | POST /api/llm/extract |
| GenerateImage | Stub (501) | POST /api/image/generate |
| CreateFileSignedUrl | Storage service | POST /api/uploads/signed-url |

## Route Mapping

| Base44 Route | Target Route | Page |
|-------------|-------------|------|
For each page from analysis, show the route conversion.

## Build Phases

### Phase 1: Database & Schema (b44-schema)
- [ ] Generate migrations for all [N] entities
- [ ] Generate TypeScript types
- [ ] Generate Zod schemas
- [ ] Generate repositories
- [ ] Run migrations

### Phase 2: Backend API (b44-backend)
- [ ] Generate CRUD routes for all entities
- [ ] Generate services
- [ ] Implement email integration (Resend)
- [ ] Implement LLM integration (Claude API)
- [ ] Implement PDF generation (Puppeteer)
- [ ] Update route mounting

### Phase 3: Frontend (b44-frontend)
- [ ] Generate Redux store slices for all entities
- [ ] Extend API client
- [ ] Convert all pages (JSX → TSX)
- [ ] Convert all components
- [ ] Update navigation
- [ ] Update routes

### Phase 4: Data & Testing (b44-seed + b44-test)
- [ ] Generate seed scripts
- [ ] Generate API tests
- [ ] Generate component tests
- [ ] Verify build passes

## Out of Scope
- Pixel-perfect visual match (functional equivalent only)
- Base44-specific features with no equivalent (GenerateImage → stub)
- Mobile native app
- Real-time/WebSocket features (unless Base44 source uses them)
```

---

## Phase 2: Generate detailed-architecture.md

Write `detailed-architecture.md` in the project root. This is the **technical contract** that implementation skills follow exactly.

### Section 1: Database Schema

For EACH entity from the analysis, write the full CREATE TABLE SQL:

```markdown
## Database Schema

### Table: customers
```sql
CREATE TABLE IF NOT EXISTS customers (
  id UUID PRIMARY KEY DEFAULT gen_random_uuid(),
  [for each field in entity.fields:]
  field_name POSTGRES_TYPE [NOT NULL] [DEFAULT value],
  [end for]
  created_at TIMESTAMPTZ NOT NULL DEFAULT now(),
  updated_at TIMESTAMPTZ NOT NULL DEFAULT now()
);

CREATE INDEX IF NOT EXISTS idx_customers_[searchable_field] ON customers([field]);
[for each FK:]
-- FK: customer_id references customers(id)
[end]
```
```

**Type mapping rules** (from analysis inferredType to SQL):
| Inferred Type | PostgreSQL Type |
|---|---|
| `string` | `TEXT` |
| `number` | `NUMERIC(10,4)` for prices/money, `INTEGER` for counts |
| `boolean` | `BOOLEAN DEFAULT false` |
| `date` | `DATE` |
| `datetime` | `TIMESTAMPTZ` |
| `json_array` | `JSONB NOT NULL DEFAULT '[]'::jsonb` |
| `json_object` | `JSONB NOT NULL DEFAULT '{}'::jsonb` |
| `enum` | `TEXT CHECK (field IN ('val1','val2',...))` |
| `foreign_key` | `UUID REFERENCES other_table(id)` |

**Migration ordering:** Sort entities by FK dependencies — entities with no FKs first, then entities that reference those, etc. Number migrations sequentially starting after the last existing migration.

### Section 2: API Endpoints

For EACH entity, list all endpoints:

```markdown
## API Endpoints

### Customer Endpoints
| Method | Path | Auth | Roles | Body Schema | Description |
|--------|------|------|-------|------------|-------------|
| GET | /api/customers | yes | all | - | List (paginated, searchable) |
| GET | /api/customers/:id | yes | all | - | Get by ID |
| POST | /api/customers | yes | admin,user | createCustomerSchema | Create |
| PUT | /api/customers/:id | yes | admin,user | updateCustomerSchema | Update |
| DELETE | /api/customers/:id | yes | admin | - | Delete |
```

Add special endpoints where the analysis shows them:
- `GET /api/jobs/filter` — if filter operation used
- `POST /api/jobs/bulk` — if bulkCreate operation used

### Integration Endpoints
```markdown
### Integration Endpoints
| Method | Path | Auth | Description |
|--------|------|------|-------------|
| POST | /api/email/send | yes | Send email via Resend |
| POST | /api/llm/invoke | yes | Invoke Claude API |
| POST | /api/llm/extract | yes | Extract data from document via Claude |
| POST | /api/pdf/generate | yes | Generate PDF via Puppeteer |
| POST | /api/uploads/signed-url | yes | Get signed URL for file access |
```

### Section 3: File Structure

List EVERY file to be created, organized by layer:

```markdown
## Files to Create

### Database Layer
- server/migrations/NNN_create_<entity>.sql (one per entity, in order)
- server/api/types/<entity>.ts (one per entity)
- server/api/types/index.ts (updated barrel export)
- server/api/schemas/<entity>.ts (one per entity)
- server/api/schemas/index.ts (updated barrel export)
- server/api/db/<entity>Repository.ts (one per entity)
- server/api/db/index.ts (updated barrel export)

### Backend Layer
- server/api/routes/<entity>Routes.ts (one per entity)
- server/api/services/<entity>Service.ts (one per entity)
- server/api/routes/emailRoutes.ts (if SendEmail used)
- server/api/routes/llmRoutes.ts (if InvokeLLM/ExtractData used)
- server/api/routes/pdfRoutes.ts (if PDF generation used)
- server/api/index.ts (updated with route mounts)
- server/.env (updated with new env vars)

### Frontend Layer — Store
- src/store/pages/<entity>/types.ts (one per entity)
- src/store/pages/<entity>/thunks.ts
- src/store/pages/<entity>/slice.ts
- src/store/pages/<entity>/selectors.ts
- src/store/pages/<entity>/index.ts
- src/store/index.ts (updated with reducers)

### Frontend Layer — Types & API
- src/types/index.ts (updated with entity interfaces)
- src/lib/apiClient.ts (updated with entity methods)

### Frontend Layer — Pages & Components
- src/pages/dashboard/<route>/index.tsx (one per page)
- src/components/<entity>/<Component>.tsx (one per component)
- src/components/layout/app-sidebar.tsx (updated navigation)
- src/routes/AppRoutes.tsx (updated with new routes)

### Seed & Tests
- server/api/utils/seed.ts (seed script)
- server/api/__tests__/<entity>.test.ts (one per entity)
```

### Section 4: Redux Store Shape

```markdown
## Redux Store Shape

```typescript
{
  app: AppState,          // existing
  auth: AuthState,        // existing
  <entity>: {
    items: <Entity>[],
    total: number,
    page: number,
    totalPages: number,
    isLoading: boolean,
    error: string | null,
  },
  // ... one per entity
}
```
```

### Section 5: Auth Extensions

```markdown
## Auth Extensions

### User model additions
- full_name TEXT — from base44.auth.me().full_name
- linked_driver_id UUID REFERENCES drivers(id) — for driver-linked users

### New endpoint
GET /api/auth/me — returns { id, email, full_name, user_role, linked_driver_id }

### ProtectedRoute extension
Add `requiredRole?: string` prop to ProtectedRoute component.
Pages with role restrictions use: `<ProtectedRoute requiredRole="admin">`

### Role-page mapping
[table from analysis auth.roleRestrictedPages]
```

### Section 6: Component Mapping

```markdown
## Component Mapping

| Base44 Component | Target Component | Target Path |
|-----------------|-----------------|-------------|
For each component found in the analysis, map to target location.
```

### Section 7: Integration Implementation Specs

For each integration that maps to a real service, write the implementation spec:

```markdown
## Integration: Email (Resend)

### Backend
- Route: POST /api/email/send
- Service: server/api/services/emailService.ts
- Env: RESEND_API_KEY, EMAIL_FROM
- Request body: { to: string, subject: string, body: string }
- Uses Resend REST API: POST https://api.resend.com/emails

### Frontend
- Replace: `base44.integrations.Core.SendEmail({ to, subject, body })`
- With: `apiClient.email.send(to, subject, body)`

## Integration: LLM (Claude API)
[similar spec]

## Integration: PDF (Puppeteer)
[similar spec]
```

---

## Phase 3: Confirmation

Ask 1-2 questions via `mcp__one-editor__ask_user`:

**Question 1:**
> "I've generated the scope and architecture. [N] entities, [M] pages, [K] API endpoints planned. Ready to start conversion?"
> Options: "Yes, start conversion", "I want to review changes first", "I want to modify something"

If they want modifications, ask what to change and update the files.

---

## Phase 4: Summary

Output:

```
Scope & Architecture Complete:
- scope.md — project overview, features, build phases
- detailed-architecture.md — full technical spec

Next steps (run in order):
1. /b44-schema — Generate database layer
2. /b44-backend — Generate API layer
3. /b44-seed — Generate seed data (can run parallel with backend)
4. /b44-frontend — Convert frontend
5. /b44-test — Generate tests
```

---

## Rules

- Follow the analysis JSON exactly. Don't add entities or fields that aren't in the analysis.
- Every entity must have entries in ALL sections (schema, endpoints, files, store).
- The detailed-architecture.md is the contract — implementation skills follow it literally.
- Migration numbering: check `ls server/migrations/` and continue the sequence.
- Use the template reference files to ensure generated specs match existing patterns.
- If the analysis has `skippedFeatures`, exclude those from both documents.
