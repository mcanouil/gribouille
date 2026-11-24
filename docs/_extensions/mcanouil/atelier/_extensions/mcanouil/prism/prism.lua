--- Prism - Filter
--- @module "prism"
--- @license MIT License
--- @copyright 2026 Mickaël Canouil
--- @author Mickaël Canouil
--- @brief Promote attributes whose key prefix matches the active Quarto target format.
--- @description
---   Reads attributes whose key follows the `format:name` pattern on `Div`,
---   `Span`, `CodeBlock`, and `Header` elements.
---
---   The `format` prefix is matched against the Quarto target format,
---   resolved from `quarto.format.format_identifier()["target-format"]`
---   (falling back to the Pandoc `FORMAT` global). The target format is the
---   user-declared format name and includes Quarto custom formats, such as
---   `mcanouil-typst`.
---
---   A custom format also matches the prefix of its base format, read from
---   `quarto.format.format_identifier()["base-format"]`, so `typst:` applies
---   under `mcanouil-typst` and `html:` applies under `foo-html`. The custom
---   format name stays more specific: `mcanouil-typst:` wins over `typst:`
---   for the same attribute name. Matching is otherwise exact, so `html:`
---   targets HTML output without also affecting revealjs.
---
---   In addition to format names, the `slide` alias matches every HTML slide
---   format (revealjs, slidy, s5, dzslides, slideous), and every custom format
---   based on one of them, so `slide:` can target the whole group at once.
---
---   A `default:name` prefix provides a fallback value, applied only when no
---   format-specific variant of the same `name` matched the active format.
---
---   When the prefix matches, the attribute is re-emitted as `name="value"`
---   and the prefixed key is removed.
---   When the prefix does not match, the attribute is dropped.
---   Attributes whose key contains no colon are passed through unchanged.
---
---   The `typst:` prefix is shared with Pandoc's own Typst writer, which reads
---   `typst:text:<property>` on a div and a span and `typst:<parameter>` on a
---   div, and reads nothing on a code block or a heading. Whenever Pandoc
---   writes Typst those keys keep their prefix and pass through untouched,
---   rather than being promoted to a name no consumer reads. Every other
---   `typst:` key stays prism's, since the writer splices it unvalidated and
---   Typst rejects it. See <https://pandoc.org/typst-property-output.html>.
---
---   Precedence for a given `name`: exact format match > base format match >
---   alias match > default fallback > unprefixed pass-through.
---
---   Promoted attributes override static ones with the same name. When two
---   format-scoped attributes share the same target name on the same element
---   (e.g. two `html:style` keys), the last one in source order wins.
---
---   Unknown prefixes (neither the target format, its base format, a known
---   group alias, nor `default`) are treated as non-matching and the attribute is dropped.
---   Enable `extensions.prism.warn-on-drop` to emit a `quarto.log.warning`
---   each time a format-scoped attribute is dropped, which surfaces typos in
---   prefixes that would otherwise vanish silently.
---
---   The filter only inspects key-value attributes; classes and ids are left
---   untouched.
---
---   Usage:
---     ::: {html:style="font-size: 1.2rem;" revealjs:style="font-size: 2em;"}
---     Conditional content.
---     :::
---
---     ::: {slide:style="font-size: 2em;" default:style="font-size: 1rem;"}
---     Larger on every slide format, smaller everywhere else.
---     :::
---
---     ```{.r mcanouil-typst:width="50%"}
---     1 + 1
---     ```

--- Extension name constant, used to namespace log messages and metadata.
local EXTENSION_NAME = 'prism'

local slide_formats = require(quarto.utils.resolve_path('_modules/slide-formats.lua'):gsub('%.lua$', ''))
local log = require(quarto.utils.resolve_path('_vendor/quarto-lua-modules/logging.lua'):gsub('%.lua$', ''))
local schema = require(quarto.utils.resolve_path('_vendor/quarto-wizard/schema.lua'):gsub('%.lua$', ''))
local check = require(quarto.utils.resolve_path('_vendor/quarto-lua-modules/schema-check.lua'):gsub('%.lua$', ''))

--- The schema check, built once per render. It reads `_schema.yml` on the way
--- in and checks the document configuration once.
---
--- The validator is injected rather than required by the check module, so the
--- two vendored sources stay independent of where the other was placed.
---
--- The extension contributes a filter and no shortcode, so the check runs from
--- the `Meta` handler, which is the only place the document configuration is
--- read.
---
--- A schema that cannot be read is reported by the module as an error and the
--- render carries on: a configuration file must not stop a document.
local checker = check.new(schema, EXTENSION_NAME)

