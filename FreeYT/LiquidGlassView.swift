//
//  LiquidGlassView.swift
//  FreeYT
//
//  Created by Claude Code
//  iOS 26 Liquid Glass Design Implementation
//

import SwiftUI
import SafariServices

// Shared liquid glass tokens for consistent radii and strokes
private enum LiquidGlassTheme {
    static let cardRadius: CGFloat = 24
    static let controlRadius: CGFloat = 28 // Half of standard button height (56) for Capsule
    static let glowOpacity: Double = 0.22
    static let strokeStrong = Color.white.opacity(0.35) // Increased for better refractive edge
    static let strokeSoft = Color.white.opacity(0.08)
}

private struct GlassModifier: ViewModifier {
    let radius: CGFloat
    let shadowOpacity: Double

    func body(content: Content) -> some View {
        content
            .background(
                RoundedRectangle(cornerRadius: radius)
                    .fill(Color.white.opacity(0.08)) // Slightly increased base fill
                    .background(.ultraThinMaterial) // Kept ultraThin for maximum blur
            )
            .overlay(
                RoundedRectangle(cornerRadius: radius)
                    .strokeBorder( // changed to strokeBorder to keep stroke inside bounds
                        LinearGradient(
                            colors: [
                                LiquidGlassTheme.strokeStrong,
                                LiquidGlassTheme.strokeSoft.opacity(0.5),
                                LiquidGlassTheme.strokeSoft
                            ],
                            startPoint: .topLeading,
                            endPoint: .bottomTrailing
                        ),
                        lineWidth: 1.5 // Slightly thicker for "glass edge" feel
                    )
            )
            .clipShape(RoundedRectangle(cornerRadius: radius))
            .shadow(color: Color.black.opacity(shadowOpacity), radius: 24, x: 0, y: 12) // Deeper, softer shadow
    }
}

private extension View {
    func glassCard(radius: CGFloat = LiquidGlassTheme.cardRadius, shadowOpacity: Double = LiquidGlassTheme.glowOpacity) -> some View {
        modifier(GlassModifier(radius: radius, shadowOpacity: shadowOpacity))
    }
}

/// Main view showcasing iOS 26 liquid glass design for FreeYT
struct LiquidGlassView: View {
    @State private var isExtensionEnabled = false
    @State private var checkingState = true

    var body: some View {
        ZStack {
            // Dynamic gradient background
            LinearGradient(
                colors: [
                    Color(red: 0.08, green: 0.08, blue: 0.18),
                    Color(red: 0.18, green: 0.07, blue: 0.22),
                    Color(red: 0.14, green: 0.1, blue: 0.26)
                ],
                startPoint: .topLeading,
                endPoint: .bottomTrailing
            )
            .ignoresSafeArea()

            ScrollView {
                VStack(spacing: 30) {
                    Spacer().frame(height: 20)

                    // App Icon with Glass Effect
                    AppIconSection()

                    // Title Section with Glass Effect
                    TitleSection()

                    // Status Card with Liquid Glass
                    StatusCard(isEnabled: isExtensionEnabled, isChecking: checkingState)

                    // Description Card with Glass Effect
                    DescriptionCard()

                    // Instructions Card with Glass Effect
                    InstructionsCard()

                    // Action Button with Glass Effect
                    ActionButton(isEnabled: isExtensionEnabled)

                    Spacer().frame(height: 30)
                }
                .padding(.horizontal, 20)
            }
        }
        .onAppear {
            checkExtensionStatus()
        }
    }

    private func checkExtensionStatus() {
        #if os(iOS) && !targetEnvironment(macCatalyst)
        if #available(iOS 15.0, *) {
            SFSafariWebExtensionManager.getStateOfSafariWebExtension(withIdentifier: ExtensionIdentifiers.safariExtensionBundleID) { state, error in
                DispatchQueue.main.async {
                    checkingState = false
                    if let state = state {
                        isExtensionEnabled = state.isEnabled
                    }
                }
            }
        } else {
            checkingState = false
        }
        #else
        checkingState = false
        #endif
    }
}

// MARK: - App Icon Section
struct AppIconSection: View {
    var body: some View {
        ZStack {
            // Glass effect background
            Circle()
                .fill(Color.white.opacity(0.05))
                .frame(width: 140, height: 140)
                .overlay(
                    Circle()
                        .stroke(
                            LinearGradient(
                                colors: [
                                    Color.white.opacity(0.3),
                                    Color.white.opacity(0.1)
                                ],
                                startPoint: .topLeading,
                                endPoint: .bottomTrailing
                            ),
                            lineWidth: 1
                        )
                )
                .shadow(color: Color.black.opacity(0.2), radius: 20, x: 0, y: 10)

            // App icon
            Image("LargeIcon")
                .resizable()
                .scaledToFit()
                .frame(width: 100, height: 100)
                .clipShape(RoundedRectangle(cornerRadius: 22))
        }
        .padding(.top, 20)
    }
}

// MARK: - Title Section
struct TitleSection: View {
    var body: some View {
        VStack(spacing: 8) {
            Text("FreeYT")
                .font(.system(size: 36, weight: .bold, design: .rounded))
                .foregroundStyle(
                    LinearGradient(
                        colors: [.white, Color.white.opacity(0.8)],
                        startPoint: .topLeading,
                        endPoint: .bottomTrailing
                    )
                )

            Text("Privacy YouTube Extension")
                .font(.system(size: 16, weight: .medium))
                .foregroundColor(.white.opacity(0.7))
        }
    }
}

// MARK: - Status Card
struct StatusCard: View {
    let isEnabled: Bool
    let isChecking: Bool

