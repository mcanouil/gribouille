--- @module "modal-filter"
--- @license MIT
--- @copyright 2026 Mickaël Canouil
--- @author Mickaël Canouil

--- Extension name constant
local EXTENSION_NAME = "modal"

--- Load modules
local str = require(quarto.utils.resolve_path('_vendor/quarto-lua-modules/string.lua'):gsub('%.lua$', ''))
local log = require(quarto.utils.resolve_path('_vendor/quarto-lua-modules/logging.lua'):gsub('%.lua$', ''))
local meta_mod = require(quarto.utils.resolve_path('_vendor/quarto-lua-modules/metadata.lua'):gsub('%.lua$', ''))
local pdoc = require(quarto.utils.resolve_path('_vendor/quarto-lua-modules/pandoc-helpers.lua'):gsub('%.lua$', ''))
local html_mod = require(quarto.utils.resolve_path('_vendor/quarto-lua-modules/html.lua'):gsub('%.lua$', ''))

--- Load content-extraction module
local content = require(quarto.utils.resolve_path('_vendor/quarto-lua-modules/content-extraction.lua'):gsub('%.lua$', ''))

local schema = require(quarto.utils.resolve_path('_vendor/quarto-wizard/schema.lua'):gsub('%.lua$', ''))
local check = require(quarto.utils.resolve_path('_vendor/quarto-lua-modules/schema-check.lua'):gsub('%.lua$', ''))

--- The schema check, built once for this filter. It reads `_schema.yml` on the
--- way in and checks the document configuration against it.
---
--- The validator is injected rather than required by the check module, so the
--- two vendored sources stay independent of where the other was placed.
---
--- The extension contributes a filter and a shortcode, and each entry point
--- builds its own checker. The document configuration is checked here, from the
--- `Meta` handler, which runs before the shortcodes expand at the `pre-quarto`
--- stage. Each shortcode call is checked in `modal-shortcode.lua`.
---
--- A schema that cannot be read is reported by the module as an error and the
--- render carries on: a configuration file must not stop a document.
local checker = check.new(schema, EXTENSION_NAME)

--- Generate unique modal ID
local modal_count = 0
local function unique_modal_id()
  modal_count = modal_count + 1
  return 'quarto-modal-' .. tostring(modal_count)
end

--- Modal settings default values.
--- @type table<string, string>
local modal_settings_meta = {
  ["size"] = "",
  ["backdrop-static"] = "false",
  ["scrollable"] = "false",
  ["keyboard"] = "true",
  ["centred"] = "false",
  ["fade"] = "false",
  ["fullscreen"] = "false"
}

--- Friendly size presets that map to Bootstrap sizes.
--- Empty string keeps Bootstrap's default 500px width.
--- @type table<string, string>
local SIZE_PRESETS = {
  ["small"] = "sm",
  ["sm"] = "sm",
  ["medium"] = "",
  ["default"] = "",
  [""] = "",
  ["large"] = "lg",
  ["lg"] = "lg",
  ["extra-large"] = "xl",
  ["xlarge"] = "xl",
  ["xl"] = "xl"
}

--- Valid fullscreen breakpoint values, excluding boolean strings.
--- @type table<string, boolean>
local FULLSCREEN_BREAKPOINTS = {
  ["sm"] = true,
  ["md"] = true,
  ["lg"] = true,
  ["xl"] = true,
  ["xxl"] = true
}

--- Attribute names that mark a Div as intended to be a modal.
--- Used to detect Divs with modal-specific configuration but an
--- identifier missing the required ``modal-`` prefix.
--- @type table<integer, string>
local MODAL_ATTRIBUTE_HINTS = {
  "size",
  "backdrop-static",
  "scrollable",
  "keyboard",
  "centred",
  "centered",
  "fade",
  "fullscreen",
  "description",
  "close-button",
  "close-button-label"
}

--- Set of identifiers present anywhere in the document.
--- Populated during the Pandoc pass before Div processing.
--- @type table<string, boolean>
local document_ids = {}

--- Get modal option from metadata.
--- @param key string The option name to retrieve.
--- @param meta table<string, any> Document metadata table.
--- @return string The option value as a string.
local function get_modal_option(key, meta)
  local meta_value = meta_mod.get_metadata_value(meta, 'modal', key)
  if not str.is_empty(meta_value) then
    return meta_value
  end

  return modal_settings_meta[key] or ''
end

