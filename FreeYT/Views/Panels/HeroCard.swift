import SwiftUI

struct HeroCard: View {
    let snapshot: DashboardSnapshot

    var body: some View {
        VStack(alignment: .leading, spacing: 18) {
            HStack(alignment: .top, spacing: 16) {
                ZStack {
                    if #available(iOS 26.0, macOS 26.0, *) {
                        RoundedRectangle(cornerRadius: 20, style: .continuous)
                            .fill(.clear)
                            .frame(width: 72, height: 72)
                            .glassEffect(.regular.tint(LiquidGlassTheme.accent.opacity(0.18)), in: RoundedRectangle(cornerRadius: 20, style: .continuous))
                    } else {
                        RoundedRectangle(cornerRadius: 20, style: .continuous)
                            .fill(LiquidGlassTheme.heroGradient)
                            .frame(width: 72, height: 72)
                    }

                    Image("LargeIcon")
                        .resizable()
                        .scaledToFit()
                        .frame(width: 58, height: 58)
                        .clipShape(RoundedRectangle(cornerRadius: 14, style: .continuous))
                }

                VStack(alignment: .leading, spacing: 8) {
                    Text("Protect YouTube privacy")
                        .font(.system(size: 28, weight: .bold, design: .rounded))
                        .foregroundStyle(LiquidGlassTheme.adaptiveText)

                    Text(heroCopy)
                        .font(.system(size: 15, weight: .medium))
                        .foregroundStyle(LiquidGlassTheme.adaptiveSecondaryText)
                        .lineSpacing(4)
                }

                Spacer()
            }

            HStack(spacing: 10) {
                Pill(text: snapshot.lastSyncState.label, icon: "arrow.triangle.2.circlepath")
                Pill(text: "Local only", icon: "hand.raised.fill")
                Pill(text: snapshot.enabled ? "Protection on" : "Protection paused", icon: snapshot.enabled ? "checkmark.shield.fill" : "pause.circle.fill")
            }

            HStack(spacing: 12) {
                factCard(title: "Today", value: "\(snapshot.todayCount)", detail: "protected sessions", tone: LiquidGlassTheme.accentStrong)
                factCard(title: "Trusted sites", value: "\(snapshot.exceptions.count)", detail: "Exceptions", tone: .indigo)
                factCard(title: "Last route", value: lastRouteValue, detail: "most recent", tone: LiquidGlassTheme.info)
            }
        }
        .glassCard()
    }

    private var heroCopy: String {
        if let lastProtectedAt = snapshot.lastProtectedAt {
            return "FreeYT is actively routing YouTube links through privacy-enhanced embeds. Last protection event \(lastProtectedAt.formatted(.relative(presentation: .named)))."
        }
        return "FreeYT keeps YouTube sessions private by routing supported links through YouTube's privacy-enhanced embed experience."
    }

    private var lastRouteValue: String {
        snapshot.recentActivity.first?.host ?? "Waiting"
    }

    private func factCard(title: String, value: String, detail: String, tone: Color) -> some View {
        VStack(alignment: .leading, spacing: 4) {
            Text(title.uppercased())
                .font(.system(size: 11, weight: .bold))
                .foregroundStyle(LiquidGlassTheme.adaptiveMutedText)
            Text(value)
                .font(.system(size: 18, weight: .bold, design: .rounded))
                .foregroundStyle(tone)
            Text(detail)
                .font(.system(size: 12, weight: .medium))
                .foregroundStyle(LiquidGlassTheme.adaptiveSecondaryText)
        }
        .glassCard(radius: 18, tint: tone.opacity(0.12), padding: 14)
    }
}
