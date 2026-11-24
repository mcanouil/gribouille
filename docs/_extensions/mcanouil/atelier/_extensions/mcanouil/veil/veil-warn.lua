--- Veil - Warn module
--- @module "veil-warn"
--- @license MIT License
--- @copyright 2026 Mickaël Canouil
--- @author Mickaël Canouil
--- @brief Render-time warnings of the filter.
--- @description Checks the options and the collected content, and writes a
--- warning for each condition of the design. A warning never stops the render.

local M = {}

--- Extension name constant
local EXTENSION_NAME = 'veil'

--- Load modules
local log = require((quarto.utils.resolve_path('_vendor/quarto-lua-modules/logging.lua'):gsub('%.lua$', '')))
local VeilState = require((quarto.utils.resolve_path('veil-state.lua'):gsub('%.lua$', '')))

--- Keys that Reveal.js uses, as `event.key` values
local REVEAL_KEYS = {
  'n', ' ', 'p', 'PageUp', 'PageDown', 'ArrowUp', 'ArrowDown', 'ArrowLeft', 'ArrowRight',
  'h', 'j', 'k', 'l', 'Home', 'End', 'b', 'v', '.', ';', ':', '/', 'f', 'a', 'g', '?',
  'F1', 'Escape', 'o',
}

--- Keys that Quarto uses in a Reveal.js deck
local QUARTO_DECK_KEYS = { 's', 'm', 'e', 'r' }

--- Keys that Quarto uses to open the search of a website
local QUARTO_SEARCH_KEYS = { 'f', '/', 's' }

--- Keys that the chalkboard plugin uses when it is enabled
local CHALKBOARD_KEYS = { 'c', 'b', 'Delete', '-', 'Backspace', 'x', 'y', 'd' }

--- The order in which the keys are checked
local KEY_NAMES = { 'menu', 'level-up', 'level-down' }

--- Write a warning.
--- @param message string
function M.warn(message)
  log.log_warning(EXTENSION_NAME, message)
end

--- Make a lookup table from a list.
--- @param lists table A list of lists
--- @return table lookup
local function lookup(lists)
  local result = {}
  for _, list in ipairs(lists) do
    for _, key in ipairs(list) do
      result[key] = true
    end
  end
  return result
end

--- Write a warning for each state problem that the state module found.
--- @param ladder_warnings table Messages of `VeilState.initial`
--- @param unknown_tokens table Tokens that `VeilState.apply` ignored
function M.state(ladder_warnings, unknown_tokens)
  for _, message in ipairs(ladder_warnings) do
    M.warn(message)
  end
  for _, token in ipairs(unknown_tokens) do
    M.warn(string.format(
      "The option state has the token '%s', which veil ignores. " ..
      "Use 'level:N', 'name' or '-name' with the name of a declared independent group.",
      token))
  end
end

--- Warn about each key that conflicts, and remove it from the keys.
--- @param keys table The `options.keys` table, changed in place
--- @param format_keys table Lists of keys that the format uses
function M.keys(keys, format_keys)
  local taken = lookup(format_keys)
  local used_by = {}
  for _, name in ipairs(KEY_NAMES) do
    local key = keys[name]
    if key ~= nil then
      if taken[key] then
        M.warn(string.format(
          "The key '%s' of keys.%s is the same as a key of Reveal.js or Quarto. " ..
          "The runtime does not bind it. Choose a different key.", key, name))
        keys[name] = nil
      elseif used_by[key] then
        M.warn(string.format(
          "The key '%s' of keys.%s is the same as keys.%s. " ..
          "The runtime does not bind it. Choose a different key.", key, name, used_by[key]))
        keys[name] = nil
      else
        used_by[key] = name
      end
    end
  end
end

