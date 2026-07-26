import Foundation
import SwiftUI
import Combine

final class AppDataStore: ObservableObject {
    static let shared = AppDataStore()

    @Published var readings: [TemperatureReading] = []
    @Published var alertConfig: TemperatureAlertConfig = .default
    @Published var daySummaries: [DayTemperature] = []
    @Published var triggerEvents: [AlertTriggerEvent] = []
    @Published var stats: UserStats = UserStats()
    @Published var unlockedAchievements: Set<String> = []
    @Published var hasSeenOnboarding: Bool = false
    @Published var hasSeenCoachTour: Bool = false
    @Published var comfortZone: ComfortZone = .default
    @Published var reminderSettings: ReminderSettings = .default
    @Published var activeProfile: AlertProfile?
    @Published var bannerTitle: String?
    @Published var showSuccessFlash: Bool = false
    @Published var lastTriggerMessage: String?
    @Published var comfortHint: String?

    private let defaults = UserDefaults.standard
    private let readingsKey = "ww_readings"
    private let alertsKey = "ww_alerts"
    private let daysKey = "ww_days"
    private let triggersKey = "ww_triggers"
    private let statsKey = "ww_stats"
    private let unlockedKey = "ww_unlocked"
    private let onboardingKey = "ww_onboarding"
    private let coachKey = "ww_coach_tour"
    private let comfortKey = "ww_comfort"
    private let reminderKey = "ww_reminder"
    private let profileKey = "ww_alert_profile"

    private var bannerQueue: [String] = []
    private var isShowingBanner = false
    private var sessionStartedAt = Date()

    private init() {
        load()
        recordOpenMinute()
        if reminderSettings.enabled {
            ReminderService.schedule(settings: reminderSettings)
        }
    }

    // MARK: - Temperature logging

    @discardableResult
    func logTemperature(_ value: Double, note: String = "", tag: String = "") -> TemperatureReading? {
        guard value >= -50, value <= 60 else { return nil }
        let reading = TemperatureReading(temperature: value, note: note, tag: tag)
        readings.insert(reading, at: 0)
        stats.readingsLogged += 1
        updateDaySummary(with: value, at: reading.timestamp)
        recordActivity()
        checkAlertTriggers(for: value)
        updateComfortHint(for: value)
        persist()
        flashSuccess()
        evaluateAchievements()
        HapticService.medium()
        return reading
    }

    func deleteReading(_ reading: TemperatureReading) {
        readings.removeAll { $0.id == reading.id }
        rebuildDaySummaries()
        persist()
        HapticService.warning()
    }

    func deleteTrigger(_ event: AlertTriggerEvent) {
        triggerEvents.removeAll { $0.id == event.id }
        persist()
        HapticService.warning()
    }

    // MARK: - Alerts

    func saveAlerts(_ config: TemperatureAlertConfig, profile: AlertProfile? = nil) {
        alertConfig = config
        activeProfile = profile
        if config.anyEnabled {
            stats.itemsCreated += 1
            recordActivity()
            flashSuccess()
        }
        persist()
        evaluateAchievements()
        HapticService.success()
    }

    func applyProfile(_ profile: AlertProfile) {
        saveAlerts(profile.config, profile: profile)
    }

    // MARK: - Comfort / Reminder / Coach

    func saveComfortZone(_ zone: ComfortZone) {
        comfortZone = zone
        if let temp = latestTemperature {
            updateComfortHint(for: temp)
        } else {
            comfortHint = nil
        }
        persist()
        HapticService.light()
    }

    func saveReminderSettings(_ settings: ReminderSettings) {
        reminderSettings = settings
        persist()
        if settings.enabled {
            ReminderService.requestPermission { granted in
                if granted {
                    ReminderService.schedule(settings: settings)
                } else {
                    self.reminderSettings.enabled = false
                    self.persist()
                }
            }
        } else {
            ReminderService.cancel()
        }
        HapticService.light()
    }

    func completeOnboarding() {
        hasSeenOnboarding = true
        defaults.set(true, forKey: onboardingKey)
        HapticService.success()
    }

    func completeCoachTour() {
        hasSeenCoachTour = true
        defaults.set(true, forKey: coachKey)
        HapticService.success()
    }

    func restartCoachTour() {
        hasSeenCoachTour = false
        defaults.set(false, forKey: coachKey)
        HapticService.light()
    }

    // MARK: - Derived data

    var todayReadings: [TemperatureReading] {
        let cal = Calendar.current
        return readings
            .filter { cal.isDateInToday($0.timestamp) }
            .sorted { $0.timestamp < $1.timestamp }
    }

