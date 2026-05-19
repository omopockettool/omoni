# OMONI Release Versioning

Use this file when the user asks for a changelog entry, release notes, or a commit message tied to a release.

## Rule

Do not assume the next version number.

Ask the user which bump category applies first unless they already specified it:

- `major`
- `minor`
- `fix`

Then map that category to the explicit semantic version that should be written in the changelog.

## Why

- Big refactors, compatibility breaks, or identity-level migrations may require a `major` bump.
- Feature work usually maps to `minor`.
- Small corrections usually map to `fix`.

## For OMONI

- If a change is not backward compatible, treat `major` as the default recommendation.
- If unsure, explicitly pause and ask before writing the changelog version header.
- Do not present a commit message as if it implies a release version unless the versioning decision is already confirmed.
