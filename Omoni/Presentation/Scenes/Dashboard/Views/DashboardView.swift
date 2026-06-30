//
//  DashboardView.swift
//  Omoni
//
//  Created by System on 3/11/25.
//

import SwiftUI

private enum DashboardActiveFilter {
    case all(DashboardCategoryRange)
    case allDay(range: DashboardCategoryRange, date: Date)
    case category(categoryId: UUID, range: DashboardCategoryRange)
    case categoryDay(categoryId: UUID, range: DashboardCategoryRange, date: Date)
}

private enum DashboardEntryDestination: Hashable {
    case singleEntryEditor
    case itemListDetail
}

private struct DashboardItemListRoute: Hashable {
    let itemListId: UUID
    let destination: DashboardEntryDestination
    let highlightedSearchQuery: String?
    let showsPendingItemsOnly: Bool
}

enum DashboardViewMode {
    case calendar, list

    var title: String {
        switch self {
        case .calendar: return "Calendario"
        case .list:     return "Lista"
        }
    }
}

/// Wrapper view to navigate to ItemListDetailView with proper currency
struct ItemListDetailNavigationWrapper: View {
    let itemList: SDItemList
    let currencyCode: String
    let group: SDGroup
    let highlightedSearchQuery: String?
    let showsPendingItemsOnly: Bool
    let onItemListUpdated: (SDItemList) -> Void
    let onItemListItemsChanged: (SDItemList) -> Void

    var body: some View {
        ItemListDetailView(
            itemList: itemList,
            currencyCode: currencyCode,
            group: group,
            highlightedSearchQuery: highlightedSearchQuery,
            showsPendingItemsOnly: showsPendingItemsOnly,
            onItemListUpdated: onItemListUpdated,
            onItemListItemsChanged: onItemListItemsChanged
        )
    }
}

struct SingleEntryEditorNavigationWrapper: View {
    let itemList: SDItemList
    let group: SDGroup
    let availableGroups: [SDGroup]
    let onItemListUpdated: (SDItemList) -> Void

    @Environment(\.dismiss) private var dismiss

    var body: some View {
        AddItemListView(
            group: group,
            availableGroups: availableGroups,
            itemListToEdit: itemList,
            showsCancelButton: false,
            onItemListCreated: { _ in },
            onItemListUpdated: { updated in
                onItemListUpdated(updated)
                // Defer dismiss to the next SwiftUI cycle so parent list/filter
                // recomposition does not compete with the navigation pop.
                Task { @MainActor in
                    dismiss()
                }
            },
            onCancel: { dismiss() }
        )
    }
}

struct DashboardView: View {
    @State private var viewModel: DashboardViewModel
    @State private var navigationPath = NavigationPath()
    @State private var contentOpacity: Double = 0.0
    @State private var hasLoadedInitialData = false
    @State private var selectedCalendarDay: Date? = nil
    @State private var addItemListTrigger: AddItemListTrigger? = nil

    private struct AddItemListTrigger: Identifiable {
        let id = UUID()
        let initialDate: Date?
        let preferredCategoryId: UUID?
    }
    @State private var listDragOffset: CGFloat = 0
    @State private var displayedCalendarMonth: Date = Calendar.current.startOfMonth(for: Date())
    @State private var viewMode: DashboardViewMode = .list
    @State private var collapsedMonthDays: Set<Date> = []
    @State private var showingFiltersSheet = false
    @State private var isSearchActive = false
    @State private var dismissSearchKeyboardToken = 0
    @State private var activeFilter: DashboardActiveFilter? = nil
    @State private var contentTransitionMode: DashboardContentTransitionMode = .drillForward
    @State private var pendingContentTransitionTask: Task<Void, Never>? = nil

    init() {
        // ✅ Clean Architecture: Use DI Container for all dependencies
        let container = AppDIContainer.shared

        self._viewModel = State(wrappedValue: DashboardViewModel(
            fetchItemListsUseCase: container.makeFetchItemListsUseCase(),
            fetchItemsUseCase: container.makeFetchItemsUseCase(),
            deleteItemListUseCase: container.makeDeleteItemListUseCase(),
            getCurrentUserUseCase: container.makeGetCurrentUserUseCase(),
            fetchGroupsForUserUseCase: container.makeFetchGroupsForUserUseCase(),
            fetchCategoriesUseCase: container.makeFetchCategoriesUseCase(),
            toggleAllItemsPaidInListUseCase: container.makeToggleAllItemsPaidInListUseCase(),
            toggleItemPaidUseCase: container.makeToggleItemPaidUseCase(),
            deleteGroupUseCase: container.makeDeleteGroupUseCase(),
            calculateItemListTotalsUseCase: container.makeCalculateItemListTotalsUseCase()
        ))
    }
    
