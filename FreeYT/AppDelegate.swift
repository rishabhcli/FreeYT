//
//  AppDelegate.swift
//  FreeYT
//
//  Created by Rishabh Bansal on 10/19/25.
//

import UIKit
import SafariServices

@main
class AppDelegate: UIResponder, UIApplicationDelegate {

    var window: UIWindow?

    func application(_ application: UIApplication, didFinishLaunchingWithOptions launchOptions: [UIApplication.LaunchOptionsKey: Any]?) -> Bool {
        
        #if os(iOS) && !targetEnvironment(macCatalyst) && !targetEnvironment(simulator)
        if #available(iOS 15.0, *) {
            SFSafariWebExtensionManager.getStateOfSafariWebExtension(withIdentifier: ExtensionIdentifiers.safariExtensionBundleID) { state, error in
                if let error = error {
                    print("[FreeYT] Safari Web Extension state error:", error.localizedDescription)
                    return
                }
                guard let state = state else {
                    print("[FreeYT] Safari Web Extension state unavailable.")
                    return
                }
                if state.isEnabled {
                    print("[FreeYT] Web Extension is installed and enabled.")
                } else {
                    print("[FreeYT] Web Extension is installed but NOT enabled. Open Safari > Settings > Extensions to enable it.")
                }
            }
        }
        #endif
        
        return true
    }

    // MARK: UISceneSession Lifecycle

    func application(_ application: UIApplication, configurationForConnecting connectingSceneSession: UISceneSession, options: UIScene.ConnectionOptions) -> UISceneConfiguration {
        return UISceneConfiguration(name: "Default Configuration", sessionRole: connectingSceneSession.role)
    }

    func application(_ application: UIApplication, didDiscardSceneSessions sceneSessions: Set<UISceneSession>) {
        // Called when the user discards a scene session.
    }
}
