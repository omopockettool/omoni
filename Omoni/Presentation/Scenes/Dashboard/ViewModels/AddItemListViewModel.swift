
import Foundation
import UIKit
import Observation

@MainActor

@Observable
final class AddItemListViewModel {
    private struct UsageMemorySnapshot {
        let itemListDescription: String
        let createdAt: Date
        let categoryId: UUID?
        let paymentMethodId: UUID?
    }

    // MARK: - Published Properties
    var categories: [SDCategory] = []
    var paymentMethods: [SDPaymentMethod] = []
    var availableGroups: [SDGroup] = []
    var selectedGroup: SDGroup?
    var isLoading = false
    var errorMessage: String?
    var showError = false
    var toast: ToastMessage?
    var description = ""
    var price = ""
    var date = Date()
    var entryStructure: ItemListStructure = .singleEntry
    var selectedCategory: SDCategory? {
        didSet {
            guard !isEditMode, !didManuallyChoosePaymentMethod else { return }
            selectedPaymentMethod = suggestedPaymentMethod(
                forCategoryId: selectedCategory?.id,
                snapshots: usageMemorySnapshots,
                in: paymentMethods
            )
        }
    }
    var selectedPaymentMethod: SDPaymentMethod?
    var suggestions: [ConceptSuggestion] = []
    var lastUsedConcept: String?
    @ObservationIgnored var lastUsedCategoryIds: [UUID] = []
    @ObservationIgnored var lastUsedPaymentMethodId: UUID?

    // MARK: - Dependencies
    private let createItemListUseCase: CreateItemListUseCase
    private let createSingleEntryUseCase: CreateSingleEntryUseCase
    private let updateItemListUseCase: UpdateItemListUseCase
    private let updateSingleEntryUseCase: UpdateSingleEntryUseCase
    private let fetchItemListsUseCase: FetchItemListsUseCase
    private let fetchCategoriesUseCase: FetchCategoriesUseCase
    private let fetchPaymentMethodsUseCase: FetchPaymentMethodsUseCase
    private let getCurrentUserUseCase: GetCurrentUserUseCase
    private let fetchGroupsForUserUseCase: FetchGroupsForUserUseCase
    private let itemListToEdit: SDItemList?
    private let preferredCategoryId: UUID?
    @ObservationIgnored private let cacheManager = CacheManager.shared
    @ObservationIgnored private let categoryUsageLimit = 3
    @ObservationIgnored private var usageMemorySnapshots: [UsageMemorySnapshot] = []
    @ObservationIgnored private var didManuallyChoosePaymentMethod = false
    @ObservationIgnored private var hasLoadedFormData = false

    // MARK: - Computed

    var isEditMode: Bool { itemListToEdit != nil }
    var showsHeroAmountInput: Bool { entryStructure == .singleEntry }
    var usesExpandedDescriptionLayout: Bool { entryStructure == .itemizedList }
    var canConvertToSingleEntry: Bool {
        guard let itemListToEdit else { return true }
        return itemListToEdit.isSingleEntry || itemListToEdit.items.count <= 1
    }
    var structureHelperText: String? {
        guard !canConvertToSingleEntry, entryStructure == .itemizedList else { return nil }
        return LocalizationKey.Entry.singleEntryDisabledHint.localized
    }

    // MARK: - Initialization

