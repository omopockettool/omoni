# OMONI Color System Tech Debt

Status: pending
Type: evolutive task
Priority: medium
Created: 2026-07-07

Related document: [COLOR_PALETTE.md](./COLOR_PALETTE.md)

## Summary

OMONI already has a recognizable color language, but the system is still split across:

- `AccentColor.colorset`
- `Color+Hex.swift`
- direct semantic iOS colors in views
- state colors defined in unrelated helpers
- dynamic category and payment-method palettes

This works for the current MVP, but it is now technical debt. The next evolutive step is to centralize the color system so product UI, App Store creatives, and future design work all use the same structure and vocabulary.

## Why this is debt

Today, color decisions are distributed instead of centralized.

Examples:

- Brand red lives in both `AccentColor.colorset` and `Color+Hex.swift`.
- Success green lives in `PressHapticButtonStyle.swift`, which is not a color-system file.
- Many surfaces still use direct semantic colors like:
  - `Color(.systemBackground)`
  - `Color(.secondarySystemBackground)`
  - `Color(.secondarySystemGroupedBackground)`
  - `Color(.tertiarySystemGroupedBackground)`
  - `.orange`
  - `.red`
  - `.accentColor`
- Dynamic palette logic for payment methods is centralized in `PaymentMethodAppearance`, but not formally integrated into a broader color system.

This makes it harder to:

- keep brand and interaction color aligned
- tune visual intensity consistently
- produce marketing assets from product truth
- evolve the UI without color drift
- reason about roles such as `brand`, `interactive`, `surface`, `state`, and `dynamic palette`

## Goal

Create a centralized color system for OMONI without changing persisted data models and without breaking the current visual language.

## Non-goals

- No SwiftData schema changes
- No redesign of category colors
- No redesign of payment-method icon mapping
- No marketing redesign by itself
- No broad UI restyle in the same pass

## Recommended deliverable

Create a dedicated file, likely:

- `Omoni/Infrastructure/Design/ColorTokens.swift`

or, if you want to stay closer to the current structure:

- `Omoni/Infrastructure/Extensions/ColorTokens.swift`

Preferred direction: a dedicated design-system file instead of continuing to grow `Color+Hex.swift`.

## Proposed token structure

### 1. Brand

- `ColorTokens.Brand.red`
- `ColorTokens.Brand.redSoft` only if product and marketing intentionally diverge
- `ColorTokens.Brand.white`

### 2. Interactive

- `ColorTokens.Interactive.accent`
- `ColorTokens.Interactive.accentPressed`
- `ColorTokens.Interactive.link`

### 3. Surface

- `ColorTokens.Surface.background`
- `ColorTokens.Surface.secondary`
- `ColorTokens.Surface.groupedCard`
- `ColorTokens.Surface.selectionSoft`

Note: these may still wrap semantic iOS colors internally. Centralization is the first win even if some values remain semantic.

### 4. Text / neutral

- `ColorTokens.Text.primary`
- `ColorTokens.Text.secondary`
- `ColorTokens.Neutral.gray1`
- `ColorTokens.Neutral.gray2`
- `ColorTokens.Neutral.gray3`

### 5. State

- `ColorTokens.State.success`
- `ColorTokens.State.warning`
- `ColorTokens.State.error`
- `ColorTokens.State.neutral`

### 6. Dynamic palette families

- `ColorTokens.CategoryPalette`
- `ColorTokens.PaymentMethodPalette`

These should not replace persisted category/payment colors. They should only centralize the visible source-of-truth definitions and mappings.

## Scope of work

### Phase 1: Centralize without redesign

- Create `ColorTokens.swift`
- Move brand red references into tokens
- Move success green out of `PressHapticButtonStyle.swift`
- Wrap existing semantic backgrounds in token names
- Keep all current visual output effectively the same

### Phase 2: Replace obvious direct color calls

Replace repeated direct usages of:

- `.accentColor`
- `.orange`
- `.red`
- `Color(.systemGray3)`
- `Color(.systemGray4)`
- `Color(.systemGray5)`
- `Color(.secondarySystemBackground)`
- `Color(.secondarySystemGroupedBackground)`

Only do this where the role is clear and stable.

### Phase 3: Fold in dynamic palettes

- Route category selectable palette through one shared definition
- Route payment-method tint families through one shared definition
- Keep `PaymentMethodAppearance` as the visible integration point unless a better shared abstraction naturally emerges

### Phase 4: Documentation alignment

- Update `docs/COLOR_PALETTE.md`
- Add usage notes for design / App Store / marketing
- Define which colors are product tokens vs marketing working colors

## Candidate files affected

- `Omoni/Infrastructure/Extensions/Color+Hex.swift`
- `Omoni/Infrastructure/Helpers/PressHapticButtonStyle.swift`
- `Omoni/Presentation/Common/Components/PrimaryToolbarCheckButton.swift`
- `Omoni/Presentation/Common/Components/Toast/ToastView.swift`
- `Omoni/Presentation/Scenes/User/Views/CreateFirstUserView.swift`
- `Omoni/Presentation/Common/Components/Loading/SplashView.swift`
- `Omoni/Presentation/Scenes/Category/Views/CategoryFormView.swift`
- `Omoni/Presentation/Scenes/PaymentMethod/View/PaymentMethodAppearance.swift`
- dashboard and item-list surfaces using repeated semantic surface grays

## Risks

### Visual risk

The main risk is not technical breakage; it is subtle visual drift.

Examples:

- brand red becoming too aggressive in interaction-heavy surfaces
- grouped cards changing tone if semantic wrappers are replaced too eagerly
- warning and success colors feeling too loud after centralization

### Product risk

If product roles are not defined clearly, tokenization can freeze bad naming and spread confusion faster.

## Risk controls

- Centralize names before changing visual values
- Keep Phase 1 visually equivalent
- Separate `brand` from `state`
- Treat dynamic category and payment-method colors as functional palettes, not generic brand tokens
- Review screenshots of onboarding, dashboard, category form, payment-method form, and item-list detail after migration

## Acceptance criteria

- There is one obvious place to understand OMONI colors
- Brand red is no longer defined ad hoc in multiple places
- Success / warning / error roles are defined centrally
- Shared surfaces and neutral roles have clear token names
- Category and payment-method palettes are documented and reusable
- `docs/COLOR_PALETTE.md` stays aligned with implementation

## Suggested implementation strategy

1. Introduce tokens without changing behavior
2. Migrate brand and state colors first
3. Migrate shared surfaces next
4. Migrate dynamic palettes last
5. Only then consider any palette refinement or visual redesign

## Effort estimate

- Phase 1 only: low
- Phase 1 + Phase 2: low-medium
- Full cleanup including dynamic palette consolidation and docs: medium

## Recommended follow-up task title

`Evolutivo: centralize OMONI color system into ColorTokens and align product + marketing palette`
