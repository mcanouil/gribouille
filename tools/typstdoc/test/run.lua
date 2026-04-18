-- Stdlib-only test runner for typstdoc.
-- Usage (from repo root): lua tools/typstdoc/test/run.lua

local function script_dir()
  local source = debug.getinfo(1, "S").source
  if source:sub(1, 1) == "@" then source = source:sub(2) end
  return source:match("^(.*)/[^/]+$") or "."
end

local TEST_DIR = script_dir()
local ROOT = TEST_DIR:match("^(.*)/test$") or TEST_DIR
package.path = ROOT .. "/?.lua;" .. TEST_DIR .. "/?.lua;" .. package.path

local T = { passed = 0, failed = 0, errors = {} }

local function describe(name, fn)
  io.write(string.format("\n== %s ==\n", name))
  fn()
end

local function it(name, fn)
  local ok, err = xpcall(fn, debug.traceback)
  if ok then
    T.passed = T.passed + 1
    io.write(string.format("  ok  %s\n", name))
  else
    T.failed = T.failed + 1
    table.insert(T.errors, { name = name, err = err })
    io.write(string.format("  FAIL %s\n%s\n", name, err))
  end
end

local function assert_eq(actual, expected, msg)
  if actual ~= expected then
    error(string.format("%s\n  expected: %s\n  actual:   %s",
      msg or "values differ", tostring(expected), tostring(actual)), 2)
  end
end

local function assert_true(cond, msg)
  if not cond then error(msg or "expected true, got falsy", 2) end
end

local function assert_contains(haystack, needle, msg)
  if not haystack:find(needle, 1, true) then
    error(string.format("%s\n  expected to contain: %s\n  got:\n%s",
      msg or "missing substring", needle, haystack), 2)
  end
end

local function assert_throws(fn, pattern, msg)
  local ok, err = pcall(fn)
  if ok then error(msg or "expected an error, got none", 2) end
  if pattern and not tostring(err):find(pattern) then
    error(string.format("%s\n  expected error matching: %s\n  got: %s",
      msg or "wrong error", pattern, tostring(err)), 2)
  end
end

local parser = require("parser")
local model = require("model")
local resolve = require("resolve")
local util = require("util")

local function tmpfile(name, body)
  local path = string.format("%s/_tmp_%s.typ", TEST_DIR, name)
  util.write_file(path, body)
  return path
end

local function cleanup()
  os.execute(string.format("rm -f %q/_tmp_*.typ", TEST_DIR))
end

