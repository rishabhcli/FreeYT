(function(){
  'use strict';

  const enabledToggle = document.getElementById('enabledToggle');
  const statusText = document.getElementById('statusText');

  const STORAGE_KEY = 'enabled';

  // Update UI based on enabled state with smooth transitions
  function setStatusUI(enabled) {
    enabledToggle.checked = enabled;
    enabledToggle.setAttribute('aria-checked', enabled ? 'true' : 'false');

    // Animate text change
    statusText.style.transition = 'all 0.3s cubic-bezier(0.4, 0, 0.2, 1)';
    statusText.style.opacity = '0';
    statusText.style.transform = 'translateY(-4px)';

    setTimeout(() => {
      statusText.textContent = enabled ? 'Enabled' : 'Disabled';
      statusText.style.color = enabled ? 'var(--success)' : 'var(--fg-muted)';
      statusText.style.fontWeight = enabled ? '600' : '500';
      statusText.style.opacity = '1';
      statusText.style.transform = 'translateY(0)';
    }, 150);
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
