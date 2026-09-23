--- MC Content Extraction - Content processing and extraction utilities for Quarto extensions
--- @module "content_extraction"
--- @license MIT
--- @copyright 2026 Mickaël Canouil
--- @author Mickaël Canouil

local M = {}

--- Load a sibling module from the same directory as this file.
--- @param filename string The sibling module filename (e.g., 'string.lua')
--- @return table The loaded module
local function load_sibling(filename)
  local source = debug.getinfo(1, 'S').source:sub(2)
  local dir = source:match('(.*[/\\])') or ''
  return require((dir .. filename):gsub('%.lua$', ''))
end

--- Load required modules
local str = load_sibling('string.lua')
local html = load_sibling('html.lua')

-- ============================================================================
-- SECTION EXTRACTION
-- ============================================================================

--- Extract section from blocks by header ID.
--- Finds a header with the specified identifier and extracts all content
--- until the next header of the same or higher level.
---
--- @param blocks table<integer, table> Array of Pandoc blocks to search
--- @param section_id string Header identifier to find
--- @param include_header boolean|nil Whether to include the header itself (default: true)
--- @return table<integer, table>|nil Array of blocks in section, or nil if not found
--- @usage local section = M.extract_section(blocks, "introduction", true)
function M.extract_section(blocks, section_id, include_header)
  if blocks == nil or section_id == nil or section_id == '' then
    return nil
  end

  --- @type boolean Include header in result (default true)
  local should_include_header = (include_header == nil) and true or include_header

  --- @type boolean Flag indicating if target section has been found
  local found = false
  --- @type integer|nil Header level of the target section
  local section_level = nil
  --- @type table<integer, table> Blocks belonging to the target section
  local section_blocks = {}

  for _, block in ipairs(blocks) do
    if block.t == 'Header' and block.identifier == section_id then
      -- Found the target header
      found = true
      section_level = block.level

      if should_include_header then
        table.insert(section_blocks, block)
      end
    elseif found then
      -- We're inside the target section
      if block.t == 'Header' and block.level <= section_level then
        -- Reached next header of same or higher level, stop
        break
      end
      table.insert(section_blocks, block)
    end
  end

  -- Return nil if section not found, otherwise return collected blocks
  if #section_blocks == 0 and not found then
    return nil
  end

  return section_blocks
end

--- Extract div from blocks by div ID.
--- Recursively searches through blocks to find a Div with the specified identifier
--- and returns its contents.
---
--- @param blocks table<integer, table> Array of Pandoc blocks to search
--- @param div_id string Div identifier to find
--- @param include_div boolean|nil Whether to include the div wrapper itself (default: false)
--- @return table<integer, table>|nil Array of blocks in div, or nil if not found
--- @usage local div_content = M.extract_div(blocks, "my-div", false)
function M.extract_div(blocks, div_id, include_div)
  if blocks == nil or div_id == nil or div_id == '' then
    return nil
  end

  local should_include_div = include_div or false
  local found_div = nil

  pandoc.walk_block(pandoc.Div(blocks), {
    Div = function(div)
      if div.identifier == div_id and found_div == nil then
        found_div = div
      end
    end
  })

  if found_div == nil then
    return nil
  end

  if should_include_div then
    return { found_div }
  else
    return found_div.content
  end
end

--- Find block index by predicate function.
--- Searches through blocks and returns the index of the first block
--- for which the predicate function returns true.
---
--- @param blocks table<integer, table> Array of blocks to search
--- @param predicate function Function that returns true for target block: function(block) → boolean
--- @return integer|nil Index of first matching block (1-based), or nil if not found
--- @usage local idx = M.find_block(blocks, function(b) return b.t == 'Header' end)
function M.find_block(blocks, predicate)
  if blocks == nil or predicate == nil then
    return nil
  end

  for i, block in ipairs(blocks) do
    if predicate(block) then
      return i
    end
  end

  return nil
end

-- ============================================================================
-- HEADER MANIPULATION
-- ============================================================================

