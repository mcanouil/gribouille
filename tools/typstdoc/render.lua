local util = require("util")
local resolve = require("resolve")

local M = {}

local function yaml_escape(s)
  if not s then return "" end
  if s:find('[:"#]') or s:match("^%s") or s:match("%s$") then
    return string.format('"%s"', s:gsub('"', '\\"'))
  end
  return s
end

local function emit_frontmatter(fn)
  local lines = { "---" }
  table.insert(lines, "title: " .. yaml_escape(fn.name))
  if fn.doc.summary then
    table.insert(lines, "subtitle: " .. yaml_escape(fn.doc.summary))
  end
  if fn.doc.category then
    table.insert(lines, "category: " .. yaml_escape(fn.doc.category))
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
    return [[
::: {.callout-warning}
## Deprecated
This function is deprecated and may be removed in a future release.
:::
]]
  elseif stability == "experimental" then
    return [[
::: {.callout-note}
## Experimental
This function is experimental; its interface may change without notice.
:::
]]
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

local function format_signature(fn)
  if fn.is_value then
    return fn.name
  end
  local parts = {}
  for _, p in ipairs(fn.signature_params) do
    local piece
    if p.variadic then
      piece = ".." .. p.name
    elseif p.default then
      piece = p.name .. ": " .. p.default
    else
      piece = p.name
    end
    table.insert(parts, piece)
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
  local doc_by_name = {}
  for _, p in ipairs(fn.doc.params) do doc_by_name[p.name] = p end

  local out = { "## Parameters", "", "| Parameter | Default | Description |", "| --- | --- | --- |" }
  for _, p in ipairs(fn.signature_params) do
    local dp = doc_by_name[p.name]
    local name_cell = p.variadic and ("`.." .. p.name .. "`") or ("`" .. p.name .. "`")
    local default_cell = p.default and ("`" .. p.default .. "`") or ""
    local desc = dp and dp.description or ""
    desc = resolve.resolve_refs_in_text(desc, from_qmd, index, strict, fn.file, fn.line)
    desc = desc:gsub("|", "\\|")
    table.insert(out, string.format("| %s | %s | %s |", name_cell, default_cell, desc))
  end
  table.insert(out, "")
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

local function emit_examples(fn)
  if #fn.doc.examples == 0 then return "" end
  local out = { "## Examples", "" }
  local render_idx = 0
  for _, ex in ipairs(fn.doc.examples) do
    if ex.render then
      render_idx = render_idx + 1
      table.insert(out, "```{typst}")
      table.insert(out, string.format('//| output-filename: "/assets/typst-render/%s-%d.svg"',
        fn.name, render_idx))
      if ex.source ~= "" then
        table.insert(out, ex.source)
      end
    else
      table.insert(out, "```typst")
      if ex.source ~= "" then
        table.insert(out, ex.source)
      end
    end
    table.insert(out, "```")
    table.insert(out, "")
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
    emit_frontmatter(fn),
    emit_stability_callout(fn.doc.stability),
    emit_description(fn.doc.description, from_qmd, index, strict, fn.file, fn.line),
    emit_usage(fn),
    emit_arities(fn, from_qmd, index, strict),
    emit_params(fn, from_qmd, index, strict),
    emit_returns(fn, from_qmd, index, strict),
    emit_examples(fn),
    emit_see_also(fn, from_qmd, index, strict),
  }
  local body = table.concat(pieces, "\n")
  return body, from_qmd
end

function M.render_category_index(category, functions, modules)
  local cat_slug = util.slugify(category)
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
    table.insert(lines, para)
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
  table.sort(main, function(a, b) return a.name < b.name end)
  table.sort(advanced, function(a, b) return a.name < b.name end)

  if #main > 0 then
    table.insert(lines, "## Functions")
    table.insert(lines, "")
    for _, fn in ipairs(main) do
      table.insert(lines, string.format("- [`%s`](%s.qmd) - %s", fn.name, fn.name, fn.doc.summary))
    end
    table.insert(lines, "")
  end

  if #advanced > 0 then
    table.insert(lines, "::: {.callout-note collapse=\"true\"}")
    table.insert(lines, "## Advanced")
    table.insert(lines, "")
    for _, fn in ipairs(advanced) do
      table.insert(lines, string.format("- [`%s`](%s.qmd) - %s", fn.name, fn.name, fn.doc.summary))
    end
    table.insert(lines, ":::")
    table.insert(lines, "")
  end

  return table.concat(lines, "\n"), string.format("%s/index.qmd", cat_slug)
end

function M.render_top_index(category_order, functions)
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
      table.sort(fns, function(a, b) return a.name < b.name end)
      table.insert(lines, string.format("## [%s](%s/index.qmd)", cat, slug))
      table.insert(lines, "")
      for _, fn in ipairs(fns) do
        if not (fn.doc.is_internal or fn.doc.is_advanced) then
          table.insert(lines, string.format("- [`%s`](%s/%s.qmd) - %s", fn.name, slug, fn.name, fn.doc.summary))
        end
      end
      table.insert(lines, "")
    end
  end
  return table.concat(lines, "\n"), "index.qmd"
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
    "        - reference/index.qmd",
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
      table.sort(fns, function(a, b) return a.name < b.name end)
      table.insert(lines, string.format("        - section: %s", cat))
      table.insert(lines, string.format("          href: reference/%s/index.qmd", slug))
      table.insert(lines, "          contents:")
      for _, fn in ipairs(fns) do
        table.insert(lines, string.format("            - reference/%s/%s.qmd", slug, fn.name))
      end
    end
  end
  table.insert(lines, "")
  return table.concat(lines, "\n")
end

return M
