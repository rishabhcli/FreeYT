// FreeYT Content Script
// Fallback redirector in case declarativeNetRequest misses a URL.
// Redirects YouTube watch/shorts/live/embed/youtu.be links by inserting a
// hyphen in the hostname (youtube.com → yout-ube.com). Non-video pages are left untouched.

(function () {
  'use strict';

  const STORAGE_KEY = 'enabled';
  const HYphen_HOST_SUFFIX = 'yout-ube.com'; // target domain with inserted hyphen
  const AUTOPLAY_HOSTS = [HYphen_HOST_SUFFIX, 'youtube-nocookie.com'];
  const QUALITY_ORDER = ['highres', 'hd2160', 'hd1440', 'hd1080', 'hd720', 'large'];
  const QUALITY_LOCK = 'highres';

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
  let autoplayAttempted = false;
  let qualityRequested = false;

  // Detect known video URL shapes and return a hyphen-host redirect.
  function computeRedirectUrl(urlString) {
    try {
      const url = new URL(urlString);
      const host = url.hostname.toLowerCase();

      // Already redirected / target hosts
      if (host.includes(HYphen_HOST_SUFFIX) || host.includes('youtube-nocookie.com')) {
        return null;
      }

      // Extract video id for each supported pattern
      let videoId = null;

      // youtu.be → yout-ube.com/watch?v=ID&autoplay=1
      if (host === 'youtu.be') {
        const pathParts = url.pathname.split('/').filter(Boolean);
        videoId = pathParts[0];
        if (!videoId) return null;
        const params = new URLSearchParams(url.search);
        params.set('v', videoId);
        ensurePlayerParams(params);
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
        const params = new URLSearchParams(url.search);
        ensurePlayerParams(params);
        url.search = params.toString() ? `?${params.toString()}` : '';
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
    triggerAutoplayIfNeeded();
    watchUrlChanges();
  }

  init().catch(err => console.error('[FreeYT] Content script init failed:', err));

  // Attempt to auto-play once on the hyphen domain when autoplay is requested.
  function triggerAutoplayIfNeeded() {
    const host = location.hostname.toLowerCase();
    const url = new URL(location.href);
    const isAutoplayHost = AUTOPLAY_HOSTS.some(h => host.includes(h));
    if (!isAutoplayHost) return;

    // Ensure autoplay-friendly params, then reload once if needed
    let updated = ensurePlayerParams(url.searchParams);
    if (updated) {
      location.replace(url.toString());
      return;
    }

    const wantsAutoplay = url.searchParams.get('autoplay') === '1';
    if (!wantsAutoplay || autoplayAttempted) {
      return;
    }
    autoplayAttempted = true;

    const playVideo = () => {
      const video = document.querySelector('video');
      if (!video) return false;
      // Try to start muted, then unmute immediately for audio playback.
      video.muted = true;
      const p = video.play();
      if (p && typeof p.then === 'function') {
        p.then(() => {
          video.muted = false;
          requestHighestQuality();
        }).catch(err => {
          console.warn('[FreeYT] Autoplay promise rejected:', err);
        });
      } else {
        video.muted = false;
        requestHighestQuality();
      }
      // Also listen for metadata to ensure quality request once video is ready.
      video.addEventListener('loadedmetadata', requestHighestQuality, { once: true });
      return true;
    };

    if (playVideo()) return;

    // Observe DOM for video availability, retrying briefly
    const observer = new MutationObserver(() => {
      if (playVideo()) {
        observer.disconnect();
      }
    });
    observer.observe(document.documentElement || document, { childList: true, subtree: true });

    // Safety timeout to stop observing after a few seconds
    setTimeout(() => observer.disconnect(), 5000);
  }

  // Ask the player to switch to the best available quality.
  function requestHighestQuality() {
    if (qualityRequested) return;
    qualityRequested = true;

    const sendCommand = (func, args) => {
      try {
        const message = JSON.stringify({ event: 'command', func, args });
        window.postMessage(message, '*');
      } catch (err) {
        console.warn('[FreeYT] Failed to request quality:', err);
      }
    };

    // Try to lock range to the top quality first, then ask for descending options.
    sendCommand('setPlaybackQualityRange', [QUALITY_LOCK, QUALITY_LOCK]);
    QUALITY_ORDER.forEach((q, idx) => {
      setTimeout(() => sendCommand('setPlaybackQuality', [q]), idx * 200);
    });
  }

  // Ensure autoplay + JS API params on player URLs.
  function ensurePlayerParams(params) {
    let changed = false;
    if (params.get('autoplay') !== '1') {
      params.set('autoplay', '1');
      changed = true;
    }
    if (!params.get('start')) {
      params.set('start', '0');
      changed = true;
    }
    if (params.get('enablejsapi') !== '1') {
      params.set('enablejsapi', '1');
      changed = true;
    }
    if (params.get('playsinline') !== '1') {
      params.set('playsinline', '1');
      changed = true;
    }
    return changed;
  }

  // Listen for player ready messages to retry quality selection.
  window.addEventListener('message', (event) => {
    if (typeof event.data !== 'string') return;
    try {
      const data = JSON.parse(event.data);
      if (data?.event === 'onReady') {
        qualityRequested = false; // allow another round when player reports ready
        requestHighestQuality();
      }
    } catch (_) {
      // ignore non-JSON messages
    }
  });
})();
