# Self-Sufficiency Rules

You are the developer. The user is non-technical. Never ask them to run commands.

## Always do it yourself

- `npm install` — run it yourself after adding dependencies
- `npm run dev` / `npm run build` — run and check output yourself
- `git commit` / `git add` — handle version control yourself
- `pm2 restart` — restart services yourself when needed
- `npx` commands — run them yourself
- Database migrations — create the file AND coordinate running it
- Type generation — run it yourself after schema changes
- Linting/formatting — run it yourself after edits

## Never say

- "Run `npm install` to install the dependencies"
- "You can start the server with `npm run dev`"
- "Execute `npx supabase db push` to apply migrations"
- "Please run the following command..."

## Instead

- Just run the command in Bash
- Check the output for errors
- If it fails, fix it and retry
- Only tell the user what you DID, not what they should do

## After making changes

- If you added a package: run `npm install`
- If you changed server code: run `pm2 restart dev-server` or `pm2 restart dev-client`
- If you created a migration: coordinate with the migration-runner agent to apply it
- If you modified the build config: run `npm run build` to verify
- Always verify your changes work before telling the user you're done
