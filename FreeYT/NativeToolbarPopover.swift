//
//  NativeToolbarPopover.swift
//  FreeYT
//
//  Native Liquid Glass popover for Safari toolbar (iOS 26+ only).
//  Note: Safari Web Extension popups are HTML-based. To show this view,
//  migrate to a Safari App Extension / native popover target and present
//  this SwiftUI view instead of the HTML popup.
//

import SwiftUI
import SafariServices

@available(iOS 26.0, *)
struct NativeToolbarPopover: View {
    @Binding var isEnabled: Bool
    let statusText: String
    let onToggle: (Bool) -> Void
    let onOpenSettings: () -> Void

    @Namespace private var glassSpace

    var body: some View {
        GlassEffectContainer(spacing: 14) {
            VStack(spacing: 14) {
                header
                statusCard
                actionButtons
            }
            .padding(16)
            .glassBackgroundEffect(.automatic)
        }
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
                .glassEffect()
                .glassEffectID("icon", in: glassSpace)

            VStack(alignment: .leading, spacing: 2) {
                Text("FreeYT")
                    .font(.system(size: 18, weight: .semibold, design: .rounded))
                    .glassEffect()
                    .glassEffectID("title", in: glassSpace)
                Text("Safari taskbar · No-cookie redirect")
                    .font(.footnote)
                    .foregroundStyle(.secondary)
            }

            Spacer()
        }
        .glassEffectUnion(id: "header", namespace: glassSpace)
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
                .glassEffect()
                .glassEffectID("badge", in: glassSpace)

            VStack(alignment: .leading, spacing: 4) {
                Text(statusText)
                    .font(.system(size: 16, weight: .semibold))
                    .glassEffectID("headline", in: glassSpace)
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
            .glassEffect()
            .glassEffectID("toggle", in: glassSpace)
            .frame(width: 72)
        }
        .glassEffectUnion(id: "status", namespace: glassSpace)
        .padding(14)
        .glassBackgroundEffect(.automatic)
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
            .glassEffect()
            .glassEffectID("primary", in: glassSpace)

            Button {
                onOpenSettings()
            } label: {
                Label("Safari Settings", systemImage: "safari")
            }
            .buttonStyle(.bordered)
            .glassEffect()
            .glassEffectID("settings", in: glassSpace)
        }
        .glassEffectUnion(id: "actions", namespace: glassSpace)
    }
}

struct NativeToolbarPopover_Previews: PreviewProvider {
    @State static var enabled = true

    static var previews: some View {
        if #available(iOS 26.0, *) {
            NativeToolbarPopover(
                isEnabled: $enabled,
                statusText: "Shield active",
                onToggle: { enabled = $0 },
                onOpenSettings: {}
            )
            .preferredColorScheme(.dark)
        } else {
            Text("iOS 26+ required for Liquid Glass preview.")
        }
    }
}
