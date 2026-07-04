import SwiftUI

struct DashboardCategoryBoardView<EmptyState: View>: View {
    let boxes: [DashboardCategoryBoxData]
    let hasVisibleItemLists: Bool
    let allFormattedAmount: String
    let getFormattedAmount: (DashboardCategoryBoxData) -> String
    let onRefresh: () async -> Void
    let customEmptyState: EmptyState
    let showCustomEmptyState: Bool
    let onSelectAll: () -> Void
    let onSelect: (DashboardCategoryBoxData) -> Void

    init(
        boxes: [DashboardCategoryBoxData],
        hasVisibleItemLists: Bool,
        allFormattedAmount: String,
        getFormattedAmount: @escaping (DashboardCategoryBoxData) -> String,
        onRefresh: @escaping () async -> Void,
        @ViewBuilder customEmptyState: () -> EmptyState,
        showCustomEmptyState: Bool = true,
        onSelectAll: @escaping () -> Void,
        onSelect: @escaping (DashboardCategoryBoxData) -> Void
    ) {
        self.boxes = boxes
        self.hasVisibleItemLists = hasVisibleItemLists
        self.allFormattedAmount = allFormattedAmount
        self.getFormattedAmount = getFormattedAmount
        self.onRefresh = onRefresh
        self.customEmptyState = customEmptyState()
        self.showCustomEmptyState = showCustomEmptyState
        self.onSelectAll = onSelectAll
        self.onSelect = onSelect
    }

    private let rowSpacing: CGFloat = 12
    private let columnSpacing: CGFloat = 12

    var body: some View {
        ScrollView {
            if hasVisibleItemLists && boxes.isEmpty {
                VStack(spacing: rowSpacing) {
                    DashboardAllCategoryBoxView(style: .fullWidth, onTap: onSelectAll)
                }
                .padding(.horizontal, AppConstants.UserInterface.padding)
                .padding(.top, AppConstants.UserInterface.padding)
                .padding(.bottom, 32)
            } else if boxes.isEmpty && showCustomEmptyState {
                customEmptyState
                    .padding(.horizontal, AppConstants.UserInterface.padding)
            } else if boxes.isEmpty && !showCustomEmptyState {
                DashboardCategoryBoardEmptyState()
                    .frame(maxWidth: .infinity)
                    .padding(.top, 72)
                    .padding(.horizontal, AppConstants.UserInterface.padding)
            } else {
                VStack(alignment: .leading, spacing: rowSpacing) {
                    Text(LocalizationKey.Dashboard.expensesByCategory.localized)
                        .font(.footnote.weight(.semibold))
                        .foregroundStyle(.secondary)
                        .textCase(.uppercase)
                        .padding(.bottom, 2)

                    ForEach(rows, id: \.id) { row in
                        rowView(row)
                    }
                }
                .animation(AnimationHelper.smoothSpring, value: rows.map(\.id))
                .padding(.horizontal, AppConstants.UserInterface.padding)
                .padding(.top, AppConstants.UserInterface.padding)
                .padding(.bottom, 32)
            }
        }
        .scrollIndicators(.hidden)
        .contentMargins(.top, 0, for: .scrollContent)
        .refreshable {
            await onRefresh()
            try? await Task.sleep(for: .milliseconds(180))
        }
        .frame(maxWidth: .infinity, maxHeight: .infinity, alignment: .top)
    }

    @ViewBuilder
    private func rowView(_ row: DashboardCategoryBoardRow) -> some View {
        switch row {
        case .single(let box):
            DashboardCategoryBoxView(
                data: box,
                formattedAmount: getFormattedAmount(box),
                displayStyle: .hero,
                onTap: { onSelect(box) }
            )
            .id(box.id)
        case .pair(let leading, let trailing):
            HStack(alignment: .top, spacing: columnSpacing) {
                DashboardCategoryBoxView(
                    data: leading,
                    formattedAmount: getFormattedAmount(leading),
                    displayStyle: .standard,
                    onTap: { onSelect(leading) }
                )
                .id(leading.id)

                DashboardCategoryBoxView(
                    data: trailing,
                    formattedAmount: getFormattedAmount(trailing),
                    displayStyle: .standard,
                    onTap: { onSelect(trailing) }
                )
                .id(trailing.id)
            }
        case .categoryWithAll(let box):
            HStack(alignment: .top, spacing: columnSpacing) {
                DashboardCategoryBoxView(
                    data: box,
                    formattedAmount: getFormattedAmount(box),
                    displayStyle: .standard,
                    onTap: { onSelect(box) }
                )
                .id(box.id)

                DashboardAllCategoryBoxView(style: .inline, onTap: onSelectAll)
            }
        case .all:
            DashboardAllCategoryBoxView(style: .fullWidth, onTap: onSelectAll)
        }
    }

