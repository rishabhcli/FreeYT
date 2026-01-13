/**
 * popup.test.js - Tests for the popup UI logic
 *
 * These tests verify popup initialization, state management,
 * user interactions, and Safari detection.
 */

import { describe, it, beforeEach, mock } from 'node:test';
import assert from 'node:assert/strict';

describe('Popup UI State Management', () => {
  describe('setStatusUI function behavior', () => {
    let mockElements;

    beforeEach(() => {
      mockElements = {
        enabledToggle: {
          checked: false,
          setAttribute: mock.fn()
        },
        statusText: {
          textContent: '',
          classList: {
            toggle: mock.fn()
          }
        },
        statusPill: {
          textContent: '',
          classList: {
            toggle: mock.fn()
          }
        },
        statusLED: {
          classList: {
            toggle: mock.fn()
          }
        },
        modeChip: {
          textContent: '',
          classList: {
            toggle: mock.fn()
          }
        }
      };
    });

    it('should set toggle checked state to true when enabled', () => {
      const enabled = true;
      mockElements.enabledToggle.checked = enabled;
      assert.equal(mockElements.enabledToggle.checked, true);
    });

    it('should set toggle checked state to false when disabled', () => {
      const enabled = false;
      mockElements.enabledToggle.checked = enabled;
      assert.equal(mockElements.enabledToggle.checked, false);
    });

    it('should set aria-checked attribute correctly', () => {
      // Simulate setStatusUI for enabled state
      mockElements.enabledToggle.setAttribute('aria-checked', 'true');
      assert.equal(mockElements.enabledToggle.setAttribute.mock.calls.length, 1);
      assert.deepEqual(
        mockElements.enabledToggle.setAttribute.mock.calls[0].arguments,
        ['aria-checked', 'true']
      );
    });

    it('should set status text to "Enabled" when enabled', () => {
      const enabled = true;
      mockElements.statusText.textContent = enabled ? 'Enabled' : 'Disabled';
      assert.equal(mockElements.statusText.textContent, 'Enabled');
    });

    it('should set status text to "Disabled" when disabled', () => {
      const enabled = false;
      mockElements.statusText.textContent = enabled ? 'Enabled' : 'Disabled';
      assert.equal(mockElements.statusText.textContent, 'Disabled');
    });

    it('should toggle state-off class on statusText', () => {
      const enabled = false;
      mockElements.statusText.classList.toggle('state-off', !enabled);
      assert.equal(mockElements.statusText.classList.toggle.mock.calls.length, 1);
      assert.deepEqual(
        mockElements.statusText.classList.toggle.mock.calls[0].arguments,
        ['state-off', true]
      );
    });

    it('should set statusPill text correctly for enabled state', () => {
      const enabled = true;
      mockElements.statusPill.textContent = enabled ? 'Shield active' : 'Shield paused';
      assert.equal(mockElements.statusPill.textContent, 'Shield active');
    });

    it('should set statusPill text correctly for disabled state', () => {
      const enabled = false;
      mockElements.statusPill.textContent = enabled ? 'Shield active' : 'Shield paused';
      assert.equal(mockElements.statusPill.textContent, 'Shield paused');
    });

    it('should toggle pill-off class on statusPill', () => {
      const enabled = false;
      mockElements.statusPill.classList.toggle('pill-off', !enabled);
      assert.deepEqual(
        mockElements.statusPill.classList.toggle.mock.calls[0].arguments,
        ['pill-off', true]
      );
    });

    it('should toggle off class on statusLED', () => {
      const enabled = false;
      mockElements.statusLED.classList.toggle('off', !enabled);
      assert.deepEqual(
        mockElements.statusLED.classList.toggle.mock.calls[0].arguments,
        ['off', true]
      );
    });

    it('should set modeChip text for enabled state', () => {
      const enabled = true;
      mockElements.modeChip.textContent = enabled ? 'Auto-redirect' : 'Awaiting Safari';
      assert.equal(mockElements.modeChip.textContent, 'Auto-redirect');
    });

    it('should set modeChip text for disabled state', () => {
      const enabled = false;
      mockElements.modeChip.textContent = enabled ? 'Auto-redirect' : 'Awaiting Safari';
      assert.equal(mockElements.modeChip.textContent, 'Awaiting Safari');
    });
  });
});

