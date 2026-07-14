import SwiftUI

struct PaymentMethodFormView: View {
    let group: SDGroup
    let methodToEdit: SDPaymentMethod?
    let onSaved: () -> Void

    @Environment(\.dismiss) private var dismiss
    @State private var viewModel = PaymentMethodFormViewModel()

    @State private var name = ""
    @State private var legacyType = "card_debit"
    @State private var selectedIcon = "creditcard.fill"
    @FocusState private var nameFocused: Bool?

    private let iconOptions = [
        "creditcard.fill", "banknote.fill", "arrow.left.arrow.right", "iphone",
        "dollarsign.circle.fill", "eurosign.circle.fill", "bag.fill", "gift.fill",
        "building.columns.fill", "qrcode", "wallet.pass.fill", "checkmark.seal.fill"
    ]
    private var isEditMode: Bool { methodToEdit != nil }
    private var resolvedType: String { inferredType(for: selectedIcon) ?? legacyType }
    private var selectedTint: Color { PaymentMethodAppearance.tint(for: selectedIcon) }
    private var selectedTintHex: String { PaymentMethodAppearance.tintHex(for: selectedIcon) }

    init(group: SDGroup, methodToEdit: SDPaymentMethod?, onSaved: @escaping () -> Void) {
        self.group = group
        self.methodToEdit = methodToEdit
        self.onSaved = onSaved

        _name = State(wrappedValue: methodToEdit?.name ?? "")
        _legacyType = State(wrappedValue: methodToEdit?.type ?? "card_debit")
        _selectedIcon = State(
            wrappedValue: {
                guard let methodToEdit else { return "creditcard.fill" }
                return PaymentMethodAppearance.icon(for: methodToEdit)
            }()
        )
    }

    var body: some View {
        ScrollView {
            VStack(spacing: 20) {
                CenteredEditorNameBlock(
                    icon: "textformat",
                    placeholder: LocalizationKey.Payment.name.localized,
                    text: $name,
                    maxLength: 30,
                    focusedField: $nameFocused,
                    fieldValue: true
                ) {
                    ZStack {
                        Circle()
                            .fill(selectedTint.opacity(0.15))
                            .frame(width: 72, height: 72)
                        Image(systemName: selectedIcon)
                            .font(.system(size: 28, weight: .medium))
                            .foregroundStyle(selectedTint)
                    }
                    .animation(AnimationHelper.quickSpring, value: selectedIcon)
                }

                VStack(alignment: .leading, spacing: 10) {
                    Text(LocalizationKey.Payment.icon.localized)
                        .font(.subheadline.weight(.semibold))
                        .foregroundStyle(.secondary)
                        .padding(.horizontal, 4)

                    LazyVGrid(columns: Array(repeating: GridItem(.flexible()), count: 4), spacing: 10) {
                        ForEach(iconOptions, id: \.self) { icon in
                            Button {
                                withAnimation(AnimationHelper.quickSpring) { selectedIcon = icon }
                            } label: {
                                ZStack {
                                    RoundedRectangle(cornerRadius: 10)
                                        .fill(selectedIcon == icon ? selectedTint : Color(.tertiarySystemGroupedBackground))
                                        .frame(height: 44)
                                    Image(systemName: icon)
                                        .font(.system(size: 16, weight: .medium))
                                        .foregroundStyle(selectedIcon == icon ? .white : .secondary)
                                }
                            }
                            .buttonStyle(.plain)
                        }
                    }
                    .padding(AppConstants.UserInterface.padding)
                    .background(Color(.secondarySystemGroupedBackground))
                    .clipShape(RoundedRectangle(cornerRadius: AppConstants.UserInterface.rowCornerRadius))
                }
            }
            .padding(AppConstants.UserInterface.padding)
        }
        .scrollDismissesKeyboard(.immediately)
        .background(Color(.systemGroupedBackground))
        .navigationTitle(isEditMode ? LocalizationKey.Payment.editMethod.localized : LocalizationKey.Payment.newMethod.localized)
        .navigationBarTitleDisplayMode(.inline)
        .errorAlert(
            isPresented: $viewModel.showError,
            message: viewModel.errorMessage,
            onDismiss: viewModel.clearError
        )
        .toolbar {
            ToolbarItem(placement: .cancellationAction) {
                Button { dismiss() } label: {
                    Image(systemName: "xmark")
                }
            }
            ToolbarItem(placement: .confirmationAction) {
                PrimaryToolbarCheckButton(isDisabled: name.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty || viewModel.isLoading) {
                    Task { await save() }
                }
            }
        }
    }

    private func save() async {
        let trimmed = name.trimmingCharacters(in: .whitespacesAndNewlines)
        guard !trimmed.isEmpty else { return }

        if await viewModel.save(
            name: trimmed,
            type: resolvedType,
            icon: selectedIcon,
            color: selectedTintHex,
            groupId: group.id,
            methodToEdit: methodToEdit
        ) {
            onSaved()
            dismiss()
        }
    }

    private func inferredType(for icon: String) -> String? {
        switch icon {
        case "banknote.fill", "dollarsign.circle.fill", "eurosign.circle.fill":
            return "cash"
        case "arrow.left.arrow.right":
            return "bank_transfer"
        case "iphone", "wallet.pass.fill":
            return "card_credit"
        case "creditcard.fill":
            return "card_debit"
        default:
            // Keep the stored type for icons that can belong to many real-world origins.
            return nil
        }
    }
}
