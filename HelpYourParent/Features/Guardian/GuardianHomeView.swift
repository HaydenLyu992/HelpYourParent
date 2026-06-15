import SwiftUI

/// A summary of an elder that the guardian is watching over.
struct ElderSummary: Codable, Identifiable {
    let userId: Int
    let nickname: String
    let avatarUrl: String?
    let latestAlertLevel: String?
    let latestHealthStatus: String?
    let lastUpdated: String?

    var id: Int { userId }

    /// The emoji avatar to display based on the user's data.
    var avatarEmoji: String {
        "👴"
    }

    /// Whether there is an active alert for this elder.
    var hasAlert: Bool {
        guard let level = latestAlertLevel else { return false }
        return level == "orange" || level == "red"
    }

    /// The badge text describing the current alert status.
    var statusBadgeText: String {
        if let level = latestAlertLevel {
            switch level {
            case "red":
                return String(localized: "elder_status_red", defaultValue: "⚠️ 需关注")
            case "orange":
                return String(localized: "elder_status_orange", defaultValue: "⚠️ 注意")
            case "yellow":
                return String(localized: "elder_status_yellow", defaultValue: "⚡ 轻微异常")
            default:
                return String(localized: "elder_status_ok", defaultValue: "✅ 正常")
            }
        }
        return String(localized: "elder_status_ok", defaultValue: "✅ 正常")
    }

    /// The badge background color based on alert level.
    var statusBadgeColor: Color {
        if let level = latestAlertLevel {
            switch level {
            case "red":
                return .doodleBadgeDanger
            case "orange":
                return .doodleBadgeWarn
            case "yellow":
                return .doodleBadgeOK
            default:
                return .doodleBadgeOK
            }
        }
        return .doodleBadgeOK
    }
}

/// A recent alert record for display in the guardian's home view.
struct GuardianAlertItem: Codable, Identifiable {
    let id: Int
    let elderUserName: String?
    let alertLevel: String
    let riskType: String
    let alertDescription: String
    let createdAt: String
}

/// The guardian's main dashboard showing all watched elders and recent alerts.
///
/// Displays:
/// - Time-appropriate greeting with guardian role label.
/// - A scrollable list of elder cards, each showing avatar, name, and status badge.
/// - A "add elder" button.
/// - A list of recent alerts across all watched elders.
struct GuardianHomeView: View {
    @Environment(APIClient.self) private var apiClient

    @State private var elders: [ElderSummary] = []
    @State private var recentAlerts: [GuardianAlertItem] = []
    @State private var isLoading = true
    @State private var errorMessage: String?
    @State private var showError = false
    @State private var showAddGuardian = false
    @State private var elderPhone = ""
    @State private var relationship = ""

