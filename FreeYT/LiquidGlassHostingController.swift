//
//  LiquidGlassHostingController.swift
//  FreeYT
//
//  Created by Claude Code
//  SwiftUI Hosting Controller for Liquid Glass View
//

import UIKit
import SwiftUI

/// UIHostingController to bridge SwiftUI LiquidGlassView with UIKit app lifecycle
final class LiquidGlassHostingController: UIHostingController<LiquidGlassView> {

    init() {
        super.init(rootView: LiquidGlassView())
        setupAppearance()
    }

    @objc required dynamic init?(coder aDecoder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }

    private func setupAppearance() {
        if #available(iOS 26.0, *) {
            // Let system manage background and navigation chrome for Liquid Glass
            view.backgroundColor = .systemBackground
        } else {
            // Hide navigation bar for seamless glass effect on older iOS
            navigationController?.navigationBar.isHidden = true
            // Force dark mode for optimal glass effect visibility
            overrideUserInterfaceStyle = .dark
            view.backgroundColor = .clear
        }
    }

    override func viewWillAppear(_ animated: Bool) {
        super.viewWillAppear(animated)

        if #available(iOS 26.0, *) {
            // NavigationSplitView handles its own nav bar
        } else {
            navigationController?.setNavigationBarHidden(true, animated: animated)
        }
    }

    override var preferredStatusBarStyle: UIStatusBarStyle {
        if #available(iOS 26.0, *) {
            return .default
        } else {
            return .lightContent
        }
    }
}