-- -----------------------------------------------------------------------
describe("parser: doc block basics", function()
  it("accepts a minimal doc block with summary", function()
    local f = tmpfile("min", [[
/// A minimal function.
///
/// @category Core
#let foo() = none
]])
    local parsed = parser.parse_file(f)
    assert_eq(#parsed.functions, 1)
    assert_eq(parsed.functions[1].name, "foo")
    assert_eq(parsed.functions[1].doc.summary, "A minimal function.")
    assert_eq(parsed.functions[1].doc.category, "Core")
  end)

  it("rejects a block with no summary", function()
    local f = tmpfile("nosummary", [[
///
/// @category Core
#let foo() = none
]])
    assert_throws(function() parser.parse_file(f) end, "missing summary")
  end)

  it("preserves paragraphs across blank /// lines", function()
    local f = tmpfile("paras", [[
/// Summary line.
///
/// First paragraph.
/// Still first paragraph.
///
/// Second paragraph.
///
/// @category Core
#let foo() = none
]])
    local parsed = parser.parse_file(f)
    local desc = parsed.functions[1].doc.description
    assert_eq(#desc, 2, "expected two paragraphs")
    assert_contains(desc[1], "First paragraph")
    assert_contains(desc[1], "Still first paragraph")
    assert_contains(desc[2], "Second paragraph")
  end)

  it("rejects unknown tags", function()
    local f = tmpfile("unknown", [[
/// Summary.
///
/// @nosuchtag boom
#let foo() = none
]])
    assert_throws(function() parser.parse_file(f) end, "unknown tag")
  end)
end)

-- -----------------------------------------------------------------------
describe("parser: signature + @param matching", function()
  it("parses named params with defaults", function()
    local f = tmpfile("named", [[
/// Summary.
///
/// @category Core
/// @param x The x.
/// @param y The y.
#let foo(x: 1, y: 2) = none
]])
    local parsed = parser.parse_file(f)
    local fn = parsed.functions[1]
    assert_eq(#fn.signature_params, 2)
    assert_eq(fn.signature_params[1].name, "x")
    assert_eq(fn.signature_params[1].default, "1")
    assert_eq(fn.signature_params[2].name, "y")
    assert_eq(fn.signature_params[2].default, "2")
  end)

  it("parses variadic ..args", function()
    local f = tmpfile("variadic", [[
/// Summary.
///
/// @category Core
/// @param ..args All extras.
#let foo(..args) = none
]])
    local parsed = parser.parse_file(f)
    local fn = parsed.functions[1]
    assert_eq(fn.signature_params[1].name, "args")
    assert_true(fn.signature_params[1].variadic)
    assert_true(fn.doc.params[1].variadic)
  end)

  it("parses @arity entries", function()
    local f = tmpfile("arity", [[
/// Summary.
///
/// @category Core
/// @param ..args Variadic.
/// @arity (data, col): Two-arg form.
/// @arity (col): One-arg form.
#let foo(..args) = none
]])
    local parsed = parser.parse_file(f)
    local doc = parsed.functions[1].doc
    assert_eq(#doc.arities, 2)
    assert_eq(doc.arities[1].signature, "(data, col)")
    assert_eq(doc.arities[1].description, "Two-arg form.")
    assert_eq(doc.arities[2].signature, "(col)")
  end)

  it("handles multi-line signatures with nested parens", function()
    local f = tmpfile("multiline", [[
/// Summary.
///
/// @category Core
/// @param x X.
/// @param layers Layers.
#let foo(
  x: rgb("#888888"),
  layers: (a: 1, b: (1, 2, 3)),
) = none
]])
    local parsed = parser.parse_file(f)
    local fn = parsed.functions[1]
    assert_eq(#fn.signature_params, 2)
    assert_eq(fn.signature_params[1].name, "x")
    assert_contains(fn.signature_params[1].default, "rgb")
    assert_eq(fn.signature_params[2].name, "layers")
  end)

  it("ignores underscore-prefixed helpers", function()
    local f = tmpfile("underscore", [[
#let _helper(x) = x
#let _other() = none
]])
    local parsed = parser.parse_file(f)
    assert_eq(#parsed.functions, 0)
  end)

  it("ignores pipeline hooks (draw, apply)", function()
    local f = tmpfile("hooks", [[
#let draw(ctx) = none
#let apply(ctx) = none
]])
    local parsed = parser.parse_file(f)
    assert_eq(#parsed.functions, 0)
  end)

  it("treats `#let name = expr(...)` as a value binding", function()
    local f = tmpfile("valueparen", [[
/// Default swatch.
///
/// @category Core
#let swatch = rgb("#1f77b4")
]])
    local parsed = parser.parse_file(f)
    assert_eq(#parsed.functions, 1)
    assert_true(parsed.functions[1].is_value, "should be value, not function")
    assert_eq(#parsed.functions[1].signature_params, 0)
  end)

  it("parses a function after a multi-line value binding", function()
    local f = tmpfile("valuethenfn", [[
#let palette = (
  rgb("#1f77b4"),
  rgb("#2ca02c"),
)

/// Summary.
///
/// @category Core
/// @param x X.
#let foo(x: 1) = x
]])
    local parsed = parser.parse_file(f)
    assert_eq(#parsed.functions, 2)
    assert_true(parsed.functions[1].is_value)
    assert_eq(parsed.functions[2].name, "foo")
    assert_eq(parsed.functions[2].is_value, false)
  end)
end)

-- -----------------------------------------------------------------------
describe("parser: validate_function", function()
  local function lib_info(exports_list)
    local exports = {}
    for _, e in ipairs(exports_list) do
      exports[e.name] = e
    end
    return { exports = exports, category_order = {} }
  end

  it("errors when exported function has no doc block", function()
    local f = tmpfile("noblock", [[
#let foo() = none
]])
    local parsed = parser.parse_file(f)
    local info = lib_info({ { name = "foo", category = "Core" } })
    assert_throws(function() parser.validate_function(parsed.functions[1], info) end,
      "no doc block")
  end)

  it("errors when @param list misses a signature param", function()
    local f = tmpfile("missparam", [[
/// Summary.
///
/// @category Core
/// @param x X.
#let foo(x: 1, y: 2) = none
]])
    local parsed = parser.parse_file(f)
    local info = lib_info({ { name = "foo", category = "Core" } })
    assert_throws(function() parser.validate_function(parsed.functions[1], info) end,
      "missing from doc block")
  end)

  it("errors when @param names a non-existent signature param", function()
    local f = tmpfile("extraparam", [[
/// Summary.
///
/// @category Core
/// @param x X.
/// @param z Z.
#let foo(x: 1) = none
]])
    local parsed = parser.parse_file(f)
    local info = lib_info({ { name = "foo", category = "Core" } })
    assert_throws(function() parser.validate_function(parsed.functions[1], info) end,
      "not in signature")
  end)

  it("errors when @category disagrees with lib.typ banner", function()
    local f = tmpfile("wrongcat", [[
/// Summary.
///
/// @category Core
#let foo() = none
]])
    local parsed = parser.parse_file(f)
    local info = lib_info({ { name = "foo", category = "Geoms" } })
    assert_throws(function() parser.validate_function(parsed.functions[1], info) end,
      "does not match lib.typ banner")
  end)

  it("accepts a correct block without throwing", function()
    local f = tmpfile("good", [[
/// Summary.
///
/// @category Core
/// @param x X.
/// @returns A thing.
#let foo(x: 1) = none
]])
    local parsed = parser.parse_file(f)
    local info = lib_info({ { name = "foo", category = "Core" } })
    parser.validate_function(parsed.functions[1], info)
  end)
end)

-- -----------------------------------------------------------------------
describe("parser: @example handling", function()
  it("captures renderable example with //| attributes", function()
    local f = tmpfile("example", [[
/// Summary.
///
/// @category Core
/// @example
/// ```
/// //| width: 10cm
/// //| height: 6cm
/// #plot(data: d, mapping: aes(x: "x", y: "y"))
/// ```
#let foo() = none
]])
    local parsed = parser.parse_file(f)
    local exs = parsed.functions[1].doc.examples
    assert_eq(#exs, 1)
    assert_true(exs[1].render)
    assert_eq(exs[1].attributes.width, "10cm")
    assert_eq(exs[1].attributes.height, "6cm")
    assert_contains(exs[1].source, "#plot")
  end)

  it("distinguishes @example from @example-static", function()
    local f = tmpfile("static", [[
/// Summary.
///
/// @category Core
/// @example-static
/// ```
/// foo()
/// ```
#let foo() = none
]])
    local parsed = parser.parse_file(f)
    local exs = parsed.functions[1].doc.examples
    assert_eq(#exs, 1)
    assert_eq(exs[1].render, false)
  end)

  it("errors when example fence is unterminated", function()
    local f = tmpfile("badfence", [[
/// Summary.
///
/// @category Core
/// @example
/// ```
/// foo()
#let foo() = none
]])
    assert_throws(function() parser.parse_file(f) end, "fence never closes")
  end)
end)

-- -----------------------------------------------------------------------
describe("parser: parse_lib", function()
  it("extracts exports grouped by banner", function()
    local f = tmpfile("lib", [[
#import "src/plot.typ": plot
#import "src/aes.typ": aes

// Geoms.
#import "src/geom/point.typ": geom-point
#import "src/geom/line.typ": geom-line

// Stats.
#import "src/stat/bin.typ": stat-bin
]])
    local info = parser.parse_lib(f)
    assert_eq(info.exports["plot"].category, nil, "plot has no banner above it")
    assert_eq(info.exports["geom-point"].category, "Geoms")
    assert_eq(info.exports["geom-line"].category, "Geoms")
    assert_eq(info.exports["stat-bin"].category, "Stats")
    assert_eq(info.category_order[1], "Geoms")
    assert_eq(info.category_order[2], "Stats")
  end)

  it("ignores banners that aren't valid categories", function()
    local f = tmpfile("libnoisy", [[
// Nonsense banner.
#import "src/foo.typ": foo

// Geoms.
#import "src/geom/x.typ": x
]])
    local info = parser.parse_lib(f)
    assert_eq(#info.category_order, 1)
    assert_eq(info.category_order[1], "Geoms")
  end)
end)

-- -----------------------------------------------------------------------
describe("resolve: cross-references", function()
  it("warns on unresolved @ref (non-strict)", function()
    local out = resolve.resolve_refs_in_text("See @missing for details.", "core/foo.qmd", {}, false, "x.typ", 1)
    assert_contains(out, "@missing")
  end)

  it("errors on unresolved @ref under strict", function()
    assert_throws(function()
      resolve.resolve_refs_in_text("See @missing.", "core/foo.qmd", {}, true, "x.typ", 1)
    end, "unresolved")
  end)

  it("resolves @ref to relative link", function()
    local index = {
      bar = { name = "bar", category = "Geoms", category_slug = "geoms", qmd_path = "geoms/bar.qmd" }
    }
    local out = resolve.resolve_refs_in_text("See @bar.", "core/foo.qmd", index, false)
    assert_contains(out, "[`bar`](../geoms/bar.qmd)")
  end)

  it("produces relative links across categories", function()
    assert_eq(resolve.relative_link("core/foo.qmd", "geoms/bar.qmd"), "../geoms/bar.qmd")
    assert_eq(resolve.relative_link("geoms/foo.qmd", "geoms/bar.qmd"), "bar.qmd")
    assert_eq(resolve.relative_link("index.qmd", "geoms/bar.qmd"), "geoms/bar.qmd")
  end)
end)

-- -----------------------------------------------------------------------
describe("config_patch: _metadata.yml removal", function()
  local config_patch = require("config_patch")

  it("is a no-op when no managed block exists", function()
    local path = string.format("%s/_tmp_meta.yml", TEST_DIR)
    util.write_file(path, "existing-key: value\n")
    config_patch.patch_metadata_yml(path)
    assert_eq(util.read_file(path), "existing-key: value\n", "file should be unchanged")
    os.execute(string.format("rm -f %q", path))
  end)

  it("removes a legacy managed block while preserving surrounding content", function()
    local path = string.format("%s/_tmp_meta3.yml", TEST_DIR)
    util.write_file(path, [[
other: yes
# >>> typstdoc (managed block; do not edit between markers)
typst-render:
  root: "."
# <<< typstdoc
]])
    config_patch.patch_metadata_yml(path)
    local content = util.read_file(path)
    assert_true(not content:find("typstdoc"), "markers should be removed")
    assert_true(not content:find("typst%-render:"), "block body should be removed")
    assert_contains(content, "other: yes")
    os.execute(string.format("rm -f %q", path))
  end)

  it("removal is idempotent", function()
    local path = string.format("%s/_tmp_meta2.yml", TEST_DIR)
    util.write_file(path, "existing-key: value\n")
    config_patch.patch_metadata_yml(path)
    local first = util.read_file(path)
    config_patch.patch_metadata_yml(path)
    assert_eq(first, util.read_file(path), "second run changed the file")
    os.execute(string.format("rm -f %q", path))
  end)
end)

-- -----------------------------------------------------------------------
describe("config_patch: _quarto.yml + _extensions-metadata.yml", function()
  local config_patch = require("config_patch")

  local function tmp_quarto(name, body)
    local path = string.format("%s/_tmp_%s", TEST_DIR, name)
    util.write_file(path, body)
    return path
  end

  local function sibling(path, filename)
    local dir = path:match("(.*)/[^/]+$") or "."
    return dir .. "/" .. filename
  end

  local function rm(path)
    os.execute(string.format("rm -f %q", path))
  end

  it("writes _extensions-metadata.yml and adds it to metadata-files", function()
    local path = tmp_quarto("quarto.yml", "project:\n  type: website\n")
    config_patch.patch_quarto_yml(path, "_sidebar-reference.yml")
    local quarto = util.read_file(path)
    assert_contains(quarto, "metadata-files:")
    assert_contains(quarto, "- _extensions-metadata.yml")
    assert_contains(quarto, "- _sidebar-reference.yml")
    assert_true(not quarto:find("# >>> typstdoc"), "no managed block in _quarto.yml")

    local ext_path = sibling(path, "_extensions-metadata.yml")
    local ext = util.read_file(ext_path)
    assert_contains(ext, "filters:")
    assert_contains(ext, "- typst-render")
    assert_contains(ext, "extensions:")
    assert_contains(ext, "typst-render:")
    assert_contains(ext, "output-directory:")
    assert_contains(ext, "preamble:")
    rm(path); rm(ext_path); rm(sibling(path, "_typst-preamble.typ"))
  end)

  it("removes a legacy managed block from _quarto.yml", function()
    local path = tmp_quarto("quarto2.yml", [[
project:
  type: website

# >>> typstdoc (managed block; do not edit between markers)
filters:
  - old-filter
typst-render:
  root: "stale"
# <<< typstdoc
]])
    config_patch.patch_quarto_yml(path, "_sidebar-reference.yml")
    local content = util.read_file(path)
    assert_true(not content:find("# >>> typstdoc"), "legacy markers should be gone")
    assert_true(not content:find("old%-filter"), "stale filter should be gone")
    assert_true(not content:find('root:%s*"stale"'), "stale root should be gone")
    assert_contains(content, "- _extensions-metadata.yml")
    rm(path); rm(sibling(path, "_extensions-metadata.yml")); rm(sibling(path, "_typst-preamble.typ"))
  end)

  it("is idempotent across re-runs (_quarto.yml and sibling files)", function()
    local path = tmp_quarto("quarto3.yml", "project:\n  type: website\n")
    config_patch.patch_quarto_yml(path, "_sidebar-reference.yml")
    local first_quarto = util.read_file(path)
    local first_ext = util.read_file(sibling(path, "_extensions-metadata.yml"))
    local first_preamble = util.read_file(sibling(path, "_typst-preamble.typ"))
    config_patch.patch_quarto_yml(path, "_sidebar-reference.yml")
    assert_eq(first_quarto, util.read_file(path), "_quarto.yml changed on second run")
    assert_eq(first_ext, util.read_file(sibling(path, "_extensions-metadata.yml")),
      "_extensions-metadata.yml changed on second run")
    assert_eq(first_preamble, util.read_file(sibling(path, "_typst-preamble.typ")),
      "_typst-preamble.typ changed on second run")
    rm(path); rm(sibling(path, "_extensions-metadata.yml")); rm(sibling(path, "_typst-preamble.typ"))
  end)

  it("preserves an existing metadata-files list when inserting entries", function()
    local path = tmp_quarto("quarto4.yml", "metadata-files:\n  - _other.yml\n")
    config_patch.patch_quarto_yml(path, "_sidebar-reference.yml")
    local content = util.read_file(path)
    assert_contains(content, "_other.yml")
    assert_contains(content, "_sidebar-reference.yml")
    assert_contains(content, "_extensions-metadata.yml")
    rm(path); rm(sibling(path, "_extensions-metadata.yml")); rm(sibling(path, "_typst-preamble.typ"))
  end)

  it("does not duplicate metadata-files entries on re-run", function()
    local path = tmp_quarto("quarto5.yml",
      "metadata-files:\n  - _sidebar-reference.yml\n  - _extensions-metadata.yml\n")
    config_patch.patch_quarto_yml(path, "_sidebar-reference.yml")
    local content = util.read_file(path)
    local _, side_count = content:gsub("_sidebar%-reference%.yml", "")
    local _, ext_count = content:gsub("_extensions%-metadata%.yml", "")
    assert_eq(side_count, 1, "sidebar entry should not duplicate")
    assert_eq(ext_count, 1, "extensions entry should not duplicate")
    rm(path); rm(sibling(path, "_extensions-metadata.yml")); rm(sibling(path, "_typst-preamble.typ"))
  end)
end)

-- -----------------------------------------------------------------------
cleanup()

io.write(string.format("\n%d passed, %d failed\n", T.passed, T.failed))
if T.failed > 0 then os.exit(1) end
