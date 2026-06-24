import SwiftUI

private extension AnyTransition {
    static var dashboardForwardDrill: AnyTransition {
        .push(from: .trailing).combined(with: .opacity)
    }

    static var dashboardBackwardDrill: AnyTransition {
        .push(from: .leading).combined(with: .opacity)
    }

    static var dashboardTodayRangeSwap: AnyTransition {
        .asymmetric(
            insertion: .move(edge: .leading).combined(with: .opacity),
            removal: .move(edge: .leading).combined(with: .opacity)
        )
    }

    static var dashboardMonthRangeSwap: AnyTransition {
        .asymmetric(
            insertion: .move(edge: .trailing).combined(with: .opacity),
            removal: .move(edge: .trailing).combined(with: .opacity)
        )
    }
}

enum DashboardContentTransitionMode {
    case drillForward
    case drillBackward
    case todayRange
    case monthRange
}

struct DashboardLoadingState: View {
    var body: some View {
        Color(.systemBackground).ignoresSafeArea()
    }
}

struct DashboardErrorState: View {
    let message: String
    let onRetry: () -> Void

    var body: some View {
        VStack(spacing: AppConstants.UserInterface.padding) {
            Image(systemName: "exclamationmark.triangle")
                .font(.largeTitle)
                .foregroundColor(.orange)

            Text(LocalizationKey.General.error.localized)
                .font(.title2)
                .fontWeight(.semibold)

            Text(message)
                .font(.body)
                .foregroundColor(.secondary)
                .multilineTextAlignment(.center)

            Button(LocalizationKey.General.retry.localized, action: onRetry)
                .buttonStyle(.borderedProminent)
        }
        .padding(AppConstants.UserInterface.largePadding)
        .frame(maxWidth: .infinity, maxHeight: .infinity)
    }
}

struct DashboardChangingGroupOverlay: View {
    var body: some View {
        Color.black.opacity(0.3)
            .ignoresSafeArea()
            .overlay {
                VStack(spacing: 12) {
                    ProgressView()
                        .scaleEffect(1.2)
                        .tint(.white)

                    Text(LocalizationKey.Dashboard.changingGroup.localized)
                        .font(.subheadline)
                        .foregroundColor(.white)
                }
            }
    }
}

struct DashboardHeroSection: View {
    let showingFullMonth: Bool
    let monthLabel: String
    let monthTotal: String
    let todayTotal: String
    var overrideLabel: String? = nil
    var overrideLabelUsesCostOfPrefix: Bool = true
    var overrideTotal: String? = nil
    var budgetLimitText: String? = nil
    var budgetFillRatio: Double? = nil
    var showsOverLimitBadge = false
    var overrideActionColor: Color? = nil
    let onAddExpense: () -> Void

    private var displayLabel: String {
        if let overrideLabel {
            return overrideLabelUsesCostOfPrefix
                ? LocalizationKey.Item.costOf.localized(with: overrideLabel)
                : overrideLabel
        }
        return showingFullMonth ? monthLabel : LocalizationKey.Dashboard.costToday.localized
    }

    private var displayTotal: String {
        if let overrideTotal { return overrideTotal }
        return showingFullMonth ? monthTotal : todayTotal
    }

    var body: some View {
        TotalSpentCardView(
            label: displayLabel,
            totalAmount: displayTotal,
            onAddExpense: onAddExpense,
            actionColor: overrideActionColor ?? .accentColor,
            budgetFillRatio: budgetFillRatio
        ) {
            if let budgetLimitText {
                HStack(spacing: 6) {
                    if showsOverLimitBadge {
                        Image(systemName: "exclamationmark.triangle.fill")
                            .font(.caption.weight(.semibold))
                            .foregroundStyle(.orange)
                    }

                    Text(budgetLimitText)
                        .font(.footnote.weight(.medium))
                        .foregroundStyle(.secondary)
                        .lineLimit(1)
                        .minimumScaleFactor(0.85)
                }
                .padding(.top, 2)
            }
        }
        .padding(.horizontal, AppConstants.UserInterface.padding)
        .padding(.top, AppConstants.UserInterface.padding)
        .padding(.bottom, 4)
        .animation(AnimationHelper.smoothSpring, value: showingFullMonth)
    }
}

