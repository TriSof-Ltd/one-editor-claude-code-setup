---
name: scope
description: Deep requirements scoping. Reads attached files (PDF, DOCX, images, text), asks clarifying questions, builds a comprehensive scope document, and creates a build tracking file. Use when user attaches requirements docs or enters scope mode.
allowed-tools: Bash, Read, Write, Edit, mcp__one-editor__ask_user
---

# Scope Mode

You are in SCOPING mode. Your job is to deeply understand what the user wants to build before any code is written.

## Step 1: Read all attached files

Read every file the user attached. These may be:
- **PDF documents** — use `Read` tool to read them
- **DOCX/DOC files** — convert to text if possible, or ask user to paste key sections
- **Images** — screenshots, mockups, wireframes — describe what you see
- **Text/Markdown** — requirements docs, user stories, specs

Extract and summarize the key requirements from each file.

## Step 2: Analyze the scope

From the attached files and user's description, identify:
- **Core features** — what must the app do?
- **User flows** — how will users interact with it?
- **Data model** — what entities and relationships exist?
- **Integrations** — external APIs, services, auth providers?
- **Design direction** — visual style, branding, layout preferences?
- **Technical constraints** — performance, accessibility, mobile support?

## Step 3: Ask clarifying questions

Ask 5-10 specific questions using `mcp__one-editor__ask_user`. Ask ONE question at a time. Focus on:

1. **Ambiguities** — anything unclear from the requirements
2. **Priorities** — what's MVP vs nice-to-have?
3. **Edge cases** — what happens when X fails?
4. **User types** — who are the users? roles? permissions?
5. **Design preferences** — colors, style, similar apps they like?
6. **Data** — where does data come from? how much? real-time?
7. **Missing info** — anything the spec doesn't cover but should

After each answer, ask follow-up questions to dig deeper. Continue until you have a clear picture (typically 2-3 rounds of questions).

## Step 4: Present summary

Write a structured summary covering:
- **Project overview** (1 paragraph)
- **Core features** (numbered list with brief descriptions)
- **User flows** (main workflows)
- **Data model** (entities + relationships)
- **Technical approach** (stack decisions)
- **Design direction** (visual approach)
- **Out of scope** (explicitly excluded)
- **Open questions** (anything still unclear)

Ask the user to confirm: "Does this accurately capture what you want to build? Any changes?"

## Step 5: Create scope tracking file

Once confirmed, write `.claude/scope.md`:

```markdown
# Project Scope

## Confirmed: [date]

[Full summary from Step 4]

## Build Tracking

### Phase 1: Foundation
- [ ] Feature A
- [ ] Feature B

### Phase 2: Core Features
- [ ] Feature C
- [ ] Feature D

### Phase 3: Polish
- [ ] Feature E
- [ ] Feature F
```

Also update PLAN.md with the confirmed scope.
Also update auto memory with the project description.

## Step 6: Transition to build mode

Tell the user: "Scope confirmed! I'll now start building. Each feature will be committed separately with tests."

Then begin building Phase 1 immediately — no more questions, just build.
