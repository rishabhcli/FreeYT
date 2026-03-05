// FreeYT Background Service Worker
// Manages declarativeNetRequest rules for YouTube → youtube-nocookie.com redirects
// Tracks ad-free video views and syncs state with native app via App Groups

const STORAGE_KEY = 'enabled';
const VIDEO_COUNT_KEY = 'videoCount';
const ALLOWLIST_KEY = 'allowlist';
const RULESET_ID = 'ruleset_1';
const DAILY_COUNT_PREFIX = 'count_';

function todayKey() {
  const d = new Date();
  return DAILY_COUNT_PREFIX + d.toISOString().slice(0, 10);
}

// Initialize extension state on install
chrome.runtime.onInstalled.addListener(async () => {
  console.log('[FreeYT] Extension installed');

  // Set default state to enabled
  const result = await chrome.storage.local.get([STORAGE_KEY, VIDEO_COUNT_KEY]);
  if (result[STORAGE_KEY] === undefined) {
    await chrome.storage.local.set({ [STORAGE_KEY]: true, [VIDEO_COUNT_KEY]: 0 });
    await enableRedirects();
    console.log('[FreeYT] Initialized as enabled with video count 0');
  } else {
    // Restore previous state
    if (result[STORAGE_KEY]) {
      await enableRedirects();
    } else {
      await disableRedirects();
    }
    console.log('[FreeYT] Restored state:', result[STORAGE_KEY] ? 'enabled' : 'disabled');
  }

  // Clean up daily count keys older than 90 days
  const allKeys = await chrome.storage.local.get(null);
  const cutoff = new Date();
  cutoff.setDate(cutoff.getDate() - 90);
  const cutoffStr = cutoff.toISOString().slice(0, 10);
  const oldKeys = Object.keys(allKeys).filter(k => k.startsWith(DAILY_COUNT_PREFIX) && k.slice(DAILY_COUNT_PREFIX.length) < cutoffStr);
  if (oldKeys.length > 0) {
    await chrome.storage.local.remove(oldKeys);
    console.log('[FreeYT] Cleaned up', oldKeys.length, 'old daily count keys');
  }

  // Sync with native app on install
  await syncWithNativeApp();
});

// Safari can unload the service worker; re-sync rules whenever it wakes
chrome.runtime.onStartup?.addListener(() => {
  syncRulesToStorage().catch(err => console.error('[FreeYT] Failed to sync rules on startup:', err));
  syncWithNativeApp().catch(err => console.log('[FreeYT] Native sync skipped on startup'));
});

