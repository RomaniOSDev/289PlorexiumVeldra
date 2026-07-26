import SwiftUI

struct OnboardingView: View {
    @EnvironmentObject private var store: AppDataStore
    @State private var page = 0
    @State private var appearScale: CGFloat = 0.7
    @State private var appearOpacity: Double = 0

    private let pages: [(title: String, body: String, symbol: String, image: String)] = [
        ("Monitor Temperatures", "Easily keep track of current temperature changes.", "thermometer.medium", "img_banner"),
        ("Set Custom Alerts", "Define your temperature thresholds to receive timely notifications.", "bell.badge.fill", "img_card"),
        ("Start Tracking Now", "Begin by enabling notifications to stay updated.", "sparkles", "img_banner")
    ]

    var body: some View {
        VStack(spacing: 0) {
            TabView(selection: $page) {
                ForEach(pages.indices, id: \.self) { index in
                    onboardingPage(pages[index], index: index)
                        .tag(index)
                }
            }
            .tabViewStyle(.page(indexDisplayMode: .never))
            .animation(.easeInOut(duration: 0.3), value: page)

            HStack(spacing: 8) {
                ForEach(pages.indices, id: \.self) { index in
                    Capsule()
                        .fill(index == page ? Palette.primary : Palette.textSecondary.opacity(0.35))
                        .frame(width: index == page ? 28 : 8, height: 8)
                        .animation(.spring(response: 0.4, dampingFraction: 0.7), value: page)
                }
            }
            .padding(.bottom, 18)

            Button {
                HapticService.light()
                if page < pages.count - 1 {
                    withAnimation(.easeInOut(duration: 0.3)) { page += 1 }
                } else {
                    store.completeOnboarding()
                }
            } label: {
                Text(page < pages.count - 1 ? "Next" : "Get Started")
                    .frame(maxWidth: .infinity)
            }
            .buttonStyle(PrimaryButtonStyle())
            .padding(.horizontal, 24)
            .padding(.bottom, 36)
        }
        .screenBackground()
        .onChange(of: page) { _ in
            appearScale = 0.7
            appearOpacity = 0
            withAnimation(.spring(response: 0.45, dampingFraction: 0.72)) {
                appearScale = 1
                appearOpacity = 1
            }
        }
        .onAppear {
            withAnimation(.spring(response: 0.45, dampingFraction: 0.72)) {
                appearScale = 1
                appearOpacity = 1
            }
        }
    }

    private func onboardingPage(_ item: (title: String, body: String, symbol: String, image: String), index: Int) -> some View {
        VStack(spacing: 20) {
            Spacer(minLength: 12)

            Image(item.image)
                .resizable()
                .scaledToFill()
                .frame(height: 220)
                .frame(maxWidth: .infinity)
                .clipped()
                .clipShape(RoundedRectangle(cornerRadius: 28, style: .continuous))
                .overlay(
                    RoundedRectangle(cornerRadius: 28, style: .continuous)
                        .stroke(Palette.accent.opacity(0.35), lineWidth: 1)
                )
                .shadow(color: .black.opacity(0.45), radius: 18, y: 10)
                .scaleEffect(index == page ? appearScale : 0.92)
                .opacity(index == page ? appearOpacity : 0.65)
                .padding(.horizontal, 28)

            Image(systemName: item.symbol)
                .font(.system(size: 36, weight: .semibold))
                .foregroundStyle(Palette.primary)
                .frame(width: 72, height: 72)
                .background(
                    Circle()
                        .fill(Palette.surface)
                        .shadow(color: Palette.primary.opacity(0.35), radius: 12)
                )
                .overlay(
                    Circle()
                        .stroke(Palette.accent.opacity(0.4), lineWidth: 1)
                )
                .scaleEffect(index == page ? appearScale : 0.85)
                .opacity(index == page ? appearOpacity : 0.5)

            VStack(spacing: 12) {
                Text(item.title)
                    .font(.system(size: 30, weight: .bold, design: .rounded))
                    .foregroundStyle(Palette.textPrimary)
                    .multilineTextAlignment(.center)
                    .lineLimit(2)
                    .minimumScaleFactor(0.8)
                Text(item.body)
                    .font(.body)
                    .foregroundStyle(Palette.textSecondary)
                    .multilineTextAlignment(.center)
                    .lineLimit(4)
                    .minimumScaleFactor(0.8)
                    .padding(.horizontal, 28)
            }

            Spacer()
        }
    }
}
