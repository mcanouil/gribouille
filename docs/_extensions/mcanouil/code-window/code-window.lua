--- @module code-window
--- @license MIT
--- @copyright 2026 Mickaël Canouil
--- @author Mickaël Canouil
--- @brief Code block window decorations with multiple styles
--- @description Adds window chrome (macOS traffic lights, Windows title bar
--- buttons, or plain filename) to code blocks in HTML, Reveal.js, and Typst
--- formats. Registered at pre-quarto to process all formats in a single pass.

-- ============================================================================
-- EXTENSION NAME
-- ============================================================================

local EXTENSION_NAME = 'code-window'
local str = require(quarto.utils.resolve_path('_modules/string.lua'):gsub('%.lua$', ''))
local log = require(quarto.utils.resolve_path('_modules/logging.lua'):gsub('%.lua$', ''))
local meta_mod = require(quarto.utils.resolve_path('_modules/metadata.lua'):gsub('%.lua$', ''))
local pdoc = require(quarto.utils.resolve_path('_modules/pandoc-helpers.lua'):gsub('%.lua$', ''))
local html_mod = require(quarto.utils.resolve_path('_modules/html.lua'):gsub('%.lua$', ''))
local code_annotations = nil

-- ============================================================================
-- DEFAULTS AND STATE
-- ============================================================================

--- @class CodeWindowConfig
--- @field enabled boolean Whether code-window styling is enabled
--- @field auto_filename boolean Whether to auto-generate filename from language
--- @field style string Window decoration style ('macos', 'windows', 'default')
--- @field typst_wrapper string Typst wrapper function name
--- @field hotfix_code_annotations boolean Whether to apply the code-annotations hot-fix for Typst
--- @field hotfix_skylighting boolean Whether to apply the Skylighting hot-fix for Typst

local VALID_STYLES = { ['default'] = true, ['macos'] = true, ['windows'] = true }

local DEFAULTS = {
  ['enabled'] = 'true',
  ['auto-filename'] = 'true',
  ['style'] = 'macos',
  ['wrapper'] = 'code-window',
  ['collapse'] = 'false',
  ['lines-label'] = 'true',
}

local VALID_COLLAPSE = {
  ['false'] = false,
  ['true'] = 'closed',
  ['closed'] = 'closed',
  ['open'] = 'open',
}

local HOTFIX_DEFAULTS = {
  ['code-annotations'] = true,
  ['skylighting'] = true,
  ['typst-title'] = true,
}

local CURRENT_FORMAT = nil
local CONFIG = nil
local TYPST_BG_COLOUR = nil
local ANNOTATION_BLOCK_COUNTER = 0

-- ============================================================================
-- BLOCK-LEVEL STYLE OVERRIDE
-- ============================================================================

--- Read the block-level style override from code-window-style attribute.
--- Returns the validated style value or nil.
--- Strips the attribute from the block.
--- @param block pandoc.CodeBlock Code block element
--- @return string|nil Style override value
local function read_block_style(block)
  local block_style = block.attributes['code-window-style']
  if not block_style or block_style == '' then
    return nil
  end
  block.attributes['code-window-style'] = nil
  if VALID_STYLES[block_style] then
    return block_style
  end
  log.log_warning(EXTENSION_NAME,
    string.format('Unknown block style "%s", using configured default.', block_style))
  return nil
end

--- Resolve a collapse value coming from extension options or a code-block
--- attribute. Returns "open"/"closed" when the window should be collapsible,
--- nil when collapsing is off or the value is unrecognised.
--- Emits a warning when the input is set but not understood.
--- @param raw string|nil Raw collapse value
--- @return string|nil Resolved collapse mode ("open"/"closed") or nil
local function resolve_collapse(raw)
  if raw == nil or raw == '' then
    return nil
  end
  local resolved = VALID_COLLAPSE[raw]
  if resolved == nil then
    log.log_warning(EXTENSION_NAME,
      string.format('Unknown collapse value "%s", expected one of true/false/open/closed.', raw))
    return nil
  end
  if resolved == false then
    return nil
  end
  return resolved
end

--- Read the per-block collapse override from code-window-collapse attribute.
--- Always strips the attribute from the block before resolving.
--- @param block pandoc.CodeBlock Code block element
--- @return string|nil Resolved collapse mode ("open"/"closed") or nil when off
local function read_block_collapse(block)
  local raw = block.attributes['code-window-collapse']
  if raw == nil then
    return nil
  end
  block.attributes['code-window-collapse'] = nil
  return resolve_collapse(raw)
end

--- Read a highlight-lines spec from the block, looking at the
--- code-window-lines attribute first and falling back to Quarto's
--- code-line-numbers attribute when it carries a non-boolean spec.
--- Returns the cleaned spec string or nil.
--- @param block pandoc.CodeBlock Code block element
--- @return string|nil Line spec to display in the title bar
local function read_block_lines_label(block)
  local raw = block.attributes['code-window-lines']
  if raw ~= nil then
    block.attributes['code-window-lines'] = nil
    if raw ~= '' then
      return raw
    end
  end

  local cln = block.attributes['code-line-numbers']
  if not cln or cln == '' or cln == 'true' or cln == 'false' then
    return nil
  end
  return cln
