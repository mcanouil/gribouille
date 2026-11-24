--- Atelier - Bundled iconify
--- @module "bundled/iconify"
--- @license MIT
--- @copyright 2026 Mickaël Canouil
--- @author Mickaël Canouil
--- @brief Run the bundled iconify filter, unless the project has its own copy.
--- @description Atelier names this wrapper in place of the bundled extension,
--- so a project that names its own copy of iconify in `filters` runs that copy's
--- filter only.
--- A copy under `_extensions/` always replaces the bundled shortcode, so the
--- load warns when the copy is not named.
--- Remove when: never.

local embedded = require(quarto.utils.resolve_path('../_vendor/quarto-lua-modules/embedded.lua'):gsub('%.lua$', ''))
local file = quarto.utils.resolve_path('../_extensions/mcanouil/iconify/iconify-filter.lua')
return embedded.load('iconify', file, { shortcode = true })