--- Read a format name from the Quarto format identifier, falling back when
--- the field is missing or empty.
--- Strips Pandoc format variants (e.g. `html+raw_attribute` -> `html`) so
--- prefixes can be written without flag suffixes.
--- @param key string The identifier field, e.g. "target-format".
--- @param fallback string The name to use when the field is missing or empty.
--- @return string
local function resolve_format(key, fallback)
  local ok, identifier = pcall(function()
    return quarto.format.format_identifier()
  end)
  local format = ok and type(identifier) == "table" and identifier[key] or nil
  if format == nil or format == "" then
    format = fallback
  end
  return format:match("^[^+]+") or format
end

--- The active Quarto target format name, e.g. `foo-html` for a custom format.
local TARGET_FORMAT = resolve_format("target-format", FORMAT)

--- The base format of the target, e.g. `html` for `foo-html`. Equal to
--- `TARGET_FORMAT` when the target is a built-in format.
local BASE_FORMAT = resolve_format("base-format", TARGET_FORMAT)

--- Whether Pandoc writes this render with its Typst writer.
--- Asks Quarto rather than the target format, because a custom format such as
--- `mcanouil-typst` is written by the same writer and reads the same `typst:`
--- attributes: its `target-format` is `mcanouil-typst` while `FORMAT`, which is
--- what `is_typst_output` tests, is `typst`.
--- @return boolean
local function resolve_writes_typst()
  local ok, result = pcall(function()
    return quarto.format.is_typst_output()
  end)
  if ok then
    return result == true
  end
  return FORMAT == 'typst'
end

local WRITES_TYPST = resolve_writes_typst()

--- The `default` prefix names a fallback value, applied only when no
--- format-specific variant of the same attribute name matched.
local DEFAULT_PREFIX = "default"

--- Aliases that match a group of formats rather than an exact format name.
--- Each value is the set of target formats the alias resolves to.
--- The `slide` set is sourced from the shared `_modules/slide-formats` module
--- so prism and portable-links agree on what counts as an HTML slide format.
--- @type table<string, table<string, boolean>>
local FORMAT_ALIASES = {
  slide = slide_formats.formats,
}

--- The parameters Typst's `block()` function accepts.
--- @type table<string, boolean>
local TYPST_BLOCK_PARAMETERS = {
  width = true,
  height = true,
  breakable = true,
  fill = true,
  stroke = true,
  radius = true,
  inset = true,
  outset = true,
  spacing = true,
  above = true,
  below = true,
  clip = true,
  sticky = true,
}

--- The one prefix that names a namespace Pandoc's own writer consumes.
--- @type string
local PANDOC_TYPST_PREFIX = 'typst'

--- Whether a `typst:` key names a set-text property, the `typst:text:<property>`
--- form Pandoc's Typst writer reads on both a div and a span.
--- @param name string The attribute key with the `typst:` prefix removed.
--- @return boolean
local function is_typst_text_property(name)
  return name:match('^text:') ~= nil
end

--- Whether Pandoc's Typst writer consumes this attribute on this element.
--- Per <https://pandoc.org/typst-property-output.html> the writer reads
--- `typst:text:<property>` as a set-text rule on a div and on a span, and
--- `typst:<parameter>` as an argument to `#block()` on a div alone. No other
--- nested function is recognised: `typst:par:leading` is dropped by the writer,
--- and code blocks and headings are not covered at all, so prism keeps those.
--- Promoting one of these would strip a prefix the writer is waiting for, and
--- the styling would be lost; a key outside the set fails the render natively
--- with `unexpected argument`, so prism claims it.
--- @param name string The attribute key with the `typst:` prefix removed.
--- @param element_type string The Pandoc element tag, e.g. "Div" or "Span".
--- @return boolean True when Pandoc consumes the attribute itself.
local function is_pandoc_typst_key(name, element_type)
  if element_type == 'Div' then
    return is_typst_text_property(name) or TYPST_BLOCK_PARAMETERS[name] == true
  end
  return element_type == 'Span' and is_typst_text_property(name)
end

--- Whether to emit a warning when a format-scoped attribute is dropped.
--- Set per document via `extensions.prism.warn-on-drop: true`.
--- @type boolean
local warn_on_drop = false

--- The rank of each match kind. A higher rank wins for the same name.
--- @type table<string, integer>
local MATCH_RANK = {
  exact = 3,
  base = 2,
  alias = 1,
}