    var body: some View {
        NavigationStack(path: $navigationPath) {
            ZStack {
                VStack(spacing: 0) {
                    if viewModel.isLoading {
                        loadingView
                    } else if let errorMessage = viewModel.errorMessage {
                        errorView(errorMessage)
                    } else {
                        mainContentView
                    }
                }
                .opacity(viewModel.isLoading ? 1.0 : contentOpacity)

                if viewModel.isChangingGroup {
                    DashboardChangingGroupOverlay()
                        .transition(.opacity)
                        .animation(.easeInOut(duration: 0.2), value: viewModel.isChangingGroup)
                }
            }
            .background(Color(.systemBackground))
            .onChange(of: navigationPath) { _, path in
                viewModel.toast = nil
                dismissSearchKeyboardToken += 1
            }
            .onChange(of: viewModel.isChangingGroup) { _, changing in
                if changing {
                    withAnimation(.easeOut(duration: 0.15)) { contentOpacity = 0.0 }
                } else {
                    selectedCalendarDay = nil
                    activeFilter = nil
                    listDragOffset = 0
                    displayedCalendarMonth = Calendar.current.startOfMonth(for: Date())
                    viewMode = .list
                    isSearchActive = false
                    viewModel.clearSearch()
                    withAnimation(.easeIn(duration: 0.3)) { contentOpacity = 1.0 }
                }
            }
            .navigationDestination(for: DashboardItemListRoute.self) { route in
                if let group = viewModel.currentGroup,
                   let itemList = viewModel.itemLists.first(where: { $0.id == route.itemListId }) {
                    switch route.destination {
                    case .singleEntryEditor:
                        SingleEntryEditorNavigationWrapper(
                            itemList: itemList,
                            group: group,
                            availableGroups: viewModel.availableGroups,
                            onItemListUpdated: { updated in
                                Task { await viewModel.updateItemList(updated) }
                            }
                        )
                    case .itemListDetail:
                        ItemListDetailNavigationWrapper(
                            itemList: itemList,
                            currencyCode: group.currency,
                            group: group,
                            highlightedSearchQuery: route.highlightedSearchQuery,
                            showsPendingItemsOnly: route.showsPendingItemsOnly,
                            onItemListUpdated: { updated in
                                Task { await viewModel.updateItemList(updated) }
                            },
                            onItemListItemsChanged: { updatedItemList in
                                Task { await viewModel.refreshTotals(for: updatedItemList) }
                            }
                        )
                    }
                } else {
                    Color.clear
                        .onAppear { navigationPath = NavigationPath() }
                }
            }
            .sheet(isPresented: $viewModel.showingSettings, onDismiss: {
                Task { await viewModel.refreshCategories() }
            }) {
                if let user = viewModel.currentUser {
                    SettingsSheetView(
                        user: user,
                        onUserUpdated: { updated in
                            viewModel.updateCurrentUser(updated)
                        },
                        onBackupImported: {
                            await viewModel.loadDashboardData()
                            viewModel.toast = ToastMessage("Backup imported successfully.", type: .info)
                        }
                    )
                }
            }
            .sheet(item: $addItemListTrigger) { trigger in
                if let group = viewModel.currentGroup {
                    NavigationStack {
                        AddItemListView(
                            group: group,
                            availableGroups: viewModel.availableGroups,
                            initialDate: trigger.initialDate,
                            preferredCategoryId: trigger.preferredCategoryId,
                            excludedCategoryIds: viewModel.visibleCategoryBoxes.map(\.categoryId),
                            onItemListCreated: { createdItemList in
                                addItemListTrigger = nil
                                Task {
                                    if createdItemList.structure == .itemizedList {
                                        await viewModel.addItemList(createdItemList)
                                        try? await Task.sleep(for: .milliseconds(400))
                                        navigationPath.append(itemListRoute(for: createdItemList))
                                    } else {
                                        try? await Task.sleep(for: .milliseconds(320))
                                        await viewModel.addItemList(createdItemList)
                                    }
                                }
                            },
                            onCancel: {
                                addItemListTrigger = nil
                            }
                        )
                    }
                    .presentationDetents([.large])
                    .presentationDragIndicator(.visible)
                }
            }
            .sheet(isPresented: $showingFiltersSheet) {
                NavigationStack {
                    DashboardMonthFilterSheet(
                        selectedMonth: viewModel.selectedMonthAnchor,
                        availableYears: viewModel.availableFilterYears,
                        isCustomFilterActive: viewModel.isCustomMonthFilterActive,
                        isPendingFilterActive: viewModel.hasActivePendingFilter,
                        selectedPendingFilter: viewModel.pendingFilter,
                        onApply: { month, pendingFilter in
                            viewModel.applyDashboardFilters(selectedMonth: month, pendingFilter: pendingFilter)
                            showingFiltersSheet = false
                        },
                        onReset: {
                            viewModel.clearDashboardFilters()
                            showingFiltersSheet = false
                        },
                        onClose: { showingFiltersSheet = false }
                    )
                }
                .presentationDetents([.medium])
                .presentationDragIndicator(.visible)
            }
        }
        .task {
            guard !hasLoadedInitialData else {
                await viewModel.refreshData()
                return
            }
            hasLoadedInitialData = true
            await viewModel.loadDashboardData()
            try? await Task.sleep(for: .milliseconds(100))
            withAnimation(.easeIn(duration: 0.5)) {
                contentOpacity = 1.0
            }
        }
    }
    
