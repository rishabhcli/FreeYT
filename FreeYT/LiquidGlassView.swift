//
//  LiquidGlassView.swift
//  FreeYT
//
//  Liquid Glass onboarding aligned with Safari taskbar popup
//

import SwiftUI
import SafariServices
#if canImport(UIKit)
import UIKit
#endif

// Shared tokens for the liquid glass onboarding
private enum LiquidGlassTheme {
    static let cardRadius: CGFloat = 22
    static let controlRadius: CGFloat = 28
    static let strokeStrong = Color.white.opacity(0.35)
    static let strokeSoft = Color.white.opacity(0.08)
    static let success = Color(red: 0.23, green: 0.89, blue: 0.56)
    static let warning = Color(red: 0.95, green: 0.79, blue: 0.29)
}

enum TintPalette: String, CaseIterable, Codable, Equatable {
    case pinkCyan
    case blueTeal
    case violetMint

    var primary: Color {
        switch self {
        case .pinkCyan: return Color(red: 1.0, green: 0.30, blue: 0.41)
        case .blueTeal: return Color(red: 0.34, green: 0.60, blue: 1.0)
        case .violetMint: return Color(red: 0.66, green: 0.48, blue: 1.0)
        }
    }

    var secondary: Color {
        switch self {
        case .pinkCyan: return Color(red: 0.42, green: 0.84, blue: 1.0)
        case .blueTeal: return Color(red: 0.24, green: 0.88, blue: 0.72)
        case .violetMint: return Color(red: 0.42, green: 0.88, blue: 0.74)
        }
    }
}

private struct GlassCardModifier: ViewModifier {
    let radius: CGFloat
    @Environment(\.accessibilityReduceTransparency) private var reduceTransparency

    func body(content: Content) -> some View {
        if #available(iOS 26.0, macOS 26.0, *) {
            content
                .padding(18)
                .frame(maxWidth: .infinity, alignment: .leading)
                .glassEffect(
                    reduceTransparency ? .identity : .regular,
                    in: RoundedRectangle(cornerRadius: radius, style: .continuous)
                )
        } else {
            content
                .padding(18)
                .frame(maxWidth: .infinity, alignment: .leading)
                .background(
                    RoundedRectangle(cornerRadius: radius, style: .continuous)
                        .fill(
                            LinearGradient(
                                colors: [
                                    Color.white.opacity(0.10),
                                    Color.white.opacity(0.04)
                                ],
                                startPoint: .topLeading,
                                endPoint: .bottomTrailing
                            )
                        )
                        .background(.ultraThinMaterial)
                        .overlay(
                            RoundedRectangle(cornerRadius: radius, style: .continuous)
                                .strokeBorder(
                                    LinearGradient(
                                        colors: [
                                            LiquidGlassTheme.strokeStrong,
                                            LiquidGlassTheme.strokeSoft
                                        ],
                                        startPoint: .topLeading,
                                        endPoint: .bottomTrailing
                                    ),
                                    lineWidth: 1.2
                                )
                        )
                )
                .shadow(color: Color.black.opacity(0.28), radius: 22, x: 0, y: 12)
        }
    }
}

private extension View {
    func glassCard(radius: CGFloat = LiquidGlassTheme.cardRadius) -> some View {
        modifier(GlassCardModifier(radius: radius))
    }
}

/// Main onboarding view showing Safari taskbar liquid glass treatment
struct LiquidGlassView: View {
    @State private var isExtensionEnabled = false
    @State private var checkingState = true
    @Namespace private var glassSpace
    @AppStorage("liquidTint") private var liquidTint: TintPalette = .pinkCyan

    var body: some View {
        ZStack {
            BackgroundGlow(tint: liquidTint)
                .ignoresSafeArea()

            ParticleField()
                .ignoresSafeArea()
                .blendMode(.plusLighter)
                .opacity(0.6)

            ScrollView(showsIndicators: false) {
                VStack(spacing: 18) {
                    HeroCard(tint: liquidTint, onPickTint: { liquidTint = $0 })

                    StatusPanel(isEnabled: isExtensionEnabled, isChecking: checkingState, glassSpace: glassSpace, toggleBinding: toggleBinding, tint: liquidTint)

                    StepsPanel(tint: liquidTint)

                    SupportPanel(onRefresh: checkExtensionStatus, tint: liquidTint)

                    DiagnosticsPanel(isEnabled: isExtensionEnabled, checking: checkingState)

                    ActionButton(isEnabled: isExtensionEnabled, tint: liquidTint, openSettings: openSafariSettings)
                }
                .padding(.horizontal, 18)
                .padding(.top, 12)
                .padding(.bottom, 32)
            }
        }
        .onAppear {
            checkExtensionStatus()
        }
    }

