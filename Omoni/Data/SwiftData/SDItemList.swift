import Foundation
import SwiftData

enum ItemListStructure: String, Codable, CaseIterable {
    case singleEntry
    case itemizedList
}

@Model
final class SDItemList {
    @Attribute(.unique) var id: UUID
    var itemListDescription: String
    var isList: Bool?
    /// User-facing entry date. This can differ from `createdAt` when someone logs
    /// an expense later (for example, creating today's record for yesterday's expense).
    var date: Date
    /// Automatic persistence timestamp for when this record was first created.
    var createdAt: Date
    /// Automatic timestamp for the latest edit affecting this list or its items.
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

extension SDItemList: Identifiable {}

extension SDItemList {
    var isValid: Bool {
        true
    }
}

extension SDItemList {
    var structure: ItemListStructure {
        if let isList {
            return isList ? .itemizedList : .singleEntry
        }

        guard items.count == 1, let singleItem = items.first else {
            return .itemizedList
        }

        return singleItem.itemDescription == itemListDescription
            ? .singleEntry
            : .itemizedList
    }

    var isSingleEntry: Bool {
        structure == .singleEntry
    }

    var singleEntryItem: SDItem? {
        guard isSingleEntry else { return nil }
        return items.first
    }

    func setStructure(_ structure: ItemListStructure) {
        let targetIsList = (structure == .itemizedList)
        guard isList != targetIsList else { return }
        isList = targetIsList
    }

    func applyEdits(
        description: String,
        structure: ItemListStructure,
        date: Date,
        category: SDCategory?,
        paymentMethod: SDPaymentMethod?,
        group: SDGroup?
    ) {
        var didChange = false

        if itemListDescription != description {
            itemListDescription = description
            didChange = true
        }

        let previousIsList = isList
        setStructure(structure)
        if previousIsList != isList {
            didChange = true
        }

        if self.date != date {
            self.date = date
            didChange = true
        }

        if self.category?.id != category?.id {
            self.category = category
            didChange = true
        }

        if self.paymentMethod?.id != paymentMethod?.id {
            self.paymentMethod = paymentMethod
            didChange = true
        }

        if self.group?.id != group?.id {
            self.group = group
            didChange = true
        }

        if didChange {
            touch()
        }
    }

    func touch(_ modifiedAt: Date = Date()) {
        lastModifiedAt = modifiedAt
    }

    var totalAmount: Double {
        items.reduce(0.0) { total, item in
            total + item.totalAmount
        }
    }
    
    var totalPaidAmount: Double {
        items.filter { $0.isPaid }.reduce(0.0) { total, item in
            total + item.totalAmount
        }
    }
    
    var totalUnpaidAmount: Double {
        items.filter { !$0.isPaid }.reduce(0.0) { total, item in
            total + item.totalAmount
        }
    }
    
    var itemCount: Int {
        items.count
    }
    
    var paidItemCount: Int {
        items.filter { $0.isPaid }.count
    }
    
    var unpaidItemCount: Int {
        items.filter { !$0.isPaid }.count
    }
    
    var isFullyPaid: Bool {
        !items.isEmpty && items.allSatisfy { $0.isPaid }
    }
    
    var isPartiallyPaid: Bool {
        let paidCount = paidItemCount
        return paidCount > 0 && paidCount < itemCount
    }
    
    var isUnpaid: Bool {
        paidItemCount == 0
    }
    
    var paymentStatus: PaymentStatus {
        if items.isEmpty || isUnpaid {
            return .unpaid
        } else if isFullyPaid {
            return .paid
        } else {
            return .partial
        }
    }
    
    enum PaymentStatus {
        case unpaid
        case partial
        case paid
        
        var displayText: String {
            switch self {
            case .unpaid: return "Unpaid"
            case .partial: return "Partially Paid"
            case .paid: return "Paid"
            }
        }
        
        var iconName: String {
            switch self {
            case .unpaid: return "circle"
            case .partial: return "circle.lefthalf.filled"
            case .paid: return "checkmark.circle.fill"
            }
        }
    }
}

extension SDItemList {
    func toggleAllItemsPaid(to isPaid: Bool) {
        let modifiedAt = Date()
        var didChange = false

        items.forEach {
            let previousValue = $0.isPaid
            $0.setPaidStatus(isPaid, modifiedAt: modifiedAt)
            if previousValue != $0.isPaid {
                didChange = true
            }
        }

        if didChange {
            lastModifiedAt = modifiedAt
        }
    }
    
    func addItem(_ item: SDItem) {
        items.append(item)
        item.itemList = self
        touch()
    }
    
    func removeItem(_ item: SDItem) {
        items.removeAll { $0.id == item.id }
        touch()
    }
}

extension SDItemList {
    static func mock(
        id: UUID = UUID(),
        itemListDescription: String = "Shopping",
        isList: Bool? = true,
        date: Date = Date(),
        createdAt: Date = Date(),
        lastModifiedAt: Date? = nil,
        category: SDCategory? = nil,
        paymentMethod: SDPaymentMethod? = nil,
        group: SDGroup? = nil
    ) -> SDItemList {
        let itemList = SDItemList(
            id: id,
            itemListDescription: itemListDescription,
            isList: isList,
            date: date,
            createdAt: createdAt,
            lastModifiedAt: lastModifiedAt
        )
        itemList.category = category
        itemList.paymentMethod = paymentMethod
        itemList.group = group
        return itemList
    }
}
