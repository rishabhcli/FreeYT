import Foundation
import Combine

protocol DashboardStateServing {
    var snapshot: DashboardSnapshot { get }
    var snapshotPublisher: AnyPublisher<DashboardSnapshot, Never> { get }
    var isAppGroupAvailable: Bool { get }

    func updateProtectionEnabled(_ enabled: Bool, lastSyncState: SyncHealth)
    func updateExceptions(_ exceptions: [String], lastSyncState: SyncHealth)
    func resetDashboardState()
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
    )
}

struct SharedDashboardStateService: DashboardStateServing {
    var snapshot: DashboardSnapshot {
        SharedState.dashboardSnapshot
    }

    var snapshotPublisher: AnyPublisher<DashboardSnapshot, Never> {
        NotificationCenter.default.publisher(for: .sharedDashboardStateDidChange)
            .map { _ in SharedState.dashboardSnapshot }
            .eraseToAnyPublisher()
    }

    var isAppGroupAvailable: Bool {
        SharedState.isAppGroupAvailable
    }

    func updateProtectionEnabled(_ enabled: Bool, lastSyncState: SyncHealth) {
        SharedState.setDashboardState(enabled: enabled, lastSyncState: lastSyncState, bumpSyncRevision: true)
    }

    func updateExceptions(_ exceptions: [String], lastSyncState: SyncHealth) {
        SharedState.setDashboardState(exceptions: exceptions, lastSyncState: lastSyncState, bumpSyncRevision: true)
    }

    func resetDashboardState() {
        SharedState.resetDashboardState()
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
        SharedState.mirrorExtensionSnapshot(
            enabled: enabled,
            videoCount: videoCount,
            dailyCounts: dailyCounts,
            recentActivity: recentActivity,
            exceptions: exceptions,
            lastProtectedAt: lastProtectedAt,
            lastSyncState: lastSyncState,
            lastSyncTimestamp: lastSyncTimestamp,
            lastSyncRevision: lastSyncRevision
        )
    }
}
