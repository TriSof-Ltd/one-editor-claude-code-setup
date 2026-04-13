---
name: b44-frontend
description: Convert all Base44 frontend pages and components to TypeScript React with Redux Toolkit state management. Converts JSX to TSX, replaces Base44 SDK calls with apiClient/Redux thunks, updates routing and navigation. Requires b44-backend to have run first.
allowed-tools: Bash, Read, Write, Edit, Glob, Grep
---

# Base44 Frontend Converter

You are the **Frontend Converter**. Your job is to convert every Base44 page and component into the target stack — TypeScript, Redux Toolkit, apiClient pattern — while preserving the app's functionality.

---

## Prerequisites

1. Verify these exist:
   - `.claude/b44-analysis.json`
   - `detailed-architecture.md`
   - `server/api/routes/*Routes.ts` — backend routes from b44-backend
   - `server/api/types/*.ts` — TypeScript types from b44-schema

   If backend routes don't exist: "Run /b44-backend first."

2. Read `.claude/b44-analysis.json` and `detailed-architecture.md`.
3. Read these template files to match patterns:
   - `src/store/pages/notes/` (all 5 files) — Redux slice pattern
   - `src/lib/apiClient.ts` — API client pattern
   - `src/routes/AppRoutes.tsx` — routing pattern
   - `src/types/index.ts` — frontend type pattern
   - `src/components/layout/app-sidebar.tsx` — navigation pattern

---

## Phase 1: Generate Frontend Types

Edit `src/types/index.ts` to add interfaces for every entity. These mirror the server types but are used on the frontend:

```typescript
export interface Customer {
  id: string
  company_name: string
  // ... all fields from analysis
  created_at: string
  updated_at: string
}

export interface CreateCustomerPayload {
  company_name: string
  // ... required fields only
}

export interface UpdateCustomerPayload {
  company_name?: string
  // ... all fields optional
}
```

Generate `<Entity>`, `Create<Entity>Payload`, and `Update<Entity>Payload` for every entity.

---

## Phase 2: Extend API Client

Edit `src/lib/apiClient.ts` to add methods for every entity:

```typescript
// Add to apiClient object:
customers: {
  list: (params?: Record<string, string | number>) =>
    unwrap<PaginatedResponse<Customer>>(api.get('/customers', { params })),
  get: (id: string) =>
    unwrap<{ data: Customer }>(api.get(`/customers/${id}`)),
  create: (payload: CreateCustomerPayload) =>
    unwrap<{ data: Customer }>(api.post('/customers', payload)),
  update: (id: string, payload: UpdateCustomerPayload) =>
    unwrap<{ data: Customer }>(api.put(`/customers/${id}`, payload)),
  delete: (id: string) =>
    unwrap<{ message: string }>(api.delete(`/customers/${id}`)),
},
```

Add extra methods where needed:
- `filter`: `filter: (params) => unwrap(api.get('/entities/filter', { params }))`
- `bulkCreate`: `bulkCreate: (items) => unwrap(api.post('/entities/bulk', items))`

Add integration methods:
```typescript
email: {
  send: (to: string, subject: string, body: string) =>
    unwrap<{ message: string }>(api.post('/email/send', { to, subject, body })),
},
llm: {
  invoke: (prompt: string, response_type?: string) =>
    unwrap<{ result: unknown }>(api.post('/llm/invoke', { prompt, response_type })),
  extract: (file_url: string, json_schema?: object) =>
    unwrap<{ data: unknown }>(api.post('/llm/extract', { file_url, json_schema })),
},
pdf: {
  generate: (html: string, filename?: string) =>
    api.post('/pdf/generate', { html, filename }, { responseType: 'blob' }),
},
```

Also add a `PaginatedResponse<T>` type if it doesn't exist:
```typescript
interface PaginatedResponse<T> {
  data: T[]
  total: number
  page: number
  totalPages: number
}
```

---

## Phase 3: Generate Redux Store

For each entity, create 5 files following the `store/pages/notes/` pattern exactly.

### 3.1 — types.ts
```typescript
// src/store/pages/<entity>/types.ts
import type { <Entity> } from '@/types'

export interface <Entity>sState {
  items: <Entity>[]
  total: number
  page: number
  totalPages: number
  isLoading: boolean
  error: string | null
}
```

