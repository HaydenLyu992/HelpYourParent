import Foundation
import Security

/// Keys used to identify values stored in the Keychain.
enum KeychainKey: String, CaseIterable {
    case accessToken  = "com.hyp.keychain.access_token"
    case refreshToken = "com.hyp.keychain.refresh_token"
}

/// A lightweight wrapper around the iOS Keychain for storing and retrieving
/// sensitive credentials such as JWT access tokens and refresh tokens.
///
/// All operations are synchronous for simplicity. This class is designed to be
/// used by `APIClient` for automatic token management.
final class KeychainManager {
    private let serviceName: String

    /// The access group for shared Keychain access (nil if none).
    private let accessGroup: String?

    // MARK: - Initialization

    /// Initialize the Keychain manager.
    /// - Parameters:
    ///   - serviceName: The service name used to scope Keychain entries. Defaults to the main bundle identifier.
    ///   - accessGroup: Optional shared access group for app extensions or widgets.
    init(
        serviceName: String = Bundle.main.bundleIdentifier ?? "com.hyp.helpyourparent",
        accessGroup: String? = nil
    ) {
        self.serviceName = serviceName
        self.accessGroup = accessGroup
    }

    // MARK: - Public API

    /// Store a value in the Keychain for the given key.
    /// - Parameters:
    ///   - key: The Keychain key identifier.
    ///   - value: The string value to store. Pass `nil` to delete the entry.
    func store(key: KeychainKey, value: String?) {
        guard let value = value, !value.isEmpty else {
            delete(key: key)
            return
        }

        // If an entry already exists, update it in place
        if let _ = retrieve(key: key) {
            update(key: key, value: value)
        } else {
            add(key: key, value: value)
        }
    }

    /// Retrieve a value from the Keychain for the given key.
    /// - Parameter key: The Keychain key identifier.
    /// - Returns: The stored string value, or `nil` if no entry exists.
    func retrieve(key: KeychainKey) -> String? {
        let query = buildQuery(key: key, returnData: true)

        var result: AnyObject?
        let status = SecItemCopyMatching(query as CFDictionary, &result)

        guard status == errSecSuccess, let data = result as? Data else {
            return nil
        }

        return String(data: data, encoding: .utf8)
    }

    /// Delete a value from the Keychain for the given key.
    /// - Parameter key: The Keychain key identifier.
    func delete(key: KeychainKey) {
        let query = buildQuery(key: key)
        SecItemDelete(query as CFDictionary)
    }

    /// Clear all Keychain entries managed by this service.
    func clearAll() {
        for key in KeychainKey.allCases {
            delete(key: key)
        }
    }

    // MARK: - Private Helpers

    /// Build a base Keychain query dictionary.
    private func buildQuery(key: KeychainKey, returnData: Bool = false) -> [String: Any] {
        var query: [String: Any] = [
            kSecClass as String: kSecClassGenericPassword,
            kSecAttrService as String: serviceName,
            kSecAttrAccount as String: key.rawValue,
            kSecAttrAccessible as String: kSecAttrAccessibleWhenUnlockedThisDeviceOnly,
        ]

        if let accessGroup = accessGroup {
            query[kSecAttrAccessGroup as String] = accessGroup
        }

        if returnData {
            query[kSecReturnData as String] = true
            query[kSecMatchLimit as String] = kSecMatchLimitOne
        }

        return query
    }

    /// Add a new entry to the Keychain.
    private func add(key: KeychainKey, value: String) {
        guard let data = value.data(using: .utf8) else { return }
        var query = buildQuery(key: key)
        query[kSecValueData as String] = data
        SecItemAdd(query as CFDictionary, nil)
    }

    /// Update an existing Keychain entry.
    private func update(key: KeychainKey, value: String) {
        guard let data = value.data(using: .utf8) else { return }
        let query = buildQuery(key: key)
        let attributes: [String: Any] = [kSecValueData as String: data]
        SecItemUpdate(query as CFDictionary, attributes as CFDictionary)
    }
}
