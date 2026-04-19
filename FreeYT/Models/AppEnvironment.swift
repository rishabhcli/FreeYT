import Foundation
import UIKit

enum AppPreferences {
    static let onboardingCompletedKey = "onboardingCompleted"

    static func isOnboardingCompleted(in defaults: UserDefaults = .standard) -> Bool {
        defaults.bool(forKey: onboardingCompletedKey)
    }

    static func setOnboardingCompleted(_ completed: Bool, in defaults: UserDefaults = .standard) {
        defaults.set(completed, forKey: onboardingCompletedKey)
    }
}

enum SafariSettingsOpener {
    static let candidateURLs: [URL] = [
        URL(string: "App-Prefs:root=SAFARI&path=WEB_EXTENSIONS"),
        URL(string: "App-Prefs:root=SAFARI"),
        URL(string: UIApplication.openSettingsURLString)
    ].compactMap { $0 }

    static func firstAvailableURL(canOpen: (URL) -> Bool) -> URL? {
        candidateURLs.first(where: canOpen)
    }

    static func open(using application: UIApplication = .shared) {
        guard let url = firstAvailableURL(canOpen: application.canOpenURL) else {
            return
        }

        application.open(url, options: [:], completionHandler: nil)
    }
}
