import Foundation

/// Evaluates blood oxygen saturation (SpO2) against clinical thresholds.
///
/// | Level  | Range (%) |
/// |--------|-----------|
/// | Normal | ≥95       |
/// | Yellow | 90–95     |
/// | Orange | 85–90     |
/// | Red    | <85       |
struct SpO2Rule: RiskRule {
    func evaluate(snapshot: HealthSnapshot, profile: ElderProfile?) -> RiskResult? {
        guard let spo2 = snapshot.spo2 else { return nil }

        let spo2Percent = spo2 * 100

        let level: RiskResult.Level
        let advice: String

        switch spo2Percent {
        case 95...100:
            return nil
        case 90..<95:
            level = .yellow
            advice = String(localized: "risk_spo2_yellow", defaultValue: "血氧饱和度偏低，建议开窗通风、深呼吸。如有慢性呼吸系统疾病请按医嘱处理")
        case 85..<90:
            level = .orange
            advice = String(localized: "risk_spo2_orange", defaultValue: "血氧饱和度明显偏低，建议立即休息并监测。如持续不升或伴有呼吸困难请就医")
        default:
            level = .red
            advice = String(localized: "risk_spo2_red", defaultValue: "血氧饱和度严重偏低！可能危及生命，请立即拨打120或前往急诊")
        }

        return RiskResult(
            level: level,
            riskName: String(localized: "risk_spo2_name", defaultValue: "血氧异常"),
            riskType: "SPO2",
            advice: advice,
            metrics: ["spo2": spo2Percent]
        )
    }
}
