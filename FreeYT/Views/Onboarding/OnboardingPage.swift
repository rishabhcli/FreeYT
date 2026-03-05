import SwiftUI

struct OnboardingPage: View {
    let icon: String
    let title: String
    let description: String
    var ctaTitle: String? = nil
    var ctaAction: (() -> Void)? = nil

    var body: some View {
        VStack(spacing: 24) {
            Spacer()

            Image(systemName: icon)
                .font(.system(size: 64, weight: .light))
                .foregroundColor(LiquidGlassTheme.success)

            Text(title)
                .font(.system(size: 28, weight: .bold, design: .rounded))
                .foregroundColor(LiquidGlassTheme.adaptiveText)
                .multilineTextAlignment(.center)

            Text(description)
                .font(.system(size: 16, weight: .medium))
                .foregroundColor(LiquidGlassTheme.adaptiveSecondaryText)
                .multilineTextAlignment(.center)
                .lineSpacing(4)
                .padding(.horizontal, 32)

            if let ctaTitle, let ctaAction {
                Button(action: ctaAction) {
                    Text(ctaTitle)
                        .font(.system(size: 17, weight: .semibold))
                        .foregroundColor(.white)
                        .padding(.horizontal, 32)
                        .padding(.vertical, 14)
                        .background(
                            Capsule()
                                .fill(LiquidGlassTheme.success)
                        )
                }
                .padding(.top, 8)
            }

            Spacer()
            Spacer()
        }
        .padding(24)
    }
}
