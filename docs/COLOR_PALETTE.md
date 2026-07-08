# OMONI Color Palette

Snapshot date: 2026-07-07

This document captures the current OMONI color palette for App Store screenshots, marketing compositions, and visual planning. It reflects the app as it exists today, including both fixed colors from code/assets and dynamic semantic colors used by the UI.

## Current status

- Brand red is now unified to `#FF3D4B`.
- The app does not yet have a centralized `ColorTokens.swift`.
- Some neutrals and status colors still come from iOS semantic system colors rather than fixed hex tokens.

## 1. Core brand colors

| Role | Hex / Value | Notes |
| --- | --- | --- |
| Brand red | `#FF3D4B` | Main OMONI red. Use as the primary accent for brand, CTA emphasis, active highlights, and App Store screenshot accents. |
| White | `#FFFFFF` | Logo fill, clean surface contrast, screenshot text over red backgrounds. |
| Paid green | `#389966` | Current success/completed state color used in the product. |

## 2. Product semantic colors

These are part of the real product language, but they are not yet fully centralized as fixed tokens.

| Role | Current source | Notes |
| --- | --- | --- |
| Primary text / black base | `Color.primary` | In practice, this behaves like the app's main dark text color in light mode. |
| Main background | `Color(.systemBackground)` | Base page/screen background. |
| Secondary surface | `Color(.secondarySystemBackground)` | Used for softer panels and chips. |
| Grouped card surface | `Color(.secondarySystemGroupedBackground)` | Used heavily in cards, forms, and grouped controls. |
| Soft selected surface | `Color(.tertiarySystemGroupedBackground)` | Used for selected pills and soft selection states. |
| Neutral gray | `Color(.systemGray3)` | Default neutral state. |
| Border gray | `Color(.systemGray4)` | Light border and stroke usage. |
| Fill gray | `Color(.systemGray5)` | Soft fills and dividers. |
| Toast gray | `Color(.systemGray6)` | Toast background. |
| Pending / warning | `.orange` | Used for pending, partial, warning emphasis. |
| Error | `.red` | Used for destructive/error feedback. |

## 3. Recommended working neutrals for marketing

These are recommended static values for screenshot layouts and mood boards. They are not yet product tokens, but they are the closest practical working set to the current UI language.

| Role | Recommended hex | Why |
| --- | --- | --- |
| Marketing black | `#111111` | Clean near-black companion for the brand red in headlines and overlays. |
| Marketing gray | `#8E8E93` | Matches the existing neutral gray family already present in the data layer. |
| Marketing soft gray | `#F2F2F7` | Good static stand-in for iOS grouped surfaces in screenshot backgrounds. |
| Marketing white | `#FFFFFF` | Clean contrast background and typography support. |

## 4. Category selectable palette

Current selectable category colors from the category form:

| Family | Hex |
| --- | --- |
| Red | `#FF453A` |
| Orange | `#FF9F0A` |
| Yellow | `#FFD60A` |
| Green | `#30D158` |
| Blue | `#0A84FF` |
| Indigo | `#5E5CE6` |
| Purple | `#BF5AF2` |
| Pink | `#FF375F` |
| Cyan | `#64D2FF` |
| Coral | `#FF6B35` |
| Teal | `#4ECDC4` |
| Gray | `#95A5A6` |

## 5. Payment method / origin palette

Current origin tint logic is icon-driven:

| Origin family | Hex | Typical icons |
| --- | --- | --- |
| Cash | `#30D158` | `banknote.fill`, `dollarsign.circle.fill`, `eurosign.circle.fill` |
| Transfer / QR | `#FF9F0A` | `arrow.left.arrow.right`, `qrcode` |
| Wallet / Phone | `#BF5AF2` | `iphone`, `wallet.pass.fill` |
| Card / Bank | `#0A84FF` | `creditcard.fill`, `building.columns.fill`, `checkmark.seal.fill` |

## 6. Default seeded colors in sample data

These are the colors currently used by the app when creating default payment methods and categories for a new group.

### Default payment methods

| Name | Hex |
| --- | --- |
| Efectivo | `#4CAF50` |
| Débito | `#2196F3` |
| Crédito | `#9C27B0` |
| Transferencia | `#FF9800` |

### Default categories

| Name | Hex |
| --- | --- |
| Alimentación | `#FF6B6B` |
| Movilidad | `#4ECDC4` |
| Hogar | `#45B7D1` |
| Salud | `#FFEAA7` |
| Ocio | `#96CEB4` |
| Ropa | `#FFA7ED` |

## 7. Suggested screenshot palette for App Store / marketing

If you want a simple palette to start composing right now, this is the most practical cut:

| Use | Hex |
| --- | --- |
| Main brand accent | `#FF3D4B` |
| Headline dark | `#111111` |
| Soft background | `#F2F2F7` |
| White space / cards | `#FFFFFF` |
| Success accent | `#389966` |
| Secondary blue | `#0A84FF` |
| Secondary orange | `#FF9F0A` |
| Secondary purple | `#BF5AF2` |
| Secondary teal | `#4ECDC4` |

## 8. Technical notes

- The strongest current source of truth for brand red is the combination of `AccentColor.colorset` and `Color.omoniBrandRed`.
- Dynamic iOS semantic colors are still part of the actual product look, so not every visible gray in the app has a single hardcoded hex today.
- A future `ColorTokens.swift` should centralize:
  - brand
  - interactive
  - surfaces
  - neutrals
  - states
  - dynamic palette families

## 9. Source files

- `Omoni/Assets.xcassets/AccentColor.colorset/Contents.json`
- `Omoni/Infrastructure/Extensions/Color+Hex.swift`
- `Omoni/Infrastructure/Helpers/PressHapticButtonStyle.swift`
- `Omoni/Presentation/Scenes/Category/Views/CategoryFormView.swift`
- `Omoni/Presentation/Scenes/PaymentMethod/View/PaymentMethodAppearance.swift`
- `Omoni/Data/Repositories/DefaultGroupRepository.swift`
