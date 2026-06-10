import SwiftUI

struct DashboardBottomBarView: View {
    @Binding var searchText: String
    @Binding var isSearchActive: Bool
    let dismissKeyboardToken: Int

    let currentGroup: SDGroup?
    let availableGroups: [SDGroup]
    let userId: UUID?
    let isChangingGroup: Bool
    let isFilterActive: Bool
    let selectedScopeTitle: String?
    let selectedScopeIcon: String?
    let selectedScopeColorHex: String?
    let onGroupChange: (SDGroup) -> Void
    let onGroupCreated: (SDGroup) -> Void
    let onDeleteGroup: (SDGroup) async throws -> Void
    let onSelectedScopeTap: () -> Void
    let onOpenFilters: () -> Void

    @FocusState private var isSearchFieldFocused: Bool
    @State private var searchFocusTask: Task<Void, Never>? = nil

    var body: some View {
        ZStack(alignment: .trailing) {
            if !isSearchActive {
                inactiveContent
                    .transition(.move(edge: .bottom).combined(with: .opacity))
            }

            if isSearchActive {
                searchContent
                    .transition(.move(edge: .bottom).combined(with: .opacity))
            }
        }
        .padding(.horizontal, AppConstants.UserInterface.padding)
        .padding(.top, AppConstants.UserInterface.smallPadding)
        .padding(.bottom, AppConstants.UserInterface.smallPadding)
        .background(Color(.systemBackground).ignoresSafeArea(edges: .bottom))
        .animation(AnimationHelper.quickEase, value: isSearchActive)
        .onChange(of: isSearchActive) { _, isActive in
            searchFocusTask?.cancel()

            if isActive {
                searchFocusTask = Task { @MainActor in
                    // Wait for the 200ms quickEase animation to finish before focusing
                    try? await Task.sleep(for: .milliseconds(250))
                    guard !Task.isCancelled, isSearchActive else { return }
                    isSearchFieldFocused = true
                }
            }
        }
        .onChange(of: dismissKeyboardToken) { _, _ in
            searchFocusTask?.cancel()
            isSearchFieldFocused = false
        }
        .onAppear {
            isSearchFieldFocused = false
        }
        .onDisappear {
            searchFocusTask?.cancel()
            isSearchFieldFocused = false
        }
    }

    private var searchContent: some View {
        VStack(spacing: 6) {
            if let selectedScopeTitle {
                SearchScopeBreadcrumb(
                    title: selectedScopeTitle,
                    iconName: selectedScopeIcon,
                    colorHex: selectedScopeColorHex,
                    onTap: onSelectedScopeTap
                )
                .transition(.move(edge: .top).combined(with: .opacity))
            }

            HStack(spacing: 10) {
                Image(systemName: "magnifyingglass")
                    .font(.system(size: 15, weight: .regular))
                    .foregroundStyle(.secondary)

                TextField(LocalizationKey.General.search.localized, text: $searchText)
                    .textFieldStyle(.plain)
                    .focused($isSearchFieldFocused)
                    .submitLabel(.search)

                Button {
                    closeSearchMode()
                } label: {
                    Image(systemName: "xmark")
                        .font(.system(size: 14, weight: .semibold))
                        .foregroundStyle(.secondary)
                }
                .buttonStyle(.plain)
            }
            .padding(.horizontal, 14)
            .padding(.vertical, 10)
            .background(Color(.secondarySystemBackground).opacity(0.9))
            .clipShape(Capsule())
        }
        .animation(AnimationHelper.quickEase, value: selectedScopeTitle)
    }

    private var inactiveContent: some View {
        HStack(spacing: AppConstants.UserInterface.smallPadding) {
            if let currentGroup, let userId {
                GroupSelectorChipView(
                    currentGroup: currentGroup,
                    availableGroups: availableGroups,
                    userId: userId,
                    isChangingGroup: isChangingGroup,
                    compact: selectedScopeTitle != nil,
                    onGroupChange: onGroupChange,
                    onGroupCreated: onGroupCreated,
                    onDeleteGroup: onDeleteGroup
                )
            }

            if let selectedScopeTitle {
                DashboardSelectedScopeChip(
                    title: selectedScopeTitle,
                    iconName: selectedScopeIcon,
                    colorHex: selectedScopeColorHex,
                    onTap: onSelectedScopeTap
                )
                .frame(maxWidth: .infinity)
            } else {
                Spacer(minLength: 0)
            }

            HStack(spacing: 0) {
                Button(action: onOpenFilters) {
                    Image(systemName: "line.3.horizontal.decrease")
                        .font(.system(size: 15, weight: .regular))
                        .foregroundColor(isFilterActive ? .accentColor : .primary)
                        .padding(.horizontal, 12)
                        .padding(.vertical, 8)
                }
                .buttonStyle(PressHapticButtonStyle())

                Divider()
                    .frame(height: 16)

                Button {
                    isSearchActive = true
                } label: {
                    Image(systemName: "magnifyingglass")
                        .font(.system(size: 15, weight: .regular))
                        .foregroundColor(.primary)
                        .padding(.horizontal, 12)
                        .padding(.vertical, 8)
                }
                .buttonStyle(PressHapticButtonStyle())
            }
            .background(Color(.secondarySystemBackground).opacity(0.9))
            .clipShape(Capsule())
            .overlay(
                Capsule()
                    .stroke(Color(.systemGray4).opacity(0.5), lineWidth: 1)
            )
        }
    }

