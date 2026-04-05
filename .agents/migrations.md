# Critical changes documentation

**Repository:** lazzo-web-version.

*Quick reference: when to use IMPLEMENTATION vs MIGRATION vs HANDOFF; templates and locations.*

**When to create IMPLEMENTATION or MIGRATION markdown files:**

## IMPLEMENTATION files

Use for **new features** or **major architecture changes** that require coordination between Supabase (P2 team) and codebase (agents/P1).

**Location:** `IMPLEMENTATION/<FEATURE>_IMPLEMENTATION.md`

**Structure:**

```markdown
# Feature Name Implementation

## Overview
Brief description of what's being implemented

## Part 1: Supabase Changes (P2 Developer)
### Database Schema
- [ ] Create tables with exact DDL
- [ ] Add indexes
- [ ] Configure RLS policies
- [ ] Create triggers/functions if needed

### Storage Setup
- [ ] Create buckets
- [ ] Configure policies

### Testing
- [ ] Verify schema with test queries
- [ ] Test RLS with different user contexts
- [ ] Validate triggers/functions

## Part 2: Codebase Changes (Agent/P1)
### Domain Layer
- [ ] Create entities
- [ ] Define repository interfaces
- [ ] Add use cases

### Data Layer
- [ ] Implement data sources
- [ ] Create DTOs/models
- [ ] Implement repositories
- [ ] Add fake repositories

### Presentation Layer
- [ ] Create pages
- [ ] Add providers
- [ ] Build widgets

### Integration
- [ ] Wire DI in main.dart
- [ ] Add routes

### Testing
- [ ] Unit tests for use cases
- [ ] Widget tests for UI
- [ ] Integration test for full flow
- [ ] Manual testing checklist

## Acceptance Criteria
- [ ] All tests pass
- [ ] No prints in code
- [ ] Architecture rules followed
- [ ] Performance acceptable
```

**Example:** `CHAT_READ_RECEIPTS_IMPLEMENTATION.md` document the chat read receipts feature with Supabase `message_reads` table + Flutter optimistic UI.

## MIGRATION files

Use for **breaking changes** or **refactoring** that affects multiple features and requires careful coordination.

**Location:** `MIGRATIONS/<CHANGE>_MIGRATION.md`

**Structure:**

```markdown
# Migration Name

## Context
Why this migration is needed

## Breaking Changes
List all breaking changes and their impact

## Migration Steps

### Phase 1: Preparation
- [ ] Identify all affected files
- [ ] Create feature flags if needed
- [ ] Backup critical data

### Phase 2: Database Migration (if applicable)
- [ ] Write migration script
- [ ] Test in staging
- [ ] Plan rollback strategy

### Phase 3: Code Migration
- [ ] Update domain layer
- [ ] Update data layer
- [ ] Update presentation layer
- [ ] Update tests

### Phase 4: Validation
- [ ] Run full test suite
- [ ] Manual testing
- [ ] Performance testing
- [ ] Rollback plan validated

## Rollback Plan
Exact steps to revert if issues arise

## Post-Migration Cleanup
- [ ] Remove deprecated code
- [ ] Update documentation
- [ ] Remove feature flags
```

## HANDOFF files

Use for **role transitions** from P1 (planning/UI) to P2 (implementation/integration).

**Location:** `HANDOFFS_TODO/<FEATURE>_P1_P2_HANDOFF.md` (before) → `HANDOFFS_DONE/<FEATURE>_P1_P2_HANDOFF.md` (after)

**Structure:**

```markdown
# Feature Name - P1 to P2 Handoff

## P1 Deliverables (Planning & UI)
- [x] Feature specification
- [x] UI mockups/designs
- [x] User flows documented
- [x] Edge cases identified

## P2 Tasks (Implementation)
- [ ] Supabase schema design
- [ ] Backend logic implementation
- [ ] API integration
- [ ] Testing & validation

## Acceptance Criteria
How to verify feature is complete

## Notes & Considerations
Important context for P2 team
```

## Key differences

| File Type     | When to Use                    | Who Creates   | Who Consumes   |
|---------------|--------------------------------|---------------|----------------|
| IMPLEMENTATION| New features with DB + code    | P1/Agent      | P2 (DB) → Agent|
| MIGRATION     | Breaking changes, refactoring   | Agent/P1      | All developers |
| HANDOFF       | Role transition P1→P2          | P1            | P2 team        |

## Benefits

- Single source of truth for complex changes
- Reduces back-and-forth in prompts
- Clear testing checkpoints
- Easier rollback if issues arise
- Knowledge preservation for team
