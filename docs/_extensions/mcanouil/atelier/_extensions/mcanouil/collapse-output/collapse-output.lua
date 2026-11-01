--- @module "collapse-output"
--- @license MIT
--- @copyright 2026 Mickaël Canouil
--- @author Mickaël Canouil

--- Extension name constant.
local EXTENSION_NAME = 'collapse-output'

--- Load modules.
local str = require(quarto.utils.resolve_path('_vendor/quarto-lua-modules/string.lua'):gsub('%.lua$', ''))
local log = require(quarto.utils.resolve_path('_vendor/quarto-lua-modules/logging.lua'):gsub('%.lua$', ''))
local meta_mod = require(quarto.utils.resolve_path('_vendor/quarto-lua-modules/metadata.lua'):gsub('%.lua$', ''))
local html_mod = require(quarto.utils.resolve_path('_vendor/quarto-lua-modules/html.lua'):gsub('%.lua$', ''))
local schema = require(quarto.utils.resolve_path('_vendor/quarto-wizard/schema.lua'):gsub('%.lua$', ''))
local check = require(quarto.utils.resolve_path('_vendor/quarto-lua-modules/schema-check.lua'):gsub('%.lua$', ''))

--- The schema check, built once and reused by the whole render. It reads
--- `_schema.yml` on the way in and checks the document configuration once.
---
--- The validator is injected rather than required by the check module, so the
--- two vendored sources stay independent of where the other was placed.
---
--- The extension contributes a filter and no shortcode, so the check runs from
--- the `Meta` handler, which is the only place the document configuration is
--- available.
---
--- A schema that cannot be read is reported by the module as an error and the
--- render carries on: a configuration file must not stop a document.
local checker = check.new(schema, EXTENSION_NAME)

--- Supported output-type identifiers and the Pandoc Div classes they map to.
local OUTPUT_TYPE_CLASSES = {
  stdout = 'cell-output-stdout',
  stderr = 'cell-output-stderr',
  display = 'cell-output-display',
  output = 'cell-output',
}

--- Ordered output-type identifiers (first match wins during detection).
local OUTPUT_TYPE_ORDER = { 'stdout', 'stderr', 'display', 'output' }

--- Default summary text per output type, used when no template/summary is set.
local DEFAULT_TYPE_SUMMARIES = {
  stdout = 'Standard Output',
  stderr = 'Standard Error',
  display = 'Display Output',
  output = 'Code Output',
}

--- Default summary template placeholders.
--- `{type}` resolves to the human label of the matched output type.
--- `{lines}` resolves to the line count of the wrapped block.
local DEFAULT_SUMMARY_TEMPLATE = '{type}'

--- Filter configuration, refreshed at every Meta pass to avoid state bleed
--- across batch renders.
--- @class collapse_config
--- @field method string Rendering method ('lua' or 'javascript').
--- @field collapse_all_outputs boolean Wrap every cell output, regardless of per-cell flag.
--- @field default_open boolean Initial state of the details element.
--- @field auto_collapse_size integer|nil Line threshold above which outputs auto-fold (Lua method).
--- @field output_types table<string, boolean> Set of enabled output-type keys.
--- @field summary_template string Template string for the summary text.
--- @field per_type_summaries table<string, string> Override summaries keyed by output type.
local config = {}

--- Reset the filter configuration to documented defaults.
--- @return nil
local function reset_config()
  config = {
    method = 'lua',
    collapse_all_outputs = false,
    default_open = false,
    auto_collapse_size = nil,
    output_types = {
      stdout = true,
      stderr = true,
      display = true,
      output = true,
    },
    summary_template = DEFAULT_SUMMARY_TEMPLATE,
    per_type_summaries = {},
  }
end

reset_config()

