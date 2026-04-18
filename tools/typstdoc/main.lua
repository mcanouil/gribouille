local function script_dir()
  local source = debug.getinfo(1, "S").source
  if source:sub(1, 1) == "@" then source = source:sub(2) end
  return source:match("^(.*)/[^/]+$") or "."
end
local DIR = script_dir()
package.path = DIR .. "/?.lua;" .. package.path

local util = require("util")
local parser = require("parser")
local render = require("render")
local resolve = require("resolve")
local config_patch = require("config_patch")

local USAGE = [[
Usage: lua tools/typstdoc/main.lua [options]

Options:
  --src <dir>       Source directory to scan (default: src)
  --lib <file>      Library entry point (default: lib.typ)
  --out <dir>       Output directory for reference pages (default: docs/reference)
  --sidebar <file>  Sidebar YAML output (default: docs/_sidebar-reference.yml)
  --docs <dir>      Quarto project directory to patch (default: docs)
  --strict          Treat unresolved @refs as errors
  --check           Parse and validate without writing
  --help            Show this help and exit
]]

local function parse_args(argv)
  local opts = {
    src = "src",
    lib = "lib.typ",
    out = "docs/reference",
    sidebar = "docs/_sidebar-reference.yml",
    docs = "docs",
    strict = false,
    check = false,
  }
  local i = 1
  while i <= #argv do
    local a = argv[i]
    if a == "--help" or a == "-h" then
      io.write(USAGE); os.exit(0)
    elseif a == "--strict" then
      opts.strict = true; i = i + 1
    elseif a == "--check" then
      opts.check = true; i = i + 1
    elseif a == "--src" then
      opts.src = argv[i + 1]; i = i + 2
    elseif a == "--lib" then
      opts.lib = argv[i + 1]; i = i + 2
    elseif a == "--out" then
      opts.out = argv[i + 1]; i = i + 2
    elseif a == "--sidebar" then
      opts.sidebar = argv[i + 1]; i = i + 2
    elseif a == "--docs" then
      opts.docs = argv[i + 1]; i = i + 2
    else
      error("typstdoc: unknown argument: " .. a, 0)
    end
  end
  return opts
end

local function main(argv)
  local ok, opts = pcall(parse_args, argv)
  if not ok then util.log_err(tostring(opts)); io.write(USAGE); os.exit(2) end

  local lib_info = parser.parse_lib(opts.lib)
  local all_functions = {}
  local modules = {}

  for _, file in ipairs(util.find_typ_files(opts.src)) do
    local parsed = parser.parse_file(file)
    if parsed.module then
      table.insert(modules, {
        file = parsed.file,
        category = nil,
        description = parsed.module.lines,
      })
    end
    for _, fn in ipairs(parsed.functions) do
      parser.validate_function(fn, lib_info)
      table.insert(all_functions, fn)
    end
  end

  local index = resolve.build_index(all_functions, lib_info)

  if opts.check then
    util.log_info(string.format("parsed %d function(s) across %d file(s) — check OK",
      #all_functions, #util.find_typ_files(opts.src)))
    return 0
  end

  util.remove_dir(opts.out)
  util.make_dir(opts.out)

  local written = 0
  for _, fn in ipairs(all_functions) do
    if fn.doc and fn.doc.category then
      local body, rel_path = render.render_function(fn, index, { strict = opts.strict })
      local full = opts.out .. "/" .. rel_path
      util.write_file(full, body)
      written = written + 1
    end
  end

  for _, cat in ipairs(lib_info.category_order) do
    local body, rel_path = render.render_category_index(cat, all_functions, modules)
    util.write_file(opts.out .. "/" .. rel_path, body)
  end

  local top_body, top_path = render.render_top_index(lib_info.category_order, all_functions)
  util.write_file(opts.out .. "/" .. top_path, top_body)

  local sidebar_body = render.render_sidebar(lib_info.category_order, all_functions)
  util.write_file(opts.sidebar, sidebar_body)

  local sidebar_basename = opts.sidebar:match("([^/]+)$") or opts.sidebar
  config_patch.patch_metadata_yml(opts.docs .. "/_metadata.yml")
  config_patch.patch_quarto_yml(opts.docs .. "/_quarto.yml", sidebar_basename)

  local stub_ref = opts.docs .. "/reference.qmd"
  if util.file_exists(stub_ref) then
    util.remove_file(stub_ref)
  end

  util.log_info(string.format("wrote %d function page(s) under %s", written, opts.out))
  return 0
end

local ok, err = pcall(main, arg)
if not ok then
  util.log_err(tostring(err))
  os.exit(1)
end
