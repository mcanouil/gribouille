--- MC Embedded - Load a filter that an extension bundles, unless the page runs the project's own copy
--- @module "embedded"
--- @license MIT
--- @copyright 2026 Mickaël Canouil
--- @author Mickaël Canouil

local M = {}

-- ============================================================================
-- EMBEDDED FILTERS
-- ============================================================================

-- A format extension can bundle other extensions under its own `_extensions/`
-- and name them in its format filters. Quarto adds the filters of a page to
-- the format filters, so a project that keeps its own copy of a bundled
-- extension, and names it, runs both copies. A format names a small wrapper in
-- place of each bundled extension, and the wrapper calls `load`, so only the
-- project copy runs.
--
-- `quarto.utils.resolve_path` answers relative to the script on top of an
-- internal Quarto stack, at load time and when a handler runs. The bundled
-- entry is loaded from the wrapper, so `load` puts the entry on that stack
-- with `_quarto.withScriptFile`, which is internal to Quarto, for the load and
-- for every handler call.
--
-- The module skips the bundled filter only when the page runs a filter from
-- the project copy, which it reads from Quarto's internal
-- `param('quarto-filters')`. A copy that the page does not name leaves the
-- bundled filter on. Without that list, a project copy alone skips the
-- bundled filter.
--
-- Only filters go through `load`. Quarto adds a Reveal.js plugin that the page
-- names to the plugins of the format, and loads the shortcodes of every
-- project extension, so a project copy can run its plugin or its shortcodes
-- with the bundled filter. The `plugin` and `shortcode` options warn when that
-- happens, and tell the author to name the copy in both lists.
-- Remove when: never.

local MANIFESTS = { '_extension.yml', '_extension.yaml' }

--- Tell whether a directory holds an extension manifest.
--- @param dir string
--- @return boolean
local function has_manifest(dir)
  for _, manifest in ipairs(MANIFESTS) do
    local handle = io.open(pandoc.path.join({ dir, manifest }), 'r')
    if handle ~= nil then
      handle:close()
      return true
    end
  end
  return false
end

--- List the entries of a directory, or none when it cannot be read.
--- @param dir string
--- @return table<integer, string>
local function entries(dir)
  local listed, names = pcall(pandoc.system.list_directory, dir)
  if not listed then
    return {}
  end
  table.sort(names)
  return names
end

--- Tell whether a directory lists an entry with exactly this name.
--- The comparison is exact, so it holds on a file system that ignores case.
--- @param dir string
--- @param name string
--- @return boolean
local function lists(dir, name)
  for _, entry in ipairs(entries(dir)) do
    if entry == name then
      return true
    end
  end
  return false
end

