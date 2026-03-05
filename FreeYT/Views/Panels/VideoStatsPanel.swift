import SwiftUI

struct VideoStatsPanel: View {
    let videoCount: Int
    @State private var animateCount = false
    @Namespace private var statsNamespace

    var body: some View {
        VStack(spacing: 16) {
            HStack {
                Text("\u{1F3AC}")
                    .font(.title2)
                Text("Videos Watched Ad-Free")
                    .font(.system(size: 17, weight: .semibold))
                    .foregroundColor(LiquidGlassTheme.adaptiveText)
                Spacer()
                Pill(text: "Privacy", icon: "shield.fill")
            }

            Text("\(videoCount)")
                .font(.system(size: 56, weight: .bold, design: .rounded))
                .foregroundColor(LiquidGlassTheme.adaptiveText)
                .scaleEffect(animateCount ? 1.05 : 1.0)
                .animation(.spring(response: 0.3, dampingFraction: 0.6), value: videoCount)

            Text("Privacy-protected views via youtube-nocookie.com")
                .font(.system(size: 14, weight: .medium))
                .foregroundColor(LiquidGlassTheme.adaptiveSecondaryText)
                .multilineTextAlignment(.center)

            statChipsRow
        }
        .glassCard()
        .onChange(of: videoCount) { _ in
            withAnimation {
                animateCount = true
            }
            DispatchQueue.main.asyncAfter(deadline: .now() + 0.3) {
                animateCount = false
            }
        }
    }

    @ViewBuilder
    private var statChipsRow: some View {
        if #available(iOS 26.0, *) {
            GlassEffectContainer(spacing: 8) {
                HStack(spacing: 12) {
                    StatChip(icon: "eye.slash.fill", label: "No Ads")
                        .glassEffectUnion(id: "stats", namespace: statsNamespace)
                    StatChip(icon: "lock.shield.fill", label: "No Cookies")
                        .glassEffectUnion(id: "stats", namespace: statsNamespace)
                    StatChip(icon: "bolt.fill", label: "Fast")
                        .glassEffectUnion(id: "stats", namespace: statsNamespace)
                }
            }
        } else {
            HStack(spacing: 12) {
                StatChip(icon: "eye.slash.fill", label: "No Ads")
                StatChip(icon: "lock.shield.fill", label: "No Cookies")
                StatChip(icon: "bolt.fill", label: "Fast")
            }
        }
    }
}
