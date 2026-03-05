import SwiftUI

struct StatusBadge: View {
    let isEnabled: Bool
    let isChecking: Bool

    var body: some View {
        statusBadgeContent
    }

    @ViewBuilder
    private var statusBadgeContent: some View {
        if #available(iOS 26.0, *) {
            ZStack {
                if isChecking {
                    ProgressView()
                        .tint(LiquidGlassTheme.adaptiveText)
                } else {
                    Image(systemName: isEnabled ? "checkmark.circle.fill" : "exclamationmark.circle.fill")
                        .font(.system(size: 28, weight: .semibold))
                        .foregroundColor(isEnabled ? LiquidGlassTheme.success : LiquidGlassTheme.warning)
                }
            }
            .frame(width: 60, height: 60)
            .glassEffect(.regular, in: .circle)
        } else {
            ZStack {
                Circle()
                    .fill(
                        LinearGradient(
                            colors: [
                                Color.white.opacity(0.15),
                                Color.white.opacity(0.05)
                            ],
                            startPoint: .topLeading,
                            endPoint: .bottomTrailing
                        )
                    )
                    .frame(width: 60, height: 60)
                    .overlay(
                        Circle()
                            .strokeBorder(Color.white.opacity(0.2), lineWidth: 1)
                    )
                    .shadow(color: Color.black.opacity(0.25), radius: 12, x: 0, y: 8)

                if isChecking {
                    ProgressView()
                        .tint(.white)
                } else {
                    Image(systemName: isEnabled ? "checkmark.circle.fill" : "exclamationmark.circle.fill")
                        .font(.system(size: 28, weight: .semibold))
                        .foregroundColor(isEnabled ? LiquidGlassTheme.success : LiquidGlassTheme.warning)
                }
            }
        }
    }
}
