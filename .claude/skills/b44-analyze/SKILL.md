---
name: b44-analyze
description: Analyze a Base44 source project. Scans all source files in .base44-source/, extracts entities with field schemas, identifies integrations, maps auth/roles, catalogs pages/components, and asks clarifying questions. Produces .claude/b44-analysis.json. Run this FIRST before any other b44-* skill.
allowed-tools: Bash, Read, Write, Edit, Glob, Grep, mcp__one-editor__ask_user
---

# Base44 Project Analyzer

You are the **Base44 Analyzer**. Your job is to thoroughly scan a Base44 source project and produce a structured analysis JSON that all downstream conversion skills will consume.

**You do NOT write any application code. You ONLY produce `.claude/b44-analysis.json`.**

---

## Prerequisites

Verify `.base44-source/` exists in the project root. If not, abort with:
> "No Base44 source found. Upload a Base44 project first — the source should be at `.base44-source/`."

---

## Phase 1: Extract Entities

### Step 1.1 — Discover entity names

Read `.base44-source/src/api/entities.js`. Each line matching `export const <Name> = base44.entities.<Name>` declares an entity.

**Special case:** `export const User = base44.auth` is NOT an entity — it maps to the auth system. Skip it.

Record every entity name (e.g., `Customer`, `Driver`, `Job`, `Vehicle`, etc.).

### Step 1.2 — Discover entity operations

For each entity, grep the entire `.base44-source/src/` directory for usage patterns:

```
<Entity>.list(       → "list" operation
<Entity>.create(     → "create" operation
<Entity>.update(     → "update" operation
<Entity>.delete(     → "delete" operation
<Entity>.filter(     → "filter" operation
<Entity>.bulkCreate( → "bulkCreate" operation
```

Record which operations each entity uses.

### Step 1.3 — Infer field schemas

For each entity, scan ALL `.jsx` files in `.base44-source/src/` for field references. Use these patterns to find fields:

**Pattern A — Create dialog state initializers:**
Look for `useState` in `Create<Entity>Dialog.jsx` files. The initial object's keys are the entity's fields:
```javascript
const [formData, setFormData] = useState({
  company_name: "",      // → TEXT
  vat_exempt: false,     // → BOOLEAN
  price: "",             // → NUMERIC (if parseFloat in submit)
  deliveries: [],        // → JSONB
})
```

**Pattern B — Object literals in `.create()` / `.update()` calls:**
```javascript
Entity.create({ field1: value1, field2: value2 })
Entity.update(id, { field1: newValue })
```

**Pattern C — Property access in JSX:**
```javascript
item.field_name         // direct access
item?.field_name        // optional access
data.field_name         // via data variable
```

**Pattern D — Table columns:**
```jsx
<TableHead>Field Label</TableHead>
// ... paired with ...
{item.field_name}
```

**Pattern E — Form inputs:**
```jsx
<Input name="field_name" />
value={formData.field_name}
onChange={(e) => setFormData({...formData, field_name: e.target.value})}
```

**Pattern F — Sort/filter:**
```javascript
Entity.list("-field_name")    // sort field
Entity.filter({ field: value }) // filter field
```

**Pattern G — Conditionals (infer enums):**
```javascript
item.status === "active"
item.status === "completed"
// → status is an enum with values ["active", "completed", ...]
```

### Step 1.4 — Infer field types

Apply these type inference rules to each discovered field:

| Code Pattern | Inferred Type |
|---|---|
| `""` string initializer | `string` |
| `false` / `true` initializer | `boolean` |
| `0` numeric initializer | `number` |
| `[]` array initializer | `json_array` |
| `{}` object initializer | `json_object` |
| `parseFloat(field)` or `.toFixed()` or arithmetic | `number` |
| `format(field, "date-pattern")` or `new Date(field)` | `date` |
| `.toISOString()` | `datetime` |
| Field ends with `_id` and another entity has that name | `foreign_key` → reference entity |
| Field named `status` with multiple `=== "value"` checks | `enum` with collected values |
| `<Select>` options listing specific values | `enum` with those values |
| `<Switch checked={field}>` or `<Checkbox>` | `boolean` |
| `<Input type="number">` | `number` |
| `<Input type="email">` | `string` (email) |
| `<Textarea>` | `string` (long text) |
| Field used in `item.field?.map(...)` | `json_array` |