    // MARK: - Private Views
    
    private var loadingView: some View {
        DashboardLoadingState()
    }
    
    private func errorView(_ message: String) -> some View {
        DashboardErrorState(message: message) {
            Task { await viewModel.loadDashboardData() }
        }
    }
    
    private var mainContentView: some View {
        DashboardMainContent(
            allFormattedAmount: viewModel.formattedVisibleRangePaidTotal(showingFullMonth: viewModel.showingFullMonth),
            categoryBoxes: viewModel.visibleCategoryBoxes,
            hasVisibleItemLists: hasVisibleItemListsInSelectedRange,
            getFormattedAmount: { viewModel.formattedAmount(for: $0) },
            showsDateRows: showsDateRows,
            dateRows: activeDateRows,
            getDateRowAmount: { viewModel.formattedCurrency($0.paidAmount) },
            getDateRowUnpaidAmount: { $0.unpaidAmount > 0.000_001 ? viewModel.formattedCurrency($0.unpaidAmount) : nil },
            onDateRowTap: { box in
                performDashboardTransition(.drillForward) {
                    switch resolvedActiveFilter {
                    case .all(let range):
                        activeFilter = .allDay(range: range, date: box.date)
                    case .category(let categoryId, let range):
                        activeFilter = .categoryDay(categoryId: categoryId, range: range, date: box.date)
                    default:
                        break
                    }
                }
            },
            filteredItemLists: activeFilteredItemLists,
            getItemListCategoryContext: { itemList in
                guard activeAllDayContext != nil else { return nil }
                return itemList.category?.name
            },
            getItemListAmount: { viewModel.formattedPaid(for: $0) },
            getItemListUnpaidAmount: { viewModel.formattedUnpaid(for: $0) },
            getDayTotal: { viewModel.formattedVisibleDayPaidTotal(for: $0, from: activeFilteredItemLists) },
            getSearchSummary: { viewModel.formattedSearchSummary(for: $0) },
            getSearchMatchedSubtotal: { viewModel.formattedSearchMatchedSubtotal(for: $0) },
            getSearchMatchedUnpaid: { viewModel.formattedSearchMatchedUnpaid(for: $0) },
            getSearchMatchedRowStatus: { viewModel.searchMatchedRowStatus(for: $0) },
            hideExpenseListSectionHeaders: true,
            customEmptyState: { DashboardNoResultsState() },
            showCustomEmptyState: viewModel.hasActiveSearch || viewModel.isCustomMonthFilterActive || viewModel.hasActivePendingFilter,
            onRefresh: { await viewModel.refreshData() },
            onAllTap: {
                performDashboardTransition(.drillForward) {
                    if viewModel.showingFullMonth {
                        activeFilter = .all(.month)
                    } else {
                        activeFilter = .allDay(range: .today, date: Date())
                    }
                }
            },
            onCategoryTap: { box in
                performDashboardTransition(.drillForward) {
                    if box.range == .today {
                        activeFilter = .categoryDay(categoryId: box.categoryId, range: .today, date: Date())
                    } else {
                        activeFilter = .category(categoryId: box.categoryId, range: box.range)
                    }
                }
            },
            onBack: { navigateBack() },
            selectedFilterTitle: activeFilterTitle,
            collapsedDays: $collapsedMonthDays,
            itemListRowStatus: viewModel.itemListRowStatus,
            onItemTap: { itemList in
                navigationPath.append(itemListRoute(for: itemList))
            },
            onTogglePaid: { viewModel.togglePaid(for: $0) },
            onDelete: { viewModel.deleteItemList($0) },
            showingFullMonth: showingFullMonthBinding,
            transitionMode: contentTransitionMode,
            contentRangeKey: activeContentRangeKey,
            hasItemsOutsideToday: viewModel.hasItemsOutsideToday,
            onOpenSettings: { viewModel.openSettings() },
            toast: $viewModel.toast,
            bottomInset: { bottomInset }
        )
        .animation(AnimationHelper.smoothSpring, value: selectedCalendarDay == nil)
        .animation(AnimationHelper.quickEase, value: viewMode == .calendar)
        .onChange(of: viewModel.currentGroup?.id) { _, _ in
            collapsedMonthDays.removeAll()
            withAnimation(AnimationHelper.quickEase) { activeFilter = nil }
        }
        .onChange(of: viewModel.showingFullMonth) { _, isShowingMonth in
            let targetRange: DashboardCategoryRange = isShowingMonth ? .month : .today
            withAnimation(AnimationHelper.quickEase) {
                switch activeFilter {
                case .all:
                    activeFilter = targetRange == .today ? .allDay(range: .today, date: Date()) : .all(.month)
                case .allDay:
                    activeFilter = targetRange == .today ? .allDay(range: .today, date: Date()) : .all(.month)
                case .category(let categoryId, _):
                    guard viewModel.categoryBox(forCategoryId: categoryId, in: targetRange) != nil else {
                        activeFilter = nil; break
                    }
                    activeFilter = targetRange == .today
                        ? .categoryDay(categoryId: categoryId, range: .today, date: Date())
                        : .category(categoryId: categoryId, range: .month)
                case .categoryDay(let categoryId, _, _):
                    guard viewModel.categoryBox(forCategoryId: categoryId, in: targetRange) != nil else {
                        activeFilter = nil; break
                    }
                    activeFilter = targetRange == .today
                        ? .categoryDay(categoryId: categoryId, range: .today, date: Date())
                        : .category(categoryId: categoryId, range: .month)
                case nil:
                    break
                }
            }
        }
        .onChange(of: viewModel.selectedMonthAnchor) { _, _ in
            refreshActiveFilter()
        }
        .onChange(of: viewModel.itemListTotals) { _, _ in
            refreshActiveFilter()
        }
        .onChange(of: viewModel.pendingFilter) { _, _ in
            refreshActiveFilter()
        }
    }

