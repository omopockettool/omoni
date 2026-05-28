import Foundation

protocol UpdateItemListUseCase {
    func execute(_ itemList: SDItemList) async throws
}

final class DefaultUpdateItemListUseCase: UpdateItemListUseCase {
    private let itemListRepository: ItemListRepository

    init(itemListRepository: ItemListRepository) {
        self.itemListRepository = itemListRepository
    }

    func execute(_ itemList: SDItemList) async throws {
        try await itemListRepository.updateItemList(itemList)
    }
}

protocol UpdateSingleEntryUseCase {
    func execute(
        itemList: SDItemList,
        description: String,
        amount: Decimal,
        date: Date,
        category: SDCategory?,
        paymentMethod: SDPaymentMethod?,
        group: SDGroup?
    ) async throws -> SDItemList
}

final class DefaultUpdateSingleEntryUseCase: UpdateSingleEntryUseCase {
    private let itemRepository: ItemRepository
    private let itemListRepository: ItemListRepository

    init(itemRepository: ItemRepository, itemListRepository: ItemListRepository) {
        self.itemRepository = itemRepository
        self.itemListRepository = itemListRepository
    }

    func execute(
        itemList: SDItemList,
        description: String,
        amount: Decimal,
        date: Date,
        category: SDCategory?,
        paymentMethod: SDPaymentMethod?,
        group: SDGroup?
    ) async throws -> SDItemList {
        let trimmedDescription = description.trimmingCharacters(in: .whitespacesAndNewlines)
        guard !trimmedDescription.isEmpty else { throw ValidationError.invalidDescription }
        guard amount > 0 else { throw ValidationError.invalidAmount }

        itemList.itemListDescription = trimmedDescription
        itemList.setStructure(.singleEntry)
        itemList.date = date
        itemList.category = category
        itemList.paymentMethod = paymentMethod
        itemList.group = group

        let item: SDItem
        let needsCreateItem: Bool
        if let existing = itemList.items.first {
            item = existing
            needsCreateItem = false
        } else {
            item = SDItem(
                itemDescription: trimmedDescription,
                amount: Double(truncating: amount as NSDecimalNumber),
                quantity: 1,
                isPaid: false
            )
            needsCreateItem = true
        }

        item.itemDescription = trimmedDescription
        item.amount = Double(truncating: amount as NSDecimalNumber)
        item.quantity = 1

        try await itemListRepository.updateItemList(itemList)
        if needsCreateItem {
            _ = try await itemRepository.createItem(
                description: trimmedDescription,
                amount: amount,
                quantity: 1,
                itemListId: itemList.id,
                isPaid: item.isPaid
            )
        } else {
            try await itemRepository.updateItem(item)
        }
        return itemList
    }
}