### 3.2 — thunks.ts
```typescript
// src/store/pages/<entity>/thunks.ts
import { createAsyncThunk } from '@reduxjs/toolkit'
import { apiClient } from '@/lib/apiClient'
import type { Create<Entity>Payload, Update<Entity>Payload } from '@/types'

export const fetch<Entity>s = createAsyncThunk(
  '<entity>/fetch<Entity>s',
  async (params: Record<string, string | number> | undefined, { rejectWithValue }) => {
    try {
      return await apiClient.<entities>.list(params)
    } catch (error: unknown) {
      const err = error as { response?: { data?: { error?: string } }; message?: string }
      return rejectWithValue(err.response?.data?.error || err.message || 'Failed to fetch')
    }
  }
)

export const create<Entity> = createAsyncThunk(
  '<entity>/create<Entity>',
  async (payload: Create<Entity>Payload, { rejectWithValue }) => {
    try {
      const response = await apiClient.<entities>.create(payload)
      return response.data
    } catch (error: unknown) {
      const err = error as { response?: { data?: { error?: string } }; message?: string }
      return rejectWithValue(err.response?.data?.error || err.message || 'Failed to create')
    }
  }
)

export const update<Entity> = createAsyncThunk(
  '<entity>/update<Entity>',
  async ({ id, ...payload }: Update<Entity>Payload & { id: string }, { rejectWithValue }) => {
    try {
      const response = await apiClient.<entities>.update(id, payload)
      return response.data
    } catch (error: unknown) {
      const err = error as { response?: { data?: { error?: string } }; message?: string }
      return rejectWithValue(err.response?.data?.error || err.message || 'Failed to update')
    }
  }
)

export const delete<Entity> = createAsyncThunk(
  '<entity>/delete<Entity>',
  async (id: string, { rejectWithValue }) => {
    try {
      await apiClient.<entities>.delete(id)
      return id
    } catch (error: unknown) {
      const err = error as { response?: { data?: { error?: string } }; message?: string }
      return rejectWithValue(err.response?.data?.error || err.message || 'Failed to delete')
    }
  }
)
```

### 3.3 — slice.ts
```typescript
// src/store/pages/<entity>/slice.ts
import { createSlice } from '@reduxjs/toolkit'
import type { <Entity>sState } from './types'
import { fetch<Entity>s, create<Entity>, update<Entity>, delete<Entity> } from './thunks'

const initialState: <Entity>sState = {
  items: [],
  total: 0,
  page: 1,
  totalPages: 1,
  isLoading: false,
  error: null,
}

const <entity>sSlice = createSlice({
  name: '<entity>s',
  initialState,
  reducers: {},
  extraReducers: (builder) => {
    builder
      .addCase(fetch<Entity>s.pending, (state) => { state.isLoading = true; state.error = null })
      .addCase(fetch<Entity>s.fulfilled, (state, action) => {
        state.isLoading = false
        state.items = action.payload.data
        state.total = action.payload.total ?? 0
        state.page = action.payload.page ?? 1
        state.totalPages = action.payload.totalPages ?? 1
      })
      .addCase(fetch<Entity>s.rejected, (state, action) => {
        state.isLoading = false
        state.error = action.payload as string
      })
      .addCase(create<Entity>.fulfilled, (state, action) => {
        state.items.unshift(action.payload)
        state.total += 1
      })
      .addCase(update<Entity>.fulfilled, (state, action) => {
        const idx = state.items.findIndex(item => item.id === action.payload.id)
        if (idx !== -1) state.items[idx] = action.payload
      })
      .addCase(delete<Entity>.fulfilled, (state, action) => {
        state.items = state.items.filter(item => item.id !== action.payload)
        state.total = Math.max(0, state.total - 1)
      })
  },
})

export default <entity>sSlice.reducer
```

### 3.4 — selectors.ts
```typescript
// src/store/pages/<entity>/selectors.ts
import type { RootState } from '@/store'

export const select<Entity>s = (state: RootState) => state.<entity>s.items
export const select<Entity>sTotal = (state: RootState) => state.<entity>s.total
export const select<Entity>sPage = (state: RootState) => state.<entity>s.page
export const select<Entity>sLoading = (state: RootState) => state.<entity>s.isLoading
export const select<Entity>sError = (state: RootState) => state.<entity>s.error
```

