import SwiftUI

enum LiquidGlassTheme {
    static let cardRadius: CGFloat = 22
    static let controlRadius: CGFloat = 28
    static let strokeStrong = Color.white.opacity(0.35)
    static let strokeSoft = Color.white.opacity(0.08)
    static let success = Color(red: 0.23, green: 0.89, blue: 0.56)
    static let warning = Color(red: 0.95, green: 0.79, blue: 0.29)

    /// Adaptive text color for iOS 26 (respects light/dark) vs older iOS (always white)
    static var adaptiveText: Color {
        if #available(iOS 26.0, *) {
            return Color.primary
        } else {
            return .white
        }
    }

    /// Adaptive secondary text color
    static var adaptiveSecondaryText: Color {
        if #available(iOS 26.0, *) {
            return Color.secondary
        } else {
            return .white.opacity(0.7)
        }
    }
}
