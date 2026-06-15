import SwiftUI

/// Information about a pending binding request from the backend.
struct PendingRequestInfo: Codable, Identifiable {
    let requestId: String
    let fromUserId: Int
    let fromNickname: String
    let fromPhone: String
    let relationship: String
    let message: String
    let createdAt: String

    var id: String { requestId }

    /// The display name for the requester.
    var displayName: String {
        fromNickname.isEmpty ? fromPhone : fromNickname
    }

    /// A formatted label for the requester's role/relationship.
    var relationshipLabel: String {
        relationship.isEmpty
            ? String(localized: "binding_unknown_relationship", defaultValue: "未知关系")
            : relationship
    }
}

/// Displays when the user taps a binding request push notification.
///
/// Shows the full details of the request: who is requesting, their phone number,
/// the intended relationship, and any personal message. The user can accept or
/// reject the binding request with two large doodle-style buttons.
struct BindingRequestView: View {
    @Environment(APIClient.self) private var apiClient
    @Environment(\.dismiss) private var dismiss

    let requestId: String
    let fromUserId: Int

    @State private var requestInfo: PendingRequestInfo?
    @State private var isLoading = true
    @State private var isProcessing = false
    @State private var errorMessage: String?
    @State private var showError = false
    @State private var showSuccess = false
    @State private var successMessage: String?

    var body: some View {
        NavigationStack {
            ScrollView {
                VStack(spacing: 24) {
                    if isLoading {
                        Spacer()
                        ProgressView()
                            .tint(.doodleCoral)
                            .scaleEffect(1.5)
                        Spacer()
                    } else if let request = requestInfo {
                        // MARK: - Header
                        VStack(spacing: 12) {
                            Text("💌")
                                .font(.system(size: 60))

                            Text(String(localized: "binding_request_title", defaultValue: "守护绑定请求"))
                                .font(.system(size: 24, weight: .black, design: .rounded))
                                .foregroundStyle(.doodleInk)

                            Text(String(localized: "binding_request_subtitle", defaultValue: "有人想要守护您的健康"))
                                .font(.system(size: 15, design: .rounded))
                                .foregroundStyle(.doodleInkLight)
                        }
                        .padding(.top, 20)

                        // MARK: - Requester Info Card
                        DoodleCardView {
                            VStack(spacing: 16) {
                                // Avatar
                                Text("👧")
                                    .font(.system(size: 50))
                                    .frame(width: 72, height: 72)
                                    .background(Color.doodleSkyLight)
                                    .clipShape(Circle())
                                    .doodleBorder(.doodleInk, width: 3)

                                // Name
                                Text(request.displayName)
                                    .font(.system(size: 22, weight: .black, design: .rounded))
                                    .foregroundStyle(.doodleInk)

                                // Info rows
                                VStack(spacing: 12) {
                                    InfoRowView(
                                        emoji: "📱",
                                        label: String(localized: "binding_phone_label", defaultValue: "手机号"),
                                        value: request.fromPhone
                                    )
                                    InfoRowView(
                                        emoji: "💞",
                                        label: String(localized: "binding_relationship_label", defaultValue: "关系"),
                                        value: request.relationshipLabel
                                    )
                                    InfoRowView(
                                        emoji: "📅",
                                        label: String(localized: "binding_date_label", defaultValue: "请求时间"),
                                        value: request.createdAt
                                    )
                                }
                            }
                        }

                        // MARK: - Message Card
                        if !request.message.isEmpty {
                            DoodleCardView(background: .doodleSunLight) {
                                VStack(alignment: .leading, spacing: 8) {
                                    Text("\(String(localized: "binding_message_label", defaultValue: "留言")) 💬")
                                        .font(.system(size: 15, weight: .bold, design: .rounded))
                                        .foregroundStyle(.doodleInk)

                                    Text(request.message)
                                        .font(.system(size: 15, design: .rounded))
                                        .foregroundStyle(.doodleInk)
                                        .frame(maxWidth: .infinity, alignment: .leading)
                                }
                            }
                        }

                        // MARK: - Action Buttons
                        VStack(spacing: 12) {
                            // Accept button
                            Button {
                                acceptBinding()
                            } label: {
                                HStack {
                                    if isProcessing {
                                        ProgressView()
                                            .tint(.white)
                                    }
                                    Text("✅ \(String(localized: "binding_accept", defaultValue: "同意绑定"))")
                                }
                                .font(.system(size: 18, weight: .black, design: .rounded))
                                .frame(maxWidth: .infinity)
                                .padding(.vertical, 16)
                                .background(Color.doodleCoral)
                                .foregroundStyle(.white)
                                .clipShape(Capsule())
                                .doodleBorder(.doodleInk, width: 3)
                                .shadow(color: .black.opacity(0.12), radius: 0, x: 3, y: 5)
                            }
                            .disabled(isProcessing)

                            // Reject button
                            Button {
                                rejectBinding()
                            } label: {
                                HStack {
                                    if isProcessing {
                                        ProgressView()
                                            .tint(.doodleInk)
                                    }
                                    Text("❌ \(String(localized: "binding_reject", defaultValue: "拒绝"))")
                                }
                                .font(.system(size: 16, weight: .bold, design: .rounded))
                                .frame(maxWidth: .infinity)
                                .padding(.vertical, 14)
                                .background(Color.white)
                                .foregroundStyle(.doodleInk)
                                .clipShape(Capsule())
                                .doodleBorder(.doodleInk, width: 3)
                                .shadow(color: .black.opacity(0.08), radius: 0, x: 2, y: 3)
                            }
                            .disabled(isProcessing)
                        }
                    } else {
                        // Error state
                        DoodleCardView(background: .doodleCoralLight) {
                            VStack(spacing: 12) {
                                Text("😅")
                                    .font(.system(size: 48))
                                Text(String(localized: "binding_not_found", defaultValue: "未找到请求信息"))
                                    .font(.system(size: 17, weight: .bold, design: .rounded))
                                    .foregroundStyle(.doodleInk)
                                Text(String(localized: "binding_not_found_hint", defaultValue: "该请求可能已过期或已被处理"))
                                    .font(.system(size: 13, design: .rounded))
                                    .foregroundStyle(.doodleInkLight)
                            }
                            .frame(maxWidth: .infinity)
                            .padding(.vertical, 20)
                        }
                    }
                }
                .padding()
            }
            .background(Color.doodleCream)
            .toolbar {
                ToolbarItem(placement: .cancellationAction) {
                    Button(String(localized: "close", defaultValue: "关闭")) {
                        dismiss()
                    }
                    .font(.system(size: 15, weight: .bold, design: .rounded))
                    .foregroundStyle(.doodleInk)
                }
            }
            .task {
                await fetchRequestDetails()
            }
            .alert(String(localized: "error", defaultValue: "提示"),
                   isPresented: $showError) {
                Button(String(localized: "ok", defaultValue: "确定"), role: .cancel) {
                    if showSuccess {
                        dismiss()
                    }
                }
            } message: {
                Text(errorMessage ?? "")
            }
        }
    }