--- Parse a metadata value into a boolean using documented conventions.
--- Deliberately wider than the schema's own boolean coercion, which accepts
--- only 'true'/'false': this parser also accepts 'yes'/'no' and '1'/'0', and
--- stays the source of every boolean value this filter reads, attribute or
--- option, whatever `checker:attributes`/`checker:options` reports about the
--- same value.
--- @param value any Raw metadata value (Pandoc Inlines, boolean, string, nil).
--- @return boolean|nil True/false when parseable, nil when value is empty.
local function parse_boolean(value)
  if value == nil then return nil end
  if type(value) == 'boolean' then return value end
  local text = str.stringify(value)
  if str.is_empty(text) then return nil end
  text = text:lower()
  if text == 'true' or text == 'yes' or text == '1' then return true end
  if text == 'false' or text == 'no' or text == '0' then return false end
  return nil
end

--- Parse a metadata value into a positive integer.
--- Returns nil, silently, when the value is not a positive integer: the
--- schema check (`checker:options`, run from `get_configuration`) already
--- names the same fault for 'auto-collapse-size', the only caller of this
--- function, so no extension-side echo is added here.
--- @param value any Raw metadata value.
--- @return integer|nil Parsed integer, or nil when invalid/empty.
local function parse_positive_integer(value)
  if value == nil then return nil end
  local text = str.stringify(value)
  if str.is_empty(text) then return nil end
  local number = tonumber(text)
  if not number or number < 0 or number ~= math.floor(number) then
    return nil
  end
  return math.floor(number)
end

--- Parse the `output-types` metadata into a set of enabled keys.
--- Accepts a comma-separated string or a YAML list of strings.
--- A YAML list arrives as a Lua table with no `.t` field on this Pandoc
--- version, so `pandoc.utils.type`, which reports 'List' for one and
--- 'Inlines' for a scalar string, is what tells the two apart; the field
--- this function used to test, `.t == 'MetaList'`, is never set here and
--- would leave every YAML list silently mistaken for one unbroken word.
--- @param value any Raw metadata value.
--- @return table<string, boolean>|nil Set of enabled keys, or nil when unset.
local function parse_output_types(value)
  if value == nil then return nil end

  --- @type table<integer, string>
  local items = {}
  if pandoc.utils.type(value) == 'List' then
    for _, item in ipairs(value) do
      local entry = str.stringify(item)
      if not str.is_empty(entry) then
        table.insert(items, entry)
      end
    end
  else
    local text = str.stringify(value)
    if str.is_empty(text) then return nil end
    for item in text:gmatch('[^,%s]+') do
      table.insert(items, item)
    end
  end

  --- @type table<string, boolean>
  local set = {}
  for _, item in ipairs(items) do
    local key = item:lower()
    if OUTPUT_TYPE_CLASSES[key] then
      set[key] = true
    else
      log.log_warning(
        EXTENSION_NAME,
        'Unknown output-type \'' .. item .. '\'. Known types: stdout, stderr, display, output.'
      )
    end
  end

  if next(set) == nil then return nil end
  return set
end

--- Parse the `summaries` mapping into per-type overrides.
--- Accepts a metadata table keyed by output-type name.
--- @param value any Raw metadata value.
--- @return table<string, string> Per-type summary overrides (possibly empty).
local function parse_per_type_summaries(value)
  --- @type table<string, string>
  local result = {}
  if value == nil or type(value) ~= 'table' then return result end
  for key, summary in pairs(value) do
    if type(key) == 'string' and OUTPUT_TYPE_CLASSES[key:lower()] then
      result[key:lower()] = str.stringify(summary)
    end
  end
  return result
end

