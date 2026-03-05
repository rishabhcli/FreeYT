import SwiftUI

@available(iOS 26.0, *)
struct SidebarRow: View {
    let section: SidebarSection
    let isEnabled: Bool
    let videoCount: Int

    var body: some View {
        HStack(spacing: 14) {
            Image(systemName: section.icon)
                .font(.system(size: 20, weight: .semibold))
                .foregroundStyle(iconColor)
                .frame(width: 32, height: 32)

            VStack(alignment: .leading, spacing: 2) {
                Text(section.title)
                    .font(.system(size: 16, weight: .semibold))

                Text(liveSubtitle)
                    .font(.system(size: 13))
                    .foregroundStyle(.secondary)
            }

            Spacer()

            if section == .status {
                Circle()
                    .fill(isEnabled ? Color.green : Color.orange)
                    .frame(width: 10, height: 10)
            }

            if section == .statistics {
                Text("\(videoCount)")
                    .font(.system(size: 14, weight: .bold, design: .rounded))
                    .foregroundStyle(.secondary)
            }
        }
        .padding(.vertical, 4)
    }

    private var iconColor: Color {
        switch section {
        case .status:     return isEnabled ? .green : .orange
        case .statistics: return .blue
        case .setup:      return .gray
        case .support:    return .gray
        case .about:      return .gray
        }
    }

    private var liveSubtitle: String {
        switch section {
        case .status:
            return isEnabled ? "Shield active" : "Shield paused"
        case .statistics:
            return videoCount == 1 ? "1 video ad-free" : "\(videoCount) videos ad-free"
        default:
            return section.subtitle
        }
    }
}
