import SwiftUI

struct LiquidToggle: View {
    let binding: Binding<Bool>
    @Environment(\.accessibilityReduceTransparency) private var reduceTransparency

    var body: some View {
        toggleBody
    }

    @ViewBuilder
    private var toggleBody: some View {
        if #available(iOS 26.0, macOS 26.0, *) {
            Toggle(isOn: binding) {
                Text(binding.wrappedValue ? "On" : "Off")
                    .font(.system(size: 12, weight: .semibold))
                    .foregroundColor(LiquidGlassTheme.adaptiveText.opacity(0.8))
            }
            .toggleStyle(.switch)
            .tint(LiquidGlassTheme.success)
            .glassEffect(
                reduceTransparency ? .identity : .regular.interactive(),
                in: .capsule
            )
            .accessibilityLabel("FreeYT Shield toggle")
            #if os(iOS)
            .onChange(of: binding.wrappedValue) { _, _ in Haptics.light() }
            #endif
        } else {
            Toggle(isOn: binding) {
                Text(binding.wrappedValue ? "On" : "Off")
                    .font(.system(size: 12, weight: .semibold))
                    .foregroundColor(.white.opacity(0.8))
            }
            .toggleStyle(.switch)
            .tint(LiquidGlassTheme.success)
            .accessibilityLabel("FreeYT Shield toggle")
            #if os(iOS)
            .onChange(of: binding.wrappedValue) { _, _ in Haptics.light() }
            #endif
        }
    }
}
