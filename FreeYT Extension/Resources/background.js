// FreeYT background service worker
// Maintains dashboard state, recent activity, exception rules, and host-app sync.

const STORAGE_KEY = 'enabled';
const VIDEO_COUNT_KEY = 'videoCount';
const ALLOWLIST_KEY = 'allowlist';
const RECENT_ACTIVITY_KEY = 'recentActivity';
const LAST_PROTECTED_AT_KEY = 'lastProtectedAt';
const LAST_SYNC_TIMESTAMP_KEY = 'dashboardSyncTimestamp';
const LAST_SYNC_STATE_KEY = 'lastSyncState';

const RULESET_ID = 'ruleset_1';
const DAILY_COUNT_PREFIX = 'count_';
const ALLOWLIST_RULE_BASE = 1000;
const MAX_RECENT_ACTIVITY = 12;

const SYNC_STATES = {
  synced: 'Synced',
  pending: 'Pending Safari sync',
  unavailable: 'Safari unavailable',
  issue: 'Sync issue'
};

function nowIso() {
  return new Date().toISOString();
}

function todayKey(date = new Date()) {
  return DAILY_COUNT_PREFIX + date.toISOString().slice(0, 10);
}

function normalizeDomain(domain) {
  return String(domain || '').trim().toLowerCase();
}

function displayHost(hostname) {
  return normalizeDomain(hostname).replace(/^www\./, '').replace(/^m\./, '');
}

function classifyURL(url) {
  if (url.includes('/shorts/')) return 'shorts';
  if (url.includes('/live/')) return 'live';
  if (url.includes('/embed/')) return 'embed';
  if (url.includes('youtu.be/')) return 'shortLink';
  if (url.includes('/v/')) return 'legacy';
  if (url.includes('/watch')) return 'watch';
  return 'unknown';
}

function extractHost(url) {
  try {
    const hostname = new URL(url).hostname;
    return hostname.includes('youtube-nocookie.com') ? 'youtube.com' : hostname;
  } catch {
    return 'youtube.com';
  }
}

function toUnixSeconds(value) {
  if (!value) return null;
  const ms = typeof value === 'number' ? value : Date.parse(value);
  if (!Number.isFinite(ms)) return null;
  return Math.floor(ms / 1000);
}

function toIsoString(value) {
  if (!value) return null;
  if (typeof value === 'string') return value;
  if (typeof value === 'number') return new Date(value * 1000).toISOString();
  return null;
}

function createActivity(url, timestampMs = Date.now()) {
  const host = displayHost(extractHost(url));
  const seconds = Math.floor(timestampMs / 1000);
  return {
    id: `${host}-${seconds}`,
    host,
    kind: classifyURL(url),
    timestamp: seconds
  };
}

function isNativeMessagingAvailable() {
  return typeof browser !== 'undefined' && typeof browser.runtime?.sendNativeMessage === 'function';
}

async function getEnabled() {
  const result = await chrome.storage.local.get(STORAGE_KEY);
  return result[STORAGE_KEY] ?? true;
}

async function getVideoCount() {
  const result = await chrome.storage.local.get(VIDEO_COUNT_KEY);
  return result[VIDEO_COUNT_KEY] ?? 0;
}

async function getAllowlist() {
  const result = await chrome.storage.local.get(ALLOWLIST_KEY);
  return result[ALLOWLIST_KEY] ?? [];
}

async function getRecentActivity() {
  const result = await chrome.storage.local.get(RECENT_ACTIVITY_KEY);
  return result[RECENT_ACTIVITY_KEY] ?? [];
}

async function getDailyStats(days = 7) {
  const keys = [];
  for (let i = 0; i < days; i += 1) {
    const date = new Date();
    date.setDate(date.getDate() - i);
    keys.push(DAILY_COUNT_PREFIX + date.toISOString().slice(0, 10));
  }

  const result = await chrome.storage.local.get(keys);
  const stats = {};
  keys.forEach((key) => {
    stats[key.slice(DAILY_COUNT_PREFIX.length)] = result[key] ?? 0;
  });
  return stats;
}

