import SwiftUI

// MARK: - Status toggle button (left side)

private struct RowStatusButton: View {
    let rowStatus: ItemListRowStatus
    let action: () -> Void

    private var iconName: String {
        switch rowStatus {
        case .neutral:  return "minus"
        case .unpaid:   return "circle"
        case .partial:  return "circle.lefthalf.filled"
        case .paid:     return "checkmark.circle.fill"
        }
    }

    private var iconColor: Color {
        switch rowStatus {
        case .neutral:  return Color(.systemGray4)
        case .unpaid:   return Color(.systemGray3)
        case .partial:  return .orange
        case .paid:     return .paidGreen
        }
    }

    var body: some View {
        Button(action: action) {
            Image(systemName: iconName)
                .font(.system(size: 24, weight: rowStatus == .paid ? .regular : .light))
                .foregroundStyle(iconColor)
                .frame(width: 34, height: 34)
                .contentShape(Rectangle())
        }
        .buttonStyle(.plain)
        .toggleHaptic(trigger: rowStatus)
        .animation(.spring(response: 0.3, dampingFraction: 0.75), value: rowStatus)
    }
}

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

    private var amountColor: Color {
        switch rowStatus {
        case .paid:    return .paidGreen
        case .partial: return .orange
        case .unpaid:  return Color.primary.opacity(0.6)
        case .neutral: return Color.secondary
        }
    }

    private var showsZeroAmountStyle: Bool {
        abs(itemList.totalPaidAmount) < 0.000_001
    }

    var body: some View {
        HStack(alignment: .center, spacing: 10) {
            // Status toggle
            RowStatusButton(rowStatus: rowStatus, action: onTogglePaid)

            // Description + optional search summary
            VStack(alignment: .leading, spacing: 2) {
                Text(itemList.itemListDescription)
                    .font(.system(size: isCompact ? 14 : 15, weight: .regular))
                    .foregroundStyle(Color.primary.opacity(0.9))
                    .lineLimit(1)

                if let searchSummary {
                    Text(searchSummary)
                        .font(.caption)
                        .foregroundStyle(.secondary)
                        .lineLimit(1)
                }
            }
            .frame(maxWidth: .infinity, alignment: .leading)

            // Amount column
            VStack(alignment: .trailing, spacing: 2) {
                Text(primaryAmountText)
                    .font(.system(size: isCompact ? 14 : 15,
                                  weight: showsZeroAmountStyle ? .light : .light,
                                  design: .default))
                    .foregroundStyle(showsZeroAmountStyle ? Color.secondary : amountColor)
                    .monospacedDigit()
                    .lineLimit(1)
                    .contentTransition(.numericText())

                if let secondary = secondaryAmountText {
                    Text("\(secondary) \(LocalizationKey.Item.unpaid.localized)")
                        .font(.caption2)
                        .foregroundStyle(.orange.opacity(0.75))
                        .monospacedDigit()
                        .lineLimit(1)
                        .transition(.opacity.combined(with: .move(edge: .top)))
                }
            }
            .animation(AnimationHelper.quickEase, value: formattedAmount)
            .animation(AnimationHelper.quickEase, value: secondaryAmountText)
        }
        .padding(.vertical, isCompact ? 14 : 17)
        .overlay(alignment: .bottom) {
            Rectangle()
                .fill(Color(.separator).opacity(0.3))
                .frame(height: 0.5)
        }
        .contentShape(Rectangle())
        .onTapGesture { onTap() }
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
