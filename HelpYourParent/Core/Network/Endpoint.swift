import Foundation

/// Centralized API endpoint constants for the HelpYourParent backend.
///
/// Each endpoint maps to a specific route in the Spring Cloud gateway.
/// Usage:
/// ```swift
/// let url = Endpoint.login.path           // "/api/auth/login"
/// let url = Endpoint.sendCode.fullURL     // "http://localhost:8080/api/auth/code"
/// ```
enum Endpoint {
    // MARK: - Auth

    /// POST: Send SMS verification code.
    /// Body: `{ "phone": "13800138000" }`
    case sendCode

    /// POST: Register a new user.
    /// Body: `{ "phone": "...", "code": "...", "password": "...", "role": "elder|guardian" }`
    case register

    /// POST: Login with phone and password.
    /// Body: `{ "phone": "...", "password": "..." }`
    case login

    /// POST: Refresh JWT tokens.
    /// Body: `{ "refresh_token": "..." }`
    case refreshToken

    // MARK: - User Profile

    /// GET: Fetch current user profile.
    case profile

    /// PUT: Update user profile.
    /// Body: `{ "nickname": "...", "avatar_url": "..." }`
    case updateProfile

    // MARK: - Settings / Preferences

    /// GET: Fetch notification preferences for the current user.
    case notificationPreferences

    /// PUT: Update notification preferences.
    /// Body: `{ "push_enabled": true, "sms_enabled": false, "email_enabled": true }`
    case updateNotificationPreferences

    // MARK: - Health

    /// POST: Submit a health snapshot from the device (risk summary, no raw data).
    case healthSnapshot

    /// GET: Fetch health summary for a given elder user (guardians only).
    /// Query: `?elderId=xxx&from=yyyy-MM-dd&to=yyyy-MM-dd`
    case healthSummary

    /// GET: Fetch health trends for a time range.
    /// Query: `?type=heartRate|spo2|sleep&from=...&to=...`
    case healthTrend

    // MARK: - Alerts

    /// GET: List alert records for the current user or bound elder.
    /// Query: `?page=0&size=20&level=red`
    case alertList

    /// POST: Trigger a new health alert.
    /// Body: `{ "elder_user_id": "...", "alert_level": "yellow|orange|red", "risk_type": "heart_rate|spo2|fall|inactivity", "description": "..." }`
    case triggerAlert

    /// GET: Fetch detail of a specific alert by ID.
    /// Query: `?alertId=xxx`
    case alertDetail

    // MARK: - Guardian

    /// GET: List all guardians bound to the current elder.
    case guardianList

    /// POST: Send an invitation to a new guardian.
    /// Body: `{ "phone": "...", "relationship": "son|daughter|spouse|..." }`
    case inviteGuardian

    /// DELETE: Remove a guardian binding.
    /// Query: `?guardianUserId=xxx`
    case removeGuardian

    /// POST: Accept a guardian invitation.
    /// Body: `{ "invitation_code": "..." }`
    case acceptGuardian

    // MARK: - Guardian (Binding Requests)

    /// POST: Send a binding request from guardian to elder.
    /// Body: `{ "elderPhone": "...", "relationship": "...", "message": "..." }`
    case requestBind

    /// GET: List all pending binding requests for the current user.
    case pendingRequests

    /// POST: Accept a binding request by ID.
    case acceptBind(String)

    /// POST: Reject a binding request by ID.
    case rejectBind(String)

    /// GET: List all elders bound to the current guardian.
    case guardianElders

    // MARK: - Device

    /// POST: Register APNs device token for push notifications.
    /// Body: `{ "deviceToken": "..." }`
    case registerDevice

    // MARK: - AI

    /// POST: Send a chat message to the AI health assistant.
    /// Body: `{ "message": "...", "context": { ... } }`
    case aiChat

    /// GET: Fetch AI-generated health report for a time range.
    /// Query: `?from=...&to=...`
    case aiHealthReport

    // MARK: - Paths

    /// The full path string for this endpoint, including the `/api` prefix.
    var path: String {
        switch self {
        // Auth
        case .sendCode:
            return "/api/auth/code"
        case .register:
            return "/api/auth/register"
        case .login:
            return "/api/auth/login"
        case .refreshToken:
            return "/api/auth/refresh"

        // Profile
        case .profile:
            return "/api/user/profile"
        case .updateProfile:
            return "/api/user/profile"

        // Settings
        case .notificationPreferences:
            return "/api/user/notifications"
        case .updateNotificationPreferences:
            return "/api/user/notifications"

        // Health
        case .healthSnapshot:
            return "/api/health/snapshot"
        case .healthSummary:
            return "/api/health/summary"
        case .healthTrend:
            return "/api/health/trend"

        // Alerts
        case .alertList:
            return "/api/alert/list"
        case .triggerAlert:
            return "/api/alert/trigger"
        case .alertDetail:
            return "/api/alert/detail"

        // Guardian
        case .guardianList:
            return "/api/guardian/list"
        case .inviteGuardian:
            return "/api/guardian/invite"
        case .removeGuardian:
            return "/api/guardian/remove"
        case .acceptGuardian:
            return "/api/guardian/accept"

        // Guardian (Binding Requests)
        case .requestBind:
            return "/api/guardian/request-bind"
        case .pendingRequests:
            return "/api/guardian/pending-requests"
        case .acceptBind(let requestId):
            return "/api/guardian/accept-bind/\(requestId)"
        case .rejectBind(let requestId):
            return "/api/guardian/reject-bind/\(requestId)"
        case .guardianElders:
            return "/api/guardian/elders"

        // Device
        case .registerDevice:
            return "/api/user/register-device"

        // AI
        case .aiChat:
            return "/api/ai/chat"
        case .aiHealthReport:
            return "/api/ai/report"
        }
    }

    /// The HTTP method most commonly used with this endpoint.
    var httpMethod: String {
        switch self {
        case .sendCode, .register, .login, .refreshToken,
                .healthSnapshot, .triggerAlert, .inviteGuardian,
                .acceptGuardian, .aiChat, .requestBind,
                .acceptBind, .rejectBind, .registerDevice:
            return "POST"
        case .updateProfile, .updateNotificationPreferences:
            return "PUT"
        case .removeGuardian:
            return "DELETE"
        default:
            return "GET"
        }
    }
}
