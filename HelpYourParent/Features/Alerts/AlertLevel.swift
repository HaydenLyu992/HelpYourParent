import SwiftUI

/// The severity level of a health alert.
enum AlertLevel: String, Codable, Comparable, CaseIterable {
    case yellow = "YELLOW"
    case orange = "ORANGE"
    case red = "RED"

    static func < (lhs: AlertLevel, rhs: AlertLevel) -> Bool {
        let order: [AlertLevel] = [.yellow, .orange, .red]
        return (order.firstIndex(of: lhs) ?? 0) < (order.firstIndex(of: rhs) ?? 0)
    }

    var displayName: String {
        switch self {
        case .yellow: return String(localized: "alert_level_yellow", defaultValue: "轻微")
        case .orange: return String(localized: "alert_level_orange", defaultValue: "注意")
        case .red: return String(localized: "alert_level_red", defaultValue: "紧急")
        }
    }

    var emoji: String {
        switch self {
        case .yellow: return "🟡"
        case .orange: return "🟠"
        case .red: return "🔴"
        }
    }

    var color: Color {
        switch self {
        case .yellow: return .doodleBadgeOK
        case .orange: return .doodleBadgeWarn
        case .red: return .doodleBadgeDanger
        }
    }
}
