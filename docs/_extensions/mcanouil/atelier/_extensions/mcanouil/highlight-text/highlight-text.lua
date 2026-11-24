--- @module "highlight-text"
--- @license MIT
--- @copyright 2026 Mickaël Canouil
--- @author Mickaël Canouil

--- Extension name constant
local EXTENSION_NAME = "highlight-text"

--- Load modules
local log = require(quarto.utils.resolve_path('_vendor/quarto-lua-modules/logging.lua'):gsub('%.lua$', ''))
local colour_utils = require(quarto.utils.resolve_path('_vendor/quarto-lua-modules/colour.lua'):gsub('%.lua$', ''))
local schema = require(quarto.utils.resolve_path('_vendor/quarto-wizard/schema.lua'):gsub('%.lua$', ''))
local check = require(quarto.utils.resolve_path('_vendor/quarto-lua-modules/schema-check.lua'):gsub('%.lua$', ''))

--- Every attribute the filter reads, with the spellings it accepts.
---
--- The spellings are listed in order of precedence: when an element carries
--- more than one of them, the first one present wins. The order is the one the
--- schema check uses, the name first and then the aliases as `_schema.yml`
--- lists them, so its warning names the value the filter applies. The check
--- also accepts the underscore form of a hyphenated spelling, read just after
--- it, so the filter lists those forms in the same place.
--- @type table<integer, {name: string, spellings: string[]}>
local ATTRIBUTE_SPELLINGS = {
  { name = 'colour', spellings = { 'colour', 'color', 'ink', 'fg' } },
  { name = 'bg-colour', spellings = { 'bg-colour', 'bg_colour', 'bg-color', 'bg_color', 'bg', 'paper' } },
  { name = 'border-colour', spellings = { 'border-colour', 'border_colour', 'border-color', 'border_color', 'bc' } },
  { name = 'border-style', spellings = { 'border-style', 'border_style', 'bs' } },
  { name = 'par', spellings = { 'par' } },
  { name = 'opacity', spellings = { 'opacity' } },
  { name = 'gradient', spellings = { 'gradient' } },
}

--- The schema check, built once and reused by every element.
---
--- The validator is injected rather than required by the check module, so the
--- two vendored sources stay independent of where the other was placed.
---
--- The `styles` option is checked once from the `Meta` pass, and the
--- `attributes` section per element. The schema's attribute group is `_any`,
--- which every element takes, so no group is named here.
---
--- A schema that cannot be read is reported by the module as an error and the
--- render carries on: a configuration file must not stop a document.
local checker = check.new(schema, EXTENSION_NAME)

--- Flag to track if deprecation warning has been shown
--- @type boolean
local deprecation_warning_shown = false

--- Flag to track if the PowerPoint border-discard warning has been shown
--- @type boolean
local pptx_border_warning_shown = false

--- Named styles from `extensions.highlight-text.styles`, keyed by class name.
--- Each style maps canonical attribute names to string values.
--- @type table<string, table<string, string>>
local styles = {}

--- Check whether a string looks like a CSS custom property reference (e.g. "var(--brand-primary)").
--- @param value string|nil The value to inspect
--- @return boolean True when the value starts with "var(" after trimming whitespace
local function is_css_var(value)
  if type(value) ~= 'string' then return false end
  return value:match('^%s*var%s*%(') ~= nil
end

--- Resolve a colour reference to a concrete colour value.
--- Convert a colour reference to a 6-character hex (without leading "#").
--- Brand-resolved values are already concrete; this normalises hex (3 or 6 digits) and named colours.
--- Returns nil for values that cannot be expressed as a hex code (rgb(), hsl(), CSS var(), Typst rgb()).
--- @param colour string|nil The colour value
--- @return string|nil A 6-character hex string without "#", or nil when not expressible as hex
local function to_hex6(colour)
  if colour == nil then return nil end
  if colour_utils.is_named_colour(colour) then
    return colour_utils.named_to_HTML(colour):gsub('^#', '')
  end
  if colour:match('^#%x%x%x%x%x%x$') then
    return colour:sub(2)
  end
  if colour:match('^#%x%x%x$') then
    return colour_utils.expand_hex_colour(colour):gsub('^#', '')
  end
  return nil
end

--- Brand colour names are resolved via the Quarto brand API.
--- CSS `var()` references are preserved for HTML output.
--- Hex/CSS colour values are validated.
--- Invalid values trigger a warning and return nil so callers can skip the styling.
--- @param theme string The brand theme to use (light/dark)
--- @param colour string|nil The colour value or brand colour reference
--- @param attribute string Human-readable attribute label used in warnings
--- @return string|nil The processed colour value or nil when invalid
local function get_brand_colour(theme, colour, attribute)
  local brand = require('modules/brand/brand')

  if colour == nil then
    return nil
  end

  if is_css_var(colour) then
    if FORMAT == 'html' or FORMAT:match('revealjs') then
      return colour
    end
    log.log_warning(
      EXTENSION_NAME,
      'Ignoring CSS `var()` ' .. attribute .. ' "' .. colour .. '" for format "' .. FORMAT .. '": only supported in HTML/RevealJS output.'
    )
    return nil
  end

  local brand_colour_key = colour:gsub('^brand%-color%.', '')
  if colour:match('^brand%-color%.') and not deprecation_warning_shown then
    log.log_warning(
      EXTENSION_NAME,
      'Using "brand-color." prefix is deprecated.' ..
      ' Please use the colour name directly (e.g., "' .. brand_colour_key .. '" instead of "' .. colour .. '").'
    )
    deprecation_warning_shown = true
  end

  local brand_colour = brand.get_color(theme, brand_colour_key)
  if brand_colour ~= nil then
    return brand_colour
  end

  -- Typst's `rgb()` takes a hex string, so a value has to be expressible as one
  -- before it can be wrapped. Anything else is skipped with a warning, as it is
  -- in every other format, rather than reaching the Typst compiler and failing
  -- the whole render.
  if FORMAT:match('typst') then
    local hex = to_hex6(colour)
    if hex ~= nil then
      return 'rgb("#' .. hex .. '")'
    end
    log.log_warning(
      EXTENSION_NAME,
      'Ignoring ' .. attribute .. ' value "' .. colour .. '" for Typst output: ' ..
      'not convertible to a hex code.'
    )
    return nil
  end

  if colour:match('^#') or colour:match('^rgb') or colour:match('^hsl') or colour:match('^hwb')
      or colour_utils.is_named_colour(colour) then
    return colour
  end

  log.log_warning(
    EXTENSION_NAME,
    'Ignoring invalid ' .. attribute .. ' value "' .. colour .. '": ' ..
    'expected a hex (#RGB/#RRGGBB), CSS function (rgb/hsl/hwb), named colour, ' ..
    'CSS var(), or brand colour name.'
  )
  return nil
