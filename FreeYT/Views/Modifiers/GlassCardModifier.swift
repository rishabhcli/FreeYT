import SwiftUI

struct GlassCardModifier: ViewModifier {
    let radius: CGFloat
    @Environment(\.accessibilityReduceTransparency) private var reduceTransparency

    func body(content: Content) -> some View {
        if #available(iOS 26.0, *) {
            content
                .padding(18)
                .frame(maxWidth: .infinity, alignment: .leading)
                .glassEffect(
                    reduceTransparency ? .identity : .regular,
                    in: RoundedRectangle(cornerRadius: radius, style: .continuous)
                )
        } else {
            content
                .padding(18)
                .frame(maxWidth: .infinity, alignment: .leading)
                .background(
                    RoundedRectangle(cornerRadius: radius, style: .continuous)
                        .fill(
                            LinearGradient(
                                colors: [
                                    Color.white.opacity(0.10),
                                    Color.white.opacity(0.04)
                                ],
                                startPoint: .topLeading,
                                endPoint: .bottomTrailing
                            )
                        )
                        .background(.ultraThinMaterial)
                        .overlay(
                            RoundedRectangle(cornerRadius: radius, style: .continuous)
                                .strokeBorder(
                                    LinearGradient(
                                        colors: [
                                            LiquidGlassTheme.strokeStrong,
                                            LiquidGlassTheme.strokeSoft
                                        ],
                                        startPoint: .topLeading,
                                        endPoint: .bottomTrailing
                                    ),
                                    lineWidth: 1.2
                                )
                        )
                )
                .shadow(color: Color.black.opacity(0.28), radius: 22, x: 0, y: 12)
        }
    }
}

extension View {
    func glassCard(radius: CGFloat = LiquidGlassTheme.cardRadius) -> some View {
        modifier(GlassCardModifier(radius: radius))
    }
}
