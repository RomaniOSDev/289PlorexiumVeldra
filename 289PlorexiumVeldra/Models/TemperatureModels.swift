import Foundation
import SwiftUI

// MARK: - Reading tags

enum ReadingTag: String, CaseIterable, Codable, Identifiable {
    case indoors
    case outdoors
    case bedroom
    case office
    case other

    var id: String { rawValue }

    var title: String {
        switch self {
        case .indoors: return "Indoors"
        case .outdoors: return "Outdoors"
        case .bedroom: return "Bedroom"
        case .office: return "Office"
        case .other: return "Other"
        }
    }

    var icon: String {
        switch self {
        case .indoors: return "house.fill"
        case .outdoors: return "sun.max.fill"
        case .bedroom: return "bed.double.fill"
        case .office: return "briefcase.fill"
        case .other: return "tag.fill"
        }
    }
}

struct TemperatureReading: Identifiable, Codable, Equatable {
    var id: UUID
    var temperature: Double
    var timestamp: Date
    var note: String
    var tag: String

    init(
        id: UUID = UUID(),
        temperature: Double,
        timestamp: Date = Date(),
        note: String = "",
        tag: String = ""
    ) {
        self.id = id
        self.temperature = temperature
        self.timestamp = timestamp
        self.note = note
        self.tag = tag
    }

    var readingTag: ReadingTag? {
        ReadingTag(rawValue: tag)
    }

    enum CodingKeys: String, CodingKey {
        case id, temperature, timestamp, note, tag
    }

    init(from decoder: Decoder) throws {
        let c = try decoder.container(keyedBy: CodingKeys.self)
        id = try c.decode(UUID.self, forKey: .id)
        temperature = try c.decode(Double.self, forKey: .temperature)
        timestamp = try c.decode(Date.self, forKey: .timestamp)
        note = try c.decodeIfPresent(String.self, forKey: .note) ?? ""
        tag = try c.decodeIfPresent(String.self, forKey: .tag) ?? ""
    }
}

struct TemperatureAlertConfig: Codable, Equatable {
    var highEnabled: Bool
    var lowEnabled: Bool
    var highThreshold: Double
    var lowThreshold: Double

    static let `default` = TemperatureAlertConfig(
        highEnabled: false,
        lowEnabled: false,
        highThreshold: 30,
        lowThreshold: 5
    )

    var anyEnabled: Bool { highEnabled || lowEnabled }
}

enum AlertProfile: String, CaseIterable, Identifiable, Codable {
    case home
    case outside
    case sleep

    var id: String { rawValue }

    var title: String {
        switch self {
        case .home: return "Home"
        case .outside: return "Outside"
        case .sleep: return "Sleep"
        }
    }

    var icon: String {
        switch self {
        case .home: return "house.fill"
        case .outside: return "cloud.sun.fill"
        case .sleep: return "moon.zzz.fill"
        }
    }

    var config: TemperatureAlertConfig {
        switch self {
        case .home:
            return TemperatureAlertConfig(highEnabled: true, lowEnabled: true, highThreshold: 28, lowThreshold: 16)
        case .outside:
            return TemperatureAlertConfig(highEnabled: true, lowEnabled: true, highThreshold: 32, lowThreshold: 0)
        case .sleep:
            return TemperatureAlertConfig(highEnabled: true, lowEnabled: true, highThreshold: 24, lowThreshold: 16)
        }
    }
}

struct ComfortZone: Codable, Equatable {
    var enabled: Bool
    var minCelsius: Double
    var maxCelsius: Double

    static let `default` = ComfortZone(enabled: false, minCelsius: 18, maxCelsius: 24)

    func status(for temperature: Double) -> ComfortStatus {
        guard enabled else { return .disabled }
        if temperature < minCelsius { return .tooCold }
        if temperature > maxCelsius { return .tooWarm }
        return .comfortable
    }
}

enum ComfortStatus {
    case disabled
    case comfortable
    case tooCold
    case tooWarm

    var message: String {
        switch self {
        case .disabled: return ""
        case .comfortable: return "Inside your comfort zone"
        case .tooCold: return "Below comfort zone"
        case .tooWarm: return "Above comfort zone"
        }
    }

    var icon: String {
        switch self {
        case .disabled: return "circle"
        case .comfortable: return "checkmark.circle.fill"
        case .tooCold: return "thermometer.snowflake"
        case .tooWarm: return "thermometer.sun.fill"
        }
    }
}

struct DayTemperature: Identifiable, Codable, Equatable {
    var id: UUID
    var date: Date
    var high: Double
    var low: Double

    init(id: UUID = UUID(), date: Date, high: Double, low: Double) {
        self.id = id
        self.date = date
        self.high = high
        self.low = low
    }
}

struct DaySnapshot: Identifiable, Equatable {
    var id: Date { date }
    let date: Date
    let high: Double
    let low: Double
    let average: Double
    let readingCount: Int
    let triggerCount: Int
    let highTriggers: Int
    let lowTriggers: Int

    var hadAlert: Bool { triggerCount > 0 }
}

struct AlertTriggerEvent: Identifiable, Codable, Equatable {
    var id: UUID
    var kind: String
    var temperature: Double
    var threshold: Double
    var timestamp: Date

    init(id: UUID = UUID(), kind: String, temperature: Double, threshold: Double, timestamp: Date = Date()) {
        self.id = id
        self.kind = kind
        self.temperature = temperature
        self.threshold = threshold
        self.timestamp = timestamp
    }
}

struct WeekComparison: Equatable {
    let thisAvg: Double?
    let lastAvg: Double?
    let thisSpread: Double?
    let lastSpread: Double?
    let thisTriggers: Int
    let lastTriggers: Int
    let thisReadings: Int
    let lastReadings: Int

    var avgDelta: Double? {
        guard let thisAvg, let lastAvg else { return nil }
        return thisAvg - lastAvg
    }
}

struct ReminderSettings: Codable, Equatable {
    var enabled: Bool
    var hour: Int
    var minute: Int

    static let `default` = ReminderSettings(enabled: false, hour: 20, minute: 0)
}
