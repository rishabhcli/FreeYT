import SwiftUI

struct HeroCard: View {
    var body: some View {
        VStack(alignment: .leading, spacing: 12) {
            HStack(alignment: .center, spacing: 14) {
                ZStack {
                    RoundedRectangle(cornerRadius: 18, style: .continuous)
                        .fill(Color.primary.opacity(0.08))
                        .frame(width: 62, height: 62)
                        .overlay(
                            RoundedRectangle(cornerRadius: 18, style: .continuous)
                                .strokeBorder(Color.primary.opacity(0.15), lineWidth: 1)
                        )

                    Image("LargeIcon")
                        .resizable()
                        .scaledToFit()
                        .frame(width: 50, height: 50)
                        .clipShape(RoundedRectangle(cornerRadius: 14, style: .continuous))
                }

                VStack(alignment: .leading, spacing: 6) {
                    Text("FreeYT")
                        .font(.system(size: 26, weight: .bold, design: .rounded))
                        .foregroundColor(LiquidGlassTheme.adaptiveText)

                    Text("Privacy-first YouTube redirects")
                        .foregroundColor(LiquidGlassTheme.adaptiveSecondaryText)
                        .font(.system(size: 14, weight: .medium))
                        .lineLimit(2)
                }

                Spacer()

                VStack(spacing: 6) {
                    Pill(text: "No-cookie route", icon: "shield.lefthalf.fill")
                    Pill(text: "Safari ready", icon: "safari")
                }
            }

            Divider().overlay(Color.primary.opacity(0.12))

            Text("Redirects YouTube links to privacy-safe no-cookie embeds. Enable the extension in Safari to start protecting your browsing.")
                .font(.system(size: 14, weight: .medium))
                .foregroundColor(LiquidGlassTheme.adaptiveSecondaryText)
                .lineSpacing(4)
        }
        .glassCard()
    }
}