--- Find a copy of an extension in one `_extensions/` folder.
--- Looks for `<name>/` and `<owner>/<name>/`, with any owner.
--- @param extensions string The `_extensions/` folder
--- @param name string The extension name, such as `veil`
--- @return string|nil The directory of the copy, or nil when there is none
local function find_copy_in(extensions, name)
  local candidates = {}
  if lists(extensions, name) then
    candidates[1] = pandoc.path.join({ extensions, name })
  end
  for _, owner in ipairs(entries(extensions)) do
    local owner_dir = pandoc.path.join({ extensions, owner })
    if lists(owner_dir, name) then
      candidates[#candidates + 1] = pandoc.path.join({ owner_dir, name })
    end
  end
  for _, dir in ipairs(candidates) do
    if has_manifest(dir) then
      return dir
    end
  end
  return nil
end

--- Normalise a directory and drop a trailing separator, except at a root
--- such as `/` or `C:\\`.
--- @param dir string
--- @return string
local function directory(dir)
  dir = pandoc.path.normalize(dir)
  local trimmed = dir:gsub('[/\\]+$', '')
  if trimmed == '' or trimmed:match('^%a:$') then
    return dir
  end
  return trimmed
end

--- Tell whether a path is a directory or lies inside it.
--- Paths are compared by whole components, so `/a/proj` does not hold
--- `/a/project`.
--- @param path string
--- @param dir string
--- @return boolean
local function inside(path, dir)
  path = pandoc.path.normalize(path)
  dir = directory(dir)
  if dir:sub(-1) == pandoc.path.separator then
    return path:sub(1, #dir) == dir
  end
  return path == dir or path:sub(1, #dir + 1) == dir .. pandoc.path.separator
end

--- The folders whose `_extensions/` Quarto reads for the input file.
--- From the folder of the input file up to the project directory, as Quarto
--- resolves extensions. Outside a project, only the folder of the input file.
--- @return table<integer, string>
local function search_roots()
  local root = quarto.project and quarto.project.directory
  local input = quarto.doc and quarto.doc.input_file
  if input == nil then
    return { root }
  end
  local dir = pandoc.path.normalize(pandoc.path.directory(input))
  if root == nil then
    return { dir }
  end
  root = directory(root)
  local roots = {}
  while dir ~= root and inside(dir, root) do
    roots[#roots + 1] = dir
    local parent = pandoc.path.directory(dir)
    if parent == dir then
      break
    end
    dir = parent
  end
  roots[#roots + 1] = root
  return roots
end

--- Find the project's own copy of an extension.
--- A copy bundled inside another extension is deeper than the folders this
--- looks in, so it never matches.
--- @param name string The extension name, such as `veil`
--- @return string|nil The directory of the copy, or nil when there is none
local function find_project_copy(name)
  for _, root in ipairs(search_roots()) do
    local copy = find_copy_in(pandoc.path.join({ root, '_extensions' }), name)
    if copy ~= nil then
      return copy
    end
  end
  return nil
end

--- Tell whether the page runs a filter from a directory.
--- Quarto lists the filters of the page in its internal `param('quarto-filters')`.
--- @param dir string The directory of the project copy
--- @return boolean|nil True or false, or nil when Quarto gives no list
local function page_runs_from(dir)
  if type(_G.param) ~= 'function' then
    return nil
  end
  local read, listed = pcall(_G.param, 'quarto-filters')
  if not read or type(listed) ~= 'table' then
    return nil
  end
  local keys = { 'entryPoints', 'beforeQuartoFilters', 'afterQuartoFilters' }
  local known = false
  for _, key in ipairs(keys) do
    known = known or type(listed[key]) == 'table'
  end
  if not known then
    return nil
  end
  for _, key in ipairs(keys) do
    for _, filter in ipairs(listed[key] or {}) do
      local path = type(filter) == 'table' and filter.path or filter
      if type(path) == 'string' and inside(path, dir) then
        return true
      end
    end
  end
  return false
end

--- Tell whether one entry of `revealjs-plugins` names a copy of an extension.
--- A page entry is a name such as `veil` or `owner/veil`, or a path that ends
--- with the folder of the copy. The plugins that a format gives are already
--- resolved to tables, so they never match.
--- @param entry any One entry of `revealjs-plugins`
--- @param name string The extension name, such as `veil`
--- @return boolean
local function names_plugin(entry, name)
  local kind = pandoc.utils.type(entry)
  if kind ~= 'string' and kind ~= 'Inlines' then
    return false
  end
  local text = pandoc.utils.stringify(entry):gsub('\\', '/'):gsub('/+$', '')
  return text == name or text:sub(-#name - 1) == '/' .. name
end

--- Tell whether `revealjs-plugins` in the page metadata names the copy.
--- The value is a list of entries, or a single entry.
--- @param meta table The page metadata
--- @param name string The extension name
--- @return boolean
local function page_names_plugin(meta, name)
  local plugins = meta['revealjs-plugins']
  if names_plugin(plugins, name) then
    return true
  end
  if pandoc.utils.type(plugins) ~= 'List' and pandoc.utils.type(plugins) ~= 'table' then
    return false
  end
  for _, plugin in ipairs(plugins) do
    if names_plugin(plugin, name) then
      return true
    end
  end
  return false
end

--- A filter that warns when the page names a project copy in only one of
--- `filters` and `revealjs-plugins`, so the Lua of one copy would run with
--- the Reveal.js plugin of the other.
--- @param name string The extension name
--- @param copy string The directory of the project copy
--- @param in_filters boolean Whether the page names the copy in `filters`
--- @return table
local function plugin_check(name, copy, in_filters)
  return {
    Meta = function(meta)
      local doc = quarto.doc
      if doc ~= nil and type(doc.is_format) == 'function' and not doc.is_format('revealjs') then
        return nil
      end
      if in_filters ~= page_names_plugin(meta, name) then
        local named = in_filters and '`filters`' or '`revealjs-plugins`'
        local missing = in_filters and '`revealjs-plugins`' or '`filters`'
        quarto.log.warning('[embedded] ' .. name .. ': the page names the project copy at ' .. copy ..
          ' in ' .. named .. ' but not in ' .. missing ..
          ', so the deck mixes the Lua filter and the Reveal.js plugin of two copies. Name the copy in both lists.')
      end
    end,
  }
end

--- Call a function with a file on top of Quarto's script stack.
--- `withScriptFile` keeps only the first value of its callback, so the values
--- are packed and unpacked to keep a second value such as `false`.
--- @param file string
--- @param fn function
--- @param element any The element that Pandoc gives to a handler
--- @return any ...
local function with_script(file, fn, element)
  local results = _quarto.withScriptFile(file, function()
    return table.pack(fn(element))
  end)
  return table.unpack(results, 1, results.n)
end

--- Wrap each handler of a filter so it runs with the entry on the stack.
--- @param file string
--- @param filter table
--- @return table
local function wrap_filter(file, filter)
  local wrapped = {}
  for key, value in pairs(filter) do
    if type(value) == 'function' then
      wrapped[key] = function(element)
        return with_script(file, value, element)
      end
    else
      wrapped[key] = value
    end
  end
  return wrapped
end

--- Load a bundled filter, or skip it when the page runs a filter from the
--- project's own copy. Without a filter list from Quarto, a project copy
--- alone skips the bundled filter.
--- The entry runs in its own environment, with `PANDOC_SCRIPT_FILE` set to
--- its path, as Quarto runs a filter. An entry that returns nothing gives the
--- functions it defines as its filter.
--- With `options.plugin`, for an extension that also gives a Reveal.js plugin,
--- the list ends with a filter that warns when the page names the project
--- copy in only one of `filters` and `revealjs-plugins`.
--- With `options.shortcode`, for an extension that also gives shortcodes,
--- `load` warns when the project has a copy that `filters` does not name:
--- Quarto loads the shortcodes of every project extension, so the shortcodes
--- of the copy would run with the bundled filter.
--- Neither check runs without a filter list from Quarto.
--- @param name string The extension name to look for in the project, such as `veil`
--- @param file string The absolute path of the bundled entry, in a folder named `name`
--- @param options table|nil `{ plugin = boolean, shortcode = boolean }`
--- @return table The list of filters; when skipped, empty or only the plugin check
--- @usage return M.load('veil', quarto.utils.resolve_path('../_extensions/mcanouil/veil/veil.lua'), { plugin = true })
function M.load(name, file, options)
  options = options or {}
  local folder = pandoc.path.filename(pandoc.path.directory(file))
  if folder ~= name then
    error('[embedded] The entry ' .. file .. ' is not in a folder named ' .. name ..
      '. Give the name of the bundled extension that holds the entry.')
  end
  local copy = find_project_copy(name)
  local check
  if copy ~= nil then
    local runs = page_runs_from(copy)
    if runs ~= nil and options.plugin then
      check = plugin_check(name, copy, runs)
    end
    if runs == false and options.shortcode then
      quarto.log.warning('[embedded] ' .. name .. ': the shortcodes of the project copy in ' .. copy ..
        ' replace the bundled ones, but the page does not name the copy in `filters`,' ..
        ' so the bundled filter runs with them. Name the copy in `filters`.')
    end
    if runs == true then
      quarto.log.debug('[embedded] ' .. name .. ' is skipped: the page runs the project copy in ' .. copy .. '.')
      return { check }
    end
    if runs == nil then
      quarto.log.debug('[embedded] ' .. name .. ' is skipped: this Quarto gives no filter list, so the project copy in ' .. copy .. ' wins.')
      return {}
    end
    quarto.log.debug('[embedded] ' .. name .. ' runs: the page does not name the project copy in ' .. copy .. '.')
  end
  if type(_quarto) ~= 'table' or type(_quarto.withScriptFile) ~= 'function' then
    error('[embedded] Could not load ' .. name .. ' from ' .. file ..
      ': this Quarto has no internal `_quarto.withScriptFile`, which the module needs.' ..
      ' Use a Quarto version that has it, or name the bundled filter directly.')
  end
  local env = setmetatable({ PANDOC_SCRIPT_FILE = file }, { __index = _G })
  local result = with_script(file, function()
    local chunk, err = loadfile(file, 'bt', env)
    if chunk == nil then
      error('[embedded] Could not load ' .. name .. ' from ' .. file .. ': ' .. tostring(err))
    end
    return chunk()
  end)
  if result == nil then
    result = { traverse = env.traverse }
    for key, value in pairs(env) do
      if type(value) == 'function' then
        result[key] = value
      end
    end
  end
  if type(result) ~= 'table' then
    error('[embedded] ' .. name .. ' at ' .. file .. ' returned a ' .. type(result) ..
      '. A filter entry must return a filter, a list of filters, or nothing.')
  end
  if result[1] == nil then
    result = { result }
  end
  local filters = {}
  for index, filter in ipairs(result) do
    if type(filter) ~= 'table' then
      error('[embedded] ' .. name .. ' at ' .. file .. ' returned a ' .. type(filter) ..
        ' as filter ' .. index .. '. Each filter in the list must be a table.')
    end
    filters[index] = wrap_filter(file, filter)
  end
  filters[#filters + 1] = check
  return filters
end

return M
