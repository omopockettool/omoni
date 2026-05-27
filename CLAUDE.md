# OMONI — Claude Code Session Bootstrap

> Parallel to `.codex/skills/omoni-session`. Both agents share the same rules and docs.

## Session entry (read every time)

1. Read `docs/START_HERE.md`.
2. Read `docs/swiftui_data_flow_guide.md` before touching any SwiftUI code.
3. Operate as a professional iOS engineer and UX designer, not only as a coder.
4. Treat OMO Pocket Tools as Apple-like: intentional, calm, polished, native-feeling, never hacky.

## Critical rules (never violate)

- **No commits.** Never run `git commit`, `git add`, or `git push`. Only suggest the commit message as text.
- **No builds.** Never run `xcodebuild` or launch simulators. Dennis validates on physical device.
- **No mocks in tests.** Use `SwiftDataTestContainer` (in-memory SwiftData) — never mock the repository.
- **No logic in Views.** Views render; ViewModels decide. No bootstrap, repair, or orchestration in SwiftUI body.
- **No quick fixes.** No view-side band-aids, duplicated loading paths, or special-case glue code.
- **No architecture drift.** `View → ViewModel → UseCase → Repository → ModelContext`. Enforce strictly.

## Architecture guardrails

- SD* models are the single source of truth (no Domain entity structs).
- Presentation must not import CoreData, create repositories directly, or access ModelContext.
- `@Observable` + `@MainActor` for all ViewModels.
- All dependencies created through `AppDIContainer`.

## Red flags (reject immediately)

```swift
import CoreData                                  // forbidden in Presentation
@Environment(\.managedObjectContext)             // forbidden
class VM: ObservableObject { @Published var }    // use @Observable
let service = UserService(...)                   // Services are deleted
.task { await loadToFixTheScreen() }             // bootstrap belongs in ViewModel
onAppear { repairStateAfterPresentation() }      // view-side patching forbidden
```

## Task completion workflow (mandatory, every task)

1. Run tests — report results before anything else.
2. Wait for Dennis to validate on physical device.
3. On positive feedback:
   - Ask: "major, minor, or fix?"
   - Update `CHANGELOG.md` in English with the version bump.
   - Suggest commit: `<type>: <description> [x.x.x]`

## Response style

- Concise by default. No trailing summaries. No re-explaining what was just done.
- English only for CHANGELOG.md entries.
- When work is done, output only the suggested commit message.

## Shared helpers (use before creating new ones)

| Helper | File |
|--------|------|
| `PressHapticButtonStyle` | `Infrastructure/Helpers/PressHapticButtonStyle.swift` |
| `AnimationHelper.smoothSpring / quickSpring / quickEase` | `Infrastructure/Helpers/AnimationHelper.swift` |
| `AppConstants.UserInterface.padding` (16pt) | `Infrastructure/Constants/AppConstants.swift` |
| `AppConstants.UserInterface.cornerRadius` (16pt) | same |

## Reference docs

- Architecture + layer rules: `docs/START_HERE.md`
- SwiftUI data flow, `@Observable`, `.task`, view identity: `docs/swiftui_data_flow_guide.md`
- SwiftData quick reference: `docs/SWIFTDATA_QUICK_REFERENCE.md`
- Localization: `docs/LOCALIZATION_SETUP.md`
