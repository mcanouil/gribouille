--- Remember - Filter
--- @module "remember"
--- @license MIT
--- @copyright 2026 Mickaël Canouil
--- @author Mickaël Canouil
--- @brief Persist scroll position and slide indices across visits.
--- @description Injects `remember.js` and `remember.css` for HTML-based
--- formats, plus a small bootstrap script that exposes the resolved Quarto
--- project type (book, website, or default) and per-extension options to
--- the client. The project type is read deterministically from
--- `QUARTO_EXECUTE_INFO` so the client never has to guess from theme-specific
--- DOM selectors.

--- Extension name constant
local EXTENSION_NAME = 'remember'

--- Load modules
local html_mod = require(quarto.utils.resolve_path('_vendor/quarto-lua-modules/html.lua'):gsub('%.lua$', ''))
local log = require(quarto.utils.resolve_path('_vendor/quarto-lua-modules/logging.lua'):gsub('%.lua$', ''))
local str = require(quarto.utils.resolve_path('_vendor/quarto-lua-modules/string.lua'):gsub('%.lua$', ''))
local metadata = require(quarto.utils.resolve_path('_vendor/quarto-lua-modules/metadata.lua'):gsub('%.lua$', ''))
local schema = require(quarto.utils.resolve_path('_vendor/quarto-wizard/schema.lua'):gsub('%.lua$', ''))
local check = require(quarto.utils.resolve_path('_vendor/quarto-lua-modules/schema-check.lua'):gsub('%.lua$', ''))

--- The schema check, built once and reused by the whole render. It reads
--- `_schema.yml` on the way in and checks the document configuration once.
---
--- The validator is injected rather than required by the check module, so the
--- two vendored sources stay independent of where the other was placed.
---
--- The extension contributes a filter and no shortcodes, so the check runs from
--- the `Meta` handler of that filter, before the handler reads its first option.
--- There is nowhere else it could run.
---
--- A schema that cannot be read is reported by the module as an error and the
--- render carries on: a configuration file must not stop a document.
local checker = check.new(schema, EXTENSION_NAME)

-- ============================================================================
-- HELPER FUNCTIONS (PRIVATE)
-- ============================================================================

--- Resolve the Quarto project type from `QUARTO_EXECUTE_INFO`.
--- Returns one of `"book"`, `"website"`, or `"default"`.
--- `"default"` covers single documents and any project whose type is neither
--- a book nor a website. A book is checked first, because a book project also
--- carries `website` metadata.
--- When the variable is unset, or the file has no `format.metadata` table, the
--- function returns `"default"` with no warning. When the file cannot be read,
--- is empty, or is not valid JSON, it logs a warning and returns `"default"`,
--- so detection degrades safely.
--- @return string project_type One of `"book"`, `"website"`, or `"default"`
local function resolve_project_type()
  local format_meta, reason = metadata.get_project_metadata()
  if not format_meta then
    if reason == 'file is unreadable' then
      log.log_warning(EXTENSION_NAME,
        "Could not open QUARTO_EXECUTE_INFO at '" .. os.getenv('QUARTO_EXECUTE_INFO') ..
        "'; assuming a single-document project.")
    elseif reason == 'file is empty' then
      log.log_warning(EXTENSION_NAME,
        "QUARTO_EXECUTE_INFO is empty; assuming a single-document project.")
    elseif reason == 'invalid JSON' then
      log.log_warning(EXTENSION_NAME,
        "Could not parse QUARTO_EXECUTE_INFO; assuming a single-document project.")
    end
    return 'default'
  end

  if format_meta['book'] then return 'book' end
  if format_meta['website'] then return 'website' end
  return 'default'
end

