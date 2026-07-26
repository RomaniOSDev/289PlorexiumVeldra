import SwiftUI

struct SoftCard<Content: View>: View {
    var content: () -> Content
    init(@ViewBuilder content: @escaping () -> Content) {
        self.content = content
    }
    var body: some View {
        content()
            .padding(16)
            .background(
                LinearGradient(
                    colors: [Palette.surface, Palette.surface.opacity(0.85)],
                    startPoint: .topLeading,
                    endPoint: .bottomTrailing
                )
            )
            .clipShape(RoundedRectangle(cornerRadius: 18, style: .continuous))
            .shadow(color: Color.black.opacity(0.35), radius: 12, x: 0, y: 8)
            .overlay(
                RoundedRectangle(cornerRadius: 18, style: .continuous)
                    .stroke(
                        LinearGradient(
                            colors: [Palette.accent.opacity(0.45), Color.clear],
                            startPoint: .topLeading,
                            endPoint: .bottomTrailing
                        ),
                        lineWidth: 1
                    )
            )
    }
}

struct PrimaryButtonStyle: ButtonStyle {
    func makeBody(configuration: Configuration) -> some View {
        configuration.label
            .font(.headline.weight(.semibold))
            .foregroundStyle(Palette.background)
            .lineLimit(1)
            .minimumScaleFactor(0.7)
            .padding(.horizontal, 16)
            .padding(.vertical, 12)
            .frame(minHeight: 44)
            .background(
                LinearGradient(
                    colors: [Palette.primary, Palette.accent],
                    startPoint: .leading,
                    endPoint: .trailing
                )
            )
            .clipShape(RoundedRectangle(cornerRadius: 14, style: .continuous))
            .shadow(color: Palette.primary.opacity(0.45), radius: configuration.isPressed ? 4 : 10, x: 0, y: configuration.isPressed ? 2 : 6)
            .scaleEffect(configuration.isPressed ? 0.95 : 1)
            .animation(.easeInOut(duration: 0.3), value: configuration.isPressed)
    }
}

struct AchievementBanner: View {
    let title: String
    var body: some View {
        HStack(spacing: 12) {
            Image(systemName: "star.circle.fill")
                .font(.title2)
                .foregroundStyle(Palette.primary)
            VStack(alignment: .leading, spacing: 2) {
                Text("Achievement Unlocked")
                    .font(.caption.weight(.semibold))
                    .foregroundStyle(Palette.textSecondary)
                Text(title)
                    .font(.subheadline.weight(.bold))
                    .foregroundStyle(Palette.textPrimary)
                    .lineLimit(2)
            }
            Spacer(minLength: 0)
        }
        .padding(14)
        .background(
            LinearGradient(colors: [Palette.surface, Palette.background], startPoint: .top, endPoint: .bottom)
        )
        .clipShape(RoundedRectangle(cornerRadius: 16, style: .continuous))
        .shadow(color: .black.opacity(0.4), radius: 14, y: 8)
        .padding(.horizontal, 16)
    }
}

struct EmptyStateView: View {
    let symbol: String
    let title: String
    let message: String
    let actionTitle: String
    var action: () -> Void

    var body: some View {
        VStack(spacing: 18) {
            Image(systemName: symbol)
                .font(.system(size: 58))
                .foregroundStyle(Palette.primary)
                .shadow(color: Palette.primary.opacity(0.45), radius: 14)
            Text(title)
                .font(.headline)
                .foregroundStyle(Palette.textPrimary)
                .multilineTextAlignment(.center)
                .lineLimit(2)
                .minimumScaleFactor(0.8)
                .padding(.horizontal, 28)
            Text(message)
                .font(.subheadline)
                .foregroundStyle(Palette.textSecondary)
                .multilineTextAlignment(.center)
                .padding(.horizontal, 32)
            Button(actionTitle) {
                HapticService.light()
                action()
            }
            .buttonStyle(PrimaryButtonStyle())
            .padding(.horizontal, 40)
            .padding(.top, 4)
        }
        .frame(maxWidth: .infinity, maxHeight: .infinity)
    }
}

