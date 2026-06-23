--- MC Iconify Typst - Iconify SVG retrieval, on-disk caching and Typst emission
--- @module "typst"
--- @license MIT
--- @copyright 2026 Mickaël Canouil
--- @author Mickaël Canouil
--- @version 1.0.0
---
--- Typst cannot natively reach the Iconify icon library. This module fetches
--- the SVG for a requested icon from the public Iconify API, caches it on disk
--- under the Quarto project cache, and emits a Typst `#image(...)` referencing
--- the cached file. The cache is bounded (age- and count-based) and the
--- cleanup is lock-free yet concurrency-safe: it only ever removes entries
--- whose `.used` stamp is older than the threshold, and every in-flight render
--- re-stamps the icons it uses so a concurrent sweep never selects them.

local M = {}

--- Load a sibling module from the same directory as this file.
--- @param filename string The sibling module filename (e.g., 'string.lua')
--- @return table The loaded module
local function load_sibling(filename)
  local source = debug.getinfo(1, 'S').source:sub(2)
  local dir = source:match('(.*[/\\])') or ''
  return require((dir .. filename):gsub('%.lua$', ''))
end

local str = load_sibling('string.lua')
local log = load_sibling('logging.lua')
local meta_mod = load_sibling('metadata.lua')

--- Extension name constant
local EXTENSION_NAME = 'iconify'
--- Base URL of the public Iconify SVG API.
local API_BASE = 'https://api.iconify.design/'
--- Default cache directory, relative to the Quarto project root.
local DEFAULT_CACHE_REL = '.quarto/iconify-svg'
--- Default maximum age (days) before a cache entry is evicted.
local DEFAULT_MAX_AGE_DAYS = 30
--- Grace window (seconds) during which a recently-used entry is never evicted
--- by the count cap, protecting icons an in-flight render is relying on.
local GRACE_SECONDS = 300

--- Units that Typst's `image` height/width accept. CSS units such as `px`,
--- `rem`, `ex` and the viewport units are intentionally excluded.
--- @type table<string, boolean>
local TYPST_UNITS = {
  pt = true, mm = true, cm = true, ['in'] = true, em = true, ['%'] = true
}

-- ============================================================================
-- PATH / NAMING HELPERS
-- ============================================================================

--- Resolve the Quarto project root. Falls back to the working directory for
--- single-file renders where no project is active.
--- @return string
local function project_base()
  local base = os.getenv('QUARTO_PROJECT_DIR')
  if base == nil or base == '' then
    return '.'
  end
  return base
end

