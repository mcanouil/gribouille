// Veil - state module.
// Pure state logic: ladder, independent groups, state text.
// It has no dependency. The Lua twin `veil-state.lua` follows the same rules,
// and both run the same test cases.

(function () {
  'use strict';

  var NAME_PATTERN = /^[a-z][a-z0-9_-]*$/;

  function copy(resolved) {
    return {
      levels: resolved.levels.slice(),
      setting: resolved.setting,
      ladder: Object.assign({}, resolved.ladder),
      independent: Object.assign({}, resolved.independent)
    };
  }

  function highestLevelUpTo(levels, value) {
    var result = 0;
    levels.forEach(function (level) {
      if (level <= value) {
        result = level;
      }
    });
    return result;
  }

  function has(map, name) {
    return Object.prototype.hasOwnProperty.call(map, name);
  }

  // The highest level below `level`, or 0.
  function previousLevel(resolved, level) {
    var lower = resolved.levels.filter(function (value) { return value < level; });
    return lower.length > 0 ? lower[lower.length - 1] : 0;
  }

  function initial(groups) {
    var resolved = { levels: [], setting: 0, ladder: {}, independent: {} };
    var warnings = [];
    groups.forEach(function (group) {
      if (typeof group.level === 'number') {
        resolved.ladder[group.name] = group.level;
        if (resolved.levels.indexOf(group.level) === -1) {
          resolved.levels.push(group.level);
        }
        if (group.shown && group.level > resolved.setting) {
          resolved.setting = group.level;
        }
      } else {
        resolved.independent[group.name] = Boolean(group.shown);
      }
    });
    resolved.levels.sort(function (a, b) { return a - b; });
    groups.forEach(function (group) {
      if (typeof group.level === 'number' && !group.shown && group.level <= resolved.setting) {
        warnings.push('The group "' + group.name + '" is hidden but a group above it is shown; the filter shows it.');
      }
    });
    return [resolved, warnings];
  }

  function apply(resolved, text) {
    var result = copy(resolved);
    var unknown = [];
    var levelTokens = [];
    var nameTokens = [];
    String(text || '').split(',').forEach(function (raw) {
      var token = raw.trim();
      if (token === '') {
        return;
      }
      var match = /^level:(\d+)$/.exec(token);
      if (match) {
        levelTokens.push(parseInt(match[1], 10));
      } else {
        nameTokens.push(token);
      }
    });
    if (levelTokens.length > 0) {
      result.setting = highestLevelUpTo(result.levels, levelTokens[levelTokens.length - 1]);
    }
    nameTokens.forEach(function (token) {
      var hide = token.charAt(0) === '-';
      var name = hide ? token.slice(1) : token;
      if (has(result.ladder, name)) {
        return;
      }
      if (has(result.independent, name)) {
        result.independent[name] = !hide;
      } else {
        unknown.push(token);
      }
    });
    return [result, unknown];
  }

  function format(resolved) {
    var tokens = [];
    if (resolved.levels.length > 0) {
      tokens.push('level:' + resolved.setting);
    }
    Object.keys(resolved.independent).sort().forEach(function (name) {
      tokens.push((resolved.independent[name] ? '' : '-') + name);
    });
    return tokens.join(',');
  }

  function visible(resolved, names) {
    return names.every(function (name) {
      if (has(resolved.ladder, name)) {
        return resolved.ladder[name] <= resolved.setting;
      }
      return !(has(resolved.independent, name) && resolved.independent[name] === false);
    });
  }

  function step(resolved, direction) {
    var result = copy(resolved);
    if (direction > 0) {
      var next = result.levels.filter(function (level) { return level > result.setting; });
      if (next.length > 0) {
        result.setting = next[0];
      }
    } else {
      result.setting = previousLevel(result, result.setting);
    }
    return result;
  }

  window.VeilState = {
    NAME_PATTERN: NAME_PATTERN,
    has: has,
    copy: copy,
    previousLevel: previousLevel,
    initial: initial,
    apply: apply,
    format: format,
    visible: visible,
    step: step
  };
})();