### 3.5 — index.ts (barrel)
```typescript
// src/store/pages/<entity>/index.ts
export { default as <entity>sReducer } from './slice'
export { fetch<Entity>s, create<Entity>, update<Entity>, delete<Entity> } from './thunks'
export { select<Entity>s, select<Entity>sTotal, select<Entity>sPage, select<Entity>sLoading, select<Entity>sError } from './selectors'
export type { <Entity>sState } from './types'
```

### 3.6 — Register in store

Edit `src/store/index.ts` to add all new reducers:

```typescript
import { <entity>sReducer } from './pages/<entity>'
// ... for each entity

// Add to reducer object:
<entity>s: <entity>sReducer,
```

---

## Phase 4: Convert Pages

For each page in the analysis, read the Base44 source and create the target page.

### 4.1 — Conversion process per page

1. **Read** `.base44-source/src/pages/<PageName>.jsx`
2. **Create** `src/pages/dashboard/<route-name>/index.tsx` (or `src/pages/<route-name>/index.tsx` for non-dashboard pages)
3. **Apply these transformations:**

#### Import replacements
| Base44 Import | Target Import |
|---|---|
| `import { Entity } from "@/api/entities"` | `import { useAppDispatch, useAppSelector } from '@/store'` + entity thunks/selectors |
| `import { base44 } from "@/api/base44Client"` | Remove — replaced by dispatch calls |
| `import { Integration } from "@/api/integrations"` | `import { apiClient } from '@/lib/apiClient'` |
| `import { createPageUrl } from "@/utils"` | Remove — use literal route strings |
| `import { ComponentX } from "@/components/ui/..."` | Keep as-is (shadcn imports stay the same) |

#### SDK call replacements
| Base44 Pattern | Target Pattern |
|---|---|
| `const data = await Entity.list("-created_date")` | `dispatch(fetchEntities({ sort: 'created_at', order: 'desc' }))` (in useEffect) |
| `await Entity.create(formData)` | `await dispatch(createEntity(formData)).unwrap()` |
| `await Entity.update(id, data)` | `await dispatch(updateEntity({ id, ...data })).unwrap()` |
| `await Entity.delete(id)` | `await dispatch(deleteEntity(id)).unwrap()` |
| `Entity.filter({ field: value }, "-sort")` | `dispatch(fetchEntities({ field: value, sort: 'sort', order: 'desc' }))` |

#### State replacements
| Base44 Pattern | Target Pattern |
|---|---|
| `const [items, setItems] = useState([])` | `const items = useAppSelector(selectEntities)` |
| `const [isLoading, setIsLoading] = useState(true)` | `const isLoading = useAppSelector(selectEntitiesLoading)` |
| `useEffect(() => { loadData() }, [])` | `useEffect(() => { dispatch(fetchEntities()) }, [dispatch])` |
| `const loadData = async () => { ... }` | Remove — replaced by thunk dispatch |

#### Auth replacements
| Base44 Pattern | Target Pattern |
|---|---|
| `const user = await base44.auth.me()` | `const user = useAppSelector(selectUser)` |
| `base44.auth.logout()` | `dispatch(signOut())` |

#### Navigation replacements
| Base44 Pattern | Target Pattern |
|---|---|
| `createPageUrl("PageName")` | `"/dashboard/page-name"` (literal kebab-case) |
| `navigate(createPageUrl("X"))` | `navigate("/dashboard/x")` |

#### Integration call replacements
| Base44 Pattern | Target Pattern |
|---|---|
| `await SendEmail({ to, subject, body })` | `await apiClient.email.send(to, subject, body)` |
| `await UploadFile({ file })` | `await apiClient.uploads.upload(file)` |
| `await InvokeLLM({ prompt })` | `await apiClient.llm.invoke(prompt)` |
| `await ExtractDataFromUploadedFile({ file_url, json_schema })` | `await apiClient.llm.extract(file_url, json_schema)` |
| `await CreateFileSignedUrl(url)` | `await apiClient.uploads.signedUrl(url)` |

### 4.2 — TypeScript conversion

For every component:
1. Rename `.jsx` → `.tsx` conceptually (write new file as `.tsx`)
2. Add interface for component props
3. Type all `useState` calls: `useState<Entity[]>([])` → `useAppSelector(selectEntities)`
4. Type event handlers: `(e: React.ChangeEvent<HTMLInputElement>)`
5. Type form data objects with proper interfaces
6. Remove `any` types — use proper entity types

### 4.3 — Local state that stays as useState