end

-- ============================================================================
-- TYPST FUNCTION DEFINITION
-- ============================================================================

--- Typst colour helpers for adaptive theme support.
--- Always injected so the code-window function can derive border, surface,
--- and muted colours from the page background at render time.
local TYPST_COLOUR_HELPERS = [==[
// code-window: adaptive colour helpers (derive UI tones from page background)
#let _cw-page-bg() = {
  let f = page.fill
  if type(f) == color { f } else { luma(255) }
}

#let _cw-fg(bg) = {
  let comps = bg.components(alpha: false)
  let lum = if comps.len() == 1 {
    comps.at(0) / 100%
  } else {
    0.2126 * comps.at(0) / 100% + 0.7152 * comps.at(1) / 100% + 0.0722 * comps.at(2) / 100%
  }
  if lum < 0.5 { luma(255) } else { luma(0) }
}
]==]

--- Typst annotation helper functions (state, colour, circled numbers, annotation items).
--- Only injected when at least one hot-fix is active.
local TYPST_ANNOTATION_DEF = [==[
// code-window: annotation state passed to Skylighting via Typst state
#let _cw-annotations = state("cw-annotations", none)

// Derive a contrasting annotation colour from a background fill.
// Light backgrounds get dark circles; dark backgrounds get light circles.
// Uses ITU-R BT.709 luminance coefficients, matching quarto-cli PR #14170.
#let code-window-annote-colour(bg) = {
  if type(bg) == color {
    let comps = bg.components(alpha: false)
    let lum = if comps.len() == 1 {
      comps.at(0) / 100%
    } else {
      0.2126 * comps.at(0) / 100% + 0.7152 * comps.at(1) / 100% + 0.0722 * comps.at(2) / 100%
    }
    if lum < 0.5 { luma(200) } else { luma(60) }
  } else {
    luma(60)
  }
}

#let code-window-circled-number(n, bg-colour: none) = {
  let c = if bg-colour != none { code-window-annote-colour(bg-colour) } else { luma(120) }
  box(baseline: 20%, circle(
    radius: 4.5pt,
    stroke: 0.5pt + c,
  )[#set text(size: 5.5pt, fill: c); #align(center + horizon, str(n))])
}

#let code-window-annotation-item(block-id, n, content) = {
  let lbl-prefix = "cw-" + str(block-id) + "-"
  context {
    let target = label(lbl-prefix + "line-" + str(n))
    let has-target = query(target).len() > 0
    [#block(above: 0.4em, below: 0.4em)[
      #if has-target {
        link(target)[#code-window-circled-number(n)]
      } else {
        code-window-circled-number(n)
      }
      #h(0.4em)
      #content
    ] #label(lbl-prefix + "item-" + str(n))]
  }
}

#let code-window-annotated-content(content, annotations: (:), bg-colour: none, block-id: 0) = {
  if annotations.len() > 0 {
    _cw-annotations.update((annotations: annotations, bg-colour: bg-colour, block-id: block-id))
    content
    _cw-annotations.update(none)
  } else {
    content
  }
}
]==]

--- Typst code-window body content template.
--- Uses annotation wrapper when hot-fixes are active, plain content otherwise.
local TYPST_CONTENT_WITH_ANNOTATIONS = [==[
        code-window-annotated-content(
          content,
          annotations: annotations,
          bg-colour: bg-colour,
          block-id: block-id,
        )
]==]

local TYPST_CONTENT_PLAIN = [==[
        content
]==]

