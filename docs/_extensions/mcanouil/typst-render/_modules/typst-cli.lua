--- MC Typst CLI - Typst binary discovery, version detection, and HTML extraction
--- @module typst-cli
--- @license MIT
--- @copyright 2026 Mickaël Canouil
--- @author Mickaël Canouil
--- @version 1.0.0
--- @brief Shared Typst helpers used by both the typst-render and typst-math filters.

local M = {}

--- Resolved Typst binary path (cached across calls).
local bin_cache = nil
local bin_checked = false

--- Parsed Typst version table { major, minor } (cached); false when unavailable.
local version_cache = nil

--- Resolve the Typst binary path via Quarto.
--- Honours the QUARTO_TYPST environment variable (Quarto resolves it before the
--- bundled binary), so pointing QUARTO_TYPST at a newer Typst is reflected here.
--- @return string|nil Path to the Typst binary, or nil if not found
function M.resolve_bin()
  if bin_checked then
    return bin_cache
  end
  bin_checked = true
  local path = quarto.paths.typst()
  if path and path ~= '' then
    bin_cache = path
  end
  return bin_cache
end

--- Detect the version of the resolved Typst binary by invoking `typst --version`.
--- @param bin string Path to the Typst binary
--- @return table|nil { major = number, minor = number }, or nil on failure
function M.get_version(bin)
  if version_cache ~= nil then
    return version_cache or nil
  end
  local ok, out = pcall(pandoc.pipe, bin, { '--version' }, '')
  if ok and type(out) == 'string' then
    local major, minor = out:match('(%d+)%.(%d+)')
    if major and minor then
      version_cache = { major = tonumber(major), minor = tonumber(minor) }
      return version_cache
    end
  end
  version_cache = false
  return nil
end

--- Whether the resolved Typst binary supports HTML export (Typst >= 0.15).
--- @param bin string Path to the Typst binary
--- @return boolean
function M.supports_html(bin)
  local v = M.get_version(bin)
  if not v then
    return false
  end
  return v.major > 0 or v.minor >= 15
end

--- Extract the inner HTML of the `<body>` element from a full Typst HTML document.
--- @param html string Full HTML document
--- @return string Body inner HTML, or the whole input when no body is found
function M.extract_body(html)
  local body = html:match('<body[^>]*>(.*)</body>')
  if body then
    return body
  end
  return html
end

--- Extract the concatenated contents of `<style>` blocks found in the document head.
--- Typst HTML export emits MathML layout CSS in the head; it must be injected once
--- into the host document for correct rendering.
--- @param html string Full HTML document
--- @return string|nil Style contents, or nil when none are present
function M.extract_head_style(html)
  local head = html:match('<head[^>]*>(.-)</head>')
  if not head then
    return nil
  end
  local styles = {}
  for style in head:gmatch('<style[^>]*>(.-)</style>') do
    styles[#styles + 1] = style
  end
  if #styles == 0 then
    return nil
  end
  return table.concat(styles, '\n')
end

--- Strip a single outer `<p>...</p>` wrapper, used to inline body content.
--- @param s string HTML fragment
--- @return string Fragment without an outer paragraph wrapper
function M.strip_paragraph(s)
  local inner = s:match('^%s*<p[^>]*>(.*)</p>%s*$')
  if inner then
    return inner
  end
  return s
end

--- Read a file's full contents.
--- @param path string File path
--- @return string|nil File contents, or nil when the file cannot be opened
function M.read_file(path)
  local f = io.open(path, 'r')
  if not f then
    return nil
  end
  local content = f:read('*a')
  f:close()
  return content
end

--- Inject the MathML/layout CSS that Typst HTML export emits in its document
--- head, at most once per document.
--- @param html string Full Typst HTML document
local head_injected = false
function M.inject_head_style_once(html)
  if head_injected then
    return
  end
  local style = M.extract_head_style(html)
  if style and style ~= '' then
    quarto.doc.include_text('in-header', '<style>\n' .. style .. '\n</style>')
    head_injected = true
  end
end

--- Clear the head-injection guard. Quarto may reuse a single Lua state across
--- documents in a batch render, so each document's Meta pass must reset this
--- before its first block/equation injects the head CSS.
function M.reset_head_injection()
  head_injected = false
end

--- Per-document cache subdirectory derived from the input file stem.
--- @return string Cache subdirectory (e.g. ".quarto/typst-render/index")
function M.doc_cache_subdir()
  local doc_stem = 'default'
  local input_file = quarto.doc.input_file
  if input_file and input_file ~= '' then
    local input_name = pandoc.path.filename(input_file)
    doc_stem = input_name:match('^(.+)%.[^.]+$') or input_name
  end
  return pandoc.path.join({ '.quarto/typst-render', doc_stem })
end

return M
