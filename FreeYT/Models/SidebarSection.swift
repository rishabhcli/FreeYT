import SwiftUI

enum SidebarSection: String, CaseIterable, Identifiable, Hashable {
    case overview
    case activity
    case exceptions
    case trust
    case setup

    var id: String { rawValue }

    var title: String {
        switch self {
        case .overview:
            return "Overview"
        case .activity:
            return "Activity"
        case .exceptions:
            return "Exceptions"
        case .trust:
            return "Trust"
        case .setup:
            return "Setup"
        }
    }

    var subtitle: String {
        switch self {
        case .overview:
            return "Status, sync, and quick actions"
        case .activity:
            return "Recent protection and trends"
        case .exceptions:
            return "Trusted sites that stay on YouTube"
        case .trust:
            return "Local processing and permissions"
        case .setup:
            return "Enable, verify, and troubleshoot"
        }
    }

    var icon: String {
        switch self {
        case .overview:
            return "shield.lefthalf.filled"
        case .activity:
            return "chart.xyaxis.line"
        case .exceptions:
            return "slider.horizontal.3"
        case .trust:
            return "lock.shield"
        case .setup:
            return "sparkles.rectangle.stack"
        }
    }
}
