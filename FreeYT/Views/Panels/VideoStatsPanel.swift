import SwiftUI
import Charts

struct VideoStatsPanel: View {
    let snapshot: DashboardSnapshot

    private struct ChartPoint: Identifiable {
        let id = UUID()
        let date: Date
        let value: Int
    }

    var body: some View {
        VStack(alignment: .leading, spacing: 18) {
            HStack(alignment: .top) {
                VStack(alignment: .leading, spacing: 6) {
                    Text("Recent protection")
                        .font(.system(size: 19, weight: .semibold))
                        .foregroundStyle(LiquidGlassTheme.adaptiveText)
                    Text("FreeYT now shows both the trend and the latest privacy-safe routes.")
                        .font(.system(size: 14, weight: .medium))
                        .foregroundStyle(LiquidGlassTheme.adaptiveSecondaryText)
                }
                Spacer()
                Pill(text: "\(snapshot.weekCount) this week", icon: "chart.bar.fill")
            }

            if snapshot.weekCount == 0 {
                emptyState
            } else {
                Chart(chartPoints) { point in
                    BarMark(
                        x: .value("Day", point.date, unit: .day),
                        y: .value("Protected", point.value)
                    )
                    .clipShape(RoundedRectangle(cornerRadius: 6, style: .continuous))
                    .foregroundStyle(LiquidGlassTheme.accent.gradient)
                }
                .frame(height: 160)
                .chartXAxis {
                    AxisMarks(values: .stride(by: .day)) { value in
                        AxisValueLabel(format: .dateTime.weekday(.narrow))
                    }
                }
                .chartYAxis {
                    AxisMarks(position: .leading)
                }

                VStack(alignment: .leading, spacing: 10) {
                    Text("Latest protected routes")
                        .font(.system(size: 15, weight: .semibold))

                    ForEach(snapshot.recentActivity.prefix(5)) { activity in
                        HStack(alignment: .top, spacing: 12) {
                            Circle()
                                .fill(LiquidGlassTheme.accent.opacity(0.22))
                                .frame(width: 34, height: 34)
                                .overlay(
                                    Image(systemName: icon(for: activity.kind))
                                        .font(.system(size: 14, weight: .semibold))
                                        .foregroundStyle(LiquidGlassTheme.accentStrong)
                                )

                            VStack(alignment: .leading, spacing: 3) {
                                Text(activity.title)
                                    .font(.system(size: 14, weight: .semibold))
                                    .foregroundStyle(LiquidGlassTheme.adaptiveText)
                                Text(activity.subtitle)
                                    .font(.system(size: 12, weight: .medium))
                                    .foregroundStyle(LiquidGlassTheme.adaptiveSecondaryText)
                            }

                            Spacer()

                            Text(activity.timestamp.formatted(.relative(presentation: .named)))
                                .font(.system(size: 11, weight: .medium))
                                .foregroundStyle(LiquidGlassTheme.adaptiveMutedText)
                        }
                        .glassCard(radius: 16, tint: LiquidGlassTheme.accent.opacity(0.08), padding: 12)
                    }
                }
            }
        }
        .glassCard()
    }

    private var emptyState: some View {
        VStack(alignment: .leading, spacing: 10) {
            Text("No protected sessions yet.")
                .font(.system(size: 17, weight: .semibold))
                .foregroundStyle(LiquidGlassTheme.adaptiveText)
            Text("Once FreeYT routes your first YouTube link, the activity trend and latest routes will appear here.")
                .font(.system(size: 14, weight: .medium))
                .foregroundStyle(LiquidGlassTheme.adaptiveSecondaryText)
        }
        .glassCard(radius: 18, tint: LiquidGlassTheme.info.opacity(0.08), padding: 18)
    }

    private var chartPoints: [ChartPoint] {
        let calendar = Calendar.current
        return (0..<7).compactMap { offset in
            guard let date = calendar.date(byAdding: .day, value: -6 + offset, to: Date()) else {
                return nil
            }
            let key = DashboardSnapshot.dateKey(for: date)
            return ChartPoint(date: date, value: snapshot.dailyCounts[key] ?? 0)
        }
    }

    private func icon(for kind: RedirectActivity.Kind) -> String {
        switch kind {
        case .watch:
            return "play.rectangle.fill"
        case .shorts:
            return "bolt.fill"
        case .live:
            return "dot.radiowaves.left.and.right"
        case .embed:
            return "rectangle.on.rectangle"
        case .shortLink:
            return "link"
        case .legacy:
            return "film.stack"
        case .unknown:
            return "play.fill"
        }
    }
}
