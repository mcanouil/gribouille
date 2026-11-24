// Veil - reveal module.
// The Reveal.js adapter: moves each hidden slide out of `.slides`, and puts
// it back at its place when it is visible again. A comment node with the
// text `veil:<n>` keeps the place of each slide that is out of the deck.
// After each change, the adapter makes Reveal.js, the slide menu and scroll
// view agree with the new deck.
// It also sends each change to the speaker view and to the multiplex
// followers, because these windows follow the deck by slide indices.
// It needs `veil-state.js` and `veil-html.js` (for the content in a slide).

(function () {
  'use strict';

  var SLIDE = 'data-veil-slide';
  var MENU = 'data-veil-menu';
  var MENU_ITEMS = '.slide-menu-panel[data-panel="Slides"] .slide-menu-items li[data-item]';

  var adapter = {
    deck: null,
    slides: null,
    // One entry for each slide and each stack, in document order.
    entries: [],
    // The entries that are slides, not stacks.
    leaves: [],
    // The slides that are out of the deck, by number.
    detached: {},
    // The menu items, by the number of their slide.
    menu: [],
    running: false,
    queue: []
  };

  // The link to the other windows. The speaker view loads the deck in two
  // frames (receivers). The main window sends each change on a
  // BroadcastChannel, and the receivers apply it. A window never sends a
  // state that it received, so no message loops.
  // Other main windows of the same deck use the same channel. Thus each
  // main window has an id, and each message of a main window has this id in
  // `owner`. A receiver finds the id of its own main window (the opener of
  // the speaker view) and ignores the messages of the other main windows.
  var link = {
    channel: null,
    receiver: false,
    // A random id: the owner id of a main window, or the id of a receiver.
    id: '',
    // In a receiver: the id of its main window, or null when it cannot be
    // found. A receiver without an owner accepts every main window.
    owner: null,
    // The receivers that said hello and did not say bye, by id.
    frames: {},
    // While a received state is applied: 'channel' or 'multiplex'.
    incoming: null
  };

  function childSections(el) {
    return Array.prototype.filter.call(el.children, function (child) {
      return child.tagName === 'SECTION';
    });
  }

  // Each slide and each stack gets a number in `data-veil-slide`. The number
  // stays when scroll view writes the HTML of the slides again.
  // Quarto removes the slides with `data-visibility="hidden"` when it renders
  // the deck, so they are usually not in the page. A slide that still has
  // this attribute gets an entry, so that the order is the order of the menu,
  // but it never counts as visible.
  function register(section, stack) {
    var entry = {
      n: adapter.entries.length,
      groups: window.VeilHtml.groupsOf(section),
      stack: stack,
      children: [],
      level1: section.classList.contains('level1'),
      removed: section.getAttribute('data-visibility') === 'hidden' || (stack !== null && stack.removed)
    };
    section.setAttribute(SLIDE, String(entry.n));
    adapter.entries.push(entry);
    return entry;
  }

  // The same walk as the slide menu: each `.slides > section`, then each
  // `section` in it.
  function buildEntries() {
    childSections(adapter.slides).forEach(function (section) {
      var children = section.querySelectorAll('section');
      var entry = register(section, null);
      Array.prototype.forEach.call(children, function (child) {
        entry.children.push(register(child, entry));
      });
    });
    adapter.leaves = adapter.entries.filter(function (entry) {
      return entry.children.length === 0;
    });
  }

  // The `li` of each slide in the slide menu. The menu builds its list before
  // veil starts, from all the slides, and its `data-item` counts each leaf
  // of `buildEntries`.
  function buildMenu() {
    document.querySelectorAll(MENU_ITEMS).forEach(function (item) {
      var entry = adapter.leaves[parseInt(item.getAttribute('data-item'), 10)];
      if (entry) {
        item.setAttribute(MENU, '');
        adapter.menu.push({ item: item, n: entry.n });
      }
    });
  }

  // The numbers of the slides and stacks to hide. The first slide of a stack
  // with `level1` hides the full stack. A stack whose children are all
  // hidden is hidden too.
  function hiddenSet(resolved) {
    var self = {};
    adapter.entries.forEach(function (entry) {
      self[entry.n] = entry.groups.length > 0 && !window.VeilState.visible(resolved, entry.groups);
    });
    var hidden = {};
    adapter.entries.forEach(function (entry) {
      if (entry.children.length > 0) {
        var first = entry.children[0];
        hidden[entry.n] = self[entry.n] || (first.level1 && self[first.n]) ||
          entry.children.every(function (child) { return self[child.n]; });
      } else {
        hidden[entry.n] = self[entry.n];
      }
    });
    return hidden;
  }

  function isLeafShown(entry, hidden) {
    return entry.children.length === 0 && !entry.removed && !hidden[entry.n] &&
      !(entry.stack && hidden[entry.stack.n]);
  }

  function canApply(resolved) {
    if (!adapter.slides || adapter.entries.length === 0) {
      return true;
    }
    var hidden = hiddenSet(resolved);
    return adapter.entries.some(function (entry) {
      return isLeafShown(entry, hidden);
    });
  }

  function findSection(n) {
    return adapter.slides.querySelector('section[' + SLIDE + '="' + n + '"]');
  }

  // The comment node `veil:<n>`, in the deck or in a slide that is out.
  function findMarker(n) {
    var text = 'veil:' + n;
    var roots = [adapter.slides].concat(Object.keys(adapter.detached).map(function (key) {
      return adapter.detached[key];
    }));
    for (var i = 0; i < roots.length; i += 1) {
      var walker = document.createTreeWalker(roots[i], NodeFilter.SHOW_COMMENT);
      while (walker.nextNode()) {
        if (walker.currentNode.nodeValue === text) {
          return walker.currentNode;
        }
      }
    }
    return null;
  }

  function detach(n) {
    var section = findSection(n);
    if (section) {
      section.parentNode.replaceChild(document.createComment('veil:' + n), section);
      adapter.detached[n] = section;
    }
  }

  function attach(n) {
    var marker = findMarker(n);
    if (marker) {
      marker.parentNode.replaceChild(adapter.detached[n], marker);
      delete adapter.detached[n];
    }
  }

  function moveSlides(hidden) {
    adapter.entries.forEach(function (entry) {
      var isOut = window.VeilState.has(adapter.detached, entry.n);
      if (entry.removed) {
        return;
      }
      if (hidden[entry.n] && !isOut) {
        detach(entry.n);
      } else if (!hidden[entry.n] && isOut) {
        attach(entry.n);
      }
    });
  }

  // The menu moves its keyboard selection by `data-item`, plus or minus one.
  // Thus the visible items get new consecutive numbers, and the items of
  // slides that are out lose their number and their indices.
  function updateMenu() {
    var count = 0;
    adapter.menu.forEach(function (link) {
      var section = adapter.entries[link.n].removed ? null : findSection(link.n);
      if (section) {
        var indices = adapter.deck.getIndices(section);
        link.item.removeAttribute('hidden');
        link.item.setAttribute('data-item', String(count));
        link.item.setAttribute('data-slide-h', String(indices.h));
        link.item.setAttribute('data-slide-v', String(indices.v || 0));
        count += 1;
      } else {
        link.item.setAttribute('hidden', '');
        link.item.removeAttribute('data-item');
        link.item.removeAttribute('data-slide-h');
        link.item.removeAttribute('data-slide-v');
      }
    });
  }

  // The slide to show after the change: the current slide if it stays, else
  // the next visible slide, else the previous one.
  function targetSlide(current) {
    var n = current ? parseInt(current.getAttribute(SLIDE), 10) : NaN;
    if (isNaN(n) || findSection(n) === current) {
      return current;
    }
    var after = adapter.leaves.filter(function (entry) { return entry.n > n; });
    var before = adapter.leaves.filter(function (entry) { return entry.n < n; }).reverse();
    var candidates = after.concat(before);
    for (var i = 0; i < candidates.length; i += 1) {
      var section = findSection(candidates[i].n);
      if (section) {
        return section;
      }
    }
    return current;
  }

  function post(message) {
    if (link.channel) {
      link.channel.postMessage(message);
    }
  }

  // The master of multiplex has a secret, with the same test as the plugin.
  // The plugin does not run in the speaker view frames.
  function isMultiplexMaster() {
    var config = adapter.deck.getConfig().multiplex;
    return !link.receiver && Boolean(config) && config.secret !== null && config.secret !== undefined;
  }

  // This runs before the deck changes its indices. Thus the other
  // windows have the new deck when the next index arrives. Only the main
  // window sends a change on the channel. The multiplex plugin forwards the
  // `content` of a `send` event to the followers.
  function sendToOtherWindows(resolved, source) {
    var text = window.VeilState.format(resolved);
    if (source === null && !link.receiver) {
      post({ type: 'veil-state', text: text, owner: link.id });
    }
    if (source !== 'multiplex' && isMultiplexMaster()) {
      var event = new CustomEvent('send');
      event.content = { veil: text };
      document.dispatchEvent(event);
    }
  }

  // Applies a state from another window with the core, so that the URL and
  // the `veil:change` event agree. A state that is already applied does not
  // run again.
  function receive(source, text) {
    if (typeof text !== 'string' || text === '' || !window.Veil || text === window.Veil.state().text) {
      return;
    }
    link.incoming = source;
    try {
      window.Veil.apply(text);
    } finally {
      link.incoming = null;
    }
  }

  // In a receiver: true for a message of its own main window. When the
  // main window loads again, the speaker view stays open, and the new main
  // window has a new id. Thus a message from another owner reads the id of
  // the opener again.
  function fromOwner(data) {
    if (link.owner === null || data.owner === link.owner) {
      return true;
    }
    var owner = findOwner();
    if (owner !== null) {
      link.owner = owner;
    }
    return data.owner === link.owner;
  }

  // In a main window: true for a receiver of this window, or for a receiver
  // that cannot find its main window.
  function forMe(data) {
    return data.owner === null || data.owner === undefined || data.owner === link.id;
  }

  // Messages: `veil-state` from a main window, `veil-hello` and `veil-bye`
  // from a receiver, and `veil-who` from a main window that starts (it asks
  // its open receivers to say hello again). Only a receiver applies
  // `veil-state`, so a main window keeps its own state.
  function onMessage(event) {
    var data = event.data || {};
    if (link.receiver) {
      if (data.type === 'veil-state' && fromOwner(data)) {
        receive('channel', data.text);
      } else if (data.type === 'veil-who' && fromOwner(data)) {
        post({ type: 'veil-hello', id: link.id, owner: link.owner });
      }
    } else if (data.type === 'veil-hello' && typeof data.id === 'string' && forMe(data)) {
      link.frames[data.id] = true;
      var text = window.Veil ? window.Veil.state().text : '';
      if (text !== '') {
        post({ type: 'veil-state', text: text, owner: link.id });
      }
    } else if (data.type === 'veil-bye' && typeof data.id === 'string') {
      delete link.frames[data.id];
    }
  }

  // The speaker view frame is in the notes window, and the main window
  // opened the notes window. A window of another origin or a closed opener
  // gives null.
  function findOwner() {
    try {
      var main = window.parent.opener;
      var id = main && main.VeilReveal ? main.VeilReveal.ownerId : null;
      return typeof id === 'string' && id !== '' ? id : null;
    } catch (error) {
      return null;
    }
  }

  function randomId() {
    return String(Date.now()) + '-' + String(Math.random()).slice(2);
  }

  function initLink(deck) {
    link.receiver = typeof deck.isSpeakerNotes === 'function'
      ? deck.isSpeakerNotes()
      : /receiver/i.test(window.location.search);
    link.id = randomId();
    document.addEventListener('received', function (event) {
      var content = event.content;
      if (content && typeof content.veil === 'string') {
        receive('multiplex', content.veil);
      }
    });
    if (typeof window.BroadcastChannel !== 'function') {
      return;
    }
    link.channel = new window.BroadcastChannel('veil:' + window.location.pathname);
    link.channel.onmessage = onMessage;
    if (link.receiver) {
      link.owner = findOwner();
      post({ type: 'veil-hello', id: link.id, owner: link.owner });
      window.addEventListener('pagehide', function () {
        post({ type: 'veil-bye', id: link.id });
      });
    } else {
      api.ownerId = link.id;
      post({ type: 'veil-who', owner: link.id });
    }
  }

  // True in a speaker view frame, and in a main window that has a receiver
  // that said hello and did not say bye. A receiver says bye when its page
  // closes (`pagehide`), so a frame that stops without `pagehide` counts as
  // open until the main window loads again.
  function speakerOpen() {
    return link.receiver || Object.keys(link.frames).length > 0;
  }

  function scrollView() {
    var support = adapter.deck.getPlugin && adapter.deck.getPlugin('quarto-support');
    if (support && typeof support.toggleScrollView === 'function') {
      return support.toggleScrollView;
    }
    return function () {
      adapter.deck.toggleScrollView();
    };
  }

  // Scroll view writes back the HTML that it saved when it started, so a
  // change made in scroll view is lost. Thus the adapter stops scroll view,
  // makes the change, and starts scroll view again.
  function change(resolved, source) {
    var deck = adapter.deck;
    var ready = deck.isReady();
    var inScroll = ready && deck.isScrollView();
    if (inScroll) {
      scrollView()();
    }
    var current = ready ? deck.getCurrentSlide() : null;
    moveSlides(hiddenSet(resolved));
    window.VeilHtml.apply(resolved);
    updateMenu();
    if (ready) {
      sendToOtherWindows(resolved, source);
      var target = targetSlide(current);
      deck.sync();
      deck.syncFragments();
      var autoAnimate = deck.getConfig().autoAnimate;
      deck.configure({ autoAnimate: false });
      if (target) {
        var indices = deck.getIndices(target);
        deck.slide(indices.h, indices.v);
      }
      deck.configure({ autoAnimate: autoAnimate });
    }
    if (inScroll && !deck.isScrollView()) {
      scrollView()();
    }
  }

  // A change that arrives while a change runs (for example from a
  // `slidechanged` listener) waits in the queue, and runs after it. Each
  // change keeps its source, so a change made during a received change is
  // still sent.
  function apply(resolved) {
    if (!adapter.slides) {
      return;
    }
    if (!canApply(resolved)) {
      console.warn('[veil] this state hides every slide, so veil does not apply it');
      return;
    }
    adapter.queue.push({ resolved: resolved, source: link.incoming });
    link.incoming = null;
    if (adapter.running) {
      return;
    }
    adapter.running = true;
    try {
      while (adapter.queue.length > 0) {
        var next = adapter.queue.shift();
        change(next.resolved, next.source);
      }
    } finally {
      adapter.running = false;
      adapter.queue = [];
    }
  }

  function registerKeys(deck, config) {
    var keys = config.keys || {};
    var ladder = config.state && Array.isArray(config.state.levels) && config.state.levels.length > 0;
    if (!ladder || typeof deck.registerKeyboardShortcut !== 'function') {
      return;
    }
    var strings = config.strings || {};
    if (keys['level-up']) {
      deck.registerKeyboardShortcut(keys['level-up'], strings['veil-level-up'] || 'veil-level-up');
    }
    if (keys['level-down']) {
      deck.registerKeyboardShortcut(keys['level-down'], strings['veil-level-down'] || 'veil-level-down');
    }
  }

  function init(deck, config) {
    deck = deck || window.Reveal;
    var slides = deck && typeof deck.getSlidesElement === 'function' ? deck.getSlidesElement() : null;
    if (!config || !slides || adapter.slides) {
      return;
    }
    adapter.deck = deck;
    adapter.slides = slides;
    buildEntries();
    buildMenu();
    registerKeys(deck, config);
    initLink(deck);
  }

  // `ownerId` is the id of a main window. Its speaker view frames read it.
  var api = { init: init, apply: apply, canApply: canApply, speakerOpen: speakerOpen, ownerId: '' };
  window.VeilReveal = api;
})();
