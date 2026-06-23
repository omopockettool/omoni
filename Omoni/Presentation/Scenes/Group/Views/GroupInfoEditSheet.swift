import SwiftUI

struct GroupInfoEditSheet: View {
    let group: SDGroup
    let onSaved: () -> Void

    @Environment(\.dismiss) private var dismiss
    @State private var viewModel = GroupFormViewModel()
    @State private var name = ""
    @State private var selectedCurrency = "EUR"
    @FocusState private var nameFocused: Bool?

    private var availableCurrencies: [(String, String)] {
        [
            ("EUR", LocalizationKey.Group.currencyEuro.localized),
            ("USD", LocalizationKey.Group.currencyDollar.localized)
        ]
    }

    init(group: SDGroup, onSaved: @escaping () -> Void) {
        self.group = group
        self.onSaved = onSaved

        _name = State(wrappedValue: group.name)
        _selectedCurrency = State(wrappedValue: group.currency)
    }

    var body: some View {
        NavigationStack {
            ScrollView {
                VStack(alignment: .leading, spacing: 20) {
                    LimitedTextField(
                        icon: "person.2.fill",
                        placeholder: LocalizationKey.Group.name.localized,
                        text: $name,
                        maxLength: AppConstants.Validation.maxGroupNameLength,
                        focusedField: $nameFocused,
                        fieldValue: true
                    )

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
            .navigationTitle(LocalizationKey.Group.info.localized)
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .cancellationAction) {
                    Button { dismiss() } label: {
                        Image(systemName: "xmark")
                    }
                    .disabled(viewModel.isLoading)
                }
                ToolbarItem(placement: .confirmationAction) {
                    PrimaryToolbarCheckButton(isDisabled: name.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty || viewModel.isLoading) {
                        Task { await save() }
                    }
                }
            }
            .disabled(viewModel.isLoading)
        }
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

    private func save() async {
        let trimmed = name.trimmingCharacters(in: .whitespacesAndNewlines)
        guard !trimmed.isEmpty else { return }

        if await viewModel.update(group: group, name: trimmed, currency: selectedCurrency) {
            onSaved()
            dismiss()
        }
    }
}
