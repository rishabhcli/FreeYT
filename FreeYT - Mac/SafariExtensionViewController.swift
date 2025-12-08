//
//  SafariExtensionViewController.swift
//  FreeYT - Mac
//
//  Hosts the native Liquid Glass SwiftUI popover for the toolbar item.
//

import SafariServices
import SwiftUI

@available(macOS 15.0, *)
final class SafariExtensionViewController: SFSafariExtensionViewController {
    static let shared = SafariExtensionViewController()

    private var enabledState = true

    override init() {
        super.init(nibName: nil, bundle: nil)
        preferredContentSize = NSSize(width: 340, height: 260)

        let root = NativePopoverView(
            isEnabled: Binding(
                get: { self.enabledState },
                set: { newValue in
                    self.enabledState = newValue
                    // TODO: bridge to Web Extension background to update rules
                }
            ),
            statusText: { self.enabledState ? "Shield active" : "Shield paused" },
            onToggle: { newValue in
                self.enabledState = newValue
                // TODO: bridge to Web Extension background to update rules
            },
            onOpenSettings: {
                let extID = Bundle.main.bundleIdentifier ?? "com.freeyt.app.extension"
                SFSafariApplication.showPreferencesForExtension(withIdentifier: extID) { _ in }
            }
        )

        let host = NSHostingController(rootView: root)
        view = host.view
    }

    @available(*, unavailable)
    required init?(coder: NSCoder) { fatalError("init(coder:) has not been implemented") }
}
