import SwiftUI

struct AddItemListView: View {
    let group: SDGroup
    let showsCancelButton: Bool
    var onRequestExpandSheet: (() -> Void)? = nil
    let onItemListCreated: (SDItemList) -> Void
    let onItemListUpdated: ((SDItemList) -> Void)?
    let onCancel: () -> Void

    @State private var viewModel: AddItemListViewModel
    @FocusState private var focusedField: AddItemListField?
    @State private var showDatePicker = false
    @State private var calendarExpanded = false
    @State private var suppressCalendarExpand = false
    @State private var showDetails = false
    @State private var showCategoryOverflow = false
    @State private var showPaymentMethodOverflow = false
    @State private var scrollToPaymentMethods = false
    @State private var scrollToHero = false

    init(
        group: SDGroup,
        availableGroups: [SDGroup] = [],
        itemListToEdit: SDItemList? = nil,
        initialDate: Date? = nil,
        preferredCategoryId: UUID? = nil,
        showsCancelButton: Bool = true,
        onRequestExpandSheet: (() -> Void)? = nil,
        onItemListCreated: @escaping (SDItemList) -> Void,
        onItemListUpdated: ((SDItemList) -> Void)? = nil,
        onCancel: @escaping () -> Void
    ) {
        self.showsCancelButton = showsCancelButton
        self.onRequestExpandSheet = onRequestExpandSheet
        self.group = group
        self.onItemListCreated = onItemListCreated
        self.onItemListUpdated = onItemListUpdated
        self.onCancel = onCancel
        let initialViewModel = AddItemListViewModel(
            itemListToEdit: itemListToEdit,
            initialDate: initialDate,
            preferredCategoryId: preferredCategoryId
        )
        initialViewModel.configure(defaultGroup: group, availableGroups: availableGroups)
        let startsExpandedForEdit = initialViewModel.isEditMode
        let startsWithDatePicker = startsExpandedForEdit && !Calendar.current.isDateInToday(initialViewModel.date)
        self._viewModel = State(
            wrappedValue: initialViewModel
        )
        self._showDetails = State(initialValue: startsExpandedForEdit)
        self._showDatePicker = State(initialValue: startsWithDatePicker)
        self._suppressCalendarExpand = State(initialValue: startsWithDatePicker)
    }

    // MARK: - Computed

    private var activeGroup: SDGroup { viewModel.selectedGroup ?? group }

    private static let gridCategoryLimit = 3
    private static let gridPaymentMethodLimit = 3

    private var gridCategories: [SDCategory] {
        viewModel.categories.prefix(Self.gridCategoryLimit).map { $0 }
    }

    private var overflowCategories: [SDCategory] {
        Array(viewModel.categories.dropFirst(Self.gridCategoryLimit))
    }

    private var displayedCategories: [SDCategory] {
        showCategoryOverflow ? viewModel.categories : gridCategories
    }

    private var gridPaymentMethods: [SDPaymentMethod] {
        viewModel.paymentMethods.prefix(Self.gridPaymentMethodLimit).map { $0 }
    }

    private var overflowPaymentMethods: [SDPaymentMethod] {
        Array(viewModel.paymentMethods.dropFirst(Self.gridPaymentMethodLimit))
    }

    private var displayedPaymentMethods: [SDPaymentMethod] {
        showPaymentMethodOverflow ? viewModel.paymentMethods : gridPaymentMethods
    }

    private var categoryChipMinHeight: CGFloat {
        (showDetails || showCategoryOverflow) ? 44 : 88
    }

    private var categoryChipCornerRadius: CGFloat {
        (showDetails || showCategoryOverflow) ? 12 : 16
    }

    private var currencySymbol: String {
        let formatter = NumberFormatter()
        formatter.numberStyle = .currency
        formatter.currencyCode = activeGroup.currency
        formatter.locale = Locale(identifier: "en_US")
        return formatter.currencySymbol
    }

    private var descriptionPlaceholder: String {
        if let concept = viewModel.lastUsedConcept {
            return concept
        }
        if let category = viewModel.selectedCategory {
            return "\(LocalizationKey.Entry.concept.localized) (\(LocalizationKey.General.eg.localized) \(category.name))"
        }
        return LocalizationKey.Entry.concept.localized
    }

    // MARK: - Body

