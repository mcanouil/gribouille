local util = require("util")
local resolve = require("resolve")
local model = require("model")

local M = {}

local function yaml_escape(s)
  if not s then return "" end
  if s:find('[:"#`%[]') or s:match("^%s") or s:match("%s$") then
    return string.format('"%s"', s:gsub('"', '\\"'))
  end
  return s
end

local function resolved_summary(fn, from_qmd, index, strict)
  return resolve.resolve_refs_in_text(fn.doc.summary, from_qmd, index, strict, fn.file, fn.line)
end

local function by_name(a, b) return a.name < b.name end

-- Split a function list into the ones with no @subcategory (kept directly under
-- the category) and named groups (one per distinct @subcategory). Groups and the
-- functions inside them are alphabetically ordered for stable output; a list with
-- no @subcategory tags yields an empty `groups`, so callers fall back to today's
-- flat rendering unchanged.
local function group_by_subcategory(fns)
  local ungrouped = {}
  local by_sub = {}
  local order = {}
  for _, fn in ipairs(fns) do
    local sub = fn.doc and fn.doc.subcategory
    if sub then
      if not by_sub[sub] then
        by_sub[sub] = {}
        table.insert(order, sub)
      end
      table.insert(by_sub[sub], fn)
    else
      table.insert(ungrouped, fn)
    end
  end
  table.sort(ungrouped, by_name)
  table.sort(order)
  local groups = {}
  for _, name in ipairs(order) do
    local g = by_sub[name]
    table.sort(g, by_name)
    table.insert(groups, { name = name, fns = g })
  end
  return { ungrouped = ungrouped, groups = groups }
end

local function emit_frontmatter(fn, from_qmd, index, strict)
  local lines = { "---" }
  table.insert(lines, "title: " .. yaml_escape(fn.name))
  if fn.doc.summary then
    table.insert(lines, "subtitle: " .. yaml_escape(resolved_summary(fn, from_qmd, index, strict)))
  end
  if fn.doc.category then
    table.insert(lines, "category: " .. yaml_escape(fn.doc.category))
  end
  if fn.doc.subcategory then
    table.insert(lines, "subcategory: " .. yaml_escape(fn.doc.subcategory))
  end
  if fn.doc.stability and fn.doc.stability ~= "stable" then
    table.insert(lines, "stability: " .. yaml_escape(fn.doc.stability))
  end
  if fn.doc.since then
    table.insert(lines, "since: " .. yaml_escape(fn.doc.since))
  end
  table.insert(lines, "engine: markdown")
  table.insert(lines, "---")
  table.insert(lines, "")
  return table.concat(lines, "\n")
end

local function emit_stability_callout(stability)
  if stability == "deprecated" then
    return "::: {.callout-warning}\n\n## Deprecated\n\nThis function is deprecated and may be removed in a future release.\n\n:::\n"
  elseif stability == "experimental" then
    return "::: {.callout-note}\n\n## Experimental\n\nThis function is experimental; its interface may change without notice.\n\n:::\n"
  end
  return ""
end

local function emit_description(desc, from_qmd, index, strict, file, line)
  if not desc or #desc == 0 then return "" end
  local out = {}
  for _, para in ipairs(desc) do
    table.insert(out, resolve.resolve_refs_in_text(para, from_qmd, index, strict, file, line))
    table.insert(out, "")
  end
  return table.concat(out, "\n")
end

-- A `..rest` binding is a pure forwarder when no `@param` shares its name: every
-- real argument is then documented individually rather than captured by the rest
-- binding, so the docs expand to those documented params instead of printing the
-- opaque `..rest`. A `@param` matching the rest name (whether or not it spells the
-- leading dots) means the rest binding is itself the documented surface, so it is
-- kept verbatim.
local function forwarding_variadic(fn)
  local variadic_name
  for _, p in ipairs(fn.signature_params) do
    if p.variadic then variadic_name = p.name end
  end
  if not variadic_name then return nil end
  for _, p in ipairs(fn.doc.params) do
    if p.name == variadic_name then return nil end
  end
  return variadic_name
end

local function named_param_piece(p)
  if p.default then return p.name .. ": " .. p.default end
  return p.name
end

local function format_signature(fn)
  if fn.is_value then
    return fn.name
  end
  local parts = {}
  if forwarding_variadic(fn) then
    local sig_by_name = {}
    for _, p in ipairs(fn.signature_params) do sig_by_name[p.name] = p end
    for _, p in ipairs(fn.doc.params) do
      local sig = sig_by_name[p.name]
      if sig and sig.default then
        table.insert(parts, p.name .. ": " .. sig.default)
      else
        table.insert(parts, p.name)
      end
    end
  else
    for _, p in ipairs(fn.signature_params) do
      if p.variadic then
        table.insert(parts, ".." .. p.name)
      else
        table.insert(parts, named_param_piece(p))
      end
    end
  end
  if #parts == 0 then
    return fn.name .. "()"
  end
  local joined = table.concat(parts, ",\n  ")
  return fn.name .. "(\n  " .. joined .. ",\n)"
