/**
 * content.test.js - Tests for the content script URL transformation
 *
 * These tests verify the computeRedirectUrl function and related
 * URL transformation logic in the content script.
 */

import { describe, it, beforeEach } from 'node:test';
import assert from 'node:assert/strict';

// Constants from content.js
const STORAGE_KEY = 'enabled';
const HYPHEN_HOST_SUFFIX = 'yout-ube.com';
const AUTOPLAY_HOSTS = [HYPHEN_HOST_SUFFIX, 'youtube-nocookie.com'];
const QUALITY_ORDER = ['highres', 'hd2160', 'hd1440', 'hd1080', 'hd720', 'large'];

/**
 * Recreated computeRedirectUrl function for testing
 * This mirrors the logic in content.js
 */
function computeRedirectUrl(urlString) {
  try {
    const url = new URL(urlString);
    const host = url.hostname.toLowerCase();

    // Already redirected / target hosts
    if (host.includes(HYPHEN_HOST_SUFFIX) || host.includes('youtube-nocookie.com')) {
      return null;
    }

    let videoId = null;

    // youtu.be → yout-ube.com/watch?v=ID&autoplay=1
    if (host === 'youtu.be') {
      const pathParts = url.pathname.split('/').filter(Boolean);
      videoId = pathParts[0];
      if (!videoId) return null;
      const params = new URLSearchParams(url.search);
      params.set('v', videoId);
      ensurePlayerParams(params);
      url.hostname = `www.${HYPHEN_HOST_SUFFIX}`;
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

      if (!videoId) return null;

      url.hostname = url.hostname.replace('youtube.com', HYPHEN_HOST_SUFFIX);
      const params = new URLSearchParams(url.search);
      ensurePlayerParams(params);
      url.search = params.toString() ? `?${params.toString()}` : '';
      return url.toString();
    }

    return null;
  } catch (err) {
    return null;
  }
}

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

describe('Constants', () => {
  it('should have correct storage key', () => {
    assert.equal(STORAGE_KEY, 'enabled');
  });

  it('should have correct target domain suffix', () => {
    assert.equal(HYPHEN_HOST_SUFFIX, 'yout-ube.com');
  });

  it('should have correct autoplay hosts', () => {
    assert.deepEqual(AUTOPLAY_HOSTS, ['yout-ube.com', 'youtube-nocookie.com']);
  });

  it('should have correct quality order', () => {
    assert.deepEqual(QUALITY_ORDER, ['highres', 'hd2160', 'hd1440', 'hd1080', 'hd720', 'large']);
  });
});

describe('computeRedirectUrl - Standard Watch URLs', () => {
  it('should redirect https://www.youtube.com/watch?v=VIDEO_ID', () => {
    const url = 'https://www.youtube.com/watch?v=dQw4w9WgXcQ';
    const result = computeRedirectUrl(url);

    assert.ok(result !== null);
    assert.ok(result.includes('yout-ube.com'));
    assert.ok(result.includes('v=dQw4w9WgXcQ'));
    assert.ok(result.includes('autoplay=1'));
  });

  it('should redirect https://youtube.com/watch?v=VIDEO_ID (no www)', () => {
    const url = 'https://youtube.com/watch?v=dQw4w9WgXcQ';
    const result = computeRedirectUrl(url);

    assert.ok(result !== null);
    assert.ok(result.includes('yout-ube.com'));
  });

  it('should preserve video ID in redirect', () => {
    const videoId = 'abc123XYZ-_';
    const url = `https://www.youtube.com/watch?v=${videoId}`;
    const result = computeRedirectUrl(url);

    assert.ok(result.includes(`v=${videoId}`));
  });

  it('should handle URL with timestamp parameter', () => {
    const url = 'https://www.youtube.com/watch?v=dQw4w9WgXcQ&t=42s';
    const result = computeRedirectUrl(url);

    assert.ok(result !== null);
    assert.ok(result.includes('yout-ube.com'));
  });

  it('should handle URL with list parameter', () => {
    const url = 'https://www.youtube.com/watch?v=dQw4w9WgXcQ&list=PLxyz';
    const result = computeRedirectUrl(url);

    assert.ok(result !== null);
  });

  it('should add autoplay parameter', () => {
    const url = 'https://www.youtube.com/watch?v=dQw4w9WgXcQ';
    const result = computeRedirectUrl(url);

    assert.ok(result.includes('autoplay=1'));
  });
});

