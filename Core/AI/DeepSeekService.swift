import Foundation

/// Service that communicates with the backend AI endpoint for chat and health reports.
///
/// The backend proxies requests to DeepSeek V4 Flash via `fn-deepseek-gateway`
/// on Alibaba Cloud Function Compute. The iOS client never holds the API key.
@Observable
final class DeepSeekService {
    private let apiClient: APIClient

    /// The conversation history for the current chat session.
    private(set) var chatHistory: [ChatMessage] = []

    init(apiClient: APIClient) {
        self.apiClient = apiClient
    }

    /// Send a message to the AI health assistant.
    /// - Parameter message: The user's natural language message.
    /// - Returns: The AI assistant's reply string.
    func sendMessage(_ message: String) async throws -> String {
        chatHistory.append(ChatMessage(role: "user", content: message))

        struct ChatRequest: Codable {
            let message: String
        }

        struct ChatResponse: Codable {
            let reply: String
        }

        let response: ChatResponse = try await apiClient.post(
            Endpoint.aiChat.path,
            body: ChatRequest(message: message)
        )

        chatHistory.append(ChatMessage(role: "assistant", content: response.reply))
        return response.reply
    }

    /// Fetch an AI-generated health report for a given date range.
    /// - Parameters:
    ///   - from: Start date string (yyyy-MM-dd).
    ///   - to: End date string (yyyy-MM-dd).
    /// - Returns: The AI-generated report text.
    func fetchHealthReport(from: String, to: String) async throws -> String {
        struct ReportResponse: Codable {
            let report: String
        }

        let response: ReportResponse = try await apiClient.get(
            Endpoint.aiHealthReport.path,
            queryItems: [
                URLQueryItem(name: "from", value: from),
                URLQueryItem(name: "to", value: to),
            ]
        )

        return response.report
    }

    /// Clear the current chat history (e.g., when starting a new conversation).
    func clearHistory() {
        chatHistory.removeAll()
    }
}

/// A single message in the AI chat conversation.
struct ChatMessage: Identifiable {
    let id = UUID()
    let role: String // "user" or "assistant"
    let content: String
    let timestamp = Date()
}
