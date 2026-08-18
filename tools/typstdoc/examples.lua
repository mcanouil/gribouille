-- Example/gallery consistency: every `examples/*.typ` must have a
-- `docs/gallery/gallery.yml` slug or be explicitly excluded, otherwise it never
-- renders (the gallery listing is slug-driven). Pure helpers; I/O lives in
-- main.lua.
local util = require("util")

local M = {}

-- Hero/landing art embedded directly by `docs/index.qmd` and site assets,
-- deliberately absent from the gallery.
M.EXCLUDE = { gribouille = true, showcase = true }

-- `gallery-intent` value of the hub page, which lists the intent cards rather
-- than filtering `gallery.yml`; it is a page mode, not a member of INTENTS.
M.HUB_INTENT = "hub"

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

-- Strip one layer of matching quotes and the trailing whitespace a flat YAML
-- parser leaves behind.
local function unquote(value)
  value = value:gsub("%s+$", "")
  local inner = value:match('^"(.*)"$') or value:match("^'(.*)'$")
  return inner or value
end

-- Collect ordered { slug, intent, showcase } records from a gallery document
-- body.
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
      local showcase = line:match("^%s+showcase:%s*(%a+)")
      if showcase then current.showcase = showcase == "true" end
    end
  end
  return entries
end

-- Ordered records from `docs/gallery/hub.yml`, one per card. Flat mappings
-- only, matching the parser in `docs/assets/lua/gallery-data.lua`.
function M.parse_cards(content)
  local cards, current = {}, nil
  for _, line in ipairs(util.split_lines(content)) do
    local head_key, head_value = line:match("^%-%s+([%w%-]+):%s*(.*)$")
    if head_key then
      current = { [head_key] = unquote(head_value) }
      cards[#cards + 1] = current
    elseif current then
      local key, value = line:match("^%s+([%w%-]+):%s*(.*)$")
      if key then current[key] = unquote(value) end
    end
  end
  return cards
end

-- Gallery page file names referenced by `docs/_sidebar-gallery.yml`, in order.
function M.parse_sidebar_pages(content)
  local out = {}
  for _, line in ipairs(util.split_lines(content)) do
    local href = line:match('^%s*%-?%s*href:%s*"?gallery/([%w%-]+%.qmd)"?')
    if href then out[#out + 1] = href end
  end
  return out
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

-- Both intent declarations on a gallery page: `declared` is the top-level
-- `gallery-intent` the Lua filter reads to inject renders, `include` is the
-- listing filter Quarto reads to pick cards. They must agree, and the hub
-- carries no `include`. Only the front matter is read, so an indented
-- `intent:` line in a fenced block documenting the gallery format is ignored.
function M.parse_page_intent(content)
  local out = {}
  local in_front_matter = false
  for _, line in ipairs(util.split_lines(content)) do
    if line:match("^%-%-%-%s*$") then
      if in_front_matter then break end
      in_front_matter = true
    elseif in_front_matter then
      local declared = line:match('^gallery%-intent:%s*"?([%w%-]+)"?')
      if declared then
        out.declared = declared
      else
        local include = line:match('^%s+intent:%s*"?([%w%-]+)"?')
        if include then out.include = include end
      end
    end
  end
  return out
end

-- Fold per-page declarations into the two maps `intent_drift` consumes, and
-- report every intent claimed by more than one page. A map keyed on the intent
-- keeps only the last claimant, so without this the duplicate is invisible
-- while both pages render the same listing. `decls` is an ordered list of
-- { page, declared, include }.
function M.fold_page_intents(decls)
  local page_intents, page_includes, duplicates = {}, {}, {}
  for _, decl in ipairs(decls) do
    local owner = page_intents[decl.declared]
    if owner then
      duplicates[#duplicates + 1] = string.format(
        "intent %q is declared by both %s and %s", decl.declared, owner, decl.page)
    else
      page_intents[decl.declared] = decl.page
    end
    page_includes[decl.page] = decl.include
  end
  table.sort(duplicates)
  return page_intents, page_includes, duplicates
end

-- Sorted list of drift between the intent taxonomy and the pages rendering it.
-- `page_intents` maps a `gallery-intent` value to the page declaring it;
-- `page_includes` maps a page to its listing `include.intent`. Without this an
-- intent with no page, a page with an unknown intent, and a page whose two
-- declarations disagree all build green with a silently empty listing.
function M.intent_drift(page_intents, intents, page_includes)
  intents = intents or M.INTENTS
  page_includes = page_includes or {}
  local out = {}

  for intent, has in pairs(intents) do
    if has and not page_intents[intent] then
      out[#out + 1] = string.format("intent %q has no page", intent)
    end
  end

  for intent, page in pairs(page_intents) do
    if intent ~= M.HUB_INTENT then
      if not intents[intent] then
        out[#out + 1] = string.format("page %s declares unknown intent %q", page, intent)
      end
      local include = page_includes[page]
      if include and include ~= intent then
        out[#out + 1] = string.format(
          "page %s declares intent %q but its listing filters %q", page, intent, include)
      end
    end
  end

  table.sort(out)
  return out
end

-- Sorted list of drift between the gallery pages on disk and the two surfaces
-- that must reach them: the cards in `hub.yml` and the entries in
-- `_sidebar-gallery.yml`. `intent_drift` covers the taxonomy but not the
-- navigation, so without this a new page builds green with nothing linking to
-- it. All three arguments are lists of page file names, hub page excluded.
function M.nav_drift(pages, card_pages, sidebar_pages)
  local out = {}
  local on_disk = {}
  for _, page in ipairs(pages) do on_disk[page] = true end

  local surfaces = {
    { label = "hub.yml card", entries = card_pages },
    { label = "_sidebar-gallery.yml entry", entries = sidebar_pages },
  }
  for _, surface in ipairs(surfaces) do
    local seen = {}
    for _, page in ipairs(surface.entries) do
      seen[page] = (seen[page] or 0) + 1
      if not on_disk[page] and seen[page] == 1 then
        out[#out + 1] = string.format("%s points at missing page %s", surface.label, page)
      end
    end
    for _, page in ipairs(pages) do
      local count = seen[page] or 0
      if count == 0 then
        out[#out + 1] = string.format("page %s has no %s", page, surface.label)
      elseif count > 1 then
        out[#out + 1] = string.format("page %s has %d %ss", page, count, surface.label)
      end
    end
  end

  table.sort(out)
  return out
end

-- Sorted list of `hub.yml` heroes that name no `gallery.yml` slug. The hub
-- filter emits `/assets/examples/<hero>.typ` for whatever string it finds, so a
-- typo becomes a Typst compile failure with no pointer back to the card.
function M.bad_heroes(cards, slugs)
  local out = {}
  for _, card in ipairs(cards) do
    local where = card.href or card.title or "?"
    if not card.hero or card.hero == "" then
      out[#out + 1] = string.format("missing (%s)", where)
    elseif not slugs[card.hero] then
      out[#out + 1] = string.format("%s (%s)", card.hero, where)
    end
  end
  table.sort(out)
  return out
end

-- Sorted list of showcase entries that sit on a craft page. A craft page renders
-- only its `Feature demos` section by design, so one `showcase: true` there
-- produces a one-card `Showcase` section above it.
function M.craft_showcases(entries, craft_intents)
  local out = {}
  for _, entry in ipairs(entries) do
    if entry.showcase and craft_intents[entry.intent or ""] then
      out[#out + 1] = string.format("%s (%s)", entry.slug, entry.intent)
    end
  end
  table.sort(out)
  return out
end

-- Line numbers where a flat-parser YAML file opens a block or folded scalar.
-- Both `gallery.yml` and `hub.yml` are read one line per key, so such a value is
-- dropped without a word.
function M.block_scalars(content)
  local out = {}
  for index, line in ipairs(util.split_lines(content)) do
    if line:match("^%s*%-?%s*[%w%-]+:%s*[|>][%-+%d]*%s*$") then
      out[#out + 1] = index
    end
  end
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
