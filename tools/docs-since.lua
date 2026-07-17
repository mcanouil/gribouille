#!/usr/bin/env lua

local function script_dir()
  local source = debug.getinfo(1, "S").source
  if source:sub(1, 1) == "@" then source = source:sub(2) end
  return source:match("^(.*)/[^/]+$") or "."
end

local DIR = script_dir()
local ROOT = DIR .. "/.."
package.path = DIR .. "/typstdoc/?.lua;" .. package.path

local util = require("util")
local parser = require("parser")

local USAGE = [[
Usage: tools/docs-since.lua [--check]

Checks that every hand-written docs page declares the release that introduced
the API it calls. Docs content is rendered from `main` while `src`/`lib.typ` are
pinned to the release tag, so a page calling API newer than the latest release
cannot compile on the release build unless it declares `since:`, which makes
assets/lua/version-gate.lua render a pointer stub in its place instead.

Fails when a page calls API newer than the latest release and its `since:` is
missing or older than that API.

Modes:
  (default)  Check; identical to --check.
  --check    Exit non-zero on any offending page.
  --help     Show this help and exit.
]]

-- Generated pages are not checked: they are built from the pinned `src` and
-- `examples`, so they cannot reference API the pinned source lacks. Only the
-- directories listed here are scanned, which excludes docs/reference,
-- docs/examples, and docs/gallery by omission.
local PAGE_DIRS = { "docs", "docs/guides", "docs/get-started", "docs/news" }

local EXCLUDED = {
  -- Generated from CHANGELOG.md, whose entries name new API in prose.
  ["docs/changelog.qmd"] = true,
  -- Development-only coverage table, kept off the release site by
  -- docs/_quarto-release.yml, so it never renders against a pinned source.
  ["docs/feature-matrix.qmd"] = true,
}

local function parse_version(value)
  if not value then return nil end
  local parts = {}
  for n in tostring(value):gmatch("(%d+)") do
    parts[#parts + 1] = tonumber(n)
  end
  if #parts == 0 then return nil end
  return parts
end

--- Return true when version `a` is strictly newer than `b`.
local function is_newer(a, b)
  for i = 1, math.max(#a, #b) do
    local x, y = a[i] or 0, b[i] or 0
    if x ~= y then return x > y end
  end
  return false
end

--- Newest released version, from the first `## X.Y.Z (date)` heading in the
--- changelog. Preferred over `git tag`: it needs no tag fetch in a shallow CI
--- checkout, and release.yml rewrites `## Unreleased` to the version at the
--- same moment the tag is created.
local function latest_release(path)
  local text = util.read_file(path)
  if not text then util.die("cannot read " .. path) end
  for line in text:gmatch("[^\n]+") do
    local version = line:match("^##%s+(%d+%.%d+%.%d+)%s+%(")
    if version then return version end
  end
  util.die("no released version heading found in " .. path)
end

--- Map every symbol exported from lib.typ to the version that introduced it.
local function since_by_symbol(src_dir, lib_path)
  parser.set_root(ROOT) -- @theme-keys resolution, as in typstdoc/main.lua
  local lib_info = parser.parse_lib(lib_path)
  local since = {}
  for _, file in ipairs(util.find_typ_files(src_dir)) do
    for _, fn in ipairs(parser.parse_file(file).functions) do
      if lib_info.exports[fn.name] and fn.doc and fn.doc.since then
        since[fn.name] = fn.doc.since
      end
    end
  end
  return since
end

local function qmd_files(dir)
  local handle = io.popen(
    string.format("find %q -maxdepth 1 -name '*.qmd' -type f 2>/dev/null", dir)
  )
  if not handle then return {} end
  local out = handle:read("a") or ""
  handle:close()
  local files = {}
  for path in out:gmatch("[^\n]+") do files[#files + 1] = path end
  table.sort(files)
  return files
end

local function declared_since(text)
  local front = text:match("^%-%-%-\n(.-)\n%-%-%-")
  if not front then return nil end
  return front:match("\nsince:%s*[\"']?([%d%.]+)[\"']?") or
    front:match("^since:%s*[\"']?([%d%.]+)[\"']?")
end

--- True when `name` is called in `text`, ignoring calls whose name merely ends
--- with `name` (`scale-continuous` must not match inside `my-scale-continuous`).
local function calls(text, name)
  local pattern = name:gsub("%-", "%%-") .. "%("
  for pos in text:gmatch("()" .. pattern) do
    local before = pos > 1 and text:sub(pos - 1, pos - 1) or ""
    if not before:match("[%w_%-]") then return true end
  end
  return false
end

--- True when the page rebinds `name` itself, so a call refers to the page's own
--- definition rather than to the library symbol.
local function shadows(text, name)
  return text:match("#let%s+" .. name:gsub("%-", "%%-") .. "%s*[=(]") ~= nil
end

local function check()
  local latest = latest_release(ROOT .. "/CHANGELOG.md")
  local latest_v = parse_version(latest)
  local since = since_by_symbol(ROOT .. "/src", ROOT .. "/lib.typ")

  local failures = 0
  local checked = 0

  for _, dir in ipairs(PAGE_DIRS) do
    for _, path in ipairs(qmd_files(ROOT .. "/" .. dir)) do
      local rel = path:gsub("^" .. ROOT:gsub("[%-%.]", "%%%0") .. "/", "")
      if not EXCLUDED[rel] then
        checked = checked + 1
        local text = util.read_file(path) or ""

        -- Newest API the page calls, and the symbols pinning it there.
        local required, culprits = nil, {}
        for name, symbol_since in pairs(since) do
          if calls(text, name) and not shadows(text, name) then
            local v = parse_version(symbol_since)
            if v and is_newer(v, latest_v) then
              if not required or is_newer(v, required) then
                required, culprits = v, {}
              end
              if not is_newer(required, v) then
                culprits[#culprits + 1] = name .. " (" .. symbol_since .. ")"
              end
            end
          end
        end

        if required then
          local declared = declared_since(text)
          local declared_v = parse_version(declared) or { 0, 0, 0 }
          if is_newer(required, declared_v) then
            failures = failures + 1
            table.sort(culprits)
            local want = table.concat(culprits, ", "):match("%((%d+%.%d+%.%d+)%)")
            io.stderr:write(("  FAIL  %s\n"):format(rel))
            io.stderr:write(("    calls: %s\n"):format(table.concat(culprits, ", ")))
            io.stderr:write(("    declared: %s\n"):format(declared or "(none)"))
            io.stderr:write(("    fix: add `since: \"%s\"` to the frontmatter\n"):format(want))
          end
        end
      end
    end
  end

  if failures > 0 then
    io.stderr:write(("\ndocs-since: %d page(s) newer than the latest release (%s) without an adequate `since:`.\n")
      :format(failures, latest))
    os.exit(1)
  end
  print(("docs-since: %d page(s) checked against latest release %s; check OK"):format(checked, latest))
end

local arg1 = arg and arg[1]
if arg1 == "--help" or arg1 == "-h" then
  io.write(USAGE)
  os.exit(0)
elseif arg1 and arg1 ~= "--check" then
  io.stderr:write(("docs-since: unknown argument: %s\n"):format(arg1))
  io.write(USAGE)
  os.exit(2)
end

check()
