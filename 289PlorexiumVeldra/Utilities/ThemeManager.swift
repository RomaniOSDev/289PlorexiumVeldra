import SwiftUI
import Combine

enum AppTheme: String, CaseIterable, Identifiable, Codable {
    case amber
    case ocean
    case ember

    var id: String { rawValue }

    var title: String {
        switch self {
        case .amber: return "Amber"
        case .ocean: return "Ocean"
        case .ember: return "Ember"
        }
    }

    var icon: String {
        switch self {
        case .amber: return "sun.max.fill"
        case .ocean: return "drop.fill"
        case .ember: return "flame.fill"
        }
    }

    var palette: ThemePalette {
        switch self {
        case .amber:
            return ThemePalette(
                primary: Color(red: 0.988, green: 0.816, blue: 0.290),
                accent: Color(red: 0.992, green: 0.851, blue: 0.431),
                background: Color(red: 0.07, green: 0.08, blue: 0.10),
                surface: Color(red: 0.12, green: 0.13, blue: 0.16),
                textPrimary: Color(red: 0.96, green: 0.96, blue: 0.97),
                textSecondary: Color(red: 0.70, green: 0.72, blue: 0.76)
            )
        case .ocean:
            return ThemePalette(
                primary: Color(red: 0.35, green: 0.78, blue: 0.86),
                accent: Color(red: 0.45, green: 0.88, blue: 0.78),
                background: Color(red: 0.05, green: 0.09, blue: 0.14),
                surface: Color(red: 0.09, green: 0.14, blue: 0.20),
                textPrimary: Color(red: 0.93, green: 0.97, blue: 0.99),
                textSecondary: Color(red: 0.62, green: 0.72, blue: 0.80)
            )
        case .ember:
            return ThemePalette(
                primary: Color(red: 0.96, green: 0.45, blue: 0.28),
                accent: Color(red: 0.98, green: 0.62, blue: 0.32),
                background: Color(red: 0.10, green: 0.07, blue: 0.06),
                surface: Color(red: 0.16, green: 0.11, blue: 0.09),
                textPrimary: Color(red: 0.98, green: 0.95, blue: 0.92),
                textSecondary: Color(red: 0.78, green: 0.68, blue: 0.60)
            )
        }
    }
}

struct ThemePalette {
    let primary: Color
    let accent: Color
    let background: Color
    let surface: Color
    let textPrimary: Color
    let textSecondary: Color
}

final class ThemeManager: ObservableObject {
    static let shared = ThemeManager()

    private let key = "ww_theme"

    @Published var theme: AppTheme {
        didSet {
            UserDefaults.standard.set(theme.rawValue, forKey: key)
        }
    }

    var palette: ThemePalette { theme.palette }

    private init() {
        if let raw = UserDefaults.standard.string(forKey: key),
           let saved = AppTheme(rawValue: raw) {
            theme = saved
        } else {
            theme = .amber
        }
    }
}

enum Palette {
    static var primary: Color { ThemeManager.shared.palette.primary }
    static var accent: Color { ThemeManager.shared.palette.accent }
    static var background: Color { ThemeManager.shared.palette.background }
    static var surface: Color { ThemeManager.shared.palette.surface }
    static var textPrimary: Color { ThemeManager.shared.palette.textPrimary }
    static var textSecondary: Color { ThemeManager.shared.palette.textSecondary }
}