struct DashboardBottomInset<Hero: View, Bar: View>: View {
    let heroSection: Hero
    let bottomBar: Bar

    init(
        @ViewBuilder heroSection: () -> Hero,
        @ViewBuilder bottomBar: () -> Bar
    ) {
        self.heroSection = heroSection()
        self.bottomBar = bottomBar()
    }

    var body: some View {
        VStack(spacing: 0) {
            heroSection
            bottomBar
        }
        .background {
            ZStack(alignment: .top) {
                Color(.systemBackground)
                    .ignoresSafeArea(edges: .bottom)

                LinearGradient(
                    colors: [
                        Color.black.opacity(0.05),
                        Color.black.opacity(0.02),
                        Color.clear
                    ],
                    startPoint: .top,
                    endPoint: .bottom
                )
                .frame(height: 18)
                .allowsHitTesting(false)
            }
        }
    }
}

struct DashboardTopChromeView: View {
    private enum Metrics {
        static let baseHeight: CGFloat = 56
    }

    @Binding var showingFullMonth: Bool
    let hasItemsOutsideToday: Bool
    let onOpenSettings: () -> Void
    let toast: Binding<ToastMessage?>

    private var showsToast: Bool {
        toast.wrappedValue != nil
    }

    var body: some View {
        DashboardTopBarView(
            showingFullMonth: $showingFullMonth,
            hasItemsOutsideToday: hasItemsOutsideToday,
            onOpenSettings: onOpenSettings
        )
        .opacity(showsToast ? 0 : 1)
        .allowsHitTesting(!showsToast)
        .overlay(alignment: .top) {
            if showsToast {
                ToastHost(
                    toast: toast,
                    topPadding: AppConstants.UserInterface.smallPadding
                )
                .transition(.move(edge: .top).combined(with: .opacity))
                .zIndex(1)
            }
        }
        .frame(maxWidth: .infinity, minHeight: Metrics.baseHeight, maxHeight: Metrics.baseHeight, alignment: .top)
        .background(Color(.systemBackground))
        .animation(AnimationHelper.smoothSpring, value: showsToast)
    }
}

struct DashboardMainContent<EmptyState: View, BottomInset: View>: View {
    let allFormattedAmount: String
    let categoryBoxes: [DashboardCategoryBoxData]
    let hasVisibleItemLists: Bool
    let getFormattedAmount: (DashboardCategoryBoxData) -> String
    // Date rows (intermediate level: category → days)
    let showsDateRows: Bool
    let dateRows: [DashboardDayBoxData]
    let getDateRowAmount: (DashboardDayBoxData) -> String
    let getDateRowUnpaidAmount: (DashboardDayBoxData) -> String?
    let onDateRowTap: (DashboardDayBoxData) -> Void
    // Expense list (deepest level: day → expense rows)
    let filteredItemLists: [SDItemList]
    let getItemListCategoryContext: (SDItemList) -> String?
    let getItemListAmount: (SDItemList) -> String
    let getItemListUnpaidAmount: (SDItemList) -> String?
    let getDayTotal: (Date) -> String
    let getSearchSummary: (SDItemList) -> String?
    let getSearchMatchedSubtotal: (SDItemList) -> String?
    let getSearchMatchedUnpaid: (SDItemList) -> String?
    let getSearchMatchedRowStatus: (SDItemList) -> ItemListRowStatus?
    let hideExpenseListSectionHeaders: Bool
    let customEmptyState: EmptyState
    let showCustomEmptyState: Bool
    let onRefresh: () async -> Void
    let onAllTap: () -> Void
    let onCategoryTap: (DashboardCategoryBoxData) -> Void
    let onBack: (() -> Void)?
    let selectedFilterTitle: String?
    @Binding var collapsedDays: Set<Date>
    let itemListRowStatus: [UUID: ItemListRowStatus]
    let onItemTap: (SDItemList) -> Void
    let onTogglePaid: (SDItemList) -> Void
    let onDelete: (SDItemList) -> Void
    @Binding var showingFullMonth: Bool
    let transitionMode: DashboardContentTransitionMode
    let hasItemsOutsideToday: Bool
    let onOpenSettings: () -> Void
    let toast: Binding<ToastMessage?>
    let bottomInset: BottomInset