### Step 1.5 — Detect relationships

Scan for foreign key patterns:
- Fields ending in `_id` (e.g., `customer_id`) → reference to `Customer` entity
- Fields named like another entity in lowercase (e.g., `customer`, `driver`) that hold IDs
- Fields used in filter queries: `Entity.filter({ assigned_driver: driverId })` → `Job` has FK to `Driver`

Record relationships as `{ entity, field, type: "belongsTo" | "hasMany" }`.

---

## Phase 2: Extract Integrations

### Step 2.1 — Read integration declarations

Read `.base44-source/src/api/integrations.js`. Look for patterns like:
```javascript
export const { SendEmail, UploadFile, ... } = base44.integrations.Core
```

Record all declared integration names.

### Step 2.2 — Find integration usage

For each declared integration, grep `.base44-source/src/` for actual usage:
```
SendEmail(          → record file, extract parameter names from the call
UploadFile(         → record file, extract parameter names
InvokeLLM(          → record file, extract parameter names
GenerateImage(      → record file, extract parameter names
ExtractDataFromUploadedFile( → record file, extract parameter names
CreateFileSignedUrl( → record file, extract parameter names
UploadPrivateFile(  → record file, extract parameter names
```

Record: `{ name, usedIn: [files], params: [param names] }` for each.

---

## Phase 3: Extract Auth Model

### Step 3.1 — Auth configuration

Read `.base44-source/src/api/base44Client.js`. Look for:
```javascript
createClient({ appId: "...", requiresAuth: true/false })
```

Record `requiresAuth`.

### Step 3.2 — Role definitions

Read `.base44-source/src/pages/Layout.jsx`. Look for:
- Navigation items with `roles` arrays (e.g., `roles: ["admin", "user"]`)
- User role checking: `user.user_role`, `userRole`
- Role-based redirects (e.g., driver users redirected to DriverInterface)
- `base44.auth.me()` call — record which fields are accessed from the user object

Collect all unique roles found.

### Step 3.3 — Role-restricted pages

Build a mapping of which pages are accessible to which roles, based on the navigation items and any route guards found.

---

## Phase 4: Extract Pages & Routes

### Step 4.1 — Route definitions

Read `.base44-source/src/pages/index.jsx`. Extract the route table — each page component and its URL path.

### Step 4.2 — Page analysis

For each page, read the page file and record:
- **Page name** and current route
- **Entities used** (which entities does this page import/call?)
- **Key components** referenced (dialogs, lists, etc.)
- **Integrations used** directly in the page

### Step 4.3 — Navigation structure

From `Layout.jsx`, extract the sidebar navigation:
- Title, icon name, route, and allowed roles for each nav item
- Any grouped/nested navigation sections

---

## Phase 5: Extract Seed Data Patterns

### Step 5.1 — Find AdminSetup

Check if `.base44-source/src/pages/AdminSetup.jsx` exists. If yes:
- Read it completely
- Extract which entities get seeded
- Extract the template data objects (the literal values passed to `.create()` / `.bulkCreate()`)
- Record dependencies (entities must be created in FK order)
- Count how many records are created per entity

If AdminSetup doesn't exist, record `seedData: null`.

---

## Phase 6: Ask Clarifying Questions

Use `mcp__one-editor__ask_user` to ask 3-5 questions. Ask ONE at a time. Focus on gaps the code analysis couldn't fill.

**Question 1 — App description:**
> "Based on my analysis, this appears to be a [inferred description based on entities/pages]. Is this correct?"
> Options: [inferred description], [alternative description], "Let me describe it"

**Question 2 — Feature scope:**
> "I found [N] pages and [M] entities. Do you want to convert everything, or skip some features?"
> Options: "Convert everything as-is", "Skip some features (I'll specify)", "Convert core features only"

If they want to skip features, ask a follow-up about which to skip.

**Question 3 — Roles:**
> "The app has [N] roles: [list]. Keep the same roles in the converted app?"
> Options: "Yes, same roles", "Modify roles", "Simplify to admin/user only"

**Question 4 — Integrations (if any found):**
> "This app uses: [list integrations]. Confirm service mappings: [SendEmail → Resend, UploadFile → Supabase Storage, InvokeLLM → Claude API]?"
> Options: "Yes, use those services", "Different services (I'll specify)"

