-- Generate the theme key reference table from src/theme/defaults.typ and
-- src/theme/theme.typ. Single source of truth: extending the defaults dict
-- or the surface-parent map regenerates the table on the next typstdoc run.

local util = require("util")

local M = {}

-- Surfaces with explicit per-axis (`-x`, `-y`) and per-side (`-x-bottom`,
-- `-x-top`, `-y-left`, `-y-right`) variants. Mirrors the for-loop in
-- src/theme/theme.typ::_surface-parent.
local AXIS_FAMILIES = { "axis-text", "axis-title", "axis-line", "axis-ticks" }
local AXIS_VARIANT_SUFFIXES = { "-x", "-x-bottom", "-x-top", "-y", "-y-left", "-y-right" }

-- Scalars that share the same per-axis/per-side cascade as the axis families
-- but are stored outside the element-record system, so they aren't listed in
-- _surface-parent. Their parent map is reconstructed here.
local SCALAR_VARIANTS = { "tick-length" }

-- Identifier substitutions: source uses sys.inputs-driven placeholders that
-- collapse to these literals in standalone renders.
local IDENT_SUBSTITUTIONS = {
  ["_tr-ink"] = "black",
  ["_tr-paper"] = "white",
}

-- Keys carried in default-theme that don't correspond to user-facing surfaces
-- in the reference table.
local SKIP_KEYS = {
  kind = true,
  name = true,
}

-- Group order for the rendered table. Each group lists root keys; variants
-- expand inline beneath their root.
local GROUP_ORDER = {
  { name = "roots", keys = { "text", "line", "rect" } },
  { name = "plot", keys = { "plot-title", "plot-subtitle", "plot-caption", "plot-tag", "plot-background" } },
  { name = "axis", keys = { "axis-title", "axis-text", "axis-line", "axis-ticks" } },
  { name = "ticks", keys = { "tick-labels", "tick-length" } },
  { name = "panel", keys = { "panel-grid", "panel-background" } },
  { name = "legend", keys = { "legend-title", "legend-text", "legend-ticks", "legend-background", "legend-bar" } },
  { name = "strip", keys = { "strip-text", "strip-background" } },
  { name = "geom", keys = { "geom" } },
  { name = "colours", keys = { "ink", "paper", "accent" } },
}

local function strip_line_comment(line)
  local in_string = false
  local string_char
  local i = 1
  local len = #line
  while i <= len do
    local c = line:sub(i, i)
    if in_string then
      if c == "\\" and i < len then
        i = i + 2
      else
        if c == string_char then in_string = false end
        i = i + 1
      end
    elseif c == '"' or c == "'" then
      in_string = true
      string_char = c
      i = i + 1
    elseif c == "/" and line:sub(i + 1, i + 1) == "/" then
      return line:sub(1, i - 1)
    else
      i = i + 1
    end
  end
  return line
end

local function classify_value(raw)
  local expr = util.trim(raw)
  if expr:sub(-1) == "," then expr = util.trim(expr:sub(1, -2)) end
  if IDENT_SUBSTITUTIONS[expr] then
    return { kind = "colour", default = IDENT_SUBSTITUTIONS[expr] }
  end
  local ctor, args = expr:match("^(element%-[%w%-]+)%((.*)%)$")
  if ctor then
    args = util.trim(args)
    return { kind = ctor, default = args == "" and (ctor .. "()") or (ctor .. "(" .. args .. ")") }
  end
  ctor, args = expr:match("^(margin)%((.*)%)$")
  if ctor then
    args = util.trim(args)
    return { kind = "margin", default = args == "" and "margin()" or ("margin(" .. args .. ")") }
  end
  if expr:match("^rgb%(") or expr == "black" or expr == "white" then
    return { kind = "colour", default = expr }
  end
  if expr:match("^[%-%d%.]+[a-z]+$") then
    return { kind = "length", default = expr }
  end
  if expr == "true" or expr == "false" then
    return { kind = "boolean", default = expr }
  end
  return { kind = "unknown", default = expr }
end

function M.read_default_theme(path)
  local content, err = util.read_file(path)
  if not content then util.die("cannot read " .. path .. ": " .. tostring(err)) end
  local body = util.find_balanced_block(content, "#let%s+default%-theme%s*=%s*")
  if not body then util.die("default-theme block not found in " .. path) end
  local order = {}
  local entries = {}
  for raw in body:gmatch("[^\n]+") do
    local line = strip_line_comment(raw)
    local key, value = line:match("^%s*([%w%-]+):%s*(.+)$")
    if key and value then
      entries[key] = classify_value(value)
      table.insert(order, key)
    end
  end
  return order, entries
end

