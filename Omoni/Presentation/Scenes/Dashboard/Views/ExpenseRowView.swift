import SwiftUI

private struct LegoSideTab: View {
    let rowStatus: ItemListRowStatus
    let accentColor: Color
    let compact: Bool
    let action: () -> Void

    private var tabWidth: CGFloat { compact ? 36 : 40 }

    private var tabColor: Color {
        switch rowStatus {
        case .neutral: return Color(.systemGray4)
        case .unpaid:  return Color(.systemGray4)
        case .partial: return .orange
        case .paid:    return accentColor
        }
    }

    private var iconName: String {
        switch rowStatus {
        case .neutral:  return "minus"
        case .unpaid:   return "clock"
        case .partial:  return "circle.lefthalf.filled"
        case .paid:     return "checkmark"
        }
    }

    var body: some View {
        Button(action: action) {
            ZStack {
                tabColor
                Image(systemName: iconName)
                    .font(.system(size: compact ? 11 : 12, weight: .bold))
                    .foregroundStyle(.white.opacity(0.9))
            }
            .contentShape(Rectangle())
        }
        .buttonStyle(.plain)
        .frame(width: tabWidth)
        .animation(.spring(response: 0.35, dampingFraction: 0.82), value: rowStatus)
        .toggleHaptic(trigger: rowStatus)
    }
}

private struct LegoCardBorder: View {
    let accentColor: Color
    let compact: Bool

    var cornerRadius: CGFloat { compact ? 18 : 20 }
    var borderWidth: CGFloat { compact ? 2.1 : 2.3 }

    var body: some View {
        ZStack {
            RoundedRectangle(cornerRadius: cornerRadius, style: .continuous)
                .stroke(accentColor.opacity(0.72), lineWidth: borderWidth)
            RoundedRectangle(cornerRadius: cornerRadius, style: .continuous)
                .stroke(Color.white.opacity(0.14), lineWidth: 0.5)
                .padding(1)
        }
        .allowsHitTesting(false)
    }
}

struct ExpenseRowView: View {
    let itemList: SDItemList
    let formattedAmount: String
    let formattedUnpaidAmount: String?
    let searchSummary: String?
    let searchMatchedSubtotal: String?
    let searchMatchedUnpaid: String?
    let rowStatus: ItemListRowStatus
    let onTap: () -> Void
    let onTogglePaid: () -> Void
    var isCompact: Bool = false
    var timelinePosition: TimelinePosition = .single

    private var showsZeroAmountStyle: Bool {
        abs(itemList.totalPaidAmount) < 0.000_001
    }

    private var minimumRowHeight: CGFloat {
        if searchSummary != nil {
            return isCompact ? 88 : 98
        }
        return isCompact ? 80 : 90
    }

    private var contentPadding: CGFloat { isCompact ? 14 : 16 }
    private var shellVerticalPadding: CGFloat { isCompact ? 10 : 12 }
    private var cardCornerRadius: CGFloat { isCompact ? 18 : 20 }
    private var tabWidth: CGFloat { isCompact ? 36 : 40 }

    private var rowAccentColor: Color {
        switch rowStatus {
        case .neutral:
            return Color(.systemGray2)
        case .unpaid:
            return Color(.systemGray2)
        case .partial:
            return .orange
        case .paid:
            return .green
        }
    }

    private var isShowingSearchAmounts: Bool {
        searchMatchedSubtotal != nil
    }

    private var primaryAmountText: String {
        if let searchMatchedSubtotal, isShowingSearchAmounts {
            return searchMatchedSubtotal
        }
        return formattedAmount
    }

    private var secondaryAmountText: String? {
        if isShowingSearchAmounts {
            return searchMatchedUnpaid
        }
        return formattedUnpaidAmount
    }

    private var showsSecondaryAmount: Bool {
        secondaryAmountText != nil
    }

    var body: some View {
        ZStack {
            // Background fill
            RoundedRectangle(cornerRadius: cardCornerRadius, style: .continuous)
                .fill(Color(.secondarySystemBackground))

            // Side tab + content in one HStack, clipped to card shape
            HStack(spacing: 0) {
                LegoSideTab(
                    rowStatus: rowStatus,
                    accentColor: rowAccentColor,
                    compact: isCompact,
                    action: onTogglePaid
                )
                .frame(maxHeight: .infinity)

                rowContent
                    .padding(.horizontal, contentPadding)
                    .padding(.vertical, shellVerticalPadding)
            }
            .clipShape(RoundedRectangle(cornerRadius: cardCornerRadius, style: .continuous))

            // Border drawn last so it sits on top of the tab strip
            LegoCardBorder(accentColor: rowAccentColor, compact: isCompact)
        }
        .frame(maxWidth: .infinity, minHeight: minimumRowHeight)
        .shadow(color: Color.black.opacity(0.03), radius: 8, y: 2)
        .contentShape(Rectangle())
        .onTapGesture { onTap() }
        .padding(.trailing, 2)
    }

