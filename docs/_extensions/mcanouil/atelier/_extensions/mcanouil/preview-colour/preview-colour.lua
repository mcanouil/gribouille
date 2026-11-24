--- @module "preview-colour"
--- @license MIT
--- @copyright 2026 Mickaël Canouil
--- @author Mickaël Canouil

--- Extension name constant
local EXTENSION_NAME = "preview-colour"

--- Load required modules
local str = require(quarto.utils.resolve_path("_vendor/quarto-lua-modules/string.lua"):gsub("%.lua$", ""))
local log = require(quarto.utils.resolve_path("_vendor/quarto-lua-modules/logging.lua"):gsub("%.lua$", ""))
local meta_mod = require(quarto.utils.resolve_path("_vendor/quarto-lua-modules/metadata.lua"):gsub("%.lua$", ""))
local pdoc = require(quarto.utils.resolve_path("_vendor/quarto-lua-modules/pandoc-helpers.lua"):gsub("%.lua$", ""))
local html = require(quarto.utils.resolve_path("_vendor/quarto-lua-modules/html.lua"):gsub("%.lua$", ""))
local colour = require(quarto.utils.resolve_path("_vendor/quarto-lua-modules/colour.lua"):gsub("%.lua$", ""))
local schema = require(quarto.utils.resolve_path("_vendor/quarto-wizard/schema.lua"):gsub("%.lua$", ""))
local check = require(quarto.utils.resolve_path("_vendor/quarto-lua-modules/schema-check.lua"):gsub("%.lua$", ""))

--- The schema check, built once and reused by every pass of the filter. It reads
--- `_schema.yml` on the way in and checks the document configuration once.
---
--- The validator is injected rather than required by the check module, so the
--- two vendored sources stay independent of where the other was placed.
---
--- The extension contributes a filter and no shortcode, so the check runs from
--- the `Meta` handler, which is the first pass to see the document.
---
--- A schema that cannot be read is reported by the module as an error and the
--- render carries on: a configuration file must not stop a document.
local checker = check.new(schema, EXTENSION_NAME)

--- Flag to track if deprecation warning has been shown.
--- @type boolean
local deprecation_warning_shown = false

--- Flag to track if the alpha-loss warning has been shown.
--- @type boolean
local alpha_loss_warning_shown = false

--- Flag to track if the keyword-unsupported warning has been shown.
--- @type boolean
local keyword_unsupported_warning_shown = false

--- Optional file path for bulk JSON export of detected colours.
--- @type string|nil
local json_export_file = nil

--- Accumulator for detected colours when bulk export is enabled.
--- Each entry: { original = "...", hex = "#RRGGBB", alpha = nil|"##", format = "hex6|rgb|...", source = "code|text" }
--- @type table[]
local detected_colours = {}

--- Default configuration for preview colour features.
--- @type table<string, any>
local preview_colour_meta = {
  ["text"] = false,
  ["code"] = true
}

--- Default glyphs for each output format.
--- @type table<string, string>
local default_glyphs = {
  ["html"] = "&#9673;",
  ["latex"] = "\\textbullet",
  ["typst"] = "◉",
  ["docx"] = "●",
  ["pptx"] = "●"
}

--- CSS keyword colours with no resolvable preview value.
--- Used for `currentColor` and `transparent`, which require special rendering paths
--- because they cannot be reduced to an opaque hex swatch.
--- @type table<string, boolean>
local keyword_colours = {
  ["currentcolor"] = true,
  ["transparent"] = true
}

--- Record a detected colour for the bulk JSON export when enabled.
--- @param spec table Colour spec table.
--- @param source string Source kind: "code", "text", or "text-multitoken".
local function record_detected(spec, source)
  if json_export_file == nil then return end
  table.insert(detected_colours, {
    original = spec.original or spec.css or spec.hex,
    hex = spec.hex,
    alpha = spec.alpha,
    keyword = spec.keyword,
    css = spec.css,
    source = source
  })
end

--- Clamp a number into the [0, 1] range.
--- @param value number Input value.
--- @return number Clamped value.
local function clamp01(value)
  if value < 0 then return 0 end
  if value > 1 then return 1 end
  return value
end

--- Parse an alpha component from a CSS value (number 0-1 or `<n>%`).
--- @param raw string|nil Raw alpha token.
--- @return number Alpha in [0, 1]; defaults to 1 when `raw` is nil or unparseable.
local function parse_alpha(raw)
  if raw == nil or raw == '' then
    return 1
  end
  local stripped = raw:gsub('%s+', '')
  local percent = stripped:match('^([%d%.]+)%%$')
  if percent then
    return clamp01(tonumber(percent) / 100)
  end
  local number = tonumber(stripped)
  if number == nil then
    return 1
  end
  return clamp01(number)
