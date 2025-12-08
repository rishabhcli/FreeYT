# CLAUDE.md

This file provides guidance to Claude Code (claude.ai/code) when working with code in this repository.

## Project Overview

FreeYT is a **production-ready** Safari Web Extension for iOS/macOS that automatically redirects YouTube URLs to privacy-enhanced no-cookie embed versions (youtube-nocookie.com). The extension protects user privacy by preventing YouTube tracking cookies.

### Components

1. **FreeYT App** - Native iOS/Mac Catalyst host app with polished UI
2. **FreeYT Extension** - Safari Web Extension (Manifest V3) with declarativeNetRequest-based redirects (Safari-only; popup blocks non-Safari UA)
3. **Features**:
   - Automatic YouTube → youtube-nocookie.com redirection
   - Toggle extension on/off via Safari toolbar popup
   - Beautiful dark/light mode UI
   - Extension status indicator in host app
   - Comprehensive URL pattern matching

## Architecture

### Two-Component Structure

The extension uses Safari's Manifest V3 architecture with declarative net request rules rather than traditional Safari App Extension APIs:

- **Host App (FreeYT/)**: Minimal iOS app that serves as a container for the extension. Uses a modern SwiftUI-based UI (`LiquidGlassView.swift`) with beautiful liquid glass design that shows extension status and instructions.

- **Extension (FreeYT Extension/)**: Contains all extension logic via:
  - `manifest.json` - Extension configuration with declarativeNetRequest permissions (Manifest V3)
  - `rules.json` - Redirect rules using regex patterns to transform YouTube URLs
  - `background.js` - Service worker for managing rule enable/disable state
  - `popup.html/css/js` - Safari toolbar popup UI for user control
  - `SafariWebExtensionHandler.swift` - Empty placeholder class (legacy Safari App Extension APIs are not used)
  - **No content scripts** - All redirects happen at network level via declarativeNetRequest

### URL Redirect Logic

The extension uses 6 declarative rules in `FreeYT Extension/Resources/rules.json`:

1. Rule 1: `youtube.com/watch?v=...` → `youtube-nocookie.com/embed/...`
2. Rule 2: `youtube.com/shorts/...` → `youtube-nocookie.com/embed/...`
3. Rule 3: `youtube.com/embed/...` → `youtube-nocookie.com/embed/...` (ensures already-embedded URLs use no-cookie)
4. Rule 4: `youtube.com/live/...` → `youtube-nocookie.com/embed/...`
5. Rule 5: `m.youtube.com/watch?v=...` → `youtube-nocookie.com/embed/...`
6. Rule 6: `youtu.be/...` → `youtube-nocookie.com/embed/...`

All rules operate on `main_frame` resource types only.

### Bundle Identifiers (Production-Ready)

The app uses consistent bundle IDs across all files:
- Host app: `com.freeyt.app`
- Extension: `com.freeyt.app.extension`
- Extension identifier in AppDelegate.swift matches Info.plist

**Ready for distribution** - Bundle identifiers are consistent across:
- FreeYT/Info.plist
- FreeYT Extension/Info.plist
- FreeYT/AppDelegate.swift:22

## Building and Running

### Build the Project (Verified Working)

```bash
# Build for iOS Simulator (tested and working)
xcodebuild -project FreeYT.xcodeproj -scheme FreeYT -destination 'platform=iOS Simulator,name=iPhone 16' clean build

# Build for Mac Catalyst
xcodebuild -project FreeYT.xcodeproj -scheme FreeYT -destination 'platform=macOS,variant=Mac Catalyst' build

# Clean build folder
xcodebuild clean -project FreeYT.xcodeproj -scheme FreeYT
```

**Status**: ✅ Builds successfully with no errors

### Running Tests

```bash
# Run unit tests
xcodebuild test -project FreeYT.xcodeproj -scheme FreeYT -destination 'platform=iOS Simulator,name=iPhone 15'

# Run specific test target
xcodebuild test -project FreeYT.xcodeproj -scheme FreeYT -only-testing:FreeYTTests
xcodebuild test -project FreeYT.xcodeproj -scheme FreeYT -only-testing:FreeYTUITests
```

### Opening in Xcode

```bash
open FreeYT.xcodeproj
```

## Project Structure