    private var toggleBinding: Binding<Bool> {
        Binding(
            get: { isExtensionEnabled },
            set: { newValue in
                handleToggleChange(newValue)
            }
        )
    }

    private func handleToggleChange(_ newValue: Bool) {
        // We cannot force-enable the Safari web extension from the host app,
        // so we mirror intent locally and guide the user to Safari Settings.
        isExtensionEnabled = newValue
        if newValue == false { return }
        openSafariSettings()
    }

    private func checkExtensionStatus() {
        #if os(iOS) && !targetEnvironment(macCatalyst) && !targetEnvironment(simulator)
        if #available(iOS 15.0, *) {
            SFSafariWebExtensionManager.getStateOfSafariWebExtension(withIdentifier: ExtensionIdentifiers.safariExtensionBundleID) { state, _ in
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

    #if canImport(UIKit)
    private func openSafariSettings() {
        #if targetEnvironment(macCatalyst)
        if let safariURL = URL(string: "safari:") {
            UIApplication.shared.open(safariURL, options: [:], completionHandler: nil)
        }
        #else
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
    #else
    private func openSafariSettings() {}
    #endif
}

// MARK: - Sections

private struct HeroCard: View {
    let tint: TintPalette
    let onPickTint: (TintPalette) -> Void

    var body: some View {
        VStack(alignment: .leading, spacing: 12) {
            HStack(alignment: .center, spacing: 14) {
                ZStack {
                    RoundedRectangle(cornerRadius: 18, style: .continuous)
                        .fill(
                            LinearGradient(
                                colors: [
                                    tint.primary.opacity(0.35),
                                    tint.secondary.opacity(0.35)
                                ],
                                startPoint: .topLeading,
                                endPoint: .bottomTrailing
                            )
                        )
                        .frame(width: 62, height: 62)
                        .overlay(
                            RoundedRectangle(cornerRadius: 18, style: .continuous)
                                .strokeBorder(Color.white.opacity(0.25), lineWidth: 1)
                        )
                        .shadow(color: tint.secondary.opacity(0.25), radius: 16, x: 0, y: 8)

                    Image("LargeIcon")
                        .resizable()
                        .scaledToFit()
                        .frame(width: 50, height: 50)
                        .clipShape(RoundedRectangle(cornerRadius: 14, style: .continuous))
                }

                VStack(alignment: .leading, spacing: 6) {
                    Text("FreeYT")
                        .font(.system(size: 26, weight: .bold, design: .rounded))
                        .foregroundStyle(
                            LinearGradient(
                                colors: [.white, Color.white.opacity(0.8)],
                                startPoint: .topLeading,
                                endPoint: .bottomTrailing
                            )
                        )

                    Text("Safari taskbar liquid glass onboarding")
                        .foregroundColor(.white.opacity(0.72))
                        .font(.system(size: 14, weight: .medium))
                        .lineLimit(2)
                }

                Spacer()

                VStack(spacing: 6) {
                    Pill(text: "No-cookie route", icon: "shield.lefthalf.fill")
                    Pill(text: "Taskbar ready", icon: "sparkles")
                }
            }

            Divider().overlay(Color.white.opacity(0.12))

            Text("Redirects YouTube links to privacy-safe embeds with a fluid glass shell. The onboarding mirrors the Safari popup so users get the same language on every surface.")
                .font(.system(size: 14, weight: .medium))
                .foregroundColor(.white.opacity(0.76))
                .lineSpacing(4)
        }
        .overlay(alignment: .bottomTrailing) {
            TintPicker(tint: tint, onPick: onPickTint)
        }
        .glassCard()
    }
}

private struct StatusPanel: View {
    let isEnabled: Bool
    let isChecking: Bool
    let glassSpace: Namespace.ID
    let toggleBinding: Binding<Bool>
    let tint: TintPalette

    var body: some View {
        VStack(alignment: .leading, spacing: 14) {
            GlassCluster(glassSpace: glassSpace) {
                HStack(spacing: 12) {
                    StatusBadge(isEnabled: isEnabled, isChecking: isChecking)
                        .glassID("badge", in: glassSpace)

                    VStack(alignment: .leading, spacing: 4) {
                        Text(isChecking ? "Checking Safari state…" : isEnabled ? "Shield active" : "Shield paused")
                            .font(.system(size: 17, weight: .semibold))
                            .foregroundColor(.white)
                            .glassID("headline", in: glassSpace)

                        Text(isEnabled ? "Auto-redirecting to youtube-nocookie.com." : "Enable the extension in Safari Extensions.")
                            .foregroundColor(.white.opacity(0.68))
                            .font(.system(size: 13))
                            .glassID("subhead", in: glassSpace)
                    }

                    Spacer(minLength: 8)

                    LiquidToggle(binding: toggleBinding, glassSpace: glassSpace)
                        .frame(width: 120)
                }
            }

            HStack(spacing: 10) {
                Metric(label: "Surface", value: "Safari taskbar")
                Metric(label: "Route", value: "No-cookie embed")
                Metric(label: "Status", value: isEnabled ? "Enabled" : "Disabled", tone: isEnabled ? .success : .warning)
            }
        }
        .glassCard()
    }
}

private struct StepsPanel: View {
    let tint: TintPalette
    private let steps = [
        "Open Safari.",
        "Safari Settings → Extensions.",
        "Enable “FreeYT”.",
        "Allow page access when prompted."
    ]

    var body: some View {
        VStack(alignment: .leading, spacing: 12) {
            HStack {
                Text("Enable in Safari")
                    .font(.system(size: 17, weight: .semibold))
                    .foregroundColor(.white)
                Spacer()
                Pill(text: "2 min setup", icon: "timer")
            }

            VStack(spacing: 8) {
                ForEach(Array(steps.enumerated()), id: \.offset) { index, text in
                    HStack(spacing: 10) {
                        StepIndex(number: index + 1, tint: tint)
                        Text(text)
                            .font(.system(size: 14, weight: .medium))
                            .foregroundColor(.white.opacity(0.86))
                        Spacer()
                    }
                    .padding(.vertical, 8)
                    .padding(.horizontal, 10)
                    .background(
                        RoundedRectangle(cornerRadius: 14, style: .continuous)
                            .fill(Color.white.opacity(0.05))
                            .overlay(
                                RoundedRectangle(cornerRadius: 14, style: .continuous)
                                    .strokeBorder(Color.white.opacity(0.08), lineWidth: 1)
                            )
                    )
                }
            }
        }
        .glassCard()
    }
}

private struct SupportPanel: View {
    let onRefresh: () -> Void
    let tint: TintPalette

    var body: some View {
        VStack(alignment: .leading, spacing: 12) {
            HStack {
                Text("Stay in control")
                    .font(.system(size: 17, weight: .semibold))
                    .foregroundColor(.white)
                Spacer()
                Pill(text: "Local only", icon: "lock.fill")
            }

            Text("Toggle stays synced with the Safari background script. Refresh any time to mirror the current permissions before you head to the taskbar popup.")
                .font(.system(size: 14, weight: .medium))
                .foregroundColor(.white.opacity(0.75))
                .lineSpacing(4)

            HStack(spacing: 10) {
                Button(action: onRefresh) {
                    SupportChip(title: "Refresh state", subtitle: "Matches Safari", icon: "arrow.clockwise", tint: tint.secondary)
                }
                .buttonStyle(.plain)
                SupportChip(title: "No trackers", subtitle: "Local logic", icon: "shield.checkered", tint: tint.primary)
            }
        }
        .glassCard()
    }
}

// MARK: - Components

private struct Pill: View {
    let text: String
    let icon: String

    var body: some View {
        pillContent
    }

    @ViewBuilder
    private var pillContent: some View {
        if #available(iOS 26.0, macOS 26.0, *) {
            HStack(spacing: 6) {
                Image(systemName: icon)
                    .font(.system(size: 12, weight: .bold))
                Text(text)
                    .font(.system(size: 12, weight: .semibold))
            }
            .padding(.horizontal, 10)
            .padding(.vertical, 6)
            .foregroundColor(.white)
            .glassEffect(.regular, in: .capsule)
        } else {
            HStack(spacing: 6) {
                Image(systemName: icon)
                    .font(.system(size: 12, weight: .bold))
                Text(text)
                    .font(.system(size: 12, weight: .semibold))
            }
            .padding(.horizontal, 10)
            .padding(.vertical, 6)
            .background(
                LinearGradient(
                    colors: [
                        Color.white.opacity(0.08),
                        Color.white.opacity(0.03)
                    ],
                    startPoint: .topLeading,
                    endPoint: .bottomTrailing
                )
            )
            .overlay(
                RoundedRectangle(cornerRadius: 999, style: .continuous)
                    .strokeBorder(Color.white.opacity(0.16), lineWidth: 1)
            )
            .clipShape(Capsule())
            .foregroundColor(.white)
        }
    }
}

/// iOS 26 Liquid Glass toggle wrapper with availability-safe fallbacks
private struct LiquidToggle: View {
    let binding: Binding<Bool>
    let glassSpace: Namespace.ID
    @Environment(\.accessibilityReduceTransparency) private var reduceTransparency

    var body: some View {
        toggleBody
    }

    @ViewBuilder
    private var toggleBody: some View {
        if #available(iOS 26.0, macOS 26.0, *) {
            Toggle(isOn: binding) {
                Text(binding.wrappedValue ? "On" : "Off")
                    .font(.system(size: 12, weight: .semibold))
                    .foregroundColor(.white.opacity(0.8))
            }
            .toggleStyle(.switch)
            .tint(LiquidGlassTheme.success)
            .glassEffect(
                reduceTransparency ? .identity : .regular.interactive(),
                in: .capsule
            )
            .glassEffectID("liquid-toggle", in: glassSpace)
            .accessibilityLabel("FreeYT Shield toggle")
            #if os(iOS)
            .onChange(of: binding.wrappedValue) { _ in Haptics.light() }
            #endif
        } else {
            Toggle(isOn: binding) {
                Text(binding.wrappedValue ? "On" : "Off")
                    .font(.system(size: 12, weight: .semibold))
                    .foregroundColor(.white.opacity(0.8))
            }
            .toggleStyle(.switch)
            .tint(LiquidGlassTheme.success)
            .accessibilityLabel("FreeYT Shield toggle")
            #if os(iOS)
            .onChange(of: binding.wrappedValue) { _ in Haptics.light() }
            #endif
        }
    }
}

private struct StatusBadge: View {
    let isEnabled: Bool
    let isChecking: Bool

