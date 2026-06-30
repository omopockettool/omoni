import SwiftUI

// MARK: - Date Rows List (intermediate level: category → day → expense rows)

struct DashboardDateRowsView: View {
    let rows: [DashboardDayBoxData]
    let getFormattedAmount: (DashboardDayBoxData) -> String
    let getFormattedUnpaidAmount: (DashboardDayBoxData) -> String?
    let restorationRowID: String?
    let onSelect: (DashboardDayBoxData) -> Void
    let onRefresh: () async -> Void

    var body: some View {
        ScrollViewReader { proxy in
            List {
                ForEach(rows) { row in
                    DashboardDateRowView(
                        data: row,
                        formattedAmount: getFormattedAmount(row),
                        formattedUnpaidAmount: getFormattedUnpaidAmount(row),
                        onTap: { onSelect(row) }
                    )
                    .id(row.id)
                    .padding(.vertical, 4)
                    .listRowInsets(EdgeInsets(top: 0, leading: 20, bottom: 0, trailing: 20))
                    .listRowBackground(Color.clear)
                    .listRowSeparator(.hidden)
                }
            }
            .listStyle(.plain)
            .scrollContentBackground(.hidden)
            .scrollIndicators(.hidden)
            .contentMargins(.top, ExpenseListLayoutMetrics.topContentMargin, for: .scrollContent)
            .refreshable {
                await onRefresh()
                try? await Task.sleep(for: .milliseconds(180))
            }
            .frame(maxWidth: .infinity, maxHeight: .infinity, alignment: .top)
            .onAppear {
                restoreScrollPosition(using: proxy)
            }
            .onChange(of: restorationRowID) { _, _ in
                restoreScrollPosition(using: proxy)
            }
            .onChange(of: rows.map(\.id)) { _, _ in
                restoreScrollPosition(using: proxy)
            }
        }
    }

    private func restoreScrollPosition(using proxy: ScrollViewProxy) {
        guard let restorationRowID,
              rows.contains(where: { $0.id == restorationRowID })
        else { return }

        Task { @MainActor in
            await Task.yield()
            withAnimation(nil) {
                proxy.scrollTo(restorationRowID, anchor: .center)
            }
        }
    }
}

// MARK: - Single Date Row

private enum DashboardDateRowLayoutMetrics {
    static let cardCornerRadius: CGFloat = AppConstants.UserInterface.rowCornerRadius
    static let leadingColumnWidth: CGFloat = 66
    static let amountColumnHeight: CGFloat = 38
    static let borderLineWidth: CGFloat = 4
}

private enum DashboardDateRowTone {
    case neutral
    case pending
    case today

    private var baseColor: Color {
        switch self {
        case .neutral:
            return Color(.systemGray3)
        case .pending:
            return .orange
        case .today:
            return .accentColor
        }
    }

    var leadingFill: Color {
        switch self {
        case .neutral:
            return baseColor.opacity(0.22)
        case .pending:
            return baseColor.opacity(0.24)
        case .today:
            return baseColor.opacity(0.22)
        }
    }

    var borderColor: Color {
        switch self {
        case .neutral:
            return baseColor
        case .pending:
            return baseColor.opacity(0.82)
        case .today:
            return baseColor.opacity(0.82)
        }
    }

    var amountColor: Color {
        switch self {
        case .neutral:
            return Color.primary.opacity(0.76)
        case .pending:
            return .primary
        case .today:
            return .accentColor
        }
    }

    var titleColor: Color {
        switch self {
        case .neutral, .pending:
            return Color.primary.opacity(0.92)
        case .today:
            return .accentColor
        }
    }

    var secondaryColor: Color {
        switch self {
        case .neutral:
            return .secondary
        case .pending:
            return .orange.opacity(0.85)
        case .today:
            return .accentColor.opacity(0.82)
        }
    }
}

struct DashboardDateRowView: View {
    @State private var displayedPrimaryAmount = ""
    @State private var primaryAmountIsDecreasing = false

    let data: DashboardDayBoxData
    let formattedAmount: String
    let formattedUnpaidAmount: String?
    let onTap: () -> Void

    private var isToday: Bool { data.isToday }

    private var rowTone: DashboardDateRowTone {
        if isToday {
            return .today
        }
        if formattedUnpaidAmount != nil {
            return .pending
        }
        return .neutral
    }

    private var primaryAmountText: String {
        formattedAmount
    }

    private var showsSecondaryAmount: Bool {
        formattedUnpaidAmount != nil
    }

