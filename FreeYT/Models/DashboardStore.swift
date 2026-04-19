import Foundation
import Combine
import SwiftUI

@MainActor
final class DashboardStore: ObservableObject {
    @Published private(set) var snapshot: DashboardSnapshot
    @Published var selectedSection: SidebarSection = .overview

    private let stateService: any DashboardStateServing
    private var snapshotObservation: AnyCancellable?

    init(stateService: any DashboardStateServing = SharedDashboardStateService()) {
        self.stateService = stateService
        self.snapshot = stateService.snapshot
        self.snapshotObservation = stateService.snapshotPublisher
            .receive(on: DispatchQueue.main)
            .sink { [weak self] snapshot in
                self?.snapshot = snapshot
            }
    }

    var isAppGroupAvailable: Bool {
        stateService.isAppGroupAvailable
    }

    func refresh() {
        snapshot = stateService.snapshot
    }

    func setProtectionEnabled(_ enabled: Bool) {
        stateService.updateProtectionEnabled(enabled, lastSyncState: .pending)
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
        stateService.updateExceptions(current, lastSyncState: .pending)
        return nil
    }

    func removeException(_ domain: String) {
        let next = snapshot.exceptions.filter { $0 != domain }
        stateService.updateExceptions(next, lastSyncState: .pending)
    }

    func completeOnboarding() {
        AppPreferences.setOnboardingCompleted(true)
        selectedSection = .overview
    }

    func handleDeepLink(_ url: URL) {
        selectedSection = DashboardRoute(url: url).section
    }

    func openSafariSettings() {
        SafariSettingsOpener.open()
    }

    private func isValidDomain(_ value: String) -> Bool {
        value.range(
            of: #"^(\*\.)?[a-zA-Z0-9]([a-zA-Z0-9-]*[a-zA-Z0-9])?(\.[a-zA-Z0-9]([a-zA-Z0-9-]*[a-zA-Z0-9])?)*\.[a-zA-Z]{2,}$"#,
            options: .regularExpression
        ) != nil
    }
}