    var body: some View {
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

private struct Metric: View {
    enum Tone {
        case normal
        case success
        case warning
    }

    let label: String
    let value: String
    var tone: Tone = .normal

    var body: some View {
        VStack(alignment: .leading, spacing: 4) {
            Text(label.uppercased())
                .font(.system(size: 11, weight: .bold))
                .foregroundColor(.white.opacity(0.55))
                .tracking(0.4)
            Text(value)
                .font(.system(size: 14, weight: .semibold))
                .foregroundColor(foregroundColor)
        }
        .padding(12)
        .frame(maxWidth: .infinity, alignment: .leading)
        .background(
            RoundedRectangle(cornerRadius: 14, style: .continuous)
                .fill(Color.white.opacity(0.05))
                .overlay(
                    RoundedRectangle(cornerRadius: 14, style: .continuous)
                        .strokeBorder(Color.white.opacity(0.1), lineWidth: 1)
                )
        )
    }

    private var foregroundColor: Color {
        switch tone {
        case .normal:
            return .white
        case .success:
            return LiquidGlassTheme.success
        case .warning:
            return LiquidGlassTheme.warning
        }
    }
}

private struct StepIndex: View {
    let number: Int
    let tint: TintPalette

    var body: some View {
        ZStack {
            Circle()
                .fill(
                    LinearGradient(
                        colors: [
                            tint.primary.opacity(0.4),
                            tint.secondary.opacity(0.35)
                        ],
                        startPoint: .topLeading,
                        endPoint: .bottomTrailing
                    )
                )
                .frame(width: 28, height: 28)
                .overlay(
                    Circle()
                        .strokeBorder(Color.white.opacity(0.25), lineWidth: 1)
                )

            Text("\(number)")
                .font(.system(size: 13, weight: .bold))
                .foregroundColor(.white)
        }
    }
}

private struct SupportChip: View {
    let title: String
    let subtitle: String
    let icon: String
    let tint: Color

    var body: some View {
        HStack(alignment: .center, spacing: 10) {
            ZStack {
                RoundedRectangle(cornerRadius: 10, style: .continuous)
                    .fill(tint.opacity(0.15))
                    .frame(width: 36, height: 36)
                    .overlay(
                        RoundedRectangle(cornerRadius: 10, style: .continuous)
                            .strokeBorder(tint.opacity(0.4), lineWidth: 1)
                    )
                Image(systemName: icon)
                    .foregroundColor(tint)
                    .font(.system(size: 16, weight: .semibold))
            }

            VStack(alignment: .leading, spacing: 2) {
                Text(title)
                    .font(.system(size: 14, weight: .semibold))
                    .foregroundColor(.white)
                Text(subtitle)
                    .font(.system(size: 12, weight: .medium))
                    .foregroundColor(.white.opacity(0.7))
            }
        }
        .padding(12)
        .frame(maxWidth: .infinity, alignment: .leading)
        .background(
            RoundedRectangle(cornerRadius: 14, style: .continuous)
                .fill(Color.white.opacity(0.04))
                .overlay(
                    RoundedRectangle(cornerRadius: 14, style: .continuous)
                        .strokeBorder(Color.white.opacity(0.08), lineWidth: 1)
                )
        )
    }
}

private enum Haptics {
    static func light() {
        #if canImport(UIKit)
        UIImpactFeedbackGenerator(style: .light).impactOccurred()
        #endif
    }
}

private struct DiagnosticsPanel: View {
    let isEnabled: Bool
    let checking: Bool

    var body: some View {
        VStack(alignment: .leading, spacing: 10) {
            HStack {
                Text("Diagnostics")
                    .font(.system(size: 17, weight: .semibold))
                    .foregroundColor(.white)
                Spacer()
                Pill(text: "Local only", icon: "bolt.horizontal.fill")
            }

            if #available(iOS 16.0, *) {
                Grid(alignment: .leading, horizontalSpacing: 12, verticalSpacing: 8) {
                    GridRow {
                        Text("Extension ID")
                            .font(.system(size: 12, weight: .medium))
                            .foregroundColor(.white.opacity(0.65))
                        Text(Bundle.main.bundleIdentifier ?? "Safari extension")
                            .font(.system(size: 12, weight: .semibold))
                            .foregroundColor(.white)
                    }
                    GridRow {
                        Text("State")
                            .font(.system(size: 12, weight: .medium))
                            .foregroundColor(.white.opacity(0.65))
                        Text(checking ? "Checking" : (isEnabled ? "Enabled" : "Disabled"))
                            .font(.system(size: 12, weight: .semibold))
                            .foregroundColor(isEnabled ? LiquidGlassTheme.success : .orange)
                    }
                    GridRow {
                        Text("Platform")
                            .font(.system(size: 12, weight: .medium))
                            .foregroundColor(.white.opacity(0.65))
                        Text("Safari (iOS taskbar)")
                            .font(.system(size: 12, weight: .semibold))
                            .foregroundColor(.white)
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
                        Text("Platform")
                            .font(.system(size: 12, weight: .medium))
                            .foregroundColor(.white.opacity(0.65))
                        Spacer()
                        Text("Safari (iOS taskbar)")
                            .font(.system(size: 12, weight: .semibold))
                            .foregroundColor(.white)
                    }
                }
            }
        }
        .glassCard()
    }
}

private struct TintPicker: View {
    let tint: TintPalette
    let onPick: (TintPalette) -> Void

