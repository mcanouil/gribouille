--- Code Cell - Generic code-cell processing for Quarto Lua extensions
--- @module code-cell
--- @license MIT
--- @copyright 2026 Mickaël Canouil
--- @author Mickaël Canouil
--- @version 1.0.1
--- @brief Parses comment-pipe options, handles echo/eval/include/output logic,
---   manages output-location, and provides cross-referencing and prefix-aware
---   option resolution for custom executable code blocks.

local str = require(quarto.utils.resolve_path('_modules/string.lua'):gsub('%.lua$', ''))
local log = require(quarto.utils.resolve_path('_modules/logging.lua'):gsub('%.lua$', ''))

local M = {}

--- Valid output-location values for Reveal.js presentations
local VALID_OUTPUT_LOCATION_SET = {
  fragment = true,
  slide = true,
  column = true,
  ['column-fragment'] = true,
}

--- Create a code-cell processor bound to the given configuration.
--- @param config table Configuration with `language` (string) and `comment_prefix` (string)
--- @return table Table of bound methods
function M.new(config)
  if not config or not config.language or not config.comment_prefix then
    error("code-cell: config must include 'language' and 'comment_prefix' fields")
  end

  local language = config.language
  local comment_prefix = config.comment_prefix
  local escaped_prefix = str.escape_lua_pattern(comment_prefix)
  --- Line-comment characters used by code annotation markers (`<chars> <N>`).
  --- Distinct from `comment_prefix` (the comment-pipe prefix, e.g. `//|`).
  --- Defaults to `comment_prefix` with a trailing `|` removed (e.g. `//`).
  local comment_chars = config.comment_chars or (comment_prefix:gsub('|$', ''))
  local escaped_comment_chars = str.escape_lua_pattern(comment_chars)
  --- Anchored pattern matching a trailing annotation marker, e.g. ` // <1>`.
  local annotation_pattern = escaped_comment_chars .. '%s*<%d+>%s*$'
  --- Bare language identifier with any single outer `{...}` wrapper stripped
  --- (e.g. `{typst}` -> `typst`). Equals `language` when already brace-free.
  local class_name = language:match('^{(.-)}$') or language

  local cell = {}

  --- Check if a CodeBlock has the configured language class.
  --- Handles both `lang` and `{lang}` (Quarto markdown engine literal).
  --- @param el pandoc.CodeBlock
  --- @return boolean
  function cell.is_code_block(el)
    return el.classes:includes(language) or el.classes:includes('{' .. language .. '}')
  end

  --- Check if an inline Code element has the configured language class.
  --- Handles both class-based syntax (`code`{.lang}) and text-prefix
  --- syntax (`{lang} code`) where Pandoc does not assign a class.
  --- @param el pandoc.Code
  --- @return boolean
  function cell.is_inline_code(el)
    if el.classes:includes(language) or el.classes:includes('{' .. language .. '}') then
      return true
    end
    return el.text:match('^{' .. str.escape_lua_pattern(class_name) .. '}%s') ~= nil
  end

  --- Extract inline code text, stripping the `{lang} ` prefix if present.
  --- @param el pandoc.Code
  --- @return string The actual code content
  function cell.inline_code_text(el)
    if el.classes:includes(language) or el.classes:includes('{' .. language .. '}') then
      return el.text
    end
    return el.text:match('^{' .. str.escape_lua_pattern(class_name) .. '}%s+(.+)$') or el.text
  end

  --- Parse comment-pipe options from code block text.
  --- comment-pipe lines use `<prefix> key: value` syntax.
  --- @param text string The raw code block text
  --- @return table Options table
  --- @return string Cleaned code with comment-pipe lines removed
  --- @return table Raw comment-pipe lines for fenced echo output
  function cell.parse_options(text)
    local opts = {}
    local code_lines = {}
    local option_lines = {}
    local in_commentpipe = true
    local key_pattern = '^%s*' .. escaped_prefix .. '%s*([%w%-]+):%s*(.+)%s*$'

    for line in text:gmatch('[^\r\n]*') do
      if in_commentpipe then
        local key, value = line:match(key_pattern)
        if key then
          value = str.trim(value)
          if value == 'true' then
            opts[key] = true
          elseif value == 'false' then
            opts[key] = false
          else
            local unquoted = value:match('^"(.*)"$') or value:match("^'(.*)'$")
            opts[key] = unquoted or value
          end
          option_lines[#option_lines + 1] = line
        else
          in_commentpipe = false
          code_lines[#code_lines + 1] = line
        end
      else
        if line:match('^%s*' .. escaped_prefix .. '%s*[%w%-]+:%s') then
          log.log_warning(
            language,
            'Comment-pipe option "' .. str.trim(line) .. '" appears after code '
              .. 'and will be treated as code. Move all options to the top of the block.'
          )
        end
        code_lines[#code_lines + 1] = line
      end
    end

    return opts, table.concat(code_lines, '\n'), option_lines
  end

  --- Merge options with priority: block comment-pipe > global YAML > defaults.
  --- @param block_opts table Per-block comment-pipe options
  --- @param global_config table Global configuration from document metadata
  --- @param defaults table Default option values
  --- @return table Merged options
  function cell.merge_options(block_opts, global_config, defaults)
    local merged = {}
    for k, v in pairs(defaults) do
      merged[k] = v
    end
    for k, v in pairs(global_config) do
      merged[k] = v
    end
    for k, v in pairs(block_opts) do
      merged[k] = v
    end
    return merged
  end

  --- Check whether the source carries any code annotation markers.
  --- A marker is a trailing line comment of the form `<comment_chars> <N>`,
  --- matching the convention used by Quarto's code-annotations feature.
  --- @param code string The source code
  --- @return boolean true if at least one line ends with an annotation marker
  function cell.has_annotations(code)
    for line in code:gmatch('[^\r\n]*') do
      if line:match(annotation_pattern) then
        return true
      end
    end
    return false
  end

  --- Remove trailing code annotation markers from every line of the source.
  --- Strips in place so line terminators (including CRLF) are preserved.
  --- @param code string The source code
  --- @return string The source with `<comment_chars> <N>` markers stripped
  function cell.strip_annotations(code)
    return (code:gsub('[^\r\n]+', function(line)
      return (line:gsub('%s*' .. annotation_pattern, ''))
    end))
  end

  --- Create a source code listing block.
  --- When fenced is true, wraps the code with fenced code block markers and
  --- comment-pipe options to mimic Quarto's `echo: fenced` presentation.
  --- When fold or annotate is set, emits Quarto's native executable-cell shape
  --- (a `cell` Div wrapping a `cell-code` CodeBlock, with the rendered result as
  --- a sibling inside the cell) so that code-fold and code-annotations are handled
  --- by Quarto's own downstream passes. Otherwise emits a bare CodeBlock followed
  --- by the result. Annotation markers are stripped unless `annotate` is true.
  --- @param code string The source code
  --- @param fenced boolean Whether to show fenced code block markers
  --- @param option_lines table|nil Raw comment-pipe lines to include in fenced output
  --- @param fold table|nil `{ open = boolean, summary = string|nil }` for code-fold
  --- @param result pandoc.Block|nil Rendered output to place after/within the source
  --- @param annotate boolean|nil Keep annotation markers for Quarto to process
  --- @param line_numbers string|nil `code-line-numbers` value for Quarto to process
  ---   (e.g. `"true"` or `"1|3-4"`); attached to the language CodeBlock unless fenced
  --- @return pandoc.Blocks The source listing, optionally wrapped in a `cell` Div
  function cell.create_echo_block(code, fenced, option_lines, fold, result, annotate, line_numbers)
    if not annotate then
      code = cell.strip_annotations(code)
    end

    local text, classes
    if fenced then
      local meta_patterns = {
        '^%s*' .. escaped_prefix .. '%s*echo:%s*',
        '^%s*' .. escaped_prefix .. '%s*include:%s*',
        '^%s*' .. escaped_prefix .. '%s*output:%s*',
        '^%s*' .. escaped_prefix .. '%s*code%-fold:%s*',
        '^%s*' .. escaped_prefix .. '%s*code%-summary:%s*',
      }
      local lines = { '```{' .. class_name .. '}' }
      if option_lines then
        for _, line in ipairs(option_lines) do
          local is_meta = false
          for _, pat in ipairs(meta_patterns) do
            if line:match(pat) then
              is_meta = true
              break
            end
          end
          if not is_meta then
            lines[#lines + 1] = line
          end
        end
      end
      lines[#lines + 1] = code
      lines[#lines + 1] = '```'
      text = table.concat(lines, '\n')
      classes = { 'markdown' }
    else
      text = code
      classes = { class_name }
    end

    -- Line numbers attach only to the Typst source CodeBlock, never to the
    -- fenced `markdown` display (whose lines are the fence, not the source).
    local attrs = {}
    if line_numbers and not fenced then
      attrs['code-line-numbers'] = line_numbers
    end

    -- The native cell shape is required for code-fold (attribute-driven, gated
    -- to HTML by Quarto) and for code-annotations (markers linked downstream).
    if fold or annotate then
      classes[#classes + 1] = 'cell-code'
      if fold then
        attrs['code-fold'] = fold.open and 'show' or 'true'
        local summary = fold.summary
        if type(summary) == 'string' and str.trim(summary) ~= '' then
          attrs['code-summary'] = summary
        end
      end
      local inner = pandoc.CodeBlock(text, pandoc.Attr('', classes, attrs))
      local children = pandoc.Blocks({ inner })
      if result then
        children:insert(result)
      end
      return pandoc.Blocks({ pandoc.Div(children, pandoc.Attr('', { 'cell' }, {})) })
    end

    local blocks = pandoc.Blocks({ pandoc.CodeBlock(text, pandoc.Attr('', classes, attrs)) })
    if result then
      blocks:insert(result)
    end
    return blocks
  end

  --- Resolve and validate the output-location option.
  --- Returns the location string only when rendering to Reveal.js.
  --- @param opts table Merged options
  --- @param extension_name string The extension name for warning messages
  --- @return string|nil Valid location string, or nil
  function cell.resolve_output_location(opts, extension_name)
    local loc = opts['output-location']
    if not loc or loc == '' then
      return nil
    end
    if not quarto.doc.is_format('revealjs') then
      return nil
    end
    if not VALID_OUTPUT_LOCATION_SET[loc] then
      log.log_warning(
        extension_name,
        'Invalid output-location value: "' .. loc .. '". '
          .. 'Valid values: fragment, slide, column, column-fragment.'
      )
      return nil
    end
    return loc
  end

  --- Apply output-location wrapping for Reveal.js presentations.
  --- @param echo_block pandoc.Blocks|nil Echo blocks (nil when echo is off)
  --- @param result pandoc.Block The compiled output block
  --- @param location string The validated output-location value
  --- @return pandoc.Blocks Wrapped output blocks
  function cell.apply_output_location(echo_block, result, location)
    if location == 'column' or location == 'column-fragment' then
      if not echo_block then
        return pandoc.Blocks({ result })
      end
      local output_classes = location == 'column-fragment'
        and { 'column', 'fragment' }
        or { 'column' }
      local code_col = pandoc.Div(echo_block, pandoc.Attr('', { 'column' }, {}))
      local output_col = pandoc.Div(pandoc.Blocks({ result }), pandoc.Attr('', output_classes, {}))
      local wrapper = pandoc.Div(
        pandoc.Blocks({ code_col, output_col }),
        pandoc.Attr('', { 'columns', 'column-output-location' }, {})
      )
      return pandoc.Blocks({ wrapper })
    end

    local wrapper_class = location == 'slide' and 'output-location-slide' or 'fragment'
    local wrapped = pandoc.Div(pandoc.Blocks({ result }), pandoc.Attr('', { wrapper_class }, {}))
    if echo_block then
      local blocks = pandoc.Blocks({})
      blocks:extend(echo_block)
      blocks:insert(wrapped)
      return blocks
    end
    return pandoc.Blocks({ wrapped })
  end

  --- Extract the cross-reference type prefix from a label.
  --- For example, returns `"fig"` from `"fig-foo"`, or `nil` if no prefix.
  --- @param label string The label string
  --- @return string|nil The prefix, or nil if no valid ref type
  function cell.ref_type(label)
    if type(label) ~= 'string' or label == '' then
      return nil
    end
    return label:match('^(%a+)%-')
  end

  --- Resolve a prefix-aware option.
  --- Given a key (e.g. `"cap"`, `"alt"`, `"align"`), checks for the prefixed
  --- form first (e.g. `fig-cap`), then the plain form (e.g. `cap`).
  --- Only returns string values; boolean or other types are treated as absent.
  --- @param opts table Merged options (must contain `label` for prefix derivation)
  --- @param key string The option key to resolve
  --- @return string|nil The resolved string value, or nil if not found
  function cell.resolve_option(opts, key)
    local prefix = cell.ref_type(opts.label or '')
    if prefix then
      local prefixed = opts[prefix .. '-' .. key]
      if type(prefixed) == 'string' then
        return prefixed
      end
    end
    local plain = opts[key]
    if type(plain) == 'string' then
      return plain
    end
    return nil
  end

  --- Resolve the caption text for a labelled block.
  --- Uses `resolve_option` with key `"cap"`.
  --- @param opts table Merged options
  --- @return string Caption text (empty string if none)
  function cell.resolve_caption(opts)
    return cell.resolve_option(opts, 'cap') or ''
  end

  --- Resolve the alt text for a labelled block.
  --- Uses `resolve_option` with key `"alt"`, falling back to the provided value.
  --- @param opts table Merged options
  --- @param fallback string Fallback text if no alt is found (typically caption)
  --- @return string Alt text
  function cell.resolve_alt(opts, fallback)
    return cell.resolve_option(opts, 'alt') or fallback
  end

  --- Wrap a content block in a quarto.FloatRefTarget if a cross-ref label is present.
  --- @param content pandoc.Block The content block
  --- @param opts table Merged options
  --- @param ref_type_names table Map from prefix to Quarto FloatRefTarget type name
  --- @return pandoc.Block FloatRefTarget or the original content block
  function cell.wrap_crossref(content, opts, ref_type_names)
    local label = opts.label or ''
    local prefix = cell.ref_type(label)

    if prefix == nil then
      return content
    end

    local caption_text = cell.resolve_caption(opts)
    local caption_inlines = {}
    if caption_text ~= '' then
      caption_inlines = quarto.utils.string_to_inlines(caption_text)
    end

    local ref_type_name = ref_type_names[prefix]
      or (prefix:sub(1, 1):upper() .. prefix:sub(2))

    return quarto.FloatRefTarget({
      identifier = label,
      type = ref_type_name,
      content = pandoc.Blocks({ content }),
      caption_long = pandoc.Blocks({ pandoc.Plain(caption_inlines) }),
    })
  end

  --- Check whether the block should be included in the output.
  --- @param opts table Merged options
  --- @return boolean false when `opts.include` is explicitly false
  function cell.should_include(opts)
    return opts.include ~= false
  end

  --- Normalise the `output` option to a canonical string.
  --- @param opts table Merged options
  --- @return string `"true"`, `"false"`, or `"asis"`
  function cell.resolve_output_mode(opts)
    local val = opts.output
    if val == false then
      return 'false'
    end
    if val == 'asis' then
      return 'asis'
    end
    return 'true'
  end

  return cell
end

return M
