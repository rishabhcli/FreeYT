# FreeYT - Privacy YouTube Safari Extension

A Safari Web Extension that automatically redirects YouTube URLs to their privacy-enhanced embed versions using youtube-nocookie.com, eliminating tracking cookies and protecting your privacy.

## Overview

FreeYT intercepts YouTube links and redirects them to embed-only versions that don't set tracking cookies. This happens at the network level using Safari's declarativeNetRequest API, making it fast, reliable, and battery-efficient.

## Features

- Network-level URL redirection (no DOM manipulation)
- Safari-only extension (explicit guard for non-Safari user agents)
- Supports multiple YouTube URL formats:
  - youtube.com/watch?v=xxx
  - youtu.be/xxx
  - youtube.com/shorts/xxx
  - m.youtube.com (mobile)
- Toggle extension on/off via Safari toolbar popup with Liquid Glass styling
- Persistent state across browser sessions
- Dark/light mode support in popup UI
- Native iOS/Mac host app with modern SwiftUI interface (Liquid Glass design, morph-ready containers, animated background/particles, haptics, tint picker)
- No data collection, no tracking, no analytics

## Technical Architecture

### Extension Components

- **Manifest V3**: Modern Safari Web Extension API
- **declarativeNetRequest**: Network-level URL rewriting for performance
- **Background Service Worker**: Manages rule enabling/disabling
- **chrome.storage**: Persists user toggle preferences
- **Safari Toolbar Popup**: User interface for extension control

### How It Works

1. User navigates to a YouTube URL
2. Safari intercepts the request via declarativeNetRequest
3. If extension is enabled, applies regex pattern matching
4. Redirects to youtube-nocookie.com/embed/[video-id]
5. Video plays without tracking cookies

## Installation

### Development/Testing

1. Clone or download this repository

2. Open the project in Xcode:
   ```bash
   open FreeYT.xcodeproj
   ```

3. Build the project:
   ```bash
   xcodebuild -project FreeYT.xcodeproj -scheme FreeYT \
     -destination 'platform=iOS Simulator,name=iPhone 16' build
   ```
   Or press Command+R in Xcode

4. Enable the extension in Safari:
   - Open Safari > Settings > Extensions
   - Find "FreeYT - Privacy YouTube"
   - Toggle it ON
   - Grant permissions for youtube.com

## Usage

### Enabling/Disabling

1. Click the FreeYT icon in Safari's toolbar
2. Use the toggle switch to enable or disable redirects
3. Status indicator shows current state:
   - Green: Extension active
   - Gray: Extension disabled

### Testing

The popup includes test buttons to verify functionality:
- Click "Test: YouTube Video" to open a sample video link
- Click "Test: YouTube Short" to open a sample short link
- Both should redirect to youtube-nocookie.com if enabled

### Manual Testing

Visit any YouTube URL:
- https://www.youtube.com/watch?v=dQw4w9WgXcQ
- https://youtu.be/dQw4w9WgXcQ
- https://www.youtube.com/shorts/abc123

All should redirect to their youtube-nocookie.com embed equivalents.

## Project Structure

```
FreeYT/
├── FreeYT.xcodeproj          # Xcode project file
├── FreeYT/                   # Host application
│   ├── AppDelegate.swift     # App lifecycle management
│   ├── SceneDelegate.swift   # Scene configuration
│   ├── LiquidGlassView.swift # Main app screen (modern SwiftUI)
│   ├── LiquidGlassHostingController.swift  # UIHostingController wrapper
│   ├── Info.plist           # App bundle configuration
│   ├── Assets.xcassets/     # Icons and images
│   └── LaunchScreen.storyboard  # Splash screen
└── FreeYT Extension/         # Safari Web Extension
    ├── Resources/
    │   ├── manifest.json    # Extension configuration
    │   ├── rules.json       # URL redirect rules
    │   ├── background.js    # Service worker
    │   ├── popup.html       # Toolbar popup UI
    │   ├── popup.css        # Popup styling
    │   ├── popup.js         # Popup logic
    │   └── images/          # Extension icons
    └── Info.plist           # Extension bundle configuration
```

## Key Files

### manifest.json
Defines extension permissions, background worker, toolbar action, and declarativeNetRequest rules.

### rules.json
Contains regex patterns for matching and redirecting YouTube URLs. All redirect rules use priority 1 and apply to youtube.com domains.

