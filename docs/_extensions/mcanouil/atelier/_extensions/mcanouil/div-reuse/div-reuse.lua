--- @module "div-reuse"
--- @license MIT
--- @copyright 2026 Mickaël Canouil
--- @author Mickaël Canouil

--- Extension name constant.
local EXTENSION_NAME = 'div-reuse'

--- Load shared modules.
local log = require(quarto.utils.resolve_path('_vendor/quarto-lua-modules/logging.lua'):gsub('%.lua$', ''))
local schema = require(quarto.utils.resolve_path('_vendor/quarto-wizard/schema.lua'):gsub('%.lua$', ''))
local check = require(quarto.utils.resolve_path('_vendor/quarto-lua-modules/schema-check.lua'):gsub('%.lua$', ''))

--- The schema check, built once per render. It reads `_schema.yml` on the way
--- in and checks the document configuration once.
---
--- The validator is injected rather than required by the check module, so the
--- two vendored sources stay independent of where the other was placed.
---
--- The extension contributes a filter and no shortcode, so the check runs from
--- the `Meta` handler, which is the only place the document configuration is
--- read. It reads `extensions.div-reuse`, while this extension also accepts a
--- top-level `div-reuse` key that the check cannot see.
---
--- A schema that cannot be read is reported by the module as an error and the
--- render carries on: a configuration file must not stop a document.
local checker = check.new(schema, EXTENSION_NAME)

--- Storage for div contents indexed by identifier.
--- @type table<string, table>
local div_contents = {}

--- Track reuse chain to detect circular references.
--- @type table<string, boolean>
local reuse_chain = {}

--- Track which div identifiers have already shown the nested-identifier warning.
--- @type table<string, boolean>
local identifier_warning_shown = {}

--- Track which variable names have already shown the unknown-variable warning.
--- @type table<string, boolean>
local variable_warning_shown = {}

--- Track which source ids have already shown the heading-shift clamp warning.
--- @type table<string, boolean>
local shift_warning_shown = {}

--- Track per-source-id reuse counts for the reuse-limit guard.
--- @type table<string, integer>
local reuse_counts = {}

--- Document-level reuse limit. nil means unlimited. Reset in Meta.
--- @type integer|nil
local document_reuse_limit = nil

--- Track whether the limit-reached warning has been emitted for a given id.
--- @type table<string, boolean>
local limit_warning_shown = {}

--- Reset all per-document module-level state.
--- Prevents state leakage across documents in batch renders.
local function reset_state()
  div_contents = {}
  reuse_chain = {}
  identifier_warning_shown = {}
  variable_warning_shown = {}
  shift_warning_shown = {}
  reuse_counts = {}
  limit_warning_shown = {}
  document_reuse_limit = nil
end

--- Convert any metadata value to a plain string for variable substitution.
--- @param value any The metadata value (string, MetaInlines, MetaBlocks, number, boolean)
--- @return string The stringified value
local function stringify_meta_value(value)
  if value == nil then return '' end
  if type(value) == 'string' then return value end
  if type(value) == 'number' or type(value) == 'boolean' then
    return tostring(value)
  end
  return pandoc.utils.stringify(value)
end

--- Resolve a dotted variable path against a metadata-like table.
--- Returns nil if any path segment is missing.
--- @param vars table The variables table (typically from document metadata)
--- @param path string Dotted key path (e.g. "user.name").
--- @return any|nil The resolved value or nil
local function resolve_variable(vars, path)
  if vars == nil then return nil end
  local current = vars
  for segment in path:gmatch('[^%.]+') do
    if type(current) ~= 'table' then return nil end
    current = current[segment]
    if current == nil then return nil end
  end
  return current
end