    private var isShowingFilteredList: Bool {
        selectedFilterTitle != nil
    }

    private var contentTransition: AnyTransition {
        switch transitionMode {
        case .drillForward:
            .dashboardForwardDrill
        case .drillBackward:
            .dashboardBackwardDrill
        case .todayRange:
            .dashboardTodayRangeSwap
        case .monthRange:
            .dashboardMonthRangeSwap
        }
    }

    private var filteredListContextID: String {
        return [
            selectedFilterTitle ?? "none",
            showingFullMonth ? "month" : "today",
            showsDateRows ? "daterows" : "expenselist"
        ].joined(separator: "#")
    }

    init(
        allFormattedAmount: String,
        categoryBoxes: [DashboardCategoryBoxData],
        hasVisibleItemLists: Bool,
        getFormattedAmount: @escaping (DashboardCategoryBoxData) -> String,
        showsDateRows: Bool,
        dateRows: [DashboardDayBoxData],
        getDateRowAmount: @escaping (DashboardDayBoxData) -> String,
        getDateRowUnpaidAmount: @escaping (DashboardDayBoxData) -> String?,
        onDateRowTap: @escaping (DashboardDayBoxData) -> Void,
        filteredItemLists: [SDItemList],
        getItemListCategoryContext: @escaping (SDItemList) -> String? = { _ in nil },
        getItemListAmount: @escaping (SDItemList) -> String,
        getItemListUnpaidAmount: @escaping (SDItemList) -> String?,
        getDayTotal: @escaping (Date) -> String,
        getSearchSummary: @escaping (SDItemList) -> String?,
        getSearchMatchedSubtotal: @escaping (SDItemList) -> String?,
        getSearchMatchedUnpaid: @escaping (SDItemList) -> String?,
        getSearchMatchedRowStatus: @escaping (SDItemList) -> ItemListRowStatus?,
        hideExpenseListSectionHeaders: Bool,
        @ViewBuilder customEmptyState: () -> EmptyState,
        showCustomEmptyState: Bool,
        onRefresh: @escaping () async -> Void,
        onAllTap: @escaping () -> Void,
        onCategoryTap: @escaping (DashboardCategoryBoxData) -> Void,
        onBack: (() -> Void)? = nil,
        selectedFilterTitle: String?,
        collapsedDays: Binding<Set<Date>>,
        itemListRowStatus: [UUID: ItemListRowStatus],
        onItemTap: @escaping (SDItemList) -> Void,
        onTogglePaid: @escaping (SDItemList) -> Void,
        onDelete: @escaping (SDItemList) -> Void,
        showingFullMonth: Binding<Bool>,
        transitionMode: DashboardContentTransitionMode,
        hasItemsOutsideToday: Bool,
        onOpenSettings: @escaping () -> Void,
        toast: Binding<ToastMessage?>,
        @ViewBuilder bottomInset: () -> BottomInset
    ) {
        self.allFormattedAmount = allFormattedAmount
        self.categoryBoxes = categoryBoxes
        self.hasVisibleItemLists = hasVisibleItemLists
        self.getFormattedAmount = getFormattedAmount
        self.showsDateRows = showsDateRows
        self.dateRows = dateRows
        self.getDateRowAmount = getDateRowAmount
        self.getDateRowUnpaidAmount = getDateRowUnpaidAmount
        self.onDateRowTap = onDateRowTap
        self.filteredItemLists = filteredItemLists
        self.getItemListCategoryContext = getItemListCategoryContext
        self.getItemListAmount = getItemListAmount
        self.getItemListUnpaidAmount = getItemListUnpaidAmount
        self.getDayTotal = getDayTotal
        self.getSearchSummary = getSearchSummary
        self.getSearchMatchedSubtotal = getSearchMatchedSubtotal
        self.getSearchMatchedUnpaid = getSearchMatchedUnpaid
        self.getSearchMatchedRowStatus = getSearchMatchedRowStatus
        self.hideExpenseListSectionHeaders = hideExpenseListSectionHeaders
        self.customEmptyState = customEmptyState()
        self.showCustomEmptyState = showCustomEmptyState
        self.onRefresh = onRefresh
        self.onAllTap = onAllTap
        self.onCategoryTap = onCategoryTap
        self.onBack = onBack
        self.selectedFilterTitle = selectedFilterTitle
        self._collapsedDays = collapsedDays
        self.itemListRowStatus = itemListRowStatus
        self.onItemTap = onItemTap
        self.onTogglePaid = onTogglePaid
        self.onDelete = onDelete
        self._showingFullMonth = showingFullMonth
        self.transitionMode = transitionMode
        self.hasItemsOutsideToday = hasItemsOutsideToday
        self.onOpenSettings = onOpenSettings
        self.toast = toast
        self.bottomInset = bottomInset()
    }