async function getCurrentSiteInfo() {
  if (!chrome.tabs?.query) {
    return null;
  }

  try {
    const tabs = await chrome.tabs.query({ active: true, currentWindow: true });
    const tab = tabs?.[0];
    if (!tab?.url) return null;

    const url = new URL(tab.url);
    const domain = normalizeDomain(url.hostname);
    const allowlist = await getAllowlist();
    const supported = /youtube\.com$|youtu\.be$|youtube-nocookie\.com$/.test(domain);

    return {
      domain,
      displayDomain: displayHost(domain),
      isException: allowlist.includes(domain),
      isSupportedDomain: supported
    };
  } catch (error) {
    console.log('[FreeYT] Could not read active tab for current site info');
    return null;
  }
}

async function updateLocalSyncState(state, timestamp = nowIso()) {
  await chrome.storage.local.set({
    [LAST_SYNC_STATE_KEY]: state,
    [LAST_SYNC_TIMESTAMP_KEY]: timestamp
  });
}

async function buildDashboardState() {
  const [enabled, videoCount, exceptions, recentActivity, dailyCounts, currentSite, storage] = await Promise.all([
    getEnabled(),
    getVideoCount(),
    getAllowlist(),
    getRecentActivity(),
    getDailyStats(7),
    getCurrentSiteInfo(),
    chrome.storage.local.get([LAST_PROTECTED_AT_KEY, LAST_SYNC_TIMESTAMP_KEY, LAST_SYNC_STATE_KEY])
  ]);

  return {
    enabled,
    videoCount,
    dailyCounts,
    recentActivity,
    exceptions,
    allowlist: exceptions,
    lastProtectedAt: toUnixSeconds(storage[LAST_PROTECTED_AT_KEY]),
    lastSyncTimestamp: toUnixSeconds(storage[LAST_SYNC_TIMESTAMP_KEY]),
    lastSyncState: storage[LAST_SYNC_STATE_KEY] ?? SYNC_STATES.unavailable,
    currentSite,
    todayCount: Object.values(dailyCounts)[0] ?? 0,
    weekCount: Object.values(dailyCounts).reduce((sum, value) => sum + value, 0)
  };
}

async function pushDashboardStateToNative(state) {
  if (!isNativeMessagingAvailable()) {
    await updateLocalSyncState(SYNC_STATES.unavailable);
    return false;
  }

  const snapshot = state ?? await buildDashboardState();
  try {
    await browser.runtime.sendNativeMessage('com.freeyt.app.extension', {
      action: 'syncDashboardState',
      enabled: snapshot.enabled,
      videoCount: snapshot.videoCount,
      dailyCounts: snapshot.dailyCounts,
      recentActivity: snapshot.recentActivity,
      exceptions: snapshot.exceptions,
      lastProtectedAt: snapshot.lastProtectedAt,
      lastSyncTimestamp: snapshot.lastSyncTimestamp,
      lastSyncState: SYNC_STATES.synced
    });
    await updateLocalSyncState(SYNC_STATES.synced);
    return true;
  } catch (error) {
    console.log('[FreeYT] Native sync skipped:', error?.message || 'unavailable');
    await updateLocalSyncState(SYNC_STATES.unavailable);
    return false;
  }
}

async function enableRedirects() {
  try {
    await chrome.declarativeNetRequest.updateEnabledRulesets({
      enableRulesetIds: [RULESET_ID]
    });
  } catch (error) {
    console.error('[FreeYT] Failed to enable redirect rules:', error);
  }
}

async function disableRedirects() {
  try {
    await chrome.declarativeNetRequest.updateEnabledRulesets({
      disableRulesetIds: [RULESET_ID]
    });
  } catch (error) {
    console.error('[FreeYT] Failed to disable redirect rules:', error);
  }
}

async function syncRulesToStorage() {
  const [enabled, enabledRulesets] = await Promise.all([
    getEnabled(),
    chrome.declarativeNetRequest.getEnabledRulesets()
  ]);

  const isEnabled = enabledRulesets.includes(RULESET_ID);
  if (enabled && !isEnabled) {
    await enableRedirects();
  } else if (!enabled && isEnabled) {
    await disableRedirects();
  }
}

