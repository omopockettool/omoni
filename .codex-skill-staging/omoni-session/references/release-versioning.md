# OMONI Release Versioning

Use this file when the user asks for a changelog entry, release notes, or a commit message tied to a release.

## Rule

Do not assume the next version number.

Ask the user which bump category applies first unless they already specified it:

- `major`
- `minor`
- `fix`

Then map that category to the explicit semantic version that should be written in the changelog.

## Default strategy for OMONI

- `MARKETING_VERSION` is the public product version.
- `CURRENT_PROJECT_VERSION` is the internal build number.
- Keep them intentionally separate.

### How to use them

- Bump `MARKETING_VERSION` only when the public release version changes.
- Bump `CURRENT_PROJECT_VERSION` whenever you produce a new meaningful build of the same public version.
- Keep `CURRENT_PROJECT_VERSION` as a simple increasing integer.

### Recommended defaults

- For a new public release, align `MARKETING_VERSION` with the changelog version immediately.
- After that release is set, keep increasing `CURRENT_PROJECT_VERSION` for subsequent builds until the next public release.
- If the user does not give a build-number policy, recommend:
  - keep `MARKETING_VERSION` equal to the latest confirmed changelog version
  - keep `CURRENT_PROJECT_VERSION` monotonic, starting from `1` and incrementing by `1`

### Backup rule

- Backup metadata should reflect the app's current runtime identity:
  - app name from the current product branding
  - bundle identifier from the current target settings
  - app version from `MARKETING_VERSION (CURRENT_PROJECT_VERSION)`

### UI version surfaces to verify

- `About OMO` current version row must reflect the live bundle values, not a hardcoded string.
- When versioning changes, verify any in-app release/version surface that reads the current installed version still reflects `MARKETING_VERSION` and `CURRENT_PROJECT_VERSION` correctly.

### Changelog and commit workflow

1. Ask whether the bump is `major`, `minor`, or `fix` unless already specified.
2. Write or update the changelog version header.
3. Align Xcode `MARKETING_VERSION` to that release version.
4. Decide whether `CURRENT_PROJECT_VERSION` should stay the same or increment for this build.
5. Verify user-facing version surfaces like `About OMO` if they depend on bundle metadata.
6. Only then suggest the commit message.

## Why

- Big refactors, compatibility breaks, or identity-level migrations may require a `major` bump.
- Feature work usually maps to `minor`.
- Small corrections usually map to `fix`.

## For OMONI

- If a change is not backward compatible, treat `major` as the default recommendation.
- If unsure, explicitly pause and ask before writing the changelog version header.
- Do not present a commit message as if it implies a release version unless the versioning decision is already confirmed.
- Prefer one stable policy over ad-hoc edits to old backups. Fix the project version settings so future backups come out correct by default.
