// FreeYT Content Script
// Fallback redirector in case declarativeNetRequest misses a URL.
// Redirects YouTube watch/shorts/live/embed/youtu.be links by inserting a
// hyphen in the hostname (youtube.com → yout-ube.com). Non-video pages are left untouched.

(function () {
  'use strict';

  const STORAGE_KEY = 'enabled';
  const HYphen_HOST_SUFFIX = 'yout-ube.com'; // target domain with inserted hyphen

  const api = typeof chrome !== 'undefined'
    ? chrome
    : (typeof browser !== 'undefined' ? browser : null);

  if (!api || !api.storage) {
    console.warn('[FreeYT] No extension API available; redirect script not active');
    return;
  }

  let enabled = true;
  let redirecting = false;
  let lastUrl = location.href;

  // Detect known video URL shapes and return a hyphen-host redirect.
  function computeRedirectUrl(urlString) {
    try {
      const url = new URL(urlString);
      const host = url.hostname.toLowerCase();

      // Already redirected
      if (host.includes(HYphen_HOST_SUFFIX)) {
        return null;
      }

      // Extract video id for each supported pattern
      let videoId = null;

      // youtu.be → yout-ube.com/watch?v=ID
      if (host === 'youtu.be') {
        const pathParts = url.pathname.split('/').filter(Boolean);
        videoId = pathParts[0];
        if (!videoId) return null;
        const params = new URLSearchParams(url.search);
        params.set('v', videoId);
        url.hostname = `www.${HYphen_HOST_SUFFIX}`;
        url.pathname = '/watch';
        url.search = params.toString() ? `?${params.toString()}` : '';
        return url.toString();
      }

      if (host.includes('youtube.com')) {
        const pathParts = url.pathname.split('/').filter(Boolean);

        if (url.pathname.startsWith('/watch')) {
          videoId = url.searchParams.get('v');
        } else if (url.pathname.startsWith('/shorts/')) {
          videoId = pathParts.length >= 2 ? pathParts[1] : null;
        } else if (url.pathname.startsWith('/embed/')) {
          videoId = pathParts.length >= 2 ? pathParts[1] : null;
        } else if (url.pathname.startsWith('/live/')) {
          videoId = pathParts.length >= 2 ? pathParts[1] : null;
        }

        if (!videoId) return null; // Non-video page; don't redirect

        url.hostname = url.hostname.replace('youtube.com', HYphen_HOST_SUFFIX);
        return url.toString();
      }

      return null;
    } catch (err) {
      console.warn('[FreeYT] Failed to parse URL for redirect:', err);
      return null;
    }
  }

  async function refreshEnabledState() {
    try {
      const result = await api.storage.local.get(STORAGE_KEY);
      enabled = result?.[STORAGE_KEY] !== false; // default to true
    } catch (err) {
      console.warn('[FreeYT] Could not read storage; assuming enabled:', err);
      enabled = true;
    }
  }

  async function maybeRedirect(reason) {
    if (redirecting) return;
    if (!enabled) return;

    const target = computeRedirectUrl(location.href);
    if (target && target !== location.href) {
      redirecting = true;
      console.log('[FreeYT] Redirecting (', reason, '):', location.href, '→', target);
      location.replace(target);
    }
  }

  function watchUrlChanges() {
    // Hook SPA navigation
    const originalPushState = history.pushState;
    history.pushState = function () {
      originalPushState.apply(history, arguments);
      queueCheck('pushState');
    };

    const originalReplaceState = history.replaceState;
    history.replaceState = function () {
      originalReplaceState.apply(history, arguments);
      queueCheck('replaceState');
    };

    window.addEventListener('popstate', () => queueCheck('popstate'));

    // Mutation observer for dynamic page title/head changes
    const observer = new MutationObserver(() => queueCheck('mutation'));
    observer.observe(document.documentElement || document, { childList: true, subtree: true });

    // Periodic polling as a safety net
    setInterval(() => queueCheck('poll'), 1500);
  }

  function queueCheck(reason) {
    const current = location.href;
    if (current === lastUrl) return;
    lastUrl = current;
    setTimeout(() => maybeRedirect(reason), 75);
  }

  async function init() {
    await refreshEnabledState();
    api.storage.onChanged.addListener((changes, area) => {
      if (area === 'local' && changes[STORAGE_KEY]) {
        enabled = changes[STORAGE_KEY].newValue !== false;
      }
    });

    await maybeRedirect('initial');
    watchUrlChanges();
  }

  init().catch(err => console.error('[FreeYT] Content script init failed:', err));
})();
