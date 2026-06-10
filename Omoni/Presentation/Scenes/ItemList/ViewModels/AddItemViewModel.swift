//
//  AddItemViewModel.swift
//  Omoni
//

import Foundation

@MainActor

@Observable
final class AddItemViewModel {

    // MARK: - Published Properties
    var description = ""
    var amount = ""
    var quantity = "1"
    var isSaving = false
    var errorMessage: String?
    var showError = false
    var suggestions: [ItemSuggestion] = []

    // MARK: - Dependencies
    private let itemListId: UUID
    private let groupId: UUID
    private let categoryId: UUID?
    private let itemToEdit: SDItem?
    private let itemListDescription: String
    private let createItemUseCase: CreateItemUseCase
    private let updateItemUseCase: UpdateItemUseCase
    private let fetchItemSuggestionsUseCase: FetchItemSuggestionsUseCase
    private var suggestionTask: Task<Void, Never>?
    private var suppressNextSuggestionLoad = false

    // MARK: - Computed Properties
    var isEditMode: Bool { itemToEdit != nil }

    var canSave: Bool {
        let hasDescription = !description.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty
        let hasAmount = !amount.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty
        return (hasDescription || hasAmount) && isQuantityValid && isAmountValid && !isSaving
    }

    var showsTotalPreview: Bool {
        let normalized = amount.replacingOccurrences(of: ",", with: ".")
        guard let price = Decimal(string: normalized), price > 0,
              let qty = ValidationHelper.itemQuantityValue(from: quantity), qty > 1 else { return false }
        return true
    }

    private var isQuantityValid: Bool {
        ValidationHelper.itemQuantityValue(from: quantity) != nil
    }

    private var isAmountValid: Bool {
        let trimmedAmount = amount.trimmingCharacters(in: .whitespacesAndNewlines)
        guard !trimmedAmount.isEmpty else { return true }

        let normalizedAmount = trimmedAmount.replacingOccurrences(of: ",", with: ".")
        if normalizedAmount.hasSuffix(".") { return false }
        return Decimal(string: normalizedAmount) != nil
    }

    // MARK: - Initialization
    init(
        itemListId: UUID,
        groupId: UUID,
        categoryId: UUID?,
        itemToEdit: SDItem? = nil,
        itemListDescription: String,
        createItemUseCase: CreateItemUseCase,
        updateItemUseCase: UpdateItemUseCase,
        fetchItemSuggestionsUseCase: FetchItemSuggestionsUseCase
    ) {
        self.itemListId = itemListId
        self.groupId = groupId
        self.categoryId = categoryId
        self.itemToEdit = itemToEdit
        self.itemListDescription = itemListDescription
        self.createItemUseCase = createItemUseCase
        self.updateItemUseCase = updateItemUseCase
        self.fetchItemSuggestionsUseCase = fetchItemSuggestionsUseCase

        if let item = itemToEdit {
            self.description = item.itemDescription
            self.amount = item.amount == 0 ? "" : String(format: "%.2f", item.amount).replacingOccurrences(of: "\\.?0+$", with: "", options: .regularExpression)
            self.quantity = String(item.quantity)
        }
    }

    // MARK: - Suggestions

    func loadSuggestions(for query: String) {
        if suppressNextSuggestionLoad {
            suppressNextSuggestionLoad = false
            return
        }
        suggestionTask?.cancel()
        guard query.count >= 2, !isEditMode else {
            suggestions = []
            return
        }
        suggestionTask = Task {
            try? await Task.sleep(for: .milliseconds(250))
            guard !Task.isCancelled else { return }
            suggestions = await fetchItemSuggestionsUseCase.execute(query: query, categoryId: categoryId, groupId: groupId)
        }
    }

    func applySuggestion(_ suggestion: ItemSuggestion) {
        suppressNextSuggestionLoad = true
        description = suggestion.description
        let formatted = suggestion.amount == 0
            ? ""
            : String(format: "%.2f", suggestion.amount)
                .replacingOccurrences(of: "\\.?0+$", with: "", options: .regularExpression)
        amount = formatted
        suggestions = []
    }

    func clearSuggestions() {
        suggestionTask?.cancel()
        suggestions = []
    }

    // MARK: - Public Methods

    func saveItem() async -> SDItem? {
        let trimmed = description.trimmingCharacters(in: .whitespacesAndNewlines)
        let finalDescription = trimmed.isEmpty ? itemListDescription : trimmed

        let trimmedAmount = amount.trimmingCharacters(in: .whitespacesAndNewlines)
        let normalizedAmount = trimmedAmount.replacingOccurrences(of: ",", with: ".")

        if !trimmedAmount.isEmpty, normalizedAmount.hasSuffix(".") {
            errorMessage = "Cantidad inválida"
            showError = true
            return nil
        }

        guard let amountDecimal = normalizedAmount.isEmpty ? Decimal(0) : Decimal(string: normalizedAmount) else {
            errorMessage = "Cantidad inválida"
            showError = true
            return nil
        }

        guard let quantityValue = ValidationHelper.itemQuantityValue(from: quantity) else {
            errorMessage = "Unidades inválidas"
            showError = true
            return nil
        }

        isSaving = true
        errorMessage = nil
        showError = false

        do {
            let item: SDItem

            if let existingItem = itemToEdit {
                try existingItem.applyEdits(
                    description: finalDescription,
                    amount: Double(truncating: NSDecimalNumber(decimal: amountDecimal)),
                    quantity: quantityValue
                )
                try await updateItemUseCase.execute(existingItem)
                item = existingItem
            } else {
                // Items created from the detail view start unpaid by default.
                // Quick-add from the dashboard uses a different flow.
                item = try await createItemUseCase.execute(
                    description: finalDescription,
                    amount: amountDecimal,
                    quantity: quantityValue,
                    itemListId: itemListId,
                    isPaid: false
                )
            }

            isSaving = false
            return item
        } catch {
            errorMessage = "Error al guardar artículo: \(error.localizedDescription)"
            showError = true
            isSaving = false
            return nil
        }
    }

    func clearError() {
        errorMessage = nil
        showError = false
    }

    func validateAndCorrectAmount() {
        amount = correctAmountInput(amount)
    }

    func sanitizeQuantityInput(_ input: String) -> String {
        ValidationHelper.sanitizeItemQuantityEditingInput(input)
    }

    func normalizeQuantityInputAfterEditing() {
        quantity = ValidationHelper.normalizeItemQuantityAfterEditing(quantity)
    }

    func setQuantity(_ newValue: Int) {
        let boundedValue = min(
            max(newValue, AppConstants.Validation.minItemQuantity),
            AppConstants.Validation.maxItemQuantity
        )
        quantity = String(boundedValue)
    }

    // MARK: - Private Methods

    private func correctAmountInput(_ input: String) -> String {
        HeroAmountInputSanitizer.sanitize(input)
    }
}
