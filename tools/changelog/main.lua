local function script_dir()
  local source = debug.getinfo(1, "S").source
  if source:sub(1, 1) == "@" then source = source:sub(2) end
  return source:match("^(.*)/[^/]+$") or "."
end
local ROOT = script_dir() .. "/../.."

local INPUT = ROOT .. "/CHANGELOG.md"
local OUTPUT = ROOT .. "/docs/changelog.qmd"

local FRONT_MATTER = [[
---
title: "Changelog"
subtitle: "Version history."
toc: true
toc-depth: 2
---
]]

local FOOTER = [[
---

Looking for a specific change?
Browse the [full commit history](https://github.com/mcanouil/gribouille/commits/main) or the [list of releases](https://github.com/mcanouil/gribouille/releases) on GitHub.
]]

local UNRELEASED_OPEN = '::: {.content-visible when-profile="dev"}'
local UNRELEASED_CLOSE = ":::"

local function die(msg)
  io.stderr:write("tools/changelog: " .. msg .. "\n")
  os.exit(1)
end

local function read_file(path)
  local f, err = io.open(path, "r")
  if not f then die("cannot read " .. path .. ": " .. tostring(err)) end
  local content = f:read("*a")
  f:close()
  return content
end

local function write_file(path, content)
  local f, err = io.open(path, "w")
  if not f then die("cannot write " .. path .. ": " .. tostring(err)) end
  f:write(content)
  f:close()
end

local function split_lines(source)
  local lines = {}
  for line in source:gmatch("([^\n]*)\n?") do
    lines[#lines + 1] = line
  end
  if lines[#lines] == "" then lines[#lines] = nil end
  return lines
end

local function match_version(line)
  local major, minor, patch, date = line:match("^## (%d+)%.(%d+)%.(%d+)%s*(%(.-%))%s*$")
  if major then return major, minor, patch, date end
  major, minor, patch = line:match("^## (%d+)%.(%d+)%.(%d+)%s*$")
  return major, minor, patch, nil
end

local function transform(source)
  local out = {}
  local current_major, current_minor
  local in_version = false
  local in_unreleased = false

  local function push(line) out[#out + 1] = line end

  local function close_unreleased()
    if in_unreleased then
      push(UNRELEASED_CLOSE)
      push("")
      in_unreleased = false
    end
  end

  for i, line in ipairs(split_lines(source)) do
    if i == 1 and line == "# Changelog" then
      -- skip document title
    elseif line == "## Unreleased" then
      close_unreleased()
      push(UNRELEASED_OPEN)
      push("## Unreleased {#unreleased}")
      push("")
      in_unreleased = true
      current_major, current_minor = nil, nil
      in_version = false
    else
      local major, minor, patch, date = match_version(line)
      if major then
        close_unreleased()
        local minor_key = major .. "." .. minor
        if current_major ~= major then
          push("## " .. major .. " {#version-" .. major .. "}")
          push("")
          current_major = major
          current_minor = nil
        end
        if current_minor ~= minor_key then
          push("### " .. minor_key .. " {#version-" .. major .. "-" .. minor .. "}")
          push("")
          current_minor = minor_key
        end
        local heading = "#### " .. major .. "." .. minor .. "." .. patch
        if date and date ~= "" then heading = heading .. " " .. date end
        heading = heading .. " {#version-" .. major .. "-" .. minor .. "-" .. patch .. "}"
        push(heading)
        in_version = true
      elseif in_version and line:sub(1, 4) == "### " then
        push("##### " .. line:sub(5))
      elseif in_version and line:sub(1, 5) == "#### " then
        push("###### " .. line:sub(6))
      else
        push(line)
      end
    end
  end

  close_unreleased()

  local normalised = {}
  for _, l in ipairs(out) do
    if not (l == "" and normalised[#normalised] == "") then
      normalised[#normalised + 1] = l
    end
  end
  while normalised[1] == "" do table.remove(normalised, 1) end
  while normalised[#normalised] == "" do normalised[#normalised] = nil end
  if #normalised == 0 then return "" end
  return table.concat(normalised, "\n") .. "\n"
end

local source = read_file(INPUT)
local body = transform(source)
local content
if body == "" then
  content = FRONT_MATTER .. "\n" .. FOOTER
else
  content = FRONT_MATTER .. "\n" .. body .. "\n" .. FOOTER
end
write_file(OUTPUT, content)
io.write("Wrote " .. OUTPUT .. "\n")