    var body: some View {
        ScrollView {
            VStack(spacing: 16) {
                // MARK: - Greeting Card
                DoodleCardView {
                    HStack {
                        VStack(alignment: .leading, spacing: 4) {
                            Text("\(greetingText) \(greetingEmoji)")
                                .font(.system(size: 26, weight: .black, design: .rounded))
                                .foregroundStyle(.doodleInk)
                            Text(String(localized: "guardian_subtitle", defaultValue: "守护中的老人"))
                                .font(.system(size: 15, design: .rounded))
                                .foregroundStyle(.doodleInkLight)
                        }
                        Spacer()
                        Text("👧")
                            .font(.system(size: 40))
                            .frame(width: 56, height: 56)
                            .background(Color.doodleSkyLight)
                            .clipShape(Circle())
                            .doodleBorder(.doodleInk, width: 3)
                    }
                }

                // MARK: - Elder Cards Section
                if isLoading {
                    ProgressView()
                        .tint(.doodleCoral)
                        .padding(.vertical, 40)
                } else if elders.isEmpty {
                    DoodleCardView(background: .doodleSunLight) {
                        VStack(spacing: 12) {
                            Text("👵")
                                .font(.system(size: 48))
                            Text(String(localized: "guardian_no_elders", defaultValue: "还没有守护的老人"))
                                .font(.system(size: 17, weight: .bold, design: .rounded))
                                .foregroundStyle(.doodleInk)
                            Text(String(localized: "guardian_no_elders_hint", defaultValue: "点击下方按钮，添加您关心的老人"))
                                .font(.system(size: 13, design: .rounded))
                                .foregroundStyle(.doodleInkLight)
                        }
                        .frame(maxWidth: .infinity)
                        .padding(.vertical, 20)
                    }
                } else {
                    // Horizontal scroll of elder cards
                    ScrollView(.horizontal, showsIndicators: false) {
                        HStack(spacing: 12) {
                            ForEach(elders) { elder in
                                ElderStatusCardView(elder: elder)
                            }

                            // Add elder button
                            Button {
                                showAddGuardian = true
                            } label: {
                                VStack(spacing: 8) {
                                    Text("➕")
                                        .font(.system(size: 32))
                                    Text(String(localized: "guardian_add_elder", defaultValue: "添加守护"))
                                        .font(.system(size: 13, weight: .bold, design: .rounded))
                                        .foregroundStyle(.doodleInk)
                                }
                                .frame(width: 140, height: 160)
                                .background(Color.white.opacity(0.6))
                                .clipShape(RoundedRectangle(cornerRadius: 22))
                                .doodleBorder(.doodleInk, width: 3, cornerRadius: 22)
                                .overlay(
                                    RoundedRectangle(cornerRadius: 22)
                                        .stroke(style: StrokeStyle(lineWidth: 3, dash: [8, 4]))
                                        .foregroundStyle(.doodleInk)
                                )
                            }
                        }
                        .padding(.horizontal, 2)
                    }
                }

                // MARK: - Recent Alerts Section
                if !recentAlerts.isEmpty {
                    VStack(alignment: .leading, spacing: 8) {
                        Text("\(String(localized: "guardian_recent_alerts", defaultValue: "最近告警"))")
                            .font(.system(size: 17, weight: .black, design: .rounded))
                            .foregroundStyle(.doodleInk)
                            .padding(.horizontal, 4)

                        ForEach(recentAlerts.prefix(5)) { alert in
                            AlertRowView(alert: alert)
                        }
                    }
                }

                // MARK: - Full Add Guardian Section
                if showAddGuardian {
                    DoodleCardView(background: .doodleSunLight) {
                        VStack(spacing: 12) {
                            Text(String(localized: "guardian_bind_title", defaultValue: "添加守护的老人"))
                                .font(.system(size: 17, weight: .bold, design: .rounded))
                                .foregroundStyle(.doodleInk)

                            // Phone input
                            HStack(spacing: 10) {
                                Text("📱")
                                    .font(.system(size: 18))
                                TextField(
                                    String(localized: "guardian_elder_phone_placeholder", defaultValue: "输入老人手机号"),
                                    text: $elderPhone
                                )
                                .keyboardType(.numberPad)
                                .font(.system(size: 16, design: .rounded))
                                .onChange(of: elderPhone) { _, newValue in
                                    elderPhone = String(newValue.filter(\.isNumber).prefix(11))
                                }
                            }
                            .padding(12)
                            .background(Color.white)
                            .clipShape(RoundedRectangle(cornerRadius: 14))
                            .doodleBorder(.doodleInk, width: 2)

                            // Relationship input
                            HStack(spacing: 10) {
                                Text("💞")
                                    .font(.system(size: 18))
                                TextField(
                                    String(localized: "guardian_relationship_placeholder", defaultValue: "关系（如：爸爸、妈妈）"),
                                    text: $relationship
                                )
                                .font(.system(size: 16, design: .rounded))
                            }
                            .padding(12)
                            .background(Color.white)
                            .clipShape(RoundedRectangle(cornerRadius: 14))
                            .doodleBorder(.doodleInk, width: 2)

                            // Message input
                            HStack(spacing: 10) {
                                Text("💬")
                                    .font(.system(size: 18))
                                TextField(
                                    String(localized: "guardian_message_placeholder", defaultValue: "留言（可选）"),
                                    text: .constant("")
                                )
                                .font(.system(size: 16, design: .rounded))
                            }
                            .padding(12)
                            .background(Color.white)
                            .clipShape(RoundedRectangle(cornerRadius: 14))
                            .doodleBorder(.doodleInk, width: 2)

                            // Send request button
                            Button {
                                sendBindingRequest()
                            } label: {
                                Text("💌 \(String(localized: "guardian_send_request", defaultValue: "发送绑定请求"))")
                                    .font(.system(size: 16, weight: .black, design: .rounded))
                                    .frame(maxWidth: .infinity)
                                    .padding(.vertical, 14)
                                    .background(Color.doodleCoral)
                                    .foregroundStyle(.white)
                                    .clipShape(Capsule())
                                    .doodleBorder(.doodleInk, width: 3)
                            }
                            .disabled(elderPhone.count != 11 || relationship.isEmpty)

                            // Cancel button
                            Button {
                                showAddGuardian = false
                                elderPhone = ""
                                relationship = ""
                            } label: {
                                Text(String(localized: "cancel", defaultValue: "取消"))
                                    .font(.system(size: 14, weight: .bold, design: .rounded))
                                    .foregroundStyle(.doodleInkLight)
                            }
                        }
                    }
                }

                // MARK: - Add Guardian FAB (when form is hidden)
                if !showAddGuardian {
                    Button {
                        showAddGuardian = true
                    } label: {
                        HStack {
                            Text("➕")
                            Text(String(localized: "guardian_add_elder_btn", defaultValue: "添加守护老人"))
                        }
                        .font(.system(size: 16, weight: .black, design: .rounded))
                        .frame(maxWidth: .infinity)
                        .padding(.vertical, 16)
                        .background(Color.doodleCoral)
                        .foregroundStyle(.white)
                        .clipShape(Capsule())
                        .doodleBorder(.doodleInk, width: 3)
                        .shadow(color: .black.opacity(0.12), radius: 0, x: 3, y: 5)
                    }
                }
            }
            .padding()
        }
        .background(Color.doodleCream)
        .task {
            await loadData()
        }
        .alert(String(localized: "error", defaultValue: "提示"),
               isPresented: $showError) {
            Button(String(localized: "ok", defaultValue: "确定"), role: .cancel) {}
        } message: {
            Text(errorMessage ?? "")
        }
    }