    var body: some View {
        HStack(spacing: 8) {
            ForEach(TintPalette.allCases, id: \.self) { option in
                Button {
                    onPick(option)
                } label: {
                    Circle()
                        .fill(
                            LinearGradient(
                                colors: [option.primary, option.secondary],
                                startPoint: .topLeading,
                                endPoint: .bottomTrailing
                            )
                        )
                        .frame(width: 22, height: 22)
                        .overlay(
                            Circle()
                                .strokeBorder(Color.white.opacity(option == tint ? 0.9 : 0.2), lineWidth: 2)
                        )
                        .shadow(color: option.secondary.opacity(0.35), radius: 8, x: 0, y: 4)
                        .opacity(option == tint ? 1 : 0.8)
                }
                .buttonStyle(.plain)
            }
        }
        .padding(10)
        .background(
            Capsule(style: .continuous)
                .fill(Color.white.opacity(0.06))
                .overlay(
                    Capsule(style: .continuous)
                        .strokeBorder(Color.white.opacity(0.12), lineWidth: 1)
                )
        )
        .padding(.trailing, 4)
        .padding(.bottom, 2)
    }
}

// MARK: - Action Button

private struct ActionButton: View {
    let isEnabled: Bool
    let tint: TintPalette
    let openSettings: () -> Void
    @State private var isPressed = false
    @Environment(\.accessibilityReduceTransparency) private var reduceTransparency

