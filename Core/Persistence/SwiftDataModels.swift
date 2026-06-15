import Foundation
import SwiftData

/// A local cache of the current user's profile information.
/// Synced from the backend after login/registration.
@Model
final class LocalUser {
    /// The unique user ID from the backend.
    @Attribute(.unique) var id: Int

    /// The user's phone number.
    var phone: String

    /// The user's role: "elder" for elderly user, "guardian" for caregiver.
    var role: String

    /// The user's display nickname.
    var nickname: String

    /// URL string for the user's avatar image.
    var avatarURL: String?

    /// Whether this is the currently logged-in user.
    var isLoggedIn: Bool

    /// The timestamp of the last sync from the backend.
    var lastSyncedAt: Date

    init(
        id: Int,
        phone: String,
        role: String,
        nickname: String,
        avatarURL: String? = nil,
        isLoggedIn: Bool = true,
        lastSyncedAt: Date = Date()
    ) {
        self.id = id
        self.phone = phone
        self.role = role
        self.nickname = nickname
        self.avatarURL = avatarURL
        self.isLoggedIn = isLoggedIn
        self.lastSyncedAt = lastSyncedAt
    }
}

/// A local cache of alert records synced from the backend.
/// Stored on-device for offline viewing and notification history.
@Model
final class LocalAlert {
    /// The unique alert ID from the backend.
    @Attribute(.unique) var id: Int

    /// The ID of the elderly user this alert belongs to.
    var elderUserID: Int

    /// The alert severity level: "yellow", "orange", or "red".
    var alertLevel: String

    /// The type of risk detected: "heart_rate", "spo2", "fall", "inactivity", etc.
    var riskType: String

    /// A human-readable description of the alert.
    var alertDescription: String

    /// AI-generated interpretation text, if available.
    var aiInterpretation: String?

    /// Whether the alert has been read by the user.
    var isRead: Bool

    /// The timestamp when the alert was created on the backend.
    var createdAt: Date

    /// The timestamp when the alert was dispatched to guardians.
    var dispatchedAt: Date?

    init(
        id: Int,
        elderUserID: Int,
        alertLevel: String,
        riskType: String,
        alertDescription: String,
        aiInterpretation: String? = nil,
        isRead: Bool = false,
        createdAt: Date,
        dispatchedAt: Date? = nil
    ) {
        self.id = id
        self.elderUserID = elderUserID
        self.alertLevel = alertLevel
        self.riskType = riskType
        self.alertDescription = alertDescription
        self.aiInterpretation = aiInterpretation
        self.isRead = isRead
        self.createdAt = createdAt
        self.dispatchedAt = dispatchedAt
    }
}
