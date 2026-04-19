import SwiftUI

struct StatusPanel: View {
    let snapshot: DashboardSnapshot
    let toggleBinding: Binding<Bool>
    let openSettings: () -> Void

    var body: some View {
        VStack(alignment: .leading, spacing: 16) {
            HStack(alignment: .center, spacing: 14) {
                StatusBadge(isEnabled: snapshot.enabled, isChecking: false)

                VStack(alignment: .leading, spacing: 6) {
                    Text(snapshot.enabled ? "Protection is active" : "Protection is paused")
                        .font(.system(size: 18, weight: .semibold))
                        .foregroundStyle(LiquidGlassTheme.adaptiveText)

                    Text(snapshot.enabled ? "YouTube links are being redirected to privacy-enhanced embeds." : "Turn protection back on to resume privacy-safe YouTube routing.")
                        .font(.system(size: 14, weight: .medium))
                        .foregroundStyle(LiquidGlassTheme.adaptiveSecondaryText)
                        .lineSpacing(3)
                }

                Spacer()

                LiquidToggle(binding: toggleBinding)
                    .frame(width: 124)
            }

            HStack(spacing: 12) {
                Metric(label: "Today", value: "\(snapshot.todayCount)", tone: .success)
                Metric(label: "This Week", value: "\(snapshot.weekCount)", tone: .normal)
                Metric(label: "All Time", value: "\(snapshot.videoCount)", tone: .normal)
            }

            HStack(spacing: 10) {
                Button(action: openSettings) {
                    Label("Open Safari Settings", systemImage: "safari")
                        .frame(maxWidth: .infinity)
                }
                .liquidButton(prominent: true, tint: LiquidGlassTheme.accentStrong)

                syncStatePill
            }
        }
        .glassCard()
    }

    private var syncStatePill: some View {
        HStack(spacing: 8) {
            Image(systemName: snapshot.lastSyncState == .synced ? "checkmark.circle.fill" : "clock.badge.exclamationmark")
                .foregroundStyle(snapshot.lastSyncState == .synced ? LiquidGlassTheme.success : LiquidGlassTheme.warning)

            VStack(alignment: .leading, spacing: 2) {
                Text(snapshot.lastSyncState.label)
                    .font(.system(size: 12, weight: .semibold))
                Text(snapshot.lastSyncState.detail)
                    .font(.system(size: 11, weight: .medium))
                    .foregroundStyle(LiquidGlassTheme.adaptiveSecondaryText)
                    .lineLimit(2)
            }
        }
        .glassCard(
            radius: 16,
            tint: (snapshot.lastSyncState == .synced ? LiquidGlassTheme.success : LiquidGlassTheme.warning).opacity(0.12),
            padding: 12
        )
    }
}
