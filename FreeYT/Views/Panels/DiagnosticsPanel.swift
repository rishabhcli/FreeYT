import SwiftUI

struct DiagnosticsPanel: View {
    let isEnabled: Bool
    let checking: Bool
    let videoCount: Int

    var body: some View {
        VStack(alignment: .leading, spacing: 10) {
            HStack {
                Text("Diagnostics")
                    .font(.system(size: 17, weight: .semibold))
                    .foregroundColor(LiquidGlassTheme.adaptiveText)
                Spacer()
                Pill(text: "App Groups", icon: "bolt.horizontal.fill")
            }

            diagnosticsGrid
        }
        .glassCard()
    }

    @ViewBuilder
    private var diagnosticsGrid: some View {
        let labelColor = LiquidGlassTheme.adaptiveSecondaryText
        let valueColor = LiquidGlassTheme.adaptiveText

        if #available(iOS 16.0, *) {
            Grid(alignment: .leading, horizontalSpacing: 12, verticalSpacing: 8) {
                GridRow {
                    Text("Extension ID")
                        .font(.system(size: 12, weight: .medium))
                        .foregroundColor(labelColor)
                    Text(Bundle.main.bundleIdentifier ?? "Safari extension")
                        .font(.system(size: 12, weight: .semibold))
                        .foregroundColor(valueColor)
                }
                GridRow {
                    Text("State")
                        .font(.system(size: 12, weight: .medium))
                        .foregroundColor(labelColor)
                    Text(checking ? "Checking" : (isEnabled ? "Enabled" : "Disabled"))
                        .font(.system(size: 12, weight: .semibold))
                        .foregroundColor(isEnabled ? LiquidGlassTheme.success : .orange)
                }
                GridRow {
                    Text("Videos Watched")
                        .font(.system(size: 12, weight: .medium))
                        .foregroundColor(labelColor)
                    Text("\(videoCount)")
                        .font(.system(size: 12, weight: .semibold))
                        .foregroundColor(LiquidGlassTheme.success)
                }
                GridRow {
                    Text("App Group")
                        .font(.system(size: 12, weight: .medium))
                        .foregroundColor(labelColor)
                    Text(SharedState.isAppGroupAvailable ? "Connected" : "Unavailable")
                        .font(.system(size: 12, weight: .semibold))
                        .foregroundColor(SharedState.isAppGroupAvailable ? LiquidGlassTheme.success : .orange)
                }
            }
        } else {
            VStack(alignment: .leading, spacing: 6) {
                HStack {
                    Text("Extension ID")
                        .font(.system(size: 12, weight: .medium))
                        .foregroundColor(.white.opacity(0.65))
                    Spacer()
                    Text(Bundle.main.bundleIdentifier ?? "Safari extension")
                        .font(.system(size: 12, weight: .semibold))
                        .foregroundColor(.white)
                }
                HStack {
                    Text("State")
                        .font(.system(size: 12, weight: .medium))
                        .foregroundColor(.white.opacity(0.65))
                    Spacer()
                    Text(checking ? "Checking" : (isEnabled ? "Enabled" : "Disabled"))
                        .font(.system(size: 12, weight: .semibold))
                        .foregroundColor(isEnabled ? LiquidGlassTheme.success : .orange)
                }
                HStack {
                    Text("Videos Watched")
                        .font(.system(size: 12, weight: .medium))
                        .foregroundColor(.white.opacity(0.65))
                    Spacer()
                    Text("\(videoCount)")
                        .font(.system(size: 12, weight: .semibold))
                        .foregroundColor(LiquidGlassTheme.success)
                }
                HStack {
                    Text("App Group")
                        .font(.system(size: 12, weight: .medium))
                        .foregroundColor(.white.opacity(0.65))
                    Spacer()
                    Text(SharedState.isAppGroupAvailable ? "Connected" : "Unavailable")
                        .font(.system(size: 12, weight: .semibold))
                        .foregroundColor(SharedState.isAppGroupAvailable ? LiquidGlassTheme.success : .orange)
                }
            }
        }
    }
}