--- Resolve a user-supplied size value to a Bootstrap size token.
--- Accepts both raw Bootstrap tokens (``sm``/``lg``/``xl``) and friendly
--- aliases (``small``/``large``/``extra-large``).
--- Returns the empty default when the value is unknown. The schema check
--- names an unknown value by itself, so this stays quiet and only applies
--- the fallback; reporting it here too would name the same mistake twice.
--- @param value string|nil User-supplied size value.
--- @return string Resolved Bootstrap size token (one of "", "sm", "lg", "xl").
local function resolve_size(value)
  if value == nil or value == '' then
    return ''
  end
  local normalised = value:lower()
  local resolved = SIZE_PRESETS[normalised]
  if resolved == nil then
    return ''
  end
  return resolved
end

--- Fold a schema-resolved attribute back to the string form the rest of
--- this filter compares against.
---
--- The schema declares ``backdrop-static``, ``scrollable`` and ``keyboard``
--- as booleans, so a value the document wrote and the schema accepted comes
--- back as a real Lua boolean, not the string ``"true"``/``"false"`` that a
--- Pandoc attribute always is. A bare ``or`` fallback would then treat an
--- explicit ``false`` as unset, because ``false`` is the one non-nil value
--- Lua's ``or`` still falls through. This stringifies a boolean so the
--- explicit value survives, passes an invalid value through unchanged (the
--- schema has already named it), and only falls back when the document did
--- not write the attribute at all.
--- @param value boolean|string|nil Schema-resolved attribute value.
--- @param fallback string The document option to use when unset.
--- @return string
local function resolved_flag(value, fallback)
  if value == nil then
    return fallback
  end
  if type(value) == 'boolean' then
    return tostring(value)
  end
  return value
end

--- Read a schema-resolved string attribute, guarding its Lua type.
--- `fullscreen` is declared `type: string`, so a value the document wrote
--- stays a string whether the schema accepts or rejects it; nothing here
--- coerces it to another type. The guard exists so that a value of any
--- other type, however it might arrive, cannot flow into the string-only
--- comparisons this filter makes against it.
--- @param value any Schema-resolved attribute value.
--- @param fallback string The document option to use when unset or wrong-typed.
--- @return string
local function resolved_string(value, fallback)
  if value == nil or type(value) ~= 'string' then
    return fallback
  end
  return value
end

--- Collect every identifier appearing anywhere in the document.
--- Walks Pandoc blocks and inlines exactly once so later validations
--- (e.g. ``description`` references) can resolve targets cheaply.
--- @param doc table Pandoc Pandoc element.
local function collect_document_ids(doc)
  document_ids = {}
  local function record(el)
    if el.identifier and el.identifier ~= '' then
      document_ids[el.identifier] = true
    end
  end
  pandoc.walk_block(pandoc.Div(doc.blocks), {
    Div = record,
    Header = record,
    Span = record,
    Link = record,
    Image = record,
    CodeBlock = record,
    Table = record
  })
end

--- Extract and configure modal settings from document metadata.
---
--- @param doc table Pandoc Pandoc element.
--- @return table Updated Pandoc Pandoc element.
local function get_modal_meta(doc)
  local meta = doc.meta
  local modal_options = {}
  for key, _ in pairs(modal_settings_meta) do
    modal_options[key] = get_modal_option(key, meta)
  end
  meta['extensions'] = meta['extensions'] or {}
  meta['extensions']['modal'] = {}
  for key, value in pairs(modal_options) do
    if modal_settings_meta[key] ~= nil then
      meta['extensions']['modal'][key] = value
    end
  end
  modal_settings_meta = meta['extensions']['modal']
  doc.meta = meta
  collect_document_ids(doc)
  return doc
end

--- Check whether a Div carries any attribute that suggests it was meant
--- to be a modal but is missing the ``modal-`` identifier prefix.
--- @param el table Pandoc Div element.
--- @return boolean True if any modal-specific attribute is set.
local function has_modal_attributes(el)
  if not el.attributes then return false end
  for _, attr_name in ipairs(MODAL_ATTRIBUTE_HINTS) do
    local value = el.attributes[attr_name]
    if value ~= nil and value ~= '' then
      return true
    end
  end
  return false
end

--- Detect modal Divs nested inside the supplied blocks and warn.
--- HTML and Bootstrap do not support nesting modals; nested modals are
--- almost always a markup mistake and lead to focus and backdrop issues.
--- @param blocks table<integer, table> Blocks to scan.
--- @param parent_id string Identifier of the enclosing modal.
local function warn_on_nested_modals(blocks, parent_id)
  if blocks == nil then return end
  pandoc.walk_block(pandoc.Div(blocks), {
    Div = function(child)
      if child.identifier and child.identifier:match('^modal%-') then
        log.log_warning(
          EXTENSION_NAME,
          "Modal '" .. parent_id .. "' contains nested modal '" .. child.identifier .. "'. " ..
          "Bootstrap does not support modal nesting; please move the nested modal out of its parent."
        )
      end
    end
  })
