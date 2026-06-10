import Foundation

struct ItemSuggestion: Identifiable, Equatable {
    let id: UUID
    let description: String
    let amount: Double
}
