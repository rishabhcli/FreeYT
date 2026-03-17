import SwiftUI

struct GlassCardModifier: ViewModifier {
    let radius: CGFloat
    let tint: Color?
    let interactive: Bool
    let padding: CGFloat
    @Environment(\.accessibilityReduceTransparency) private var reduceTransparency
    @Environment(\.colorScheme) private var colorScheme

    func body(content: Content) -> some View {
        if #available(iOS 26.0, macOS 26.0, *) {
            let glass = resolvedGlass
            content
                .padding(padding)
                .frame(maxWidth: .infinity, alignment: .leading)
                .glassEffect(
                    glass,
                    in: RoundedRectangle(cornerRadius: radius, style: .continuous)
                )
        } else {
            content
                .padding(padding)
                .frame(maxWidth: .infinity, alignment: .leading)
                .background(
                    RoundedRectangle(cornerRadius: radius, style: .continuous)
                        .fill(colorScheme == .dark ? LiquidGlassTheme.darkGlassFill : LiquidGlassTheme.glassFill)
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
                .shadow(color: Color.black.opacity(colorScheme == .dark ? 0.28 : 0.1), radius: 22, x: 0, y: 12)
        }
    }

    @available(iOS 26.0, macOS 26.0, *)
    private var resolvedGlass: Glass {
        guard reduceTransparency == false else { return .identity }

        var glass: Glass = .regular
        if let tint {
            glass = glass.tint(tint)
        }
        if interactive {
            glass = glass.interactive()
        }
        return glass
    }
}

extension View {
    func glassCard(
        radius: CGFloat = LiquidGlassTheme.cardRadius,
        tint: Color? = nil,
        interactive: Bool = false,
        padding: CGFloat = 18
    ) -> some View {
        modifier(
            GlassCardModifier(
                radius: radius,
                tint: tint,
                interactive: interactive,
                padding: padding
            )
        )
    }
}