    var body: some View {
        buttonContent
    }

    @ViewBuilder
    private var buttonContent: some View {
        if #available(iOS 26.0, macOS 26.0, *) {
            Button(action: openSettings) {
                HStack(spacing: 10) {
                    Image(systemName: isEnabled ? "checkmark.circle.fill" : "safari")
                        .font(.system(size: 18, weight: .semibold))
                    Text(isEnabled ? "Extension active" : "Open Safari Settings")
                        .font(.system(size: 17, weight: .semibold))
                }
                .foregroundColor(.white)
                .frame(maxWidth: .infinity)
                .frame(height: 58)
                .glassEffect(
                    reduceTransparency ? .identity : .regular.interactive().tint(tint.primary),
                    in: .capsule
                )
            }
            .disabled(isEnabled)
        } else {
            Button(action: openSettings) {
                HStack(spacing: 10) {
                    Image(systemName: isEnabled ? "checkmark.circle.fill" : "safari")
                        .font(.system(size: 18, weight: .semibold))
                    Text(isEnabled ? "Extension active" : "Open Safari Settings")
                        .font(.system(size: 17, weight: .semibold))
                }
                .foregroundColor(.white)
                .frame(maxWidth: .infinity)
                .frame(height: 58)
                .background(
                    Capsule(style: .continuous)
                        .fill(
                            LinearGradient(
                                colors: [
                                    tint.primary.opacity(isEnabled ? 0.45 : 0.65),
                                    tint.secondary.opacity(0.55)
                                ],
                                startPoint: .topLeading,
                                endPoint: .bottomTrailing
                            )
                        )
                        .overlay(
                            Capsule(style: .continuous)
                                .strokeBorder(Color.white.opacity(0.25), lineWidth: 1.2)
                        )
                        .shadow(color: tint.secondary.opacity(0.35), radius: 18, x: 0, y: 10)
                )
                .scaleEffect(isPressed ? 0.97 : 1)
                .animation(.spring(response: 0.28, dampingFraction: 0.7), value: isPressed)
            }
            .disabled(isEnabled)
            .simultaneousGesture(
                DragGesture(minimumDistance: 0)
                    .onChanged { _ in isPressed = true }
                    .onEnded { _ in isPressed = false; Haptics.light() }
            )
        }
    }
}

// MARK: - Background

/// Wraps content in a GlassEffectContainer when available to enable Liquid Glass unions/morphs
@MainActor @ViewBuilder
private func GlassCluster<Content: View>(glassSpace: Namespace.ID, @ViewBuilder _ content: () -> Content) -> some View {
    if #available(iOS 26.0, macOS 26.0, *) {
        GlassEffectContainer(spacing: 12) {
            content()
        }
    } else {
        content()
    }
}

