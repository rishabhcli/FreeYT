import { describe, it } from 'node:test';
import assert from 'node:assert/strict';
import { readFileSync } from 'node:fs';
import { dirname, join } from 'node:path';
import { fileURLToPath } from 'node:url';
import vm from 'node:vm';

const __filename = fileURLToPath(import.meta.url);
const __dirname = dirname(__filename);
const popupSource = readFileSync(join(__dirname, '..', 'Resources', 'popup.js'), 'utf8');

function flushPromises() {
  return new Promise((resolve) => setImmediate(resolve));
}

async function settle() {
  await flushPromises();
  await flushPromises();
}

function createElement(id = '') {
  const listeners = {};
  const attributes = {};
  let innerHTML = '';

  const element = {
    id,
    hidden: false,
    disabled: false,
    checked: false,
    className: '',
    value: '',
    textContent: '',
    children: [],
    dataset: {},
    listeners,
    setAttribute(name, value) {
      attributes[name] = String(value);
    },
    getAttribute(name) {
      return attributes[name] ?? null;
    },
    removeAttribute(name) {
      delete attributes[name];
    },
    addEventListener(name, callback) {
      if (!listeners[name]) {
        listeners[name] = [];
      }
      listeners[name].push(callback);
    },
    appendChild(child) {
      this.children.push(child);
      return child;
    },
    querySelectorAll() {
      return [];
    },
    async click() {
      if (this.disabled) {
        return;
      }
      for (const callback of listeners.click ?? []) {
        await callback({ currentTarget: this });
      }
    },
    async keydown(key) {
      if (this.disabled) {
        return;
      }
      for (const callback of listeners.keydown ?? []) {
        await callback({ key, currentTarget: this });
      }
    }
  };

  Object.defineProperty(element, 'innerHTML', {
    get() {
      return innerHTML;
    },
    set(value) {
      innerHTML = value;
      this.children = [];
    }
  });

  return element;
}

function createPopupHarness({
  safari = true,
  stateOverrides = {},
  messageHandlers = {}
} = {}) {
  const elements = {
    enabledToggle: createElement('enabledToggle'),
    summaryTitle: createElement('summaryTitle'),
    summaryDetail: createElement('summaryDetail'),
    statusPill: createElement('statusPill'),
    syncPill: createElement('syncPill'),
    currentSitePill: createElement('currentSitePill'),
    todayCount: createElement('todayCount'),
    weekCount: createElement('weekCount'),
    videoCount: createElement('videoCount'),
    currentSiteDetail: createElement('currentSiteDetail'),
    currentSiteButton: createElement('currentSiteButton'),
    exceptionsButton: createElement('exceptionsButton'),
    dashboardButton: createElement('dashboardButton'),
    refreshButton: createElement('refreshButton'),
    exceptionsPanel: createElement('exceptionsPanel'),
    exceptionsCount: createElement('exceptionsCount'),
    exceptionInput: createElement('exceptionInput'),
    exceptionAdd: createElement('exceptionAdd'),
    exceptionsList: createElement('exceptionsList'),
    toast: createElement('toast')
  };

  elements.exceptionsPanel.hidden = true;
  elements.exceptionsButton.textContent = 'Manage exceptions';
  elements.exceptionsButton.setAttribute('aria-expanded', 'false');
  elements.toast.hidden = true;

  let dashboardState = {
    enabled: true,
    videoCount: 12,
    todayCount: 3,
    weekCount: 8,
    lastSyncState: 'Synced',
    currentSite: {
      domain: 'music.youtube.com',
      displayDomain: 'music.youtube.com',
      isException: false,
      isSupportedDomain: true
    },
    exceptions: [],
    ...stateOverrides
  };

  const messages = [];
  const chrome = {
    runtime: {
      async sendMessage(message) {
        messages.push(message);

        const customHandler = messageHandlers[message.action];
        if (customHandler) {
          return customHandler(message, dashboardState);
        }

        switch (message.action) {
          case 'getDashboardState':
            return { ...dashboardState };
          case 'setState':
            dashboardState = { ...dashboardState, enabled: message.enabled };
            return { success: true };
          case 'toggleCurrentSiteException':
            dashboardState = {
              ...dashboardState,
              currentSite: {
                ...dashboardState.currentSite,
                isException: !dashboardState.currentSite.isException
              },
              exceptions: dashboardState.currentSite.isException
                ? []
                : [dashboardState.currentSite.domain]
            };
            return {
              success: true,
              currentSite: dashboardState.currentSite,
              exceptions: dashboardState.exceptions
            };
          case 'addToAllowlist':
            dashboardState = {
              ...dashboardState,
              exceptions: Array.from(new Set([...dashboardState.exceptions, message.pattern])).sort()
            };
            return { success: true, exceptions: dashboardState.exceptions };
          case 'removeFromAllowlist':
            dashboardState = {
              ...dashboardState,
              exceptions: dashboardState.exceptions.filter((domain) => domain !== message.pattern)
            };
            return { success: true, exceptions: dashboardState.exceptions };
          case 'syncWithNative':
            return { success: true, state: { ...dashboardState } };
          case 'openDashboard':
            return { success: true };
          default:
            throw new Error(`Unexpected action: ${message.action}`);
        }
      }
    }
  };

  const document = {
    readyState: 'complete',
    getElementById(id) {
      return elements[id];
    },
    createElement() {
      return createElement();
    },
    addEventListener() {}
  };

  const context = vm.createContext({
    chrome,
    browser: safari ? { runtime: { sendNativeMessage() {} } } : undefined,
    document,
    navigator: {
      userAgent: safari
        ? 'Mozilla/5.0 (Macintosh; Intel Mac OS X 10_15_7) AppleWebKit/605.1.15 (KHTML, like Gecko) Version/17.0 Safari/605.1.15'
        : 'Mozilla/5.0 (Macintosh; Intel Mac OS X 10_15_7) AppleWebKit/537.36 (KHTML, like Gecko) Chrome/123.0.0.0 Safari/537.36'
    },
    setTimeout,
    clearTimeout
  });

  vm.runInContext(popupSource, context, { filename: 'popup.js' });

  return { elements, messages };
}

