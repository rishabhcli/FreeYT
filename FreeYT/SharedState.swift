//
//  SharedState.swift
//  FreeYT
//
//  Shared dashboard state via App Groups for syncing between
//  the companion app and Safari extension.
//

import Foundation
#if canImport(WidgetKit)
import WidgetKit
#endif

enum SyncHealth: String, Codable, CaseIterable {
    case synced = "Synced"
    case pending = "Pending Safari sync"
    case unavailable = "Safari unavailable"
    case issue = "Sync issue"

    var label: String { rawValue }

    var detail: String {
        switch self {
        case .synced:
            return "FreeYT and Safari are in sync."
        case .pending:
            return "A recent change will apply the next time Safari refreshes."
        case .unavailable:
            return "Safari or the extension is not currently reachable."
        case .issue:
            return "FreeYT hit a sync issue. A manual refresh should recover."
        }
    }
}

struct RedirectActivity: Codable, Hashable, Identifiable {
    enum Kind: String, Codable, CaseIterable {
        case watch
        case shorts
        case live
        case embed
        case shortLink
        case legacy
        case unknown

        var label: String {
            switch self {
            case .watch:
                return "Video"
            case .shorts:
                return "Short"
            case .live:
                return "Live"
            case .embed:
                return "Embed"
            case .shortLink:
                return "Short link"
            case .legacy:
                return "Legacy"
            case .unknown:
                return "YouTube"
            }
        }
    }

    let id: String
    let host: String
    let kind: Kind
    let timestamp: Date

    init(host: String, kind: Kind, timestamp: Date = Date()) {
        let normalizedHost = RedirectActivity.clean(host: host)
        self.id = "\(normalizedHost)-\(Int(timestamp.timeIntervalSince1970))"
        self.host = normalizedHost
        self.kind = kind
        self.timestamp = timestamp
    }

    var title: String {
        "\(kind.label) protected"
    }

    var subtitle: String {
        "\(host) -> youtube-nocookie.com"
    }

    private static func clean(host: String) -> String {
        host
            .replacingOccurrences(of: "www.", with: "")
            .replacingOccurrences(of: "m.", with: "")
    }
}

struct DashboardSnapshot: Equatable {
    let enabled: Bool
    let videoCount: Int
    let dailyCounts: [String: Int]
    let lastProtectedAt: Date?
    let recentActivity: [RedirectActivity]
    let exceptions: [String]
    let lastSyncState: SyncHealth
    let lastSyncTimestamp: Date?

    var todayCount: Int {
        dailyCounts[DashboardSnapshot.dateKey(for: Date())] ?? 0
    }

    var weekCount: Int {
        let calendar = Calendar.current
        return (0..<7).reduce(0) { partial, offset in
            guard let date = calendar.date(byAdding: .day, value: -offset, to: Date()) else {
                return partial
            }
            return partial + (dailyCounts[DashboardSnapshot.dateKey(for: date)] ?? 0)
        }
    }

    var sortedExceptions: [String] {
        exceptions.sorted { $0.localizedCaseInsensitiveCompare($1) == .orderedAscending }
    }

    var protectedDomains: Int {
        Set(recentActivity.map(\.host)).count
    }

    static let empty = DashboardSnapshot(
        enabled: true,
        videoCount: 0,
        dailyCounts: [:],
        lastProtectedAt: nil,
        recentActivity: [],
        exceptions: [],
        lastSyncState: .unavailable,
        lastSyncTimestamp: nil
    )

    static func dateKey(for date: Date) -> String {
        let formatter = DateFormatter()
        formatter.dateFormat = "yyyy-MM-dd"
        formatter.timeZone = TimeZone.current
        return formatter.string(from: date)
    }
}

/// Manages shared state between the FreeYT host app and Safari extension
/// using App Groups for cross-process communication.
struct SharedState {
    /// App Group identifier - must match entitlements in both targets
    static let suiteName = "group.com.freeyt.app"

    private static let enabledKey = "extensionEnabled"
    private static let videoCountKey = "videoWatchCount"
    private static let lastSyncKey = "lastSyncTimestamp"
    private static let lastSyncStateKey = "lastSyncState"
    private static let lastProtectedAtKey = "lastProtectedAt"
    private static let recentActivityKey = "recentActivity"
    private static let exceptionsKey = "exceptionDomains"
    private static let dailyCountPrefix = "count_"

    /// Returns UserDefaults for the shared App Group container.
    static var defaults: UserDefaults? {
        UserDefaults(suiteName: suiteName)
    }

