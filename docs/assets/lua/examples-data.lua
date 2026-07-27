--- @license MIT
--- @copyright 2026 Mickaël Canouil
--- @author Mickaël Canouil
--
-- Reads `gallery.yml` adjacent to `examples/index.qmd`, prepends one hidden
-- `{typst}` chunk per item so `typst-render` writes the SVGs to disk, and
-- appends a `#modal-<slug>` div per item carrying the rewritten `.typ` source
-- for the `modal` extension to wrap as a Bootstrap modal.

local function read_file(path)
  local f = io.open(path, 'rb')
  if not f then return nil end
  local body = f:read('*a')
  f:close()
  return body
end

local function rewrite_lib_import(source)
  local version = os.getenv('VERSION') or '?.?.?'
  local replacement = '#import "@preview/gribouille:' .. version .. '": *'
  local rewritten, n = source:gsub('#import%s+"[^"]*lib%.typ"%s*:[^\n]*', replacement, 1)
  if n > 0 then return rewritten end
  local header_lines = {}
  local rest_start = 1
  for line, next_pos in source:gmatch('([^\n]*)\n()') do
    if line:match('^%s*//') or line:match('^%s*$') then
      header_lines[#header_lines + 1] = line
      rest_start = next_pos
    else
      break
    end
  end
  local rest = source:sub(rest_start):gsub('^\n+', '')
  if #header_lines > 0 then
    return table.concat(header_lines, '\n') .. '\n' .. replacement .. '\n\n' .. rest
  end
  return replacement .. '\n\n' .. rest
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

local function build_typst_block(slug, alt)
  local quoted_alt = "'" .. (alt or ''):gsub("'", "''") .. "'"
  local text = table.concat({
    "//| output-filename: '" .. slug .. ".svg'",
    '//| alt: ' .. quoted_alt,
    "//| file: '/assets/examples/" .. slug .. ".typ'",
  }, '\n')
  return pandoc.CodeBlock(text, pandoc.Attr('', { '{typst}' }, {}))
end

local function build_modal(slug, source)
  return pandoc.Div(
    {
      pandoc.Header(3, { pandoc.Code(slug .. '.typ') }),
      pandoc.CodeBlock(source, pandoc.Attr('', { 'typst' }, {})),
    },
    pandoc.Attr('modal-' .. slug, {}, {})
  )
end

function Pandoc(doc)
  local input = quarto.doc.input_file or ''
  if not input:match('examples/index%.qmd$') then return nil end
  local input_dir = input:match('^(.*)/[^/]+$')
  if not input_dir then return nil end

  local yml_path = input_dir .. '/gallery.yml'
  local yml_text = read_file(yml_path)
  if not yml_text then
    quarto.log.warning('examples-data: cannot read ' .. yml_path)
    return nil
  end

  local project_dir = quarto.project.directory or input_dir
  local items = parse_yaml_list(yml_text)

  local typst_blocks, modal_blocks = {}, {}
  for _, it in ipairs(items) do
    local slug = it.slug
    if slug and slug ~= '' then
      table.insert(typst_blocks, build_typst_block(slug, it.alt))

      local typ_path = project_dir .. '/assets/examples/' .. slug .. '.typ'
      local source = read_file(typ_path)
      if source then
        source = rewrite_lib_import(source):gsub('\n+$', '')
      else
        quarto.log.warning('examples-data: cannot read ' .. typ_path)
        source = '// File not found: ' .. typ_path
      end
      table.insert(modal_blocks, build_modal(slug, source))
    end
  end

  local hidden = pandoc.Div(typst_blocks, pandoc.Attr('examples-typst-render', {}, { style = 'display:none' }))

  local new_blocks = pandoc.Blocks({ hidden })
  for _, b in ipairs(doc.blocks) do new_blocks:insert(b) end
  for _, m in ipairs(modal_blocks) do new_blocks:insert(m) end
  doc.blocks = new_blocks

  return doc
end
