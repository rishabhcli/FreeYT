//
//  SceneDelegate.swift
//  FreeYT
//
//  Created by Rishabh Bansal on 10/19/25.
//

import UIKit
import SwiftUI

class SceneDelegate: UIResponder, UIWindowSceneDelegate {

    var window: UIWindow?

    func scene(_ scene: UIScene, willConnectTo session: UISceneSession, options connectionOptions: UIScene.ConnectionOptions) {
        guard let windowScene = (scene as? UIWindowScene) else { return }
        let window = UIWindow(windowScene: windowScene)

        if UserDefaults.standard.bool(forKey: "onboardingCompleted") {
            window.rootViewController = LiquidGlassHostingController()
        } else {
            let onboardingView = OnboardingView {
                let transition = CATransition()
                transition.type = .fade
                transition.duration = 0.3
                window.layer.add(transition, forKey: kCATransition)
                window.rootViewController = LiquidGlassHostingController()
            }
            window.rootViewController = UIHostingController(rootView: onboardingView)
        }

        self.window = window
        window.makeKeyAndVisible()
    }
}
