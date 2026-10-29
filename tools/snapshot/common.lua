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

-- ImageMagick `compare -metric AE` writes "<ae>" or "<ae> (<normalised>)" on
-- stderr. Uses the v6/v7-compatible `compare` entry point rather than
-- `magick compare`. Exit codes: 0 == identical, 1 == differs but ran
-- cleanly, >=2 == error. run.lua gates on this contract and diff.lua draws
-- its overlay with it, so both read the same AE count.
function M.compare_cmd(golden, current, diff_png, fuzz)
  return string.format(
    "compare -metric AE -fuzz %s %s %s %s 2>&1",
    fuzz, M.shell_quote(golden), M.shell_quote(current), M.shell_quote(diff_png)
  )
end

-- Reads the AE pixel count from a `compare` exit code and output. Returns nil
-- on error, so callers don't confuse a crashed compare with a clean 0-pixel match.
function M.parse_ae(code, out)
  if code <= 1 then return tonumber(out:match("^%s*(%d+)")) end
  return nil
end

return M