end

local function emit_usage(fn)
  local out = { "## Usage", "" }
  if #fn.doc.arities > 0 then
    for _, arity in ipairs(fn.doc.arities) do
      table.insert(out, "```typst")
      table.insert(out, fn.name .. arity.signature)
      table.insert(out, "```")
      table.insert(out, "")
    end
  else
    table.insert(out, "```typst")
    table.insert(out, format_signature(fn))
    table.insert(out, "```")
    table.insert(out, "")
  end
  return table.concat(out, "\n")
end

local function emit_params(fn, from_qmd, index, strict)
  if fn.is_value or #fn.doc.params == 0 then return "" end

  local sig_by_name = {}
  local variadic_names = {}
  local has_variadic = false
  local variadic_name
  for _, p in ipairs(fn.signature_params) do
    sig_by_name[p.name] = p
    if p.variadic then has_variadic = true; variadic_names[p.name] = true; variadic_name = p.name end
  end

  -- `@named-keys` keys are documented in a sub-list under the table, not as rows;
  -- skip them (and their per-key `@param` overrides) here.
  local key_set = {}
  for _, k in ipairs(fn.doc.named_keys) do key_set[k] = true end

  -- A `..rest` binding in the signature forwards arbitrary kwargs, so the doc
  -- block (not the signature) enumerates the real parameters: a pure forwarder's
  -- delegate params, or explicit params plus the rest for a mixed signature. The
  -- matching signature param supplies the default where one exists.
  local rows = {}
  if has_variadic then
    for _, p in ipairs(fn.doc.params) do
      if not key_set[p.name] then
        local sig = sig_by_name[p.name]
        rows[#rows + 1] = {
          name = p.name,
          variadic = p.variadic or variadic_names[p.name] or false,
          default = sig and sig.default or nil,
          description = p.description,
        }
      end
    end
  else
    local doc_by_name = {}
    for _, p in ipairs(fn.doc.params) do doc_by_name[p.name] = p end
    for _, p in ipairs(fn.signature_params) do
      local dp = doc_by_name[p.name]
      rows[#rows + 1] = {
        name = p.name,
        variadic = p.variadic,
        default = p.default,
        description = dp and dp.description or "",
      }
    end
  end

  local out = { "## Parameters", "", "| Parameter | Default | Description |", "| --- | --- | --- |" }
  for _, r in ipairs(rows) do
    local name_cell = r.variadic and ("`.." .. r.name .. "`") or ("`" .. r.name .. "`")
    local default_cell = r.default and ("`" .. r.default .. "`") or ""
    local desc = resolve.resolve_refs_in_text(r.description or "", from_qmd, index, strict, fn.file, fn.line)
    desc = desc:gsub("|", "\\|")
    table.insert(out, string.format("| %s | %s | %s |", name_cell, default_cell, desc))
  end
  table.insert(out, "")

  -- A documented `@named-keys` sink lists its accepted keys as a real markdown
  -- sub-list below the table, so `@ref` links resolve (they would not inside a
  -- raw-HTML table cell).
  local named_keys = model.resolve_named_keys(fn.doc)
  if #named_keys > 0 and variadic_name then
    table.insert(out, string.format("Keys accepted by `..%s`:", variadic_name))
    table.insert(out, "")
    for _, k in ipairs(named_keys) do
      local desc = resolve.resolve_refs_in_text(k.description or "", from_qmd, index, strict, fn.file, fn.line)
      table.insert(out, string.format("- `%s`: %s", k.name, desc))
    end
    table.insert(out, "")
  end
  return table.concat(out, "\n")
end

local function emit_arities(fn, from_qmd, index, strict)
  if #fn.doc.arities == 0 then return "" end
  local out = { "## Arities", "" }
  for _, a in ipairs(fn.doc.arities) do
    local desc = resolve.resolve_refs_in_text(a.description, from_qmd, index, strict, fn.file, fn.line)
    table.insert(out, string.format("- `%s%s`: %s", fn.name, a.signature, desc))
  end
  table.insert(out, "")
  return table.concat(out, "\n")
end

local function emit_returns(fn, from_qmd, index, strict)
  if not fn.doc.returns then return "" end
  local out = {
    "## Returns",
    "",
    resolve.resolve_refs_in_text(fn.doc.returns, from_qmd, index, strict, fn.file, fn.line),
    "",
  }
  return table.concat(out, "\n")
end