    var latestTemperature: Double? {
        readings.first?.temperature
    }

    var todayHigh: Double? {
        todayReadings.map(\.temperature).max()
    }

    var todayLow: Double? {
        todayReadings.map(\.temperature).min()
    }

    var weeklyDaySummaries: [DayTemperature] {
        daySummaries(forLast: 7)
    }

    var previousWeekDaySummaries: [DayTemperature] {
        let cal = Calendar.current
        let today = cal.startOfDay(for: Date())
        return (7..<14).compactMap { offset -> DayTemperature? in
            guard let day = cal.date(byAdding: .day, value: -offset, to: today) else { return nil }
            return snapshotDay(day)
        }.reversed()
    }

    var weekComparison: WeekComparison {
        let thisDays = weeklyDaySummaries
        let lastDays = previousWeekDaySummaries
        let thisReadings = readingsInLastDays(0..<7)
        let lastReadings = readingsInLastDays(7..<14)
        let thisTriggers = triggersInLastDays(0..<7)
        let lastTriggers = triggersInLastDays(7..<14)

        func avg(_ days: [DayTemperature]) -> Double? {
            guard !days.isEmpty else { return nil }
            return days.map { ($0.high + $0.low) / 2 }.reduce(0, +) / Double(days.count)
        }
        func spread(_ days: [DayTemperature]) -> Double? {
            guard !days.isEmpty else { return nil }
            return days.map { $0.high - $0.low }.reduce(0, +) / Double(days.count)
        }

        return WeekComparison(
            thisAvg: avg(thisDays),
            lastAvg: avg(lastDays),
            thisSpread: spread(thisDays),
            lastSpread: spread(lastDays),
            thisTriggers: thisTriggers.count,
            lastTriggers: lastTriggers.count,
            thisReadings: thisReadings.count,
            lastReadings: lastReadings.count
        )
    }

    var dailySnapshots: [DaySnapshot] {
        let cal = Calendar.current
        let today = cal.startOfDay(for: Date())
        return (0..<14).compactMap { offset -> DaySnapshot? in
            guard let day = cal.date(byAdding: .day, value: -offset, to: today) else { return nil }
            let dayReadings = readings.filter { cal.isDate($0.timestamp, inSameDayAs: day) }
            guard !dayReadings.isEmpty else { return nil }
            let temps = dayReadings.map(\.temperature)
            let events = triggerEvents.filter { cal.isDate($0.timestamp, inSameDayAs: day) }
            return DaySnapshot(
                date: day,
                high: temps.max() ?? 0,
                low: temps.min() ?? 0,
                average: temps.reduce(0, +) / Double(temps.count),
                readingCount: dayReadings.count,
                triggerCount: events.count,
                highTriggers: events.filter { $0.kind == "high" }.count,
                lowTriggers: events.filter { $0.kind == "low" }.count
            )
        }
    }

    var todaySnapshot: DaySnapshot? {
        dailySnapshots.first { Calendar.current.isDateInToday($0.date) }
    }

    // MARK: - Reset

    func resetAll() {
        readings = []
        alertConfig = .default
        daySummaries = []
        triggerEvents = []
        stats = UserStats()
        unlockedAchievements = []
        comfortZone = .default
        reminderSettings = .default
        activeProfile = nil
        bannerTitle = nil
        lastTriggerMessage = nil
        comfortHint = nil
        bannerQueue.removeAll()
        isShowingBanner = false
        ReminderService.cancel()
        persist()
        NotificationCenter.default.post(name: .dataReset, object: nil)
        HapticService.warning()
    }

    // MARK: - Achievements

    func evaluateAchievements() {
        for kind in AchievementKind.allCases {
            guard kind.isUnlocked(stats: stats) else { continue }
            let key = kind.rawValue
            guard !unlockedAchievements.contains(key) else { continue }
            unlockedAchievements.insert(key)
            enqueueBanner(kind.title)
        }
        persist()
    }

    private func enqueueBanner(_ title: String) {
        bannerQueue.append(title)
        presentNextBannerIfNeeded()
    }

    private func presentNextBannerIfNeeded() {
        guard !isShowingBanner, let next = bannerQueue.first else { return }
        bannerQueue.removeFirst()
        isShowingBanner = true
        HapticService.success()
        withAnimation(.spring(response: 0.45, dampingFraction: 0.8)) {
            bannerTitle = next
        }
        DispatchQueue.main.asyncAfter(deadline: .now() + 2.0) { [weak self] in
            withAnimation(.easeOut(duration: 0.35)) {
                self?.bannerTitle = nil
            }
            DispatchQueue.main.asyncAfter(deadline: .now() + 0.4) {
                self?.isShowingBanner = false
                self?.presentNextBannerIfNeeded()
            }
        }
    }

