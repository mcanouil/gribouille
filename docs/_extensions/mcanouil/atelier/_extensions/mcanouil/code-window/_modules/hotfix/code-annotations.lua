--- @module "code-annotations"
--- @license MIT
--- @copyright 2026 Mickaël Canouil
--- @author Mickaël Canouil
--- @brief Code annotation detection, stripping, and Typst rendering helpers.
--- Scans CodeBlock elements for inline annotation markers (e.g. # <1>, // <2>)
--- and provides utilities for converting annotations to Typst output.

-- ============================================================================
-- LANGUAGE COMMENT CHARACTERS
-- ============================================================================

--- Map of language identifiers to their single-line comment prefix.
--- @type table<string, string>
local LANG_COMMENT_CHARS = {
  r = '#',
  python = '#',
  lua = '--',
  javascript = '//',
  typescript = '//',
  go = '//',
  rust = '//',
  bash = '#',
  sh = '#',
  zsh = '#',
  fish = '#',
  c = '//',
  cpp = '//',
  cxx = '//',
  cc = '//',
  cs = '//',
  java = '//',
  scala = '//',
  kotlin = '//',
  swift = '//',
  objc = '//',
  php = '//',
  ruby = '#',
  perl = '#',
  julia = '#',
  haskell = '--',
  elm = '--',
  clojure = ';',
  scheme = ';',
  lisp = ';',
  racket = ';',
  erlang = '%%',
  elixir = '#',
  fortran = '!',
  matlab = '%%',
  ada = '--',
  sql = '--',
  plsql = '--',
  tsql = '--',
  mysql = '--',
  sqlite = '--',
  postgresql = '--',
  vb = "'",
  vbnet = "'",
  fsharp = '//',
  stata = '//',
  yaml = '#',
  toml = '#',
  make = '#',
  cmake = '#',
  dockerfile = '#',
  powershell = '#',
  nix = '#',
  zig = '//',
  dart = '//',
  groovy = '//',
  d = '//',
  nim = '#',
  crystal = '#',
  v = '//',
  odin = '//',
  mojo = '#',
}

-- ============================================================================
-- ANNOTATION RESOLUTION
-- ============================================================================

--- Escape a string for use in a Lua pattern.
--- @param s string
--- @return string
local function escape_pattern(s)
  return s:gsub('([%(%)%.%%%+%-%*%?%[%]%^%$])', '%%%1')
end

--- Resolve annotations in a CodeBlock element.
--- Scans each line for a trailing annotation marker (e.g. # <1>) using the
--- language's comment prefix. Strips the marker from the code text and returns
--- the cleaned text along with an annotations table.
--- @param block pandoc.CodeBlock
--- @return string cleaned_text The code with annotation markers removed
--- @return table|nil annotations Maps line numbers (int) to annotation numbers (int), or nil if none found
local function resolve_annotations(block)
  if not block.classes or #block.classes == 0 then
    return block.text, nil
  end

  local lang = block.classes[1]:lower()
  local comment = LANG_COMMENT_CHARS[lang] or '#'

  local escaped_comment = escape_pattern(comment)
  local pattern = '^(.-)%s*' .. escaped_comment .. '%s*<%s*(%d+)%s*>%s*$'

  local annotations = {}
  local lines = {}
  local found = false

  local line_num = 0
  for line in (block.text .. '\n'):gmatch('([^\n]*)\n') do
    line_num = line_num + 1
    local content, annot_num = line:match(pattern)
    if annot_num then
      found = true
      annotations[line_num] = tonumber(annot_num)
      table.insert(lines, content)
    else
      table.insert(lines, line)
    end
  end

  if not found then
    return block.text, nil
  end

  return table.concat(lines, '\n'), annotations
end

-- ============================================================================
-- TYPST CONVERSION HELPERS
-- ============================================================================

--- Convert an annotations table to a Typst dictionary literal.
--- Keys are stringified line numbers, values are annotation numbers.
--- Example output: (1: 2, 3: 1)
--- @param annotations table<int, int> Line number to annotation number mapping
--- @return string Typst dictionary literal
local function annotations_to_typst_dict(annotations)
  local pairs_list = {}
  local keys = {}
  for k in pairs(annotations) do
    table.insert(keys, k)
  end
  table.sort(keys)
  for _, line_num in ipairs(keys) do
    table.insert(pairs_list,
      string.format('"%d": %d', line_num, annotations[line_num]))
  end
  return '(' .. table.concat(pairs_list, ', ') .. ')'
end

--- Check whether a block is an OrderedList that looks like an annotation list.
--- Annotation lists are OrderedLists immediately following a code block,
--- where each item corresponds to an annotation number.
--- @param block pandoc.Block
--- @return boolean
local function is_annotation_ordered_list(block)
  return block and block.t == 'OrderedList'
end

--- Convert an OrderedList to Typst annotation item RawBlocks.
--- Each list item becomes a #code-window-annotation-item(block-id, n)[...] call.
--- @param ol pandoc.OrderedList The ordered list to convert
--- @param wrapper_prefix string Prefix for the Typst function name
--- @param block_id integer Unique block identifier for bidirectional linking
--- @return pandoc.List List of RawBlock elements
local function ordered_list_to_typst_blocks(ol, wrapper_prefix, block_id)
  local blocks = {}
  local start = ol.listAttributes and ol.listAttributes.start or 1
  for i, item in ipairs(ol.content) do
    local annot_num = start + i - 1
    local content_blocks = pandoc.Blocks(item)
    local rendered = pandoc.write(pandoc.Pandoc(content_blocks), 'typst')
    rendered = rendered:gsub('%s+$', '')
    table.insert(blocks, pandoc.RawBlock('typst', string.format(
      '#%s-annotation-item(%d, %d)[%s]',
      wrapper_prefix, block_id, annot_num, rendered
    )))
  end
  return blocks
end

-- ============================================================================
-- MODULE EXPORTS
-- ============================================================================

return {
  LANG_COMMENT_CHARS = LANG_COMMENT_CHARS,
  resolve_annotations = resolve_annotations,
  annotations_to_typst_dict = annotations_to_typst_dict,
  is_annotation_ordered_list = is_annotation_ordered_list,
  ordered_list_to_typst_blocks = ordered_list_to_typst_blocks,
}
