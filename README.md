# FreeYT

FreeYT is a Safari Web Extension for iPhone, iPad, and Mac that routes supported YouTube links through `youtube-nocookie.com` and keeps a local-first privacy dashboard in the companion app.

## What ships

- A native SwiftUI dashboard with `Overview`, `Activity`, `Exceptions`, `Trust`, and `Setup`
- Guided onboarding that helps users enable the extension and verify protection
- A compact Safari popup with primary protection control, quick stats, current-site exception support, and exception management
- A background service worker that owns extension state, redirect rules, recent activity, and native sync
- A small content script banner on `youtube-nocookie.com` pages that explains the privacy-enhanced route
- Seven declarative redirect rules covering watch, shorts, embed, live, mobile watch, short links, and legacy `/v/` URLs

## Product model

FreeYT stays local-first:

- No accounts
- No analytics
- No remote dashboard backend
- No cross-site tracking
- State stays on-device in the shared app-group container and Safari extension storage

The shared dashboard snapshot includes:

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

- [`FreeYT/SharedState.swift`](FreeYT/SharedState.swift) stores the shared dashboard snapshot in the `group.com.freeyt.app` app group
- [`FreeYT/Models/DashboardStore.swift`](FreeYT/Models/DashboardStore.swift) coordinates app-side state, navigation, and actions
- [`FreeYT/LiquidGlassView.swift`](FreeYT/LiquidGlassView.swift) renders the dashboard shell
- [`FreeYT/Views/Onboarding/OnboardingView.swift`](FreeYT/Views/Onboarding/OnboardingView.swift) drives setup

### Safari extension

- [`FreeYT Extension/Resources/manifest.json`](FreeYT%20Extension/Resources/manifest.json) defines the MV3 extension, popup, background worker, content script, and permissions
- [`FreeYT Extension/Resources/background.js`](FreeYT%20Extension/Resources/background.js) manages redirect state, exceptions, recent activity, and native sync
- [`FreeYT Extension/Resources/popup.html`](FreeYT%20Extension/Resources/popup.html), [`popup.css`](FreeYT%20Extension/Resources/popup.css), and [`popup.js`](FreeYT%20Extension/Resources/popup.js) implement the popup
- [`FreeYT Extension/Resources/banner.js`](FreeYT%20Extension/Resources/banner.js) shows the explanatory banner on `youtube-nocookie.com`
- [`FreeYT Extension/SafariWebExtensionHandler.swift`](FreeYT%20Extension/SafariWebExtensionHandler.swift) handles native messaging and app deep links

## Redirect coverage

[`FreeYT Extension/Resources/rules.json`](FreeYT%20Extension/Resources/rules.json) currently ships 7 `main_frame` redirect rules:

1. `youtube.com/watch?v=...`
2. `youtube.com/shorts/...`
3. `youtube.com/embed/...`
4. `youtube.com/live/...`
5. `m.youtube.com/watch?v=...`
6. `youtu.be/...`
7. `youtube.com/v/...`

All supported routes redirect to `https://www.youtube-nocookie.com/embed/<video-id>?autoplay=1`.

## Bundle identifiers and shared container

The project is aligned around:

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
3. Complete the onboarding flow in the host app.
4. Open a supported YouTube URL and confirm it lands on `youtube-nocookie.com`.
5. Open the Safari popup and verify:
   - protection can be paused and resumed
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
