--- @module "iconify-filter"
--- @license MIT
--- @copyright 2026 Mickaël Canouil
--- @author Mickaël Canouil
---
--- Document-level filter for the Iconify extension. Reads one or more
--- author-supplied JSON files containing Iconify icon-collection payloads
--- and injects them as `window.IconifyPreload`. The Iconify Web Component
--- reads that global at boot and renders the preloaded icons without any
--- CDN call, which makes the document work offline (or when the public
--- Iconify CDN is unreachable) for those icons.

--- Extension name constant
local EXTENSION_NAME = "iconify"

--- Load modules
local str = require(quarto.utils.resolve_path('_vendor/quarto-lua-modules/string.lua'):gsub('%.lua$', ''))
local log = require(quarto.utils.resolve_path('_vendor/quarto-lua-modules/logging.lua'):gsub('%.lua$', ''))

--- Tracker so the preload payload is only injected once per document, even
--- when the filter runs multiple passes.
--- @type boolean
local preload_injected = false

--- Collect preload file paths from metadata.
--- Accepts a single string, a Pandoc Inlines value, or a list of either.
--- @param value any The raw metadata value
--- @return table<integer, string>
local function collect_paths(value)
  --- @type table<integer, string>
  local paths = {}
  if value == nil then
    return paths
  end
  -- Pandoc MetaList is a table with sequential integer keys and no `.t` tag.
  if type(value) == 'table' and value[1] ~= nil and value.t == nil then
    for _, item in ipairs(value) do
      local raw = str.stringify(item)
      if not str.is_empty(raw) then
        table.insert(paths, raw)
      end
    end
  else
    local raw = str.stringify(value)
    if not str.is_empty(raw) then
      table.insert(paths, raw)
    end
  end
  return paths
end

--- Read the entire content of a file. Returns nil if the file cannot be opened.
--- @param path string
--- @return string|nil
local function read_file(path)
  local handle = io.open(path, 'rb')
  if not handle then return nil end
  local content = handle:read('*a')
  handle:close()
  return content
end

--- Inject author-supplied icon data as a global `IconifyPreload` payload.
--- @param meta table<string, any>
--- @return nil
local function inject_preload(meta)
  if preload_injected then return end
  if meta == nil or meta.extensions == nil or meta.extensions.iconify == nil then
    return
  end
  if meta.extensions.iconify.preload == nil then
    return
  end

  --- @type table<integer, string>
  local paths = collect_paths(meta.extensions.iconify.preload)
  if #paths == 0 then return end

  --- @type table<integer, string>
  local payloads = {}
  for _, path in ipairs(paths) do
    local content = read_file(path)
    if content == nil then
      log.log_warning(
        EXTENSION_NAME,
        'Preload file "' .. path .. '" could not be read; skipping.'
      )
    else
      --- @type string
      local trimmed = content:gsub('^%s+', ''):gsub('%s+$', '')
      if trimmed:sub(1, 1) ~= '{' then
        log.log_warning(
          EXTENSION_NAME,
          'Preload file "' .. path .. '" does not start with "{"; skipping.'
        )
      else
        table.insert(payloads, trimmed)
      end
    end
  end

  if #payloads == 0 then return end

  --- @type string
  local joined = table.concat(payloads, ',')
  quarto.doc.include_text(
    'in-header',
    '<script>window.IconifyPreload=[' .. joined .. '];</script>'
  )
  preload_injected = true
end

--- Pandoc Meta handler. Inject preload script for HTML output only.
--- Quarto's language-server plugin rewrites a filter function's doc comment,
--- adding `@param meta pandoc.Meta` and `@return pandoc.Meta|nil` without
--- checking for an existing annotation, so declaring either here duplicates it.
function Meta(meta)
  if quarto.doc.is_format('html:js') then
    inject_preload(meta)
  end
  return meta
end
