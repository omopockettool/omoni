# OMONI Session Checklist

Use this as a lightweight reminder after the main project docs have already been read.

## Before editing

1. Read `docs/START_HERE.md`.
2. Read `docs/swiftui_data_flow_guide.md` before touching SwiftUI.
3. Check whether the task is really local to one layer or needs a deeper architectural fix.

## During implementation

- Think like an iOS engineer and UX designer together.
- Favor Apple-like flows: clear hierarchy, calm motion, obvious intent, no visual or architectural hacks.
- Keep views dumb and light.
- Push orchestration, loading, and decision logic into ViewModels, UseCases, or Repositories as appropriate.
- Use DI through `AppDIContainer`.
- Prefer concise communication unless the user asks for depth.

## Before finishing

- Re-scan the changed area for architecture drift or naming regressions.
- Mention if validation was not run because the project uses manual device verification.
- Suggest a commit message only if it helps; do not commit.