--- Resolve how a prefix matches the active target format.
--- The target format name matches as "exact"; the base format of a custom
--- format matches as "base"; group aliases match when the target format or
--- its base format is a member of the alias set.
--- @param prefix string The attribute key prefix (the part before the colon).
--- @return "exact"|"base"|"alias"|nil The match kind, or nil when the prefix does not match.
local function match_prefix(prefix)
  if prefix == TARGET_FORMAT then
    return "exact"
  end
  if prefix == BASE_FORMAT then
    return "base"
  end
  local alias = FORMAT_ALIASES[prefix]
  if alias and (alias[TARGET_FORMAT] or alias[BASE_FORMAT]) then
    return "alias"
  end
  return nil
end

--- Describe an element for warning messages: prefer the id, then the first
--- class, then the element tag.
--- @param el pandoc.Div|pandoc.Span|pandoc.CodeBlock|pandoc.Header
--- @return string
local function describe_element(el)
  if el.identifier and el.identifier ~= '' then
    return '#' .. el.identifier
  end
  if el.classes and #el.classes > 0 then
    return '.' .. el.classes[1]
  end
  return el.t or 'element'
end

--- Rewrite the `attributes` table of an element by resolving format prefixes.
--- @param el pandoc.Div|pandoc.Span|pandoc.CodeBlock|pandoc.Header The element to process.
--- @return pandoc.Div|pandoc.Span|pandoc.CodeBlock|pandoc.Header|nil
local function process(el)
  if #el.attributes == 0 then
    return nil
  end

  local kept = {}
  local promoted_order = {}
  local promoted_value = {}
  local promoted_kind = {}
  local default_order = {}
  local default_value = {}
  local dropped = {}

  for _, kv in ipairs(el.attributes) do
    local key, value = kv[1], kv[2]
    local prefix, name = key:match("^([^:]+):(.+)$")
    if WRITES_TYPST and prefix == PANDOC_TYPST_PREFIX and is_pandoc_typst_key(name, el.t) then
      -- Pandoc's Typst writer reads this key itself, so it keeps its prefix and
      -- passes through untouched. Promoting it would leave a name neither the
      -- writer nor Quarto's CSS filter consumes, and the styling would vanish.
      -- Outside a Typst render the key falls through and is dropped as usual.
      table.insert(kept, { key, value })
    elseif prefix and name then
      if prefix == DEFAULT_PREFIX then
        if default_value[name] == nil then
          table.insert(default_order, name)
        end
        default_value[name] = value
      else
        local kind = match_prefix(prefix)
        -- A more specific match wins for the same name: exact, then base, then alias.
        if kind and MATCH_RANK[kind] >= (MATCH_RANK[promoted_kind[name]] or 0) then
          if promoted_value[name] == nil then
            table.insert(promoted_order, name)
          end
          promoted_value[name] = value
          promoted_kind[name] = kind
        elseif kind == nil then
          table.insert(dropped, key)
        end
      end
    else
      table.insert(kept, { key, value })
    end
  end

  -- A default fallback applies only when no format-specific variant of the
  -- same name matched the active target format.
  for _, name in ipairs(default_order) do
    if promoted_value[name] == nil then
      table.insert(promoted_order, name)
      promoted_value[name] = default_value[name]
    end
  end

  -- Drop static attributes whose name is also promoted, so the format-scoped
  -- value wins and Pandoc does not see a duplicate-attribute warning.
  -- Among promoted entries, the last source occurrence wins.
  local final = {}
  for _, kv in ipairs(kept) do
    if promoted_value[kv[1]] == nil then
      table.insert(final, kv)
    end
  end
  for _, name in ipairs(promoted_order) do
    table.insert(final, { name, promoted_value[name] })
  end

  if warn_on_drop and #dropped > 0 then
    log.log_warning(
      EXTENSION_NAME,
      "Dropped attribute(s) '" .. table.concat(dropped, "', '") ..
        "' on " .. describe_element(el) ..
        " because no prefix matched target format '" .. TARGET_FORMAT .. "'" ..
        (BASE_FORMAT ~= TARGET_FORMAT and " (base format '" .. BASE_FORMAT .. "')" or "") .. "."
    )
  end

  el.attributes = final
  return el
end

--- Read the `extensions.prism.warn-on-drop` option from document metadata.
--- @param meta table The document metadata table.
--- @return nil
local function read_options(meta)
  checker:options(meta)
  -- The schema decides what counts as true, so `warn-on-drop: no` turns the
  -- warning off. Reading the document itself left it on.
  warn_on_drop = checker:option('warn-on-drop') == true
  return nil
end

return {
  { Meta = read_options },
  { Div = process, Span = process, CodeBlock = process, Header = process }
}
