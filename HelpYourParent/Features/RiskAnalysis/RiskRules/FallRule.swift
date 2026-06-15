import Foundation

/// Detects fall events from HealthKit data.
///
/// Falls are always treated as red-level alerts requiring immediate attention.
struct FallRule: RiskRule {
    func evaluate(snapshot: HealthSnapshot, profile: ElderProfile?) -> RiskResult? {
        guard snapshot.fallDetected == true else { return nil }

        return RiskResult(
            level: .red,
            riskName: String(localized: "risk_fall_name", defaultValue: "疑似跌倒"),
            riskType: "FALL",
            advice: String(localized: "risk_fall_advice", defaultValue: "检测到疑似跌倒事件！已通知您的守护者。如您能自行操作手机，请确认是否需要拨打120"),
            metrics: ["fallDetected": 1]
        )
    }
}
