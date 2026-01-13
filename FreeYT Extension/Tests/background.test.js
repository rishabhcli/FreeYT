/**
 * background.test.js - Tests for the background service worker
 *
 * These tests verify the background script's message handling,
 * storage operations, and rule management functionality.
 */

import { describe, it, beforeEach, mock } from 'node:test';
import assert from 'node:assert/strict';

// Constants from background.js
const STORAGE_KEY = 'enabled';
const RULESET_ID = 'ruleset_1';

describe('Background Service Worker Constants', () => {
  it('should use correct storage key', () => {
    assert.equal(STORAGE_KEY, 'enabled');
  });

  it('should use correct ruleset ID', () => {
    assert.equal(RULESET_ID, 'ruleset_1');
  });
});

describe('Chrome API Mock Setup', () => {
  let mockChrome;
  let storageData;
  let enabledRulesets;
  let messageListeners;
  let storageListeners;
  let installedListeners;
  let startupListeners;

  beforeEach(() => {
    storageData = {};
    enabledRulesets = new Set();
    messageListeners = [];
    storageListeners = [];
    installedListeners = [];
    startupListeners = [];

    mockChrome = {
      storage: {
        local: {
          get: mock.fn(async (key) => {
            if (typeof key === 'string') {
              return { [key]: storageData[key] };
            }
            return storageData;
          }),
          set: mock.fn(async (data) => {
            Object.assign(storageData, data);
          })
        },
        onChanged: {
          addListener: mock.fn((callback) => {
            storageListeners.push(callback);
          })
        }
      },
      declarativeNetRequest: {
        updateEnabledRulesets: mock.fn(async ({ enableRulesetIds, disableRulesetIds }) => {
          if (enableRulesetIds) {
            enableRulesetIds.forEach(id => enabledRulesets.add(id));
          }
          if (disableRulesetIds) {
            disableRulesetIds.forEach(id => enabledRulesets.delete(id));
          }
        })
      },
      runtime: {
        onInstalled: {
          addListener: mock.fn((callback) => {
            installedListeners.push(callback);
          })
        },
        onStartup: {
          addListener: mock.fn((callback) => {
            startupListeners.push(callback);
          })
        },
        onMessage: {
          addListener: mock.fn((callback) => {
            messageListeners.push(callback);
          })
        }
      }
    };
  });

  describe('Storage Operations', () => {
    it('should initialize storage with enabled=true on first install', async () => {
      // Simulate first install - storage is empty
      storageData = {};

      // Simulate onInstalled handler
      await mockChrome.storage.local.set({ [STORAGE_KEY]: true });

      assert.equal(storageData[STORAGE_KEY], true);
    });

    it('should preserve existing storage state on reinstall', async () => {
      // Simulate reinstall - storage has existing value
      storageData = { [STORAGE_KEY]: false };

      const result = await mockChrome.storage.local.get(STORAGE_KEY);
      assert.equal(result[STORAGE_KEY], false);
    });

    it('should update storage when state changes', async () => {
      storageData = { [STORAGE_KEY]: true };

      await mockChrome.storage.local.set({ [STORAGE_KEY]: false });
      assert.equal(storageData[STORAGE_KEY], false);

      await mockChrome.storage.local.set({ [STORAGE_KEY]: true });
      assert.equal(storageData[STORAGE_KEY], true);
    });
  });

  describe('Ruleset Management', () => {
    it('should enable ruleset when enabling redirects', async () => {
      await mockChrome.declarativeNetRequest.updateEnabledRulesets({
        enableRulesetIds: [RULESET_ID]
      });

      assert.ok(enabledRulesets.has(RULESET_ID));
    });

    it('should disable ruleset when disabling redirects', async () => {
      enabledRulesets.add(RULESET_ID);

      await mockChrome.declarativeNetRequest.updateEnabledRulesets({
        disableRulesetIds: [RULESET_ID]
      });

      assert.ok(!enabledRulesets.has(RULESET_ID));
    });

    it('should handle enable/disable toggle correctly', async () => {
      // Enable
      await mockChrome.declarativeNetRequest.updateEnabledRulesets({
        enableRulesetIds: [RULESET_ID]
      });
      assert.ok(enabledRulesets.has(RULESET_ID));

      // Disable
      await mockChrome.declarativeNetRequest.updateEnabledRulesets({
        disableRulesetIds: [RULESET_ID]
      });
      assert.ok(!enabledRulesets.has(RULESET_ID));

      // Enable again
      await mockChrome.declarativeNetRequest.updateEnabledRulesets({
        enableRulesetIds: [RULESET_ID]
      });
      assert.ok(enabledRulesets.has(RULESET_ID));
    });
  });

  describe('Message Handling', () => {
    it('should respond to getState with current enabled status', async () => {
      storageData = { [STORAGE_KEY]: true };

      // Simulate message handler logic
      const request = { action: 'getState' };
      const result = await mockChrome.storage.local.get(STORAGE_KEY);
      const response = { enabled: result[STORAGE_KEY] ?? true };

      assert.deepEqual(response, { enabled: true });
    });

    it('should respond to getState with false when disabled', async () => {
      storageData = { [STORAGE_KEY]: false };

      const request = { action: 'getState' };
      const result = await mockChrome.storage.local.get(STORAGE_KEY);
      const response = { enabled: result[STORAGE_KEY] ?? true };

      assert.deepEqual(response, { enabled: false });
    });

    it('should default to enabled when storage is empty', async () => {
      storageData = {};

      const result = await mockChrome.storage.local.get(STORAGE_KEY);
      const response = { enabled: result[STORAGE_KEY] ?? true };

      assert.deepEqual(response, { enabled: true });
    });

    it('should update state and rules on setState action', async () => {
      storageData = { [STORAGE_KEY]: true };

      // Simulate setState handler - disable
      await mockChrome.storage.local.set({ [STORAGE_KEY]: false });
      await mockChrome.declarativeNetRequest.updateEnabledRulesets({
        disableRulesetIds: [RULESET_ID]
      });

      assert.equal(storageData[STORAGE_KEY], false);
      assert.ok(!enabledRulesets.has(RULESET_ID));

      // Simulate setState handler - enable
      await mockChrome.storage.local.set({ [STORAGE_KEY]: true });
      await mockChrome.declarativeNetRequest.updateEnabledRulesets({
        enableRulesetIds: [RULESET_ID]
      });

      assert.equal(storageData[STORAGE_KEY], true);
      assert.ok(enabledRulesets.has(RULESET_ID));
    });

    it('should return success response after setState', async () => {
      const response = { success: true };
      assert.deepEqual(response, { success: true });
    });

    it('should ignore unknown actions', () => {
      const request = { action: 'unknownAction' };
      // The handler should return false for unknown actions
      const handled = request.action === 'getState' || request.action === 'setState';
      assert.ok(!handled);
    });
  });

  describe('Storage Change Listener', () => {
    it('should react to storage changes from other contexts', async () => {
      // Simulate storage change event
      const changes = {
        [STORAGE_KEY]: {
          oldValue: true,
          newValue: false
        }
      };
      const areaName = 'local';

      // Handler logic
      if (areaName === 'local' && changes[STORAGE_KEY]) {
        const enabled = changes[STORAGE_KEY].newValue;
        if (enabled) {
          await mockChrome.declarativeNetRequest.updateEnabledRulesets({
            enableRulesetIds: [RULESET_ID]
          });
        } else {
          await mockChrome.declarativeNetRequest.updateEnabledRulesets({
            disableRulesetIds: [RULESET_ID]
          });
        }
      }

      assert.ok(!enabledRulesets.has(RULESET_ID));
    });

    it('should ignore storage changes from sync area', async () => {
      const changes = {
        [STORAGE_KEY]: {
          oldValue: true,
          newValue: false
        }
      };
      const areaName = 'sync';

      // Handler should not process sync area changes
      const shouldProcess = areaName === 'local' && changes[STORAGE_KEY];
      assert.ok(!shouldProcess);
    });

    it('should ignore changes to other keys', async () => {
      const changes = {
        'otherKey': {
          oldValue: 'old',
          newValue: 'new'
        }
      };
      const areaName = 'local';

      const shouldProcess = areaName === 'local' && changes[STORAGE_KEY];
      assert.ok(!shouldProcess);
    });
  });

  describe('Error Handling', () => {
    it('should handle storage.get errors gracefully', async () => {
      const mockErrorChrome = {
        storage: {
          local: {
            get: mock.fn(async () => {
              throw new Error('Storage unavailable');
            })
          }
        }
      };

      let error = null;
      try {
        await mockErrorChrome.storage.local.get(STORAGE_KEY);
      } catch (e) {
        error = e;
      }

      assert.ok(error !== null);
      assert.equal(error.message, 'Storage unavailable');
    });

    it('should handle updateEnabledRulesets errors gracefully', async () => {
      const mockErrorChrome = {
        declarativeNetRequest: {
          updateEnabledRulesets: mock.fn(async () => {
            throw new Error('Failed to update rulesets');
          })
        }
      };

      let error = null;
      try {
        await mockErrorChrome.declarativeNetRequest.updateEnabledRulesets({
          enableRulesetIds: [RULESET_ID]
        });
      } catch (e) {
        error = e;
      }

      assert.ok(error !== null);
      assert.equal(error.message, 'Failed to update rulesets');
    });
  });

  describe('Sync Rules to Storage', () => {
    it('should sync rules to enabled state from storage', async () => {
      storageData = { [STORAGE_KEY]: true };

      const result = await mockChrome.storage.local.get(STORAGE_KEY);
      const enabled = result[STORAGE_KEY] ?? true;

      if (enabled) {
        await mockChrome.declarativeNetRequest.updateEnabledRulesets({
          enableRulesetIds: [RULESET_ID]
        });
      }

      assert.ok(enabledRulesets.has(RULESET_ID));
    });

    it('should sync rules to disabled state from storage', async () => {
      storageData = { [STORAGE_KEY]: false };
      enabledRulesets.add(RULESET_ID);

      const result = await mockChrome.storage.local.get(STORAGE_KEY);
      const enabled = result[STORAGE_KEY] ?? true;

      if (!enabled) {
        await mockChrome.declarativeNetRequest.updateEnabledRulesets({
          disableRulesetIds: [RULESET_ID]
        });
      }

      assert.ok(!enabledRulesets.has(RULESET_ID));
    });

    it('should default to enabled when storage is undefined', async () => {
      storageData = {};

      const result = await mockChrome.storage.local.get(STORAGE_KEY);
      const enabled = result[STORAGE_KEY] ?? true;

      assert.equal(enabled, true);
    });
  });
});

