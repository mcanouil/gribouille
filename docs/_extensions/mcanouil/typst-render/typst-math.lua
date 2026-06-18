--- Typst Math - Filter (post-quarto)
--- @module "typst-math"
--- @license MIT
--- @copyright 2026 Mickaël Canouil
--- @author Mickaël Canouil
--- @brief Renders document equations as Typst math for HTML and Typst output.
--- @description When `math: typst` is set, treats the contents of every `$...$`
---   and `$$...$$` as Typst math syntax (not LaTeX). For Typst output it emits the
---   math verbatim so Pandoc's writer does not reinterpret it as LaTeX; for HTML
---   output (Typst >= 0.15) it compiles the math to native MathML. Runs at
---   post-quarto so Quarto's equation numbering and `@eq-` cross-references, which
---   wrap equations in a labelled span, are already in place and left untouched.

local EXTENSION_NAME = 'typst-render'

local log = require(quarto.utils.resolve_path('_modules/logging.lua'):gsub('%.lua$', ''))
local meta_mod = require(quarto.utils.resolve_path('_modules/metadata.lua'):gsub('%.lua$', ''))
local paths = require(quarto.utils.resolve_path('_modules/paths.lua'):gsub('%.lua$', ''))
local typst_cli = require(quarto.utils.resolve_path('_modules/typst-cli.lua'):gsub('%.lua$', ''))

--- Module state
local cache_subdir = nil
local html_mode = false
local typst_mode = false
local css_injected = false

--- Font and package directories, read from global config so equations compile
--- with the same resources as `format: html` blocks.
local font_paths = nil
local package_path = nil

--- In-render cache of compiled math bodies, keyed by Typst source.
local html_cache = {}

--- Resolve the Typst binary path.
--- @return string|nil
local function resolve_bin()
  local bin = typst_cli.resolve_bin()
  if not bin then
    log.log_error(EXTENSION_NAME, 'Typst binary not found. Ensure Quarto >= 1.6 is installed.')
  end
  return bin
end

--- Ensure the per-document cache directory exists.
--- @return string|nil Absolute path to the cache directory, or nil on failure
local function ensure_cache_dir()
  if not cache_subdir then
    return nil
  end
  local abs_path = pandoc.path.join({ quarto.project.directory, cache_subdir })
  local ok = pcall(pandoc.system.make_directory, abs_path, true)
  if not ok then
    return nil
  end
  return abs_path
end

--- Inject the equation-numbering layout CSS, once per render.
local function inject_number_css_once()
  if css_injected then
    return
  end
  quarto.doc.include_text(
    'in-header',
    '<style>\n'
    .. '.typst-eq{display:flex;align-items:center;justify-content:center;position:relative;}\n'
    .. '.typst-eq>.typst-eq-number{position:absolute;right:0;}\n'
    -- Inside cross-reference hover previews (tippy popups) the flex/absolute rules
    -- squash the cloned equation; render it in normal flow and drop the number
    -- (the number is the reference itself, so it is redundant in the preview).
    .. '.tippy-content .typst-eq{display:block;}\n'
    .. '.tippy-content .typst-eq>.typst-eq-number{display:none;}\n'
    .. '</style>'
  )
  css_injected = true
end