end

--- Format an alpha component as a two-digit hex pair.
--- @param alpha number Alpha in [0, 1].
--- @return string Two-digit uppercase hex.
local function alpha_to_hex(alpha)
  local n = math.floor(alpha * 255 + 0.5)
  return string.upper(string.format('%02x', n))
end

--- Convert an `rgba(r, g, b, a)` string to an opaque hex and alpha hex pair.
--- @param css string CSS rgba value.
--- @return string|nil, string|nil Hex (`#RRGGBB`) and alpha hex (`##`), or nil if unparseable.
local function rgba_to_hex(css)
  local r, g, b, a = css:match('rgba?%s*%(%s*(%d+)%s*,%s*(%d+)%s*,%s*(%d+)%s*,%s*([%d%.%%]+)%s*%)')
  if not r then return nil, nil end
  local hex = string.upper(string.format('#%02x%02x%02x', tonumber(r), tonumber(g), tonumber(b)))
  return hex, alpha_to_hex(parse_alpha(a))
end

--- Convert an `hsla(h, s%, l%, a)` string to an opaque hex and alpha hex pair.
--- @param css string CSS hsla value.
--- @return string|nil, string|nil Hex (`#RRGGBB`) and alpha hex (`##`), or nil if unparseable.
local function hsla_to_hex(css)
  local h, s, l, a = css:match('hsla?%s*%(%s*(%d+)%s*,%s*(%d+)%%%s*,%s*(%d+)%%%s*,%s*([%d%.%%]+)%s*%)')
  if not h then return nil, nil end
  local opaque = colour.HSL_to_HTML('hsl(' .. h .. ', ' .. s .. '%, ' .. l .. '%)')
  return opaque, alpha_to_hex(parse_alpha(a))
end

--- Check for deprecated top-level preview-colour configuration and emit warning if found.
--- @param meta table<string, any> Document metadata table.
--- @param key string The configuration key being accessed.
--- @return boolean|nil The value from deprecated config, or nil if not found.
local function check_deprecated_config(meta, key)
  local value
  value, deprecation_warning_shown = meta_mod.check_deprecated_config(meta, 'preview-colour', key, deprecation_warning_shown)
  return value
end

--- Get preview-colour option from metadata with deprecation support.
--- @param key string The option name to retrieve.
--- @param meta table<string, any> Document metadata table.
--- @return boolean The option value as a boolean.
local function get_preview_colour_option(key, meta)
  -- Both sources hand back a string, and the callers compare against a boolean,
  -- so coerce here rather than leaving the type to depend on where the value
  -- came from.
  -- Check new nested structure: extensions.preview-colour.key
  local meta_value = meta_mod.get_metadata_value(meta, 'preview-colour', key)
  if not str.is_empty(meta_value) then
    return meta_value:lower() ~= 'false'
  end

  -- Check deprecated top-level structure: preview-colour.key (with warning)
  local deprecated_value = check_deprecated_config(meta, key)
  if deprecated_value ~= nil then
    return tostring(deprecated_value):lower() ~= 'false'
  end

  -- Return default values: code: true, text: false
  if key == 'code' then
    return true
  elseif key == 'text' then
    return false
  end

  return true -- fallback for any other keys
end

--- Get glyph for a specific output format.
--- Checks user configuration and falls back to defaults.
--- @param format string Output format (html, latex, typst, docx, pptx).
--- @return string The glyph to use for the format.
local function get_glyph_for_format(format)
  local glyph_config = preview_colour_meta['glyph']

  if glyph_config == nil then
    return default_glyphs[format] or default_glyphs["html"]
  end

  -- In Pandoc Lua, metadata values are never plain strings.
  -- Simple string config (glyph: "●") becomes MetaInlines (table with numeric keys).
  -- Per-format config (glyph: {html: "●"}) becomes MetaMap (table with string keys).
  -- Check if it's a MetaMap by looking for string keys.
  local is_format_table = false
  if type(glyph_config) == "table" then
    for k, _ in pairs(glyph_config) do
      if type(k) == "string" then
        is_format_table = true
        break
      end
    end
  end

  local glyph = nil

  if is_format_table then
    -- Per-format configuration (MetaMap)
    if glyph_config[format] then
      glyph = str.stringify(glyph_config[format])
    elseif glyph_config["default"] then
      glyph = str.stringify(glyph_config["default"])
    end
  else
    -- Simple string configuration (MetaInlines) or plain string
    local glyph_str = str.stringify(glyph_config)
    if glyph_str and glyph_str ~= "" then
      glyph = glyph_str
    end
  end

  -- Fall back to default if no glyph found
  if glyph == nil then
    return default_glyphs[format] or default_glyphs["html"]
  end

  return glyph
