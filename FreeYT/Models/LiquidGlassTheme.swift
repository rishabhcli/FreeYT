import SwiftUI

enum LiquidGlassTheme {
    static let cardRadius: CGFloat = 24
    static let controlRadius: CGFloat = 18
    static let pagePadding: CGFloat = 22
    static let sectionSpacing: CGFloat = 18
    static let contentSpacing: CGFloat = 14

    static let accent = Color(red: 0.23, green: 0.74, blue: 0.55)
    static let accentStrong = Color(red: 0.12, green: 0.52, blue: 0.37)
    static let warning = Color(red: 0.95, green: 0.72, blue: 0.29)
    static let info = Color(red: 0.37, green: 0.62, blue: 0.95)

    static let strokeStrong = Color.white.opacity(0.22)
    static let strokeSoft = Color.white.opacity(0.08)
    static let sidebarTint = Color.white.opacity(0.08)
    static let glassHighlight = Color.white.opacity(0.16)

    static var success: Color { accent }

    static var adaptiveText: Color {
        Color.primary
    }

    static var adaptiveSecondaryText: Color {
        Color.secondary
    }

    static var adaptiveMutedText: Color {
        Color.secondary.opacity(0.72)
    }

    static var glassFill: LinearGradient {
        LinearGradient(
            colors: [
                Color.white.opacity(0.72),
                Color.white.opacity(0.38)
            ],
            startPoint: .topLeading,
            endPoint: .bottomTrailing
        )
    }

    static var darkGlassFill: LinearGradient {
        LinearGradient(
            colors: [
                Color.white.opacity(0.14),
                Color.white.opacity(0.05)
            ],
            startPoint: .topLeading,
            endPoint: .bottomTrailing
        )
    }

    static var heroGradient: LinearGradient {
        LinearGradient(
            colors: [
                accent.opacity(0.18),
                Color.white.opacity(0.12),
                info.opacity(0.08)
            ],
            startPoint: .topLeading,
            endPoint: .bottomTrailing
        )
    }
}