--- Build the complete Typst code-window function definition.
--- @param has_hotfixes boolean Whether at least one hot-fix is active
--- @return string Typst function definition(s)
local function build_typst_function_def(has_hotfixes)
  local content_block = has_hotfixes
      and TYPST_CONTENT_WITH_ANNOTATIONS
      or TYPST_CONTENT_PLAIN

  local fn_def = string.format([==[
#let code-window(
  content,
  filename: none,
  is-auto: false,
  style: "macos",
  annotations: (:),
  bg-colour: none,
  block-id: 0,
  lines-label: none,
) = {
  context {
  let page-bg = _cw-page-bg()
  let fg = _cw-fg(page-bg)
  let border-colour = color.mix((fg, 15%%), (page-bg, 85%%))
  let surface-fill = color.mix((fg, 5%%), (page-bg, 95%%))
  let muted-colour = color.mix((fg, 50%%), (page-bg, 50%%))

  let filename-label = if filename != none {
    text(
      size: if is-auto { 0.7em } else { 0.85em },
      weight: 500,
      fill: muted-colour,
      if is-auto { upper(filename) } else { filename },
    )
  }

  let lines-chip = if lines-label != none {
    box(
      inset: (x: 0.4em, y: 0.05em),
      outset: (y: 0.15em),
      radius: 3pt,
      fill: color.mix((fg, 10%%), (page-bg, 90%%)),
      stroke: 0.5pt + border-colour,
      text(size: 0.7em, weight: 500, fill: muted-colour, lines-label),
    )
  }

  let traffic-lights = box(
    inset: (right: 0.5em),
    stack(
      dir: ltr,
      spacing: 0.425em,
      circle(radius: 0.425em, fill: rgb("#ff5f56"), stroke: none),
      circle(radius: 0.425em, fill: rgb("#ffbd2e"), stroke: none),
      circle(radius: 0.425em, fill: rgb("#27c93f"), stroke: none),
    ),
  )

  let window-buttons = box(
    inset: (left: 0.5em),
    {
      set line(stroke: 1pt + muted-colour)
      stack(
        dir: ltr,
        spacing: 0.8em,
        // Minimise (horizontal line)
        box(width: 0.6em, height: 0.6em, align(horizon, line(length: 100%%))),
        // Maximise (square)
        box(width: 0.6em, height: 0.6em, stroke: 1pt + muted-colour),
        // Close (x)
        box(width: 0.6em, height: 0.6em, {
          place(line(start: (0%%, 0%%), end: (100%%, 100%%)))
          place(line(start: (100%%, 0%%), end: (0%%, 100%%)))
        }),
      )
    },
  )

  let _label-with-chip = if lines-chip != none {
    stack(dir: ltr, spacing: 0.5em, filename-label, lines-chip)
  } else {
    filename-label
  }

  let title-bar = if style == "macos" {
    grid(
      columns: (auto, 1fr),
      align: (left + horizon, right + horizon),
      gutter: 0.5em,
      stroke: 0pt,
      traffic-lights,
      _label-with-chip,
    )
  } else if style == "windows" {
    grid(
      columns: (1fr, auto),
      align: (left + horizon, right + horizon),
      gutter: 0.5em,
      stroke: 0pt,
      _label-with-chip,
      window-buttons,
    )
  } else {
    // default: plain filename, left-aligned
    _label-with-chip
  }

  block(
    width: 100%%,
    stroke: 1pt + border-colour,
    radius: 8pt,
    clip: true,
    {
      block(
        width: 100%%,
        fill: surface-fill,
        inset: (x: 1em, y: 0.6em),
        below: 0pt,
        radius: 0pt,
        stroke: (bottom: 1pt + border-colour),
        title-bar,
      )
      // Strip code block chrome so content fills flush against the window body.
      // set block() provides defaults for Skylighting blocks (explicit fill preserved).
      // show raw overrides the document-level raw block styling (fill, radius).
      {
        set block(
          width: 100%%,
          inset: 8pt,
          radius: 0pt,
          stroke: none,
          above: 0pt,
          below: 0pt,
        )
        show raw.where(block: true): set block(
          fill: none,
          width: 100%%,
          radius: 0pt,
          stroke: none,
          above: 0pt,
          below: 0pt,
        )
%s      }
    },
  )
  }
}
]==], content_block)

  local result = TYPST_COLOUR_HELPERS
  if has_hotfixes then
    result = result .. TYPST_ANNOTATION_DEF
  end
  return result .. fn_def
end

-- ============================================================================
-- TYPST PROCESSING
-- ============================================================================

--- Get the next unique block ID for annotation linking.
--- @return integer
local function next_block_id()
  ANNOTATION_BLOCK_COUNTER = ANNOTATION_BLOCK_COUNTER + 1
  return ANNOTATION_BLOCK_COUNTER
end

--- Build the Typst bg-colour parameter string.
--- @return string Empty string or ', bg-colour: rgb("...")'
local function typst_bg_colour_param()
  if not TYPST_BG_COLOUR then
    return ''
  end
  return string.format(', bg-colour: rgb("%s")', TYPST_BG_COLOUR)
end

--- Escape a string for embedding in a Typst double-quoted string literal.
--- @param s string
--- @return string
local function typst_escape_string(s)
  return (s:gsub('\\', '\\\\'):gsub('"', '\\"'))
end

--- Build a code-window opening RawBlock for Typst.
--- @param filename string
--- @param is_auto boolean
--- @param style string
--- @param annotations table|nil
--- @param block_id integer
--- @param lines_label string|nil Highlighted-lines spec to display in the title bar
--- @return pandoc.RawBlock
local function typst_code_window_open(filename, is_auto, style, annotations, block_id, lines_label)
  local annot_param = ''
  if annotations and next(annotations) then
    annot_param = string.format(', annotations: %s, block-id: %d',
      code_annotations.annotations_to_typst_dict(annotations), block_id)
  end

  local lines_param = ''
  if lines_label and lines_label ~= '' then
    lines_param = string.format(', lines-label: "%s"', typst_escape_string(lines_label))
  end

  return pandoc.RawBlock('typst', string.format(
    '#%s(filename: "%s", is-auto: %s, style: "%s"%s%s%s)[',
    CONFIG.typst_wrapper,
    typst_escape_string(filename),
    is_auto and 'true' or 'false',
    style,
    annot_param,
    typst_bg_colour_param(),
    lines_param
  ))
end

--- Build a standalone annotation wrapper for non-windowed blocks.
--- @param annotations table
--- @param block_id integer
--- @return pandoc.RawBlock opening, pandoc.RawBlock closing
local function typst_annotation_wrapper(annotations, block_id)
  local open = pandoc.RawBlock('typst', string.format(
    '#%s-annotated-content(annotations: %s, block-id: %d%s)[',
    CONFIG.typst_wrapper,
    code_annotations.annotations_to_typst_dict(annotations),
    block_id,
    typst_bg_colour_param()
  ))
  local close = pandoc.RawBlock('typst', ']')
  return open, close
