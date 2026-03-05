import SwiftUI

struct BackgroundGlow: View {
    var body: some View {
        TimelineView(.animation) { timeline in
            let time = timeline.date.timeIntervalSinceReferenceDate
            Canvas { context, size in
                // Clean dark base gradient
                let gradient = Gradient(colors: [
                    Color(red: 0.05, green: 0.05, blue: 0.08),
                    Color(red: 0.08, green: 0.08, blue: 0.12),
                    Color(red: 0.06, green: 0.06, blue: 0.10)
                ])
                context.fill(
                    Path(CGRect(origin: .zero, size: size)),
                    with: .linearGradient(
                        gradient,
                        startPoint: CGPoint(x: 0, y: 0),
                        endPoint: CGPoint(x: size.width, y: size.height)
                    )
                )

                // Subtle monochrome animated blobs
                func drawBlob(color: Color, base: CGPoint, radius: CGFloat, t: Double, speed: Double) {
                    let x = base.x + cos(t * speed) * radius * 0.25
                    let y = base.y + sin(t * speed * 0.9) * radius * 0.3
                    let rect = CGRect(x: x, y: y, width: radius, height: radius)
                    context.addFilter(.blur(radius: radius * 0.4))
                    context.fill(
                        Path(ellipseIn: rect),
                        with: .radialGradient(
                            Gradient(colors: [color.opacity(0.18), color.opacity(0.02)]),
                            center: CGPoint(x: rect.midX, y: rect.midY),
                            startRadius: 0,
                            endRadius: radius * 0.6
                        )
                    )
                }

                drawBlob(color: .white, base: CGPoint(x: size.width * 0.2, y: size.height * 0.15), radius: 240, t: time, speed: 0.35)
                drawBlob(color: .gray, base: CGPoint(x: size.width * 0.8, y: size.height * 0.2), radius: 260, t: time, speed: 0.28)
                drawBlob(color: .white, base: CGPoint(x: size.width * 0.5, y: size.height * 0.8), radius: 280, t: time, speed: 0.32)
            }
        }
    }
}
