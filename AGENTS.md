# AGENTS.md

This file documents the current FreeYT architecture and the practical expectations for agents working in this repository.

## Project overview

FreeYT is a Safari Web Extension with a native SwiftUI companion app. The product routes supported YouTube URLs through `youtube-nocookie.com` and exposes a local-first privacy dashboard so users can review protection state, recent activity, trusted exceptions, and setup status.

## Current product surfaces

1. **Host app**
   - Dashboard-first IA with `Overview`, `Activity`, `Exceptions`, `Trust`, and `Setup`
   - Guided onboarding and verification flow
   - Shared dashboard snapshot backed by the app group container

2. **Safari popup**
   - Primary `Active` / `Paused` control
   - `Today`, `This Week`, and `All Time` stats
   - Current-site quick exception
   - Expandable exceptions management
   - Open-dashboard and refresh actions

3. **Background worker**
   - Owns the extension-side dashboard state
   - Tracks recent redirects and daily counts
   - Syncs to the native app via Safari native messaging

4. **Banner content script**
   - Runs on `youtube-nocookie.com` pages
   - Explains that the current route is privacy-enhanced
   - Supports dismiss and always-hide behavior

## Architecture

### Host app

- [`FreeYT/SharedState.swift`](/Users/rishabhbansal/Documents/GitHub/FreeYT/FreeYT/SharedState.swift)
  Stores the shared dashboard snapshot in the `group.com.freeyt.app` app group.

- [`FreeYT/Models/DashboardStore.swift`](/Users/rishabhbansal/Documents/GitHub/FreeYT/FreeYT/Models/DashboardStore.swift)
  App-side observable store for dashboard data, section selection, protection toggling, exceptions, and deep links.

- [`FreeYT/LiquidGlassView.swift`](/Users/rishabhbansal/Documents/GitHub/FreeYT/FreeYT/LiquidGlassView.swift)
  Main dashboard shell.

- [`FreeYT/Views/Onboarding/OnboardingView.swift`](/Users/rishabhbansal/Documents/GitHub/FreeYT/FreeYT/Views/Onboarding/OnboardingView.swift)
  Guided setup flow.

### Extension

- [`FreeYT Extension/Resources/manifest.json`](/Users/rishabhbansal/Documents/GitHub/FreeYT/FreeYT%20Extension/Resources/manifest.json)
  MV3 manifest. Includes popup, background worker, permissions, content script, and rule resource registration.

- [`FreeYT Extension/Resources/background.js`](/Users/rishabhbansal/Documents/GitHub/FreeYT/FreeYT%20Extension/Resources/background.js)
  Tracks dashboard state and exception rules.

- [`FreeYT Extension/Resources/popup.js`](/Users/rishabhbansal/Documents/GitHub/FreeYT/FreeYT%20Extension/Resources/popup.js)
  Popup UI state and interaction handling.

- [`FreeYT Extension/SafariWebExtensionHandler.swift`](/Users/rishabhbansal/Documents/GitHub/FreeYT/FreeYT%20Extension/SafariWebExtensionHandler.swift)
  Native messaging bridge used for dashboard sync and app deep linking.

### Shared dashboard model

The effective snapshot includes:

- `enabled`
- `videoCount`
- `dailyCounts`
- `lastProtectedAt`
- `recentActivity`
- `exceptions`
- `lastSyncState`
- `lastSyncTimestamp`

User-facing copy uses **Exceptions**. Storage and compatibility paths may still refer to `allowlist` in the extension for backward-compatible messaging.

## Redirect rules

[`FreeYT Extension/Resources/rules.json`](/Users/rishabhbansal/Documents/GitHub/FreeYT/FreeYT%20Extension/Resources/rules.json) currently contains **7** redirect rules:

1. watch
2. shorts
3. embed
4. live
5. mobile watch
6. short link
7. legacy `/v/`

All rules target `main_frame`.

## Identifiers

These are the current expected identifiers:

- App bundle ID: `com.freeyt.app`
- Extension bundle ID: `com.freeyt.app.extension`
- Widget bundle ID: `com.freeyt.app.widget`
- App group: `group.com.freeyt.app`

The Xcode project, entitlements, shared state, and native messaging bridge should stay aligned with those values.

## Build commands

```bash
xcodebuild -project FreeYT.xcodeproj -scheme FreeYT \
  -destination 'platform=iOS Simulator,name=iPhone 17' build

xcodebuild -project FreeYT.xcodeproj -scheme FreeYT \
  -destination 'platform=macOS,variant=Mac Catalyst' build
```

## Test commands

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

## Working notes

- Prefer the shared snapshot model over adding one-off storage keys or message contracts.
- Keep the popup compact and action-oriented. Deeper education belongs in the host app.
- Keep product copy trust-focused and consumer-facing. Avoid drifting back toward diagnostics-heavy language.
- The extension is Safari-only, but the popup explicitly guards non-Safari user agents.
- Do not document the product as “no content scripts”; `banner.js` is intentionally shipped as a small explanatory content script.
