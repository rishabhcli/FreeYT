import SwiftUI

struct StepsPanel: View {
    let snapshot: DashboardSnapshot
    let openSettings: () -> Void

    private var steps: [(String, String, Bool)] {
        [
            ("Open Safari Settings", "Go to Safari -> Extensions and enable FreeYT.", snapshot.enabled),
            ("Grant YouTube access", "Allow FreeYT to run on youtube.com, youtu.be, and youtube-nocookie.com.", snapshot.enabled),
            ("Verify a protected route", "Open any YouTube video and confirm FreeYT records a recent protection event.", snapshot.lastProtectedAt != nil),
            ("Use Exceptions only when needed", "Add trusted sites that should stay on YouTube instead of routing through embeds.", true)
        ]
    }

    var body: some View {
        VStack(alignment: .leading, spacing: 18) {
            HStack {
                VStack(alignment: .leading, spacing: 6) {
                    Text("Setup and verification")
                        .font(.system(size: 19, weight: .semibold))
                    Text("Use this checklist to enable FreeYT and confirm it is working.")
                        .font(.system(size: 14, weight: .medium))
                        .foregroundStyle(LiquidGlassTheme.adaptiveSecondaryText)
                }
                Spacer()
                Pill(text: snapshot.lastProtectedAt == nil ? "Needs verification" : "Verified", icon: snapshot.lastProtectedAt == nil ? "exclamationmark.triangle.fill" : "checkmark.circle.fill")
            }

            VStack(spacing: 12) {
                ForEach(Array(steps.enumerated()), id: \.offset) { index, item in
                    stepRow(index: index + 1, title: item.0, detail: item.1, complete: item.2)
                }
            }

            Button(action: openSettings) {
                Label("Open Safari Settings", systemImage: "safari")
                    .frame(maxWidth: .infinity)
            }
            .liquidButton(prominent: true, tint: LiquidGlassTheme.accentStrong)
        }
        .glassCard()
    }

    private func stepRow(index: Int, title: String, detail: String, complete: Bool) -> some View {
        HStack(alignment: .top, spacing: 12) {
            ZStack {
                Circle()
                    .fill((complete ? LiquidGlassTheme.accent : LiquidGlassTheme.warning).opacity(0.16))
                    .frame(width: 32, height: 32)
                Image(systemName: complete ? "checkmark" : "\(index).circle.fill")
                    .font(.system(size: 13, weight: .bold))
                    .foregroundStyle(complete ? LiquidGlassTheme.accentStrong : LiquidGlassTheme.warning)
            }

            VStack(alignment: .leading, spacing: 4) {
                Text(title)
                    .font(.system(size: 15, weight: .semibold))
                Text(detail)
                    .font(.system(size: 13, weight: .medium))
                    .foregroundStyle(LiquidGlassTheme.adaptiveSecondaryText)
            }

            Spacer()
        }
        .glassCard(
            radius: 18,
            tint: (complete ? LiquidGlassTheme.accent : LiquidGlassTheme.warning).opacity(0.08),
            padding: 14
        )
    }
}
