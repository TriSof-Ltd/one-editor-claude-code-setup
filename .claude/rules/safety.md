# Safety Rules — Prevent Breaking the App

## NEVER delete these core files
These files are part of the template and must ALWAYS exist. If you need to modify them, edit — never delete and recreate:
- `src/routes/AppRoutes.tsx` — main router (always keep ALL existing routes when adding new ones)
- `src/App.tsx` — app entry point
- `src/main.tsx` — React mount point
- `src/lib/supabase.ts` — Supabase client
- `src/hooks/useAuth.ts` — auth hook
- `src/store/index.ts` — Redux store
- `src/components/auth/ProtectedRoute.tsx` — route protection
- `src/components/auth/EmailAuth.tsx` — email auth form
- `src/components/auth/GoogleSignIn.tsx` — Google sign-in
- `src/pages/auth/sign-in/index.tsx` — sign in page
- `src/pages/auth/sign-up/index.tsx` — sign up page
- `server/api/index.ts` — server entry point
- `server/api/utils/auth.ts` — server auth middleware
- `server/api/utils/supabaseClient.ts` — server Supabase client

## Before EVERY commit
1. Verify the app builds: `npm run build 2>&1 | tail -5` — must show "built in" success
2. Verify the server builds: `cd server && npm run build 2>&1` — must exit 0
3. If either fails, fix the error BEFORE committing

## When adding routes
- ALWAYS keep existing routes in AppRoutes.tsx — add your new route alongside them
- Never replace the entire file — use Edit to add your route

## When modifying imports
- If you change a file's exports, grep for all files that import from it and update them
- Never leave broken imports

## File corruption
- If you see literal `\n` characters in a file (instead of newlines), fix immediately with: `sed -i 's/\\n/\n/g' <file>`
- Always use Edit tool for modifications instead of Write when possible — Write can corrupt newlines
