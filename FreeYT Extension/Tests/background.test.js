import { describe, it } from 'node:test';
import assert from 'node:assert/strict';
import { readFileSync } from 'node:fs';
import { dirname, join } from 'node:path';
import { fileURLToPath } from 'node:url';
import vm from 'node:vm';

const __filename = fileURLToPath(import.meta.url);
const __dirname = dirname(__filename);
const backgroundSource = readFileSync(join(__dirname, '..', 'Resources', 'background.js'), 'utf8');

function flushPromises() {
  return new Promise((resolve) => setImmediate(resolve));
}

async function settle() {
  await flushPromises();
  await flushPromises();
  await flushPromises();
}

function createBackgroundHarness({
  activeTabUrl = 'https://www.youtube.com/watch?v=dQw4w9WgXcQ',
  nativeSnapshot = {}
} = {}) {
  const storageData = {};
  const enabledRulesets = new Set();
  let dynamicRules = [];

  const listeners = {
    onInstalled: null,
    onStartup: null,
    onSuspend: null,
    onMessage: null,
    onChanged: null,
    onRuleMatchedDebug: null,
    onCompleted: null
  };

  const nativeMessages = [];

  const storageLocal = {
    async get(keys) {
      if (keys == null) {
        return { ...storageData };
      }

      if (typeof keys === 'string') {
        return { [keys]: storageData[keys] };
      }

      if (Array.isArray(keys)) {
        return Object.fromEntries(keys.map((key) => [key, storageData[key]]));
      }

      if (typeof keys === 'object') {
        return Object.fromEntries(
          Object.entries(keys).map(([key, fallback]) => [key, storageData[key] ?? fallback])
        );
      }

      return {};
    },

    async set(nextValues) {
      const changes = {};
      for (const [key, newValue] of Object.entries(nextValues)) {
        const oldValue = storageData[key];
        storageData[key] = newValue;
        changes[key] = { oldValue, newValue };
      }

      if (listeners.onChanged) {
        await listeners.onChanged(changes, 'local');
      }
    },

    async remove(keys) {
      const entries = Array.isArray(keys) ? keys : [keys];
      const changes = {};
      for (const key of entries) {
        if (Object.prototype.hasOwnProperty.call(storageData, key)) {
          changes[key] = { oldValue: storageData[key], newValue: undefined };
          delete storageData[key];
        }
      }

      if (listeners.onChanged && Object.keys(changes).length > 0) {
        await listeners.onChanged(changes, 'local');
      }
    }
  };

  const chrome = {
    storage: {
      local: storageLocal,
      onChanged: {
        addListener(callback) {
          listeners.onChanged = callback;
        }
      }
    },
    declarativeNetRequest: {
      async updateEnabledRulesets({ enableRulesetIds = [], disableRulesetIds = [] }) {
        enableRulesetIds.forEach((id) => enabledRulesets.add(id));
        disableRulesetIds.forEach((id) => enabledRulesets.delete(id));
      },
      async getEnabledRulesets() {
        return Array.from(enabledRulesets);
      },
      async getDynamicRules() {
        return dynamicRules.slice();
      },
      async updateDynamicRules({ removeRuleIds = [], addRules = [] }) {
        dynamicRules = dynamicRules
          .filter((rule) => !removeRuleIds.includes(rule.id))
          .concat(addRules);
      },
      onRuleMatchedDebug: {
        addListener(callback) {
          listeners.onRuleMatchedDebug = callback;
        }
      }
    },
    runtime: {
      onInstalled: {
        addListener(callback) {
          listeners.onInstalled = callback;
        }
      },
      onStartup: {
        addListener(callback) {
          listeners.onStartup = callback;
        }
      },
      onSuspend: {
        addListener(callback) {
          listeners.onSuspend = callback;
        }
      },
      onMessage: {
        addListener(callback) {
          listeners.onMessage = callback;
        }
      }
    },
    tabs: {
      async query() {
        return [{ url: activeTabUrl }];
      }
    },
    webNavigation: {
      onCompleted: {
        addListener(callback) {
          listeners.onCompleted = callback;
        }
      }
    }
  };

  const browser = {
    runtime: {
      async sendNativeMessage(_identifier, message) {
        nativeMessages.push(message);

        if (message.action === 'getDashboardSnapshot') {
          return nativeSnapshot;
        }

        if (message.action === 'openDashboard') {
          return { success: true };
        }

        if (message.action === 'syncDashboardState') {
          return { success: true };
        }

        return {};
      }
    }
  };

  const context = vm.createContext({
    chrome,
    browser,
    URL,
    console: {
      log() {},
      error() {}
    },
    setTimeout,
    clearTimeout
  });

  vm.runInContext(backgroundSource, context, { filename: 'background.js' });

  return {
    listeners,
    storageData,
    nativeMessages,
    get enabledRulesets() {
      return enabledRulesets;
    },
    get dynamicRules() {
      return dynamicRules;
    }
  };
}

