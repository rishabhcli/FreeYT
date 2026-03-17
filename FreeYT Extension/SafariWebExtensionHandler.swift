//
//  SafariWebExtensionHandler.swift
//  FreeYT Extension
//
//  Native messaging bridge between the Safari Web Extension and the host app.
//  Handles bidirectional dashboard sync via App Groups shared container.
//

import Foundation
import SafariServices
import os.log

class SafariWebExtensionHandler: NSObject, NSExtensionRequestHandling {
    private let logger = Logger(subsystem: "com.freeyt.app.extension", category: "NativeMessaging")

    func beginRequest(with context: NSExtensionContext) {
        guard let item = context.inputItems.first as? NSExtensionItem,
              let message = item.userInfo?[SFExtensionMessageKey] as? [String: Any] else {
            logger.debug("No message received, completing request")
            context.completeRequest(returningItems: nil, completionHandler: nil)
            return
        }

        let action = message["action"] as? String ?? ""
        logger.info("Received action: \(action, privacy: .public)")

        switch action {
        case "openDashboard":
            openDashboard(from: context, message: message)
        default:
            let payload = handleMessage(message)
            complete(context: context, payload: payload)
        }
    }

    private func handleMessage(_ message: [String: Any]) -> [String: Any] {
        let action = message["action"] as? String ?? ""

        switch action {
        case "getSharedState", "getDashboardSnapshot":
            return responsePayload(for: SharedState.dashboardSnapshot, success: true)

        case "setEnabled":
            guard let enabled = message["enabled"] as? Bool else {
                return ["success": false, "error": "Missing 'enabled' parameter"]
            }
            SharedState.setDashboardState(enabled: enabled, lastSyncState: .synced)
            return responsePayload(for: SharedState.dashboardSnapshot, success: true)

        case "setExceptions":
            guard let exceptions = decodeArray([String].self, from: message["exceptions"]) else {
                return ["success": false, "error": "Missing 'exceptions' parameter"]
            }
            SharedState.setDashboardState(exceptions: exceptions, lastSyncState: .pending)
            return responsePayload(for: SharedState.dashboardSnapshot, success: true)

        case "incrementCount":
            let host = (message["host"] as? String) ?? "youtube.com"
            let kind = RedirectActivity.Kind(rawValue: (message["kind"] as? String) ?? "") ?? .watch
            SharedState.incrementVideoCount(host: host, kind: kind)
            return responsePayload(for: SharedState.dashboardSnapshot, success: true)

        case "syncDashboardState":
            applyDashboardSync(message)
            return responsePayload(for: SharedState.dashboardSnapshot, success: true)

        case "getVideoCount":
            return [
                "success": true,
                "videoCount": SharedState.videoCount
            ]

        case "resetCount":
            SharedState.resetVideoCount()
            SharedState.setDashboardState(lastSyncState: .synced)
            return responsePayload(for: SharedState.dashboardSnapshot, success: true)

        case "getDailyStats":
            return [
                "success": true,
                "dailyCounts": SharedState.dailyCounts(for: 7)
            ]

        case "ping":
            return [
                "success": true,
                "pong": true,
                "timestamp": Date().timeIntervalSince1970
            ]

        default:
            logger.warning("Unknown action received: \(action, privacy: .public)")
            return ["success": false, "error": "Unknown action: \(action)"]
        }
    }

    private func applyDashboardSync(_ message: [String: Any]) {
        let snapshot = SharedState.dashboardSnapshot

        let enabled = (message["enabled"] as? Bool) ?? snapshot.enabled
        let videoCount = (message["videoCount"] as? Int) ?? snapshot.videoCount
        let dailyCounts = decodeDictionary(from: message["dailyCounts"]) ?? snapshot.dailyCounts
        let exceptions = decodeArray([String].self, from: message["exceptions"]) ?? snapshot.exceptions
        let recentActivity = decodeArray([RedirectActivity].self, from: message["recentActivity"]) ?? snapshot.recentActivity
        let syncState = SyncHealth(rawValue: (message["lastSyncState"] as? String) ?? "") ?? .synced
        let syncTimestamp = decodeDate(from: message["lastSyncTimestamp"]) ?? Date()
        let lastProtectedAt = decodeDate(from: message["lastProtectedAt"]) ?? snapshot.lastProtectedAt

        SharedState.mirrorExtensionSnapshot(
            enabled: enabled,
            videoCount: videoCount,
            dailyCounts: dailyCounts,
            recentActivity: recentActivity,
            exceptions: exceptions,
            lastProtectedAt: lastProtectedAt,
            lastSyncState: syncState,
            lastSyncTimestamp: syncTimestamp
        )
    }

    private func responsePayload(for snapshot: DashboardSnapshot, success: Bool) -> [String: Any] {
        [
            "success": success,
            "enabled": snapshot.enabled,
            "videoCount": snapshot.videoCount,
            "dailyCounts": snapshot.dailyCounts,
            "exceptions": snapshot.exceptions,
            "recentActivity": snapshot.recentActivity.map(activityPayload),
            "lastProtectedAt": snapshot.lastProtectedAt?.timeIntervalSince1970 as Any,
            "lastSyncState": snapshot.lastSyncState.rawValue,
            "lastSyncTimestamp": snapshot.lastSyncTimestamp?.timeIntervalSince1970 as Any,
            "isAppGroupAvailable": SharedState.isAppGroupAvailable
        ]
    }

    private func activityPayload(for activity: RedirectActivity) -> [String: Any] {
        [
            "id": activity.id,
            "host": activity.host,
            "kind": activity.kind.rawValue,
            "timestamp": activity.timestamp.timeIntervalSince1970
        ]
    }

    private func complete(context: NSExtensionContext, payload: [String: Any]) {
        let response = NSExtensionItem()
        response.userInfo = [SFExtensionMessageKey: payload]
        context.completeRequest(returningItems: [response], completionHandler: nil)
    }

    private func openDashboard(from context: NSExtensionContext, message: [String: Any]) {
        let section = (message["section"] as? String)?.trimmingCharacters(in: .whitespacesAndNewlines)
        let urlString: String
        if let section, !section.isEmpty {
            urlString = "freeyt://dashboard/\(section)"
        } else {
            urlString = "freeyt://dashboard"
        }

        guard let url = URL(string: urlString) else {
            complete(context: context, payload: ["success": false, "error": "Invalid dashboard URL"])
            return
        }

        context.open(url) { [logger] success in
            logger.info("Open dashboard result: \(success)")
            self.complete(context: context, payload: ["success": success])
        }
    }

    private func decodeArray<T: Decodable>(_ type: T.Type, from value: Any?) -> T? {
        guard let value else { return nil }
        guard JSONSerialization.isValidJSONObject(value),
              let data = try? JSONSerialization.data(withJSONObject: value) else {
            return nil
        }
        return try? JSONDecoder().decode(type, from: data)
    }

    private func decodeDictionary(from value: Any?) -> [String: Int]? {
        guard let raw = value as? [String: Any] else { return nil }
        var result: [String: Int] = [:]
        for (key, value) in raw {
            if let intValue = value as? Int {
                result[key] = intValue
            } else if let doubleValue = value as? Double {
                result[key] = Int(doubleValue)
            }
        }
        return result
    }

    private func decodeDate(from value: Any?) -> Date? {
        if let value = value as? TimeInterval {
            return Date(timeIntervalSince1970: value)
        }
        if let value = value as? Double {
            return Date(timeIntervalSince1970: value)
        }
        if let value = value as? Int {
            return Date(timeIntervalSince1970: TimeInterval(value))
        }
        return nil
    }
}
