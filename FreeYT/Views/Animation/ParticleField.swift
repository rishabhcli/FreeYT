import SwiftUI

struct Particle: Identifiable {
    let id = UUID()
    let base: CGPoint // normalized position (0...1)
    let radius: CGFloat
    let size: CGFloat
    let speed: Double
    let color: Color
}

/// Ambient particle glow field to add premium motion without interaction cost
struct ParticleField: View {
    let count: Int
    @State private var particles: [Particle] = []

    init(count: Int = 18) {
        self.count = count
    }

    private static func generateParticles(count: Int) -> [Particle] {
        (0..<count).map { _ in
            Particle(
                base: CGPoint(x: .random(in: 0.05...0.95), y: .random(in: 0.05...0.95)),
                radius: .random(in: 40...120),
                size: .random(in: 10...26),
                speed: .random(in: 0.3...0.9),
                color: Color.white.opacity(.random(in: 0.2...0.5))
            )
        }
    }

    var body: some View {
        TimelineView(.animation) { timeline in
            let time = timeline.date.timeIntervalSinceReferenceDate
            Canvas { context, size in
                for particle in particles {
                    let angle = time * particle.speed
                    let x = particle.base.x * size.width + cos(angle) * particle.radius
                    let y = particle.base.y * size.height + sin(angle * 0.9) * particle.radius
                    let rect = CGRect(x: x, y: y, width: particle.size, height: particle.size)

                    var bubble = context
                    bubble.addFilter(.blur(radius: particle.size * 0.4))
                    bubble.fill(
                        Path(ellipseIn: rect),
                        with: .radialGradient(
                            Gradient(colors: [
                                particle.color.opacity(0.9),
                                particle.color.opacity(0.05)
                            ]),
                            center: CGPoint(x: rect.midX, y: rect.midY),
                            startRadius: 0,
                            endRadius: particle.size * 0.8
                        )
                    )
                }
            }
        }
        .onAppear {
            if particles.isEmpty {
                particles = Self.generateParticles(count: count)
            }
        }
    }
}