    private func closeSearchMode() {
        searchFocusTask?.cancel()
        isSearchFieldFocused = false

        Task { @MainActor in
            // Wait for the keyboard to fully dismiss before closing the bar,
            // so the hero section doesn't reappear while the keyboard is still visible.
            try? await Task.sleep(for: .milliseconds(280))
            guard !Task.isCancelled else { return }
            withAnimation(AnimationHelper.quickEase) {
                isSearchActive = false
            }
            try? await Task.sleep(for: .milliseconds(140))
            guard !isSearchActive else { return }
            searchText = ""
        }
    }
}

private struct SearchScopeBreadcrumb: View {
    let title: String
    let iconName: String?
    let colorHex: String?
    let onTap: () -> Void

    private var hasCategoryTint: Bool {
        colorHex != nil
    }

    private var contentColor: Color {
        guard let colorHex else { return .primary }
        return Color(hex: colorHex) ?? .primary
    }

    private var backgroundColor: Color {
        hasCategoryTint ? contentColor.opacity(0.10) : Color(.secondarySystemBackground).opacity(0.9)
    }

    private var borderColor: Color {
        hasCategoryTint ? contentColor.opacity(0.18) : Color(.systemGray4).opacity(0.5)
    }

    var body: some View {
        Button(action: onTap) {
            HStack(spacing: 5) {
                Image(systemName: "chevron.left")
                    .font(.system(size: 12, weight: .semibold))

                if let iconName {
                    Image(systemName: iconName)
                        .font(.caption2)
                }

                Text(title)
                    .font(.subheadline)
                    .fontWeight(.medium)
                    .lineLimit(1)
                    .truncationMode(.tail)

                Spacer(minLength: 0)
            }
            .foregroundStyle(contentColor)
            .padding(.horizontal, 12)
            .padding(.vertical, 6)
            .frame(maxWidth: .infinity, alignment: .leading)
            .background(backgroundColor)
            .clipShape(Capsule())
            .overlay(
                Capsule()
                    .stroke(borderColor, lineWidth: 1)
            )
            .contentShape(Capsule())
        }
        .buttonStyle(PressHapticButtonStyle())
    }
}

private struct DashboardSelectedScopeChip: View {
    let title: String
    let iconName: String?
    let colorHex: String?
    let onTap: () -> Void

    @State private var hapticTrigger = false

    private var hasCategoryTint: Bool {
        colorHex != nil
    }

    private var contentColor: Color {
        guard let colorHex else { return .primary }
        return Color(hex: colorHex) ?? .primary
    }

    private var backgroundColor: Color {
        hasCategoryTint ? contentColor.opacity(0.12) : Color(.secondarySystemBackground).opacity(0.9)
    }

    private var borderColor: Color {
        hasCategoryTint ? contentColor.opacity(0.2) : Color(.systemGray4).opacity(0.5)
    }

    var body: some View {
        Button {
            hapticTrigger.toggle()
            onTap()
        } label: {
            HStack(spacing: 6) {
                if let iconName {
                    Image(systemName: iconName)
                        .font(.caption2)
                        .foregroundStyle(contentColor)
                }

                Text(title)
                    .font(.subheadline)
                    .fontWeight(.medium)
                    .lineLimit(1)
                    .truncationMode(.tail)
                    .foregroundStyle(contentColor)

                Spacer(minLength: 4)

                Image(systemName: "xmark")
                    .font(.caption2)
                    .foregroundStyle(contentColor)
            }
            .padding(.horizontal, 12)
            .padding(.vertical, 8)
            .frame(maxWidth: .infinity, alignment: .leading)
            .background(backgroundColor)
            .clipShape(Capsule())
            .overlay(
                Capsule()
                    .stroke(borderColor, lineWidth: 1)
            )
            .contentShape(Capsule())
        }
        .buttonStyle(.plain)
        .sensoryFeedback(.selection, trigger: hapticTrigger)
    }
}
