/**
 * Remember Extension - Navigation Position Persistence
 *
 * Saves and restores the user's scroll position and current anchor or slide
 * indices for HTML, Quarto book, and Reveal.js outputs.
 *
 * The Quarto project type (book, website, default) is delivered by the
 * companion Lua filter through a `<script id="quarto-remember-config"
 * type="application/json">` block injected into the page head. The client
 * never has to guess from theme-specific DOM selectors.
 *
 * @author Mickaël Canouil
 * @version 1.1.0
 */

(function () {
  'use strict';

  const STORAGE_KEY = 'quarto-remember-position';
  const STORAGE_TIMESTAMP_KEY = 'quarto-remember-timestamp';
  const CHAPTER_KEY = 'quarto-remember-chapter';
  const PROMPT_SHOWN_KEY = 'quarto-remember-prompt-shown';
  const SESSION_ACTIVE_KEY = 'quarto-remember-session-active';
  const RESUME_NOTE_KEY = 'quarto-remember-resume';
  const RESUME_NOTE_MAX_AGE = 30000;
  const RESUME_LOAD_WAIT = 3000;
  const RESUME_CANCEL_WAIT = 5000;
  const CONFIG_ELEMENT_ID = 'quarto-remember-config';
  const PROMPT_COOLDOWN = 5000;

  /**
   * Configuration injected by the Lua filter via `<script
   * id="quarto-remember-config" type="application/json">`.
   *
   * Shape:
   *   {
   *     "project-type": "book" | "website" | "default",
   *     "separate-chapter-state": boolean
   *   }
   *
   * If the element is missing or malformed, the defaults below preserve the
   * previous "single document" behaviour.
   *
   * @returns {{projectType: string, separateChapterState: boolean}}
   */
  function readConfig() {
    const fallback = {
      projectType: 'default',
      separateChapterState: false
    };
    const element = document.getElementById(CONFIG_ELEMENT_ID);
    if (!element) {
      return fallback;
    }
    try {
      const raw = JSON.parse(element.textContent || '{}');
      return {
        projectType: typeof raw['project-type'] === 'string' ? raw['project-type'] : fallback.projectType,
        separateChapterState: raw['separate-chapter-state'] === true
      };
    } catch (e) {
      console.warn('Remember: invalid configuration JSON, falling back to defaults.', e);
      return fallback;
    }
  }

  // Read in `init()`: the configuration tag comes after this script in the
  // page head, so it does not exist yet when the script runs.
  let CONFIG;

  /**
   * Feature-detect `localStorage` and `sessionStorage` before any other work.
   * Some private browsing modes throw on `setItem`, so a probe write is
   * required to be sure.
   *
   * @param {Storage} storage
   * @returns {boolean}
   */
  function isStorageUsable(storage) {
    if (!storage) {
      return false;
    }
    const probeKey = '__quarto_remember_probe__';
    try {
      storage.setItem(probeKey, '1');
      storage.removeItem(probeKey);
      return true;
    } catch (e) {
      return false;
    }
  }

  const LOCAL_STORAGE_OK = isStorageUsable(typeof window !== 'undefined' ? window.localStorage : null);
  const SESSION_STORAGE_OK = isStorageUsable(typeof window !== 'undefined' ? window.sessionStorage : null);

  /**
   * Determine whether the current page belongs to a Quarto book.
   * Now driven by the Lua-injected config, not DOM selectors.
   *
   * @returns {boolean}
   */
  function isQuartoBook() {
    return CONFIG.projectType === 'book';
  }

  /**
   * Compute the page identifier.
   *
   * For book projects, all chapters share a single identifier (the book
   * root) so the extension can redirect across chapters. For every other
   * project type, the full pathname is used.
   *
   * @returns {string}
   */
  function computePageIdentifier() {
    if (isQuartoBook()) {
      const parts = window.location.pathname.split('/');
      parts.pop();
      return parts.join('/') || '/';
    }
    return window.location.pathname;
  }

  let pageIdentifier;

  /**
   * Invalidate the cached page identifier whenever the URL changes within
   * an SPA-style navigation. The browser does not reload the script on
   * `popstate`/`hashchange`, so the identifier must be recomputed.
   */
  function watchPageIdentifier() {
    const refresh = () => {
      pageIdentifier = computePageIdentifier();
    };
    window.addEventListener('popstate', refresh);
    window.addEventListener('hashchange', refresh);

    // Hook into pushState/replaceState so client-side routers also trigger
    // the refresh, mirroring the browser's own popstate behaviour.
    ['pushState', 'replaceState'].forEach((method) => {
      const original = history[method];
      if (typeof original !== 'function') {
        return;
      }
      history[method] = function patched(...args) {
        const result = original.apply(this, args);
        refresh();
        return result;
      };
    });
  }

  /**
   * Read the saved navigation payload, scoped to the current page.
   *
   * @returns {object|null}
   */
  function getStoredPosition() {
    if (!LOCAL_STORAGE_OK) {
      return null;
    }
    try {
      const data = localStorage.getItem(STORAGE_KEY);
      const timestamp = localStorage.getItem(STORAGE_TIMESTAMP_KEY);
      if (!data || !timestamp) {
        return null;
      }
      const position = JSON.parse(data);
      if (position.page !== pageIdentifier) {
        return null;
      }
      return Object.assign({}, position, { timestamp: parseInt(timestamp, 10) });
    } catch (e) {
      console.error('Remember: Failed to retrieve stored position', e);
      return null;
    }
  }

  /**
   * Read the saved chapter payload when `separate-chapter-state` is on.
   *
   * @returns {object|null}
   */
  function getStoredChapter() {
    if (!LOCAL_STORAGE_OK || !CONFIG.separateChapterState) {
      return null;
    }
    try {
      const data = localStorage.getItem(CHAPTER_KEY);
      if (!data) {
        return null;
      }
      const parsed = JSON.parse(data);
      if (parsed.page !== pageIdentifier) {
        return null;
      }
      return parsed;
    } catch (e) {
      console.error('Remember: Failed to retrieve stored chapter', e);
      return null;
    }
  }

  // Set when Resume sends the reader to another page, so the handlers of the
  // page being left do not overwrite the position on the way out. A page
  // restored from the back-forward cache saves again.
  let leaving = false;
  window.addEventListener('pageshow', (e) => {
    if (e.persisted) {
      leaving = false;
    }
  });

  /**
   * Persist a navigation payload for the current page.
   *
   * @param {object} position
   */
  function savePosition(position) {
    if (!LOCAL_STORAGE_OK || leaving) {
      return;
    }
    try {
      const data = {
        page: pageIdentifier,
        url: window.location.pathname,
        scrollY: position.scrollY || 0,
        hash: position.hash || '',
        slideIndices: position.slideIndices || null
      };
      localStorage.setItem(STORAGE_KEY, JSON.stringify(data));
      localStorage.setItem(STORAGE_TIMESTAMP_KEY, Date.now().toString());

      // Optional chapter-state branch: track which chapter is current
      // independently from the scroll position inside that chapter.
      if (CONFIG.separateChapterState && isQuartoBook()) {
        const chapter = {
          page: pageIdentifier,
          url: window.location.pathname,
          hash: window.location.hash || ''
        };
        localStorage.setItem(CHAPTER_KEY, JSON.stringify(chapter));
      }
    } catch (e) {
      console.error('Remember: Failed to save position', e);
    }
  }

  /**
   * Wipe the stored position and chapter payloads.
   */
  function clearStoredPosition() {
    if (!LOCAL_STORAGE_OK) {
      return;
    }
    try {
      localStorage.removeItem(STORAGE_KEY);
      localStorage.removeItem(STORAGE_TIMESTAMP_KEY);
      if (CONFIG.separateChapterState) {
        localStorage.removeItem(CHAPTER_KEY);
      }
    } catch (e) {
      console.error('Remember: Failed to clear stored position', e);
    }
  }

  /**
   * Check whether the resume prompt was shown within the cooldown window.
   *
   * @returns {boolean}
   */
  function wasPromptRecentlyShown() {
    if (!SESSION_STORAGE_OK) {
      return false;
    }
    try {
      const lastShown = sessionStorage.getItem(PROMPT_SHOWN_KEY);
      if (!lastShown) {
        return false;
      }
      return Date.now() - parseInt(lastShown, 10) < PROMPT_COOLDOWN;
    } catch (e) {
      return false;
    }
  }

  /**
   * Record that the resume prompt was shown.
   */
  function markPromptShown() {
    if (!SESSION_STORAGE_OK) {
      return;
    }
    try {
      sessionStorage.setItem(PROMPT_SHOWN_KEY, Date.now().toString());
    } catch (e) {
      // sessionStorage refused to write; nothing else to do.
    }
  }

  /**
   * Place the banner where a reader meets it after the page title: after the
   * title block when it is inside `main`, else at the start of `main`, else
   * at the start of `body`. On a Reveal.js deck the banner is fixed by the
   * stylesheet, above the slide footer when the deck has one.
   *
   * @param {HTMLElement} banner
   * @returns {string} Where the banner is, for the announcement
   */
  function placeBanner(banner) {
    if (document.querySelector('.reveal')) {
      banner.classList.add('remember-banner-fixed');
      const footer = document.querySelector('.reveal .footer');
      if (footer && footer.offsetHeight > 0) {
        const clearance = window.innerHeight - footer.getBoundingClientRect().top + 8;
        banner.style.setProperty('--remember-offset', `${Math.ceil(clearance)}px`);
      }
      document.body.appendChild(banner);
      return 'at the bottom of the screen';
    }
    const main = document.querySelector('main');
    const titleBlock = document.getElementById('title-block-header');
    if (main && titleBlock && main.contains(titleBlock)) {
      titleBlock.parentNode.insertBefore(banner, titleBlock.nextSibling);
      return 'below the page title';
    }
    const container = main || document.body;
    container.insertBefore(banner, container.firstChild);
    return 'at the start of the page content';
  }

  /**
   * Return the scroll position as it would be without the banner. While the
   * top of the view is inside an in-flow banner, the position is the top of
   * the banner, because the banner is gone on the next visit. Past the
   * banner, the space it takes is removed.
   *
   * @returns {number}
   */
  function scrollWithoutBanner() {
    const banner = document.querySelector('.remember-banner:not(.remember-banner-fixed)');
    if (!banner) {
      return window.scrollY;
    }
    const rect = banner.getBoundingClientRect();
    if (rect.top >= 0) {
      return window.scrollY;
    }
    if (rect.bottom > 0 || !banner.nextElementSibling) {
      return Math.max(0, Math.round(window.scrollY + rect.top));
    }
    // A focused banner stays in the page after the reader scrolls past it,
    // so the space it takes is removed from the saved position.
    const taken = banner.nextElementSibling.getBoundingClientRect().top - rect.top;
    return Math.max(0, Math.round(window.scrollY - taken));
  }

  /**
   * Report whether an element is rendered, in the viewport, and not hidden
   * from assistive technology.
   *
   * @param {Element} element
   * @returns {boolean}
   */
  function isVisible(element) {
    if (element.closest('[hidden], [aria-hidden="true"]')) {
      return false;
    }
    const rect = element.getBoundingClientRect();
    return rect.height > 0 && rect.bottom > 0 && rect.top < window.innerHeight;
  }

  /**
   * Return the element that takes focus when the banner closes: the current
   * slide on a Reveal.js deck, else the first visible heading of the page
   * content, else `main`.
   *
   * @returns {HTMLElement|null}
   */
  function focusTarget() {
    if (typeof Reveal !== 'undefined' && document.querySelector('.reveal')) {
      const slide = Reveal.getCurrentSlide();
      const heading = slide && slide.querySelector('h1, h2, h3, h4, h5, h6');
      return heading && isVisible(heading) ? heading : slide;
    }
    const root = document.querySelector('main') || document.body;
    for (const heading of root.querySelectorAll('h1, h2, h3, h4, h5, h6')) {
      if (isVisible(heading)) {
        return heading;
      }
    }
    return root;
  }

  /**
   * Move focus to an element that does not take focus by itself, without
   * scrolling, so focus is not lost to `body` when the banner goes away.
   * Focus the reader has already placed elsewhere is left alone.
   *
   * @param {HTMLElement|null} element
   */
  function focusWithoutScroll(element) {
    const active = document.activeElement;
    if (!element || (active && active !== document.body && active !== document.documentElement)) {
      return;
    }
    if (!element.hasAttribute('tabindex')) {
      element.setAttribute('tabindex', '-1');
      element.addEventListener('blur', () => element.removeAttribute('tabindex'), { once: true });
    }
    element.focus({ preventScroll: true });
  }

  /**
   * Run a callback once the page stops scrolling, or after a short wait when
   * it does not scroll at all.
   *
   * @param {Function} callback
   */
  function afterScrollSettles(callback) {
    let done = false;
    const finish = () => {
      if (done) {
        return;
      }
      done = true;
      window.removeEventListener('scrollend', finish);
      callback();
    };
    window.addEventListener('scrollend', finish, { once: true });
    setTimeout(finish, 1500);
  }

  /**
   * Show a banner that offers to resume, without interrupting the reader.
   * The banner does not move or trap focus and does not cover the page. A
   * polite live region announces it once.
   *
   * @param {string} message
   * @param {Function} onAccept
   * @param {Function} onDecline
   */
  function showBanner(message, onAccept, onDecline) {
    if (wasPromptRecentlyShown()) {
      return;
    }
    markPromptShown();

    const banner = document.createElement('section');
    banner.className = 'remember-banner';
    banner.setAttribute('aria-label', 'Resume reading');

    const text = document.createElement('p');
    text.className = 'remember-message';
    text.textContent = message;

    const buttons = document.createElement('div');
    buttons.className = 'remember-buttons';

    const acceptBtn = document.createElement('button');
    acceptBtn.type = 'button';
    acceptBtn.textContent = 'Resume';
    acceptBtn.className = 'remember-btn remember-btn-accept btn btn-primary';

    const declineBtn = document.createElement('button');
    declineBtn.type = 'button';
    declineBtn.textContent = 'Dismiss';
    declineBtn.className = 'remember-btn remember-btn-decline btn btn-outline-secondary';

    const status = document.createElement('div');
    status.className = 'remember-status';
    status.setAttribute('role', 'status');
    document.body.appendChild(status);

    const timers = [];
    // Removing an in-flow banner above the view would pull the content up,
    // so the view is moved by the same amount, at once.
    const close = () => {
      const hadFocus = banner.contains(document.activeElement);
      timers.forEach(clearTimeout);
      const anchor = banner.classList.contains('remember-banner-fixed') ? null : banner.nextElementSibling;
      const before = anchor ? anchor.getBoundingClientRect().top : 0;
      const above = banner.getBoundingClientRect().top < 0;
      banner.remove();
      status.remove();
      document.removeEventListener('focusin', onFocusIn);
      if (typeof Reveal !== 'undefined' && typeof Reveal.off === 'function') {
        Reveal.off('slidechanged', onSlideChanged);
      }
      if (anchor && above) {
        // Scroll anchoring and margin collapse settle by the next frame, so
        // the remaining gap is measured and closed then.
        requestAnimationFrame(() => {
          window.scrollBy({ top: anchor.getBoundingClientRect().top - before, left: 0, behavior: 'instant' });
        });
      }
      return hadFocus;
    };

    acceptBtn.onclick = () => {
      const hadFocus = close();
      onAccept();
      if (hadFocus) {
        // A deck changes slide at once; a page may still be scrolling.
        const settle = document.querySelector('.reveal') ? requestAnimationFrame : afterScrollSettles;
        settle(() => focusWithoutScroll(focusTarget()));
      }
    };

    const decline = () => {
      const hadFocus = close();
      onDecline();
      if (hadFocus) {
        // Wait for the view correction in `close` before choosing a heading.
        requestAnimationFrame(() => requestAnimationFrame(() => focusWithoutScroll(focusTarget())));
      }
    };
    declineBtn.onclick = decline;

    // Keys pressed inside the banner belong to the banner: Reveal.js would
    // otherwise turn Space into the next slide and Escape into its overview.
    banner.addEventListener('keydown', (e) => {
      e.stopPropagation();
      if (e.key === 'Escape') {
        decline();
      }
    });

    buttons.appendChild(acceptBtn);
    buttons.appendChild(declineBtn);
    banner.appendChild(text);
    banner.appendChild(buttons);
    const where = placeBanner(banner);

    // A fixed banner must not hide the element that has keyboard focus. When
    // focus lands behind it, the banner moves to the other edge of the screen.
    // Containers such as the page or a slide are not what the reader is
    // looking at, so only a control smaller than half the screen counts.
    const onFocusIn = (e) => {
      if (!banner.isConnected) {
        document.removeEventListener('focusin', onFocusIn);
        return;
      }
      const target = e.target;
      if (!(target instanceof Element) || banner.contains(target) ||
          target === document.body || target === document.documentElement) {
        return;
      }
      const rect = target.getBoundingClientRect();
      if (rect.height === 0 || rect.height > window.innerHeight / 2) {
        return;
      }
      const inBottomHalf = rect.top + rect.height / 2 > window.innerHeight / 2;
      banner.classList.toggle('remember-banner-top', inBottomHalf);
    };

    // Moving to another slide is the deck's way of reading on, as scrolling
    // past the banner is on a page. Reveal.js also changes slide by itself
    // while it starts, for example in its scroll view on a narrow screen, so
    // only a change after the reader has acted counts.
    let readerActed = false;
    const markActed = () => {
      readerActed = true;
    };
    ['keydown', 'pointerdown', 'wheel', 'touchstart'].forEach((type) => {
      document.addEventListener(type, markActed, { capture: true, once: true, passive: true });
    });
    const onSlideChanged = () => {
      if (!readerActed) {
        return;
      }
      const hadFocus = close();
      if (hadFocus) {
        focusWithoutScroll(focusTarget());
      }
    };

    if (banner.classList.contains('remember-banner-fixed')) {
      document.addEventListener('focusin', onFocusIn);
      if (typeof Reveal !== 'undefined' && typeof Reveal.on === 'function') {
        Reveal.on('slidechanged', onSlideChanged);
      }
    }

    // A reader who scrolls past the banner has chosen to read on. The banner
    // then leaves the page, with the view held still, so later saved
    // positions do not include its height.
    if (!banner.classList.contains('remember-banner-fixed') && 'IntersectionObserver' in window) {
      // Only a banner the reader has seen counts as scrolled past, so a page
      // that opens below it, such as a link to a section, keeps the offer. A
      // banner that holds focus stays until focus leaves it.
      let seen = false;
      let scrolledPast = false;
      const leave = () => {
        observer.disconnect();
        close();
      };
      const observer = new IntersectionObserver((entries) => {
        const entry = entries[0];
        if (entry.isIntersecting) {
          seen = true;
          scrolledPast = false;
          return;
        }
        if (!seen || entry.boundingClientRect.top >= 0 || !banner.isConnected) {
          return;
        }
        scrolledPast = true;
        if (!banner.contains(document.activeElement)) {
          leave();
        }
      });
      banner.addEventListener('focusout', (e) => {
        if (scrolledPast && banner.isConnected && !banner.contains(e.relatedTarget)) {
          leave();
        }
      });
      observer.observe(banner);
    }

    // Screen readers miss a live region that changes as soon as it enters
    // the page, and the page load reading can drown a polite message, so the
    // short announcement waits a second. It is cleared after ten seconds, so
    // a reader who browses the page does not meet it twice.
    timers.push(setTimeout(() => {
      status.textContent = `Resume reading is available ${where}.`;
    }, 1000));
    timers.push(setTimeout(() => {
      status.textContent = '';
    }, 11000));
  }

  /**
   * Format a saved timestamp as a relative phrase.
   *
   * @param {number} timestamp Unix timestamp in milliseconds
   * @returns {string}
   */
  function formatTimestamp(timestamp) {
    const diff = Date.now() - timestamp;
    const minutes = Math.floor(diff / 60000);
    const hours = Math.floor(diff / 3600000);
    const days = Math.floor(diff / 86400000);
    if (minutes < 1) return 'just now';
    if (minutes < 60) return `${minutes} minute${minutes > 1 ? 's' : ''} ago`;
    if (hours < 24) return `${hours} hour${hours > 1 ? 's' : ''} ago`;
    return `${days} day${days > 1 ? 's' : ''} ago`;
  }

  /**
   * Restore the saved scroll position or hash for the current document.
   *
   * @param {object} position
   */
  function restoreScrollPosition(position) {
    if (!position) {
      return;
    }
    if (position.hash) {
      window.location.hash = position.hash;
      return;
    }
    if (position.scrollY && typeof position.scrollY === 'number') {
      const prefersReducedMotion = window.matchMedia('(prefers-reduced-motion: reduce)').matches;
      window.scrollTo({
        top: position.scrollY,
        left: 0,
        behavior: prefersReducedMotion ? 'auto' : 'smooth'
      });
    }
  }

  /**
   * Wire up scroll, hash, click, and unload listeners that persist the
   * user's current position.
   */
  function setupScrollTracking() {
    let saveTimeout;

    const saveCurrentPosition = () => {
      savePosition({
        scrollY: scrollWithoutBanner(),
        hash: window.location.hash
      });
    };

    if (isQuartoBook()) {
      saveCurrentPosition();
    }

    window.addEventListener('scroll', () => {
      clearTimeout(saveTimeout);
      saveTimeout = setTimeout(saveCurrentPosition, 500);
    }, { passive: true });

    window.addEventListener('hashchange', saveCurrentPosition);

    document.addEventListener('click', (e) => {
      const link = e.target.closest('a');
      if (link && link.href) {
        saveCurrentPosition();
      }
    }, { passive: true });

    window.addEventListener('beforeunload', saveCurrentPosition);
  }

  /**
   * Initialise the Reveal.js code path.
   */
  function initRevealJS() {
    if (typeof Reveal === 'undefined') {
      console.warn('Remember: Reveal.js not found');
      return;
    }

    const start = () => {
      const stored = getStoredPosition();

      if (stored && stored.slideIndices) {
        const message = `You left this presentation ${formatTimestamp(stored.timestamp)}. You can resume where you left off.`;
        showBanner(message,
          () => Reveal.slide(stored.slideIndices.h, stored.slideIndices.v, stored.slideIndices.f),
          () => clearStoredPosition()
        );
      }

      Reveal.on('slidechanged', () => {
        savePosition({ slideIndices: Reveal.getIndices() });
      });

      window.addEventListener('beforeunload', () => {
        savePosition({ slideIndices: Reveal.getIndices() });
      });
    };

    // Quarto initialises Reveal.js before `DOMContentLoaded`, so the deck is
    // often ready before this runs, and its `ready` event has already fired.
    if (typeof Reveal.isReady === 'function' && Reveal.isReady()) {
      start();
    } else {
      Reveal.on('ready', start);
    }
  }

  /**
   * Check whether the current session is already active (the user has been
   * navigating within this site).
   *
   * @returns {boolean}
   */
  function isSessionActive() {
    if (!SESSION_STORAGE_OK) {
      return false;
    }
    try {
      return sessionStorage.getItem(SESSION_ACTIVE_KEY) === 'true';
    } catch (e) {
      return false;
    }
  }

  /**
   * Mark the current session as active.
   */
  function markSessionActive() {
    if (!SESSION_STORAGE_OK) {
      return;
    }
    try {
      sessionStorage.setItem(SESSION_ACTIVE_KEY, 'true');
    } catch (e) {
      // sessionStorage refused to write; nothing else to do.
    }
  }

  /**
   * Record the position that Resume sends the reader to, for the next page.
   *
   * @param {{url: string, scrollY: number, hash: string}} position
   */
  function writeResumeNote(position) {
    if (!SESSION_STORAGE_OK) {
      return;
    }
    try {
      const note = {
        url: position.url,
        scrollY: position.scrollY || 0,
        hash: position.hash || '',
        at: Date.now()
      };
      sessionStorage.setItem(RESUME_NOTE_KEY, JSON.stringify(note));
    } catch (e) {
      // sessionStorage refused to write: the target page shows the banner
      // again, and the reader resumes from there.
    }
  }

  /**
   * Read and remove the resume note. Return it only for the current page and
   * only while it is fresh, so a redirect that never arrived cannot scroll a
   * later visit.
   *
   * @returns {object|null}
   */
  function takeResumeNote() {
    if (!SESSION_STORAGE_OK) {
      return null;
    }
    try {
      const raw = sessionStorage.getItem(RESUME_NOTE_KEY);
      sessionStorage.removeItem(RESUME_NOTE_KEY);
      if (!raw) {
        return null;
      }
      const note = JSON.parse(raw);
      const fresh = Date.now() - note.at < RESUME_NOTE_MAX_AGE;
      return fresh && note.url === window.location.pathname ? note : null;
    } catch (e) {
      console.error('Remember: Failed to read the resume note', e);
      return null;
    }
  }

  /**
   * Send the reader to the page of a position, which restores it on arrival.
   *
   * @param {{url: string, scrollY: number, hash: string}} position
   */
  function resumeOnPage(position) {
    writeResumeNote(position);
    leaving = true;
    markSessionActive();
    window.location.href = position.url + (position.hash || '');
    // A page still here after the wait had its navigation cancelled, for
    // example with Escape or Stop, or is waiting for a slow server. It saves
    // again either way. The note stays for a slow server, and expires by age.
    setTimeout(() => {
      leaving = false;
    }, RESUME_CANCEL_WAIT);
  }

  /**
   * Initialise the HTML/Quarto-book code path.
   */
  function initHTML() {
    const note = takeResumeNote();
    if (note) {
      // Images, maths and fonts above the stored position change the layout
      // until the page has loaded, so the position is restored after that, or
      // after a short wait when a slow resource holds the load back.
      let restored = false;
      const restore = () => {
        if (restored) {
          return;
        }
        restored = true;
        window.removeEventListener('load', restore);
        restoreScrollPosition(note);
        setupScrollTracking();
      };
      if (document.readyState === 'complete') {
        restore();
      } else {
        window.addEventListener('load', restore);
        setTimeout(restore, RESUME_LOAD_WAIT);
      }
      return;
    }

    const stored = getStoredPosition();
    const chapter = getStoredChapter();
    const sessionActive = isSessionActive();
    const inBook = isQuartoBook();

    // Chapter-only branch: if `separate-chapter-state` is enabled and we are
    // currently on a different chapter than the one we last visited, prefer
    // redirecting to that chapter before considering scroll restoration.
    if (inBook && CONFIG.separateChapterState && chapter && !sessionActive) {
      const currentPath = window.location.pathname;
      if (chapter.url && chapter.url !== currentPath) {
        const message = `You were reading a different chapter ${formatTimestamp(stored ? stored.timestamp : Date.now())}. You can return to where you were.`;
        showBanner(message,
          () => {
            const sameChapter = stored && stored.url === chapter.url;
            resumeOnPage(sameChapter ? stored : { url: chapter.url, scrollY: 0, hash: chapter.hash });
          },
          () => {
            markSessionActive();
            clearStoredPosition();
          }
        );
        setupScrollTracking();
        return;
      }
    }

    const handleNavigation = () => {
      markSessionActive();
      if (stored) {
        clearStoredPosition();
      }
    };

    window.addEventListener('beforeunload', handleNavigation);

    if (stored && !sessionActive) {
      const currentPath = window.location.pathname;
      const storedPath = stored.url || currentPath;
      const isDifferentPage = currentPath !== storedPath;

      const shouldShowPrompt = isDifferentPage || stored.scrollY > 100 || Boolean(stored.hash);

      if (shouldShowPrompt) {
        const message = isDifferentPage
          ? `You were reading a different chapter ${formatTimestamp(stored.timestamp)}. You can return to where you were.`
          : `You visited this page ${formatTimestamp(stored.timestamp)}. You can return to where you were.`;

        showBanner(message,
          () => {
            window.removeEventListener('beforeunload', handleNavigation);
            if (isDifferentPage) {
              resumeOnPage({ url: storedPath, scrollY: stored.scrollY, hash: stored.hash });
            } else {
              markSessionActive();
              restoreScrollPosition(stored);
            }
          },
          () => {
            window.removeEventListener('beforeunload', handleNavigation);
            markSessionActive();
            clearStoredPosition();
          }
        );
      }
    }

    setupScrollTracking();
  }

  /**
   * Top-level initialiser.
   */
  function init() {
    if (!LOCAL_STORAGE_OK) {
      console.warn('Remember: localStorage is unavailable; navigation persistence is disabled for this session.');
      return;
    }
    CONFIG = readConfig();
    pageIdentifier = computePageIdentifier();
    watchPageIdentifier();
    if (document.querySelector('.reveal')) {
      initRevealJS();
    } else {
      initHTML();
    }
  }

  if (document.readyState === 'loading') {
    document.addEventListener('DOMContentLoaded', init);
  } else {
    init();
  }
})();

/**
 * Reveal.js plugin entry point.
 * The IIFE above already handles initialisation; this stub satisfies the
 * Reveal plugin contract so users can register `Remember` alongside other
 * plugins without errors.
 */
window.RevealRemember = function () {
  return {
    id: 'remember',
    init: function () {
      console.log('Remember plugin loaded for Reveal.js');
    }
  };
};
