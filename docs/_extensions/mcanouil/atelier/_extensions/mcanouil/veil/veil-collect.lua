--- Veil - Collect module
--- @module "veil-collect"
--- @license MIT License
--- @copyright 2026 Mickaël Canouil
--- @author Mickaël Canouil
--- @brief Element handlers: record the groups of veiled elements, write the
--- runtime markup in `html` and `revealjs`, and remove hidden content in
--- static formats.
--- @description The filter table that `filter()` returns runs after the `Meta`
--- handler of `veil.lua`, which calls `configure()` first.

local M = {}

--- Extension name constant
local EXTENSION_NAME = 'veil'

--- The attribute that holds the groups in the output of a runtime format
local GROUP_DATA = 'data-veil-group'

--- The attribute of an element that is hidden in the resolved state
local HIDDEN_DATA = 'data-veil-hidden'

--- A private attribute on a hidden header. The `Blocks` handler removes the
--- section of each header that has it. Its value is the list of groups.
local REMOVE_MARK = 'veil-remove'

--- A private attribute that numbers each owner header of a removed section.
--- It tells the owners apart from equal headers inside a removed section.
local OWNER_MARK = 'veil-owner'

--- Load modules
local log = require((quarto.utils.resolve_path('_vendor/quarto-lua-modules/logging.lua'):gsub('%.lua$', '')))
local helpers = require((quarto.utils.resolve_path('_vendor/quarto-lua-modules/pandoc-helpers.lua'):gsub('%.lua$', '')))
local extraction = require((quarto.utils.resolve_path('_vendor/quarto-lua-modules/content-extraction.lua'):gsub('%.lua$', '')))
local VeilState = require((quarto.utils.resolve_path('veil-state.lua'):gsub('%.lua$', '')))

local VEIL_CLASS = VeilState.VEIL_CLASS
local GROUP_ATTRIBUTE = VeilState.GROUP_ATTRIBUTE

--- The groups and the identifiers that the handlers found.
--- `used` maps each group name to true.
--- `ids` maps the identifier of each removed element to its groups.
M.collected = { used = {}, ids = {} }

--- The resolved state and whether the format removes hidden content.
--- @type table
local context = { resolved = nil, static = false }

-- ============================================================================
-- HELPER FUNCTIONS (PRIVATE)
-- ============================================================================

--- Record an identifier of removed content with the groups that removed it.
--- An identifier that is already recorded keeps its first groups.
--- @param identifier string|nil
--- @param groups table
local function record_id(identifier, groups)
  if identifier ~= nil and identifier ~= '' and M.collected.ids[identifier] == nil then
    M.collected.ids[identifier] = groups
  end
end

--- The groups of the content that `record_tree` walks.
--- @type table
local walked_groups = {}

local function visit(el)
  record_id(el.identifier, walked_groups)
end

--- The walk filter of `record_tree`, built once.
local RECORD_FILTER = {
  Block = visit,
  Inline = visit,
  FloatRefTarget = visit,
  Callout = function(el)
    record_id(el.attr.identifier, walked_groups)
  end,
}

--- Record the identifiers of all the elements in removed content.
--- @param content any A block, an inline, or a list of them
--- @param groups table The groups that removed the content
local function record_tree(content, groups)
  if pandoc.utils.type(content) == 'Block' then
    content = pandoc.Blocks({ content })
  elseif pandoc.utils.type(content) == 'Inline' then
    content = pandoc.Inlines({ content })
  end
  if type(content) == 'table' and content.walk then
    walked_groups = groups
    content:walk(RECORD_FILTER)
  end
end

--- Remove the class `veil` and the attribute `group` from a kept element.
--- @param attr table An element or an `Attr` with `classes` and `attributes`
local function strip(attr)
  for index = #attr.classes, 1, -1 do
    if attr.classes[index] == VEIL_CLASS then
      table.remove(attr.classes, index)
    end
  end
  attr.attributes[GROUP_ATTRIBUTE] = nil
end

--- Read the groups of a veiled element and record them as used.
--- @param attr table The element, or its `Attr` for a callout
--- @return table|nil groups The groups, or nil when the element has no class `veil`
local function read_veil(attr)
  if not helpers.has_class(attr.classes, VEIL_CLASS) then
    return nil
  end
  local groups = M.parse_groups(attr.attributes[GROUP_ATTRIBUTE])
  for _, name in ipairs(groups) do
    M.collected.used[name] = true
  end
  return groups
end