--- Read filter configuration from document metadata.
--- Checks the document configuration against the schema, resets per-document
--- state, then populates `config` from `extensions.collapse-output`.
--- @param meta table The document metadata table.
--- @return table The metadata table (unchanged).
local function get_configuration(meta)
  if quarto.doc.is_format('html') then
    checker:options(meta)
  end

  reset_config()

  local meta_method = meta_mod.get_metadata_value(meta, EXTENSION_NAME, 'method')
  if not str.is_empty(meta_method) then
    --- @cast meta_method string
    local method = meta_method:lower()
    if method ~= 'lua' and method ~= 'javascript' then
      log.log_warning(
        EXTENSION_NAME,
        'Invalid method \'' .. method .. '\'. Using default \'lua\'.'
      )
      method = 'lua'
    end
    config.method = method
  end

  local raw_config = meta_mod.get_extension_config(meta, EXTENSION_NAME)
  if type(raw_config) == 'table' then
    local collapse_all = parse_boolean(raw_config['collapse-all-outputs'])
    if collapse_all ~= nil then config.collapse_all_outputs = collapse_all end

    local default_open = parse_boolean(raw_config['default-open'])
    if default_open ~= nil then config.default_open = default_open end

    local auto_size = parse_positive_integer(raw_config['auto-collapse-size'])
    if auto_size ~= nil then config.auto_collapse_size = auto_size end

    local output_types = parse_output_types(raw_config['output-types'])
    if output_types ~= nil then config.output_types = output_types end

    local template = raw_config['summary-template']
    if template ~= nil then
      local text = str.stringify(template)
      if not str.is_empty(text) then
        config.summary_template = text
      end
    end

    config.per_type_summaries = parse_per_type_summaries(raw_config['summaries'])
  end

  return meta
end

--- Resolve the output-type key for a Div by inspecting its classes.
--- @param block pandoc.Div The candidate block.
--- @return string|nil The output-type key, or nil if not an output block.
local function detect_output_type(block)
  for _, key in ipairs(OUTPUT_TYPE_ORDER) do
    if block.classes:find(OUTPUT_TYPE_CLASSES[key]) then
      return key
    end
  end
  return nil
end

--- Count the number of textual lines for a block.
--- CodeBlock and RawBlock preserve newlines in their `.text` field; other
--- block kinds fall back to `pandoc.utils.stringify` so each child paragraph
--- is treated as one line.
--- @param block pandoc.Block The block to measure.
--- @return integer Number of lines (minimum 1 for any non-empty content).
local function count_lines(block)
  --- @type string
  local text = ''
  if block.t == 'CodeBlock' or block.t == 'RawBlock' then
    text = block.text or ''
  elseif block.t == 'Div' then
    --- @type table<integer, string>
    local parts = {}
    for _, child in ipairs(block.content) do
      if child.t == 'CodeBlock' or child.t == 'RawBlock' then
        table.insert(parts, child.text or '')
      else
        table.insert(parts, pandoc.utils.stringify(child))
      end
    end
    text = table.concat(parts, '\n')
  else
    text = pandoc.utils.stringify(block)
  end
  if str.is_empty(text) then return 0 end
  --- @type integer
  local lines = 1
  for _ in text:gmatch('\n') do
    lines = lines + 1
  end
  return lines
end

--- Render the summary text using the configured template.
--- Substitutes `{type}` and `{lines}` placeholders.
--- @param output_type string The detected output-type key.
--- @param explicit string|nil The per-cell `output-summary` attribute, when set.
--- @param line_count integer The measured line count for the output.
--- @return string The rendered, HTML-escaped summary text.
local function render_summary(output_type, explicit, line_count)
  if explicit and not str.is_empty(explicit) then
    return str.escape_html(explicit)
  end

  local per_type = config.per_type_summaries[output_type]
  if per_type and not str.is_empty(per_type) then
    return str.escape_html(per_type)
  end

  local label = DEFAULT_TYPE_SUMMARIES[output_type] or DEFAULT_TYPE_SUMMARIES.output
  local rendered = config.summary_template
    :gsub('{type}', label)
    :gsub('{lines}', tostring(line_count))
  return str.escape_html(rendered)
end

--- Decide whether a per-cell directive (or the global toggle) requests folding.
--- Per-cell `output-fold` always wins over `collapse-all-outputs`.
--- @param div pandoc.Div The cell-level Div carrying the directive.
--- @return boolean True when the cell's outputs should be wrapped.
local function should_fold_cell(div)
  local explicit = div.attributes['output-fold']
  if explicit ~= nil and explicit ~= '' then
    local parsed = parse_boolean(explicit)
    if parsed ~= nil then return parsed end
  end
  return config.collapse_all_outputs
end

