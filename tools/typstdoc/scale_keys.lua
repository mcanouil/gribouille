-- Cross-check the valid-key tuples in src/scale/bind.typ against the
-- builder signatures in the scale family files. bind-scale validates user
-- arguments against those tuples before spreading them into a builder, so a
-- builder parameter added or renamed without updating its tuple would make
-- the eager validation lie; this check fails the test run instead.

local M = {}

local FAMILY_FILES = {
  "src/scale/continuous.typ",
  "src/scale/discrete.typ",
  "src/scale/date.typ",
  "src/scale/colour.typ",
  "src/scale/size.typ",
  "src/scale/linewidth.typ",
  "src/scale/stroke.typ",
  "src/scale/shape.typ",
  "src/scale/linetype.typ",
}

local BIND_FILE = "src/scale/bind.typ"

-- Builders reached through adapters whose key tuple does not sit next to the
-- builder name in the dispatch table (see `_trans` / `_temporal` in bind.typ).
local IMPLICIT_PAIRS = {
  { builder = "_transform-scale", keys = "_POS-TRANSFORM-KEYS" },
  { builder = "_temporal-scale", keys = "_TEMPORAL-KEYS" },
}

local function read_file(path)
  local fh, err = io.open(path, "r")
  if not fh then error("scale_keys: cannot open " .. path .. ": " .. tostring(err)) end
  local text = fh:read("*a")
  fh:close()
  return text
end

-- Scan from the character after an opening `(` to its matching `)`,
-- respecting strings; returns the enclosed text.
local function balanced(text, open_idx)
  local depth = 1
  local i = open_idx + 1
  local len = #text
  local in_string = false
  while i <= len do
    local c = text:sub(i, i)
    if in_string then
      if c == "\\" then
        i = i + 1
      elseif c == '"' then
        in_string = false
      end
    elseif c == '"' then
      in_string = true
    elseif c == "(" then
      depth = depth + 1
    elseif c == ")" then
      depth = depth - 1
      if depth == 0 then return text:sub(open_idx + 1, i - 1) end
    end
    i = i + 1
  end
  error("scale_keys: unbalanced parentheses at offset " .. open_idx)
end

-- Named parameters (name preceding `:` at depth zero) of `#let name(...)`.
-- Leading bare positionals (`aesthetic`, `transform`, `temporal`) carry no
-- default and are skipped; they are adapter-injected, never user keys.
local function signature_named_params(text, name)
  local pattern = "#let%s+" .. name:gsub("%-", "%%-") .. "%s*%("
  local s, e = text:find(pattern)
  if not s then return nil end
  local body = balanced(text, e)
  local params = {}
  local depth = 0
  local in_string = false
  local start = 1
  local function take(part)
    local pname = part:match("^%s*([%w_%-]+)%s*:")
    if pname then table.insert(params, pname) end
  end
  for i = 1, #body do
    local c = body:sub(i, i)
    if in_string then
      if c == "\\" then --[[ skip escapes ]]
      elseif c == '"' then in_string = false end
    elseif c == '"' then
      in_string = true
    elseif c == "(" or c == "[" or c == "{" then
      depth = depth + 1
    elseif c == ")" or c == "]" or c == "}" then
      depth = depth - 1
    elseif c == "," and depth == 0 then
      take(body:sub(start, i - 1))
      start = i + 1
    end
  end
  take(body:sub(start))
  return params
end

-- All `#let _<NAME>-KEYS = ("a", "b", ...)` tuples in bind.typ.
local function key_tuples(text)
  local tuples = {}
  for name, open_idx in text:gmatch("#let%s+(_[%w%-]+%-KEYS)%s*=%s*()") do
    local body = balanced(text, open_idx)
    local keys = {}
    for key in body:gmatch('"([^"]+)"') do table.insert(keys, key) end
    tuples[name] = keys
  end
  return tuples
end

-- Builder-to-tuple associations written literally in the dispatch table:
-- `_aes(_builder, _X-KEYS)`, `_solo(...)`, `_cf(...)`.
local function dispatch_pairs(text)
  local pairs_ = {}
  for _, adapter in ipairs({ "_aes", "_solo", "_cf" }) do
    local pattern = adapter .. "%(%s*(_[%w%-]+)%s*,%s*(_[%w%-]+%-KEYS)"
    for builder, keys in text:gmatch(pattern) do
      table.insert(pairs_, { builder = builder, keys = keys })
    end
  end
  return pairs_
end

local function to_set(list)
  local set = {}
  for _, v in ipairs(list) do set[v] = true end
  return set
end

local function sorted_join(list)
  local copy = {}
  for _, v in ipairs(list) do table.insert(copy, v) end
  table.sort(copy)
  return table.concat(copy, ", ")
end

-- Compare every association; returns a list of human-readable mismatch
-- strings (empty when in sync).
function M.check(root)
  local bind_text = read_file(root .. "/" .. BIND_FILE)
  local tuples = key_tuples(bind_text)
  local associations = dispatch_pairs(bind_text)
  for _, pair in ipairs(IMPLICIT_PAIRS) do table.insert(associations, pair) end

  local family_texts = {}
  for _, path in ipairs(FAMILY_FILES) do
    table.insert(family_texts, { path = path, text = read_file(root .. "/" .. path) })
  end

  local problems = {}
  local seen = {}
  for _, assoc in ipairs(associations) do
    local id = assoc.builder .. "/" .. assoc.keys
    if not seen[id] then
      seen[id] = true
      local tuple = tuples[assoc.keys]
      if tuple == nil then
        table.insert(problems, assoc.keys .. " referenced for " .. assoc.builder .. " but not defined")
      else
        local params = nil
        for _, entry in ipairs(family_texts) do
          params = signature_named_params(entry.text, assoc.builder)
          if params then break end
        end
        if params == nil then
          table.insert(problems, assoc.builder .. " not found in any scale family file")
        else
          local tuple_set = to_set(tuple)
          local param_set = to_set(params)
          for _, key in ipairs(tuple) do
            if not param_set[key] then
              table.insert(problems, assoc.keys .. ' lists "' .. key .. '" but ' .. assoc.builder
                .. " has no such named parameter (has: " .. sorted_join(params) .. ")")
            end
          end
          for _, param in ipairs(params) do
            if not tuple_set[param] then
              table.insert(problems, assoc.builder .. ' has named parameter "' .. param .. '" missing from '
                .. assoc.keys .. " (lists: " .. sorted_join(tuple) .. ")")
            end
          end
        end
      end
    end
  end
  if #associations == 0 then
    table.insert(problems, "no builder/keys associations found in " .. BIND_FILE)
  end
  return problems
end

return M
