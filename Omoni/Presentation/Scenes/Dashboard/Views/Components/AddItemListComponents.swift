import SwiftUI

enum AddItemListField {
    case description
    case price
}

struct AddItemListStructureSection: View {
    let selection: ItemListStructure
    let canConvertToSingleEntry: Bool
    let helperText: String?
    let onSelect: (ItemListStructure) -> Void

    private var singleEntryEnabled: Bool {
        canConvertToSingleEntry || selection == .singleEntry
    }

    var body: some View {
        VStack(alignment: .leading, spacing: 10) {
            HStack(spacing: 6) {
                structureSegment(
                    title: LocalizationKey.Entry.singleEntry.localized,
                    systemImage: "bolt.fill",
                    structure: .singleEntry,
                    isEnabled: singleEntryEnabled
                )

                structureSegment(
                    title: LocalizationKey.Entry.itemizedList.localized,
                    systemImage: "list.bullet",
                    structure: .itemizedList,
                    isEnabled: true
                )
            }
            .padding(4)
            .background(Color(.secondarySystemGroupedBackground))
            .clipShape(Capsule())
            .sensoryFeedback(.selection, trigger: selection)

            if let helperText {
                Text(helperText)
                    .font(.caption)
                    .foregroundStyle(.secondary)
                    .padding(.horizontal, 4)
            }
        }
    }

    private func structureSegment(
        title: String,
        systemImage: String,
        structure: ItemListStructure,
        isEnabled: Bool
    ) -> some View {
        let isSelected = selection == structure

        return Button {
            guard isEnabled else { return }
            withAnimation(AnimationHelper.quickSpring) {
                onSelect(structure)
            }
        } label: {
            HStack(spacing: 8) {
                Image(systemName: systemImage)
                    .font(.subheadline.weight(.semibold))

                Text(title)
                    .font(.subheadline.weight(.semibold))
                    .lineLimit(1)
            }
            .frame(maxWidth: .infinity)
            .padding(.horizontal, 14)
            .padding(.vertical, 12)
            .foregroundStyle(segmentForegroundColor(isSelected: isSelected, isEnabled: isEnabled))
            .background {
                Capsule()
                    .fill(isSelected ? Color(.tertiarySystemGroupedBackground) : Color.clear)
            }
            .overlay {
                Capsule()
                    .stroke(
                        isSelected ? Color.primary.opacity(0.08) : Color.clear,
                        lineWidth: 1
                    )
            }
            .shadow(
                color: .black.opacity(isSelected ? 0.12 : 0),
                radius: isSelected ? 10 : 0,
                y: isSelected ? 3 : 0
            )
            .opacity(isEnabled ? 1 : 0.5)
            .contentShape(Capsule())
            .animation(AnimationHelper.quickSpring, value: isSelected)
        }
        .buttonStyle(.plain)
    }

    private func segmentForegroundColor(isSelected: Bool, isEnabled: Bool) -> Color {
        if isSelected {
            return .primary
        }
        if isEnabled {
            return Color.primary.opacity(0.92)
        }
        return .secondary
    }
}

// MARK: - Top Card (Amount + Description)

struct AddItemListTopCard: View {
    let showsHeroAmountInput: Bool
    let usesExpandedDescriptionLayout: Bool
    @Binding var price: String
    let currencySymbol: String
    let descriptionPlaceholder: String
    @Binding var description: String
    let suggestions: [ConceptSuggestion]
    let focusedField: FocusState<AddItemListField?>.Binding
    let onValidate: () -> Void
    let onPaste: () -> Void
    let onSuggestionSelected: (ConceptSuggestion) -> Void

