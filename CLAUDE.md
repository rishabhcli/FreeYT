# CLAUDE.md

This file provides guidance to Claude Code when working in this repository.

## Project Overview

FreeYT is a Safari Web Extension with a native SwiftUI companion app. It redirects supported YouTube URLs to `youtube-nocookie.com` and exposes a local-first dashboard for protection status, recent activity, trusted exceptions, and setup.

## Product Surfaces

1. Host app
   - Dashboard-first IA with `Overview`, `Activity`, `Exceptions`, `Trust`, and `Setup`
   - Guided onboarding and verification flow
   - Shared dashboard snapshot backed by the app-group container
2. Safari popup
   - Primary `Active` / `Paused` control
   - `Today`, `This Week`, and `All Time` stats
   - Current-site quick exception
   - Expandable exception management
   - Open-dashboard and refresh actions
3. Background worker
   - Owns the extension-side dashboard state
   - Tracks recent redirects and daily counts
   - Syncs to the native app via Safari native messaging
4. Banner content script
   - Runs on `youtube-nocookie.com` pages
   - Explains that the current route is privacy-enhanced
   - Supports dismiss and always-hide behavior

## Architecture

### Host app

- [`FreeYT/SharedState.swift`](FreeYT/SharedState.swift)
  Stores the shared dashboard snapshot in the `group.com.freeyt.app` app group.
- [`FreeYT/Models/DashboardStore.swift`](FreeYT/Models/DashboardStore.swift)
  App-side observable store for dashboard data, section selection, protection toggling, exceptions, and deep links.
- [`FreeYT/LiquidGlassView.swift`](FreeYT/LiquidGlassView.swift)
  Main dashboard shell.
- [`FreeYT/Views/Onboarding/OnboardingView.swift`](FreeYT/Views/Onboarding/OnboardingView.swift)
  Guided setup flow.

### Extension

- [`FreeYT Extension/Resources/manifest.json`](FreeYT%20Extension/Resources/manifest.json)
  MV3 manifest. Includes popup, background worker, permissions, content script, and rule resource registration.
- [`FreeYT Extension/Resources/background.js`](FreeYT%20Extension/Resources/background.js)
  Tracks dashboard state and exception rules.
- [`FreeYT Extension/Resources/popup.js`](FreeYT%20Extension/Resources/popup.js)
  Popup UI state and interaction handling.
- [`FreeYT Extension/SafariWebExtensionHandler.swift`](FreeYT%20Extension/SafariWebExtensionHandler.swift)
  Native messaging bridge used for dashboard sync and app deep linking.

## Shared Dashboard Model

The effective snapshot includes:

- `enabled`
- `videoCount`
- `dailyCounts`
- `lastProtectedAt`
- `recentActivity`
- `exceptions`
- `lastSyncState`
- `lastSyncTimestamp`

User-facing copy uses **Exceptions**. Extension compatibility paths may still refer to `allowlist` in storage or bridge payloads.

## Redirect Rules

[`FreeYT Extension/Resources/rules.json`](FreeYT%20Extension/Resources/rules.json) currently contains **7** redirect rules:

1. watch
2. shorts
3. embed
4. live
5. mobile watch
6. short link
7. legacy `/v/`

All rules operate on `main_frame`.

## Identifiers

Current expected identifiers:

- App bundle ID: `com.freeyt.app`
- Extension bundle ID: `com.freeyt.app.extension`
- Widget bundle ID: `com.freeyt.app.widget`
- App group: `group.com.freeyt.app`

The Xcode project, entitlements, shared state, and native messaging bridge should stay aligned with those values.

## Build Commands

```bash
xcodebuild -project FreeYT.xcodeproj -scheme FreeYT \
  -destination 'platform=iOS Simulator,name=iPhone 17' build

xcodebuild -project FreeYT.xcodeproj -scheme FreeYT \
  -destination 'platform=macOS,variant=Mac Catalyst' build
```

## Test Commands

Swift tests:

```bash
xcodebuild test -project FreeYT.xcodeproj -scheme FreeYT \
  -destination 'platform=iOS Simulator,name=iPhone 17'
```

Extension tests:

```bash
cd "FreeYT Extension/Tests"
npm test
```

## Working Notes

- Prefer the shared snapshot model over adding one-off storage keys or message contracts.
- Keep the popup compact and action-oriented. Deeper education belongs in the host app.
- Keep product copy trust-focused and consumer-facing.
- The extension is Safari-only, but the popup explicitly guards non-Safari user agents.
- Do not document the product as having no content scripts; `banner.js` is intentionally shipped as a small explanatory content script.