async function updateAllowlistRules(allowlist) {
  try {
    const existingRules = await chrome.declarativeNetRequest.getDynamicRules();
    const existingIds = existingRules
      .filter((rule) => rule.id >= ALLOWLIST_RULE_BASE)
      .map((rule) => rule.id);

    const addRules = allowlist.map((domain, index) => ({
      id: ALLOWLIST_RULE_BASE + index,
      priority: 10,
      action: { type: 'allowAllRequests' },
      condition: {
        urlFilter: `*://${domain}/*`,
        resourceTypes: ['main_frame']
      }
    }));

    await chrome.declarativeNetRequest.updateDynamicRules({
      removeRuleIds: existingIds,
      addRules
    });
  } catch (error) {
    console.error('[FreeYT] Failed to update exception rules:', error);
  }
}

async function setAllowlist(nextAllowlist, syncState = SYNC_STATES.synced) {
  const normalized = Array.from(new Set(nextAllowlist.map(normalizeDomain))).filter(Boolean).sort();
  const timestamp = nowIso();

  await chrome.storage.local.set({
    [ALLOWLIST_KEY]: normalized,
    [LAST_SYNC_TIMESTAMP_KEY]: timestamp,
    [LAST_SYNC_STATE_KEY]: syncState
  });

  await updateAllowlistRules(normalized);
  await pushDashboardStateToNative(await buildDashboardState());
  return normalized;
}

async function toggleCurrentSiteException() {
  const currentSite = await getCurrentSiteInfo();
  if (!currentSite?.domain || !currentSite.isSupportedDomain) {
    return { success: false, error: 'No supported active site found.' };
  }

  const allowlist = await getAllowlist();
  const next = currentSite.isException
    ? allowlist.filter((domain) => domain !== currentSite.domain)
    : [...allowlist, currentSite.domain];

  const exceptions = await setAllowlist(next);
  const refreshedSite = await getCurrentSiteInfo();

  return {
    success: true,
    exceptions,
    allowlist: exceptions,
    currentSite: refreshedSite
  };
}

async function applyNativeSnapshot(snapshot) {
  const exceptions = Array.isArray(snapshot.exceptions) ? snapshot.exceptions.map(normalizeDomain).filter(Boolean) : [];
  const recentActivity = Array.isArray(snapshot.recentActivity) ? snapshot.recentActivity.slice(0, MAX_RECENT_ACTIVITY) : [];
  const enabled = snapshot.enabled ?? true;
  const videoCount = snapshot.videoCount ?? 0;
  const syncTimestampIso = toIsoString(snapshot.lastSyncTimestamp) ?? nowIso();
  const syncState = snapshot.lastSyncState || SYNC_STATES.synced;
  const dailyCounts = snapshot.dailyCounts && typeof snapshot.dailyCounts === 'object' ? snapshot.dailyCounts : {};

  const existing = await chrome.storage.local.get(null);
  const removeKeys = Object.keys(existing).filter((key) => key.startsWith(DAILY_COUNT_PREFIX));
  if (removeKeys.length > 0) {
    await chrome.storage.local.remove(removeKeys);
  }

  const dailyPayload = Object.fromEntries(
    Object.entries(dailyCounts).map(([key, value]) => [`${DAILY_COUNT_PREFIX}${key}`, value])
  );

  await chrome.storage.local.set({
    [STORAGE_KEY]: enabled,
    [VIDEO_COUNT_KEY]: videoCount,
    [ALLOWLIST_KEY]: exceptions,
    [RECENT_ACTIVITY_KEY]: recentActivity,
    [LAST_PROTECTED_AT_KEY]: toIsoString(snapshot.lastProtectedAt),
    [LAST_SYNC_TIMESTAMP_KEY]: syncTimestampIso,
    [LAST_SYNC_STATE_KEY]: syncState,
    ...dailyPayload
  });

  await updateAllowlistRules(exceptions);
  await syncRulesToStorage();
}