    private var hasVisibleItemListsInSelectedRange: Bool {
        let visibleRangeItemLists = viewModel.showingFullMonth
            ? viewModel.filteredMonthItemLists
            : viewModel.filteredTodayItemLists
        return !visibleRangeItemLists.isEmpty
    }

    private var showingFullMonthBinding: Binding<Bool> {
        Binding(
            get: { viewModel.showingFullMonth },
            set: { newValue in
                let mode: DashboardContentTransitionMode = newValue ? .monthRange : .todayRange
                performDashboardTransition(mode) {
                    viewModel.showingFullMonth = newValue
                }
            }
        )
    }

    private func performDashboardTransition(
        _ mode: DashboardContentTransitionMode,
        mutation: @escaping @MainActor () -> Void
    ) {
        pendingContentTransitionTask?.cancel()

        let applyMutation = {
            withAnimation(AnimationHelper.smoothSpring) {
                mutation()
            }
        }

        guard contentTransitionMode != mode else {
            applyMutation()
            return
        }

        contentTransitionMode = mode

        pendingContentTransitionTask = Task { @MainActor in
            await Task.yield()
            guard !Task.isCancelled else { return }
            applyMutation()
        }
    }

    private func refreshActiveFilter() {
        switch resolvedActiveFilter {
        case .all:
            break
        case .allDay(let range, let date):
            if viewModel.filteredItemLists(in: range, day: date).isEmpty {
                withAnimation(AnimationHelper.smoothSpring) {
                    activeFilter = range == .today ? nil : .all(range)
                }
            }
        case .category(let categoryId, let range):
            guard !viewModel.hasCategoryContext(forCategoryId: categoryId, in: range) else { return }
            withAnimation(AnimationHelper.smoothSpring) { activeFilter = nil }
        case .categoryDay(let categoryId, let range, let date):
            if viewModel.filteredItemLists(forCategoryId: categoryId, in: range, day: date).isEmpty {
                withAnimation(AnimationHelper.smoothSpring) {
                    activeFilter = range == .today ? nil : .category(categoryId: categoryId, range: range)
                }
            }
        case nil:
            break
        }
    }

