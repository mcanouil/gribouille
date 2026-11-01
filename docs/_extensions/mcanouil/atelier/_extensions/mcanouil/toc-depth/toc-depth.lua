--- @module "toc-depth"
--- @license MIT
--- @copyright 2026 Mickaël Canouil
--- @author Mickaël Canouil

--- Extension name used as a prefix in log messages
local EXTENSION_NAME = 'toc-depth'

--- Load modules
local pdoc = require(quarto.utils.resolve_path('_vendor/quarto-lua-modules/pandoc-helpers.lua'):gsub('%.lua$', ''))
local logging = require(quarto.utils.resolve_path('_vendor/quarto-lua-modules/logging.lua'):gsub('%.lua$', ''))
local schema = require(quarto.utils.resolve_path('_vendor/quarto-wizard/schema.lua'):gsub('%.lua$', ''))
local check = require(quarto.utils.resolve_path('_vendor/quarto-lua-modules/schema-check.lua'):gsub('%.lua$', ''))

--- The schema check, built once for the whole render. It reads `_schema.yml` on
--- the way in and checks the document configuration against it once.
---
--- The validator is injected rather than required by the check module, so the
--- two vendored sources stay independent of where the other was placed.
---
--- The extension contributes a filter and no shortcodes, so the check runs from
--- the `Meta` handler, after the per-document state reset and before the first
--- option is read. There is no call to check.
---
--- A schema that cannot be read is reported by the module as an error and the
--- render carries on: a configuration file must not stop a document.
local checker = check.new(schema, EXTENSION_NAME)

--- @type boolean Flag indicating if we're currently processing children of a header with toc-depth
local is_parent = false

--- @type number|nil The level of the header that has the toc-depth attribute
local reference_level = nil

--- @type number The current toc-depth value being applied
local current_toc_depth = 1

--- @type number|nil The document-wide default toc-depth applied to headers without an explicit attribute
local default_toc_depth = nil


--- Reset module-level cascade state.
--- Quarto can render multiple documents in one process; without an explicit reset
--- the cascade flags from a previous document would leak into the next render.
local function reset_state()
  is_parent = false
  reference_level = nil
  current_toc_depth = 1
  default_toc_depth = nil
end

--- Add a class to the class list if it doesn't already exist
--- @param classes table List of CSS classes
--- @param name string The class name to add
local function add_class(classes, name)
  pdoc.add_class(classes, name)
end

--- Clamp a resolved toc-depth into the range the schema declares.
--- The checker reports a value below the minimum by name, so this applies the
--- clamp and says nothing. Two messages for one mistake helps nobody.
--- @param value number|nil A resolved toc-depth
--- @return number|nil The value, clamped to 0 when negative
local function clamp_toc_depth(value)
  if value == nil then
    return nil
  end
  if value < 0 then
    return 0
  end
  return value
end

--- Extract the toc-depth value from an element's resolved attributes.
--- The schema declares an integer, and the validator hands back a number when
--- the document wrote one. A value it rejects arrives as the text the document
--- wrote, and the checker has already named it, so it is ignored here rather
--- than applied. `toc-depth="1.5"` used to be applied as 1.5 while the same
--- document was told the value was invalid.
--- @param attributes table|nil Resolved element attributes
--- @return number|nil The toc-depth value when the schema accepted one
local function get_toc_depth_from_attributes(attributes)
  local value = attributes and attributes['toc-depth']
  if type(value) ~= 'number' then
    return nil
  end
  return clamp_toc_depth(value)
end

--- Read the document-wide default toc-depth from metadata and reset per-document state
--- @param meta table Document metadata table
--- @return table The unchanged document metadata table
--- @description Resets module-level cascade state so a fresh render does not inherit
--- state from a previous document in the same Quarto process, checks the document
--- configuration against the extension schema, then reads the integer option
--- extensions.toc-depth.default and stores it as the fallback toc-depth for
--- headers without an explicit toc-depth attribute. Negative values are clamped to 0
--- with a warning.
local function get_toc_depth_meta(meta)
  reset_state()
  checker:options(meta)
  -- The schema decides the option, and reports a value it does not accept, so
  -- a non-integer is ignored here rather than warned about a second time.
  local resolved = checker:option('default')
  if type(resolved) == 'number' then
    default_toc_depth = clamp_toc_depth(resolved)
  end
  return meta
end

--- Process a header element to apply toc-depth filtering
--- @param elem table Pandoc Header element with properties: level, attributes, classes
--- @return table|nil The modified header element or nil if no changes needed
--- @description This function handles two scenarios:
--- 1. If the header has a toc-depth attribute, it becomes a "parent" and sets the reference
--- 2. If we're processing children of a parent header, it applies the toc-depth rules
--- An explicit toc-depth attribute always overrides the document-wide default.
--- When toc-depth is 0, the header is hidden from the TOC and unnumbered.
local function process_header(elem)
  local toc_depth = get_toc_depth_from_attributes(checker:attributes(elem.attributes, 'Header'))

  if is_parent and not toc_depth and elem.level <= reference_level then
    is_parent = false
    reference_level = nil
  end

  if not toc_depth and not is_parent then
    toc_depth = default_toc_depth
  end

  if toc_depth then
    is_parent = true
    reference_level = elem.level
    current_toc_depth = toc_depth
    if current_toc_depth == 0 then
      add_class(elem.classes, 'unlisted')
      add_class(elem.classes, 'unnumbered')
    end
    return elem
  end

  if is_parent then
    if elem.level > reference_level then
      local relative_depth = elem.level - reference_level
      if relative_depth >= current_toc_depth then
        add_class(elem.classes, 'unlisted')
        add_class(elem.classes, 'unnumbered')
      end
      return elem
    end
  end

  return nil
end

--- Pandoc filter configuration
--- @return table Filter configuration with Meta and Header walker functions
--- @description Returns a Pandoc filter that resets per-document state and reads the
--- document-wide default depth, then processes Header elements to apply custom toc-depth
--- behaviour based on the toc-depth attribute, falling back to the document default when
--- no attribute is set.
return {
  { Meta = get_toc_depth_meta },
  { Header = process_header }
}
