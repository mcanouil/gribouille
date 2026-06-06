-- Shared helpers for the snapshot scripts (run.lua, diff.lua). `script_dir`
-- stays inline in each entry point because it bootstraps `package.path` before
-- this module can be required.
local M = {}

-- Single-quote a string for safe interpolation into a shell command.
function M.shell_quote(s)
  return "'" .. s:gsub("'", [['\'']]) .. "'"
end

-- Resolve a path against `root` unless it is already absolute.
function M.abs(root, path)
  if path:sub(1, 1) == "/" then return path end
  return root .. "/" .. path
end

return M
