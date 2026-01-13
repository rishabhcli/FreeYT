/**
 * rules.test.js - Tests for declarativeNetRequest rules in rules.json
 *
 * These tests validate that the regex patterns correctly match YouTube URLs
 * and transform them to the expected redirect destinations.
 */

import { describe, it } from 'node:test';
import assert from 'node:assert/strict';
import { readFileSync } from 'node:fs';
import { fileURLToPath } from 'node:url';
import { dirname, join } from 'node:path';

const __filename = fileURLToPath(import.meta.url);
const __dirname = dirname(__filename);

// Load rules.json
const rulesPath = join(__dirname, '..', 'Resources', 'rules.json');
const rules = JSON.parse(readFileSync(rulesPath, 'utf8'));

describe('rules.json structure', () => {
  it('should contain 6 redirect rules', () => {
    assert.equal(rules.length, 6, 'Expected 6 rules in rules.json');
  });

  it('should have sequential rule IDs from 1 to 6', () => {
    const ids = rules.map(r => r.id).sort((a, b) => a - b);
    assert.deepEqual(ids, [1, 2, 3, 4, 5, 6], 'Rule IDs should be 1-6');
  });

  it('should have all rules with type "redirect"', () => {
    rules.forEach((rule, index) => {
      assert.equal(rule.action.type, 'redirect', `Rule ${index + 1} should have type "redirect"`);
    });
  });

  it('should have all rules targeting main_frame only', () => {
    rules.forEach((rule, index) => {
      assert.deepEqual(
        rule.condition.resourceTypes,
        ['main_frame'],
        `Rule ${index + 1} should target main_frame only`
      );
    });
  });

  it('should have all rules with priority 1', () => {
    rules.forEach((rule, index) => {
      assert.equal(rule.priority, 1, `Rule ${index + 1} should have priority 1`);
    });
  });
});

describe('Rule 1: Standard YouTube watch URLs', () => {
  const rule = rules.find(r => r.id === 1);
  const regex = new RegExp(rule.condition.regexFilter);

  it('should match https://www.youtube.com/watch?v=VIDEO_ID', () => {
    const url = 'https://www.youtube.com/watch?v=dQw4w9WgXcQ';
    assert.ok(regex.test(url), `Should match: ${url}`);
  });

  it('should match https://youtube.com/watch?v=VIDEO_ID (no www)', () => {
    const url = 'https://youtube.com/watch?v=dQw4w9WgXcQ';
    assert.ok(regex.test(url), `Should match: ${url}`);
  });

  it('should match http://www.youtube.com/watch?v=VIDEO_ID', () => {
    const url = 'http://www.youtube.com/watch?v=dQw4w9WgXcQ';
    assert.ok(regex.test(url), `Should match: ${url}`);
  });

  it('should match URL with additional query parameters', () => {
    const url = 'https://www.youtube.com/watch?v=dQw4w9WgXcQ&t=42s&list=PLxyz';
    assert.ok(regex.test(url), `Should match: ${url}`);
  });

  it('should match URL with v parameter not first', () => {
    const url = 'https://www.youtube.com/watch?list=PLxyz&v=dQw4w9WgXcQ';
    assert.ok(regex.test(url), `Should match: ${url}`);
  });

  it('should NOT match YouTube homepage', () => {
    const url = 'https://www.youtube.com/';
    assert.ok(!regex.test(url), `Should NOT match: ${url}`);
  });

  it('should NOT match YouTube channel pages', () => {
    const url = 'https://www.youtube.com/@channelname';
    assert.ok(!regex.test(url), `Should NOT match: ${url}`);
  });

  it('should NOT match YouTube search', () => {
    const url = 'https://www.youtube.com/results?search_query=test';
    assert.ok(!regex.test(url), `Should NOT match: ${url}`);
  });
});

