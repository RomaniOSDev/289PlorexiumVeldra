import SwiftUI

struct TemperatureAlertsView: View {
    @EnvironmentObject private var store: AppDataStore
    @State private var highEnabled = false
    @State private var lowEnabled = false
    @State private var highThreshold: Double = 30
    @State private var lowThreshold: Double = 5
    @State private var highText = "30"
    @State private var lowText = "5"
    @State private var showEditor = false
    @State private var showSavedBanner = false
    @State private var shakeHigh: CGFloat = 0
    @State private var shakeLow: CGFloat = 0
    @State private var validationError: String?

    var body: some View {
        NavigationStack {
            Group {
                if !store.alertConfig.anyEnabled && !showEditor {
                    EmptyStateView(
                        symbol: "thermometer",
                        title: "No alerts set — personalize your notifications",
                        message: "Choose high and low thresholds. Alerts trigger locally when you log a crossing temperature.",
                        actionTitle: "Set Alerts"
                    ) {
                        loadFromStore()
                        showEditor = true
                    }
                } else {
                    content
                }
            }
            .navigationTitle("Temperature Alerts")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .topBarTrailing) {
                    Button {
                        HapticService.light()
                        loadFromStore()
                        showEditor = true
                    } label: {
                        Image(systemName: "slider.horizontal.3")
                            .foregroundStyle(Palette.primary)
                    }
                    .frame(minWidth: 44, minHeight: 44)
                }
            }
            .toolbarBackground(Palette.surface, for: .navigationBar)
            .toolbarColorScheme(.dark, for: .navigationBar)
            .screenBackground()
            .onAppear { loadFromStore() }
            .overlay(alignment: .top) {
                if showSavedBanner {
                    Text("Alerts saved")
                        .font(.subheadline.weight(.semibold))
                        .foregroundStyle(Palette.textPrimary)
                        .padding(.horizontal, 16)
                        .padding(.vertical, 10)
                        .background(Palette.surface)
                        .clipShape(Capsule())
                        .shadow(color: .black.opacity(0.3), radius: 8, y: 4)
                        .padding(.top, 8)
                        .transition(.opacity)
                }
            }
        }
    }

    private var content: some View {
        Form {
            Section {
                HStack(spacing: 8) {
                    ForEach(AlertProfile.allCases) { profile in
                        Button {
                            HapticService.light()
                            store.applyProfile(profile)
                            loadFromStore()
                            showEditor = true
                            withAnimation { showSavedBanner = true }
                            DispatchQueue.main.asyncAfter(deadline: .now() + 1.4) {
                                withAnimation { showSavedBanner = false }
                            }
                        } label: {
                            VStack(spacing: 6) {
                                Image(systemName: profile.icon)
                                Text(profile.title)
                                    .font(.caption2.weight(.semibold))
                                    .lineLimit(1)
                                    .minimumScaleFactor(0.7)
                            }
                            .foregroundStyle(store.activeProfile == profile ? Palette.background : Palette.textPrimary)
                            .frame(maxWidth: .infinity)
                            .padding(.vertical, 10)
                            .background(store.activeProfile == profile ? Palette.primary : Palette.background.opacity(0.45))
                            .clipShape(RoundedRectangle(cornerRadius: 12, style: .continuous))
                        }
                        .buttonStyle(.plain)
                    }
                }
                .listRowBackground(Palette.surface)
            } header: {
                Text("Quick Profiles")
                    .foregroundStyle(Palette.textSecondary)
            }

            Section {
                Toggle(isOn: $highEnabled) {
                    Text("Enable High Alert")
                        .foregroundStyle(Palette.textPrimary)
                        .lineLimit(1)
                        .minimumScaleFactor(0.8)
                }
                .tint(Palette.primary)
                .listRowBackground(Palette.surface)
                .onChange(of: highEnabled) { _ in store.activeProfile = nil }

                if highEnabled {
                    VStack(alignment: .leading, spacing: 10) {
                        Text(String(format: "High threshold: %.0f°C", highThreshold))
                            .font(.subheadline.weight(.semibold))
                            .foregroundStyle(Palette.textPrimary)
                        Slider(value: $highThreshold, in: -20...50, step: 1)
                            .tint(Palette.primary)
                            .onChange(of: highThreshold) { value in
                                highText = String(format: "%.0f", value)
                                store.activeProfile = nil
                            }

                        TextField("High °C", text: $highText)
                            .keyboardType(.decimalPad)
                            .foregroundStyle(Palette.textPrimary)
                            .modifier(ShakeEffect(animatableData: shakeHigh))
                            .onChange(of: highText) { text in
                                if let v = Double(text.replacingOccurrences(of: ",", with: ".")) {
                                    highThreshold = min(max(v, -20), 50)
                                }
                            }
                    }
                    .listRowBackground(Palette.surface)
                }
            } header: {
                Text("High Temperature Alert")
                    .foregroundStyle(Palette.textSecondary)
            }

            Section {
                Toggle(isOn: $lowEnabled) {
                    Text("Enable Low Alert")
                        .foregroundStyle(Palette.textPrimary)
                        .lineLimit(1)
                        .minimumScaleFactor(0.8)
                }
                .tint(Palette.primary)
                .listRowBackground(Palette.surface)
                .onChange(of: lowEnabled) { _ in store.activeProfile = nil }

                if lowEnabled {
                    VStack(alignment: .leading, spacing: 10) {
                        Text(String(format: "Low threshold: %.0f°C", lowThreshold))
                            .font(.subheadline.weight(.semibold))
                            .foregroundStyle(Palette.textPrimary)
                        Slider(value: $lowThreshold, in: -40...40, step: 1)
                            .tint(Palette.accent)
                            .onChange(of: lowThreshold) { value in
                                lowText = String(format: "%.0f", value)
                                store.activeProfile = nil
                            }

                        TextField("Low °C", text: $lowText)
                            .keyboardType(.decimalPad)
                            .foregroundStyle(Palette.textPrimary)
                            .modifier(ShakeEffect(animatableData: shakeLow))
                            .onChange(of: lowText) { text in
                                if let v = Double(text.replacingOccurrences(of: ",", with: ".")) {
                                    lowThreshold = min(max(v, -40), 40)
                                }
                            }
                    }
                    .listRowBackground(Palette.surface)
                }
            } header: {
                Text("Low Temperature Alert")
                    .foregroundStyle(Palette.textSecondary)
            }

            if let validationError {
                Section {
                    Text(validationError)
                        .font(.caption)
                        .foregroundStyle(Color.red.opacity(0.9))
                        .listRowBackground(Palette.surface)
                }
            }

            Section {
                Button {
                    save()
                } label: {
                    Text("Save Alerts")
                        .frame(maxWidth: .infinity)
                        .font(.headline.weight(.semibold))
                        .foregroundStyle(Palette.background)
                }
                .listRowBackground(
                    LinearGradient(
                        colors: [Palette.primary, Palette.accent],
                        startPoint: .leading,
                        endPoint: .trailing
                    )
                )

                if store.alertConfig.anyEnabled {
                    Button(role: .destructive) {
                        HapticService.warning()
                        highEnabled = false
                        lowEnabled = false
                        store.saveAlerts(
                            TemperatureAlertConfig(
                                highEnabled: false,
                                lowEnabled: false,
                                highThreshold: highThreshold,
                                lowThreshold: lowThreshold
                            ),
                            profile: nil
                        )
                        showEditor = false
                    } label: {
                        Text("Disable All Alerts")
                            .frame(maxWidth: .infinity)
                    }
                    .listRowBackground(Palette.surface)
                }
            }

            Section {
                NavigationLink {
                    TriggerHistoryView()
                } label: {
                    HStack {
                        Image(systemName: "clock.arrow.circlepath")
                            .foregroundStyle(Palette.primary)
                        Text("Full Trigger History")
                            .foregroundStyle(Palette.textPrimary)
                    }
                }
                .listRowBackground(Palette.surface)

                ForEach(store.triggerEvents.prefix(5)) { event in
                    HStack {
                        Image(systemName: event.kind == "high" ? "sun.max.fill" : "snowflake")
                            .foregroundStyle(Palette.primary)
                        VStack(alignment: .leading, spacing: 2) {
                            Text(event.kind == "high" ? "High threshold crossed" : "Low threshold crossed")
                                .font(.subheadline.weight(.semibold))
                                .foregroundStyle(Palette.textPrimary)
                                .lineLimit(1)
                                .minimumScaleFactor(0.8)
                            Text(String(format: "%.1f° vs %.0f° · %@", event.temperature, event.threshold, timeLabel(event.timestamp)))
                                .font(.caption)
                                .foregroundStyle(Palette.textSecondary)
                        }
                    }
                    .listRowBackground(Palette.surface)
                }
            } header: {
                Text("Recent Triggers")
                    .foregroundStyle(Palette.textSecondary)
            }
        }
        .scrollContentBackground(.hidden)
    }

    private func loadFromStore() {
        highEnabled = store.alertConfig.highEnabled
        lowEnabled = store.alertConfig.lowEnabled
        highThreshold = store.alertConfig.highThreshold
        lowThreshold = store.alertConfig.lowThreshold
        highText = String(format: "%.0f", highThreshold)
        lowText = String(format: "%.0f", lowThreshold)
    }

    private func save() {
        if highEnabled && lowEnabled && lowThreshold >= highThreshold {
            validationError = "Low threshold must be below high threshold."
            HapticService.warning()
            withAnimation(.default) {
                shakeHigh += 1
                shakeLow += 1
            }
            return
        }
        if !highEnabled && !lowEnabled {
            validationError = "Enable at least one alert to save."
            HapticService.warning()
            return
        }
        validationError = nil
        store.saveAlerts(
            TemperatureAlertConfig(
                highEnabled: highEnabled,
                lowEnabled: lowEnabled,
                highThreshold: highThreshold,
                lowThreshold: lowThreshold
            ),
            profile: store.activeProfile
        )
        showEditor = true
        withAnimation { showSavedBanner = true }
        DispatchQueue.main.asyncAfter(deadline: .now() + 1.4) {
            withAnimation { showSavedBanner = false }
        }
    }

    private func timeLabel(_ date: Date) -> String {
        let formatter = DateFormatter()
        formatter.locale = Locale(identifier: "en_US_POSIX")
        formatter.dateFormat = "MMM d, HH:mm"
        return formatter.string(from: date)
    }
}
