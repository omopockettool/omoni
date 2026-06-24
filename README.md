# OMONI

OMONI is a local-first iOS app for tracking everyday spending with a calm, native-feeling experience built in SwiftUI and SwiftData.

## Repository Overview

- `Omoni/` contains the app source.
- `OmoniTests/` contains the XCTest unit suite backed by in-memory SwiftData.
- `OmoniUITests/` contains UI test scaffolding that is currently not part of the default shared test flow.
- `docs/` contains the project guides, architecture rules, migration notes, and onboarding material.
- `.github/` contains the GitHub Actions workflow and GitHub-specific setup notes.

## Development Workflow

- `develop` is the integration branch.
- `main` is the production branch.
- New work should branch from `develop` using `feature/*` names.
- Pull requests into `develop` and `main` are validated by GitHub Actions CI.

## CI

The repository currently uses GitHub Actions for base CI:

- `SwiftLint` on changed Swift files
- unsigned simulator build validation
- `OmoniTests` unit tests
- `xcbeautify` terminal-formatted build/test logs to keep GitHub annotations readable

See [`.github/README.md`](.github/README.md) for the exact workflow behavior and the GitHub branch-protection settings required to enforce it.

## Project Notes

- The app uses SwiftUI + SwiftData with `AppDIContainer` as the dependency-construction entrypoint.
- Manual product validation is still done on a physical iPhone as part of the team's release workflow.
- Persisted model changes should be treated as migration work, not casual schema edits.

## Documentation Entry Points

- [`docs/START_HERE.md`](docs/START_HERE.md)
- [`docs/swiftui_data_flow_guide.md`](docs/swiftui_data_flow_guide.md)
- [`docs/SWIFTDATA_MIGRATION_GUIDE.md`](docs/SWIFTDATA_MIGRATION_GUIDE.md)
