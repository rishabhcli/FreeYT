import SwiftUI

struct Pill: View {
    let text: String
    let icon: String

    var body: some View {
        pillContent
    }

    @ViewBuilder
    private var pillContent: some View {
        if #available(iOS 26.0, macOS 26.0, *) {
            HStack(spacing: 6) {
                Image(systemName: icon)
                    .font(.system(size: 12, weight: .bold))
                Text(text)
                    .font(.system(size: 12, weight: .semibold))
            }
            .padding(.horizontal, 10)
            .padding(.vertical, 6)
            .foregroundColor(LiquidGlassTheme.adaptiveText)
            .glassEffect(.regular.tint(LiquidGlassTheme.glassHighlight), in: .capsule)
        } else {
            HStack(spacing: 6) {
                Image(systemName: icon)
                    .font(.system(size: 12, weight: .bold))
                Text(text)
                    .font(.system(size: 12, weight: .semibold))
            }
            .padding(.horizontal, 10)
            .padding(.vertical, 6)
            .background(
                LinearGradient(
                    colors: [
                        Color.white.opacity(0.08),
                        Color.white.opacity(0.03)
                    ],
                    startPoint: .topLeading,
                    endPoint: .bottomTrailing
                )
            )
            .overlay(
                RoundedRectangle(cornerRadius: 999, style: .continuous)
                    .strokeBorder(Color.white.opacity(0.16), lineWidth: 1)
            )
            .clipShape(Capsule())
            .foregroundColor(.white)
        }
    }
}