end

-- ============================================================================
-- HTML PROCESSING
-- ============================================================================

--- Process CodeBlock for HTML/Reveal.js formats.
--- Explicit-filename blocks are returned for Quarto to wrap; a marker class
--- is added when a block-level style override is present.
--- Auto-filename blocks are wrapped directly with the style class.
--- @param block pandoc.CodeBlock Code block element
--- @return pandoc.Div|pandoc.CodeBlock Wrapped block or original
local function process_html(block)
  -- Per-block opt-out: code-window-enabled="false" skips window chrome.
  local block_enabled = block.attributes['code-window-enabled']
  if block_enabled then
    block.attributes['code-window-enabled'] = nil
  end
  if block_enabled == 'false' then
    return block
  end

  local block_style = read_block_style(block)
  local block_collapse = read_block_collapse(block)
  local effective_collapse = block_collapse or CONFIG.collapse
  local explicit_filename = block.attributes['filename']
  local no_auto = block.attributes['code-window-no-auto-filename']
  if no_auto then
    block.attributes['code-window-no-auto-filename'] = nil
  end

  local lines_label = CONFIG.lines_label and read_block_lines_label(block) or nil

  if explicit_filename and explicit_filename ~= '' then
    -- Let Quarto create the .code-with-filename wrapper.
    -- Add a marker class for block-level style override; the injected JS
    -- reads it and promotes it to the wrapper div.
    if block_style then
      table.insert(block.classes, 'cw-style-' .. block_style)
    end
    if effective_collapse then
      table.insert(block.classes, 'cw-collapse-' .. effective_collapse)
    end
    if lines_label then
      block.attributes['code-window-lines-label'] = lines_label
    end
    return block
  end

  if not CONFIG.auto_filename or no_auto then
    return block
  end

  -- Default/unknown/no-language blocks carry their label on
  -- code-window-auto-label (set by the language module); everything else uses
  -- its language class.
  local filename = block.attributes['code-window-auto-label'] or block.classes[1]
  block.attributes['code-window-auto-label'] = nil

  -- Set the filename attribute so Quarto creates its own .code-with-filename
  -- wrapper. This preserves the CodeBlock+OrderedList sibling structure
  -- needed by Quarto's code-annotations processor.
  block.attributes['filename'] = filename
  table.insert(block.classes, 'cw-auto')
  if block_style then
    table.insert(block.classes, 'cw-style-' .. block_style)
  end
  if effective_collapse then
    table.insert(block.classes, 'cw-collapse-' .. effective_collapse)
  end
  if lines_label then
    block.attributes['code-window-lines-label'] = lines_label
  end

  return block
end

-- ============================================================================
-- FILTER HANDLERS
-- ============================================================================

--- Generate a JS snippet that builds .code-with-filename wrappers for
--- auto-filename blocks (marked with cw-auto at pre-quarto), applies the
--- configured default style class to all .code-with-filename wrappers,
--- promotes block-level cw-style-* / cw-collapse-* marker classes, inserts
--- a highlighted-lines chip when data-code-window-lines-label is set on the inner
--- pre, and wraps collapsible windows in a <details> element where the
--- title bar acts as the <summary>.
--- @param default_style string The configured default style
--- @param default_collapse string|nil Default collapse mode ("open"/"closed"/nil)
--- @return string JavaScript code
local function make_style_js(default_style, default_collapse)
  local default_collapse_js = default_collapse and ('"' .. default_collapse .. '"') or 'null'
  return string.format([=[
document.addEventListener("DOMContentLoaded",function(){
  var DEFAULT_COLLAPSE=%s;
  document.querySelectorAll("pre.cw-auto").forEach(function(pre){
    var fn=pre.closest("[data-filename]");
    if(!fn)return;
    var name=fn.getAttribute("data-filename");
    if(!name)return;
    var scaffold=pre.closest(".code-copy-outer-scaffold")||pre.closest(".sourceCode");
    if(!scaffold)return;
    var w=document.createElement("div");
    w.className="code-with-filename code-window-auto";
    var tb=document.createElement("div");
    tb.className="code-with-filename-file";
    var tp=document.createElement("pre");
    var ts=document.createElement("strong");
    ts.textContent=name;
    tp.appendChild(ts);tb.appendChild(tp);
    scaffold.parentNode.insertBefore(w,scaffold);
    w.appendChild(tb);w.appendChild(scaffold);
    pre.classList.remove("cw-auto");
  });
  function findMarkerSource(el){
    return el.querySelector('pre[class*="cw-style-"],pre[class*="cw-collapse-"],pre[data-code-window-lines-label]')
      ||el.querySelector('[class*="cw-style-"],[class*="cw-collapse-"],[data-code-window-lines-label]');
  }
  document.querySelectorAll(".code-with-filename").forEach(function(el){
    var marker=findMarkerSource(el);
    var styleApplied=/\bcode-window-(macos|windows|default)\b/.test(el.className);
    if(!styleApplied){
      var sm=marker&&marker.className.match(/cw-style-(\w+)/);
      if(sm){el.classList.add("code-window-"+sm[1]);marker.classList.remove(sm[0]);}
      else{el.classList.add("code-window-%s");}
    }
    var collapse=null;
    if(marker){
      var cm=marker.className.match(/cw-collapse-(open|closed)/);
      if(cm){collapse=cm[1];marker.classList.remove(cm[0]);}
    }
    if(collapse===null&&DEFAULT_COLLAPSE){collapse=DEFAULT_COLLAPSE;}
    if(marker&&marker.hasAttribute("data-code-window-lines-label")){
      var spec=marker.getAttribute("data-code-window-lines-label");
      marker.removeAttribute("data-code-window-lines-label");
      var titleBar=el.querySelector(".code-with-filename-file");
      if(titleBar&&!titleBar.querySelector(".code-with-filename-lines")){
        var chip=document.createElement("span");
        chip.className="code-with-filename-lines";
        chip.textContent="L"+spec;
        titleBar.appendChild(chip);
      }
    }
    if(collapse&&!el.classList.contains("code-window-collapsible")){
      var titleBar=el.querySelector(".code-with-filename-file");
      if(titleBar){
        var details=document.createElement("details");
        details.className=el.className+" code-window-collapsible";
        if(collapse==="open"){details.open=true;}
        var summaryEl=document.createElement("summary");
        summaryEl.className="code-with-filename-file";
        while(titleBar.firstChild){summaryEl.appendChild(titleBar.firstChild);}
        titleBar.parentNode.removeChild(titleBar);
        details.appendChild(summaryEl);
        while(el.firstChild){details.appendChild(el.firstChild);}
        el.parentNode.replaceChild(details,el);
      }
    }
  });
});]=], default_collapse_js, default_style)
end

