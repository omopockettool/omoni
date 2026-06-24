# Production Migration Playbook

Use this checklist for every persisted SwiftData change once OMONI has public users.

## 1. Decide The Change Type

Use `lightweight` when:

- adding an optional stored field
- adding a field with a safe default SwiftData can infer
- renaming fields with explicit migration support
- making simple additive relationship changes SwiftData can map safely

Use `custom` when:

- splitting one model into several models
- merging models
- changing field meaning, not just storage shape
- moving data between entities
- needing derived defaults based on old records
- changing relationships in a way that needs record-by-record repair

Use backup rescue as a fallback plan when:

- the schema change is risky
- the release is close
- there is any doubt that automatic migration is safe

## 2. Freeze The Previous Schema

- Never reuse the same live `SD*` classes for old and new schema versions.
- Keep old schema models nested under their version snapshot.
- Treat the previous schema as read-only history.

## 3. Add The New Live Schema

- Point the newest schema version at the current global `SD*` models.
- Keep `OmoniSchema` aliased to the newest live version.
- Add the new version to `OmoniMigrationPlan.schemas`.
- Add a matching migration stage to `OmoniMigrationPlan.stages`.

## 4. Review Backup Compatibility

- Decide whether the backup envelope version must increase.
- Accept older payloads when safe.
- Normalize missing values during import when possible.
- Export the newest normalized shape whenever possible.

## 5. Add Tests

- Add a fixture or compatibility test for the old backup shape.
- Add a migration test plan for opening an older store.
- Add regression tests for new defaults introduced by the migration.
- Keep test containers on the official versioned `ModelContainer` path.

## 6. Validate Before Release

- Test clean install behavior.
- Test upgrade behavior from the previous public build.
- Test backup export from the old build and import into the new build.
- Test rescue-backup flow before destructive import.

## 7. MVP0 / Current Status

Current state before launch:

- `SchemaV1` is a frozen historical pre-release snapshot.
- `SchemaV2` is the live app schema.
- `groupKind` is optional in storage and resolves to `expense` when missing.
- Backup import accepts older payloads without `groupKind`.

That means the app is now set up for real post-launch migrations, even though pre-launch local installs may still be reset during development when needed.
