import SwiftUI
import UIKit

enum Haptics {
    static func light() {
        UIImpactFeedbackGenerator(style: .light).impactOccurred()
    }
}

struct LiquidButtonModifier: ViewModifier {
    let prominent: Bool
    let tint: Color?

    @ViewBuilder
    func body(content: Content) -> some View {
        if #available(iOS 26.0, macOS 26.0, *) {
            if prominent {
                content
                    .buttonStyle(.glassProminent)
                    .tint(tint ?? LiquidGlassTheme.accentStrong)
            } else {
                content
                    .buttonStyle(.glass)
                    .tint(tint ?? LiquidGlassTheme.accentStrong)
            }
        } else if prominent {
            content
                .buttonStyle(.borderedProminent)
                .tint(tint ?? LiquidGlassTheme.accentStrong)
        } else {
            content
                .buttonStyle(.bordered)
                .tint(tint ?? LiquidGlassTheme.accentStrong)
        }
    }
}

/// Wraps content in a GlassEffectContainer when available
@MainActor @ViewBuilder
func GlassCluster<Content: View>(glassSpace: Namespace.ID, @ViewBuilder _ content: () -> Content) -> some View {
    if #available(iOS 26.0, macOS 26.0, *) {
        GlassEffectContainer(spacing: 12) {
            content()
        }
    } else {
        content()
    }
}

/// Attach glass IDs when available
extension View {
    @ViewBuilder
    func glassID<H: Hashable & Sendable>(_ id: H, in namespace: Namespace.ID) -> some View {
        if #available(iOS 26.0, macOS 26.0, *) {
            self.glassEffectID(id, in: namespace)
        } else {
            self
        }
    }

    /// Apply materialize transition on iOS 26 for panel entrance animations
    @ViewBuilder
    func glassTransitionIfAvailable() -> some View {
        if #available(iOS 26.0, macOS 26.0, *) {
            self.glassEffectTransition(.materialize)
        } else {
            self
        }
    }

    func liquidButton(prominent: Bool = false, tint: Color? = nil) -> some View {
        modifier(LiquidButtonModifier(prominent: prominent, tint: tint))
    }
}
