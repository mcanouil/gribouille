local util = require("util")
local parser = require("parser")

local M = {}

-- Wraps a /// @examples fence in the same self-contained shell as `examples/*.typ`.
-- `auto` page size keeps the diff focused on plot pixels rather than blank margins.
local WRAPPER = '#import "/lib.typ": *\n#set page(width: auto, height: auto, margin: 0cm)\n\n%s\n'

-- Gives a visual test the same `auto` page as a docstring fence. The page
-- must stay single: one golden PNG holds one page.
local PAGE_WRAPPER = '#set page(width: auto, height: auto, margin: 0cm)\n#include "/%s"\n'

-- Directories whose top-level `.typ` files are snapshotted whole, beside the
-- docstring examples. An example sets its own page; a visual test, the
-- regression render of a behaviour fix, gets `PAGE_WRAPPER`.
local FILE_GROUPS = {
  { group = "examples", dir = "examples", wrap = false },
  { group = "visual", dir = "tests/visual", wrap = true },
}

local function make_matcher(only)
  if not only then return function() return true end end
  return function(key) return key:find(only, 1, true) ~= nil end
end

-- One source per top-level `.typ` file in `spec.dir`, keyed `<group>/<name>`.
local function collect_files(root, spec, build_root, golden_root, matches)
  local sources = {}
  for _, file in ipairs(util.list_dir_files(root .. "/" .. spec.dir)) do
    local name = file:match("^(.+)%.typ$")
    local key = name and (spec.group .. "/" .. name)
    if key and matches(key) then
      local rel = spec.dir .. "/" .. file
      local src_typ = root .. "/" .. rel
      if spec.wrap then
        src_typ = string.format("%s/src/%s-%s.typ", build_root, spec.group, name)
        util.write_file(src_typ, string.format(PAGE_WRAPPER, rel))
      end
      sources[#sources + 1] = {
        key = key,
        src_typ = src_typ,
        golden = string.format("%s/%s/%s.png", golden_root, spec.group, name),
      }
    end
  end
  return sources
end

local function append_docstring_fences(fn, build_root, golden_root, matches, sources)
  if not fn.doc then return end
  local idx = 0
  for _, ex in ipairs(fn.doc.examples or {}) do
    if ex.render then
      for _, seg in ipairs(ex.segments) do
        if seg.kind == "code" then
          idx = idx + 1
          local key = string.format("docstrings/%s-%d", fn.name, idx)
          if matches(key) then
            local out_typ = string.format("%s/src/%s-%d.typ", build_root, fn.name, idx)
            util.write_file(out_typ, string.format(WRAPPER, seg.source))
            sources[#sources + 1] = {
              key = key,
              src_typ = out_typ,
              golden = string.format("%s/docstrings/%s-%d.png", golden_root, fn.name, idx),
            }
          end
        end
      end
    end
  end
end

local function collect_docstrings(root, build_root, golden_root, matches)
  local sources = {}
  parser.set_root(root)
  for _, f in ipairs(util.find_typ_files(root .. "/src")) do
    for _, fn in ipairs(parser.parse_file(f).functions or {}) do
      append_docstring_fences(fn, build_root, golden_root, matches, sources)
    end
  end
  return sources
end

function M.collect(opts)
  assert(opts.root, "extract.collect: root required")
  assert(opts.build_root, "extract.collect: build_root required")
  assert(opts.golden_root, "extract.collect: golden_root required")

  local matches = make_matcher(opts.only)
  local sources = {}
  for _, spec in ipairs(FILE_GROUPS) do
    local files = collect_files(opts.root, spec, opts.build_root, opts.golden_root, matches)
    for _, s in ipairs(files) do sources[#sources + 1] = s end
  end
  for _, s in ipairs(collect_docstrings(opts.root, opts.build_root, opts.golden_root, matches)) do
    sources[#sources + 1] = s
  end
  table.sort(sources, function(a, b) return a.key < b.key end)
  return sources
end

return M