--- Load configuration and inject CSS/JS dependencies.
function Meta(meta)
  CURRENT_FORMAT = pdoc.get_quarto_format()
  local opts = meta_mod.get_options({
    extension = EXTENSION_NAME,
    keys = { 'enabled', 'auto-filename', 'style', 'wrapper', 'collapse', 'lines-label' },
    meta = meta,
    defaults = DEFAULTS,
  })

  if not VALID_STYLES[opts['style']] then
    log.log_warning(EXTENSION_NAME,
      string.format('Unknown style "%s", falling back to "macos".', opts['style']))
  end

  local global_collapse = resolve_collapse(opts['collapse'])

  -- Read code-annotations metadata (Quarto standard option).
  local annot_meta = meta['code-annotations']
  local annot_value = annot_meta and pandoc.utils.stringify(annot_meta) or ''
  local annotations_enabled = annot_value ~= 'none' and annot_value ~= 'false'

  -- Read hotfix sub-table from extensions.code-window.hotfix.
  local ext_config = meta_mod.get_extension_config(meta, EXTENSION_NAME)
  local hotfix_meta = ext_config and ext_config['hotfix'] or nil

  -- Deprecation check for old flat skylighting-fix key.
  if ext_config and ext_config['skylighting-fix'] ~= nil then
    log.log_warning(EXTENSION_NAME,
      '"skylighting-fix" is deprecated. Use "hotfix: { skylighting: true/false }" instead.')
  end

  -- Parse hotfix options with per-hotfix version-based auto-disable.
  -- Each hotfix value can be:
  --   boolean/string: true/false to enable/disable
  --   map: { enabled: true/false, quarto-version: "x.y.z" }
  local hotfix = {}
  for key, default in pairs(HOTFIX_DEFAULTS) do
    local entry = hotfix_meta and hotfix_meta[key]
    if entry ~= nil and pandoc.utils.type(entry) == 'table' then
      -- Map form: { enabled: bool, quarto-version: "x.y.z" }
      local enabled = true
      if entry['enabled'] ~= nil then
        enabled = pandoc.utils.stringify(entry['enabled']) == 'true'
      end
      local ver = entry['quarto-version']
      if ver then
        ver = pandoc.utils.stringify(ver)
        if ver ~= '' then
          local ok, threshold = pcall(pandoc.types.Version, ver)
          if ok and quarto.version >= threshold then
            enabled = false
          end
        end
      end
      hotfix[key] = enabled
    elseif entry ~= nil then
      -- Simple boolean/string form
      hotfix[key] = pandoc.utils.stringify(entry) == 'true'
    else
      hotfix[key] = default
    end
  end

  CONFIG = {
    enabled = opts['enabled'] == 'true',
    auto_filename = opts['auto-filename'] == 'true',
    style = VALID_STYLES[opts['style']] and opts['style'] or 'macos',
    typst_wrapper = opts['wrapper'],
    collapse = global_collapse,
    lines_label = opts['lines-label'] == 'true',
    hotfix_code_annotations = hotfix['code-annotations'],
    hotfix_skylighting = hotfix['skylighting'],
    hotfix_typst_title = hotfix['typst-title'],
    code_annotations = annotations_enabled,
  }

  -- Store hotfix state in metadata so the post-quarto typst-title-fix filter
  -- can read it (it runs as a separate filter and has no access to CONFIG).
  if not meta['_code-window-hotfix'] then
    meta['_code-window-hotfix'] = pandoc.MetaMap({})
  end
  meta['_code-window-hotfix']['typst-title'] = pandoc.MetaString(
    CONFIG.enabled and hotfix['typst-title'] and 'true' or 'false'
  )

  -- Cache syntax highlighting background colour for Typst contrast-aware annotations.
  if CURRENT_FORMAT == 'typst' then
    local hm = PANDOC_WRITER_OPTIONS and PANDOC_WRITER_OPTIONS.highlight_method
    if hm then
      local bg = hm['background-color']
      if bg and type(bg) == 'string' then
        TYPST_BG_COLOUR = bg
      end
    end
  end

  if CURRENT_FORMAT == 'html' and CONFIG.enabled then
    html_mod.ensure_html_dependency({
      name = EXTENSION_NAME,
      version = '0.1.0',
      stylesheets = { 'style.css' },
    })
    html_mod.ensure_html_dependency({
      name = EXTENSION_NAME .. '-style-init',
      version = '0.1.0',
      head = '<script>' .. make_style_js(CONFIG.style, CONFIG.collapse) .. '</script>',
    })
  end

  return meta