local function emit_outputs(fn, stat_info)
  if not stat_info or not fn.doc or fn.doc.category ~= "Stats" then return "" end
  local bare = fn.name:match("^stat%-(.+)$")
  local entry = bare and stat_info[bare]
  if not entry then return "" end
  local out = { "## Outputs", "" }
  if #entry.outputs == 0 then
    table.insert(out, "This stat passes input rows through unchanged.")
    table.insert(out, "")
    return table.concat(out, "\n")
  end
  for _, col in ipairs(entry.outputs) do
    table.insert(out, string.format("- `%s`.", col))
  end
  table.insert(out, "")
  return table.concat(out, "\n")
end

local function emit_examples(fn, from_qmd, index, strict)
  if #fn.doc.examples == 0 then return "" end
  local out = { "## Examples", "" }
  local render_idx = 0
  local function emit_fence(open, source)
    table.insert(out, open)
    if source ~= "" then table.insert(out, source) end
    table.insert(out, "```")
    table.insert(out, "")
  end
  for _, ex in ipairs(fn.doc.examples) do
    for _, seg in ipairs(ex.segments) do
      if seg.kind == "prose" then
        if seg.text ~= "" then
          table.insert(out, resolve.resolve_refs_in_text(seg.text, from_qmd, index, strict, fn.file, fn.line))
          table.insert(out, "")
        end
      elseif seg.kind == "code" then
        emit_fence("```typst", seg.source)
        if ex.render then
          render_idx = render_idx + 1
          local attrs = seg.attributes or {}
          local alt = attrs.alt
          local header_lines = {
            "```{typst}",
            string.format('//| output-filename: "%s-%d.svg"', fn.name, render_idx),
          }
          if alt == nil or alt == "" then
            util.log_warn(string.format(
              "%s:%d: @examples fence %d for `%s` missing `//| alt: \"...\"`",
              fn.file, fn.line, render_idx, fn.name))
          else
            table.insert(header_lines, "//| alt: " .. alt)
          end
          emit_fence(table.concat(header_lines, "\n"), seg.source)
        end
      end
    end
  end
  return table.concat(out, "\n")
end

local function emit_see_also(fn, from_qmd, index, strict)
  if #fn.doc.see == 0 then return "" end
  local out = { "## See also", "" }
  local links = {}
  for _, ref in ipairs(fn.doc.see) do
    local name = ref:sub(2)
    local target = index[name]
    if target then
      local link = resolve.relative_link(from_qmd, target.qmd_path)
      table.insert(links, string.format("[`%s`](%s)", name, link))
    else
      if strict then
        error(string.format("typstdoc: unresolved @see `@%s` in %s:%d", name, fn.file, fn.line), 0)
      end
      util.log_warn(string.format("%s:%d: unresolved @see `@%s`", fn.file, fn.line, name))
      table.insert(links, "`" .. name .. "`")
    end
  end
  table.insert(out, table.concat(links, ", ") .. ".")
  table.insert(out, "")
  return table.concat(out, "\n")
end

function M.render_function(fn, index, opts)
  opts = opts or {}
  local strict = opts.strict
  local cat_slug = util.slugify(fn.doc.category)
  local from_qmd = string.format("%s/%s.qmd", cat_slug, fn.name)
  local pieces = {
    emit_frontmatter(fn, from_qmd, index, strict),
    emit_stability_callout(fn.doc.stability),
    emit_description(fn.doc.description, from_qmd, index, strict, fn.file, fn.line),
    emit_usage(fn),
    emit_arities(fn, from_qmd, index, strict),
    emit_params(fn, from_qmd, index, strict),
    emit_returns(fn, from_qmd, index, strict),
    emit_outputs(fn, opts.stat_info),
    emit_examples(fn, from_qmd, index, strict),
    emit_see_also(fn, from_qmd, index, strict),
  }
  local parts = {}
  for _, p in ipairs(pieces) do
    if p ~= "" then table.insert(parts, p) end
  end
  local body = table.concat(parts, "\n"):gsub("\n\n\n+", "\n\n"):gsub("\n+$", "\n")
  return body, from_qmd
end

