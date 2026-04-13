---
name: b44-schema
description: Generate all database migrations, TypeScript types, Zod validation schemas, and repository files for every entity from the Base44 analysis. Creates the full data layer. Requires b44-scope to have run first.
allowed-tools: Bash, Read, Write, Edit, Glob, Grep
---

# Base44 Schema Generator

You are the **Schema Generator**. Your job is to create the entire data layer for the converted app — migrations, types, schemas, and repositories — following the patterns established in the web-app-template.

---

## Prerequisites

1. Verify these files exist:
   - `.claude/b44-analysis.json` — entity definitions
   - `detailed-architecture.md` — SQL schemas and file list

   If missing: "Run /b44-analyze and /b44-scope first."

2. Read both files completely.
3. Read these template reference files to match patterns exactly:
   - `server/api/db/noteRepository.ts` — repository CRUD pattern
   - `server/api/schemas/notes.ts` — Zod schema pattern
   - `server/api/types/notes.ts` or equivalent — TypeScript type pattern
   - `server/api/db/index.ts` — barrel export pattern

---

## Phase 1: Determine Migration Numbering

```bash
ls server/migrations/ 2>/dev/null | sort | tail -1
```

Extract the highest number. New migrations start at the next number. If no migrations exist, start at `001`.

---

## Phase 2: Generate Migrations

For each entity from the analysis (in **FK dependency order** — entities with no foreign keys first):

Create `server/migrations/NNN_create_<table_name>.sql`:

```sql
-- Create <table_name> table
CREATE TABLE IF NOT EXISTS <table_name> (
  id UUID PRIMARY KEY DEFAULT gen_random_uuid(),
  <for each field from analysis:>
  <field_name> <POSTGRES_TYPE> [NOT NULL] [DEFAULT <value>] [CHECK (...)],
  <for each FK field:>
  <field_name> UUID REFERENCES <referenced_table>(id),
  created_at TIMESTAMPTZ NOT NULL DEFAULT now(),
  updated_at TIMESTAMPTZ NOT NULL DEFAULT now()
);

<for each searchable/filterable field:>
CREATE INDEX IF NOT EXISTS idx_<table>_<field> ON <table_name>(<field>);
```

**Automatic additions:**
- `id UUID PRIMARY KEY DEFAULT gen_random_uuid()` — always first
- `created_at TIMESTAMPTZ NOT NULL DEFAULT now()` — always last-2
- `updated_at TIMESTAMPTZ NOT NULL DEFAULT now()` — always last

**Type mapping from analysis:**
| `inferredType` | PostgreSQL |
|---|---|
| `string` | `TEXT` |
| `number` | `NUMERIC(10,4)` for prices, `INTEGER` for counts/quantities |
| `boolean` | `BOOLEAN NOT NULL DEFAULT false` |
| `date` | `DATE` |
| `datetime` | `TIMESTAMPTZ` |
| `json_array` | `JSONB NOT NULL DEFAULT '[]'::jsonb` |
| `json_object` | `JSONB NOT NULL DEFAULT '{}'::jsonb` |
| `enum` | `TEXT NOT NULL DEFAULT '<first_value>' CHECK (<field> IN (<values>))` |
| `foreign_key` | `UUID REFERENCES <table>(id)` |

**Required vs optional:** Fields marked `required: true` in the analysis get `NOT NULL`. Others are nullable.

---

## Phase 3: Generate TypeScript Types

For each entity, create `server/api/types/<entity_snake>.ts`:

```typescript
export interface <EntityName>Row {
  id: string
  <for each field:>
  <field_name>: <ts_type>
  created_at: string
  updated_at: string
}
```

**Type mapping:**
| PostgreSQL | TypeScript |
|---|---|
| `TEXT` | `string` |
| `NUMERIC`, `INTEGER` | `number` |
| `BOOLEAN` | `boolean` |
| `DATE`, `TIMESTAMPTZ` | `string` |
| `JSONB` (array) | `unknown[]` or typed array if known |
| `JSONB` (object) | `Record<string, unknown>` or typed if known |
| `UUID` (FK) | `string` |
| nullable field | `<type> \| null` |

Update `server/api/types/index.ts` to re-export all new types.

---

## Phase 4: Generate Zod Schemas

For each entity, create `server/api/schemas/<entity_snake>.ts`:

```typescript
import { z } from 'zod'

export const create<EntityName>Schema = z.object({
  <for each field (excluding id, created_at, updated_at):>
  <field_name>: <zod_validator>,
})

export const update<EntityName>Schema = create<EntityName>Schema.partial()
```

**Zod mapping:**
| PostgreSQL | Zod |
|---|---|
| `TEXT NOT NULL` | `z.string().min(1).max(500)` |
| `TEXT` (nullable) | `z.string().max(500).optional().nullable()` |
| `NUMERIC` | `z.number()` or `z.coerce.number()` |
| `BOOLEAN` | `z.boolean().optional().default(false)` |
| `DATE` | `z.string().optional().nullable()` |
| `TIMESTAMPTZ` | `z.string().datetime().optional().nullable()` |
| `JSONB` (array) | `z.array(z.unknown()).optional().default([])` |
| `JSONB` (object) | `z.record(z.unknown()).optional().default({})` |
| `TEXT CHECK (IN ...)` | `z.enum(['val1', 'val2', ...])` |
| `UUID REFERENCES` | `z.string().uuid().optional().nullable()` |