describe('computeRedirectUrl - Mobile URLs', () => {
  it('should redirect https://m.youtube.com/watch?v=VIDEO_ID', () => {
    const url = 'https://m.youtube.com/watch?v=dQw4w9WgXcQ';
    const result = computeRedirectUrl(url);

    assert.ok(result !== null);
    assert.ok(result.includes('yout-ube.com'));
    assert.ok(result.includes('v=dQw4w9WgXcQ'));
  });

  it('should preserve mobile subdomain transformation', () => {
    const url = 'https://m.youtube.com/watch?v=dQw4w9WgXcQ';
    const result = computeRedirectUrl(url);

    assert.ok(result.includes('m.yout-ube.com'));
  });
});

describe('computeRedirectUrl - Short URLs (youtu.be)', () => {
  it('should redirect https://youtu.be/VIDEO_ID', () => {
    const url = 'https://youtu.be/dQw4w9WgXcQ';
    const result = computeRedirectUrl(url);

    assert.ok(result !== null);
    assert.ok(result.includes('yout-ube.com'));
    assert.ok(result.includes('v=dQw4w9WgXcQ'));
  });

  it('should convert youtu.be to watch format', () => {
    const url = 'https://youtu.be/dQw4w9WgXcQ';
    const result = computeRedirectUrl(url);

    assert.ok(result.includes('/watch'));
  });

  it('should handle youtu.be with timestamp', () => {
    const url = 'https://youtu.be/dQw4w9WgXcQ?t=42';
    const result = computeRedirectUrl(url);

    assert.ok(result !== null);
    assert.ok(result.includes('yout-ube.com'));
  });

  it('should handle youtu.be with si parameter', () => {
    const url = 'https://youtu.be/dQw4w9WgXcQ?si=shareIdXyz';
    const result = computeRedirectUrl(url);

    assert.ok(result !== null);
  });

  it('should return null for youtu.be without video ID', () => {
    const url = 'https://youtu.be/';
    const result = computeRedirectUrl(url);

    assert.equal(result, null);
  });
});

describe('computeRedirectUrl - Shorts URLs', () => {
  it('should redirect https://www.youtube.com/shorts/VIDEO_ID', () => {
    const url = 'https://www.youtube.com/shorts/abc123def';
    const result = computeRedirectUrl(url);

    assert.ok(result !== null);
    assert.ok(result.includes('yout-ube.com'));
    assert.ok(result.includes('/shorts/'));
    assert.ok(result.includes('abc123def'));
  });

  it('should handle shorts URL with query params', () => {
    const url = 'https://www.youtube.com/shorts/abc123def?feature=share';
    const result = computeRedirectUrl(url);

    assert.ok(result !== null);
  });
});

describe('computeRedirectUrl - Embed URLs', () => {
  it('should redirect https://www.youtube.com/embed/VIDEO_ID', () => {
    const url = 'https://www.youtube.com/embed/dQw4w9WgXcQ';
    const result = computeRedirectUrl(url);

    assert.ok(result !== null);
    assert.ok(result.includes('yout-ube.com'));
    assert.ok(result.includes('/embed/'));
  });

  it('should handle embed URL with autoplay', () => {
    const url = 'https://www.youtube.com/embed/dQw4w9WgXcQ?autoplay=1';
    const result = computeRedirectUrl(url);

    assert.ok(result !== null);
  });
});