    init(
        itemListToEdit: SDItemList? = nil,
        createItemListUseCase: CreateItemListUseCase,
        createSingleEntryUseCase: CreateSingleEntryUseCase,
        updateItemListUseCase: UpdateItemListUseCase,
        updateSingleEntryUseCase: UpdateSingleEntryUseCase,
        fetchItemListsUseCase: FetchItemListsUseCase,
        fetchCategoriesUseCase: FetchCategoriesUseCase,
        fetchPaymentMethodsUseCase: FetchPaymentMethodsUseCase,
        getCurrentUserUseCase: GetCurrentUserUseCase,
        fetchGroupsForUserUseCase: FetchGroupsForUserUseCase,
        preferredCategoryId: UUID? = nil
    ) {
        self.itemListToEdit = itemListToEdit
        self.preferredCategoryId = preferredCategoryId
        self.createItemListUseCase = createItemListUseCase
        self.createSingleEntryUseCase = createSingleEntryUseCase
        self.updateItemListUseCase = updateItemListUseCase
        self.updateSingleEntryUseCase = updateSingleEntryUseCase
        self.fetchItemListsUseCase = fetchItemListsUseCase
        self.fetchCategoriesUseCase = fetchCategoriesUseCase
        self.fetchPaymentMethodsUseCase = fetchPaymentMethodsUseCase
        self.getCurrentUserUseCase = getCurrentUserUseCase
        self.fetchGroupsForUserUseCase = fetchGroupsForUserUseCase

        if let toEdit = itemListToEdit {
            self.entryStructure = toEdit.structure
            self.description = toEdit.itemListDescription
            self.date = toEdit.date
            self.selectedGroup = toEdit.group
            if toEdit.items.count == 1, let firstItem = toEdit.items.first {
                self.price = Self.formattedPrice(firstItem.amount)
            }
            if let singleItem = toEdit.singleEntryItem {
                self.description = singleItem.itemDescription
            }
        }
    }

    convenience init(
        itemListToEdit: SDItemList? = nil,
        initialDate: Date? = nil,
        preferredCategoryId: UUID? = nil
    ) {
        let appContainer = AppDIContainer.shared
        self.init(
            itemListToEdit: itemListToEdit,
            createItemListUseCase: appContainer.makeCreateItemListUseCase(),
            createSingleEntryUseCase: appContainer.makeCreateSingleEntryUseCase(),
            updateItemListUseCase: appContainer.makeUpdateItemListUseCase(),
            updateSingleEntryUseCase: appContainer.makeUpdateSingleEntryUseCase(),
            fetchItemListsUseCase: appContainer.makeFetchItemListsUseCase(),
            fetchCategoriesUseCase: appContainer.makeFetchCategoriesUseCase(),
            fetchPaymentMethodsUseCase: appContainer.makeFetchPaymentMethodsUseCase(),
            getCurrentUserUseCase: appContainer.makeGetCurrentUserUseCase(),
            fetchGroupsForUserUseCase: appContainer.makeFetchGroupsForUserUseCase(),
            preferredCategoryId: preferredCategoryId
        )
        if itemListToEdit == nil, let initialDate {
            self.date = initialDate
        }
    }

    // MARK: - Computed Properties

    var formattedDate: String { DateFormatterHelper.formatDate(date) }

    var canSave: Bool {
        guard isPriceValid else { return false }
        if entryStructure == .singleEntry {
            guard let priceAsDecimal else { return false }
            return priceAsDecimal > 0
        }
        return true
    }

    var isPriceValid: Bool {
        if price.isEmpty { return entryStructure == .itemizedList }
        let normalizedPrice = price.replacingOccurrences(of: ",", with: ".")
        if normalizedPrice.hasSuffix(".") { return false }
        return NSDecimalNumber(string: normalizedPrice) != NSDecimalNumber.notANumber
    }

    var priceAsDecimal: Decimal? {
        guard !price.isEmpty else { return nil }
        let normalizedPrice = price.replacingOccurrences(of: ",", with: ".")
        guard let decimal = Decimal(string: normalizedPrice) else { return nil }
        return decimal
    }

    func showValidationToast() {
        let resolvedPrice = priceAsDecimal
        if entryStructure == .singleEntry,
           resolvedPrice == nil || (resolvedPrice ?? 0) <= 0 {
            toast = ToastMessage("Añade un importe válido para guardar el registro.", type: .warning)
        } else if !isPriceValid {
            toast = ToastMessage("Precio no válido", type: .warning)
        }
    }

    func resolvedDescriptionForSave() -> String {
        let trimmedDescription = description.trimmingCharacters(in: .whitespacesAndNewlines)
        if !trimmedDescription.isEmpty {
            return trimmedDescription
        }

        let fallback = lastUsedConcept ?? selectedCategory?.name ?? "Concepto"
        description = fallback
        return fallback
    }

    func updateEntryStructure(to newStructure: ItemListStructure) {
        guard newStructure != entryStructure else { return }
        guard newStructure == .itemizedList || canConvertToSingleEntry else {
            toast = ToastMessage(LocalizationKey.Entry.singleEntryDisabledHint.localized, type: .info)
            return
        }
        entryStructure = newStructure
    }

    // MARK: - Public Methods

