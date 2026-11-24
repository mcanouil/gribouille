--- Veil - Config module
--- @module "veil-config"
--- @license MIT License
--- @copyright 2026 Mickaël Canouil
--- @author Mickaël Canouil
--- @brief The configuration of the runtime, and the files that load it.
--- @description Writes `<script type="application/json" id="veil-config">`
--- in the header of a `html` or `revealjs` document, and adds the runtime
--- files as an HTML dependency in `html`.

local M = {}

--- Load modules
local html = require((quarto.utils.resolve_path('_vendor/quarto-lua-modules/html.lua'):gsub('%.lua$', '')))

--- The runtime files, in load order. Each script needs the scripts before it.
local SCRIPTS = { 'veil-state.js', 'veil-ui.js', 'veil-html.js', 'veil.js' }

-- ============================================================================
-- HELPER FUNCTIONS (PRIVATE)
-- ============================================================================

--- The groups of the configuration: the declared groups in their order, then
--- the undeclared groups in alphanumeric order. An undeclared group is used
--- in the document or named in the `state` option.
--- @param declared table The declared groups
--- @param known table The declared groups, then the groups named in the `state` option
--- @param used table Set of the used group names
--- @return table groups {name, level, label}
local function config_groups(declared, known, used)
  local groups, seen, extra = {}, {}, {}
  for _, group in ipairs(declared) do
    groups[#groups + 1] = { name = group.name, level = group.level, label = group.label }
    seen[group.name] = true
  end
  local function add(name)
    if not seen[name] then
      extra[#extra + 1] = name
      seen[name] = true
    end
  end
  for _, group in ipairs(known) do
    add(group.name)
  end
  for name, _ in pairs(used) do
    add(name)
  end
  table.sort(extra)
  for _, name in ipairs(extra) do
    groups[#groups + 1] = { name = name, label = name }
  end
  return groups
end

--- The resolved state with an entry for each group of the configuration.
--- A group that the state does not know is a shown independent group, which
--- is how `VeilState.visible` reads it.
--- @param resolved table The resolved state
--- @param groups table The groups of the configuration
--- @return table state
local function full_state(resolved, groups)
  local independent = {}
  for name, shown in pairs(resolved.independent) do
    independent[name] = shown
  end
  for _, group in ipairs(groups) do
    if resolved.ladder[group.name] == nil and independent[group.name] == nil then
      independent[group.name] = true
    end
  end
  return {
    levels = resolved.levels,
    setting = resolved.setting,
    ladder = resolved.ladder,
    independent = independent,
  }
end

--- The value of `button.enabled` as a boolean.
--- @param enabled string `auto`, `true` or `false`
--- @param is_revealjs boolean
--- @return boolean
local function button_enabled(enabled, is_revealjs)
  if enabled == 'auto' then
    return not is_revealjs
  end
  return enabled == 'true'
end

-- ============================================================================
-- PUBLIC FUNCTIONS
-- ============================================================================

--- The configuration of the runtime as JSON, safe inside a `<script>` element.
--- @param options table The options of `veil.lua`, with the keys that conflict removed
--- @param known table The declared groups, then the groups named in the `state` option
--- @param resolved table The resolved state
--- @param used table Set of the used group names
--- @param is_revealjs boolean
--- @param strings table The interface text of `veil-language`
--- @return string json
function M.encode(options, known, resolved, used, is_revealjs, strings)
  local groups = config_groups(options.groups, known, used)
  local json = quarto.json.encode({
    groups = groups,
    state = full_state(resolved, groups),
    keys = options.keys,
    button = {
      enabled = button_enabled(options.button.enabled, is_revealjs),
      position = options.button.position,
    },
    toast = options.toast,
    strings = strings,
  })
  return (json:gsub('<', '\\u003c'))
end

--- Add the configuration to the header, and, in `html`, the runtime files.
--- In `revealjs`, the `revealjs-plugins` entry of the extension loads the files.
--- @param json string The configuration of `encode`
--- @param is_revealjs boolean
function M.add(json, is_revealjs)
  quarto.doc.include_text('in-header',
    '<script type="application/json" id="veil-config">' .. json .. '</script>')
  if not is_revealjs then
    html.ensure_html_dependency({
      name = 'veil',
      scripts = SCRIPTS,
      stylesheets = { 'veil.css' },
    })
  end
end

return M