end

--- Process Divs whose identifier starts with ``modal-``.
--- Invoked by Pandoc on every Div; returns ``nil`` (leaving the Div
--- untouched) when the Div is not a modal container or when the active
--- format does not support Bootstrap modals.
---
--- @param el table Pandoc Div element.
--- @return table|nil Pandoc Div structure for a modal, or nil if not applicable.
local function modal(el)
  if not quarto.doc.is_format("html:js") or not quarto.doc.has_bootstrap() then
    return nil
  end

  local has_modal_prefix = el.identifier:match("^modal%-") ~= nil
  if not has_modal_prefix then
    if has_modal_attributes(el) then
      log.log_warning(
        EXTENSION_NAME,
        "Div '" .. (el.identifier ~= '' and el.identifier or '(no id)') ..
        "' carries modal-specific attributes but its identifier does not start with 'modal-'. " ..
        "Modal Divs must use an identifier like '#modal-my-id'."
      )
    end
    return nil
  end

  quarto.doc.add_html_dependency({
    name = "modal-clipboard",
    version = '1.0.0',
    scripts = {
      { path = "modal-clipboard.min.js", afterBody = true }
    }
  })

  local modal_id = el.identifier ~= '' and el.identifier or unique_modal_id()

  local resolved = checker:attributes(el.attributes, 'modal')
  local raw_size = resolved.size or modal_settings_meta["size"]
  local modal_size = resolve_size(raw_size)
  local modal_backdrop_static = resolved_flag(resolved["backdrop-static"], modal_settings_meta["backdrop-static"])
  local modal_scrollable = resolved_flag(resolved.scrollable, modal_settings_meta["scrollable"])
  local modal_keyboard = resolved_flag(resolved.keyboard, modal_settings_meta["keyboard"])
  -- `centred` declares `aliases: [centered]` in the schema, and this
  -- extension's own attribute list names `centered` too, so both advertise
  -- the spelling. The merge inside `checker:attributes` moves a
  -- document-written `centered` onto `resolved.centred`, with the declared
  -- spelling winning when both are written (the schema check already names
  -- that conflict), and always empties `resolved.centered`.
  --
  -- Testing presence on `centred` alone previously carried forward a
  -- pre-existing bug: `centered` written by itself was never honoured,
  -- because `modal_settings_meta["centred"]` is never a falsy Lua value, so
  -- the old `el.attributes.centred or modal_settings_meta["centred"]`
  -- fallback chain could never reach `centered`. Testing presence on either
  -- spelling fixes that: `resolved.centred` already carries the correctly
  -- precedenced value once either was written, so this changes only the
  -- "centered alone" case and leaves "centred alone", "both written" and
  -- "neither written" exactly as they were.
  local modal_centred = modal_settings_meta["centred"]
  if el.attributes.centred ~= nil or el.attributes.centered ~= nil then
    modal_centred = resolved_flag(resolved.centred, modal_settings_meta["centred"])
  end
  local modal_fade = resolved_flag(resolved.fade, modal_settings_meta["fade"])
  local modal_fullscreen = resolved_string(resolved.fullscreen, modal_settings_meta["fullscreen"])

  local dialog_classes = { 'modal-dialog' }
  if modal_size ~= '' then table.insert(dialog_classes, 'modal-' .. modal_size) end
  if modal_scrollable == 'true' then table.insert(dialog_classes, 'modal-dialog-scrollable') end
  if modal_centred == 'true' then table.insert(dialog_classes, 'modal-dialog-centered') end
  -- An unknown value falls back to no fullscreen; the schema check already
  -- names the same mistake, so this stays quiet and only applies the
  -- fallback.
  if modal_fullscreen == 'true' then
    table.insert(dialog_classes, 'modal-fullscreen')
  elseif modal_fullscreen and FULLSCREEN_BREAKPOINTS[modal_fullscreen] then
    table.insert(dialog_classes, 'modal-fullscreen-' .. modal_fullscreen .. '-down')
  end

  --- Parse modal sections
  local parsed = content.parse_sections(el.content)
  local header_text = parsed.header_text
  local header_level = parsed.header_level
  local body_blocks = parsed.body_blocks
  local footer_blocks = parsed.footer_blocks

  warn_on_nested_modals(body_blocks, modal_id)
  warn_on_nested_modals(footer_blocks, modal_id)

  local modal_header_id = header_text and str.ascii_id(header_text) or "modal-title"

  --- Optional close button in the header (Bootstrap-rendered "x").
  --- ``close-button=false`` suppresses it; ``close-button-label`` overrides
  --- the default aria-label (useful for localisation).
  --- Both declare a `default:` in the schema's `modal` attribute group, so
  --- the resolved table already carries the same value (`true`, `"Close"`)
  --- as the literal fallbacks below when the document wrote nothing.
  local close_button_attr = resolved_flag(resolved['close-button'], 'true')
  local include_close_button = close_button_attr ~= 'false'
  local close_button_label = resolved_flag(resolved['close-button-label'], 'Close')

  local header_html = html_mod.raw_header(
    header_level,
    header_text,
    modal_header_id,
    { 'modal-title' },
    nil
  )
  if include_close_button then
    header_html = header_html ..
        '\n' ..
        '<button type="button" class="btn-close" data-bs-dismiss="modal" aria-label="' ..
        str.escape_attribute(close_button_label) .. '"></button>'
  end
  local modal_header = pandoc.Div({ pandoc.RawBlock('html', header_html) }, pdoc.attr('', { 'modal-header' }))

  local modal_content = { modal_header }
  if #body_blocks > 0 then
    table.insert(modal_content, pandoc.Div(content.protect_headers(body_blocks, modal_id .. '-', 'html'), pdoc.attr('', { 'modal-body' })))
  end
  if #footer_blocks > 0 then
    table.insert(modal_content, pandoc.Div(content.protect_headers(footer_blocks, '', 'html'), pdoc.attr('', { 'modal-footer' })))
  end

  local modal_description = el.attributes.description
  local modal_attrs = {
    ['tabindex'] = '-1',
    ['aria-hidden'] = 'true',
    ['aria-labelledby'] = modal_header_id
  }
  if modal_description then
    if not document_ids[modal_description] then
      log.log_warning(
        EXTENSION_NAME,
        "Modal '" .. modal_id .. "' has description='" .. modal_description ..
        "' but no element with that identifier exists in the document."
      )
    end
    modal_attrs['aria-describedby'] = modal_description
  end
  if modal_backdrop_static == 'true' then
    modal_attrs['data-bs-backdrop'] = 'static'
  end
  if modal_keyboard == 'false' then
    modal_attrs['data-bs-keyboard'] = 'false'
  end

  local modal_classes = { 'modal' }
  if modal_fade == 'true' then table.insert(modal_classes, 'fade') end

  local modal_structure = pandoc.Div({
    pandoc.Div({
      pandoc.Div(modal_content, pdoc.attr('', { 'modal-content' }))
    }, pdoc.attr('', dialog_classes))
  }, pdoc.attr(modal_id, modal_classes, modal_attrs))

  return modal_structure
