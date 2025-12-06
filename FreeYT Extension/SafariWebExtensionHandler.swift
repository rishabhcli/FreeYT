//
//  SafariWebExtensionHandler.swift
//  FreeYT Extension
//
//  This project uses a Safari Web Extension (Manifest V3) with JavaScript-based
//  background/content scripts and declarativeNetRequest rules. The legacy
//  Safari App Extension APIs (SFSafariWebExtensionHandler, SFSafariWindow,
//  SFSafariPage) are not used and are unavailable in this target.
//
//  This stub exists to avoid build errors if Xcode created this file during
//  template generation. It intentionally contains no references to SFSafari* types.
//

import Foundation

/// Minimal principal class so Safari can instantiate the extension bundle.
/// All runtime behavior lives in the web extension resources (manifest, rules,
/// background.js, popup files), but Safari still requires a principal class
/// that conforms to `NSExtensionRequestHandling`.
@objc class SafariWebExtensionHandler: NSObject, NSExtensionRequestHandling {
    func beginRequest(with context: NSExtensionContext) {
        // We do not exchange messages with the native host, so immediately
        // finish the request to keep Safari happy.
        context.completeRequest(returningItems: nil, completionHandler: nil)
    }
}