// Flush state before Safari unloads the service worker
chrome.runtime.onSuspend?.addListener(() => {
  console.log('[FreeYT] Service worker suspending at', new Date().toISOString());
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

// Ensure the enabled ruleset matches the saved toggle state (idempotent)
async function syncRulesToStorage() {
  const [storageResult, enabledRulesets] = await Promise.all([
    chrome.storage.local.get(STORAGE_KEY),
    chrome.declarativeNetRequest.getEnabledRulesets()
  ]);
  const shouldBeEnabled = storageResult[STORAGE_KEY] ?? true;
  const isEnabled = enabledRulesets.includes(RULESET_ID);

  if (shouldBeEnabled && !isEnabled) {
    await enableRedirects();
  } else if (!shouldBeEnabled && isEnabled) {
    await disableRedirects();
  }
  console.log('[FreeYT] Synced rules (was:', isEnabled, 'should be:', shouldBeEnabled, ')');
}

// ============================================================================
// VIDEO COUNT TRACKING
// ============================================================================

// Get current video count from local storage
async function getVideoCount() {
  const result = await chrome.storage.local.get(VIDEO_COUNT_KEY);
  return result[VIDEO_COUNT_KEY] || 0;
}

// Increment video count in both local storage and native app
async function incrementVideoCount() {
  // Update total count
  const currentCount = await getVideoCount();
  const newCount = currentCount + 1;
  await chrome.storage.local.set({ [VIDEO_COUNT_KEY]: newCount });

  // Update daily count
  const dayKey = todayKey();
  const dayResult = await chrome.storage.local.get(dayKey);
  await chrome.storage.local.set({ [dayKey]: (dayResult[dayKey] || 0) + 1 });
  console.log('[FreeYT] Video count incremented to:', newCount);

  // Sync to native app via messaging (best-effort)
  try {
    await browser.runtime.sendNativeMessage('com.freeyt.app.extension', {
      action: 'incrementCount'
    });
    console.log('[FreeYT] Native app notified of video count increment');
  } catch (e) {
    // Native messaging may not be available or app may not be running
    console.log('[FreeYT] Native sync skipped (app not running or unavailable)');
  }

  return newCount;
}

// Track redirects using declarativeNetRequest feedback API
// This listener fires whenever a redirect rule is applied
if (chrome.declarativeNetRequest.onRuleMatchedDebug) {
  chrome.declarativeNetRequest.onRuleMatchedDebug.addListener((info) => {
    if (info.rule.rulesetId === RULESET_ID) {
      incrementVideoCount();
      console.log('[FreeYT] Redirect tracked, rule:', info.rule.ruleId, 'URL:', info.request?.url);
    }
  });
  console.log('[FreeYT] Redirect tracking enabled via onRuleMatchedDebug');
} else {
  console.log('[FreeYT] onRuleMatchedDebug not available, tracking via web navigation');

  // Fallback: Track navigations to youtube-nocookie.com as a proxy for redirects
  if (chrome.webNavigation?.onCompleted) {
    chrome.webNavigation.onCompleted.addListener((details) => {
      if (details.frameId === 0 && details.url.includes('youtube-nocookie.com/embed/')) {
        incrementVideoCount();
        console.log('[FreeYT] Redirect tracked via navigation:', details.url);
      }
    }, { url: [{ hostContains: 'youtube-nocookie.com' }] });
    console.log('[FreeYT] Redirect tracking enabled via webNavigation fallback');
  }
}

// ============================================================================
// NATIVE APP SYNC
// ============================================================================

// Sync state with native app via Safari's native messaging
async function syncWithNativeApp() {
  try {
    const response = await browser.runtime.sendNativeMessage('com.freeyt.app.extension', {
      action: 'getSharedState'
    });

    if (response?.enabled !== undefined) {
      const currentResult = await chrome.storage.local.get(STORAGE_KEY);
      const currentEnabled = currentResult[STORAGE_KEY] ?? true;

      // Only update if different (avoid loops)
      if (response.enabled !== currentEnabled) {
        await chrome.storage.local.set({ [STORAGE_KEY]: response.enabled });
        if (response.enabled) {
          await enableRedirects();
        } else {
          await disableRedirects();
        }
        console.log('[FreeYT] Synced enabled state from native app:', response.enabled);
      }
    }

    if (response?.videoCount !== undefined) {
      const localCount = await getVideoCount();
      // Use the higher count (in case either side has more recent data)
      const maxCount = Math.max(localCount, response.videoCount);
      if (maxCount !== localCount) {
        await chrome.storage.local.set({ [VIDEO_COUNT_KEY]: maxCount });
        console.log('[FreeYT] Synced video count from native app:', maxCount);
      }
    }

    console.log('[FreeYT] Native app sync completed successfully');
    return response;
  } catch (e) {
    console.log('[FreeYT] Native sync skipped:', e.message || 'unavailable');
    return null;
  }
}

// Notify native app when enabled state changes
async function notifyNativeAppStateChange(enabled) {
  try {
    await browser.runtime.sendNativeMessage('com.freeyt.app.extension', {
      action: 'setEnabled',
      enabled: enabled
    });
    console.log('[FreeYT] Native app notified of state change:', enabled);
  } catch (e) {
    console.log('[FreeYT] Failed to notify native app:', e.message || 'unavailable');
  }
}

// ============================================================================
// ALLOWLIST RULES
// ============================================================================

// Dynamic rule IDs for allowlist start at 1000 to avoid conflicts with static rules
const ALLOWLIST_RULE_BASE = 1000;

// Update dynamic rules to allow specific domains to bypass redirects
async function updateAllowlistRules(allowlist) {
  try {
    // Remove all existing allowlist dynamic rules
    const existingRules = await chrome.declarativeNetRequest.getDynamicRules();
    const existingIds = existingRules
      .filter(r => r.id >= ALLOWLIST_RULE_BASE)
      .map(r => r.id);

    const addRules = allowlist.map((pattern, index) => ({
      id: ALLOWLIST_RULE_BASE + index,
      priority: 10, // Higher than redirect rules (priority 1)
      action: { type: 'allowAllRequests' },
      condition: {
        urlFilter: `*://${pattern}/*`,
        resourceTypes: ['main_frame']
      }
    }));

    await chrome.declarativeNetRequest.updateDynamicRules({
      removeRuleIds: existingIds,
      addRules: addRules
    });
    console.log('[FreeYT] Allowlist rules updated:', allowlist.length, 'patterns');
  } catch (error) {
    console.error('[FreeYT] Failed to update allowlist rules:', error);
  }
}

// Restore allowlist rules on startup
async function restoreAllowlistRules() {
  const result = await chrome.storage.local.get(ALLOWLIST_KEY);
  const list = result[ALLOWLIST_KEY] || [];
  if (list.length > 0) {
    await updateAllowlistRules(list);
  }
}

// ============================================================================
// MESSAGE HANDLERS
// ============================================================================

// Handle messages from popup
chrome.runtime.onMessage.addListener((request, sender, sendResponse) => {
  console.log('[FreeYT] Received message:', request);

  if (request.action === 'getState') {
    // Return current enabled state and video count
    Promise.all([
      chrome.storage.local.get(STORAGE_KEY),
      getVideoCount()
    ]).then(([result, count]) => {
      sendResponse({
        enabled: result[STORAGE_KEY] ?? true,
        videoCount: count
      });
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
      // Notify native app of state change
      await notifyNativeAppStateChange(enabled);
      console.log('[FreeYT] State updated:', enabled ? 'enabled' : 'disabled');
      sendResponse({ success: true });
    });
    return true; // Keep channel open for async response
  }

  if (request.action === 'getVideoCount') {
    getVideoCount().then(count => {
      sendResponse({ count: count });
    });
    return true;
  }

  if (request.action === 'getAllowlist') {
    chrome.storage.local.get(ALLOWLIST_KEY).then(result => {
      sendResponse({ allowlist: result[ALLOWLIST_KEY] || [] });
    });
    return true;
  }

  if (request.action === 'addToAllowlist') {
    const pattern = request.pattern;
    chrome.storage.local.get(ALLOWLIST_KEY).then(async result => {
      const list = result[ALLOWLIST_KEY] || [];
      if (!list.includes(pattern)) {
        list.push(pattern);
        await chrome.storage.local.set({ [ALLOWLIST_KEY]: list });
        await updateAllowlistRules(list);
      }
      sendResponse({ success: true, allowlist: list });
    });
    return true;
  }

  if (request.action === 'removeFromAllowlist') {
    const pattern = request.pattern;
    chrome.storage.local.get(ALLOWLIST_KEY).then(async result => {
      let list = result[ALLOWLIST_KEY] || [];
      list = list.filter(p => p !== pattern);
      await chrome.storage.local.set({ [ALLOWLIST_KEY]: list });
      await updateAllowlistRules(list);
      sendResponse({ success: true, allowlist: list });
    });
    return true;
  }

  if (request.action === 'getDailyStats') {
    (async () => {
      const days = 7;
      const keys = [];
      for (let i = 0; i < days; i++) {
        const d = new Date();
        d.setDate(d.getDate() - i);
        keys.push(DAILY_COUNT_PREFIX + d.toISOString().slice(0, 10));
      }
      const result = await chrome.storage.local.get(keys);
      const stats = {};
      keys.forEach(k => { stats[k.slice(DAILY_COUNT_PREFIX.length)] = result[k] || 0; });
      sendResponse({ stats });
    })();
    return true;
  }

  if (request.action === 'syncWithNative') {
    syncWithNativeApp().then(response => {
      sendResponse({ success: true, response: response });
    }).catch(err => {
      sendResponse({ success: false, error: err.message });
    });
    return true;
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
syncWithNativeApp().catch(err => console.log('[FreeYT] Initial native sync skipped'));
restoreAllowlistRules().catch(err => console.log('[FreeYT] Allowlist restore skipped:', err));

console.log('[FreeYT] Background service worker loaded at', new Date().toISOString());
