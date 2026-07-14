import SwiftUI

struct ItemListDetailHeroCard: View {
    let itemList: SDItemList
    let totalAmount: String
    let heroStatus: ItemListDetailHeroStatus
    let showMetaLabels: Bool
    let onAddExpense: () -> Void

    private var actionColor: Color {
        guard let colorHex = itemList.category?.color else { return .accentColor }
        return Color(hex: colorHex) ?? .accentColor
    }

    var body: some View {
        TotalSpentCardView(
            label: LocalizationKey.Item.costOf.localized(with: itemList.itemListDescription),
            totalAmount: totalAmount,
            onAddExpense: onAddExpense,
            actionColor: actionColor
        ) {
            ItemListDetailMetaRow(
                itemList: itemList,
                heroStatus: heroStatus,
                showMetaLabels: showMetaLabels
            )
        }
    }
}

struct ItemListDetailMetaRow: View {
    let itemList: SDItemList
    let heroStatus: ItemListDetailHeroStatus
    let showMetaLabels: Bool

    var body: some View {
        HStack(spacing: 10) {
            if let category = itemList.category {
                let color = Color(hex: category.color) ?? .accentColor
                HStack(spacing: 4) {
                    Image(systemName: category.icon)
                        .foregroundStyle(color)
                    if showMetaLabels {
                        Text(category.name)
                            .foregroundStyle(color)
                            .lineLimit(1)
                            .truncationMode(.tail)
                            .transition(.opacity.combined(with: .scale(scale: 0.85, anchor: .leading)))
                    }
                }
                .font(.caption)
                .fontWeight(.medium)
            }

            if let paymentMethod = itemList.paymentMethod {
                let color = PaymentMethodAppearance.tint(for: paymentMethod)
                HStack(spacing: 4) {
                    Image(systemName: PaymentMethodAppearance.icon(for: paymentMethod))
                        .foregroundStyle(color)
                    if showMetaLabels {
                        Text(paymentMethod.name)
                            .foregroundStyle(color)
                            .lineLimit(1)
                            .truncationMode(.tail)
                            .transition(.opacity.combined(with: .scale(scale: 0.85, anchor: .leading)))
                    }
                }
                .font(.caption)
                .fontWeight(.medium)
            }

            statusBadge
                .font(.caption)
                .animation(.spring(response: 0.45, dampingFraction: 0.8), value: heroStatusKey)
        }
        .padding(.top, 2)
    }

    @ViewBuilder
    private var statusBadge: some View {
        switch heroStatus {
        case .unpaid(let unpaidTotal):
            HStack(spacing: 4) {
                Image(systemName: "circle")
                if !showMetaLabels && !unpaidTotal.isEmpty {
                    Text(unpaidTotal)
                        .fontWeight(.medium)
                        .transition(.opacity.combined(with: .scale(scale: 0.85, anchor: .leading)))
                }
            }
            .foregroundStyle(.orange)
        case .partial(let unpaidTotal):
            HStack(spacing: 4) {
                Image(systemName: "circle.lefthalf.filled")
                if !showMetaLabels && !unpaidTotal.isEmpty {
                    Text(unpaidTotal)
                        .fontWeight(.medium)
                        .transition(.opacity.combined(with: .scale(scale: 0.85, anchor: .leading)))
                }
            }
            .foregroundStyle(.orange)
        case .completed:
            Image(systemName: "checkmark.circle.fill")
                .foregroundStyle(Color.paidGreen)
        case .neutral:
            EmptyView()
        }
    }

    private var heroStatusKey: String {
        switch heroStatus {
        case .neutral:
            return "neutral"
        case .unpaid:
            return "unpaid"
        case .partial:
            return "partial"
        case .completed:
            return "completed"
        }
    }
}

struct ItemListItemsSection: View {
    let items: [SDItem]
    let formattedAmount: (SDItem) -> String
    let quantityBreakdown: (SDItem) -> String?
    let highlightedQuery: (SDItem) -> String?
    let onItemTap: (SDItem) -> Void
    let onTogglePaid: (SDItem) -> Void
    let onDelete: (SDItem) -> Void
    let onRefresh: () async -> Void

    var body: some View {
        List {
            if items.isEmpty {
                ItemListEmptyStateRow()
                    .listRowBackground(Color.clear)
                    .listRowSeparator(.hidden)
            } else {
                ForEach(items, id: \.id) { item in
                    ItemRowView(
                        item: item,
                        formattedAmount: formattedAmount(item),
                        quantityBreakdown: quantityBreakdown(item),
                        highlightedQuery: highlightedQuery(item),
                        onTap: { onItemTap(item) },
                        onTogglePaid: { onTogglePaid(item) }
                    )
                    .listRowInsets(EdgeInsets(top: 0, leading: 20, bottom: 0, trailing: 20))
                    .listRowSeparator(.hidden)
                    .listRowBackground(Color.clear)
                }
                .onDelete { indexSet in
                    indexSet.forEach { onDelete(items[$0]) }
                }
            }
        }
        .listStyle(.plain)
        .scrollContentBackground(.hidden)
        .scrollIndicators(.hidden)
        .contentMargins(.top, ExpenseListLayoutMetrics.topContentMargin, for: .scrollContent)
        .refreshable {
            await onRefresh()
            try? await Task.sleep(for: .milliseconds(420))
        }
        .frame(maxWidth: .infinity, maxHeight: .infinity, alignment: .top)
    }
}

struct ItemListEmptyStateRow: View {
    var body: some View {
        EmptyStateView(message: LocalizationKey.Item.tapToAdd.localized)
    }
}

struct ItemListErrorState: View {
    let message: String
    let onRetry: () -> Void

    var body: some View {
        VStack(spacing: AppConstants.UserInterface.padding) {
            Image(systemName: "exclamationmark.triangle")
                .font(.largeTitle)
                .foregroundColor(.orange)
            Text(LocalizationKey.General.error.localized)
                .font(.title2)
                .fontWeight(.semibold)
            Text(message)
                .font(.body)
                .foregroundColor(.secondary)
                .multilineTextAlignment(.center)
            Button(LocalizationKey.General.retry.localized, action: onRetry)
                .buttonStyle(.borderedProminent)
        }
        .padding(AppConstants.UserInterface.largePadding)
        .frame(maxWidth: .infinity, maxHeight: .infinity)
    }
}