    private var rows: [DashboardCategoryBoardRow] {
        DashboardCategoryBoxGridLayout.makeRows(from: boxes)
    }
}

// MARK: - Convenience init (no custom empty state)
extension DashboardCategoryBoardView where EmptyState == EmptyView {
    init(
        boxes: [DashboardCategoryBoxData],
        hasVisibleItemLists: Bool,
        allFormattedAmount: String,
        getFormattedAmount: @escaping (DashboardCategoryBoxData) -> String,
        onRefresh: @escaping () async -> Void,
        onSelectAll: @escaping () -> Void,
        onSelect: @escaping (DashboardCategoryBoxData) -> Void
    ) {
        self.init(
            boxes: boxes,
            hasVisibleItemLists: hasVisibleItemLists,
            allFormattedAmount: allFormattedAmount,
            getFormattedAmount: getFormattedAmount,
            onRefresh: onRefresh,
            customEmptyState: { EmptyView() },
            showCustomEmptyState: false,
            onSelectAll: onSelectAll,
            onSelect: onSelect
        )
    }
}

private enum DashboardAllCategoryBoxStyle {
    case fullWidth
    case inline
}

private struct DashboardAllCategoryBoxView: View {
    let style: DashboardAllCategoryBoxStyle
    let onTap: () -> Void

    var body: some View {
        Button(action: onTap) {
            HStack(spacing: 8) {
                Spacer(minLength: 0)

                Image(systemName: "square.grid.2x2.fill")
                    .font(.system(size: 12, weight: .semibold))

                Text(LocalizationKey.General.all.localized)
                    .font(.subheadline.weight(.semibold))
                    .lineLimit(1)

                Spacer(minLength: 0)
            }
            .foregroundStyle(Color.white.opacity(0.96))
            .frame(maxWidth: .infinity, minHeight: minHeight)
            .padding(.horizontal, horizontalPadding)
            .padding(.vertical, verticalPadding)
            .background {
                RoundedRectangle(cornerRadius: AppConstants.UserInterface.cornerRadius, style: .continuous)
                    .fill(backgroundColor)
            }
            .overlay {
                RoundedRectangle(cornerRadius: AppConstants.UserInterface.cornerRadius, style: .continuous)
                    .stroke(Color.black.opacity(0.18), lineWidth: DashboardCategoryBoxBorderMetrics.lineWidth)
            }
        }
        .buttonStyle(PressHapticButtonStyle())
    }

    private var minHeight: CGFloat {
        switch style {
        case .fullWidth:
            44
        case .inline:
            88
        }
    }

    private var horizontalPadding: CGFloat {
        switch style {
        case .fullWidth:
            14
        case .inline:
            15
        }
    }

    private var verticalPadding: CGFloat {
        switch style {
        case .fullWidth:
            4
        case .inline:
            10
        }
    }

    private var backgroundColor: Color {
        Color(.systemGray).opacity(0.9)
    }
}

private enum DashboardCategoryBoardRow {
    case single(DashboardCategoryBoxData)
    case pair(DashboardCategoryBoxData, DashboardCategoryBoxData)
    case categoryWithAll(DashboardCategoryBoxData)
    case all

    var id: String {
        switch self {
        case .single(let box):
            return "single-\(box.id)"
        case .pair(let leading, let trailing):
            return "pair-\(leading.id)-\(trailing.id)"
        case .categoryWithAll(let box):
            return "category-all-\(box.id)"
        case .all:
            return "all"
        }
    }
}