end

--- Convert foreground, background, and border colours to 6-character hex for a binary writer
--- (LaTeX, Word, PowerPoint). Emits a warning for each value that cannot be expressed as hex.
--- @param colour string|nil The foreground colour value
--- @param bg_colour string|nil The background colour value
--- @param border_colour string|nil The border colour value
--- @param format_label string Human-readable format label used in warnings (e.g. "LaTeX")
--- @return string|nil, string|nil, string|nil colour_hex, bg_hex, border_hex
local function resolve_hex_triplet(colour, bg_colour, border_colour, format_label)
  local pairs_list = {
    { name = 'foreground colour', value = colour },
    { name = 'background colour', value = bg_colour },
    { name = 'border colour',     value = border_colour },
  }
  local results = {}
  for i, entry in ipairs(pairs_list) do
    local hex = to_hex6(entry.value)
    if entry.value ~= nil and hex == nil then
      log.log_warning(
        EXTENSION_NAME,
        'Ignoring ' .. entry.name .. ' "' .. entry.value .. '" for ' .. format_label ..
        ' output: not convertible to hex.'
      )
    end
    results[i] = hex
  end
  return results[1], results[2], results[3]
end

--- Apply opacity to a CSS-style colour value when the colour is a hex code.
--- Returns the original value unchanged when conversion is not possible (e.g. `var()`, rgb()).
--- For hex inputs, returns an `rgba()` string.
--- @param colour string|nil The colour value
--- @param opacity number A value in [0, 1]
--- @return string|nil The colour with opacity applied where possible, or the original value
local function apply_opacity_css(colour, opacity)
  if colour == nil then return nil end
  local hex = to_hex6(colour)
  if hex == nil then
    return colour
  end
  local r = tonumber(hex:sub(1, 2), 16)
  local g = tonumber(hex:sub(3, 4), 16)
  local b = tonumber(hex:sub(5, 6), 16)
  return string.format('rgba(%d, %d, %d, %s)', r, g, b, tostring(opacity))
end

--- Apply an opacity to a Typst colour expression via `.transparentize()`.
--- An opacity of `o` maps to `transparentize((1 - o) * 100%)` so that `o = 0.5`
--- yields `transparentize(50%)`.
--- @param colour string A Typst colour expression (e.g. `rgb("#...")`)
--- @param opacity number A value in [0, 1]
--- @return string The colour expression with `.transparentize(P%)` appended
local function apply_opacity_typst(colour, opacity)
  local pct = (1 - opacity) * 100
  return colour .. '.transparentize(' .. string.format('%g', pct) .. '%)'
end

--- Parse and validate an opacity attribute value.
--- Accepts a number in [0, 1] or a percentage string (e.g. "50%").
--- Out-of-range or malformed values emit a warning and return nil.
--- @param value string|number|nil The raw attribute value
--- @return number|nil A number in [0, 1], or nil when the value is absent or invalid
local function parse_opacity(value)
  if value == nil then return nil end
  local str = pandoc.utils.stringify(value)
  if str == '' then return nil end
  local percent = str:match('^%s*([%-%d%.]+)%s*%%%s*$')
  local number = percent and tonumber(percent) / 100 or tonumber(str)
  if number == nil then
    log.log_warning(
      EXTENSION_NAME,
      'Ignoring invalid opacity value "' .. str .. '": expected a number in [0, 1] or a percentage.'
    )
    return nil
  end
  if number < 0 or number > 1 then
    log.log_warning(
      EXTENSION_NAME,
      'Ignoring out-of-range opacity value "' .. str .. '": must be in [0, 1].'
    )
    return nil
  end
  return number
end

--- Build a CSS gradient value from a `gradient` attribute string.
--- Accepts either a full `linear-gradient(...)`/`radial-gradient(...)` value (passed through),
--- or a comma-separated list of colour stops (e.g. `"#ff0000, #0000ff"`) which becomes
--- `linear-gradient(to right, #ff0000, #0000ff)`.
--- @param value string|nil The raw attribute value
--- @return string|nil A CSS gradient value or nil
local function parse_gradient(value)
  if value == nil then return nil end
  local str = pandoc.utils.stringify(value)
  if str == '' then return nil end
  if str:match('^%s*linear%-gradient%s*%(') or str:match('^%s*radial%-gradient%s*%(') then
    return str
  end
  return 'linear-gradient(to right, ' .. str .. ')'
end

