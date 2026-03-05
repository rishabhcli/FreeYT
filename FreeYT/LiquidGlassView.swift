//
//  LiquidGlassView.swift
//  FreeYT
//
//  Main app UI view
//

import SwiftUI
import UIKit
import Combine

/// Main app view
struct LiquidGlassView: View {
    @State private var isExtensionEnabled = false
    @State private var checkingState = true
    @State private var videoCount: Int = 0
    @State private var panelsAppeared = false
    @State private var selectedSection: SidebarSection? = .status
    @Namespace private var glassSpace

    private var isIOS26: Bool {
        if #available(iOS 26.0, *) { return true }
        return false
    }

    // Timer for periodic sync with shared state
    private let syncTimer = Timer.publish(every: 2, on: .main, in: .common).autoconnect()

    var body: some View {
        if #available(iOS 26.0, *) {
            sidebarLayout
                .onAppear {
                    refreshFromSharedState()
                }
                .onReceive(syncTimer) { _ in
                    refreshFromSharedState()
                }
        } else {
            legacyLayout
                .onAppear {
                    refreshFromSharedState()
                }
                .onReceive(syncTimer) { _ in
                    refreshFromSharedState()
                }
        }
    }

    // MARK: - iOS 26+ Sidebar Layout

    @available(iOS 26.0, *)
    private var sidebarLayout: some View {
        NavigationSplitView {
            List(SidebarSection.allCases, selection: $selectedSection) { section in
                NavigationLink(value: section) {
                    SidebarRow(section: section, isEnabled: isExtensionEnabled, videoCount: videoCount)
                }
            }
            .navigationTitle("FreeYT")
            .listStyle(.sidebar)
        } detail: {
            ScrollView(showsIndicators: false) {
                VStack(spacing: 18) {
                    detailContent
                }
                .padding(.horizontal, 18)
                .padding(.top, 12)
                .padding(.bottom, 32)
            }
            .navigationTitle(selectedSection?.title ?? "FreeYT")
        }
    }

    // MARK: - iOS 26+ Detail Content

    @available(iOS 26.0, *)
    @ViewBuilder
    private var detailContent: some View {
        switch selectedSection {
        case .status:
            StatusPanel(isEnabled: isExtensionEnabled, isChecking: checkingState, glassSpace: glassSpace, toggleBinding: toggleBinding, videoCount: videoCount)
                .glassTransitionIfAvailable()
            ActionButton(isEnabled: isExtensionEnabled, openSettings: openSafariSettings)
                .glassTransitionIfAvailable()

        case .statistics:
            VideoStatsPanel(videoCount: videoCount)
                .glassTransitionIfAvailable()

        case .setup:
            StepsPanel()
                .glassTransitionIfAvailable()

        case .support:
            SupportPanel(onRefresh: refreshFromSharedState)
                .glassTransitionIfAvailable()
            DiagnosticsPanel(isEnabled: isExtensionEnabled, checking: checkingState, videoCount: videoCount)
                .glassTransitionIfAvailable()

        case .about:
            HeroCard()
                .glassTransitionIfAvailable()

        case .none:
            HeroCard()
                .glassTransitionIfAvailable()
        }
    }

    // MARK: - Pre-iOS 26 Legacy Layout

    private var legacyLayout: some View {
        ZStack {
            BackgroundGlow()
                .ignoresSafeArea()

            ParticleField(count: 18)
                .ignoresSafeArea()
                .blendMode(.plusLighter)
                .opacity(0.6)

            ScrollView(showsIndicators: false) {
                VStack(spacing: 18) {
                    panelStack
                }
                .padding(.horizontal, 18)
                .padding(.top, 12)
                .padding(.bottom, 32)
            }
        }
    }

    @ViewBuilder
    private var panelStack: some View {
        HeroCard()
            .glassTransitionIfAvailable()

        StatusPanel(isEnabled: isExtensionEnabled, isChecking: checkingState, glassSpace: glassSpace, toggleBinding: toggleBinding, videoCount: videoCount)
            .glassTransitionIfAvailable()

        VideoStatsPanel(videoCount: videoCount)
            .glassTransitionIfAvailable()

        StepsPanel()
            .glassTransitionIfAvailable()

        SupportPanel(onRefresh: refreshFromSharedState)
            .glassTransitionIfAvailable()

        DiagnosticsPanel(isEnabled: isExtensionEnabled, checking: checkingState, videoCount: videoCount)
            .glassTransitionIfAvailable()

        ActionButton(isEnabled: isExtensionEnabled, openSettings: openSafariSettings)
            .glassTransitionIfAvailable()
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
        // Update shared state so extension can sync
        SharedState.isEnabled = newValue
        isExtensionEnabled = newValue

        // If enabling, guide user to Safari Settings
        if newValue {
            openSafariSettings()
        }
    }

    /// Refresh state from the App Groups shared container
    private func refreshFromSharedState() {
        // Read from shared App Group container
        isExtensionEnabled = SharedState.isEnabled
        videoCount = SharedState.videoCount
        checkingState = false
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

// MARK: - Preview

struct LiquidGlassView_Previews: PreviewProvider {
    static var previews: some View {
        LiquidGlassView()
    }
}
