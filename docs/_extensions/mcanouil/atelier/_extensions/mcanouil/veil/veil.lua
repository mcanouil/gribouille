--- Veil - Filter
--- @module "veil"
--- @license MIT License
--- @copyright 2026 Mickaël Canouil
--- @author Mickaël Canouil
--- @brief Hide or show content by group.
--- @description Reads the options of the extension and marks content with the
--- `.veil` class so that the reader can hide or show it by group.

--- Extension name constant
local EXTENSION_NAME = 'veil'

--- Load modules
local str = require((quarto.utils.resolve_path('_vendor/quarto-lua-modules/string.lua'):gsub('%.lua$', '')))
local schema = require((quarto.utils.resolve_path('_vendor/quarto-wizard/schema.lua'):gsub('%.lua$', '')))
local check = require((quarto.utils.resolve_path('_vendor/quarto-lua-modules/schema-check.lua'):gsub('%.lua$', '')))
local VeilState = require((quarto.utils.resolve_path('veil-state.lua'):gsub('%.lua$', '')))
local collect = require((quarto.utils.resolve_path('veil-collect.lua'):gsub('%.lua$', '')))
local warn = require((quarto.utils.resolve_path('veil-warn.lua'):gsub('%.lua$', '')))
local structure = require((quarto.utils.resolve_path('veil-structure.lua'):gsub('%.lua$', '')))
local language = require((quarto.utils.resolve_path('veil-language.lua'):gsub('%.lua$', '')))
local config = require((quarto.utils.resolve_path('veil-config.lua'):gsub('%.lua$', '')))

local fail = collect.fail

--- The schema check, built once and reused by the whole render.
--- The validator is injected so that the two vendored sources stay independent.
local checker = check.new(schema, EXTENSION_NAME)

--- The options of the render, set by the `Meta` handler.
--- @type table|nil
local options = nil

--- Whether the chalkboard plugin is enabled, set by the `Meta` handler.
--- @type boolean
local chalkboard = false

--- The declared groups, then the groups named in the `state` option, set by
--- the `Meta` handler.
--- @type table|nil
local known = nil

--- The resolved state, set by the `Meta` handler.
--- @type table|nil
local resolved = nil

--- The slide level of a Reveal.js deck, set by the `Meta` handler.
--- @type integer
local slide_level = 2

--- The interface text of the runtime, set by the `Meta` handler.
--- @type table
local strings = {}

-- ============================================================================
-- HELPER FUNCTIONS (PRIVATE)
-- ============================================================================

--- Read a value as a plain string.
--- @param value any A string, a boolean, or a Pandoc inline list
--- @return string|nil text The value as a string, nil when the value is absent
local function as_string(value)
  if value == nil then
    return nil
  end
  if type(value) == 'string' then
    return value
  end
  if type(value) == 'boolean' or type(value) == 'number' then
    return tostring(value)
  end
  return pandoc.utils.stringify(value)
end

--- Read one declared group and check it.
--- @param raw table The group as the schema check resolved it
--- @param position integer The position of the group in the list
--- @return table group {name, level, shown, label}
local function read_group(raw, position)
  local name = as_string(raw.name)
  if name == nil or name == '' then
    fail(string.format(
      'Group %d has no name. Give the group a name that matches the pattern %s.',
      position, VeilState.NAME_PATTERN))
  end
  if not name:match(VeilState.NAME_PATTERN) then
    fail(string.format(
      "Group %d has the name '%s', which is not valid. A group name must match the pattern %s. " ..
      "Rename the group, for example to '%s'.",
      position, name, VeilState.NAME_PATTERN, VeilState.suggest_name(name)))
  end
  local level = nil
  if raw.level ~= nil then
    level = tonumber(as_string(raw.level))
    if level == nil or level < 1 or level ~= math.floor(level) then
      fail(string.format(
        "Group '%s' has the level '%s', which is not valid. A level is an integer of 1 or more.",
        name, tostring(as_string(raw.level))))
    end
  end
  local shown = raw.shown
  if shown == nil then
    shown = true
  end
  return {
    name = name,
    level = level,
    shown = shown == true or as_string(shown) == 'true',
    label = as_string(raw.label) or name,
  }
end