async function loadBackground(options = {}) {
  const harness = createBackgroundHarness(options);
  await settle();
  return harness;
}

async function sendMessage(harness, request) {
  return new Promise((resolve, reject) => {
    const timeout = setTimeout(() => reject(new Error(`No response for ${request.action}`)), 200);

    harness.listeners.onMessage(request, {}, (response) => {
      clearTimeout(timeout);
      resolve(response);
    });
  });
}

describe('background.js dashboard state', () => {
  it('initializes with enabled protection, a sync timestamp, and no exceptions', async () => {
    const harness = await loadBackground();

    assert.equal(harness.storageData.enabled, true);
    assert.deepEqual(Array.from(harness.storageData.allowlist ?? []), []);
    assert.ok(typeof harness.storageData.dashboardSyncTimestamp === 'string');
    assert.equal(harness.storageData.dashboardSyncRevision, 0);
    assert.ok(harness.enabledRulesets.has('ruleset_1'));
  });

  it('records redirect activity into all-time, today, and recent activity surfaces', async () => {
    const harness = await loadBackground();

    await harness.listeners.onRuleMatchedDebug({
      rule: { rulesetId: 'ruleset_1' },
      request: { url: 'https://www.youtube.com/watch?v=abc123xyz98' }
    });
    await settle();

    const state = await sendMessage(harness, { action: 'getDashboardState' });
    const todayKey = Object.keys(state.dailyCounts)[0];

    assert.equal(state.videoCount, 1);
    assert.equal(state.todayCount, 1);
    assert.equal(state.dailyCounts[todayKey], 1);
    assert.equal(state.recentActivity.length, 1);
    assert.equal(state.recentActivity[0].host, 'youtube.com');
    assert.equal(state.recentActivity[0].kind, 'watch');
  });

  it('adds and removes a quick exception for the active YouTube tab', async () => {
    const harness = await loadBackground({
      activeTabUrl: 'https://music.youtube.com/watch?v=abc123xyz98'
    });

    const added = await sendMessage(harness, { action: 'toggleCurrentSiteException' });
    assert.equal(added.success, true);
    assert.deepEqual(Array.from(added.exceptions), ['music.youtube.com']);
    assert.equal(added.currentSite.isException, true);
    assert.equal(harness.dynamicRules.length, 1);
    assert.equal(harness.dynamicRules[0].condition.urlFilter, '*://music.youtube.com/*');

    const removed = await sendMessage(harness, { action: 'toggleCurrentSiteException' });
    assert.equal(removed.success, true);
    assert.deepEqual(Array.from(removed.exceptions), []);
    assert.equal(removed.currentSite.isException, false);
    assert.equal(harness.dynamicRules.length, 0);
  });

  it('keeps legacy allowlist messaging compatible with the new exceptions UI', async () => {
    const harness = await loadBackground();

    const addResponse = await sendMessage(harness, {
      action: 'addToAllowlist',
      pattern: 'music.youtube.com'
    });
    assert.equal(addResponse.success, true);
    assert.deepEqual(Array.from(addResponse.allowlist), ['music.youtube.com']);
    assert.deepEqual(Array.from(addResponse.exceptions), ['music.youtube.com']);

    const listResponse = await sendMessage(harness, { action: 'getAllowlist' });
    assert.deepEqual(Array.from(listResponse.allowlist), ['music.youtube.com']);
    assert.deepEqual(Array.from(listResponse.exceptions), ['music.youtube.com']);
  });

  it('rejects unsupported manual exceptions before touching storage or rules', async () => {
    const harness = await loadBackground();

    const response = await sendMessage(harness, {
      action: 'addToAllowlist',
      pattern: 'example.com'
    });

    assert.equal(response.success, false);
    assert.equal(response.error, 'Use a supported YouTube domain like music.youtube.com.');
    assert.deepEqual(Array.from(harness.storageData.allowlist ?? []), []);
    assert.equal(harness.dynamicRules.length, 0);
  });

  it('does not offer quick exceptions on privacy-enhanced youtube-nocookie pages', async () => {
    const harness = await loadBackground({
      activeTabUrl: 'https://www.youtube-nocookie.com/embed/abc123xyz98?autoplay=1'
    });

    const state = await sendMessage(harness, { action: 'getDashboardState' });
    assert.equal(state.currentSite.domain, 'www.youtube-nocookie.com');
    assert.equal(state.currentSite.isSupportedDomain, false);

    const toggle = await sendMessage(harness, { action: 'toggleCurrentSiteException' });
    assert.equal(toggle.success, false);
    assert.equal(toggle.error, 'No supported active site found.');
    assert.deepEqual(Array.from(harness.storageData.allowlist ?? []), []);
  });

  it('prefers a newer native snapshot when the native revision is higher', async () => {
    const timestamp = Math.floor(Date.now() / 1000);
    const today = new Date(timestamp * 1000).toISOString().slice(0, 10);
    const nativeSnapshot = {
      enabled: false,
      videoCount: 5,
      dailyCounts: { [today]: 5 },
      recentActivity: [],
      exceptions: ['music.youtube.com'],
      lastProtectedAt: timestamp,
      lastSyncState: 'Synced',
      lastSyncTimestamp: timestamp,
      lastSyncRevision: 3
    };

    const harness = await loadBackground({ nativeSnapshot });
    const state = await sendMessage(harness, { action: 'getDashboardState' });

    assert.equal(state.enabled, false);
    assert.equal(state.videoCount, 5);
    assert.deepEqual(Array.from(state.exceptions), ['music.youtube.com']);
    assert.equal(state.lastSyncRevision, 3);
    assert.equal(harness.storageData.dashboardSyncRevision, 3);
  });

  it('pushes the local snapshot when the local revision is newer than native', async () => {
    const nativeSnapshot = {
      enabled: true,
      videoCount: 0,
      dailyCounts: {},
      recentActivity: [],
      exceptions: [],
      lastSyncState: 'Synced',
      lastSyncTimestamp: 0,
      lastSyncRevision: 0
    };

    const harness = await loadBackground({ nativeSnapshot });
    harness.nativeMessages.length = 0;

    await sendMessage(harness, { action: 'setState', enabled: false });
    nativeSnapshot.enabled = true;
    nativeSnapshot.lastSyncRevision = 0;
    nativeSnapshot.lastSyncTimestamp = 0;
    harness.nativeMessages.length = 0;

    const response = await sendMessage(harness, { action: 'syncWithNative' });
    const push = harness.nativeMessages.find((message) => message.action === 'syncDashboardState');

    assert.equal(response.success, true);
    assert.equal(response.state.enabled, false);
    assert.equal(response.state.lastSyncRevision, 1);
    assert.equal(push.enabled, false);
    assert.equal(push.lastSyncRevision, 1);
  });
});
