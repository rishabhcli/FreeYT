//
//  SharedState.swift
//  FreeYT
//
//  Shared state management via App Groups for syncing between
//  the companion app and Safari extension.
//

import Foundation
#if canImport(WidgetKit)
import WidgetKit
#endif

/// Manages shared state between the FreeYT host app and Safari extension
/// using App Groups for cross-process communication.
struct SharedState {
    /// App Group identifier - must match entitlements in both targets
    static let suiteName = "group.com.freeyt.app"

    // MARK: - Storage Keys

    private static let enabledKey = "extensionEnabled"
    private static let videoCountKey = "videoWatchCount"
    private static let lastSyncKey = "lastSyncTimestamp"

    // MARK: - Shared UserDefaults

    /// Returns UserDefaults for the shared App Group container.
    /// Returns nil if App Groups are not properly configured.
    static var defaults: UserDefaults? {
        UserDefaults(suiteName: suiteName)
    }

    // MARK: - Extension Enabled State

    /// Whether the extension redirect functionality is enabled.
    /// Defaults to `true` if not previously set.
    static var isEnabled: Bool {
        get {
            // Use object(forKey:) to distinguish between "not set" and "false"
            guard let defaults = defaults else { return true }
            if defaults.object(forKey: enabledKey) == nil {
                return true // Default to enabled
            }
            return defaults.bool(forKey: enabledKey)
        }
        set {
            defaults?.set(newValue, forKey: enabledKey)
            updateLastSync()
            reloadWidgets()
        }
    }

    // MARK: - Video Watch Counter

    /// The total count of YouTube videos watched ad-free via redirects.
    static var videoCount: Int {
        get {
            defaults?.integer(forKey: videoCountKey) ?? 0
        }
        set {
            defaults?.set(newValue, forKey: videoCountKey)
            updateLastSync()
        }
    }

    /// Increments the video watch counter by 1.
    /// Note: This is a non-atomic read-modify-write, which is acceptable
    /// for this use case since counts are approximate and conflicts are rare.
    static func incrementVideoCount() {
        let current = videoCount
        videoCount = current + 1
        incrementDailyCount()
        reloadWidgets()
    }

    // MARK: - Daily Counts

    private static let dailyCountPrefix = "count_"

    /// Increments today's daily redirect count.
    private static func incrementDailyCount() {
        let key = dailyCountPrefix + todayKey()
        let current = defaults?.integer(forKey: key) ?? 0
        defaults?.set(current + 1, forKey: key)
    }

    /// Returns daily counts for the last `days` days, keyed by date string (YYYY-MM-DD).
    static func dailyCounts(for days: Int = 7) -> [String: Int] {
        var result: [String: Int] = [:]
        let calendar = Calendar.current
        for i in 0..<days {
            guard let date = calendar.date(byAdding: .day, value: -i, to: Date()) else { continue }
            let key = dailyCountPrefix + dateKey(for: date)
            result[dateKey(for: date)] = defaults?.integer(forKey: key) ?? 0
        }
        return result
    }

    private static func todayKey() -> String {
        dateKey(for: Date())
    }

    private static func dateKey(for date: Date) -> String {
        let formatter = DateFormatter()
        formatter.dateFormat = "yyyy-MM-dd"
        formatter.timeZone = TimeZone.current
        return formatter.string(from: date)
    }

    /// Resets the video watch counter to 0.
    static func resetVideoCount() {
        videoCount = 0
    }

    // MARK: - Sync Timestamp

    /// The timestamp of the last state change.
    /// Useful for conflict resolution between app and extension.
    static var lastSyncTimestamp: Date? {
        get {
            defaults?.object(forKey: lastSyncKey) as? Date
        }
        set {
            defaults?.set(newValue, forKey: lastSyncKey)
        }
    }

    /// Updates the last sync timestamp to now.
    private static func updateLastSync() {
        lastSyncTimestamp = Date()
    }

    /// Tells WidgetKit to refresh all FreeYT widgets.
    private static func reloadWidgets() {
        #if canImport(WidgetKit)
        WidgetCenter.shared.reloadAllTimelines()
        #endif
    }

    // MARK: - Diagnostics

    /// Checks if App Groups are properly configured and accessible.
    static var isAppGroupAvailable: Bool {
        defaults != nil
    }

    /// Returns a dictionary of all shared state for debugging purposes.
    static var debugState: [String: Any] {
        [
            "suiteName": suiteName,
            "isAppGroupAvailable": isAppGroupAvailable,
            "isEnabled": isEnabled,
            "videoCount": videoCount,
            "lastSyncTimestamp": lastSyncTimestamp?.description ?? "nil"
        ]
    }
}