end


--- Create colour preview mark for HTML format.
--- Accepts either an opaque hex colour or a CSS colour string (for keywords/alpha).
--- The mark is a button, so it is reachable and operable from the keyboard.
--- The copy itself is done by `preview-colour.js`, which reads `data-colour`.
--- @param css string CSS colour value to apply (e.g. `#FF0000`, `rgba(...)`, `currentColor`, `transparent`).
--- @param label string Human-readable label for the accessible name and copy buffer.
--- @param glyph string Glyph character to use for the preview.
--- @return string HTML colour preview mark.
local function create_html_colour_mark(css, label, glyph)
  html.ensure_html_dependency({
    name = EXTENSION_NAME,
    stylesheets = { 'preview-colour.css' },
    scripts = { 'preview-colour.js' },
  })
  local name = str.escape_html('Copy colour ' .. label)
  return '<button type="button" class="preview-colour" data-colour="' .. str.escape_html(label) ..
      '" aria-label="' .. name .. '" title="' .. name ..
      '"><span style="color: ' .. str.escape_html(css) ..
      ';" aria-hidden="true">' .. glyph .. '</span></button>'
end

--- Create colour preview mark for LaTeX format.
--- @param hex string Hex colour code.
--- @param glyph string Glyph character to use for the preview.
--- @return string LaTeX colour preview mark.
local function create_latex_colour_mark(hex, glyph)
  local hex_colour_six = colour.expand_hex_colour(hex)
  return "\\textcolor[HTML]{" .. string.gsub(hex_colour_six, '#', '') .. "}{" .. glyph .. "}"
end

--- Create colour preview mark for Typst format.
--- @param hex string Hex colour code.
--- @param glyph string Glyph character to use for the preview.
--- @return string Typst colour preview mark.
local function create_typst_colour_mark(hex, glyph)
  local hex_colour_six = colour.expand_hex_colour(hex)
  return '#text(fill: rgb("' .. string.lower(hex_colour_six) .. '"))[' .. glyph .. ']'
end

--- Create colour preview mark for DOCX format using OpenXML.
--- @param hex string Hex colour code.
--- @param glyph string Glyph character to use for the preview.
--- @return string DOCX colour preview mark using OpenXML.
local function create_docx_colour_mark(hex, glyph)
  local hex_colour_six = colour.expand_hex_colour(hex)
  local hex_without_hash = string.gsub(hex_colour_six, '#', '')
  return '<w:r><w:rPr><w:color w:val="' .. hex_without_hash .. '"/></w:rPr><w:t>' .. glyph .. '</w:t></w:r>'
end

--- Create colour preview mark for PPTX format using OpenXML.
--- @param hex string Hex colour code.
--- @param glyph string Glyph character to use for the preview.
--- @return string PPTX colour preview mark using OpenXML.
local function create_pptx_colour_mark(hex, glyph)
  local hex_colour_six = colour.expand_hex_colour(hex)
  local hex_without_hash = string.gsub(hex_colour_six, '#', '')
  return '<a:r><a:rPr dirty="0"><a:solidFill><a:srgbClr val="' ..
      hex_without_hash .. '" /></a:solidFill></a:rPr><a:t>' .. glyph .. '</a:t></a:r>'
end

