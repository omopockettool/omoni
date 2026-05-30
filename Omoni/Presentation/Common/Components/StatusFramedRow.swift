import SwiftUI

enum StatusFramedRowTone: Equatable {
    case neutral
    case pending
    case completed

    var accentColor: Color {
        switch self {
        case .neutral:
            return Color(.systemGray3)
        case .pending:
            return .orange
        case .completed:
            return .paidGreen
        }
    }

    var borderColor: Color {
        switch self {
        case .neutral:
            return Color(.separator).opacity(0.72)
        case .pending:
            return .orange.opacity(0.72)
        case .completed:
            return Color.paidGreen.opacity(0.76)
        }
    }

    var amountColor: Color {
        switch self {
        case .neutral:
            return Color.primary.opacity(0.72)
        case .pending:
            return .orange
        case .completed:
            return .paidGreen
        }
    }
}

struct StatusFramedRow<Content: View>: View {
    let tone: StatusFramedRowTone
    let statusIconName: String
    let statusIconWeight: Font.Weight
    let onTap: () -> Void
    let onToggle: () -> Void
    @ViewBuilder let content: () -> Content

    init(
        tone: StatusFramedRowTone,
        statusIconName: String,
        statusIconWeight: Font.Weight = .semibold,
        onTap: @escaping () -> Void,
        onToggle: @escaping () -> Void,
        @ViewBuilder content: @escaping () -> Content
    ) {
        self.tone = tone
        self.statusIconName = statusIconName
        self.statusIconWeight = statusIconWeight
        self.onTap = onTap
        self.onToggle = onToggle
        self.content = content
    }

    var body: some View {
        HStack(spacing: 0) {
            statusButton
            content()
                .padding(.horizontal, 15)
                .padding(.vertical, 15)
                .frame(maxWidth: .infinity, alignment: .leading)
        }
        .background(cardBackground)
        .clipShape(cardShape)
        .overlay {
            cardShape
                .stroke(tone.borderColor, lineWidth: 1)
        }
        .contentShape(cardShape)
        .onTapGesture(perform: onTap)
    }

    private var statusButton: some View {
        Button(action: onToggle) {
            ZStack {
                Rectangle()
                    .fill(tone.accentColor)

                Image(systemName: statusIconName)
                    .font(.system(size: 18, weight: statusIconWeight))
                    .foregroundStyle(Color.white.opacity(0.96))
            }
            .frame(width: 52)
            .frame(maxHeight: .infinity)
            .contentShape(Rectangle())
        }
        .buttonStyle(.plain)
        .toggleHaptic(trigger: tone)
        .animation(AnimationHelper.quickSpring, value: tone)
    }

    private var cardBackground: some View {
        RoundedRectangle(cornerRadius: 18, style: .continuous)
            .fill(Color(.secondarySystemGroupedBackground))
    }

    private var cardShape: RoundedRectangle {
        RoundedRectangle(cornerRadius: 18, style: .continuous)
    }
}
