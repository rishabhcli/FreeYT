# Privacy Policy for FreeYT - Privacy YouTube

**Last Updated:** April 8, 2026

## Overview

FreeYT - Privacy YouTube is a Safari Web Extension designed to improve privacy when browsing YouTube. This policy explains what the extension and companion app do locally on your device and what data they store.

## Our Privacy Commitment

FreeYT does not collect, sell, or transmit your personal data to any remote service. The product is designed to work locally on your device.

## What the Product Does

FreeYT redirects supported YouTube URLs to privacy-enhanced no-cookie embed versions:

- `youtube.com/watch?v=...`
- `youtube.com/shorts/...`
- `youtube.com/embed/...`
- `youtube.com/live/...`
- `m.youtube.com/watch?v=...`
- `youtu.be/...`
- `youtube.com/v/...`

It also shows a small explanatory banner on `youtube-nocookie.com` pages so users understand why the page changed.

## Data and Storage

FreeYT stores product state locally so the extension, popup, widget, and host app can stay in sync. The stored local data may include:

- `enabled`
- `videoCount`
- `dailyCounts`
- `lastProtectedAt`
- `recentActivity`
- `exceptions`
- `lastSyncState`
- `lastSyncTimestamp`

This information stays on the device in Safari storage and the shared app-group container. FreeYT does not use a remote dashboard backend or cloud account.

## Permissions Explained

FreeYT requests the following permissions to function:

### 1. `declarativeNetRequest`

- Purpose: Redirect supported YouTube URLs at the network level
- Data access: URL pattern matching only
- Privacy impact: Local-only redirect behavior

### 2. `declarativeNetRequestFeedback`

- Purpose: Verify redirect rule behavior
- Data access: Rule activation metadata
- Privacy impact: Local-only diagnostics

### 3. `storage`

- Purpose: Store extension state, counts, exceptions, and sync metadata
- Data stored: The local dashboard snapshot described above
- Privacy impact: Stored only on your device

### 4. `tabs`

- Purpose: Read the active tab when showing current-site information in the popup
- Data access: The currently active tab URL
- Privacy impact: Used locally for the popup only

### 5. Host Permissions

- `*://*.youtube.com/*`
- `*://youtu.be/*`
- `*://*.youtube-nocookie.com/*`

These permissions allow FreeYT to redirect supported routes and show the banner on privacy-enhanced embed pages.

## How FreeYT Works

FreeYT uses Safari's declarativeNetRequest API and a small background worker:

1. Redirect decisions happen locally in the extension.
2. The popup reads local state to show protection and exception status.
3. The host app reads the shared dashboard snapshot from the app group container.
4. The extension and app sync through Safari native messaging, which stays on-device.
5. No analytics endpoint, ad network, or remote dashboard is involved.

## Third-Party Access

FreeYT does not share stored state with third-party services. The only external domain involved in normal use is YouTube's own `youtube-nocookie.com` embed domain, which serves the redirected video page.

## Security

Because FreeYT keeps its product state local and does not send it to a remote backend, the main security concerns are limited to the device itself and the browser permissions required to redirect supported URLs.

## Changes to This Policy

We may update this policy from time to time. If we make material changes, we will update the date above and publish the new version in the repository.

## Open Source

FreeYT is open source software. You can review the code here:

**GitHub Repository:** https://github.com/risban933/FreeYT

## Contact Information

If you have questions about this policy or FreeYT's privacy practices, you can open an issue on the repository above.

## Your Rights

Since FreeYT is designed to keep its data local to your device, you can remove the product at any time by uninstalling the extension and deleting the companion app. Doing so removes the locally stored product state.

## Summary

FreeYT is designed to be local-first:

- No remote dashboard backend
- No analytics
- No ad tracking
- No account required
- No cloud sync
- Local storage only