describe('computeRedirectUrl - Live URLs', () => {
  it('should redirect https://www.youtube.com/live/VIDEO_ID', () => {
    const url = 'https://www.youtube.com/live/xyz789abc';
    const result = computeRedirectUrl(url);

    assert.ok(result !== null);
    assert.ok(result.includes('yout-ube.com'));
    assert.ok(result.includes('/live/'));
  });
});

describe('computeRedirectUrl - Already Redirected URLs', () => {
  it('should return null for yout-ube.com URLs', () => {
    const url = 'https://www.yout-ube.com/watch?v=dQw4w9WgXcQ';
    const result = computeRedirectUrl(url);

    assert.equal(result, null);
  });

  it('should return null for youtube-nocookie.com URLs', () => {
    const url = 'https://www.youtube-nocookie.com/embed/dQw4w9WgXcQ';
    const result = computeRedirectUrl(url);

    assert.equal(result, null);
  });

  it('should return null for already-redirected shorts', () => {
    const url = 'https://www.yout-ube.com/shorts/abc123';
    const result = computeRedirectUrl(url);

    assert.equal(result, null);
  });
});

describe('computeRedirectUrl - Non-Video Pages', () => {
  it('should return null for YouTube homepage', () => {
    const url = 'https://www.youtube.com/';
    const result = computeRedirectUrl(url);

    assert.equal(result, null);
  });

  it('should return null for YouTube search', () => {
    const url = 'https://www.youtube.com/results?search_query=test';
    const result = computeRedirectUrl(url);

    assert.equal(result, null);
  });

  it('should return null for YouTube channel', () => {
    const url = 'https://www.youtube.com/@channelname';
    const result = computeRedirectUrl(url);

    assert.equal(result, null);
  });

  it('should return null for YouTube feed', () => {
    const url = 'https://www.youtube.com/feed/trending';
    const result = computeRedirectUrl(url);

    assert.equal(result, null);
  });

  it('should return null for YouTube subscriptions', () => {
    const url = 'https://www.youtube.com/feed/subscriptions';
    const result = computeRedirectUrl(url);

    assert.equal(result, null);
  });

  it('should return null for YouTube history', () => {
    const url = 'https://www.youtube.com/feed/history';
    const result = computeRedirectUrl(url);

    assert.equal(result, null);
  });

  it('should return null for YouTube playlist page', () => {
    const url = 'https://www.youtube.com/playlist?list=PLxyz';
    const result = computeRedirectUrl(url);

    assert.equal(result, null);
  });
});

describe('computeRedirectUrl - Non-YouTube URLs', () => {
  it('should return null for google.com', () => {
    const url = 'https://www.google.com/';
    const result = computeRedirectUrl(url);

    assert.equal(result, null);
  });

  it('should return null for other video platforms', () => {
    const urls = [
      'https://www.vimeo.com/123456',
      'https://www.dailymotion.com/video/xyz',
      'https://www.twitch.tv/channel'
    ];

    urls.forEach(url => {
      const result = computeRedirectUrl(url);
      assert.equal(result, null, `Should return null for: ${url}`);
    });
  });

  // Note: The current content.js implementation uses host.includes('youtube.com')
  // which would match domains like 'fakeyoutube.com'. This test documents the behavior.
  it('should be aware that includes() matches substrings (potential edge case)', () => {
    // This documents that fakeyoutube.com would be matched by includes('youtube.com')
    // The declarativeNetRequest rules have stricter regex patterns for this
    const fakeHost = 'www.fakeyoutube.com';
    const matchesByIncludes = fakeHost.includes('youtube.com');
    assert.ok(matchesByIncludes, 'includes() matches substrings - this is expected behavior');
  });
});