--- Read the options of the extension, with the defaults applied.
--- @param meta table Document metadata
--- @return table options {groups, state, keys, button, toast}
local function read_options(meta)
  checker:options(meta)

  local groups = {}
  local declared = checker:option('groups') or {}
  for position, raw in ipairs(declared) do
    groups[#groups + 1] = read_group(raw, position)
  end

  local keys = checker:option('keys') or {}
  local button = checker:option('button') or {}

  return {
    groups = groups,
    state = as_string(checker:option('state')),
    keys = {
      menu = as_string(keys.menu) or 'u',
      ['level-up'] = as_string(keys['level-up']) or ']',
      ['level-down'] = as_string(keys['level-down']) or '[',
    },
    button = {
      enabled = as_string(button.enabled) or 'auto',
      position = as_string(button.position) or 'bottom-left',
    },
    toast = as_string(checker:option('toast')) or 'auto',
  }
end

-- ============================================================================
-- FILTER EXPORT
-- ============================================================================

--- Whether the format has the runtime. All other formats are static: the
--- filter removes their hidden content. `dashboard` and `email` are HTML, but
--- they have no runtime.
--- @return boolean
local function has_runtime()
  if quarto.doc.is_format('dashboard') or quarto.doc.is_format('email') then
    return false
  end
  return FORMAT == 'revealjs' or FORMAT:match('^html') ~= nil
end

--- The declared groups, then one shown independent group for each name in
--- the `state` option that no group declares. Without these, the state
--- could not hide an undeclared group such as the default group `veil`.
--- @param opts table The options
--- @return table groups
local function groups_with_state_names(opts)
  local groups, declared = {}, {}
  for _, group in ipairs(opts.groups) do
    groups[#groups + 1] = group
    declared[group.name] = true
  end
  for _, raw in ipairs(str.split(opts.state or '', ',')) do
    local name = (str.trim(raw):gsub('^%-', ''))
    if name:match(VeilState.NAME_PATTERN) and not declared[name] then
      groups[#groups + 1] = { name = name, level = nil, shown = true, label = name }
      declared[name] = true
    end
  end
  return groups
end

--- The state that static formats show: the `shown` values of the groups,
--- then the `state` option. Problems of the state become warnings.
--- The runtime starts from this state, then reads the URL.
--- @param opts table The options
--- @param groups table The groups of `groups_with_state_names`
--- @return table state
local function resolve_state(opts, groups)
  local state, ladder_warnings = VeilState.initial(groups)
  local unknown = {}
  if opts.state then
    state, unknown = VeilState.apply(state, opts.state)
  end
  warn.state(ladder_warnings, unknown)
  return state
end

--- Whether a metadata value turns a feature on.
--- @param value any
--- @return boolean
local function is_enabled(value)
  return value ~= nil and as_string(value) ~= 'false'
end

--- Read the options once, before any element handler runs.
--- @param meta pandoc.Meta Document metadata
--- @return pandoc.Meta meta The metadata, unchanged
local function read_meta(meta)
  options = read_options(meta)
  chalkboard = FORMAT == 'revealjs' and is_enabled(meta.chalkboard)
  if has_runtime() then
    warn.keys(options.keys, warn.format_keys(FORMAT == 'revealjs', chalkboard))
  end
  known = groups_with_state_names(options)
  resolved = resolve_state(options, known)
  slide_level = tonumber(as_string(meta['slide-level'])) or PANDOC_WRITER_OPTIONS.slide_level or 2
  strings = language.strings(meta)
  collect.configure(resolved, not has_runtime())
  return meta
end

--- Apply the Reveal.js block rules to each list of blocks of a deck.
--- @param blocks pandoc.Blocks
--- @return pandoc.Blocks|nil blocks
local function apply_structure(blocks)
  if FORMAT ~= 'revealjs' then
    return nil
  end
  return structure.apply(blocks, slide_level)
end

--- Check the whole document, after all the element handlers ran. In a format
--- with the runtime, add the configuration when the document has veiled content.
--- @param doc pandoc.Pandoc The document
--- @return pandoc.Pandoc doc The document, unchanged
local function check_document(doc)
  local declared = {}
  for _, group in ipairs(options.groups) do
    declared[#declared + 1] = group.name
  end
  local page_of_project = quarto.project.directory ~= nil and quarto.doc.is_format('html:js')
  warn.groups(declared, collect.collected.used, page_of_project)
  if FORMAT == 'revealjs' then
    warn.reveal(doc, chalkboard)
  end
  if not has_runtime() then
    warn.cross_references(doc, collect.collected)
  elseif next(collect.collected.used) ~= nil then
    local is_revealjs = FORMAT == 'revealjs'
    if is_revealjs then
      warn.reveal_plugin(doc.meta['revealjs-plugins'])
    end
    config.add(config.encode(options, known, resolved, collect.collected.used, is_revealjs, strings), is_revealjs)
  end
  return doc
end

local handlers = collect.filter()
handlers.Pandoc = check_document

return {
  { Meta = read_meta },
  { Blocks = apply_structure },
  handlers,
}