--- Write the runtime markup on a veiled element of a format with the runtime.
--- The class stays. The attribute `group` becomes `data-veil-group`, and an
--- element that is not visible in the resolved state gets `data-veil-hidden`.
--- @param attr table An element or an `Attr` with `attributes`
--- @param groups table The groups of the element
local function mark(attr, groups)
  attr.attributes[GROUP_ATTRIBUTE] = nil
  attr.attributes[GROUP_DATA] = table.concat(groups, ' ')
  if not VeilState.visible(context.resolved, groups) then
    attr.attributes[HIDDEN_DATA] = ''
  end
end

--- Rewrite or remove one element with the class `veil`.
--- @param el table The element
--- @param attr table The element, or its `Attr` for a callout
--- @param content any The content of the element
--- @return table|nil result `{}` to remove the element, or the element
local function handle(el, attr, content)
  local groups = read_veil(attr)
  if groups == nil then
    return nil
  end
  if not context.static then
    mark(attr, groups)
    return el
  end
  if VeilState.visible(context.resolved, groups) then
    strip(attr)
    return el
  end
  record_id(attr.identifier, groups)
  record_tree(content, groups)
  return {}
end

-- ============================================================================
-- ELEMENT HANDLERS (PRIVATE)
-- ============================================================================

--- Handle a `Div`, a `Span`, or a `FloatRefTarget`.
local function on_element(el)
  return handle(el, el, el.content)
end

local function on_code_block(el)
  return handle(el, el, nil)
end

local function on_callout(el)
  return handle(el, el.attr, el.content)
end

--- Write the runtime markup on a veiled header, or, in a static format, mark
--- a hidden header. The `Blocks` handler removes the section of a marked header.
local function on_header(el)
  local groups = read_veil(el)
  if groups == nil then
    return nil
  end
  if not context.static then
    mark(el, groups)
  elseif VeilState.visible(context.resolved, groups) then
    strip(el)
  else
    el.attributes[REMOVE_MARK] = table.concat(groups, ' ')
  end
  return el
end

--- Whether a header has the private mark of a hidden header.
--- @param header pandoc.Header
--- @return boolean
local function is_marked(header)
  return header.attributes[REMOVE_MARK] ~= nil
end

--- Remove the section of each marked header in one list of blocks.
--- @param blocks pandoc.Blocks
--- @return pandoc.Blocks|nil kept The blocks without the removed sections
local function on_blocks(blocks)
  if not context.static then
    return nil
  end
  local found = false
  for _, block in ipairs(blocks) do
    if block.t == 'Header' and is_marked(block) then
      found = true
      break
    end
  end
  if not found then
    return nil
  end

  local owner_count = 0
  local kept, removed = extraction.remove_sections(blocks, function(header)
    if is_marked(header) then
      owner_count = owner_count + 1
      header.attributes[OWNER_MARK] = tostring(owner_count)
      return true
    end
    return false
  end)

  local groups = {}
  for _, block in ipairs(removed) do
    if block.t == 'Header' and block.attributes[OWNER_MARK] ~= nil then
      groups = M.parse_groups(block.attributes[REMOVE_MARK])
      block.attributes[OWNER_MARK] = nil
    end
    record_tree(block, groups)
  end
  return kept
end

-- ============================================================================
-- PUBLIC FUNCTIONS
-- ============================================================================

--- Stop the render with a message that names the operation and the bad value.
--- @param message string What is wrong and how to correct it
function M.fail(message)
  log.log_error(EXTENSION_NAME, message)
  error('[' .. EXTENSION_NAME .. '] ' .. message)
end

--- Read the groups of a veiled element and check each name.
--- @param value string|nil The value of the `group` attribute
--- @return table names The group names, `{'veil'}` when the value is empty
function M.parse_groups(value)
  local names = VeilState.parse_groups(value)
  for _, name in ipairs(names) do
    if not name:match(VeilState.NAME_PATTERN) then
      M.fail(string.format(
        "The attribute group=\"%s\" has the name '%s', which is not valid. " ..
        "A group name must match the pattern %s. Rename the group, for example to '%s'.",
        value, name, VeilState.NAME_PATTERN, VeilState.suggest_name(name)))
    end
  end
  return names
end

--- Set the resolved state and the kind of format before the handlers run.
--- @param resolved table The resolved state of `veil-state.lua`
--- @param static boolean True when the format removes hidden content
function M.configure(resolved, static)
  context.resolved = resolved
  context.static = static
end

--- The filter table with the element handlers and the `Blocks` handler.
--- @return table filter
function M.filter()
  return {
    Div = on_element,
    Span = on_element,
    Header = on_header,
    CodeBlock = on_code_block,
    Callout = on_callout,
    FloatRefTarget = on_element,
    Blocks = on_blocks,
  }
end

return M
