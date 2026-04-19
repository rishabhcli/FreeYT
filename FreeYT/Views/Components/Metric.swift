import SwiftUI

struct Metric: View {
    enum Tone {
        case normal
        case success
        case warning
    }

    let label: String
    let value: String
    var tone: Tone = .normal

    var body: some View {
        metricContent
    }

    @ViewBuilder
    private var metricContent: some View {
        if #available(iOS 26.0, macOS 26.0, *) {
            VStack(alignment: .leading, spacing: 4) {
                Text(label.uppercased())
                    .font(.system(size: 11, weight: .bold))
                    .foregroundColor(LiquidGlassTheme.adaptiveSecondaryText)
                    .tracking(0.4)
                Text(value)
                    .font(.system(size: 14, weight: .semibold))
                    .foregroundColor(foregroundColor)
            }
            .glassCard(
                radius: 14,
                tint: foregroundColor.opacity(0.12),
                padding: 12
            )
        } else {
            VStack(alignment: .leading, spacing: 4) {
                Text(label.uppercased())
                    .font(.system(size: 11, weight: .bold))
                    .foregroundColor(.white.opacity(0.55))
                    .tracking(0.4)
                Text(value)
                    .font(.system(size: 14, weight: .semibold))
                    .foregroundColor(foregroundColor)
            }
            .padding(12)
            .frame(maxWidth: .infinity, alignment: .leading)
            .background(
                RoundedRectangle(cornerRadius: 14, style: .continuous)
                    .fill(Color.white.opacity(0.05))
                    .overlay(
                        RoundedRectangle(cornerRadius: 14, style: .continuous)
                            .strokeBorder(Color.white.opacity(0.1), lineWidth: 1)
                    )
            )
        }
    }

    private var foregroundColor: Color {
        switch tone {
        case .normal:
            return LiquidGlassTheme.adaptiveText
        case .success:
            return LiquidGlassTheme.success
        case .warning:
            return LiquidGlassTheme.warning
        }
    }
}
