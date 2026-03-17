# FreeYT

FreeYT is a Safari Web Extension for iPhone, iPad, and Mac that routes supported YouTube links through `youtube-nocookie.com` and surfaces a local-first privacy dashboard in the companion app.

## What ships now

- A native SwiftUI dashboard with `Overview`, `Activity`, `Exceptions`, `Trust`, and `Setup` sections
- Guided onboarding that walks users through enabling the Safari extension and verifying protection
- A compact Safari popup with one primary control, quick stats, current-site bypass, and exception management
- A background service worker that maintains a shared dashboard snapshot and syncs it with the host app
- A lightweight banner content script on `youtube-nocookie.com` pages that explains the privacy-enhanced route
- Seven declarative redirect rules covering watch, shorts, embed, live, mobile watch, short links, and legacy `/v/` URLs

## Product model

FreeYT stays local-first:

- No accounts
- No analytics
- No remote dashboard backend
- No cross-site tracking
- All state is stored on-device through the app group shared container

The dashboard snapshot currently includes:

- `enabled`
- `videoCount`
- `dailyCounts`
- `lastProtectedAt`
- `recentActivity`
- `exceptions`
- `lastSyncState`
- `lastSyncTimestamp`

## Architecture

### Host app

The host app lives in [`/Users/rishabhbansal/Documents/GitHub/FreeYT/FreeYT`](/Users/rishabhbansal/Documents/GitHub/FreeYT/FreeYT) and now centers on a shared dashboard model rather than a status shell.

- [`LiquidGlassView.swift`](/Users/rishabhbansal/Documents/GitHub/FreeYT/FreeYT/LiquidGlassView.swift) renders the dashboard IA
- [`DashboardStore.swift`](/Users/rishabhbansal/Documents/GitHub/FreeYT/FreeYT/Models/DashboardStore.swift) coordinates app-side state, navigation, and actions
- [`SharedState.swift`](/Users/rishabhbansal/Documents/GitHub/FreeYT/FreeYT/SharedState.swift) owns the shared dashboard snapshot in the app group container
- [`OnboardingView.swift`](/Users/rishabhbansal/Documents/GitHub/FreeYT/FreeYT/Views/Onboarding/OnboardingView.swift) drives the guided setup flow

### Safari extension

The extension lives in [`/Users/rishabhbansal/Documents/GitHub/FreeYT/FreeYT Extension`](/Users/rishabhbansal/Documents/GitHub/FreeYT/FreeYT%20Extension).

- [`manifest.json`](/Users/rishabhbansal/Documents/GitHub/FreeYT/FreeYT%20Extension/Resources/manifest.json) defines the MV3 extension, popup, background worker, content script, and permissions
- [`background.js`](/Users/rishabhbansal/Documents/GitHub/FreeYT/FreeYT%20Extension/Resources/background.js) manages redirect state, exceptions, recent activity, and native sync
- [`popup.html`](/Users/rishabhbansal/Documents/GitHub/FreeYT/FreeYT%20Extension/Resources/popup.html), [`popup.css`](/Users/rishabhbansal/Documents/GitHub/FreeYT/FreeYT%20Extension/Resources/popup.css), and [`popup.js`](/Users/rishabhbansal/Documents/GitHub/FreeYT/FreeYT%20Extension/Resources/popup.js) implement the compact control surface
- [`banner.js`](/Users/rishabhbansal/Documents/GitHub/FreeYT/FreeYT%20Extension/Resources/banner.js) shows an in-page notice on privacy-enhanced embed pages
- [`SafariWebExtensionHandler.swift`](/Users/rishabhbansal/Documents/GitHub/FreeYT/FreeYT%20Extension/SafariWebExtensionHandler.swift) handles native message sync and app deep links

## Redirect coverage

[`rules.json`](/Users/rishabhbansal/Documents/GitHub/FreeYT/FreeYT%20Extension/Resources/rules.json) currently ships 7 `main_frame` redirect rules:

1. `youtube.com/watch?v=...`
2. `youtube.com/shorts/...`
3. `youtube.com/embed/...`
4. `youtube.com/live/...`
5. `m.youtube.com/watch?v=...`
6. `youtu.be/...`
7. `youtube.com/v/...`

All supported routes redirect to `https://www.youtube-nocookie.com/embed/<video-id>?autoplay=1`.

## Bundle identifiers and shared container

The project is now aligned around:

- App: `com.freeyt.app`
- Extension: `com.freeyt.app.extension`
- Widget: `com.freeyt.app.widget`
- App group: `group.com.freeyt.app`

Those values are used by the Xcode project, entitlements, shared state, and native messaging bridge.

## Build

```bash
xcodebuild -project FreeYT.xcodeproj -scheme FreeYT \
  -destination 'platform=iOS Simulator,name=iPhone 17' build

xcodebuild -project FreeYT.xcodeproj -scheme FreeYT \
  -destination 'platform=macOS,variant=Mac Catalyst' build
```

## Test

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

## Manual verification

1. Build and run the app.
2. Enable the FreeYT extension in Safari.
3. Complete the guided setup flow in the host app.
4. Open a supported YouTube URL and confirm it lands on `youtube-nocookie.com`.
5. Open the Safari popup and verify:
   - protection can be paused/resumed
   - `Today`, `This Week`, and `All Time` counts update
   - `Bypass this site` adds and removes a trusted exception
6. Open the host app and verify recent activity, exceptions, trust copy, and setup checklist.

## Accessibility and adaptation

The dashboard and popup are designed to respect:

- Dynamic Type
- Light and dark appearance
- Reduce Motion
- Reduce Transparency where system materials fall back
- VoiceOver and semantic labels for popup controls and status regions

## Repo layout

```text
FreeYT/
├── FreeYT.xcodeproj/
├── FreeYT/
├── FreeYT Extension/
├── FreeYTWidget/
├── FreeYTTests/
├── FreeYTUITests/
├── PRIVACY.md
└── README.md
```