**Question 5 (optional) — Anything ambiguous:**
If the code analysis revealed anything unclear (fields with ambiguous types, features with unclear purpose), ask about those.

---

## Phase 7: Write Analysis Output

Write `.claude/b44-analysis.json` with this structure:

```json
{
  "analyzedAt": "ISO date",
  "sourceDir": ".base44-source",
  "appDescription": "user-confirmed description",
  "entities": [
    {
      "name": "EntityName",
      "tableName": "entity_names",
      "fields": [
        {
          "name": "field_name",
          "inferredType": "string|number|boolean|date|datetime|json_array|json_object|enum|foreign_key",
          "postgresType": "TEXT|NUMERIC(10,4)|BOOLEAN|DATE|TIMESTAMPTZ|JSONB|UUID",
          "required": true,
          "defaultValue": null,
          "enumValues": [],
          "referencesEntity": null,
          "usedIn": ["file1.jsx", "file2.jsx"]
        }
      ],
      "operations": ["list", "create", "update", "delete"],
      "sortFields": ["-created_date"],
      "filterFields": ["status", "assigned_driver"],
      "relationships": [
        { "entity": "OtherEntity", "field": "other_id", "type": "belongsTo" }
      ]
    }
  ],
  "integrations": {
    "SendEmail": { "usedIn": ["file.jsx"], "params": ["to", "subject", "body"], "targetService": "resend" },
    "UploadFile": { "usedIn": ["file.jsx"], "params": ["file"], "targetService": "supabase-storage" },
    "InvokeLLM": { "usedIn": [], "params": [], "targetService": "claude-api" }
  },
  "auth": {
    "requiresAuth": true,
    "roles": ["admin", "user", "driver"],
    "roleField": "user_role",
    "userFields": ["id", "email", "full_name", "user_role", "linked_driver_id"],
    "roleRestrictedPages": {
      "PageName": ["admin", "user"]
    }
  },
  "pages": [
    {
      "name": "PageName",
      "sourceFile": "pages/PageName.jsx",
      "currentRoute": "/PageName",
      "targetRoute": "/dashboard/page-name",
      "entities": ["Entity1", "Entity2"],
      "components": ["Component1Dialog", "Component2List"],
      "integrations": ["SendEmail"]
    }
  ],
  "navigation": [
    { "title": "Nav Item", "icon": "IconName", "route": "/Route", "roles": ["admin", "user"] }
  ],
  "seedData": {
    "source": "AdminSetup.jsx",
    "entities": ["Entity1", "Entity2"],
    "recordCounts": { "Entity1": 5, "Entity2": 10 },
    "dependencies": ["Entity1 before Entity2"]
  },
  "skippedFeatures": [],
  "questions": [
    { "question": "...", "answer": "..." }
  ]
}
```

### Table name convention
Convert PascalCase entity names to snake_case plural:
- `Customer` → `customers`
- `StorageTank` → `storage_tanks`
- `CompanySettings` → `company_settings`
- `FuelProduct` → `fuel_products`

### Target route convention
Convert PascalCase routes to kebab-case under `/dashboard/`:
- `/Dashboard` → `/dashboard`
- `/Jobs` → `/dashboard/jobs`
- `/DriverInterface` → `/dashboard/driver-interface`
- `/StorageTanks` → `/dashboard/storage-tanks`

---

## Phase 8: Summary

After writing the analysis file, output a brief summary:

```
Base44 Analysis Complete:
- Entities: [N] ([list names])
- Pages: [N] ([list names])
- Integrations: [list used ones]
- Auth: [requiresAuth], roles: [list]
- Seed data: [yes/no]

Analysis saved to .claude/b44-analysis.json
Next step: Run /b44-scope to generate scope and architecture documents.
```

---

## Rules

- Read EVERY source file relevant to each entity. Don't skip files.
- When inferring types, prefer the most specific type (e.g., `enum` over `string` if you see known values).
- Fields found in create dialogs are likely required. Fields only in update/display may be optional.
- Always add `id`, `created_at`, `updated_at` as implicit fields (don't scan for these — they're added automatically by the schema skill).
- If a field's type is genuinely ambiguous, default to `string` / `TEXT`.
- Use the `b44-field-scanner` agent for parallel entity scanning when there are 5+ entities.
- Ask questions via `mcp__one-editor__ask_user`. If unavailable, ask in your response text with numbered options.
