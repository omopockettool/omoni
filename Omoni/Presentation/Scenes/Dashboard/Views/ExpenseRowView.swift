import SwiftUI

// MARK: - Expense Row

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
        case .unpaid:
            return Color(.systemGray2)
        case .paid, .neutral:
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

    private var secondaryAmountSlotHeight: CGFloat {
        isCompact ? 14 : 16
    }

    var body: some View {
        StatusFramedRow(
            tone: rowTone,
            statusIconName: statusIconName,
            statusIconColor: statusIconColor,
            onTap: onTap,
            onToggle: onTogglePaid
        ) {
            HStack(alignment: .top, spacing: 12) {
                Text(itemList.itemListDescription)
                    .font(.system(size: isCompact ? 14 : 15, weight: .medium))
                    .foregroundStyle(Color.primary.opacity(0.92))
                    .lineLimit(1)
                    .frame(maxWidth: .infinity, alignment: .leading)

                VStack(alignment: .trailing, spacing: 4) {
                    Text(primaryAmountText)
                        .font(.system(size: isCompact ? 14 : 15, weight: .semibold, design: .rounded))
                        .foregroundStyle(rowTone.amountColor)
                        .monospacedDigit()
                        .lineLimit(1)
                        .contentTransition(.numericText())

                    ZStack(alignment: .trailing) {
                        Text(" ")
                            .font(.caption)
                            .monospacedDigit()

                        Text(secondaryAmountLabel)
                            .font(.caption)
                            .foregroundStyle(secondaryAmountColor)
                            .monospacedDigit()
                            .lineLimit(1)
                            .opacity(showsSecondaryAmount ? 1 : 0)
                            .offset(y: showsSecondaryAmount ? 0 : -3)
                    }
                    .frame(height: secondaryAmountSlotHeight, alignment: .topTrailing)
                    .clipped()
                }
            }
        }
        .padding(.vertical, isCompact ? 4 : 6)
        .animation(AnimationHelper.quickEase, value: primaryAmountText)
        .animation(AnimationHelper.quickEase, value: secondaryAmountText)
        .animation(AnimationHelper.quickEase, value: showsSecondaryAmount)
    }

    private var secondaryAmountLabel: String {
        guard let secondaryAmountText else { return "" }
        return "\(secondaryAmountText) \(LocalizationKey.Item.unpaid.localized)"
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
