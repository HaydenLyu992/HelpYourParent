import SwiftUI

// MARK: - Doodle Border Modifier

/// Applies a thick, hand-drawn-style border around a view,
/// mimicking the marker-pen look from the 康护亲 design system.
struct DoodleBorderModifier: ViewModifier {
    let color: Color
    let width: CGFloat

    func body(content: Content) -> some View {
        content
            .overlay(
                RoundedRectangle(cornerRadius: 22)
                    .stroke(color, lineWidth: width)
            )
    }
}

struct DoodleBorderRectModifier: ViewModifier {
    let color: Color
    let width: CGFloat
    let cornerRadius: CGFloat

    func body(content: Content) -> some View {
        content
            .overlay(
                RoundedRectangle(cornerRadius: cornerRadius)
                    .stroke(color, lineWidth: width)
            )
    }
}

extension View {
    /// Apply the standard doodle border (thick ink stroke) around any view.
    /// - Parameters:
    ///   - color: The border color. Defaults to `.doodleInk`.
    ///   - width: The border width in points. Defaults to 3.
    /// - Returns: A view with the doodle border overlay.
    func doodleBorder(_ color: Color = .doodleInk, width: CGFloat = 3) -> some View {
        modifier(DoodleBorderModifier(color: color, width: width))
    }

    /// Apply a doodle border with a custom corner radius.
    /// - Parameters:
    ///   - color: The border color. Defaults to `.doodleInk`.
    ///   - width: The border width in points. Defaults to 3.
    ///   - cornerRadius: The corner radius for the border.
    /// - Returns: A view with the doodle border overlay.
    func doodleBorder(_ color: Color = .doodleInk, width: CGFloat = 3, cornerRadius: CGFloat) -> some View {
        modifier(DoodleBorderRectModifier(color: color, width: width, cornerRadius: cornerRadius))
    }
}

// MARK: - Doodle Card Modifier

/// A card-style container with the doodle aesthetic: white background,
/// thick ink border, rounded corners, and a subtle shadow.
struct DoodleCardModifier: ViewModifier {
    let background: Color
    let borderColor: Color

    func body(content: Content) -> some View {
        content
            .padding(20)
            .background(background)
            .clipShape(RoundedRectangle(cornerRadius: 22))
            .overlay(
                RoundedRectangle(cornerRadius: 22)
                    .stroke(borderColor, lineWidth: 3)
            )
            .shadow(
                color: .black.opacity(0.10),
                radius: 0,
                x: 3,
                y: 5
            )
    }
}

extension View {
    /// Wrap the view in a doodle-style card: rounded rect with thick border,
    /// white background, and doodle shadow.
    /// - Parameters:
    ///   - background: The card background color. Defaults to `.white`.
    ///   - borderColor: The card border color. Defaults to `.doodleInk`.
    /// - Returns: A view modifier that applies the card style.
    func doodleCard(
        background: Color = .white,
        borderColor: Color = .doodleInk
    ) -> some View {
        modifier(DoodleCardModifier(background: background, borderColor: borderColor))
    }
}

// MARK: - Doodle Button Modifier

/// A primary action button styled in the doodle aesthetic:
/// coral background, thick ink border, rounded pill shape, and shadow.
struct DoodleButtonModifier: ViewModifier {
    let background: Color
    let textColor: Color

    func body(content: Content) -> some View {
        content
            .font(.system(size: 18, weight: .black, design: .rounded))
            .foregroundStyle(textColor)
            .frame(maxWidth: .infinity)
            .padding(.vertical, 16)
            .padding(.horizontal, 32)
            .background(background)
            .clipShape(Capsule())
            .overlay(
                Capsule()
                    .stroke(Color.doodleInk, lineWidth: 3)
            )
            .shadow(
                color: .black.opacity(0.15),
                radius: 0,
                x: 3,
                y: 5
            )
    }
}

extension View {
    /// Style a button as a doodle primary button (coral, pill-shaped, thick border).
    /// - Parameters:
    ///   - background: The button fill color. Defaults to `.doodleCoral`.
    ///   - textColor: The button text color. Defaults to `.white`.
    /// - Returns: A view modifier for the doodle button style.
    func doodleButton(
        background: Color = .doodleCoral,
        textColor: Color = .white
    ) -> some View {
        modifier(DoodleButtonModifier(background: background, textColor: textColor))
    }
}

// MARK: - Doodle Badge Modifier

/// A small inline badge with the doodle aesthetic: capsule shape,
/// thick border, bold text, and emoji support.
struct DoodleBadgeModifier: ViewModifier {
    let background: Color
    let textColor: Color

    func body(content: Content) -> some View {
        content
            .font(.system(size: 13, weight: .black, design: .rounded))
            .foregroundStyle(textColor)
            .padding(.horizontal, 14)
            .padding(.vertical, 6)
            .background(background)
            .clipShape(Capsule())
            .overlay(
                Capsule()
                    .stroke(Color.doodleInk, lineWidth: 2)
            )
    }
}

extension View {
    /// Style a view as a doodle badge (capsule, thick border, compact).
    /// - Parameters:
    ///   - background: The badge fill color. Defaults to `.doodleBadgeOK` (yellow).
    ///   - textColor: The badge text color. Defaults to `.doodleInk`.
    /// - Returns: A view modifier for the doodle badge style.
    func doodleBadge(
        background: Color = .doodleBadgeOK,
        textColor: Color = .doodleInk
    ) -> some View {
        modifier(DoodleBadgeModifier(background: background, textColor: textColor))
    }
}
