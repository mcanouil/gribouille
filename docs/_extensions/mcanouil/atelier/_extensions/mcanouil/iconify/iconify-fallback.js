// Iconify fallback runtime.
// For each `.iconify-icon-wrapper`, watch the contained `<iconify-icon>` and
// reveal the sibling `.iconify-icon-fallback` element when the icon fails to
// load. Failure covers unknown icon names, offline use, and CDN unreachable.

(function () {
  'use strict';

  // Maximum number of poll cycles before declaring the icon failed.
  // Iconify's default request timeout is 5s; we poll for ~6s.
  var MAX_POLLS = 60;
  var POLL_INTERVAL_MS = 100;

  function watchWrapper(wrapper) {
    var icon = wrapper.querySelector('iconify-icon');
    var fallback = wrapper.querySelector('.iconify-icon-fallback');
    if (!icon || !fallback) return;

    var polls = 0;

    function reveal() {
      fallback.hidden = false;
      icon.setAttribute('hidden', '');
      wrapper.setAttribute('data-iconify-state', 'failed');
    }

    function settle() {
      wrapper.setAttribute('data-iconify-state', 'rendered');
    }

    function tick() {
      var status = icon.status;
      if (status === 'rendered') {
        settle();
        return;
      }
      if (status === 'failed') {
        reveal();
        return;
      }
      polls += 1;
      if (polls >= MAX_POLLS) {
        reveal();
        return;
      }
      setTimeout(tick, POLL_INTERVAL_MS);
    }

    // `iconify-icon` may not be defined yet if the script load order differs;
    // wait for the custom element to be upgraded before polling its `status`.
    if (window.customElements && typeof window.customElements.whenDefined === 'function') {
      window.customElements.whenDefined('iconify-icon').then(tick, reveal);
    } else {
      tick();
    }
  }

  function init() {
    var wrappers = document.querySelectorAll('.iconify-icon-wrapper[data-iconify-fallback]');
    for (var i = 0; i < wrappers.length; i += 1) {
      watchWrapper(wrappers[i]);
    }
  }

  if (document.readyState === 'loading') {
    document.addEventListener('DOMContentLoaded', init);
  } else {
    init();
  }
})();
