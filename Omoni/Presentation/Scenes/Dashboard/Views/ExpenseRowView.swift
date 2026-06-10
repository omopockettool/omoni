import SwiftUI

// MARK: - Expense Row

private enum ExpenseRowLayoutMetrics {
    static func trailingAmountColumnHeight(isCompact: Bool) -> CGFloat {
        isCompact ? 36 : 42
    }
}

struct ExpenseRowView: View {
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

    private var targetSecondaryAmountText: String? {
        searchMatchedSubtotal != nil ? searchMatchedUnpaid : formattedUnpaidAmount
    }

    private var showsSplitAmounts: Bool {
        switch rowStatus {
        case .partial, .unpaid:
            return targetSecondaryAmountText != nil
        case .paid, .neutral:
            return false
        }
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

    private var secondaryAmountColor: Color {
        switch rowStatus {
        case .partial, .unpaid:
            return .orange
        case .paid, .neutral:
            return .secondary
        }
    }

    private var trailingAmountColumnHeight: CGFloat {
        ExpenseRowLayoutMetrics.trailingAmountColumnHeight(isCompact: isCompact)
    }

    private var trailingAmountAnimationCurve: Animation {
        .easeInOut(duration: 0.2)
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
        .animation(trailingAmountAnimationCurve, value: showsSplitAmounts)
        .onAppear { detailTitleColor = defaultDetailTitleColor }
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

            withAnimation(AnimationHelper.flashIn) {
                detailTitleColor = flashColor
            }
            withAnimation(AnimationHelper.flashOut) {
                detailTitleColor = defaultDetailTitleColor
            }
        }
    }

    @ViewBuilder
    private var trailingAmountColumn: some View {
        // Keep the right column height stable so paid/unpaid toggles animate internally
        // instead of changing the overall row height.
        // No maxWidth: .infinity here — the column sizes to its content so the title
        // gets all remaining space when the amount is short.
        ZStack(alignment: .trailing) {
            primaryAmountReservationView

            centeredPrimaryAmountView
                .frame(height: trailingAmountColumnHeight, alignment: .trailing)
                .opacity(showsSplitAmounts ? 0 : 1)

            splitAmountsView
                .frame(height: trailingAmountColumnHeight, alignment: .trailing)
                .opacity(showsSplitAmounts ? 1 : 0)
        }
        .fixedSize(horizontal: true, vertical: false)
        .frame(height: trailingAmountColumnHeight, alignment: .topTrailing)
        .clipped()
    }

    @ViewBuilder
    private var primaryAmountReservationView: some View {
        primaryAmountReservationText(primaryAmountText)

        if let targetSecondaryAmountText {
            primaryAmountReservationText(targetSecondaryAmountText)
        }
    }

    private var centeredPrimaryAmountView: some View {
        primaryAmountTextView(primaryAmountText)
    }

    private var splitAmountsView: some View {
        ZStack(alignment: .trailing) {
            primaryAmountTextView(primaryAmountText)
                .frame(height: trailingAmountColumnHeight, alignment: .topTrailing)

            if let targetSecondaryAmountText {
                secondaryAmountTextView(targetSecondaryAmountText)
                    .frame(height: trailingAmountColumnHeight, alignment: .bottomTrailing)
            }
        }
    }

    private func primaryAmountTextView(_ text: String) -> some View {
        Text(text)
            .font(.system(size: isCompact ? 14 : 15, weight: .semibold, design: .rounded))
            .foregroundStyle(rowTone.amountColor)
            .monospacedDigit()
            .lineLimit(1)
            .animation(.none, value: rowTone)
    }

    private func primaryAmountReservationText(_ text: String) -> some View {
        Text(text)
            .font(.system(size: isCompact ? 14 : 15, weight: .semibold, design: .rounded))
            .monospacedDigit()
            .lineLimit(1)
            .hidden()
    }

    private func secondaryAmountTextView(_ text: String) -> some View {
        Text(text)
            .font(.caption)
            .foregroundStyle(secondaryAmountColor)
            .monospacedDigit()
            .lineLimit(1)
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