    var body: some View {
        VStack(spacing: 0) {
            if showsHeroAmountInput {
                HeroAmountInputView(
                    text: $price,
                    currencySymbol: currencySymbol,
                    onValidate: onValidate,
                    focusedField: focusedField,
                    fieldValue: .price,
                    embedded: true,
                    onPaste: onPaste
                )

                Rectangle()
                    .fill(Color(.separator))
                    .frame(height: 1.5)
                    .padding(.horizontal, AppConstants.UserInterface.padding)
            }

            AddItemListDescriptionField(
                usesExpandedLayout: usesExpandedDescriptionLayout,
                description: $description,
                placeholder: descriptionPlaceholder,
                focusedField: focusedField
            )

            if focusedField.wrappedValue == .description && !suggestions.isEmpty {
                ConceptSuggestionChipsView(suggestions: suggestions) { selected in
                    onSuggestionSelected(selected)
                }
                .padding(.bottom, 8)
                .transition(.opacity.combined(with: .move(edge: .top)))
            }
        }
        .background(Color(.secondarySystemGroupedBackground))
        .clipShape(RoundedRectangle(cornerRadius: AppConstants.UserInterface.rowCornerRadius))
    }
}

struct AddItemListDescriptionField: View {
    let usesExpandedLayout: Bool
    @Binding var description: String
    let placeholder: String
    let focusedField: FocusState<AddItemListField?>.Binding

    var body: some View {
        LimitedTextField(
            icon: "textformat",
            placeholder: placeholder,
            text: $description,
            maxLength: AppConstants.Validation.maxItemDescriptionLength,
            axis: .horizontal,
            style: .embedded,
            submitLabel: .done,
            onSubmit: { focusedField.wrappedValue = nil },
            focusedField: focusedField,
            fieldValue: .description
        )
        .padding(usesExpandedLayout ? AppConstants.UserInterface.largePadding : AppConstants.UserInterface.padding)
    }
}

// MARK: - Category Grid (no section label)

struct AddItemListCategorySection: View {
    let displayedCategories: [SDCategory]
    let overflowCategories: [SDCategory]
    @Binding var showOverflow: Bool
    let compact: Bool
    let selectedCategoryID: UUID?
    let chipMinHeight: CGFloat
    let chipCornerRadius: CGFloat
    let onSelect: (SDCategory) -> Void

    var body: some View {
        VStack(alignment: .leading, spacing: 10) {
            LazyVGrid(columns: [GridItem(.flexible()), GridItem(.flexible())], spacing: 10) {
                ForEach(displayedCategories) { category in
                    AddItemListCategoryChip(
                        category: category,
                        isSelected: selectedCategoryID == category.id,
                        compact: compact,
                        minHeight: chipMinHeight,
                        cornerRadius: chipCornerRadius,
                        onTap: { onSelect(category) }
                    )
                    .transition(.opacity.combined(with: .scale(scale: 0.88, anchor: .top)))
                }

                if !overflowCategories.isEmpty && !showOverflow {
                    AddItemListCategoryOverflowChip(
                        overflowSelected: overflowCategories.first { $0.id == selectedCategoryID },
                        compact: compact,
                        minHeight: chipMinHeight,
                        cornerRadius: chipCornerRadius,
                        isExpanded: showOverflow
                    ) {
                        withAnimation(AnimationHelper.expansionSpring) {
                            showOverflow.toggle()
                        }
                    }
                }
            }
            .animation(AnimationHelper.expansionSpring, value: showOverflow)

            if showOverflow {
                Button {
                    withAnimation(AnimationHelper.expansionSpring) {
                        showOverflow = false
                    }
                } label: {
                    HStack(spacing: 4) {
                        Text(LocalizationKey.Entry.viewLess.localized)
                            .font(.caption.weight(.semibold))
                            .foregroundStyle(.secondary)
                        Image(systemName: "chevron.up")
                            .font(.caption2.weight(.semibold))
                            .foregroundStyle(.secondary)
                    }
                    .frame(maxWidth: .infinity)
                    .padding(.top, 2)
                    .contentShape(Rectangle())
                }
                .buttonStyle(.plain)
                .transition(.opacity)
            }
        }
    }

}

struct AddItemListDashboardCategoryHintBanner: View {
    let onDismiss: () -> Void

