import SwiftUI

struct CategoryFormView: View {
    private struct LimitFrequencyOption: Identifiable {
        let value: String
        let titleKey: String

        var id: String { value }
    }

    private enum Field: Hashable {
        case name
        case limit
    }

    let group: SDGroup
    let categoryToEdit: SDCategory?
    let onSaved: (SDCategory) -> Void

    @Environment(\.dismiss) private var dismiss
    @State private var viewModel = CategoryFormViewModel()

    @State private var name = ""
    @State private var selectedColor = "#0A84FF"
    @State private var selectedIcon = "tag.fill"
    @State private var limitText = ""
    @State private var selectedLimitFrequency = BudgetHelper.LimitFrequency.monthly.rawValue
    @FocusState private var focusedField: Field?

    private var isEditMode: Bool { categoryToEdit != nil }
    private var hasActiveLimit: Bool { normalizedLimit != nil }
    private var selectedTint: Color { Color(hex: selectedColor) ?? .accentColor }
    private var normalizedLimit: Decimal? {
        Decimal(string: limitText.replacingOccurrences(of: ",", with: "."))
            .flatMap { $0 > 0 ? $0 : nil }
    }

    private let colorOptions = [
        "#FF453A", "#FF9F0A", "#FFD60A", "#30D158",
        "#0A84FF", "#5E5CE6", "#BF5AF2", "#FF375F",
        "#64D2FF", "#FF6B35", "#4ECDC4", "#95A5A6"
    ]

    private let iconOptions = [
        "cart.fill", "fork.knife", "car.fill", "house.fill",
        "gamecontroller.fill", "tshirt.fill", "heart.fill", "book.fill",
        "airplane", "bus.fill", "pill.fill", "dog.fill",
        "music.note", "dumbbell.fill", "bag.fill", "gift.fill",
        "tag.fill", "star.fill", "bolt.fill", "leaf.fill",
        "cup.and.saucer.fill", "tv.fill", "phone.fill", "wifi"
    ]

    private let limitFrequencyOptions: [LimitFrequencyOption] = [
        LimitFrequencyOption(value: BudgetHelper.LimitFrequency.daily.rawValue, titleKey: LocalizationKey.General.daily),
        LimitFrequencyOption(value: BudgetHelper.LimitFrequency.weekly.rawValue, titleKey: LocalizationKey.General.weekly),
        LimitFrequencyOption(value: BudgetHelper.LimitFrequency.monthly.rawValue, titleKey: LocalizationKey.General.monthly)
    ]

    init(group: SDGroup, categoryToEdit: SDCategory?, onSaved: @escaping (SDCategory) -> Void) {
        self.group = group
        self.categoryToEdit = categoryToEdit
        self.onSaved = onSaved

        _name = State(wrappedValue: categoryToEdit?.name ?? "")
        _selectedColor = State(wrappedValue: categoryToEdit?.color ?? "#0A84FF")
        _selectedIcon = State(wrappedValue: categoryToEdit?.icon ?? "tag.fill")
        _limitText = State(wrappedValue: categoryToEdit?.limit.map {
            $0 == $0.rounded() ? String(format: "%.0f", $0) : String(format: "%.2f", $0)
        } ?? "")
        _selectedLimitFrequency = State(
            wrappedValue: Self.allowedLimitFrequencyValues.contains(categoryToEdit?.limitFrequency ?? "")
                ? (categoryToEdit?.limitFrequency ?? BudgetHelper.LimitFrequency.monthly.rawValue)
                : BudgetHelper.LimitFrequency.monthly.rawValue
        )
    }

    private static let allowedLimitFrequencyValues: Set<String> = [
        BudgetHelper.LimitFrequency.daily.rawValue,
        BudgetHelper.LimitFrequency.weekly.rawValue,
        BudgetHelper.LimitFrequency.monthly.rawValue
    ]

    private let colorGridColumns = Array(repeating: GridItem(.flexible(), spacing: 10), count: 6)
    private let iconGridColumns = Array(repeating: GridItem(.flexible(), spacing: 10), count: 4)

