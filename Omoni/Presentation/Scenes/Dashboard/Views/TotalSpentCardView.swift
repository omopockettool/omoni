//
//  TotalSpentCardView.swift
//  Omoni
//
//  Created by System on 3/11/25.
//

import SwiftUI

struct TotalSpentCardView<BottomContent: View>: View {
    let label: String
    let totalAmount: String
    let onAddExpense: () -> Void
    var actionColor: Color = .accentColor
    var budgetFillRatio: Double? = nil
    @ViewBuilder let bottomContent: () -> BottomContent

    @State private var displayedAmount: String = ""
    @State private var isDecreasing: Bool = false
    @State private var flashColor: Color = .clear
    @State private var cardScale: CGFloat = 1.0
    @State private var isAddPressed = false
    @State private var displayedBudgetFillRatio: Double = 0

    init(
        label: String,
        totalAmount: String,
        onAddExpense: @escaping () -> Void,
        actionColor: Color = .accentColor,
        budgetFillRatio: Double? = nil,
        @ViewBuilder bottomContent: @escaping () -> BottomContent
    ) {
        self.label = label
        self.totalAmount = totalAmount
        self.onAddExpense = onAddExpense
        self.actionColor = actionColor
        self.budgetFillRatio = budgetFillRatio
        self.bottomContent = bottomContent
    }

    var body: some View {
        Button(action: onAddExpense) {
            HStack(alignment: .center, spacing: 16) {
                VStack(alignment: .leading, spacing: 4) {
                    Text(label)
                        .font(.subheadline)
                        .fontWeight(.medium)
                        .foregroundColor(.secondary)
                        .lineLimit(1)
                        .truncationMode(.tail)
                        .animation(.easeInOut(duration: 0.2), value: label)

                    Text(displayedAmount)
                        .font(.system(size: dynamicFontSize, weight: .bold, design: .rounded))
                        .foregroundColor(.primary)
                        .minimumScaleFactor(0.5)
                        .lineLimit(1)
                        .contentTransition(.numericText(countsDown: isDecreasing))
                        .animation(AnimationHelper.feedbackSpring, value: displayedAmount)

                    bottomContent()
                }
                .frame(maxWidth: .infinity, alignment: .leading)

                Spacer(minLength: 8)

                ZStack {
                    Circle()
                        .fill(actionColor.opacity(0.45))
                        .frame(width: 48, height: 48)
                        .offset(y: 4)

                    Circle()
                        .fill(actionColor)
                        .frame(width: 48, height: 48)
                        .overlay {
                            Image(systemName: "plus")
                                .font(.system(size: 21, weight: .black))
                                .foregroundColor(.white)
                        }
                        .offset(y: isAddPressed ? 4 : 0)
                }
                .frame(width: 48, height: 52)
                .animation(.spring(response: 0.18, dampingFraction: 0.6), value: isAddPressed)
            }
            .padding(.horizontal, AppConstants.UserInterface.padding)
            .padding(.vertical, 16)
            .background {
                ZStack(alignment: .bottom) {
                    RoundedRectangle(cornerRadius: AppConstants.UserInterface.cornerRadius, style: .continuous)
                        .fill(.regularMaterial)

                    if budgetFillRatio != nil {
                        Rectangle()
                            .fill(actionColor.opacity(0.16))
                            .scaleEffect(x: 1, y: displayedBudgetFillRatio, anchor: .bottom)
                    }
                }
                .clipShape(RoundedRectangle(cornerRadius: AppConstants.UserInterface.cornerRadius, style: .continuous))
            }
            .overlay(
                RoundedRectangle(cornerRadius: AppConstants.UserInterface.cornerRadius)
                    .fill(flashColor)
                    .allowsHitTesting(false)
            )
            .cornerRadius(AppConstants.UserInterface.cornerRadius)
            .scaleEffect(cardScale)
        }
        .buttonStyle(PressHapticButtonStyle())
        .simultaneousGesture(
            DragGesture(minimumDistance: 0)
                .onChanged { _ in isAddPressed = true }
                .onEnded   { _ in isAddPressed = false }
        )
        .onAppear {
            displayedAmount = totalAmount
            displayedBudgetFillRatio = budgetFillRatio ?? 0
        }
        .onChange(of: totalAmount) { oldValue, newValue in
            let oldDigits = extractDigits(from: oldValue)
            let newDigits = extractDigits(from: newValue)
            withAnimation(AnimationHelper.feedbackSpring) {
                isDecreasing = newDigits < oldDigits
                displayedAmount = newValue
            }
            let targetColor: Color = isDecreasing ? .red.opacity(0.12) : .green.opacity(0.12)
            withAnimation(AnimationHelper.flashIn) { flashColor = targetColor }
            withAnimation(AnimationHelper.flashOut) { flashColor = .clear }
            withAnimation(.spring(response: 0.25, dampingFraction: 0.45)) { cardScale = 1.025 }
            withAnimation(.spring(response: 0.35, dampingFraction: 0.6).delay(0.12)) { cardScale = 1.0 }
        }
        .onChange(of: budgetFillRatio) { _, newValue in
            withAnimation(.spring(response: 0.5, dampingFraction: 0.86)) {
                displayedBudgetFillRatio = newValue ?? 0
            }
        }
    }

    private func extractDigits(from string: String) -> Int {
        Int(string.filter(\.isNumber)) ?? 0
    }

    private var dynamicFontSize: CGFloat {
        let length = totalAmount.count
        switch length {
        case 0...10:  return 34
        case 11...15: return 28
        case 16...20: return 22
        default:      return 18
        }
    }
}

extension TotalSpentCardView where BottomContent == EmptyView {
    init(
        label: String,
        totalAmount: String,
        onAddExpense: @escaping () -> Void,
        actionColor: Color = .accentColor,
        budgetFillRatio: Double? = nil
    ) {
        self.init(
            label: label,
            totalAmount: totalAmount,
            onAddExpense: onAddExpense,
            actionColor: actionColor,
            budgetFillRatio: budgetFillRatio,
            bottomContent: { EmptyView() }
        )
    }
}

// MARK: - Preview
#Preview {
    VStack(spacing: 20) {
        TotalSpentCardView(
            label: "Coste de hoy",
            totalAmount: "50,45 €",
            onAddExpense: {}
        )
    }
    .padding()
    .background(Color.black)
}
