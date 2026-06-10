import Foundation
import SwiftData
@testable import Omoni

/// In-memory SwiftData container for unit tests.
/// Each test should create its own instance for isolation.
@MainActor
final class SwiftDataTestContainer {
    let container: ModelContainer
    let context: ModelContext

    init() throws {
        container = ModelContainer.test()
        context = container.mainContext
    }

    // MARK: - Repository factories

    func makeGroupRepository() -> GroupRepository {
        DefaultGroupRepository(context: context)
    }

    func makeCategoryRepository() -> CategoryRepository {
        DefaultCategoryRepository(context: context)
    }

    func makeItemListRepository() -> ItemListRepository {
        DefaultItemListRepository(context: context)
    }

    func makeItemRepository() -> ItemRepository {
        DefaultItemRepository(context: context)
    }

    func makeBackupRepository() -> BackupRepository {
        DefaultBackupRepository(context: context)
    }

    // MARK: - Seed helpers

    @discardableResult
    func insertUser(
        name: String = "Dennis",
        email: String = "dennis@example.com"
    ) throws -> SDUser {
        let user = SDUser(name: name, email: email)
        context.insert(user)
        try context.save()
        return user
    }

    func insertGroup(name: String = "Test Group", currency: String = "EUR") throws -> SDGroup {
        let group = SDGroup(name: name, currency: currency)
        context.insert(group)
        try context.save()
        return group
    }

    @discardableResult
    func insertUserGroup(
        user: SDUser,
        group: SDGroup,
        role: String = "owner"
    ) throws -> SDUserGroup {
        let userGroup = SDUserGroup(role: role)
        userGroup.user = user
        userGroup.group = group
        context.insert(userGroup)
        try context.save()
        return userGroup
    }

    func insertCategory(name: String, group: SDGroup) throws -> SDCategory {
        let category = SDCategory(name: name)
        category.group = group
        context.insert(category)
        try context.save()
        return category
    }

    func insertItemList(
        description: String = "Lista",
        isList: Bool? = true,
        date: Date = Date(),
        group: SDGroup
    ) throws -> SDItemList {
        let itemList = SDItemList(itemListDescription: description, isList: isList, date: date)
        itemList.group = group
        context.insert(itemList)
        try context.save()
        return itemList
    }

    @discardableResult
    func insertItem(
        description: String = "Item",
        amount: Double = 10.0,
        quantity: Int = 1,
        isPaid: Bool = false,
        itemList: SDItemList
    ) throws -> SDItem {
        let item = SDItem(
            itemDescription: description,
            amount: amount,
            quantity: quantity,
            isPaid: isPaid
        )
        item.itemList = itemList
        context.insert(item)
        try context.save()
        return item
    }
}