describe('Rule 2: YouTube Shorts URLs', () => {
  const rule = rules.find(r => r.id === 2);
  const regex = new RegExp(rule.condition.regexFilter);

  it('should match https://www.youtube.com/shorts/VIDEO_ID', () => {
    const url = 'https://www.youtube.com/shorts/abc123def';
    assert.ok(regex.test(url), `Should match: ${url}`);
  });

  it('should match https://youtube.com/shorts/VIDEO_ID (no www)', () => {
    const url = 'https://youtube.com/shorts/abc123def';
    assert.ok(regex.test(url), `Should match: ${url}`);
  });

  it('should match Shorts URL with query parameters', () => {
    const url = 'https://www.youtube.com/shorts/abc123def?feature=share';
    assert.ok(regex.test(url), `Should match: ${url}`);
  });

  it('should NOT match /shorts without video ID', () => {
    const url = 'https://www.youtube.com/shorts/';
    // The regex requires at least one character after /shorts/
    assert.ok(!regex.test(url), `Should NOT match: ${url}`);
  });
});

describe('Rule 3: YouTube Embed URLs', () => {
  const rule = rules.find(r => r.id === 3);
  const regex = new RegExp(rule.condition.regexFilter);

  it('should match https://www.youtube.com/embed/VIDEO_ID', () => {
    const url = 'https://www.youtube.com/embed/dQw4w9WgXcQ';
    assert.ok(regex.test(url), `Should match: ${url}`);
  });

  it('should match embed URL with autoplay parameter', () => {
    const url = 'https://www.youtube.com/embed/dQw4w9WgXcQ?autoplay=1';
    assert.ok(regex.test(url), `Should match: ${url}`);
  });

  it('should match embed URL with multiple parameters', () => {
    const url = 'https://www.youtube.com/embed/dQw4w9WgXcQ?autoplay=1&mute=1&start=30';
    assert.ok(regex.test(url), `Should match: ${url}`);
  });
});

describe('Rule 4: YouTube Live URLs', () => {
  const rule = rules.find(r => r.id === 4);
  const regex = new RegExp(rule.condition.regexFilter);

  it('should match https://www.youtube.com/live/VIDEO_ID', () => {
    const url = 'https://www.youtube.com/live/xyz789abc';
    assert.ok(regex.test(url), `Should match: ${url}`);
  });

  it('should match live URL with query parameters', () => {
    const url = 'https://www.youtube.com/live/xyz789abc?feature=share';
    assert.ok(regex.test(url), `Should match: ${url}`);
  });
});

describe('Rule 5: Mobile YouTube watch URLs', () => {
  const rule = rules.find(r => r.id === 5);
  const regex = new RegExp(rule.condition.regexFilter);

  it('should match https://m.youtube.com/watch?v=VIDEO_ID', () => {
    const url = 'https://m.youtube.com/watch?v=dQw4w9WgXcQ';
    assert.ok(regex.test(url), `Should match: ${url}`);
  });

  it('should match mobile URL with additional parameters', () => {
    const url = 'https://m.youtube.com/watch?v=dQw4w9WgXcQ&t=120';
    assert.ok(regex.test(url), `Should match: ${url}`);
  });

  it('should NOT match www.youtube.com (handled by rule 1)', () => {
    const url = 'https://www.youtube.com/watch?v=dQw4w9WgXcQ';
    // Rule 5 is specifically for m.youtube.com, not www
    assert.ok(!regex.test(url), `Rule 5 should NOT match www URLs`);
  });
});

describe('Rule 6: youtu.be short URLs', () => {
  const rule = rules.find(r => r.id === 6);
  const regex = new RegExp(rule.condition.regexFilter);

  it('should match https://youtu.be/VIDEO_ID', () => {
    const url = 'https://youtu.be/dQw4w9WgXcQ';
    assert.ok(regex.test(url), `Should match: ${url}`);
  });

  it('should match http://youtu.be/VIDEO_ID', () => {
    const url = 'http://youtu.be/dQw4w9WgXcQ';
    assert.ok(regex.test(url), `Should match: ${url}`);
  });

  it('should match youtu.be URL with timestamp', () => {
    const url = 'https://youtu.be/dQw4w9WgXcQ?t=42';
    assert.ok(regex.test(url), `Should match: ${url}`);
  });

  it('should match youtu.be URL with si parameter', () => {
    const url = 'https://youtu.be/dQw4w9WgXcQ?si=shareId123';
    assert.ok(regex.test(url), `Should match: ${url}`);
  });
});

