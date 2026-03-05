import SwiftUI

struct StepsPanel: View {
    private let steps = [
        "Open Safari.",
        "Safari Settings → Extensions.",
        "Enable \u{201C}FreeYT\u{201D}.",
        "Allow page access when prompted."
    ]

    var body: some View {
        VStack(alignment: .leading, spacing: 12) {
            HStack {
                Text("Enable in Safari")
                    .font(.system(size: 17, weight: .semibold))
                    .foregroundColor(LiquidGlassTheme.adaptiveText)
                Spacer()
                Pill(text: "2 min setup", icon: "timer")
            }

            VStack(spacing: 8) {
                ForEach(Array(steps.enumerated()), id: \.offset) { index, text in
                    stepRow(index: index, text: text)
                }
            }
        }
        .glassCard()
    }

    @ViewBuilder
    private func stepRow(index: Int, text: String) -> some View {
        if #available(iOS 26.0, *) {
            HStack(spacing: 10) {
                StepIndex(number: index + 1)
                Text(text)
                    .font(.system(size: 14, weight: .medium))
                    .foregroundColor(LiquidGlassTheme.adaptiveText.opacity(0.86))
                Spacer()
            }
            .padding(.vertical, 8)
            .padding(.horizontal, 10)
            .background(
                RoundedRectangle(cornerRadius: 14, style: .continuous)
                    .fill(Color.primary.opacity(0.04))
                    .overlay(
                        RoundedRectangle(cornerRadius: 14, style: .continuous)
                            .strokeBorder(Color.primary.opacity(0.08), lineWidth: 1)
                    )
            )
        } else {
            HStack(spacing: 10) {
                StepIndex(number: index + 1)
                Text(text)
                    .font(.system(size: 14, weight: .medium))
                    .foregroundColor(.white.opacity(0.86))
                Spacer()
            }
            .padding(.vertical, 8)
            .padding(.horizontal, 10)
            .background(
                RoundedRectangle(cornerRadius: 14, style: .continuous)
                    .fill(Color.white.opacity(0.05))
                    .overlay(
                        RoundedRectangle(cornerRadius: 14, style: .continuous)
                            .strokeBorder(Color.white.opacity(0.08), lineWidth: 1)
                    )
            )
        }
    }
}
