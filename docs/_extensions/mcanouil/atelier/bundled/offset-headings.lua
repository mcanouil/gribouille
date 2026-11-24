--- Atelier - Bundled offset-headings
--- @module "bundled/offset-headings"
--- @license MIT
--- @copyright 2026 Mickaël Canouil
--- @author Mickaël Canouil
--- @brief Run the bundled offset-headings filter, unless the project has its own copy.
--- @description Atelier names this wrapper in place of the bundled extension,
--- so a project that keeps its own copy of offset-headings runs that copy only.
--- Remove when: never.

local embedded = require(quarto.utils.resolve_path('../_vendor/quarto-lua-modules/embedded.lua'):gsub('%.lua$', ''))
local file = quarto.utils.resolve_path('../_extensions/mcanouil/offset-headings/offset-headings.lua')
return embedded.load('offset-headings', file)
