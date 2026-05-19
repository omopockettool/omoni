import SwiftUI

private struct ItemRowSideTab: View {
    let isPaid: Bool
    let compact: Bool
    let action: () -> Void

    private var tabWidth: CGFloat { compact ? 36 : 40 }

    private var tabColor: Color {
        isPaid ? .green : Color(.systemGray4)
    }

    private var iconName: String {
        isPaid ? "checkmark" : "clock"
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
        .buttonStyle(PressHapticButtonStyle())
        .frame(width: tabWidth)
        .animation(.spring(response: 0.35, dampingFraction: 0.82), value: isPaid)
    }
}

private struct ItemRowCardBorder: View {
    let accentColor: Color
    let compact: Bool

    private var cornerRadius: CGFloat { compact ? 18 : 20 }
    private var borderWidth: CGFloat { compact ? 2.1 : 2.3 }

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

struct ItemListDetailView: View {
    let itemList: SDItemList
    let currencyCode: String
    let group: SDGroup
    let highlightedSearchQuery: String?
    let showsPendingItemsOnly: Bool
    let onItemListUpdated: ((SDItemList) -> Void)?

    @State private var viewModel: ItemListDetailViewModel
    @State private var sheetMode: ItemSheetMode?
    @State private var heroIsSuccess: Bool = false
    @State private var showMetaLabels: Bool = true
    @State private var lastAddedDescription: String = ""

    enum ItemSheetMode: Identifiable {
        case create
        case edit(SDItem)
        case editRegistry

        var id: String {
            switch self {
            case .create:       return "create"
            case .edit(let i):  return "edit-\(i.id)"
            case .editRegistry: return "editRegistry"
            }
        }
    }

    let onPaidStatusChanged: (() -> Void)?

    init(
        itemList: SDItemList,
        currencyCode: String = "EUR",
        group: SDGroup,
        highlightedSearchQuery: String? = nil,
        showsPendingItemsOnly: Bool = false,
        onItemListUpdated: ((SDItemList) -> Void)? = nil,
        onPaidStatusChanged: (() -> Void)? = nil
    ) {
        self.itemList = itemList
        self.currencyCode = currencyCode
        self.group = group
        self.highlightedSearchQuery = highlightedSearchQuery
        self.showsPendingItemsOnly = showsPendingItemsOnly
        self.onItemListUpdated = onItemListUpdated
        self.onPaidStatusChanged = onPaidStatusChanged

        let container = AppDIContainer.shared
        self._viewModel = State(wrappedValue: ItemListDetailViewModel(
            itemList: itemList,
            currencyCode: currencyCode,
            showsPendingItemsOnly: showsPendingItemsOnly,
            fetchItemsUseCase: container.makeFetchItemsUseCase(),
            createItemUseCase: container.makeCreateItemUseCase(),
            updateItemUseCase: container.makeUpdateItemUseCase(),
            deleteItemUseCase: container.makeDeleteItemUseCase(),
            toggleItemPaidUseCase: container.makeToggleItemPaidUseCase()
        ))
    }