--- Resolve the cache directory relative to the project root, honouring the
--- `extensions.iconify.typst-cache` metadata override. The result is kept
--- inside the project root: leading/trailing slashes are trimmed and any
--- `..` segments are dropped so the override cannot escape the project (and
--- so the Typst root-relative `#image` path stays valid).
--- @param meta table|nil Document metadata
--- @return string A normalised, project-root-relative directory
local function resolve_reldir(meta)
  local rel = meta and meta_mod.get_metadata_value(meta, 'iconify', 'typst-cache')
  if str.is_empty(rel) then
    rel = DEFAULT_CACHE_REL
  end
  --- @cast rel string
  --- @type table<integer, string>
  local segments = {}
  for segment in rel:gmatch('[^/\\]+') do
    if segment ~= '..' and segment ~= '.' then
      segments[#segments + 1] = segment
    end
  end
  if #segments == 0 then
    return DEFAULT_CACHE_REL
  end
  return table.concat(segments, '/')
end

--- URL-encode a query parameter value (RFC 3986 unreserved set kept verbatim).
--- @param value string
--- @return string
local function urlencode(value)
  return (value:gsub('[^%w%-_%.~]', function(c)
    return string.format('%%%02X', string.byte(c))
  end))
end

--- Build a deterministic, sorted query string from a parameter table.
--- Keys are sorted so the resulting string (and its hash) is stable.
--- @param params table<string, string>
--- @return string The query string without a leading `?` (empty if no params)
function M.build_query(params)
  --- @type table<integer, string>
  local keys = {}
  for k, v in pairs(params) do
    if not str.is_empty(v) then
      keys[#keys + 1] = k
    end
  end
  table.sort(keys)
  --- @type table<integer, string>
  local parts = {}
  for _, k in ipairs(keys) do
    parts[#parts + 1] = k .. '=' .. urlencode(params[k])
  end
  return table.concat(parts, '&')
end

--- Assemble the Iconify SVG API URL for an icon and query.
--- @param set string Icon set (prefix)
--- @param icon string Icon name
--- @param query string Pre-built query string (may be empty)
--- @return string
function M.build_api_url(set, icon, query)
  local url = API_BASE .. set .. '/' .. icon .. '.svg'
  if query ~= '' then
    url = url .. '?' .. query
  end
  return url
end

--- Deterministic cache file name for an icon variant.
--- @param set string
--- @param icon string
--- @param query string
--- @return string
local function entry_name(set, icon, query)
  local hash = pandoc.utils.sha1(set .. '/' .. icon .. '?' .. query):sub(1, 8)
  return set .. '-' .. icon .. '-' .. hash .. '.svg'
end

-- ============================================================================
-- FILESYSTEM HELPERS
-- ============================================================================

--- Ensure a directory exists (creating parents). Failure is non-fatal.
--- @param dir string
--- @return nil
local function ensure_dir(dir)
  pcall(function() pandoc.system.make_directory(dir, true) end)
end

--- Write content to a path atomically: write to a unique temp file then
--- rename into place so a concurrent reader never sees a partial file.
--- @param path string Destination path
--- @param content string
--- @return boolean True on success
local function write_atomic(path, content)
  local tmp = path .. '.tmp.' .. tostring(os.time()) .. '.' ..
      tostring(math.random(0, 1000000)) .. tostring(os.clock())
  local handle = io.open(tmp, 'wb')
  if not handle then
    return false
  end
  handle:write(content)
  handle:close()
  if os.rename(tmp, path) then
    return true
  end
  -- Windows rename fails if the destination exists; replace then retry.
  os.remove(path)
  if os.rename(tmp, path) then
    return true
  end
  os.remove(tmp)
  return false
end

--- Path of the sidecar last-used stamp for a cache entry.
--- @param fspath string
--- @return string
local function stamp_path(fspath)
  return fspath .. '.used'
end

--- Record the current time as the last-used stamp for a cache entry.
--- @param fspath string
--- @return nil
local function touch(fspath)
  write_atomic(stamp_path(fspath), tostring(os.time()))
end

--- Read the last-used epoch from a cache entry's stamp.
--- @param fspath string
--- @return integer|nil
local function read_stamp(fspath)
  local handle = io.open(stamp_path(fspath), 'rb')
  if not handle then
    return nil
  end
  local content = handle:read('*a')
  handle:close()
  if content == nil then
    return nil
  end
  return tonumber(content:match('%d+'))
end

-- ============================================================================
-- FETCHING
-- ============================================================================

--- Check that a payload looks like an SVG document.
--- @param data string|nil
--- @return boolean
local function valid_svg(data)
  if str.is_empty(data) then
    return false
  end
  --- @cast data string
  local head = data:gsub('^%s+', ''):sub(1, 5):lower()
  return head:sub(1, 4) == '<svg' or head == '<?xml'
end

--- Fetch an SVG, preferring Pandoc's mediabag and falling back to curl.
--- @param url string
--- @return string|nil The SVG content, or nil on failure
local function fetch_svg(url)
  local ok, _, data = pcall(function()
    return pandoc.mediabag.fetch(url)
  end)
  if ok and valid_svg(data) then
    return data
  end

  local handle = io.popen("curl -fsSL '" .. url:gsub("'", "'\\''") .. "' 2>/dev/null")
  if handle then
    local out = handle:read('*a')
    handle:close()
    if valid_svg(out) then
      return out
    end
  end

  return nil
end

-- ============================================================================
-- PUBLIC API
-- ============================================================================

--- Ensure an icon SVG is cached on disk, fetching it if needed.
--- Refreshes the last-used stamp on every hit and write.
--- @param set string
--- @param icon string
--- @param query string Pre-built query string (may be empty)
--- @param meta table|nil Document metadata
--- @return string|nil Typst project-root-relative image path, or nil on failure
function M.ensure_cached(set, icon, query, meta)
  local reldir = resolve_reldir(meta)
  local dir = project_base() .. '/' .. reldir
  local name = entry_name(set, icon, query)
  local fspath = dir .. '/' .. name
  --- Leading slash makes the path relative to the Typst project root.
  local typst_path = '/' .. reldir .. '/' .. name

  local existing = io.open(fspath, 'rb')
  if existing then
    existing:close()
    touch(fspath)
    return typst_path
  end

  local data = fetch_svg(M.build_api_url(set, icon, query))
  if data == nil then
    return nil
  end

  ensure_dir(dir)
  if not write_atomic(fspath, data) then
    return nil
  end
  touch(fspath)
  return typst_path
end

--- Render an icon as a Typst `#image`, fetching/caching as needed.
--- @param opts table Fields: set, icon, query, size_value, inline, alt,
---   fallback, meta.
--- @return any Pandoc RawInline (Typst), Str (fallback), or Null
function M.render(opts)
  local typst_path = M.ensure_cached(opts.set, opts.icon, opts.query, opts.meta)
  if typst_path == nil then
    log.log_warning(
      EXTENSION_NAME,
      'Could not retrieve icon "' .. opts.set .. ':' .. opts.icon ..
      '" for Typst output' ..
      (str.is_empty(opts.fallback) and '.' or '; using fallback.')
    )
    if not str.is_empty(opts.fallback) then
      return pandoc.Str(opts.fallback)
    end
    return pandoc.Null()
  end

  --- @type string
  local height = opts.size_value
  if str.is_empty(height) then
    height = '1em'
  end

  --- @type string
  local image_args = '"' .. str.escape_typst_string(typst_path) ..
      '", height: ' .. height
  if not str.is_empty(opts.alt) then
    image_args = image_args .. ', alt: "' .. str.escape_typst_string(opts.alt) .. '"'
  end

  --- @type string
  local code
  if opts.inline then
    code = '#box(baseline: 0.125em, image(' .. image_args .. '))'
  else
    code = '#image(' .. image_args .. ')'
  end
  return pandoc.RawInline('typst', code)
end

--- Validate that a length value uses a Typst-supported unit.
--- @param value string|nil
--- @return string|nil The value if Typst-compatible, otherwise nil
function M.typst_length(value)
  if str.is_empty(value) then
    return nil
  end
  --- @cast value string
  local number_part, unit = value:match('^([-+]?%d*%.?%d+)(.*)$')
  if not number_part or unit == '' then
    return nil
  end
  if TYPST_UNITS[unit] then
    return value
  end
  return nil
end

--- Evict cache entries to keep the cache bounded. Age pass first, then a
--- least-recently-used count cap. Lock-free and idempotent; safe to run
--- concurrently across independent renders: the age pass only removes entries
--- unused for `max-age` days (which no live render references, since every use
--- re-stamps), and the count cap never evicts entries used within a short
--- grace window (so an in-flight render's freshly-cached icons are protected).
--- @param meta table Document metadata
--- @return nil
function M.cleanup(meta)
  local dir = project_base() .. '/' .. resolve_reldir(meta)

  --- @type table<integer, string>|nil
  local listing
  local ok = pcall(function() listing = pandoc.system.list_directory(dir) end)
  if not ok or listing == nil then
    -- Cache directory does not exist yet (nothing rendered): nothing to do.
    return
  end

  --- @type number
  local max_age_days = tonumber(
    meta_mod.get_metadata_value(meta, 'iconify', 'typst-cache-max-age')
  ) or DEFAULT_MAX_AGE_DAYS
  --- @type number
  local max_entries = tonumber(
    meta_mod.get_metadata_value(meta, 'iconify', 'typst-cache-max-entries')
  ) or 0
  --- @type integer
  local now = os.time()

  --- @type table<integer, table>
  local entries = {}
  for _, fname in ipairs(listing) do
    if fname:sub(-4) == '.svg' then
      local fspath = dir .. '/' .. fname
      local used = read_stamp(fspath)
      if used == nil then
        -- Missing/garbled stamp: treat as in use, re-stamp, never evict now.
        touch(fspath)
        used = now
      end
      entries[#entries + 1] = { path = fspath, used = used }
    end
  end

  --- @param entry table
  --- @return nil
  local function remove_entry(entry)
    os.remove(entry.path)
    os.remove(stamp_path(entry.path))
  end

  --- @type table<integer, table>
  local survivors = {}
  if max_age_days > 0 then
    local cutoff = now - math.floor(max_age_days * 86400)
    for _, entry in ipairs(entries) do
      if entry.used < cutoff then
        remove_entry(entry)
      else
        survivors[#survivors + 1] = entry
      end
    end
  else
    survivors = entries
  end

  if max_entries > 0 and #survivors > max_entries then
    -- Oldest first; never evict entries used within the grace window, as a
    -- concurrent render may be relying on them right now.
    local grace = now - GRACE_SECONDS
    table.sort(survivors, function(a, b) return a.used < b.used end)
    local count = #survivors
    for i = 1, #survivors do
      if count <= max_entries then break end
      if survivors[i].used >= grace then break end
      remove_entry(survivors[i])
      count = count - 1
    end
  end
end

-- ============================================================================
-- MODULE EXPORT
-- ============================================================================

return M