    var body: some View {
        HStack(spacing: 10) {
            Image(systemName: "square.grid.2x2.fill")
                .font(.system(size: 15, weight: .semibold))
                .foregroundStyle(.accent)

            Text(LocalizationKey.Entry.dashboardCategoryHintMessage.localized)
                .font(.subheadline.weight(.medium))
                .foregroundStyle(.primary)

            Spacer(minLength: 0)

            Button(action: onDismiss) {
                Image(systemName: "xmark")
                    .font(.system(size: 12, weight: .bold))
                    .foregroundStyle(.secondary)
            }
            .buttonStyle(.plain)
        }
        .padding(.horizontal, 14)
        .padding(.vertical, 12)
        .background(Color(.secondarySystemGroupedBackground))
        .clipShape(RoundedRectangle(cornerRadius: 14, style: .continuous))
    }
}

private struct AddItemListCategoryChip: View {
    let category: SDCategory
    let isSelected: Bool
    let compact: Bool
    let minHeight: CGFloat
    let cornerRadius: CGFloat
    let onTap: () -> Void

    private var chipColor: Color {
        Color(hex: category.color) ?? .accentColor
    }

    var body: some View {
        Button(action: onTap) {
            ZStack {
                HStack(spacing: 8) {
                    Image(systemName: category.icon)
                        .font(.subheadline)
                        .foregroundStyle(isSelected ? .white : chipColor)
                    Text(category.name)
                        .font(.subheadline)
                        .fontWeight(isSelected ? .semibold : .regular)
                        .foregroundStyle(isSelected ? .white : .primary)
                        .lineLimit(1)
                    Spacer(minLength: 0)
                    if isSelected {
                        Image(systemName: "checkmark.circle.fill")
                            .font(.caption.weight(.bold))
                            .foregroundStyle(.white.opacity(0.96))
                    }
                }
                .opacity(compact ? 1 : 0)
                .scaleEffect(compact ? 1 : 0.85, anchor: .leading)

                VStack(spacing: 6) {
                    Image(systemName: category.icon)
                        .font(.title2)
                        .foregroundStyle(isSelected ? .white : chipColor)
                    Text(category.name)
                        .font(.subheadline)
                        .fontWeight(isSelected ? .semibold : .regular)
                        .foregroundStyle(isSelected ? .white : .primary)
                        .lineLimit(1)
                        .multilineTextAlignment(.center)
                }
                .opacity(compact ? 0 : 1)
                .scaleEffect(compact ? 0.85 : 1, anchor: .center)
                .frame(maxHeight: compact ? 0 : .infinity)
                .clipped()
            }
            .frame(maxWidth: .infinity, minHeight: minHeight)
            .padding(.horizontal, compact ? 14 : 12)
            .padding(.vertical, compact ? 12 : 10)
            .background(isSelected ? chipColor : Color(.secondarySystemGroupedBackground))
            .clipShape(RoundedRectangle(cornerRadius: cornerRadius))
            .overlay(
                RoundedRectangle(cornerRadius: cornerRadius)
                    .stroke(chipColor.opacity(isSelected ? 0 : 0.3), lineWidth: 1)
            )
            .overlay(alignment: .topTrailing) {
                if isSelected && !compact {
                    Image(systemName: "checkmark.circle.fill")
                        .font(.caption.weight(.bold))
                        .foregroundStyle(.white.opacity(0.96))
                        .padding(10)
                }
            }
            .animation(AnimationHelper.expansionSpring, value: compact)
        }
        .buttonStyle(.plain)
    }
}

private struct AddItemListCategoryOverflowChip: View {
    let overflowSelected: SDCategory?
    let compact: Bool
    let minHeight: CGFloat
    let cornerRadius: CGFloat
    let isExpanded: Bool
    let onTap: () -> Void

    private var chipColor: Color {
        overflowSelected.flatMap { Color(hex: $0.color) } ?? Color(.systemGray3)
    }

    private var icon: String {
        overflowSelected?.icon ?? "ellipsis.circle.fill"
    }