--- Convert headers to raw HTML with optional ID prefix.
--- Replaces Header blocks with RawBlock HTML to prevent ID conflicts
--- and control header rendering. Useful in modals, included content, etc.
---
--- @param blocks table<integer, table> Array of Pandoc blocks to process
--- @param id_prefix string|nil Prefix to add to header IDs (e.g., "modal-123-")
--- @param format string|nil Output format (default: 'html')
--- @return table<integer, table> Modified blocks with headers as RawBlocks
--- @usage local protected = M.protect_headers(blocks, "modal-123", "html")
function M.protect_headers(blocks, id_prefix, format)
  if blocks == nil then
    return {}
  end

  --- @type string Output format for raw blocks
  local output_format = format or 'html'

  --- @type table<integer, table> Result blocks
  local protected = {}

  for _, block in ipairs(blocks) do
    if block.t == 'Header' then
      --- @type string Header ID (possibly prefixed)
      local id = block.identifier or ''
      if id ~= '' and id_prefix ~= nil and id_prefix ~= '' then
        id = id_prefix .. id
      end

      --- @type table CSS classes for the header
      local classes = block.classes or {}
      --- @type table Additional HTML attributes
      local attributes = block.attributes or {}

      --- @type string Header content as string
      local header_text = str.stringify(block.content)

      -- Convert to raw HTML block
      table.insert(protected,
        pandoc.RawBlock(
          output_format,
          html.raw_header(block.level, header_text, id, classes, attributes)
        )
      )
    else
      -- Keep other blocks as-is
      table.insert(protected, block)
    end
  end

  return protected
end

-- ============================================================================
-- CONTENT STRUCTURE PARSING
-- ============================================================================

--- Parse content into sections (header, body, footer) separated by HorizontalRule.
--- Common pattern for modal dialogs and similar structures where content is divided:
--- - First Header becomes the title
--- - Content before HorizontalRule becomes body
--- - Content after HorizontalRule becomes footer
---
--- @param blocks table<integer, table> Array of Pandoc blocks to parse
--- @return table Parsed structure: {header_text = string|nil, header_level = integer|nil, body_blocks = table, footer_blocks = table}
--- @usage local parsed = M.parse_sections(modal_content)
function M.parse_sections(blocks)
  if blocks == nil then
    return {
      header_text = nil,
      header_level = nil,
      body_blocks = {},
      footer_blocks = {}
    }
  end

  --- @type string|nil Header text from first header
  local header_text = nil
  --- @type integer|nil Header level from first header
  local header_level = nil
  --- @type table<integer, table> Body blocks (before HorizontalRule)
  local body_blocks = {}
  --- @type table<integer, table> Footer blocks (after HorizontalRule)
  local footer_blocks = {}

  --- @type boolean Flag indicating first header has been found
  local found_header = false
  --- @type boolean Flag indicating HorizontalRule has been found
  local found_hr = false

  for _, block in ipairs(blocks) do
    if not found_header and block.t == 'Header' then
      -- First header becomes the title
      header_text = str.stringify(block.content)
      header_level = block.level
      found_header = true
    elseif block.t == 'HorizontalRule' then
      -- HorizontalRule divides body and footer
      found_hr = true
    elseif not found_hr then
      -- Before HorizontalRule → body
      table.insert(body_blocks, block)
    else
      -- After HorizontalRule → footer
      table.insert(footer_blocks, block)
    end
  end

  return {
    header_text = header_text,
    header_level = header_level or 2,
    body_blocks = body_blocks,
    footer_blocks = footer_blocks
  }
end

--- Extract filename and language from code block text.
--- Searches for metadata in code block using a pattern like: "language | filename: name.ext"
--- Removes the metadata line from the code text.
---
--- @param code_text string Code block text content
--- @param pattern string|nil Pattern to match (default: language-cell-decorator pattern)
--- @return string|nil, string filename (if found), cleaned text (metadata removed)
--- @usage local filename, clean_text = M.extract_code_metadata("python | filename: script.py\nprint('hello')")
function M.extract_code_metadata(code_text, pattern)
  if code_text == nil or code_text == '' then
    return nil, code_text
  end

  --- @type string Pattern for matching metadata
  local match_pattern = pattern or '^%s*.-|%s*filename:%s*([%w%._%-]+)'

  --- @type string|nil Extracted filename
  local filename = string.match(code_text, match_pattern)

  if filename then
    --- @type string Code text with metadata line removed
    local cleaned_text = string.gsub(code_text, match_pattern, '')
    return filename, cleaned_text
  end

  return nil, code_text
end

-- ============================================================================
-- MODULE EXPORT
-- ============================================================================

return M
