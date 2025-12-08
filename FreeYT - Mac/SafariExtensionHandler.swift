//
//  SafariExtensionHandler.swift
//  FreeYT - Mac
//
//  Native Safari App Extension handler presenting a Liquid Glass popover.
//

import SafariServices

@available(macOS 15.0, *)
final class SafariExtensionHandler: SFSafariExtensionHandler {

    override func toolbarItemClicked(in window: SFSafariWindow) {
        window.getToolbarItem { item in
            item?.popover = SafariExtensionViewController.shared
            item?.showPopover()
        }
    }

    override func validateToolbarItem(in window: SFSafariWindow, validationHandler: @escaping ((Bool, String) -> Void)) {
        validationHandler(true, "")
    }
}
