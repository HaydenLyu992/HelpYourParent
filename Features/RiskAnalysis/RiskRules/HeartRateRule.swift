import Foundation

/// Evaluates resting heart rate against the thresholds defined in the
/// Chinese Elderly Health Management Expert Consensus.
///
/// | Level  | Range (bpm)  |
/// |--------|--------------|
/// | Normal | 60–90        |
/// | Yellow | 50–60, 90–110|
/// | Orange | 45–50, 110–130|
/// | Red    | <45, >130    |
struct HeartRateRule: RiskRule {
    func evaluate(snapshot: HealthSnapshot, profile: ElderProfile?) -> RiskResult? {
        guard let hr = snapshot.heartRate else { return nil }

        let level: RiskResult.Level
        let advice: String

        switch hr {
        case 60...90:
            return nil // normal
        case 50..<60, 90...110:
            level = .yellow
            advice = hr > 90
                ? String(localized: "risk_hr_high_yellow", defaultValue: "心率偏快，建议静坐休息15分钟后复测")
                : String(localized: "risk_hr_low_yellow", defaultValue: "心率偏慢，请注意观察，如持续偏低建议就医")
        case 45..<50, 110...130:
            level = .orange
            advice = hr > 110
                ? String(localized: "risk_hr_high_orange", defaultValue: "心率过快，请立即休息。如有胸闷、头晕请及时就医")
                : String(localized: "risk_hr_low_orange", defaultValue: "心率过慢，如感到乏力、头晕请立即坐下，建议就医检查")
        default:
            level = .red
            advice = hr > 130
                ? String(localized: "risk_hr_high_red", defaultValue: "心率极度异常！请立即停止活动，通知家人或拨打120")
                : String(localized: "risk_hr_low_red", defaultValue: "心率极度偏低！请立即坐下或平躺，通知家人并拨打120")
        }

        return RiskResult(
            level: level,
            riskName: String(localized: "risk_hr_name", defaultValue: "心率异常"),
            riskType: "HEART_RATE",
            advice: advice,
            metrics: ["heartRate": hr]
        )
    }
}
