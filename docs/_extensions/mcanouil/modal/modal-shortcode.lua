--- @module "modal-shortcode"
--- @license MIT
--- @copyright 2026 Mickaël Canouil
--- @author Mickaël Canouil

--- Extension name constant
local EXTENSION_NAME = "modal"

--- Load modules
local str = require(quarto.utils.resolve_path('_vendor/quarto-lua-modules/string.lua'):gsub('%.lua$', ''))
local schema = require(quarto.utils.resolve_path('_vendor/quarto-wizard/schema.lua'):gsub('%.lua$', ''))
local check = require(quarto.utils.resolve_path('_vendor/quarto-lua-modules/schema-check.lua'):gsub('%.lua$', ''))

--- The schema check, built once and reused by every shortcode call. It reads
--- `_schema.yml` on the way in and checks each call against the entry that
--- describes it.
---
--- The validator is injected rather than required by the check module, so the
--- two vendored sources stay independent of where the other was placed.
---
--- The extension contributes a filter and a shortcode, and each entry point
--- builds its own checker. The document configuration is checked by the filter,
--- so it is not checked again here.
---
--- A schema that cannot be read is reported by the module as an error and the
--- render carries on: a configuration file must not stop a document.
local checker = check.new(schema, EXTENSION_NAME)

--- Generate a Bootstrap modal button for Quarto shortcode.
--- @param args table List of arguments (first is button type).
--- @param kwargs table Key-value arguments (target, label, classes, inside).
--- @param _meta table Pandoc document metadata.
--- @param _raw_args table Raw arguments.
--- @param _context table Pandoc context.
--- @return pandoc.RawBlock HTML button or pandoc.Null if invalid.
local function modal(args, kwargs, _meta, _raw_args, _context)
  checker:call('modal', args, kwargs)

  if not quarto.doc.is_format('html:js') or not quarto.doc.has_bootstrap() then
    return pandoc.Null()
  end

  local button_type = #args > 0 and str.stringify(args[1]) or 'toggle'
  local target = str.stringify(kwargs.target)
  local label = str.stringify(kwargs.label)
  local classes = str.stringify(kwargs.classes)
  local inside = str.stringify(kwargs.inside) == 'true'

  if classes == '' then
    if button_type == 'toggle' or label ~= '' then
      classes = 'btn btn-primary'
    elseif button_type == 'dismiss' then
      classes = 'btn-close'
    end
  end

  --- @type string|nil HTML button string or nil if invalid button type
  local button_html = nil
  if button_type == 'toggle' then
    button_html = string.format(
      '<button type="button" data-bs-toggle="modal" data-bs-target="#%s" class="%s">%s</button>',
      target, classes, label
    )
  elseif button_type == 'dismiss' then
    if inside then
      button_html = string.format(
        '<button type="button" class="%s" data-bs-dismiss="modal" aria-label="Close">%s</button>',
        classes, label
      )
    else
      button_html = string.format(
        '<button type="button" class="%s" data-bs-dismiss="modal" data-bs-target="#%s" aria-label="Close">%s</button>',
        classes, target, label
      )
    end
  end

  if button_html then
    return pandoc.RawBlock('html', button_html)
  else
    return pandoc.Null()
  end
end

---
--- Export modal shortcode function for Quarto.
--- @return table Table with modal function.
---
return {
  ['modal'] = modal
}
