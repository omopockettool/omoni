import Foundation
import SwiftData

@MainActor
final class DefaultItemListRepository: ItemListRepository {
    private let context: ModelContext

    init(context: ModelContext) {
        self.context = context
    }

    func fetchItemLists(forGroupId groupId: UUID) async throws -> [SDItemList] {
        let targetGroupId = groupId
        let descriptor = FetchDescriptor<SDItemList>(
            predicate: #Predicate { $0.group?.id == targetGroupId },
            sortBy: [SortDescriptor(\.date, order: .reverse), SortDescriptor(\.createdAt, order: .reverse)]
        )
        return try context.fetch(descriptor)
    }

    func createItemList(
        description: String,
        isList: Bool,
        date: Date,
        categoryId: UUID?,
        paymentMethodId: UUID?,
        groupId: UUID?
    ) async throws -> SDItemList {
        let itemList = SDItemList(
            itemListDescription: description,
            isList: isList,
            date: date
        )

        if let groupId {
            let targetId = groupId
            let descriptor = FetchDescriptor<SDGroup>(predicate: #Predicate { $0.id == targetId })
            guard let group = try context.fetch(descriptor).first else {
                throw RepositoryError.notFound
            }
            itemList.group = group
        }
        if let categoryId {
            let targetId = categoryId
            let descriptor = FetchDescriptor<SDCategory>(predicate: #Predicate { $0.id == targetId })
            guard let category = try context.fetch(descriptor).first else {
                throw RepositoryError.notFound
            }
            itemList.category = category
        }
        if let paymentMethodId {
            let targetId = paymentMethodId
            let descriptor = FetchDescriptor<SDPaymentMethod>(predicate: #Predicate { $0.id == targetId })
            guard let paymentMethod = try context.fetch(descriptor).first else {
                throw RepositoryError.notFound
            }
            itemList.paymentMethod = paymentMethod
        }

        context.insert(itemList)
        do {
            try context.save()
        } catch {
            context.rollback()
            throw error
        }
        return itemList
    }

    func updateItemList(_ itemList: SDItemList) async throws {
        guard context.hasChanges else { return }
        itemList.touch()
        do {
            try context.save()
        } catch {
            context.rollback()
            throw error
        }
    }

    func deleteItemList(id: UUID) async throws {
        let targetId = id
        let descriptor = FetchDescriptor<SDItemList>(predicate: #Predicate { $0.id == targetId })
        guard let itemList = try context.fetch(descriptor).first else {
            throw RepositoryError.notFound
        }
        context.delete(itemList)
        do {
            try context.save()
        } catch {
            context.rollback()
            throw error
        }
    }
}