function M.read_surface_parent(path)
  local content, err = util.read_file(path)
  if not content then util.die("cannot read " .. path .. ": " .. tostring(err)) end
  local body = util.find_balanced_block(content, "#let%s+_surface%-parent%s*=%s*")
  if not body then util.die("_surface-parent block not found in " .. path) end
  local parents = {}
  for child, parent in body:gmatch('"([%w%-]+)"%s*:%s*"([%w%-]+)"') do
    parents[child] = parent
  end
  local function expand_variants(base)
    parents[base .. "-x"] = base
    parents[base .. "-y"] = base
    parents[base .. "-x-bottom"] = base .. "-x"
    parents[base .. "-x-top"] = base .. "-x"
    parents[base .. "-y-left"] = base .. "-y"
    parents[base .. "-y-right"] = base .. "-y"
  end
  for _, fam in ipairs(AXIS_FAMILIES) do expand_variants(fam) end
  for _, base in ipairs(SCALAR_VARIANTS) do expand_variants(base) end
  return parents
end

local function family_root(parents, key)
  local cur = key
  while parents[cur] do cur = parents[cur] end
  return cur
end

local function type_for(key, parents, defaults)
  local root = family_root(parents, key)
  if root == "text" then
    if key == "text" then return "@element-text" end
    return "@element-text or @element-typst"
  end
  if root == "line" then
    if key == "line" then return "@element-line" end
    return "@element-line or @element-blank"
  end
  if root == "rect" then
    if key == "rect" then return "@element-rect" end
    return "@element-rect or @element-blank"
  end
  local entry = defaults[key]
  if entry then
    if entry.kind == "colour" then return "colour" end
    if entry.kind == "length" then return "length" end
    if entry.kind == "boolean" then return "boolean" end
    if entry.kind == "margin" then return "@margin record" end
    -- Root-level element records with no base-record parent, e.g. `geom`.
    if entry.kind == "element-geom" then return "@element-geom" end
  end
  -- tick-length variants inherit from tick-length scalar.
  if key:match("^tick%-length") then return "length" end
  return "—"
end

local function default_for(key, defaults)
  local entry = defaults[key]
  if not entry then return "inherits" end
  return entry.default
end

local function has_variants(root)
  for _, fam in ipairs(AXIS_FAMILIES) do
    if fam == root then return true end
  end
  for _, base in ipairs(SCALAR_VARIANTS) do
    if base == root then return true end
  end
  return false
end

local function variant_keys_for(root)
  if not has_variants(root) then return {} end
  local out = {}
  for _, suf in ipairs(AXIS_VARIANT_SUFFIXES) do
    table.insert(out, root .. suf)
  end
  return out
end

function M.build_records(defaults, parents)
  local records = {}
  for _, group in ipairs(GROUP_ORDER) do
    for _, key in ipairs(group.keys) do
      if not SKIP_KEYS[key] then
        local parent = parents[key]
        table.insert(records, {
          key = key,
          type_str = type_for(key, parents, defaults),
          default_str = default_for(key, defaults),
          parent_str = parent or "(root)",
        })
        for _, child in ipairs(variant_keys_for(key)) do
          table.insert(records, {
            key = child,
            type_str = type_for(child, parents, defaults),
            default_str = default_for(child, defaults),
            parent_str = parents[child] or "(root)",
          })
        end
      end
    end
  end
  return records
end

-- default-theme keys (excluding the SKIP_KEYS book-keeping fields) that no row
-- in `records` covers. A non-empty result means GROUP_ORDER fell behind the
-- default theme and the table would silently omit a real element.
function M.uncovered_keys(defaults, records)
  local covered = {}
  for _, r in ipairs(records) do covered[r.key] = true end
  local missing = {}
  for key in pairs(defaults) do
    if not SKIP_KEYS[key] and not covered[key] then
      table.insert(missing, key)
    end
  end
  table.sort(missing)
  return missing
end

local function fmt_parent(p)
  if p == "(root)" then return "(root)" end
  return "`" .. p .. "`"
end

local function fmt_default(d)
  if d == "inherits" then return "inherits" end
  return "`" .. d .. "`"
end

function M.render_table(records)
  local out = {
    "| Key | Type | Default | Parent |",
    "| --- | --- | --- | --- |",
  }
  for _, r in ipairs(records) do
    table.insert(out, string.format(
      "| `%s` | %s | %s | %s |",
      r.key, r.type_str, fmt_default(r.default_str), fmt_parent(r.parent_str)))
  end
  return table.concat(out, "\n")
end

local cache = {}

function M.render(root)
  if cache[root] then return cache[root] end
  local _, defaults = M.read_default_theme(root .. "/src/theme/defaults.typ")
  local parents = M.read_surface_parent(root .. "/src/theme/theme.typ")
  local records = M.build_records(defaults, parents)
  local missing = M.uncovered_keys(defaults, records)
  if #missing > 0 then
    util.die("theme reference table omits default-theme key(s): "
      .. table.concat(missing, ", ")
      .. " (add them to GROUP_ORDER in tools/typstdoc/theme_keys.lua)")
  end
  local rendered = M.render_table(records)
  cache[root] = rendered
  return rendered
end

return M
