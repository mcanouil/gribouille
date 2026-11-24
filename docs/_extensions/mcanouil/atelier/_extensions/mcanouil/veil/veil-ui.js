// Veil - ui module.
// The toast, the floating button, and the popover. In Reveal.js, it also
// adds an entry to the Tools menu and the menu key to the `?` help.
// The core calls `mount(api, config)` when it starts, `toast(text)` after
// each change, and `toggle()` when the user presses the key `menu`. The core
// owns all the keys, so this module adds no key listener outside the popover.
// Every label goes into the page with `textContent`, never as markup.

(function () {
  'use strict';

  var SHOW_MS = 1500;
  var FADE_MS = 250;
  var SETTLE_MS = 30;
  var MENU_WAIT_MS = 10000;
  var SVG_NS = 'http://www.w3.org/2000/svg';

  var ui = {
    api: null,
    config: null,
    root: null,
    button: null,
    popover: null,
    toastElement: null,
    opener: null,
    ladder: [],
    switches: [],
    timers: { settle: 0, hide: 0, clear: 0 }
  };

  function make(tag, className, attributes) {
    var element = document.createElement(tag);
    if (className) {
      element.className = className;
    }
    Object.keys(attributes || {}).forEach(function (name) {
      element.setAttribute(name, attributes[name]);
    });
    return element;
  }

  function textOf(key) {
    var strings = ui.config.strings || {};
    return typeof strings[key] === 'string' ? strings[key] : key;
  }

  function labelOf(name) {
    var group = ui.config.groups.filter(function (item) {
      return item.name === name;
    })[0];
    return String((group && group.label) || name);
  }

  function orderOf(name) {
    return ui.config.groups.map(function (group) {
      return group.name;
    }).indexOf(name);
  }

  function byDeclaration(a, b) {
    return orderOf(a) - orderOf(b);
  }

  function isReceiver() {
    return /[?&]receiver(&|=|$)/.test(window.location.search);
  }

  function isUpcomingFrame() {
    return /[?&]controls=false(&|$)/.test(window.location.search);
  }

  // Where the toast shows. In HTML, `auto` and `speaker` are `main`. In a
  // speaker view, only the frame of the current slide shows it.
  function toastHere() {
    var mode = String(ui.config.toast || 'auto');
    if (mode === 'false') {
      return false;
    }
    if (isReceiver()) {
      return !isUpcomingFrame() && (mode === 'auto' || mode === 'speaker');
    }
    if (!window.VeilReveal || mode === 'main') {
      return true;
    }
    return mode === 'auto' && !window.VeilReveal.speakerOpen();
  }

  function toast(text) {
    if (!ui.toastElement || !toastHere()) {
      return;
    }
    var element = ui.toastElement;
    Object.keys(ui.timers).forEach(function (name) {
      window.clearTimeout(ui.timers[name]);
    });
    // The text is empty for a moment, so that a screen reader reads a
    // repeated text again.
    element.textContent = '';
    element.classList.add('veil-toast-on');
    ui.timers.settle = window.setTimeout(function () {
      element.textContent = text;
    }, SETTLE_MS);
    ui.timers.hide = window.setTimeout(function () {
      element.classList.remove('veil-toast-on');
      ui.timers.clear = window.setTimeout(function () {
        element.textContent = '';
      }, FADE_MS);
    }, SETTLE_MS + SHOW_MS);
  }

  function icon() {
    var svg = document.createElementNS(SVG_NS, 'svg');
    var attributes = {
      viewBox: '0 0 24 24',
      width: '22',
      height: '22',
      'aria-hidden': 'true',
      focusable: 'false',
      fill: 'none',
      stroke: 'currentColor',
      'stroke-width': '2',
      'stroke-linecap': 'round',
      'stroke-linejoin': 'round'
    };
    Object.keys(attributes).forEach(function (name) {
      svg.setAttribute(name, attributes[name]);
    });
    var outline = document.createElementNS(SVG_NS, 'path');
    outline.setAttribute('d', 'M1 12s4-8 11-8 11 8 11 8-4 8-11 8-11-8-11-8z');
    var pupil = document.createElementNS(SVG_NS, 'circle');
    pupil.setAttribute('cx', '12');
    pupil.setAttribute('cy', '12');
    pupil.setAttribute('r', '3');
    svg.appendChild(outline);
    svg.appendChild(pupil);
    return svg;
  }

  // One segment for 0, and one for each level. A level with more than one
  // group shows the labels joined with `+`.
  function buildLadder() {
    var state = ui.config.state;
    if (state.levels.length === 0) {
      return null;
    }
    var section = make('div', 'veil-section');
    var heading = make('div', 'veil-heading');
    heading.textContent = textOf('veil-level');
    var group = make('div', 'veil-ladder', { role: 'group', 'aria-label': textOf('veil-level') });
    var levels = [0].concat(state.levels.slice().sort(function (a, b) {
      return a - b;
    }));
    levels.forEach(function (level) {
      var names = Object.keys(state.ladder).filter(function (name) {
        return state.ladder[name] === level;
      }).sort(byDeclaration);
      var segment = make('button', 'veil-segment', { type: 'button', 'aria-pressed': 'false' });
      segment.textContent = level === 0 ? '0' : names.map(labelOf).join(' + ');
      segment.addEventListener('click', function () {
        ui.api.setLevel(level);
      });
      ui.ladder.push({ level: level, element: segment });
      group.appendChild(segment);
    });
    section.appendChild(heading);
    section.appendChild(group);
    return section;
  }

  function buildSwitches() {
    var names = Object.keys(ui.config.state.independent).sort(byDeclaration);
    if (names.length === 0) {
      return null;
    }
    var section = make('div', 'veil-section');
    var heading = make('div', 'veil-heading');
    heading.textContent = textOf('veil-groups');
    section.appendChild(heading);
    names.forEach(function (name) {
      var control = make('button', 'veil-switch', { type: 'button', role: 'switch', 'aria-checked': 'false' });
      control.appendChild(make('span', 'veil-track'));
      var text = make('span', 'veil-switch-label');
      text.textContent = labelOf(name);
      control.appendChild(text);
      control.addEventListener('click', function () {
        ui.api.toggle(name);
      });
      ui.switches.push({ name: name, element: control });
      section.appendChild(control);
    });
    return section;
  }

  function refresh() {
    if (!ui.popover) {
      return;
    }
    var state = ui.api.state();
    ui.ladder.forEach(function (item) {
      item.element.setAttribute('aria-pressed', String(item.level === state.level));
    });
    ui.switches.forEach(function (item) {
      item.element.setAttribute('aria-checked', String(state.groups[item.name] !== false));
    });
  }

  function isOpen() {
    return ui.popover !== null && !ui.popover.hidden;
  }

  function onPointerDown(event) {
    var inside = ui.popover.contains(event.target) || (ui.button && ui.button.contains(event.target));
    if (!inside) {
      close(false);
    }
  }

  function open() {
    if (!ui.popover || isOpen()) {
      return;
    }
    ui.opener = document.activeElement;
    refresh();
    ui.popover.hidden = false;
    if (ui.button) {
      ui.button.setAttribute('aria-expanded', 'true');
    }
    var first = ui.popover.querySelector('[aria-pressed="true"], button');
    if (first) {
      first.focus();
    }
    document.addEventListener('pointerdown', onPointerDown, true);
  }

  function close(restoreFocus) {
    if (!isOpen()) {
      return;
    }
    ui.popover.hidden = true;
    if (ui.button) {
      ui.button.setAttribute('aria-expanded', 'false');
    }
    document.removeEventListener('pointerdown', onPointerDown, true);
    if (restoreFocus) {
      var target = ui.opener;
      if (target && target !== document.body && document.contains(target) && typeof target.focus === 'function') {
        target.focus();
      } else if (document.activeElement && document.activeElement !== document.body) {
        document.activeElement.blur();
      }
    }
    ui.opener = null;
  }

  function toggle() {
    if (isOpen()) {
      close(true);
    } else {
      open();
    }
  }

  // The popover keeps its key events, so Space, the arrows, and Esc do not
  // reach Reveal.js. Esc and the key `menu` close it.
  function onPopoverKey(event) {
    event.stopPropagation();
    if (event.type === 'keydown' && (event.key === 'Escape' || event.key === ui.config.keys.menu)) {
      event.preventDefault();
      close(true);
    }
  }

  function buildPopover(position, withButton) {
    var popover = make('div', 'veil-popover veil-' + position + (withButton ? ' veil-with-button' : ''), {
      id: 'veil-popover',
      role: 'dialog',
      'aria-label': textOf('veil-name')
    });
    popover.hidden = true;
    [buildLadder(), buildSwitches()].forEach(function (section) {
      if (section) {
        popover.appendChild(section);
      }
    });
    ['keydown', 'keyup', 'keypress'].forEach(function (type) {
      popover.addEventListener(type, onPopoverKey);
    });
    return popover;
  }

  function buildButton(position) {
    var button = make('button', 'veil-button veil-' + position, {
      type: 'button',
      title: textOf('veil-name'),
      'aria-label': textOf('veil-name'),
      'aria-haspopup': 'dialog',
      'aria-expanded': 'false',
      'aria-controls': 'veil-popover'
    });
    button.appendChild(icon());
    button.addEventListener('click', toggle);
    return button;
  }

  // The Tools panel of the Reveal.js menu has no API, so the entry goes into
  // its list. The menu builds the panel after this module starts.
  function toolsList() {
    var tool = document.querySelector('.slide-menu-panel .slide-tool-item');
    return tool ? tool.parentNode : null;
  }

  function addMenuEntry() {
    var list = toolsList();
    if (!list) {
      return false;
    }
    if (list.querySelector('.veil-tool')) {
      return true;
    }
    var item = make('li', 'slide-tool-item veil-tool', {
      'data-item': String(list.querySelectorAll('.slide-tool-item').length)
    });
    var link = make('a', '', { href: '#' });
    var menuKey = ui.config.keys.menu;
    if (typeof menuKey === 'string' && menuKey !== '') {
      var key = make('kbd');
      key.textContent = menuKey;
      link.appendChild(key);
    }
    link.appendChild(document.createTextNode(' ' + textOf('veil-name') + '…'));
    link.addEventListener('click', function (event) {
      event.preventDefault();
      var menu = window.Reveal.getPlugin && window.Reveal.getPlugin('menu');
      if (menu && typeof menu.closeMenu === 'function') {
        menu.closeMenu();
      }
      open();
    });
    item.appendChild(link);
    list.appendChild(item);
    return true;
  }

  function watchMenu() {
    if (addMenuEntry()) {
      return;
    }
    var observer = new MutationObserver(function () {
      if (addMenuEntry()) {
        observer.disconnect();
      }
    });
    // Once the menu has made its wrapper, the observer watches only that
    // wrapper. Before, the wrapper can be anywhere in the page.
    var container = document.querySelector('.slide-menu-wrapper') || document.body;
    observer.observe(container, { childList: true, subtree: true });
    window.setTimeout(function () {
      observer.disconnect();
    }, MENU_WAIT_MS);
  }

  function addReveal() {
    var deck = window.Reveal;
    if (!deck) {
      return;
    }
    if (typeof deck.registerKeyboardShortcut === 'function' && ui.config.keys.menu) {
      deck.registerKeyboardShortcut(ui.config.keys.menu, textOf('veil-open-popover'));
    }
    watchMenu();
  }

  function mount(api, config) {
    if (ui.root) {
      return;
    }
    ui.api = api;
    ui.config = config;
    ui.root = make('div', 'veil-ui');
    ui.toastElement = make('div', 'veil-toast', { role: 'status', 'aria-live': 'polite' });
    ui.root.appendChild(ui.toastElement);
    if (!isReceiver()) {
      var position = String(config.button.position || 'bottom-left');
      var withButton = config.button.enabled === true;
      ui.popover = buildPopover(position, withButton);
      if (withButton) {
        ui.button = buildButton(position);
      }
      // The tab order follows the screen: the popover opens above a button
      // at the bottom, and below a button at the top.
      var pair = position.indexOf('bottom') === 0 ? [ui.popover, ui.button] : [ui.button, ui.popover];
      pair.forEach(function (element) {
        if (element) {
          ui.root.appendChild(element);
        }
      });
      document.addEventListener('veil:change', refresh);
      addReveal();
      refresh();
    }
    document.body.appendChild(ui.root);
  }

  window.VeilUI = { mount: mount, toast: toast, toggle: toggle };
})();