    private var activeFilteredItemLists: [SDItemList] {
        switch resolvedActiveFilter {
        case .all:
            return []
        case .allDay(let range, let date):
            return viewModel.filteredItemLists(in: range, day: date)
        case .category:
            return []  // category shows date rows, not expense rows directly
        case .categoryDay(let categoryId, let range, let date):
            return viewModel.filteredItemLists(forCategoryId: categoryId, in: range, day: date)
        case nil:
            return []
        }
    }

    private var activeFilterTitle: String? {
        switch resolvedActiveFilter {
        case .all:
            return LocalizationKey.General.all.localized
        case .allDay:
            return LocalizationKey.General.all.localized
        case .category(let categoryId, let range):
            return activeCategoryBox?.categoryName ?? viewModel.categoryDisplayName(forCategoryId: categoryId, in: range)
        case .categoryDay(let categoryId, let range, _):
            return activeCategoryBox?.categoryName ?? viewModel.categoryDisplayName(forCategoryId: categoryId, in: range)
        case nil:
            return nil
        }
    }

    private var activeFilterIcon: String? {
        switch resolvedActiveFilter {
        case .all:
            return "square.grid.2x2.fill"
        case .allDay:
            return "square.grid.2x2.fill"
        case .category(let categoryId, let range), .categoryDay(let categoryId, let range, _):
            return activeCategoryBox?.categoryIcon ?? viewModel.categoryDisplayIcon(forCategoryId: categoryId, in: range)
        case nil:
            return nil
        }
    }

    private var activeFilterColorHex: String? {
        switch resolvedActiveFilter {
        case .all:
            return nil
        case .allDay:
            return nil
        case .category(let categoryId, let range), .categoryDay(let categoryId, let range, _):
            return activeCategoryBox?.categoryColorHex ?? viewModel.categoryDisplayColorHex(forCategoryId: categoryId, in: range)
        case nil:
            return nil
        }
    }

    private var selectedScopeTitle: String? {
        guard let activeFilter else { return nil }
        switch activeFilter {
        case .all:
            return LocalizationKey.General.all.localized
        case .allDay(_, let date):
            return viewModel.dayFilterLabel(for: date)
        case .category(let categoryId, let range), .categoryDay(let categoryId, let range, _):
            return activeCategoryBox?.categoryName ?? viewModel.categoryDisplayName(forCategoryId: categoryId, in: range)
        }
    }

    private var selectedScopeIcon: String? {
        guard let activeFilter else { return nil }
        switch activeFilter {
        case .all:
            return "square.grid.2x2.fill"
        case .allDay:
            return "calendar"
        case .category(let categoryId, let range), .categoryDay(let categoryId, let range, _):
            return activeCategoryBox?.categoryIcon ?? viewModel.categoryDisplayIcon(forCategoryId: categoryId, in: range)
        }
    }

    private var selectedScopeColorHex: String? {
        guard let activeFilter else { return nil }
        switch activeFilter {
        case .all:
            return nil
        case .allDay:
            return nil
        case .category(let categoryId, let range), .categoryDay(let categoryId, let range, _):
            return activeCategoryBox?.categoryColorHex ?? viewModel.categoryDisplayColorHex(forCategoryId: categoryId, in: range)
        }
    }

    private var resolvedActiveFilter: DashboardActiveFilter? {
        if let activeFilter {
            return activeFilter
        }

        guard shouldAutoSelectAllForUncategorizedOnly else {
            return nil
        }

        return .all(viewModel.showingFullMonth ? .month : .today)
    }