    func configure(defaultGroup: SDGroup, availableGroups: [SDGroup]) {
        if selectedGroup == nil {
            selectedGroup = defaultGroup
        }
        let configuredGroups = availableGroups.isEmpty ? [defaultGroup] : availableGroups
        if configuredGroups.contains(where: { $0.id == defaultGroup.id }) {
            self.availableGroups = configuredGroups
        } else {
            self.availableGroups = [defaultGroup] + configuredGroups
        }
    }

    func loadOptionsForSelectedGroup() async {
        await ensureAvailableGroupsLoaded()
        guard let groupId = selectedGroup?.id else { return }
        let shouldRestoreEditSelections = isEditMode && !hasLoadedFormData
        await loadOptions(forGroupId: groupId, restoringEditSelections: shouldRestoreEditSelections)
        hasLoadedFormData = true
    }

    func loadOptions(forGroupId groupId: UUID, restoringEditSelections: Bool) async {
        isLoading = true
        errorMessage = nil
        showError = false

        do {
            let categories = try await fetchCategoriesUseCase.execute(forGroupId: groupId)
            let paymentMethods = try await fetchPaymentMethodsUseCase.executeActive(forGroupId: groupId)
            self.categories = categories
            self.paymentMethods = paymentMethods

            if restoringEditSelections {
                selectedCategory = categories.first { $0.id == itemListToEdit?.category?.id }
                selectedPaymentMethod = paymentMethods.first { $0.id == itemListToEdit?.paymentMethod?.id }
            } else {
                let snapshots = (try? await loadUsageMemorySnapshots(forGroupId: groupId)) ?? []
                usageMemorySnapshots = snapshots
                let categoryIdToSelect = preferredCategoryId
                    ?? snapshots.max { $0.createdAt < $1.createdAt }.flatMap { $0.categoryId }
                selectedCategory = categoryIdToSelect.flatMap { id in categories.first { $0.id == id } }
                // selectedPaymentMethod is set by selectedCategory's didSet via suggestedPaymentMethod
            }

            updateSuggestions()
        } catch {
            errorMessage = "Error al cargar datos del formulario: \(error.localizedDescription)"
            showError = true
        }

        isLoading = false
    }

    func loadUsageMemory(forGroupId groupId: UUID) async {
        didManuallyChoosePaymentMethod = false
        let persistedLastUsed = await loadLastUsedSelectionIds(forGroupId: groupId)
        lastUsedCategoryIds = storedCategoryIds(forGroupId: groupId)
        if lastUsedCategoryIds.isEmpty, let categoryId = persistedLastUsed.categoryId {
            lastUsedCategoryIds = [categoryId]
        }
        lastUsedPaymentMethodId = persistedLastUsed.hasHistory
            ? persistedLastUsed.paymentMethodId
            : storedPaymentMethodId(forGroupId: groupId)
    }

    func resolveUsageMemory(forGroupId groupId: UUID) async -> (categoryIds: [UUID], paymentMethodId: UUID?) {
        let persistedLastUsed = await loadLastUsedSelectionIds(forGroupId: groupId)
        var categoryIds = storedCategoryIds(forGroupId: groupId)
        if categoryIds.isEmpty, let categoryId = persistedLastUsed.categoryId {
            categoryIds = [categoryId]
        }
        let paymentMethodId = persistedLastUsed.hasHistory
            ? persistedLastUsed.paymentMethodId
            : storedPaymentMethodId(forGroupId: groupId)
        return (categoryIds, paymentMethodId)
    }

    func recordCategoryUsage(_ category: SDCategory, forGroupId groupId: UUID) {
        var ids = lastUsedCategoryIds
        ids.removeAll { $0 == category.id }
        ids.insert(category.id, at: 0)
        ids = Array(ids.prefix(categoryUsageLimit))
        lastUsedCategoryIds = ids

        let stored = ids.map { $0.uuidString }.joined(separator: ",")
        UserDefaults.standard.set(stored, forKey: categoryUsageKey(forGroupId: groupId))
    }

    func recordPaymentMethodUsage(_ paymentMethod: SDPaymentMethod, forGroupId groupId: UUID) {
        didManuallyChoosePaymentMethod = true
        lastUsedPaymentMethodId = paymentMethod.id
        UserDefaults.standard.set(paymentMethod.id.uuidString, forKey: paymentMethodUsageKey(forGroupId: groupId))
    }