end

--- Process CodeBlock elements for HTML/Reveal.js only.
--- Typst processing is handled by the Blocks filter.
function CodeBlock(block)
  if not CURRENT_FORMAT or not CONFIG or not CONFIG.enabled then
    block.attributes['code-window-no-auto-filename'] = nil
    return block
  end

  if CURRENT_FORMAT == 'html' then
    return process_html(block)
  end

  return block
end

-- ============================================================================
-- TYPST BLOCKS FILTER
-- ============================================================================

--- Determine whether a CodeBlock should get code-window chrome.
--- @param block pandoc.CodeBlock
--- @return string|nil filename
--- @return boolean is_auto
--- @return string|nil block_style
--- @return boolean window_opted_out True when code-window-enabled="false" was set
--- @return string|nil lines_label Highlighted-lines spec for the title bar
local function resolve_window_params(block)
  -- Per-block opt-out: code-window-enabled="false" skips window chrome.
  local block_enabled = block.attributes['code-window-enabled']
  if block_enabled then
    block.attributes['code-window-enabled'] = nil
  end
  if block_enabled == 'false' then
    return nil, false, nil, true, nil
  end

  local block_style = read_block_style(block)
  local explicit_filename = block.attributes['filename']
  local filename = explicit_filename
  local is_auto = false
  local no_auto = block.attributes['code-window-no-auto-filename']
  if no_auto then
    block.attributes['code-window-no-auto-filename'] = nil
  end

  if (not filename or filename == '') and not no_auto then
    if CONFIG.auto_filename and block.classes and #block.classes > 0 then
      -- Default/unknown/no-language blocks carry their label on
      -- code-window-auto-label; everything else uses its language class.
      filename = block.attributes['code-window-auto-label'] or block.classes[1]
      block.attributes['code-window-auto-label'] = nil
      is_auto = true
    end
  end

  local lines_label = nil
  if CONFIG.lines_label then
    lines_label = read_block_lines_label(block)
  end

  return filename, is_auto, block_style, false, lines_label
end

--- Process a single CodeBlock for Typst, returning replacement blocks.
--- Handles both code-window wrapping and standalone annotation rendering.
--- @param block pandoc.CodeBlock
--- @param next_block pandoc.Block|nil The block following this CodeBlock
--- @return pandoc.List replacement_blocks Blocks to splice in
--- @return boolean consumed_next Whether the next block was consumed
--- @return integer|nil annotation_block_id Block ID if annotations were found (for parent propagation)
local function process_typst_block(block, next_block)
  local filename, is_auto, block_style, window_opted_out, lines_label = resolve_window_params(block)
  local has_window = filename and filename ~= ''
  local effective_style = block_style or CONFIG.style

  -- Resolve annotations if enabled and the code-annotations hot-fix is active.
  local annotations = nil
  local should_handle_annotations = CONFIG.code_annotations and CONFIG.hotfix_code_annotations

  if should_handle_annotations then
    local cleaned_text
    cleaned_text, annotations = code_annotations.resolve_annotations(block)
    if annotations then
      block.text = cleaned_text
    end
  end

  -- Strip filename attribute so the CodeBlock renders as plain code inside the
  -- code-window wrapper (the DecoratedCodeBlock Div is already unwrapped above).
  if has_window and block.attributes['filename'] then
    block.attributes['filename'] = nil
  end

  local has_annotations = annotations and next(annotations)
  local consumed_next = false
  local result = {}
  local block_id = has_annotations and next_block_id() or 0

  if has_window and has_annotations then
    table.insert(result, typst_code_window_open(
      filename, is_auto, effective_style, annotations, block_id, lines_label))
    table.insert(result, block)
    table.insert(result, pandoc.RawBlock('typst', ']'))
  elseif has_window then
    table.insert(result, typst_code_window_open(
      filename, is_auto, effective_style, nil, 0, lines_label))
    table.insert(result, block)
    table.insert(result, pandoc.RawBlock('typst', ']'))
  elseif has_annotations then
    local open, close = typst_annotation_wrapper(annotations, block_id)
    table.insert(result, open)
    table.insert(result, block)
    table.insert(result, close)
  else
    table.insert(result, block)
  end

  -- Consume the following OrderedList if it is an annotation list.
  if has_annotations
      and next_block
      and code_annotations.is_annotation_ordered_list(next_block) then
    local wrapper_prefix = CONFIG.typst_wrapper
    local annot_blocks = code_annotations.ordered_list_to_typst_blocks(
      next_block, wrapper_prefix, block_id)
    for _, ab in ipairs(annot_blocks) do
      table.insert(result, ab)
    end
    consumed_next = true
  end

  local returned_block_id = has_annotations and (not consumed_next) and block_id or nil
  return result, consumed_next, returned_block_id
