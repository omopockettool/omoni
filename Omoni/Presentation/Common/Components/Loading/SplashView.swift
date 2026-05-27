import SwiftUI

struct SplashView: View {
    @State private var appeared = false

    var body: some View {
        ZStack {
            Color(.systemBackground).ignoresSafeArea()

            VStack(spacing: 14) {
                OMOBrandIconView(size: 104)

                wordmark

                // Tagline
                Text(LocalizationKey.Splash.tagline.localized)
                    .font(.system(size: 13, weight: .regular, design: .rounded))
                    .foregroundStyle(.tertiary)
                    .tracking(0.3)
            }
            .scaleEffect(appeared ? 1 : 0.88)
            .opacity(appeared ? 1 : 0)
            .onAppear {
                withAnimation(.spring(response: 0.55, dampingFraction: 0.75)) {
                    appeared = true
                }
            }
        }
    }
    
    private var wordmark: some View {
        HStack(alignment: .lastTextBaseline, spacing: 0) {
            Text("omo")
                .font(.system(size: 40, weight: .bold, design: .rounded))
                .foregroundStyle(.primary)

            Text("ni")
                .font(.system(size: 40, weight: .semibold, design: .rounded))
                .foregroundStyle(Color.omoniBrandRed)
        }
        .tracking(0.6)
    }
}

#Preview {
    SplashView()
}
