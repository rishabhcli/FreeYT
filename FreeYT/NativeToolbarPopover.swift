//
//  NativeToolbarPopover.swift
//  FreeYT
//
//  Native popover for Safari toolbar.
//  Note: Safari Web Extension popups are HTML-based. To show this view,
//  migrate to a Safari App Extension / native popover target and present
//  this SwiftUI view instead of the HTML popup.
//

import SwiftUI
import SafariServices

@available(iOS 15.0, *)
struct NativeToolbarPopover: View {
    @Binding var isEnabled: Bool
    let statusText: String
    let onToggle: (Bool) -> Void
    let onOpenSettings: () -> Void

    var body: some View {
        VStack(spacing: 14) {
            header
            statusCard
            actionButtons
        }
        .padding(16)
        .frame(width: 340)
        .padding(12)
    }

    private var header: some View {
        HStack(spacing: 12) {
            Image("LargeIcon")
                .resizable()
                .scaledToFit()
                .frame(width: 42, height: 42)
                .clipShape(RoundedRectangle(cornerRadius: 12, style: .continuous))

            VStack(alignment: .leading, spacing: 2) {
                Text("FreeYT")
                    .font(.system(size: 18, weight: .semibold, design: .rounded))
                Text("Safari taskbar · No-cookie redirect")
                    .font(.footnote)
                    .foregroundStyle(.secondary)
            }

            Spacer()
        }
    }

    private var statusCard: some View {
        HStack(spacing: 12) {
            Circle()
                .fill(.quaternary)
                .frame(width: 44, height: 44)
                .overlay(
                    Image(systemName: isEnabled ? "checkmark.circle.fill" : "exclamationmark.circle.fill")
                        .font(.system(size: 24, weight: .semibold))
                        .foregroundStyle(isEnabled ? .green : .orange)
                )

            VStack(alignment: .leading, spacing: 4) {
                Text(statusText)
                    .font(.system(size: 16, weight: .semibold))
                Text(isEnabled ? "Redirecting to youtube-nocookie.com" : "Enable in Safari Extensions")
                    .font(.footnote)
                    .foregroundStyle(.secondary)
            }

            Spacer(minLength: 8)

            Toggle(isOn: Binding(get: { isEnabled }, set: { onToggle($0) })) {
                EmptyView()
            }
            .toggleStyle(.switch)
            .tint(.green)
            .frame(width: 72)
        }
        .padding(14)
        .background(.regularMaterial, in: RoundedRectangle(cornerRadius: 12, style: .continuous))
    }

    private var actionButtons: some View {
        HStack(spacing: 10) {
            Button {
                onToggle(!isEnabled)
            } label: {
                Label(isEnabled ? "Turn Off" : "Turn On", systemImage: isEnabled ? "pause.fill" : "play.fill")
            }
            .buttonStyle(.borderedProminent)
            .tint(isEnabled ? .orange : .green)

            Button {
                onOpenSettings()
            } label: {
                Label("Safari Settings", systemImage: "safari")
            }
            .buttonStyle(.bordered)
        }
    }
}

struct NativeToolbarPopover_Previews: PreviewProvider {
    @State static var enabled = true

    static var previews: some View {
        if #available(iOS 15.0, *) {
            NativeToolbarPopover(
                isEnabled: $enabled,
                statusText: "Shield active",
                onToggle: { enabled = $0 },
                onOpenSettings: {}
            )
            .preferredColorScheme(.dark)
        } else {
            Text("iOS 15+ required for preview.")
        }
    }
}
