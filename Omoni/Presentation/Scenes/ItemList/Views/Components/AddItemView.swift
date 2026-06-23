import SwiftUI

enum AddItemField {
    case description
    case amount
    case quantity
}

struct AddItemView: View {
    private let compactDetent: PresentationDetent = .fraction(0.58)
    private let subtotalDetent: PresentationDetent = .fraction(0.66)

    let onItemSaved: (SDItem) -> Void
    let currencyCode: String
    let itemListDescription: String

    @Environment(\.dismiss) private var dismiss
    @State private var viewModel: AddItemViewModel
    @FocusState private var focusedField: AddItemField?
    @State private var displayedSubtotal: String = ""
    @State private var subtotalIsDecreasing: Bool = false
    @State private var selectedDetent: PresentationDetent = .fraction(0.58)

    init(
        itemListId: UUID,
        itemToEdit: SDItem? = nil,
        itemListDescription: String,
        currencyCode: String = "EUR",
        onItemSaved: @escaping (SDItem) -> Void,
        createItemUseCase: CreateItemUseCase,
        updateItemUseCase: UpdateItemUseCase
    ) {
        self.onItemSaved = onItemSaved
        self.currencyCode = currencyCode
        self.itemListDescription = itemListDescription
        self._viewModel = State(wrappedValue: AddItemViewModel(
            itemListId: itemListId,
            itemToEdit: itemToEdit,
            itemListDescription: itemListDescription,
            createItemUseCase: createItemUseCase,
            updateItemUseCase: updateItemUseCase
        ))
    }

    private var currencySymbol: String {
        let formatter = NumberFormatter()
        formatter.numberStyle = .currency
        formatter.currencyCode = currencyCode
        formatter.locale = Locale(identifier: "en_US")
        return formatter.currencySymbol
    }

    private var quantityValue: Int { ValidationHelper.itemQuantityValue(from: viewModel.quantity) ?? 1 }

    private var subtotalAmount: String {
        let normalized = viewModel.amount.replacingOccurrences(of: ",", with: ".")
        guard let price = Decimal(string: normalized), price > 0, quantityValue > 1 else { return "" }
        let total = price * Decimal(quantityValue)
        return String(format: "%.2f", NSDecimalNumber(decimal: total).doubleValue) + " " + currencySymbol
    }

    private var subtotalFormula: String {
        guard quantityValue > 1 else { return "" }
        return "\(viewModel.amount) \(currencySymbol) × \(quantityValue) \(LocalizationKey.Item.units.localized)"
    }