--- Parse the reuse-filter attribute value into a structured options table.
--- Syntax: comma-separated key=value pairs, for example:
---   "shift-headings=1,take=2,id-remap=fig-a->fig-b;fig-c->fig-d".
--- @param raw string|nil Raw attribute value
--- @return table options Parsed options with fields shift_headings, take, id_remap
local function parse_filter_attribute(raw)
  --- @type table
  local options = {
    shift_headings = nil,
    take = nil,
    id_remap = {},
  }
  if raw == nil or raw == '' then return options end
  for pair in tostring(raw):gmatch('[^,]+') do
    local key, value = pair:match('^%s*([^=%s]+)%s*=%s*(.-)%s*$')
    if key and value then
      if key == 'shift-headings' then
        options.shift_headings = tonumber(value)
      elseif key == 'take' then
        options.take = tonumber(value)
      elseif key == 'id-remap' then
        for mapping in value:gmatch('[^;]+') do
          local arrow_start, arrow_end = mapping:find('->', 1, true)
          if arrow_start ~= nil then
            local old_id = mapping:sub(1, arrow_start - 1):match('^%s*(.-)%s*$')
            local new_id = mapping:sub(arrow_end + 1):match('^%s*(.-)%s*$')
            if old_id ~= nil and old_id ~= '' and new_id ~= nil and new_id ~= '' then
              options.id_remap[old_id] = new_id
            end
          end
        end
      end
    end
  end
  return options
end

--- Deep-clone an array of blocks.
--- @param blocks table Array of Pandoc blocks
--- @return table A list of cloned blocks
local function clone_blocks(blocks)
  local cloned = {}
  for _, block in ipairs(blocks) do
    if type(block) == 'table' and block.clone then
      table.insert(cloned, block:clone())
    else
      table.insert(cloned, block)
    end
  end
  return cloned
end

--- Substitute `{{name}}` tokens within a single Str element's text.
--- Dotted names (`{{a.b}}`) are resolved as nested metadata keys.
--- Unknown names are left literal with a one-shot warning.
--- @param text string The Str text
--- @param variables table Variables table (typically document metadata)
--- @return string|nil The replaced text, or nil when nothing changed
local function substitute_str_text(text, variables)
  if not text:find('{{') then return nil end
  local changed = false
  local replaced = text:gsub('{{%s*([%w_%-%.]+)%s*}}', function(name)
    local value = resolve_variable(variables, name)
    if value == nil then
      if not variable_warning_shown[name] then
        variable_warning_shown[name] = true
        log.log_warning(
          EXTENSION_NAME,
          'Variable "' .. name .. '" is not defined in metadata; leaving token literal.'
        )
      end
      return '{{' .. name .. '}}'
    end
    changed = true
    return stringify_meta_value(value)
  end)
  if not changed then return nil end
  return replaced
end

--- Walk a content list to perform variable substitution on Str and Code inlines
--- as well as RawBlock and CodeBlock contents.
--- @param content table Array of Pandoc blocks
--- @param variables table Variables table (typically document metadata)
--- @return table The walked content
local function apply_variable_substitution(content, variables)
  if variables == nil then return content end
  --- Mutate `el.text` in place when a substitution occurs; return el on change, nil otherwise.
  local function substitute_text_field(el)
    local replaced = substitute_str_text(el.text, variables)
    if replaced == nil then return nil end
    el.text = replaced
    return el
  end
  return pandoc.Blocks(content):walk({
    Str = function(str)
      local replaced = substitute_str_text(str.text, variables)
      if replaced == nil then return nil end
      return pandoc.Str(replaced)
    end,
    Code = substitute_text_field,
    CodeBlock = substitute_text_field,
    RawInline = substitute_text_field,
    RawBlock = substitute_text_field,
  })
end

--- Apply heading-level shift to all Header elements in the content.
--- Clamps the resulting level to the [1, 6] range with a warning when clamping occurs.
--- @param content table Array of Pandoc blocks
--- @param shift integer The level delta (positive deepens, negative promotes)
--- @param ref_id string The source identifier used for warning context
--- @return table The walked content
local function apply_heading_shift(content, shift, ref_id)
  if shift == nil or shift == 0 then return content end
  return pandoc.Blocks(content):walk({
    Header = function(header)
      local new_level = header.level + shift
      if new_level < 1 or new_level > 6 then
        if not shift_warning_shown[ref_id] then
          shift_warning_shown[ref_id] = true
          log.log_warning(
            EXTENSION_NAME,
            'Heading shift for reuse of "' .. ref_id ..
            '" clamped to the [1, 6] range.'
          )
        end
        new_level = math.max(1, math.min(6, new_level))
      end
      header.level = new_level
      return header
    end,
  })
end