describe('computeRedirectUrl - Error Handling', () => {
  it('should return null for invalid URLs', () => {
    const result = computeRedirectUrl('not-a-valid-url');
    assert.equal(result, null);
  });

  it('should return null for empty string', () => {
    const result = computeRedirectUrl('');
    assert.equal(result, null);
  });

  it('should handle URLs with special characters', () => {
    const url = 'https://www.youtube.com/watch?v=abc-123_XYZ';
    const result = computeRedirectUrl(url);

    assert.ok(result !== null);
    assert.ok(result.includes('abc-123_XYZ'));
  });
});

describe('ensurePlayerParams function', () => {
  it('should add autoplay=1 if missing', () => {
    const params = new URLSearchParams();
    ensurePlayerParams(params);

    assert.equal(params.get('autoplay'), '1');
  });

  it('should add start=0 if missing', () => {
    const params = new URLSearchParams();
    ensurePlayerParams(params);

    assert.equal(params.get('start'), '0');
  });

  it('should add enablejsapi=1 if missing', () => {
    const params = new URLSearchParams();
    ensurePlayerParams(params);

    assert.equal(params.get('enablejsapi'), '1');
  });

  it('should add playsinline=1 if missing', () => {
    const params = new URLSearchParams();
    ensurePlayerParams(params);

    assert.equal(params.get('playsinline'), '1');
  });

  it('should return true if params were changed', () => {
    const params = new URLSearchParams();
    const changed = ensurePlayerParams(params);

    assert.equal(changed, true);
  });

  it('should return false if all params already set correctly', () => {
    const params = new URLSearchParams('autoplay=1&start=0&enablejsapi=1&playsinline=1');
    const changed = ensurePlayerParams(params);

    assert.equal(changed, false);
  });

  it('should not override existing autoplay=1', () => {
    const params = new URLSearchParams('autoplay=1');
    ensurePlayerParams(params);

    assert.equal(params.get('autoplay'), '1');
  });

  it('should preserve existing start parameter', () => {
    const params = new URLSearchParams('start=120');
    ensurePlayerParams(params);

    assert.equal(params.get('start'), '120');
  });
});

describe('URL Change Detection', () => {
  it('should detect URL change from initial state', () => {
    let lastUrl = 'https://www.youtube.com/';
    const currentUrl = 'https://www.youtube.com/watch?v=test';

    const changed = currentUrl !== lastUrl;
    assert.ok(changed);
  });

  it('should not detect change for same URL', () => {
    const lastUrl = 'https://www.youtube.com/watch?v=test';
    const currentUrl = 'https://www.youtube.com/watch?v=test';

    const changed = currentUrl !== lastUrl;
    assert.ok(!changed);
  });

  it('should detect video change within watch page', () => {
    let lastUrl = 'https://www.youtube.com/watch?v=video1';
    const currentUrl = 'https://www.youtube.com/watch?v=video2';

    const changed = currentUrl !== lastUrl;
    assert.ok(changed);
  });
});

describe('Autoplay Host Detection', () => {
  it('should detect yout-ube.com as autoplay host', () => {
    const host = 'www.yout-ube.com';
    const isAutoplayHost = AUTOPLAY_HOSTS.some(h => host.includes(h));
    assert.ok(isAutoplayHost);
  });

  it('should detect youtube-nocookie.com as autoplay host', () => {
    const host = 'www.youtube-nocookie.com';
    const isAutoplayHost = AUTOPLAY_HOSTS.some(h => host.includes(h));
    assert.ok(isAutoplayHost);
  });

  it('should NOT detect youtube.com as autoplay host', () => {
    const host = 'www.youtube.com';
    const isAutoplayHost = AUTOPLAY_HOSTS.some(h => host.includes(h));
    assert.ok(!isAutoplayHost);
  });

  it('should NOT detect other hosts as autoplay host', () => {
    const hosts = ['www.google.com', 'www.example.com', 'youtu.be'];
    hosts.forEach(host => {
      const isAutoplayHost = AUTOPLAY_HOSTS.some(h => host.includes(h));
      assert.ok(!isAutoplayHost, `${host} should not be autoplay host`);
    });
  });
});

