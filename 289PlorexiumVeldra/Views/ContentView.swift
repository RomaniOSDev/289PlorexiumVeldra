import SwiftUI

struct ContentView: View {
    @StateObject private var store = AppDataStore.shared
    @ObservedObject private var theme = ThemeManager.shared

    var body: some View {
        Group {
            if store.hasSeenOnboarding {
                MainTabView()
            } else {
                OnboardingView()
            }
        }
        .preferredColorScheme(.dark)
        .environmentObject(store)
        .environmentObject(theme)
        .id(theme.theme.rawValue)
    }
}