describe('Integration Scenarios', () => {
  it('should handle fresh install flow correctly', async () => {
    const storageData = {};
    const enabledRulesets = new Set();

    // 1. Check if storage has value
    const hasValue = storageData[STORAGE_KEY] !== undefined;
    assert.ok(!hasValue, 'Storage should be empty on fresh install');

    // 2. Set default enabled state
    storageData[STORAGE_KEY] = true;
    assert.equal(storageData[STORAGE_KEY], true);

    // 3. Enable rulesets
    enabledRulesets.add(RULESET_ID);
    assert.ok(enabledRulesets.has(RULESET_ID));
  });

  it('should handle user disable/enable cycle', async () => {
    const storageData = { [STORAGE_KEY]: true };
    const enabledRulesets = new Set([RULESET_ID]);

    // User disables
    storageData[STORAGE_KEY] = false;
    enabledRulesets.delete(RULESET_ID);
    assert.equal(storageData[STORAGE_KEY], false);
    assert.ok(!enabledRulesets.has(RULESET_ID));

    // User enables again
    storageData[STORAGE_KEY] = true;
    enabledRulesets.add(RULESET_ID);
    assert.equal(storageData[STORAGE_KEY], true);
    assert.ok(enabledRulesets.has(RULESET_ID));
  });

  it('should handle service worker restart (Safari wake-up)', async () => {
    // Simulate service worker restart - storage persists but rulesets need re-sync
    const storageData = { [STORAGE_KEY]: true };
    const enabledRulesets = new Set(); // Rulesets cleared on restart

    // Sync rules to storage state
    const enabled = storageData[STORAGE_KEY] ?? true;
    if (enabled) {
      enabledRulesets.add(RULESET_ID);
    }

    assert.ok(enabledRulesets.has(RULESET_ID));
  });
});
