import SwiftUI

struct SidebarRow: View {
    let section: SidebarSection
    let snapshot: DashboardSnapshot

    var body: some View {
        HStack(spacing: 14) {
            ZStack {
                if #available(iOS 26.0, macOS 26.0, *) {
                    RoundedRectangle(cornerRadius: 12, style: .continuous)
                        .fill(.clear)
                        .frame(width: 36, height: 36)
                        .glassEffect(.regular.tint(sectionAccent.opacity(0.22)), in: RoundedRectangle(cornerRadius: 12, style: .continuous))
                } else {
                    RoundedRectangle(cornerRadius: 12, style: .continuous)
                        .fill(sectionAccent.opacity(0.14))
                        .frame(width: 36, height: 36)
                }

                Image(systemName: section.icon)
                    .font(.system(size: 16, weight: .semibold))
                    .foregroundStyle(sectionAccent)
            }

            VStack(alignment: .leading, spacing: 2) {
                Text(section.title)
                    .font(.system(size: 15, weight: .semibold))

                Text(liveSubtitle)
                    .font(.system(size: 12, weight: .medium))
                    .foregroundStyle(.secondary)
            }

            Spacer()

            if let badgeText {
                Text(badgeText)
                    .font(.system(size: 11, weight: .bold, design: .rounded))
                    .foregroundStyle(badgeColor)
                    .padding(.horizontal, 8)
                    .padding(.vertical, 5)
                    .background(badgeBackground)
            }
        }
        .padding(.vertical, 4)
    }

    @ViewBuilder
    private var badgeBackground: some View {
        if #available(iOS 26.0, macOS 26.0, *) {
            Capsule(style: .continuous)
                .fill(.clear)
                .glassEffect(.regular.tint(badgeColor.opacity(0.18)), in: Capsule(style: .continuous))
        } else {
            Capsule(style: .continuous)
                .fill(badgeColor.opacity(0.12))
        }
    }

    private var liveSubtitle: String {
        switch section {
        case .overview:
            return snapshot.enabled ? "Protection is active" : "Protection is paused"
        case .activity:
            return snapshot.videoCount == 0 ? "No protected sessions yet" : "\(snapshot.weekCount) protected this week"
        case .exceptions:
            return snapshot.exceptions.isEmpty ? "No trusted exceptions" : "\(snapshot.exceptions.count) trusted sites"
        case .trust:
            return snapshot.lastSyncState.label
        case .setup:
            return snapshot.lastProtectedAt == nil ? "Needs verification" : "Ready to verify"
        }
    }

    private var badgeText: String? {
        switch section {
        case .overview:
            return snapshot.enabled ? "On" : "Off"
        case .activity:
            return snapshot.videoCount == 0 ? nil : "\(snapshot.videoCount)"
        case .exceptions:
            return snapshot.exceptions.isEmpty ? nil : "\(snapshot.exceptions.count)"
        case .trust:
            return snapshot.lastSyncState == .synced ? "Sync" : "Check"
        case .setup:
            return snapshot.lastProtectedAt == nil ? "Guide" : nil
        }
    }

    private var sectionAccent: Color {
        switch section {
        case .overview:
            return snapshot.enabled ? LiquidGlassTheme.accent : LiquidGlassTheme.warning
        case .activity:
            return LiquidGlassTheme.info
        case .exceptions:
            return .indigo
        case .trust:
            return .teal
        case .setup:
            return .orange
        }
    }

    private var badgeColor: Color {
        switch section {
        case .overview:
            return snapshot.enabled ? LiquidGlassTheme.accentStrong : LiquidGlassTheme.warning
        default:
            return sectionAccent
        }
    }
}
