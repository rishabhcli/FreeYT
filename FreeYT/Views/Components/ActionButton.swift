import SwiftUI

struct ActionButton: View {
    let snapshot: DashboardSnapshot
    let openSettings: () -> Void
    let onRefresh: () -> Void

    var body: some View {
        VStack(alignment: .leading, spacing: 16) {
            HStack {
                Text("Quick actions")
                    .font(.system(size: 19, weight: .semibold))
                Spacer()
                Pill(text: snapshot.lastProtectedAt == nil ? "Verify" : "Ready", icon: snapshot.lastProtectedAt == nil ? "sparkles" : "checkmark.circle.fill")
            }

            Text("Use these shortcuts to verify Safari access, refresh the dashboard, and keep protection in sync.")
                .font(.system(size: 14, weight: .medium))
                .foregroundStyle(LiquidGlassTheme.adaptiveSecondaryText)

            HStack(spacing: 10) {
                Button(action: openSettings) {
                    Label("Safari Settings", systemImage: "safari")
                        .frame(maxWidth: .infinity)
                }
                .liquidButton(prominent: true, tint: LiquidGlassTheme.accentStrong)

                Button(action: onRefresh) {
                    Label("Refresh", systemImage: "arrow.clockwise")
                        .frame(maxWidth: .infinity)
                }
                .liquidButton()
            }
        }
        .glassCard()
    }
}
