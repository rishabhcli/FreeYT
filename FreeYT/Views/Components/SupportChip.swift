import SwiftUI

struct SupportChip: View {
    let title: String
    let subtitle: String
    let icon: String

    var body: some View {
        supportChipContent
    }

    @ViewBuilder
    private var supportChipContent: some View {
        if #available(iOS 26.0, *) {
            HStack(alignment: .center, spacing: 10) {
                Image(systemName: icon)
                    .foregroundColor(LiquidGlassTheme.adaptiveSecondaryText)
                    .font(.system(size: 16, weight: .semibold))
                    .frame(width: 36, height: 36)
                    .glassEffect(.regular, in: .rect(cornerRadius: 10))

                VStack(alignment: .leading, spacing: 2) {
                    Text(title)
                        .font(.system(size: 14, weight: .semibold))
                        .foregroundColor(LiquidGlassTheme.adaptiveText)
                    Text(subtitle)
                        .font(.system(size: 12, weight: .medium))
                        .foregroundColor(LiquidGlassTheme.adaptiveSecondaryText)
                }
            }
            .padding(12)
            .frame(maxWidth: .infinity, alignment: .leading)
            .glassEffect(.regular, in: .rect(cornerRadius: 14))
        } else {
            HStack(alignment: .center, spacing: 10) {
                ZStack {
                    RoundedRectangle(cornerRadius: 10, style: .continuous)
                        .fill(Color.white.opacity(0.08))
                        .frame(width: 36, height: 36)
                        .overlay(
                            RoundedRectangle(cornerRadius: 10, style: .continuous)
                                .strokeBorder(Color.white.opacity(0.15), lineWidth: 1)
                        )
                    Image(systemName: icon)
                        .foregroundColor(.white.opacity(0.7))
                        .font(.system(size: 16, weight: .semibold))
                }

                VStack(alignment: .leading, spacing: 2) {
                    Text(title)
                        .font(.system(size: 14, weight: .semibold))
                        .foregroundColor(.white)
                    Text(subtitle)
                        .font(.system(size: 12, weight: .medium))
                        .foregroundColor(.white.opacity(0.7))
                }
            }
            .padding(12)
            .frame(maxWidth: .infinity, alignment: .leading)
            .background(
                RoundedRectangle(cornerRadius: 14, style: .continuous)
                    .fill(Color.white.opacity(0.04))
                    .overlay(
                        RoundedRectangle(cornerRadius: 14, style: .continuous)
                            .strokeBorder(Color.white.opacity(0.08), lineWidth: 1)
                    )
            )
        }
    }
}
