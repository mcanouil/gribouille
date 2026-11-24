--- Atelier - Bundled preview-colour
--- @module "bundled/preview-colour"
--- @license MIT
--- @copyright 2026 Mickaël Canouil
--- @author Mickaël Canouil
--- @brief Run the bundled preview-colour filter, unless the project has its own copy.
--- @description Atelier names this wrapper in place of the bundled extension,
--- so a project that keeps its own copy of preview-colour runs that copy only.
--- Remove when: never.

local embedded = require(quarto.utils.resolve_path('../_vendor/quarto-lua-modules/embedded.lua'):gsub('%.lua$', ''))
local file = quarto.utils.resolve_path('../_extensions/mcanouil/preview-colour/preview-colour.lua')
return embedded.load('preview-colour', file)
