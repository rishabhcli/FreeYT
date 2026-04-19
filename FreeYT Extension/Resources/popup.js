(function () {
  'use strict';

  const enabledToggle = document.getElementById('enabledToggle');
  const summaryTitle = document.getElementById('summaryTitle');
  const summaryDetail = document.getElementById('summaryDetail');
  const statusPill = document.getElementById('statusPill');
  const syncPill = document.getElementById('syncPill');
  const currentSitePill = document.getElementById('currentSitePill');
  const todayCountEl = document.getElementById('todayCount');
  const weekCountEl = document.getElementById('weekCount');
  const videoCountEl = document.getElementById('videoCount');
  const currentSiteDetail = document.getElementById('currentSiteDetail');
  const currentSiteButton = document.getElementById('currentSiteButton');
  const exceptionsButton = document.getElementById('exceptionsButton');
  const dashboardButton = document.getElementById('dashboardButton');
  const refreshButton = document.getElementById('refreshButton');
  const exceptionsPanel = document.getElementById('exceptionsPanel');
  const exceptionsCount = document.getElementById('exceptionsCount');
  const exceptionInput = document.getElementById('exceptionInput');
  const exceptionAdd = document.getElementById('exceptionAdd');
  const exceptionsList = document.getElementById('exceptionsList');
  const toast = document.getElementById('toast');
  const DOMAIN_PATTERN = /^(\*\.)?[a-zA-Z0-9]([a-zA-Z0-9-]*[a-zA-Z0-9])?(\.[a-zA-Z0-9]([a-zA-Z0-9-]*[a-zA-Z0-9])?)*\.[a-zA-Z]{2,}$/;
  const MESSAGE_TIMEOUT_MS = 3000;
  const TOAST_DURATION_MS = 2200;

  function isSafariBrowser() {
    try {
      if (typeof browser !== 'undefined' && typeof browser.runtime?.sendNativeMessage === 'function') {
        return true;
      }
      const ua = navigator.userAgent || '';
      return ua.includes('Safari') && !ua.match(/Chrome|CriOS|Edg|OPR|Brave|Firefox/i);
    } catch (error) {
      return false;
    }
  }

  function sendMessageWithTimeout(message, timeoutMs = MESSAGE_TIMEOUT_MS) {
    return Promise.race([
      chrome.runtime.sendMessage(message),
      new Promise((_, reject) => setTimeout(() => reject(new Error('Background script timeout')), timeoutMs))
    ]);
  }

  function showToast(message, kind = 'status') {
    if (!toast) return;
    toast.textContent = message;
    toast.hidden = false;
    toast.className = `toast${kind === 'error' ? ' error' : ''}`;
    clearTimeout(showToast._timeout);
    showToast._timeout = setTimeout(() => {
      toast.hidden = true;
    }, TOAST_DURATION_MS);
  }

  function setBusyState(control, busy) {
    if (!control) return;
    control.disabled = busy;
    control.setAttribute('aria-busy', busy ? 'true' : 'false');
  }

  async function runWithBusyState(control, action) {
    if (!control || control.disabled) {
      return false;
    }

    setBusyState(control, true);
    try {
      await action();
      return true;
    } finally {
      setBusyState(control, false);
    }
  }

  function setProtectionUI(state) {
    enabledToggle.checked = !!state.enabled;
    enabledToggle.setAttribute('aria-checked', state.enabled ? 'true' : 'false');

    summaryTitle.textContent = state.enabled ? 'Protection is active' : 'Protection is paused';
    summaryDetail.textContent = state.enabled
      ? 'YouTube links are routing through privacy-enhanced embeds.'
      : 'Turn protection back on to route YouTube links through privacy-enhanced embeds.';

    statusPill.textContent = state.enabled ? 'Active' : 'Paused';
    statusPill.className = `pill ${state.enabled ? 'accent' : 'subtle'}`;

    syncPill.textContent = state.lastSyncState || 'Safari unavailable';
    currentSitePill.textContent = state.currentSite?.displayDomain || 'No YouTube tab';
  }

  function setStats(state) {
    todayCountEl.textContent = Number(state.todayCount || 0).toLocaleString();
    weekCountEl.textContent = Number(state.weekCount || 0).toLocaleString();
    videoCountEl.textContent = Number(state.videoCount || 0).toLocaleString();
  }

  function setCurrentSiteUI(currentSite) {
    if (!currentSite?.domain) {
      currentSiteDetail.textContent = 'Open a YouTube tab to add a quick exception.';
      currentSiteButton.disabled = true;
      currentSiteButton.textContent = 'Bypass this site';
      currentSitePill.textContent = 'No YouTube tab';
      return;
    }

    currentSitePill.textContent = currentSite.displayDomain;

    if (!currentSite.isSupportedDomain) {
      currentSiteDetail.textContent = 'Quick exceptions only work when the active tab is on a supported YouTube page.';
      currentSiteButton.disabled = true;
      currentSiteButton.textContent = 'Bypass this site';
      return;
    }

    currentSiteButton.disabled = false;
    currentSiteButton.textContent = currentSite.isException ? 'Remove site exception' : 'Bypass this site';
    currentSiteDetail.textContent = currentSite.isException
      ? `${currentSite.displayDomain} currently stays on YouTube.`
      : `Add ${currentSite.displayDomain} to trusted exceptions if you need it to stay on YouTube.`;
  }

  function renderExceptions(exceptions) {
    const list = Array.isArray(exceptions) ? [...exceptions].sort() : [];
    exceptionsCount.textContent = `${list.length} saved`;
    exceptionsList.innerHTML = '';

    if (list.length === 0) {
      const item = document.createElement('li');
      item.className = 'empty-state';
      item.textContent = 'Most people can leave this empty. Add a domain only when you need that site to stay on YouTube.';
      exceptionsList.appendChild(item);
      return;
    }

    list.forEach((domain) => {
      const item = document.createElement('li');
      const content = document.createElement('div');
      const title = document.createElement('strong');
      const detail = document.createElement('span');
      const removeButton = document.createElement('button');

      item.className = 'exception-item';
      title.textContent = domain;
      detail.textContent = 'Keep this site on YouTube instead of routing through embeds.';
      content.appendChild(title);
      content.appendChild(detail);

      removeButton.type = 'button';
      removeButton.dataset.domain = domain;
      removeButton.textContent = 'Remove';
      removeButton.addEventListener('click', async () => {
        await runWithBusyState(removeButton, async () => {
          try {
            const result = await sendMessageWithTimeout({ action: 'removeFromAllowlist', pattern: domain });
            if (!result?.success) {
              throw new Error(result?.error || 'Could not remove the exception.');
            }
            await loadDashboardState();
            showToast('Exception removed');
          } catch (error) {
            showToast(error.message || 'Could not remove the exception.', 'error');
          }
        });
      });

      item.appendChild(content);
      item.appendChild(removeButton);
      exceptionsList.appendChild(item);
    });
  }

  function isValidDomain(value) {
    return DOMAIN_PATTERN.test(value);
  }

  function isSupportedExceptionDomain(value) {
    return value === 'youtu.be'
      || value === 'youtube.com'
      || value.endsWith('.youtube.com');
  }

  async function loadDashboardState() {
    const state = await sendMessageWithTimeout({ action: 'getDashboardState' });
    setProtectionUI(state);
    setStats(state);
    setCurrentSiteUI(state.currentSite);
    renderExceptions(state.exceptions || []);
  }

  async function init() {
    if (!isSafariBrowser()) {
      enabledToggle.disabled = true;
      summaryTitle.textContent = 'Safari only';
      summaryDetail.textContent = 'FreeYT runs as a Safari extension and needs Safari to protect YouTube privacy.';
      statusPill.textContent = 'Unsupported';
      statusPill.className = 'pill subtle';
      currentSiteButton.disabled = true;
      showToast('Open FreeYT in Safari to use the extension.', 'error');
      return;
    }

    try {
      await loadDashboardState();
    } catch (error) {
      showToast(error.message === 'Background script timeout' ? 'Extension is waking up. Try again.' : 'Could not load FreeYT.', 'error');
    }

    enabledToggle.addEventListener('change', async () => {
      const nextValue = enabledToggle.checked;
      await runWithBusyState(enabledToggle, async () => {
        try {
          await sendMessageWithTimeout({ action: 'setState', enabled: nextValue });
          await loadDashboardState();
        } catch (error) {
          enabledToggle.checked = !nextValue;
          showToast('Could not change protection state.', 'error');
        }
      });
    });

    currentSiteButton.addEventListener('click', async () => {
      await runWithBusyState(currentSiteButton, async () => {
        try {
          const result = await sendMessageWithTimeout({ action: 'toggleCurrentSiteException' });
          if (!result.success) {
            throw new Error(result.error || 'No supported site.');
          }
          await loadDashboardState();
          showToast(result.currentSite?.isException ? 'Site added to exceptions' : 'Site exception removed');
        } catch (error) {
          showToast(error.message || 'Could not update this site.', 'error');
        }
      });
    });

    exceptionsButton.addEventListener('click', () => {
      exceptionsPanel.hidden = !exceptionsPanel.hidden;
      exceptionsButton.setAttribute('aria-expanded', exceptionsPanel.hidden ? 'false' : 'true');
      exceptionsButton.textContent = exceptionsPanel.hidden ? 'Manage exceptions' : 'Hide exceptions';
    });

    exceptionAdd.addEventListener('click', async () => {
      const domain = exceptionInput.value.trim().toLowerCase();
      if (!domain) return;
      if (!isValidDomain(domain)) {
        showToast('Use a valid domain like music.youtube.com.', 'error');
        return;
      }
      if (!isSupportedExceptionDomain(domain)) {
        showToast('Use a supported YouTube domain like music.youtube.com.', 'error');
        return;
      }

      const inputWasDisabled = exceptionInput.disabled;
      setBusyState(exceptionInput, true);

      try {
        await runWithBusyState(exceptionAdd, async () => {
          try {
            const result = await sendMessageWithTimeout({ action: 'addToAllowlist', pattern: domain });
            if (!result?.success) {
              throw new Error(result?.error || 'Could not add the exception.');
            }
            exceptionInput.value = '';
            await loadDashboardState();
            showToast('Exception added');
          } catch (error) {
            showToast(error.message || 'Could not add the exception.', 'error');
          }
        });
      } finally {
        exceptionInput.disabled = inputWasDisabled;
        exceptionInput.setAttribute('aria-busy', 'false');
      }
    });

    exceptionInput.addEventListener('keydown', (event) => {
      if (event.key === 'Enter') {
        exceptionAdd.click();
      }
    });

    refreshButton.addEventListener('click', async () => {
      await runWithBusyState(refreshButton, async () => {
        try {
          await sendMessageWithTimeout({ action: 'syncWithNative' });
          await loadDashboardState();
          showToast('Dashboard refreshed');
        } catch (error) {
          showToast('Could not refresh FreeYT.', 'error');
        }
      });
    });

    dashboardButton.addEventListener('click', async () => {
      await runWithBusyState(dashboardButton, async () => {
        try {
          const result = await sendMessageWithTimeout({ action: 'openDashboard', section: 'overview' });
          if (!result?.success) {
            throw new Error(result?.error || 'Could not open FreeYT.');
          }
        } catch (error) {
          showToast('Could not open the FreeYT app.', 'error');
        }
      });
    });
  }

  if (document.readyState === 'loading') {
    document.addEventListener('DOMContentLoaded', init);
  } else {
    init();
  }
})();
