import Foundation

enum DashboardRoute: String, CaseIterable, Hashable {
    case overview
    case activity
    case exceptions
    case trust
    case setup

    init(rawRouteValue: String?) {
        self = DashboardRoute(rawValue: rawRouteValue?.lowercased() ?? "") ?? .overview
    }

    init(url: URL) {
        let routeValue = url.pathComponents.dropFirst().first ?? url.host
        self.init(rawRouteValue: routeValue)
    }

    var section: SidebarSection {
        SidebarSection(rawValue: rawValue) ?? .overview
    }
}
