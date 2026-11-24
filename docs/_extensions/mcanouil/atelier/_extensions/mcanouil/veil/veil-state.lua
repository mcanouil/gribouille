--- Veil - State module
--- @module "veil-state"
--- @license MIT License
--- @copyright 2026 Mickaël Canouil
--- @author Mickaël Canouil
--- @brief Pure state logic: ladder, independent groups, state text.
--- @description Has no dependency and no Quarto API. The JavaScript twin
--- `veil-state.js` follows the same rules, and both run the same test cases.

local M = {}

--- The pattern that a group name must match
M.NAME_PATTERN = '^[a-z][a-z0-9_-]*$'

--- The class that marks a veiled element
M.VEIL_CLASS = 'veil'

--- The attribute that holds the groups of a veiled element
M.GROUP_ATTRIBUTE = 'group'

--- The group of a veiled element that has no `group` attribute
M.DEFAULT_GROUP = 'veil'

--- Read the group names of a `group` attribute value, without checking them
--- @param value string|nil The value of the `group` attribute
--- @return table names The names, `{ DEFAULT_GROUP }` when the value is empty
function M.parse_groups(value)
  local names = {}
  for name in (value or ''):gmatch('%S+') do
    names[#names + 1] = name
  end
  if #names == 0 then
    names[1] = M.DEFAULT_GROUP
  end
  return names
end

--- A valid group name close to a name that is not valid
--- @param name string
--- @return string suggestion
function M.suggest_name(name)
  local suggestion = (name:lower():gsub('[^a-z0-9_-]', '-'))
  if not suggestion:match('^[a-z]') then
    suggestion = 'g-' .. suggestion
  end
  return suggestion
end
--- Sort a list of numbers in place and remove duplicates
--- @param values table
--- @return table
local function sorted_unique(values)
  table.sort(values)
  local result = {}
  for _, value in ipairs(values) do
    if result[#result] ~= value then
      result[#result + 1] = value
    end
  end
  return result
end

--- Sorted names of a map or a set
--- @param map table
--- @return table
function M.sorted_names(map)
  local keys = {}
  for key, _ in pairs(map) do
    keys[#keys + 1] = key
  end
  table.sort(keys)
  return keys
end

--- Copy a resolved state
--- @param resolved table
--- @return table
local function copy(resolved)
  local result = {
    levels = {},
    setting = resolved.setting,
    ladder = {},
    independent = {},
  }
  for i, level in ipairs(resolved.levels) do
    result.levels[i] = level
  end
  for name, level in pairs(resolved.ladder) do
    result.ladder[name] = level
  end
  for name, shown in pairs(resolved.independent) do
    result.independent[name] = shown
  end
  return result
end

--- The highest declared level that is not above a value, or 0
--- @param levels table
--- @param value number
--- @return number
local function highest_level_up_to(levels, value)
  local result = 0
  for _, level in ipairs(levels) do
    if level <= value then
      result = level
    end
  end
  return result
end

--- Build the resolved state from the groups of the options
--- @param groups table List of `{ name, level|nil, shown, label }`
--- @return table Resolved state
--- @return table Warnings
function M.initial(groups)
  local resolved = { levels = {}, setting = 0, ladder = {}, independent = {} }
  local warnings = {}
  local levels = {}
  for _, group in ipairs(groups) do
    if group.level then
      local level = math.floor(group.level)
      resolved.ladder[group.name] = level
      levels[#levels + 1] = level
      if group.shown and level > resolved.setting then
        resolved.setting = level
      end
    else
      resolved.independent[group.name] = group.shown and true or false
    end
  end
  resolved.levels = sorted_unique(levels)
  for _, group in ipairs(groups) do
    if group.level and not group.shown and resolved.ladder[group.name] <= resolved.setting then
      warnings[#warnings + 1] = string.format(
        'The group "%s" is hidden but a group above it is shown; the filter shows it.',
        group.name
      )
    end
  end
  return resolved, warnings
end

--- Apply a state text to a resolved state
--- @param resolved table
--- @param text string
--- @return table New resolved state
--- @return table Unknown tokens
function M.apply(resolved, text)
  local result = copy(resolved)
  local unknown = {}
  local level_tokens = {}
  local name_tokens = {}
  for raw in string.gmatch(text or '', '[^,]+') do
    local token = raw:match('^%s*(.-)%s*$')
    if token ~= '' then
      local digits = token:match('^level:(%d+)$')
      if digits then
        level_tokens[#level_tokens + 1] = tonumber(digits)
      else
        name_tokens[#name_tokens + 1] = token
      end
    end
  end
  if #level_tokens > 0 then
    result.setting = highest_level_up_to(result.levels, level_tokens[#level_tokens])
  end
  for _, token in ipairs(name_tokens) do
    local name = token:gsub('^%-', '')
    local hide = token:sub(1, 1) == '-'
    if result.ladder[name] then
      -- A ladder group is set by `level:S` only.
    elseif result.independent[name] ~= nil then
      result.independent[name] = not hide
    else
      unknown[#unknown + 1] = token
    end
  end
  return result, unknown
end

--- Format the full state
--- @param resolved table
--- @return string
function M.format(resolved)
  local tokens = {}
  if #resolved.levels > 0 then
    tokens[#tokens + 1] = 'level:' .. tostring(resolved.setting)
  end
  for _, name in ipairs(M.sorted_names(resolved.independent)) do
    tokens[#tokens + 1] = (resolved.independent[name] and '' or '-') .. name
  end
  return table.concat(tokens, ',')
end

--- Whether a veiled element is visible: all its groups are shown
--- A group that the state does not know counts as shown.
--- @param resolved table
--- @param names table
--- @return boolean
function M.visible(resolved, names)
  for _, name in ipairs(names) do
    local level = resolved.ladder[name]
    if level then
      if level > resolved.setting then
        return false
      end
    elseif resolved.independent[name] == false then
      return false
    end
  end
  return true
end

--- The highest declared level below a level, or 0
--- @param resolved table
--- @param level number
--- @return number
function M.previous_level(resolved, level)
  local previous = 0
  for _, value in ipairs(resolved.levels) do
    if value < level then
      previous = value
    end
  end
  return previous
end

--- Move the ladder setting to the next or previous declared level
--- @param resolved table
--- @param direction number `1` for level-up, `-1` for level-down
--- @return table New resolved state
function M.step(resolved, direction)
  local result = copy(resolved)
  if direction > 0 then
    for _, level in ipairs(result.levels) do
      if level > result.setting then
        result.setting = level
        break
      end
    end
  else
    result.setting = M.previous_level(result, result.setting)
  end
  return result
end

return M
