import SwiftUI

enum SidebarSection: String, CaseIterable, Identifiable, Hashable {
    case status
    case statistics
    case setup
    case support
    case about

    var id: String { rawValue }

    var title: String {
        switch self {
        case .status:     return "Protection"
        case .statistics: return "Statistics"
        case .setup:      return "Setup"
        case .support:    return "Support"
        case .about:      return "About"
        }
    }

    var subtitle: String {
        switch self {
        case .status:     return "Extension status & toggle"
        case .statistics: return "Ad-free video count"
        case .setup:      return "Enable in Safari"
        case .support:    return "Refresh & diagnostics"
        case .about:      return "FreeYT info"
        }
    }

    var icon: String {
        switch self {
        case .status:     return "shield.checkered"
        case .statistics: return "chart.bar.fill"
        case .setup:      return "gearshape.2.fill"
        case .support:    return "wrench.and.screwdriver.fill"
        case .about:      return "info.circle.fill"
        }
    }
}