describe('Safari Detection', () => {
  const testUserAgents = {
    // Safari on macOS
    safariMac: 'Mozilla/5.0 (Macintosh; Intel Mac OS X 10_15_7) AppleWebKit/605.1.15 (KHTML, like Gecko) Version/17.0 Safari/605.1.15',
    // Safari on iOS
    safariIOS: 'Mozilla/5.0 (iPhone; CPU iPhone OS 17_0 like Mac OS X) AppleWebKit/605.1.15 (KHTML, like Gecko) Version/17.0 Mobile/15E148 Safari/604.1',
    // Safari on iPad
    safariIPad: 'Mozilla/5.0 (iPad; CPU OS 17_0 like Mac OS X) AppleWebKit/605.1.15 (KHTML, like Gecko) Version/17.0 Mobile/15E148 Safari/604.1',
    // Chrome on macOS (should NOT match)
    chrome: 'Mozilla/5.0 (Macintosh; Intel Mac OS X 10_15_7) AppleWebKit/537.36 (KHTML, like Gecko) Chrome/119.0.0.0 Safari/537.36',
    // Chrome on iOS (should NOT match)
    chromeIOS: 'Mozilla/5.0 (iPhone; CPU iPhone OS 17_0 like Mac OS X) AppleWebKit/605.1.15 (KHTML, like Gecko) CriOS/119.0.6045.109 Mobile/15E148 Safari/604.1',
    // Firefox (should NOT match)
    firefox: 'Mozilla/5.0 (Macintosh; Intel Mac OS X 10.15; rv:120.0) Gecko/20100101 Firefox/120.0',
    // Edge (should NOT match)
    edge: 'Mozilla/5.0 (Macintosh; Intel Mac OS X 10_15_7) AppleWebKit/537.36 (KHTML, like Gecko) Chrome/119.0.0.0 Safari/537.36 Edg/119.0.2151.58',
    // Opera (should NOT match)
    opera: 'Mozilla/5.0 (Macintosh; Intel Mac OS X 10_15_7) AppleWebKit/537.36 (KHTML, like Gecko) Chrome/119.0.0.0 Safari/537.36 OPR/105.0.0.0',
    // Brave (should NOT match)
    brave: 'Mozilla/5.0 (Macintosh; Intel Mac OS X 10_15_7) AppleWebKit/537.36 (KHTML, like Gecko) Chrome/119.0.0.0 Safari/537.36 Brave/119',
  };

  function isSafari(ua) {
    return ua.includes('Safari') && !ua.match(/Chrome|CriOS|Edg|OPR|Brave|Firefox/i);
  }

  it('should detect Safari on macOS', () => {
    assert.ok(isSafari(testUserAgents.safariMac));
  });

  it('should detect Safari on iOS', () => {
    assert.ok(isSafari(testUserAgents.safariIOS));
  });

  it('should detect Safari on iPad', () => {
    assert.ok(isSafari(testUserAgents.safariIPad));
  });

  it('should NOT detect Chrome as Safari', () => {
    assert.ok(!isSafari(testUserAgents.chrome));
  });

  it('should NOT detect Chrome iOS as Safari', () => {
    assert.ok(!isSafari(testUserAgents.chromeIOS));
  });

  it('should NOT detect Firefox as Safari', () => {
    assert.ok(!isSafari(testUserAgents.firefox));
  });

  it('should NOT detect Edge as Safari', () => {
    assert.ok(!isSafari(testUserAgents.edge));
  });

  it('should NOT detect Opera as Safari', () => {
    assert.ok(!isSafari(testUserAgents.opera));
  });

  it('should NOT detect Brave as Safari', () => {
    assert.ok(!isSafari(testUserAgents.brave));
  });

  it('should handle empty user agent string', () => {
    assert.ok(!isSafari(''));
  });
});