    // MARK: - API Calls

    /// Fetch all pending requests and find the one matching our `requestId`.
    private func fetchRequestDetails() async {
        isLoading = true
        defer { isLoading = false }

        do {
            let requests: [PendingRequestInfo] = try await apiClient.get(Endpoint.pendingRequests.path)
            requestInfo = requests.first { $0.requestId == requestId }
        } catch {
            // If we can't fetch, the view shows the "not found" state
        }
    }

    /// Accept the binding request.
    private func acceptBinding() {
        Task {
            isProcessing = true
            defer { isProcessing = false }

            do {
                let _: APIResponse<String> = try await apiClient.postEmpty(
                    Endpoint.acceptBind(requestId).path
                )

                successMessage = String(localized: "binding_accept_success", defaultValue: "绑定成功！你们已经成为守护关系 💕")
                showSuccess = true
            } catch {
                errorMessage = error.localizedDescription
                showError = true
            }
        }
    }

    /// Reject the binding request.
    private func rejectBinding() {
        Task {
            isProcessing = true
            defer { isProcessing = false }

            do {
                let _: APIResponse<String> = try await apiClient.postEmpty(
                    Endpoint.rejectBind(requestId).path
                )

                dismiss()
            } catch {
                errorMessage = error.localizedDescription
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

/// A single info row displaying an emoji label and its value.
private struct InfoRowView: View {
    let emoji: String
    let label: String
    let value: String

    var body: some View {
        HStack(spacing: 10) {
            Text(emoji)
                .font(.system(size: 18))
            Text(label)
                .font(.system(size: 14, design: .rounded))
                .foregroundStyle(.doodleInkLight)
            Spacer()
            Text(value)
                .font(.system(size: 15, weight: .bold, design: .rounded))
                .foregroundStyle(.doodleInk)
        }
        .padding(.horizontal, 4)
    }
}

// MARK: - Preview

#Preview {
    BindingRequestView(requestId: "test-123", fromUserId: 456)
        .environment(APIClient())
}
