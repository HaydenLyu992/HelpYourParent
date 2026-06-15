import SwiftUI

/// Elder's view of their guardians. Replaces the `ElderGuardiansPlaceholder`.
///
/// Shows a list of all guardians bound to the elder, with options to
/// manage them. Each guardian card shows avatar, name, phone, relationship,
/// and status.
struct GuardianManagementView: View {
    @Environment(APIClient.self) private var apiClient

    @State private var guardians: [BoundUserInfo] = []
    @State private var isLoading = true
    @State private var showRemoveConfirm = false
    @State private var guardianToRemove: BoundUserInfo?

    var body: some View {
        ScrollView {
            VStack(spacing: 16) {
                // Header
                DoodleCardView(background: .doodleCoralLight) {
                    HStack(spacing: 16) {
                        Text("👨‍👩‍👧")
                            .font(.system(size: 42))
                        VStack(alignment: .leading, spacing: 4) {
                            Text(String(localized: "my_guardians", defaultValue: "我的守护者"))
                                .font(.system(size: 20, weight: .black, design: .rounded))
                                .foregroundStyle(.doodleInk)
                            Text(String(localized: "guardian_management_subtitle", defaultValue: "他们可以收到您的健康告警通知"))
                                .font(.system(size: 13, design: .rounded))
                                .foregroundStyle(.doodleInkLight)
                        }
                    }
                }

                if isLoading {
                    ProgressView()
                        .tint(.doodleCoral)
                        .padding(.vertical, 40)
                } else if guardians.isEmpty {
                    DoodleCardView(background: .doodleSunLight) {
                        VStack(spacing: 12) {
                            Text("👋")
                                .font(.system(size: 48))
                            Text(String(localized: "no_guardians_yet", defaultValue: "还没有守护者"))
                                .font(.system(size: 17, weight: .bold, design: .rounded))
                                .foregroundStyle(.doodleInk)
                            Text(String(localized: "no_guardians_hint", defaultValue: "让家人下载康护亲App，通过手机号绑定您"))
                                .font(.system(size: 13, design: .rounded))
                                .foregroundStyle(.doodleInkLight)
                        }
                        .frame(maxWidth: .infinity)
                        .padding(.vertical, 20)
                    }
                } else {
                    ForEach(guardians) { guardian in
                        GuardianCardView(guardian: guardian) {
                            guardianToRemove = guardian
                            showRemoveConfirm = true
                        }
                    }
                }

                // Invite section
                DoodleCardView(background: .doodleSkyLight) {
                    VStack(spacing: 8) {
                        Text(String(localized: "invite_guardian_hint", defaultValue: "想让家人守护您吗？"))
                            .font(.system(size: 14, design: .rounded))
                            .foregroundStyle(.doodleInk)
                        Text(String(localized: "invite_guardian_detail", defaultValue: "让家人下载康护亲App，用守护者身份注册后，搜索您的手机号即可绑定"))
                            .font(.system(size: 12, design: .rounded))
                            .foregroundStyle(.doodleInkLight)
                            .multilineTextAlignment(.center)
                    }
                    .frame(maxWidth: .infinity)
                }
            }
            .padding()
        }
        .background(Color.doodleCream)
        .navigationTitle(String(localized: "guardian_tab", defaultValue: "守护者"))
        .task { await loadGuardians() }
        .refreshable { await loadGuardians() }
        .confirmationDialog(
            String(localized: "remove_guardian_title", defaultValue: "移除守护者"),
            isPresented: $showRemoveConfirm,
            titleVisibility: .visible
        ) {
            Button(String(localized: "remove_guardian_confirm", defaultValue: "确认移除"), role: .destructive) {
                if let target = guardianToRemove {
                    removeGuardian(target)
                }
            }
            Button(String(localized: "cancel", defaultValue: "取消"), role: .cancel) {}
        } message: {
            Text(String(localized: "remove_guardian_message", defaultValue: "移除后该守护者将不再收到您的健康告警"))
        }
    }

    private func loadGuardians() async {
        isLoading = true
        defer { isLoading = false }
        do {
            guardians = try await apiClient.get(Endpoint.guardianList.path)
        } catch {}
    }

    private func removeGuardian(_ target: BoundUserInfo) {
        Task {
            do {
                let _: APIResponse<String>? = try? await apiClient.delete(
                    Endpoint.removeGuardian.path + "?guardianUserId=\(target.userId)"
                )
                guardians.removeAll { $0.userId == target.userId }
            }
        }
    }
}

// MARK: - Guardian Card

private struct GuardianCardView: View {
    let guardian: BoundUserInfo
    let onRemove: () -> Void

    var body: some View {
        HStack(spacing: 14) {
            Text("👧")
                .font(.system(size: 32))
                .frame(width: 56, height: 56)
                .background(Color.doodleSkyLight)
                .clipShape(Circle())
                .doodleBorder(.doodleInk, width: 3)

            VStack(alignment: .leading, spacing: 4) {
                Text(guardian.displayName)
                    .font(.system(size: 17, weight: .black, design: .rounded))
                    .foregroundStyle(.doodleInk)
                Text(guardian.relationshipLabel)
                    .font(.system(size: 13, design: .rounded))
                    .foregroundStyle(.doodleInkLight)
                Text(guardian.phone ?? "")
                    .font(.system(size: 12, design: .rounded))
                    .foregroundStyle(.doodleInkLighter)
            }

            Spacer()

            Button(action: onRemove) {
                Text(String(localized: "guardian_remove_btn", defaultValue: "移除"))
                    .font(.system(size: 13, weight: .bold, design: .rounded))
                    .foregroundStyle(.doodleCoralDark)
                    .padding(.horizontal, 14)
                    .padding(.vertical, 8)
                    .background(Color.doodleCoralLight)
                    .clipShape(Capsule())
                    .doodleBorder(.doodleInk, width: 2)
            }
        }
        .padding(16)
        .background(.white)
        .clipShape(RoundedRectangle(cornerRadius: 20))
        .doodleBorder(.doodleInk, width: 3)
        .shadow(color: .black.opacity(0.06), radius: 0, x: 2, y: 3)
    }
}

// MARK: - Preview

#Preview {
    NavigationStack {
        GuardianManagementView()
            .environment(APIClient())
    }
}