    private var shouldAutoSelectAllForUncategorizedOnly: Bool {
        hasVisibleItemListsInSelectedRange && viewModel.visibleCategoryBoxes.isEmpty
    }

    private func navigateBack() {
        performDashboardTransition(.drillBackward) {
            if case .allDay(let range, _) = activeFilter {
                activeFilter = range == .today ? nil : .all(range)
            } else if case .categoryDay(let categoryId, let range, _) = activeFilter {
                activeFilter = range == .today ? nil : .category(categoryId: categoryId, range: range)
            } else {
                activeFilter = nil
            }
        }
    }

    private var bottomInset: some View {
        DashboardBottomInset(
            heroSection: {
                Group {
                    if !isSearchActive {
                        DashboardHeroSection(
                            showingFullMonth: viewModel.showingFullMonth,
                            monthLabel: viewModel.monthHeroLabel,
                            monthTotal: viewModel.formattedCachedMonthTotal(),
                            todayTotal: viewModel.formattedTodayTotal,
                            overrideLabel: activeDayHeroLabel
                                ?? activeCategoryBox?.categoryName,
                            overrideLabelUsesCostOfPrefix: activeDayHeroLabel == nil,
                            overrideTotal: activeAllDayContext.map {
                                viewModel.formattedTotal(in: $0.range, day: $0.date)
                            } ?? activeCategoryDayContext.map {
                                viewModel.formattedTotal(forCategoryId: $0.categoryId, in: $0.range, day: $0.date)
                            } ?? activeCategoryBox.map { viewModel.formattedCurrency($0.paidAmount) },
                            budgetLimitText: activeCategoryBox.flatMap { viewModel.formattedBudgetLimitText(for: $0) },
                            budgetFillRatio: activeCategoryBox.flatMap { viewModel.budgetFillRatio(for: $0) },
                            showsOverLimitBadge: activeCategoryBox.map { viewModel.isOverBudget(for: $0) } ?? false,
                            overrideActionColor: activeCategoryBox.flatMap { Color(hex: $0.categoryColorHex) },
                            onAddExpense: {
                                addItemListTrigger = AddItemListTrigger(
                                    initialDate: resolvedInitialEntryDate,
                                    preferredCategoryId: activeCategoryBox?.categoryId
                                )
                            }
                        )
                    }
                }
            },
            bottomBar: {
                DashboardBottomBarView(
                    searchText: $viewModel.searchQuery,
                    isSearchActive: $isSearchActive,
                    dismissKeyboardToken: dismissSearchKeyboardToken,
                    currentGroup: viewModel.currentGroup,
                    availableGroups: viewModel.availableGroups,
                    userId: viewModel.currentUser?.id,
                    isChangingGroup: viewModel.isChangingGroup,
                    isFilterActive: viewModel.isCustomMonthFilterActive || viewModel.hasActivePendingFilter,
                    selectedScopeTitle: selectedScopeTitle,
                    selectedScopeIcon: selectedScopeIcon,
                    selectedScopeColorHex: selectedScopeColorHex,
                    onGroupChange: { newGroup in Task { await viewModel.changeGroup(to: newGroup) } },
                    onGroupCreated: { newGroup in viewModel.addGroup(newGroup) },
                    onDeleteGroup: { deletedGroup in try await viewModel.deleteGroup(deletedGroup) },
                    onSelectedScopeTap: { navigateBack() },
                    onOpenFilters: { showingFiltersSheet = true }
                )
            }
        )
    }

    private var activeCategoryBox: DashboardCategoryBoxData? {
        switch resolvedActiveFilter {
        case .category(let categoryId, let range), .categoryDay(let categoryId, let range, _):
            return viewModel.categoryBox(forCategoryId: categoryId, in: range)
        default:
            return nil
        }
    }

    private var activeAllDayContext: (range: DashboardCategoryRange, date: Date)? {
        guard case .allDay(let range, let date) = resolvedActiveFilter else { return nil }
        return (range, date)
    }

    // Non-nil when drill down to a specific day within a category
    private var activeCategoryDayContext: (categoryId: UUID, range: DashboardCategoryRange, date: Date)? {
        guard case .categoryDay(let categoryId, let range, let date) = resolvedActiveFilter else { return nil }
        return (categoryId, range, date)
    }