    func deselectPaymentMethodManually() {
        didManuallyChoosePaymentMethod = true
        selectedPaymentMethod = nil
    }

    func orderedCategoriesByUsage() -> [SDCategory] {
        categories.sorted {
            chipRank($0.id, lastUsed: lastUsedCategoryIds) <
            chipRank($1.id, lastUsed: lastUsedCategoryIds)
        }
    }

    func orderedCategoriesByUsage(lastUsedCategoryIds: [UUID]) -> [SDCategory] {
        categories.sorted {
            chipRank($0.id, lastUsed: lastUsedCategoryIds) <
            chipRank($1.id, lastUsed: lastUsedCategoryIds)
        }
    }

    func orderedPaymentMethodsByUsage() -> [SDPaymentMethod] {
        paymentMethods.sorted {
            chipRank($0.id, lastUsed: lastUsedPaymentMethodId) <
            chipRank($1.id, lastUsed: lastUsedPaymentMethodId)
        }
    }

    func orderedPaymentMethodsByUsage(lastUsedPaymentMethodId: UUID?) -> [SDPaymentMethod] {
        paymentMethods.sorted {
            chipRank($0.id, lastUsed: lastUsedPaymentMethodId) <
            chipRank($1.id, lastUsed: lastUsedPaymentMethodId)
        }
    }

    private func loadLastUsedSelectionIds(forGroupId groupId: UUID) async -> (categoryId: UUID?, paymentMethodId: UUID?, hasHistory: Bool) {
        do {
            let snapshots = try await loadUsageMemorySnapshots(forGroupId: groupId)
            usageMemorySnapshots = snapshots
            let lastRegistered = snapshots.max { $0.createdAt < $1.createdAt }
            return (
                snapshots.first { $0.categoryId != nil }?.categoryId,
                lastRegistered?.paymentMethodId,
                lastRegistered != nil
            )
        } catch {
            usageMemorySnapshots = []
            return (nil, nil, false)
        }
    }

    private func loadUsageMemorySnapshots(forGroupId groupId: UUID) async throws -> [UsageMemorySnapshot] {
        let key = usageMemoryCacheKey(forGroupId: groupId)
        if let cached: [UsageMemorySnapshot] = cacheManager.getCachedData(for: key) {
            return cached
        }

        let itemLists = try await fetchItemListsUseCase.execute(forGroupId: groupId)
        let snapshots = itemLists.map {
            UsageMemorySnapshot(
                itemListDescription: $0.itemListDescription,
                createdAt: $0.createdAt,
                categoryId: $0.category?.id,
                paymentMethodId: $0.paymentMethod?.id
            )
        }
        cacheManager.cacheData(snapshots, for: key)
        return snapshots
    }

    private func suggestedPaymentMethod(
        forCategoryId categoryId: UUID?,
        snapshots: [UsageMemorySnapshot],
        in paymentMethods: [SDPaymentMethod]
    ) -> SDPaymentMethod? {
        if let categoryId {
            let lastForCategory = snapshots
                .filter { $0.categoryId == categoryId }
                .max { $0.createdAt < $1.createdAt }
                .flatMap { $0.paymentMethodId }
            if let id = lastForCategory, let method = paymentMethods.first(where: { $0.id == id }) {
                return method
            }
        }
        let lastGlobal = snapshots
            .max { $0.createdAt < $1.createdAt }
            .flatMap { $0.paymentMethodId }
        if let id = lastGlobal, let method = paymentMethods.first(where: { $0.id == id }) {
            return method
        }
        return nil
    }

    private func clearUsageMemoryCache(forGroupId groupId: UUID) {
        cacheManager.clearDataCache(for: usageMemoryCacheKey(forGroupId: groupId))
    }

    private func usageMemoryCacheKey(forGroupId groupId: UUID) -> String {
        "quick_add_usage_memory_\(groupId.uuidString)"
    }

    private func storedCategoryIds(forGroupId groupId: UUID) -> [UUID] {
        UserDefaults.standard
            .string(forKey: categoryUsageKey(forGroupId: groupId))
            .map { $0.components(separatedBy: ",").compactMap { UUID(uuidString: $0) } }
            ?? []
    }