--- Create colour preview mark for the specified format.
--- Supports the legacy hex-only signature plus alpha and keyword colours.
--- For keyword colours (`currentColor`, `transparent`) and alpha-bearing colours,
--- only HTML produces a faithful preview; other formats render an opaque hex when
--- possible and skip the swatch (with a one-time warning) when there is no hex.
--- @param spec table|string Colour specification table, or a hex string for back-compat.
---        Table fields: { hex = "#RRGGBB"|nil, alpha = "##"|nil, css = "..."|nil, keyword = "..."|nil, original = "..." }
--- @param format string Output format (html, latex, typst, docx, pptx).
--- @param glyph string Glyph character to use for the preview.
--- @return string|nil Colour preview mark for the format, or nil when no preview is possible.
local function create_colour_mark(spec, format, glyph)
  if type(spec) == 'string' then
    spec = { hex = spec, original = spec }
  end

  local colour_mark_functions = {
    latex = create_latex_colour_mark,
    typst = create_typst_colour_mark,
    docx = create_docx_colour_mark,
    pptx = create_pptx_colour_mark
  }

  if format == 'html' then
    local css = spec.css or spec.keyword
    if css == nil and spec.hex then
      if spec.alpha then
        css = spec.hex .. spec.alpha
      else
        css = spec.hex
      end
    end
    if css == nil then return nil end
    return create_html_colour_mark(css, spec.original or css, glyph)
  end

  local create_mark = colour_mark_functions[format]
  if not create_mark then
    error('Unsupported format: ' .. format)
  end

  if spec.keyword then
    if not keyword_unsupported_warning_shown then
      log.log_warning(
        EXTENSION_NAME,
        'Keyword colour "' .. spec.keyword .. '" has no preview in ' .. format ..
        '; only HTML renders these faithfully.'
      )
      keyword_unsupported_warning_shown = true
    end
    return nil
  end

  if spec.alpha and not alpha_loss_warning_shown then
    log.log_warning(
      EXTENSION_NAME,
      'Alpha channel is not preserved in ' .. format ..
      '; rendering the opaque colour for "' .. (spec.original or spec.hex or '') .. '".'
    )
    alpha_loss_warning_shown = true
  end

  if spec.hex == nil then return nil end
  return create_mark(spec.hex, glyph)
end

--- Convert a recognised colour token to a structured spec.
--- @param token string The matched colour text.
--- @param token_format string Pattern name (`hex6`, `rgba`, `keyword`, ...).
--- @return table|nil Spec table with `hex`, `alpha`, `css`, `keyword`, or nil if unparseable.
local function build_colour_spec(token, token_format)
  if token_format == 'keyword' then
    return { keyword = token, css = token, original = token }
  end
  if token_format == 'rgba' then
    local hex, alpha = rgba_to_hex(token)
    if not hex then return nil end
    return { hex = hex, alpha = alpha, css = token, original = token }
  end
  if token_format == 'hsla' then
    local hex, alpha = hsla_to_hex(token)
    if not hex then return nil end
    return { hex = hex, alpha = alpha, css = token, original = token }
  end
  local hex = colour.to_html(token, token_format)
  if not hex then return nil end
  return { hex = hex, css = hex, original = token }
end

--- Extract all colour matches from element text with positions.
--- Supports multiple colours and colours embedded within other text.
--- @param element table Pandoc element containing text to analyse.
--- @return table Array of match objects sorted by start position.
---         Each match: { spec = {...}, original = "...", start_pos = n, end_pos = m, format = "hex6" }
local function get_all_colours(element)
  local matches = {}
  local text = element.text

  -- Pattern definitions with priority (specific functions before bare hex/named).
  -- `rgba`/`hsla` come before `rgb`/`hsl` so the alpha form wins.
  local patterns = {
    { name = 'hex6',        pattern = '#[0-9a-fA-F][0-9a-fA-F][0-9a-fA-F][0-9a-fA-F][0-9a-fA-F][0-9a-fA-F]' },
    { name = 'rgba',        pattern = 'rgba%s*%(%s*%d+%s*,%s*%d+%s*,%s*%d+%s*,%s*[%d%.%%]+%s*%)' },
    { name = 'hsla',        pattern = 'hsla%s*%(%s*%d+%s*,%s*%d+%s*%%%s*,%s*%d+%s*%%%s*,%s*[%d%.%%]+%s*%)' },
    { name = 'rgb',         pattern = 'rgb%s*%(%s*%d+%s*,%s*%d+%s*,%s*%d+%s*%)' },
    { name = 'rgb_percent', pattern = 'rgb%s*%(%s*%d+%s*%%%s*,%s*%d+%s*%%%s*,%s*%d+%s*%%%s*%)' },
    { name = 'hsl',         pattern = 'hsl%s*%(%s*%d+%s*,%s*%d+%s*%%%s*,%s*%d+%s*%%%s*%)' },
    { name = 'hwb',         pattern = 'hwb%s*%(%s*%d+%s+%d+%%%s+%d+%%%s*%)' },
    { name = 'hex3',        pattern = '#[0-9a-fA-F][0-9a-fA-F][0-9a-fA-F]' }, -- Before named to avoid false positives.
    { name = 'keyword',     pattern = '[a-zA-Z]+',                            validate = function(t) return keyword_colours[t:lower()] ~= nil end },
    { name = 'named',       pattern = '[a-zA-Z]+',                            validate = colour.is_named_colour } -- Last: requires validation.
  }

  -- Track covered positions to prevent overlaps.
  local covered = {}

  --- Check if a position range overlaps with any covered range.
  --- @param start_pos number Start position to check.
  --- @param end_pos number End position to check.
  --- @return boolean True if position overlaps with a covered range.
  local function is_position_covered(start_pos, end_pos)
    for _, range in ipairs(covered) do
      if (start_pos >= range[1] and start_pos <= range[2]) or
          (end_pos >= range[1] and end_pos <= range[2]) or
          (start_pos <= range[1] and end_pos >= range[2]) then
        return true
      end
    end
    return false
  end

  for _, pat in ipairs(patterns) do
    local pos = 1
    while pos <= #text do
      local start_pos, end_pos = string.find(text, pat.pattern, pos)
      if not start_pos then break end

      -- Check if position is already covered by a previous match.
      if not is_position_covered(start_pos, end_pos) then
        local matched_text = string.sub(text, start_pos, end_pos)

        -- If pattern has a validation function, use it to verify the match.
        local is_valid = true
        if pat.validate then
          is_valid = pat.validate(matched_text)
        end

        if is_valid then
          local spec = build_colour_spec(matched_text, pat.name)
          if spec then
            table.insert(matches, {
              spec = spec,
              hex = spec.hex,
              original = matched_text,
              start_pos = start_pos,
              end_pos = end_pos,
              format = pat.name
            })
            table.insert(covered, { start_pos, end_pos })
          end
        end
      end

      pos = end_pos + 1
    end
  end

  -- Sort by start position for sequential processing.
  table.sort(matches, function(a, b) return a.start_pos < b.start_pos end)

  return matches
