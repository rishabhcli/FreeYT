//
//  SceneDelegate.swift
//  FreeYT
//
//  Created by Rishabh Bansal on 10/19/25.
//

import UIKit
import SwiftUI

class SceneDelegate: UIResponder, UIWindowSceneDelegate {
    var window: UIWindow?
    private let stateService: any DashboardStateServing = SharedDashboardStateService()
    private lazy var store = DashboardStore(stateService: stateService)

    func scene(_ scene: UIScene, willConnectTo session: UISceneSession, options connectionOptions: UIScene.ConnectionOptions) {
        guard let windowScene = (scene as? UIWindowScene) else { return }
        let window = UIWindow(windowScene: windowScene)
        configureLaunchOverrides()

        if AppPreferences.isOnboardingCompleted() {
            window.rootViewController = LiquidGlassHostingController(store: store)
        } else {
            let onboardingView = OnboardingView { [self] in
                let transition = CATransition()
                transition.type = .fade
                transition.duration = 0.3
                window.layer.add(transition, forKey: kCATransition)
                self.store.completeOnboarding()
                window.rootViewController = LiquidGlassHostingController(store: self.store)
            }
            window.rootViewController = UIHostingController(rootView: onboardingView)
        }

        self.window = window
        window.makeKeyAndVisible()

        if let context = connectionOptions.urlContexts.first {
            handle(url: context.url)
        }
    }

    func sceneDidBecomeActive(_ scene: UIScene) {
        store.refresh()
    }

    func scene(_ scene: UIScene, openURLContexts URLContexts: Set<UIOpenURLContext>) {
        guard let url = URLContexts.first?.url else { return }
        handle(url: url)
    }

    private func handle(url: URL) {
        store.handleDeepLink(url)
        if AppPreferences.isOnboardingCompleted() == false {
            AppPreferences.setOnboardingCompleted(true)
            window?.rootViewController = LiquidGlassHostingController(store: store)
        }
    }

    private func configureLaunchOverrides() {
        let arguments = ProcessInfo.processInfo.arguments

        if launchFlagValue(named: "-uiTestingResetState", in: arguments) == true {
            stateService.resetDashboardState()
        }

        if launchFlagValue(named: "-uiTestingSeedDashboard", in: arguments) == true {
            seedDashboardState()
        }

        if let onboardingCompleted = launchFlagValue(named: "-onboardingCompleted", in: arguments) {
            AppPreferences.setOnboardingCompleted(onboardingCompleted)
        }

        if let rawSection = launchArgument(named: "-dashboardSection", in: arguments) {
            store.selectedSection = DashboardRoute(rawRouteValue: rawSection).section
        }

        store.refresh()
    }

    private func launchFlagValue(named flag: String, in arguments: [String]) -> Bool? {
        guard let index = arguments.firstIndex(of: flag) else { return nil }
        let nextIndex = arguments.index(after: index)
        guard nextIndex < arguments.endIndex else { return true }

        switch arguments[nextIndex].lowercased() {
        case "yes", "true", "1":
            return true
        case "no", "false", "0":
            return false
        default:
            return true
        }
    }

    private func launchArgument(named flag: String, in arguments: [String]) -> String? {
        guard let index = arguments.firstIndex(of: flag) else { return nil }
        let nextIndex = arguments.index(after: index)
        guard nextIndex < arguments.endIndex else { return nil }
        return arguments[nextIndex]
    }

    private func seedDashboardState() {
        let now = Date()
        let calendar = Calendar.current
        var dailyCounts: [String: Int] = [:]

        for offset in 0..<7 {
            guard let date = calendar.date(byAdding: .day, value: -offset, to: now) else { continue }
            dailyCounts[DashboardSnapshot.dateKey(for: date)] = max(1, 7 - offset)
        }

        let recentActivity = [
            RedirectActivity(host: "youtube.com", kind: .watch, timestamp: now.addingTimeInterval(-900)),
            RedirectActivity(host: "music.youtube.com", kind: .shortLink, timestamp: now.addingTimeInterval(-3_600)),
            RedirectActivity(host: "youtube.com", kind: .shorts, timestamp: now.addingTimeInterval(-7_200))
        ]

        stateService.mirrorExtensionSnapshot(
            enabled: true,
            videoCount: dailyCounts.values.reduce(0, +),
            dailyCounts: dailyCounts,
            recentActivity: recentActivity,
            exceptions: ["music.youtube.com", "studio.youtube.com"],
            lastProtectedAt: recentActivity.first?.timestamp,
            lastSyncState: .synced,
            lastSyncTimestamp: now,
            lastSyncRevision: 1
        )
    }
}