    // MARK: - Helpers

    private var greetingText: String {
        let hour = Calendar.current.component(.hour, from: Date())
        switch hour {
        case 6..<12:
            return String(localized: "morning_greeting", defaultValue: "早上好")
        case 12..<18:
            return String(localized: "afternoon_greeting", defaultValue: "下午好")
        default:
            return String(localized: "evening_greeting", defaultValue: "晚上好")
        }
    }

    private var greetingEmoji: String {
        let hour = Calendar.current.component(.hour, from: Date())
        switch hour {
        case 6..<12:  return "☀️"
        case 12..<18: return "🌤️"
        default:       return "🌙"
        }
    }

    /// Load elders list and recent alerts from the backend.
    private func loadData() async {
        isLoading = true
        defer { isLoading = false }

        do {
            async let fetchedElders: [ElderSummary] = try apiClient.get(Endpoint.guardianElders.path)
            async let fetchedAlerts: [GuardianAlertItem] = try apiClient.get(Endpoint.alertList.path)

            elders = try await fetchedElders
            recentAlerts = try await fetchedAlerts
        } catch {
            errorMessage = error.localizedDescription
            showError = true
        }
    }

    /// Send a binding request to an elder's phone number.
    private func sendBindingRequest() {
        Task {
            do {
                struct BindingRequest: Codable {
                    let elderPhone: String
                    let relationship: String
                    let message: String
                }

                let _: APIResponse<String>? = try? await apiClient.post(
                    Endpoint.requestBind.path,
                    body: BindingRequest(
                        elderPhone: elderPhone,
                        relationship: relationship,
                        message: String(localized: "guardian_default_message", defaultValue: "我想守护您的健康！")
                    )
                )

                // Reset form
                showAddGuardian = false
                elderPhone = ""
                relationship = ""

                // Show success feedback
                errorMessage = String(localized: "guardian_request_sent", defaultValue: "绑定请求已发送，请等待对方确认")
                showError = true
            }
        }
    }
}

// MARK: - Reusable Sub-Views