struct BannerImageCard: View {
    var imageName: String = "img_banner"
    var height: CGFloat = 120

    var body: some View {
        Image(imageName)
            .resizable()
            .scaledToFill()
            .frame(maxWidth: .infinity)
            .frame(height: height)
            .clipped()
            .clipShape(RoundedRectangle(cornerRadius: 18, style: .continuous))
            .shadow(color: .black.opacity(0.35), radius: 10, y: 6)
            .overlay(
                RoundedRectangle(cornerRadius: 18, style: .continuous)
                    .stroke(Palette.accent.opacity(0.35), lineWidth: 1)
            )
    }
}

struct AccentButtonImage: View {
    var title: String
    var action: () -> Void

    var body: some View {
        Button(action: {
            HapticService.light()
            action()
        }) {
            Text(title)
                .font(.headline.weight(.bold))
                .foregroundStyle(Palette.background)
                .lineLimit(1)
                .minimumScaleFactor(0.7)
                .frame(maxWidth: .infinity)
                .frame(height: 52)
                .background {
                    ZStack {
                        RoundedRectangle(cornerRadius: 14, style: .continuous)
                            .fill(
                                LinearGradient(
                                    colors: [
                                        Palette.accent,
                                        Palette.primary,
                                        Palette.primary.opacity(0.85)
                                    ],
                                    startPoint: .topLeading,
                                    endPoint: .bottomTrailing
                                )
                            )
                        RoundedRectangle(cornerRadius: 14, style: .continuous)
                            .fill(
                                LinearGradient(
                                    colors: [
                                        Color.white.opacity(0.38),
                                        Color.white.opacity(0.08),
                                        Color.clear,
                                        Color.black.opacity(0.12)
                                    ],
                                    startPoint: .top,
                                    endPoint: .bottom
                                )
                            )
                        AccentButtonGrain()
                            .clipShape(RoundedRectangle(cornerRadius: 14, style: .continuous))
                            .opacity(0.22)
                        RoundedRectangle(cornerRadius: 14, style: .continuous)
                            .stroke(
                                LinearGradient(
                                    colors: [
                                        Color.white.opacity(0.55),
                                        Palette.accent.opacity(0.25),
                                        Color.black.opacity(0.2)
                                    ],
                                    startPoint: .topLeading,
                                    endPoint: .bottomTrailing
                                ),
                                lineWidth: 1
                            )
                    }
                }
                .clipShape(RoundedRectangle(cornerRadius: 14, style: .continuous))
                .shadow(color: Palette.primary.opacity(0.35), radius: 10, y: 5)
        }
        .buttonStyle(.plain)
    }
}

private struct AccentButtonGrain: View {
    var body: some View {
        Canvas { context, size in
            let cols = max(Int(size.width / 4), 1)
            let rows = max(Int(size.height / 4), 1)
            for row in 0..<rows {
                for col in 0..<cols {
                    let hash = (row * 37 &+ col * 17) % 10
                    guard hash < 4 else { continue }
                    let x = CGFloat(col) * 4 + CGFloat(hash % 3)
                    let y = CGFloat(row) * 4 + CGFloat((hash * 3) % 3)
                    let rect = CGRect(x: x, y: y, width: 1.1, height: 1.1)
                    context.fill(Path(ellipseIn: rect), with: .color(.white.opacity(0.35)))
                }
            }
            for i in stride(from: 0, to: Int(size.height), by: 3) {
                var path = Path()
                path.move(to: CGPoint(x: 0, y: CGFloat(i)))
                path.addLine(to: CGPoint(x: size.width, y: CGFloat(i)))
                context.stroke(path, with: .color(.black.opacity(0.06)), lineWidth: 0.6)
            }
        }
        .allowsHitTesting(false)
    }
}
