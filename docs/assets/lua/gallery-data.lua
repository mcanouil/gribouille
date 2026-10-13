--- @license MIT
--- @copyright 2026 Mickaël Canouil
--- @author Mickaël Canouil
--
-- Powers the intent-driven gallery under `gallery/`. Reads the page's
-- `gallery-intent` metadata: `hub` injects one hidden `{typst}` chunk per
-- `hub.yml` hero so `typst-render` writes `hero-<slug>` SVGs; any other value
-- filters `gallery.yml` to that intent, prepending one hidden `{typst}` chunk
-- per item and appending a `#modal-<slug>` div carrying the `.typ`
-- source for the `modal` extension to wrap as a Bootstrap modal.
--
-- The hub renders its heroes under a `hero-` prefix rather than reusing the
-- intent pages' SVGs. That costs 24 extra Typst compilations per build, one
-- light and one dark for each of the 12 cards, and buys build-order
-- independence: `quarto render gallery/index.qmd` alone yields a complete hub
-- instead of one wired to artefacts a sibling page may not have produced yet.
-- `index.qmd` at the site root is the deliberate exception: its four preview
-- images reuse the intent pages' renders, so it needs a full site build.

local function read_file(path)
  local f = io.open(path, 'rb')
  if not f then return nil end
  local body = f:read('*a')
  f:close()
  return body
end

local function strip_quotes(v)
  v = v:gsub('^%s*(.-)%s*$', '%1')
  if #v >= 2 then
    local c1, cN = v:sub(1, 1), v:sub(-1)
    if c1 == '"' and cN == '"' then
      return (v:sub(2, -2):gsub('\\"', '"'):gsub('\\\\', '\\'))
    elseif c1 == "'" and cN == "'" then
      return (v:sub(2, -2):gsub("''", "'"))
    end
  end
  return v
end

-- Flat list of mappings only; values must be single-line scalars.
local function parse_yaml_list(text)
  local items, current = {}, nil
  for line in text:gmatch('[^\r\n]+') do
    if not (line:match('^%s*$') or line:match('^%s*#')) then
      if line:match('^%- ') or line == '-' then
        if current then table.insert(items, current) end
        current = {}
        local rest = line:match('^%- (.*)$')
        if rest then
          local k, v = rest:match('^([%w_-]+):%s*(.*)$')
          if k then current[k] = strip_quotes(v) end
        end
      else
        local k, v = line:match('^%s+([%w_-]+):%s*(.*)$')
        if k and current then current[k] = strip_quotes(v) end
      end
    end
  end
  if current then table.insert(items, current) end
  return items
end

