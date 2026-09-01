--- MC Paths - Path resolution utilities for Quarto Lua filters and shortcodes
--- @module "paths"
--- @license MIT
--- @copyright 2026 Mickaël Canouil
--- @author Mickaël Canouil
--- @version 1.0.0

local M = {}

--- Load a sibling module from the same directory as this file.
--- @param filename string The sibling module filename (e.g., 'string.lua')
--- @return table The loaded module
local function load_sibling(filename)
  local source = debug.getinfo(1, 'S').source:sub(2)
  local dir = source:match('(.*[/\\])') or ''
  return require((dir .. filename):gsub('%.lua$', ''))
end

--- Load string module for is_empty
local str = load_sibling('string.lua')

-- ============================================================================
-- PATH UTILITIES
-- ============================================================================

--- Resolve a path relative to the project directory.
--- If the path starts with `/`, it is treated as relative to the project directory.
--- If `quarto.project.directory` is available, it is prepended to the path.
--- If `quarto.project.directory` is nil, the leading `/` is removed.
--- @param path string The path to resolve (may start with `/`)
--- @return string The resolved path
--- @usage local resolved = M.resolve_project_path("/config.yml")
--- @usage local resolved = M.resolve_project_path("config.yml")
function M.resolve_project_path(path)
  if str.is_empty(path) then
    return path
  end

  if path:sub(1, 1) == '/' then
    if quarto.project.directory then
      return pandoc.path.join({ quarto.project.directory, path:sub(2) })
    else
      return path:sub(2)
    end
  else
    return path
  end
end

-- ============================================================================
-- MODULE EXPORT
-- ============================================================================

return M