    var body: some View {
        Button(action: onTap) {
            HStack(spacing: 0) {
                leadingDateColumn

                HStack(alignment: .center, spacing: 12) {
                    contentColumn
                    trailingAmountColumn
                }
                .padding(.horizontal, 15)
                .padding(.vertical, 15)
                .frame(maxWidth: .infinity, alignment: .leading)
            }
            .background(cardBackground)
            .clipShape(cardShape)
            .overlay {
                cardShape
                    .stroke(rowTone.borderColor, lineWidth: DashboardDateRowLayoutMetrics.borderLineWidth)
            }
            .contentShape(cardShape)
        }
        .buttonStyle(PressHapticButtonStyle())
        .onAppear {
            displayedPrimaryAmount = primaryAmountText
        }
        .onChange(of: primaryAmountText) { oldValue, newValue in
            let oldDigits = extractDigits(from: oldValue)
            let newDigits = extractDigits(from: newValue)
            primaryAmountIsDecreasing = newDigits < oldDigits
            withAnimation(.spring(response: 0.45, dampingFraction: 0.78, blendDuration: 0.15)) {
                displayedPrimaryAmount = newValue
            }
        }
        .animation(AnimationHelper.quickEase, value: formattedUnpaidAmount)
    }

    private var leadingDateColumn: some View {
        ZStack {
            Rectangle()
                .fill(rowTone.leadingFill)

            Text(dayNumber)
                .font(.system(size: 22, weight: .bold, design: .rounded))
                .foregroundStyle(rowTone.titleColor)
                .monospacedDigit()
                .padding(.vertical, 14)
        }
        .frame(width: DashboardDateRowLayoutMetrics.leadingColumnWidth)
        .frame(maxHeight: .infinity)
    }

    private var contentColumn: some View {
        VStack(alignment: .leading, spacing: 4) {
            Text(primaryTitleLabel)
                .font(.system(size: 15, weight: .medium))
                .foregroundStyle(rowTone.titleColor)
                .lineLimit(1)

            if let secondaryTitleLabel {
                Text(secondaryTitleLabel)
                    .font(.caption.weight(.medium))
                    .foregroundStyle(rowTone.secondaryColor)
                    .lineLimit(1)
            }
        }
        .frame(maxWidth: .infinity, alignment: .leading)
    }

    @ViewBuilder
    private var trailingAmountColumn: some View {
        ZStack(alignment: .trailing) {
            primaryAmountView
                .frame(height: DashboardDateRowLayoutMetrics.amountColumnHeight, alignment: .trailing)
                .offset(y: showsSecondaryAmount ? -7 : 0)

            secondaryAmountView
                .frame(height: DashboardDateRowLayoutMetrics.amountColumnHeight, alignment: .bottomTrailing)
                .opacity(showsSecondaryAmount ? 1 : 0)
                .offset(y: showsSecondaryAmount ? 0 : -10)
        }
        .fixedSize(horizontal: true, vertical: false)
        .frame(height: DashboardDateRowLayoutMetrics.amountColumnHeight, alignment: .topTrailing)
    }

    private var primaryAmountView: some View {
        Text(displayedPrimaryAmount)
            .font(.system(size: 15, weight: .semibold, design: .rounded))
            .foregroundStyle(rowTone.amountColor)
            .monospacedDigit()
            .lineLimit(1)
            .contentTransition(.numericText(countsDown: primaryAmountIsDecreasing))
    }

    @ViewBuilder
    private var secondaryAmountView: some View {
        if let formattedUnpaidAmount {
            Text(formattedUnpaidAmount)
                .font(.caption)
                .foregroundStyle(.orange)
                .monospacedDigit()
                .lineLimit(1)
        } else {
            Text("")
                .font(.caption)
        }
    }

    private var cardBackground: some View {
        RoundedRectangle(cornerRadius: DashboardDateRowLayoutMetrics.cardCornerRadius, style: .continuous)
            .fill(Color(.secondarySystemGroupedBackground))
    }

    private var cardShape: RoundedRectangle {
        RoundedRectangle(cornerRadius: DashboardDateRowLayoutMetrics.cardCornerRadius, style: .continuous)
    }

    private var primaryTitleLabel: String {
        isToday ? LocalizationKey.Dashboard.today.localized : weekday
    }

    private var secondaryTitleLabel: String? {
        isToday ? weekday : nil
    }

    private var weekday: String {
        let formatter = DateFormatter()
        formatter.locale = .autoupdatingCurrent
        formatter.dateFormat = "EEEE"
        let value = formatter.string(from: data.date)
        return value.prefix(1).uppercased() + value.dropFirst()
    }

    private func extractDigits(from string: String) -> Int {
        Int(string.filter(\.isNumber)) ?? 0
    }

    private var dayNumber: String {
        String(Calendar.current.component(.day, from: data.date))
    }
}