### background.js
Service worker that:
- Initializes extension as enabled by default
- Listens for toggle changes from popup
- Enables/disables redirect rulesets dynamically
- Logs all state changes for debugging

### popup.html/css/js
Safari toolbar popup interface that:
- Displays current extension state
- Provides toggle control (Safari-only guard; blocks non-Safari)
- Includes test buttons for verification
- Supports system dark/light mode

### LiquidGlassView.swift
Modern SwiftUI app UI that:
- Displays app branding with Liquid Glass design, animated background/particles
- Shows extension status and instructions in a GlassEffectContainer cluster
- Includes morph-ready Liquid Glass toggle (iOS 18+/26), tint picker, haptics
- Supports dark/light mode automatically
- Provides polished onboarding aligned with the Safari popup
- Auto-detects extension status on Mac Catalyst and offers refresh/diagnostics

## Bundle Identifiers

- Host app: `com.freeyt.app`
- Extension: `com.freeyt.app.extension`

These must remain consistent across Info.plist files and AppDelegate.swift.

## Build Commands

### Clean Build
```bash
xcodebuild clean -project FreeYT.xcodeproj -scheme FreeYT
```

### Build for iOS Simulator
```bash
xcodebuild -project FreeYT.xcodeproj -scheme FreeYT \
  -destination 'platform=iOS Simulator,name=iPhone 16' build
```

### Build for Mac Catalyst
```bash
xcodebuild -project FreeYT.xcodeproj -scheme FreeYT \
  -destination 'platform=macOS,variant=Mac Catalyst' build
```

### Run Tests
```bash
xcodebuild test -project FreeYT.xcodeproj -scheme FreeYT \
  -destination 'platform=iOS Simulator,name=iPhone 16'
```

## Debugging

1. Enable extension in Safari
2. Open Safari > Develop > Show Web Inspector
3. Check Console for `[FreeYT]` log messages
4. Background worker logs:
   - Extension initialization
   - Rule enabling/disabling
   - Storage changes

## Testing Checklist

- [ ] Build succeeds without errors
- [ ] Run on iOS Simulator and enable extension in Safari
- [ ] Test youtube.com/watch?v=xxx redirect
- [ ] Test youtu.be/xxx redirect
- [ ] Test youtube.com/shorts/xxx redirect
- [ ] Toggle extension off and verify redirects stop
- [ ] Toggle back on and verify redirects resume
- [ ] Check popup UI in dark mode
- [ ] Check popup UI in light mode
- [ ] Verify test buttons open YouTube URLs

## Development

### Modifying Redirect Rules
Edit `FreeYT Extension/Resources/rules.json` to add or modify URL patterns.

### Changing Popup UI
Edit the following files:
- `FreeYT Extension/Resources/popup.html` - Structure
- `FreeYT Extension/Resources/popup.css` - Styling
- `FreeYT Extension/Resources/popup.js` - Functionality

### Updating App UI
Edit the following files for host app interface changes:
- `FreeYT/LiquidGlassView.swift` - SwiftUI view structure and layout
- `FreeYT/LiquidGlassHostingController.swift` - UIHostingController wrapper
- `FreeYT/SceneDelegate.swift` - Scene configuration

## Roadmap

### For Production Release

1. **Update Bundle IDs** (if needed)
   - Modify Info.plist files
   - Update AppDelegate.swift references

2. **App Store Assets**
   - Screenshots of extension in action
   - App preview video (optional)
   - Description highlighting privacy benefits

3. **Privacy Policy**
   - Document "No data collected, no tracking, no analytics"
   - Host on webpage or GitHub

4. **Code Signing**
   - Add Apple Developer Team ID
   - Configure provisioning profiles
   - Enable necessary capabilities

5. **App Review Preparation**
   - Document privacy benefits
   - Provide testing instructions
   - Note declarativeNetRequest usage (no data access)

## Privacy

This extension:
- Does NOT collect any user data
- Does NOT track browsing history
- Does NOT use analytics
- Does NOT inject scripts into pages
- Does NOT read page content
- Only redirects YouTube URLs to privacy-enhanced versions

All processing happens locally on your device.

## Requirements

- iOS 15.0+ / macOS 11.0+
- Safari 15.0+
- Xcode 13.0+ (for development)

## License

Copyright 2025. All rights reserved.

## Support

For issues or questions, please check the Safari extension logs in Web Inspector or review the debugging section above.

---

Built with a focus on privacy. No tracking. No cookies. Just pure YouTube content.
