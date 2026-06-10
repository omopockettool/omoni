# SwiftData Migration Guide

## Purpose

This document defines the persistence workflow for OMONI now that the app is using a versioned SwiftData schema.

It exists to prevent accidental store breakage before and after production launch.

## Current Baseline

OMONI now uses:

- `SchemaV1` as a frozen historical snapshot
- `SchemaV2` as the current live app schema
- `OmoniMigrationPlan` as the migration entry point
- `ModelContainer` initialized with both the schema and the migration plan

Relevant files:

- `Omoni/Data/SwiftData/OmoniSchema.swift`
- `Omoni/Data/SwiftData/ModelContainer+Shared.swift`

## What Was Fixed

Previously, the codebase had a `VersionedSchema` type, but the live `ModelContainer` was still being built directly from `Schema([...])`.

That meant the project had persistence versioning in name, but not fully in the actual container setup.

The container now runs through the proper versioned path, which gives OMONI a safer base for future schema evolution.

## Golden Rule

If a persisted model changes, do **not** just edit the `@Model` and move on.

Persisted changes must go through the schema versioning path.

Examples of persisted changes:

- Adding a stored property
- Removing a stored property
- Renaming a stored property
- Changing relationships
- Adding a new `@Model`
- Splitting one model into multiple models

## What To Do For Future Persisted Changes

### 1. Add a New Schema Version

Create the next schema version (`SchemaV3`, `SchemaV4`, and so on) in `OmoniSchema.swift`.

### 2. Update the Migration Plan

Add the new schema to:

- `OmoniMigrationPlan.schemas`

Add a migration stage to:

- `OmoniMigrationPlan.stages`

Use:

- `MigrationStage.lightweight(...)` when SwiftData can handle it safely
- `MigrationStage.custom(...)` when data reshaping is needed

### 3. Keep the Container on the Official Path

Do not bypass `OmoniMigrationPlan` in `ModelContainer+Shared.swift`.

All app containers should continue using:

- the versioned schema
- the migration plan

### 4. Review Backup Impact

If the persistence model changes, also review:

- `Omoni/Domain/Backup/OMOBackupModels.swift`
- `Omoni/Data/Repositories/DefaultBackupRepository.swift`

Ask:

- Does backup need new fields?
- Does restore need a compatibility path?
- Should backup schema version increase?

### 5. Document the Product Behavior

If the persistence change affects user-visible meaning, add a short design note in `docs/`.

Examples:

- Recurring item lists
- Historical category limit versions
- Archived records

## Important Limitation

Historical schemas must not point at the live model classes forever.

Once production data exists, historical schema versions should represent the old persisted shape intentionally and not drift casually with unrelated edits.

In other words:

- `V1`, `V2`, and later versions are snapshots
- only the newest live schema should point at the current global `SD*` models

## What "Frozen Schema" Means In OMONI

For an old schema version:

- Keep the old stored fields exactly as they were
- Keep the old relationships exactly as they were
- Use version-scoped `@Model` types inside the schema snapshot
- Do not keep historical versions pointing at the same live `SD*` classes

If two schema versions point at the same live model shape, SwiftData can detect duplicate checksums and the migration plan is not real.

## Practical Rule For OMONI

Before changing anything in `Omoni/Data/SwiftData/`, pause and ask:

- Is this only runtime/computed behavior?
- Or does this change what gets stored on disk?

If it changes what gets stored on disk, it is a migration concern.

## Safe Examples

Usually safe without a new schema version:

- Adding computed properties
- Adding helper methods
- Adding formatting helpers
- Adding non-persisted convenience behavior

Usually requires schema review:

- New stored properties
- Relationship changes
- Model deletions
- Model additions
- Renames of stored fields

## Suggested Workflow

1. Define the product behavior first
2. Decide the persisted shape
3. Create the new schema version
4. Add the migration stage
5. Update backup if needed
6. Add or update compatibility tests for store/backup behavior
7. Keep view logic out of migration logic
8. Validate manually on device before release

## Required Tests Before Release

For every persisted change after launch, cover at least:

- A compatibility test for old backup payloads if the backup shape changed
- A migration test or fixture plan for opening older stores with the new schema
- A regression test for any new default/fallback behavior introduced by the migration

## Operational Playbook

See `docs/production-migration-playbook.md` for the release-oriented checklist the team should follow once public data exists.

## Decision

OMONI is now in a better place for SwiftData evolution than before, but future persisted changes still need discipline.

This guide should be treated as the default workflow for any storage-level change going forward.
