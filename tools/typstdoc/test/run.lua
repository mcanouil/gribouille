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
local examples = require("examples")

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

  it("unescapes \\@ to @ in /// and ///! comment lines", function()
    local f = tmpfile("escaped_at", [[
///! Module summary mentioning \@aes and \@plot.

/// Summary referencing \@aes inline.
///
/// Body that links \@geom-line and \@plot too.
///
/// @category Core
/// \@param x The x value, see \@aes.
/// @see \@geom-line, \@aes
#let foo(x: 1) = none
]])
    local parsed = parser.parse_file(f)
    local fn = parsed.functions[1]
    assert_eq(fn.name, "foo")
    assert_eq(fn.doc.summary, "Summary referencing @aes inline.")
    assert_contains(fn.doc.description[1], "@geom-line")
    assert_contains(fn.doc.description[1], "@plot")
    assert_eq(#fn.doc.params, 1)
    assert_eq(fn.doc.params[1].name, "x")
    assert_contains(fn.doc.params[1].description, "@aes")
    assert_eq(#fn.doc.see, 2)
    assert_eq(fn.doc.see[1], "@geom-line")
    assert_eq(fn.doc.see[2], "@aes")
    assert_true(parsed.module ~= nil, "expected module block")
    local mod = table.concat(parsed.module.lines, "\n")
    assert_contains(mod, "@aes")
    assert_contains(mod, "@plot")
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

  it("ignores // comments inside a multi-line signature", function()
    local f = tmpfile("comment-sig", [[
/// Summary.
///
/// @category Core
/// @param a A.
/// @param b B.
#let foo(
  a,  // pairs like (x, y) leave a paren open: (
  b,
) = a + b
]])
    local parsed = parser.parse_file(f)
    local fn = parsed.functions[1]
    assert_eq(#fn.signature_params, 2)
    assert_eq(fn.signature_params[1].name, "a")
    assert_eq(fn.signature_params[2].name, "b")
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
describe("parser: @examples handling", function()
  it("captures renderable example with //| attributes", function()
    local f = tmpfile("example", [[
/// Summary.
///
/// @category Core
/// @examples
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
    assert_eq(#exs[1].segments, 1)
    assert_eq(exs[1].segments[1].kind, "code")
    assert_eq(exs[1].segments[1].attributes.width, "10cm")
    assert_eq(exs[1].segments[1].attributes.height, "6cm")
    assert_contains(exs[1].segments[1].source, "#plot")
  end)

  it("distinguishes @examples from @examples-static", function()
    local f = tmpfile("static", [[
/// Summary.
///
/// @category Core
/// @examples-static
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
/// @examples
/// ```
/// foo()
#let foo() = none
]])
    assert_throws(function() parser.parse_file(f) end, "fence never closes")
  end)

  it("errors when @examples block has no code fence", function()
    local f = tmpfile("nofence", [[
/// Summary.
///
/// @category Core
/// @examples Just prose, no fence.
/// @returns Nothing.
#let foo() = none
]])
    assert_throws(function() parser.parse_file(f) end, "must contain at least one code fence")
  end)

  it("captures inline caption on the tag line", function()
    local f = tmpfile("inlinecap", [[
/// Summary.
///
/// @category Core
/// @examples Default invocation.
/// ```
/// foo()
/// ```
#let foo() = none
]])
    local parsed = parser.parse_file(f)
    local exs = parsed.functions[1].doc.examples
    assert_eq(#exs[1].segments, 2)
    assert_eq(exs[1].segments[1].kind, "prose")
    assert_eq(exs[1].segments[1].text, "Default invocation.")
    assert_eq(exs[1].segments[2].kind, "code")
  end)

  it("captures multi-line caption between tag and fence", function()
    local f = tmpfile("multilinecap", [[
/// Summary.
///
/// @category Core
/// @examples
/// First sentence of the caption.
/// Second sentence on the next line.
///
/// A second paragraph.
/// ```
/// foo()
/// ```
#let foo() = none
]])
    local parsed = parser.parse_file(f)
    local exs = parsed.functions[1].doc.examples
    assert_eq(exs[1].segments[1].kind, "prose")
    assert_contains(exs[1].segments[1].text, "First sentence of the caption.")
    assert_contains(exs[1].segments[1].text, "Second sentence on the next line.")
    assert_contains(exs[1].segments[1].text, "\n\nA second paragraph.")
  end)

  it("collects multiple fences and prose into one block of segments", function()
    local f = tmpfile("blockmulti", [[
/// Summary.
///
/// @category Core
/// @examples
/// First step prose.
/// ```
/// foo()
/// ```
///
/// Second step prose.
/// ```
/// bar()
/// ```
#let foo() = none
]])
    local parsed = parser.parse_file(f)
    local exs = parsed.functions[1].doc.examples
    assert_eq(#exs, 1)
    assert_true(exs[1].render)
    assert_eq(#exs[1].segments, 4)
    assert_eq(exs[1].segments[1].kind, "prose")
    assert_eq(exs[1].segments[1].text, "First step prose.")
    assert_eq(exs[1].segments[2].kind, "code")
    assert_contains(exs[1].segments[2].source, "foo()")
    assert_eq(exs[1].segments[3].kind, "prose")
    assert_eq(exs[1].segments[3].text, "Second step prose.")
    assert_eq(exs[1].segments[4].kind, "code")
    assert_contains(exs[1].segments[4].source, "bar()")
  end)

  it("closes @examples block at the next @tag", function()
    local f = tmpfile("blockclose", [[
/// Summary.
///
/// @category Core
/// @examples
/// Setup.
/// ```
/// foo()
/// ```
/// @returns A thing.
#let foo() = none
]])
    local parsed = parser.parse_file(f)
    local doc = parsed.functions[1].doc
    assert_eq(doc.returns, "A thing.")
    assert_eq(#doc.examples, 1)
    assert_eq(#doc.examples[1].segments, 2)
    assert_eq(doc.examples[1].segments[1].text, "Setup.")
  end)

  it("treats @examples-static as a block with non-rendered code", function()
    local f = tmpfile("staticblock", [[
/// Summary.
///
/// @category Core
/// @examples-static
/// Step 1.
/// ```
/// foo()
/// ```
///
/// Step 2.
/// ```
/// bar()
/// ```
#let foo() = none
]])
    local parsed = parser.parse_file(f)
    local exs = parsed.functions[1].doc.examples
    assert_eq(#exs, 1)
    assert_eq(exs[1].render, false)
    assert_eq(#exs[1].segments, 4)
    assert_eq(exs[1].segments[2].kind, "code")
    assert_eq(exs[1].segments[4].kind, "code")
  end)

  it("rejects unknown legacy @example tag", function()
    local f = tmpfile("legacy", [[
/// Summary.
///
/// @category Core
/// @example
/// ```
/// foo()
/// ```
#let foo() = none
]])
    assert_throws(function() parser.parse_file(f) end, "unknown tag")
  end)
end)

-- -----------------------------------------------------------------------
describe("parser: indented continuation lines", function()
  it("merges indented continuation into @param description", function()
    local f = tmpfile("paramcont", [[
/// Summary.
///
/// @category Core
/// @param x The x value
///   continues on a second line
///   and ends here.
#let foo(x: 1) = none
]])
    local parsed = parser.parse_file(f)
    local p = parsed.functions[1].doc.params[1]
    assert_eq(p.name, "x")
    assert_eq(p.description, "The x value continues on a second line and ends here.")
  end)

  it("keeps a leading @ref on an indented line as part of the description", function()
    local f = tmpfile("paramref", [[
/// Summary.
///
/// @category Core
/// @param x The x value, see
///   \@bar for more info.
#let foo(x: 1) = none
]])
    local parsed = parser.parse_file(f)
    local p = parsed.functions[1].doc.params[1]
    assert_eq(p.description, "The x value, see @bar for more info.")
  end)

  it("merges indented continuation into @returns", function()
    local f = tmpfile("returnscont", [[
/// Summary.
///
/// @category Core
/// @returns A dictionary
///   with several fields.
#let foo() = none
]])
    local parsed = parser.parse_file(f)
    assert_eq(parsed.functions[1].doc.returns, "A dictionary with several fields.")
  end)

  it("starts a new tag on a non-indented @param line", function()
    local f = tmpfile("twoparams", [[
/// Summary.
///
/// @category Core
/// @param x The x value
///   continues here.
/// @param y The y value.
#let foo(x: 1, y: 2) = none
]])
    local parsed = parser.parse_file(f)
    local params = parsed.functions[1].doc.params
    assert_eq(#params, 2)
    assert_eq(params[1].description, "The x value continues here.")
    assert_eq(params[2].description, "The y value.")
  end)
end)

-- -----------------------------------------------------------------------
describe("parser: markdown lists in description", function()
  it("preserves a three-item list as a single description entry with newlines", function()
    local f = tmpfile("list_basic", [[
/// Summary line.
///
/// Columns:
///
/// - alpha.
/// - beta.
/// - gamma.
///
/// @category Core
#let foo() = none
]])
    local parsed = parser.parse_file(f)
    local desc = parsed.functions[1].doc.description
    assert_eq(#desc, 2, "expected prose paragraph + list as two entries")
    assert_eq(desc[1], "Columns:")
    assert_eq(desc[2], "- alpha.\n- beta.\n- gamma.")
  end)

  it("folds an indented continuation into the preceding list item", function()
    local f = tmpfile("list_cont", [[
/// Summary line.
///
/// Returns:
///
/// - both originals when neither or both aesthetics are set, so geoms keep
///   their historical look when the user touches nothing or supplies both;
/// - `(c, none)` when only colour is set.
///
/// @category Core
#let foo() = none
]])
    local parsed = parser.parse_file(f)
    local desc = parsed.functions[1].doc.description
    assert_eq(#desc, 2, "expected prose paragraph + list as two entries")
    local lines = {}
    for line in (desc[2] .. "\n"):gmatch("([^\n]*)\n") do
      table.insert(lines, line)
    end
    assert_eq(#lines, 2, "expected two list items after continuation merge")
    assert_eq(lines[1]:sub(1, 2), "- ")
    assert_eq(lines[2]:sub(1, 2), "- ")
    assert_contains(lines[1], "their historical look when the user touches nothing")
    assert_contains(lines[2], "`(c, none)` when only colour is set.")
  end)

  it("keeps a list and a following prose paragraph as separate entries", function()
    local f = tmpfile("list_then_prose", [[
/// Summary line.
///
/// - one.
/// - two.
///
/// Some prose afterwards.
///
/// @category Core
#let foo() = none
]])
    local parsed = parser.parse_file(f)
    local desc = parsed.functions[1].doc.description
    assert_eq(#desc, 2, "expected list + prose as two entries")
    assert_contains(desc[1], "\n- two")
    assert_eq(desc[2], "Some prose afterwards.")
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
describe("parser: @subcategory", function()
  it("captures @subcategory on the doc block", function()
    local f = tmpfile("subcat", [[
/// A foo.
///
/// @category Geoms
/// @subcategory Reference lines
#let foo() = none
]])
    local fn = parser.parse_file(f).functions[1]
    assert_eq(fn.doc.category, "Geoms")
    assert_eq(fn.doc.subcategory, "Reference lines")
  end)

  it("leaves subcategory nil when the tag is absent", function()
    local f = tmpfile("nosubcat", [[
/// A foo.
///
/// @category Geoms
#let foo() = none
]])
    assert_eq(parser.parse_file(f).functions[1].doc.subcategory, nil)
  end)

  it("rejects a duplicate @subcategory", function()
    local f = tmpfile("dupsubcat", [[
/// A foo.
///
/// @category Geoms
/// @subcategory A
/// @subcategory B
#let foo() = none
]])
    assert_throws(function() parser.parse_file(f) end, "duplicate @subcategory")
  end)

  it("rejects an empty @subcategory", function()
    local f = tmpfile("emptysubcat", [[
/// A foo.
///
/// @category Geoms
/// @subcategory
#let foo() = none
]])
    assert_throws(function() parser.parse_file(f) end, "empty @subcategory")
  end)
end)

-- -----------------------------------------------------------------------
describe("resolve: cross-references", function()
  local bar_index = {
    bar = { name = "bar", category = "Geoms", category_slug = "geoms", qmd_path = "geoms/bar.qmd" }
  }

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
    local out = resolve.resolve_refs_in_text("See @bar.", "core/foo.qmd", bar_index, false)
    assert_contains(out, "[`bar`](../geoms/bar.qmd)")
  end)

  it("produces relative links across categories", function()
    assert_eq(resolve.relative_link("core/foo.qmd", "geoms/bar.qmd"), "../geoms/bar.qmd")
    assert_eq(resolve.relative_link("geoms/foo.qmd", "geoms/bar.qmd"), "bar.qmd")
    assert_eq(resolve.relative_link("index.qmd", "geoms/bar.qmd"), "geoms/bar.qmd")
  end)

  it("includes trailing () in the resolved link's code span", function()
    local out = resolve.resolve_refs_in_text("Call @bar() now.", "core/foo.qmd", bar_index, false)
    assert_contains(out, "[`bar()`](../geoms/bar.qmd)")
    assert_true(not out:find("`bar`()", 1, true), "() must not leak outside the code span")
  end)

  it("preserves trailing () on unresolved @ref (non-strict)", function()
    local out = resolve.resolve_refs_in_text("See @missing() please.", "core/foo.qmd", {}, false, "x.typ", 1)
    assert_contains(out, "@missing()")
  end)

  it("errors on unresolved @ref() under strict and mentions the parens", function()
    assert_throws(function()
      resolve.resolve_refs_in_text("See @missing().", "core/foo.qmd", {}, true, "x.typ", 1)
    end, "@missing%(%)")
  end)

  it("leaves a lone opening ( untouched: @bar(x reads as a call signature", function()
    local out = resolve.resolve_refs_in_text("(@bar(x)", "core/foo.qmd", bar_index, false)
    assert_contains(out, "@bar(x")
  end)

  it("resolves a @ref closing a parenthetical and keeps the )", function()
    local out = resolve.resolve_refs_in_text("(e.g., @bar) tail", "core/foo.qmd", bar_index, false)
    assert_contains(out, "(e.g., [`bar`](../geoms/bar.qmd)) tail")
  end)

  it("resolves a @ref followed by punctuation", function()
    local out = resolve.resolve_refs_in_text("See @bar, then @bar.", "core/foo.qmd", bar_index, false)
    assert_contains(out, "[`bar`](../geoms/bar.qmd), then [`bar`](../geoms/bar.qmd).")
  end)

  it("errors on an unresolved @ref closing a parenthetical under strict", function()
    assert_throws(function()
      resolve.resolve_refs_in_text("(see @missing).", "core/foo.qmd", {}, true, "x.typ", 1)
    end, "unresolved")
  end)
end)

-- -----------------------------------------------------------------------

describe("sources: @refs in doc comments", function()
  local repo_root = ROOT:match("^(.*)/tools/typstdoc$")
    or (ROOT == "tools/typstdoc" and ".")

  -- A ref glued to the previous character renders glued too, e.g. `for\@compose`
  -- becomes ``for[`compose`](compose.qmd)`` on the page. `(`, `[`, and `/` are
  -- legitimate: `(\@plot)`, `[\@plot]`, and `\@geom-point/\@geom-label`.
  it("every \\@ref is preceded by whitespace, (, [, / or line start", function()
    local problems = {}
    local listing = io.popen("find " .. repo_root .. "/src -name '*.typ' | sort")
    for path in listing:lines() do
      local lineno = 0
      for line in io.lines(path) do
        lineno = lineno + 1
        if line:match("^%s*///") then
          local from = 1
          while true do
            local s = line:find("\\@", from, true)
            if not s then break end
            local before = s > 1 and line:sub(s - 1, s - 1) or ""
            if before ~= "" and not before:match("[%s%(%[/]") then
              local rel = path:gsub("^" .. repo_root:gsub("%p", "%%%0") .. "/", "")
              table.insert(problems, string.format("%s:%d: %s", rel, lineno, line:match("^%s*(.-)%s*$")))
            end
            from = s + 2
          end
        end
      end
    end
    listing:close()
    if #problems > 0 then
      error("\\@ref glued to the preceding character:\n  " .. table.concat(problems, "\n  "), 2)
    end
  end)
end)

-- -----------------------------------------------------------------------
describe("render: summaries resolve cross-references", function()
  local render = require("render")

  local function parsed_functions(body)
    local f = tmpfile("xref_summary", body)
    return parser.parse_file(f).functions
  end

  local TWO_GEOMS = [[
/// A foo that pairs with \@bar.
///
/// @category Geoms
#let foo() = none

/// A bar.
///
/// @category Geoms
#let bar() = none
]]

  it("resolves @ref in the top index bullet", function()
    local fns = parsed_functions(TWO_GEOMS)
    local index = resolve.build_index(fns)
    local body = render.render_top_index({ "Geoms" }, fns, index, false)
    assert_contains(body, "- [`foo`](geoms/foo.qmd) - A foo that pairs with [`bar`](geoms/bar.qmd).")
    assert_true(not body:find("@bar", 1, true), "bare @bar should be resolved away")
  end)

  it("resolves @ref in the category index bullet", function()
    local fns = parsed_functions([[
/// A foo that pairs with \@aes.
///
/// @category Geoms
#let foo() = none

/// Bind columns.
///
/// @category Core
#let aes() = none
]])
    local index = resolve.build_index(fns)
    local body = render.render_category_index("Geoms", fns, {}, index, false)
    assert_contains(body, "- [`foo`](foo.qmd) - A foo that pairs with [`aes`](../core/aes.qmd).")
  end)

  it("resolves @ref in the function-page subtitle", function()
    local fns = parsed_functions(TWO_GEOMS)
    local index = resolve.build_index(fns)
    local body = render.render_function(fns[1], index, { strict = false })
    assert_contains(body, 'subtitle: "A foo that pairs with [`bar`](bar.qmd)."')
  end)

  it("errors on unresolved @ref in a summary under strict", function()
    local fns = parsed_functions([[
/// A foo that pairs with \@missing.
///
/// @category Geoms
#let foo() = none
]])
    local index = resolve.build_index(fns)
    assert_throws(function()
      render.render_top_index({ "Geoms" }, fns, index, true)
    end, "unresolved")
  end)
end)

-- -----------------------------------------------------------------------
describe("render: variadic forwarding in Usage and Parameters", function()
  local render = require("render")

  local function parsed_functions(body)
    local f = tmpfile("variadic_render", body)
    return parser.parse_file(f).functions
  end

  it("expands a pure `..rest` forwarder to its documented params", function()
    local fns = parsed_functions([[
/// A forwarder.
///
/// @category Core
/// @param name Legend title.
/// @param palette Colour source.
/// @returns Scale.
#let foo(..args) = bar("colour", ..args)
]])
    local body = render.render_function(fns[1], {}, { strict = false })
    assert_contains(body, "foo(\n  name,\n  palette,\n)")
    assert_contains(body, "| `name` |  | Legend title. |")
    assert_contains(body, "| `palette` |  | Colour source. |")
    assert_true(not body:find("..args", 1, true), "opaque ..args should not appear")
  end)

  it("keeps `..rest` when a @param of the same name documents it", function()
    local fns = parsed_functions([[
/// A sink.
///
/// @category Core
/// @param args Named specs keyed by aesthetic.
/// @returns Guides.
#let foo(..args) = none
]])
    local body = render.render_function(fns[1], {}, { strict = false })
    assert_contains(body, "foo(\n  ..args,\n)")
    assert_contains(body, "| `..args` |  | Named specs keyed by aesthetic. |")
  end)

  it("renders explicit params, then delegated, then the rest, for a mixed signature", function()
    local fns = parsed_functions([[
/// A dispatcher.
///
/// @category Core
/// @param geom Geom name.
/// @param clip Whether to clip.
/// @param ..fields Forwarded named arguments.
/// @returns Layer.
#let foo(geom, ..fields) = none
]])
    local body = render.render_function(fns[1], {}, { strict = false })
    assert_contains(body, "foo(\n  geom,\n  ..fields,\n)")
    assert_contains(body, "| `geom` |  | Geom name. |")
    assert_contains(body, "| `clip` |  | Whether to clip. |")
    assert_contains(body, "| `..fields` |  | Forwarded named arguments. |")
  end)

  it("keeps the `..args` signature and lists keys in a sub-list under the table", function()
    local fns = parsed_functions([[
/// A sink with known keys.
///
/// @category Core
/// @param args Named specs keyed by aesthetic.
/// @named-keys colour fill size : Channel `{}`.
/// @returns Guides.
#let foo(..args) = none
]])
    local body = render.render_function(fns[1], {}, { strict = false })
    assert_contains(body, "foo(\n  ..args,\n)")
    assert_contains(body, "| `..args` |  | Named specs keyed by aesthetic. |")
    assert_contains(body, "Keys accepted by `..args`:")
    assert_contains(body, "- `colour`: Channel `colour`.")
    assert_contains(body, "- `fill`: Channel `fill`.")
    assert_true(not body:find("| `colour` |", 1, true), "keys should not be table rows")
  end)

  it("lets an explicit @param override the shared template for a single key", function()
    local fns = parsed_functions([[
/// A sink with one special key.
///
/// @category Core
/// @param args Named specs.
/// @named-keys colour fill default : Channel `{}`.
/// @param default Fallback guide for unset channels.
/// @returns Guides.
#let foo(..args) = none
]])
    local body = render.render_function(fns[1], {}, { strict = false })
    assert_contains(body, "- `colour`: Channel `colour`.")
    assert_contains(body, "- `default`: Fallback guide for unset channels.")
    assert_true(not body:find("| `default` |", 1, true), "override key should not be its own row")
  end)
end)

-- -----------------------------------------------------------------------
describe("render: @examples alt forwarding", function()
  local render = require("render")

  local function parsed_functions(body)
    local f = tmpfile("alt_forward", body)
    return parser.parse_file(f).functions
  end

  local function with_warn_capture(fn)
    local original = util.log_warn
    local captured = {}
    util.log_warn = function(msg) captured[#captured + 1] = msg end
    local ok, err = pcall(fn, captured)
    util.log_warn = original
    if not ok then error(err, 0) end
  end

  it("emits //| alt: when docstring fence carries it", function()
    local fns = parsed_functions([[
/// Sample.
///
/// @category Core
/// @examples Render with alt.
/// ```
/// //| alt: "Scatter of x against y."
/// #plot(data: d, mapping: aes(x: "x", y: "y"))
/// ```
#let foo() = none
]])
    with_warn_capture(function(captured)
      local body = render.render_function(fns[1], {}, { strict = false })
      assert_contains(body, '//| output-filename: "foo-1.svg"')
      assert_contains(body, '//| alt: "Scatter of x against y."')
      assert_eq(#captured, 0, "alt present should not warn")
    end)
  end)

  it("warns when rendered fence lacks //| alt:", function()
    local fns = parsed_functions([[
/// Sample.
///
/// @category Core
/// @examples No alt here.
/// ```
/// #plot(data: d, mapping: aes(x: "x", y: "y"))
/// ```
#let foo() = none
]])
    with_warn_capture(function(captured)
      local body = render.render_function(fns[1], {}, { strict = false })
      assert_true(not body:find('//| alt:', 1, true), "no alt directive expected")
      assert_eq(#captured, 1, "exactly one warning expected")
      assert_contains(captured[1], "@examples fence 1 for `foo` missing")
    end)
  end)

  it("passes alt value through verbatim (no re-quoting)", function()
    local fns = parsed_functions([[
/// Sample.
///
/// @category Core
/// @examples
/// ```
/// //| alt: "Quoted with \"inner\" quotes."
/// #plot()
/// ```
#let foo() = none
]])
    with_warn_capture(function(captured)
      local body = render.render_function(fns[1], {}, { strict = false })
      assert_contains(body, [[//| alt: "Quoted with \"inner\" quotes."]])
      assert_eq(#captured, 0)
    end)
  end)

  it("does not warn for @examples-static fences", function()
    local fns = parsed_functions([[
/// Sample.
///
/// @category Core
/// @examples-static
/// ```
/// foo()
/// ```
#let foo() = none
]])
    with_warn_capture(function(captured)
      render.render_function(fns[1], {}, { strict = false })
      assert_eq(#captured, 0, "static examples must not trigger alt warnings")
    end)
  end)
end)

-- -----------------------------------------------------------------------
describe("render: @subcategory grouping", function()
  local render = require("render")

  local function parsed_functions(body)
    local f = tmpfile("subcat_render", body)
    return parser.parse_file(f).functions
  end

  -- One ungrouped function, two subcategories ("Points", "Reference lines");
  -- "Points" sorts before "Reference lines".
  local MIXED_GEOMS = [[
/// A blank.
///
/// @category Geoms
#let geom-blank() = none

/// An abline.
///
/// @category Geoms
/// @subcategory Reference lines
#let geom-abline() = none

/// A point.
///
/// @category Geoms
/// @subcategory Points
#let geom-point() = none

/// A hline.
///
/// @category Geoms
/// @subcategory Reference lines
#let geom-hline() = none
]]

  local FLAT_GEOMS = [[
/// A foo.
///
/// @category Geoms
#let foo() = none

/// A bar.
///
/// @category Geoms
#let bar() = none
]]

  it("emits H3 sub-sections in the top index, ungrouped first, groups alphabetical", function()
    local fns = parsed_functions(MIXED_GEOMS)
    local index = resolve.build_index(fns)
    local body = render.render_top_index({ "Geoms" }, fns, index, false)
    assert_contains(body, "## [Geoms](geoms/index.qmd)")
    assert_contains(body, "- [`geom-blank`](geoms/geom-blank.qmd) - A blank.")
    assert_contains(body, "### Points")
    assert_contains(body, "### Reference lines")
    local pos_blank = body:find("geom-blank", 1, true)
    local pos_points = body:find("### Points", 1, true)
    local pos_reflines = body:find("### Reference lines", 1, true)
    assert_true(pos_blank < pos_points, "ungrouped bullets come before the first sub-section")
    assert_true(pos_points < pos_reflines, "sub-sections are alphabetical")
    -- alphabetical within a group: geom-abline before geom-hline
    assert_true(body:find("geom-abline", 1, true) < body:find("geom-hline", 1, true))
  end)

  it("leaves a category with no @subcategory flat in the top index", function()
    local fns = parsed_functions(FLAT_GEOMS)
    local index = resolve.build_index(fns)
    local body = render.render_top_index({ "Geoms" }, fns, index, false)
    assert_true(not body:find("### ", 1, true), "no sub-headings without @subcategory")
  end)

  it("emits ## Functions then ## <subcategory> in the category index", function()
    local fns = parsed_functions(MIXED_GEOMS)
    local index = resolve.build_index(fns)
    local body = render.render_category_index("Geoms", fns, {}, index, false)
    assert_contains(body, "## Functions")
    assert_contains(body, "- [`geom-blank`](geom-blank.qmd) - A blank.")
    assert_contains(body, "## Points")
    assert_contains(body, "## Reference lines")
    assert_true(body:find("## Functions", 1, true) < body:find("## Points", 1, true))
    assert_true(body:find("## Points", 1, true) < body:find("## Reference lines", 1, true))
  end)

  it("keeps the category index flat with no @subcategory", function()
    local fns = parsed_functions(FLAT_GEOMS)
    local index = resolve.build_index(fns)
    local body = render.render_category_index("Geoms", fns, {}, index, false)
    assert_contains(body, "## Functions")
    local _, h2_count = body:gsub("\n## ", "")
    assert_eq(h2_count, 1, "exactly one H2 heading without @subcategory")
    -- alphabetical: bar before foo
    assert_true(body:find("`bar`", 1, true) < body:find("`foo`", 1, true))
  end)

  it("nests sidebar sections per subcategory", function()
    local fns = parsed_functions(MIXED_GEOMS)
    local body = render.render_sidebar({ "Geoms" }, fns)
    assert_contains(body, "collapse-level: 2")
    assert_contains(body, "            - section: Geoms")
    assert_contains(body, "                - reference/geoms/geom-blank.qmd")
    assert_contains(body, "                - section: Points")
    assert_contains(body, "                    - reference/geoms/geom-point.qmd")
    assert_contains(body, "                - section: Reference lines")
    assert_true(body:find("geom-blank", 1, true) < body:find("section: Points", 1, true),
      "ungrouped files listed before nested sub-sections")
  end)

  it("quotes a subcategory name that contains a colon in the sidebar", function()
    local fns = parsed_functions([[
/// A scale.
///
/// @category Scales
/// @subcategory Colour and fill: binned
#let scale-steps() = none
]])
    local body = render.render_sidebar({ "Scales" }, fns)
    assert_contains(body, '- section: "Colour and fill: binned"')
  end)

  it("keeps the function-page frontmatter to the keys Quarto renders", function()
    local fns = parsed_functions(MIXED_GEOMS)
    local index = resolve.build_index(fns)
    local abline
    for _, fn in ipairs(fns) do
      if fn.name == "geom-abline" then abline = fn end
    end
    local body = render.render_function(abline, index, { strict = false })
    assert_contains(body, "title: geom-abline")
    assert_contains(body, "subtitle: An abline.")
    assert_contains(body, "engine: markdown")
    assert_true(not body:find("subcategory:", 1, true),
      "classification reaches the reader through the sidebar, not the frontmatter")
  end)
end)

-- -----------------------------------------------------------------------
describe("theme_keys: extractor + table render", function()
  local theme_keys = require("theme_keys")

  it("structured_keys lists element surfaces and omits scalar/colour keys", function()
    local keys = theme_keys.structured_keys()
    local set = {}
    for _, k in ipairs(keys) do set[k] = true end
    assert_eq(keys[1], "text", "starts with the roots group")
    assert_eq(keys[#keys], "geom", "ends with the geom group")
    assert_true(set["panel-grid"], "includes panel surfaces")
    assert_true(set["legend-bar"], "includes legend surfaces")
    assert_true(not set["legend-key"] and not set["legend-position"],
      "omits the scalar legend keys that live inside the legend group")
    assert_true(set["axis-ticks"], "includes the tick surface")
    assert_true(not set["ink"] and not set["paper"] and not set["accent"], "omits the colours group")
  end)

  local DEFAULTS_BODY = [[
#let _tr-ink = black
#let _tr-paper = white

#let default-theme = (
  kind: "theme",
  name: "grey",

  ink: _tr-ink,
  paper: _tr-paper,
  accent: rgb("#3366FF"),

  text: element-text(size: 9pt),
  line: element-line(thickness: 0.5pt),
  rect: element-rect(),

  axis-text: element-text(size: 8pt),
  axis-title: element-text(size: 9pt),
  panel-grid: element-line(thickness: 0.5pt),
  panel-background: element-rect(),

  plot-margin: margin(),
  axis-ticks: element-tick(stroke: 0.5pt, length: 0.1cm),
)
]]

  local THEME_BODY = [[
#let _surface-parent = {
  let out = (
    "axis-text": "text",
    "axis-title": "text",
    "panel-grid": "line",
    "panel-background": "rect",
  )
  for fam in ("axis-text", "axis-title") {
    out.insert(fam + "-x", fam)
  }
  out
}
]]

  it("read_default_theme classifies every value kind", function()
    local path = tmpfile("theme_defaults", DEFAULTS_BODY)
    local _, defaults = theme_keys.read_default_theme(path)
    assert_eq(defaults["text"].kind, "element-text")
    assert_eq(defaults["text"].default, "element-text(size: 9pt)")
    assert_eq(defaults["line"].kind, "element-line")
    assert_eq(defaults["rect"].kind, "element-rect")
    assert_eq(defaults["ink"].kind, "colour")
    assert_eq(defaults["ink"].default, "black")
    assert_eq(defaults["paper"].default, "white")
    assert_eq(defaults["accent"].default, 'rgb("#3366FF")')
    assert_eq(defaults["plot-margin"].kind, "margin")
    assert_eq(defaults["plot-margin"].default, "margin()")
    assert_eq(defaults["axis-ticks"].kind, "element-tick")
    assert_eq(defaults["axis-ticks"].default,
      "element-tick(stroke: 0.5pt, length: 0.1cm)")
    assert_true(defaults["kind"] ~= nil, "raw `kind` key still surfaces from parsing")
  end)

  it("read_surface_parent reads explicit entries and expands axis families", function()
    local path = tmpfile("theme_parents", THEME_BODY)
    local parents = theme_keys.read_surface_parent(path)
    assert_eq(parents["axis-text"], "text")
    assert_eq(parents["panel-grid"], "line")
    assert_eq(parents["axis-text-x"], "axis-text")
    assert_eq(parents["axis-text-x-bottom"], "axis-text-x")
    assert_eq(parents["axis-text-y-right"], "axis-text-y")
    assert_eq(parents["axis-line-x"], "axis-line",
      "axis-line variants are added even when not in the explicit dict")
    assert_eq(parents["axis-ticks-minor"], "axis-ticks",
      "minor ticks inherit the major tick surface")
    assert_eq(parents["axis-ticks-minor-x"], "axis-ticks-minor",
      "minor ticks gain a per-axis variant")
  end)

  it("render_table emits a header and one row per record", function()
    local records = {
      { key = "text", type_str = "@element-text", default_str = "element-text(size: 9pt)", parent_str = "(root)" },
      { key = "axis-text-x", type_str = "@element-text or @element-typst", default_str = "inherits", parent_str = "axis-text" },
    }
    local out = theme_keys.render_table(records)
    assert_contains(out, "| Key | Type | Default | Parent |")
    assert_contains(out, "| --- | --- | --- | --- |")
    assert_contains(out, "| `text` | @element-text | `element-text(size: 9pt)` | (root) |")
    assert_contains(out, "| `axis-text-x` | @element-text or @element-typst | inherits | `axis-text` |")
  end)

  it("uncovered_keys flags a default-theme key absent from the records", function()
    local defaults = { text = { kind = "element-text" }, mystery = { kind = "colour" }, kind = {} }
    local records = { { key = "text" } }
    local missing = theme_keys.uncovered_keys(defaults, records)
    assert_eq(#missing, 1)
    assert_eq(missing[1], "mystery")
  end)

  it("every default-theme element appears in the rendered reference table", function()
    local repo = ROOT .. "/../.."
    local _, defaults = theme_keys.read_default_theme(repo .. "/src/theme/defaults.typ")
    local parents = theme_keys.read_surface_parent(repo .. "/src/theme/theme.typ")
    local records = theme_keys.build_records(defaults, parents)
    local missing = theme_keys.uncovered_keys(defaults, records)
    assert_eq(#missing, 0, "uncovered theme keys: " .. table.concat(missing, ", "))
  end)
end)

-- -----------------------------------------------------------------------
describe("examples: gallery consistency", function()
  local gallery = [[
# header comment
- slug: minimal
  section: basics
- slug: scale-okabe-ito
  section: scales
]]

  it("parses every slug from a gallery body", function()
    local slugs = examples.parse_slugs(gallery)
    assert_true(slugs["minimal"], "minimal slug parsed")
    assert_true(slugs["scale-okabe-ito"], "kebab-case slug parsed")
    assert_eq(slugs["header"], nil, "comment line is not a slug")
  end)

  it("reports an example with no slug as an orphan", function()
    local slugs = examples.parse_slugs(gallery)
    local orphans = examples.orphans({ "minimal.typ", "missing.typ" }, slugs, {})
    assert_eq(#orphans, 1)
    assert_eq(orphans[1], "missing")
  end)

  it("excludes hero assets even without a slug", function()
    local slugs = examples.parse_slugs(gallery)
    local orphans = examples.orphans({ "gribouille.typ", "showcase.typ" }, slugs)
    assert_eq(#orphans, 0, "default EXCLUDE covers the hero assets")
  end)

  it("ignores non-typ files and sorts orphans", function()
    local slugs = examples.parse_slugs(gallery)
    local orphans = examples.orphans({ "zeta.typ", "alpha.typ", "notes.md" }, slugs, {})
    assert_eq(#orphans, 2)
    assert_eq(orphans[1], "alpha")
    assert_eq(orphans[2], "zeta")
  end)

  local intent_gallery = [[
# header comment
- slug: bar-simple
  intent: comparison
- slug: histogram
  intent: distribution
- slug: mystery
  intent: nonsense
- slug: no-intent
  title: "No intent field"
]]

  it("parses ordered slug/intent entries from a gallery body", function()
    local entries = examples.parse_entries(intent_gallery)
    assert_eq(#entries, 4)
    assert_eq(entries[1].slug, "bar-simple")
    assert_eq(entries[1].intent, "comparison")
    assert_eq(entries[3].intent, "nonsense")
    assert_eq(entries[4].intent, nil)
  end)

  it("flags missing and unknown intents", function()
    local bad = examples.bad_intents(examples.parse_entries(intent_gallery))
    assert_eq(#bad, 2)
    assert_eq(bad[1], "mystery (nonsense)")
    assert_eq(bad[2], "no-intent (missing)")
  end)

  it("accepts every documented intent key", function()
    local entries = {}
    for intent in pairs(examples.INTENTS) do
      entries[#entries + 1] = { slug = "x-" .. intent, intent = intent }
    end
    assert_eq(#examples.bad_intents(entries), 0)
  end)

  local page = [[
---
title: "Comparison and ranking"
gallery-intent: comparison
listing:
  - id: gallery
    contents: gallery.yml
    include:
      intent: comparison
---
]]

  it("reads both intent declarations from a page", function()
    local decl = examples.parse_page_intent(page)
    assert_eq(decl.declared, "comparison")
    assert_eq(decl.include, "comparison")
  end)

  it("reads a hub page that declares no listing filter", function()
    local decl = examples.parse_page_intent('---\ngallery-intent: hub\ntoc: false\n---\n')
    assert_eq(decl.declared, "hub")
    assert_eq(decl.include, nil)
  end)

  it("flags an intent with no page", function()
    local drift = examples.intent_drift({ comparison = "comparison.qmd" }, { comparison = true, themes = true })
    assert_eq(#drift, 1)
    assert_contains(drift[1], 'themes')
    assert_contains(drift[1], "no page")
  end)

  it("flags a page declaring an unknown intent", function()
    local drift = examples.intent_drift({ flow = "flow.qmd" }, { flow = false })
    assert_eq(#drift, 1)
    assert_contains(drift[1], "flow.qmd")
    assert_contains(drift[1], "unknown intent")
  end)

  it("flags a page whose two intent declarations disagree", function()
    local drift = examples.intent_drift(
      { comparison = "comparison.qmd" },
      { comparison = true },
      { ["comparison.qmd"] = "distribution" }
    )
    assert_eq(#drift, 1)
    assert_contains(drift[1], "comparison.qmd")
    assert_contains(drift[1], "distribution")
  end)

  it("ignores the hub page, which filters no intent", function()
    local drift = examples.intent_drift({ hub = "index.qmd" }, { comparison = true, hub = nil })
    assert_eq(#drift, 1, "only the page-less comparison intent should be reported")
    assert_contains(drift[1], "comparison")
  end)

  it("passes when every intent has a matching page", function()
    local pages = {}
    for intent in pairs(examples.INTENTS) do pages[intent] = intent .. ".qmd" end
    pages[examples.HUB_INTENT] = "index.qmd"
    assert_eq(#examples.intent_drift(pages), 0)
  end)
end)

-- -----------------------------------------------------------------------
describe("changelog: news announcement links", function()
  local changelog = require("changelog")

  local news_yml = [[
- version: "0.2"
  title: "Gribouille 0.2"
  date: "2026-06-03"
  path: "https://example.com/0-2/"
  description: "What is new."
- version: "0.1"
  title: "Launch"
  date: "2026-05-20"
  path: "https://example.com/0-1/"
]]

  local changelog_md = [[
# Changelog

## 0.2.0 (2026-06-03)

- A change.

## 0.1.0 (2026-05-20)

- First release.
]]

  it("parses each post into a minor-version map", function()
    local news = changelog.parse_news(news_yml)
    assert_eq(news["0.2"].title, "Gribouille 0.2")
    assert_eq(news["0.2"].path, "https://example.com/0-2/")
    assert_eq(news["0.1"].title, "Launch")
  end)

  it("injects an announcement link under the matching minor heading", function()
    local out = changelog.transform(changelog_md, changelog.parse_news(news_yml))
    assert_contains(out, "### 0.2 {#version-0-2}")
    assert_contains(out, "Read the Gribouille 0.2 announcement](https://example.com/0-2/)")
    assert_contains(out, "Read the Launch announcement](https://example.com/0-1/)")
  end)

  it("emits no link for a version without a post", function()
    local out = changelog.transform(changelog_md, { ["9.9"] = { title = "X", path = "u" } })
    assert_eq(out:find("announcement", 1, true), nil, "no announcement injected")
  end)

  it("renders unchanged when there is no news", function()
    local out = changelog.transform(changelog_md, {})
    assert_contains(out, "### 0.2 {#version-0-2}")
    assert_eq(out:find("announcement", 1, true), nil)
  end)

  it("fails in strict mode when a post references an absent version", function()
    local orphan = '- version: "9.9"\n  title: "Ghost"\n  path: "https://example.com/ghost/"\n'
    assert_throws(function()
      changelog.run({
        input = tmpfile("cl_md", changelog_md),
        output = tmpfile("cl_out", ""),
        news = tmpfile("cl_news", orphan),
        check = true,
        strict = true,
      })
    end, "absent from the changelog")
  end)
end)

-- -----------------------------------------------------------------------
describe("tidydoc: tinymist docstring emitter", function()
  local tidydoc = require("tidydoc")

  local function transformed(body)
    local path = tmpfile("tidy", body)
    tidydoc.transform_file(path)
    return util.read_file(path)
  end

  it("converts @param to a `- name:` list and drops metadata tags", function()
    local out = transformed([[
/// Bind a thing.
///
/// @category Core
/// @param name Legend title.
/// @returns A scale.
#let foo(name: auto) = none
]])
    assert_contains(out, "/// - name: Legend title.")
    assert_contains(out, "/// Returns: A scale.")
    assert_true(not out:find("@category", 1, true), "metadata tag dropped")
    assert_true(not out:find("@param", 1, true), "@param tag converted")
  end)

  it("nests @named-keys under the sink bullet via the template, resolving @refs", function()
    local out = transformed([[
/// Bind guides.
///
/// Threads into @plot.
///
/// @category Guides
/// @param args Named guide specs keyed by aesthetic.
/// @named-keys colour fill default : Guide for the `{}` aesthetic via @guide-legend.
/// @param default Fallback guide for unset channels.
/// @returns Dict.
#let foo(..args) = none
]])
    assert_contains(out, "/// - args: Named guide specs keyed by aesthetic.")
    assert_contains(out, "///   - colour: Guide for the `colour` aesthetic via `guide-legend`.")
    assert_contains(out, "///   - fill: Guide for the `fill` aesthetic via `guide-legend`.")
    assert_contains(out, "///   - default: Fallback guide for unset channels.")
    assert_contains(out, "/// Threads into `plot`.")
  end)

  it("replaces a @theme-keys table with a reference pointer", function()
    local out = transformed([[
/// Build a theme.
///
/// @theme-keys
///
/// @category Themes
/// @param ..fields Overrides.
/// @returns Theme.
#let foo(..fields) = none
]])
    assert_contains(out, "See the package reference for the full theme key catalogue.")
    assert_true(not out:find("|", 1, true), "no markdown table leaks in")
  end)

  it("nests the theme element catalogue under a @theme-fields sink", function()
    local out = transformed([[
/// A preset.
///
/// @category Themes
/// @param ..fields Extra overrides forwarded to @theme.
/// @theme-fields
/// @returns Theme.
#let foo(..fields) = none
]])
    assert_contains(out, "/// - fields: Extra overrides forwarded to `theme`.")
    assert_contains(out, "///   - text: Override for the `text` element.")
    assert_contains(out, "///   - panel-grid: Override for the `panel-grid` element.")
    assert_contains(out, "///   - geom: Override for the `geom` element.")
    assert_contains(out, "/// See the package reference for the full theme key catalogue.")
    assert_true(not out:find("///   - ink:", 1, true), "colour keys are not listed")
  end)

  it("lets @named-keys take precedence over @theme-fields for the nested list", function()
    local out = transformed([[
/// A sink.
///
/// @category Core
/// @param ..fields Overrides.
/// @named-keys colour fill : Channel `{}`.
/// @theme-fields
/// @returns Dict.
#let foo(..fields) = none
]])
    assert_contains(out, "///   - colour: Channel `colour`.")
    assert_true(not out:find("///   - text:", 1, true), "theme catalogue must not be used when @named-keys is present")
  end)

  it("emits @see as a plain list and keeps code verbatim", function()
    local out = transformed([[
/// A widget.
///
/// @category Core
/// @see @bar @baz
/// @returns none.
#let foo() = none
]])
    assert_contains(out, "/// See also: `bar`, `baz`.")
    assert_contains(out, "#let foo() = none")
  end)

  it("preserves non-doc code lines, rewriting only the block", function()
    local out = transformed([[
#import "x.typ": y

/// Summary only.
///
/// @category Core
/// @returns none.
#let foo() = y()
]])
    assert_contains(out, '#import "x.typ": y')
    assert_contains(out, "/// Summary only.")
    assert_contains(out, "#let foo() = y()")
  end)
end)

-- -----------------------------------------------------------------------

describe("scale_keys: bind key tuples match builder signatures", function()
  local scale_keys = require("scale_keys")
  local repo_root = ROOT:match("^(.*)/tools/typstdoc$")
    or (ROOT == "tools/typstdoc" and ".")

  it("every bind.typ key tuple matches its builder's named parameters", function()
    local problems = scale_keys.check(repo_root)
    if #problems > 0 then
      error("bind.typ key tuples out of sync:\n  " .. table.concat(problems, "\n  "), 2)
    end
  end)

  it("every constructor documents exactly the keys its family accepts", function()
    local problems = scale_keys.check_docs(repo_root)
    if #problems > 0 then
      error("scale constructor @named-keys out of sync:\n  " .. table.concat(problems, "\n  "), 2)
    end
  end)
end)

-- -----------------------------------------------------------------------
cleanup()

io.write(string.format("\n%d passed, %d failed\n", T.passed, T.failed))
if T.failed > 0 then os.exit(1) end
