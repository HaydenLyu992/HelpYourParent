import Foundation

/// Errors that can occur during API communication.
enum APIError: LocalizedError {
    case invalidURL
    case noData
    case decodingFailed(Error)
    case httpError(statusCode: Int, message: String)
    case unauthorized
    case networkError(Error)
    case tokenRefreshFailed

    var errorDescription: String? {
        switch self {
        case .invalidURL:
            return String(localized: "api_error_invalid_url", defaultValue: "无效的请求地址")
        case .noData:
            return String(localized: "api_error_no_data", defaultValue: "未收到服务器响应")
        case .decodingFailed(let error):
            return String(localized: "api_error_decoding", defaultValue: "数据解析失败: \(error.localizedDescription)")
        case .httpError(let statusCode, let message):
            return String(localized: "api_error_http", defaultValue: "请求失败 (\(statusCode)): \(message)")
        case .unauthorized:
            return String(localized: "api_error_unauthorized", defaultValue: "登录已过期，请重新登录")
        case .networkError(let error):
            return String(localized: "api_error_network", defaultValue: "网络连接失败: \(error.localizedDescription)")
        case .tokenRefreshFailed:
            return String(localized: "api_error_token_refresh", defaultValue: "自动续期失败，请重新登录")
        }
    }
}

/// A generic API response wrapper used by the backend.
struct APIResponse<T: Codable>: Codable {
    let code: Int
    let message: String
    let data: T?
}

/// URLSession-based HTTP client with JWT token management and async/await support.
///
/// Usage:
/// ```swift
/// let client = APIClient(baseURL: URL(string: "https://api.example.com")!)
/// let response: UserProfile = try await client.get("/user/profile")
/// ```
@Observable
final class APIClient {
    /// The base URL for all API requests. Configurable at initialization or runtime.
    var baseURL: URL {
        didSet {
            // Recompute cached URLSession configuration if needed
        }
    }

    /// Timeout interval for requests (default: 30 seconds).
    var timeoutInterval: TimeInterval = 30

    private let decoder: JSONDecoder
    private let encoder: JSONEncoder
    private let keychainManager: KeychainManager
    private let session: URLSession

    // MARK: - Initialization

    init(
        baseURL: URL = URL(string: "http://localhost:8080")!,
        keychainManager: KeychainManager = KeychainManager()
    ) {
        self.baseURL = baseURL
        self.keychainManager = keychainManager
        self.decoder = JSONDecoder()
        self.encoder = JSONEncoder()
        let configuration = URLSessionConfiguration.default
        configuration.timeoutIntervalForRequest = 30
        configuration.timeoutIntervalForResource = 60
        self.session = URLSession(configuration: configuration)
    }

    // MARK: - Public HTTP Methods

    /// Perform a GET request.
    /// - Parameters:
    ///   - path: API endpoint path (e.g., "/user/profile").
    ///   - queryItems: Optional query parameters.
    /// - Returns: Decoded response of type `T`.
    func get<T: Codable>(_ path: String, queryItems: [URLQueryItem]? = nil) async throws -> T {
        let request = try await buildRequest(path: path, method: "GET", queryItems: queryItems)
        return try await perform(request)
    }

    /// Perform a POST request with an encodable body.
    /// - Parameters:
    ///   - path: API endpoint path.
    ///   - body: Encodable request body.
    /// - Returns: Decoded response of type `T`.
    func post<T: Codable, U: Codable>(_ path: String, body: U) async throws -> T {
        var request = try await buildRequest(path: path, method: "POST")
        request.httpBody = try encoder.encode(body)
        request.setValue("application/json", forHTTPHeaderField: "Content-Type")
        return try await perform(request)
    }

    /// Perform a PUT request with an encodable body.
    /// - Parameters:
    ///   - path: API endpoint path.
    ///   - body: Encodable request body.
    /// - Returns: Decoded response of type `T`.
    func put<T: Codable, U: Codable>(_ path: String, body: U) async throws -> T {
        var request = try await buildRequest(path: path, method: "PUT")
        request.httpBody = try encoder.encode(body)
        request.setValue("application/json", forHTTPHeaderField: "Content-Type")
        return try await perform(request)
    }

    /// Perform a DELETE request.
    /// - Parameters:
    ///   - path: API endpoint path.
    /// - Returns: Decoded response of type `T`.
    func delete<T: Codable>(_ path: String) async throws -> T {
        let request = try await buildRequest(path: path, method: "DELETE")
        return try await perform(request)
    }

    /// Perform a POST request without a body (e.g., for simple actions).
    /// - Parameter path: API endpoint path.
    /// - Returns: Decoded response of type `T`.
    func postEmpty<T: Codable>(_ path: String) async throws -> T {
        let request = try await buildRequest(path: path, method: "POST")
        return try await perform(request)
    }

    /// Send a raw multipart/form-data POST request (e.g., for image upload).
    /// - Parameters:
    ///   - path: API endpoint path.
    ///   - multipartData: The multipart form data.
    ///   - boundary: The boundary string.
    /// - Returns: Decoded response of type `T`.
    func upload<T: Codable>(_ path: String, multipartData: Data, boundary: String) async throws -> T {
        var request = try await buildRequest(path: path, method: "POST")
        request.setValue("multipart/form-data; boundary=\(boundary)", forHTTPHeaderField: "Content-Type")
        request.httpBody = multipartData
        return try await perform(request)
    }

    // MARK: - Token Management

    /// Store the JWT access token and refresh token in the Keychain.
    /// - Parameters:
    ///   - accessToken: The JWT access token string.
    ///   - refreshToken: The JWT refresh token string.
    func storeTokens(accessToken: String, refreshToken: String) {
        keychainManager.store(key: .accessToken, value: accessToken)
        keychainManager.store(key: .refreshToken, value: refreshToken)
    }