function createDeferred() {
  let resolve;
  let reject;
  const promise = new Promise((nextResolve, nextReject) => {
    resolve = nextResolve;
    reject = nextReject;
  });
  return { promise, resolve, reject };
}

describe('popup.js dashboard interactions', () => {
  it('renders the active protection summary, stats, and quick action labels', async () => {
    const harness = createPopupHarness();
    await settle();

    assert.equal(harness.elements.summaryTitle.textContent, 'Protection is active');
    assert.equal(harness.elements.statusPill.textContent, 'Active');
    assert.equal(harness.elements.todayCount.textContent, '3');
    assert.equal(harness.elements.weekCount.textContent, '8');
    assert.equal(harness.elements.videoCount.textContent, '12');
    assert.equal(harness.elements.currentSiteButton.textContent, 'Bypass this site');
  });

  it('toggles the exceptions panel and updates aria-expanded for assistive tech', async () => {
    const harness = createPopupHarness();
    await settle();

    await harness.elements.exceptionsButton.click();

    assert.equal(harness.elements.exceptionsPanel.hidden, false);
    assert.equal(harness.elements.exceptionsButton.textContent, 'Hide exceptions');
    assert.equal(harness.elements.exceptionsButton.getAttribute('aria-expanded'), 'true');
  });

  it('shows a validation error before sending an invalid exception domain', async () => {
    const harness = createPopupHarness();
    await settle();

    harness.elements.exceptionInput.value = 'bad domain';
    await harness.elements.exceptionAdd.click();

    assert.equal(
      harness.messages.some((message) => message.action === 'addToAllowlist'),
      false
    );
    assert.equal(harness.elements.toast.hidden, false);
    assert.equal(harness.elements.toast.textContent, 'Use a valid domain like music.youtube.com.');
    assert.equal(harness.elements.toast.className, 'toast error');
  });

  it('rejects non-YouTube exception domains before messaging the background worker', async () => {
    const harness = createPopupHarness();
    await settle();

    harness.elements.exceptionInput.value = 'example.com';
    await harness.elements.exceptionAdd.click();

    assert.equal(
      harness.messages.some((message) => message.action === 'addToAllowlist'),
      false
    );
    assert.equal(harness.elements.toast.hidden, false);
    assert.equal(harness.elements.toast.textContent, 'Use a supported YouTube domain like music.youtube.com.');
    assert.equal(harness.elements.toast.className, 'toast error');
  });

  it('sends the quick current-site exception action and updates the toast copy', async () => {
    const harness = createPopupHarness();
    await settle();

    await harness.elements.currentSiteButton.click();
    await settle();

    assert.equal(
      harness.messages.some((message) => message.action === 'toggleCurrentSiteException'),
      true
    );
    assert.equal(harness.elements.currentSiteButton.textContent, 'Remove site exception');
    assert.equal(harness.elements.toast.textContent, 'Site added to exceptions');
  });

  it('renders remove buttons for saved exceptions and removes them through the background contract', async () => {
    const harness = createPopupHarness({
      stateOverrides: {
        exceptions: ['music.youtube.com']
      }
    });
    await settle();

    const removeButton = harness.elements.exceptionsList.children[0]?.children[1];
    assert.ok(removeButton);

    await removeButton.click();
    await settle();

    assert.equal(
      harness.messages.some(
        (message) => message.action === 'removeFromAllowlist' && message.pattern === 'music.youtube.com'
      ),
      true
    );
    assert.equal(harness.elements.toast.textContent, 'Exception removed');
  });

  it('blocks the popup outside Safari and surfaces the guard copy', async () => {
    const harness = createPopupHarness({ safari: false });
    await settle();

    assert.equal(harness.elements.enabledToggle.disabled, true);
    assert.equal(harness.elements.summaryTitle.textContent, 'Safari only');
    assert.equal(
      harness.elements.summaryDetail.textContent,
      'FreeYT runs as a Safari extension and needs Safari to protect YouTube privacy.'
    );
    assert.equal(harness.elements.statusPill.textContent, 'Unsupported');
  });

  it('opens the native dashboard on the overview route', async () => {
    const harness = createPopupHarness();
    await settle();

    await harness.elements.dashboardButton.click();

    const [message] = harness.messages.filter((entry) => entry.action === 'openDashboard');
    assert.ok(message);
    assert.equal(message.action, 'openDashboard');
    assert.equal(message.section, 'overview');
  });

  it('disables refresh while a sync request is in flight so duplicate clicks do not queue', async () => {
    const refreshRequest = createDeferred();
    const harness = createPopupHarness({
      messageHandlers: {
        syncWithNative() {
          return refreshRequest.promise;
        }
      }
    });
    await settle();

    const firstClick = harness.elements.refreshButton.click();
    await flushPromises();

    assert.equal(harness.elements.refreshButton.disabled, true);
    assert.equal(harness.elements.refreshButton.getAttribute('aria-busy'), 'true');

    const secondClick = harness.elements.refreshButton.click();
    await flushPromises();

    assert.equal(
      harness.messages.filter((message) => message.action === 'syncWithNative').length,
      1
    );

    refreshRequest.resolve({ success: true, state: {} });
    await firstClick;
    await secondClick;
    await settle();

    assert.equal(harness.elements.refreshButton.disabled, false);
    assert.equal(harness.elements.refreshButton.getAttribute('aria-busy'), 'false');
  });
});
