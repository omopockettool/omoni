# OMONI Architecture Guardrails

Use this file when working on app structure, data flow, or SwiftUI lifecycle-sensitive screens.

## Core shape

`View -> ViewModel -> UseCase -> Repository -> ModelContext`

- SwiftData `SD*` models are the source of truth.
- Presentation can use `SD*`, UseCases, `AppDIContainer`, and `@Query` where already appropriate.
- Presentation must not talk directly to repositories or `ModelContext`.

## Rules that matter most

- Views render; ViewModels decide.
- No repair logic in SwiftUI views after presentation.
- No quick fixes that bypass layering just to make the screen work.
- Prefer one clear loading path instead of stacked `.task`, `onAppear`, and reactive band-aids.
- Use `@Observable` and `@MainActor` for ViewModels.
- Create dependencies through `AppDIContainer`.

## Common red flags

- `import CoreData` in Presentation
- `@Environment(\\.managedObjectContext)`
- Direct repository creation inside a View
- `ObservableObject` plus `@Published` in places that should now be `@Observable`
- View-side async bootstrap needed to "finish" the screen

## Escalation heuristic

If a fix is tempting in a SwiftUI view, pause and check whether the real owner is:

- ViewModel: state preparation, selection recovery, async coordination, display-state mapping
- UseCase: business rule, validation, derived totals, orchestration across repositories
- Repository: persistence behavior, fetch scope, ordering, SwiftData access
