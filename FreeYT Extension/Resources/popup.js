(function(){
  'use strict';

  const enabledToggle = document.getElementById('enabledToggle');
  const statusText = document.getElementById('statusText');
  const statusPill = document.getElementById('statusPill');
  const statusLED = document.getElementById('statusLED');
  const modeChip = document.getElementById('modeChip');
  const refreshStateButton = document.getElementById('refreshState');

  // Update UI based on enabled state with smooth transitions
  function setStatusUI(enabled) {
    enabledToggle.checked = enabled;
    enabledToggle.setAttribute('aria-checked', enabled ? 'true' : 'false');

    statusText.textContent = enabled ? 'Enabled' : 'Disabled';
    statusText.classList.toggle('state-off', !enabled);

    if (statusPill) {
      statusPill.textContent = enabled ? 'Shield active' : 'Shield paused';
      statusPill.classList.toggle('pill-off', !enabled);
    }

    if (statusLED) {
      statusLED.classList.toggle('off', !enabled);
    }

    if (modeChip) {
      modeChip.textContent = enabled ? 'Auto-redirect' : 'Awaiting Safari';
      modeChip.classList.toggle('chip-off', !enabled);
    }
  }

  // Show error message to user
  function showError(message) {
    const errorDiv = document.createElement('div');
    errorDiv.className = 'error-message';
    errorDiv.textContent = message;
    errorDiv.setAttribute('role', 'alert');
    errorDiv.setAttribute('aria-live', 'assertive');
    errorDiv.style.cssText = `
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
    document.body.appendChild(errorDiv);
    setTimeout(() => {
      errorDiv.style.opacity = '0';
      errorDiv.style.transition = 'opacity 0.3s';
      setTimeout(() => errorDiv.remove(), 300);
    }, 3000);
  }

  // Initialize popup
  async function init() {
    try {
      // Validate required elements exist
      if (!enabledToggle || !statusText) {
        throw new Error('Required popup elements not found');
      }

      // Safari-only guard: if not Safari, disable UI and exit
      const ua = navigator.userAgent || '';
      const isSafari = ua.includes('Safari') && !ua.match(/Chrome|CriOS|Edg|OPR|Brave|Firefox/i);
      if (!isSafari) {
        enabledToggle.disabled = true;
        statusText.textContent = 'Safari only';
        statusText.classList.add('state-off');
        if (statusPill) {
          statusPill.textContent = 'Unsupported browser';
          statusPill.classList.add('pill-off');
        }
        if (modeChip) {
          modeChip.textContent = 'Safari required';
          modeChip.classList.add('chip-off');
        }
        if (statusLED) {
          statusLED.classList.add('off');
        }
        showError('FreeYT is a Safari-only extension. Install and use it in Safari.');
        return;
      }

      // Get current state from background (falls back to storage)
      const result = await chrome.runtime.sendMessage({ action: 'getState' });
      const enabled = result?.enabled ?? true;
      setStatusUI(enabled);

      // Listen for toggle changes
      enabledToggle.addEventListener('change', async () => {
        const newState = enabledToggle.checked;

        try {
          const response = await chrome.runtime.sendMessage({ action: 'setState', enabled: newState });
          if (!response?.success) {
            throw new Error('Background rejected state change');
          }
          setStatusUI(newState);
          console.log('[FreeYT Popup] State changed to:', newState);
        } catch (error) {
          console.error('[FreeYT Popup] Failed to save state:', error);
          showError('Failed to save settings. Please try again.');
          // Revert UI to previous state
          setStatusUI(!newState);
        }
      });

      if (refreshStateButton) {
        refreshStateButton.addEventListener('click', async () => {
          try {
            const result = await chrome.runtime.sendMessage({ action: 'getState' });
            const enabled = result?.enabled ?? true;
            setStatusUI(enabled);
          } catch (error) {
            console.error('[FreeYT Popup] Refresh failed:', error);
            showError('Could not refresh state from Safari.');
          }
        });
      }

      console.log('[FreeYT Popup] Initialized, current state:', enabled);
    } catch (error) {
      console.error('[FreeYT Popup] Initialization error:', error);
      showError('Failed to initialize extension popup. Please reload.');
    }
  }

  // Start when DOM is ready
  if (document.readyState === 'loading') {
    document.addEventListener('DOMContentLoaded', init);
  } else {
    init();
  }
})();