    var body: some View {
        ScrollViewReader { proxy in
        ScrollView {
            VStack(spacing: 20) {
                entryStructureSection
                topCard
                    .id("heroAnchor")
                if !viewModel.categories.isEmpty {
                    categoryGridSection
                }
                moreDetailsSection
            }
            .padding(AppConstants.UserInterface.padding)
            .padding(.bottom, 8)
        }

        .onChange(of: scrollToPaymentMethods) { _, fire in
            guard fire else { return }
            scrollToPaymentMethods = false
            Task {
                try? await Task.sleep(for: .milliseconds(350))
                withAnimation(.spring(response: 0.45, dampingFraction: 0.82)) {
                    proxy.scrollTo("paymentMethodAnchor", anchor: .top)
                }
            }
        }
        .onChange(of: scrollToHero) { _, fire in
            guard fire else { return }
            scrollToHero = false
            withAnimation(.spring(response: 0.45, dampingFraction: 0.82)) {
                proxy.scrollTo("heroAnchor", anchor: .top)
            }
        }

        } // ScrollViewReader
        .scrollDisabled(!showDetails && !viewModel.isEditMode && !showCategoryOverflow && !showPaymentMethodOverflow)
        .background(Color(.systemGroupedBackground))
        .navigationTitle(viewModel.isEditMode ? LocalizationKey.Entry.edit.localized : LocalizationKey.Entry.newEntry.localized)
        .navigationBarTitleDisplayMode(.inline)
        .toolbar {
            if showsCancelButton {
                ToolbarItem(placement: .cancellationAction) {
                    Button { onCancel() } label: {
                        Image(systemName: "xmark")
                    }
                }
            }
            ToolbarItem(placement: .confirmationAction) {
                PrimaryToolbarCheckButton {
                    if viewModel.canSave {
                        Task { await saveItemList() }
                    } else {
                        viewModel.showValidationToast()
                    }
                }
            }
        }
        .toolbar {
            ToolbarItemGroup(placement: .keyboard) {
                Button(action: moveFocusBackward) {
                    Image(systemName: "chevron.up")
                }
                .disabled(!canMoveFocusBackward)

                Button(action: moveFocusForward) {
                    Image(systemName: "chevron.down")
                }
                .disabled(!canMoveFocusForward)

                Spacer()

                Button(LocalizationKey.General.done.localized) { focusedField = nil }
            }
        }
        .onChange(of: focusedField) { _, newField in
            if newField != nil { onRequestExpandSheet?() }
            if newField == .price { scrollToHero = true }
        }
        .onChange(of: viewModel.entryStructure) { _, structure in
            if structure == .singleEntry {
                scrollToHero = true
            } else if focusedField == .price {
                focusedField = nil
            }
        }
        .onChange(of: showDetails) { _, isShowing in
            if isShowing { onRequestExpandSheet?() }
        }
        .errorAlert(
            isPresented: $viewModel.showError,
            message: viewModel.errorMessage,
            onDismiss: viewModel.clearError
        )
        .task(id: activeGroup.id) {
            await viewModel.loadOptionsForSelectedGroup()
        }
        .toast($viewModel.toast)
    }

    private var canMoveFocusBackward: Bool {
        switch focusedField {
        case .description:
            return viewModel.showsHeroAmountInput
        default:
            return false
        }
    }

    private var canMoveFocusForward: Bool {
        switch focusedField {
        case .price:
            return viewModel.showsHeroAmountInput
        default:
            return false
        }
    }

    private func moveFocusBackward() {
        switch focusedField {
        case .description:
            guard viewModel.showsHeroAmountInput else { return }
            focusedField = .price
        default:
            break
        }
    }

    private func moveFocusForward() {
        switch focusedField {
        case .price:
            focusedField = .description
        default:
            break
        }
    }

    // MARK: - Top Card (Concept + Amount)

    private var entryStructureSection: some View {
        AddItemListStructureSection(
            selection: viewModel.entryStructure,
            canConvertToSingleEntry: viewModel.canConvertToSingleEntry,
            helperText: viewModel.structureHelperText,
            onSelect: { structure in
                withAnimation(AnimationHelper.quickSpring) {
                    viewModel.updateEntryStructure(to: structure)
                }
            }
        )
    }

    private var topCard: some View {
        AddItemListTopCard(
            showsHeroAmountInput: viewModel.showsHeroAmountInput,
            usesExpandedDescriptionLayout: viewModel.usesExpandedDescriptionLayout,
            price: $viewModel.price,
            currencySymbol: currencySymbol,
            descriptionPlaceholder: descriptionPlaceholder,
            description: $viewModel.description,
            suggestions: viewModel.suggestions,
            focusedField: $focusedField,
            onValidate: viewModel.validateAndCorrectPrice,
            onPaste: viewModel.pastePrice,
            onSuggestionSelected: { viewModel.applySuggestion($0, forGroupId: activeGroup.id) }
        )
    }

    // MARK: - Category Grid