    var body: some View {
        ZStack {
            Color(.systemGroupedBackground)
                .ignoresSafeArea()

            ZStack(alignment: .top) {
                if showsDateRows && !dateRows.isEmpty {
                    DashboardDateRowsView(
                        rows: dateRows,
                        getFormattedAmount: getDateRowAmount,
                        getFormattedUnpaidAmount: getDateRowUnpaidAmount,
                        onSelect: onDateRowTap,
                        onRefresh: onRefresh
                    )
                    .id(filteredListContextID)
                    .zIndex(1)
                    .transition(contentTransition)
                } else if showsDateRows {
                    customEmptyState
                        .frame(maxWidth: .infinity, maxHeight: .infinity, alignment: .top)
                        .padding(.horizontal, AppConstants.UserInterface.padding)
                        .padding(.top, AppConstants.UserInterface.padding)
                        .zIndex(1)
                        .transition(contentTransition)
                } else if selectedFilterTitle != nil {
                    ExpenseListView(
                        itemLists: filteredItemLists,
                        getCategoryContext: getItemListCategoryContext,
                        getFormattedAmount: getItemListAmount,
                        getFormattedUnpaidAmount: getItemListUnpaidAmount,
                        getSearchSummary: getSearchSummary,
                        getSearchMatchedSubtotal: getSearchMatchedSubtotal,
                        getSearchMatchedUnpaid: getSearchMatchedUnpaid,
                        getSearchMatchedRowStatus: getSearchMatchedRowStatus,
                        itemListRowStatus: itemListRowStatus,
                        onItemTap: onItemTap,
                        onTogglePaid: onTogglePaid,
                        onRefresh: onRefresh,
                        onDelete: onDelete,
                        customEmptyState: { customEmptyState },
                        showCustomEmptyState: showCustomEmptyState,
                        getDayTotal: getDayTotal,
                        hideSectionHeaders: hideExpenseListSectionHeaders,
                        collapsedDays: $collapsedDays,
                        allowsDayCollapse: !hideExpenseListSectionHeaders && showingFullMonth
                    )
                    .id(filteredListContextID)
                    .zIndex(2)
                    .transition(contentTransition)
                } else {
                    DashboardCategoryBoardView(
                        boxes: categoryBoxes,
                        hasVisibleItemLists: hasVisibleItemLists,
                        allFormattedAmount: allFormattedAmount,
                        getFormattedAmount: getFormattedAmount,
                        onRefresh: onRefresh,
                        customEmptyState: { customEmptyState },
                        showCustomEmptyState: showCustomEmptyState,
                        onSelectAll: onAllTap,
                        onSelect: onCategoryTap
                    )
                    .zIndex(0)
                    .transition(contentTransition)
                }
            }
            .animation(AnimationHelper.dashboardDrill, value: isShowingFilteredList)
            .animation(AnimationHelper.dashboardDrill, value: showsDateRows)
            .frame(maxWidth: .infinity, maxHeight: .infinity, alignment: .top)
            .background(Color(.secondarySystemBackground))
            .clipShape(RoundedRectangle(cornerRadius: 24, style: .continuous))
            .padding(.horizontal, AppConstants.UserInterface.padding)
            .padding(.bottom, 2)
        }
        .frame(maxWidth: .infinity, maxHeight: .infinity, alignment: .top)
        .overlay(alignment: .leading) {
            if isShowingFilteredList, let onBack {
                Color.clear
                    .frame(width: 28)
                    .frame(maxHeight: .infinity)
                    .contentShape(Rectangle())
                    .ignoresSafeArea()
                    .gesture(
                        DragGesture(minimumDistance: 20, coordinateSpace: .local)
                            .onEnded { value in
                                guard value.translation.width > 60,
                                      abs(value.translation.width) > abs(value.translation.height)
                                else { return }
                                onBack()
                            }
                    )
            }
        }
        .safeAreaInset(edge: .top, spacing: 0) {
            DashboardTopChromeView(
                showingFullMonth: $showingFullMonth,
                hasItemsOutsideToday: hasItemsOutsideToday,
                onOpenSettings: onOpenSettings,
                toast: toast
            )
        }
        .safeAreaInset(edge: .bottom, spacing: 0) {
            bottomInset
        }
    }
}