    private var label: String {
        overflowSelected?.name ?? LocalizationKey.Entry.more.localized
    }

    private var isActive: Bool { overflowSelected != nil }

    private var trailingIndicatorColor: some ShapeStyle {
        isActive ? .white.opacity(0.88) : Color(.tertiaryLabel)
    }

    private var trailingIndicator: some View {
        HStack(spacing: 8) {
            if isActive && !isExpanded {
                Image(systemName: "checkmark.circle.fill")
                    .font(.caption.weight(.bold))
            }

            Image(systemName: isExpanded ? "chevron.up" : "chevron.down")
                .font(.caption.weight(.semibold))
        }
        .foregroundStyle(trailingIndicatorColor)
    }

    var body: some View {
        Button(action: onTap) {
            ZStack {
                HStack(spacing: 8) {
                    Image(systemName: icon)
                        .font(.subheadline)
                        .foregroundStyle(isActive ? .white : chipColor)
                    Text(label)
                        .font(.subheadline)
                        .fontWeight(isActive ? .semibold : .regular)
                        .foregroundStyle(isActive ? .white : .primary)
                        .lineLimit(1)
                    Spacer(minLength: 0)
                    trailingIndicator
                }
                .opacity(compact ? 1 : 0)
                .scaleEffect(compact ? 1 : 0.85, anchor: .leading)

                VStack(spacing: 6) {
                    Image(systemName: icon)
                        .font(.title2)
                        .foregroundStyle(isActive ? .white : chipColor)
                    HStack(spacing: 4) {
                        Text(label)
                            .font(.subheadline)
                            .fontWeight(isActive ? .semibold : .regular)
                            .foregroundStyle(isActive ? .white : .primary)
                            .lineLimit(1)
                        trailingIndicator
                    }
                }
                .opacity(compact ? 0 : 1)
                .scaleEffect(compact ? 0.85 : 1, anchor: .center)
                .frame(maxHeight: compact ? 0 : .infinity)
                .clipped()
            }
            .frame(maxWidth: .infinity, minHeight: minHeight)
            .padding(.horizontal, compact ? 14 : 12)
            .padding(.vertical, compact ? 12 : 10)
            .background(isActive ? chipColor : Color(.secondarySystemGroupedBackground))
            .clipShape(RoundedRectangle(cornerRadius: cornerRadius))
            .overlay(
                RoundedRectangle(cornerRadius: cornerRadius)
                    .stroke(chipColor.opacity(isActive ? 0 : 0.3), lineWidth: 1)
            )
            .animation(AnimationHelper.expansionSpring, value: compact)
            .animation(AnimationHelper.expansionSpring, value: isExpanded)
        }
        .buttonStyle(.plain)
    }
}

// MARK: - More Details Section (lighter trigger)

struct AddItemListMoreDetailsSection<Content: View>: View {
    let isEditMode: Bool
    @Binding var showDetails: Bool
    @ViewBuilder let content: () -> Content

    private var triggerTransition: AnyTransition {
        .asymmetric(
            insertion: .move(edge: .top).combined(with: .opacity),
            removal: .move(edge: .top).combined(with: .opacity)
        )
    }

    private var detailsTransition: AnyTransition {
        .asymmetric(
            insertion: .move(edge: .bottom).combined(with: .opacity),
            removal: .move(edge: .bottom).combined(with: .opacity)
        )
    }

    var body: some View {
        VStack(spacing: 16) {
            if !isEditMode && !showDetails {
                Button {
                    withAnimation(AnimationHelper.expansionSpring) {
                        showDetails = true
                    }
                } label: {
                    HStack(spacing: 6) {
                        Image(systemName: "chevron.down")
                            .font(.system(size: 11, weight: .semibold))
                        Text(LocalizationKey.Entry.moreDetails.localized)
                            .font(.subheadline)
                            .fontWeight(.medium)
                    }
                    .foregroundStyle(Color.secondary)
                    .frame(maxWidth: .infinity)
                    .padding(.vertical, 13)
                    .background(Color(.secondarySystemGroupedBackground))
                    .clipShape(RoundedRectangle(cornerRadius: 12, style: .continuous))
                    .contentShape(Rectangle())
                }
                .buttonStyle(PressHapticButtonStyle())
                .zIndex(1)
                .transition(triggerTransition)
            }

            if isEditMode || showDetails {
                VStack(spacing: 16) {
                    content()
                }
                .zIndex(0)
                .clipped()
                .transition(isEditMode ? .identity : detailsTransition)
                .animation(isEditMode ? nil : AnimationHelper.expansionSpring, value: showDetails)
            }
        }
    }
}

