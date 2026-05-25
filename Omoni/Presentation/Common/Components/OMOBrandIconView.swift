import SwiftUI

struct OMOBrandIconView: View {
    let size: CGFloat
    let iconScale: CGFloat

    init(size: CGFloat, iconScale: CGFloat = 0.68) {
        self.size = size
        self.iconScale = iconScale
    }

    var body: some View {
        ZStack {
            Circle()
                .fill(Color.black)
                .overlay(
                    Circle()
                        .stroke(Color.white.opacity(0.08), lineWidth: 1)
                )

            Image("settings-icon")
                .resizable()
                .renderingMode(.original)
                .scaledToFit()
                .frame(width: size * iconScale, height: size * iconScale)
        }
        .frame(width: size, height: size)
        .shadow(color: Color.black.opacity(0.16), radius: 12, y: 6)
    }
}

#Preview {
    ZStack {
        Color(.systemBackground)
            .ignoresSafeArea()

        OMOBrandIconView(size: 92)
    }
}