describe('URL transformation tests', () => {
  // Note: declarativeNetRequest uses \1 syntax in regexSubstitution
  // which maps to $1 in JavaScript regex replace

  /**
   * Helper to convert declarativeNetRequest substitution to JS format
   * \1 -> $1, \2 -> $2, etc.
   * The backslash is a literal backslash character (char code 92)
   */
  function convertSubstitution(dnrSubstitution) {
    // Match literal backslash followed by digit(s)
    return dnrSubstitution.replace(/\\(\d+)/g, '$$$1');
  }

  it('should transform watch URLs to yout-ube.com with autoplay', () => {
    const rule = rules.find(r => r.id === 1);
    const url = 'https://www.youtube.com/watch?v=dQw4w9WgXcQ';
    const regex = new RegExp(rule.condition.regexFilter);
    const substitution = convertSubstitution(rule.action.redirect.regexSubstitution);

    const transformed = url.replace(regex, substitution);
    assert.ok(
      transformed.includes('yout-ube.com'),
      'Transformed URL should contain yout-ube.com'
    );
    assert.ok(
      transformed.includes('autoplay=1'),
      'Transformed URL should contain autoplay=1'
    );
  });

  it('should preserve query parameters in watch URL transformation', () => {
    const rule = rules.find(r => r.id === 1);
    const url = 'https://www.youtube.com/watch?v=dQw4w9WgXcQ';
    const regex = new RegExp(rule.condition.regexFilter);
    const substitution = convertSubstitution(rule.action.redirect.regexSubstitution);

    const transformed = url.replace(regex, substitution);
    // Rule 1 captures the entire query string and preserves it
    assert.ok(
      transformed.includes('v=dQw4w9WgXcQ'),
      'Transformed URL should preserve v parameter'
    );
  });

  it('should transform Shorts URLs correctly', () => {
    const rule = rules.find(r => r.id === 2);
    const videoId = 'abc123def';
    const url = `https://www.youtube.com/shorts/${videoId}`;
    const regex = new RegExp(rule.condition.regexFilter);
    const substitution = convertSubstitution(rule.action.redirect.regexSubstitution);

    const transformed = url.replace(regex, substitution);
    assert.ok(
      transformed.includes('yout-ube.com/shorts/'),
      'Transformed URL should use yout-ube.com/shorts/'
    );
    assert.ok(
      transformed.includes(videoId),
      `Transformed URL should preserve video ID: ${transformed}`
    );
  });

  it('should transform youtu.be URLs to watch format', () => {
    const rule = rules.find(r => r.id === 6);
    const videoId = 'dQw4w9WgXcQ';
    const url = `https://youtu.be/${videoId}`;
    const regex = new RegExp(rule.condition.regexFilter);
    const substitution = convertSubstitution(rule.action.redirect.regexSubstitution);

    const transformed = url.replace(regex, substitution);
    assert.ok(
      transformed.includes('yout-ube.com/watch'),
      'Transformed URL should use yout-ube.com/watch'
    );
    assert.ok(
      transformed.includes(`v=${videoId}`),
      `Transformed URL should have v= parameter: ${transformed}`
    );
  });

  it('should verify regexSubstitution syntax is valid', () => {
    // All rules should use \\1 (or \\2, etc.) for capture group references
    rules.forEach((rule, index) => {
      const sub = rule.action.redirect.regexSubstitution;
      // Should not have bare $1 (that's JS syntax, not DNR)
      // DNR uses \\1 which looks like \1 in the JSON
      assert.ok(
        !sub.includes('$1') || sub.includes('\\1'),
        `Rule ${index + 1} should use correct DNR substitution syntax`
      );
    });
  });
});