    func flashSuccess() {
        withAnimation(.spring(response: 0.35, dampingFraction: 0.7)) {
            showSuccessFlash = true
        }
        DispatchQueue.main.asyncAfter(deadline: .now() + 1.0) { [weak self] in
            withAnimation(.easeOut(duration: 0.3)) {
                self?.showSuccessFlash = false
            }
        }
    }

    // MARK: - Private helpers

    private func checkAlertTriggers(for temperature: Double) {
        var triggered = false
        if alertConfig.highEnabled, temperature >= alertConfig.highThreshold {
            let event = AlertTriggerEvent(
                kind: "high",
                temperature: temperature,
                threshold: alertConfig.highThreshold
            )
            triggerEvents.insert(event, at: 0)
            stats.sessionsCompleted += 1
            stats.highTriggers += 1
            lastTriggerMessage = String(format: "High alert: %.0f° reached", temperature)
            triggered = true
        }
        if alertConfig.lowEnabled, temperature <= alertConfig.lowThreshold {
            let event = AlertTriggerEvent(
                kind: "low",
                temperature: temperature,
                threshold: alertConfig.lowThreshold
            )
            triggerEvents.insert(event, at: 0)
            stats.sessionsCompleted += 1
            stats.lowTriggers += 1
            lastTriggerMessage = String(format: "Low alert: %.0f° reached", temperature)
            triggered = true
        }
        if triggered {
            HapticService.warning()
            DispatchQueue.main.asyncAfter(deadline: .now() + 2.5) { [weak self] in
                withAnimation { self?.lastTriggerMessage = nil }
            }
        }
    }

    private func updateComfortHint(for temperature: Double) {
        let status = comfortZone.status(for: temperature)
        withAnimation(.easeInOut(duration: 0.25)) {
            switch status {
            case .disabled:
                comfortHint = nil
            case .comfortable, .tooCold, .tooWarm:
                comfortHint = status.message
            }
        }
    }

    private func updateDaySummary(with value: Double, at date: Date) {
        let cal = Calendar.current
        let start = cal.startOfDay(for: date)
        if let idx = daySummaries.firstIndex(where: { cal.isDate($0.date, inSameDayAs: start) }) {
            daySummaries[idx].high = max(daySummaries[idx].high, value)
            daySummaries[idx].low = min(daySummaries[idx].low, value)
        } else {
            daySummaries.insert(DayTemperature(date: start, high: value, low: value), at: 0)
        }
    }

    private func rebuildDaySummaries() {
        let cal = Calendar.current
        let grouped = Dictionary(grouping: readings) { cal.startOfDay(for: $0.timestamp) }
        daySummaries = grouped.map { day, items in
            DayTemperature(
                date: day,
                high: items.map(\.temperature).max() ?? 0,
                low: items.map(\.temperature).min() ?? 0
            )
        }.sorted { $0.date > $1.date }
    }

    private func daySummaries(forLast days: Int) -> [DayTemperature] {
        let cal = Calendar.current
        let today = cal.startOfDay(for: Date())
        return (0..<days).compactMap { offset -> DayTemperature? in
            guard let day = cal.date(byAdding: .day, value: -offset, to: today) else { return nil }
            return snapshotDay(day)
        }.reversed()
    }

    private func snapshotDay(_ day: Date) -> DayTemperature? {
        let cal = Calendar.current
        if let existing = daySummaries.first(where: { cal.isDate($0.date, inSameDayAs: day) }) {
            return existing
        }
        let dayReadings = readings.filter { cal.isDate($0.timestamp, inSameDayAs: day) }
        guard let high = dayReadings.map(\.temperature).max(),
              let low = dayReadings.map(\.temperature).min() else { return nil }
        return DayTemperature(date: day, high: high, low: low)
    }

    private func readingsInLastDays(_ range: Range<Int>) -> [TemperatureReading] {
        let cal = Calendar.current
        let today = cal.startOfDay(for: Date())
        return readings.filter { reading in
            guard let days = cal.dateComponents([.day], from: cal.startOfDay(for: reading.timestamp), to: today).day else { return false }
            return range.contains(days)
        }
    }

