--- Veil - Structure module
--- @module "veil-structure"
--- @license MIT License
--- @copyright 2026 Mickaël Canouil
--- @author Mickaël Canouil
--- @brief The Reveal.js block rules: slides from veiled Divs, and veiled
--- headers below the slide level.
--- @description Reveal.js reads slides as `section > section`. A `.veil` Div
--- that holds slide headers puts their sections inside a `<div>`, and the
--- slides fall out of the deck. A header below the slide level opens no
--- slide, so its `.veil` would hide the heading only. `apply` rewrites both
--- cases before the element handlers run.

local M = {}

--- Load modules
local VeilState = require((quarto.utils.resolve_path('veil-state.lua'):gsub('%.lua$', '')))

local log = require((quarto.utils.resolve_path('_vendor/quarto-lua-modules/logging.lua'):gsub('%.lua$', '')))

local EXTENSION_NAME = 'veil'
local VEIL_CLASS = VeilState.VEIL_CLASS
local GROUP_ATTRIBUTE = VeilState.GROUP_ATTRIBUTE

-- ============================================================================
-- HELPER FUNCTIONS (PRIVATE)
-- ============================================================================

--- Whether a block has the class `veil`.
--- @param block table
--- @return boolean
local function is_veiled(block)
  return block.classes ~= nil and block.classes:includes(VEIL_CLASS)
end

--- Add the names of `extra` that are not yet in `names`.
--- @param names table
--- @param extra table
--- @return table names
local function merge(names, extra)
  local seen = {}
  for _, name in ipairs(names) do
    seen[name] = true
  end
  for _, name in ipairs(extra) do
    if not seen[name] then
      names[#names + 1] = name
      seen[name] = true
    end
  end
  return names
end

--- Put the class `veil` and the groups on a header.
--- A header that is already veiled keeps its groups, and gets the new ones.
--- @param header pandoc.Header
--- @param groups table
local function veil_header(header, groups)
  local names = groups
  if is_veiled(header) then
    names = merge(VeilState.parse_groups(header.attributes[GROUP_ATTRIBUTE]), groups)
  else
    header.classes:insert(VEIL_CLASS)
  end
  header.attributes[GROUP_ATTRIBUTE] = table.concat(names, ' ')
end

--- Whether a Div holds a header at the slide level or above.
--- @param div pandoc.Div
--- @param slide_level integer
--- @return boolean
local function holds_slides(div, slide_level)
  for _, block in ipairs(div.content) do
    if block.t == 'Header' and block.level <= slide_level then
      return true
    end
  end
  return false
end

--- Keep the id of an unwrapped Div when no content comes before its first
--- header. A Div before the header would make an empty slide, so the id goes
--- on the header. A header that has an id keeps it, and a warning names the
--- id of the Div.
--- @param header pandoc.Header The first header of the Div
--- @param div_id string The id of the Div
local function keep_identifier(header, div_id)
  if div_id == '' then
    return
  end
  if header.identifier == '' then
    header.identifier = div_id
    return
  end
  log.log_warning(EXTENSION_NAME, string.format(
    "The id '%s' of a veiled Div is dropped, because its first header already has the id '%s'. " ..
    "Remove one of the two ids, or put the content that needs the id before the first header.",
    div_id, header.identifier))
end

--- The blocks that replace a veiled Div that holds slide headers.
--- @param div pandoc.Div
--- @param slide_level integer
--- @return table blocks
local function unwrap(div, slide_level)
  local groups = VeilState.parse_groups(div.attributes[GROUP_ATTRIBUTE])
  local result, before = {}, {}
  local seen_header = false
  for _, block in ipairs(div.content) do
    if block.t == 'Header' and block.level <= slide_level then
      if not seen_header and #before > 0 then
        result[#result + 1] = pandoc.Div(before, pandoc.Attr(div.identifier, { VEIL_CLASS },
          { [GROUP_ATTRIBUTE] = div.attributes[GROUP_ATTRIBUTE] }))
      end
      if not seen_header and #before == 0 then
        keep_identifier(block, div.identifier)
      end
      seen_header = true
      veil_header(block, groups)
      result[#result + 1] = block
    elseif seen_header then
      result[#result + 1] = block
    else
      before[#before + 1] = block
    end
  end
  return result
end

--- Whether a block ends the section of a header below the slide level: a
--- header at the same level or above, or `---`, which starts a new slide.
--- @param block table
--- @param level integer The level of the header
--- @return boolean
local function ends_section(block, level)
  return block.t == 'HorizontalRule' or (block.t == 'Header' and block.level <= level)
end

--- Wrap each veiled header below the slide level, with its content, in a
--- veiled Div. The header gives its class and groups to the Div.
--- Pandoc changes a Div that starts with a header into a `<section>`, and
--- Reveal.js reads a `<section>` in a slide as a vertical stack. An empty raw
--- block before the header keeps the Div a `<div>`.
--- @param blocks table
--- @param slide_level integer
--- @return table blocks
local function wrap_sub_headers(blocks, slide_level)
  local result = {}
  local index = 1
  while index <= #blocks do
    local block = blocks[index]
    if block.t == 'Header' and block.level > slide_level and is_veiled(block) then
      local section = {}
      index = index + 1
      while index <= #blocks and not ends_section(blocks[index], block.level) do
        section[#section + 1] = blocks[index]
        index = index + 1
      end
      local group = block.attributes[GROUP_ATTRIBUTE]
      block.classes = block.classes:filter(function(class) return class ~= VEIL_CLASS end)
      block.attributes[GROUP_ATTRIBUTE] = nil
      local content = { pandoc.RawBlock('html', ''), block }
      for _, item in ipairs(wrap_sub_headers(section, slide_level)) do
        content[#content + 1] = item
      end
      result[#result + 1] = pandoc.Div(content, pandoc.Attr('', { VEIL_CLASS }, { [GROUP_ATTRIBUTE] = group }))
    else
      result[#result + 1] = block
      index = index + 1
    end
  end
  return result
end

-- ============================================================================
-- PUBLIC FUNCTIONS
-- ============================================================================

--- Apply the Reveal.js block rules to one list of blocks.
--- Call it from a `Blocks` handler, so that it reaches the lists in Divs too.
--- @param blocks pandoc.Blocks
--- @param slide_level integer The slide level of the deck
--- @return pandoc.Blocks blocks A new list
function M.apply(blocks, slide_level)
  local flat = {}
  for _, block in ipairs(blocks) do
    if block.t == 'Div' and is_veiled(block) and holds_slides(block, slide_level) then
      for _, item in ipairs(unwrap(block, slide_level)) do
        flat[#flat + 1] = item
      end
    else
      flat[#flat + 1] = block
    end
  end
  return pandoc.Blocks(wrap_sub_headers(flat, slide_level))
end

return M