--- Apply identifier remapping to Div, Span and Header elements in the content.
--- @param content table Array of Pandoc blocks
--- @param mapping table<string, string> old to new identifier mapping
--- @return table The walked content
local function apply_id_remap(content, mapping)
  if next(mapping) == nil then return content end
  return pandoc.Blocks(content):walk({
    Div = function(div)
      local new_id = mapping[div.identifier]
      if new_id then div.identifier = new_id end
      return div
    end,
    Span = function(span)
      local new_id = mapping[span.identifier]
      if new_id then span.identifier = new_id end
      return span
    end,
    Header = function(header)
      local new_id = mapping[header.identifier]
      if new_id then header.identifier = new_id end
      return header
    end,
  })
end

--- Take only the first `n` blocks from a content list.
--- Negative or zero `n` returns the empty list with a warning.
--- @param content table Array of Pandoc blocks
--- @param n integer The number of leading blocks to keep
--- @param ref_id string The source identifier used for warning context
--- @return table The trimmed content
local function apply_take(content, n, ref_id)
  if n == nil then return content end
  if n <= 0 then
    log.log_warning(
      EXTENSION_NAME,
      'take=' .. tostring(n) .. ' on reuse of "' .. ref_id .. '" yields no content.'
    )
    return {}
  end
  if n >= #content then return content end
  local trimmed = {}
  for i = 1, n do
    table.insert(trimmed, content[i])
  end
  return trimmed
end

--- Collect divs with identifiers for later reuse.
--- Stores div content in the div_contents table indexed by the div's identifier.
---
--- @param el pandoc.Div The div element to collect
--- @return pandoc.Div The unchanged div element
local function collect_divs(el)
  if el.identifier ~= '' then
    div_contents[el.identifier] = el.content
  end
  return el
end

--- Collect the identifiers of divs within content.
--- Recursively searches through content and records every identifier found, so
--- a reused copy can be compared against its source.
---
--- @param content table Array of pandoc elements to search through
--- @param found table|nil Accumulator, keyed by identifier
--- @return table Set of identifiers found in the content
local function collect_identifiers(content, found)
  found = found or {}
  for _, inner_el in ipairs(content) do
    if inner_el.t == 'Div' and inner_el.identifier ~= '' then
      found[inner_el.identifier] = true
    end
    if inner_el.content then
      collect_identifiers(inner_el.content, found)
    end
  end
  return found
end

--- Look up a key inside the `div-reuse` metadata namespace.
--- Accepts either `div-reuse.<key>` or `extensions.div-reuse.<key>`.
--- @param meta table Document metadata
--- @param key string The key inside the namespace
--- @return any|nil The raw metadata value or nil when unset
local function read_namespace_key(meta, key)
  if meta['div-reuse'] and meta['div-reuse'][key] ~= nil then
    return meta['div-reuse'][key]
  end
  if meta.extensions and meta.extensions[EXTENSION_NAME]
      and meta.extensions[EXTENSION_NAME][key] ~= nil then
    return meta.extensions[EXTENSION_NAME][key]
  end
  return nil
end

--- Read the document-level reuse limit from metadata.
--- @param meta table Document metadata
--- @return integer|nil The numeric limit or nil when unset
local function read_reuse_limit(meta)
  local raw = read_namespace_key(meta, 'limit')
  if raw == nil then return nil end
  local value = tonumber(pandoc.utils.stringify(raw))
  if value == nil or value < 0 then
    log.log_warning(
      EXTENSION_NAME,
      'Invalid reuse limit "' .. tostring(pandoc.utils.stringify(raw)) ..
      '"; ignoring.'
    )
    return nil
  end
  return math.floor(value)
end

--- Document-level variables namespace for `{{variable}}` substitution.
--- @type table|nil
local document_variables = nil

--- Resolve the variables table for the current document.
--- @param meta table Document metadata
--- @return table|nil The variables table or nil when unset
local function read_variables(meta)
  return read_namespace_key(meta, 'vars')
end

--- Meta pass: reset state and read configuration.
--- @param meta table Document metadata
--- @return table The unchanged metadata
local function read_meta(meta)
  reset_state()
  checker:options(meta)
  document_reuse_limit = read_reuse_limit(meta)
  document_variables = read_variables(meta)
  return meta
end