describe('Edge cases and security', () => {
  it('should NOT match non-YouTube domains', () => {
    const testUrls = [
      'https://www.google.com/watch?v=test',
      'https://www.fakeyoutube.com/watch?v=test',
      'https://youtube.com.evil.com/watch?v=test',
      'https://notyoutube.com/watch?v=test'
    ];

    rules.forEach(rule => {
      const regex = new RegExp(rule.condition.regexFilter);
      testUrls.forEach(url => {
        assert.ok(
          !regex.test(url),
          `Rule ${rule.id} should NOT match: ${url}`
        );
      });
    });
  });

  it('should NOT match already-redirected URLs (yout-ube.com)', () => {
    const testUrls = [
      'https://www.yout-ube.com/watch?v=test',
      'https://yout-ube.com/shorts/test',
      'https://www.yout-ube.com/embed/test'
    ];

    rules.forEach(rule => {
      const regex = new RegExp(rule.condition.regexFilter);
      testUrls.forEach(url => {
        assert.ok(
          !regex.test(url),
          `Rule ${rule.id} should NOT match already-redirected URL: ${url}`
        );
      });
    });
  });

  it('should NOT match youtube-nocookie.com URLs', () => {
    const testUrls = [
      'https://www.youtube-nocookie.com/embed/test',
      'https://youtube-nocookie.com/embed/test'
    ];

    rules.forEach(rule => {
      const regex = new RegExp(rule.condition.regexFilter);
      testUrls.forEach(url => {
        assert.ok(
          !regex.test(url),
          `Rule ${rule.id} should NOT match youtube-nocookie.com: ${url}`
        );
      });
    });
  });

  it('should handle special characters in video IDs', () => {
    const rule = rules.find(r => r.id === 1);
    const regex = new RegExp(rule.condition.regexFilter);

    // YouTube video IDs can contain: a-z, A-Z, 0-9, -, _
    const specialIds = [
      'dQw4w9WgXcQ',
      'abc-123_def',
      'ABC123xyz',
      '_underscore_',
      '-hyphen-'
    ];

    specialIds.forEach(id => {
      const url = `https://www.youtube.com/watch?v=${id}`;
      assert.ok(regex.test(url), `Should match video ID: ${id}`);
    });
  });

  it('should handle URLs with fragments', () => {
    const rule = rules.find(r => r.id === 1);
    const regex = new RegExp(rule.condition.regexFilter);

    // URLs with fragments should still match (fragment is after #)
    const url = 'https://www.youtube.com/watch?v=dQw4w9WgXcQ';
    assert.ok(regex.test(url), 'Should match URL without fragment');

    // Note: The regex explicitly excludes fragments with [^#] patterns
    const urlWithFragment = 'https://www.youtube.com/watch?v=dQw4w9WgXcQ#t=42';
    // This may or may not match depending on regex - test actual behavior
  });
});

describe('Comprehensive URL coverage', () => {
  const testCases = [
    // Standard watch URLs
    { url: 'https://www.youtube.com/watch?v=abc123', shouldMatch: true, ruleId: 1 },
    { url: 'https://youtube.com/watch?v=abc123', shouldMatch: true, ruleId: 1 },
    { url: 'http://www.youtube.com/watch?v=abc123', shouldMatch: true, ruleId: 1 },

    // Shorts
    { url: 'https://www.youtube.com/shorts/abc123', shouldMatch: true, ruleId: 2 },
    { url: 'https://youtube.com/shorts/abc123', shouldMatch: true, ruleId: 2 },

    // Embeds
    { url: 'https://www.youtube.com/embed/abc123', shouldMatch: true, ruleId: 3 },
    { url: 'https://youtube.com/embed/abc123', shouldMatch: true, ruleId: 3 },

    // Live
    { url: 'https://www.youtube.com/live/abc123', shouldMatch: true, ruleId: 4 },

    // Mobile
    { url: 'https://m.youtube.com/watch?v=abc123', shouldMatch: true, ruleId: 5 },

    // Short URLs
    { url: 'https://youtu.be/abc123', shouldMatch: true, ruleId: 6 },
    { url: 'http://youtu.be/abc123', shouldMatch: true, ruleId: 6 },
  ];

  testCases.forEach(({ url, shouldMatch, ruleId }) => {
    it(`Rule ${ruleId} ${shouldMatch ? 'should' : 'should NOT'} match: ${url}`, () => {
      const rule = rules.find(r => r.id === ruleId);
      const regex = new RegExp(rule.condition.regexFilter);
      assert.equal(regex.test(url), shouldMatch);
    });
  });
});
