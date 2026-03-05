import SwiftUI

struct SupportPanel: View {
    let onRefresh: () -> Void

    var body: some View {
        VStack(alignment: .leading, spacing: 12) {
            HStack {
                Text("Stay in control")
                    .font(.system(size: 17, weight: .semibold))
                    .foregroundColor(LiquidGlassTheme.adaptiveText)
                Spacer()
                Pill(text: "Local only", icon: "lock.fill")
            }

            Text("Toggle stays synced with the Safari background script. Refresh any time to mirror the current permissions.")
                .font(.system(size: 14, weight: .medium))
                .foregroundColor(LiquidGlassTheme.adaptiveSecondaryText)
                .lineSpacing(4)

            if #available(iOS 26.0, *) {
                HStack(spacing: 10) {
                    Button(action: onRefresh) {
                        Label("Refresh state", systemImage: "arrow.clockwise")
                    }
                    .buttonStyle(.glass)

                    Button(action: {}) {
                        Label("No trackers", systemImage: "shield.checkered")
                    }
                    .buttonStyle(.glass)
                    .disabled(true)
                }
            } else {
                HStack(spacing: 10) {
                    Button(action: onRefresh) {
                        SupportChip(title: "Refresh state", subtitle: "Matches Safari", icon: "arrow.clockwise")
                    }
                    .buttonStyle(.plain)
                    SupportChip(title: "No trackers", subtitle: "Local logic", icon: "shield.checkered")
                }
            }
        }
        .glassCard()
    }
}