/// Attach glass IDs when Liquid Glass APIs are available
private extension View {
    @ViewBuilder
    func glassID<H: Hashable & Sendable>(_ id: H, in namespace: Namespace.ID) -> some View {
        if #available(iOS 26.0, macOS 26.0, *) {
            self.glassEffectID(id, in: namespace)
        } else {
            self
        }
    }
}

private struct Particle: Identifiable {
    let id = UUID()
    let base: CGPoint // normalized position (0...1)
    let radius: CGFloat
    let size: CGFloat
    let speed: Double
    let color: Color
}

/// Ambient particle glow field to add premium motion without interaction cost
private struct ParticleField: View {
    private let particles: [Particle] = {
        (0..<18).map { _ in
            Particle(
                base: CGPoint(x: .random(in: 0.05...0.95), y: .random(in: 0.05...0.95)),
                radius: .random(in: 40...120),
                size: .random(in: 10...26),
                speed: .random(in: 0.3...0.9),
                color: [.cyan, .pink, LiquidGlassTheme.success, .white].randomElement()!.opacity(0.4)
            )
        }
    }()

    var body: some View {
        TimelineView(.animation) { timeline in
            let time = timeline.date.timeIntervalSinceReferenceDate
            Canvas { context, size in
                for particle in particles {
                    let angle = time * particle.speed
                    let x = particle.base.x * size.width + cos(angle) * particle.radius
                    let y = particle.base.y * size.height + sin(angle * 0.9) * particle.radius
                    let rect = CGRect(x: x, y: y, width: particle.size, height: particle.size)

                    var bubble = context
                    bubble.addFilter(.blur(radius: particle.size * 0.4))
                    bubble.fill(
                        Path(ellipseIn: rect),
                        with: .radialGradient(
                            Gradient(colors: [
                                particle.color.opacity(0.9),
                                particle.color.opacity(0.05)
                            ]),
                            center: CGPoint(x: rect.midX, y: rect.midY),
                            startRadius: 0,
                            endRadius: particle.size * 0.8
                        )
                    )
                }
            }
        }
    }
}