--- Compile a Typst math expression to HTML and return its `<body>` content.
--- Memoised in-render and cached on disk, both keyed by the Typst source.
--- @param source string Full Typst source (e.g. "$ x^2 $")
--- @return string|nil Body inner HTML, or nil on failure
local function compile_math_html(source)
  local cached_body = html_cache[source]
  if cached_body ~= nil then
    return cached_body or nil
  end

  local bin = resolve_bin()
  if not bin then
    return nil
  end
  local abs_cache = ensure_cache_dir()
  if not abs_cache then
    return nil
  end
  local hash = pandoc.utils.sha1(source):sub(1, 12)
  local abs_output = pandoc.path.join({ abs_cache, 'typst-math-' .. hash .. '.html' })

  local html = typst_cli.read_file(abs_output)
  if not html then
    local root = quarto.project.directory or '.'
    local args = { 'compile', '--format', 'html', '--features', 'html', '--root', root }
    if font_paths then
      for _, p in ipairs(font_paths) do
        args[#args + 1] = '--font-path'
        args[#args + 1] = paths.resolve_project_path(p)
      end
    end
    if package_path then
      args[#args + 1] = '--package-path'
      args[#args + 1] = paths.resolve_project_path(package_path)
    end
    args[#args + 1] = '-'
    args[#args + 1] = abs_output
    local ok = pcall(pandoc.pipe, bin, args, source)
    if not ok then
      return nil
    end
    html = typst_cli.read_file(abs_output)
    if not html then
      log.log_error(EXTENSION_NAME, 'Compiled math HTML not found: ' .. abs_output)
      return nil
    end
  end
  typst_cli.inject_head_style_once(html)
  local body = typst_cli.extract_body(html)
  html_cache[source] = body or false
  return body
end

--- Replace a Math element rendered for HTML output with native MathML.
--- @param m pandoc.Math
--- @return pandoc.Inline|nil
local function render_html_math(m)
  if m.mathtype == 'InlineMath' then
    local body = compile_math_html('$' .. m.text .. '$')
    if not body then
      return nil
    end
    return pandoc.RawInline('html', typst_cli.strip_paragraph(body))
  end

  -- Display math: strip the equation number Quarto appended. The form depends on
  -- the html-math-method: \tag{N} for mathjax/katex, \qquad(N) for mathml/plain.
  -- All numbers are stripped so none leak into the Typst source; a single-number
  -- span is rendered (a multi-line aligned block with several numbers shows only
  -- the first, which the single-equation common case never hits).
  local number = m.text:match('\\tag%{(%d+)%}') or m.text:match('\\qquad%((%d+)%)')
  local cleaned = m.text:gsub('\\tag%{%d+%}', ''):gsub('\\qquad%((%d+)%)', '')
  local body = compile_math_html('$ ' .. cleaned .. ' $')
  if not body then
    return nil
  end
  if number then
    inject_number_css_once()
    return pandoc.RawInline(
      'html',
      '<span class="typst-eq">' .. body
      .. '<span class="typst-eq-number">(' .. number .. ')</span></span>'
    )
  end
  return pandoc.RawInline('html', body)
end

--- Process a Math element.
--- @param m pandoc.Math
--- @return pandoc.Inline|nil
local function process_math(m)
  if typst_mode then
    -- Emit Typst math verbatim so Pandoc's writer does not treat it as LaTeX.
    -- Display math sits inside Quarto's #math.equation([...]) wrapper, where a
    -- $...$ equation is the valid markup-mode form.
    return pandoc.RawInline('typst', '$' .. m.text .. '$')
  end

  if html_mode then
    return render_html_math(m)
  end

  return nil
end

--- Read configuration and decide whether the takeover is active.
--- @param meta pandoc.Meta
--- @return pandoc.Meta
local function configure(meta)
  -- Reset per-document state: Quarto may reuse the Lua state across documents in
  -- a batch render, so a document that does not opt in must not inherit a prior
  -- document's mode, fonts, or cached equations.
  html_mode = false
  typst_mode = false
  font_paths = nil
  package_path = nil
  css_injected = false
  html_cache = {}
  typst_cli.reset_head_injection()
  cache_subdir = typst_cli.doc_cache_subdir()

  local ext_config = meta_mod.get_extension_config(meta, EXTENSION_NAME) or meta['typst-render']
  local math_opt = ext_config and ext_config['math'] and pandoc.utils.stringify(ext_config['math'])
  if math_opt ~= 'typst' then
    return meta
  end

  -- Resolve the same font/package directories the render filter uses, so equations
  -- compiled here match `format: html` blocks. (root and input are not applied:
  -- self-contained equations do not reference files or sys.inputs.)
  if ext_config['font-path'] ~= nil then
    local raw = ext_config['font-path']
    if pandoc.utils.type(raw) == 'List' then
      font_paths = {}
      for _, v in ipairs(raw) do
        font_paths[#font_paths + 1] = pandoc.utils.stringify(v)
      end
    else
      font_paths = { pandoc.utils.stringify(raw) }
    end
  end
  if ext_config['package-path'] ~= nil then
    package_path = pandoc.utils.stringify(ext_config['package-path'])
  end

  -- Only HTML output that can run Typst HTML export gets the MathML takeover;
  -- on an older Typst, leave Quarto's renderer in place. Typst output always
  -- passes through (no Typst CLI needed).
  if quarto.format.is_typst_output() then
    typst_mode = true
  elseif quarto.format.is_html_output() then
    if typst_cli.supports_html(typst_cli.resolve_bin()) then
      html_mode = true
    else
      log.log_warning(EXTENSION_NAME, '\'math: typst\' requires Typst >= 0.15 for HTML output.')
    end
  end

  return meta
end

return {
  { Meta = configure },
  { Math = process_math },
}
