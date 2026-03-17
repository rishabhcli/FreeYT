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
    private let store: DashboardStore

    @MainActor
    init(store: DashboardStore) {
        self.store = store
        super.init(rootView: LiquidGlassView(store: store))
        setupAppearance()
    }

    @objc required dynamic init?(coder aDecoder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }

    private func setupAppearance() {
        view.backgroundColor = .clear
        view.isOpaque = false
    }

    override func viewWillAppear(_ animated: Bool) {
        super.viewWillAppear(animated)
        store.refresh()
    }

    override var preferredStatusBarStyle: UIStatusBarStyle {
        .default
    }
}