private struct BackgroundGlow: View {
    let tint: TintPalette

    var body: some View {
        TimelineView(.animation) { timeline in
            let time = timeline.date.timeIntervalSinceReferenceDate
            Canvas { context, size in
                // Base gradient
                let gradient = Gradient(colors: [
                    Color(red: 0.04, green: 0.05, blue: 0.12),
                    Color(red: 0.07, green: 0.07, blue: 0.18),
                    Color(red: 0.09, green: 0.06, blue: 0.20)
                ])
                context.fill(
                    Path(CGRect(origin: .zero, size: size)),
                    with: .linearGradient(
                        gradient,
                        startPoint: CGPoint(x: 0, y: 0),
                        endPoint: CGPoint(x: size.width, y: size.height)
                    )
                )

                // Animated blobs
                func drawBlob(color: Color, base: CGPoint, radius: CGFloat, t: Double, speed: Double) {
                    let x = base.x + cos(t * speed) * radius * 0.25
                    let y = base.y + sin(t * speed * 0.9) * radius * 0.3
                    let rect = CGRect(x: x, y: y, width: radius, height: radius)
                    context.addFilter(.blur(radius: radius * 0.4))
                    context.fill(
                        Path(ellipseIn: rect),
                        with: .radialGradient(
                            Gradient(colors: [color.opacity(0.32), color.opacity(0.02)]),
                            center: CGPoint(x: rect.midX, y: rect.midY),
                            startRadius: 0,
                            endRadius: radius * 0.6
                        )
                    )
                }

                drawBlob(color: tint.primary, base: CGPoint(x: size.width * 0.2, y: size.height * 0.15), radius: 240, t: time, speed: 0.35)
                drawBlob(color: tint.secondary, base: CGPoint(x: size.width * 0.8, y: size.height * 0.2), radius: 260, t: time, speed: 0.28)
                drawBlob(color: LiquidGlassTheme.success, base: CGPoint(x: size.width * 0.5, y: size.height * 0.8), radius: 280, t: time, speed: 0.32)
            }
        }
    }
}

// MARK: - Preview

struct LiquidGlassView_Previews: PreviewProvider {
    static var previews: some View {
        LiquidGlassView()
            .preferredColorScheme(.dark)
    }
}