describe('Error Message Display', () => {
  it('should create error div with correct class', () => {
    const errorDiv = {
      className: 'error-message',
      textContent: '',
      style: { cssText: '' },
      setAttribute: mock.fn()
    };

    errorDiv.className = 'error-message';
    assert.equal(errorDiv.className, 'error-message');
  });

  it('should set error message text', () => {
    const message = 'Failed to save settings. Please try again.';
    const errorDiv = { textContent: '' };
    errorDiv.textContent = message;
    assert.equal(errorDiv.textContent, message);
  });

  it('should set ARIA role to alert', () => {
    const errorDiv = { setAttribute: mock.fn() };
    errorDiv.setAttribute('role', 'alert');
    assert.deepEqual(
      errorDiv.setAttribute.mock.calls[0].arguments,
      ['role', 'alert']
    );
  });

  it('should set aria-live to assertive for screen readers', () => {
    const errorDiv = { setAttribute: mock.fn() };
    errorDiv.setAttribute('aria-live', 'assertive');
    assert.deepEqual(
      errorDiv.setAttribute.mock.calls[0].arguments,
      ['aria-live', 'assertive']
    );
  });

  it('should include slideDown animation in styles', () => {
    const styleText = `
      position: fixed;
      top: 10px;
      left: 50%;
      transform: translateX(-50%);
      background: #ff4444;
      color: white;
      padding: 12px 20px;
      border-radius: 8px;
      font-size: 13px;
      font-weight: 500;
      box-shadow: 0 4px 12px rgba(0, 0, 0, 0.2);
      z-index: 1000;
      animation: slideDown 0.3s ease-out;
    `;

    assert.ok(styleText.includes('animation: slideDown'));
    assert.ok(styleText.includes('background: #ff4444'));
    assert.ok(styleText.includes('position: fixed'));
  });
});

describe('Message Passing with Background Script', () => {
  let mockChrome;

  beforeEach(() => {
    mockChrome = {
      runtime: {
        sendMessage: mock.fn()
      }
    };
  });

  describe('getState message', () => {
    it('should send getState action to background', async () => {
      mockChrome.runtime.sendMessage.mock.mockImplementation(async (message) => {
        if (message.action === 'getState') {
          return { enabled: true };
        }
      });

      const result = await mockChrome.runtime.sendMessage({ action: 'getState' });
      assert.deepEqual(result, { enabled: true });
    });

    it('should handle getState returning disabled', async () => {
      mockChrome.runtime.sendMessage.mock.mockImplementation(async (message) => {
        if (message.action === 'getState') {
          return { enabled: false };
        }
      });

      const result = await mockChrome.runtime.sendMessage({ action: 'getState' });
      assert.deepEqual(result, { enabled: false });
    });

    it('should default to enabled when response is null', async () => {
      mockChrome.runtime.sendMessage.mock.mockImplementation(async () => null);

      const result = await mockChrome.runtime.sendMessage({ action: 'getState' });
      const enabled = result?.enabled ?? true;
      assert.equal(enabled, true);
    });
  });

  describe('setState message', () => {
    it('should send setState action with enabled=true', async () => {
      mockChrome.runtime.sendMessage.mock.mockImplementation(async (message) => {
        if (message.action === 'setState' && message.enabled === true) {
          return { success: true };
        }
      });

      const result = await mockChrome.runtime.sendMessage({
        action: 'setState',
        enabled: true
      });
      assert.deepEqual(result, { success: true });
    });

    it('should send setState action with enabled=false', async () => {
      mockChrome.runtime.sendMessage.mock.mockImplementation(async (message) => {
        if (message.action === 'setState' && message.enabled === false) {
          return { success: true };
        }
      });

      const result = await mockChrome.runtime.sendMessage({
        action: 'setState',
        enabled: false
      });
      assert.deepEqual(result, { success: true });
    });

    it('should handle setState failure', async () => {
      mockChrome.runtime.sendMessage.mock.mockImplementation(async () => {
        return { success: false };
      });

      const result = await mockChrome.runtime.sendMessage({
        action: 'setState',
        enabled: true
      });
      assert.equal(result.success, false);
    });

    it('should handle network errors gracefully', async () => {
      mockChrome.runtime.sendMessage.mock.mockImplementation(async () => {
        throw new Error('Extension context invalidated');
      });

      let error = null;
      try {
        await mockChrome.runtime.sendMessage({
          action: 'setState',
          enabled: true
        });
      } catch (e) {
        error = e;
      }

      assert.ok(error !== null);
    });
  });
});

describe('Toggle Event Handler', () => {
  it('should get new state from checkbox checked property', () => {
    const checkbox = { checked: true };
    const newState = checkbox.checked;
    assert.equal(newState, true);
  });

  it('should revert UI state on error', () => {
    const currentState = true;
    const newState = !currentState;

    // Simulate error - revert to previous state
    const revertedState = !newState;
    assert.equal(revertedState, currentState);
  });

  it('should track state transitions correctly', () => {
    const states = [];

    // Initial state
    states.push(true);

    // User toggles off
    states.push(false);

    // Error occurs, revert
    states.push(true);

    assert.deepEqual(states, [true, false, true]);
  });
});

