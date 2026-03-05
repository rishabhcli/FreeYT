//
//  SafariWebExtensionHandler.swift
//  FreeYT Extension
//
//  Native messaging bridge between the Safari Web Extension and the host app.
//  Handles bidirectional state sync via App Groups shared container.
//

import Foundation
import SafariServices
import os.log

/// Handles native messaging between the Safari Web Extension and the host app.
/// Uses App Groups to share state (enabled, video count) across processes.
class SafariWebExtensionHandler: NSObject, NSExtensionRequestHandling {

    private let logger = Logger(subsystem: "com.freeyt.app.extension", category: "NativeMessaging")

    func beginRequest(with context: NSExtensionContext) {
        // Extract the message from the extension
        guard let item = context.inputItems.first as? NSExtensionItem,
              let message = item.userInfo?[SFExtensionMessageKey] as? [String: Any] else {
            logger.debug("No message received, completing request")
            context.completeRequest(returningItems: nil, completionHandler: nil)
            return
        }

        logger.info("Received message: \(String(describing: message))")

        let response = NSExtensionItem()
        var responseData: [String: Any] = [:]

        // Handle different message actions
        let action = message["action"] as? String ?? ""

        switch action {
        case "getSharedState":
            // Return both enabled state and video count
            responseData["enabled"] = SharedState.isEnabled
            responseData["videoCount"] = SharedState.videoCount
            responseData["isAppGroupAvailable"] = SharedState.isAppGroupAvailable
            logger.info("Returning shared state: enabled=\(SharedState.isEnabled), count=\(SharedState.videoCount)")

        case "setEnabled":
            // Update the enabled state
            if let enabled = message["enabled"] as? Bool {
                SharedState.isEnabled = enabled
                responseData["success"] = true
                responseData["enabled"] = enabled
                logger.info("Set enabled state to: \(enabled)")
            } else {
                responseData["error"] = "Missing 'enabled' parameter"
                logger.error("setEnabled called without 'enabled' parameter")
            }

        case "incrementCount":
            // Increment the video watch counter
            SharedState.incrementVideoCount()
            responseData["videoCount"] = SharedState.videoCount
            responseData["success"] = true
            logger.info("Incremented video count to: \(SharedState.videoCount)")

        case "getVideoCount":
            // Return only the video count
            responseData["videoCount"] = SharedState.videoCount
            logger.info("Returning video count: \(SharedState.videoCount)")

        case "resetCount":
            // Reset the video counter (for debugging/testing)
            SharedState.resetVideoCount()
            responseData["videoCount"] = 0
            responseData["success"] = true
            logger.info("Reset video count to 0")

        case "getDailyStats":
            // Return daily redirect counts for the last 7 days
            let counts = SharedState.dailyCounts(for: 7)
            responseData["dailyCounts"] = counts
            responseData["success"] = true
            logger.info("Returning daily stats for 7 days")

        case "ping":
            // Simple ping for connectivity testing
            responseData["pong"] = true
            responseData["timestamp"] = Date().timeIntervalSince1970
            logger.debug("Ping received, responding with pong")

        default:
            responseData["error"] = "Unknown action: \(action)"
            logger.warning("Unknown action received: \(action)")
        }

        // Send the response back to the extension
        response.userInfo = [SFExtensionMessageKey: responseData]
        context.completeRequest(returningItems: [response], completionHandler: nil)
    }
}
