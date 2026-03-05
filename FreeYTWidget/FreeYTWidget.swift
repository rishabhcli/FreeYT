import WidgetKit
import SwiftUI

struct VideoCountEntry: TimelineEntry {
    let date: Date
    let videoCount: Int
    let isEnabled: Bool
}

struct VideoCountProvider: TimelineProvider {
    func placeholder(in context: Context) -> VideoCountEntry {
        VideoCountEntry(date: .now, videoCount: 42, isEnabled: true)
    }

    func getSnapshot(in context: Context, completion: @escaping (VideoCountEntry) -> Void) {
        let entry = VideoCountEntry(
            date: .now,
            videoCount: SharedState.videoCount,
            isEnabled: SharedState.isEnabled
        )
        completion(entry)
    }

    func getTimeline(in context: Context, completion: @escaping (Timeline<VideoCountEntry>) -> Void) {
        let entry = VideoCountEntry(
            date: .now,
            videoCount: SharedState.videoCount,
            isEnabled: SharedState.isEnabled
        )
        let nextUpdate = Calendar.current.date(byAdding: .minute, value: 15, to: .now)!
        let timeline = Timeline(entries: [entry], policy: .after(nextUpdate))
        completion(timeline)
    }
}

struct SmallWidgetView: View {
    let entry: VideoCountEntry

    var body: some View {
        VStack(spacing: 8) {
            Image(systemName: "shield.checkered")
                .font(.system(size: 28, weight: .semibold))
                .foregroundColor(entry.isEnabled ? .green : .orange)

            Text("\(entry.videoCount)")
                .font(.system(size: 32, weight: .bold, design: .rounded))

            Text("Ad-free")
                .font(.system(size: 12, weight: .medium))
                .foregroundColor(.secondary)
        }
        .containerBackground(for: .widget) {
            Color.clear
        }
    }
}

struct MediumWidgetView: View {
    let entry: VideoCountEntry

    var body: some View {
        HStack(spacing: 16) {
            VStack(spacing: 8) {
                Image(systemName: "shield.checkered")
                    .font(.system(size: 32, weight: .semibold))
                    .foregroundColor(entry.isEnabled ? .green : .orange)

                Text("\(entry.videoCount)")
                    .font(.system(size: 36, weight: .bold, design: .rounded))
            }

            VStack(alignment: .leading, spacing: 6) {
                Text("FreeYT")
                    .font(.system(size: 18, weight: .bold, design: .rounded))

                Text("Videos redirected to privacy-safe embeds")
                    .font(.system(size: 13, weight: .medium))
                    .foregroundColor(.secondary)
                    .lineLimit(2)

                HStack(spacing: 4) {
                    Circle()
                        .fill(entry.isEnabled ? Color.green : Color.orange)
                        .frame(width: 8, height: 8)
                    Text(entry.isEnabled ? "Active" : "Paused")
                        .font(.system(size: 12, weight: .semibold))
                        .foregroundColor(.secondary)
                }
            }
        }
        .containerBackground(for: .widget) {
            Color.clear
        }
    }
}

@main
struct FreeYTWidget: Widget {
    let kind: String = "FreeYTWidget"

    var body: some WidgetConfiguration {
        StaticConfiguration(kind: kind, provider: VideoCountProvider()) { entry in
            if #available(iOS 17.0, *) {
                switch entry.date {
                default:
                    SmallWidgetView(entry: entry)
                }
            } else {
                SmallWidgetView(entry: entry)
            }
        }
        .configurationDisplayName("FreeYT Stats")
        .description("Shows your ad-free video count and protection status.")
        .supportedFamilies([.systemSmall, .systemMedium])
    }
}
