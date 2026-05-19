import SwiftUI

private struct LegoConnectorGuideLine: View {
    let color: Color
    let visible: Bool
    let compact: Bool

    private var width: CGFloat { compact ? 22 : 28 }

    var body: some View {
        Rectangle()
            .fill(color.opacity(visible ? 0.55 : 0))
            .frame(width: 2.4, height: width)
    }
}

private struct LegoConnectorButton: View {
    let iconName: String?
    let tintColor: Color
    let isActive: Bool
    let compact: Bool
    let action: () -> Void

    private var size: CGFloat {
        compact ? 30 : 34
    }

    var body: some View {
        Button(action: action) {
            Circle()
                .fill(isActive ? tintColor : Color(.systemGray4))
                .overlay {
                    Circle()
                        .stroke(isActive ? tintColor.opacity(0.2) : Color.black.opacity(0.05), lineWidth: 0.8)
                }
                .overlay {
                    Group {
                        if let iconName {
                            Image(systemName: iconName)
                                .font(.system(size: compact ? 12 : 13, weight: .bold))
                        } else {
                            Circle()
                                .fill(Color.white.opacity(0.95))
                                .frame(width: compact ? 7 : 8, height: compact ? 7 : 8)
                        }
                    }
                    .foregroundStyle(isActive ? Color.white.opacity(0.98) : Color(.systemGray2))
                }
                .frame(width: size, height: size)
                .contentShape(Circle())
        }
        .buttonStyle(PressHapticButtonStyle())
        .frame(width: 48, height: 48)
    }
}

private struct LegoExpenseCapsuleChrome: View {
    let accentColor: Color
    let compact: Bool

    private var fillColor: Color {
        Color(.secondarySystemBackground).opacity(0.16)
    }

    private var borderWidth: CGFloat {
        compact ? 2.1 : 2.3
    }

    private var cornerRadius: CGFloat {
        compact ? 18 : 20
    }

    var body: some View {
        RoundedRectangle(cornerRadius: cornerRadius, style: .continuous)
            .fill(fillColor)
            .overlay {
                RoundedRectangle(cornerRadius: cornerRadius, style: .continuous)
                    .stroke(accentColor.opacity(0.72), lineWidth: borderWidth)
            }
            .overlay {
                RoundedRectangle(cornerRadius: cornerRadius, style: .continuous)
                    .stroke(Color.white.opacity(0.14), lineWidth: 0.5)
                    .padding(1)
            }
            .shadow(color: Color.black.opacity(0.03), radius: 8, y: 2)
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
            return isCompact ? 82 : 92
        }
        return isCompact ? 74 : 82
    }

    private var contentPadding: CGFloat {
        isCompact ? 18 : 20
    }

    private var shellVerticalPadding: CGFloat {
        isCompact ? 10 : 11
    }

    private var topMarkerLift: CGFloat {
        isCompact ? 24 : 27
    }

    private var parentTopPadding: CGFloat {
        isCompact ? 12 : 13
    }

    private var rowAccentColor: Color {
        if rowStatus == .unpaid {
            return Color(.systemGray2)
        }

        if let categoryColor = itemList.category?.color,
           let parsedColor = Color(hex: categoryColor) {
            return parsedColor
        }

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

    private var connectorIconName: String? {
        switch rowStatus {
        case .neutral:
            return nil
        case .unpaid:
            return "circle"
        case .partial:
            return "circle.lefthalf.filled"
        case .paid:
            return "checkmark"
        }
    }

    private var connectorIsActive: Bool {
        rowStatus != .neutral && rowStatus != .unpaid
    }

    var body: some View {
        VStack(spacing: 0) {
            LegoConnectorGuideLine(
                color: rowAccentColor,
                visible: timelinePosition.showsTopLine,
                compact: isCompact
            )

            ZStack(alignment: .top) {
                Color.clear

                ZStack(alignment: .top) {
                    LegoExpenseCapsuleChrome(
                        accentColor: rowAccentColor,
                        compact: isCompact
                    )

                    rowContent
                        .padding(.horizontal, contentPadding)
                        .padding(.top, shellVerticalPadding + (isCompact ? 10 : 12))
                        .padding(.bottom, shellVerticalPadding + 2)

                    LegoConnectorButton(
                        iconName: connectorIconName,
                        tintColor: rowAccentColor,
                        isActive: connectorIsActive,
                        compact: isCompact,
                        action: onTogglePaid
                    )
                    .offset(y: -topMarkerLift)
                }
                .padding(.top, parentTopPadding)
            }
            .frame(maxWidth: .infinity, minHeight: minimumRowHeight)

            LegoConnectorGuideLine(
                color: rowAccentColor,
                visible: timelinePosition.showsBottomLine,
                compact: isCompact
            )
        }
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

                if let searchSummary {
                    Text(searchSummary)
                        .font(.caption)
                        .foregroundStyle(.secondary)
                        .lineLimit(1)
                        .padding(.top, 2)
                }
            }

            Spacer(minLength: 28)

            VStack(alignment: .trailing, spacing: 2) {
                if let searchMatchedSubtotal, isShowingSearchAmounts {
                    Text(searchMatchedSubtotal)
                        .font(.subheadline)
                        .fontWeight(.bold)
                        .foregroundStyle(.primary)
                        .lineLimit(1)
                        .contentTransition(.numericText())

                    secondaryAmountLine(searchMatchedUnpaid)
                } else {
                    Text(formattedAmount)
                        .font(.subheadline)
                        .fontWeight(showsZeroAmountStyle ? .semibold : .bold)
                        .foregroundStyle(showsZeroAmountStyle ? Color.secondary : Color.primary)
                        .lineLimit(1)
                        .contentTransition(.numericText())

                    secondaryAmountLine(formattedUnpaidAmount)
                }
            }
            .layoutPriority(1)
            .animation(.spring(response: 0.35, dampingFraction: 0.82), value: formattedAmount)
            .animation(.spring(response: 0.35, dampingFraction: 0.82), value: formattedUnpaidAmount)
            .animation(.spring(response: 0.35, dampingFraction: 0.82), value: searchMatchedSubtotal)
            .animation(.spring(response: 0.35, dampingFraction: 0.82), value: searchMatchedUnpaid)
        }
    }

    @ViewBuilder
    private func secondaryAmountLine(_ value: String?) -> some View {
        Text(value.map { "\($0) \(LocalizationKey.Item.unpaid.localized)" } ?? " ")
            .font(.caption)
            .foregroundStyle(.secondary)
            .lineLimit(1)
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
