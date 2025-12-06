// FreeYT Background Service Worker
// Manages declarativeNetRequest rules for YouTube → youtube-nocookie.com redirects

const STORAGE_KEY = 'enabled';
const RULESET_ID = 'ruleset_1';

// Initialize extension state on install
chrome.runtime.onInstalled.addListener(async () => {
  console.log('[FreeYT] Extension installed');

  // Set default state to enabled
  const result = await chrome.storage.local.get(STORAGE_KEY);
  if (result[STORAGE_KEY] === undefined) {
    await chrome.storage.local.set({ [STORAGE_KEY]: true });
    await enableRedirects();
    console.log('[FreeYT] Initialized as enabled');
  } else {
    // Restore previous state
    if (result[STORAGE_KEY]) {
      await enableRedirects();
    } else {
      await disableRedirects();
    }
    console.log('[FreeYT] Restored state:', result[STORAGE_KEY] ? 'enabled' : 'disabled');
  }
});

// Safari can unload the service worker; re-sync rules whenever it wakes
chrome.runtime.onStartup?.addListener(() => {
  syncRulesToStorage().catch(err => console.error('[FreeYT] Failed to sync rules on startup:', err));
});

// Enable redirect rules
async function enableRedirects() {
  try {
    await chrome.declarativeNetRequest.updateEnabledRulesets({
      enableRulesetIds: [RULESET_ID]
    });
    console.log('[FreeYT] Redirect rules enabled');
  } catch (error) {
    console.error('[FreeYT] Failed to enable redirect rules:', error);
  }
}

// Disable redirect rules
async function disableRedirects() {
  try {
    await chrome.declarativeNetRequest.updateEnabledRulesets({
      disableRulesetIds: [RULESET_ID]
    });
    console.log('[FreeYT] Redirect rules disabled');
  } catch (error) {
    console.error('[FreeYT] Failed to disable redirect rules:', error);
  }
}

// Ensure the enabled ruleset matches the saved toggle state
async function syncRulesToStorage() {
  const result = await chrome.storage.local.get(STORAGE_KEY);
  const enabled = result[STORAGE_KEY] ?? true;
  if (enabled) {
    await enableRedirects();
  } else {
    await disableRedirects();
  }
  console.log('[FreeYT] Synced rules to stored state:', enabled ? 'enabled' : 'disabled');
}

// Handle messages from popup
chrome.runtime.onMessage.addListener((request, sender, sendResponse) => {
  console.log('[FreeYT] Received message:', request);

  if (request.action === 'getState') {
    // Return current enabled state
    chrome.storage.local.get(STORAGE_KEY).then(result => {
      sendResponse({ enabled: result[STORAGE_KEY] ?? true });
    });
    return true; // Keep channel open for async response
  }

  if (request.action === 'setState') {
    // Update enabled state and toggle rules
    const enabled = request.enabled;
    chrome.storage.local.set({ [STORAGE_KEY]: enabled }).then(async () => {
      if (enabled) {
        await enableRedirects();
      } else {
        await disableRedirects();
      }
      console.log('[FreeYT] State updated:', enabled ? 'enabled' : 'disabled');
      sendResponse({ success: true });
    });
    return true; // Keep channel open for async response
  }

  return false;
});

// Listen for storage changes (in case user modifies from another context)
chrome.storage.onChanged.addListener(async (changes, areaName) => {
  if (areaName === 'local' && changes[STORAGE_KEY]) {
    const enabled = changes[STORAGE_KEY].newValue;
    console.log('[FreeYT] Storage changed, updating rules:', enabled ? 'enabled' : 'disabled');
    if (enabled) {
      await enableRedirects();
    } else {
      await disableRedirects();
    }
  }
});

// Best-effort sync whenever the worker spins up
syncRulesToStorage().catch(err => console.error('[FreeYT] Initial sync failed:', err));

console.log('[FreeYT] Background service worker initialized');