    private func storedPaymentMethodId(forGroupId groupId: UUID) -> UUID? {
        UserDefaults.standard
            .string(forKey: paymentMethodUsageKey(forGroupId: groupId))
            .flatMap { UUID(uuidString: $0) }
    }

    private func categoryUsageKey(forGroupId groupId: UUID) -> String {
        "lastUsedCategoryIds_\(groupId.uuidString)"
    }

    private func paymentMethodUsageKey(forGroupId groupId: UUID) -> String {
        "lastUsedPaymentMethodId_\(groupId.uuidString)"
    }

    private func chipRank(_ id: UUID, lastUsed: [UUID]) -> Int {
        lastUsed.firstIndex(of: id) ?? lastUsed.count
    }

    private func chipRank(_ id: UUID, lastUsed: UUID?) -> Int {
        id == lastUsed ? 0 : 1
    }

    func loadCategories(forGroupId groupId: UUID, lastUsedCategoryId: UUID? = nil) async {
        isLoading = true
        errorMessage = nil
        showError = false

        do {
            categories = try await fetchCategoriesUseCase.execute(forGroupId: groupId)
            if isEditMode {
                selectedCategory = categories.first { $0.id == itemListToEdit?.category?.id }
            } else {
                selectedCategory = nil
            }
            updateSuggestions()
        } catch {
            errorMessage = "Error al cargar categorías: \(error.localizedDescription)"
            showError = true
        }

        isLoading = false
    }

    func loadPaymentMethods(forGroupId groupId: UUID, lastUsedPaymentMethodId: UUID? = nil) async {
        isLoading = true
        errorMessage = nil
        showError = false

        do {
            paymentMethods = try await fetchPaymentMethodsUseCase.executeActive(forGroupId: groupId)
            if isEditMode {
                selectedPaymentMethod = paymentMethods.first { $0.id == itemListToEdit?.paymentMethod?.id }
            } else {
                selectedPaymentMethod = nil
            }
        } catch {
            errorMessage = "Error al cargar métodos de pago: \(error.localizedDescription)"
            showError = true
        }

        isLoading = false
    }

    func createItemList(
        description: String,
        date: Date,
        categoryId: UUID?,
        groupId: UUID,
        paymentMethodId: UUID?
    ) async -> SDItemList? {
        isLoading = true
        errorMessage = nil
        showError = false

        do {
            let trimmedDescription = description.trimmingCharacters(in: .whitespacesAndNewlines)
            let itemList: SDItemList

            switch entryStructure {
            case .singleEntry:
                guard let priceDecimal = priceAsDecimal, priceDecimal > 0 else {
                    errorMessage = "Añade un importe para crear el registro."
                    showError = true
                    isLoading = false
                    return nil
                }
                let isFuture = Calendar.current.startOfDay(for: date) > Calendar.current.startOfDay(for: Date())
                itemList = try await createSingleEntryUseCase.execute(
                    description: trimmedDescription,
                    amount: priceDecimal,
                    date: date,
                    categoryId: categoryId,
                    paymentMethodId: paymentMethodId,
                    groupId: groupId,
                    isPaid: !isFuture
                )
            case .itemizedList:
                itemList = try await createItemListUseCase.execute(
                    description: trimmedDescription,
                    isList: true,
                    date: date,
                    categoryId: categoryId,
                    paymentMethodId: paymentMethodId,
                    groupId: groupId
                )
            }

            clearUsageMemoryCache(forGroupId: groupId)
            isLoading = false
            return itemList
        } catch {
            errorMessage = "Error al crear gasto: \(error.localizedDescription)"
            showError = true
            isLoading = false
            return nil
        }
    }