    private var categoryGridSection: some View {
        AddItemListCategorySection(
            displayedCategories: displayedCategories,
            overflowCategories: overflowCategories,
            showOverflow: $showCategoryOverflow,
            compact: showDetails || showCategoryOverflow,
            selectedCategoryID: viewModel.selectedCategory?.id,
            chipMinHeight: categoryChipMinHeight,
            chipCornerRadius: categoryChipCornerRadius
        ) { category in
            withAnimation(AnimationHelper.quickSpring) {
                viewModel.selectedCategory = category
                showCategoryOverflow = false
            }
        }
    }

    // MARK: - More Details Section

    private var moreDetailsSection: some View {
        AddItemListMoreDetailsSection(
            isEditMode: viewModel.isEditMode,
            showDetails: $showDetails,
            onCollapse: {
                showDatePicker = false
                calendarExpanded = false
            }
        ) {
            dateCard
            groupCard

            if !viewModel.paymentMethods.isEmpty {
                paymentMethodGridSection
            }

            Color.clear
                .frame(height: 1)
                .id("moreDetailsAnchor")
        }
    }

    // MARK: - Payment Method Grid

    private var paymentMethodGridSection: some View {
        AddItemListPaymentMethodSection(
            displayedPaymentMethods: displayedPaymentMethods,
            overflowPaymentMethods: overflowPaymentMethods,
            showOverflow: $showPaymentMethodOverflow,
            selectedPaymentMethodID: viewModel.selectedPaymentMethod?.id,
            colorForType: paymentMethodColor,
            iconForMethod: paymentMethodIcon,
            onSelect: { method in
                withAnimation(AnimationHelper.quickSpring) {
                    viewModel.selectedPaymentMethod = method
                    showPaymentMethodOverflow = false
                    scrollToPaymentMethods = true
                }
            },
            onToggleOffSelected: {
                withAnimation(AnimationHelper.quickSpring) {
                    viewModel.deselectPaymentMethodManually()
                    showPaymentMethodOverflow = false
                    scrollToPaymentMethods = true
                }
            },
            onCollapseOverflow: { scrollToPaymentMethods = true }
        )
    }

    // MARK: - Date Card

    private var dateCard: some View {
        AddItemListDateCard(
            showDatePicker: $showDatePicker,
            calendarExpanded: $calendarExpanded,
            date: $viewModel.date,
            formattedDate: viewModel.formattedDate,
            focusedField: $focusedField
        ) { on in
            if on {
                if suppressCalendarExpand {
                    suppressCalendarExpand = false
                } else {
                    withAnimation(.spring(response: 0.5, dampingFraction: 0.85)) {
                        calendarExpanded = true
                    }
                }
            } else {
                withAnimation(.spring(response: 0.45, dampingFraction: 0.88)) {
                    calendarExpanded = false
                }
                Task {
                    try? await Task.sleep(for: .milliseconds(400))
                    viewModel.date = Date()
                }
            }
        }
    }

    // MARK: - Group Card

    private var groupCard: some View {
        AddItemListGroupCard(
            activeGroup: activeGroup,
            availableGroups: viewModel.availableGroups,
            onSelect: { viewModel.selectedGroup = $0 }
        )
    }

    // MARK: - Payment Method Helpers

    private func paymentMethodColor(_ type: String) -> Color {
        switch type {
        case "cash":          return .green
        case "bank_transfer": return .orange
        case "card_credit":   return .purple
        default:              return .blue
        }
    }

    private func paymentMethodIcon(_ method: SDPaymentMethod) -> String {
        method.icon.isEmpty ? defaultIcon(for: method.type) : method.icon
    }

    private func defaultIcon(for type: String) -> String {
        switch type {
        case "cash":          return "banknote.fill"
        case "bank_transfer": return "arrow.left.arrow.right"
        case "card_credit":   return "creditcard.fill"
        default:              return "creditcard.fill"
        }
    }

    // MARK: - Actions

    private func saveItemList() async {
        let finalDescription = viewModel.resolvedDescriptionForSave()

        if viewModel.isEditMode {
            if let updated = await viewModel.updateItemList(groupId: activeGroup.id) {
                onItemListUpdated?(updated)
            }
        } else {
            if let created = await viewModel.createItemList(
                description: finalDescription,
                date: viewModel.date,
                categoryId: viewModel.selectedCategory?.id,
                groupId: activeGroup.id,
                paymentMethodId: viewModel.selectedPaymentMethod?.id
            ) {
                onItemListCreated(created)
            }
        }
    }
}


#Preview {
    let group = SDGroup.mock(name: "Casa", currency: "EUR")
    NavigationStack {
        AddItemListView(
            group: group,
            onItemListCreated: { _ in },
            onCancel: { }
        )
    }
}