    var body: some View {
        VStack(spacing: 0) {
            if viewModel.isLoading {
                ProgressView(LocalizationKey.Item.loading.localized)
                    .frame(maxWidth: .infinity, maxHeight: .infinity)
            } else if let errorMessage = viewModel.errorMessage {
                errorView(errorMessage)
            } else {
                mainContentView
            }
        }
        .navigationTitle(itemList.itemListDescription)
        .navigationBarTitleDisplayMode(.inline)
        .toolbar {
            ToolbarItem(placement: .topBarTrailing) {
                Menu {
                    Button(LocalizationKey.Entry.edit.localized, systemImage: "pencil") {
                        sheetMode = .editRegistry
                    }
                } label: {
                    Image(systemName: "ellipsis")
                }
            }
        }
        .task {
            await viewModel.loadItems()
        }
        .task {
            try? await Task.sleep(for: .seconds(3))
            withAnimation(.easeInOut(duration: 0.5)) { showMetaLabels = false }
        }
        .sheet(item: $sheetMode) { mode in
            let container = AppDIContainer.shared
            switch mode {
            case .create:
                AddItemView(
                    itemListId: itemList.id,
                    itemToEdit: nil,
                    itemListDescription: itemList.itemListDescription,
                    currencyCode: currencyCode,
                    onItemSaved: { item in
                        Task { await viewModel.addItem(item) }
                        lastAddedDescription = item.itemDescription
                        withAnimation(AnimationHelper.smoothSpring) { heroIsSuccess = true }
                        Task {
                            try? await Task.sleep(for: .milliseconds(900))
                            withAnimation(AnimationHelper.smoothSpring) { heroIsSuccess = false }
                        }
                    },
                    createItemUseCase: container.makeCreateItemUseCase(),
                    updateItemUseCase: container.makeUpdateItemUseCase()
                )
            case .edit(let item):
                AddItemView(
                    itemListId: itemList.id,
                    itemToEdit: item,
                    itemListDescription: itemList.itemListDescription,
                    currencyCode: currencyCode,
                    onItemSaved: { item in Task { await viewModel.updateItem(item) } },
                    createItemUseCase: container.makeCreateItemUseCase(),
                    updateItemUseCase: container.makeUpdateItemUseCase()
                )
            case .editRegistry:
                NavigationStack {
                    AddItemListView(
                        group: group,
                        availableGroups: [group],
                        itemListToEdit: itemList,
                        onItemListCreated: { _ in },
                        onItemListUpdated: { updated in
                            onItemListUpdated?(updated)
                            sheetMode = nil
                        },
                        onCancel: { sheetMode = nil }
                    )
                }
            }
        }
    }

    // MARK: - Main Content

    private var mainContentView: some View {
        ZStack {
            Color(.systemGroupedBackground)
                .ignoresSafeArea()

            RoundedRectangle(cornerRadius: 24, style: .continuous)
                .fill(Color(.secondarySystemBackground))
                .overlay {
                    itemsList
                        .safeAreaInset(edge: .top, spacing: 0) {
                            Color.clear.frame(height: 4)
                        }
                        .safeAreaInset(edge: .bottom, spacing: 0) {
                            Color.clear.frame(height: 2)
                        }
                }
                .clipShape(RoundedRectangle(cornerRadius: 24, style: .continuous))
                .padding(.horizontal, AppConstants.UserInterface.padding)
                .padding(.top, 4)
                .padding(.bottom, 2)
        }
        .frame(maxWidth: .infinity, maxHeight: .infinity, alignment: .top)
        .safeAreaInset(edge: .bottom, spacing: 0) {
            heroCardInset
        }
    }

    // MARK: - Hero Card

    private var heroCard: some View {
        ItemListDetailHeroCard(
            itemList: itemList,
            heroIsSuccess: heroIsSuccess,
            lastAddedDescription: lastAddedDescription,
            totalAmount: viewModel.getFormattedTotal(),
            heroStatus: viewModel.getHeroStatus(),
            showMetaLabels: showMetaLabels,
            onAddExpense: { sheetMode = .create }
        )
    }

    // MARK: - Items List (scrollable)

    private var itemsList: some View {
        ItemListItemsSection(
            items: viewModel.visibleItems,
            currencyCode: currencyCode,
            formattedAmount: viewModel.getFormattedAmount,
            isSearchMatch: { item in
                viewModel.itemMatchesSearch(item, query: highlightedSearchQuery)
            },
            onItemTap: { sheetMode = .edit($0) },
            onTogglePaid: { item in
                Task {
                    await viewModel.toggleItemPaid(item)
                    onPaidStatusChanged?()
                }
            },
            onDelete: { viewModel.deleteItem($0) },
            onRefresh: { await viewModel.loadItems() }
        )
    }

