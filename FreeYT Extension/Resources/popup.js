(function(){
  'use strict';

  const enabledToggle = document.getElementById('enabledToggle');
  const statusText = document.getElementById('statusText');
  const statusDetail = document.getElementById('statusDetail');
  const statusPill = document.getElementById('statusPill');
  const videoCountEl = document.getElementById('videoCount');
  const allowlistRow = document.getElementById('allowlistRow');
  const allowlistPanel = document.getElementById('allowlistPanel');
  const allowlistInput = document.getElementById('allowlistInput');
  const allowlistAddBtn = document.getElementById('allowlistAdd');
  const allowlistEntriesEl = document.getElementById('allowlistEntries');
  const allowlistCountEl = document.getElementById('allowlistCount');
  const refreshRow = document.getElementById('refreshRow');
  const todayCountEl = document.getElementById('todayCount');
  const weekCountEl = document.getElementById('weekCount');

  const MAX_ALLOWLIST = 50;

  // Send message with timeout to handle service worker wake-up delays
  function sendMessageWithTimeout(msg, timeoutMs = 3000) {
    return Promise.race([
      chrome.runtime.sendMessage(msg),
      new Promise((_, reject) =>
        setTimeout(() => reject(new Error('Background script timeout')), timeoutMs)
      )
    ]);
  }

  // Update UI based on enabled state
  function setStatusUI(enabled) {
    enabledToggle.checked = enabled;
    enabledToggle.setAttribute('aria-checked', enabled ? 'true' : 'false');

    statusText.textContent = enabled ? 'Protection Enabled' : 'Protection Disabled';
    statusDetail.textContent = enabled
      ? 'Redirecting to youtube-nocookie.com'
      : 'Enable to redirect YouTube links';

    if (statusPill) {
      statusPill.textContent = enabled ? 'Active' : 'Paused';
      statusPill.classList.toggle('inactive', !enabled);
    }
  }

  // Update video count display
  function setVideoCount(count) {
    if (videoCountEl) {
      videoCountEl.textContent = count.toLocaleString();
    }
  }

  // Update daily stats display
  function setDailyStats(stats) {
    if (!stats) return;
    const today = new Date().toISOString().slice(0, 10);
    const todayVal = stats[today] || 0;

    let weekVal = 0;
    Object.values(stats).forEach(v => { weekVal += v; });

    if (todayCountEl) todayCountEl.textContent = todayVal.toLocaleString();
    if (weekCountEl) weekCountEl.textContent = weekVal.toLocaleString();
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

  // Show success message to user
  function showSuccess(message) {
    const div = document.createElement('div');
    div.className = 'success-message';
    div.textContent = message;
    div.setAttribute('role', 'status');
    div.style.cssText = `
      position: fixed;
      top: 10px;
      left: 50%;
      transform: translateX(-50%);
      background: #34c759;
      color: white;
      padding: 12px 20px;
      border-radius: 8px;
      font-size: 13px;
      font-weight: 500;
      box-shadow: 0 4px 12px rgba(0, 0, 0, 0.2);
      z-index: 1000;
      animation: slideDown 0.3s ease-out;
    `;
    document.body.appendChild(div);
    setTimeout(() => {
      div.style.opacity = '0';
      div.style.transition = 'opacity 0.3s';
      setTimeout(() => div.remove(), 300);
    }, 2000);
  }

  // Escape HTML to prevent XSS
  function escapeHTML(str) {
    const div = document.createElement('div');
    div.appendChild(document.createTextNode(str));
    return div.innerHTML;
  }

  // Validate domain format for allowlist
  function isValidDomain(str) {
    return /^(\*\.)?[a-zA-Z0-9]([a-zA-Z0-9-]*[a-zA-Z0-9])?(\.[a-zA-Z0-9]([a-zA-Z0-9-]*[a-zA-Z0-9])?)*\.[a-zA-Z]{2,}$/.test(str);
  }

  // Update allowlist count display
  function updateAllowlistCount(count) {
    if (allowlistCountEl) {
      allowlistCountEl.textContent = count > 0 ? `(${count})` : '';
    }
  }

  // Render the allowlist entries
  function renderAllowlist(list) {
    if (!allowlistEntriesEl) return;
    allowlistEntriesEl.innerHTML = '';
    updateAllowlistCount(list.length);

    if (list.length === 0) {
      const li = document.createElement('li');
      li.className = 'allowlist-empty';
      li.textContent = 'No domains allowlisted';
      li.style.cssText = 'color: var(--fg-muted); font-style: italic; justify-content: center;';
      allowlistEntriesEl.appendChild(li);
      return;
    }

    list.forEach(pattern => {
      const li = document.createElement('li');
      li.innerHTML = `<span>${escapeHTML(pattern)}</span><button class="remove-btn" data-pattern="${escapeHTML(pattern)}" aria-label="Remove ${escapeHTML(pattern)}">×</button>`;
      allowlistEntriesEl.appendChild(li);
    });

    // Attach remove listeners
    allowlistEntriesEl.querySelectorAll('.remove-btn').forEach(btn => {
      btn.addEventListener('click', async () => {
        try {
          const result = await sendMessageWithTimeout({ action: 'removeFromAllowlist', pattern: btn.dataset.pattern });
          if (result?.allowlist) {
            renderAllowlist(result.allowlist);
            showSuccess('Domain removed');
          }
        } catch (e) {
          showError('Failed to remove from allowlist.');
        }
      });
    });
  }

  // Detect Safari using feature detection with UA fallback
  function isSafariBrowser() {
    try {
      // Primary: check for Safari-specific native messaging API
      if (typeof browser !== 'undefined' && typeof browser.runtime?.sendNativeMessage === 'function') {
        return true;
      }
      // Fallback: UA-based detection
      const ua = navigator.userAgent || '';
      return ua.includes('Safari') && !ua.match(/Chrome|CriOS|Edg|OPR|Brave|Firefox/i);
    } catch (e) {
      return false;
    }
  }

  // Initialize popup
  async function init() {
    try {
      // Validate required elements exist
      if (!enabledToggle || !statusText) {
        throw new Error('Required popup elements not found');
      }

      // Safari-only guard
      if (!isSafariBrowser()) {
        enabledToggle.disabled = true;
        statusText.textContent = 'Safari only';
        if (statusDetail) statusDetail.textContent = 'This extension requires Safari';
        if (statusPill) {
          statusPill.textContent = 'Unsupported';
          statusPill.classList.add('inactive');
        }
        showError('FreeYT is a Safari-only extension. Install and use it in Safari.');
        return;
      }

      // Get current state from background
      const result = await sendMessageWithTimeout({ action: 'getState' });
      const enabled = result?.enabled ?? true;
      setStatusUI(enabled);

      // Get and display video count
      const videoCount = result?.videoCount ?? 0;
      setVideoCount(videoCount);

      // Get daily stats
      try {
        const dailyResult = await sendMessageWithTimeout({ action: 'getDailyStats' });
        setDailyStats(dailyResult?.stats);
      } catch (e) {
        console.log('[FreeYT Popup] Daily stats load skipped');
      }

      // Allowlist
      try {
        const alResult = await sendMessageWithTimeout({ action: 'getAllowlist' });
        renderAllowlist(alResult?.allowlist || []);
      } catch (e) {
        console.log('[FreeYT Popup] Allowlist load skipped');
      }

      // Allowlist row toggle
      if (allowlistRow && allowlistPanel) {
        allowlistRow.addEventListener('click', () => {
          allowlistPanel.hidden = !allowlistPanel.hidden;
        });
      }

      // Allowlist add with validation
      if (allowlistAddBtn && allowlistInput) {
        allowlistAddBtn.addEventListener('click', async () => {
          const pattern = allowlistInput.value.trim();
          if (!pattern) return;

          if (!isValidDomain(pattern)) {
            showError('Enter a valid domain (e.g. music.youtube.com)');
            return;
          }

          try {
            // Check entry limit
            const currentResult = await sendMessageWithTimeout({ action: 'getAllowlist' });
            const currentList = currentResult?.allowlist || [];
            if (currentList.length >= MAX_ALLOWLIST) {
              showError(`Allowlist is full (max ${MAX_ALLOWLIST} domains).`);
              return;
            }
            if (currentList.includes(pattern)) {
              showError('Domain already in allowlist.');
              return;
            }

            const result = await sendMessageWithTimeout({ action: 'addToAllowlist', pattern });
            if (result?.allowlist) {
              renderAllowlist(result.allowlist);
              showSuccess('Domain added');
            }
            allowlistInput.value = '';
          } catch (e) {
            showError('Failed to add to allowlist.');
          }
        });

        allowlistInput.addEventListener('keydown', (e) => {
          if (e.key === 'Enter') allowlistAddBtn.click();
        });
      }

      // Listen for toggle changes
      enabledToggle.addEventListener('change', async () => {
        const newState = enabledToggle.checked;

        try {
          const response = await sendMessageWithTimeout({ action: 'setState', enabled: newState });
          if (!response?.success) {
            throw new Error('Background rejected state change');
          }
          setStatusUI(newState);
          console.log('[FreeYT Popup] State changed to:', newState);
        } catch (error) {
          console.error('[FreeYT Popup] Failed to save state:', error);
          if (error.message === 'Background script timeout') {
            showError('Extension is waking up. Please try again.');
          } else {
            showError('Failed to save settings. Please try again.');
          }
          // Revert UI to previous state
          setStatusUI(!newState);
        }
      });

      // Refresh state row
      if (refreshRow) {
        refreshRow.addEventListener('click', async () => {
          try {
            await sendMessageWithTimeout({ action: 'syncWithNative' });
            const result = await sendMessageWithTimeout({ action: 'getState' });
            const enabled = result?.enabled ?? true;
            setStatusUI(enabled);
            const videoCount = result?.videoCount ?? 0;
            setVideoCount(videoCount);
            try {
              const dailyResult = await sendMessageWithTimeout({ action: 'getDailyStats' });
              setDailyStats(dailyResult?.stats);
            } catch (e) { /* skip */ }
            console.log('[FreeYT Popup] State refreshed, videoCount:', videoCount);
          } catch (error) {
            console.error('[FreeYT Popup] Refresh failed:', error);
            if (error.message === 'Background script timeout') {
              showError('Extension is waking up. Please try again.');
            } else {
              showError('Could not refresh state from Safari.');
            }
          }
        });
      }

      console.log('[FreeYT Popup] Initialized, current state:', enabled);
    } catch (error) {
      console.error('[FreeYT Popup] Initialization error:', error);
      if (error.message === 'Background script timeout') {
        showError('Extension is waking up. Please reload the popup.');
      } else {
        showError('Failed to initialize extension popup. Please reload.');
      }
    }
  }

  // Start when DOM is ready
  if (document.readyState === 'loading') {
    document.addEventListener('DOMContentLoaded', init);
  } else {
    init();
  }
})();