--- Replace div content with content from a referenced div.
--- If a div has a "reuse" attribute, replaces its content with the content
--- from the div identified by that attribute. Warns if the reused content
--- contains divs with identifiers, as this may cause issues. Detects and prevents
--- circular references. Honours reuse-filter, take, and id-remap attributes,
--- applies variable substitution from metadata, and enforces the document-level
--- reuse limit.
---
--- @param el pandoc.Div The div element to potentially replace
--- @return pandoc.Div The div with replaced content or the original div
local function replace_divs(el)
  --- @type table<string, any> The div's own attributes, resolved against the schema
  local resolved = checker:attributes(el.attributes, nil) or {}
  if not resolved['reuse'] then return el end

  --- @type string The identifier of the div to reuse
  local ref_id = resolved['reuse']

  if reuse_chain[ref_id] then
    log.log_warning(
      EXTENSION_NAME,
      'Circular reference detected: Div "' .. ref_id ..
      '" is already in the reuse chain. Skipping to prevent infinite loop.'
    )
    return el
  end

  if not div_contents[ref_id] then return el end

  reuse_counts[ref_id] = (reuse_counts[ref_id] or 0) + 1
  if document_reuse_limit ~= nil and reuse_counts[ref_id] > document_reuse_limit then
    if not limit_warning_shown[ref_id] then
      limit_warning_shown[ref_id] = true
      log.log_warning(
        EXTENSION_NAME,
        'Reuse limit (' .. tostring(document_reuse_limit) ..
        ') reached for "' .. ref_id .. '"; subsequent reuses are skipped.'
      )
    end
    return el
  end

  reuse_chain[ref_id] = true

  --- @type table Cloned content to avoid mutating the source
  local content = clone_blocks(div_contents[ref_id])

  --- @type table Parsed reuse-filter options
  local filter_options = parse_filter_attribute(resolved['reuse-filter'])

  --- @type any Raw value read for reuse-take, whatever type it resolved to
  local take_value = resolved['reuse-take']

  --- @type integer|nil Take override from the dedicated attribute
  --- A value the schema rejects comes back as the string the document wrote,
  --- not as nil, so the type must be checked rather than relying on tonumber.
  local take_attr = type(take_value) == 'number' and take_value or nil
  if take_attr ~= nil then filter_options.take = take_attr end

  if filter_options.take ~= nil then
    content = apply_take(content, filter_options.take, ref_id)
  end
  if filter_options.shift_headings ~= nil then
    content = apply_heading_shift(content, filter_options.shift_headings, ref_id)
  end
  if next(filter_options.id_remap) ~= nil then
    content = apply_id_remap(content, filter_options.id_remap)
  end
  if document_variables ~= nil then
    content = apply_variable_substitution(content, document_variables)
  end

  el.content = content

  -- The source div stays in the document, so an identifier that survives into
  -- the copy unchanged now appears twice. One that `id-remap` renamed does not,
  -- which is the whole point of the attribute, so it is not reported.
  --- @type table Identifiers the source carries
  local source_identifiers = collect_identifiers(div_contents[ref_id])
  --- @type table Identifiers now present in both the source and the copy
  local duplicated = {}
  for identifier in pairs(collect_identifiers(el.content)) do
    if source_identifiers[identifier] then
      table.insert(duplicated, identifier)
    end
  end

  if #duplicated > 0 and not identifier_warning_shown[ref_id] then
    identifier_warning_shown[ref_id] = true
    table.sort(duplicated)
    log.log_warning(
      EXTENSION_NAME,
      'Div "' .. ref_id .. '" has been reused and duplicates ' .. #duplicated ..
      ' identifier(s): "' .. table.concat(duplicated, '", "') .. '". ' ..
      'Use reuse-filter="id-remap=old->new" to rename them in the copy.'
    )
  end

  reuse_chain[ref_id] = nil
  return el
end

--- Pandoc filter configuration.
--- Defines a three-pass filter:
--- 1. Meta pass resets per-document state and reads configuration.
--- 2. First Div pass collects all divs with identifiers.
--- 3. Second Div pass replaces divs with reuse attributes.
--- @type table
return {
  { Meta = read_meta },
  { Div = collect_divs },
  { Div = replace_divs },
}
