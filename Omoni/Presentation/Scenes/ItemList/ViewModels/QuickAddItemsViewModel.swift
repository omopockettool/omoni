import Foundation

@MainActor
@Observable
final class QuickAddItemsViewModel {

    // MARK: - State
    var frequentItems: [ItemSuggestion] = []
    var addedItemIds: Set<UUID> = []
    var isLoading = false

    // MARK: - Dependencies
    private let itemListId: UUID
    private let groupId: UUID
    private let categoryId: UUID?
    private let fetchFrequentItemsUseCase: FetchFrequentItemsUseCase
    private let createItemUseCase: CreateItemUseCase

    // MARK: - Init
    init(
        itemListId: UUID,
        groupId: UUID,
        categoryId: UUID?,
        fetchFrequentItemsUseCase: FetchFrequentItemsUseCase,
        createItemUseCase: CreateItemUseCase
    ) {
        self.itemListId = itemListId
        self.groupId = groupId
        self.categoryId = categoryId
        self.fetchFrequentItemsUseCase = fetchFrequentItemsUseCase
        self.createItemUseCase = createItemUseCase
    }

    // MARK: - Public

    func loadFrequentItems() async {
        isLoading = true
        frequentItems = await fetchFrequentItemsUseCase.execute(
            categoryId: categoryId,
            groupId: groupId,
            limit: 10
        )
        isLoading = false
    }

    func quickAdd(_ suggestion: ItemSuggestion) async -> SDItem? {
        guard !isAdded(suggestion) else { return nil }
        do {
            let item = try await createItemUseCase.execute(
                description: suggestion.description,
                amount: Decimal(suggestion.amount),
                quantity: 1,
                itemListId: itemListId,
                isPaid: false
            )
            addedItemIds.insert(suggestion.id)
            return item
        } catch {
            return nil
        }
    }

    func isAdded(_ suggestion: ItemSuggestion) -> Bool {
        addedItemIds.contains(suggestion.id)
    }
}
