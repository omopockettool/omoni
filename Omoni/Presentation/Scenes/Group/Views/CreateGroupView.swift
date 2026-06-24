import SwiftUI

struct CreateGroupView: View {
    @Environment(\.dismiss) private var dismiss

    let userId: UUID
    let onGroupCreated: (SDGroup) -> Void

    @State private var viewModel = GroupFormViewModel()
    @State private var groupName = ""
    @State private var selectedCurrency = "EUR"
    @FocusState private var groupNameFocused: Bool?

    private var availableCurrencies: [(String, String)] {
        [
            ("EUR", LocalizationKey.Group.currencyEuro.localized),
            ("USD", LocalizationKey.Group.currencyDollar.localized)
        ]
    }

    var body: some View {
        NavigationStack {
            ScrollView {
                VStack(alignment: .leading, spacing: 20) {
                    LimitedTextField(
                        icon: "person.2.fill",
                        placeholder: LocalizationKey.Group.name.localized,
                        text: $groupName,
                        maxLength: AppConstants.Validation.maxGroupNameLength,
                        focusedField: $groupNameFocused,
                        fieldValue: true
                    )
                    .textInputAutocapitalization(.words)

                    VStack(alignment: .leading, spacing: 10) {
                        sectionHeader(LocalizationKey.Group.currency.localized)

                        NativeSettingsCard {
                            ForEach(Array(availableCurrencies.enumerated()), id: \.element.0) { index, currency in
                                Button {
                                    withAnimation(AnimationHelper.quickSpring) { selectedCurrency = currency.0 }
                                } label: {
                                    currencyRow(code: currency.0, label: currency.1)
                                        .padding(AppConstants.UserInterface.padding)
                                }
                                .buttonStyle(.plain)

                                if index < availableCurrencies.count - 1 {
                                    Divider()
                                        .padding(.leading, AppConstants.UserInterface.padding)
                                }
                            }
                        }
                    }
                }
                .padding(AppConstants.UserInterface.padding)
            }
            .background(Color(.systemGroupedBackground))
            .navigationTitle(LocalizationKey.Group.create.localized)
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .cancellationAction) {
                    Button { dismiss() } label: {
                        Image(systemName: "xmark")
                    }
                    .disabled(viewModel.isLoading)
                }
                ToolbarItem(placement: .confirmationAction) {
                    PrimaryToolbarCheckButton(isDisabled: groupName.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty || viewModel.isLoading) {
                        Task { await createGroup() }
                    }
                }
            }
            .disabled(viewModel.isLoading)
        }
        .errorAlert(
            isPresented: $viewModel.showError,
            message: viewModel.errorMessage,
            onDismiss: viewModel.clearError
        )
    }

    private func sectionHeader(_ title: String) -> some View {
        Text(title)
            .font(.subheadline.weight(.semibold))
            .foregroundStyle(.secondary)
            .padding(.horizontal, 4)
    }

    private func currencyRow(code: String, label: String) -> some View {
        HStack {
            Text(label)
                .foregroundStyle(.primary)
            Spacer()
            if selectedCurrency == code {
                Image(systemName: "checkmark")
                    .font(.body.weight(.semibold))
                    .foregroundStyle(Color.accentColor)
            }
        }
        .contentShape(Rectangle())
    }

    private func createGroup() async {
        let trimmed = groupName.trimmingCharacters(in: .whitespacesAndNewlines)
        guard !trimmed.isEmpty else { return }
        if let group = await viewModel.create(name: trimmed, currency: selectedCurrency, userId: userId) {
            onGroupCreated(group)
            dismiss()
        }
    }
}

// MARK: - Preview
#Preview {
    CreateGroupView(userId: UUID(), onGroupCreated: { _ in })
}