// MARK: - Payment Method Grid (no section label)

struct AddItemListPaymentMethodSection: View {
    let displayedPaymentMethods: [SDPaymentMethod]
    let overflowPaymentMethods: [SDPaymentMethod]
    @Binding var showOverflow: Bool
    let selectedPaymentMethodID: UUID?
    let colorForType: (String) -> Color
    let iconForMethod: (SDPaymentMethod) -> String
    let onSelect: (SDPaymentMethod) -> Void
    let onToggleOffSelected: () -> Void
    let onCollapseOverflow: () -> Void

    var body: some View {
        VStack(alignment: .leading, spacing: 10) {
            LazyVGrid(columns: [GridItem(.flexible()), GridItem(.flexible())], spacing: 10) {
                ForEach(displayedPaymentMethods) { method in
                    AddItemListPaymentMethodChip(
                        method: method,
                        isSelected: selectedPaymentMethodID == method.id,
                        color: colorForType(method.type),
                        iconName: iconForMethod(method)
                    ) {
                        if selectedPaymentMethodID == method.id {
                            onToggleOffSelected()
                        } else {
                            onSelect(method)
                        }
                    }
                    .transition(.opacity.combined(with: .scale(scale: 0.88, anchor: .top)))
                }

                if !overflowPaymentMethods.isEmpty && !showOverflow {
                    AddItemListPaymentMethodOverflowChip(
                        overflowSelected: overflowPaymentMethods.first { $0.id == selectedPaymentMethodID },
                        isExpanded: showOverflow,
                        colorForType: colorForType,
                        iconForMethod: iconForMethod
                    ) {
                        withAnimation(AnimationHelper.quickSpring) {
                            showOverflow.toggle()
                        }
                    }
                }
            }
            .animation(AnimationHelper.expansionSpring, value: showOverflow)
            .id("paymentMethodAnchor")

            if showOverflow {
                Button {
                    withAnimation(AnimationHelper.expansionSpring) {
                        showOverflow = false
                    }
                    onCollapseOverflow()
                } label: {
                    HStack(spacing: 4) {
                        Text(LocalizationKey.Entry.viewLess.localized)
                            .font(.caption.weight(.semibold))
                            .foregroundStyle(.secondary)
                        Image(systemName: "chevron.up")
                            .font(.caption2.weight(.semibold))
                            .foregroundStyle(.secondary)
                    }
                    .frame(maxWidth: .infinity)
                    .padding(.top, 2)
                    .contentShape(Rectangle())
                }
                .buttonStyle(.plain)
                .transition(.opacity)
            }
        }
    }
}

private struct AddItemListPaymentMethodChip: View {
    let method: SDPaymentMethod
    let isSelected: Bool
    let color: Color
    let iconName: String
    let onTap: () -> Void

    var body: some View {
        Button(action: onTap) {
            HStack(spacing: 8) {
                Image(systemName: iconName)
                    .font(.subheadline)
                    .foregroundStyle(isSelected ? .white : color)
                Text(method.name)
                    .font(.subheadline)
                    .fontWeight(isSelected ? .semibold : .regular)
                    .foregroundStyle(isSelected ? .white : .primary)
                    .lineLimit(1)
                Spacer(minLength: 0)
                if isSelected {
                    Image(systemName: "checkmark.circle.fill")
                        .font(.caption.weight(.bold))
                        .foregroundStyle(.white.opacity(0.96))
                }
            }
            .frame(maxWidth: .infinity, minHeight: 44)
            .padding(.horizontal, 14)
            .padding(.vertical, 12)
            .background(isSelected ? color : Color(.secondarySystemGroupedBackground))
            .clipShape(RoundedRectangle(cornerRadius: 12))
            .overlay(
                RoundedRectangle(cornerRadius: 12)
                    .stroke(color.opacity(isSelected ? 0 : 0.3), lineWidth: 1)
            )
        }
        .buttonStyle(.plain)
    }
}