    var body: some View {
        ScrollViewReader { proxy in
            ScrollView {
                VStack(spacing: 20) {
                    LimitedTextField(
                        icon: "textformat",
                        placeholder: LocalizationKey.Category.name.localized,
                        text: $name,
                        maxLength: 20,
                        focusedField: $focusedField,
                        fieldValue: .name
                    )
                    .textInputAutocapitalization(.words)

                    appearanceCard

                    limitCard
                        .id(Field.limit)
                }
                .padding(AppConstants.UserInterface.padding)
            }
            .scrollDismissesKeyboard(.interactively)
            .background(Color(.systemGroupedBackground))
            .navigationTitle(isEditMode ? LocalizationKey.Category.edit.localized : LocalizationKey.Category.new.localized)
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
                ToolbarItemGroup(placement: .keyboard) {
                    Spacer()

                    Button(LocalizationKey.General.done.localized) {
                        focusedField = nil
                    }
                }
            }
            .animation(AnimationHelper.quickEase, value: hasActiveLimit)
            .onAppear {
                if !isEditMode {
                    focusedField = .name
                }
            }
            .onChange(of: focusedField) { _, newField in
                guard newField == .limit else { return }

                withAnimation(AnimationHelper.quickEase) {
                    proxy.scrollTo(Field.limit, anchor: .center)
                }
            }
        }
    }

    private func save() async {
        let trimmed = name.trimmingCharacters(in: .whitespacesAndNewlines)
        guard !trimmed.isEmpty else { return }

        if let saved = await viewModel.save(
            name: trimmed,
            color: selectedColor,
            icon: selectedIcon,
            groupId: group.id,
            limit: normalizedLimit,
            limitFrequency: selectedLimitFrequency,
            categoryToEdit: categoryToEdit
        ) {
            onSaved(saved)
            dismiss()
        }
    }

    private var appearanceCard: some View {
        NativeSettingsCard {
            VStack(spacing: 0) {
                pickerSection(title: LocalizationKey.Category.color.localized) {
                    LazyVGrid(columns: colorGridColumns, spacing: 10) {
                        ForEach(colorOptions, id: \.self) { hex in
                            Button {
                                withAnimation(AnimationHelper.quickSpring) {
                                    selectedColor = hex
                                }
                            } label: {
                                Circle()
                                    .fill(Color(hex: hex) ?? .accentColor)
                                    .frame(height: 36)
                                    .overlay {
                                        if selectedColor == hex {
                                            Circle()
                                                .stroke(Color.white, lineWidth: 2.5)
                                                .padding(2)
                                                .overlay {
                                                    Image(systemName: "checkmark")
                                                        .font(.system(size: 12, weight: .bold))
                                                        .foregroundStyle(.white)
                                                }
                                        }
                                    }
                                    .scaleEffect(selectedColor == hex ? 1.06 : 1)
                            }
                            .buttonStyle(.plain)
                        }
                    }
                }

                Divider()
                    .padding(.horizontal, AppConstants.UserInterface.padding)

                pickerSection(title: LocalizationKey.Category.icon.localized) {
                    LazyVGrid(columns: iconGridColumns, spacing: 10) {
                        ForEach(iconOptions, id: \.self) { icon in
                            Button {
                                withAnimation(AnimationHelper.quickSpring) {
                                    selectedIcon = icon
                                }
                            } label: {
                                RoundedRectangle(cornerRadius: 12)
                                    .fill(selectedIcon == icon ? selectedTint : Color(.tertiarySystemGroupedBackground))
                                    .frame(height: 52)
                                    .overlay {
                                        Image(systemName: icon)
                                            .font(.system(size: 18, weight: .medium))
                                            .foregroundStyle(selectedIcon == icon ? .white : .secondary)
                                    }
                                    .overlay {
                                        RoundedRectangle(cornerRadius: 12)
                                            .stroke(selectedIcon == icon ? Color.white.opacity(0.18) : Color.clear, lineWidth: 1)
                                    }
                                    .scaleEffect(selectedIcon == icon ? 1.02 : 1)
                            }
                            .buttonStyle(.plain)
                        }
                    }
                }
            }
        }
    }

    private var limitCard: some View {
        NativeSettingsCard {
            VStack(spacing: 0) {
                HStack(spacing: 12) {
                    HStack(spacing: 8) {
                        Image(systemName: "chart.bar.fill")
                            .font(.system(size: 16, weight: .medium))
                            .foregroundStyle(selectedTint)

                        Text(LocalizationKey.Category.limit.localized)
                            .font(.subheadline.weight(.semibold))
                            .foregroundStyle(.secondary)
                    }

                    Spacer(minLength: 12)

                    HStack(spacing: 8) {
                        TextField(LocalizationKey.Category.noLimit.localized, text: $limitText)
                            .multilineTextAlignment(.trailing)
                            .keyboardType(.decimalPad)
                            .focused($focusedField, equals: .limit)

                        if !limitText.isEmpty {
                            Button { limitText = "" } label: {
                                Image(systemName: "xmark.circle.fill")
                                    .foregroundStyle(Color(.tertiaryLabel))
                                    .font(.system(size: 16))
                            }
                            .buttonStyle(.plain)
                        }
                    }
                    .frame(maxWidth: 140, alignment: .trailing)
                }
                .padding(AppConstants.UserInterface.padding)

                if hasActiveLimit {
                    Divider()
                        .padding(.leading, AppConstants.UserInterface.padding + 24)

                    HStack(spacing: 12) {
                        Text(LocalizationKey.Category.limitFrequency.localized)
                            .font(.subheadline.weight(.semibold))
                            .foregroundStyle(.secondary)

                        Spacer(minLength: 12)

                        Picker(LocalizationKey.Category.limitFrequency.localized, selection: $selectedLimitFrequency) {
                            ForEach(limitFrequencyOptions) { option in
                                Text(option.titleKey.localized)
                                    .tag(option.value)
                            }
                        }
                        .pickerStyle(.menu)
                        .tint(selectedTint)
                    }
                    .padding(AppConstants.UserInterface.padding)
                    .transition(.opacity)
                }
            }
        }
    }

    private func pickerSection<Content: View>(
        title: String,
        @ViewBuilder content: () -> Content
    ) -> some View {
        VStack(alignment: .leading, spacing: 12) {
            Text(title)
                .font(.subheadline.weight(.semibold))
                .foregroundStyle(.secondary)

            content()
        }
        .padding(AppConstants.UserInterface.padding)
    }
}
