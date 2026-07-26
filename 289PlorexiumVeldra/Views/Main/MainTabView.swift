import SwiftUI

struct MainTabView: View {
    @EnvironmentObject private var store: AppDataStore
    @State private var selected = 0

    var body: some View {
        ZStack(alignment: .top) {
            TabView(selection: $selected) {
                TemperatureTrendView()
                    .tabItem { Label("Trends", systemImage: "thermometer.medium") }
                    .tag(0)
                TemperatureAlertsView()
                    .tabItem { Label("Alerts", systemImage: "bell.fill") }
                    .tag(1)
                TemperatureInsightsView()
                    .tabItem { Label("Insights", systemImage: "chart.xyaxis.line") }
                    .tag(2)
                AchievementsView()
                    .tabItem { Label("Awards", systemImage: "trophy.fill") }
                    .tag(3)
                SettingsView()
                    .tabItem { Label("Settings", systemImage: "gearshape.fill") }
                    .tag(4)
            }
            .tint(Palette.primary)

            if let title = store.bannerTitle {
                AchievementBanner(title: title)
                    .transition(.move(edge: .top).combined(with: .opacity))
                    .padding(.top, 8)
                    .zIndex(10)
            }

            if store.showSuccessFlash {
                Image(systemName: "checkmark.circle.fill")
                    .font(.system(size: 54))
                    .foregroundStyle(Palette.accent)
                    .shadow(color: Palette.accent.opacity(0.55), radius: 16)
                    .transition(.scale.combined(with: .opacity))
                    .frame(maxWidth: .infinity, maxHeight: .infinity, alignment: .center)
                    .allowsHitTesting(false)
                    .zIndex(9)
            }

            if let message = store.lastTriggerMessage {
                Text(message)
                    .font(.subheadline.weight(.semibold))
                    .foregroundStyle(Palette.textPrimary)
                    .padding(.horizontal, 16)
                    .padding(.vertical, 12)
                    .background(Palette.surface)
                    .clipShape(RoundedRectangle(cornerRadius: 14, style: .continuous))
                    .shadow(color: .black.opacity(0.35), radius: 10, y: 6)
                    .padding(.top, 64)
                    .transition(.move(edge: .top).combined(with: .opacity))
                    .zIndex(11)
            }

            if store.hasSeenOnboarding && !store.hasSeenCoachTour {
                CoachMarksOverlay(selectedTab: $selected)
            }
        }
        .onAppear {
            let appearance = UITabBarAppearance()
            appearance.configureWithOpaqueBackground()
            appearance.backgroundColor = UIColor(Palette.surface)
            UITabBar.appearance().standardAppearance = appearance
            UITabBar.appearance().scrollEdgeAppearance = appearance
        }
    }
}
