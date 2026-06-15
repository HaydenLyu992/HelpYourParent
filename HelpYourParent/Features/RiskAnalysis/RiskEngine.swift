import Foundation

/// The result of evaluating a single risk rule.
struct RiskResult {
    enum Level: String, Comparable {
        case normal = "normal"
        case yellow = "yellow"
        case orange = "orange"
        case red = "red"

        static func < (lhs: Level, rhs: Level) -> Bool {
            let order: [Level] = [.normal, .yellow, .orange, .red]
            return (order.firstIndex(of: lhs) ?? 0) < (order.firstIndex(of: rhs) ?? 0)
        }
    }

    let level: Level
    let riskName: String
    let riskType: String
    let advice: String
    let metrics: [String: Double]

    init(level: Level, riskName: String, riskType: String, advice: String, metrics: [String: Double] = [:]) {
        self.level = level
        self.riskName = riskName
        self.riskType = riskType
        self.advice = advice
        self.metrics = metrics
    }
}

/// Protocol that all risk evaluation rules must implement.
protocol RiskRule {
    func evaluate(snapshot: HealthSnapshot, profile: ElderProfile?) -> RiskResult?
}

/// A model representing an elder's health profile for risk evaluation context.
struct ElderProfile {
    var height: Double?
    var weight: Double?
    var bloodType: String?
    var birthday: Date?
    var medicalHistory: [String]?
    var medications: [String]?
    var allergies: [String]?

    var age: Int? {
        guard let birthday else { return nil }
        return Calendar.current.dateComponents([.year], from: birthday, to: Date()).year
    }
}

/// The central risk evaluation engine that runs all configured rules against a health snapshot.
///
/// Each rule implements `RiskRule` and returns an optional `RiskResult`.
/// When multiple rules fire, the engine returns them all sorted by severity (highest first).
@Observable
final class RiskEngine {
    private let rules: [RiskRule]

    /// The results from the most recent evaluation.
    private(set) var lastResults: [RiskResult] = []

    init(rules: [RiskRule] = RiskEngine.defaultRules) {
        self.rules = rules
    }

    /// Evaluate all rules against the given snapshot and profile.
    /// - Returns: All triggered risk results, sorted by descending severity.
    @discardableResult
    func evaluate(snapshot: HealthSnapshot, profile: ElderProfile? = nil) -> [RiskResult] {
        var results: [RiskResult] = []
        for rule in rules {
            if let result = rule.evaluate(snapshot: snapshot, profile: profile) {
                results.append(result)
            }
        }
        results.sort { $0.level > $1.level }
        lastResults = results
        return results
    }

    /// The highest risk level from the last evaluation.
    var highestLevel: RiskResult.Level {
        lastResults.map(\.level).max() ?? .normal
    }

    /// Whether any critical (orange or red) alerts were found.
    var hasCriticalAlert: Bool {
        lastResults.contains { $0.level >= .orange }
    }

    static let defaultRules: [RiskRule] = [
        HeartRateRule(),
        SpO2Rule(),
        FallRule(),
        InactivityRule(),
    ]
}
