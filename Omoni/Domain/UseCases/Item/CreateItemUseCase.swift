import Foundation

protocol CreateItemUseCase {
    func execute(
        description: String,
        amount: Decimal,
        quantity: Int,
        itemListId: UUID?,
        isPaid: Bool
    ) async throws -> SDItem
}

final class DefaultCreateItemUseCase: CreateItemUseCase {
    private let itemRepository: ItemRepository

    init(itemRepository: ItemRepository) {
        self.itemRepository = itemRepository
    }

    func execute(
        description: String,
        amount: Decimal,
        quantity: Int,
        itemListId: UUID?,
        isPaid: Bool = false
    ) async throws -> SDItem {
        let trimmedDescription = description.trimmingCharacters(in: .whitespacesAndNewlines)
        guard !trimmedDescription.isEmpty else { throw ValidationError.invalidDescription }
        guard amount >= 0 else { throw ValidationError.invalidAmount }
        guard ValidationHelper.isValidItemQuantity(quantity) else { throw ValidationError.invalidQuantity }
        return try await itemRepository.createItem(
            description: trimmedDescription,
            amount: amount,
            quantity: quantity,
            itemListId: itemListId,
            isPaid: isPaid
        )
    }
}
