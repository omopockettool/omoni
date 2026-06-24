import Foundation

protocol FetchFrequentItemsUseCase {
    func execute(categoryId: UUID?, groupId: UUID, limit: Int) async -> [ItemSuggestion]
}

final class DefaultFetchFrequentItemsUseCase: FetchFrequentItemsUseCase {
    private let itemRepository: ItemRepository

    init(itemRepository: ItemRepository) {
        self.itemRepository = itemRepository
    }

    func execute(categoryId: UUID?, groupId: UUID, limit: Int = 10) async -> [ItemSuggestion] {
        let allItems: [SDItem]
        if let categoryId {
            allItems = (try? await itemRepository.fetchItems(forCategoryId: categoryId)) ?? []
        } else {
            allItems = (try? await itemRepository.fetchItems(forGroupId: groupId)) ?? []
        }

        guard !allItems.isEmpty else { return [] }

        // Items arrive sorted by createdAt descending; first per group = most recent price.
        let groups = Dictionary(grouping: allItems) { item in
            item.itemDescription.trimmingCharacters(in: .whitespacesAndNewlines).lowercased()
        }

        return groups
            .compactMap { _, items -> (suggestion: ItemSuggestion, score: Double)? in
                guard let mostRecent = items.first else { return nil }
                let daysSince = Date().timeIntervalSince(mostRecent.createdAt) / 86_400
                let score = Double(items.count) / (daysSince + 1)
                return (
                    suggestion: ItemSuggestion(
                        id: mostRecent.id,
                        description: mostRecent.itemDescription,
                        amount: mostRecent.amount
                    ),
                    score: score
                )
            }
            .sorted { $0.score > $1.score }
            .prefix(limit)
            .map(\.suggestion)
    }
}
