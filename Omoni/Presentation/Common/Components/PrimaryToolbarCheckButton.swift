import SwiftUI

struct PrimaryToolbarCheckButton: View {
    let isDisabled: Bool
    let action: () -> Void

    init(
        isDisabled: Bool = false,
        action: @escaping () -> Void
    ) {
        self.isDisabled = isDisabled
        self.action = action
    }

    var body: some View {
        Button(action: action) {
            Image(systemName: "checkmark")
                .font(.system(size: 15, weight: .bold))
                .foregroundStyle(.white)
        }
        .buttonStyle(.borderedProminent)
        .buttonBorderShape(.circle)
        .tint(.omoniInteractiveRed)
        .disabled(isDisabled)
    }
}
