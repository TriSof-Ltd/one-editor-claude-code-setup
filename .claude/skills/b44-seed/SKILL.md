---
name: b44-seed
description: Generate database seed scripts from Base44 AdminSetup patterns. Creates test users and realistic sample data for all entities. Requires b44-schema to have run first (needs repositories).
allowed-tools: Bash, Read, Write, Edit, Glob, Grep
---

# Base44 Seed Data Generator

You are the **Seed Generator**. Your job is to create a seed script that populates the database with realistic test data, mirroring what the Base44 AdminSetup page created.

---

## Prerequisites

1. Verify these exist:
   - `.claude/b44-analysis.json` — with seedData section
   - `server/api/db/*Repository.ts` — repositories from b44-schema
   - `.base44-source/src/pages/AdminSetup.jsx` — if seedData exists in analysis

   If repositories don't exist: "Run /b44-schema first."

2. Read `.claude/b44-analysis.json` — check `seedData` section.
3. If `seedData` is null, output: "No AdminSetup found in Base44 source — no seed data to generate." and stop.

---

## Phase 1: Read AdminSetup Source

Read `.base44-source/src/pages/AdminSetup.jsx` completely.

Extract:
1. **Entity creation order** — which entities are created first (FK dependencies)
2. **Template data** — the literal objects passed to `.create()` and `.bulkCreate()`
3. **Record counts** — how many records per entity
4. **Dynamic values** — dates relative to "now", random selections, etc.
5. **Dependencies** — where created records reference other records (e.g., job references customer)

---

## Phase 2: Generate Seed Script

Create or update `server/api/utils/seed.ts`:

```typescript
import pool from '../db/pool'

async function seed() {
  console.log('Seeding database...')

  // Phase 1: Create test users
  const bcrypt = await import('bcryptjs')

  const adminHash = await bcrypt.hash('admin123', 12)
  const userHash = await bcrypt.hash('user123', 12)
  const driverHash = await bcrypt.hash('driver123', 12)

  // Insert admin user
  const { rows: [admin] } = await pool.query(
    `INSERT INTO users (email, password_hash, full_name)
     VALUES ($1, $2, $3)
     ON CONFLICT (email) DO UPDATE SET full_name = EXCLUDED.full_name
     RETURNING id`,
    ['admin@example.com', adminHash, 'Admin User']
  )
  await pool.query(
    `INSERT INTO profiles (user_id, role, display_name)
     VALUES ($1, $2, $3)
     ON CONFLICT (user_id) DO UPDATE SET role = EXCLUDED.role`,
    [admin.id, 'admin', 'Admin User']
  )

  // Insert regular user
  const { rows: [regularUser] } = await pool.query(
    `INSERT INTO users (email, password_hash, full_name)
     VALUES ($1, $2, $3)
     ON CONFLICT (email) DO UPDATE SET full_name = EXCLUDED.full_name
     RETURNING id`,
    ['user@example.com', userHash, 'Regular User']
  )
  await pool.query(
    `INSERT INTO profiles (user_id, role, display_name)
     VALUES ($1, $2, $3)
     ON CONFLICT (user_id) DO UPDATE SET role = EXCLUDED.role`,
    [regularUser.id, 'user', 'Regular User']
  )

  // Insert driver user (if driver role exists)
  // ... similar pattern

  // Phase 2: Seed entities in FK dependency order
  // [Generate INSERT statements from AdminSetup template data]

  // For each entity, use the repository or direct SQL:
  const { rows: [customer1] } = await pool.query(
    `INSERT INTO customers (company_name, contact_name, contact_number, credit_terms)
     VALUES ($1, $2, $3, $4)
     ON CONFLICT DO NOTHING
     RETURNING id`,
    ['Example Corp', 'John Smith', '01234567890', '30_days']
  )
  // ... more customers from AdminSetup data

  // Entities that reference others use the captured IDs:
  await pool.query(
    `INSERT INTO jobs (customer_id, status, job_type, ...)
     VALUES ($1, $2, $3, ...)
     ON CONFLICT DO NOTHING`,
    [customer1.id, 'completed', 'delivery', ...]
  )

  console.log('Seed complete!')
  await pool.end()
}

seed().catch(err => {
  console.error('Seed failed:', err)
  process.exit(1)
})
```

### Data extraction rules:

1. **Literal values** from AdminSetup — use directly
2. **Relative dates** (`subDays(new Date(), 3)`) — keep as dynamic: `new Date(Date.now() - 3 * 86400000).toISOString()`
3. **Random selections** — pick a fixed value from the array (deterministic seeds are better)
4. **Entity references** — capture the `RETURNING id` from parent INSERT, use in child INSERT
5. **Array/JSONB fields** — JSON.stringify the array objects

### User creation:
- Always create at least one user per role found in the analysis
- Passwords: `admin123`, `user123`, `driver123` (dev only — clearly test data)
- If `linked_driver_id` exists, create a driver entity and link it to the driver user

---

## Phase 3: Add npm script

Edit `server/package.json` to add a seed script:

```json
"scripts": {
  "seed": "ts-node api/utils/seed.ts"
}
```

If `ts-node` isn't available, use:
```json
"seed": "npx tsx api/utils/seed.ts"
```

---

## Phase 4: Run Seed

```bash
cd server && npm run seed 2>&1
```

If it fails, read the error, fix the seed script, and retry. Common issues:
- Table doesn't exist yet (migrations not run)
- FK constraint violation (wrong insertion order)
- Duplicate key on re-run (add ON CONFLICT handling)
- Missing columns (schema mismatch)

---

## Phase 5: Verify

```bash
cd server && node -e "
const { Pool } = require('pg');
const pool = new Pool({ connectionString: process.env.DATABASE_URL || 'postgresql://claude:localdev@127.0.0.1:5432/$(basename $(pwd))' });
(async () => {
  // Check each seeded table
  const tables = [/* list entity table names */];
  for (const t of tables) {
    const { rows } = await pool.query('SELECT COUNT(*) FROM ' + t);
    console.log(t + ': ' + rows[0].count + ' rows');
  }
  await pool.end();
})().catch(console.error);
"
```

---

## Phase 6: Summary

```
Seed Data Generation Complete:
- Users created: admin, user, driver (passwords: admin123, user123, driver123)
- Entities seeded: [list with counts]
- Seed script: server/api/utils/seed.ts
- Run with: cd server && npm run seed

Next step: Run /b44-test to generate tests.
```

---

## Rules

- Use ON CONFLICT DO NOTHING or DO UPDATE so the seed is idempotent (safe to re-run).
- Insert entities in FK dependency order — parents before children.
- Use RETURNING id to capture auto-generated UUIDs for child references.
- Keep test data realistic but obviously fake (no real emails, phone numbers).
- If AdminSetup has very complex logic, simplify — the goal is useful test data, not a 1:1 recreation.
- Don't seed hundreds of records — 3-10 per entity is enough for testing.
