#!/usr/bin/env lua

local function script_dir()
  local source = debug.getinfo(1, "S").source
  if source:sub(1, 1) == "@" then source = source:sub(2) end
  return source:match("^(.*)/[^/]+$") or "."
end
local DIR = script_dir()
local DEFAULT_ROOT = DIR .. "/../.."
package.path = DIR .. "/?.lua;" .. package.path

local util = require("util")
local parser = require("parser")
local render = require("render")
local resolve = require("resolve")
local deps = require("deps")
local changelog = require("changelog")
local stat_info = require("stat_info")
local examples = require("examples")

local USAGE = [[
Usage: tools/typstdoc/main.lua [options]

Options:
  --root <dir>        Repository root (default: two levels above this script). Prefixes all path defaults.
  --src <dir>         Source directory to scan (default: <root>/src)
  --lib <file>        Library entry point (default: <root>/lib.typ)
  --examples <dir>    Example .typ sources (default: <root>/examples)
  --examples-out <dir> Where examples are copied for Quarto (default: <root>/docs/assets/examples)
  --out <dir>         Output directory for reference pages (default: <root>/docs/reference)
  --sidebar <file>    Sidebar YAML output (default: <root>/docs/_sidebar-reference.yml)
  --docs <dir>        Quarto project directory to patch (default: <root>/docs)
  --toml <file>       Package manifest to read (default: <root>/typst.toml)
  --deps <file>       Typst dependency entry file (default: <root>/src/deps.typ)
  --variables <file>  YAML output with compiler + dependency versions (default: <root>/docs/_variables.yml)
  --news <file>       Release announcement data feeding changelog links (default: <root>/docs/_news.yml)
  --strict            Treat unresolved @refs as errors
  --check             Parse and validate without writing
  --help              Show this help and exit
]]

local VALUE_FLAGS = {
  ["--root"] = "root",
  ["--src"] = "src",
  ["--lib"] = "lib",
  ["--examples"] = "examples",
  ["--examples-out"] = "examples_out",
  ["--out"] = "out",
  ["--sidebar"] = "sidebar",
  ["--docs"] = "docs",
  ["--toml"] = "toml",
  ["--deps"] = "deps_file",
  ["--variables"] = "variables",
  ["--news"] = "news",
}

local BOOL_FLAGS = {
  ["--strict"] = "strict",
  ["--check"] = "check",
}

local function parse_args(argv)
  local opts = { root = DEFAULT_ROOT, strict = false, check = false }
  local i = 1
  while i <= #argv do
    local a = argv[i]
    if a == "--help" or a == "-h" then
      io.write(USAGE); os.exit(0)
    elseif BOOL_FLAGS[a] then
      opts[BOOL_FLAGS[a]] = true; i = i + 1
    elseif VALUE_FLAGS[a] then
      local value = argv[i + 1]
      if not value then util.die("missing value for " .. a) end
      opts[VALUE_FLAGS[a]] = value; i = i + 2
    else
      util.die("unknown argument: " .. a)
    end
  end
  opts.src = opts.src or (opts.root .. "/src")
  opts.lib = opts.lib or (opts.root .. "/lib.typ")
  opts.examples = opts.examples or (opts.root .. "/examples")
  opts.examples_out = opts.examples_out or (opts.root .. "/docs/assets/examples")
  opts.out = opts.out or (opts.root .. "/docs/reference")
  opts.sidebar = opts.sidebar or (opts.root .. "/docs/_sidebar-reference.yml")
  opts.docs = opts.docs or (opts.root .. "/docs")
  opts.toml = opts.toml or (opts.root .. "/typst.toml")
  opts.deps_file = opts.deps_file or (opts.root .. "/src/deps.typ")
  opts.variables = opts.variables or (opts.root .. "/docs/_variables.yml")
  opts.news = opts.news or (opts.docs .. "/_news.yml")
  return opts
end