private enum DashboardCategoryBoxGridLayout {
    static func makeRows(from boxes: [DashboardCategoryBoxData]) -> [DashboardCategoryBoardRow] {
        guard let hero = boxes.first else { return [] }

        var rows: [DashboardCategoryBoardRow] = [.single(hero)]
        let remaining = Array(boxes.dropFirst())
        var index = 0

        while index + 1 < remaining.count {
            rows.append(.pair(remaining[index], remaining[index + 1]))
            index += 2
        }

        if index < remaining.count {
            rows.append(.categoryWithAll(remaining[index]))
        } else {
            rows.append(.all)
        }

        return rows
    }
}

private enum DashboardCategoryBoxDisplayStyle: Equatable {
    case hero
    case standard
}

private enum DashboardCategoryBoxBorderMetrics {
    static let lineWidth: CGFloat = 1.35
}

private struct DashboardCategoryBoxView: View {
    @State private var displayedAmount = ""
    @State private var amountIsDecreasing = false
    @State private var flashColor: Color = .clear
    @State private var displayedFillRatio: Double = 0

    let data: DashboardCategoryBoxData
    let formattedAmount: String
    let displayStyle: DashboardCategoryBoxDisplayStyle
    let onTap: () -> Void

    init(
        data: DashboardCategoryBoxData,
        formattedAmount: String,
        displayStyle: DashboardCategoryBoxDisplayStyle,
        onTap: @escaping () -> Void
    ) {
        self.data = data
        self.formattedAmount = formattedAmount
        self.displayStyle = displayStyle
        self.onTap = onTap
        _displayedAmount = State(initialValue: formattedAmount)
        _displayedFillRatio = State(initialValue: DashboardCategoryBoxView.makeFillRatio(for: data))
    }

    private var accentColor: Color {
        Color(hex: data.categoryColorHex) ?? .accentColor
    }

    private var hasLimit: Bool {
        guard let limit = data.categoryEffectiveLimit else { return false }
        return limit > 0
    }

    private var isOverLimit: Bool {
        guard let limit = data.categoryEffectiveLimit, limit > 0 else { return false }
        return data.categoryBudgetProgressAmount > limit
    }

    private var fillRatio: Double {
        Self.makeFillRatio(for: data)
    }

    private var minHeight: CGFloat {
        switch displayStyle {
        case .standard:
            88
        case .hero:
            98
        }
    }

    private var titleFont: Font {
        switch displayStyle {
        case .standard:
            .headline.weight(.semibold)
        case .hero:
            .title3.weight(.bold)
        }
    }

    private var amountFont: Font {
        switch displayStyle {
        case .standard:
            .title2.weight(.bold)
        case .hero:
            .system(size: 28, weight: .bold, design: .rounded)
        }
    }

    private var horizontalPadding: CGFloat {
        switch displayStyle {
        case .standard:
            15
        case .hero:
            18
        }
    }

    private var showsExpandedOverLimitBadge: Bool {
        isOverLimit && displayStyle == .hero
    }

    private var showsCompactOverLimitIndicator: Bool {
        isOverLimit && displayStyle == .standard
    }

    private var overLimitStrokeColor: Color {
        .orange.opacity(displayStyle == .hero ? 0.82 : 0.76)
    }

    private var baseStrokeColor: Color {
        if hasLimit {
            return Color.black.opacity(displayStyle == .hero ? 0.24 : 0.2)
        } else {
            return Color.black.opacity(displayStyle == .hero ? 0.2 : 0.17)
        }
    }

