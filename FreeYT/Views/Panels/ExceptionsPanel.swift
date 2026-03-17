import SwiftUI

struct ExceptionsPanel: View {
    let snapshot: DashboardSnapshot
    let onAdd: (String) -> String?
    let onRemove: (String) -> Void

    @State private var draft = ""
    @State private var errorMessage: String?

    var body: some View {
        VStack(alignment: .leading, spacing: 18) {
            HStack(alignment: .top) {
                VStack(alignment: .leading, spacing: 6) {
                    Text("Trusted site exceptions")
                        .font(.system(size: 19, weight: .semibold))
                    Text("Exceptions let specific domains stay on YouTube instead of routing through privacy-enhanced embeds.")
                        .font(.system(size: 14, weight: .medium))
                        .foregroundStyle(LiquidGlassTheme.adaptiveSecondaryText)
                }
                Spacer()
                Pill(text: snapshot.exceptions.isEmpty ? "No exceptions" : "\(snapshot.exceptions.count) saved", icon: "slider.horizontal.3")
            }

            HStack(spacing: 10) {
                TextField("music.youtube.com", text: $draft)
                    .textInputAutocapitalization(.never)
                    .autocorrectionDisabled()
                    .padding(.horizontal, 14)
                    .padding(.vertical, 12)
                    .background(inputBackground)

                Button(action: addException) {
                    Text("Add")
                        .font(.system(size: 15, weight: .semibold))
                        .padding(.horizontal, 18)
                        .padding(.vertical, 12)
                }
                .liquidButton(prominent: true, tint: LiquidGlassTheme.accentStrong)
            }

            if let errorMessage {
                Text(errorMessage)
                    .font(.system(size: 12, weight: .medium))
                    .foregroundStyle(.red)
            }

            if snapshot.sortedExceptions.isEmpty {
                emptyState
            } else {
                VStack(spacing: 10) {
                    ForEach(snapshot.sortedExceptions, id: \.self) { domain in
                        HStack(spacing: 12) {
                            VStack(alignment: .leading, spacing: 3) {
                                Text(domain)
                                    .font(.system(size: 14, weight: .semibold))
                                Text("Keep this domain on YouTube instead of routing through embeds.")
                                    .font(.system(size: 12, weight: .medium))
                                    .foregroundStyle(LiquidGlassTheme.adaptiveSecondaryText)
                            }

                            Spacer()

                            Button(role: .destructive) {
                                onRemove(domain)
                            } label: {
                                Image(systemName: "minus.circle.fill")
                                    .font(.system(size: 18, weight: .semibold))
                            }
                            .liquidButton(tint: .red)
                        }
                        .glassCard(radius: 18, tint: LiquidGlassTheme.accent.opacity(0.08), padding: 14)
                    }
                }
            }
        }
        .glassCard()
    }

    @ViewBuilder
    private var inputBackground: some View {
        if #available(iOS 26.0, macOS 26.0, *) {
            RoundedRectangle(cornerRadius: 16, style: .continuous)
                .fill(.clear)
                .glassEffect(.clear.tint(LiquidGlassTheme.glassHighlight), in: RoundedRectangle(cornerRadius: 16, style: .continuous))
        } else {
            RoundedRectangle(cornerRadius: 16, style: .continuous)
                .fill(Color.primary.opacity(0.05))
        }
    }

    private var emptyState: some View {
        VStack(alignment: .leading, spacing: 8) {
            Text("No trusted exceptions yet.")
                .font(.system(size: 16, weight: .semibold))
            Text("Most people can leave this empty. Add a site only when you need to stay on YouTube for that domain.")
                .font(.system(size: 13, weight: .medium))
                .foregroundStyle(LiquidGlassTheme.adaptiveSecondaryText)
        }
        .glassCard(radius: 18, tint: LiquidGlassTheme.info.opacity(0.08), padding: 16)
    }

    private func addException() {
        errorMessage = onAdd(draft)
        if errorMessage == nil {
            draft = ""
        }
    }
}
