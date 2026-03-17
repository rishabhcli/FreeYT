import Foundation
import Combine
import SwiftUI
import UIKit

@MainActor
final class DashboardStore: ObservableObject {
    static let shared = DashboardStore()

    @Published private(set) var snapshot: DashboardSnapshot = SharedState.dashboardSnapshot
    @Published var selectedSection: SidebarSection = .overview

    private init() {}

    func refresh() {
        snapshot = SharedState.dashboardSnapshot
    }

    func setProtectionEnabled(_ enabled: Bool) {
        SharedState.setDashboardState(enabled: enabled, lastSyncState: .pending)
        refresh()
    }

    func addException(_ domain: String) -> String? {
        let normalized = domain.trimmingCharacters(in: .whitespacesAndNewlines).lowercased()
        guard !normalized.isEmpty else {
            return "Enter a domain like music.youtube.com."
        }
        guard isValidDomain(normalized) else {
            return "Use a valid domain like music.youtube.com."
        }

        var current = snapshot.exceptions
        guard !current.contains(normalized) else {
            return "That domain is already in Exceptions."
        }

        current.append(normalized)
        SharedState.setDashboardState(exceptions: current, lastSyncState: .pending)
        refresh()
        return nil
    }

    func removeException(_ domain: String) {
        let next = snapshot.exceptions.filter { $0 != domain }
        SharedState.setDashboardState(exceptions: next, lastSyncState: .pending)
        refresh()
    }

    func completeOnboarding() {
        UserDefaults.standard.set(true, forKey: "onboardingCompleted")
        selectedSection = .overview
        refresh()
    }

    func handleDeepLink(_ url: URL) {
        let route = url.pathComponents.dropFirst().first ?? url.host ?? "dashboard"
        switch route.lowercased() {
        case "activity":
            selectedSection = .activity
        case "exceptions":
            selectedSection = .exceptions
        case "trust":
            selectedSection = .trust
        case "setup":
            selectedSection = .setup
        default:
            selectedSection = .overview
        }
        refresh()
    }

    func openSafariSettings() {
        let candidates = [
            "App-Prefs:root=SAFARI&path=WEB_EXTENSIONS",
            "App-Prefs:root=SAFARI",
            UIApplication.openSettingsURLString
        ]
        for candidate in candidates {
            guard let url = URL(string: candidate),
                  UIApplication.shared.canOpenURL(url) else {
                continue
            }
            UIApplication.shared.open(url, options: [:], completionHandler: nil)
            break
        }
    }

    private func isValidDomain(_ value: String) -> Bool {
        value.range(
            of: #"^(\*\.)?[a-zA-Z0-9]([a-zA-Z0-9-]*[a-zA-Z0-9])?(\.[a-zA-Z0-9]([a-zA-Z0-9-]*[a-zA-Z0-9])?)*\.[a-zA-Z]{2,}$"#,
            options: .regularExpression
        ) != nil
    }
}
