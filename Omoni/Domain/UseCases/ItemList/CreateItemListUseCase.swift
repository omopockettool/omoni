import Foundation

protocol CreateItemListUseCase {
    func execute(
        description: String,
        isList: Bool,
        date: Date,
        categoryId: UUID?,
        paymentMethodId: UUID?,
        groupId: UUID?
    ) async throws -> SDItemList
}

final class DefaultCreateItemListUseCase: CreateItemListUseCase {
    private let itemListRepository: ItemListRepository

    init(itemListRepository: ItemListRepository) {
        self.itemListRepository = itemListRepository
    }

    func execute(
        description: String,
        isList: Bool,
        date: Date,
        categoryId: UUID?,
        paymentMethodId: UUID?,
        groupId: UUID?
    ) async throws -> SDItemList {
        return try await itemListRepository.createItemList(
            description: description,
            isList: isList,
            date: date,
            categoryId: categoryId,
            paymentMethodId: paymentMethodId,
            groupId: groupId
        )
    }
}

protocol CreateSingleEntryUseCase {
    func execute(
        description: String,
        amount: Decimal,
        date: Date,
        categoryId: UUID?,
        paymentMethodId: UUID?,
        groupId: UUID?,
        isPaid: Bool
    ) async throws -> SDItemList
}

final class DefaultCreateSingleEntryUseCase: CreateSingleEntryUseCase {
    private let itemListRepository: ItemListRepository
    private let itemRepository: ItemRepository

    init(itemListRepository: ItemListRepository, itemRepository: ItemRepository) {
        self.itemListRepository = itemListRepository
        self.itemRepository = itemRepository
    }

    func execute(
        description: String,
        amount: Decimal,
        date: Date,
        categoryId: UUID?,
        paymentMethodId: UUID?,
        groupId: UUID?,
        isPaid: Bool
    ) async throws -> SDItemList {
        let trimmedDescription = description.trimmingCharacters(in: .whitespacesAndNewlines)
        guard !trimmedDescription.isEmpty else { throw ValidationError.invalidDescription }
        guard amount >= 0 else { throw ValidationError.invalidAmount }

        let itemList = try await itemListRepository.createItemList(
            description: trimmedDescription,
            isList: false,
            date: date,
            categoryId: categoryId,
            paymentMethodId: paymentMethodId,
            groupId: groupId
        )

        _ = try await itemRepository.createItem(
            description: trimmedDescription,
            amount: amount,
            quantity: 1,
            itemListId: itemList.id,
            isPaid: isPaid
        )

        return itemList
    }
}
