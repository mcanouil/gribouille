local util = require("util")
local parser = require("parser")

local M = {}

-- Directories whose `.typ` files are snapshotted whole, beside the docstring
-- examples. `tests/visual/` holds the regression renders of behaviour fixes.
M.FILE_GROUPS = {
  { name = "examples", dir = "examples" },
  { name = "visual", dir = "tests/visual" },
}

-- Wraps a /// @examples fence in the same self-contained shell as `examples/*.typ`.
-- `auto` page size keeps the diff focused on plot pixels rather than blank margins.
local WRAPPER = '#import "/lib.typ": *\n#set page(width: auto, height: auto, margin: 0cm)\n\n%s\n'

local function make_matcher(only)
  if not only then return function() return true end end
  return function(key) return key:find(only, 1, true) ~= nil end
end

-- Each standalone `.typ` file under `dir` is one source, keyed and stored
-- under `group`: `examples/*.typ` as "examples", `tests/visual/*.typ` as
-- "visual".
local function collect_files(dir, group, golden_root, matches)
  local sources = {}
  for _, f in ipairs(util.find_typ_files(dir)) do
    local name = f:match("([^/]+)%.typ$")
    local key = group .. "/" .. name
    if matches(key) then
      sources[#sources + 1] = {
        key = key,
        src_typ = f,
        golden = string.format("%s/%s/%s.png", golden_root, group, name),
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
  for _, group in ipairs(M.FILE_GROUPS) do
    local dir = opts.root .. "/" .. group.dir
    for _, s in ipairs(collect_files(dir, group.name, opts.golden_root, matches)) do
      sources[#sources + 1] = s
    end
  end
  for _, s in ipairs(collect_docstrings(opts.root, opts.build_root, opts.golden_root, matches)) do
    sources[#sources + 1] = s
  end
  table.sort(sources, function(a, b) return a.key < b.key end)
  return sources
end

return M