struct DashboardDayPanel<Content: View>: View {
    let selectedCalendarDay: Date?
    let listDragOffset: CGFloat
    let content: Content
    let onDragChanged: (CGFloat) -> Void
    let onDismiss: () -> Void
    let onResetDrag: () -> Void

    init(
        selectedCalendarDay: Date?,
        listDragOffset: CGFloat,
        @ViewBuilder content: () -> Content,
        onDragChanged: @escaping (CGFloat) -> Void,
        onDismiss: @escaping () -> Void,
        onResetDrag: @escaping () -> Void
    ) {
        self.selectedCalendarDay = selectedCalendarDay
        self.listDragOffset = listDragOffset
        self.content = content()
        self.onDragChanged = onDragChanged
        self.onDismiss = onDismiss
        self.onResetDrag = onResetDrag
    }

    var body: some View {
        VStack(spacing: 0) {
            Capsule()
                .fill(Color(.systemGray4))
                .frame(width: 36, height: 5)
                .padding(.top, 6)
                .padding(.bottom, 2)
                .frame(maxWidth: .infinity)

            if selectedCalendarDay != nil {
                ZStack(alignment: .bottom) {
                    content
                        .contentMargins(.top, 0, for: .scrollContent)

                    LinearGradient(
                        colors: [Color(.systemGray5).opacity(0), Color(.systemGray5)],
                        startPoint: .top,
                        endPoint: .bottom
                    )
                    .frame(height: 10)
                    .allowsHitTesting(false)
                }
            }
        }
        .background(Color(.systemGray5))
        .clipShape(RoundedRectangle(cornerRadius: 16, style: .continuous))
        .shadow(color: .black.opacity(0.15), radius: 12, x: 0, y: -4)
        .offset(y: listDragOffset)
        .gesture(
            DragGesture()
                .onChanged { value in
                    onDragChanged(max(0, value.translation.height))
                }
                .onEnded { value in
                    if value.translation.height > 80 {
                        onDismiss()
                    } else {
                        onResetDrag()
                    }
                }
        )
        .frame(maxHeight: .infinity)
    }
}
