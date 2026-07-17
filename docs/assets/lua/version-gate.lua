--- @license MIT
--- @copyright 2026 Mickaël Canouil
--- @author Mickaël Canouil
--
-- Gates a page against the version being built. Docs content always comes from
-- `main`, while `src`/`lib.typ` are pinned to a release tag, so a page written
-- for unreleased API cannot compile on a release build. Pages declare the
-- version that introduced them with `since:` in the frontmatter; when that is
-- newer than `VERSION`, the body is replaced with a callout pointing at the dev
-- documentation.
--
-- Runs before `typst-render` so gated blocks never reach the compiler.
-- `VERSION` is `dev` (or unset, when rendering locally), which never gates.

local DEV_BASE = 'https://m.canouil.dev/gribouille/dev'

--- Parse a dotted version into a comparable list of integers.
--- Returns nil for anything that is not `major.minor.patch`, notably `dev`.
local function parse_version(value)
  if not value then return nil end
  local parts = {}
  for n in tostring(value):gmatch('(%d+)') do
    parts[#parts + 1] = tonumber(n)
  end
  if #parts == 0 then return nil end
  return parts
end

--- Return true when `a` is strictly newer than `b`.
local function is_newer(a, b)
  for i = 1, math.max(#a, #b) do
    local x, y = a[i] or 0, b[i] or 0
    if x ~= y then return x > y end
  end
  return false
end

--- Same page on the dev site: `guides/wrangle.qmd` -> `<dev>/guides/wrangle.html`.
--- Falls back to the dev site root when the input path cannot be resolved.
local function dev_url()
  local input = quarto.doc.input_file
  local root = quarto.project.directory
  if not input or not root then return DEV_BASE .. '/' end
  local rel = input:sub(#root + 2):gsub('%.qmd$', '.html')
  if rel == '' then return DEV_BASE .. '/' end
  return DEV_BASE .. '/' .. rel
end

local function stub(since, version)
  local body = pandoc.Para({
    pandoc.Str('This page documents features added in '),
    pandoc.Strong({ pandoc.Str(since) }),
    pandoc.Str(', which are not available in '),
    pandoc.Strong({ pandoc.Str(version) }),
    pandoc.Str('. Read it in the '),
    pandoc.Link({ pandoc.Str('development documentation') }, dev_url()),
    pandoc.Str('.'),
  })
  return pandoc.Div(
    { body },
    pandoc.Attr('', { 'callout-note' }, { title = 'Added in ' .. since })
  )
end

--- Quarto injects a hidden `#quarto-navigation-envelope` div carrying the
--- navbar/sidebar markdown, then reads it back in an HTML post-processor
--- (`website-navigation.ts`). It is not page content, and dropping it crashes
--- the render, so hidden blocks survive the swap.
local function is_hidden(block)
  return block.t == 'Div' and block.classes:includes('hidden')
end

function Pandoc(doc)
  local since = doc.meta.since
  if not since then return nil end

  local target = parse_version(os.getenv('VERSION'))
  if not target then return nil end

  since = pandoc.utils.stringify(since)
  local introduced = parse_version(since)
  if not introduced or not is_newer(introduced, target) then return nil end

  local kept = pandoc.Blocks({ stub(since, os.getenv('VERSION')) })
  for _, block in ipairs(doc.blocks) do
    if is_hidden(block) then kept:insert(block) end
  end
  doc.blocks = kept
  return doc
end
