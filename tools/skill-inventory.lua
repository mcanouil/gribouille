#!/usr/bin/env lua

local function script_dir()
  local source = debug.getinfo(1, "S").source
  if source:sub(1, 1) == "@" then source = source:sub(2) end
  return source:match("^(.*)/[^/]+$") or "."
end

local ROOT = script_dir() .. "/.."
local LIB = ROOT .. "/lib.typ"
local SKILL = ROOT .. "/skills/gribouille/SKILL.md"
local BEGIN_MARK = "<!-- inventory:begin -->"
local END_MARK = "<!-- inventory:end -->"

local USAGE = [[
Usage: tools/skill-inventory.lua [--check]

Regenerates the symbol inventory in skills/gribouille/SKILL.md from the
public exports in lib.typ, splicing it between the inventory markers.

Modes:
  (default)  Rewrite the inventory block in place.
  --check    Exit non-zero if the block is stale; write nothing.
  --help     Show this help and exit.
]]

local function read_file(path)
  local handle, err = io.open(path, "r")
  if not handle then
    io.stderr:write(("skill-inventory: cannot read %s; %s.\n"):format(path, err))
    os.exit(1)
  end
  local text = handle:read("a")
  handle:close()
  return text
end

local function parse_groups(lib_text)
  local groups = {}
  local current = nil
  local pending = nil
  local lines = {}
  for line in (lib_text .. "\n"):gmatch("(.-)\n") do
    lines[#lines + 1] = line
  end
  local function add_symbols(chunk)
    for symbol in chunk:gmatch("[%w%-]+") do
      current.symbols[#current.symbols + 1] = symbol
    end
  end
  for _, line in ipairs(lines) do
    local family = line:match("^// ([A-Za-z][A-Za-z ]*)%.$")
    if family then
      pending = family
    elseif line:match("^#import ") then
      if pending then
        current = { name = pending, symbols = {} }
        groups[#groups + 1] = current
        pending = nil
      end
      if not current then
        io.stderr:write("skill-inventory: #import before any `// <Family>.` header in lib.typ.\n")
        os.exit(1)
      end
      local names = line:match('^#import "[^"]+": (.+)$')
      if names == "(" then
        current.open = true
      elseif names then
        add_symbols(names)
      end
    elseif current and current.open then
      if line:match("^%)") then
        current.open = false
      else
        add_symbols(line)
      end
    end
  end
  if #groups == 0 then
    io.stderr:write("skill-inventory: no export groups found in lib.typ.\n")
    os.exit(1)
  end
  return groups
end

local function render_block(groups)
  local out = {}
  for _, group in ipairs(groups) do
    local ticked = {}
    for i, symbol in ipairs(group.symbols) do
      ticked[i] = "`" .. symbol .. "`"
    end
    out[#out + 1] = ("- **%s**: %s."):format(group.name, table.concat(ticked, ", "))
  end
  return table.concat(out, "\n")
end

local function splice(skill_text, block)
  local _, begin_end = skill_text:find(BEGIN_MARK, 1, true)
  local end_start = skill_text:find(END_MARK, begin_end or 1, true)
  if not begin_end or not end_start then
    io.stderr:write(("skill-inventory: markers %s / %s not found in %s.\n"):format(BEGIN_MARK, END_MARK, SKILL))
    os.exit(1)
  end
  return skill_text:sub(1, begin_end) .. "\n\n" .. block .. "\n\n" .. skill_text:sub(end_start)
end

local check = false
for _, arg_value in ipairs(arg) do
  if arg_value == "--check" then
    check = true
  elseif arg_value == "--help" then
    io.write(USAGE)
    os.exit(0)
  else
    io.stderr:write(("skill-inventory: unknown argument %q.\n%s"):format(arg_value, USAGE))
    os.exit(2)
  end
end

local skill_text = read_file(SKILL)
local updated = splice(skill_text, render_block(parse_groups(read_file(LIB))))

if updated == skill_text then
  io.write("skill inventory: ok\n")
  os.exit(0)
end

if check then
  io.stderr:write("skill inventory: STALE; run `lua tools/skill-inventory.lua` to regenerate.\n")
  os.exit(1)
end

local handle, err = io.open(SKILL, "w")
if not handle then
  io.stderr:write(("skill-inventory: cannot write %s; %s.\n"):format(SKILL, err))
  os.exit(1)
end
handle:write(updated)
handle:close()
io.write("skill inventory: updated\n")