```
FreeYT/
├── FreeYT.xcodeproj/          # Xcode project file
├── FreeYT/                    # Host iOS app
│   ├── AppDelegate.swift      # App lifecycle, extension state checking
│   ├── SceneDelegate.swift    # Scene configuration using LiquidGlassHostingController
│   ├── LiquidGlassView.swift  # Modern SwiftUI UI with liquid glass design
│   ├── LiquidGlassHostingController.swift  # UIHostingController for SwiftUI view
│   ├── Info.plist            # App configuration
│   ├── Resources/
│   │   └── Base.lproj/Main.html  # Fallback instructions HTML
│   └── Assets.xcassets/      # App icons and assets
├── FreeYT Extension/          # Safari Web Extension
│   ├── SafariWebExtensionHandler.swift  # No-op placeholder
│   ├── Info.plist            # Extension configuration
│   └── Resources/
│       ├── manifest.json     # Extension manifest (Manifest V3)
│       ├── rules.json        # Declarative net request rules (6 rules)
│       ├── background.js     # Service worker for rule management
│       ├── popup.html        # Extension popup with ARIA accessibility
│       ├── popup.css         # Popup styling (dark/light mode)
│       ├── popup.js          # Popup logic with error handling
│       └── _locales/en/      # Localization strings
├── FreeYTTests/              # Comprehensive unit tests (18 tests)
├── FreeYTUITests/            # UI tests
├── .github/workflows/        # CI/CD automation
│   └── build-and-test.yml    # GitHub Actions workflow
├── PRIVACY.md                # Privacy policy for App Store
├── README.md                 # Project documentation
└── CLAUDE.md                 # This file
```

## Key Files and Their Purpose

### Extension Core Logic

- **manifest.json** - Extension configuration with declarativeNetRequest permissions (Manifest V3)
- **rules.json** - 6 declarativeNetRequest rules for redirecting YouTube URLs to youtube-nocookie.com
- **background.js** - Service worker that manages rule enabling/disabling via `updateEnabledRulesets()`
- **popup.html/css/js** - Safari toolbar popup UI with toggle switch, ARIA accessibility, error handling, and Safari-only guard (non-Safari UAs are blocked)

### Host App

- **LiquidGlassView.swift** - Modern SwiftUI UI with Liquid Glass design showing extension status; includes tint picker, animated background/particles, haptics, morph-ready GlassEffectContainer clusters, and Safari-only messaging alignment
- **LiquidGlassHostingController.swift** - UIHostingController wrapper for SwiftUI view
- **AppDelegate.swift** - Checks extension state on Mac Catalyst
- **LaunchScreen.storyboard** - Polished splash screen with icon, title, and subtitle
- **Assets.xcassets/AppIcon** - Contains 1024x1024 app icon (properly sized)

### How the Extension Works

1. **Declarative Rules**: Uses `declarativeNetRequest` API for efficient URL redirects at network level
2. **User Control**: Background service worker enables/disables rules via `chrome.declarativeNetRequest.updateEnabledRulesets()`
3. **No Content Scripts**: All redirects happen at the network level (faster, more private, better battery life)
4. **Comprehensive Coverage**: Handles youtube.com, youtu.be, m.youtube.com, shorts, embeds, and live streams
5. **Privacy-First**: Zero data collection, all processing happens locally on device

## Mac Catalyst Support

The app includes Mac Catalyst support with extension state checking in `AppDelegate.swift`. On Mac, the app checks if the Safari Web Extension is enabled and logs status to console. This requires:

- `#if targetEnvironment(macCatalyst)` compilation conditions
- `SFSafariWebExtensionManager` API (iOS 15.0+)
- Correct extension identifier matching the bundle ID

## Production-Ready Status ✅

### What's Complete

- ✅ **Manifest V3 implementation** with declarativeNetRequest (network-level redirects)
- ✅ **Functional toggle popup** with enable/disable control
- ✅ **Background service worker** for dynamic rule management via `updateEnabledRulesets()`
- ✅ **Comprehensive redirect rules** covering all YouTube URL patterns (6 rules)
- ✅ **Correct redirect target** - Uses Google's official youtube-nocookie.com domain
- ✅ **Polished SwiftUI UI** with liquid glass design and dark/light mode support
- ✅ **Proper app icon** (1024x1024, all sizes configured)
- ✅ **Beautiful launch screen** with branding
- ✅ **Bundle ID consistency** across all files
- ✅ **Extension state detection** for Mac Catalyst
- ✅ **Clean codebase** (redundant code removed, no content scripts)
- ✅ **Comprehensive test suite** (18 unit tests covering URL patterns, transformations, privacy)
- ✅ **ARIA accessibility** (full screen reader support with proper ARIA labels)
- ✅ **Error handling** (user-friendly error messages and recovery)
- ✅ **Privacy policy** (comprehensive PRIVACY.md for App Store submission)
- ✅ **CI/CD automation** (GitHub Actions for builds, tests, and validation)
- ✅ **Builds successfully** with no errors or warnings