end

--- Reconstruct a Code element with colour marks inserted after each colour.
--- Keeps the code as a single visual unit with marks embedded inside.
--- @param element table Pandoc Code element.
--- @param matches table Array of colour matches with positions.
--- @param format string Output format (html, latex, typst, docx, pptx).
--- @param language string Language for RawInline.
--- @param glyph string Glyph character to use for the preview.
--- @return table Pandoc RawInline with code and embedded colour marks.
local function reconstruct_code_with_marks(element, matches, format, language, glyph)
  if #matches == 0 then
    return element
  end

  local text = element.text
  local result_text = ""
  local last_pos = 1

  -- Build the content with embedded colour marks.
  for _, match in ipairs(matches) do
    -- Add text before this colour.
    if match.start_pos > last_pos then
      local prefix = string.sub(text, last_pos, match.start_pos - 1)
      if format == "html" then
        prefix = str.escape_html(prefix)
      elseif format == "latex" then
        prefix = str.escape_text(prefix, format)
      elseif format == "typst" then
        prefix = str.escape_text(prefix, format)
      end
      result_text = result_text .. prefix
    end

    -- Add the colour code.
    local colour_text = match.original
    if format == "html" then
      colour_text = str.escape_html(colour_text)
    elseif format == "latex" then
      colour_text = str.escape_text(colour_text, format)
    elseif format == "typst" then
      colour_text = str.escape_text(colour_text, format)
    end
    result_text = result_text .. colour_text

    -- Add the colour mark (may be nil for keyword/alpha colours outside HTML).
    local mark = create_colour_mark(match.spec, format, glyph)
    if mark then
      result_text = result_text .. mark
    end

    last_pos = match.end_pos + 1
  end

  -- Add remaining text after last colour.
  if last_pos <= #text then
    local suffix = string.sub(text, last_pos)
    if format == "html" then
      suffix = str.escape_html(suffix)
    elseif format == "latex" then
      suffix = str.escape_text(suffix, format)
    elseif format == "typst" then
      suffix = str.escape_text(suffix, format)
    end
    result_text = result_text .. suffix
  end

  -- Wrap in format-specific code markup.
  if format == "html" then
    return pandoc.RawInline(language, '<code>' .. result_text .. '</code>')
  elseif format == "latex" then
    return pandoc.RawInline(language, '\\texttt{' .. result_text .. '}')
  end

  -- For Typst and OpenXML, keep the split approach as they have limitations
  -- with embedding marks inside code content.
  local result = {}
  last_pos = 1
  for _, match in ipairs(matches) do
    if match.start_pos > last_pos then
      local prefix = string.sub(text, last_pos, match.start_pos - 1)
      if #prefix > 0 then
        table.insert(result, pandoc.Code(prefix, element.attr))
      end
    end
    table.insert(result, pandoc.Code(match.original, element.attr))
    local colour_mark = create_colour_mark(match.spec, format, glyph)
    if colour_mark then
      table.insert(result, pandoc.RawInline(language, colour_mark))
    end
    last_pos = match.end_pos + 1
  end
  if last_pos <= #text then
    local suffix = string.sub(text, last_pos)
    if #suffix > 0 then
      table.insert(result, pandoc.Code(suffix, element.attr))
    end
  end
  return pandoc.Span(result)
