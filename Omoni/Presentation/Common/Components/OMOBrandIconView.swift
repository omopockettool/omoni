import SwiftUI

struct OMOBrandIconView: View {
    let size: CGFloat
    let iconScale: CGFloat
    
    private var iconCornerRadius: CGFloat {
        size * 0.225
    }

    init(size: CGFloat, iconScale: CGFloat = 1) {
        self.size = size
        self.iconScale = iconScale
    }

    var body: some View {
        Image("settings-icon")
            .resizable()
            .renderingMode(.original)
            .scaledToFit()
            .frame(width: size * iconScale, height: size * iconScale)
            .clipShape(
                RoundedRectangle(cornerRadius: iconCornerRadius, style: .continuous)
            )
        .frame(width: size, height: size)
    }
}

#Preview {
    ZStack {
        Color(.systemBackground)
            .ignoresSafeArea()

        OMOBrandIconView(size: 92)
    }
}