### Testing the Extension

1. Build and run the FreeYT app on iOS Simulator or Mac:
   ```bash
   xcodebuild -project FreeYT.xcodeproj -scheme FreeYT -destination 'platform=iOS Simulator,name=iPhone 16' build
   ```

2. Open Safari Settings → Extensions

3. Enable "FreeYT - Privacy YouTube" extension

4. Test redirects:
   - Click "Test: YouTube Video" in the popup
   - Navigate to `https://youtube.com/watch?v=xxx`
   - Should redirect to `https://youtube-nocookie.com/embed/xxx`

5. Toggle on/off in Safari toolbar popup to enable/disable redirects

### Extension Popup Features

- **Toggle Switch**: Enable/disable YouTube redirects
- **Status Indicator**: Shows enabled/disabled state with color coding
- **Test Buttons**: Open sample YouTube URLs to verify redirects work
- **Beautiful Design**: Modern dark/light mode UI with smooth animations

### For App Store Submission

Ready for submission! ✅

**Completed:**
1. ✅ Bundle IDs configured (`com.freeyt.app` and `com.freeyt.app.extension`)
2. ✅ Privacy policy created (PRIVACY.md - comprehensive, GDPR/CCPA compliant)
3. ✅ Zero data collection verified (extension collects no user data)
4. ✅ Comprehensive test suite (18 tests passing)
5. ✅ CI/CD workflow (automated builds and validation)
6. ✅ Accessibility implemented (ARIA labels, screen reader support)
7. ✅ Modern Manifest V3 architecture

**Todo before submission:**
- Create App Store screenshots
- Write App Store description and metadata
- Prepare app review notes explaining privacy benefits
- Sign with distribution certificate
- Test on physical iOS devices (currently tested on simulators)

## Code Quality and Best Practices

### Architecture Improvements (Completed)

- ✅ **Removed redundant code:** Eliminated triple-redundant redirect implementations
- ✅ **Network-level redirects only:** Using declarativeNetRequest exclusively (no content scripts)
- ✅ **Proper error handling:** User-friendly error messages with recovery
- ✅ **Accessibility first:** Full ARIA support for screen readers
- ✅ **Zero data collection:** Privacy-first design with no telemetry
- ✅ **Modern SwiftUI:** Clean, maintainable UI code with liquid glass design
- ✅ **Comprehensive tests:** 18 unit tests covering core functionality

### Performance Optimizations (Completed)

- ✅ **No content script polling:** Removed 2-second interval polling
- ✅ **No MutationObservers:** Removed unnecessary DOM monitoring
- ✅ **Network-level redirects:** Faster, more efficient than JavaScript-based redirects
- ✅ **Minimal permissions:** Only 3 permissions requested (declarativeNetRequest, declarativeNetRequestFeedback, storage)
- ✅ **Battery efficient:** No background polling or unnecessary wake-ups

### Security and Privacy (Completed)

- ✅ **Minimal permissions:** Only requests necessary permissions
- ✅ **No network requests:** Extension makes zero external network calls
- ✅ **Local processing only:** All redirect logic runs on-device
- ✅ **Content Security Policy:** Implemented in popup HTML
- ✅ **No eval() usage:** No dynamic code execution
- ✅ **Open source:** Full code transparency on GitHub

## Testing and Validation

### Automated Testing

**CI/CD Pipeline (GitHub Actions):**
- iOS build validation
- Mac Catalyst build validation
- Unit test execution (18 tests)
- JSON validation (manifest.json, rules.json, messages.json)
- Extension structure validation
- Security scanning
- Permission auditing

**Test Coverage:**
- URL pattern matching (6 patterns tested)
- Video ID extraction (multiple formats)
- Redirect transformation logic
- Edge cases (multiple parameters, homepage, etc.)
- Bundle configuration
- Privacy policy validation
- Resource existence checks
