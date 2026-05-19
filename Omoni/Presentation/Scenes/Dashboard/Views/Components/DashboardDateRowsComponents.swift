import SwiftUI

// MARK: - Date Rows List (intermediate level: category → day → expense rows)

struct DashboardDateRowsView: View {
    let rows: [DashboardDayBoxData]
    let getFormattedAmount: (DashboardDayBoxData) -> String
    let onSelect: (DashboardDayBoxData) -> Void
    let onRefresh: () async -> Void

    var body: some View {
        List {
            ForEach(rows) { row in
                DashboardDateRowView(
                    data: row,
                    formattedAmount: getFormattedAmount(row),
                    onTap: { onSelect(row) }
                )
                .listRowInsets(EdgeInsets(top: 8, leading: 18, bottom: 8, trailing: 18))
                .listRowBackground(Color.clear)
                .listRowSeparator(.hidden)
            }
        }
        .listStyle(.plain)
        .scrollContentBackground(.hidden)
        .scrollIndicators(.hidden)
        .contentMargins(.top, 10, for: .scrollContent)
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
    let onTap: () -> Void

    private var accentColor: Color {
        data.isToday ? .accentColor : Color(.systemGray2)
    }

    private var cardFillColor: Color {
        data.isToday ? Color.accentColor.opacity(0.08) : Color(.secondarySystemBackground)
    }

    private var cardBorderColor: Color {
        data.isToday ? Color.accentColor.opacity(0.24) : Color(.systemGray5)
    }

    private var dateLabel: String {
        if data.isToday { return LocalizationKey.Dashboard.today.localized.capitalized }
        return DateFormatterHelper.formatSectionDate(data.date)
    }

    var body: some View {
        Button(action: onTap) {
            HStack(spacing: 0) {
                RoundedRectangle(cornerRadius: 14, style: .continuous)
                    .fill(accentColor.opacity(data.isToday ? 0.18 : 0.12))
                    .frame(width: 8)
                    .padding(.vertical, 10)

                HStack(spacing: 14) {
                    ZStack {
                        Circle()
                            .fill(accentColor.opacity(data.isToday ? 0.16 : 0.1))
                            .frame(width: 42, height: 42)

                        Image(systemName: data.isToday ? "sun.max.fill" : "calendar")
                            .font(.system(size: 15, weight: .semibold))
                            .foregroundStyle(data.isToday ? Color.accentColor : Color.secondary)
                    }

                    VStack(alignment: .leading, spacing: 4) {
                        Text(dateLabel)
                            .font(.subheadline.weight(.semibold))
                            .foregroundStyle(data.isToday ? Color.accentColor : Color.primary)

                        Text(itemCountLabel)
                            .font(.caption.weight(.medium))
                            .foregroundStyle(Color.secondary)
                            .lineLimit(1)
                    }

                    Spacer(minLength: 12)

                    VStack(alignment: .trailing, spacing: 8) {
                        Text(formattedAmount)
                            .font(.subheadline.weight(.bold))
                            .foregroundStyle(Color.primary)
                            .lineLimit(1)
                            .minimumScaleFactor(0.8)

                        HStack(spacing: 6) {
                            Text(drillLabel)
                                .font(.caption2.weight(.semibold))
                                .foregroundStyle(Color.secondary)

                            Image(systemName: "chevron.right")
                                .font(.caption2.weight(.bold))
                                .foregroundStyle(Color(.tertiaryLabel))
                        }
                    }
                }
                .padding(.leading, 12)
                .padding(.trailing, 14)
                .padding(.vertical, 14)
            }
            .background {
                RoundedRectangle(cornerRadius: 20, style: .continuous)
                    .fill(cardFillColor)
            }
            .overlay {
                RoundedRectangle(cornerRadius: 20, style: .continuous)
                    .stroke(cardBorderColor, lineWidth: 1)
            }
            .shadow(color: Color.black.opacity(0.035), radius: 10, y: 3)
            .contentShape(Rectangle())
        }
        .buttonStyle(PressHapticButtonStyle())
        .animation(AnimationHelper.quickEase, value: data.isToday)
    }

    private var itemCountLabel: String {
        if data.itemListCount == 1 {
            return "1 entrada"
        }
        return "\(data.itemListCount) entradas"
    }

    private var drillLabel: String {
        data.itemListCount == 1 ? "Ver gasto" : "Ver gastos"
    }
}