local function parse_sources(src_dir, lib_info)
  local files = util.find_typ_files(src_dir)
  local all_functions = {}
  local modules = {}
  for _, file in ipairs(files) do
    local parsed = parser.parse_file(file)
    if parsed.module then
      modules[#modules + 1] = {
        file = parsed.file,
        category = nil,
        description = parsed.module.lines,
      }
    end
    for _, fn in ipairs(parsed.functions) do
      parser.validate_function(fn, lib_info)
      all_functions[#all_functions + 1] = fn
    end
  end
  return files, all_functions, modules
end

local function report_check(files, all_functions, deps_info, changelog_result)
  local changelog_status = changelog_result.skipped_entirely
    and "changelog skipped"
    or "changelog OK"
  util.log_info(string.format(
    "parsed %d function(s) across %d file(s); deps OK (%s); %s; check OK",
    #all_functions, #files, deps.summary(deps_info),
    changelog_status))
end

local EXAMPLE_SKIP_EXT = { pdf = true, png = true, jpg = true, jpeg = true, gif = true, svg = true }

-- Every `examples/*.typ` must have a gallery slug (in either the examples or
-- the intent gallery) or be excluded (see examples.EXCLUDE), otherwise it
-- never renders in the slug-driven galleries. Intent gallery entries must
-- also carry a valid intent (see examples.INTENTS) or they land on no page.
local function enforce_examples_gallery(opts)
  if not util.dir_exists(opts.examples) then return end
  local function report(msg)
    if opts.check or opts.strict then
      util.die(msg)
    else
      util.log_warn(msg)
    end
  end

  local gallery_path = opts.docs .. "/examples/gallery.yml"
  if not util.file_exists(gallery_path) then
    util.die("gallery file not found: " .. gallery_path)
  end
  local content, err = util.read_file(gallery_path)
  if not content then util.die("could not read gallery: " .. gallery_path .. ": " .. tostring(err)) end
  local slugs = examples.parse_slugs(content)

  local intent_path = opts.docs .. "/gallery/gallery.yml"
  if util.file_exists(intent_path) then
    local intent_content, intent_err = util.read_file(intent_path)
    if not intent_content then
      util.die("could not read gallery: " .. intent_path .. ": " .. tostring(intent_err))
    end
    local entries = examples.parse_entries(intent_content)
    for _, entry in ipairs(entries) do slugs[entry.slug] = true end
    local bad = examples.bad_intents(entries)
    if #bad > 0 then
      report(string.format(
        "%d gallery entr%s with a missing or unknown intent in %s: %s",
        #bad, #bad == 1 and "y" or "ies", intent_path, table.concat(bad, ", ")))
    end
  end

  local orphans = examples.orphans(util.list_dir_files(opts.examples), slugs)
  if #orphans == 0 then return end
  report(string.format(
    "%d example(s) missing an entry in either gallery.yml (add one, or extend examples.EXCLUDE): %s",
    #orphans, table.concat(orphans, ", ")))
end

local function copy_examples(opts)
  if not util.dir_exists(opts.examples) then return 0 end

  util.make_dir(opts.examples_out)
  util.run(string.format(
    "find %q -maxdepth 1 -type f ! -name '*.svg' -delete 2>/dev/null",
    opts.examples_out))

  local copied = 0
  for _, name in ipairs(util.list_dir_files(opts.examples)) do
    local ext = name:match("%.([^.]+)$")
    if not (ext and EXAMPLE_SKIP_EXT[ext:lower()]) then
      local src = opts.examples .. "/" .. name
      local dst = opts.examples_out .. "/" .. name
      if ext == "typ" then
        local content, err = util.read_file(src)
        if not content then util.die("could not read " .. src .. ": " .. tostring(err)) end
        content = content:gsub('#import "%.%./lib%.typ":[^\n]*\n\n?', '')
        content = content:gsub('"%.%./docs/', '"/docs/')
        util.write_file(dst, content)
      else
        util.run(string.format("cp %q %q", src, dst))
      end
      copied = copied + 1
    end
  end

  return copied
end

local function write_reference(opts, all_functions, modules, lib_info)
  local index = resolve.build_index(all_functions, lib_info)
  local stats = stat_info.load(opts.root)

  util.remove_generated_files(opts.out, "*.qmd")
  util.make_dir(opts.out)

  local written = 0
  for _, fn in ipairs(all_functions) do
    if fn.doc and fn.doc.category then
      local body, rel_path = render.render_function(fn, index, { strict = opts.strict, stat_info = stats })
      util.write_file(opts.out .. "/" .. rel_path, body)
      written = written + 1
    end
  end

  for _, cat in ipairs(lib_info.category_order) do
    local body, rel_path = render.render_category_index(cat, all_functions, modules, index, opts.strict)
    util.write_file(opts.out .. "/" .. rel_path, body)
  end

  local top_body, top_path = render.render_top_index(lib_info.category_order, all_functions, index, opts.strict)
  util.write_file(opts.out .. "/" .. top_path, top_body)

  util.write_file(opts.sidebar, render.render_sidebar(lib_info.category_order, all_functions))
  return written
end

local function main(argv)
  local ok, opts = pcall(parse_args, argv)
  if not ok then util.log_err(tostring(opts)); io.write(USAGE); os.exit(2) end

  local deps_info = deps.collect({
    toml = opts.toml,
    deps_file = opts.deps_file,
    src = opts.src,
  })

  local changelog_result = changelog.run({
    input = opts.root .. "/CHANGELOG.md",
    output = opts.docs .. "/changelog.qmd",
    news = opts.news,
    check = opts.check,
    strict = opts.strict,
  })

  parser.set_root(opts.root)
  local lib_info = parser.parse_lib(opts.lib)
  local files, all_functions, modules = parse_sources(opts.src, lib_info)

  enforce_examples_gallery(opts)

  if opts.check then
    report_check(files, all_functions, deps_info, changelog_result)
    return 0
  end

  util.write_file(opts.variables, deps.render(deps_info))
  local written = write_reference(opts, all_functions, modules, lib_info)
  local copied = copy_examples(opts)

  util.log_info(string.format("wrote %d function page(s) under %s", written, opts.out))
  util.log_info(string.format("copied %d example(s) under %s", copied, opts.examples_out))
  return 0
end

local ok, err = pcall(main, arg or {})
if not ok then
  util.log_err(tostring(err))
  os.exit(1)
end