Keep these as `useState` (don't move to Redux):
- `searchTerm` — page-specific filter
- `statusFilter`, `typeFilter` — page-specific filters
- `showCreateDialog`, `showDetailsDialog` — dialog open/close
- `selectedItem` — currently selected item for detail view
- Form state within dialog components
- `isUploading`, `uploadProgress`

---

## Phase 5: Convert Components

For each component directory in `.base44-source/src/components/`:

1. Read each `.jsx` file
2. Create target `.tsx` file at `src/components/<entity>/<ComponentName>.tsx`
3. Apply the same transformations as pages (imports, SDK calls, types)
4. Add proper TypeScript interfaces for all props

**Dialog components** (CreateEntityDialog, EntityDetailsDialog):
- Keep form state as `useState`
- Replace `Entity.create()` in submit handler with `dispatch(createEntity()).unwrap()`
- Add proper validation (can reuse the same Zod schemas or simple checks)
- Type the `onOpenChange` and callback props

**List components** (EntityList, EntityTable):
- Replace `data.map(...)` with `items.map(...)`
- Type each item in the map as the entity type

---

## Phase 6: Update Navigation

Edit `src/components/layout/app-sidebar.tsx`:

Read the current file first. Add navigation items from the analysis:

```typescript
const navigationItems = [
  { title: "Dashboard", url: "/dashboard", icon: LayoutDashboard },
  { title: "Jobs", url: "/dashboard/jobs", icon: FileText },
  { title: "Customers", url: "/dashboard/customers", icon: Users },
  // ... from analysis.navigation, converted to kebab-case routes
]
```

If the analysis shows role-based navigation, filter items based on user role:
```typescript
const userRole = useAppSelector(selectUserRole)
const visibleItems = navigationItems.filter(item =>
  !item.roles || item.roles.includes(userRole)
)
```

---

## Phase 7: Update Routes

Edit `src/routes/AppRoutes.tsx`. Read it first, then add routes for all new pages:

```tsx
import { Route } from 'react-router-dom'

// Inside the DashboardLayout route group:
<Route path="/dashboard/jobs" element={<Jobs />} />
<Route path="/dashboard/customers" element={<Customers />} />
<Route path="/dashboard/driver-interface" element={
  <ProtectedRoute requiredRole="driver"><DriverInterface /></ProtectedRoute>
} />
<Route path="/dashboard/users" element={
  <ProtectedRoute requiredRole="admin"><Users /></ProtectedRoute>
} />
// ... for each page
```

Add lazy imports at the top for each page.

---

## Phase 8: Copy/Adapt UI Components

Check which shadcn/ui components exist in `.base44-source/src/components/ui/` but NOT in `src/components/ui/`. Copy any missing ones:

```bash
# Find components in base44 source
ls .base44-source/src/components/ui/ | sort > /tmp/b44-ui.txt
# Find components in target
ls src/components/ui/ | sort > /tmp/target-ui.txt
# Show missing
comm -23 /tmp/b44-ui.txt /tmp/target-ui.txt
```

For each missing component, copy from `.base44-source/` and rename `.jsx` to `.tsx`. Add type annotations where needed.

---

## Phase 9: Verify Build

```bash
npm run build 2>&1 | tail -20
```

Fix TypeScript errors. Common issues:
- Missing type imports
- `any` types that need proper typing
- Missing component exports
- Route import paths wrong
- Selector/thunk name mismatches

---

## Phase 10: Summary

```
Frontend Conversion Complete:
- Types: [N] entity interfaces + payload types
- API Client: Extended with [N] entity methods + integrations
- Redux Store: [N] entity slices (5 files each)
- Pages: [N] pages converted (JSX → TSX)
- Components: [M] components converted
- Navigation: Updated with [N] items
- Routes: [N] new routes added
- Frontend build: [pass/fail]

Next step: Run /b44-test to generate tests.
```

---

## Rules

- Read the Base44 source file BEFORE writing the target file. Understand the logic first.
- Preserve all business logic (calculations, validations, conditional rendering).
- Don't simplify or remove features — functional equivalent means ALL features work.
- Match the template's patterns exactly (Redux slice structure, apiClient pattern, route conventions).
- Keep shadcn/ui component usage identical — both stacks use the same library.
- Use the `b44-entity-converter` agent for parallel page conversion when there are 5+ pages.
- Run the build check after EVERY 2-3 pages converted to catch errors early.
- If a component is very complex (500+ lines), split into smaller sub-components during conversion.