private struct AddItemListPaymentMethodOverflowChip: View {
    let overflowSelected: SDPaymentMethod?
    let isExpanded: Bool
    let colorForType: (String) -> Color
    let iconForMethod: (SDPaymentMethod) -> String
    let onTap: () -> Void

    private var chipColor: Color {
        overflowSelected.map { colorForType($0.type) } ?? Color(.systemGray3)
    }

    private var iconName: String {
        overflowSelected.map(iconForMethod) ?? "ellipsis.circle.fill"
    }

    private var label: String {
        overflowSelected?.name ?? LocalizationKey.Entry.more.localized
    }

    private var isActive: Bool { overflowSelected != nil }

    private var trailingIndicatorColor: some ShapeStyle {
        isActive ? .white.opacity(0.88) : Color(.tertiaryLabel)
    }

    private var trailingIndicator: some View {
        HStack(spacing: 8) {
            if isActive && !isExpanded {
                Image(systemName: "checkmark.circle.fill")
                    .font(.caption.weight(.bold))
            }

            Image(systemName: isExpanded ? "chevron.up" : "chevron.down")
                .font(.caption.weight(.semibold))
        }
        .foregroundStyle(trailingIndicatorColor)
    }

    var body: some View {
        Button(action: onTap) {
            HStack(spacing: 8) {
                Image(systemName: iconName)
                    .font(.subheadline)
                    .foregroundStyle(isActive ? .white : chipColor)
                Text(label)
                    .font(.subheadline)
                    .fontWeight(isActive ? .semibold : .regular)
                    .foregroundStyle(isActive ? .white : .primary)
                    .lineLimit(1)
                Spacer(minLength: 0)
                trailingIndicator
            }
            .frame(maxWidth: .infinity, minHeight: 44)
            .padding(.horizontal, 14)
            .padding(.vertical, 12)
            .background(isActive ? chipColor : Color(.secondarySystemGroupedBackground))
            .clipShape(RoundedRectangle(cornerRadius: 12))
            .overlay(
                RoundedRectangle(cornerRadius: 12)
                    .stroke(chipColor.opacity(isActive ? 0 : 0.3), lineWidth: 1)
            )
            .animation(AnimationHelper.quickSpring, value: isExpanded)
        }
        .buttonStyle(.plain)
    }
}

// MARK: - Date Card (chip-style, no Toggle)

struct AddItemListDateCard: View {
    @Binding var showDatePicker: Bool
    @Binding var calendarExpanded: Bool
    @Binding var date: Date
    let formattedDate: String
    let focusedField: FocusState<AddItemListField?>.Binding
    let onToggleChanged: (Bool) -> Void

    private var dateLabel: String {
        !showDatePicker && Calendar.current.isDateInToday(date)
            ? LocalizationKey.Dashboard.today.localized.capitalized
            : formattedDate
    }

    private var isTodayCompactState: Bool {
        !showDatePicker && Calendar.current.isDateInToday(date)
    }

    private var iconTint: Color {
        (showDatePicker || isTodayCompactState) ? .primary : .secondary
    }

    private var iconBadgeBackground: Color {
        if showDatePicker {
            return Color.primary.opacity(0.1)
        }
        if isTodayCompactState {
            return Color.primary.opacity(0.08)
        }
        return .clear
    }

    private var dateTextColor: Color {
        (showDatePicker || isTodayCompactState) ? .primary : .secondary
    }

