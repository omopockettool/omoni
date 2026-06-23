import SwiftUI

/// Reusable budget limit input field with section label, accent icon, clear button, and keyboard Done toolbar.
struct BudgetLimitField: View {
    @Binding var text: String
    let accentColor: Color
    @FocusState private var isFocused: Bool

    var body: some View {
        HStack(spacing: 12) {
            HStack(spacing: 8) {
                Image(systemName: "chart.bar.fill")
                    .font(.system(size: 16, weight: .medium))
                    .foregroundStyle(accentColor)

                Text(LocalizationKey.Category.limit.localized)
                    .font(.subheadline.weight(.semibold))
                    .foregroundStyle(.secondary)
            }

            Spacer(minLength: 12)

            HStack(spacing: 8) {
                TextField(LocalizationKey.Category.noLimit.localized, text: $text)
                    .multilineTextAlignment(.trailing)
                    .keyboardType(.decimalPad)
                    .focused($isFocused)
                    .toolbar {
                        ToolbarItemGroup(placement: .keyboard) {
                            Spacer()
                            Button(LocalizationKey.General.done.localized) {
                                isFocused = false
                            }
                            .fontWeight(.semibold)
                        }
                    }

                if !text.isEmpty {
                    Button { text = "" } label: {
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
        .background(Color(.secondarySystemGroupedBackground))
        .clipShape(RoundedRectangle(cornerRadius: AppConstants.UserInterface.rowCornerRadius))
    }
}
