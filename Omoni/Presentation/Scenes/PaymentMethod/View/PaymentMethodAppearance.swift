import SwiftUI

enum PaymentMethodAppearance {
    private static let defaultIcon = "creditcard.fill"
    private static let defaultTintHex = "#0A84FF"

    static func icon(for paymentMethod: SDPaymentMethod) -> String {
        let trimmedIcon = paymentMethod.icon.trimmingCharacters(in: .whitespacesAndNewlines)
        return trimmedIcon.isEmpty ? defaultIcon : trimmedIcon
    }

    static func tint(for paymentMethod: SDPaymentMethod) -> Color {
        tint(for: icon(for: paymentMethod))
    }

    static func tint(for icon: String) -> Color {
        Color(hex: tintHex(for: icon)) ?? .blue
    }

    static func tintHex(for icon: String) -> String {
        switch icon {
        case "banknote.fill", "dollarsign.circle.fill", "eurosign.circle.fill":
            return "#30D158"
        case "arrow.left.arrow.right", "qrcode":
            return "#FF9F0A"
        case "iphone", "wallet.pass.fill":
            return "#BF5AF2"
        case "creditcard.fill", "building.columns.fill", "checkmark.seal.fill":
            return "#0A84FF"
        default:
            return defaultTintHex
        }
    }
}
