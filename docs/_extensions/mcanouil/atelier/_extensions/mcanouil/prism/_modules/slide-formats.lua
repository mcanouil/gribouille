--- MC Slide Formats - Canonical list of HTML slide formats for Quarto extensions
--- @module "slide-formats"
--- @license MIT
--- @copyright 2026 Mickaël Canouil
--- @author Mickaël Canouil
--- @version 1.0.0
--- @brief Single source of truth for the HTML slide-format set shared across
---   filters that need to treat slides distinctly from plain HTML.

local M = {}

-- ============================================================================
-- SLIDE FORMAT SET
-- ============================================================================

--- The set of HTML slide formats that Quarto can target.
--- Keys are Pandoc/Quarto format names; values are `true` for fast membership
--- checks via `M.formats[name]`.
--- Extensions that need to extend this set per document should overlay their
--- own additions on top of this table; this module never mutates it.
--- @type table<string, boolean>
M.formats = {
  revealjs = true,
  slidy = true,
  s5 = true,
  dzslides = true,
  slideous = true,
}

--- The list form of `M.formats`, ordered as declared above.
--- Useful for documentation, schema generation, and iteration where order
--- matters; the set in `M.formats` is the source of truth for membership.
--- @type string[]
M.list = {
  'revealjs',
  'slidy',
  's5',
  'dzslides',
  'slideous',
}

-- ============================================================================
-- HELPERS
-- ============================================================================

--- Check whether a format name is one of the HTML slide formats.
--- @param format string|nil The format name to test.
--- @return boolean True when `format` is a slide format, false otherwise.
--- @usage if slide_formats.is_slide_format('revealjs') then ... end
function M.is_slide_format(format)
  if type(format) ~= 'string' or format == '' then
    return false
  end
  return M.formats[format] == true
end

-- ============================================================================
-- MODULE EXPORT
-- ============================================================================

return M
