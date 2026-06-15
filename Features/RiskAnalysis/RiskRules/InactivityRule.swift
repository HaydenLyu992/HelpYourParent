import Foundation

/// Evaluates prolonged inactivity (sedentary time).
///
/// | Level  | Duration (hours) |
/// |--------|------------------|
/// | Normal | <4               |
/// | Yellow | 4–6              |
/// | Orange | 6–12             |
/// | Red    | >12              |
///
/// Note: Inactivity is derived from the time since the last significant
/// movement or step count change detected by HealthKit.
struct InactivityRule: RiskRule {

    /// The threshold for considering the user "inactive" based on hourly step count.
    private let minStepsPerHour: Double = 100

    func evaluate(snapshot: HealthSnapshot, profile: ElderProfile?) -> RiskResult? {
        guard let stepCount = snapshot.stepCount else { return nil }

        // Calculate inactive hours using the current hour
        let hour = Calendar.current.component(.hour, from: Date())
        let expectedSteps = Double(max(hour - 6, 0)) * minStepsPerHour
        let deficit = max(0, expectedSteps - stepCount)
        let inactiveHours = deficit / minStepsPerHour

        guard inactiveHours >= 4 else { return nil }

        let level: RiskResult.Level
        let advice: String

        switch inactiveHours {
        case 4..<6:
            level = .yellow
            advice = String(localized: "risk_inactive_yellow", defaultValue: "您已有一段时间未活动了，建议起身走动一下")
        case 6..<12:
            level = .orange
            advice = String(localized: "risk_inactive_orange", defaultValue: "长时间未检测到活动，请确认身体状况。如有不适请通知守护者")
        default:
            level = .red
            advice = String(localized: "risk_inactive_red", defaultValue: "严重长时间未活动！守护者已收到通知，请确认您的安全状况")
        }

        return RiskResult(
            level: level,
            riskName: String(localized: "risk_inactive_name", defaultValue: "长时间未活动"),
            riskType: "INACTIVITY",
            advice: advice,
            metrics: ["inactiveHours": inactiveHours, "stepCount": stepCount]
        )
    }
}