end

--- Reconstruct a Str element with colour marks inserted after each colour.
--- @param element table Pandoc Str element.
--- @param matches table Array of colour matches with positions.
--- @param format string Output format (html, latex, typst, docx, pptx).
--- @param language string Language for RawInline.
--- @param glyph string Glyph character to use for the preview.
--- @return table Pandoc Span or RawInline depending on format.
local function reconstruct_str_with_marks(element, matches, format, language, glyph)
  if #matches == 0 then
    return element
  end

  local text = element.text

  -- For OpenXML formats, use Span with separate elements
  if language == "openxml" then
    local result = {}
    local last_pos = 1

    for _, match in ipairs(matches) do
      if match.start_pos > last_pos then
        local prefix = string.sub(text, last_pos, match.start_pos - 1)
        if #prefix > 0 then
          table.insert(result, pandoc.Str(prefix))
        end
      end

      table.insert(result, pandoc.Str(match.original))
      local colour_mark = create_colour_mark(match.spec, format, glyph)
      if colour_mark then
        table.insert(result, pandoc.RawInline(language, colour_mark))
      end

      last_pos = match.end_pos + 1
    end

    if last_pos <= #text then
      local suffix = string.sub(text, last_pos)
      if #suffix > 0 then
        table.insert(result, pandoc.Str(suffix))
      end
    end

    return pandoc.Span(result)
  end

  -- For LaTeX/Typst/HTML, build a single raw inline with escaping.
  local result_text = ""
  local last_pos = 1

  for _, match in ipairs(matches) do
    if match.start_pos > last_pos then
      local prefix = string.sub(text, last_pos, match.start_pos - 1)
      if format == "latex" or format == "typst" then
        prefix = str.escape_text(prefix, format)
      end
      result_text = result_text .. prefix
    end

    local colour_text = match.original
    if format == "latex" or format == "typst" then
      colour_text = str.escape_text(colour_text, format)
    end
    result_text = result_text .. colour_text
    local mark = create_colour_mark(match.spec, format, glyph)
    if mark then
      result_text = result_text .. mark
    end

    last_pos = match.end_pos + 1
  end

  if last_pos <= #text then
    local suffix = string.sub(text, last_pos)
    if format == "latex" or format == "typst" then
      suffix = str.escape_text(suffix, format)
    end
    result_text = result_text .. suffix
  end

  return pandoc.RawInline(language, result_text)
end

--- Add colour preview marks to a Pandoc element.
--- Handles multiple colours and colours embedded within other text.
--- Supports multiple output formats (HTML, LaTeX, Typst, DOCX, PPTX).
--- @param element table Pandoc Str or Code element to process.
--- @return table Pandoc element with colour previews, or original element if no colours found.
local function add_colour_mark(element)
  local matches = get_all_colours(element)

  if #matches == 0 then
    return element -- No colours found, return original element.
  end

  local format, language = pdoc.get_quarto_format()
  if format == "unknown" then
    log.log_warning(
      EXTENSION_NAME,
      'Unsupported output format for colour preview: "' .. language .. '". ' ..
      'No colour preview will be generated.'
    )
    return element -- Unsupported format, return original element.
  end

  local glyph = get_glyph_for_format(format)
  local source = element.t == "Code" and "code" or "text"
  for _, match in ipairs(matches) do
    record_detected(match.spec, source)
  end

  if element.t == "Code" then
    return reconstruct_code_with_marks(element, matches, format, language, glyph)
  elseif element.t == "Str" then
    return reconstruct_str_with_marks(element, matches, format, language, glyph)
  end

  return element
end