    static var isEnabled: Bool {
        get {
            guard let defaults = defaults else { return true }
            if defaults.object(forKey: enabledKey) == nil {
                return true
            }
            return defaults.bool(forKey: enabledKey)
        }
        set {
            setDashboardState(enabled: newValue)
        }
    }

    static var videoCount: Int {
        get {
            defaults?.integer(forKey: videoCountKey) ?? 0
        }
        set {
            setDashboardState(videoCount: newValue)
        }
    }

    static var lastProtectedAt: Date? {
        get {
            defaults?.object(forKey: lastProtectedAtKey) as? Date
        }
        set {
            setDashboardState(lastProtectedAt: newValue, updateLastProtectedAt: true)
        }
    }

    static var lastSyncTimestamp: Date? {
        get {
            defaults?.object(forKey: lastSyncKey) as? Date
        }
        set {
            defaults?.set(newValue, forKey: lastSyncKey)
        }
    }

    static var lastSyncState: SyncHealth {
        get {
            guard let raw = defaults?.string(forKey: lastSyncStateKey),
                  let value = SyncHealth(rawValue: raw) else {
                return .unavailable
            }
            return value
        }
        set {
            setDashboardState(lastSyncState: newValue)
        }
    }

    static var exceptionDomains: [String] {
        get {
            decode([String].self, forKey: exceptionsKey, defaultValue: [])
        }
        set {
            let normalized = Array(Set(newValue.map { normalize(domain: $0) })).sorted()
            setDashboardState(exceptions: normalized)
        }
    }

    static var recentActivity: [RedirectActivity] {
        get {
            decode([RedirectActivity].self, forKey: recentActivityKey, defaultValue: [])
        }
        set {
            let trimmed = Array(newValue.sorted(by: { $0.timestamp > $1.timestamp }).prefix(12))
            setDashboardState(recentActivity: trimmed)
        }
    }

    static var dashboardSnapshot: DashboardSnapshot {
        DashboardSnapshot(
            enabled: isEnabled,
            videoCount: videoCount,
            dailyCounts: dailyCounts(for: 7),
            lastProtectedAt: lastProtectedAt,
            recentActivity: recentActivity,
            exceptions: exceptionDomains,
            lastSyncState: lastSyncState,
            lastSyncTimestamp: lastSyncTimestamp
        )
    }

    static func incrementVideoCount(host: String = "youtube.com", kind: RedirectActivity.Kind = .watch) {
        let now = Date()
        let nextCount = videoCount + 1
        let key = dailyCountPrefix + DashboardSnapshot.dateKey(for: now)
        let nextDailyCount = (defaults?.integer(forKey: key) ?? 0) + 1
        var nextActivity = recentActivity
        nextActivity.insert(RedirectActivity(host: host, kind: kind, timestamp: now), at: 0)
        setDashboardState(
            videoCount: nextCount,
            dailyCounts: mergingDailyCounts(with: [DashboardSnapshot.dateKey(for: now): nextDailyCount]),
            recentActivity: nextActivity,
            lastProtectedAt: now,
            updateLastProtectedAt: true,
            lastSyncState: .synced,
            lastSyncTimestamp: now
        )
    }

    static func dailyCounts(for days: Int = 7) -> [String: Int] {
        var result: [String: Int] = [:]
        let calendar = Calendar.current
        for i in 0..<days {
            guard let date = calendar.date(byAdding: .day, value: -i, to: Date()) else { continue }
            let key = dailyCountPrefix + DashboardSnapshot.dateKey(for: date)
            result[DashboardSnapshot.dateKey(for: date)] = defaults?.integer(forKey: key) ?? 0
        }
        return result
    }

    static func resetVideoCount() {
        setDashboardState(
            videoCount: 0,
            dailyCounts: [:],
            recentActivity: [],
            lastProtectedAt: nil,
            updateLastProtectedAt: true
        )
    }

    static func resetDashboardState() {
        guard let defaults else { return }

        defaults.removeObject(forKey: enabledKey)
        defaults.removeObject(forKey: videoCountKey)
        defaults.removeObject(forKey: lastSyncKey)
        defaults.removeObject(forKey: lastSyncStateKey)
        defaults.removeObject(forKey: lastProtectedAtKey)
        defaults.removeObject(forKey: recentActivityKey)
        defaults.removeObject(forKey: exceptionsKey)

        for key in defaults.dictionaryRepresentation().keys where key.hasPrefix(dailyCountPrefix) {
            defaults.removeObject(forKey: key)
        }

        reloadWidgets()
    }

