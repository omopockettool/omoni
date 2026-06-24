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

    func fetchItems(forCategoryId categoryId: UUID) async throws -> [SDItem] {
        let targetId = categoryId
        let listDescriptor = FetchDescriptor<SDItemList>(
            predicate: #Predicate { $0.category?.id == targetId }
        )
        let itemLists = try context.fetch(listDescriptor)
        let itemListIds = Set(itemLists.map(\.id))
        guard !itemListIds.isEmpty else { return [] }

        let itemDescriptor = FetchDescriptor<SDItem>(
            sortBy: [SortDescriptor(\.createdAt, order: .reverse)]
        )
        let allItems = try context.fetch(itemDescriptor)
        return allItems.filter { item in
            guard let listId = item.itemList?.id else { return false }
            return itemListIds.contains(listId)
        }
    }

    func fetchItems(forGroupId groupId: UUID) async throws -> [SDItem] {
        let targetId = groupId
        // Two-hop optional predicates (itemList?.group?.id) are not supported by SwiftData.
        // Resolve in two steps: one-hop fetch of item lists, then in-memory filter on items.
        let listDescriptor = FetchDescriptor<SDItemList>(
            predicate: #Predicate { $0.group?.id == targetId }
        )
        let itemLists = try context.fetch(listDescriptor)
        let itemListIds = Set(itemLists.map(\.id))
        guard !itemListIds.isEmpty else { return [] }

        let itemDescriptor = FetchDescriptor<SDItem>(
            sortBy: [SortDescriptor(\.createdAt, order: .reverse)]
        )
        let allItems = try context.fetch(itemDescriptor)
        return allItems.filter { item in
            guard let listId = item.itemList?.id else { return false }
            return itemListIds.contains(listId)
        }
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
