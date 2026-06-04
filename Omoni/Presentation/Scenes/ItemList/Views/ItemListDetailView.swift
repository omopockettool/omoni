import SwiftUI

struct ItemListDetailView: View {
    let itemList: SDItemList
    let currencyCode: String
    let group: SDGroup
    let highlightedSearchQuery: String?
    let showsPendingItemsOnly: Bool
    let onItemListUpdated: ((SDItemList) -> Void)?

    @Environment(\.dismiss) private var dismiss
    @State private var viewModel: ItemListDetailViewModel
    @State private var sheetMode: ItemSheetMode?
    @State private var showMetaLabels: Bool = true

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
                            if updated.isSingleEntry {
                                Task { dismiss() }
                            }
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
            formattedAmount: viewModel.getFormattedAmount,
            quantityBreakdown: viewModel.getQuantityBreakdown,
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
    let quantityBreakdown: String?
    let isSearchMatch: Bool
    let onTap: () -> Void
    let onTogglePaid: () -> Void

    private var rowTone: StatusFramedRowTone {
        item.isPaid ? .completed : .neutral
    }

    private var statusIconName: String {
        item.isPaid ? "checkmark" : "circle"
    }

    private var statusIconColor: Color? {
        item.isPaid ? nil : Color(.systemGray2)
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
                VStack(alignment: .leading, spacing: 1) {
                    Text(item.itemDescription)
                        .font(.system(size: 15, weight: isSearchMatch ? .semibold : .medium))
                        .foregroundStyle(Color.primary.opacity(0.92))
                        .lineLimit(1)
                    if let breakdown = quantityBreakdown {
                        Text(breakdown)
                            .font(.system(size: 12, weight: .regular, design: .rounded))
                            .foregroundStyle(Color.secondary)
                            .monospacedDigit()
                            .lineLimit(1)
                    }
                }
                .frame(maxWidth: .infinity, alignment: .leading)

                Text(formattedAmount)
                    .font(.system(size: 15, weight: .semibold, design: .rounded))
                    .foregroundStyle(rowTone.amountColor)
                    .monospacedDigit()
                    .lineLimit(1)
                    .contentTransition(.numericText())
            }
        }
        .padding(.vertical, 6)
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