--- Split a string on top-level commas, ignoring commas nested in parentheses.
--- Keeps commas inside `rgb(0, 0, 0)`/`hsl(...)` from splitting colour stops.
--- @param str string The string to split
--- @return table A list of trimmed, non-empty segments
local function split_top_level_commas(str)
  local parts = {}
  local depth = 0
  local current = ''
  for i = 1, #str do
    local ch = str:sub(i, i)
    if ch == '(' then
      depth = depth + 1
      current = current .. ch
    elseif ch == ')' then
      depth = depth - 1
      current = current .. ch
    elseif ch == ',' and depth == 0 then
      parts[#parts + 1] = current:match('^%s*(.-)%s*$')
      current = ''
    else
      current = current .. ch
    end
  end
  if current:match('%S') then
    parts[#parts + 1] = current:match('^%s*(.-)%s*$')
  end
  return parts
end

--- Parse a single CSS colour stop into a Typst-ready table.
--- Separates an optional trailing position (e.g. `0%`, `2em`) from the colour and
--- wraps the colour as `rgb("...")` (matching the Typst branch of `get_brand_colour`).
--- @param stop string A single colour stop (e.g. `#00b09b 0%`)
--- @return table A table `{ colour = 'rgb("...")', position = <string|nil> }`
local function parse_stop(stop)
  local colour, position = stop:match('^(.-)%s+([%-%d%.]+%%?[a-z]*)$')
  if colour == nil then
    colour = stop
  end
  return {
    colour = 'rgb("' .. colour:match('^%s*(.-)%s*$') .. '")',
    position = position
  }
end

--- Parse a `gradient` attribute into a structured representation for Typst rendering.
--- Accepts the same inputs as `parse_gradient` (full `linear-gradient(...)`/
--- `radial-gradient(...)` or a comma-separated colour-stop shorthand).
--- @param value string|nil The raw attribute value
--- @return table|nil A table
---   `{ kind = 'linear'|'radial', dir = <'ltr'|'rtl'|'ttb'|'btt'|nil>, angle = <number|nil>,
---      stops = { { colour = ..., position = ... }, ... } }`, or nil
local function parse_gradient_typst(value)
  if value == nil then return nil end
  local str = pandoc.utils.stringify(value)
  if str == '' then return nil end

  local kind, dir, angle = 'linear', nil, nil
  local inner

  local linear = str:match('^%s*linear%-gradient%s*%((.*)%)%s*$')
  local radial = str:match('^%s*radial%-gradient%s*%((.*)%)%s*$')

  if radial ~= nil then
    kind = 'radial'
    inner = radial
  elseif linear ~= nil then
    local segments = split_top_level_commas(linear)
    local first = segments[1] or ''
    local degrees = first:match('^([%-%d%.]+)deg$')
    if first:match('^to%s+') then
      local keyword = first:gsub('^to%s+', '')
      local directions = { right = 'ltr', left = 'rtl', bottom = 'ttb', top = 'btt' }
      dir = directions[keyword]
      table.remove(segments, 1)
    elseif degrees ~= nil then
      angle = (tonumber(degrees) - 90) % 360
      table.remove(segments, 1)
    end
    inner = table.concat(segments, ', ')
  else
    dir = 'ltr'
    inner = str
  end

  local stops = {}
  for _, segment in ipairs(split_top_level_commas(inner)) do
    stops[#stops + 1] = parse_stop(segment)
  end
  if #stops == 0 then return nil end

  return { kind = kind, dir = dir, angle = angle, stops = stops }
end

--- Render a structured gradient (from `parse_gradient_typst`) as Typst markup.
--- @param gradient table The structured gradient
--- @return string A Typst `gradient.linear(...)`/`gradient.radial(...)` expression
local function gradient_to_typst(gradient)
  local args = {}
  if gradient.kind == 'linear' then
    if gradient.angle ~= nil then
      args[#args + 1] = 'angle: ' .. string.format('%g', gradient.angle) .. 'deg'
    elseif gradient.dir ~= nil then
      args[#args + 1] = 'dir: ' .. gradient.dir
    end
  end
  for _, stop in ipairs(gradient.stops) do
    if stop.position ~= nil then
      args[#args + 1] = '(' .. stop.colour .. ', ' .. stop.position .. ')'
    else
      args[#args + 1] = stop.colour
    end
  end
  local fn = gradient.kind == 'radial' and 'gradient.radial' or 'gradient.linear'
  return fn .. '(' .. table.concat(args, ', ') .. ')'
end

--- Strip every input-alias attribute consumed by the filter so they do not leak to output.
--- @param attributes table The element attributes (mutated in place)
local function strip_alias_attributes(attributes)
  for _, attribute in ipairs(ATTRIBUTE_SPELLINGS) do
    for _, spelling in ipairs(attribute.spellings) do
      attributes[spelling] = nil
    end
  end
end

--- Applies HTML styling to an element.
--- Handles foreground, background, border, opacity, and (for blocks) gradient fills.
---
--- The identifier, classes and attributes of the element go on one element
--- only: the styled copy when there is one theme, or a wrapper around the
--- light and dark copies. A class such as `.fragment` then acts once, next to
--- its `data-fragment-index`, and the identifier stays unique. Each copy keeps
--- the `style` attribute, which it extends.
--- @param element table The element to style
--- @param settings table The highlight settings keyed by theme (light/dark)
--- @param is_block boolean Whether this is a block-level element
--- @param constructor any The Pandoc constructor (pandoc.Span or pandoc.Div)
--- @return table The styled element
local function apply_html_styling(element, settings, is_block, constructor)
  local result = {}
  local theme_keys = {}

  for key, _ in pairs(settings) do
    table.insert(theme_keys, key)
  end

  local padding = is_block and '0.5rem' or '0 0.2rem 0 0.2rem'

  for _, theme in ipairs(theme_keys) do
    local themed_element = constructor(element.content)
    local colour = settings[theme].colour
    local bg_colour = settings[theme].bg_colour
    local border_colour = settings[theme].border_colour
    local border_style = settings[theme].border_style
    local opacity = settings[theme].opacity
    local gradient = settings[theme].gradient

    themed_element.attributes['style'] = element.attributes['style']

    if themed_element.attributes['style'] == nil then
      themed_element.attributes['style'] = ''
    elseif themed_element.attributes['style']:sub(-1) ~= ';' then
      themed_element.attributes['style'] = themed_element.attributes['style'] .. ';'
    end

    themed_element.classes = { theme .. '-content' }

    if colour ~= nil then
      themed_element.attributes['style'] = themed_element.attributes['style'] .. 'color: ' .. colour .. ';'
    end

    if is_block and gradient ~= nil then
      themed_element.attributes['style'] = themed_element.attributes['style'] ..
          'border-radius: 0.2rem; padding: ' .. padding .. ';' ..
          'background-image: ' .. gradient .. ';'
    elseif bg_colour ~= nil then
      local bg_value = opacity ~= nil and apply_opacity_css(bg_colour, opacity) or bg_colour
      themed_element.attributes['style'] = themed_element.attributes['style'] ..
          'border-radius: 0.2rem; padding: ' .. padding .. ';' ..
          'background-color: ' .. bg_value .. ';'
    end

    if border_colour ~= nil then
      local style = border_style or 'solid'
      themed_element.attributes['style'] = themed_element.attributes['style'] ..
          'border: 1px ' .. style .. ' ' .. border_colour .. ';'
    end

    if opacity ~= nil and bg_colour == nil and gradient == nil then
      themed_element.attributes['style'] = themed_element.attributes['style'] ..
          'opacity: ' .. tostring(opacity) .. ';'
    end

    table.insert(result, themed_element)
  end

  local carried = {}
  for key, value in pairs(element.attributes) do
    if key ~= 'style' then
      carried[key] = value
    end
  end

  if #result == 1 then
    local styled = result[1]
    styled.identifier = element.identifier
    styled.classes = element.classes .. styled.classes
    for key, value in pairs(carried) do
      styled.attributes[key] = value
    end
    return styled
  end
  return constructor(result, pandoc.Attr(element.identifier, element.classes, carried))
end

--- Applies text and background colour styling for HTML-based outputs.
--- @param span table The span element to modify
--- @param settings table The highlight settings containing colour and background colour
--- @return table The modified span with HTML styling
local function highlight_html(span, settings)
  return apply_html_styling(span, settings, false, pandoc.Span)
end

--- Applies text and background colour styling for HTML-based outputs (block level).
--- @param div table The div element to modify
--- @param settings table The highlight settings containing colour and background colour
--- @return table The modified div with HTML styling
local function highlight_html_block(div, settings)
  return apply_html_styling(div, settings, true, pandoc.Div)
end

--- Applies text and background colour styling for LaTeX-based outputs.
--- Invalid colours are reported and the corresponding effect is skipped rather than crashing.
--- @param span table The span element to modify
--- @param colour string|nil The text colour to apply
--- @param bg_colour string|nil The background colour to apply
--- @param border_colour string|nil The border colour to apply
--- @param border_style string|nil The border style to apply
--- @param par boolean Whether to wrap in a paragraph box
--- @return table The span content with LaTeX markup
local function highlight_latex(span, colour, bg_colour, border_colour, border_style, par)
  local is_lualatex = quarto.doc.pdf_engine() == 'lualatex'

  local colour_hex, bg_hex, border_hex = resolve_hex_triplet(colour, bg_colour, border_colour, 'LaTeX')

  if is_lualatex and bg_hex ~= nil then
    quarto.doc.use_latex_package('luacolor, lua-ul')
  end

  if border_hex ~= nil then
    quarto.doc.use_latex_package('tikz')
  end

  local colour_open, colour_close = '', ''
  if colour_hex ~= nil then
    colour_open = '\\textcolor[HTML]{' .. colour_hex .. '}{'
    colour_close = '}'
  end

  local bg_colour_open, bg_colour_close = '', ''
  if bg_hex ~= nil then
    if is_lualatex then
      bg_colour_open = '\\highLight[{[HTML]{' .. bg_hex .. '}}]{'
      bg_colour_close = '}'
    else
      bg_colour_open = '\\colorbox[HTML]{' .. bg_hex .. '}{'
      bg_colour_close = '}'
    end
  end

  if par and not is_lualatex then
    bg_colour_open = bg_colour_open .. '\\parbox{\\linewidth}{'
    bg_colour_close = '}' .. bg_colour_close
  end

  local border_open, border_close = '', ''
  if border_hex ~= nil then
    local tikz_style = ''
    if border_style == 'dashed' then
      tikz_style = ', dashed'
    elseif border_style == 'dotted' then
      tikz_style = ', dotted'
    elseif border_style == 'double' then
      tikz_style = ', double'
    end

    border_open = '\\tikz[baseline=(text.base)]{\\node[draw={rgb,255:red,' ..
        tonumber(border_hex:sub(1, 2), 16) .. ';green,' ..
        tonumber(border_hex:sub(3, 4), 16) .. ';blue,' ..
        tonumber(border_hex:sub(5, 6), 16) .. '}' .. tikz_style .. ', inner sep=0.1em] (text) {\\strut '
    border_close = '};}'
  end

  table.insert(
    span.content, 1,
    pandoc.RawInline('latex', border_open .. colour_open .. bg_colour_open)
  )
  table.insert(span.content, pandoc.RawInline('latex', bg_colour_close .. colour_close .. border_close))

  return span.content
end

--- Applies text and background colour styling for LaTeX-based outputs (block level).
--- Invalid colours are reported and the corresponding effect is skipped.
--- @param div table The div element to modify
--- @param colour string|nil The text colour to apply
--- @param bg_colour string|nil The background colour to apply
--- @param border_colour string|nil The border colour to apply
--- @param border_style string|nil The border style to apply
--- @return table A modified div with LaTeX environment wrapping
local function highlight_latex_block(div, colour, bg_colour, border_colour, border_style)
  local is_lualatex = quarto.doc.pdf_engine() == 'lualatex'

  local colour_hex, bg_hex, border_hex = resolve_hex_triplet(colour, bg_colour, border_colour, 'LaTeX')

  if bg_hex ~= nil then
    if is_lualatex then
      quarto.doc.use_latex_package('luacolor, lua-ul')
    else
      quarto.doc.use_latex_package('xcolor')
    end
  end

  if border_hex ~= nil then
    quarto.doc.use_latex_package('tikz')
  end

  local latex_begin = ''
  local latex_end = ''

  if border_hex ~= nil then
    local tikz_style = ''
    if border_style == 'dashed' then
      tikz_style = ', dashed'
    elseif border_style == 'dotted' then
      tikz_style = ', dotted'
    elseif border_style == 'double' then
      tikz_style = ', double'
    end

    latex_begin = '\\begin{tikzpicture}\\node[draw={rgb,255:red,' ..
        tonumber(border_hex:sub(1, 2), 16) .. ';green,' ..
        tonumber(border_hex:sub(3, 4), 16) .. ';blue,' ..
        tonumber(border_hex:sub(5, 6), 16) ..
        '}' .. tikz_style .. ', inner sep=0.5em, text width=\\dimexpr\\linewidth-1em\\relax]{'
    latex_end = '};\\end{tikzpicture}'

    if colour_hex ~= nil and bg_hex ~= nil then
      if is_lualatex then
        latex_begin = latex_begin ..
            '{\\color[HTML]{' .. colour_hex .. '}\\highLight[{[HTML]{' .. bg_hex .. '}}]{'
        latex_end = '}}' .. latex_end
      else
        latex_begin = latex_begin ..
            '\\colorbox[HTML]{' .. bg_hex ..
            '}{\\parbox{\\dimexpr\\linewidth-2em}{\\color[HTML]{' .. colour_hex .. '}'
        latex_end = '}}' .. latex_end
      end
    elseif bg_hex ~= nil then
      if is_lualatex then
        latex_begin = latex_begin .. '\\highLight[{[HTML]{' .. bg_hex .. '}}]{'
        latex_end = '}' .. latex_end
      else
        latex_begin = latex_begin ..
            '\\colorbox[HTML]{' .. bg_hex .. '}{\\parbox{\\dimexpr\\linewidth-2em}{'
        latex_end = '}}' .. latex_end
      end
    elseif colour_hex ~= nil then
      latex_begin = latex_begin .. '{\\color[HTML]{' .. colour_hex .. '}'
      latex_end = '}' .. latex_end
    end
  elseif colour_hex ~= nil and bg_hex ~= nil then
    if is_lualatex then
      latex_begin = '{\\color[HTML]{' ..
          colour_hex .. '}\\highLight[{[HTML]{' .. bg_hex .. '}}]{'
      latex_end = '}}'
    else
      latex_begin = '\\colorbox[HTML]{' .. bg_hex ..
          '}{\\parbox{\\dimexpr\\linewidth-2\\fboxsep}{\\color[HTML]{' .. colour_hex .. '}'
      latex_end = '}}'
    end
  elseif bg_hex ~= nil then
    if is_lualatex then
      latex_begin = '\\highLight[{[HTML]{' .. bg_hex .. '}}]{'
      latex_end = '}'
    else
      latex_begin = '\\colorbox[HTML]{' .. bg_hex .. '}{\\parbox{\\dimexpr\\linewidth-2\\fboxsep}{'
      latex_end = '}}'
    end
  elseif colour_hex ~= nil then
    latex_begin = '{\\color[HTML]{' .. colour_hex .. '}'
    latex_end = '}'
  end

  table.insert(div.content, 1, pandoc.RawBlock('latex', latex_begin))
  table.insert(div.content, pandoc.RawBlock('latex', latex_end))

  return div.content
end

--- Applies text and background colour styling for Word documents.
--- @param span table The span element to modify
--- @param colour string|nil The text colour to apply
--- @param bg_colour string|nil The background colour to apply
--- @param border_colour string|nil The border colour to apply
--- @param border_style string|nil The border style to apply
--- @return table The span content with OpenXML markup for Word
local function highlight_openxml_docx(span, colour, bg_colour, border_colour, border_style)
  local colour_hex, bg_hex, border_hex = resolve_hex_triplet(colour, bg_colour, border_colour, 'Word')

  local spec = '<w:r><w:rPr>'
  if bg_hex ~= nil then
    spec = spec .. '<w:shd w:val="clear" w:fill="' .. bg_hex .. '"/>'
  end
  if colour_hex ~= nil then
    spec = spec .. '<w:color w:val="' .. colour_hex .. '"/>'
  end
  if border_hex ~= nil then
    local word_style = 'single'
    if border_style == 'dashed' then
      word_style = 'dashed'
    elseif border_style == 'dotted' then
      word_style = 'dotted'
    elseif border_style == 'double' then
      word_style = 'double'
    end
    spec = spec ..
        '<w:bdr w:val="' .. word_style .. '" w:sz="4" w:space="0" w:color="' .. border_hex .. '"/>'
  end
  spec = spec .. '</w:rPr><w:t>'

  table.insert(span.content, 1, pandoc.RawInline('openxml', spec))
  table.insert(span.content, pandoc.RawInline('openxml', '</w:t></w:r>'))

  return span.content
end

--- Applies text and background colour styling for Word documents (block level).
--- @param div table The div element to modify
--- @param colour string|nil The text colour to apply
--- @param bg_colour string|nil The background colour to apply
--- @param border_colour string|nil The border colour to apply
--- @param border_style string|nil The border style to apply
--- @return table The div content with OpenXML markup for Word
local function highlight_openxml_docx_block(div, colour, bg_colour, border_colour, border_style)
  local colour_hex, bg_hex, border_hex = resolve_hex_triplet(colour, bg_colour, border_colour, 'Word')

  local spec = '<w:pPr>'
  if bg_hex ~= nil then
    spec = spec .. '<w:shd w:val="clear" w:fill="' .. bg_hex .. '"/>'
  end
  if border_hex ~= nil then
    local word_style = 'single'
    if border_style == 'dashed' then
      word_style = 'dashed'
    elseif border_style == 'dotted' then
      word_style = 'dotted'
    elseif border_style == 'double' then
      word_style = 'double'
    end
    local border_spec = '<w:pBdr><w:top w:val="' ..
        word_style .. '" w:sz="4" w:space="1" w:color="' .. border_hex .. '"/>' ..
        '<w:left w:val="' .. word_style .. '" w:sz="4" w:space="1" w:color="' .. border_hex .. '"/>' ..
        '<w:bottom w:val="' ..
        word_style .. '" w:sz="4" w:space="1" w:color="' .. border_hex .. '"/>' ..
        '<w:right w:val="' ..
        word_style .. '" w:sz="4" w:space="1" w:color="' .. border_hex .. '"/></w:pBdr>'
    spec = spec .. border_spec
  end
  spec = spec .. '</w:pPr>'

  table.insert(div.content, 1, pandoc.RawBlock('openxml', spec))

  if colour_hex ~= nil then
    for idx = 2, #div.content do
      if div.content[idx].t == 'Para' or div.content[idx].t == 'Plain' then
        local para = div.content[idx]
        local colour_spec = '<w:r><w:rPr><w:color w:val="' .. colour_hex .. '"/></w:rPr><w:t>'
        table.insert(para.content, 1, pandoc.RawInline('openxml', colour_spec))
        table.insert(para.content, pandoc.RawInline('openxml', '</w:t></w:r>'))
      end
    end
  end

  return div.content
end

--- Warn once per render when PowerPoint silently discards a border colour.
--- @param scope string Either "inline" or "block" for the warning context
local function warn_pptx_border_discarded(scope)
  if pptx_border_warning_shown then return end
  log.log_warning(
    EXTENSION_NAME,
    'PowerPoint does not support borders on ' .. scope ..
    ' text runs; the border colour is discarded. Use a shape or table cell for borders.'
  )
  pptx_border_warning_shown = true
end

--- Applies text and background colour styling for PowerPoint presentations.
--- @param span table The span element to modify
--- @param colour string|nil The text colour to apply
--- @param bg_colour string|nil The background colour to apply
--- @param border_colour string|nil The border colour (warned and discarded)
--- @return table Raw inline containing OpenXML markup for PowerPoint
local function highlight_openxml_pptx(span, colour, bg_colour, border_colour)
  local colour_hex, bg_hex = resolve_hex_triplet(colour, bg_colour, nil, 'PowerPoint')

  if border_colour ~= nil then
    warn_pptx_border_discarded('inline')
  end

  local spec = '<a:r><a:rPr dirty="0">'
  if colour_hex ~= nil then
    spec = spec .. '<a:solidFill><a:srgbClr val="' .. colour_hex .. '" /></a:solidFill>'
  end
  if bg_hex ~= nil then
    spec = spec .. '<a:highlight><a:srgbClr val="' .. bg_hex .. '" /></a:highlight>'
  end
  spec = spec .. '</a:rPr><a:t>'

  local span_content_string = ''
  for _, inline in ipairs(span.content) do
    span_content_string = span_content_string .. pandoc.utils.stringify(inline)
  end

  return pandoc.RawInline('openxml', spec .. span_content_string .. '</a:t></a:r>')
end

--- Applies text and background colour styling for PowerPoint presentations (block level).
--- @param div table The div element to modify
--- @param colour string|nil The text colour to apply
--- @param bg_colour string|nil The background colour to apply
--- @param border_colour string|nil The border colour (warned and discarded)
--- @return table The div content with OpenXML markup for PowerPoint
local function highlight_openxml_pptx_block(div, colour, bg_colour, border_colour)
  local colour_hex, bg_hex = resolve_hex_triplet(colour, bg_colour, nil, 'PowerPoint')

  if border_colour ~= nil then
    warn_pptx_border_discarded('block')
  end

  for idx = 1, #div.content do
    if div.content[idx].t == 'Para' or div.content[idx].t == 'Plain' then
      local para = div.content[idx]
      local para_content_string = ''
      for _, inline in ipairs(para.content) do
        para_content_string = para_content_string .. pandoc.utils.stringify(inline)
      end

      local spec = '<a:r><a:rPr dirty="0">'
      if colour_hex ~= nil then
        spec = spec .. '<a:solidFill><a:srgbClr val="' .. colour_hex .. '" /></a:solidFill>'
      end
      if bg_hex ~= nil then
        spec = spec .. '<a:highlight><a:srgbClr val="' .. bg_hex .. '" /></a:highlight>'
      end
      spec = spec .. '</a:rPr><a:t>'

      para.content = { pandoc.RawInline('openxml', spec .. para_content_string .. '</a:t></a:r>') }
    end
  end

  return div.content
end

--- Applies text and background colour styling for Typst output.
--- @param span table The span element to modify
--- @param colour string|nil The text colour to apply
--- @param bg_colour string|nil The background colour to apply
--- @param border_colour string|nil The border colour to apply
--- @param border_style string|nil The border style to apply
--- @param opacity number|nil The opacity in [0, 1] (applied to background if present, else foreground)
--- @return table The span content with Typst markup
local function highlight_typst(span, colour, bg_colour, border_colour, border_style, opacity)
  if opacity ~= nil and bg_colour ~= nil then
    bg_colour = apply_opacity_typst(bg_colour, opacity)
  end

  local colour_open, colour_close = '', ''
  if colour ~= nil then
    local text_colour = colour
    if opacity ~= nil and bg_colour == nil then
      text_colour = apply_opacity_typst(colour, opacity)
    end
    colour_open = '#text(' .. text_colour .. ')['
    colour_close = ']'
  end

  local bg_colour_open, bg_colour_close = '', ''
  local border_open, border_close = '', ''

  -- Build Typst stroke specification with optional dash pattern.
  local function build_stroke(stroke_colour, style)
    if style == 'dashed' then
      return '(paint: ' .. stroke_colour .. ', dash: "dashed")'
    elseif style == 'dotted' then
      return '(paint: ' .. stroke_colour .. ', dash: "dotted")'
    elseif style == 'double' then
      return '(paint: ' .. stroke_colour .. ', thickness: 2pt)'
    else
      return stroke_colour
    end
  end

  if border_colour ~= nil and bg_colour ~= nil then
    local stroke_spec = build_stroke(border_colour, border_style)
    border_open = '#box(stroke: ' .. stroke_spec .. ', fill: ' .. bg_colour ..
        ', inset: (x: 0.2em, y: 0.45em))['
    border_close = ']'
  elseif border_colour ~= nil then
    local stroke_spec = build_stroke(border_colour, border_style)
    border_open = '#box(stroke: ' .. stroke_spec .. ', inset: (x: 0.2em, y: 0.45em))['
    border_close = ']'
  elseif bg_colour ~= nil then
    bg_colour_open = '#highlight(fill: ' .. bg_colour .. ')['
    bg_colour_close = ']'
  end

  table.insert(
    span.content, 1,
    pandoc.RawInline('typst', border_open .. colour_open .. bg_colour_open)
  )
  table.insert(
    span.content,
    pandoc.RawInline('typst', bg_colour_close .. colour_close .. border_close)
  )

  return span.content
end

--- Applies text and background colour styling for Typst output (block level).
--- @param div table The div element to modify
--- @param colour string|nil The text colour to apply
--- @param bg_colour string|nil The background colour to apply
--- @param border_colour string|nil The border colour to apply
--- @param border_style string|nil The border style to apply
--- @param opacity number|nil The opacity in [0, 1] (ignored when a gradient is present)
--- @param gradient table|nil A structured gradient from `parse_gradient_typst`
--- @return table The div content with Typst markup
local function highlight_typst_block(div, colour, bg_colour, border_colour, border_style, opacity, gradient)
  -- Resolve the block fill: a gradient takes precedence over a background colour.
  local fill = nil
  if gradient ~= nil then
    fill = gradient_to_typst(gradient)
  elseif bg_colour ~= nil then
    fill = bg_colour
    if opacity ~= nil then
      fill = apply_opacity_typst(fill, opacity)
    end
  end

  local colour_open, colour_close = '', ''
  if colour ~= nil then
    local text_colour = colour
    if opacity ~= nil and gradient == nil and bg_colour == nil then
      text_colour = apply_opacity_typst(colour, opacity)
    end
    colour_open = '#text(' .. text_colour .. ')['
    colour_close = ']'
  end

  local bg_colour_open, bg_colour_close = '', ''
  local border_open, border_close = '', ''

  -- Build Typst stroke specification with optional dash pattern.
  local function build_stroke(stroke_colour, style)
    if style == 'dashed' then
      return '(paint: ' .. stroke_colour .. ', dash: "dashed")'
    elseif style == 'dotted' then
      return '(paint: ' .. stroke_colour .. ', dash: "dotted")'
    elseif style == 'double' then
      return '(paint: ' .. stroke_colour .. ', thickness: 2pt)'
    else
      return stroke_colour
    end
  end

  if border_colour ~= nil and fill ~= nil then
    local stroke_spec = build_stroke(border_colour, border_style)
    border_open = '#block(stroke: ' ..
        stroke_spec .. ', fill: ' .. fill .. ', inset: (x: 0.5em, y: 0.9em), radius: 0.2em)['
    border_close = ']'
  elseif border_colour ~= nil then
    local stroke_spec = build_stroke(border_colour, border_style)
    border_open = '#block(stroke: ' .. stroke_spec ..
        ', inset: (x: 0.5em, y: 0.9em), radius: 0.2em)['
    border_close = ']'
  elseif fill ~= nil then
    bg_colour_open = '#block(fill: ' .. fill .. ', inset: 0.5em, radius: 0.2em)['
    bg_colour_close = ']'
  end

  table.insert(
    div.content, 1,
    pandoc.RawBlock('typst', border_open .. colour_open .. bg_colour_open)
  )
  table.insert(
    div.content,
    pandoc.RawBlock('typst', bg_colour_close .. colour_close .. border_close)
  )

  return div.content
end

--- Resolves every accepted spelling to its canonical attribute name.
--- @param attributes table The attributes, keyed by any accepted spelling
--- @return table<string, string> canonical The values keyed by canonical name
local function canonical_attributes(attributes)
  local canonical = {}
  for _, attribute in ipairs(ATTRIBUTE_SPELLINGS) do
    for _, spelling in ipairs(attribute.spellings) do
      if attributes[spelling] ~= nil then
        canonical[attribute.name] = attributes[spelling]
        break
      end
    end
  end
  return canonical
end

--- Extracts colour attributes from element attributes.
--- @param attributes table The element attributes
--- @return string|nil colour The foreground colour
--- @return string|nil bg_colour The background colour
--- @return string|nil border_colour The border colour
--- @return string|nil border_style The border style
local function get_colour_attributes(attributes)
  local canonical = canonical_attributes(attributes)
  return canonical['colour'], canonical['bg-colour'], canonical['border-colour'], canonical['border-style']
end

--- Reads the named styles from `extensions.highlight-text.styles`.
---
--- The schema check reports a malformed definition. Here a definition that is
--- not a map is skipped, and an unknown key inside one is dropped. A style left
--- with no attribute is not registered, so its class stays on the element.
--- @param meta table The document metadata
local function load_styles(meta)
  checker:options(meta)
  local extension_meta = meta['extensions'] and meta['extensions'][EXTENSION_NAME]
  local definitions = extension_meta and extension_meta['styles']
  if pandoc.utils.type(definitions) ~= 'table' then
    return
  end
  for name, definition in pairs(definitions) do
    if pandoc.utils.type(definition) == 'table' then
      local values = {}
      for key, value in pairs(definition) do
        values[key] = type(value) == 'boolean' and tostring(value) or pandoc.utils.stringify(value)
      end
      local resolved = canonical_attributes(values)
      if next(resolved) ~= nil then
        styles[name] = resolved
      end
    end
  end
end

--- Replaces the style classes of an element with the attributes they define.
---
--- Styles merge in class order, so a later class wins, and the element's own
--- attributes win over every style. A style value is added under its canonical
--- name only where the element gives that attribute under no spelling, so the
--- element's own spellings reach the schema check as written.
--- @param element table The span or div (mutated in place)
local function apply_styles(element)
  if next(styles) == nil then
    return
  end
  local merged = {}
  local remaining = pandoc.List()
  for _, class in ipairs(element.classes) do
    local style = styles[class]
    if style == nil then
      remaining:insert(class)
    else
      for name, value in pairs(style) do
        merged[name] = value
      end
    end
  end
  if #remaining == #element.classes then
    return
  end

  local own = canonical_attributes(element.attributes)
  element.classes = remaining
  for name, value in pairs(merged) do
    if own[name] == nil then
      element.attributes[name] = value
    end
  end
end

--- Processes colour settings for light and dark themes.
--- @param colour string|nil The foreground colour
--- @param bg_colour string|nil The background colour
--- @param border_colour string|nil The border colour
--- @param border_style string|nil The border style
--- @param opacity number|nil The opacity (HTML only)
--- @param gradient string|nil The block-level gradient (HTML only)
--- @return table|nil highlight_settings The processed highlight settings
local function process_highlight_settings(colour, bg_colour, border_colour, border_style, opacity, gradient)
  local highlight_settings = {}

  if quarto.brand.has_mode('light') or quarto.brand.has_mode('dark') then
    local modes = { 'light', 'dark' }
    for _, mode in ipairs(modes) do
      if quarto.brand.has_mode(mode) then
        highlight_settings[mode] = {
          colour = get_brand_colour(mode, colour, 'foreground colour'),
          bg_colour = get_brand_colour(mode, bg_colour, 'background colour'),
          border_colour = get_brand_colour(mode, border_colour, 'border colour'),
          border_style = border_style,
          opacity = opacity,
          gradient = gradient
        }
      end
    end
  else
    highlight_settings.light = {
      colour = get_brand_colour('light', colour, 'foreground colour'),
      bg_colour = get_brand_colour('light', bg_colour, 'background colour'),
      border_colour = get_brand_colour('light', border_colour, 'border colour'),
      border_style = border_style,
      opacity = opacity,
      gradient = gradient
    }
  end

  if highlight_settings.light == nil and highlight_settings.dark == nil then
    return nil
  end

  if highlight_settings.light == nil then
    highlight_settings.light = highlight_settings.dark
  end

  return highlight_settings
end

--- Main filter function that processes span elements and applies highlighting
--- based on the output format and specified attributes.
--- @param span table The span element from the document
--- @return table The modified span or span content with appropriate styling
local function highlight(span)
  -- Checked before the styles are applied and the aliases are stripped, so the
  -- schema sees what the document wrote on the element. A style value was
  -- already checked once from the `Meta` pass.
  local checked = checker:attributes(span.attributes)
  apply_styles(span)
  local colour, bg_colour, border_colour, border_style = get_colour_attributes(span.attributes)
  local opacity = parse_opacity(span.attributes['opacity'])
  local highlight_settings = process_highlight_settings(colour, bg_colour, border_colour, border_style, opacity, nil)

  if highlight_settings == nil then
    strip_alias_attributes(span.attributes)
    return span
  end

  colour = highlight_settings.light.colour
  bg_colour = highlight_settings.light.bg_colour
  border_colour = highlight_settings.light.border_colour
  border_style = highlight_settings.light.border_style

  if colour == nil and bg_colour == nil and border_colour == nil and opacity == nil then
    strip_alias_attributes(span.attributes)
    return span
  end

  -- The schema declares `par` a boolean, so its value decides. Reading presence
  -- alone meant `par="false"` turned it on as surely as `par="true"` did. A bare
  -- `par` cannot reach here: Pandoc does not parse an attribute without a value,
  -- so the word is left as text and no span is made.
  -- The element's own `par` was checked above. Without one, a style's value
  -- applies, which `load_styles` wrote as "true" or "false".
  local par = (checked ~= nil and checked['par'] == true) or span.attributes['par'] == 'true'
  strip_alias_attributes(span.attributes)

  if quarto.doc.is_format('html') or quarto.doc.is_format('revealjs') then
    return highlight_html(span, highlight_settings)
  elseif quarto.doc.is_format('latex') or quarto.doc.is_format('beamer') then
    return highlight_latex(span, colour, bg_colour, border_colour, border_style, par)
  elseif quarto.doc.is_format('docx') then
    return highlight_openxml_docx(span, colour, bg_colour, border_colour, border_style)
  elseif quarto.doc.is_format('pptx') then
    return highlight_openxml_pptx(span, colour, bg_colour, border_colour)
  elseif quarto.doc.is_format('typst') then
    return highlight_typst(span, colour, bg_colour, border_colour, border_style, opacity)
  else
    return span
  end
end

--- Main filter function that processes div elements and applies highlighting
--- based on the output format and specified attributes.
--- @param div table The div element from the document
--- @return table The modified div or div content with appropriate styling
local function highlight_block(div)
  checker:attributes(div.attributes)
  apply_styles(div)
  local colour, bg_colour, border_colour, border_style = get_colour_attributes(div.attributes)
  local opacity = parse_opacity(div.attributes['opacity'])
  local gradient = parse_gradient(div.attributes['gradient'])
  local gradient_typst = parse_gradient_typst(div.attributes['gradient'])
  local highlight_settings = process_highlight_settings(colour, bg_colour, border_colour, border_style, opacity, gradient)

  if highlight_settings == nil then
    strip_alias_attributes(div.attributes)
    return div
  end

  colour = highlight_settings.light.colour
  bg_colour = highlight_settings.light.bg_colour
  border_colour = highlight_settings.light.border_colour
  border_style = highlight_settings.light.border_style

  if colour == nil and bg_colour == nil and border_colour == nil and opacity == nil and gradient == nil then
    strip_alias_attributes(div.attributes)
    return div
  end

  if gradient ~= nil and not (quarto.doc.is_format('html') or quarto.doc.is_format('revealjs') or quarto.doc.is_format('typst')) then
    log.log_warning(
      EXTENSION_NAME,
      'The "gradient" attribute is only supported in HTML/RevealJS/Typst output; ignoring for format "' .. FORMAT .. '".'
    )
  end

  strip_alias_attributes(div.attributes)

  if quarto.doc.is_format('html') or quarto.doc.is_format('revealjs') then
    return highlight_html_block(div, highlight_settings)
  elseif quarto.doc.is_format('latex') or quarto.doc.is_format('beamer') then
    return highlight_latex_block(div, colour, bg_colour, border_colour, border_style)
  elseif quarto.doc.is_format('docx') then
    return highlight_openxml_docx_block(div, colour, bg_colour, border_colour, border_style)
  elseif quarto.doc.is_format('pptx') then
    return highlight_openxml_pptx_block(div, colour, bg_colour, border_colour)
  elseif quarto.doc.is_format('typst') then
    return highlight_typst_block(div, colour, bg_colour, border_colour, border_style, opacity, gradient_typst)
  else
    return div
  end
end

--- Wraps a filter function so the element's identifier survives the rewrite.
---
--- The format writers rebuild the element from its content, which drops the
--- identifier. A wrapper that carries only the identifier keeps links to it
--- working in LaTeX, Typst, and Word. PowerPoint has no anchor for it. HTML output already carries the identifier, so it
--- is returned as it is.
--- @param handler function The filter function for one element type
--- @param constructor any The Pandoc constructor (pandoc.Span or pandoc.Div)
--- @return function handler The filter function that keeps the identifier
local function keep_identifier(handler, constructor)
  return function(element)
    local identifier = element.identifier
    local result = handler(element)
    if identifier == '' or rawequal(result, element) or result.identifier == identifier then
      return result
    end
    return constructor(result, pandoc.Attr(identifier))
  end
end

return {
  { Meta = load_styles },
  { Span = keep_identifier(highlight, pandoc.Span) },
  { Div = keep_identifier(highlight_block, pandoc.Div) },
}