async function syncWithNativeApp() {
  if (!isNativeMessagingAvailable()) {
    await updateLocalSyncState(SYNC_STATES.unavailable);
    return null;
  }

  try {
    const nativeSnapshot = await browser.runtime.sendNativeMessage('com.freeyt.app.extension', {
      action: 'getDashboardSnapshot'
    });

    const localSnapshot = await buildDashboardState();
    const localTimestamp = (localSnapshot.lastSyncTimestamp ?? 0) * 1000;
    const nativeTimestamp = (nativeSnapshot.lastSyncTimestamp ?? 0) * 1000;

    if (nativeTimestamp > localTimestamp) {
      await applyNativeSnapshot(nativeSnapshot);
      await pushDashboardStateToNative(await buildDashboardState());
      return buildDashboardState();
    }

    if (localTimestamp > nativeTimestamp) {
      await pushDashboardStateToNative(localSnapshot);
    } else {
      await updateLocalSyncState(SYNC_STATES.synced);
    }

    return localSnapshot;
  } catch (error) {
    console.log('[FreeYT] Native sync skipped:', error?.message || 'unavailable');
    await updateLocalSyncState(SYNC_STATES.unavailable);
    return null;
  }
}

async function recordRedirect(rawURL) {
  const now = Date.now();
  const timestamp = nowIso();
  const dayKey = todayKey(new Date(now));
  const [videoCount, recentActivity, existingDayCount] = await Promise.all([
    getVideoCount(),
    getRecentActivity(),
    chrome.storage.local.get(dayKey)
  ]);

  const activity = createActivity(rawURL, now);
  const nextRecentActivity = [
    activity,
    ...recentActivity.filter((item) => item.id !== activity.id)
  ].slice(0, MAX_RECENT_ACTIVITY);

  await chrome.storage.local.set({
    [VIDEO_COUNT_KEY]: videoCount + 1,
    [RECENT_ACTIVITY_KEY]: nextRecentActivity,
    [LAST_PROTECTED_AT_KEY]: timestamp,
    [LAST_SYNC_TIMESTAMP_KEY]: timestamp,
    [LAST_SYNC_STATE_KEY]: SYNC_STATES.synced,
    [dayKey]: (existingDayCount[dayKey] ?? 0) + 1
  });

  await pushDashboardStateToNative(await buildDashboardState());
  return videoCount + 1;
}

async function initializeState() {
  const result = await chrome.storage.local.get([STORAGE_KEY, VIDEO_COUNT_KEY, ALLOWLIST_KEY]);
  if (result[STORAGE_KEY] === undefined) {
    await chrome.storage.local.set({
      [STORAGE_KEY]: true,
      [VIDEO_COUNT_KEY]: 0,
      [ALLOWLIST_KEY]: [],
      [LAST_SYNC_STATE_KEY]: SYNC_STATES.pending,
      [LAST_SYNC_TIMESTAMP_KEY]: nowIso()
    });
    await enableRedirects();
  }

  await cleanupOldDailyStats();
  await syncRulesToStorage();
  await updateAllowlistRules(result[ALLOWLIST_KEY] ?? []);
  await syncWithNativeApp();
}

async function cleanupOldDailyStats() {
  const allKeys = await chrome.storage.local.get(null);
  const cutoff = new Date();
  cutoff.setDate(cutoff.getDate() - 90);
  const cutoffString = cutoff.toISOString().slice(0, 10);
  const oldKeys = Object.keys(allKeys).filter(
    (key) => key.startsWith(DAILY_COUNT_PREFIX) && key.slice(DAILY_COUNT_PREFIX.length) < cutoffString
  );
  if (oldKeys.length > 0) {
    await chrome.storage.local.remove(oldKeys);
  }
}

chrome.runtime.onInstalled.addListener(async () => {
  console.log('[FreeYT] Extension installed');
  await initializeState();
});

chrome.runtime.onStartup?.addListener(() => {
  initializeState().catch((error) => console.error('[FreeYT] Startup init failed:', error));
});

