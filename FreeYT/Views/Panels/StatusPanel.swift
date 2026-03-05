import SwiftUI

struct StatusPanel: View {
    let isEnabled: Bool
    let isChecking: Bool
    let glassSpace: Namespace.ID
    let toggleBinding: Binding<Bool>
    let videoCount: Int
    @Namespace private var metricsNamespace

    var body: some View {
        VStack(alignment: .leading, spacing: 14) {
            GlassCluster(glassSpace: glassSpace) {
                HStack(spacing: 12) {
                    StatusBadge(isEnabled: isEnabled, isChecking: isChecking)
                        .glassID("badge", in: glassSpace)

                    VStack(alignment: .leading, spacing: 4) {
                        Text(isChecking ? "Checking Safari state…" : isEnabled ? "Shield active" : "Shield paused")
                            .font(.system(size: 17, weight: .semibold))
                            .foregroundColor(LiquidGlassTheme.adaptiveText)
                            .glassID("headline", in: glassSpace)

                        Text(isEnabled ? "Auto-redirecting to youtube-nocookie.com." : "Enable the extension in Safari Extensions.")
                            .foregroundColor(LiquidGlassTheme.adaptiveSecondaryText)
                            .font(.system(size: 13))
                            .glassID("subhead", in: glassSpace)
                    }

                    Spacer(minLength: 8)

                    LiquidToggle(binding: toggleBinding, glassSpace: glassSpace)
                        .frame(width: 120)
                }
            }

            metricsRow
        }
        .glassCard()
    }

    @ViewBuilder
    private var metricsRow: some View {
        if #available(iOS 26.0, *) {
            GlassEffectContainer(spacing: 8) {
                HStack(spacing: 10) {
                    Metric(label: "Videos", value: "\(videoCount)", tone: .success)
                        .glassEffectUnion(id: "metrics", namespace: metricsNamespace)
                    Metric(label: "Route", value: "No-cookie embed")
                        .glassEffectUnion(id: "metrics", namespace: metricsNamespace)
                    Metric(label: "Status", value: isEnabled ? "Enabled" : "Disabled", tone: isEnabled ? .success : .warning)
                        .glassEffectUnion(id: "metrics", namespace: metricsNamespace)
                }
            }
        } else {
            HStack(spacing: 10) {
                Metric(label: "Videos", value: "\(videoCount)", tone: .success)
                Metric(label: "Route", value: "No-cookie embed")
                Metric(label: "Status", value: isEnabled ? "Enabled" : "Disabled", tone: isEnabled ? .success : .warning)
            }
        }
    }
}
