# GitHub Actions for OMONI

This folder contains the GitHub-side automation for the OMONI repository.

## Current Workflow

### `pr-checks.yml`

This workflow is the base CI for the project.

**Triggers**
- Pull requests targeting `develop`
- Pull requests targeting `main`
- Pushes directly to `develop`
- Pushes directly to `main`
- Manual runs via `workflow_dispatch`

**Checks**
- `SwiftLint`
- `Build`
- `Unit Tests`

**Implementation notes**
- The macOS runner is pinned to `macos-15` to avoid `macos-latest` drift.
- Xcode is pinned to `26.3`.
- The workflow resolves an available iOS 26 simulator dynamically instead of hardcoding a device name.
- Test artifacts are uploaded so failed CI runs are easier to inspect.

## GitHub Configuration Still Needed

The workflow file is only half of the setup. In GitHub you should also configure branch protection.

### 1. Protect `develop`

In `Settings` -> `Branches` -> `Add branch protection rule`:

- Branch name pattern: `develop`
- Enable `Require a pull request before merging`
- Enable `Require status checks to pass before merging`
- Add these required checks:
  - `SwiftLint`
  - `Build`
  - `Unit Tests`
- Enable `Require branches to be up to date before merging`
- Enable `Dismiss stale pull request approvals when new commits are pushed`

### 2. Protect `main`

Use the same settings for `main`.

If you want a stricter production gate, you can also:

- Restrict who can push to `main`
- Require at least 1 approval
- Require conversation resolution before merge

## Secrets

No repository secrets are required for this base CI workflow.

That means you can merge this PR and have PR validation working immediately.

## Next Recommended Step

Once this CI is merged and branch protection is enabled, the next step is release automation.

Recommended direction for OMONI:

- `GitHub Actions` for CI
- `Xcode Cloud` for signed TestFlight delivery

If you prefer to keep all delivery inside GitHub, the alternative is:

- `GitHub Actions` + `fastlane match` + `fastlane pilot`
