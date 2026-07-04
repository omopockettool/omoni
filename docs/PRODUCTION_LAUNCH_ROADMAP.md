# OMONI Production Launch Roadmap

Last updated: 2026-07-04

## Goal

Ship OMONI to production as soon as possible without introducing avoidable release risk.

This roadmap focuses on the shortest realistic path to a solid `1.0.0` launch, based on the current repository state.

## Current Status

### Already in good shape

- Public versioning is already aligned to `1.0.0` in the project metadata.
- Base CI already exists in GitHub Actions with:
  - `SwiftLint`
  - unsigned simulator build
  - unit tests
- The app has a local-first architecture with SwiftUI + SwiftData and a documented migration path.
- Backup export and import already exist, including rescue-backup flow.
- Privacy policy and terms URLs are already wired into onboarding.
- Public and internal changelogs are now separated.

### Not yet fully closed for production

- Apple Developer Program enrollment is paid but still processing.
- App Store Connect is not yet fully available.
- Signed delivery is not automated yet.
- GitHub branch protection is documented, but still needs to be confirmed in GitHub itself.
- The shared App Store link in `About OMONI` still points to the website instead of the final App Store URL.
- Production release validation is still mostly manual on device.
- App Store Connect readiness is still an external dependency:
  - app record state
  - metadata
  - screenshots
  - privacy answers
  - pricing/distribution

## Launch Board

### Done

- [x] Reset public release line to `1.0.0`
- [x] Keep prerelease/internal history in `docs/CHANGELOG-prerelease.md`
- [x] Separate public `CHANGELOG.md` from internal release notes
- [x] Basic CI is already present in GitHub Actions
- [x] Backup/export-import flows already exist
- [x] Privacy policy and terms links already exist in the app

### In progress

- [ ] Apple Developer Program membership activation
  - Paid on `2026-07-04`
  - Current status appears as `Pending`
  - Apple indicates processing may take up to `48 hours`

### Pending

- [ ] Confirm App Store Connect access after membership activation
- [ ] Create the App Store Connect app record
- [ ] Confirm branch protection and required CI checks
- [ ] Choose signed delivery path for the first release
- [ ] Produce a signed TestFlight build
- [ ] Run a real device release-candidate pass
- [ ] Prepare App Store metadata
- [ ] Create App Store screenshots
- [ ] Replace the placeholder App Store URL in `About OMONI`
- [ ] Submit `1.0.0`

## Priority Levels

### P0 — Must be done before production submission

These are the real blockers.

1. Confirm Apple account activation and App Store Connect access
- Wait until the Apple Developer Program membership is fully active.
- Confirm that `App Store Connect` is accessible with the same Apple ID.

2. Confirm App Store Connect version strategy
- Verify that this app record can still ship publicly as `1.0.0`.
- If App Store Connect already has a higher public version recorded for this same app, adjust the public version before submission.

3. Freeze release candidate scope
- Stop non-essential feature work.
- Only allow release fixes, wording fixes, and submission blockers.
- Avoid SwiftData shape changes unless absolutely necessary.

4. Confirm GitHub protection and CI gate
- Enable branch protection for `develop` and `main` using the checks documented in [`.github/README.md`](../.github/README.md).
- Treat green CI on the release candidate branch as mandatory.

5. Choose signed delivery path
- Pick one:
  - `Xcode Cloud` for signed TestFlight delivery
  - `GitHub Actions + fastlane` later
- For fastest launch, Xcode Cloud is the most direct next step if not already configured elsewhere.

6. Build a real release candidate on device
- Create a release candidate build from the exact branch you intend to ship.
- Validate on physical iPhone at minimum:
  - first launch
  - first user creation
  - backup export
  - backup import
  - create new entry in `simple`
  - create new entry in `list`
  - edit item list
  - add item inside item-list detail
  - paid/pending toggles
  - dashboard navigation in `Today` and `This Month`
  - search
  - group switching

7. Fix the remaining production placeholder
- Replace the temporary `appStoreURL` in [AboutOMOView.swift](../Omoni/Presentation/Common/Views/AboutOMOView.swift) once the real App Store URL exists.

8. Prepare App Store submission material
- App name
- subtitle
- description
- keywords
- screenshots
- support URL
- marketing URL
- privacy policy URL
- app review notes

## P1 — Strongly recommended before launch week ends

These are not hard blockers, but they reduce launch risk a lot.

1. TestFlight pass
- Upload the release candidate to TestFlight.
- Do at least one full pass from a TestFlight-installed build, not only a local debug/dev run.

2. Release checklist run
- Validate:
  - clean install behavior
  - upgrade behavior from the latest internal build you actually use
  - backup export from previous build
  - backup import into release candidate

3. Final copy and links audit
- Re-check:
  - `About OMONI`
  - onboarding legal copy
  - settings
  - empty states
  - release notes

4. Submission rollback plan
- Decide what you do if a last-minute issue appears:
  - fix and resubmit immediately
  - delay release by 24-48h
  - ship and patch in `1.0.1`

## P2 — Valuable soon after launch, not required for day one

1. Signed delivery automation
- If release delivery is manual for `1.0.0`, automate it right after launch.

2. Crash reporting
- Add a lightweight crash-reporting solution only if it fits the product/privacy direction.

3. Stronger UI regression coverage
- The repo already has unit tests and CI, but UI tests are still scaffolding and are not part of the shared release gate.

4. Post-launch release checklist
- Document the exact `1.0.1+` workflow once the first public release is live.

## Recommended Fast Path

If the goal is "ship as soon as possible", this is the shortest safe path:

1. Wait for Apple Developer membership activation.
2. Confirm App Store Connect can accept `1.0.0`.
3. Freeze scope and treat current branch as release candidate.
4. Enable or verify branch protection.
5. Run CI and fix any failing checks.
6. Produce a signed TestFlight build.
7. Do one serious device validation pass from the signed build.
8. Fill App Store metadata and create screenshots.
9. Replace the final App Store URL placeholder.
10. Submit `1.0.0`.

## Suggested Immediate Next Step

If we want momentum now, the next best step is:

**Wait for Apple membership activation, then create the App Store Connect app record immediately.**

While Apple is processing the enrollment, the best parallel work is:
- define App Store name, subtitle, and description
- prepare screenshot plan and assets
- verify branch protection and release branch discipline
- keep the app in release-fix-only mode

## Repo References

- [README.md](../README.md)
- [`.github/README.md`](../.github/README.md)
- [`.github/workflows/pr-checks.yml`](../.github/workflows/pr-checks.yml)
- [docs/production-migration-playbook.md](./production-migration-playbook.md)
- [docs/SWIFTDATA_MIGRATION_GUIDE.md](./SWIFTDATA_MIGRATION_GUIDE.md)
