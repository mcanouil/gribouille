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

-- Scan the intent gallery's pages for the two intent values each declares:
-- the `gallery-intent` the Lua filter renders from, and the listing `include`
-- Quarto filters cards with. Returns an ordered list of { page, declared,
-- include } so a duplicate declaration survives to be reported.
local function read_gallery_pages(gallery_dir)
  local decls = {}
  if not util.dir_exists(gallery_dir) then return decls end
  for _, name in ipairs(util.list_dir_files(gallery_dir)) do
    if name:match("%.qmd$") then
      local content, err = util.read_file(gallery_dir .. "/" .. name)
      if not content then util.die("could not read page: " .. name .. ": " .. tostring(err)) end
      local decl = examples.parse_page_intent(content)
      if decl.declared then
        decls[#decls + 1] = { page = name, declared = decl.declared, include = decl.include }
      end
    end
  end
  return decls
end

-- File name of every intent page under `docs/gallery`, hub page excluded, from
-- the declarations `read_gallery_pages` collected.
local function intent_page_names(decls)
  local out = {}
  for _, decl in ipairs(decls) do
    if decl.declared ~= examples.HUB_INTENT then out[#out + 1] = decl.page end
  end
  table.sort(out)
  return out
end

-- Read a file the caller has already required to exist.
local function read_required(path, what)
  if not util.file_exists(path) then util.die(what .. " not found: " .. path) end
  local content, err = util.read_file(path)
  if not content then util.die("could not read " .. what .. ": " .. path .. ": " .. tostring(err)) end
  return content
end

-- Drop the hub page from a list of page file names, so the intent pages alone
-- are compared against the navigation surfaces.
local function without_hub(names, hub_page)
  local out = {}
  for _, name in ipairs(names) do
    if name ~= hub_page then out[#out + 1] = name end
  end
  return out
end

-- Every `examples/*.typ` must have a gallery slug or be excluded (see
-- examples.EXCLUDE), otherwise it never renders in the slug-driven gallery.
-- Every entry must also carry a valid intent (see examples.INTENTS), and that
-- taxonomy must match the pages rendering it, or entries land on no page.
-- The taxonomy also has to match the two navigation surfaces, `hub.yml` and
-- `_sidebar-gallery.yml`, or a page renders that nothing links to.
local function enforce_examples_gallery(opts)
  if not util.dir_exists(opts.examples) then return end
  local function report(msg)
    if opts.check or opts.strict then
      util.die(msg)
    else
      util.log_warn(msg)
    end
  end

  local gallery_dir = opts.docs .. "/gallery"
  local gallery_path = gallery_dir .. "/gallery.yml"
  local hub_path = gallery_dir .. "/hub.yml"
  local sidebar_path = opts.docs .. "/_sidebar-gallery.yml"

  local content = read_required(gallery_path, "gallery file")
  local hub_content = read_required(hub_path, "gallery hub file")
  local sidebar_content = read_required(sidebar_path, "gallery sidebar file")

  local entries = examples.parse_entries(content)
  local slugs = {}
  for _, entry in ipairs(entries) do slugs[entry.slug] = true end

  local bad = examples.bad_intents(entries)
  if #bad > 0 then
    report(string.format(
      "%d gallery entr%s with a missing or unknown intent in %s: %s",
      #bad, #bad == 1 and "y" or "ies", gallery_path, table.concat(bad, ", ")))
  end

  for _, pair in ipairs({ { gallery_path, content }, { hub_path, hub_content } }) do
    local lines = examples.block_scalars(pair[2])
    if #lines > 0 then
      report(string.format(
        "%s uses a block or folded scalar on line(s) %s; the Lua filters read one line per key",
        pair[1], table.concat(lines, ", ")))
    end
  end

  local decls = read_gallery_pages(gallery_dir)
  local page_intents, page_includes, duplicates = examples.fold_page_intents(decls)
  if #duplicates > 0 then
    report(string.format("%d duplicate intent declaration(s) in %s: %s",
      #duplicates, gallery_dir, table.concat(duplicates, "; ")))
  end

  local drift = examples.intent_drift(page_intents, nil, page_includes)
  if #drift > 0 then
    report(string.format(
      "%d intent taxonomy drift(s) between examples.INTENTS and docs/gallery: %s",
      #drift, table.concat(drift, "; ")))
  end

  local cards = examples.parse_cards(hub_content)
  local hub_page = page_intents[examples.HUB_INTENT]
  local card_pages, craft_intents = {}, {}
  for _, card in ipairs(cards) do
    if card.href then
      card_pages[#card_pages + 1] = card.href
      if card.group == "craft" then
        craft_intents[card.href:gsub("%.qmd$", "")] = true
      end
    end
  end

  local nav = examples.nav_drift(
    intent_page_names(decls),
    card_pages,
    without_hub(examples.parse_sidebar_pages(sidebar_content), hub_page))
  if #nav > 0 then
    report(string.format("%d gallery navigation drift(s) across %s and %s: %s",
      #nav, hub_path, sidebar_path, table.concat(nav, "; ")))
  end

  local heroes = examples.bad_heroes(cards, slugs)
  if #heroes > 0 then
    report(string.format("%d hub card hero(es) with no gallery.yml slug in %s: %s",
      #heroes, hub_path, table.concat(heroes, ", ")))
  end

  local showcases = examples.craft_showcases(entries, craft_intents)
  if #showcases > 0 then
    report(string.format(
      "%d showcase entr%s on a craft page in %s, which renders feature demos only: %s",
      #showcases, #showcases == 1 and "y" or "ies", gallery_path, table.concat(showcases, ", ")))
  end

  local orphans = examples.orphans(util.list_dir_files(opts.examples), slugs)
  if #orphans == 0 then return end
  report(string.format(
    "%d example(s) missing a gallery.yml entry (add one, or extend examples.EXCLUDE): %s",
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