    private var activeDayHeroLabel: String? {
        activeAllDayContext.map { viewModel.heroCostLabel(for: $0.date) }
            ?? activeCategoryDayContext.flatMap {
                $0.range == .month ? viewModel.heroCostLabel(for: $0.date) : nil
            }
    }

    private var resolvedInitialEntryDate: Date {
        selectedCalendarDay
            ?? activeAllDayContext?.date
            ?? activeCategoryDayContext?.date
            ?? Date()
    }

    private var showsDateRows: Bool {
        switch resolvedActiveFilter {
        case .all, .category:
            return true
        default:
            return false
        }
    }

    private var activeDateRows: [DashboardDayBoxData] {
        switch resolvedActiveFilter {
        case .all(let range):
            return viewModel.dayBoxes(in: range)
        case .category(let categoryId, let range):
            return viewModel.dayBoxes(forCategoryId: categoryId, in: range)
        default:
            return []
        }
    }

    private var activeContentRangeKey: String {
        let range: DashboardCategoryRange? = switch resolvedActiveFilter {
        case .all(let range):
            range
        case .allDay(let range, _):
            range
        case .category(_, let range):
            range
        case .categoryDay(_, let range, _):
            range
        case nil:
            nil
        }

        let resolvedRange = range ?? (viewModel.showingFullMonth ? .month : .today)
        return resolvedRange == .month ? "month" : "today"
    }

    // View picker: filter pill on left, settings icon on right

    private var dayListPanel: some View {
        DashboardDayPanel(
            selectedCalendarDay: selectedCalendarDay,
            listDragOffset: listDragOffset,
            content: {
                Group {
                    if let day = selectedCalendarDay {
                        dayExpenseList(for: day, isCompact: true)
                    }
                }
            },
            onDragChanged: { listDragOffset = $0 },
            onDismiss: {
                withAnimation(AnimationHelper.smoothSpring) {
                    selectedCalendarDay = nil
                }
                listDragOffset = 0
            },
            onResetDrag: {
                withAnimation(AnimationHelper.smoothSpring) {
                    listDragOffset = 0
                }
            }
        )
    }

    private func dayExpenseList(for date: Date, onItemTap: ((SDItemList) -> Void)? = nil, isCompact: Bool = false) -> some View {
        let cal = Calendar.current
        let source = viewModel.itemLists.filter {
            cal.isDate($0.date, inSameDayAs: date)
        }
        return ExpenseListView(
            itemLists: viewModel.filteredSearchResults(from: source),
            getFormattedAmount: { viewModel.formattedPaid(for: $0) },
            getFormattedUnpaidAmount: { viewModel.formattedUnpaid(for: $0) },
            getSearchSummary: { viewModel.formattedSearchSummary(for: $0) },
            getSearchMatchedSubtotal: { viewModel.formattedSearchMatchedSubtotal(for: $0) },
            getSearchMatchedUnpaid: { viewModel.formattedSearchMatchedUnpaid(for: $0) },
            getSearchMatchedRowStatus: { viewModel.searchMatchedRowStatus(for: $0) },
            itemListRowStatus: viewModel.itemListRowStatus,
            onItemTap: { item in
                if let customTap = onItemTap {
                    customTap(item)
                } else {
                    navigationPath.append(itemListRoute(for: item))
                }
            },
            onTogglePaid: { viewModel.togglePaid(for: $0) },
            onRefresh: { await viewModel.refreshData() },
            onDelete: { viewModel.deleteItemList($0) },
            isCompact: isCompact
        )
        .frame(maxHeight: .infinity)
    }

}

private extension DashboardView {
    func itemListRoute(for itemList: SDItemList) -> DashboardItemListRoute {
        DashboardItemListRoute(
            itemListId: itemList.id,
            destination: viewModel.prefersSingleEntryEditor(for: itemList) ? .singleEntryEditor : .itemListDetail,
            highlightedSearchQuery: viewModel.hasActiveSearch ? viewModel.searchQuery : nil,
            showsPendingItemsOnly: viewModel.hasActivePendingFilter
        )
    }
}

private extension DashboardActiveFilter {
    var categoryId: UUID? {
        switch self {
        case .category(let categoryId, _), .categoryDay(let categoryId, _, _):
            return categoryId
        default:
            return nil
        }
    }
}

// MARK: - Preview
#Preview {
    DashboardView()
}