--- Extract and configure colour preview settings from document metadata.
--- @param meta table<string, any> Document metadata table.
--- @return table<string, any> Updated metadata table with preview-colour configuration.
local function get_colour_preview_meta(meta)
  checker:options(meta)

  local preview_colour_text = get_preview_colour_option('text', meta)
  local preview_colour_code = get_preview_colour_option('code', meta)

  -- Get glyph configuration (can be string or table)
  -- Use get_extension_config (not get_metadata_value) to preserve the raw
  -- metadata object without stringifying table values.
  local glyph_config = nil
  local ext_config = meta_mod.get_extension_config(meta, EXTENSION_NAME)
  if ext_config and ext_config['glyph'] then
    glyph_config = ext_config['glyph']
  end
  if glyph_config == nil then
    -- Check deprecated top-level config
    if meta['preview-colour'] and meta['preview-colour']['glyph'] then
      glyph_config = meta['preview-colour']['glyph']
      if not deprecation_warning_shown then
        log.log_warning(
          EXTENSION_NAME,
          'Top-level "preview-colour" configuration is deprecated. ' ..
          'Please use:\n' ..
          'extensions:\n' ..
          '  preview-colour:\n' ..
          '    glyph: value'
        )
        deprecation_warning_shown = true
      end
    end
  end

  -- Optional bulk JSON export of detected colours.
  --
  -- Whether to export and where to export are two questions, so they are two
  -- options. They were one declaration of `type: [boolean, string]` once, which
  -- made `json: no` write a file called `no`: a string is a declared type, so
  -- the validator returned it untouched and this code read it as a file name.
  -- The comment here claimed anything falsy disabled the export, and the branch
  -- below it did the opposite.
  if checker:option('json') == true then
    local path = checker:option('json-file')
    json_export_file = (type(path) == 'string' and path ~= '') and path or 'preview-colour.json'
  end

  -- A document configured only through the deprecated top-level block has no
  -- `extensions` key at all, so the table has to exist before writing into it.
  if meta['extensions'] == nil then
    meta['extensions'] = {}
  end

  meta['extensions']['preview-colour'] = {
    ["text"] = preview_colour_text,
    ["code"] = preview_colour_code,
    ["glyph"] = glyph_config,
    ["json"] = json_export_file
  }
  preview_colour_meta = meta['extensions']['preview-colour']
  return meta
end


--- Process string elements to add colour previews in text.
--- @param element table Pandoc Str element.
--- @return table|nil Modified pandoc element with colour preview, or original element.
local function process_str(element)
  if preview_colour_meta['text'] == false then
    return element
  end

  return add_colour_mark(element)
end

--- Process code elements to add colour previews.
--- @param element table Pandoc Code element.
--- @return table|nil Modified pandoc element with colour preview, or original element.
local function process_code(element)
  if preview_colour_meta['code'] == false then
    return element
  end

  return add_colour_mark(element)
end

--- Patterns that start multi-token colours (function-style colours with parentheses).
--- @type table<string, string>
local multi_token_starters = {
  ["rgb("] = "rgb",
  ["rgba("] = "rgba",
  ["hsl("] = "hsl",
  ["hsla("] = "hsla",
  ["hwb("] = "hwb"
}

--- Check if a Str element starts a multi-token colour.
--- @param str_text string The text content of a Str element.
--- @return string|nil The colour function name if it starts a multi-token colour.
local function get_multitoken_starter(str_text)
  for starter, func_name in pairs(multi_token_starters) do
    if string.find(str_text, starter, 1, true) then
      return func_name
    end
  end
  return nil
end

--- Try to parse a complete colour from joined text.
--- @param text string The joined text to parse.
--- @return table|nil, string|nil The colour spec table and pattern name, or nil if not a valid colour.
local function try_parse_colour(text)
  -- Try each pattern that could match the joined text.
  -- Alpha-bearing forms come first so they win over their opaque counterparts.
  local patterns = {
    { name = 'rgba',        pattern = '^rgba%s*%(%s*%d+%s*,%s*%d+%s*,%s*%d+%s*,%s*[%d%.%%]+%s*%)$' },
    { name = 'hsla',        pattern = '^hsla%s*%(%s*%d+%s*,%s*%d+%s*%%%s*,%s*%d+%s*%%%s*,%s*[%d%.%%]+%s*%)$' },
    { name = 'rgb',         pattern = '^rgb%s*%(%s*%d+%s*,%s*%d+%s*,%s*%d+%s*%)$' },
    { name = 'rgb_percent', pattern = '^rgb%s*%(%s*%d+%s*%%%s*,%s*%d+%s*%%%s*,%s*%d+%s*%%%s*%)$' },
    { name = 'hsl',         pattern = '^hsl%s*%(%s*%d+%s*,%s*%d+%s*%%%s*,%s*%d+%s*%%%s*%)$' },
    { name = 'hwb',         pattern = '^hwb%s*%(%s*%d+%s+%d+%%%s+%d+%%%s*%)$' }
  }

  for _, pat in ipairs(patterns) do
    if string.match(text, pat.pattern) then
      local spec = build_colour_spec(text, pat.name)
      if spec then
        return spec, pat.name
      end
    end
  end

  return nil, nil
end

