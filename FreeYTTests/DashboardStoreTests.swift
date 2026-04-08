import Testing
import Foundation
import Combine
import UIKit
@testable import FreeYT

private final class MockDashboardStateService: DashboardStateServing {
    private let subject: CurrentValueSubject<DashboardSnapshot, Never>

    var snapshot: DashboardSnapshot {
        subject.value
    }

    var snapshotPublisher: AnyPublisher<DashboardSnapshot, Never> {
        subject.eraseToAnyPublisher()
    }

    var isAppGroupAvailable: Bool = true

    init(snapshot: DashboardSnapshot = .empty) {
        self.subject = CurrentValueSubject(snapshot)
    }

    func updateProtectionEnabled(_ enabled: Bool, lastSyncState: SyncHealth) {
        subject.send(DashboardSnapshot(
            enabled: enabled,
            videoCount: snapshot.videoCount,
            dailyCounts: snapshot.dailyCounts,
            lastProtectedAt: snapshot.lastProtectedAt,
            recentActivity: snapshot.recentActivity,
            exceptions: snapshot.exceptions,
            lastSyncState: lastSyncState,
            lastSyncTimestamp: snapshot.lastSyncTimestamp
        ))
    }

    func updateExceptions(_ exceptions: [String], lastSyncState: SyncHealth) {
        subject.send(DashboardSnapshot(
            enabled: snapshot.enabled,
            videoCount: snapshot.videoCount,
            dailyCounts: snapshot.dailyCounts,
            lastProtectedAt: snapshot.lastProtectedAt,
            recentActivity: snapshot.recentActivity,
            exceptions: exceptions,
            lastSyncState: lastSyncState,
            lastSyncTimestamp: snapshot.lastSyncTimestamp
        ))
    }

    func resetDashboardState() {
        subject.send(.empty)
    }

    func mirrorExtensionSnapshot(
        enabled: Bool,
        videoCount: Int,
        dailyCounts: [String: Int],
        recentActivity: [RedirectActivity],
        exceptions: [String],
        lastProtectedAt: Date?,
        lastSyncState: SyncHealth,
        lastSyncTimestamp: Date?,
        lastSyncRevision: Int?
    ) {
        subject.send(DashboardSnapshot(
            enabled: enabled,
            videoCount: videoCount,
            dailyCounts: dailyCounts,
            lastProtectedAt: lastProtectedAt,
            recentActivity: recentActivity,
            exceptions: exceptions,
            lastSyncState: lastSyncState,
            lastSyncTimestamp: lastSyncTimestamp,
            lastSyncRevision: lastSyncRevision ?? snapshot.lastSyncRevision
        ))
    }
}

@MainActor
@Suite(.serialized)
struct DashboardStoreTests {

    @Test func addExceptionNormalizesStoresAndMarksPendingSync() {
        let stateService = MockDashboardStateService()
        let store = DashboardStore(stateService: stateService)

        let error = store.addException(" Music.YouTube.com ")

        #expect(error == nil)
        #expect(store.snapshot.exceptions == ["music.youtube.com"])
        #expect(store.snapshot.lastSyncState == .pending)
    }

    @Test func addExceptionRejectsDuplicateDomains() {
        let stateService = MockDashboardStateService(
            snapshot: DashboardSnapshot(
                enabled: true,
                videoCount: 0,
                dailyCounts: [:],
                lastProtectedAt: nil,
                recentActivity: [],
                exceptions: ["music.youtube.com"],
                lastSyncState: .synced,
                lastSyncTimestamp: nil
            )
        )
        let store = DashboardStore(stateService: stateService)

        let error = store.addException("music.youtube.com")

        #expect(error == "That domain is already in Exceptions.")
        #expect(store.snapshot.exceptions == ["music.youtube.com"])
    }

    @Test func handleDeepLinkUsesTypedDashboardRoutes() {
        let store = DashboardStore(stateService: MockDashboardStateService())

        store.handleDeepLink(URL(string: "freeyt://dashboard/activity")!)
        #expect(store.selectedSection == .activity)

        store.handleDeepLink(URL(string: "freeyt://exceptions")!)
        #expect(store.selectedSection == .exceptions)

        store.handleDeepLink(URL(string: "freeyt://dashboard/not-real")!)
        #expect(store.selectedSection == .overview)
    }

    @Test func completeOnboardingSetsPreferenceAndReturnsToOverview() {
        AppPreferences.setOnboardingCompleted(false)
        let store = DashboardStore(stateService: MockDashboardStateService())
        store.selectedSection = .trust

        store.completeOnboarding()

        #expect(AppPreferences.isOnboardingCompleted())
        #expect(store.selectedSection == .overview)
    }

    @Test func storeObservesExternalSnapshotUpdates() {
        let stateService = MockDashboardStateService()
        let store = DashboardStore(stateService: stateService)
        let timestamp = Date(timeIntervalSince1970: 1_234)

        stateService.mirrorExtensionSnapshot(
            enabled: false,
            videoCount: 6,
            dailyCounts: [DashboardSnapshot.dateKey(for: timestamp): 6],
            recentActivity: [RedirectActivity(host: "youtube.com", kind: .watch, timestamp: timestamp)],
            exceptions: ["music.youtube.com"],
            lastProtectedAt: timestamp,
            lastSyncState: .synced,
            lastSyncTimestamp: timestamp,
            lastSyncRevision: 3
        )

        #expect(store.snapshot.enabled == false)
        #expect(store.snapshot.videoCount == 6)
        #expect(store.snapshot.exceptions == ["music.youtube.com"])
        #expect(store.snapshot.lastSyncTimestamp == timestamp)
        #expect(store.snapshot.lastSyncRevision == 3)
    }
}

struct DashboardRouteTests {

    @Test func routeParsesPathAndHostForms() {
        #expect(DashboardRoute(url: URL(string: "freeyt://dashboard/activity")!) == .activity)
        #expect(DashboardRoute(url: URL(string: "freeyt://setup")!) == .setup)
        #expect(DashboardRoute(url: URL(string: "freeyt://dashboard/not-real")!) == .overview)
    }
}

struct AppEnvironmentTests {

    @Test func safariSettingsOpenerPrefersTheMostSpecificAvailableURL() {
        let selected = SafariSettingsOpener.firstAvailableURL { url in
            url.absoluteString.contains("WEB_EXTENSIONS")
        }

        #expect(selected?.absoluteString == "App-Prefs:root=SAFARI&path=WEB_EXTENSIONS")
    }

    @Test func safariSettingsOpenerFallsBackToAppSettings() {
        let selected = SafariSettingsOpener.firstAvailableURL { url in
            url.absoluteString == UIApplication.openSettingsURLString
        }

        #expect(selected?.absoluteString == UIApplication.openSettingsURLString)
    }
}