--- The lists of keys that the format uses.
--- @param is_revealjs boolean
--- @param chalkboard boolean Whether the chalkboard is enabled
--- @return table lists
function M.format_keys(is_revealjs, chalkboard)
  if not is_revealjs then
    return { QUARTO_SEARCH_KEYS }
  end
  local lists = { QUARTO_DECK_KEYS, REVEAL_KEYS }
  if chalkboard then
    lists[#lists + 1] = CHALKBOARD_KEYS
  end
  return lists
end

--- Warn about the groups of the document and the declared groups.
--- @param declared table List of declared group names
--- @param used table Set of the used group names
--- @param skip_unused boolean True when the unused check does not apply
function M.groups(declared, used, skip_unused)
  local is_declared = {}
  for _, name in ipairs(declared) do
    is_declared[name] = true
  end
  if #declared > 0 then
    for _, name in ipairs(VeilState.sorted_names(used)) do
      if not is_declared[name] then
        M.warn(string.format(
          "The group '%s' is used in the document but not declared in the option groups. " ..
          "Veil adds it as an independent group. Declare it to set its order, label or level.", name))
      end
    end
  end
  if skip_unused or next(used) == nil then
    return
  end
  for _, name in ipairs(declared) do
    if not used[name] then
      M.warn(string.format(
        "The group '%s' is declared in the option groups but no element uses it. " ..
        "Remove the group or add group=\"%s\" to an element.", name, name))
    end
  end
end

--- Whether a block list holds a horizontal rule at any depth.
--- @param content pandoc.Blocks
--- @return boolean
local function has_rule(content)
  local found = false
  content:walk({ HorizontalRule = function() found = true end })
  return found
end

--- Warn about the veiled content of a Reveal.js document.
--- @param doc pandoc.Pandoc The document
--- @param chalkboard boolean Whether the chalkboard is enabled
function M.reveal(doc, chalkboard)
  local veiled_slide = false
  local filter = {
    Header = function(header)
      if header.classes:includes('veil') then
        veiled_slide = true
      end
    end,
    Div = function(div)
      if div.classes:includes('veil') and has_rule(div.content) then
        M.warn("A Div with the class 'veil' contains '---'. A block cannot span two slides. " ..
          'Put the rule outside the Div, or use one Div for each slide.')
      end
    end,
  }
  doc:walk(filter)
  if chalkboard and veiled_slide then
    M.warn('The chalkboard is enabled and the document has veiled slides. ' ..
      'A drawing can show on a different slide after a change of state. ' ..
      'Choose the state before you draw.')
  end
end

--- Whether one entry of `revealjs-plugins` names the Veil plugin. An entry is
--- a name or a path, for example `veil` or `_extensions/mcanouil/veil`.
--- @param entry any A string, a Pandoc inline list, or a map with `name` or `path`
--- @return boolean
local function names_veil(entry)
  local values = { entry }
  if pandoc.utils.type(entry) == 'table' then
    values = { entry.name, entry.path }
  end
  for _, value in pairs(values) do
    local text = pandoc.utils.stringify(value)
    if text == EXTENSION_NAME or text:sub(-#EXTENSION_NAME - 1) == '/' .. EXTENSION_NAME then
      return true
    end
  end
  return false
end

--- Warn when a Reveal.js deck has veiled content but does not load the
--- plugin. Without the plugin, the deck has no runtime and shows every slide.
--- @param plugins any The `revealjs-plugins` metadata value
function M.reveal_plugin(plugins)
  if pandoc.utils.type(plugins) == 'List' then
    for _, entry in ipairs(plugins) do
      if names_veil(entry) then
        return
      end
    end
  elseif plugins ~= nil and names_veil(plugins) then
    return
  end
  M.warn("The document has veiled content, but no 'revealjs-plugins' entry names 'veil'. " ..
    'Without the plugin, the deck shows every slide and the keys do nothing. ' ..
    "Add 'revealjs-plugins: [veil]' to the front matter, next to 'filters: [veil]'.")
end

--- Warn about each cross-reference that points to removed content.
--- Only identifiers that a handler removed are reported, never a kept one.
--- @param doc pandoc.Pandoc The kept document
--- @param collected table The collected identifiers (`ids`)
function M.cross_references(doc, collected)
  local reported = {}
  doc:walk({
    Cite = function(cite)
      for _, citation in ipairs(cite.citations) do
        local groups = collected.ids[citation.id]
        if groups ~= nil and not reported[citation.id] then
          reported[citation.id] = true
          if #groups > 0 then
            M.warn(string.format('`@%s` points to content that the group%s `%s` removed',
              citation.id, #groups > 1 and 's' or '', table.concat(groups, '`, `')))
          else
            M.warn(string.format('`@%s` points to content that veil removed', citation.id))
          end
        end
      end
    end,
  })
end

return M
