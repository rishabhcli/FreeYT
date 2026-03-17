// FreeYT Privacy Banner
// Shown on youtube-nocookie.com after redirect to confirm privacy protection.
// Only runs in top frame. Dismissible with localStorage persistence.

(function () {
    'use strict';

    // Only run in top frame
    if (window !== window.top) return;

    // Check if user permanently dismissed
    const DISMISS_KEY = 'freeyt_banner_dismissed';
    try {
        if (localStorage.getItem(DISMISS_KEY) === 'true') return;
    } catch {
        // localStorage unavailable (e.g. private browsing), show banner anyway
    }

    // Create banner element
    const banner = document.createElement('div');
    banner.id = 'freeyt-privacy-banner';
    banner.setAttribute('role', 'status');
    banner.setAttribute('aria-live', 'polite');

    banner.innerHTML = `
        <span class="freeyt-banner-text">
            <svg width="16" height="16" viewBox="0 0 16 16" fill="none" style="vertical-align: middle; margin-right: 6px;">
                <path d="M8 1L1 14h14L8 1z" fill="none" stroke="#22c55e" stroke-width="1.5"/>
                <path d="M8 6v4M8 11.5v.5" stroke="#22c55e" stroke-width="1.5" stroke-linecap="round"/>
            </svg>
            Protected by FreeYT — this page is using YouTube's privacy-enhanced embed
        </span>
        <button class="freeyt-banner-close" aria-label="Hide" title="Hide">&times;</button>
        <button class="freeyt-banner-stop" aria-label="Always hide" title="Always hide">Always hide</button>
    `;

    // Inject styles
    const style = document.createElement('style');
    style.textContent = `
        #freeyt-privacy-banner {
            position: fixed;
            top: 0;
            left: 0;
            right: 0;
            z-index: 2147483647;
            display: flex;
            align-items: center;
            justify-content: center;
            gap: 12px;
            padding: 8px 16px;
            background: rgba(0, 0, 0, 0.85);
            backdrop-filter: blur(8px);
            -webkit-backdrop-filter: blur(8px);
            color: #e5e5e5;
            font-family: -apple-system, BlinkMacSystemFont, "SF Pro Text", sans-serif;
            font-size: 13px;
            line-height: 1.4;
            animation: freeyt-slide-down 0.3s ease-out;
        }
        #freeyt-privacy-banner.freeyt-fade-out {
            animation: freeyt-fade-out 0.3s ease-in forwards;
        }
        .freeyt-banner-text {
            display: flex;
            align-items: center;
        }
        .freeyt-banner-close,
        .freeyt-banner-stop {
            background: none;
            border: 1px solid rgba(255,255,255,0.2);
            color: #e5e5e5;
            cursor: pointer;
            border-radius: 4px;
            font-size: 12px;
            padding: 2px 8px;
            font-family: inherit;
            transition: background 0.15s;
        }
        .freeyt-banner-close:hover,
        .freeyt-banner-stop:hover {
            background: rgba(255,255,255,0.15);
        }
        .freeyt-banner-close {
            font-size: 18px;
            line-height: 1;
            padding: 0 6px;
            border: none;
        }
        @keyframes freeyt-slide-down {
            from { transform: translateY(-100%); opacity: 0; }
            to { transform: translateY(0); opacity: 1; }
        }
        @keyframes freeyt-fade-out {
            from { opacity: 1; }
            to { opacity: 0; }
        }
    `;

    function dismiss() {
        banner.classList.add('freeyt-fade-out');
        banner.addEventListener('animationend', function () {
            banner.remove();
            style.remove();
        }, { once: true });
    }

    function dismissPermanently() {
        try {
            localStorage.setItem(DISMISS_KEY, 'true');
        } catch {
            // Ignore storage errors
        }
        dismiss();
    }

    // Wire up buttons
    banner.querySelector('.freeyt-banner-close').addEventListener('click', dismiss);
    banner.querySelector('.freeyt-banner-stop').addEventListener('click', dismissPermanently);

    // Auto-dismiss after 5 seconds
    const autoDismissTimer = setTimeout(dismiss, 5000);

    // Cancel auto-dismiss if user interacts
    banner.addEventListener('mouseenter', function () {
        clearTimeout(autoDismissTimer);
    });

    // Inject into page
    document.documentElement.appendChild(style);
    document.documentElement.appendChild(banner);
})();