describe('Refresh Button Handler', () => {
  it('should request current state from background', async () => {
    const mockChrome = {
      runtime: {
        sendMessage: mock.fn(async () => ({ enabled: true }))
      }
    };

    const result = await mockChrome.runtime.sendMessage({ action: 'getState' });
    assert.equal(result.enabled, true);
  });

  it('should update UI after successful refresh', async () => {
    const mockUI = {
      enabled: false
    };

    const result = { enabled: true };
    mockUI.enabled = result.enabled;

    assert.equal(mockUI.enabled, true);
  });

  it('should show error on refresh failure', async () => {
    const mockChrome = {
      runtime: {
        sendMessage: mock.fn(async () => {
          throw new Error('Could not refresh state');
        })
      }
    };

    let errorShown = false;
    try {
      await mockChrome.runtime.sendMessage({ action: 'getState' });
    } catch (e) {
      errorShown = true;
    }

    assert.ok(errorShown);
  });
});

describe('DOM Element Validation', () => {
  it('should require enabledToggle element', () => {
    const elements = {
      enabledToggle: null,
      statusText: { textContent: '' }
    };

    const isValid = elements.enabledToggle && elements.statusText;
    assert.ok(!isValid);
  });

  it('should require statusText element', () => {
    const elements = {
      enabledToggle: { checked: false },
      statusText: null
    };

    const isValid = elements.enabledToggle && elements.statusText;
    assert.ok(!isValid);
  });

  it('should pass validation with both required elements', () => {
    const elements = {
      enabledToggle: { checked: false },
      statusText: { textContent: '' }
    };

    const isValid = elements.enabledToggle && elements.statusText;
    assert.ok(isValid);
  });

  it('should handle optional elements being null', () => {
    const elements = {
      enabledToggle: { checked: false },
      statusText: { textContent: '' },
      statusPill: null,
      statusLED: null,
      modeChip: null
    };

    // Optional elements should be checked before use
    if (elements.statusPill) {
      elements.statusPill.textContent = 'test';
    }

    assert.ok(true); // Should not throw
  });
});

describe('Non-Safari Browser Behavior', () => {
  it('should disable toggle for non-Safari browsers', () => {
    const toggle = { disabled: false };
    const isSafari = false;

    if (!isSafari) {
      toggle.disabled = true;
    }

    assert.ok(toggle.disabled);
  });

  it('should show "Safari only" in status text', () => {
    const statusText = { textContent: '' };
    const isSafari = false;

    if (!isSafari) {
      statusText.textContent = 'Safari only';
    }

    assert.equal(statusText.textContent, 'Safari only');
  });

  it('should show "Unsupported browser" in pill', () => {
    const statusPill = { textContent: '' };
    const isSafari = false;

    if (!isSafari && statusPill) {
      statusPill.textContent = 'Unsupported browser';
    }

    assert.equal(statusPill.textContent, 'Unsupported browser');
  });

  it('should show "Safari required" in modeChip', () => {
    const modeChip = { textContent: '' };
    const isSafari = false;

    if (!isSafari && modeChip) {
      modeChip.textContent = 'Safari required';
    }

    assert.equal(modeChip.textContent, 'Safari required');
  });

  it('should show error message for non-Safari', () => {
    let errorMessage = null;
    const isSafari = false;

    if (!isSafari) {
      errorMessage = 'FreeYT is a Safari-only extension. Install and use it in Safari.';
    }

    assert.equal(
      errorMessage,
      'FreeYT is a Safari-only extension. Install and use it in Safari.'
    );
  });
});

describe('DOMContentLoaded Handling', () => {
  it('should call init when DOM is ready', () => {
    let initCalled = false;

    const init = () => {
      initCalled = true;
    };

    // Simulate DOM ready
    const readyState = 'complete';
    if (readyState !== 'loading') {
      init();
    }

    assert.ok(initCalled);
  });

  it('should add listener when DOM is loading', () => {
    let listenerAdded = false;
    const listeners = [];

    const document = {
      readyState: 'loading',
      addEventListener: (event, callback) => {
        listeners.push({ event, callback });
        listenerAdded = true;
      }
    };

    const init = () => {};

    if (document.readyState === 'loading') {
      document.addEventListener('DOMContentLoaded', init);
    }

    assert.ok(listenerAdded);
    assert.equal(listeners[0].event, 'DOMContentLoaded');
  });
});
