import SwiftUI

struct BackgroundGlow: View {
    @Environment(\.colorScheme) private var colorScheme

    var body: some View {
        TimelineView(.animation) { timeline in
            let time = timeline.date.timeIntervalSinceReferenceDate

            Canvas { context, size in
                context.fill(
                    Path(CGRect(origin: .zero, size: size)),
                    with: .linearGradient(
                        Gradient(colors: baseColors),
                        startPoint: .zero,
                        endPoint: CGPoint(x: size.width, y: size.height)
                    )
                )

                drawBlob(
                    context: context,
                    color: LiquidGlassTheme.accent,
                    base: CGPoint(x: size.width * 0.18, y: size.height * 0.16),
                    radius: 260,
                    time: time,
                    speed: 0.35
                )

                drawBlob(
                    context: context,
                    color: LiquidGlassTheme.info,
                    base: CGPoint(x: size.width * 0.82, y: size.height * 0.18),
                    radius: 240,
                    time: time,
                    speed: 0.28
                )

                drawBlob(
                    context: context,
                    color: Color.white,
                    base: CGPoint(x: size.width * 0.5, y: size.height * 0.84),
                    radius: 320,
                    time: time,
                    speed: 0.22
                )
            }
        }
    }

    private var baseColors: [Color] {
        if colorScheme == .dark {
            return [
                Color(red: 0.05, green: 0.08, blue: 0.06),
                Color(red: 0.07, green: 0.10, blue: 0.08),
                Color(red: 0.04, green: 0.05, blue: 0.06)
            ]
        }

        return [
            Color(red: 0.95, green: 0.97, blue: 0.95),
            Color(red: 0.91, green: 0.95, blue: 0.93),
            Color(red: 0.96, green: 0.97, blue: 0.99)
        ]
    }

    private func drawBlob(context: GraphicsContext, color: Color, base: CGPoint, radius: CGFloat, time: Double, speed: Double) {
        let x = base.x + cos(time * speed) * radius * 0.22
        let y = base.y + sin(time * speed * 0.9) * radius * 0.26
        let rect = CGRect(x: x, y: y, width: radius, height: radius)

        var glow = context
        glow.addFilter(.blur(radius: radius * 0.36))
        glow.fill(
            Path(ellipseIn: rect),
            with: .radialGradient(
                Gradient(colors: [color.opacity(colorScheme == .dark ? 0.18 : 0.11), color.opacity(0.01)]),
                center: CGPoint(x: rect.midX, y: rect.midY),
                startRadius: 0,
                endRadius: radius * 0.62
            )
        )
    }
}
