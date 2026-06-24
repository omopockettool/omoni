import Foundation
import SwiftData

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

extension SDItem: Identifiable {}

extension SDItem {
    var isValid: Bool {
        !itemDescription.isEmpty && amount > 0 && ValidationHelper.isValidItemQuantity(quantity)
    }
    
    func validate() throws {
        guard !itemDescription.isEmpty else {
            throw ValidationError.emptyItemDescription
        }
        
        guard amount > 0 else {
            throw ValidationError.invalidAmount
        }
        
        guard ValidationHelper.isValidItemQuantity(quantity) else {
            throw ValidationError.invalidQuantity
        }
    }
}

extension SDItem {
    var totalAmount: Double {
        guard amount.isFinite && !amount.isNaN else { return 0.0 }
        return amount * Double(quantity)
    }
    
    var amountDecimal: Decimal {
        Decimal(amount)
    }
    
    var totalAmountDecimal: Decimal {
        amountDecimal * Decimal(quantity)
    }
    
    func formattedAmount(currencyCode: String = "USD") -> String {
        let formatter = NumberFormatter()
        formatter.numberStyle = .currency
        formatter.currencyCode = currencyCode
        return formatter.string(from: NSNumber(value: amount)) ?? "$0.00"
    }
    
    func formattedTotalAmount(currencyCode: String = "USD") -> String {
        let formatter = NumberFormatter()
        formatter.numberStyle = .currency
        formatter.currencyCode = currencyCode
        return formatter.string(from: NSNumber(value: totalAmount)) ?? "$0.00"
    }
}

extension SDItem {
    func applyEdits(description: String, amount: Double, quantity: Int) throws {
        guard !description.isEmpty else {
            throw ValidationError.emptyItemDescription
        }

        guard amount >= 0 else {
            throw ValidationError.invalidAmount
        }

        guard ValidationHelper.isValidItemQuantity(quantity) else {
            throw ValidationError.invalidQuantity
        }

        var didChange = false

        if itemDescription != description {
            itemDescription = description
            didChange = true
        }

        if self.amount != amount {
            self.amount = amount
            didChange = true
        }

        if self.quantity != quantity {
            self.quantity = quantity
            didChange = true
        }

        if didChange {
            touch()
        }
    }

    func touch(_ modifiedAt: Date = Date()) {
        lastModifiedAt = modifiedAt
    }

    func togglePaid() {
        setPaidStatus(!isPaid)
    }
    
    func markAsPaid() {
        setPaidStatus(true)
    }
    
    func markAsUnpaid() {
        setPaidStatus(false)
    }

    func setPaidStatus(_ isPaid: Bool, modifiedAt: Date = Date()) {
        guard self.isPaid != isPaid else { return }
        self.isPaid = isPaid
        lastModifiedAt = modifiedAt
    }

    func restorePaidStatus(_ isPaid: Bool, lastModifiedAt: Date?) {
        guard self.isPaid != isPaid || self.lastModifiedAt != lastModifiedAt else { return }
        self.isPaid = isPaid
        self.lastModifiedAt = lastModifiedAt
    }
    
    func updateQuantity(to newQuantity: Int) throws {
        guard ValidationHelper.isValidItemQuantity(newQuantity) else {
            throw ValidationError.invalidQuantity
        }
        guard quantity != newQuantity else { return }
        quantity = newQuantity
        touch()
    }
    
    func updateAmount(to newAmount: Double) throws {
        guard newAmount > 0 else {
            throw ValidationError.invalidAmount
        }
        guard amount != newAmount else { return }
        amount = newAmount
        touch()
    }
}

#if DEBUG
extension SDItem {
    static func mock(
        id: UUID = UUID(),
        itemDescription: String = "Test Item",
        amount: Double = 10.0,
        quantity: Int = 1,
        isPaid: Bool = false,
        createdAt: Date = Date(),
        lastModifiedAt: Date? = nil,
        itemList: SDItemList? = nil
    ) -> SDItem {
        let item = SDItem(
            id: id,
            itemDescription: itemDescription,
            amount: amount,
            quantity: quantity,
            isPaid: isPaid,
            createdAt: createdAt,
            lastModifiedAt: lastModifiedAt
        )
        item.itemList = itemList
        return item
    }
}
#endif
