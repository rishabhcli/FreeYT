import SwiftUI

struct StatChip: View {
    let icon: String
    let label: String

    var body: some View {
        statChipContent
    }

    @ViewBuilder
    private var statChipContent: some View {
        if #available(iOS 26.0, macOS 26.0, *) {
            HStack(spacing: 6) {
                Image(systemName: icon)
                    .font(.system(size: 12, weight: .semibold))
                    .foregroundColor(LiquidGlassTheme.adaptiveSecondaryText)
                Text(label)
                    .font(.system(size: 12, weight: .semibold))
                    .foregroundColor(LiquidGlassTheme.adaptiveText)
            }
            .padding(.horizontal, 10)
            .padding(.vertical, 8)
            .glassEffect(.regular, in: .rect(cornerRadius: 12))
        } else {
            HStack(spacing: 6) {
                Image(systemName: icon)
                    .font(.system(size: 12, weight: .semibold))
                    .foregroundColor(.white.opacity(0.7))
                Text(label)
                    .font(.system(size: 12, weight: .semibold))
                    .foregroundColor(.white.opacity(0.85))
            }
            .padding(.horizontal, 10)
            .padding(.vertical, 8)
            .background(
                RoundedRectangle(cornerRadius: 12, style: .continuous)
                    .fill(Color.white.opacity(0.06))
                    .overlay(
                        RoundedRectangle(cornerRadius: 12, style: .continuous)
                            .strokeBorder(Color.white.opacity(0.12), lineWidth: 1)
                    )
            )
        }
    }
}
