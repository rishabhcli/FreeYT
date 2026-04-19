//
//  LiquidGlassView.swift
//  FreeYT
//
//  Main dashboard UI
//

import SwiftUI

struct LiquidGlassView: View {
    @ObservedObject var store: DashboardStore
    @Environment(\.scenePhase) private var scenePhase
    @Namespace private var glassSpace

    init(store: DashboardStore) {
        self.store = store
    }

    var body: some View {
        NavigationSplitView {
            List(SidebarSection.allCases, selection: sectionBinding) { section in
                NavigationLink(value: section) {
                    SidebarRow(section: section, snapshot: store.snapshot)
                }
            }
            .listStyle(.sidebar)
            .navigationTitle("FreeYT")
            .scrollContentBackground(.hidden)
            .background(sidebarBackground)
        } detail: {
            ScrollView(showsIndicators: false) {
                GlassCluster(glassSpace: glassSpace) {
                    VStack(spacing: LiquidGlassTheme.sectionSpacing) {
                        detailContent
                    }
                    .glassTransitionIfAvailable()
                }
                .padding(.horizontal, LiquidGlassTheme.pagePadding)
                .padding(.top, 18)
                .padding(.bottom, 32)
            }
            .background(detailBackground.ignoresSafeArea())
            .navigationTitle(store.selectedSection.title)
        }
        .tint(LiquidGlassTheme.accentStrong)
        .onAppear { store.refresh() }
        .onChange(of: scenePhase) { _, newPhase in
            if newPhase == .active {
                store.refresh()
            }
        }
    }

    @ViewBuilder
    private var detailContent: some View {
        switch store.selectedSection {
        case .overview:
            HeroCard(snapshot: store.snapshot)
            StatusPanel(
                snapshot: store.snapshot,
                toggleBinding: Binding(
                    get: { store.snapshot.enabled },
                    set: { store.setProtectionEnabled($0) }
                ),
                openSettings: store.openSafariSettings
            )
            ActionButton(snapshot: store.snapshot, openSettings: store.openSafariSettings, onRefresh: store.refresh)

        case .activity:
            VideoStatsPanel(snapshot: store.snapshot)

        case .exceptions:
            ExceptionsPanel(snapshot: store.snapshot, onAdd: store.addException, onRemove: store.removeException)

        case .trust:
            SupportPanel(snapshot: store.snapshot, onRefresh: store.refresh, openSettings: store.openSafariSettings)
            DiagnosticsPanel(snapshot: store.snapshot, appGroupConnected: store.isAppGroupAvailable)

        case .setup:
            StepsPanel(snapshot: store.snapshot, openSettings: store.openSafariSettings)
        }
    }

    private var sectionBinding: Binding<SidebarSection?> {
        Binding(
            get: { store.selectedSection },
            set: { store.selectedSection = $0 ?? .overview }
        )
    }

    private var sidebarBackground: some View {
        ZStack {
            Color.clear
            if #available(iOS 26.0, macOS 26.0, *) {
                RoundedRectangle(cornerRadius: 28, style: .continuous)
                    .fill(.clear)
                    .glassEffect(.regular.tint(LiquidGlassTheme.sidebarTint), in: RoundedRectangle(cornerRadius: 28, style: .continuous))
                    .padding(.vertical, 8)
                    .padding(.leading, 8)
            } else {
                LinearGradient(
                    colors: [
                        Color.white.opacity(0.14),
                        Color.white.opacity(0.04)
                    ],
                    startPoint: .top,
                    endPoint: .bottom
                )
            }
        }
    }

    private var detailBackground: some View {
        ZStack {
            BackgroundGlow()
            ParticleField(count: 14)
                .blendMode(.plusLighter)
                .opacity(0.32)
        }
    }
}

struct LiquidGlassView_Previews: PreviewProvider {
    static var previews: some View {
        LiquidGlassView(store: DashboardStore())
    }
}