    static func setDashboardState(
        enabled: Bool? = nil,
        videoCount: Int? = nil,
        dailyCounts: [String: Int]? = nil,
        recentActivity: [RedirectActivity]? = nil,
        exceptions: [String]? = nil,
        lastProtectedAt: Date? = nil,
        updateLastProtectedAt: Bool = false,
        lastSyncState: SyncHealth? = nil,
        lastSyncTimestamp: Date? = nil
    ) {
        guard let defaults else { return }

        if let enabled {
            defaults.set(enabled, forKey: enabledKey)
        }

        if let videoCount {
            defaults.set(max(videoCount, 0), forKey: videoCountKey)
        }

        if let dailyCounts {
            replaceDailyCounts(with: dailyCounts, defaults: defaults)
        }

        if let recentActivity {
            encode(Array(recentActivity.prefix(12)), forKey: recentActivityKey, defaults: defaults)
        }

        if let exceptions {
            encode(exceptions.map { normalize(domain: $0) }, forKey: exceptionsKey, defaults: defaults)
        }

        if updateLastProtectedAt {
            defaults.set(lastProtectedAt, forKey: lastProtectedAtKey)
        }

        if let lastSyncState {
            defaults.set(lastSyncState.rawValue, forKey: lastSyncStateKey)
        }

        defaults.set(lastSyncTimestamp ?? Date(), forKey: lastSyncKey)
        reloadWidgets()
    }

    static func mirrorExtensionSnapshot(
        enabled: Bool,
        videoCount: Int,
        dailyCounts: [String: Int],
        recentActivity: [RedirectActivity],
        exceptions: [String],
        lastProtectedAt: Date?,
        lastSyncState: SyncHealth,
        lastSyncTimestamp: Date? = nil
    ) {
        setDashboardState(
            enabled: enabled,
            videoCount: videoCount,
            dailyCounts: dailyCounts,
            recentActivity: recentActivity,
            exceptions: exceptions,
            lastProtectedAt: lastProtectedAt,
            updateLastProtectedAt: true,
            lastSyncState: lastSyncState,
            lastSyncTimestamp: lastSyncTimestamp
        )
    }

    static var isAppGroupAvailable: Bool {
        defaults != nil
    }

    static var debugState: [String: Any] {
        let snapshot = dashboardSnapshot
        return [
            "suiteName": suiteName,
            "isAppGroupAvailable": isAppGroupAvailable,
            "enabled": snapshot.enabled,
            "videoCount": snapshot.videoCount,
            "todayCount": snapshot.todayCount,
            "weekCount": snapshot.weekCount,
            "exceptions": snapshot.exceptions,
            "recentActivityCount": snapshot.recentActivity.count,
            "lastSyncState": snapshot.lastSyncState.rawValue,
            "lastSyncTimestamp": snapshot.lastSyncTimestamp?.description ?? "nil"
        ]
    }

    private static func replaceDailyCounts(with counts: [String: Int], defaults: UserDefaults) {
        for key in defaults.dictionaryRepresentation().keys where key.hasPrefix(dailyCountPrefix) {
            defaults.removeObject(forKey: key)
        }

        for (dateKey, value) in counts {
            defaults.set(max(value, 0), forKey: dailyCountPrefix + dateKey)
        }
    }

    private static func mergingDailyCounts(with updates: [String: Int]) -> [String: Int] {
        var counts = dailyCounts(for: 90)
        for (key, value) in updates {
            counts[key] = max(value, 0)
        }
        return counts
    }

    private static func normalize(domain: String) -> String {
        domain
            .trimmingCharacters(in: .whitespacesAndNewlines)
            .lowercased()
    }

    private static func decode<T: Decodable>(_ type: T.Type, forKey key: String, defaultValue: T) -> T {
        guard let data = defaults?.data(forKey: key) else { return defaultValue }
        return (try? JSONDecoder().decode(type, from: data)) ?? defaultValue
    }

    private static func encode<T: Encodable>(_ value: T, forKey key: String, defaults: UserDefaults) {
        guard let data = try? JSONEncoder().encode(value) else { return }
        defaults.set(data, forKey: key)
    }

    private static func reloadWidgets() {
        #if canImport(WidgetKit)
        WidgetCenter.shared.reloadAllTimelines()
        #endif
    }
}
