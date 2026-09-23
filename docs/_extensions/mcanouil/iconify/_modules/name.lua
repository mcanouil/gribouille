--- MC Iconify Name - Checking an icon set or icon name
--- @module "name"
--- @license MIT
--- @copyright 2026 Mickaël Canouil
--- @author Mickaël Canouil
--- @version 1.0.0
---
--- Iconify writes every set and every icon name in lower case, with digits
--- and single hyphens between words. The shortcode takes both from the
--- author, and Typst output puts them into the Iconify API path and into the
--- cache file name. A value such as `../../etc/passwd` therefore reaches the
--- filesystem, and the cached SVG is written outside the cache directory.
---
--- This module holds the one rule both the HTML and the Typst path read, so
--- the two cannot drift apart.
---
--- It depends on nothing, so `tests/icon-name.lua` can load it directly.

local M = {}

--- Whether a value is a usable Iconify set or icon name.
---
--- The rule is Iconify's own: lower-case letters, digits and single hyphens,
--- with no hyphen at either end. Everything a path or a URL gives a meaning
--- to, such as `/`, `.`, `:`, `?`, `#`, `@` and whitespace, falls outside it.
---
--- @param value string|nil The set or icon name
--- @return boolean valid `true` when the value is a safe single path segment
function M.is_valid(value)
  if type(value) ~= 'string' then return false end
  if value:find('%-%-') then return false end
  if value:sub(1, 1) == '-' or value:sub(-1) == '-' then return false end
  return value:match('^[a-z0-9-]+$') ~= nil
end

return M
