import SwiftUI

// MARK: - ShapeStyle Forwarding

extension ShapeStyle where Self == Color {
    static var doodleCoral: Color { Color.doodleCoral }
    static var doodleCoralLight: Color { Color.doodleCoralLight }
    static var doodleCoralDark: Color { Color.doodleCoralDark }
    static var doodleSky: Color { Color.doodleSky }
    static var doodleSkyLight: Color { Color.doodleSkyLight }
    static var doodleSun: Color { Color.doodleSun }
    static var doodleSunLight: Color { Color.doodleSunLight }
    static var doodleCream: Color { Color.doodleCream }
    static var doodleWhite: Color { Color.doodleWhite }
    static var doodleInk: Color { Color.doodleInk }
    static var doodleInkLight: Color { Color.doodleInkLight }
    static var doodleInkLighter: Color { Color.doodleInkLighter }
    static var doodleBadgeOK: Color { Color.doodleBadgeOK }
    static var doodleBadgeWarn: Color { Color.doodleBadgeWarn }
    static var doodleBadgeDanger: Color { Color.doodleBadgeDanger }
    static var doodleMint: Color { Color.doodleMint }
}

/// Doodle-style color palette for the 康护亲 app.
///
/// Based on the design system defined in UIDesign.html.
/// All colors use warm, friendly tones with thick black borders and a hand-drawn feel.
///
/// Usage:
/// ```swift
/// Text("Hello").foregroundStyle(.doodleInk)
/// Rectangle().fill(.doodleCoral)
/// ```
extension Color {
    // MARK: - Primary

    /// Warm coral red — the app's primary brand color (#FF6B6B).
    static let doodleCoral = Color(red: 1.0, green: 0.4196, blue: 0.4196)

    /// Light coral tint used as card backgrounds (#FFE0E0).
    static let doodleCoralLight = Color(red: 1.0, green: 0.8784, blue: 0.8784)

    /// Darker coral for pressed states (#E05555).
    static let doodleCoralDark = Color(red: 0.8784, green: 0.3333, blue: 0.3333)

    // MARK: - Secondary

    /// Sky blue accent for secondary actions and info cards (#5BA4E6).
    static let doodleSky = Color(red: 0.3569, green: 0.6431, blue: 0.9020)

    /// Light sky blue tint for card backgrounds (#DCEFFF).
    static let doodleSkyLight = Color(red: 0.8627, green: 0.9373, blue: 1.0)

    // MARK: - Accent

    /// Warm sun yellow for highlights and badges (#FFC940).
    static let doodleSun = Color(red: 1.0, green: 0.7882, blue: 0.2510)

    /// Light warm yellow tint for card backgrounds (#FFF3D0).
    static let doodleSunLight = Color(red: 1.0, green: 0.9529, blue: 0.8157)

    // MARK: - Neutrals

    /// Creamy off-white background for the app (#FFFBF3).
    static let doodleCream = Color(red: 1.0, green: 0.9843, blue: 0.9529)

    /// Pure white for cards and surfaces (#FFFFFF).
    static let doodleWhite = Color.white

    /// Near-black ink color for text and borders (#2D2D2D).
    static let doodleInk = Color(red: 0.1765, green: 0.1765, blue: 0.1765)

    /// Medium gray for secondary text (#777777).
    static let doodleInkLight = Color(red: 0.4667, green: 0.4667, blue: 0.4667)

    /// Light gray for tertiary text and dividers (#BBBBBB).
    static let doodleInkLighter = Color(red: 0.7333, green: 0.7333, blue: 0.7333)

    // MARK: - Badge Colors

    /// Yellow background for "normal" status badges.
    static let doodleBadgeOK = Color(red: 1.0, green: 0.8510, blue: 0.2392)

    /// Orange background for "warning" status badges.
    static let doodleBadgeWarn = Color(red: 1.0, green: 0.6627, blue: 0.3020)

    /// Red background for "danger" status badges (same as coral).
    static let doodleBadgeDanger = Color.doodleCoral

    /// Mint green for step count and activity indicators.
    static let doodleMint = Color(red: 0.3569, green: 0.8235, blue: 0.6196)
}
