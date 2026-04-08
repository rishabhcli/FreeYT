import SwiftUI

struct OnboardingView: View {
    @State private var currentPage = 0
    var onComplete: () -> Void

    private let pages: [(icon: String, eyebrow: String, title: String, description: String, highlights: [String])] = [
        (
            icon: "shield.lefthalf.filled",
            eyebrow: "Welcome",
            title: "A privacy-first YouTube companion",
            description: "FreeYT routes supported YouTube links through privacy-enhanced embeds so you can watch with less tracking.",
            highlights: [
                "No accounts or analytics",
                "All dashboard data stays on-device",
                "Built for Safari on iPhone, iPad, and Mac"
            ]
        ),
        (
            icon: "chart.xyaxis.line",
            eyebrow: "Dashboard",
            title: "See proof that protection is working",
            description: "The new dashboard shows current protection state, recent routes, weekly activity, and trusted exceptions in one place.",
            highlights: [
                "Overview for status and sync",
                "Activity trend and recent routes",
                "Exceptions for trusted sites"
            ]
        ),
        (
            icon: "safari",
            eyebrow: "Setup",
            title: "Enable FreeYT in Safari",
            description: "Turn on the extension in Safari Settings, allow access to YouTube domains, then verify your first protected route.",
            highlights: [
                "Open Safari -> Extensions",
                "Enable FreeYT",
                "Grant access to youtube.com and youtu.be"
            ]
        ),
        (
            icon: "checkmark.seal.fill",
            eyebrow: "Ready",
            title: "You’re ready to protect YouTube privacy",
            description: "Open the FreeYT dashboard any time to review protection, trusted exceptions, and local-only processing details.",
            highlights: [
                "Use Exceptions only when needed",
                "Refresh the dashboard after Safari changes",
                "Recent routes appear after your first protected session"
            ]
        )
    ]

    var body: some View {
        ZStack {
            BackgroundGlow()
                .ignoresSafeArea()

            VStack(spacing: 24) {
                HStack {
                    progressHeader
                    Spacer()
                    if currentPage < pages.count - 1 {
                        Button("Skip") {
                            completeOnboarding()
                        }
                        .font(.system(size: 15, weight: .semibold))
                        .foregroundStyle(LiquidGlassTheme.adaptiveSecondaryText)
                        .liquidButton()
                    }
                }
                .padding(.top, 20)
                .padding(.horizontal, 24)

                TabView(selection: $currentPage) {
                    ForEach(Array(pages.enumerated()), id: \.offset) { index, page in
                        OnboardingPage(
                            icon: page.icon,
                            eyebrow: page.eyebrow,
                            title: page.title,
                            description: page.description,
                            highlights: page.highlights
                        )
                        .padding(.horizontal, 24)
                        .tag(index)
                    }
                }
                .tabViewStyle(.page(indexDisplayMode: .never))

                actionBar
                    .padding(.horizontal, 24)
                    .padding(.bottom, 20)
            }
        }
    }

    private var progressHeader: some View {
        VStack(alignment: .leading, spacing: 8) {
            Text("FreeYT setup")
                .font(.system(size: 24, weight: .bold, design: .rounded))
                .foregroundStyle(LiquidGlassTheme.adaptiveText)

            HStack(spacing: 8) {
                ForEach(0..<pages.count, id: \.self) { index in
                    Capsule(style: .continuous)
                        .fill(index <= currentPage ? LiquidGlassTheme.accentStrong : Color.white.opacity(0.18))
                        .frame(width: index == currentPage ? 34 : 12, height: 8)
                        .animation(.spring(response: 0.28, dampingFraction: 0.8), value: currentPage)
                }
            }
        }
    }

    private var actionBar: some View {
        HStack(spacing: 10) {
            if currentPage == 2 {
                Button(action: openSafariSettings) {
                    Label("Open Safari Settings", systemImage: "safari")
                        .frame(maxWidth: .infinity)
                }
                .liquidButton()
            }

            Button(action: advance) {
                Text(currentPage == pages.count - 1 ? "Open dashboard" : "Continue")
                    .frame(maxWidth: .infinity)
            }
            .liquidButton(prominent: true, tint: LiquidGlassTheme.accentStrong)
        }
    }

    private func advance() {
        guard currentPage < pages.count - 1 else {
            completeOnboarding()
            return
        }
        withAnimation(.spring(response: 0.3, dampingFraction: 0.8)) {
            currentPage += 1
        }
    }

    private func completeOnboarding() {
        AppPreferences.setOnboardingCompleted(true)
        onComplete()
    }

    private func openSafariSettings() {
        SafariSettingsOpener.open()
    }
}
