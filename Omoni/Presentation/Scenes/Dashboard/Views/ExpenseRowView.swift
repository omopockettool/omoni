import SwiftUI

// MARK: - Expense Row

private enum ExpenseRowLayoutMetrics {
    static func trailingAmountColumnHeight(isCompact: Bool) -> CGFloat {
        isCompact ? 36 : 42
    }

    static func primaryAmountVerticalOffset(hasSecondaryAmount: Bool, isCompact: Bool) -> CGFloat {
        guard hasSecondaryAmount else { return 0 }
        return isCompact ? -7 : -8
    }
}

struct ExpenseRowView: View {
    @State private var displayedPrimaryAmount = ""
    @State private var primaryAmountIsDecreasing = false
    @State private var detailTitleColor: Color = Color.primary.opacity(0.92)

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

    private var primaryAmountText: String {
        searchMatchedSubtotal ?? formattedAmount
    }

    private var secondaryAmountText: String? {
        searchMatchedSubtotal != nil ? searchMatchedUnpaid : formattedUnpaidAmount
    }

    private var rowTone: StatusFramedRowTone {
        switch rowStatus {
        case .paid:
            return .completed
        case .partial, .unpaid:
            return .neutral
        case .neutral:
            return .neutral
        }
    }

    private var statusIconName: String {
        switch rowStatus {
        case .paid:
            return "checkmark"
        case .partial:
            return "circle.lefthalf.filled"
        case .unpaid:
            return "circle"
        case .neutral:
            return "minus"
        }
    }

    private var statusIconColor: Color? {
        switch rowStatus {
        case .partial:
            return .orange
        case .unpaid, .neutral:
            return Color(.systemGray2)
        case .paid:
            return nil
        }
    }

    private var showsSecondaryAmount: Bool {
        switch rowStatus {
        case .partial, .unpaid:
            return secondaryAmountText != nil
        case .paid, .neutral:
            return false
        }
    }

    private var secondaryAmountColor: Color {
        switch rowStatus {
        case .partial:
            return .orange
        case .unpaid, .paid, .neutral:
            return .secondary
        }
    }

    private var trailingAmountColumnHeight: CGFloat {
        ExpenseRowLayoutMetrics.trailingAmountColumnHeight(isCompact: isCompact)
    }

    private var trailingAmountAnimationCurve: Animation {
        .spring(response: 0.45, dampingFraction: 0.78, blendDuration: 0.15)
    }

    private var primaryAmountVerticalOffset: CGFloat {
        ExpenseRowLayoutMetrics.primaryAmountVerticalOffset(
            hasSecondaryAmount: showsSecondaryAmount,
            isCompact: isCompact
        )
    }

    private var defaultDetailTitleColor: Color {
        Color.primary.opacity(0.92)
    }

    var body: some View {
        StatusFramedRow(
            tone: rowTone,
            statusIconName: statusIconName,
            statusIconColor: statusIconColor,
            onTap: onTap,
            onToggle: onTogglePaid
        ) {
            HStack(alignment: .center, spacing: 12) {
                Text(itemList.itemListDescription)
                    .font(.system(size: isCompact ? 14 : 15, weight: .medium))
                    .foregroundStyle(detailTitleColor)
                    .lineLimit(1)
                    .frame(maxWidth: .infinity, maxHeight: .infinity, alignment: .leading)

                trailingAmountColumn
            }
        }
        .padding(.vertical, isCompact ? 4 : 6)
        .animation(trailingAmountAnimationCurve, value: showsSecondaryAmount)
        .animation(trailingAmountAnimationCurve, value: secondaryAmountText)
        .onAppear {
            displayedPrimaryAmount = primaryAmountText
            detailTitleColor = defaultDetailTitleColor
        }
        .onChange(of: primaryAmountText) { oldValue, newValue in
            let oldDigits = extractDigits(from: oldValue)
            let newDigits = extractDigits(from: newValue)
            primaryAmountIsDecreasing = newDigits < oldDigits
            withAnimation(trailingAmountAnimationCurve) {
                displayedPrimaryAmount = newValue
            }
        }
        .onChange(of: rowStatus) { oldValue, newValue in
            guard oldValue != newValue else { return }

            let flashColor: Color?
            switch (oldValue, newValue) {
            case (_, .paid):
                flashColor = .paidGreen
            case (.paid, _):
                flashColor = Color(.systemGray2)
            default:
                flashColor = nil
            }

            guard let flashColor else { return }

            withAnimation(.easeIn(duration: 0.12)) {
                detailTitleColor = flashColor
            }
            withAnimation(.easeOut(duration: 0.45).delay(0.15)) {
                detailTitleColor = defaultDetailTitleColor
            }
        }
    }

    @ViewBuilder
    private var trailingAmountColumn: some View {
        // Keep the right column height stable so paid/unpaid toggles animate internally
        // instead of changing the overall row height.
        ZStack(alignment: .trailing) {
            primaryAmountView
                .frame(maxWidth: .infinity, alignment: .trailing)
                .frame(height: trailingAmountColumnHeight, alignment: .trailing)
                .offset(y: primaryAmountVerticalOffset)

            secondaryAmountView
                .frame(maxWidth: .infinity, alignment: .trailing)
                .frame(height: trailingAmountColumnHeight, alignment: .bottomTrailing)
                .opacity(showsSecondaryAmount ? 1 : 0)
        }
        .frame(height: trailingAmountColumnHeight, alignment: .topTrailing)
        .clipped()
    }

    private var primaryAmountView: some View {
        Text(displayedPrimaryAmount)
            .font(.system(size: isCompact ? 14 : 15, weight: .semibold, design: .rounded))
            .foregroundStyle(rowTone.amountColor)
            .monospacedDigit()
            .lineLimit(1)
            .contentTransition(.numericText(countsDown: primaryAmountIsDecreasing))
            .animation(trailingAmountAnimationCurve, value: displayedPrimaryAmount)
    }

    private var secondaryAmountView: some View {
        Text(secondaryAmountLabel)
            .font(.caption)
            .foregroundStyle(secondaryAmountColor)
            .monospacedDigit()
            .lineLimit(1)
            .offset(y: showsSecondaryAmount ? 0 : -6)
    }

    private var secondaryAmountLabel: String {
        guard let secondaryAmountText else { return "" }
        return "\(secondaryAmountText) \(LocalizationKey.Item.unpaid.localized)"
    }

    private func extractDigits(from string: String) -> Int {
        Int(string.filter(\.isNumber)) ?? 0
    }
}

#Preview {
    VStack(spacing: 0) {
        ExpenseRowView(
            itemList: SDItemList.mock(itemListDescription: "Compras del supermercado"),
            formattedAmount: "12,89 €",
            formattedUnpaidAmount: nil,
            searchSummary: nil,
            searchMatchedSubtotal: nil,
            searchMatchedUnpaid: nil,
            rowStatus: .paid,
            onTap: {},
            onTogglePaid: {}
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
            onTogglePaid: {}
        )
        ExpenseRowView(
            itemList: SDItemList.mock(itemListDescription: "Farmacia"),
            formattedAmount: "22,00 €",
            formattedUnpaidAmount: nil,
            searchSummary: nil,
            searchMatchedSubtotal: nil,
            searchMatchedUnpaid: nil,
            rowStatus: .unpaid,
            onTap: {},
            onTogglePaid: {}
        )
    }
    .padding(.horizontal, 20)
    .background(Color(.systemGroupedBackground))
}
