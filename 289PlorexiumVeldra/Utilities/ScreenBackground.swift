import SwiftUI

struct ScreenBackground: ViewModifier {
    var imageName: String = "img_background"
    var opacity: Double = 0.28

    func body(content: Content) -> some View {
        content
            .frame(maxWidth: .infinity, maxHeight: .infinity)
            .background {
                Palette.background
                    .overlay {
                        Image(imageName)
                            .resizable()
                            .scaledToFill()
                            .opacity(opacity)
                    }
                    .clipped()
                    .ignoresSafeArea()
            }
    }
}

extension View {
    func screenBackground(_ imageName: String = "img_background", opacity: Double = 0.28) -> some View {
        modifier(ScreenBackground(imageName: imageName, opacity: opacity))
    }
}