    private var heroCardInset: some View {
        heroCard
            .padding(.horizontal, AppConstants.UserInterface.padding)
            .padding(.vertical, 12)
            .background(Color(.systemGroupedBackground).ignoresSafeArea(edges: .bottom))
    }

    private func errorView(_ message: String) -> some View {
        ItemListErrorState(message: message) {
            Task { await viewModel.loadItems() }
        }
    }
}

// MARK: - Item Row View

struct ItemRowView: View {
    let item: SDItem
    let formattedAmount: String
    let currencyCode: String
    let isSearchMatch: Bool
    let onTap: () -> Void
    let onTogglePaid: () -> Void

    private var showsBreakdown: Bool { item.quantity > 1 }
    private var showsZeroAmountStyle: Bool { abs(item.totalAmount) < 0.000_001 }
    private var minimumRowHeight: CGFloat { showsBreakdown ? 80 : 72 }
    private var contentPadding: CGFloat { 16 }
    private var shellVerticalPadding: CGFloat { showsBreakdown ? 12 : 11 }
    private var cardCornerRadius: CGFloat { 20 }
    private var rowAccentColor: Color {
        item.isPaid ? .green : Color(.systemGray2)
    }
    private var formattedUnitPrice: String {
        let formatter = NumberFormatter()
        formatter.numberStyle = .currency
        formatter.currencyCode = currencyCode
        formatter.locale = Locale(identifier: "es_ES")
        return formatter.string(from: NSNumber(value: item.amount)) ?? "\(item.amount)"
    }

    var body: some View {
        ZStack {
            RoundedRectangle(cornerRadius: cardCornerRadius, style: .continuous)
                .fill(Color(.secondarySystemBackground))

            HStack(spacing: 0) {
                ItemRowSideTab(
                    isPaid: item.isPaid,
                    compact: false,
                    action: onTogglePaid
                )
                .frame(maxHeight: .infinity)

                HStack(alignment: .center, spacing: 12) {
                    VStack(alignment: .leading, spacing: 0) {
                        HStack(spacing: 6) {
                            Text(item.itemDescription)
                                .font(.subheadline)
                                .fontWeight(.semibold)
                                .lineLimit(1)
                                .layoutPriority(1)

                            if isSearchMatch {
                                Image(systemName: "magnifyingglass.circle.fill")
                                    .font(.caption)
                                    .foregroundStyle(.tint)
                            }
                        }

                        if showsBreakdown {
                            Text("\(formattedUnitPrice) × \(item.quantity) \(LocalizationKey.Item.units.localized)")
                                .font(.caption)
                                .foregroundStyle(.secondary)
                                .padding(.top, 2)
                        }
                    }

                    Spacer(minLength: 20)

                    Text(formattedAmount)
                        .font(.subheadline)
                        .fontWeight(showsZeroAmountStyle ? .semibold : .bold)
                        .foregroundStyle(showsZeroAmountStyle ? Color.secondary : Color.primary)
                        .lineLimit(1)
                        .frame(minWidth: 72, alignment: .trailing)
                        .layoutPriority(1)
                }
                .padding(.horizontal, contentPadding)
                .padding(.vertical, shellVerticalPadding)
            }
            .clipShape(RoundedRectangle(cornerRadius: cardCornerRadius, style: .continuous))

            ItemRowCardBorder(accentColor: rowAccentColor, compact: false)
        }
        .frame(maxWidth: .infinity, minHeight: minimumRowHeight)
        .shadow(color: Color.black.opacity(0.03), radius: 8, y: 2)
        .padding(.trailing, 2)
        .contentShape(Rectangle())
        .onTapGesture { onTap() }
    }
}

// MARK: - Preview
#Preview {
    let itemList = SDItemList.mock(itemListDescription: "Compras del supermercado")
    let group = SDGroup.mock(name: "Casa", currency: "EUR")
    return NavigationStack {
        ItemListDetailView(itemList: itemList, currencyCode: "EUR", group: group)
    }
}
