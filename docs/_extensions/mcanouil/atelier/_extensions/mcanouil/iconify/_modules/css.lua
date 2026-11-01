--- MC Iconify CSS - Reading one declaration out of an inline `style` value
--- @module "css"
--- @license MIT
--- @copyright 2026 Mickaël Canouil
--- @author Mickaël Canouil
--- @version 1.0.0
---
--- The shortcode accepts a `style` attribute, and Typst output needs the icon
--- colour out of it. A plain search for `color:` finds the colour inside
--- `background-color`, `border-color` and every other property whose name ends
--- the same way, so the icon is painted a colour the author never asked for.
---
--- This module reads the declaration list one declaration at a time and
--- compares the whole property name, which is the only way to tell
--- `background-color` from `color`.
---
--- It depends on nothing, so `tests/style-colour.lua` can load it directly.
---
--- Declarations are split on every semicolon, including one inside a quoted
--- value. A value such as `"a; b"` is therefore read as two declarations.
--- No property that takes a quoted value has any bearing on an icon, so the
--- parser is left simple rather than made quote-aware.

local M = {}

--- Read one property from an inline CSS declaration list.
---
--- The property name is compared in full and without regard to case, so
--- `background-color` never answers for `color`. The last matching
--- declaration wins, as it does in CSS. A declaration with no value is
--- invalid, so it is ignored rather than clearing an earlier one. An
--- `!important` marker belongs to the declaration rather than to the value,
--- so it is removed.
---
--- @param style string|nil The inline CSS, such as `color: red; font-size: 2em`
--- @param property string The property name to read, in lower case
--- @return string value The declared value, trimmed, or an empty string
function M.declaration(style, property)
  if type(style) ~= 'string' or style == '' then
    return ''
  end

  local found = ''
  for declaration in (style .. ';'):gmatch('([^;]*);') do
    local name, value = declaration:match('^%s*([%w%-]+)%s*:%s*(.-)%s*$')
    if name and name:lower() == property then
      -- `!important` is part of the declaration, not of the value. Passing it
      -- on would hand a colour function a string that names no colour.
      value = value
        :gsub('%s*!%s*[Ii][Mm][Pp][Oo][Rr][Tt][Aa][Nn][Tt]%s*$', '')
        :gsub('%s*$', '')
      -- A declaration with no value is invalid, so it is ignored rather than
      -- clearing an earlier one.
      if value ~= '' then
        found = value
      end
    end
  end

  return found
end

return M