Update `server/api/schemas/index.ts` to re-export all new schemas.

---

## Phase 5: Generate Repositories

For each entity, create `server/api/db/<entity_snake>Repository.ts` following the `noteRepository.ts` pattern exactly:

```typescript
import pool from './pool'
import type { <EntityName>Row } from '../types/<entity_snake>'

const ALLOWED_SORT_COLUMNS = ['created_at', 'updated_at', '<searchable fields>']

export async function get<EntityName>s(options: {
  limit: number
  offset: number
  search?: string
  sort: string
  order: 'asc' | 'desc'
}) {
  const params: unknown[] = []
  let where = 'WHERE 1=1'

  if (options.search) {
    const safe = options.search.replace(/[^a-zA-Z0-9\s\-'.]/g, '').trim().slice(0, 100)
    if (safe.length > 0) {
      params.push(`%${safe}%`)
      where += ` AND (<searchable_field> ILIKE $${params.length})`
    }
  }

  const sortCol = ALLOWED_SORT_COLUMNS.includes(options.sort) ? options.sort : 'created_at'
  const sortDir = options.order === 'asc' ? 'ASC' : 'DESC'

  const countResult = await pool.query(`SELECT COUNT(*) FROM <table> ${where}`, params)
  const count = parseInt(countResult.rows[0].count)

  params.push(options.limit, options.offset)
  const dataResult = await pool.query(
    `SELECT * FROM <table> ${where} ORDER BY ${sortCol} ${sortDir} LIMIT $${params.length - 1} OFFSET $${params.length}`,
    params
  )

  return { data: dataResult.rows as <EntityName>Row[], count }
}

export async function get<EntityName>ById(id: string) {
  const { rows } = await pool.query('SELECT * FROM <table> WHERE id = $1', [id])
  return (rows[0] as <EntityName>Row) || null
}

export async function create<EntityName>(fields: Omit<<EntityName>Row, 'id' | 'created_at' | 'updated_at'>) {
  const keys = Object.keys(fields).filter(k => (fields as Record<string, unknown>)[k] !== undefined)
  const values = keys.map(k => (fields as Record<string, unknown>)[k])
  const placeholders = keys.map((_, i) => `$${i + 1}`)
  const { rows } = await pool.query(
    `INSERT INTO <table> (${keys.join(', ')}) VALUES (${placeholders.join(', ')}) RETURNING *`,
    values
  )
  return rows[0] as <EntityName>Row
}

export async function update<EntityName>(id: string, fields: Partial<<EntityName>Row>) {
  const sets: string[] = []
  const params: unknown[] = []
  let i = 1
  for (const [key, value] of Object.entries(fields)) {
    if (key !== 'id' && key !== 'created_at' && value !== undefined) {
      sets.push(`${key} = $${i++}`)
      params.push(value)
    }
  }
  sets.push('updated_at = now()')
  params.push(id)
  const { rows } = await pool.query(
    `UPDATE <table> SET ${sets.join(', ')} WHERE id = $${i} RETURNING *`,
    params
  )
  return (rows[0] as <EntityName>Row) || null
}

export async function delete<EntityName>(id: string) {
  await pool.query('DELETE FROM <table> WHERE id = $1', [id])
}
```

**Additional methods per entity:**

If entity has `filter` operation:
```typescript
export async function filter<EntityName>s(filters: Record<string, string>, sort: string) {
  // Build WHERE from filters, handle "-field" sort convention
}
```

If entity has `bulkCreate` operation:
```typescript
export async function bulkCreate<EntityName>s(items: Omit<<EntityName>Row, 'id' | 'created_at' | 'updated_at'>[]) {
  // INSERT multiple rows in a transaction
}
```

Update `server/api/db/index.ts` to re-export all new repositories.

---

## Phase 6: Run Migrations

```bash
cd server && DATABASE_URL=$(grep DATABASE_URL .env | cut -d= -f2-) npx ts-node api/utils/migrate.ts
```

If migrate.ts doesn't exist or uses a different approach, check how existing migrations are run:
```bash
grep -r "migrate" server/package.json
```

---

## Phase 7: Verify Build

```bash
cd server && npm run build 2>&1 | tail -20
```

If there are TypeScript errors, fix them. Common issues:
- Missing imports in barrel exports
- Type mismatches between repository return types and interfaces
- Pool import path differences

---

## Phase 8: Summary

```
Schema Generation Complete:
- Migrations: [N] files created (NNN_create_*.sql)
- Types: [N] interface files
- Schemas: [N] Zod validation files
- Repositories: [N] CRUD repository files
- Migrations applied: [yes/no]
- Server build: [pass/fail]

Next step: Run /b44-backend to generate API routes and services.
```

---

## Rules

- Follow `detailed-architecture.md` exactly for SQL schemas. Don't deviate.
- Match the `noteRepository.ts` pattern precisely — same function signatures, same query patterns.
- Every entity gets all 5 files: migration, type, schema, repository, barrel export update.
- FK dependency order matters for migrations — referenced tables must exist first.
- Run the build check and fix any errors before marking complete.
- Use the `b44-entity-converter` agent for parallel generation when there are 5+ entities.