-- Digest of lib.typ and every file under src/, keyed by path relative to the
-- repository so it matches across machines. typst-render's cache key does not
-- read `/lib.typ` or the nested src/ imports, so each gallery block carries this
-- digest as an input: a figure recompiles when the library changes and comes
-- from the cache otherwise.
local library_digest_cache = nil
local function library_digest()
  if library_digest_cache then return library_digest_cache end
  local root = (quarto.project.directory or '.') .. '/..'
  local parts = {}
  local function add(rel)
    local path = root .. '/' .. rel
    local ok, entries = pcall(pandoc.system.list_directory, path)
    if ok then
      table.sort(entries)
      for _, name in ipairs(entries) do add(rel .. '/' .. name) end
    else
      local body = read_file(path)
      if not body then
        error('gallery-data: cannot read ' .. path .. ' for the library digest; check that lib.typ and src/ exist under ' .. root)
      end
      parts[#parts + 1] = rel .. '\n' .. body
    end
  end
  add('lib.typ')
  add('src')
  library_digest_cache = pandoc.utils.sha1(table.concat(parts, '\n'))
  return library_digest_cache
end

-- The examples import the working tree with `#import "/lib.typ"`. A reader
-- types the published package instead, so the modal shows that line, with the
-- version typst.toml declares.
local package_import_cache = nil
local function package_import()
  if package_import_cache then return package_import_cache end
  local toml_path = (quarto.project.directory or '.') .. '/../typst.toml'
  local version = (read_file(toml_path) or ''):match('\nversion%s*=%s*"([^"]+)"')
  if not version then
    error('gallery-data: no version = "x.y.z" line in ' .. toml_path)
  end
  package_import_cache = '#import "@preview/gribouille:' .. version .. '"'
  return package_import_cache
end

local function shown_source(source)
  local shown, n = source:gsub('#import%s+"/lib%.typ"', package_import(), 1)
  if n == 0 then
    error('gallery-data: example has no #import "/lib.typ" line to show as the package import')
  end
  return shown
end

-- typst-render resolves a leading `/` against docs/, so `/../examples/` is the
-- repository's examples folder whatever the page folder or working directory.
local function build_typst_block(slug, alt, output_name)
  local quoted_alt = "'" .. (alt or ''):gsub("'", "''") .. "'"
  local text = table.concat({
    "//| output-filename: '" .. (output_name or slug) .. ".svg'",
    '//| alt: ' .. quoted_alt,
    "//| file: '/../examples/" .. slug .. ".typ'",
    "//| input: 'gribouille-library=" .. library_digest() .. "'",
  }, '\n')
  return pandoc.CodeBlock(text, pandoc.Attr('', { '{typst}' }, {}))
end

-- No `description` attribute: the modal extension treats it as an
-- `aria-describedby` id reference, and the header already labels the dialog.
local function build_modal(slug, source)
  return pandoc.Div(
    {
      pandoc.Header(3, { pandoc.Code(slug .. '.typ') }),
      pandoc.CodeBlock(source, pandoc.Attr('', { 'typst' }, {})),
    },
    pandoc.Attr('modal-' .. slug, {}, {})
  )
end

local function read_items(input_dir, name)
  local yml_path = input_dir .. '/' .. name
  local yml_text = read_file(yml_path)
  if not yml_text then
    quarto.log.warning('gallery-data: cannot read ' .. yml_path)
    return nil
  end
  return parse_yaml_list(yml_text)
end

local function hub_blocks(input_dir)
  local cards = read_items(input_dir, 'hub.yml')
  if not cards then return nil end

  local typst_blocks = {}
  for _, card in ipairs(cards) do
    local hero = card.hero
    if hero and hero ~= '' then
      table.insert(typst_blocks, build_typst_block(hero, card.alt, 'hero-' .. hero))
    end
  end
  return typst_blocks, {}
end

local function intent_blocks(input_dir, project_dir, intent)
  local items = read_items(input_dir, 'gallery.yml')
  if not items then return nil end

  local typst_blocks, modal_blocks = {}, {}
  for _, it in ipairs(items) do
    local slug = it.slug
    if slug and slug ~= '' and it.intent == intent then
      table.insert(typst_blocks, build_typst_block(slug, it.alt))

      local typ_path = project_dir .. '/../examples/' .. slug .. '.typ'
      local source = read_file(typ_path)
      if source then
        source = shown_source(source):gsub('\n+$', '')
      else
        quarto.log.warning('gallery-data: cannot read ' .. typ_path)
        source = '// File not found: ' .. typ_path
      end
      table.insert(modal_blocks, build_modal(slug, source))
    end
  end
  return typst_blocks, modal_blocks
end

function Pandoc(doc)
  local input = quarto.doc.input_file or ''
  if not input:match('/gallery/[^/]+%.qmd$') then return nil end
  local intent = doc.meta['gallery-intent'] and pandoc.utils.stringify(doc.meta['gallery-intent']) or nil
  if not intent or intent == '' then return nil end
  local input_dir = input:match('^(.*)/[^/]+$')
  if not input_dir then return nil end

  local project_dir = quarto.project.directory or input_dir

  local typst_blocks, modal_blocks
  if intent == 'hub' then
    typst_blocks, modal_blocks = hub_blocks(input_dir)
  else
    typst_blocks, modal_blocks = intent_blocks(input_dir, project_dir, intent)
  end
  if not typst_blocks then return nil end

  local hidden = pandoc.Div(typst_blocks, pandoc.Attr('gallery-typst-render', {}, { style = 'display:none' }))

  local new_blocks = pandoc.Blocks({ hidden })
  for _, b in ipairs(doc.blocks) do new_blocks:insert(b) end
  for _, m in ipairs(modal_blocks) do new_blocks:insert(m) end
  doc.blocks = new_blocks

  return doc
end
