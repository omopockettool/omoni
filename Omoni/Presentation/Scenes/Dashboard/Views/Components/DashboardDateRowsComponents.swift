import SwiftUI

// MARK: - Date Rows List (intermediate level: category → day → expense rows)

struct DashboardDateRowsView: View {
    let rows: [DashboardDayBoxData]
    let getFormattedAmount: (DashboardDayBoxData) -> String
    let getFormattedUnpaidAmount: (DashboardDayBoxData) -> String?
    let onSelect: (DashboardDayBoxData) -> Void
    let onRefresh: () async -> Void

    var body: some View {
        List {
            ForEach(rows) { row in
                DashboardDateRowView(
                    data: row,
                    formattedAmount: getFormattedAmount(row),
                    formattedUnpaidAmount: getFormattedUnpaidAmount(row),
                    onTap: { onSelect(row) }
                )
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
    }
}

// MARK: - Single Date Row

struct DashboardDateRowView: View {
    let data: DashboardDayBoxData
    let formattedAmount: String
    let formattedUnpaidAmount: String?
    let onTap: () -> Void

    private var isToday: Bool { data.isToday }

    var body: some View {
        Button(action: onTap) {
            HStack(alignment: .center, spacing: 0) {
                // Left: day number + weekday label
                HStack(alignment: .firstTextBaseline, spacing: 7) {
                    if isToday {
                        Text(LocalizationKey.Dashboard.today.localized.uppercased())
                            .font(.system(size: 13, weight: .semibold))
                            .foregroundStyle(Color.accentColor)
                            .tracking(1.5)
                    } else {
                        Text(dayNumber)
                            .font(.system(size: 26, weight: .light, design: .default))
                            .foregroundStyle(Color.primary.opacity(0.88))
                            .monospacedDigit()

                        Text(weekday)
                            .font(.system(size: 10, weight: .medium))
                            .foregroundStyle(Color.secondary)
                            .tracking(1.2)
                            .textCase(.uppercase)
                            .offset(y: -1)
                    }
                }
                .frame(minWidth: 64, alignment: .leading)

                Spacer()

                // Right: amounts + nav chevron
                HStack(alignment: .center, spacing: 10) {
                    VStack(alignment: .trailing, spacing: 2) {
                        Text(formattedAmount)
                            .font(.system(size: 16, weight: isToday ? .medium : .light))
                            .foregroundStyle(isToday ? Color.accentColor : Color.primary.opacity(0.75))
                            .monospacedDigit()

                        if let unpaid = formattedUnpaidAmount {
                            Text("\(unpaid) \(LocalizationKey.Item.unpaid.localized)")
                                .font(.system(size: 11, weight: .regular))
                                .foregroundStyle(.orange.opacity(0.85))
                                .transition(.opacity.combined(with: .move(edge: .top)))
                        }
                    }
                    .animation(AnimationHelper.quickEase, value: formattedUnpaidAmount)

                    Image(systemName: "chevron.right")
                        .font(.system(size: 10, weight: .medium))
                        .foregroundStyle(Color(.tertiaryLabel))
                }
            }
            .padding(.vertical, 20)
            .overlay(alignment: .bottom) {
                Rectangle()
                    .fill(Color(.separator).opacity(0.5))
                    .frame(height: 1)
            }
            .contentShape(Rectangle())
        }
        .buttonStyle(PressHapticButtonStyle())
    }

    private var dayNumber: String {
        String(Calendar.current.component(.day, from: data.date))
    }

    private var weekday: String {
        let f = DateFormatter()
        f.dateFormat = "EEE"
        return f.string(from: data.date)
    }
}
