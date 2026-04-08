import SwiftUI

struct DiagnosticsPanel: View {
    let snapshot: DashboardSnapshot
    let appGroupConnected: Bool

    var body: some View {
        DisclosureGroup {
            VStack(alignment: .leading, spacing: 10) {
                diagnosticRow(label: "Bundle", value: Bundle.main.bundleIdentifier ?? "Unknown")
                diagnosticRow(label: "Sync state", value: snapshot.lastSyncState.label)
                diagnosticRow(label: "Exceptions", value: "\(snapshot.exceptions.count)")
                diagnosticRow(label: "Recent routes", value: "\(snapshot.recentActivity.count)")
                diagnosticRow(label: "App Group", value: appGroupConnected ? "Connected" : "Unavailable")
                diagnosticRow(label: "Last sync", value: snapshot.lastSyncTimestamp?.formatted(date: .abbreviated, time: .shortened) ?? "Unknown")
            }
            .padding(.top, 14)
        } label: {
            HStack {
                Text("Technical details")
                    .font(.system(size: 16, weight: .semibold))
                Spacer()
                Text("Advanced")
                    .font(.system(size: 11, weight: .bold))
                    .foregroundStyle(LiquidGlassTheme.adaptiveMutedText)
            }
        }
        .glassCard()
    }

    private func diagnosticRow(label: String, value: String) -> some View {
        HStack(alignment: .top) {
            Text(label)
                .font(.system(size: 12, weight: .medium))
                .foregroundStyle(LiquidGlassTheme.adaptiveMutedText)
            Spacer(minLength: 20)
            Text(value)
                .font(.system(size: 12, weight: .semibold))
                .multilineTextAlignment(.trailing)
                .foregroundStyle(LiquidGlassTheme.adaptiveText)
        }
        .padding(.vertical, 2)
    }
}