function M.render_category_index(category, functions, modules, index, strict)
  local from_qmd = string.format("%s/index.qmd", util.slugify(category))
  local lines = {
    "---",
    "title: " .. yaml_escape(category),
    "---",
    "",
  }

  local module_desc = {}
  for _, mod in ipairs(modules or {}) do
    if mod.category == category then
      for _, para in ipairs(mod.description) do
        table.insert(module_desc, para)
      end
    end
  end
  for _, para in ipairs(module_desc) do
    table.insert(lines, resolve.resolve_refs_in_text(para, from_qmd, index, strict))
    table.insert(lines, "")
  end

  local main = {}
  local advanced = {}
  for _, fn in ipairs(functions) do
    if fn.doc and fn.doc.category == category then
      if fn.doc.is_internal or fn.doc.is_advanced then
        table.insert(advanced, fn)
      else
        table.insert(main, fn)
      end
    end
  end
  table.sort(advanced, by_name)

  local function emit_bullets(fns)
    for _, fn in ipairs(fns) do
      table.insert(lines, string.format("- [`%s`](%s.qmd) - %s", fn.name, fn.name, resolved_summary(fn, from_qmd, index, strict)))
    end
  end

  local grouped = group_by_subcategory(main)
  if #grouped.ungrouped > 0 then
    table.insert(lines, "## Functions")
    table.insert(lines, "")
    emit_bullets(grouped.ungrouped)
    table.insert(lines, "")
  end
  for _, g in ipairs(grouped.groups) do
    table.insert(lines, "## " .. g.name)
    table.insert(lines, "")
    emit_bullets(g.fns)
    table.insert(lines, "")
  end

  if #advanced > 0 then
    table.insert(lines, "::: {.callout-note collapse=\"true\"}")
    table.insert(lines, "")
    table.insert(lines, "## Advanced")
    table.insert(lines, "")
    emit_bullets(advanced)
    table.insert(lines, "")
    table.insert(lines, ":::")
    table.insert(lines, "")
  end

  return table.concat(lines, "\n"):gsub("\n\n\n+", "\n\n"):gsub("\n+$", "\n"), from_qmd
end

function M.render_top_index(category_order, functions, index, strict)
  local from_qmd = "index.qmd"
  local lines = {
    "---",
    "title: Reference",
    "---",
    "",
    "Every public function in the library, grouped by role.",
    "",
  }
  local by_cat = {}
  for _, fn in ipairs(functions) do
    if fn.doc and fn.doc.category then
      by_cat[fn.doc.category] = by_cat[fn.doc.category] or {}
      table.insert(by_cat[fn.doc.category], fn)
    end
  end
  for _, cat in ipairs(category_order) do
    local fns = by_cat[cat]
    if fns and #fns > 0 then
      local slug = util.slugify(cat)
      table.insert(lines, string.format("## [%s](%s/index.qmd)", cat, slug))
      table.insert(lines, "")
      local visible = {}
      for _, fn in ipairs(fns) do
        if not (fn.doc.is_internal or fn.doc.is_advanced) then
          table.insert(visible, fn)
        end
      end
      local function emit_bullets(list)
        for _, fn in ipairs(list) do
          table.insert(lines, string.format("- [`%s`](%s/%s.qmd) - %s", fn.name, slug, fn.name, resolved_summary(fn, from_qmd, index, strict)))
        end
      end
      local grouped = group_by_subcategory(visible)
      emit_bullets(grouped.ungrouped)
      for _, g in ipairs(grouped.groups) do
        table.insert(lines, "")
        table.insert(lines, "### " .. g.name)
        table.insert(lines, "")
        emit_bullets(g.fns)
      end
      table.insert(lines, "")
    end
  end
  return table.concat(lines, "\n"):gsub("\n\n\n+", "\n\n"):gsub("\n+$", "\n"), "index.qmd"
end

function M.render_sidebar(category_order, functions)
  local lines = {
    "# Reference sidebar (generated by typstdoc).",
    "website:",
    "  sidebar:",
    "    - id: reference",
    "      title: Reference",
    "      style: docked",
    "      align: left",
    "      collapse-level: 2",
    "      contents:",
    "        - section: Reference",
    "          href: reference/index.qmd",
    "          contents:",
  }
  local by_cat = {}
  for _, fn in ipairs(functions) do
    if fn.doc and fn.doc.category then
      by_cat[fn.doc.category] = by_cat[fn.doc.category] or {}
      table.insert(by_cat[fn.doc.category], fn)
    end
  end
  for _, cat in ipairs(category_order) do
    local fns = by_cat[cat]
    if fns and #fns > 0 then
      local slug = util.slugify(cat)
      table.insert(lines, string.format("            - section: %s", cat))
      table.insert(lines, string.format("              href: reference/%s/index.qmd", slug))
      table.insert(lines, "              contents:")
      local grouped = group_by_subcategory(fns)
      for _, fn in ipairs(grouped.ungrouped) do
        table.insert(lines, string.format("                - reference/%s/%s.qmd", slug, fn.name))
      end
      for _, g in ipairs(grouped.groups) do
        table.insert(lines, string.format("                - section: %s", yaml_escape(g.name)))
        table.insert(lines, "                  contents:")
        for _, fn in ipairs(g.fns) do
          table.insert(lines, string.format("                    - reference/%s/%s.qmd", slug, fn.name))
        end
      end
    end
  end
  table.insert(lines, "")
  return table.concat(lines, "\n")
end

return M