chrome.runtime.onSuspend?.addListener(() => {
  console.log('[FreeYT] Service worker suspending at', nowIso());
});

if (chrome.declarativeNetRequest.onRuleMatchedDebug) {
  chrome.declarativeNetRequest.onRuleMatchedDebug.addListener((info) => {
    if (info.rule.rulesetId === RULESET_ID) {
      recordRedirect(info.request?.url || 'https://youtube.com/watch')
        .catch((error) => console.error('[FreeYT] Failed to record redirect:', error));
    }
  });
} else if (chrome.webNavigation?.onCompleted) {
  chrome.webNavigation.onCompleted.addListener((details) => {
    if (details.frameId === 0 && details.url.includes('youtube-nocookie.com/embed/')) {
      recordRedirect(details.url)
        .catch((error) => console.error('[FreeYT] Failed to record fallback redirect:', error));
    }
  }, { url: [{ hostContains: 'youtube-nocookie.com' }] });
}

chrome.runtime.onMessage.addListener((request, sender, sendResponse) => {
  (async () => {
    switch (request.action) {
      case 'getDashboardState':
        sendResponse(await buildDashboardState());
        return;

      case 'getState': {
        const state = await buildDashboardState();
        sendResponse({ enabled: state.enabled, videoCount: state.videoCount });
        return;
      }

      case 'setState': {
        const enabled = request.enabled ?? true;
        await chrome.storage.local.set({
          [STORAGE_KEY]: enabled,
          [LAST_SYNC_TIMESTAMP_KEY]: nowIso(),
          [LAST_SYNC_STATE_KEY]: SYNC_STATES.synced
        });
        await syncRulesToStorage();
        await pushDashboardStateToNative(await buildDashboardState());
        sendResponse({ success: true });
        return;
      }

      case 'getAllowlist': {
        const allowlist = await getAllowlist();
        sendResponse({ allowlist, exceptions: allowlist });
        return;
      }

      case 'addToAllowlist': {
        const allowlist = await getAllowlist();
        const next = [...allowlist, request.pattern];
        const exceptions = await setAllowlist(next);
        sendResponse({ success: true, allowlist: exceptions, exceptions });
        return;
      }

      case 'removeFromAllowlist': {
        const allowlist = await getAllowlist();
        const next = allowlist.filter((domain) => domain !== request.pattern);
        const exceptions = await setAllowlist(next);
        sendResponse({ success: true, allowlist: exceptions, exceptions });
        return;
      }

      case 'toggleCurrentSiteException':
        sendResponse(await toggleCurrentSiteException());
        return;

      case 'getDailyStats':
        sendResponse({ stats: await getDailyStats(7) });
        return;

      case 'getRecentActivity':
        sendResponse({ recentActivity: await getRecentActivity() });
        return;

      case 'syncWithNative':
        await syncWithNativeApp();
        sendResponse({ success: true, state: await buildDashboardState() });
        return;

      case 'openDashboard':
        if (!isNativeMessagingAvailable()) {
          sendResponse({ success: false, error: 'Native messaging unavailable.' });
          return;
        }
        try {
          const response = await browser.runtime.sendNativeMessage('com.freeyt.app.extension', {
            action: 'openDashboard',
            section: request.section || 'dashboard'
          });
          sendResponse(response);
        } catch (error) {
          sendResponse({ success: false, error: error?.message || 'Could not open FreeYT.' });
        }
        return;

      default:
        sendResponse({ success: false, error: `Unknown action: ${request.action}` });
    }
  })().catch((error) => {
    console.error('[FreeYT] Message handler failed:', error);
    sendResponse({ success: false, error: error?.message || 'Unexpected background failure.' });
  });

  return true;
});

chrome.storage.onChanged.addListener(async (changes, areaName) => {
  if (areaName === 'local' && changes[STORAGE_KEY]) {
    await syncRulesToStorage();
  }
});

initializeState().catch((error) => console.error('[FreeYT] Initial sync failed:', error));
console.log('[FreeYT] Background service worker loaded at', nowIso());