--- Process Inlines to detect and merge multi-token colours.
--- Handles colours like rgb(10, 100, 200) that are split across multiple Str/Space elements.
--- @param inlines table Pandoc Inlines list.
--- @return table Modified Inlines list with multi-token colours processed.
local function process_inlines(inlines)
  if preview_colour_meta['text'] == false then
    return inlines
  end

  local format, language = pdoc.get_quarto_format()
  if format == "unknown" then
    return inlines
  end

  local glyph = get_glyph_for_format(format)
  local result = pandoc.List()
  local i = 1

  while i <= #inlines do
    local elem = inlines[i]

    -- Check if this is a Str that could start a multi-token colour.
    if elem.t == "Str" then
      local starter = get_multitoken_starter(elem.text)

      if starter then
        -- Collect tokens until we find a closing parenthesis.
        local collected = { elem.text }
        local j = i + 1
        local close_in = string.find(elem.text, ")", 1, true) ~= nil and 1 or nil

        while j <= #inlines and not close_in do
          local next_elem = inlines[j]

          if next_elem.t == "Str" then
            table.insert(collected, next_elem.text)
            if string.find(next_elem.text, ")", 1, true) then
              close_in = #collected
            end
          elseif next_elem.t == "Space" then
            table.insert(collected, " ")
          else
            -- Non-Str/Space element breaks the sequence.
            break
          end

          j = j + 1
        end

        if close_in then
          -- The last collected token may carry text after the `)` (punctuation,
          -- following words, ...). Split it so the colour candidate ends at `)`
          -- and the trailer is reinserted into the output stream.
          local last_index = close_in
          local last_text = collected[last_index]
          local paren_pos = string.find(last_text, ")", 1, true)
          local trailing_text = string.sub(last_text, paren_pos + 1)
          collected[last_index] = string.sub(last_text, 1, paren_pos)

          local joined = table.concat(collected)
          local spec, _ = try_parse_colour(joined)

          if spec then
            spec.original = joined
            record_detected(spec, "text-multitoken")
            local colour_mark = create_colour_mark(spec, format, glyph)

            if colour_mark == nil then
              -- No preview possible for this format/spec; keep the original element.
              result:insert(elem)
              i = i + 1
            else
              -- Compute the next index based on which token contained `)`.
              local consumed_to = i + (last_index - 1)
              if language == "openxml" then
                result:insert(pandoc.Str(joined))
                result:insert(pandoc.RawInline(language, colour_mark))
              else
                local text_escaped = joined
                if format == "latex" or format == "typst" then
                  text_escaped = str.escape_text(joined, format)
                end
                result:insert(pandoc.RawInline(language, text_escaped .. colour_mark))
              end
              if trailing_text ~= "" then
                result:insert(pandoc.Str(trailing_text))
              end
              i = consumed_to + 1
            end
          else
            -- Not a valid colour, keep original element.
            result:insert(elem)
            i = i + 1
          end
        else
          -- No closing paren found, keep original element.
          result:insert(elem)
          i = i + 1
        end
      else
        -- Not a starter, keep original element.
        result:insert(elem)
        i = i + 1
      end
    else
      -- Not a Str element, keep as-is.
      result:insert(elem)
      i = i + 1
    end
  end

  return result
end

--- Write the collected colour list to JSON when bulk export is enabled.
--- @param doc table Pandoc document (returned unchanged).
--- @return table The unchanged Pandoc document.
local function export_detected_colours(doc)
  if json_export_file == nil or #detected_colours == 0 then
    return doc
  end

  local payload = {
    extension = EXTENSION_NAME,
    count = #detected_colours,
    colours = detected_colours
  }

  local ok, encoded = pcall(quarto.json.encode, payload)
  if not ok then
    log.log_error(EXTENSION_NAME, 'Failed to encode JSON payload: ' .. tostring(encoded))
    return doc
  end

  local file, err = io.open(json_export_file, 'w')
  if not file then
    log.log_error(EXTENSION_NAME, 'Failed to write JSON export to "' .. json_export_file .. '": ' .. (err or 'unknown error'))
    return doc
  end
  file:write(encoded)
  file:close()
  log.log_output(EXTENSION_NAME, 'Exported ' .. #detected_colours .. ' colour(s) to: ' .. json_export_file)
  return doc
end

--- Pandoc filter configuration.
--- Defines the processing pipeline for different pandoc elements.
--- @return table Filter table for Pandoc.
return {
  { Meta = get_colour_preview_meta },
  { Inlines = process_inlines }, -- Process multi-token colours first.
  { Str = process_str },
  { Code = process_code },
  { Pandoc = export_detected_colours } -- Final pass: write JSON export when configured.
}