    /// Clear stored tokens (e.g., on logout).
    func clearTokens() {
        keychainManager.delete(key: .accessToken)
        keychainManager.delete(key: .refreshToken)
    }

    /// Check whether an access token currently exists in the Keychain.
    /// - Returns: `true` if an access token is stored.
    var hasAccessToken: Bool {
        keychainManager.retrieve(key: .accessToken) != nil
    }

    // MARK: - Internal Helpers

    /// Build a URLRequest, attaching the Bearer token from Keychain.
    private func buildRequest(
        path: String,
        method: String,
        queryItems: [URLQueryItem]? = nil
    ) async throws -> URLRequest {
        guard var components = URLComponents(url: baseURL.appendingPathComponent(path), resolvingAgainstBaseURL: false) else {
            throw APIError.invalidURL
        }

        if let queryItems = queryItems, !queryItems.isEmpty {
            components.queryItems = queryItems
        }

        guard let url = components.url else {
            throw APIError.invalidURL
        }

        var request = URLRequest(url: url)
        request.httpMethod = method
        request.timeoutInterval = timeoutInterval
        request.setValue("application/json", forHTTPHeaderField: "Accept")

        // Attach Bearer token if available
        if let accessToken = keychainManager.retrieve(key: .accessToken) {
            request.setValue("Bearer \(accessToken)", forHTTPHeaderField: "Authorization")
        }

        return request
    }

    /// Perform the URLRequest, decode the response, handle HTTP errors and 401 auto-refresh.
    private func perform<T: Codable>(_ request: URLRequest) async throws -> T {
        do {
            let (data, response) = try await session.data(for: request)
            return try handleResponse(data: data, response: response, for: request)
        } catch let error as APIError {
            throw error
        } catch {
            throw APIError.networkError(error)
        }
    }

    /// Validate the HTTP response, attempt token refresh on 401, then decode.
    private func handleResponse<T: Codable>(
        data: Data,
        response: URLResponse,
        for originalRequest: URLRequest
    ) async throws -> T {
        guard let httpResponse = response as? HTTPURLResponse else {
            throw APIError.noData
        }

        // Success case
        if (200...299).contains(httpResponse.statusCode) {
            return try decodeResponse(data: data)
        }

        // Unauthorized — attempt token refresh once
        if httpResponse.statusCode == 401 {
            guard let refreshed = try await attemptTokenRefresh() else {
                throw APIError.unauthorized
            }

            // Retry the original request with the new token
            var retryRequest = originalRequest
            retryRequest.setValue("Bearer \(refreshed)", forHTTPHeaderField: "Authorization")

            let (retryData, retryResponse) = try await session.data(for: retryRequest)
            guard let retryHTTP = retryResponse as? HTTPURLResponse, (200...299).contains(retryHTTP.statusCode) else {
                throw APIError.unauthorized
            }
            return try decodeResponse(data: retryData)
        }

        // Other HTTP errors
        let bodyMessage = (try? JSONDecoder().decode(APIResponse<String>.self, from: data))?.message
            ?? String(localized: "api_error_unknown", defaultValue: "未知错误")
        throw APIError.httpError(statusCode: httpResponse.statusCode, message: bodyMessage)
    }

    /// Decode the response body into `T`, unwrapping from `APIResponse` wrapper if present.
    private func decodeResponse<T: Codable>(data: Data) throws -> T {
        do {
            // Try to decode as a wrapped APIResponse first
            let wrapped = try decoder.decode(APIResponse<T>.self, from: data)
            if let data = wrapped.data {
                return data
            }
            // If data is nil but T is Void or similar, try casting
            throw APIError.noData
        } catch let error as APIError {
            throw error
        } catch {
            // If APIResponse decoding fails, try direct decoding
            do {
                return try decoder.decode(T.self, from: data)
            } catch {
                throw APIError.decodingFailed(error)
            }
        }
    }

    /// Attempt to refresh the access token using the stored refresh token.
    /// - Returns: The new access token string, or `nil` if refresh failed.
    private func attemptTokenRefresh() async throws -> String? {
        guard let refreshToken = keychainManager.retrieve(key: .refreshToken) else {
            return nil
        }

        let refreshURL = baseURL.appendingPathComponent("/api/auth/refresh")
        var request = URLRequest(url: refreshURL)
        request.httpMethod = "POST"
        request.setValue("application/json", forHTTPHeaderField: "Content-Type")
        request.timeoutInterval = timeoutInterval

        let body: [String: String] = ["refresh_token": refreshToken]
        request.httpBody = try encoder.encode(body)

        let (data, response) = try await session.data(for: request)
        guard let httpResponse = response as? HTTPURLResponse, httpResponse.statusCode == 200 else {
            // Refresh failed — clear tokens
            clearTokens()
            return nil
        }

        struct RefreshResponse: Codable {
            let accessToken: String
            let refreshToken: String?
        }

        let decoded: RefreshResponse
        do {
            // Try wrapped format first
            let wrapped = try decoder.decode(APIResponse<RefreshResponse>.self, from: data)
            guard let data = wrapped.data else {
                clearTokens()
                return nil
            }
            decoded = data
        } catch {
            // Fall back to direct decode
            do {
                decoded = try decoder.decode(RefreshResponse.self, from: data)
            } catch {
                clearTokens()
                return nil
            }
        }

        // Store new tokens
        keychainManager.store(key: .accessToken, value: decoded.accessToken)
        if let newRefresh = decoded.refreshToken {
            keychainManager.store(key: .refreshToken, value: newRefresh)
        }

        return decoded.accessToken
    }
}