    private var dateTextWeight: Font.Weight {
        (showDatePicker || isTodayCompactState) ? .semibold : .medium
    }

    private var cardStrokeColor: Color {
        if showDatePicker {
            return Color.primary.opacity(0.12)
        }
        if isTodayCompactState {
            return Color.primary.opacity(0.08)
        }
        return .clear
    }

    private func clearDateSelection() {
        focusedField.wrappedValue = nil

        let finishReset = {
            date = Date()
            showDatePicker = false
            onToggleChanged(false)
        }

        if calendarExpanded {
            withAnimation(.spring(response: 0.45, dampingFraction: 0.88)) {
                calendarExpanded = false
            }

            Task {
                try? await Task.sleep(for: .milliseconds(320))
                finishReset()
            }
        } else {
            finishReset()
        }
    }

    var body: some View {
        VStack(spacing: 0) {
            HStack(spacing: 12) {
                ZStack(alignment: .trailing) {
                    // Tappable date area — full width
                    Button {
                        focusedField.wrappedValue = nil
                        if !showDatePicker {
                            showDatePicker = true
                            onToggleChanged(true)
                        } else {
                            withAnimation(.spring(response: 0.5, dampingFraction: 0.85)) {
                                calendarExpanded.toggle()
                            }
                        }
                    } label: {
                        HStack(spacing: 8) {
                            Image(systemName: "calendar")
                                .font(.system(size: 14))
                                .foregroundStyle(iconTint)
                                .frame(width: 28, height: 28)
                                .background(iconBadgeBackground)
                                .clipShape(RoundedRectangle(cornerRadius: 9, style: .continuous))

                            Text(dateLabel)
                                .font(.subheadline.weight(dateTextWeight))
                                .foregroundStyle(dateTextColor)
                                .contentTransition(.interpolate)

                            Spacer(minLength: 6)

                            Image(systemName: showDatePicker ? (calendarExpanded ? "chevron.up" : "chevron.down") : "chevron.right")
                                .font(.caption.weight(.semibold))
                                .foregroundStyle(Color(.tertiaryLabel))
                                .padding(.trailing, showDatePicker ? 32 : 0)
                        }
                        .frame(maxWidth: .infinity, alignment: .leading)
                        .contentShape(Rectangle())
                    }
                    .buttonStyle(.plain)

                    if showDatePicker {
                        Button(action: clearDateSelection) {
                            Image(systemName: "xmark.circle.fill")
                                .font(.system(size: 18))
                                .foregroundStyle(Color(.tertiaryLabel))
                        }
                        .buttonStyle(.plain)
                        .transition(.opacity.combined(with: .scale(scale: 0.85)))
                    }
                }
            }
            .padding(AppConstants.UserInterface.padding)
            .animation(.spring(response: 0.35, dampingFraction: 0.82), value: showDatePicker)

            // Collapsible calendar
            VStack(spacing: 0) {
                Divider()
                    .padding(.horizontal, AppConstants.UserInterface.padding)
                DatePicker("", selection: $date, displayedComponents: .date)
                    .datePickerStyle(.graphical)
                    .frame(maxWidth: .infinity)
                    .padding(.bottom, AppConstants.UserInterface.smallPadding)
                    .id("datePickerAnchor")
            }
            .frame(maxHeight: (showDatePicker && calendarExpanded) ? .infinity : 0, alignment: .top)
            .clipped()
            .opacity((showDatePicker && calendarExpanded) ? 1 : 0)
        }
        .background(Color(.secondarySystemGroupedBackground))
        .clipShape(RoundedRectangle(cornerRadius: AppConstants.UserInterface.rowCornerRadius))
        .overlay(
            RoundedRectangle(cornerRadius: AppConstants.UserInterface.rowCornerRadius)
                .stroke(cardStrokeColor, lineWidth: 1)
        )
        .animation(.spring(response: 0.45, dampingFraction: 0.88), value: calendarExpanded)
        .animation(.spring(response: 0.45, dampingFraction: 0.88), value: showDatePicker)
    }
}
