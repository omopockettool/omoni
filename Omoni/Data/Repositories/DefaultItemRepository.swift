import Foundation
import SwiftData

@MainActor
final class DefaultItemRepository: ItemRepository {
    private let context: ModelContext

    init(context: ModelContext) {
        self.context = context
    }

    func fetchItems(forItemListId itemListId: UUID) async throws -> [SDItem] {
        let targetId = itemListId
        let descriptor = FetchDescriptor<SDItem>(
            predicate: #Predicate { $0.itemList?.id == targetId },
            sortBy: [SortDescriptor(\.createdAt, order: .reverse)]
        )
        return try context.fetch(descriptor)
    }

    func createItem(
        description: String,
        amount: Decimal,
        quantity: Int,
        itemListId: UUID?,
        isPaid: Bool
    ) async throws -> SDItem {
        guard let itemListId else { throw ValidationError.invalidItemList }

        let item = SDItem(
            itemDescription: description,
            amount: Double(truncating: amount as NSDecimalNumber),
            quantity: quantity,
            isPaid: isPaid
        )
        let targetId = itemListId
        let descriptor = FetchDescriptor<SDItemList>(predicate: #Predicate { $0.id == targetId })
        guard let itemList = try context.fetch(descriptor).first else {
            throw RepositoryError.notFound
        }
        item.itemList = itemList
        item.itemList?.touch()
        context.insert(item)
        do {
            try context.save()
        } catch {
            context.rollback()
            throw error
        }
        return item
    }

    func updateItem(_ item: SDItem) async throws {
        guard context.hasChanges else { return }
        let modifiedAt = Date()
        item.touch(modifiedAt)
        item.itemList?.touch(modifiedAt)
        do {
            try context.save()
        } catch {
            context.rollback()
            throw error
        }
    }

    func deleteItem(id: UUID) async throws {
        let targetId = id
        let descriptor = FetchDescriptor<SDItem>(predicate: #Predicate { $0.id == targetId })
        guard let item = try context.fetch(descriptor).first else {
            throw RepositoryError.notFound
        }
        item.itemList?.touch()
        context.delete(item)
        do {
            try context.save()
        } catch {
            context.rollback()
            throw error
        }
    }

    func setAllItemsPaid(forItemListId itemListId: UUID, isPaid: Bool) async throws {
        let targetId = itemListId
        let descriptor = FetchDescriptor<SDItem>(predicate: #Predicate { $0.itemList?.id == targetId })
        let items = try context.fetch(descriptor)
        let modifiedAt = Date()
        var didChange = false
        items.forEach {
            let previousStatus = $0.isPaid
            $0.setPaidStatus(isPaid, modifiedAt: modifiedAt)
            if previousStatus != $0.isPaid {
                didChange = true
            }
        }

        if didChange {
            items.first?.itemList?.touch(modifiedAt)
        }

        guard context.hasChanges else {
            return
        }
        do {
            try context.save()
        } catch {
            context.rollback()
            throw error
        }
    }

    func toggleItemPaid(id: UUID, isPaid: Bool) async throws {
        let targetId = id
        let descriptor = FetchDescriptor<SDItem>(predicate: #Predicate { $0.id == targetId })
        guard let item = try context.fetch(descriptor).first else {
            throw RepositoryError.notFound
        }

        if item.isPaid != isPaid {
            let modifiedAt = Date()
            item.setPaidStatus(isPaid, modifiedAt: modifiedAt)
            item.itemList?.touch(modifiedAt)
        }

        guard context.hasChanges else { return }
        do {
            try context.save()
        } catch {
            context.rollback()
            throw error
        }
    }
}
