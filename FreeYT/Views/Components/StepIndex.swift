import SwiftUI

struct StepIndex: View {
    let number: Int

    var body: some View {
        stepIndexContent
    }

    @ViewBuilder
    private var stepIndexContent: some View {
        if #available(iOS 26.0, macOS 26.0, *) {
            Text("\(number)")
                .font(.system(size: 13, weight: .bold))
                .foregroundColor(LiquidGlassTheme.adaptiveText)
                .frame(width: 28, height: 28)
                .glassEffect(.regular, in: .circle)
        } else {
            ZStack {
                Circle()
                    .fill(Color.white.opacity(0.12))
                    .frame(width: 28, height: 28)
                    .overlay(
                        Circle()
                            .strokeBorder(Color.white.opacity(0.2), lineWidth: 1)
                    )

                Text("\(number)")
                    .font(.system(size: 13, weight: .bold))
                    .foregroundColor(.white)
            }
        }
    }
}
