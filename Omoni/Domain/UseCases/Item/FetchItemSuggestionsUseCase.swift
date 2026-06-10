import Foundation

protocol FetchItemSuggestionsUseCase {
    func execute(query: String, categoryId: UUID?, groupId: UUID) async -> [ItemSuggestion]
}

final class DefaultFetchItemSuggestionsUseCase: FetchItemSuggestionsUseCase {
    private let itemRepository: ItemRepository

    init(itemRepository: ItemRepository) {
        self.itemRepository = itemRepository
    }

    func execute(query: String, categoryId: UUID?, groupId: UUID) async -> [ItemSuggestion] {
        guard query.count >= 2 else { return [] }

        let allItems: [SDItem]
        if let categoryId {
            allItems = (try? await itemRepository.fetchItems(forCategoryId: categoryId)) ?? []
        } else {
            allItems = (try? await itemRepository.fetchItems(forGroupId: groupId)) ?? []
        }

        let filtered = allItems.filter { item in
            item.itemDescription.range(
                of: query,
                options: [.caseInsensitive, .diacriticInsensitive]
            ) != nil
        }

        // Items arrive sorted by createdAt descending; first element per group = most recent.
        let groups = Dictionary(grouping: filtered) { item in
            item.itemDescription.trimmingCharacters(in: .whitespacesAndNewlines).lowercased()
        }

        let ranked: [(suggestion: ItemSuggestion, frequency: Int)] = groups.compactMap { _, items in
            guard let mostRecent = items.first else { return nil }
            let suggestion = ItemSuggestion(
                id: mostRecent.id,
                description: mostRecent.itemDescription,
                amount: mostRecent.amount
            )
            return (suggestion: suggestion, frequency: items.count)
        }

        return ranked
            .sorted { $0.frequency > $1.frequency }
            .prefix(5)
            .map(\.suggestion)
    }
}
