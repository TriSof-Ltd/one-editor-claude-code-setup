# Sprint Contract Rules

## Before Starting Each Feature

Before building any feature from PLAN.md, you MUST:

1. Create/update `.claude/sprint-contract.md` with:
   - **Feature**: which PLAN.md feature you're building
   - **Scope**: specific files to create/modify
   - **Acceptance Criteria**: 3-5 concrete, testable criteria
   - **Design Notes**: visual approach, layout decisions
   - **Estimated Commits**: how many commits this feature will take

2. Commit the contract:
```bash
git add .claude/sprint-contract.md
git commit -m "sprint: Contract for [feature name]"
```

## While Building

- Follow the contract scope — don't add extras or skip items
- Each commit message should reference the feature

## After Completing the Feature

- Update the sprint contract with an **Outcome** section
- The evaluator will grade your work against the acceptance criteria

## Contract Template

```markdown
# Sprint Contract

## Feature
[Name from PLAN.md]

## Scope
- [ ] Create: src/pages/Feature.tsx
- [ ] Create: server/api/routes/featureRoutes.ts
- [ ] Modify: src/routes/AppRoutes.tsx (add route)

## Acceptance Criteria
1. Page loads without errors
2. API returns correct data
3. Page is responsive on mobile
4. Loading and error states handled

## Design Notes
- Use existing shadcn components
- Match app color scheme

## Estimated Commits
2-3
```
