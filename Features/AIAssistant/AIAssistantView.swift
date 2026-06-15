import SwiftUI

/// AI health assistant chat view. Replaces the `ElderAIPlaceholder`.
///
/// Features:
/// - Chat-style message bubbles (user right-aligned coral, AI left-aligned white).
/// - Suggested quick questions as tappable chips.
/// - Auto-scroll to latest message.
/// - Loading indicator while AI is thinking.
struct AIAssistantView: View {
    @Environment(APIClient.self) private var apiClient

    @State private var messages: [ChatMessage] = []
    @State private var inputText: String = ""
    @State private var isThinking = false
    @State private var errorMessage: String?

    private let quickQuestions = [
        String(localized: "ai_quick_hr", defaultValue: "我的心率正常吗？"),
        String(localized: "ai_quick_sleep", defaultValue: "如何改善睡眠质量？"),
        String(localized: "ai_quick_diet", defaultValue: "老年人饮食要注意什么？"),
        String(localized: "ai_quick_exercise", defaultValue: "适合我的运动有哪些？"),
    ]

    var body: some View {
        VStack(spacing: 0) {
            // Messages
            ScrollViewReader { proxy in
                ScrollView {
                    LazyVStack(spacing: 12) {
                        // Welcome message
                        if messages.isEmpty {
                            DoodleCardView(background: .doodleSkyLight) {
                                VStack(spacing: 12) {
                                    Text("🤖")
                                        .font(.system(size: 48))
                                    Text(String(localized: "ai_welcome", defaultValue: "您好！我是您的AI健康小助手小康 👋\n有什么可以帮您的吗？"))
                                        .font(.system(size: 16, weight: .bold, design: .rounded))
                                        .foregroundStyle(.doodleInk)
                                        .multilineTextAlignment(.center)
                                }
                                .frame(maxWidth: .infinity)
                            }
                            .padding(.horizontal)

                            // Quick questions
                            VStack(alignment: .leading, spacing: 8) {
                                Text(String(localized: "ai_quick_questions", defaultValue: "您可以试试问我："))
                                    .font(.system(size: 13, design: .rounded))
                                    .foregroundStyle(.doodleInkLight)
                                    .padding(.horizontal)

                                FlowLayout(spacing: 8) {
                                    ForEach(quickQuestions, id: \.self) { question in
                                        Button {
                                            sendMessage(question)
                                        } label: {
                                            Text(question)
                                                .font(.system(size: 13, weight: .bold, design: .rounded))
                                                .foregroundStyle(.doodleInk)
                                                .padding(.horizontal, 14)
                                                .padding(.vertical, 10)
                                                .background(.white)
                                                .clipShape(Capsule())
                                                .doodleBorder(.doodleInk, width: 2)
                                        }
                                    }
                                }
                                .padding(.horizontal)
                            }
                        }

                        ForEach(messages) { msg in
                            ChatBubbleView(message: msg)
                                .padding(.horizontal)
                                .id(msg.id)
                        }

                        if isThinking {
                            HStack {
                                Text("🤖")
                                    .font(.system(size: 24))
                                Text(String(localized: "ai_thinking", defaultValue: "正在思考..."))
                                    .font(.system(size: 14, design: .rounded))
                                    .foregroundStyle(.doodleInkLight)
                                ProgressView()
                                    .tint(.doodleCoral)
                                Spacer()
                            }
                            .padding()
                            .id("thinking")
                        }
                    }
                    .padding(.vertical)
                }
                .onChange(of: messages.count) { _, _ in
                    if let last = messages.last {
                        withAnimation { proxy.scrollTo(last.id, anchor: .bottom) }
                    }
                }
                .onChange(of: isThinking) { _, _ in
                    withAnimation { proxy.scrollTo("thinking", anchor: .bottom) }
                }
            }

            // Input bar
            HStack(spacing: 10) {
                TextField(
                    String(localized: "ai_input_placeholder", defaultValue: "输入您的问题..."),
                    text: $inputText
                )
                .font(.system(size: 16, design: .rounded))
                .padding(12)
                .background(Color.white)
                .clipShape(Capsule())
                .doodleBorder(.doodleInk, width: 2)
                .onSubmit { sendMessage(inputText) }

                Button {
                    sendMessage(inputText)
                } label: {
                    Text("📤")
                        .font(.system(size: 20))
                        .frame(width: 44, height: 44)
                        .background(Color.doodleCoral)
                        .clipShape(Circle())
                        .doodleBorder(.doodleInk, width: 3)
                }
                .disabled(inputText.trimmingCharacters(in: .whitespaces).isEmpty || isThinking)
            }
            .padding()
            .background(Color.doodleCream)
        }
        .background(Color.doodleCream)
        .navigationTitle(String(localized: "ai_tab", defaultValue: "AI助手"))
    }

