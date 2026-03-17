import SwiftUI

struct OnboardingPage: View {
    let icon: String
    let eyebrow: String
    let title: String
    let description: String
    let highlights: [String]

    var body: some View {
        VStack(spacing: 26) {
            ZStack {
                Circle()
                    .fill(LiquidGlassTheme.accent.opacity(0.14))
                    .frame(width: 88, height: 88)

                Image(systemName: icon)
                    .font(.system(size: 38, weight: .semibold))
                    .foregroundStyle(LiquidGlassTheme.accentStrong)
            }

            VStack(spacing: 10) {
                Text(eyebrow.uppercased())
                    .font(.system(size: 12, weight: .bold))
                    .tracking(1.0)
                    .foregroundStyle(LiquidGlassTheme.accentStrong)

                Text(title)
                    .font(.system(size: 30, weight: .bold, design: .rounded))
                    .multilineTextAlignment(.center)
                    .foregroundStyle(LiquidGlassTheme.adaptiveText)

                Text(description)
                    .font(.system(size: 16, weight: .medium))
                    .multilineTextAlignment(.center)
                    .foregroundStyle(LiquidGlassTheme.adaptiveSecondaryText)
                    .lineSpacing(4)
            }

            VStack(spacing: 10) {
                ForEach(highlights, id: \.self) { item in
                    HStack(spacing: 10) {
                        Image(systemName: "checkmark.circle.fill")
                            .foregroundStyle(LiquidGlassTheme.accentStrong)
                        Text(item)
                            .font(.system(size: 14, weight: .medium))
                            .foregroundStyle(LiquidGlassTheme.adaptiveText)
                        Spacer()
                    }
                    .glassCard(radius: 16, tint: LiquidGlassTheme.accent.opacity(0.08), padding: 12)
                }
            }
        }
        .padding(24)
        .frame(maxWidth: 520)
        .glassCard()
    }
}
