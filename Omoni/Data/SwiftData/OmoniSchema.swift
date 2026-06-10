import Foundation
import SwiftData

/// Frozen pre-release schema snapshot without `groupKind`.
/// Keep this shape immutable once a newer schema is introduced.
enum SchemaV1: VersionedSchema {
    static var versionIdentifier = Schema.Version(1, 0, 0)

    static var models: [any PersistentModel.Type] {
        [
            SDUser.self,
            SDGroup.self,
            SDUserGroup.self,
            SDCategory.self,
            SDPaymentMethod.self,
            SDItemList.self,
            SDItem.self
        ]
    }

    @Model
    final class SDUser {
        @Attribute(.unique) var id: UUID
        var name: String
        var email: String
        var createdAt: Date
        var lastModifiedAt: Date?

        @Relationship(deleteRule: .cascade, inverse: \SDUserGroup.user)
        var userGroups: [SDUserGroup] = []

        init(
            id: UUID = UUID(),
            name: String,
            email: String,
            createdAt: Date = Date(),
            lastModifiedAt: Date? = nil
        ) {
            self.id = id
            self.name = name
            self.email = email
            self.createdAt = createdAt
            self.lastModifiedAt = lastModifiedAt
        }
    }

    @Model
    final class SDGroup {
        @Attribute(.unique) var id: UUID
        var name: String
        var currency: String
        var createdAt: Date
        var lastModifiedAt: Date?

        @Relationship(deleteRule: .cascade, inverse: \SDUserGroup.group)
        var userGroups: [SDUserGroup] = []

        @Relationship(deleteRule: .cascade, inverse: \SDCategory.group)
        var categories: [SDCategory] = []

        @Relationship(deleteRule: .cascade, inverse: \SDPaymentMethod.group)
        var paymentMethods: [SDPaymentMethod] = []

        @Relationship(deleteRule: .cascade, inverse: \SDItemList.group)
        var itemLists: [SDItemList] = []

        init(
            id: UUID = UUID(),
            name: String,
            currency: String = "USD",
            createdAt: Date = Date(),
            lastModifiedAt: Date? = nil
        ) {
            self.id = id
            self.name = name
            self.currency = currency
            self.createdAt = createdAt
            self.lastModifiedAt = lastModifiedAt
        }
    }

    @Model
    final class SDUserGroup {
        @Attribute(.unique) var id: UUID
        var role: String
        var joinedAt: Date

        var user: SDUser?
        var group: SDGroup?

        init(
            id: UUID = UUID(),
            role: String = "owner",
            joinedAt: Date = Date()
        ) {
            self.id = id
            self.role = role
            self.joinedAt = joinedAt
        }
    }

    @Model
    final class SDCategory {
        @Attribute(.unique) var id: UUID
        var name: String
        var color: String
        var icon: String
        var sortOrder: Int
        var limit: Double?
        var limitFrequency: String
        var createdAt: Date
        var lastModifiedAt: Date?

        var group: SDGroup?

        @Relationship(deleteRule: .nullify, inverse: \SDItemList.category)
        var itemLists: [SDItemList] = []

        init(
            id: UUID = UUID(),
            name: String,
            color: String = "#8E8E93",
            icon: String = "tag.fill",
            sortOrder: Int = 0,
            limit: Double? = nil,
            limitFrequency: String = "monthly",
            createdAt: Date = Date(),
            lastModifiedAt: Date? = nil
        ) {
            self.id = id
            self.name = name
            self.color = color
            self.icon = icon
            self.sortOrder = sortOrder
            self.limit = limit
            self.limitFrequency = limitFrequency
            self.createdAt = createdAt
            self.lastModifiedAt = lastModifiedAt
        }
    }

    @Model
    final class SDPaymentMethod {
        @Attribute(.unique) var id: UUID
        var name: String
        var type: String
        var icon: String
        var color: String
        var isActive: Bool
        var createdAt: Date
        var lastModifiedAt: Date?

        var group: SDGroup?

        @Relationship(deleteRule: .nullify, inverse: \SDItemList.paymentMethod)
        var itemLists: [SDItemList] = []

        init(
            id: UUID = UUID(),
            name: String,
            type: String = "card",
            icon: String = "creditcard.fill",
            color: String = "#8E8E93",
            isActive: Bool = true,
            createdAt: Date = Date(),
            lastModifiedAt: Date? = nil
        ) {
            self.id = id
            self.name = name
            self.type = type
            self.icon = icon
            self.color = color
            self.isActive = isActive
            self.createdAt = createdAt
            self.lastModifiedAt = lastModifiedAt
        }
    }

    @Model
    final class SDItemList {
        @Attribute(.unique) var id: UUID
        var itemListDescription: String
        var isList: Bool?
        var date: Date
        var createdAt: Date
        var lastModifiedAt: Date?

        var group: SDGroup?
        var category: SDCategory?
        var paymentMethod: SDPaymentMethod?

        @Relationship(deleteRule: .cascade, inverse: \SDItem.itemList)
        var items: [SDItem] = []

        init(
            id: UUID = UUID(),
            itemListDescription: String = "",
            isList: Bool? = nil,
            date: Date = Date(),
            createdAt: Date = Date(),
            lastModifiedAt: Date? = nil
        ) {
            self.id = id
            self.itemListDescription = itemListDescription
            self.isList = isList
            self.date = date
            self.createdAt = createdAt
            self.lastModifiedAt = lastModifiedAt
        }
    }

    @Model
    final class SDItem {
        @Attribute(.unique) var id: UUID
        var itemDescription: String
        var amount: Double
        var quantity: Int
        var isPaid: Bool
        var createdAt: Date
        var lastModifiedAt: Date?

        var itemList: SDItemList?

        init(
            id: UUID = UUID(),
            itemDescription: String = "",
            amount: Double = 0.0,
            quantity: Int = 1,
            isPaid: Bool = false,
            createdAt: Date = Date(),
            lastModifiedAt: Date? = nil
        ) {
            self.id = id
            self.itemDescription = itemDescription
            self.amount = amount
            self.quantity = quantity
            self.isPaid = isPaid
            self.createdAt = createdAt
            self.lastModifiedAt = lastModifiedAt
        }
    }
}

/// Current live schema used by the app.
enum SchemaV2: VersionedSchema {
    static var versionIdentifier = Schema.Version(2, 0, 0)

    static var models: [any PersistentModel.Type] {
        [
            SDUser.self,
            SDGroup.self,
            SDUserGroup.self,
            SDCategory.self,
            SDPaymentMethod.self,
            SDItemList.self,
            SDItem.self
        ]
    }
}

enum OmoniMigrationPlan: SchemaMigrationPlan {
    static var schemas: [any VersionedSchema.Type] {
        [SchemaV1.self, SchemaV2.self]
    }

    static var stages: [MigrationStage] {
        [
            .lightweight(fromVersion: SchemaV1.self, toVersion: SchemaV2.self)
        ]
    }
}

typealias OmoniSchema = SchemaV2
