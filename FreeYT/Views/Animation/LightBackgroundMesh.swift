import SwiftUI

/// Semi-transparent background for iOS 26
@available(iOS 26.0, *)
struct LightBackgroundMesh: View {
    var body: some View {
        ZStack {
            Color.clear

            LinearGradient(
                colors: [
                    Color.gray.opacity(0.04),
                    Color.gray.opacity(0.02)
                ],
                startPoint: .topLeading,
                endPoint: .bottomTrailing
            )
        }
    }
}