    var body: some View {
        NavigationStack {
            ScrollView {
                VStack(spacing: 20) {
                    descriptionCard
                    heroAmountInput
                    quantityStepper
                    if viewModel.showsTotalPreview {
                        subtotalCard
                    }
                }
                .padding(AppConstants.UserInterface.padding)
                .padding(.bottom, 8)
            }
            .background(Color(.systemGroupedBackground))
            .navigationTitle(viewModel.isEditMode ? LocalizationKey.Item.editItem.localized : LocalizationKey.Item.newItem.localized)
            .navigationBarTitleDisplayMode(.inline)
            .presentationDetents([compactDetent, subtotalDetent, .large], selection: $selectedDetent)
            .presentationDragIndicator(.visible)
            .errorAlert(
                isPresented: $viewModel.showError,
                message: viewModel.errorMessage,
                onDismiss: viewModel.clearError
            )
            .onAppear {
                selectedDetent = viewModel.showsTotalPreview ? subtotalDetent : compactDetent
            }
            .onChange(of: focusedField) { oldValue, newValue in
                guard oldValue == .quantity, newValue != .quantity else { return }
                viewModel.normalizeQuantityInputAfterEditing()
            }
            .onChange(of: viewModel.showsTotalPreview) { _, showsPreview in
                withAnimation(AnimationHelper.quickSpring) {
                    selectedDetent = showsPreview ? subtotalDetent : compactDetent
                }
            }
            .toolbar {
                ToolbarItem(placement: .cancellationAction) {
                    Button { dismiss() } label: { Image(systemName: "xmark") }
                }
                ToolbarItem(placement: .confirmationAction) {
                    PrimaryToolbarCheckButton(isDisabled: !viewModel.canSave) {
                        Task {
                            if let item = await viewModel.saveItem() {
                                onItemSaved(item)
                                dismiss()
                            }
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
        }
    }

    private var canMoveFocusBackward: Bool {
        switch focusedField {
        case .amount, .quantity:
            return true
        default:
            return false
        }
    }

    private var canMoveFocusForward: Bool {
        switch focusedField {
        case .description, .amount:
            return true
        default:
            return false
        }
    }

    private func moveFocusBackward() {
        switch focusedField {
        case .amount:
            focusedField = .description
        case .quantity:
            focusedField = .amount
        default:
            break
        }
    }

    private func moveFocusForward() {
        switch focusedField {
        case .description:
            focusedField = .amount
        case .amount:
            focusedField = .quantity
        default:
            break
        }
    }

    private var heroAmountInput: some View {
        HeroAmountInputView(
            text: $viewModel.amount,
            currencySymbol: currencySymbol,
            onValidate: viewModel.validateAndCorrectAmount,
            focusedField: $focusedField,
            fieldValue: .amount
        )
    }

    private var descriptionCard: some View {
        LimitedTextField(
            icon: "textformat",
            placeholder: itemListDescription,
            text: $viewModel.description,
            maxLength: AppConstants.Validation.maxItemDescriptionLength,
            axis: .horizontal,
            submitLabel: .done,
            onSubmit: { focusedField = nil },
            focusedField: $focusedField,
            fieldValue: .description
        )
    }

    private var quantityBinding: Binding<Int> {
        Binding(
            get: { ValidationHelper.itemQuantityValue(from: viewModel.quantity) ?? AppConstants.Validation.minItemQuantity },
            set: { viewModel.setQuantity($0) }
        )
    }

    private var quantityTextBinding: Binding<String> {
        Binding(
            get: { viewModel.quantity },
            set: { viewModel.quantity = viewModel.sanitizeQuantityInput($0) }
        )
    }

    private var quantityTextFont: Font {
        .subheadline.weight(.semibold)
    }

    private var quantityStepper: some View {
        VStack(alignment: .leading, spacing: 10) {
            Text(LocalizationKey.Item.quantity.localized)
                .font(.subheadline)
                .fontWeight(.semibold)
                .foregroundStyle(.secondary)
                .padding(.horizontal, 4)

            HStack(spacing: 12) {
                HStack(spacing: 12) {
                    Image(systemName: "number")
                        .foregroundStyle(.secondary)
                        .frame(width: 20)

                    quantityInputDisplay
                }
                .frame(maxWidth: .infinity, alignment: .leading)
                .contentShape(Rectangle())
                .onTapGesture { focusedField = .quantity }

                Stepper(
                    "",
                    value: quantityBinding,
                    in: AppConstants.Validation.minItemQuantity...AppConstants.Validation.maxItemQuantity
                )
                    .labelsHidden()
                    .fixedSize()
            }
            .padding(AppConstants.UserInterface.padding)
            .background(Color(.secondarySystemGroupedBackground))
            .clipShape(RoundedRectangle(cornerRadius: AppConstants.UserInterface.cornerRadius))
            .overlay(
                RoundedRectangle(cornerRadius: AppConstants.UserInterface.cornerRadius)
                    .stroke(Color(.systemGray5), lineWidth: 1)
            )
        }
    }

    private var quantityInputDisplay: some View {
        ZStack(alignment: .leading) {
            Text(viewModel.quantity.isEmpty ? "1" : viewModel.quantity)
                .font(quantityTextFont)
                .monospacedDigit()
                .foregroundStyle(viewModel.quantity.isEmpty ? Color(.tertiaryLabel) : .primary)

            TextField("", text: quantityTextBinding)
                .keyboardType(.numberPad)
                .font(quantityTextFont)
                .monospacedDigit()
                .foregroundStyle(.clear)
                .tint(Color.accentColor)
                .focused($focusedField, equals: .quantity)
        }
        .frame(maxWidth: .infinity, alignment: .leading)
    }

    private var subtotalCard: some View {
        VStack(alignment: .leading, spacing: 8) {
            HStack(alignment: .firstTextBaseline) {
                Text(LocalizationKey.Item.subtotal.localized)
                    .font(.caption)
                    .fontWeight(.semibold)
                    .foregroundStyle(.secondary)
                Spacer()
                Text(subtotalFormula)
                    .font(.caption)
                    .foregroundStyle(.tertiary)
            }

            Text(displayedSubtotal.isEmpty ? subtotalAmount : displayedSubtotal)
                .font(.system(size: 34, weight: .bold, design: .rounded))
                .foregroundStyle(.primary)
                .minimumScaleFactor(0.5)
                .lineLimit(1)
                .contentTransition(.numericText(countsDown: subtotalIsDecreasing))
                .animation(AnimationHelper.feedbackSpring, value: displayedSubtotal)
                .frame(maxWidth: .infinity, alignment: .center)
        }
        .padding(AppConstants.UserInterface.padding)
        .background(Color(.secondarySystemGroupedBackground))
        .clipShape(RoundedRectangle(cornerRadius: AppConstants.UserInterface.cornerRadius))
        .transition(.opacity.combined(with: .scale(scale: 0.96, anchor: .top)))
        .onAppear { displayedSubtotal = subtotalAmount }
        .onChange(of: subtotalAmount) { _, newValue in
            let oldDigits = Int(displayedSubtotal.filter(\.isNumber)) ?? 0
            let newDigits = Int(newValue.filter(\.isNumber)) ?? 0
            subtotalIsDecreasing = newDigits < oldDigits
            withAnimation(AnimationHelper.feedbackSpring) {
                displayedSubtotal = newValue
            }
        }
    }
}
