import SwiftUI

extension View {
    func toggleHaptic<T: Equatable>(trigger: T) -> some View {
        sensoryFeedback(.impact(weight: .medium), trigger: trigger)
    }
}

/// Button style that fires a rigid haptic on press-down and a soft haptic on release,
/// simulating the feel of pressing a physical button.
struct PressHapticButtonStyle: ButtonStyle {
    func makeBody(configuration: Configuration) -> some View {
        configuration.label
            .overlay(
                Rectangle()
                    .fill(Color.black.opacity(configuration.isPressed ? 0.06 : 0))
                    .allowsHitTesting(false)
            )
            .scaleEffect(configuration.isPressed ? 0.97 : 1.0)
            .animation(.easeInOut(duration: 0.12), value: configuration.isPressed)
            .onChange(of: configuration.isPressed) { _, isPressed in
#if targetEnvironment(simulator)
                return
#else
                if isPressed {
                    UIImpactFeedbackGenerator(style: .rigid).impactOccurred()
                } else {
                    UIImpactFeedbackGenerator(style: .soft).impactOccurred()
                }
#endif
            }
    }
}
