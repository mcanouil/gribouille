--- Atelier - Bundled collapse-output
--- @module "bundled/collapse-output"
--- @license MIT
--- @copyright 2026 Mickaël Canouil
--- @author Mickaël Canouil
--- @brief Run the bundled collapse-output filter, unless the project has its own copy.
--- @description Atelier names this wrapper in place of the bundled extension,
--- so a project that keeps its own copy of collapse-output runs that copy only.
--- Remove when: never.

local embedded = require(quarto.utils.resolve_path('../_vendor/quarto-lua-modules/embedded.lua'):gsub('%.lua$', ''))
local file = quarto.utils.resolve_path('../_extensions/mcanouil/collapse-output/collapse-output.lua')
return embedded.load('collapse-output', file)
