import SwiftUI

/// Displays the alert history for a guardian, with filtering by severity level.
///
/// Features:
/// - Filter tabs for all / yellow / orange / red alerts.
/// - Each alert row shows the level emoji, elder name, description, and time.
/// - Pull-to-refresh support.
struct AlertHistoryView: View {
    @Environment(APIClient.self) private var apiClient

    @State private var alerts: [AlertHistoryItem] = []
    @State private var selectedLevel: String? = nil
    @State private var isLoading = true
    @State private var errorMessage: String?

    var body: some View {
        VStack(spacing: 0) {
            // Filter tabs
            ScrollView(.horizontal, showsIndicators: false) {
                HStack(spacing: 8) {
                    FilterChipView(label: String(localized: "alert_filter_all", defaultValue: "全部"),
                                   isSelected: selectedLevel == nil) {
                        selectedLevel = nil
                    }
                    ForEach(["YELLOW", "ORANGE", "RED"], id: \.self) { level in
                        FilterChipView(label: alertLevelLabel(level),
                                       isSelected: selectedLevel == level) {
                            selectedLevel = selectedLevel == level ? nil : level
                        }
                    }
                }
                .padding(.horizontal)
                .padding(.vertical, 8)
            }
            .background(Color.doodleCream)

            // Alert list
            if isLoading {
                Spacer()
                ProgressView()
                    .tint(.doodleCoral)
                Spacer()
            } else if filteredAlerts.isEmpty {
                Spacer()
                VStack(spacing: 12) {
                    Text("🔔")
                        .font(.system(size: 48))
                    Text(String(localized: "alert_history_empty", defaultValue: "暂无告警记录"))
                        .font(.system(size: 17, weight: .bold, design: .rounded))
                        .foregroundStyle(.doodleInk)
                    Text(String(localized: "alert_history_empty_hint", defaultValue: "告警记录会在这里展示"))
                        .font(.system(size: 13, design: .rounded))
                        .foregroundStyle(.doodleInkLight)
                }
                Spacer()
            } else {
                ScrollView {
                    LazyVStack(spacing: 10) {
                        ForEach(filteredAlerts) { alert in
                            AlertHistoryRowView(alert: alert)
                        }
                    }
                    .padding()
                }
            }
        }
        .background(Color.doodleCream)
        .navigationTitle(String(localized: "guardian_alerts_title", defaultValue: "告警记录"))
        .task { await loadAlerts() }
        .refreshable { await loadAlerts() }
    }

    private var filteredAlerts: [AlertHistoryItem] {
        guard let level = selectedLevel else { return alerts }
        return alerts.filter { $0.alertLevel == level }
    }

    private func alertLevelLabel(_ level: String) -> String {
        switch level {
        case "YELLOW": return String(localized: "alert_level_yellow_short", defaultValue: "🟡 轻微")
        case "ORANGE": return String(localized: "alert_level_orange_short", defaultValue: "🟠 注意")
        case "RED": return String(localized: "alert_level_red_short", defaultValue: "🔴 紧急")
        default: return level
        }
    }

    private func loadAlerts() async {
        isLoading = true
        defer { isLoading = false }

        do {
            alerts = try await apiClient.get(
                Endpoint.alertList.path,
                queryItems: [URLQueryItem(name: "size", value: "50")]
            )
        } catch {
            errorMessage = error.localizedDescription
        }
    }
}

// MARK: - Supporting Types

struct AlertHistoryItem: Codable, Identifiable {
    let alertId: Int
    let alertLevel: String
    let riskType: String
    let summary: String
    let aiAdvice: String?
    let createdAt: String
    var isMerged: Bool?

    var id: Int { alertId }

    var levelEmoji: String {
        switch alertLevel {
        case "RED": return "🔴"
        case "ORANGE": return "🟠"
        default: return "🟡"
        }
    }

    var levelColor: Color {
        switch alertLevel {
        case "RED": return .doodleBadgeDanger
        case "ORANGE": return .doodleBadgeWarn
        default: return .doodleBadgeOK
        }
    }

    var riskTypeLabel: String {
        switch riskType {
        case "HEART_RATE": return String(localized: "risk_type_hr", defaultValue: "心率")
        case "SPO2": return String(localized: "risk_type_spo2", defaultValue: "血氧")
        case "FALL": return String(localized: "risk_type_fall", defaultValue: "跌倒")
        case "INACTIVITY": return String(localized: "risk_type_inactive", defaultValue: "久坐")
        case "SLEEP": return String(localized: "risk_type_sleep", defaultValue: "睡眠")
        default: return riskType
        }
    }
}

// MARK: - Sub-Views

private struct FilterChipView: View {
    let label: String
    let isSelected: Bool
    let action: () -> Void

    var body: some View {
        Button(action: action) {
            Text(label)
                .font(.system(size: 13, weight: .black, design: .rounded))
                .foregroundStyle(isSelected ? .white : .doodleInk)
                .padding(.horizontal, 14)
                .padding(.vertical, 8)
                .background(isSelected ? Color.doodleCoral : Color.white)
                .clipShape(Capsule())
                .doodleBorder(.doodleInk, width: isSelected ? 3 : 2)
        }
    }
}

private struct AlertHistoryRowView: View {
    let alert: AlertHistoryItem

    var body: some View {
        VStack(alignment: .leading, spacing: 8) {
            HStack(spacing: 10) {
                ZStack {
                    Circle()
                        .fill(alert.levelColor)
                        .frame(width: 40, height: 40)
                        .doodleBorder(.doodleInk, width: 2)
                    Text(alert.levelEmoji)
                        .font(.system(size: 20))
                }

                VStack(alignment: .leading, spacing: 2) {
                    HStack {
                        Text(alert.riskTypeLabel)
                            .font(.system(size: 15, weight: .black, design: .rounded))
                            .foregroundStyle(.doodleInk)
                        if alert.isMerged == true {
                            Text(String(localized: "alert_merged_badge", defaultValue: "已合并"))
                                .font(.system(size: 10, weight: .bold, design: .rounded))
                                .foregroundStyle(.doodleInkLight)
                                .padding(.horizontal, 6)
                                .padding(.vertical, 2)
                                .background(Color.doodleInkLighter.opacity(0.3))
                                .clipShape(Capsule())
                        }
                    }
                    Text(alert.createdAt)
                        .font(.system(size: 11, design: .rounded))
                        .foregroundStyle(.doodleInkLighter)
                }

                Spacer()

                Text("➡️")
                    .font(.system(size: 14))
                    .foregroundStyle(.doodleInkLighter)
            }

            Text(alert.summary)
                .font(.system(size: 13, design: .rounded))
                .foregroundStyle(.doodleInkLight)

            if let advice = alert.aiAdvice, !advice.isEmpty {
                Text(advice)
                    .font(.system(size: 12, design: .rounded))
                    .foregroundStyle(.doodleSky)
                    .padding(10)
                    .background(Color.doodleSkyLight)
                    .clipShape(RoundedRectangle(cornerRadius: 12))
                    .doodleBorder(.doodleInk, width: 1)
            }
        }
        .padding(14)
        .background(.white)
        .clipShape(RoundedRectangle(cornerRadius: 18))
        .doodleBorder(.doodleInk, width: 3)
        .shadow(color: .black.opacity(0.06), radius: 0, x: 2, y: 2)
    }
}

// MARK: - Preview

#Preview {
    NavigationStack {
        AlertHistoryView()
            .environment(APIClient())
    }
}