    private func sendMessage(_ text: String) {
        let trimmed = text.trimmingCharacters(in: .whitespaces)
        guard !trimmed.isEmpty, !isThinking else { return }

        inputText = ""
        messages.append(ChatMessage(role: "user", content: trimmed))
        isThinking = true

        Task {
            do {
                let service = DeepSeekService(apiClient: apiClient)
                let reply = try await service.sendMessage(trimmed)
                messages.append(ChatMessage(role: "assistant", content: reply))
            } catch {
                messages.append(ChatMessage(role: "assistant",
                    content: String(localized: "ai_error_reply", defaultValue: "抱歉，我暂时无法回复，请稍后再试。")))
            }
            isThinking = false
        }
    }
}

// MARK: - Chat Bubble

private struct ChatBubbleView: View {
    let message: ChatMessage

    private var isUser: Bool { message.role == "user" }

    var body: some View {
        HStack {
            if isUser { Spacer() }

            VStack(alignment: isUser ? .trailing : .leading, spacing: 4) {
                HStack(alignment: .top, spacing: 8) {
                    if !isUser {
                        Text("🤖")
                            .font(.system(size: 22))
                    }
                    Text(message.content)
                        .font(.system(size: 16, design: .rounded))
                        .foregroundStyle(isUser ? .white : .doodleInk)
                        .padding(14)
                        .background(isUser ? Color.doodleCoral : Color.white)
                        .clipShape(RoundedRectangle(cornerRadius: 18))
                        .doodleBorder(.doodleInk, width: 2)
                }

                Text(message.timestamp, style: .time)
                    .font(.system(size: 10, design: .rounded))
                    .foregroundStyle(.doodleInkLighter)
                    .padding(.horizontal, 4)
            }

            if !isUser { Spacer() }
        }
    }
}

// MARK: - Flow Layout

/// A simple flow layout that wraps its content horizontally.
private struct FlowLayout: Layout {
    var spacing: CGFloat = 8

    func sizeThatFits(proposal: ProposedViewSize, subviews: Subviews, cache: inout ()) -> CGSize {
        let rows = buildRows(proposal.width ?? 0, subviews: subviews)
        let height = rows.reduce(0) { $0 + $1.maxHeight } + CGFloat(max(0, rows.count - 1)) * spacing
        return CGSize(width: proposal.width ?? 0, height: height)
    }

    func placeSubviews(in bounds: CGRect, proposal: ProposedViewSize, subviews: Subviews, cache: inout ()) {
        let rows = buildRows(bounds.width, subviews: subviews)
        var y = bounds.minY
        for row in rows {
            var x = bounds.minX
            for size in row.sizes {
                let centerY = y + row.maxHeight / 2
                subviews[size.index].place(at: CGPoint(x: x, y: centerY), anchor: .leading, proposal: .init(width: size.width, height: size.height))
                x += size.width + spacing
            }
            y += row.maxHeight + spacing
        }
    }

    private struct Row {
        var sizes: [(index: Int, width: CGFloat, height: CGFloat)] = []
        var maxHeight: CGFloat = 0
    }

    private func buildRows(_ maxWidth: CGFloat, subviews: Subviews) -> [Row] {
        var rows: [Row] = [Row()]
        for (i, subview) in subviews.enumerated() {
            let size = subview.sizeThatFits(.unspecified)
            let currentWidth = rows[rows.count - 1].sizes.reduce(0) { $0 + $1.width }
            let needed = currentWidth + size.width + (rows[rows.count - 1].sizes.isEmpty ? 0 : spacing)
            if needed > maxWidth, !rows[rows.count - 1].sizes.isEmpty {
                rows.append(Row())
            }
            var row = rows[rows.count - 1]
            row.sizes.append((i, size.width, size.height))
            row.maxHeight = max(row.maxHeight, size.height)
            rows[rows.count - 1] = row
        }
        return rows
    }
}

// MARK: - Doodle Card View

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
            .overlay(
                RoundedRectangle(cornerRadius: 22)
                    .stroke(Color.doodleInk, lineWidth: 3)
            )
            .shadow(color: .black.opacity(0.10), radius: 0, x: 3, y: 5)
    }
}

// MARK: - Preview

#Preview {
    NavigationStack {
        AIAssistantView()
            .environment(APIClient())
    }
}
