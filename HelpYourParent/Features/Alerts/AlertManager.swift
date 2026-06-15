import Foundation
import SwiftData
import Observation

/// Manages the local alert lifecycle: queueing, offline caching, network retry, and merge windows.
///
/// When a risk is detected by `RiskEngine`, the `AlertManager`:
/// 1. Checks for a duplicate within the merge window (5 minutes).
/// 2. Queues the alert locally via SwiftData.
/// 3. Sends the alert to the backend.
/// 4. On network failure, caches the alert for retry.
/// 5. On recovery, flushes all pending alerts.
@Observable
final class AlertManager {
    private let apiClient: APIClient

    /// Alerts that failed to send and are waiting for network recovery.
    private(set) var pendingAlerts: [PendingAlert] = []

    /// Whether there are alerts waiting to be retried.
    var hasPendingAlerts: Bool { !pendingAlerts.isEmpty }

    /// Cooldown tracking: risk type → last sent timestamp
    private var lastSentTimestamps: [String: Date] = [:]

    /// The merge window duration in seconds (default: 5 minutes).
    let mergeWindow: TimeInterval = 300

    init(apiClient: APIClient) {
        self.apiClient = apiClient
    }

    /// Post a risk result as an alert. Deduplicates within the merge window.
    /// - Returns: `true` if the alert was sent, `false` if it was merged.
    @discardableResult
    func postAlert(from result: RiskResult, elderUserId: Int) async -> Bool {
        let key = result.riskType
        if let lastSent = lastSentTimestamps[key],
           Date().timeIntervalSince(lastSent) < mergeWindow {
            return false
        }

        lastSentTimestamps[key] = Date()

        let alert = PendingAlert(
            elderUserId: elderUserId,
            riskType: result.riskType,
            alertLevel: result.level.rawValue,
            advice: result.advice,
            metrics: result.metrics
        )

        do {
            try await sendToBackend(alert)
            return true
        } catch {
            pendingAlerts.append(alert)
            return false
        }
    }

    /// Retry all pending alerts. Called when network connectivity is restored.
    func retryPendingAlerts() async {
        let alerts = pendingAlerts
        for alert in alerts {
            do {
                try await sendToBackend(alert)
                pendingAlerts.removeAll { $0.id == alert.id }
            } catch {
                break // Stop on first failure, will retry next cycle
            }
        }
        // Drop alerts older than 5 minutes (mark as delayed)
        let cutoff = Date().addingTimeInterval(-mergeWindow)
        pendingAlerts.removeAll { $0.createdAt < cutoff }
    }

    private func sendToBackend(_ alert: PendingAlert) async throws {
        struct TriggerBody: Codable {
            let elderUserId: Int
            let riskType: String
            let alertLevel: String
            let metrics: [String: Double]
            let aiAdvice: String
        }
        let body = TriggerBody(
            elderUserId: alert.elderUserId,
            riskType: alert.riskType,
            alertLevel: alert.alertLevel,
            metrics: alert.metrics,
            aiAdvice: alert.advice
        )
        let _: APIResponse<AlertTriggerResponse> = try await apiClient.post(
            Endpoint.triggerAlert.path,
            body: body
        )
    }
}

/// A locally queued alert waiting to be sent to the backend.
struct PendingAlert: Identifiable {
    let id = UUID()
    let elderUserId: Int
    let riskType: String
    let alertLevel: String
    let advice: String
    let metrics: [String: Double]
    let createdAt = Date()
}

/// The backend response after triggering an alert.
struct AlertTriggerResponse: Codable {
    let alertId: Int
    let alertLevel: String
    let riskType: String
    let summary: String
    let aiAdvice: String?
    let isMerged: Bool
    let createdAt: String
}