    var body: some View {
        Button(action: onTap) {
            VStack(alignment: .leading, spacing: 8) {
                HStack(alignment: .top, spacing: 8) {
                    HStack(spacing: 8) {
                        Image(systemName: data.categoryIcon)
                            .font(.system(size: 14, weight: .semibold))

                        Text(data.categoryName)
                            .font(titleFont)
                            .lineLimit(displayStyle == .hero ? 2 : 1)
                            .minimumScaleFactor(displayStyle == .hero ? 0.88 : 0.84)
                            .allowsTightening(true)
                            .multilineTextAlignment(.leading)
                    }
                    .foregroundStyle(accentColor)
                    .layoutPriority(1)

                    Spacer(minLength: 0)

                    if showsExpandedOverLimitBadge {
                        HStack(spacing: 4) {
                            Image(systemName: "exclamationmark.triangle.fill")
                                .font(.system(size: 10, weight: .bold))
                            Text(LocalizationKey.Dashboard.overLimit.localized)
                                .font(.caption.weight(.semibold))
                                .lineLimit(1)
                        }
                        .foregroundStyle(.orange)
                        .padding(.horizontal, 8)
                        .padding(.vertical, 5)
                        .background(.orange.opacity(0.12), in: Capsule())
                    } else if showsCompactOverLimitIndicator {
                        Image(systemName: "exclamationmark.triangle.fill")
                            .font(.system(size: 11, weight: .bold))
                            .foregroundStyle(.orange)
                            .padding(.top, 2)
                    }
                }

                VStack(alignment: .leading, spacing: 6) {
                    Text(displayedAmount)
                        .font(amountFont)
                        .fontDesign(.rounded)
                        .foregroundStyle(Color.primary)
                        .monospacedDigit()
                        .lineLimit(1)
                        .minimumScaleFactor(0.7)
                        .contentTransition(.numericText(countsDown: amountIsDecreasing))
                        .animation(AnimationHelper.feedbackSpring, value: displayedAmount)
                }
            }
            .frame(maxWidth: .infinity, minHeight: minHeight, alignment: .topLeading)
            .padding(.horizontal, horizontalPadding)
            .padding(.vertical, 10)
            .background {
                if hasLimit {
                    ZStack(alignment: .bottom) {
                        RoundedRectangle(cornerRadius: AppConstants.UserInterface.cornerRadius, style: .continuous)
                            .fill(Color(.systemGray4))
                        Rectangle()
                            .fill(accentColor.opacity(0.18))
                            .scaleEffect(x: 1, y: displayedFillRatio, anchor: .bottom)
                    }
                    .clipShape(RoundedRectangle(cornerRadius: AppConstants.UserInterface.cornerRadius, style: .continuous))
                } else {
                    RoundedRectangle(cornerRadius: AppConstants.UserInterface.cornerRadius, style: .continuous)
                        .fill(accentColor.opacity(0.13))
                }
            }
            .overlay {
                ZStack {
                    RoundedRectangle(cornerRadius: AppConstants.UserInterface.cornerRadius, style: .continuous)
                        .fill(flashColor)

                    RoundedRectangle(cornerRadius: AppConstants.UserInterface.cornerRadius, style: .continuous)
                        .stroke(baseStrokeColor, lineWidth: DashboardCategoryBoxBorderMetrics.lineWidth)

                    if isOverLimit {
                        RoundedRectangle(cornerRadius: AppConstants.UserInterface.cornerRadius, style: .continuous)
                            .stroke(overLimitStrokeColor, lineWidth: DashboardCategoryBoxBorderMetrics.lineWidth)
                    }
                }
                .allowsHitTesting(false)
            }
        }
        .buttonStyle(PressHapticButtonStyle())
        .onChange(of: formattedAmount) { oldValue, newValue in
            let oldDigits = extractDigits(from: oldValue)
            let newDigits = extractDigits(from: newValue)
            amountIsDecreasing = newDigits < oldDigits

            withAnimation(AnimationHelper.feedbackSpring) {
                displayedAmount = newValue
            }

            let targetColor: Color = amountIsDecreasing ? .red.opacity(0.12) : .green.opacity(0.12)
            withAnimation(AnimationHelper.flashIn) { flashColor = targetColor }
            withAnimation(AnimationHelper.flashOut) { flashColor = .clear }
        }
        .onChange(of: fillRatio) { _, newValue in
            withAnimation(.spring(response: 0.5, dampingFraction: 0.86)) {
                displayedFillRatio = newValue
            }
        }
    }

    private func extractDigits(from string: String) -> Int {
        Int(string.filter(\.isNumber)) ?? 0
    }

    private static func makeFillRatio(for data: DashboardCategoryBoxData) -> Double {
        guard let limit = data.categoryEffectiveLimit, limit > 0 else { return 1.0 }
        return min(data.categoryBudgetProgressAmount / limit, 1.0)
    }
}

struct DashboardCategoryBoardEmptyState: View {
    var body: some View {
        EmptyStateView(message: LocalizationKey.Entry.tapToAdd.localized)
    }
}
