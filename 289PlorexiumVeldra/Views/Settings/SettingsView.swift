import SwiftUI
import StoreKit

struct SettingsView: View {
    @EnvironmentObject private var store: AppDataStore
    @EnvironmentObject private var themeManager: ThemeManager
    @State private var showResetAlert = false
    @State private var soundEnabled = HapticService.soundEnabled
    @State private var hapticsEnabled = HapticService.hapticsEnabled
    @State private var comfortEnabled = false
    @State private var comfortMin: Double = 18
    @State private var comfortMax: Double = 24
    @State private var reminderEnabled = false
    @State private var reminderDate = Calendar.current.date(bySettingHour: 20, minute: 0, second: 0, of: Date()) ?? Date()

    var body: some View {
        NavigationStack {
            ScrollView {
                VStack(spacing: 16) {
                    SoftCard {
                        VStack(alignment: .leading, spacing: 12) {
                            Text("Stats")
                                .font(.headline)
                                .foregroundStyle(Palette.textPrimary)
                            HStack {
                                statCell("Alerts", "\(store.stats.itemsCreated)")
                                statCell("Triggers", "\(store.stats.sessionsCompleted)")
                                statCell("Streak", "\(store.stats.streakDays)")
                            }
                            NavigationLink {
                                StatsView()
                            } label: {
                                HStack {
                                    Text("View Full Stats")
                                        .foregroundStyle(Palette.primary)
                                        .lineLimit(1)
                                        .minimumScaleFactor(0.8)
                                    Spacer()
                                    Image(systemName: "chevron.right")
                                        .font(.caption.weight(.semibold))
                                        .foregroundStyle(Palette.textSecondary)
                                }
                                .frame(minHeight: 44)
                            }
                        }
                    }

                    SoftCard {
                        VStack(spacing: 0) {
                            Toggle(isOn: $soundEnabled) {
                                Label {
                                    Text("Sound Effects")
                                        .foregroundStyle(Palette.textPrimary)
                                        .lineLimit(1)
                                        .minimumScaleFactor(0.8)
                                } icon: {
                                    Image(systemName: "speaker.wave.2.fill")
                                        .foregroundStyle(Palette.primary)
                                        .frame(width: 28)
                                }
                            }
                            .tint(Palette.primary)
                            .frame(minHeight: 44)
                            .padding(.vertical, 6)
                            .onChange(of: soundEnabled) { value in
                                HapticService.soundEnabled = value
                                if value { HapticService.play(1104) }
                            }

                            Divider().background(Palette.textSecondary.opacity(0.25))

                            Toggle(isOn: $hapticsEnabled) {
                                Label {
                                    Text("Haptic Feedback")
                                        .foregroundStyle(Palette.textPrimary)
                                        .lineLimit(1)
                                        .minimumScaleFactor(0.8)
                                } icon: {
                                    Image(systemName: "hand.tap.fill")
                                        .foregroundStyle(Palette.primary)
                                        .frame(width: 28)
                                }
                            }
                            .tint(Palette.primary)
                            .frame(minHeight: 44)
                            .padding(.vertical, 6)
                            .onChange(of: hapticsEnabled) { value in
                                HapticService.hapticsEnabled = value
                                if value { HapticService.light() }
                            }
                        }
                    }

                    SoftCard {
                        VStack(alignment: .leading, spacing: 12) {
                            Text("Daily Reminder")
                                .font(.headline)
                                .foregroundStyle(Palette.textPrimary)

                            Toggle(isOn: $reminderEnabled) {
                                Text("Remind me to log")
                                    .foregroundStyle(Palette.textPrimary)
                            }
                            .tint(Palette.primary)
                            .onChange(of: reminderEnabled) { _ in
                                commitReminder()
                            }

                            if reminderEnabled {
                                DatePicker(
                                    "Time",
                                    selection: $reminderDate,
                                    displayedComponents: .hourAndMinute
                                )
                                .tint(Palette.primary)
                                .foregroundStyle(Palette.textPrimary)
                                .onChange(of: reminderDate) { _ in
                                    commitReminder()
                                }
                            }
                        }
                    }

                    SoftCard {
                        VStack(alignment: .leading, spacing: 12) {
                            Text("Comfort Zone")
                                .font(.headline)
                                .foregroundStyle(Palette.textPrimary)

                            Toggle(isOn: $comfortEnabled) {
                                Text("Enable comfort range")
                                    .foregroundStyle(Palette.textPrimary)
                            }
                            .tint(Palette.primary)
                            .onChange(of: comfortEnabled) { _ in
                                commitComfort()
                            }

                            if comfortEnabled {
                                Text(String(format: "Min %.0f°C", comfortMin))
                                    .font(.caption)
                                    .foregroundStyle(Palette.textSecondary)
                                Slider(value: $comfortMin, in: -10...35, step: 1)
                                    .tint(Palette.accent)
                                    .onChange(of: comfortMin) { value in
                                        if value >= comfortMax {
                                            comfortMax = min(value + 1, 40)
                                        }
                                        commitComfort()
                                    }

                                Text(String(format: "Max %.0f°C", comfortMax))
                                    .font(.caption)
                                    .foregroundStyle(Palette.textSecondary)
                                Slider(value: $comfortMax, in: -5...40, step: 1)
                                    .tint(Palette.primary)
                                    .onChange(of: comfortMax) { value in
                                        if value <= comfortMin {
                                            comfortMin = max(value - 1, -10)
                                        }
                                        commitComfort()
                                    }
                            }
                        }
                    }

                    SoftCard {
                        VStack(alignment: .leading, spacing: 12) {
                            Text("Theme")
                                .font(.headline)
                                .foregroundStyle(Palette.textPrimary)

                            HStack(spacing: 10) {
                                ForEach(AppTheme.allCases) { theme in
                                    Button {
                                        HapticService.light()
                                        themeManager.theme = theme
                                    } label: {
                                        VStack(spacing: 8) {
                                            Circle()
                                                .fill(theme.palette.primary)
                                                .frame(width: 28, height: 28)
                                                .overlay(
                                                    Circle()
                                                        .stroke(Color.white.opacity(themeManager.theme == theme ? 0.9 : 0.2), lineWidth: 2)
                                                )
                                            Text(theme.title)
                                                .font(.caption2.weight(.semibold))
                                                .foregroundStyle(Palette.textPrimary)
                                                .lineLimit(1)
                                                .minimumScaleFactor(0.7)
                                        }
                                        .frame(maxWidth: .infinity)
                                        .padding(.vertical, 10)
                                        .background(
                                            themeManager.theme == theme
                                            ? Palette.background.opacity(0.55)
                                            : Palette.background.opacity(0.25)
                                        )
                                        .clipShape(RoundedRectangle(cornerRadius: 12, style: .continuous))
                                    }
                                    .buttonStyle(.plain)
                                }
                            }
                        }
                    }

                    SoftCard {
                        VStack(spacing: 0) {
                            settingsButton(title: "Replay Quick Tour", systemImage: "sparkles") {
                                store.restartCoachTour()
                            }
                            Divider().background(Palette.textSecondary.opacity(0.25))
                            settingsButton(title: "Rate Us", systemImage: "star.fill") {
                                rateApp()
                            }
                            Divider().background(Palette.textSecondary.opacity(0.25))
                            settingsButton(title: "Privacy Policy", systemImage: "hand.raised.fill") {
                                openURL(AppLinks.privacyPolicy)
                            }
                            Divider().background(Palette.textSecondary.opacity(0.25))
                            settingsButton(title: "Terms of Use", systemImage: "doc.text.fill") {
                                openURL(AppLinks.termsOfUse)
                            }
                        }
                    }

                    Button {
                        HapticService.warning()
                        showResetAlert = true
                    } label: {
                        HStack {
                            Image(systemName: "trash.fill")
                            Text("Reset All Data")
                                .lineLimit(1)
                                .minimumScaleFactor(0.8)
                            Spacer()
                        }
                        .font(.headline)
                        .foregroundStyle(Color.red.opacity(0.95))
                        .padding(16)
                        .background(Palette.surface)
                        .clipShape(RoundedRectangle(cornerRadius: 18, style: .continuous))
                        .shadow(color: .black.opacity(0.3), radius: 10, y: 6)
                    }
                    .buttonStyle(.plain)
                    .padding(.bottom, 24)
                }
                .padding(16)
            }
            .navigationTitle("Settings")
            .navigationBarTitleDisplayMode(.inline)
            .toolbarBackground(Palette.surface, for: .navigationBar)
            .toolbarColorScheme(.dark, for: .navigationBar)
            .screenBackground()
            .onAppear {
                soundEnabled = HapticService.soundEnabled
                hapticsEnabled = HapticService.hapticsEnabled
                comfortEnabled = store.comfortZone.enabled
                comfortMin = store.comfortZone.minCelsius
                comfortMax = store.comfortZone.maxCelsius
                reminderEnabled = store.reminderSettings.enabled
                reminderDate = Calendar.current.date(
                    bySettingHour: store.reminderSettings.hour,
                    minute: store.reminderSettings.minute,
                    second: 0,
                    of: Date()
                ) ?? reminderDate
            }
            .alert("Reset All Data?", isPresented: $showResetAlert) {
                Button("Cancel", role: .cancel) {}
                Button("Reset", role: .destructive) {
                    store.resetAll()
                    comfortEnabled = false
                    comfortMin = 18
                    comfortMax = 24
                    reminderEnabled = false
                }
            } message: {
                Text("This clears temperature readings, alerts, triggers, and achievements on this device.")
            }
        }
    }

