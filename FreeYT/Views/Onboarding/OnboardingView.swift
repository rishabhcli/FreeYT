import SwiftUI
import UIKit

struct OnboardingView: View {
    @State private var currentPage = 0
    var onComplete: () -> Void

    var body: some View {
        ZStack(alignment: .topTrailing) {
            TabView(selection: $currentPage) {
                OnboardingPage(
                    icon: "shield.checkered",
                    title: "Welcome to FreeYT",
                    description: "Protect your privacy by automatically redirecting YouTube to no-cookie embeds."
                )
                .tag(0)

                OnboardingPage(
                    icon: "arrow.triangle.turn.up.right.circle",
                    title: "How It Works",
                    description: "FreeYT intercepts YouTube links at the network level and redirects them to youtube-nocookie.com — no tracking cookies, no ads."
                )
                .tag(1)

                OnboardingPage(
                    icon: "safari",
                    title: "Enable in Safari",
                    description: "Open Safari Settings, tap Extensions, and enable FreeYT. Allow access to YouTube domains when prompted.",
                    ctaTitle: "Open Safari Settings",
                    ctaAction: openSafariSettings
                )
                .tag(2)

                OnboardingPage(
                    icon: "checkmark.seal.fill",
                    title: "You're All Set",
                    description: "FreeYT is ready to protect your browsing. Every YouTube link will now route through privacy-safe embeds.",
                    ctaTitle: "Get Started",
                    ctaAction: completeOnboarding
                )
                .tag(3)
            }
            .tabViewStyle(.page(indexDisplayMode: .always))
            .indexViewStyle(.page(backgroundDisplayMode: .always))

            // Skip button
            if currentPage < 3 {
                Button("Skip") {
                    completeOnboarding()
                }
                .font(.system(size: 15, weight: .medium))
                .foregroundColor(LiquidGlassTheme.adaptiveSecondaryText)
                .padding(.horizontal, 24)
                .padding(.top, 16)
            }
        }
    }

    private func completeOnboarding() {
        UserDefaults.standard.set(true, forKey: "onboardingCompleted")
        onComplete()
    }

    private func openSafariSettings() {
        let candidates = [
            "App-Prefs:root=SAFARI&path=WEB_EXTENSIONS",
            "App-Prefs:root=SAFARI",
            UIApplication.openSettingsURLString
        ]
        for candidate in candidates {
            if let url = URL(string: candidate), UIApplication.shared.canOpenURL(url) {
                UIApplication.shared.open(url, options: [:], completionHandler: nil)
                break
            }
        }
    }
}