end

--- Check if a Div is Quarto's DecoratedCodeBlock wrapper.
--- @param div pandoc.Div
--- @return boolean
local function is_decorated_codeblock(div)
  return div.attributes['__quarto_custom_type'] == 'DecoratedCodeBlock'
end

--- Extract the CodeBlock from a DecoratedCodeBlock Div.
--- Structure: DecoratedCodeBlock Div > scaffold Div > CodeBlock
--- @param div pandoc.Div
--- @return pandoc.CodeBlock|nil
local function extract_codeblock(div)
  for _, child in ipairs(div.content) do
    if child.t == 'CodeBlock' then
      return child
    elseif child.t == 'Div' then
      local found = extract_codeblock(child)
      if found then return found end
    end
  end
  return nil
end

--- Read the filename from Quarto's internal custom node registry for a
--- DecoratedCodeBlock Div. Quarto stores the #| filename: value there rather
--- than as a plain Pandoc attribute on the inner CodeBlock.
--- @param div pandoc.Div A DecoratedCodeBlock Div
--- @return string|nil filename, or nil when the data is unavailable
local function get_decorated_codeblock_filename(div)
  local custom_id = div.attributes['__quarto_custom_id']
  if not custom_id then return nil end
  if not (_quarto and _quarto.ast and _quarto.ast.custom_node_data) then return nil end
  local entry = _quarto.ast.custom_node_data[custom_id]
  if type(entry) == 'table' and entry.filename and entry.filename ~= '' then
    return entry.filename
  end
  return nil
end

