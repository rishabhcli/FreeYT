import SwiftUI

struct SupportPanel: View {
    let snapshot: DashboardSnapshot
    let onRefresh: () -> Void
    let openSettings: () -> Void

    var body: some View {
        VStack(alignment: .leading, spacing: 18) {
            VStack(alignment: .leading, spacing: 6) {
                Text("Why FreeYT is trustworthy")
                    .font(.system(size: 19, weight: .semibold))
                    .foregroundStyle(LiquidGlassTheme.adaptiveText)
                Text("FreeYT stays local, uses minimal permissions, and makes it clear when Safari still needs to sync.")
                    .font(.system(size: 14, weight: .medium))
                    .foregroundStyle(LiquidGlassTheme.adaptiveSecondaryText)
            }

            VStack(spacing: 12) {
                trustRow(icon: "lock.shield.fill", title: "Local only", detail: "FreeYT stores dashboard data and exceptions on your device. No analytics or account system.")
                trustRow(icon: "scope", title: "Minimal permissions", detail: "Safari access is limited to YouTube and youtube-nocookie.com domains that FreeYT protects.")
                trustRow(icon: "arrow.triangle.2.circlepath", title: snapshot.lastSyncState.label, detail: snapshot.lastSyncState.detail)
            }

            HStack(spacing: 10) {
                Button(action: onRefresh) {
                    Label("Refresh dashboard", systemImage: "arrow.clockwise")
                        .frame(maxWidth: .infinity)
                }
                .liquidButton()

                Button(action: openSettings) {
                    Label("Review Safari access", systemImage: "safari")
                        .frame(maxWidth: .infinity)
                }
                .liquidButton()
            }
        }
        .glassCard()
    }

    private func trustRow(icon: String, title: String, detail: String) -> some View {
        HStack(alignment: .top, spacing: 12) {
            Image(systemName: icon)
                .font(.system(size: 16, weight: .semibold))
                .foregroundStyle(LiquidGlassTheme.accentStrong)
                .frame(width: 30, height: 30)
                .background(
                    RoundedRectangle(cornerRadius: 10, style: .continuous)
                        .fill(LiquidGlassTheme.accent.opacity(0.14))
                )

            VStack(alignment: .leading, spacing: 4) {
                Text(title)
                    .font(.system(size: 15, weight: .semibold))
                    .foregroundStyle(LiquidGlassTheme.adaptiveText)
                Text(detail)
                    .font(.system(size: 13, weight: .medium))
                    .foregroundStyle(LiquidGlassTheme.adaptiveSecondaryText)
                    .lineSpacing(2)
            }

            Spacer()
        }
        .glassCard(radius: 18, tint: LiquidGlassTheme.accent.opacity(0.08), padding: 12)
    }
}
