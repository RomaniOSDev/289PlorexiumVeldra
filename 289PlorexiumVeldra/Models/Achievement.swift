import Foundation

enum AchievementKind: String, Codable, CaseIterable {
    case firstSetup
    case temperatureTracker
    case alertEnthusiast
    case warmWelcome
    case stayCool
    case weeklyMonitor
    case patternObserver
    case proactivePlanner

    var title: String {
        switch self {
        case .firstSetup: return "First Setup"
        case .temperatureTracker: return "Temperature Tracker"
        case .alertEnthusiast: return "Alert Enthusiast"
        case .warmWelcome: return "Warm Welcome"
        case .stayCool: return "Stay Cool"
        case .weeklyMonitor: return "Weekly Monitor"
        case .patternObserver: return "Pattern Observer"
        case .proactivePlanner: return "Proactive Planner"
        }
    }

    var detail: String {
        switch self {
        case .firstSetup: return "You set up your first custom alert."
        case .temperatureTracker: return "Tracked temperatures for seven consecutive days."
        case .alertEnthusiast: return "Created ten custom alerts."
        case .warmWelcome: return "Received an alert for a high temperature threshold."
        case .stayCool: return "Received an alert for a low-temperature threshold."
        case .weeklyMonitor: return "Checked the app every day for one week."
        case .patternObserver: return "Analyzed trends over four weeks."
        case .proactivePlanner: return "Acted on thirty different alerts."
        }
    }

    var icon: String {
        switch self {
        case .firstSetup: return "bell.badge.fill"
        case .temperatureTracker: return "thermometer.medium"
        case .alertEnthusiast: return "bell.fill"
        case .warmWelcome: return "sun.max.fill"
        case .stayCool: return "snowflake"
        case .weeklyMonitor: return "calendar"
        case .patternObserver: return "chart.xyaxis.line"
        case .proactivePlanner: return "checkmark.seal.fill"
        }
    }

    var goal: Int {
        switch self {
        case .firstSetup: return 1
        case .temperatureTracker: return 7
        case .alertEnthusiast: return 10
        case .warmWelcome: return 1
        case .stayCool: return 1
        case .weeklyMonitor: return 7
        case .patternObserver: return 28
        case .proactivePlanner: return 30
        }
    }

    func progress(stats: UserStats) -> Int {
        switch self {
        case .firstSetup, .alertEnthusiast:
            return stats.itemsCreated
        case .temperatureTracker, .weeklyMonitor:
            return stats.streakDays
        case .warmWelcome:
            return stats.highTriggers
        case .stayCool:
            return stats.lowTriggers
        case .patternObserver:
            return stats.streakDays
        case .proactivePlanner:
            return stats.sessionsCompleted
        }
    }

    func isUnlocked(stats: UserStats) -> Bool {
        progress(stats: stats) >= goal
    }
}

struct UserStats: Codable, Equatable {
    var itemsCreated: Int = 0
    var sessionsCompleted: Int = 0
    var streakDays: Int = 0
    var lastActiveDay: String = ""
    var totalMinutesUsed: Int = 0
    var readingsLogged: Int = 0
    var highTriggers: Int = 0
    var lowTriggers: Int = 0

    enum CodingKeys: String, CodingKey {
        case itemsCreated, sessionsCompleted, streakDays, lastActiveDay
        case totalMinutesUsed, readingsLogged, highTriggers, lowTriggers
    }

    init(
        itemsCreated: Int = 0,
        sessionsCompleted: Int = 0,
        streakDays: Int = 0,
        lastActiveDay: String = "",
        totalMinutesUsed: Int = 0,
        readingsLogged: Int = 0,
        highTriggers: Int = 0,
        lowTriggers: Int = 0
    ) {
        self.itemsCreated = itemsCreated
        self.sessionsCompleted = sessionsCompleted
        self.streakDays = streakDays
        self.lastActiveDay = lastActiveDay
        self.totalMinutesUsed = totalMinutesUsed
        self.readingsLogged = readingsLogged
        self.highTriggers = highTriggers
        self.lowTriggers = lowTriggers
    }

    init(from decoder: Decoder) throws {
        let c = try decoder.container(keyedBy: CodingKeys.self)
        itemsCreated = try c.decodeIfPresent(Int.self, forKey: .itemsCreated) ?? 0
        sessionsCompleted = try c.decodeIfPresent(Int.self, forKey: .sessionsCompleted) ?? 0
        streakDays = try c.decodeIfPresent(Int.self, forKey: .streakDays) ?? 0
        lastActiveDay = try c.decodeIfPresent(String.self, forKey: .lastActiveDay) ?? ""
        totalMinutesUsed = try c.decodeIfPresent(Int.self, forKey: .totalMinutesUsed) ?? 0
        readingsLogged = try c.decodeIfPresent(Int.self, forKey: .readingsLogged) ?? 0
        highTriggers = try c.decodeIfPresent(Int.self, forKey: .highTriggers) ?? 0
        lowTriggers = try c.decodeIfPresent(Int.self, forKey: .lowTriggers) ?? 0
    }
}

extension Notification.Name {
    static let dataReset = Notification.Name("dataReset")
}
