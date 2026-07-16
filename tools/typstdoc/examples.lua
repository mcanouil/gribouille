-- Example/gallery consistency: every `examples/*.typ` must have a `gallery.yml`
-- slug or be explicitly excluded, otherwise it never renders (the gallery
-- listing is slug-driven). Pure helpers; I/O lives in main.lua.
local util = require("util")

local M = {}

-- Hero/landing art embedded directly by `docs/index.qmd` and site assets,
-- deliberately absent from the gallery.
M.EXCLUDE = { gribouille = true, showcase = true }

-- Intent page keys for `docs/gallery/gallery.yml`; every entry must use one,
-- otherwise it never renders (each intent page filters on this field).
M.INTENTS = {
  comparison = true,
  distribution = true,
  evolution = true,
  correlation = true,
  ["part-to-whole"] = true,
  uncertainty = true,
  annotation = true,
  ["colour-scales"] = true,
  ["axes-legends"] = true,
  layout = true,
  themes = true,
  techniques = true,
}

-- Collect `slug:` values from a `gallery.yml` document body.
function M.parse_slugs(content)
  local slugs = {}
  for _, line in ipairs(util.split_lines(content)) do
    local slug = line:match('^%s*%-%s*slug:%s*"?([%w%-]+)"?')
    if slug then slugs[slug] = true end
  end
  return slugs
end

-- Collect ordered { slug, intent } records from a gallery document body.
function M.parse_entries(content)
  local entries, current = {}, nil
  for _, line in ipairs(util.split_lines(content)) do
    local slug = line:match('^%s*%-%s*slug:%s*"?([%w%-]+)"?')
    if slug then
      current = { slug = slug }
      entries[#entries + 1] = current
    elseif current then
      local intent = line:match('^%s+intent:%s*"?([%w%-]+)"?')
      if intent then current.intent = intent end
    end
  end
  return entries
end

-- Sorted list of "slug (intent)" strings whose intent is missing or unknown.
function M.bad_intents(entries, intents)
  intents = intents or M.INTENTS
  local out = {}
  for _, entry in ipairs(entries) do
    if not intents[entry.intent or ""] then
      out[#out + 1] = string.format("%s (%s)", entry.slug, entry.intent or "missing")
    end
  end
  table.sort(out)
  return out
end

-- Sorted list of example basenames that lack a slug and are not excluded.
-- `example_names` are file names with the `.typ` extension.
function M.orphans(example_names, slugs, exclude)
  exclude = exclude or M.EXCLUDE
  local out = {}
  for _, name in ipairs(example_names) do
    local base = name:match("^(.+)%.typ$")
    if base and not slugs[base] and not exclude[base] then
      out[#out + 1] = base
    end
  end
  table.sort(out)
  return out
end

return M