    var body: some View {
        HStack(spacing: 16) {
            // Status indicator with glass effect
            ZStack {
                Circle()
                    .fill(Color.white.opacity(0.1))
                    .frame(width: 50, height: 50)

                if isChecking {
                    ProgressView()
                        .tint(.white)
                } else {
                    Image(systemName: isEnabled ? "checkmark.circle.fill" : "exclamationmark.circle.fill")
                        .font(.system(size: 28))
                        .foregroundColor(isEnabled ? .green : .orange)
                }
            }

            VStack(alignment: .leading, spacing: 4) {
                Text(isChecking ? "Checking Status..." : (isEnabled ? "Extension Enabled" : "Extension Disabled"))
                    .font(.system(size: 17, weight: .semibold))
                    .foregroundColor(.white)

                Text(isEnabled ? "Your privacy is protected" : "Enable in Safari Settings")
                    .font(.system(size: 13))
                    .foregroundColor(.white.opacity(0.6))
            }

            Spacer()
        }
        .padding(20)
        .glassCard()
    }
}

// MARK: - Description Card
struct DescriptionCard: View {
    var body: some View {
        VStack(alignment: .leading, spacing: 12) {
            HStack {
                Image(systemName: "shield.checkered")
                    .font(.system(size: 20))
                    .foregroundColor(.blue.opacity(0.8))

                Text("Privacy Protection")
                    .font(.system(size: 17, weight: .semibold))
                    .foregroundColor(.white)
            }

            Text("Automatically redirects YouTube links to privacy-enhanced no-cookie versions, protecting you from tracking.")
                .font(.system(size: 14))
                .foregroundColor(.white.opacity(0.7))
                .lineSpacing(4)
        }
        .frame(maxWidth: .infinity, alignment: .leading)
        .padding(20)
        .glassCard()
    }
}

// MARK: - Instructions Card
struct InstructionsCard: View {
    var body: some View {
        VStack(alignment: .leading, spacing: 16) {
            HStack {
                Image(systemName: "list.number")
                    .font(.system(size: 20))
                    .foregroundColor(.purple.opacity(0.8))

                Text("How to Enable")
                    .font(.system(size: 17, weight: .semibold))
                    .foregroundColor(.white)
            }

            VStack(alignment: .leading, spacing: 12) {
                InstructionStep(number: "1", text: "Open Safari")
                InstructionStep(number: "2", text: "Go to Settings → Extensions")
                InstructionStep(number: "3", text: "Enable FreeYT Extension")
                InstructionStep(number: "4", text: "Grant necessary permissions")
            }
        }
        .frame(maxWidth: .infinity, alignment: .leading)
        .padding(20)
        .glassCard()
    }
}

struct InstructionStep: View {
    let number: String
    let text: String

    var body: some View {
        HStack(spacing: 12) {
            ZStack {
                Circle()
                    .fill(Color.white.opacity(0.15))
                    .frame(width: 28, height: 28)

                Text(number)
                    .font(.system(size: 14, weight: .bold))
                    .foregroundColor(.white)
            }

            Text(text)
                .font(.system(size: 14))
                .foregroundColor(.white.opacity(0.8))
        }
    }
}

// MARK: - Action Button
struct ActionButton: View {
    let isEnabled: Bool
    @State private var isPressed = false

    var body: some View {
        Button(action: openSafariSettings) {
            HStack(spacing: 8) {
                Image(systemName: isEnabled ? "checkmark.circle.fill" : "gear")
                    .font(.system(size: 18))

                Text(isEnabled ? "Extension Active" : "Open Safari Settings")
                    .font(.system(size: 17, weight: .semibold))
            }
            .foregroundColor(.white)
            .frame(maxWidth: .infinity)
            .frame(height: 56)
            .clipShape(Capsule()) // Enforce Capsule shape
            .background(
                Capsule()
                    .fill(.ultraThinMaterial)
                    .overlay(
                        LinearGradient(
                            colors: isEnabled ? [
                                Color.green.opacity(0.40),
                                Color.green.opacity(0.25)
                            ] : [
                                Color.red.opacity(0.45),
                                Color.red.opacity(0.25)
                            ],
                            startPoint: .topLeading,
                            endPoint: .bottomTrailing
                        )
                        .blendMode(.overlay) // Changed to overlay for better color integration
                    )
                    .overlay(
                        Capsule()
                            .strokeBorder(
                                LinearGradient(
                                    colors: [
                                        LiquidGlassTheme.strokeStrong,
                                        LiquidGlassTheme.strokeSoft
                                    ],
                                    startPoint: .topLeading,
                                    endPoint: .bottomTrailing
                                ),
                                lineWidth: 1.5
                            )
                    )
            )
            .shadow(color: (isEnabled ? Color.green : Color.red).opacity(0.35), radius: 20, x: 0, y: 10)
            .scaleEffect(isPressed ? 0.96 : 1.0)
        }
        .disabled(isEnabled)
        .simultaneousGesture(
            DragGesture(minimumDistance: 0)
                .onChanged { _ in isPressed = true }
                .onEnded { _ in isPressed = false }
        )
        .animation(.spring(response: 0.3, dampingFraction: 0.6), value: isPressed)
    }

    private func openSafariSettings() {
        #if targetEnvironment(macCatalyst)
        // Catalyst: open Safari so the user can enable the extension from Safari Settings → Extensions
        if let safariURL = URL(string: "safari:") {
            UIApplication.shared.open(safariURL, options: [:], completionHandler: nil)
        }
        #else
        // iOS: try deep link to Safari extensions; fall back to Safari root settings, then app settings
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
        #endif
    }
}

// MARK: - Preview
struct LiquidGlassView_Previews: PreviewProvider {
    static var previews: some View {
        LiquidGlassView()
            .preferredColorScheme(.dark)
    }
}