end

--- Expand bare Markdown links to a ``#modal-*`` anchor into Bootstrap
--- modal triggers.
---
--- Runs at the ``pre-quarto`` filter stage, where Pandoc-style attribute
--- names (``bs-target``, ``bs-toggle``) have not yet been prefixed with
--- ``data-`` by Quarto. The filter checks (and writes) the unprefixed
--- names so that author intent is preserved: if the link already declares
--- a Bootstrap toggle or target, the filter leaves it alone.
--- @param el table Pandoc Link element.
--- @return table Possibly-modified Link element.
local function expand_modal_link(el)
  if not el.target or not el.target:match('^#modal%-') then
    return el
  end
  if el.attributes['bs-toggle'] ~= nil and el.attributes['bs-toggle'] ~= '' then
    return el
  end
  if el.attributes['bs-target'] ~= nil and el.attributes['bs-target'] ~= '' then
    return el
  end
  el.attributes['bs-target'] = el.target
  el.attributes['bs-toggle'] = 'modal'
  return el
end

--- Check the document configuration against the extension schema.
--- Runs before ``get_modal_meta`` replaces ``extensions.modal`` with the
--- resolved settings, so the check reads what the author wrote.
--- @param meta table Pandoc document metadata.
--- @return nil Metadata is never modified by the check.
local function check_document_options(meta)
  if quarto.doc.is_format("html:js") and quarto.doc.has_bootstrap() then
    checker:options(meta)
  end
end

return {
  { Meta = check_document_options },
  { Pandoc = get_modal_meta },
  { Div = modal },
  { Link = expand_modal_link }
}
