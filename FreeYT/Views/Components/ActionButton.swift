import SwiftUI

struct ActionButton: View {
    let isEnabled: Bool
    let openSettings: () -> Void
    @State private var isPressed = false
    @Environment(\.accessibilityReduceTransparency) private var reduceTransparency

    var body: some View {
        buttonContent
    }

    @ViewBuilder
    private var buttonContent: some View {
        if #available(iOS 26.0, *) {
            Button(action: openSettings) {
                HStack(spacing: 10) {
                    Image(systemName: isEnabled ? "checkmark.circle.fill" : "safari")
                        .font(.system(size: 18, weight: .semibold))
                    Text(isEnabled ? "Extension active" : "Open Safari Settings")
                        .font(.system(size: 17, weight: .semibold))
                }
                .frame(maxWidth: .infinity)
                .frame(height: 58)
            }
            .buttonStyle(.glassProminent)
            .disabled(isEnabled)
        } else {
            Button(action: openSettings) {
                HStack(spacing: 10) {
                    Image(systemName: isEnabled ? "checkmark.circle.fill" : "safari")
                        .font(.system(size: 18, weight: .semibold))
                    Text(isEnabled ? "Extension active" : "Open Safari Settings")
                        .font(.system(size: 17, weight: .semibold))
                }
                .foregroundColor(.white)
                .frame(maxWidth: .infinity)
                .frame(height: 58)
                .background(
                    Capsule(style: .continuous)
                        .fill(Color.white.opacity(isEnabled ? 0.08 : 0.15))
                        .overlay(
                            Capsule(style: .continuous)
                                .strokeBorder(Color.white.opacity(0.2), lineWidth: 1.2)
                        )
                        .shadow(color: Color.black.opacity(0.25), radius: 18, x: 0, y: 10)
                )
                .scaleEffect(isPressed ? 0.97 : 1)
                .animation(.spring(response: 0.28, dampingFraction: 0.7), value: isPressed)
            }
            .disabled(isEnabled)
            .simultaneousGesture(
                DragGesture(minimumDistance: 0)
                    .onChanged { _ in isPressed = true }
                    .onEnded { _ in isPressed = false; Haptics.light() }
            )
        }
    }
}
