// Veil - html module.
// The HTML adapter: sets the `hidden` attribute on each veiled element from
// the resolved state, hides the table of contents entries of hidden
// sections, and turns off fragments in hidden content.
// It needs `veil-state.js`.

(function () {
  'use strict';

  var TOC_LINKS = '#TOC a[href], nav[role="doc-toc"] a[href]';

  function groupsOf(el) {
    return (el.getAttribute('data-veil-group') || '').split(/\s+/).filter(Boolean);
  }

  function setHidden(el, hidden) {
    if (hidden) {
      el.setAttribute('hidden', '');
    } else {
      el.removeAttribute('hidden');
    }
  }

  // The elements, their groups and the table of contents items, found once.
  // A page keeps its elements. A deck does not: scroll view writes the HTML of
  // the slides again, so a deck finds the elements on each change.
  var cache = null;

  // The fragment of a link to a place on this page, or an empty string.
  // Quarto makes the links of a website absolute, so the link is compared by
  // its resolved URL and not by the text of its `href`. The query is not
  // compared, because the state in the URL changes after Quarto writes the
  // links.
  function pageFragment(link) {
    var samePage = link.origin === location.origin && link.pathname === location.pathname;
    return samePage ? link.hash : '';
  }

  // The `li` of each table of contents link, by the identifier it points to.
  function tocEntries() {
    var entries = {};
    document.querySelectorAll(TOC_LINKS).forEach(function (link) {
      var hash = pageFragment(link);
      var item = link.closest('li');
      if (hash.length < 2 || !item) {
        return;
      }
      var id;
      try {
        id = decodeURIComponent(hash.slice(1));
      } catch (error) {
        id = hash.slice(1);
      }
      (entries[id] = entries[id] || []).push(item);
    });
    return entries;
  }

  function collect() {
    var entries = tocEntries();
    cache = {
      veiled: Array.prototype.map.call(document.querySelectorAll('[data-veil-group]'), function (el) {
        return { el: el, groups: groupsOf(el), items: (el.id && entries[el.id]) || [] };
      }),
      fragments: Array.prototype.slice.call(document.querySelectorAll('.fragment, [data-veil-fragment]'))
    };
    cache.veiled.forEach(function (veiled) {
      veiled.items.forEach(function (item) {
        item.setAttribute('data-veil-toc', '');
      });
    });
  }

  // A fragment in hidden content loses the class `fragment`, so that it does
  // not count. It gets the class back when the content is visible again.
  function updateFragment(el) {
    var inHidden = el.closest('[data-veil-group][hidden]') !== null;
    if (inHidden && el.classList.contains('fragment')) {
      el.classList.remove('fragment');
      el.setAttribute('data-veil-fragment', '');
    } else if (!inHidden && el.hasAttribute('data-veil-fragment')) {
      el.classList.add('fragment');
      el.removeAttribute('data-veil-fragment');
    }
  }

  function apply(resolved) {
    if (cache === null || window.Reveal) {
      collect();
    }
    cache.veiled.forEach(function (veiled) {
      var hidden = !window.VeilState.visible(resolved, veiled.groups);
      setHidden(veiled.el, hidden);
      veiled.items.forEach(function (item) {
        setHidden(item, hidden);
      });
    });
    cache.fragments.forEach(updateFragment);
  }

  window.VeilHtml = { apply: apply, groupsOf: groupsOf };
})();