    private func commitComfort() {
        store.saveComfortZone(
            ComfortZone(enabled: comfortEnabled, minCelsius: comfortMin, maxCelsius: comfortMax)
        )
    }

    private func commitReminder() {
        let comps = Calendar.current.dateComponents([.hour, .minute], from: reminderDate)
        store.saveReminderSettings(
            ReminderSettings(
                enabled: reminderEnabled,
                hour: comps.hour ?? 20,
                minute: comps.minute ?? 0
            )
        )
    }

    private func statCell(_ title: String, _ value: String) -> some View {
        VStack(spacing: 4) {
            Text(value)
                .font(.title3.weight(.bold))
                .foregroundStyle(Palette.primary)
                .lineLimit(1)
                .minimumScaleFactor(0.7)
            Text(title)
                .font(.caption2)
                .foregroundStyle(Palette.textSecondary)
                .lineLimit(1)
                .minimumScaleFactor(0.7)
        }
        .frame(maxWidth: .infinity)
    }

    private func settingsButton(title: String, systemImage: String, action: @escaping () -> Void) -> some View {
        Button {
            HapticService.light()
            action()
        } label: {
            HStack(spacing: 12) {
                Image(systemName: systemImage)
                    .foregroundStyle(Palette.primary)
                    .frame(width: 28)
                Text(title)
                    .foregroundStyle(Palette.textPrimary)
                    .lineLimit(1)
                    .minimumScaleFactor(0.8)
                Spacer()
                Image(systemName: "chevron.right")
                    .font(.caption.weight(.semibold))
                    .foregroundStyle(Palette.textSecondary)
            }
            .frame(minHeight: 44)
            .padding(.vertical, 6)
        }
        .buttonStyle(.plain)
    }

    private func openURL(_ string: String) {
        guard let url = URL(string: string) else { return }
        UIApplication.shared.open(url)
    }

    private func rateApp() {
        if let windowScene = UIApplication.shared.connectedScenes.first as? UIWindowScene {
            SKStoreReviewController.requestReview(in: windowScene)
        }
    }
}