--- Process a flat list of blocks for Typst, handling CodeBlocks and their
--- following OrderedLists. Called recursively on Div contents.
--- @param blocks pandoc.Blocks|pandoc.List
--- @return pandoc.Blocks processed_blocks
--- @return integer|nil pending_annotation_block_id Block ID if the last block had annotations (for parent consumption)
local function process_typst_blocks(blocks, wrap_codeblocks)
  local new_blocks = {}
  local pending_annot_block_id = nil
  local i = 1
  while i <= #blocks do
    local blk = blocks[i]

    if blk.t == 'CodeBlock' then
      local next_blk = blocks[i + 1]
      local replacement, consumed_next, annot_id = process_typst_block(blk, next_blk)
      local to_insert = (wrap_codeblocks and #replacement > 1)
        and { pandoc.Div(replacement) } or replacement
      for _, rb in ipairs(to_insert) do
        table.insert(new_blocks, rb)
      end
      if consumed_next then
        pending_annot_block_id = nil
        i = i + 2
      else
        pending_annot_block_id = annot_id
        i = i + 1
      end
    elseif blk.t == 'Div' and is_decorated_codeblock(blk) then
      -- Unwrap Quarto's DecoratedCodeBlock to prevent double filename wrapping.
      -- Process the inner CodeBlock directly, replacing the entire Div.
      local inner_block = extract_codeblock(blk)
      if inner_block then
        -- Quarto stores the #| filename: value in its custom node registry, not as
        -- a plain Pandoc attribute on the inner CodeBlock. Transfer it here so
        -- resolve_window_params sees the explicit filename instead of falling back
        -- to auto-filename.
        if str.is_empty(inner_block.attributes['filename']) then
          local fn = get_decorated_codeblock_filename(blk)
          if fn then
            inner_block.attributes['filename'] = fn
          end
        end
        local next_blk = blocks[i + 1]
        local replacement, consumed_next, annot_id = process_typst_block(inner_block, next_blk)
        local to_insert = (wrap_codeblocks and #replacement > 1)
          and { pandoc.Div(replacement) } or replacement
        for _, rb in ipairs(to_insert) do
          table.insert(new_blocks, rb)
        end
        if consumed_next then
          pending_annot_block_id = nil
          i = i + 2
        else
          pending_annot_block_id = annot_id
          i = i + 1
        end
      else
        -- Fallback: keep the Div as-is if no CodeBlock found.
        local processed, inner_pending = process_typst_blocks(blk.content)
        blk.content = processed
        table.insert(new_blocks, blk)
        pending_annot_block_id = inner_pending
        i = i + 1
      end
    elseif blk.t == 'Div' then
      local is_layout = blk.attributes['layout-ncol']
        or blk.attributes['layout-nrow']
        or blk.attributes['layout']
      local processed, inner_pending = process_typst_blocks(blk.content, is_layout)
      blk.content = processed
      table.insert(new_blocks, blk)
      -- If the Div's last processed block had pending annotations,
      -- check if the next sibling is an OrderedList to consume.
      if inner_pending then
        local next_blk = blocks[i + 1]
        if next_blk and code_annotations.is_annotation_ordered_list(next_blk) then
          local annot_blocks = code_annotations.ordered_list_to_typst_blocks(
            next_blk, CONFIG.typst_wrapper, inner_pending)
          for _, ab in ipairs(annot_blocks) do
            table.insert(new_blocks, ab)
          end
          pending_annot_block_id = nil
          i = i + 2
        else
          pending_annot_block_id = inner_pending
          i = i + 1
        end
      else
        pending_annot_block_id = nil
        i = i + 1
      end
    elseif blk.t == 'BulletList' or blk.t == 'OrderedList' then
      for j, item in ipairs(blk.content) do
        blk.content[j] = process_typst_blocks(pandoc.Blocks(item))
      end
      table.insert(new_blocks, blk)
      pending_annot_block_id = nil
      i = i + 1
    elseif blk.t == 'BlockQuote' then
      blk.content = process_typst_blocks(blk.content)
      table.insert(new_blocks, blk)
      pending_annot_block_id = nil
      i = i + 1
    elseif blk.t == 'DefinitionList' then
      for j, def_item in ipairs(blk.content) do
        for k, body in ipairs(def_item[2]) do
          def_item[2][k] = process_typst_blocks(pandoc.Blocks(body))
        end
      end
      table.insert(new_blocks, blk)
      pending_annot_block_id = nil
      i = i + 1
    else
      pending_annot_block_id = nil
      table.insert(new_blocks, blk)
      i = i + 1
    end
  end
  return pandoc.Blocks(new_blocks), pending_annot_block_id
end

--- Walk HTML document blocks and transfer the filename from any DecoratedCodeBlock
--- outer Div to its inner CodeBlock, so process_html sees an explicit filename
--- and does not trigger auto-filename (which would otherwise produce a second
--- .code-with-filename wrapper alongside Quarto's own).
--- @param blocks pandoc.Blocks
--- @return pandoc.Blocks
local function fix_html_decorated_filenames(blocks)
  return blocks:walk({
    Div = function(div)
      if not is_decorated_codeblock(div) then return nil end
      local fn = get_decorated_codeblock_filename(div)
      if not fn then return nil end
      local inner_block = extract_codeblock(div)
      if inner_block and str.is_empty(inner_block.attributes['filename']) then
        inner_block.attributes['filename'] = fn
      end
      return div
    end
  })
end

--- Inject Typst function definition and process code blocks for Typst format.
--- Also repairs HTML DecoratedCodeBlock filename propagation.
--- Runs as a Pandoc filter to have full control over the document tree.
function Pandoc(doc)
  if not CONFIG or not CONFIG.enabled then
    return doc
  end

  -- For HTML: transfer filenames from DecoratedCodeBlock Divs to inner
  -- CodeBlocks before the CodeBlock filter runs, preventing auto-filename
  -- from adding a second .code-with-filename wrapper.
  if CURRENT_FORMAT == 'html' then
    doc.blocks = fix_html_decorated_filenames(doc.blocks)
    return doc
  end

  if CURRENT_FORMAT ~= 'typst' then
    return doc
  end

  -- Process code blocks and annotations throughout the document tree.
  doc.blocks = process_typst_blocks(doc.blocks)

  -- Guard: check if the function definition is already present.
  local fn_pattern = '#let ' .. CONFIG.typst_wrapper
  for _, blk in ipairs(doc.blocks) do
    if blk.t == 'RawBlock' and blk.format == 'typst'
        and blk.text:find(fn_pattern, 1, true) then
      return doc
    end
  end

  local has_hotfixes = CONFIG.hotfix_code_annotations or CONFIG.hotfix_skylighting
  local fn_def = build_typst_function_def(has_hotfixes)
  if CONFIG.typst_wrapper ~= 'code-window' then
    fn_def = fn_def:gsub('code%-window%-annote%-colour', CONFIG.typst_wrapper .. '-annote-colour')
    fn_def = fn_def:gsub('code%-window%-circled%-number', CONFIG.typst_wrapper .. '-circled-number')
    fn_def = fn_def:gsub('code%-window%-annotation%-item', CONFIG.typst_wrapper .. '-annotation-item')
    fn_def = fn_def:gsub('code%-window%-annotated%-content', CONFIG.typst_wrapper .. '-annotated-content')
    fn_def = fn_def:gsub('#let code%-window%(', '#let ' .. CONFIG.typst_wrapper .. '(')
  end
  table.insert(doc.blocks, 1, pandoc.RawBlock('typst', fn_def))

  return doc
end

-- ============================================================================
-- MODULE EXPORTS
-- ============================================================================

--- Inject the code-annotations module dependency.
--- Called by main.lua before any filter handlers run.
--- @param mod table The code-annotations module
local function set_code_annotations(mod)
  code_annotations = mod
end

return {
  set_code_annotations = set_code_annotations,
  Meta = Meta,
  Pandoc = Pandoc,
  CodeBlock = CodeBlock,
  CONFIG = function() return CONFIG end,
}