    private var rowContent: some View {
        HStack(alignment: .center, spacing: 12) {
            VStack(alignment: .leading, spacing: 0) {
                Text(itemList.itemListDescription)
                    .font(.subheadline)
                    .fontWeight(.semibold)
                    .lineLimit(1)
                    .layoutPriority(1)

                if let searchSummary {
                    Text(searchSummary)
                        .font(.caption)
                        .foregroundStyle(.secondary)
                        .lineLimit(1)
                        .padding(.top, 2)
                }
            }

            Spacer(minLength: 20)

            VStack(alignment: .trailing, spacing: 4) {
                Spacer(minLength: 0)

                Text(primaryAmountText)
                    .font(.subheadline)
                    .fontWeight(primaryAmountFontWeight)
                    .foregroundStyle(primaryAmountColor)
                    .lineLimit(1)
                    .contentTransition(.numericText())
                    .fixedSize(horizontal: true, vertical: false)

                if showsSecondaryAmount {
                    secondaryAmountLine(secondaryAmountText)
                        .transition(.opacity.combined(with: .move(edge: .top)))
                }

                Spacer(minLength: 0)
            }
            .frame(
                minWidth: isCompact ? 72 : 72,
                maxHeight: .infinity,
                alignment: .trailing
            )
            .layoutPriority(1)
            .animation(AnimationHelper.quickEase, value: showsSecondaryAmount)
            .animation(AnimationHelper.quickEase, value: formattedAmount)
            .animation(AnimationHelper.quickEase, value: formattedUnpaidAmount)
            .animation(AnimationHelper.quickEase, value: searchMatchedSubtotal)
            .animation(AnimationHelper.quickEase, value: searchMatchedUnpaid)
        }
    }

    private var primaryAmountFontWeight: Font.Weight {
        showsZeroAmountStyle && !isShowingSearchAmounts ? .semibold : .bold
    }

    private var primaryAmountColor: Color {
        showsZeroAmountStyle && !isShowingSearchAmounts ? Color.secondary : Color.primary
    }

    @ViewBuilder
    private func secondaryAmountLine(_ value: String?) -> some View {
        Text(value.map { "\($0) \(LocalizationKey.Item.unpaid.localized)" } ?? " ")
            .font(.caption)
            .foregroundStyle(.secondary)
            .lineLimit(1)
            .fixedSize(horizontal: true, vertical: false)
            .opacity(value == nil ? 0 : 1)
            .accessibilityHidden(value == nil)
    }
}

#Preview {
    VStack(spacing: 0) {
        ExpenseRowView(
            itemList: SDItemList.mock(itemListDescription: "Compras del supermercado"),
            formattedAmount: "12,89 €",
            formattedUnpaidAmount: nil,
            searchSummary: "3 matching items",
            searchMatchedSubtotal: "€4.00",
            searchMatchedUnpaid: "€1.50",
            rowStatus: .paid,
            onTap: {},
            onTogglePaid: {},
            timelinePosition: .first
        )
        ExpenseRowView(
            itemList: SDItemList.mock(itemListDescription: "Cena en restaurante"),
            formattedAmount: "8,00 €",
            formattedUnpaidAmount: "37,60 €",
            searchSummary: nil,
            searchMatchedSubtotal: nil,
            searchMatchedUnpaid: nil,
            rowStatus: .partial,
            onTap: {},
            onTogglePaid: {},
            timelinePosition: .middle
        )
        ExpenseRowView(
            itemList: SDItemList.mock(itemListDescription: "Farmacia"),
            formattedAmount: "0,00 €",
            formattedUnpaidAmount: "22,00 €",
            searchSummary: nil,
            searchMatchedSubtotal: nil,
            searchMatchedUnpaid: nil,
            rowStatus: .unpaid,
            onTap: {},
            onTogglePaid: {},
            timelinePosition: .last
        )
    }
    .padding()
    .background(Color(.systemGroupedBackground))
}