private struct DoodleCardView<Content: View>: View {
    let background: Color
    let content: Content

    init(background: Color = .white, @ViewBuilder content: () -> Content) {
        self.background = background
        self.content = content()
    }

    var body: some View {
        content
            .padding(20)
            .background(background)
            .clipShape(RoundedRectangle(cornerRadius: 22))
            .doodleBorder(.doodleInk, width: 3)
            .shadow(color: .black.opacity(0.1), radius: 0, x: 3, y: 5)
    }
}

/// A card displaying an elder's summary in the guardian's view.
private struct ElderStatusCardView: View {
    let elder: ElderSummary

    var body: some View {
        VStack(spacing: 8) {
            Text(elder.avatarEmoji)
                .font(.system(size: 40))
                .frame(width: 64, height: 64)
                .background(Color.doodleCoralLight)
                .clipShape(Circle())
                .doodleBorder(.doodleInk, width: 3)

            Text(elder.nickname)
                .font(.system(size: 16, weight: .black, design: .rounded))
                .foregroundStyle(.doodleInk)

            Text(elder.statusBadgeText)
                .font(.system(size: 12, weight: .black, design: .rounded))
                .foregroundStyle(elder.hasAlert ? .white : .doodleInk)
                .padding(.horizontal, 12)
                .padding(.vertical, 5)
                .background(elder.statusBadgeColor)
                .clipShape(Capsule())
                .doodleBorder(.doodleInk, width: 2)

            if let status = elder.latestHealthStatus, !status.isEmpty {
                Text(status)
                    .font(.system(size: 11, design: .rounded))
                    .foregroundStyle(.doodleInkLight)
                    .lineLimit(2)
                    .multilineTextAlignment(.center)
            }

            Text("▶️")
                .font(.system(size: 16))
                .foregroundStyle(.doodleCoral)
        }
        .frame(width: 140, height: 180)
        .padding(12)
        .background(.white)
        .clipShape(RoundedRectangle(cornerRadius: 22))
        .doodleBorder(.doodleInk, width: 3)
        .shadow(color: .black.opacity(0.08), radius: 0, x: 2, y: 3)
    }
}

/// A single row displaying a recent alert in the guardian's view.
private struct AlertRowView: View {
    let alert: GuardianAlertItem

    var body: some View {
        HStack(spacing: 12) {
            // Alert level icon
            ZStack {
                Circle()
                    .fill(alertLevelColor)
                    .frame(width: 40, height: 40)
                    .doodleBorder(.doodleInk, width: 2)
                Text(alertLevelEmoji)
                    .font(.system(size: 20))
            }

            VStack(alignment: .leading, spacing: 2) {
                if let name = alert.elderUserName {
                    Text(name)
                        .font(.system(size: 14, weight: .bold, design: .rounded))
                        .foregroundStyle(.doodleInk)
                }
                Text(alert.alertDescription)
                    .font(.system(size: 13, design: .rounded))
                    .foregroundStyle(.doodleInkLight)
                    .lineLimit(1)
                Text(alert.createdAt)
                    .font(.system(size: 11, design: .rounded))
                    .foregroundStyle(.doodleInkLighter)
            }

            Spacer()

            Text("➡️")
                .font(.system(size: 14))
                .foregroundStyle(.doodleInkLighter)
        }
        .padding(14)
        .background(.white)
        .clipShape(RoundedRectangle(cornerRadius: 16))
        .doodleBorder(.doodleInk, width: 2)
        .shadow(color: .black.opacity(0.06), radius: 0, x: 2, y: 2)
    }

    private var alertLevelColor: Color {
        switch alert.alertLevel {
        case "red":     return .doodleBadgeDanger
        case "orange":  return .doodleBadgeWarn
        case "yellow":  return .doodleBadgeOK
        default:        return .doodleBadgeOK
        }
    }

    private var alertLevelEmoji: String {
        switch alert.alertLevel {
        case "red":     return "🔴"
        case "orange":  return "🟠"
        case "yellow":  return "🟡"
        default:        return "🟢"
        }
    }
}

// MARK: - Preview

#Preview {
    NavigationStack {
        GuardianHomeView()
            .environment(APIClient())
    }
}
