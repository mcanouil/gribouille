--- Typst Render - Filter
--- @module "typst-render"
--- @license MIT
--- @copyright 2026 Mickaël Canouil
--- @author Mickaël Canouil
--- @brief Compiles {typst} code blocks to images for non-Typst output formats.
--- @description Intercepts ```{typst} CodeBlock elements and compiles them to
---   images (PNG, SVG, or PDF) using the Typst binary bundled with Quarto,
---   making Typst diagrams, figures, and tables usable across all output formats.

--- Extension name constant
local EXTENSION_NAME = 'typst-render'

--- Load modules
local str = require(quarto.utils.resolve_path('_modules/string.lua'):gsub('%.lua$', ''))
local log = require(quarto.utils.resolve_path('_modules/logging.lua'):gsub('%.lua$', ''))
local paths = require(quarto.utils.resolve_path('_modules/paths.lua'):gsub('%.lua$', ''))
local meta_mod = require(quarto.utils.resolve_path('_modules/metadata.lua'):gsub('%.lua$', ''))
local code_cell = require(quarto.utils.resolve_path('_modules/code-cell.lua'):gsub('%.lua$', ''))
local cell = code_cell.new({ language = '{typst}', comment_prefix = '//|' })

-- ============================================================================
-- CONSTANTS
-- ============================================================================

--- Valid image format set for O(1) lookup
local VALID_FORMAT_SET = { png = true, svg = true, pdf = true }

--- Valid alignment values
local VALID_ALIGN_SET = { left = true, center = true, right = true, default = true }

--- Default option values
local DEFAULTS = {
  format = nil,
  dpi = 144,
  width = 'auto',
  height = 'auto',
  margin = '0.5em',
  background = 'none',
  foreground = nil,
  preamble = '',
  cache = true,
  ['cache-refresh'] = false,
  file = nil,
  ['output-directory'] = nil,
  ['output-filename'] = nil,
  input = nil,
  echo = false,
  eval = true,
  include = true,
  output = true,
  ['output-location'] = nil,
  classes = nil,
  label = nil,
  pages = 'all',
  ['layout-ncol'] = nil,
  align = nil,
}

--- Keys consumed by the filter; any other option is forwarded as an HTML attribute.
--- NOTE: pairs(DEFAULTS) skips nil-valued keys, so all keys with nil defaults
--- must be listed explicitly here to prevent them leaking as HTML attributes.
local KNOWN_KEYS = {
  cap = true,
  alt = true,
  _block_input = true,
  _inline = true,
  _alt = true,
  _source = true,
  root = true,
  ['font-path'] = true,
  ['package-path'] = true,
  format = true,
  foreground = true,
  file = true,
  ['output-directory'] = true,
  ['output-filename'] = true,
  input = true,
  ['output-location'] = true,
  classes = true,
  label = true,
  ['layout-ncol'] = true,
  align = true,
}
for k in pairs(DEFAULTS) do
  KNOWN_KEYS[k] = true
end

--- Check whether a key is consumed by the filter (not forwarded as an attribute).
--- Matches exact known keys and prefix-specific cross-ref keys (e.g. fig-cap, tbl-alt).
--- @param key string
--- @return boolean
local function is_known_key(key)
  if KNOWN_KEYS[key] then
    return true
  end
  return key:match('^%a+%-cap$') ~= nil or key:match('^%a+%-alt$') ~= nil
end

--- Cache base directory within the .quarto scratch directory
local CACHE_BASE = '.quarto/typst-render'

--- Per-document cache subdirectory (set during Meta pass)
local cache_subdir = nil

-- ============================================================================
-- MODULE STATE
-- ============================================================================

--- Global configuration from document metadata
local global_config = {}

--- Detected brand mode ("light" or "dark")
local global_brand_mode = 'light'

--- Resolved Typst binary path (cached)
local typst_bin = nil

--- Whether Typst binary availability has been checked
local typst_checked = false

--- Block counter for auto-numbering unlabelled blocks
local block_counter = 0

--- Inline counter for auto-numbering inline expressions
local inline_counter = 0

--- Whether the PPTX inline warning has been shown
local pptx_inline_warned = false

--- Set of cache filenames produced or hit during this render (for cleanup)
local used_cache_files = {}

--- Set of image format extensions produced during this render (for cleanup)
local used_cache_formats = {}

--- Cache of file contents read during this render pass (keyed by absolute path)
local read_file_cache = {}

--- Document-wide `typst_define()` payload, accumulated by the collect pass.
--- Maps name -> raw value (Lua representation of the JSON-decoded payload).
local typst_define_dict = {}

--- Declaration order of names in `typst_define_dict`, preserved across calls.
local typst_define_order = {}

--- Cached preamble line; built once per Meta pass after ingestion completes,
--- then reused for every {typst} block in this render.
local typst_define_preamble_cache = nil

-- ============================================================================
-- TYPST DEFINE — INGEST FROM `typst-define:` METADATA BLOCK
-- ============================================================================

--- Decode a hex-encoded UTF-8 string back to its raw bytes.
--- WHY: pandoc's smart-quote, dash, and ellipsis transforms would corrupt the
--- JSON payload during YAML metadata block parsing. Hex is transform-free.
--- @param hex string Hex string (lowercase or uppercase, no separators)
--- @return string|nil Decoded string, or nil on malformed input
local function hex_decode(hex)
  if type(hex) ~= 'string' then return nil end
  if #hex % 2 ~= 0 then return nil end
  if hex:match('[^%x]') then return nil end
  return (hex:gsub('(%x%x)', function(byte)
    return string.char(tonumber(byte, 16))
  end))
end

--- Decode a JSON payload and merge its `contents` into the document-wide dict.
--- Last-write-wins on duplicate names; first-seen index in declaration order.
--- @param json_str string JSON payload carried by the metadata block
local function ingest_define_payload(json_str)
  local ok, parsed = pcall(pandoc.json.decode, json_str)
  if not ok or type(parsed) ~= 'table' or type(parsed.contents) ~= 'table' then
    log.log_warning(EXTENSION_NAME, 'Failed to decode typst-define payload; ignoring.')
    return
  end
  for _, entry in ipairs(parsed.contents) do
    if type(entry) == 'table' and entry.name then
      if typst_define_dict[entry.name] == nil then
        typst_define_order[#typst_define_order + 1] = entry.name
      end
      typst_define_dict[entry.name] = entry.value
    end
  end
end

-- ============================================================================
-- TYPST DEFINE — JSON → TYPST LITERAL CONVERSION
-- ============================================================================

--- Format a Lua number for Typst output.
--- Integers print without a decimal point; doubles use `%.17g` for lossless
--- round-trip of the original IEEE-754 value.
--- @param n number
--- @return string
local function format_number(n)
  if math.type(n) == 'integer' then return tostring(n) end
  return string.format('%.17g', n)
end

--- Detect whether a value is a `pandoc.List` (used for JSON arrays).
--- @param v any
--- @return boolean
local function is_pandoc_list(v)
  return pandoc.utils.type(v) == 'List'
end

--- Convert a JSON-decoded Lua value to a Typst literal source fragment.
--- @param v any Decoded value (nil/boolean/number/string/table/pandoc.List/pandoc.json.null)
--- @return string Typst source
local function to_typst_literal(v)
  if v == nil or v == pandoc.json.null then return 'none' end
  local t = type(v)
  if t == 'boolean' then return tostring(v) end
  if t == 'number' then return format_number(v) end
  if t == 'string' then return '"' .. str.escape_typst_string(v) .. '"' end
  if t == 'table' then
    if is_pandoc_list(v) then
      local parts = {}
      for _, x in ipairs(v) do parts[#parts + 1] = to_typst_literal(x) end
      if #parts == 0 then return '()' end
      if #parts == 1 then return '(' .. parts[1] .. ',)' end
      return '(' .. table.concat(parts, ', ') .. ')'
    end
    local entries = {}
    for k, x in pairs(v) do
      entries[#entries + 1] = { key = tostring(k), value = x }
    end
    table.sort(entries, function(a, b) return a.key < b.key end)
    local parts = {}
    for _, e in ipairs(entries) do
      parts[#parts + 1] = '"' .. str.escape_typst_string(e.key) .. '": ' .. to_typst_literal(e.value)
    end
    if #parts == 0 then return '(:)' end
    return '(' .. table.concat(parts, ', ') .. ')'
  end
  return 'none'
end

--- Build the `#let typst_define = (...)` preamble line from accumulated
--- payloads, memoised across all blocks in a single render.
--- @return string|nil
local function build_define_preamble()
  if typst_define_preamble_cache ~= nil then
    return typst_define_preamble_cache
  end
  if #typst_define_order == 0 then return nil end
  local parts = {}
  for _, name in ipairs(typst_define_order) do
    parts[#parts + 1] = '"' .. str.escape_typst_string(name) .. '": '
        .. to_typst_literal(typst_define_dict[name])
  end
  typst_define_preamble_cache = '#let typst_define = (' .. table.concat(parts, ', ') .. ')'
  return typst_define_preamble_cache
end

-- ============================================================================
-- BRAND / THEME COLOUR RESOLUTION
-- ============================================================================

--- Cached brand module (nil = not yet attempted, false = unavailable)
local brand_module = nil

--- Load the Quarto brand module if available.
--- @return table|nil The brand module, or nil if unavailable
local function get_brand_module()
  if brand_module == false then
    return nil
  end
  if brand_module ~= nil then
    return brand_module
  end
  local ok, mod = pcall(require, 'modules/brand/brand')
  if ok and mod then
    brand_module = mod
    return mod
  end
  brand_module = false
  return nil
end

--- Convert a CSS colour string to a Typst colour literal.
--- Wraps hex values like "#fdfdfd" as rgb("#fdfdfd") for Typst.
--- Passes through values that are already Typst-native (e.g., "blue", "luma(240)").
--- @param css_colour string CSS colour string
--- @return string Typst-compatible colour string
local function css_colour_to_typst(css_colour)
  if css_colour:match('^#') then
    return 'rgb("' .. css_colour .. '")'
  end
  if css_colour:match('^rgb%(') or css_colour:match('^hsl%(') then
    return 'rgb("' .. css_colour .. '")'
  end
  return css_colour
end

--- Resolve a colour option to a config value preserving both modes when available.
--- Returns a {light=..., dark=...} table when both modes are present,
--- or a plain string when only one value is available.
--- @param raw any Raw value from config (string, MetaInlines, or MetaMap)
--- @param colour_name string Brand colour name ("foreground" or "background")
--- @return string|table|nil Resolved config value
local function resolve_colour_config(raw, colour_name)
  if raw == nil then
    return nil
  end

  -- Handle MetaMap / table with light/dark keys
  if type(raw) == 'table' and not pandoc.utils.type(raw):match('Inlines') then
    local light = raw['light'] and css_colour_to_typst(pandoc.utils.stringify(raw['light'])) or nil
    local dark = raw['dark'] and css_colour_to_typst(pandoc.utils.stringify(raw['dark'])) or nil
    if light and dark then
      return { light = light, dark = dark }
    end
    return light or dark
  end

  local str = pandoc.utils.stringify(raw)

  if str == 'auto' then
    local brand = get_brand_module()
    if brand and brand.get_color then
      local ok_l, light = pcall(brand.get_color, 'light', colour_name)
      local ok_d, dark = pcall(brand.get_color, 'dark', colour_name)
      local have_light = ok_l and light and light ~= ''
      local have_dark = ok_d and dark and dark ~= ''
      if have_light and have_dark and light ~= dark then
        return { light = css_colour_to_typst(light), dark = css_colour_to_typst(dark) }
      end
      if have_light then
        return css_colour_to_typst(light)
      end
      if have_dark then
        return css_colour_to_typst(dark)
      end
    end
    log.log_warning(
      EXTENSION_NAME,
      colour_name .. ': auto requires a _brand.yml with "' .. colour_name
      .. '" defined; falling back to default.'
    )
    return nil
  end

  if str ~= '' then
    return css_colour_to_typst(str)
  end
  return nil
end

--- Extract a single colour string from a colour config value for a given mode.
--- @param config string|table|nil Colour config (string or {light, dark} table)
--- @param brand_mode string "light" or "dark"
--- @return string|nil Resolved colour string
local function resolve_colour_value(config, brand_mode)
  if type(config) == 'string' then
    return config
  end
  if type(config) == 'table' then
    local other = brand_mode == 'light' and 'dark' or 'light'
    return config[brand_mode] or config[other]
  end
  return nil
end

--- Check whether a colour config has both light and dark values.
--- @param config string|table|nil Colour config
--- @return boolean
local function is_dual_colour(config)
  return type(config) == 'table' and config.light ~= nil and config.dark ~= nil
end

-- ============================================================================
-- HELPER FUNCTIONS
-- ============================================================================

--- Read the entire contents of a file.
--- @param path string The file path to read
--- @return string|nil File contents, or nil if the file cannot be opened
local function read_file(path)
  local f = io.open(path, 'r')
  if not f then
    return nil
  end
  local content = f:read('*a')
  f:close()
  return content
end

--- Serialise all merged options as a sorted, deterministic string for cache hashing.
--- Handles string, number, boolean, and nested table values.
--- @param opts table Merged options
--- @return string Serialised string
local function serialise_opts(opts)
  local function serialise_value(v)
    local t = type(v)
    if t == 'boolean' or t == 'number' then return tostring(v) end
    if t == 'string' then return v end
    if t == 'table' then
      local keys = {}
      for k in pairs(v) do keys[#keys + 1] = k end
      table.sort(keys)
      local parts = {}
      for _, k in ipairs(keys) do
        parts[#parts + 1] = tostring(k) .. '=' .. serialise_value(v[k])
      end
      return '{' .. table.concat(parts, ',') .. '}'
    end
    return ''
  end
  local keys = {}
  for k in pairs(opts) do keys[#keys + 1] = k end
  table.sort(keys)
  local parts = {}
  for _, k in ipairs(keys) do
    -- Skip internal implementation keys (prefixed with '_'); they are not user-visible
    -- rendering parameters and change independently (e.g. _source is a code preview,
    -- _block_input is already captured by input_serial).
    if opts[k] ~= nil and k:sub(1, 1) ~= '_' then
      parts[#parts + 1] = tostring(k) .. '=' .. serialise_value(opts[k])
    end
  end
  return table.concat(parts, '|')
end

--- Extract local file paths referenced by #import and #include statements.
--- Skips package imports (paths starting with @).
--- @param source string Typst source to scan
--- @return table List of unique local file path strings
local function extract_local_file_refs(source)
  local refs, seen = {}, {}
  local function add(path)
    if path:sub(1, 1) ~= '@' and not seen[path] then
      seen[path] = true
      refs[#refs + 1] = path
    end
  end
  for p in source:gmatch('#import%s*"([^"]+)"') do add(p) end
  for p in source:gmatch("#import%s*'([^']+)'") do add(p) end
  for p in source:gmatch('#include%s*"([^"]+)"') do add(p) end
  for p in source:gmatch("#include%s*'([^']+)'") do add(p) end
  return refs
end

--- Recursively collect the content of locally imported Typst files for cache hashing.
--- All paths are resolved relative to root (matching how Typst resolves stdin imports).
--- Missing files are silently skipped; cycles are prevented via visited table.
--- @param source string Typst source to scan for imports
--- @param root string Absolute Typst project root path
--- @param visited table Set of already-visited absolute paths (prevents cycles)
--- @return string Concatenated rel_path+content string for all reachable local imports
local function collect_import_content(source, root, visited)
  local parts = {}
  for _, rel_path in ipairs(extract_local_file_refs(source)) do
    local abs_path = pandoc.path.normalize(pandoc.path.join({ root, rel_path }))
    if not visited[abs_path] then
      visited[abs_path] = true
      local content = read_file_cache[abs_path]
      if content == nil then
        content = read_file(abs_path)
        read_file_cache[abs_path] = content or false
      elseif content == false then
        content = nil
      end
      if content then
        parts[#parts + 1] = rel_path .. '\0' .. content
        local sub = collect_import_content(content, root, visited)
        if sub ~= '' then parts[#parts + 1] = sub end
      end
    end
  end
  return table.concat(parts, '\n')
end

--- Resolve the Typst binary path.
--- @return string|nil Path to the Typst binary, or nil if not found
local function resolve_typst_bin()
  if typst_checked then
    return typst_bin
  end
  typst_checked = true

  local path = quarto.paths.typst()
  if path and path ~= '' then
    typst_bin = path
    return typst_bin
  end

  log.log_error(EXTENSION_NAME, 'Typst binary not found. Ensure Quarto >= 1.6 is installed.')
  return nil
end

--- Determine the best image format for the current output.
--- @return string Image format: "svg", "pdf", or "png"
local function get_image_format_for_output()
  if quarto.format.is_html_output() then
    return 'svg'
  elseif quarto.format.is_latex_output() then
    return 'pdf'
  elseif quarto.format.is_docx_output() or quarto.format.is_powerpoint_output() then
    return 'png'
  elseif quarto.format.is_typst_output() then
    return 'png'
  else
    return 'png'
  end
end

--- Resolve a single preamble entry to Typst code.
--- If the value ends with `.typ`, it is treated as a file path and its contents
--- are read; otherwise the value is used as inline Typst code.
--- @param value string Inline Typst code or path to a `.typ` file
--- @return string|nil Resolved Typst code, or nil on read failure
local function resolve_preamble_entry(value)
  if not value or value == '' then
    return nil
  end
  if value:match('%.typ$') then
    local file_path = paths.resolve_project_path(value)
    local content = read_file(file_path)
    if content then
      return content
    end
    log.log_error(EXTENSION_NAME, 'Could not read preamble file: ' .. value)
    return nil
  end
  return value
end

--- Resolve a preamble option to Typst code.
--- Accepts a string, a list of strings, or nil.
--- Each entry is resolved individually via resolve_preamble_entry.
--- @param value string|table|nil Preamble option value
--- @return string|nil Concatenated Typst code, or nil if empty
local function resolve_preamble(value)
  if not value then
    return nil
  end
  if type(value) == 'string' then
    return resolve_preamble_entry(value)
  end
  if type(value) == 'table' then
    local parts = {}
    for _, entry in ipairs(value) do
      local resolved = resolve_preamble_entry(entry)
      if resolved then
        parts[#parts + 1] = resolved
      end
    end
    if #parts > 0 then
      return table.concat(parts, '\n')
    end
  end
  return nil
end

--- Parse a comma-separated string of key=value pairs into a table.
--- @param str string Input string like "key1=val1,key2=val2"
--- @return table Parsed key-value table
local function parse_input_string(str)
  local result = {}
  if not str or str == '' then
    return result
  end
  for pair in str:gmatch('[^,]+') do
    local k, v = pair:match('^%s*(.-)%s*=%s*(.-)%s*$')
    if k and k ~= '' then
      result[k] = v or ''
    end
  end
  return result
end

--- Merge global and per-block input maps. Per-block values override global ones.
--- @param global_input table|nil Global input map from YAML
--- @param block_input string|nil Per-block comma-separated input string
--- @return table Merged input map (may be empty)
local function merge_inputs(global_input, block_input)
  local merged = {}
  if type(global_input) == 'table' then
    for k, v in pairs(global_input) do
      merged[k] = v
    end
  end
  if type(block_input) == 'string' then
    for k, v in pairs(parse_input_string(block_input)) do
      merged[k] = v
    end
  end
  return merged
end

--- Serialise an input map as a sorted, deterministic string for cache hashing.
--- @param input_map table Key-value table
--- @return string Serialised string like "key1=val1|key2=val2"
local function serialise_inputs(input_map)
  local keys = {}
  for k in pairs(input_map) do
    keys[#keys + 1] = k
  end
  table.sort(keys)
  local parts = {}
  for _, k in ipairs(keys) do
    parts[#parts + 1] = k .. '=' .. input_map[k]
  end
  return table.concat(parts, '|')
end

--- Parse a pages specification string into a sorted, deduplicated list of page numbers.
--- Supports: "all", single numbers ("3"), ranges ("1-3"), open-ended ranges ("3-"),
--- and comma-separated combinations ("1,3-5,8").
--- @param pages_str string Pages specification
--- @param total_pages number Total number of pages available
--- @return table List of valid page numbers (sorted, deduplicated)
local function parse_pages(pages_str, total_pages)
  if pages_str == 'all' then
    local result = {}
    for i = 1, total_pages do
      result[i] = i
    end
    return result
  end

  local seen = {}
  local result = {}
  for part in pages_str:gmatch('[^,]+') do
    part = part:match('^%s*(.-)%s*$')
    local lo, hi = part:match('^(%d+)%-(%d+)$')
    if not lo then
      local open_lo = part:match('^(%d+)%-$')
      if open_lo then
        lo = open_lo
        hi = tostring(total_pages)
      else
        local single = part:match('^(%d+)$')
        if single then
          lo = single
          hi = single
        end
      end
    end
    if lo then
      lo = tonumber(lo)
      hi = tonumber(hi)
      for i = lo, hi do
        if i >= 1 and i <= total_pages then
          if not seen[i] then
            seen[i] = true
            result[#result + 1] = i
          end
        else
          log.log_warning(
            EXTENSION_NAME,
            'Page ' .. tostring(i) .. ' is out of range (1-' .. tostring(total_pages) .. '); skipping.'
          )
        end
      end
    else
      log.log_warning(
        EXTENSION_NAME,
        'Invalid page specification "' .. part .. '"; skipping.'
      )
    end
  end

  table.sort(result)
  return result
end

--- Check whether opts contain any dual-mode colour values requiring dual rendering.
--- @param opts table Merged options
--- @return boolean
local function has_dual_mode_colours(opts)
  return is_dual_colour(opts.background) or is_dual_colour(opts.foreground)
end

--- Resolve table-valued colours in opts to strings for a specific mode.
--- Returns a shallow copy of opts with background/foreground as plain strings.
--- @param opts table Merged options (may contain table-valued colours)
--- @param mode string "light" or "dark"
--- @return table Copy of opts with colours resolved to strings
local function resolve_opts_colours(opts, mode)
  local resolved = {}
  for k, v in pairs(opts) do
    resolved[k] = v
  end
  resolved.background = resolve_colour_value(opts.background, mode) or DEFAULTS.background
  resolved.foreground = resolve_colour_value(opts.foreground, mode)
  return resolved
end

--- Extract a raw hex value from a Typst rgb() expression, e.g. rgb("#F4EDDF") -> "#F4EDDF".
--- Returns nil for non-hex expressions (oklch, named colours, etc.).
--- @param typst_expr string|nil Typst colour expression
--- @return string|nil Hex string or nil
local function typst_colour_to_hex(typst_expr)
  if not typst_expr then return nil end
  return typst_expr:match('^rgb%("(#[%x]+)"%)$')
end

--- Prepend Typst let-bindings for the render background/foreground variables.
--- These make document colours available to library code under predictable names.
--- @param parts table String parts list to append to
--- @param opts table Options containing background and optional foreground
local function inject_colour_vars(parts, opts)
  parts[#parts + 1] = '#let _typst_render_background = ' .. opts.background
  if opts.foreground then
    parts[#parts + 1] = '#let _typst_render_foreground = ' .. opts.foreground
  else
    parts[#parts + 1] = '#let _typst_render_foreground = none'
  end
end

--- Build the `#set page(...)` directive from options (for image compilation).
--- @param opts table Merged options
--- @return string Typst page directive
local function build_page_directive(opts)
  return string.format(
    '#set page(width: %s, height: %s, margin: %s, fill: %s)',
    opts.width, opts.height, opts.margin, opts.background
  )
end

--- Check whether block-level options differ from defaults for native Typst output.
--- Background, foreground, and margin are propagated.
--- @param opts table Merged options
--- @return boolean
local function has_custom_block_options(opts)
  return opts.background ~= DEFAULTS.background
      or opts.foreground ~= DEFAULTS.foreground
      or opts.margin ~= DEFAULTS.margin
end

--- Build the full Typst source with page template.
--- @param code string User Typst code
--- @param opts table Merged options
--- @return string Complete Typst source
local function build_typst_source(code, opts)
  local parts = {}
  inject_colour_vars(parts, opts)
  local define_preamble = build_define_preamble()
  if define_preamble then
    parts[#parts + 1] = define_preamble
  end
  parts[#parts + 1] = build_page_directive(opts)
  if opts.foreground then
    parts[#parts + 1] = '#set text(fill: ' .. opts.foreground .. ')'
  end
  local preamble = resolve_preamble(opts.preamble)
  if preamble then
    parts[#parts + 1] = preamble
  end
  parts[#parts + 1] = code
  return table.concat(parts, '\n')
end

--- Build a human-readable cache file stem from label or block number and a
--- content hash.  Returns e.g. "typst-fig-my-diagram-a1b2c3d4" or "typst-block-3-a1b2c3d4".
--- @param source string Full Typst source
--- @param fmt string Image format
--- @param dpi string DPI value
--- @param label string|nil Cross-reference label
--- @return string File stem (without extension)
local function compute_cache_stem(source, fmt, dpi, label, inline)
  local hash = pandoc.utils.sha1(source .. '|' .. fmt .. '|' .. dpi):sub(1, 8)
  if type(label) == 'string' and label ~= '' then
    return 'typst-' .. label .. '-' .. hash
  end
  if inline then
    inline_counter = inline_counter + 1
    return 'typst-inline-' .. inline_counter .. '-' .. hash
  end
  block_counter = block_counter + 1
  return 'typst-block-' .. block_counter .. '-' .. hash
end

--- Ensure the cache directory exists.
--- @return string|nil Absolute path to the cache directory, or nil on failure
--- @return string|nil Relative path to the cache directory (for image references)
local function ensure_cache_dir()
  if not cache_subdir then
    log.log_error(EXTENSION_NAME, 'Cache subdirectory not initialised.')
    return nil, nil
  end
  local abs_path = pandoc.path.join({ quarto.project.directory, cache_subdir })
  local ok, err = pcall(pandoc.system.make_directory, abs_path, true)
  if not ok then
    log.log_error(EXTENSION_NAME, 'Could not create cache directory: ' .. tostring(err))
    return nil, nil
  end
  local rel_path = cache_subdir
  if quarto.project.offset and quarto.project.offset ~= '' and quarto.project.offset ~= '.' then
    rel_path = pandoc.path.join({ quarto.project.offset, cache_subdir })
  end
  return abs_path, rel_path
end

--- Discover page-numbered output files produced by Typst CLI.
--- Typst generates {stem}1.{ext}, {stem}2.{ext}, ... for PNG/SVG.
--- @param abs_cache string Absolute path to cache directory
--- @param rel_cache string Relative path to cache directory
--- @param stem string File stem (without extension)
--- @param ext string File extension (e.g., "png", "svg")
--- @return table List of relative paths to discovered page files
local function discover_page_files(abs_cache, rel_cache, stem, ext)
  local pages = {}
  local i = 1
  while true do
    local page_name = stem .. tostring(i) .. '.' .. ext
    local page_path = pandoc.path.join({ abs_cache, page_name })
    local f = io.open(page_path, 'r')
    if not f then
      break
    end
    f:close()
    used_cache_files[page_name] = true
    pages[#pages + 1] = pandoc.path.join({ rel_cache, page_name })
    i = i + 1
  end
  return pages
end

--- Copy a file in binary mode.
--- @param src string Source file path
--- @param dst string Destination file path
--- @return boolean True on success
local function copy_file(src, dst)
  local f_in = io.open(src, 'rb')
  if not f_in then
    log.log_warning(EXTENSION_NAME, 'output-file: could not read source file: ' .. src)
    return false
  end
  local data = f_in:read('*a')
  f_in:close()
  if not data then
    log.log_warning(EXTENSION_NAME, 'output-file: failed to read data from ' .. src)
    return false
  end
  local f_out = io.open(dst, 'wb')
  if not f_out then
    log.log_warning(EXTENSION_NAME, 'output-file: could not write to destination: ' .. dst)
    return false
  end
  f_out:write(data)
  f_out:close()
  return true
end

--- Resolve a path to absolute, accounting for document directory.
--- Leading '/' paths are resolved relative to the project root.
--- Other paths are resolved relative to the document directory.
--- @param path string The path to resolve
--- @return string Absolute path
local function resolve_to_absolute(path)
  -- Leading '/' means project root
  if path:sub(1, 1) == '/' then
    return paths.resolve_project_path(path)
  end
  -- Relative path: resolve against the document's directory
  local input_file = quarto.doc.input_file
  if input_file and input_file ~= '' then
    local doc_dir = pandoc.path.directory(input_file)
    if doc_dir and doc_dir ~= '' and doc_dir ~= '.' then
      return pandoc.path.join({ quarto.project.directory, doc_dir, path })
    end
  end
  -- Document is at project root
  if quarto.project.directory then
    return pandoc.path.join({ quarto.project.directory, path })
  end
  return path
end

--- Resolve the output path for saving compiled images.
--- @param global_dir string|nil Global output-directory value
--- @param block_dir string|nil Per-block output-directory value
--- @param block_filename string|nil Per-block output-filename value
--- @param label string|nil Block label (e.g., "fig-diagram")
--- @param counter_name string Auto-generated name (e.g., "typst-block-3")
--- @param img_format string Image format extension (e.g., "png")
--- @return string|nil Resolved absolute path, or nil if no output path
local function resolve_output_path(global_dir, block_dir, block_filename, label, counter_name, img_format)
  -- Determine the filename
  local filename = block_filename
  if not filename or filename == '' then
    -- Auto-generate from label or counter
    local stem = (type(label) == 'string' and label ~= '') and label or counter_name
    filename = stem .. '.' .. img_format
  end

  -- If filename starts with '/', it is a project-root path; ignore directory
  if filename:sub(1, 1) == '/' then
    return resolve_to_absolute(filename)
  end

  -- Determine the directory (per-block overrides global)
  local dir = block_dir or global_dir
  if not dir or dir == '' then
    -- No directory and filename was explicitly set (not auto-generated)
    if block_filename and block_filename ~= '' then
      return resolve_to_absolute(filename)
    end
    return nil
  end

  -- Join directory and filename
  local joined = pandoc.path.join({ dir, filename })

  return resolve_to_absolute(joined)
end

--- Compute a document-relative path from an absolute path.
--- Uses the same approach as ensure_cache_dir: paths are relative to the
--- project root, then prepended with quarto.project.offset when the document
--- lives in a subdirectory.
--- @param abs_path string Absolute path
--- @return string Document-relative path suitable for pandoc Image elements
local function make_doc_relative(abs_path)
  local rel = pandoc.path.make_relative(abs_path, quarto.project.directory)
  if quarto.project.offset and quarto.project.offset ~= '' and quarto.project.offset ~= '.' then
    rel = pandoc.path.join({ quarto.project.offset, rel })
  end
  return rel
end

--- Save compiled image files to the resolved output path.
--- Copies from the cache to the output location and returns
--- document-relative paths so the pandoc elements can reference them.
--- @param page_paths table List of relative page paths from compilation
--- @param output_path string Resolved absolute output path
--- @param mode_suffix string|nil Optional suffix for dual-mode ("-light", "-dark")
--- @param img_format string Image format (e.g., "png")
--- @return table|nil List of document-relative destination paths, or nil on failure
local function save_output_files(page_paths, output_path, mode_suffix, img_format)
  if not page_paths or #page_paths == 0 or not output_path then
    return nil
  end

  local dir = pandoc.path.directory(output_path)
  local filename = pandoc.path.filename(output_path)
  local stem, ext = filename:match('^(.+)%.([^.]+)$')
  if not stem then
    stem = filename
    ext = img_format
  end

  if ext ~= img_format then
    log.log_warning(
      EXTENSION_NAME,
      'output-filename extension ".' .. ext .. '" does not match output format "' .. img_format .. '".'
    )
  end

  -- Create intermediate directories
  if dir and dir ~= '' and dir ~= '.' then
    local ok, err = pcall(pandoc.system.make_directory, dir, true)
    if not ok then
      log.log_warning(EXTENSION_NAME, 'output-directory: could not create directory: ' .. tostring(err))
      return nil
    end
  end

  mode_suffix = mode_suffix or ''
  local result_paths = {}

  -- page_paths are document-relative; resolve to absolute via the document directory
  local doc_abs_dir = quarto.project.directory
  local input_file = quarto.doc.input_file
  if input_file and input_file ~= '' then
    local doc_subdir = pandoc.path.directory(input_file)
    if doc_subdir and doc_subdir ~= '' and doc_subdir ~= '.' then
      doc_abs_dir = pandoc.path.join({ quarto.project.directory, doc_subdir })
    end
  end

  if #page_paths == 1 then
    local src = pandoc.path.normalize(pandoc.path.join({ doc_abs_dir, page_paths[1] }))
    local dst = pandoc.path.join({ dir, stem .. mode_suffix .. '.' .. ext })
    if copy_file(src, dst) then
      log.log_debug(EXTENSION_NAME, 'Saved image to ' .. dst)
      result_paths[1] = make_doc_relative(dst)
    else
      return nil
    end
  else
    for i, page_path in ipairs(page_paths) do
      local src = pandoc.path.normalize(pandoc.path.join({ doc_abs_dir, page_path }))
      local dst = pandoc.path.join({ dir, stem .. mode_suffix .. tostring(i) .. '.' .. ext })
      if copy_file(src, dst) then
        log.log_debug(EXTENSION_NAME, 'Saved image to ' .. dst)
        result_paths[#result_paths + 1] = make_doc_relative(dst)
      else
        return nil
      end
    end
  end

  return result_paths
end

--- Compile Typst source to an image file (or multiple files for multi-page output).
--- Uses stdin to pass source code, avoiding temporary .typ files.
--- @param source string Full Typst source code
--- @param opts table Merged options
--- @param img_format string Target image format
--- @return table|nil List of paths to compiled images, or nil on failure
local function compile_typst(source, opts, img_format)
  local bin = resolve_typst_bin()
  if not bin then
    return nil
  end

  local dpi = tonumber(opts.dpi)
  if not dpi or dpi <= 0 or dpi ~= math.floor(dpi) then
    log.log_warning(
      EXTENSION_NAME,
      'Invalid dpi value "' .. tostring(opts.dpi) .. '"; falling back to default (' .. DEFAULTS.dpi .. ').'
    )
    dpi = DEFAULTS.dpi
  end
  dpi = tostring(math.floor(dpi))

  -- Resolve root early: needed for import scanning before cache key is built.
  -- Defaults to the document's directory; a relative root resolves against it,
  -- a leading '/' means the project root (see resolve_to_absolute).
  local resolved_root = pandoc.path.normalize(resolve_to_absolute(global_config.root or '.'))

  -- Merge global and per-block input variables
  local merged_input = merge_inputs(opts.input, opts._block_input)
  local input_serial = serialise_inputs(merged_input)

  -- Build cache hash material: source + inputs + all merged options + imported file contents
  local hash_source = source
  if input_serial ~= '' then
    hash_source = hash_source .. '|input:' .. input_serial
  end
  hash_source = hash_source .. '|opts:' .. serialise_opts(opts)
  local import_content = collect_import_content(source, resolved_root, {})
  if import_content ~= '' then
    hash_source = hash_source .. '|imports:' .. import_content
  end

  local use_cache = opts.cache ~= false
  local stem = compute_cache_stem(hash_source, img_format, dpi, opts.label, opts._inline)
  local abs_cache, rel_cache = ensure_cache_dir()
  if not abs_cache then
    return nil
  end
  used_cache_formats[img_format] = true

  -- PDF uses a direct output path; PNG/SVG use a page-number template
  -- so Typst CLI can produce one file per page ({stem}{p}.{ext}).
  local is_paged = img_format ~= 'pdf'
  local abs_output, rel_output
  if is_paged then
    abs_output = pandoc.path.join({ abs_cache, stem .. '{p}.' .. img_format })
    rel_output = nil -- not used directly; discover_page_files builds paths
  else
    abs_output = pandoc.path.join({ abs_cache, stem .. '.' .. img_format })
    rel_output = pandoc.path.join({ rel_cache, stem .. '.' .. img_format })
  end

  if use_cache then
    if is_paged then
      local first_page = pandoc.path.join({ abs_cache, stem .. '1.' .. img_format })
      local f = io.open(first_page, 'r')
      if f then
        f:close()
        local pages = discover_page_files(abs_cache, rel_cache, stem, img_format)
        if #pages > 0 then
          return pages
        end
      end
    else
      local f = io.open(abs_output, 'r')
      if f then
        f:close()
        used_cache_files[stem .. '.' .. img_format] = true
        return { rel_output }
      end
    end
  end

  local args = { 'compile', '--format', img_format, '--ppi', dpi, '--root', resolved_root }

  -- Add --font-path flags (global-only; always a list after get_configuration)
  local font_paths = global_config['font-path']
  if font_paths then
    for _, p in ipairs(font_paths) do
      args[#args + 1] = '--font-path'
      args[#args + 1] = paths.resolve_project_path(p)
    end
  end

  -- Add --package-path if specified (global-only)
  if global_config['package-path'] then
    args[#args + 1] = '--package-path'
    args[#args + 1] = paths.resolve_project_path(global_config['package-path'])
  end

  -- Add --input flags for each input variable
  local sorted_keys = {}
  for k in pairs(merged_input) do
    sorted_keys[#sorted_keys + 1] = k
  end
  table.sort(sorted_keys)
  for _, k in ipairs(sorted_keys) do
    args[#args + 1] = '--input'
    args[#args + 1] = k .. '=' .. merged_input[k]
  end

  -- Expose document colours to library theme functions via sys.inputs.
  -- Only hex colours (rgb("#RRGGBB")) can be round-tripped through a CLI flag;
  -- other expressions (oklch, named colours) are available via the #let bindings
  -- injected by inject_colour_vars and do not need a separate --input flag.
  local fg_hex = typst_colour_to_hex(opts.foreground)
  local bg_hex = typst_colour_to_hex(opts.background)
  if fg_hex then
    args[#args + 1] = '--input'
    args[#args + 1] = 'typst-render-foreground=' .. fg_hex
  end
  if bg_hex then
    args[#args + 1] = '--input'
    args[#args + 1] = 'typst-render-background=' .. bg_hex
  end

  -- Use stdin ('-') instead of a temp file
  args[#args + 1] = '-'
  args[#args + 1] = abs_output

  local ok, result = pcall(pandoc.pipe, bin, args, source)
  if not ok then
    local err_msg = tostring(result)
    log.log_error(
      EXTENSION_NAME,
      'Typst compilation failed:\n' .. err_msg
    )
    return nil, err_msg
  end

  if is_paged then
    -- PNG/SVG: Typst CLI generates {stem}1.{ext}, {stem}2.{ext}, ...
    local pages = discover_page_files(abs_cache, rel_cache, stem, img_format)
    if #pages > 0 then
      return pages
    end
    log.log_error(EXTENSION_NAME, 'No compiled page files found for stem: ' .. stem)
    return nil
  else
    -- PDF: single file at the exact output path
    local f = io.open(abs_output, 'r')
    if f then
      f:close()
      used_cache_files[stem .. '.' .. img_format] = true
      return { rel_output }
    end
    log.log_error(EXTENSION_NAME, 'Compiled file not found: ' .. abs_output)
    return nil
  end
end

--- Map from cross-reference prefix to Quarto FloatRefTarget type name.
--- Built-in types are pre-populated; custom types are added from metadata
--- during the Meta pass (see get_configuration).
local REF_TYPE_NAMES = {
  fig = 'Figure',
  tbl = 'Table',
  lst = 'Listing',
}

--- Create a Pandoc Image element from a compiled image.
--- @param img_path string Path to the image file
--- @param opts table Merged options
--- @return pandoc.Para Para containing the image
local function create_image_element(img_path, opts)
  local caption_text = cell.resolve_caption(opts)
  local fallback = caption_text ~= '' and caption_text or opts._source or ''
  local alt_text = cell.resolve_alt(opts, fallback)

  local classes = {}
  if quarto.format.is_html_output() then
    classes[#classes + 1] = 'img-fluid'
  end
  if type(opts.classes) == 'string' and opts.classes ~= '' then
    for cls in opts.classes:gmatch('%S+') do
      classes[#classes + 1] = cls
    end
  end

  local kvpairs = {}
  for k, v in pairs(opts) do
    if not is_known_key(k) and type(v) == 'string' then
      kvpairs[#kvpairs + 1] = { k, v }
    end
  end

  -- Carry the alt text as `fig-alt` so Quarto's figure pipeline copies it onto
  -- the rendered `<img alt>` (and LaTeX/Typst equivalents). When the image is
  -- wrapped in a FloatRefTarget, its caption inlines are consumed as the
  -- caption, so the attribute is the only path that reaches the image alt.
  if alt_text ~= '' then
    kvpairs[#kvpairs + 1] = { 'fig-alt', alt_text }
  end

  local img = pandoc.Image(
    { pandoc.Str(alt_text) },
    img_path,
    '',
    pandoc.Attr('', classes, kvpairs)
  )

  return pandoc.Para({ img })
end

--- Create a Pandoc element from one or more compiled page images.
--- Single-page output returns a Para; multi-page output returns a Div
--- with optional layout-ncol for Quarto's layout processing.
--- @param page_paths table List of image paths
--- @param opts table Merged options
--- @return pandoc.Block Para (single page) or Div (multiple pages)
local function create_multi_page_element(page_paths, opts)
  if #page_paths == 1 then
    return create_image_element(page_paths[1], opts)
  end

  local blocks = {}
  for _, path in ipairs(page_paths) do
    blocks[#blocks + 1] = create_image_element(path, opts)
  end

  local div_attrs = {}
  if opts['layout-ncol'] then
    div_attrs[#div_attrs + 1] = { 'layout-ncol', tostring(opts['layout-ncol']) }
  end

  return pandoc.Div(blocks, pandoc.Attr('', {}, div_attrs))
end

--- Wrap a block in an alignment container if the `align` option is set.
--- Returns the block unchanged when alignment is nil or "default".
--- @param block pandoc.Block The content block
--- @param opts table Merged options
--- @return pandoc.Block The original or wrapped block
local function wrap_alignment(block, opts)
  local align = opts.align
  if not align or align == 'default' then
    return block
  end
  if not VALID_ALIGN_SET[align] then
    log.log_warning(
      EXTENSION_NAME,
      'Invalid align value "' .. align .. '"; ignoring. '
      .. 'Valid values: left, center, right, default.'
    )
    return block
  end
  if quarto.format.is_typst_output() then
    local raw = pandoc.RawBlock('typst', '#align(' .. align .. ')[')
    local raw_close = pandoc.RawBlock('typst', ']')
    return pandoc.Div(pandoc.Blocks({ raw, block, raw_close }))
  end
  local style = 'text-align: ' .. align .. ';'
  return pandoc.Div(
    pandoc.Blocks({ block }),
    pandoc.Attr('', {}, { { 'style', style } })
  )
end

--- Create an error block for failed Typst compilation.
--- @param err string|nil Error message from the compiler
--- @return pandoc.Div Error block
local function create_error_block(err)
  local error_inlines = {
    pandoc.Strong({ pandoc.Str('[typst-render] Compilation failed for this block.') }),
  }
  if err then
    error_inlines[#error_inlines + 1] = pandoc.LineBreak()
    error_inlines[#error_inlines + 1] = pandoc.Code(err)
  end
  return pandoc.Div(
    pandoc.Blocks({ pandoc.Para(error_inlines) }),
    pandoc.Attr('', { 'typst-render-error' }, {})
  )
end

--- Compile Typst code and produce a result block (image element with alignment).
--- @param code string User Typst code
--- @param opts table Resolved options (colours must be plain strings)
--- @param img_format string Target image format
--- @return pandoc.Block|nil Result block, or nil on failure
--- @return table|nil List of selected page paths, or nil on failure
--- @return string|nil Error message on compilation failure
local function compile_to_result(code, opts, img_format)
  local full_source = build_typst_source(code, opts)
  local all_pages, compile_err = compile_typst(full_source, opts, img_format)

  if not all_pages then
    return nil, nil, compile_err
  end

  local selected_pages
  if img_format == 'pdf' and opts.pages ~= 'all' then
    log.log_warning(
      EXTENSION_NAME,
      'Page selection is not supported for PDF format; embedding the full PDF.'
    )
    selected_pages = all_pages
  else
    local page_indices = parse_pages(opts.pages, #all_pages)
    selected_pages = {}
    for _, idx in ipairs(page_indices) do
      selected_pages[#selected_pages + 1] = all_pages[idx]
    end
  end

  if #selected_pages == 0 then
    return nil, nil, nil
  end

  return wrap_alignment(create_multi_page_element(selected_pages, opts), opts), selected_pages, nil
end

--- Read an external `.typ` file, resolving relative to the project directory.
--- @param file_opt string Path from the `file` option
--- @return string|nil File contents, or nil on failure
local function read_external_file(file_opt)
  local file_path = paths.resolve_project_path(file_opt)
  local content = read_file(file_path)
  if content then
    return content
  end
  log.log_error(EXTENSION_NAME, 'Could not read file: ' .. file_opt)
  return nil
end

-- ============================================================================
-- FILTER FUNCTIONS
-- ============================================================================

--- Register custom cross-reference categories from document metadata.
--- Reads `crossref.custom` entries and adds their `key` -> `reference-prefix`
--- mappings to REF_TYPE_NAMES so that wrap_crossref can look them up.
--- @param meta pandoc.Meta
local function register_custom_crossref_types(meta)
  local cr = meta['crossref']
  if not cr then
    return
  end
  local custom = cr['custom']
  if not custom or type(custom) ~= 'table' then
    return
  end
  for _, entry in ipairs(custom) do
    local key = entry['key'] and pandoc.utils.stringify(entry['key'])
    local name = entry['reference-prefix'] and pandoc.utils.stringify(entry['reference-prefix'])
    if key and name then
      REF_TYPE_NAMES[key] = name
    end
  end
end

--- Extract global configuration from document metadata.
--- @param meta pandoc.Meta
--- @return pandoc.Meta
local function get_configuration(meta)
  register_custom_crossref_types(meta)
  read_file_cache = {}

  -- Build per-document cache subdirectory from the input file stem
  local doc_stem = 'default'
  local input_file = quarto.doc.input_file
  if input_file and input_file ~= '' then
    local input_name = pandoc.path.filename(input_file)
    doc_stem = input_name:match('^(.+)%.[^.]+$') or input_name
  end
  cache_subdir = pandoc.path.join({ CACHE_BASE, doc_stem })

  -- Detect brand mode from document metadata (used for colour resolution)
  global_brand_mode = (meta['brand-mode'] and pandoc.utils.stringify(meta['brand-mode']) == 'dark')
      and 'dark' or 'light'

  local ext_config = meta_mod.get_extension_config(meta, EXTENSION_NAME) or meta['typst-render']

  if ext_config then
    -- Iterate all DEFAULTS keys explicitly; pairs() skips nil-valued keys,
    -- so we use a separate key list to ensure 'format' etc. are not missed.
    local config_keys = {
      'format', 'dpi', 'width', 'height', 'margin',
      'cache', 'cache-refresh', 'echo', 'eval', 'include', 'output', 'output-location', 'classes',
      'root', 'package-path', 'pages', 'layout-ncol', 'align',
      'output-directory',
    }
    for _, k in ipairs(config_keys) do
      local default_val = DEFAULTS[k]
      if ext_config[k] ~= nil then
        local val = ext_config[k]
        if k == 'echo' then
          if type(val) == 'boolean' then
            global_config[k] = val
          else
            local str = pandoc.utils.stringify(val)
            if str == 'fenced' then
              global_config[k] = 'fenced'
            else
              global_config[k] = str == 'true'
            end
          end
        elseif k == 'output' then
          if type(val) == 'boolean' then
            global_config[k] = val
          else
            local str = pandoc.utils.stringify(val)
            if str == 'asis' then
              global_config[k] = 'asis'
            else
              global_config[k] = str == 'true'
            end
          end
        elseif type(default_val) == 'number' then
          local n = tonumber(pandoc.utils.stringify(val))
          if n then
            global_config[k] = n
          end
        elseif type(default_val) == 'boolean' then
          if type(val) == 'boolean' then
            global_config[k] = val
          else
            local str = pandoc.utils.stringify(val)
            global_config[k] = str == 'true'
          end
        else
          global_config[k] = pandoc.utils.stringify(val)
        end
      end
    end

    -- Handle 'font-path' separately: accept a string or list of strings
    if ext_config['font-path'] ~= nil then
      local raw = ext_config['font-path']
      local raw_type = pandoc.utils.type(raw)
      if raw_type == 'List' then
        local paths = {}
        for _, v in ipairs(raw) do
          paths[#paths + 1] = pandoc.utils.stringify(v)
        end
        global_config['font-path'] = paths
      else
        global_config['font-path'] = { pandoc.utils.stringify(raw) }
      end
    end

    -- Handle 'preamble' separately: accept a string or list of strings
    if ext_config['preamble'] ~= nil then
      local raw = ext_config['preamble']
      local raw_type = pandoc.utils.type(raw)
      if raw_type == 'List' then
        local items = {}
        for _, v in ipairs(raw) do
          items[#items + 1] = pandoc.utils.stringify(v)
        end
        global_config['preamble'] = items
      else
        local str = pandoc.utils.stringify(raw)
        global_config['preamble'] = str ~= '' and { str } or {}
      end
    end

    -- Handle 'input' separately: store as a key-value table (YAML map)
    if ext_config['input'] ~= nil then
      local raw = ext_config['input']
      if type(raw) == 'table' then
        local input_map = {}
        for k, v in pairs(raw) do
          input_map[tostring(k)] = pandoc.utils.stringify(v)
        end
        global_config['input'] = input_map
      else
        log.log_warning(
          EXTENSION_NAME,
          'Global "input" must be a YAML map (e.g., input: {key: value}), not a string.'
        )
      end
    end

    -- Handle 'background' and 'foreground' separately: support string, "auto", or {light, dark} map
    for _, colour_key in ipairs({ 'background', 'foreground' }) do
      if ext_config[colour_key] ~= nil then
        local resolved = resolve_colour_config(ext_config[colour_key], colour_key)
        if resolved then
          global_config[colour_key] = resolved
        end
      end
    end
  end

  -- Ingest any `typst-define:` payload emitted by the R/Python helpers.
  -- The helpers write a YAML metadata block whose value is a hex-encoded
  -- JSON payload; we hex-decode, JSON-decode, and strip the key so it does
  -- not leak to downstream filters.
  local define_meta = meta['typst-define']
  if define_meta then
    local hex = pandoc.utils.stringify(define_meta)
    local json_str = hex and hex_decode(hex)
    if json_str and json_str ~= '' then
      ingest_define_payload(json_str)
    elseif hex and hex ~= '' then
      log.log_warning(EXTENSION_NAME, 'typst-define metadata payload is not valid hex; ignoring.')
    end
    meta['typst-define'] = nil
  end

  return meta
end

--- Process a {typst} CodeBlock element.
--- @param el pandoc.CodeBlock
--- @return pandoc.Block|pandoc.Blocks|nil
local function process_codeblock(el)
  if not cell.is_code_block(el) then
    return nil
  end

  local block_opts, clean_code, option_lines = cell.parse_options(el.text)

  if block_opts['cache-refresh'] ~= nil then
    log.log_warning(
      EXTENSION_NAME,
      'Per-block "cache-refresh" is not supported; use the global option instead.'
    )
    block_opts['cache-refresh'] = nil
  end

  -- Stash per-block input string before merge overwrites it with global table
  local block_input_str = nil
  if type(block_opts.input) == 'string' then
    block_input_str = block_opts.input
    block_opts.input = nil
  end

  local opts = cell.merge_options(block_opts, global_config, DEFAULTS)
  opts._block_input = block_input_str

  -- Resolve per-block colour overrides only. Values inherited from global_config
  -- are already resolved (e.g. 'rgb("#FAF6EE")') and must not be re-wrapped.
  for _, colour_key in ipairs({ 'background', 'foreground' }) do
    local block_val = block_opts[colour_key]
    if block_val == 'auto' then
      opts[colour_key] = resolve_colour_config('auto', colour_key) or DEFAULTS[colour_key]
    elseif type(block_val) == 'string' and block_val ~= DEFAULTS[colour_key] then
      opts[colour_key] = css_colour_to_typst(block_val)
    end
  end

  local do_include = cell.should_include(opts)
  local do_eval = opts.eval ~= false
  local do_echo = opts.echo == true or opts.echo == 'fenced'
  local is_fenced = opts.echo == 'fenced'
  local output_mode = cell.resolve_output_mode(opts)

  -- Handle eval/echo matrix: both false means hidden block
  if not do_eval and not do_echo then
    return pandoc.Null()
  end

  -- Resolve source code
  local code = clean_code
  if opts.file then
    code = read_external_file(opts.file)
    if not code then
      return do_include and el or pandoc.Null()
    end
  end

  opts._source = code:sub(1, 200)

  -- Echo-only: show source listing without compilation
  if not do_eval then
    if not do_include then
      return pandoc.Null()
    end
    return cell.create_echo_block(code, is_fenced, option_lines)
  end

  -- Output suppressed: skip compilation, show echo block only
  if output_mode == 'false' then
    if do_echo and do_include then
      return cell.create_echo_block(code, is_fenced, option_lines)
    end
    return pandoc.Null()
  end

  -- Native Typst output: pass through as scoped RawBlock, wrapped in crossref if needed
  if quarto.format.is_typst_output() and output_mode == 'asis' then
    if not do_include then
      return pandoc.Null()
    end
    local typst_opts = has_dual_mode_colours(opts)
        and resolve_opts_colours(opts, global_brand_mode)
        or opts
    local preamble = resolve_preamble(typst_opts.preamble)
    local parts = {}
    inject_colour_vars(parts, typst_opts)
    local define_preamble = build_define_preamble()
    if define_preamble then
      parts[#parts + 1] = define_preamble
    end
    if typst_opts.foreground then
      parts[#parts + 1] = '#set text(fill: ' .. typst_opts.foreground .. ')'
    end
    if preamble then
      parts[#parts + 1] = preamble
    end
    parts[#parts + 1] = code
    local inner = table.concat(parts, '\n')
    local scoped_code
    if has_custom_block_options(typst_opts) then
      local params = { 'width: 100%' }
      if typst_opts.margin ~= DEFAULTS.margin then
        params[#params + 1] = 'inset: ' .. typst_opts.margin
      end
      if typst_opts.background ~= DEFAULTS.background then
        params[#params + 1] = 'fill: ' .. typst_opts.background
      end
      scoped_code = '#[\n#block(' .. table.concat(params, ', ') .. ')[\n' .. inner .. '\n]\n]'
    else
      scoped_code = '#[\n' .. inner .. '\n]'
    end
    if opts.align and opts.align ~= 'default' and VALID_ALIGN_SET[opts.align] then
      scoped_code = '#align(' .. opts.align .. ')[\n' .. scoped_code .. '\n]'
    end
    local result = cell.wrap_crossref(pandoc.RawBlock('typst', scoped_code), opts, REF_TYPE_NAMES)
    if do_echo then
      local echo_block = cell.create_echo_block(code, is_fenced, option_lines)
      return pandoc.Blocks({ echo_block, result })
    end
    return result
  end

  -- Determine image format
  local img_format = opts.format
  if img_format and not VALID_FORMAT_SET[img_format] then
    log.log_warning(
      EXTENSION_NAME,
      'Invalid format "' .. img_format .. '"; auto-detecting from output format.'
    )
    img_format = nil
  end
  if not img_format then
    img_format = get_image_format_for_output()
  end

  -- Warn about PDF in HTML
  if img_format == 'pdf' and quarto.format.is_html_output() then
    log.log_warning(
      EXTENSION_NAME,
      'PDF images are not supported in HTML output. Falling back to PNG.'
    )
    img_format = 'png'
  end

  -- Dual-mode rendering for HTML/Reveal.js when both light and dark colours are present
  local dual_mode = quarto.format.is_html_output() and has_dual_mode_colours(opts)

  -- Capture the next block counter value before compilations increment it.
  -- In dual-mode, compile_to_result is called twice, each incrementing block_counter,
  -- but we want the first value for the auto-generated output filename.
  local next_block_counter = block_counter + 1

  local result
  if dual_mode then
    local light_opts = resolve_opts_colours(opts, 'light')
    local dark_opts = resolve_opts_colours(opts, 'dark')
    local light_content, light_pages, light_err = compile_to_result(code, light_opts, img_format)
    local dark_content, dark_pages, dark_err = compile_to_result(code, dark_opts, img_format)

    if not light_content and not dark_content then
      log.log_warning(EXTENSION_NAME, 'Compilation failed; returning error block.')
      if not do_include then
        return pandoc.Null()
      end
      local error_block = create_error_block(light_err or dark_err)
      if do_echo then
        local echo_block = cell.create_echo_block(code, is_fenced, option_lines)
        return pandoc.Blocks({ echo_block, error_block })
      end
      return error_block
    end

    local output_path = resolve_output_path(
      global_config['output-directory'], opts['output-directory'],
      opts['output-filename'], opts.label,
      'typst-block-' .. next_block_counter, img_format
    )

    -- Save to output directory and rebuild elements using output paths
    if output_path then
      if light_pages then
        local out_pages = save_output_files(light_pages, output_path, '-light', img_format)
        if out_pages then
          light_content = wrap_alignment(create_multi_page_element(out_pages, light_opts), light_opts)
        end
      end
      if dark_pages then
        local out_pages = save_output_files(dark_pages, output_path, '-dark', img_format)
        if out_pages then
          dark_content = wrap_alignment(create_multi_page_element(out_pages, dark_opts), dark_opts)
        end
      end
    end

    local blocks = {}
    if light_content then
      blocks[#blocks + 1] = pandoc.Div(
        pandoc.Blocks({ light_content }),
        pandoc.Attr('', { 'light-content' }, {})
      )
    end
    if dark_content then
      blocks[#blocks + 1] = pandoc.Div(
        pandoc.Blocks({ dark_content }),
        pandoc.Attr('', { 'dark-content' }, {})
      )
    end
    result = cell.wrap_crossref(pandoc.Div(blocks), opts, REF_TYPE_NAMES)
  else
    -- Single-mode: resolve colours to brand mode
    local resolved_opts = has_dual_mode_colours(opts)
        and resolve_opts_colours(opts, global_brand_mode)
        or opts
    local content, selected_pages, compile_err = compile_to_result(code, resolved_opts, img_format)

    if not content then
      if compile_err then
        log.log_warning(EXTENSION_NAME, 'Compilation failed; returning error block.')
        if not do_include then
          return pandoc.Null()
        end
        local error_block = create_error_block(compile_err)
        if do_echo then
          local echo_block = cell.create_echo_block(code, is_fenced, option_lines)
          return pandoc.Blocks({ echo_block, error_block })
        end
        return error_block
      end
      log.log_warning(EXTENSION_NAME, 'No pages matched the selection; returning empty block.')
      return pandoc.Null()
    end

    local output_path = resolve_output_path(
      global_config['output-directory'], opts['output-directory'],
      opts['output-filename'], opts.label,
      'typst-block-' .. next_block_counter, img_format
    )

    -- Save to output directory and rebuild element using output paths
    if output_path and selected_pages then
      local out_pages = save_output_files(selected_pages, output_path, nil, img_format)
      if out_pages then
        content = wrap_alignment(create_multi_page_element(out_pages, resolved_opts), resolved_opts)
      end
    end

    result = cell.wrap_crossref(content, opts, REF_TYPE_NAMES)
  end

  -- Compilation and file-save side effects have run; suppress embedding if include is false.
  if not do_include then
    return pandoc.Null()
  end

  local output_location = cell.resolve_output_location(opts, EXTENSION_NAME)
  if output_location then
    local echo_block = do_echo and cell.create_echo_block(code, is_fenced, option_lines) or nil
    return cell.apply_output_location(echo_block, result, output_location)
  end

  if do_echo then
    local echo_block = cell.create_echo_block(code, is_fenced, option_lines)
    return pandoc.Blocks({ echo_block, result })
  end

  return result
end

--- Create a bare inline Image element from a compiled image.
--- Emits format-specific raw markup to size the image to match
--- surrounding text (height: 1em, auto width, vertical centring).
--- @param img_path string Path to the image file
--- @param opts table Merged options
--- @return pandoc.Inline Inline image element
local function create_inline_image_element(img_path, opts)
  if quarto.format.is_typst_output() then
    local escaped_alt = str.escape_typst_string(opts._alt or '')
    return pandoc.RawInline(
      'typst',
      '#box(height: 1.1em, baseline: 20%, image("' .. img_path .. '", alt: "' .. escaped_alt .. '"))'
    )
  end

  if quarto.format.is_latex_output() then
    return pandoc.RawInline(
      'latex',
      '\\raisebox{-0.3em}{\\includegraphics[height=1.3em]{' .. img_path .. '}}'
    )
  end

  if quarto.format.is_docx_output() then
    local img = pandoc.Image(
      { pandoc.Str(opts._alt or '') },
      img_path
    )
    img.attr = pandoc.Attr('', {}, { { 'height', '1em' } })
    return img
  end

  if not quarto.format.is_html_output() then
    return pandoc.Image(
      { pandoc.Str(opts._alt or '') },
      img_path
    )
  end

  local extra_classes = ''
  if type(opts.classes) == 'string' and opts.classes ~= '' then
    extra_classes = ' ' .. opts.classes
  end

  local style
  if quarto.doc.is_format('revealjs') then
    style = 'height: 1.1em; width: auto; vertical-align: -0.55em;'
  else
    style = 'height: 1.15em; width: auto; vertical-align: -0.35em;'
  end

  return pandoc.RawInline(
    'html',
    '<span class="typst-inline' .. extra_classes .. '">'
    .. '<img src="' .. str.escape_attribute(img_path) .. '"'
    .. ' alt="' .. str.escape_attribute(opts._alt or '') .. '"'
    .. ' style="' .. style .. '"'
    .. '></span>'
  )
end

--- Process a {typst} inline Code element.
--- Compiles inline Typst expressions to tightly-cropped images.
--- @param el pandoc.Code
--- @return pandoc.Inline|pandoc.List|nil
local function process_inline_code(el)
  if not cell.is_inline_code(el) then
    return nil
  end

  if quarto.format.is_powerpoint_output() then
    if not pptx_inline_warned then
      pptx_inline_warned = true
      log.log_warning(
        EXTENSION_NAME,
        'Inline Typst is not supported for PowerPoint output; '
        .. 'inline code will be kept as-is.'
      )
    end
    return nil
  end

  local code = cell.inline_code_text(el)
  if not code or code:match('^%s*$') then
    return nil
  end

  local opts = cell.merge_options({}, global_config, DEFAULTS)
  opts.width = 'auto'
  opts.height = 'auto'
  opts.margin = '(x: 0.5pt, top: 0.5pt, bottom: 0.25em)'
  opts._inline = true
  opts._alt = (el.attributes and el.attributes['alt'] and el.attributes['alt'] ~= '')
      and el.attributes['alt']
      or code

  -- Resolve table-valued colours to strings (inline can't do dual-mode rendering)
  if has_dual_mode_colours(opts) then
    opts = resolve_opts_colours(opts, global_brand_mode)
  end

  local output_mode = cell.resolve_output_mode(opts)

  if output_mode == 'false' then
    return {}
  end

  if output_mode == 'asis' then
    return pandoc.RawInline('typst', code)
  end

  local img_format = opts.format
  if img_format and not VALID_FORMAT_SET[img_format] then
    log.log_warning(EXTENSION_NAME, 'Invalid inline format "' .. img_format .. '"; auto-detecting.')
    img_format = nil
  end
  if not img_format then
    img_format = get_image_format_for_output()
  end
  if img_format == 'pdf' and quarto.format.is_html_output() then
    img_format = 'png'
  end

  local full_source = build_typst_source(code, opts)
  local pages, compile_err = compile_typst(full_source, opts, img_format)

  if not pages or #pages == 0 then
    local detail = compile_err and (': ' .. compile_err) or '.'
    log.log_warning(EXTENSION_NAME, 'Inline Typst compilation failed' .. detail)
    return el
  end

  return create_inline_image_element(pages[1], opts)
end

--- Remove stale cache files after all blocks have been processed.
--- Only runs when `cache-refresh` is `true`. Only removes files whose
--- extension matches a format produced during the current render, so an HTML
--- render (producing `.svg`) will not wipe `.png` files from a previous PDF render.
--- @param doc pandoc.Pandoc
--- @return nil
local function cleanup_cache(doc) -- luacheck: ignore 212
  if not global_config['cache-refresh'] or not cache_subdir then
    return nil
  end
  local abs_cache = pandoc.path.join({ quarto.project.directory, cache_subdir })
  local ok, entries = pcall(pandoc.system.list_directory, abs_cache)
  if not ok then
    return nil
  end

  local removed = 0
  for _, filename in ipairs(entries) do
    if filename:match('^typst%-') and not used_cache_files[filename] then
      local ext = filename:match('%.(%w+)$')
      if ext and used_cache_formats[ext] then
        local filepath = pandoc.path.join({ abs_cache, filename })
        local rm_ok, rm_err = os.remove(filepath)
        if rm_ok then
          removed = removed + 1
          log.log_output(EXTENSION_NAME, 'Removed stale cache file: ' .. filename)
        else
          log.log_warning(
            EXTENSION_NAME,
            'Could not remove cache file: ' .. filename .. ' (' .. tostring(rm_err) .. ')'
          )
        end
      end
    end
  end

  if removed > 0 then
    log.log_output(
      EXTENSION_NAME,
      'Cache cleanup: removed ' .. removed .. ' stale file(s).'
    )
  end

  -- Reset typst_define state in case the Lua VM is reused for another document
  -- (e.g. batch render). Each document's payloads must not leak into the next.
  typst_define_dict = {}
  typst_define_order = {}
  typst_define_preamble_cache = nil

  return nil
end

-- ============================================================================
-- FILTER EXPORT
-- ============================================================================

return {
  { Meta = get_configuration },
  { CodeBlock = process_codeblock, Code = process_inline_code },
  { Pandoc = cleanup_cache },
}