    private func triggersInLastDays(_ range: Range<Int>) -> [AlertTriggerEvent] {
        let cal = Calendar.current
        let today = cal.startOfDay(for: Date())
        return triggerEvents.filter { event in
            guard let days = cal.dateComponents([.day], from: cal.startOfDay(for: event.timestamp), to: today).day else { return false }
            return range.contains(days)
        }
    }

    private func recordActivity() {
        let formatter = DateFormatter()
        formatter.calendar = Calendar.current
        formatter.locale = Locale(identifier: "en_US_POSIX")
        formatter.dateFormat = "yyyy-MM-dd"
        let today = formatter.string(from: Date())
        if stats.lastActiveDay.isEmpty {
            stats.streakDays = 1
            stats.lastActiveDay = today
            return
        }
        if stats.lastActiveDay == today { return }
        if let yesterday = Calendar.current.date(byAdding: .day, value: -1, to: Date()),
           formatter.string(from: yesterday) == stats.lastActiveDay {
            stats.streakDays += 1
        } else {
            stats.streakDays = 1
        }
        stats.lastActiveDay = today
    }

    private func recordOpenMinute() {
        let elapsed = Int(Date().timeIntervalSince(sessionStartedAt) / 60)
        if elapsed > 0 {
            stats.totalMinutesUsed += elapsed
            sessionStartedAt = Date()
            persist()
        }
    }

    private func load() {
        hasSeenOnboarding = defaults.bool(forKey: onboardingKey)
        hasSeenCoachTour = defaults.bool(forKey: coachKey)
        if let data = defaults.data(forKey: readingsKey),
           let decoded = try? JSONDecoder().decode([TemperatureReading].self, from: data) {
            readings = decoded
        }
        if let data = defaults.data(forKey: alertsKey),
           let decoded = try? JSONDecoder().decode(TemperatureAlertConfig.self, from: data) {
            alertConfig = decoded
        }
        if let data = defaults.data(forKey: daysKey),
           let decoded = try? JSONDecoder().decode([DayTemperature].self, from: data) {
            daySummaries = decoded
        }
        if let data = defaults.data(forKey: triggersKey),
           let decoded = try? JSONDecoder().decode([AlertTriggerEvent].self, from: data) {
            triggerEvents = decoded
        }
        if let data = defaults.data(forKey: statsKey),
           let decoded = try? JSONDecoder().decode(UserStats.self, from: data) {
            stats = decoded
        }
        if let arr = defaults.array(forKey: unlockedKey) as? [String] {
            unlockedAchievements = Set(arr)
        }
        if let data = defaults.data(forKey: comfortKey),
           let decoded = try? JSONDecoder().decode(ComfortZone.self, from: data) {
            comfortZone = decoded
        }
        if let data = defaults.data(forKey: reminderKey),
           let decoded = try? JSONDecoder().decode(ReminderSettings.self, from: data) {
            reminderSettings = decoded
        }
        if let raw = defaults.string(forKey: profileKey),
           let profile = AlertProfile(rawValue: raw) {
            activeProfile = profile
        }
        if let temp = latestTemperature {
            updateComfortHint(for: temp)
        }
        if stats.highTriggers == 0 && stats.lowTriggers == 0 && !triggerEvents.isEmpty {
            stats.highTriggers = triggerEvents.filter { $0.kind == "high" }.count
            stats.lowTriggers = triggerEvents.filter { $0.kind == "low" }.count
        }
    }

    private func persist() {
        if let data = try? JSONEncoder().encode(readings) {
            defaults.set(data, forKey: readingsKey)
        }
        if let data = try? JSONEncoder().encode(alertConfig) {
            defaults.set(data, forKey: alertsKey)
        }
        if let data = try? JSONEncoder().encode(daySummaries) {
            defaults.set(data, forKey: daysKey)
        }
        if let data = try? JSONEncoder().encode(triggerEvents) {
            defaults.set(data, forKey: triggersKey)
        }
        if let data = try? JSONEncoder().encode(stats) {
            defaults.set(data, forKey: statsKey)
        }
        if let data = try? JSONEncoder().encode(comfortZone) {
            defaults.set(data, forKey: comfortKey)
        }
        if let data = try? JSONEncoder().encode(reminderSettings) {
            defaults.set(data, forKey: reminderKey)
        }
        defaults.set(Array(unlockedAchievements), forKey: unlockedKey)
        defaults.set(hasSeenOnboarding, forKey: onboardingKey)
        defaults.set(hasSeenCoachTour, forKey: coachKey)
        if let activeProfile {
            defaults.set(activeProfile.rawValue, forKey: profileKey)
        } else {
            defaults.removeObject(forKey: profileKey)
        }
    }
}
