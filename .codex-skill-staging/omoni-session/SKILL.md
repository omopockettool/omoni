---
name: omoni-session
description: Use this skill for any request involving the OMONI iOS project, Swift files in this repository, architecture decisions for OMONI, or UX direction for the OMO Pocket Tools ecosystem.
---

# OMONI Session Bootstrap

Use this skill for any task in the OMONI repository.

## Default stance

- Operate as a professional UX designer and iOS engineer, not only as a coder.
- Treat the OMO Pocket Tools ecosystem as Apple-like: intentional, calm, polished, native-feeling, and never hacky.
- Keep responses concise by default to reduce token usage.
- Avoid verbosity unless the user explicitly asks for more detail.

## Session bootstrap

1. Read `docs/START_HERE.md` first.
2. Always read `docs/swiftui_data_flow_guide.md` before touching SwiftUI code, even if the request seems small.
3. Then read any other files explicitly marked in `docs/START_HERE.md` as required or recommended for the task.
4. Follow the architecture, workflow, and validation constraints from the project docs.

## Guardrails

- Never run `git commit`, `git add`, or other git write commands unless the user explicitly asks for them.
- Never run `xcodebuild`, simulator builds, or launch flows for routine validation in this project.
- Prefer fixing problems at the correct layer rather than patching SwiftUI views.
- Keep views light: avoid bootstrap orchestration, repair logic, and duplicated loading in view modifiers.
- When the user asks for `changelog` or `commit`, always ask which version bump category applies first: `major`, `minor`, or `fix`, unless the user already specified it.
- For changelog work, do not assume the next version number. Confirm the intended bump category first, then map it to the explicit semantic version.
- Keep release metadata aligned: when a release version is finalized, update Xcode `MARKETING_VERSION` to match it so future backups export the same public version.
- When suggesting a release/version commit message, use the exact format `type: summary and release [x.y.z]` with the semantic version wrapped in square brackets. Example: `feat: refine dashboard date drill-down and release [2.5.0]`.

## Load references only when useful

- Read `references/session-checklist.md` when you want a quick session reminder without reopening the full project docs.
- Read `references/architecture-guardrails.md` when touching layering, DI, SwiftData, ViewModels, or view lifecycle decisions.
- Read `references/ux-direction.md` when shaping flows, interaction quality, wording, visual behavior, or product feel.
- Read `references/release-versioning.md` when preparing changelog entries, release notes, or commit suggestions tied to a version bump.

## Use scripts when useful

- Run `scripts/find_legacy_naming.sh` before or during naming migrations from `OMOMoney` to `OMONI`.
- Run `scripts/find_architecture_red_flags.sh` when auditing for forbidden patterns in Presentation or legacy architecture leftovers.