--- Decide whether a single output block should start expanded.
--- Per-cell `output-open` overrides the document `default-open`.
--- `auto-collapse-size` forces collapsed state for outputs above the threshold.
--- @param div pandoc.Div The cell-level Div carrying the directive.
--- @param line_count integer Line count of the candidate output block.
--- @return boolean True when the details element should be rendered open.
local function should_open(div, line_count)
  if config.auto_collapse_size and line_count >= config.auto_collapse_size then
    return false
  end

  local explicit = div.attributes['output-open']
  if explicit ~= nil and explicit ~= '' then
    local parsed = parse_boolean(explicit)
    if parsed ~= nil then return parsed end
  end

  return config.default_open
end

--- Wrap a cell-output Div in `<details>` elements (server-side rendering).
--- @param div pandoc.Div The parent cell Div whose content is being rewritten.
--- @return pandoc.Div The same Div with wrapped content.
local function wrap_with_details(div)
  --- @type string|nil
  local explicit_summary = div.attributes['output-summary']

  --- @type table
  local new_content = {}

  for _, block in ipairs(div.content) do
    local wrapped = false
    if block.t == 'Div' then
      local output_type = detect_output_type(block)
      if output_type and config.output_types[output_type] then
        local lines = count_lines(block)
        local summary = render_summary(output_type, explicit_summary, lines)
        local open_attr = should_open(div, lines) and ' open' or ''
        table.insert(
          new_content,
          pandoc.RawBlock(
            'html',
            '<details' .. open_attr .. '><summary>' .. summary .. '</summary>'
          )
        )
        table.insert(new_content, block)
        table.insert(new_content, pandoc.RawBlock('html', '</details>'))
        wrapped = true
      end
    end
    if not wrapped then
      table.insert(new_content, block)
    end
  end

  div.content = new_content
  return div
end

--- Inject runtime data attributes consumed by the JavaScript renderer.
--- @param div pandoc.Div The cell-level Div being annotated.
--- @return pandoc.Div The same Div with additional attributes.
local function annotate_for_javascript(div)
  div.attributes['output-fold'] = 'true'
  if config.default_open then
    div.attributes['output-open'] = div.attributes['output-open'] or 'true'
  end
  if config.auto_collapse_size then
    div.attributes['output-auto-collapse'] = tostring(config.auto_collapse_size)
  end
  local enabled_types = {}
  for key, enabled in pairs(config.output_types) do
    if enabled then table.insert(enabled_types, key) end
  end
  table.sort(enabled_types)
  div.attributes['output-types'] = table.concat(enabled_types, ',')
  if config.summary_template ~= DEFAULT_SUMMARY_TEMPLATE then
    div.attributes['output-summary-template'] = config.summary_template
  end
  for key, summary in pairs(config.per_type_summaries) do
    div.attributes['output-summary-' .. key] = summary
  end
  return div
end

--- Process every Quarto cell Div: decide whether to fold and how to render.
--- @param div pandoc.Div The Div element to process.
--- @return pandoc.Div|nil The modified Div, or nil when no changes are needed.
local function process_div(div)
  if not quarto.doc.is_format('html') then
    return nil
  end

  -- Validate this Div's attributes against the `_any` group before any of
  -- them are read below (`should_fold_cell`, `should_open`,
  -- `wrap_with_details`) or written back (`annotate_for_javascript`), so an
  -- invalid value is named once. `output-fold` declares a schema default, so
  -- the merged table this returns carries that default for a Div that never
  -- wrote the attribute; nothing here reads that merged table as a VALUE,
  -- only `parse_boolean` on the raw attribute does, so a Div's own
  -- `collapse-all-outputs` fallback is never shadowed by the schema default.
  checker:attributes(div.attributes, nil)

  if not should_fold_cell(div) then
    return nil
  end

  if config.method == 'javascript' then
    html_mod.ensure_html_dependency({
      name = 'collapse-output',
      version = '1.0.0',
      scripts = {
        { path = 'collapse-output.min.js', afterBody = true }
      }
    })
    return annotate_for_javascript(div)
  end

  return wrap_with_details(div)
end

--- Pandoc filter configuration.
--- Order:
--- 1. Reset and read configuration from metadata.
--- 2. Process Div elements for collapse functionality.
--- @type table
return {
  { Meta = get_configuration },
  { Div = process_div },
}