--- Normalise a resolved list option to a list of strings.
--- The schema accepts a string or a list, and the validator returns whichever
--- the document wrote, so a single entry becomes a one item list here.
--- @param value string|table<integer, string>|nil The resolved option value
--- @return table<integer, string> The list of string values (possibly empty)
local function as_string_list(value)
  if value == nil then return {} end

  if type(value) ~= 'table' then
    local entry = tostring(value)
    return entry ~= '' and { entry } or {}
  end

  local result = {}
  for _, item in ipairs(value) do
    local entry = tostring(item)
    if entry ~= '' then result[#result + 1] = entry end
  end
  return result
end

--- Return the path of the source file, relative to the project root, with
--- `/` separators. A single document rendered outside a project has no root,
--- so its base name stands in for the relative path. A file outside the
--- project root gets `nil`, so no pattern can match it by accident.
--- @return string|nil The project-relative source path
local function source_path()
  local input = (quarto.doc.input_file or ''):gsub('\\', '/')
  local root = quarto.project.directory
  if root == nil or root == '' then
    return (input:match('[^/]+$') or input)
  end
  root = root:gsub('\\', '/'):gsub('/+$', '') .. '/'
  if input:sub(1, #root) == root then
    return input:sub(#root + 1)
  end
  return nil
end

--- Resolve a pattern that Quarto made relative to the page.
--- Quarto rewrites a project metadata string that names an existing file so
--- that it is relative to the page being rendered: on `guide/intro.qmd`, the
--- entry `guide/intro.qmd` arrives as `../guide/intro.qmd`. Such a pattern is
--- joined to the folder of the page and collapsed back to a project-relative
--- path. Any other pattern is already relative to the project. A pattern
--- that climbs above the project root names no page, so it gets `nil`.
--- @param pattern string The pattern as the filter receives it
--- @param page string The project-relative path of the page
--- @return string|nil The project-relative pattern
local function project_relative(pattern, page)
  pattern = pattern:gsub('\\', '/')
  if pattern:sub(1, 3) ~= '../' then
    return (pattern:gsub('^%./', ''))
  end
  local parts = {}
  for segment in (page:match('^(.*)/[^/]*$') or ''):gmatch('[^/]+') do
    parts[#parts + 1] = segment
  end
  for segment in pattern:gmatch('[^/]+') do
    if segment == '..' then
      if #parts == 0 then return nil end
      parts[#parts] = nil
    elseif segment ~= '.' then
      parts[#parts + 1] = segment
    end
  end
  return table.concat(parts, '/')
end

--- Turn a `page-exclude` pattern into an anchored Lua pattern. Every
--- character is literal except `*`, which matches within one path segment.
--- @param pattern string A project-relative path, optionally with `*`
--- @return string The anchored Lua pattern
local function to_lua_pattern(pattern)
  return '^' .. str.escape_lua_pattern(pattern):gsub('%%%*', '[^/]*') .. '$'
end

--- Report whether the source file matches one of the `page-exclude` patterns.
--- @param patterns table<integer, string> Project-relative source paths
--- @return boolean True when the page must carry no remember code
local function is_excluded(patterns)
  if #patterns == 0 then return false end
  for _, pattern in ipairs(patterns) do
    if pattern:sub(1, 1) == '/' or pattern:match('%.html$') then
      log.log_warning(EXTENSION_NAME,
        "page-exclude entry '" .. pattern .. "' looks like a URL. " ..
        "Entries name source files relative to the project, " ..
        "for example 'about.qmd' or 'drafts/*.qmd'.")
    end
  end
  local path = source_path()
  if path == nil then
    log.log_warning(EXTENSION_NAME,
      "Could not place '" .. tostring(quarto.doc.input_file) .. "' inside the project directory '" ..
      tostring(quarto.project.directory) .. "', so page-exclude is not applied to it.")
    return false
  end
  for _, pattern in ipairs(patterns) do
    local relative = project_relative(pattern, path)
    if relative and path:match(to_lua_pattern(relative)) then return true end
  end
  return false
end

--- Encode a Lua value as a JSON literal suitable for inlining in a
--- `<script>` block. The result never contains the substring `</`, so
--- it cannot prematurely terminate the script element.
--- @param value any Any value `quarto.json.encode` accepts
--- @return string JSON literal with `</` neutralised
local function encode_for_script(value)
  local encoded = quarto.json.encode(value)
  -- Defensive: prevent the literal "</" from closing the <script> early.
  return (encoded:gsub('</', '<\\/'))
end

--- Build the bootstrap `<script>` that hands the resolved options to the
--- client. The payload is intentionally minimal: project type and the
--- separate-chapter-state flag.
--- @param project_type string One of `"book"`, `"website"`, or `"default"`
--- @param separate_chapter_state boolean Whether to store chapter and
---   scroll position under independent keys
--- @return string Raw HTML containing the bootstrap script
local function build_bootstrap_script(project_type, separate_chapter_state)
  local payload = {
    ['project-type'] = project_type,
    ['separate-chapter-state'] = separate_chapter_state,
  }
  return string.format(
    '<script id="quarto-remember-config" type="application/json">%s</script>',
    encode_for_script(payload)
  )
end

-- ============================================================================
-- PUBLIC FUNCTIONS
-- ============================================================================

--- Inject dependencies and the bootstrap configuration for HTML-based formats.
--- @param meta table Document metadata
--- @return table Modified metadata
local function inject_dependencies(meta)
  if not quarto.doc.is_format('html:js') then
    return meta
  end

  checker:options(meta)

  -- A disabled filter or an excluded page gets no script, no stylesheet and
  -- no configuration, so it carries no remember code at all.
  if checker:option('enabled') == false
      or is_excluded(as_string_list(checker:option('page-exclude'))) then
    return meta
  end

  html_mod.ensure_html_dependency({
    name = EXTENSION_NAME,
    scripts = { 'remember.js' },
    stylesheets = { 'remember.css' },
  })

  local project_type = resolve_project_type()
  -- The schema decides the value, so `separate-chapter-state: no` turns the
  -- feature off. Reading the document itself left it on.
  local separate_chapter_state = checker:option('separate-chapter-state') == true

  local script = build_bootstrap_script(project_type, separate_chapter_state)
  quarto.doc.include_text('in-header', script)

  return meta
end

-- ============================================================================
-- FILTER EXPORT
-- ============================================================================

--- Pandoc filter configuration
return {
  { Meta = inject_dependencies },
}