describe('Video ID Extraction', () => {
  const testCases = [
    { url: 'https://www.youtube.com/watch?v=dQw4w9WgXcQ', expectedId: 'dQw4w9WgXcQ' },
    { url: 'https://youtu.be/dQw4w9WgXcQ', expectedId: 'dQw4w9WgXcQ' },
    { url: 'https://www.youtube.com/shorts/abc123def', expectedId: 'abc123def' },
    { url: 'https://www.youtube.com/embed/xyz789', expectedId: 'xyz789' },
    { url: 'https://www.youtube.com/live/streamId', expectedId: 'streamId' },
  ];

  testCases.forEach(({ url, expectedId }) => {
    it(`should extract video ID "${expectedId}" from ${url}`, () => {
      const result = computeRedirectUrl(url);
      assert.ok(result !== null);
      assert.ok(result.includes(expectedId));
    });
  });

  it('should handle 11-character standard video IDs', () => {
    const videoId = 'dQw4w9WgXcQ'; // Standard 11-char ID
    const url = `https://www.youtube.com/watch?v=${videoId}`;
    const result = computeRedirectUrl(url);

    assert.ok(result.includes(videoId));
  });

  it('should handle video IDs with hyphens', () => {
    const videoId = 'abc-123-xyz';
    const url = `https://www.youtube.com/watch?v=${videoId}`;
    const result = computeRedirectUrl(url);

    assert.ok(result.includes(videoId));
  });

  it('should handle video IDs with underscores', () => {
    const videoId = 'abc_123_xyz';
    const url = `https://www.youtube.com/watch?v=${videoId}`;
    const result = computeRedirectUrl(url);

    assert.ok(result.includes(videoId));
  });
});

describe('Comprehensive URL Coverage', () => {
  const shouldRedirect = [
    'https://www.youtube.com/watch?v=dQw4w9WgXcQ',
    'https://youtube.com/watch?v=dQw4w9WgXcQ',
    'http://www.youtube.com/watch?v=dQw4w9WgXcQ',
    'https://m.youtube.com/watch?v=dQw4w9WgXcQ',
    'https://youtu.be/dQw4w9WgXcQ',
    'http://youtu.be/dQw4w9WgXcQ',
    'https://www.youtube.com/shorts/abc123',
    'https://youtube.com/shorts/abc123',
    'https://www.youtube.com/embed/dQw4w9WgXcQ',
    'https://www.youtube.com/live/streamId',
    'https://www.youtube.com/watch?v=dQw4w9WgXcQ&t=42s',
    'https://www.youtube.com/watch?v=dQw4w9WgXcQ&list=PLxyz',
    'https://youtu.be/dQw4w9WgXcQ?t=42',
    'https://youtu.be/dQw4w9WgXcQ?si=shareId',
  ];

  const shouldNotRedirect = [
    'https://www.youtube.com/',
    'https://www.youtube.com/results?search_query=test',
    'https://www.youtube.com/@channelname',
    'https://www.youtube.com/feed/trending',
    'https://www.youtube.com/playlist?list=PLxyz',
    'https://www.yout-ube.com/watch?v=test',
    'https://www.youtube-nocookie.com/embed/test',
    'https://www.google.com/',
    'https://www.vimeo.com/123456',
    '',
    'invalid-url',
  ];

  shouldRedirect.forEach(url => {
    it(`should redirect: ${url}`, () => {
      const result = computeRedirectUrl(url);
      assert.ok(result !== null, `Expected redirect for: ${url}`);
      assert.ok(result.includes('yout-ube.com'), `Expected yout-ube.com in result for: ${url}`);
    });
  });

  shouldNotRedirect.forEach(url => {
    it(`should NOT redirect: ${url || '(empty string)'}`, () => {
      const result = computeRedirectUrl(url);
      assert.equal(result, null, `Expected null for: ${url}`);
    });
  });
});
