local util = require("util")

local M = {}

function M.build_index(functions, lib_info)
  local by_name = {}
  for _, fn in ipairs(functions) do
    if fn.doc and fn.doc.category then
      local cat_slug = util.slugify(fn.doc.category)
      by_name[fn.name] = {
        name = fn.name,
        category = fn.doc.category,
        category_slug = cat_slug,
        qmd_path = string.format("%s/%s.qmd", cat_slug, fn.name),
      }
    end
  end
  return by_name
end

function M.relative_link(from_qmd, target_qmd)
  if from_qmd == target_qmd then return "" end
  local from_dir = from_qmd:match("^(.*)/[^/]+$") or ""
  if from_dir == "" then
    return target_qmd
  end
  local from_parts = {}
  for part in from_dir:gmatch("[^/]+") do table.insert(from_parts, part) end
  local target_parts = {}
  for part in target_qmd:gmatch("[^/]+") do table.insert(target_parts, part) end

  local common = 0
  for i = 1, math.min(#from_parts, #target_parts - 1) do
    if from_parts[i] == target_parts[i] then
      common = i
    else
      break
    end
  end

  local ups = #from_parts - common
  local pieces = {}
  for _ = 1, ups do table.insert(pieces, "..") end
  for i = common + 1, #target_parts do table.insert(pieces, target_parts[i]) end
  return table.concat(pieces, "/")
end

function M.resolve_refs_in_text(text, from_qmd, index, strict, source_file, source_line)
  return (text:gsub("@([%w_%-]+)", function(name)
    local target = index[name]
    if not target then
      local msg = string.format("unresolved @ref `@%s`", name)
      if source_file then
        msg = string.format("%s:%d: %s", source_file, source_line or 0, msg)
      end
      if strict then error("typstdoc: " .. msg, 0) end
      util.log_warn(msg)
      return "@" .. name
    end
    local link = M.relative_link(from_qmd, target.qmd_path)
    return string.format("[`%s`](%s)", name, link)
  end))
end

return M
