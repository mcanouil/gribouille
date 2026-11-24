// Veil - core and Reveal.js plugin entry point.
// Reads the configuration that the filter writes in `#veil-config`, applies
// the `veil` URL parameter, keeps the state, binds the keys, and exposes
// `window.Veil`. An adapter shows and hides the content:
// `window.VeilHtml` in HTML, and `window.VeilReveal` in a deck.
// An adapter has `apply(resolved)`, and optionally `init(deck, config)` and
// `canApply(resolved)`. When `canApply` returns false, the state does not
// change.
// In HTML, the core starts when the DOM is ready. In Reveal.js, it starts
// from the `init` of the plugin `RevealVeil`.
// It needs `veil-state.js`. `window.VeilUI` is optional. When it exists, the
// core calls `VeilUI.mount(api, config)` at start, `VeilUI.toast(text)` after
// each change, and `VeilUI.toggle()` when the user presses the key `menu`.

(function () {
  'use strict';

  var core = {
    started: false,
    config: null,
    resolved: null,
    adapter: null,
    labels: {}
  };

  function log(level, message) {
    if (window.console && console[level]) {
      console[level]('[veil] ' + message);
    }
  }

  // An adapter can refuse a state, for example one that hides every slide.
  function accepts(adapter, resolved) {
    return typeof adapter.canApply !== 'function' || adapter.canApply(resolved);
  }

  function ui(method) {
    var api = window.VeilUI;
    if (api && typeof api[method] === 'function') {
      api[method].apply(api, Array.prototype.slice.call(arguments, 1));
    }
  }

  // An empty Lua table becomes `[]` in JSON, so each map is read as an object.
  function asMap(value) {
    var map = {};
    if (value && typeof value === 'object' && !Array.isArray(value)) {
      Object.keys(value).forEach(function (key) {
        map[key] = value[key];
      });
    }
    return map;
  }

  function readConfig() {
    var element = document.getElementById('veil-config');
    if (!element) {
      return null;
    }
    try {
      var config = JSON.parse(element.textContent);
      config.groups = Array.isArray(config.groups) ? config.groups : [];
      config.keys = asMap(config.keys);
      config.button = asMap(config.button);
      var state = config.state || {};
      config.state = {
        levels: Array.isArray(state.levels) ? state.levels : [],
        setting: typeof state.setting === 'number' ? state.setting : 0,
        ladder: asMap(state.ladder),
        independent: asMap(state.independent)
      };
      return config;
    } catch (error) {
      log('info', '#veil-config is not valid JSON, so veil does nothing: ' + error.message);
      return null;
    }
  }

  // The first `veil` query parameter, or null. A malformed URL gives null.
  function readUrl() {
    try {
      return new URLSearchParams(window.location.search).get('veil');
    } catch (error) {
      log('info', 'the URL cannot be read: ' + error.message);
      return null;
    }
  }

  function applyText(resolved, text) {
    var result = window.VeilState.apply(resolved, text);
    if (result[1].length > 0) {
      log('info', 'these state tokens are ignored: ' + result[1].join(', '));
    }
    return result[0];
  }

  // The URL gets the full state. Other parameters and the hash stay.
  function writeUrl(text) {
    try {
      var params = window.location.search.replace(/^\?/, '').split('&').filter(function (part) {
        return part !== '' && part.split('=')[0] !== 'veil';
      });
      params.push('veil=' + text);
      var url = window.location.pathname + '?' + params.join('&') + window.location.hash;
      window.history.replaceState(window.history.state, '', url);
    } catch (error) {
      log('info', 'the URL cannot be written: ' + error.message);
    }
  }

  function snapshot(resolved) {
    return {
      level: resolved.levels.length > 0 ? resolved.setting : null,
      groups: asMap(resolved.independent),
      text: window.VeilState.format(resolved)
    };
  }

  function text(key) {
    var strings = core.config.strings || {};
    return typeof strings[key] === 'string' ? strings[key] : key;
  }

  function ladderText(resolved) {
    var shown = core.config.groups.filter(function (group) {
      return window.VeilState.has(resolved.ladder, group.name) && resolved.ladder[group.name] <= resolved.setting;
    }).map(function (group) {
      return core.labels[group.name];
    });
    return text('veil-level') + ' ' + resolved.setting + ' · ' + (shown.length > 0 ? shown.join(', ') : text('veil-none'));
  }

  // The text of the toast: the ladder when the setting changed or a ladder
  // action ran, and each independent group that changed.
  function describe(before, after, ladderAction) {
    var parts = [];
    var hasLadder = after.levels.length > 0;
    if (hasLadder && (ladderAction || before.setting !== after.setting)) {
      parts.push(ladderText(after));
    }
    Object.keys(after.independent).forEach(function (name) {
      if (before.independent[name] !== after.independent[name]) {
        parts.push((core.labels[name] || name) + ' · ' + text(after.independent[name] ? 'veil-shown' : 'veil-hidden'));
      }
    });
    if (parts.length === 0 && hasLadder) {
      parts.push(ladderText(after));
    }
    return parts.join('; ');
  }

  function ready() {
    if (!core.started) {
      log('info', 'the document has no veiled content, so the call does nothing');
    }
    return core.started;
  }

  function commit(next, ladderAction) {
    if (!accepts(core.adapter, next)) {
      log('warn', 'the state "' + window.VeilState.format(next) + '" is not applied, because it hides all the content');
      return;
    }
    var before = core.resolved;
    core.resolved = next;
    core.adapter.apply(next);
    // A change can start another change while it runs (for example from a
    // Reveal.js event), so the URL and the event use the latest state.
    var state = snapshot(core.resolved);
    writeUrl(state.text);
    var text = describe(before, next, ladderAction);
    if (text !== '' && core.config.toast !== 'false') {
      ui('toast', text);
    }
    document.dispatchEvent(new CustomEvent('veil:change', { detail: state }));
  }

  function setGroup(name, shown) {
    var next = window.VeilState.copy(core.resolved);
    if (window.VeilState.has(next.ladder, name)) {
      // Show never hides a group, and hide never shows one.
      next.setting = shown
        ? Math.max(next.setting, next.ladder[name])
        : Math.min(next.setting, window.VeilState.previousLevel(next, next.ladder[name]));
      commit(next, true);
    } else if (window.VeilState.has(next.independent, name)) {
      next.independent[name] = shown;
      commit(next, false);
    } else {
      log('info', 'the group "' + name + '" is not known');
    }
  }

  var api = {
    show: function (group) {
      if (ready()) {
        setGroup(String(group), true);
      }
    },
    hide: function (group) {
      if (ready()) {
        setGroup(String(group), false);
      }
    },
    toggle: function (group) {
      if (ready()) {
        setGroup(String(group), !window.VeilState.visible(core.resolved, [String(group)]));
      }
    },
    setLevel: function (level) {
      if (ready()) {
        commit(applyText(core.resolved, 'level:' + parseInt(level, 10)), true);
      }
    },
    apply: function (state) {
      if (ready()) {
        commit(applyText(core.resolved, String(state || '')), false);
      }
    },
    state: function () {
      if (!core.started) {
        return { level: null, groups: {}, text: '' };
      }
      return snapshot(core.resolved);
    }
  };

  function isEditable(target) {
    if (!target || target.nodeType !== 1) {
      return false;
    }
    return target.isContentEditable || /^(INPUT|TEXTAREA|SELECT)$/.test(target.tagName);
  }

  function step(direction) {
    commit(window.VeilState.step(core.resolved, direction), true);
  }

  // One listener that reads `event.key`, so that keys typed with AltGr work.
  function onKey(event) {
    if (event.defaultPrevented || event.metaKey || (event.ctrlKey && !event.altKey) || isEditable(event.target)) {
      return;
    }
    var keys = core.config.keys;
    var ladder = core.resolved.levels.length > 0;
    if (ladder && event.key === keys['level-up']) {
      step(1);
    } else if (ladder && event.key === keys['level-down']) {
      step(-1);
    } else if (event.key === keys.menu) {
      ui('toggle');
    } else {
      return;
    }
    event.preventDefault();
  }

  function start(adapter, deck) {
    if (core.started) {
      return;
    }
    var config = readConfig();
    if (!config || !adapter) {
      return;
    }
    core.config = config;
    config.groups.forEach(function (group) {
      core.labels[group.name] = String(group.label || group.name);
    });
    if (typeof adapter.init === 'function') {
      adapter.init(deck, config);
    }
    var resolved = config.state;
    var text = readUrl();
    if (text !== null) {
      resolved = applyText(resolved, text);
      if (!accepts(adapter, resolved)) {
        log('warn', 'the URL state "' + text + '" hides all the content, so veil uses the state of the document');
        resolved = config.state;
      }
    }
    core.resolved = resolved;
    core.adapter = adapter;
    core.started = true;
    adapter.apply(resolved);
    document.documentElement.classList.add('veil-ready');
    document.addEventListener('keydown', onKey);
    ui('mount', api, config);
    document.dispatchEvent(new CustomEvent('veil:ready', { detail: snapshot(resolved) }));
  }

  window.Veil = api;

  window.RevealVeil = function () {
    return {
      id: 'veil',
      init: function (deck) {
        start(window.VeilReveal || window.VeilHtml, deck);
      }
    };
  };

  function startHtml() {
    if (!window.Reveal) {
      start(window.VeilHtml);
    }
  }

  if (document.readyState === 'loading') {
    document.addEventListener('DOMContentLoaded', startHtml);
  } else {
    startHtml();
  }
})();
