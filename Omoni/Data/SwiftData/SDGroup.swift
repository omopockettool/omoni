import Foundation
import SwiftData

enum SDGroupKind: String, Codable, CaseIterable {
    case expense
    case income
}

@Model
final class SDGroup {
    @Attribute(.unique) var id: UUID
    var name: String
    var currency: String
    /// Persisted optional during the first rollout so older backups and pre-UI records stay compatible.
    /// `nil` is treated as `.expense` until the UI exposes this field.
    var groupKind: String?
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
        groupKind: String? = nil,
        createdAt: Date = Date(),
        lastModifiedAt: Date? = nil
    ) {
        self.id = id
        self.name = name
        self.currency = currency
        self.groupKind = groupKind
        self.createdAt = createdAt
        self.lastModifiedAt = lastModifiedAt
    }
}

extension SDGroup: Identifiable {}

extension SDGroup {
    var resolvedGroupKind: SDGroupKind {
        guard let groupKind, let resolved = SDGroupKind(rawValue: groupKind) else {
            return .expense
        }
        return resolved
    }

    func setGroupKind(_ kind: SDGroupKind) {
        let rawValue = kind.rawValue
        guard groupKind != rawValue else { return }
        groupKind = rawValue
    }

    func applyEdits(name: String, currency: String, kind: SDGroupKind? = nil) {
        var didChange = false

        if self.name != name {
            self.name = name
            didChange = true
        }

        if self.currency != currency {
            self.currency = currency
            didChange = true
        }

        if let kind {
            let previousGroupKind = groupKind
            setGroupKind(kind)
            if previousGroupKind != groupKind {
                didChange = true
            }
        }

        if didChange {
            touch()
        }
    }

    func touch(_ modifiedAt: Date = Date()) {
        lastModifiedAt = modifiedAt
    }

    var isValid: Bool {
        !name.isEmpty && !currency.isEmpty
    }
    
    func validate() throws {
        guard !name.isEmpty else {
            throw ValidationError.emptyGroupName
        }
        
        guard !currency.isEmpty else {
            throw ValidationError.invalidAmount
        }
    }
}

extension SDGroup {
    var users: [SDUser] {
        userGroups.compactMap { $0.user }
    }
    
    var owner: SDUser? {
        userGroups.first { $0.role == SDUserGroup.Role.owner.rawValue }?.user
    }
    
    var activePaymentMethods: [SDPaymentMethod] {
        paymentMethods.filter { $0.isActive }
    }
    
}

extension SDGroup {
    static func mock(
        id: UUID = UUID(),
        name: String = "My Group",
        currency: String = "USD",
        groupKind: String? = SDGroupKind.expense.rawValue,
        createdAt: Date = Date(),
        lastModifiedAt: Date? = nil
    ) -> SDGroup {
        SDGroup(
            id: id,
            name: name,
            currency: currency,
            groupKind: groupKind,
            createdAt: createdAt,
            lastModifiedAt: lastModifiedAt
        )
    }
}