    func updateItemList(groupId: UUID) async -> SDItemList? {
        guard let toEdit = itemListToEdit else { return nil }
        isLoading = true
        errorMessage = nil
        showError = false

        do {
            let updatedItemList: SDItemList

            switch entryStructure {
            case .singleEntry:
                guard let priceDecimal = priceAsDecimal, priceDecimal > 0 else {
                    errorMessage = "Añade un importe para guardar el registro."
                    showError = true
                    isLoading = false
                    return nil
                }

                updatedItemList = try await updateSingleEntryUseCase.execute(
                    itemList: toEdit,
                    description: resolvedDescriptionForSave(),
                    amount: priceDecimal,
                    date: date,
                    category: selectedCategory,
                    paymentMethod: selectedPaymentMethod,
                    group: selectedGroup ?? toEdit.group
                )
            case .itemizedList:
                toEdit.itemListDescription = resolvedDescriptionForSave()
                toEdit.setStructure(.itemizedList)
                toEdit.date = date
                toEdit.category = selectedCategory
                toEdit.paymentMethod = selectedPaymentMethod
                toEdit.group = selectedGroup ?? toEdit.group
                try await updateItemListUseCase.execute(toEdit)
                updatedItemList = toEdit
            }

            clearUsageMemoryCache(forGroupId: groupId)
            isLoading = false
            return updatedItemList
        } catch {
            errorMessage = "Error al actualizar: \(error.localizedDescription)"
            showError = true
            isLoading = false
            return nil
        }
    }

    func validateAndCorrectPrice() {
        price = correctPriceInput(price)
    }

    func pastePrice() {
        guard let raw = UIPasteboard.general.string else { return }
        price = correctPriceInput(raw)
    }

    // MARK: - Private Methods

    private func ensureAvailableGroupsLoaded() async {
        guard availableGroups.count <= 1 else { return }

        do {
            guard let currentUser = try await getCurrentUserUseCase.execute() else { return }
            let fetchedGroups = try await fetchGroupsForUserUseCase.execute(userId: currentUser.id)
            guard !fetchedGroups.isEmpty else { return }

            availableGroups = fetchedGroups

            if let selectedGroup,
               let refreshedSelectedGroup = fetchedGroups.first(where: { $0.id == selectedGroup.id }) {
                self.selectedGroup = refreshedSelectedGroup
            } else if let firstGroup = fetchedGroups.first {
                selectedGroup = firstGroup
            }
        } catch {
            // Keep the existing local groups if fetching all groups fails.
        }
    }

    private func correctPriceInput(_ input: String) -> String {
        HeroAmountInputSanitizer.sanitize(input)
    }

    private static func formattedPrice(_ amount: Double) -> String {
        guard amount != 0 else { return "" }
        return String(format: "%.2f", amount)
            .replacingOccurrences(of: "\\.?0+$", with: "", options: .regularExpression)
    }

    func updateSuggestions() {
        suggestions = ConceptSuggestionEngine.getSuggestions(
            query: description,
            amount: priceAsDecimal.map { Double(truncating: $0 as NSDecimalNumber) },
            forCategory: selectedCategory,
            allCategories: categories
        )
        lastUsedConcept = ConceptSuggestionEngine.lastUsed(forCategory: selectedCategory)
    }

    func updateConceptAssists() {
        updateSuggestions()
        applyPaymentMethodSuggestionForCurrentConcept()
    }

    func applySuggestion(_ suggestion: ConceptSuggestion, forGroupId groupId: UUID) {
        description = suggestion.description
        if suggestion.category.id != selectedCategory?.id {
            selectedCategory = suggestion.category
            recordCategoryUsage(suggestion.category, forGroupId: groupId)
        }
        updateConceptAssists()
    }

    private func applyPaymentMethodSuggestionForCurrentConcept() {
        guard !isEditMode, !didManuallyChoosePaymentMethod else { return }
        guard let selectedCategory else { return }

        let normalizedDescription = normalizedConcept(description)
        guard !normalizedDescription.isEmpty else { return }

        let matchingSnapshot = usageMemorySnapshots
            .filter {
                $0.categoryId == selectedCategory.id &&
                normalizedConcept($0.itemListDescription) == normalizedDescription
            }
            .max { $0.createdAt < $1.createdAt }

        guard let paymentMethodId = matchingSnapshot?.paymentMethodId else { return }

        selectedPaymentMethod = paymentMethods.first { $0.id == paymentMethodId }
        lastUsedPaymentMethodId = selectedPaymentMethod?.id
    }

    private func normalizedConcept(_ value: String) -> String {
        value
            .trimmingCharacters(in: .whitespacesAndNewlines)
            .folding(options: [.caseInsensitive, .diacriticInsensitive], locale: .current)
    }

    func clearError() {
        errorMessage = nil
        showError = false
    }
}
