--- @module "main"
--- @license MIT
--- @copyright 2026 Mickaël Canouil
--- @author Mickaël Canouil
--- @brief Entry point for the code-window extension.
--- Loads all submodules, wires dependencies, and assembles the filter list.

local EXTENSION_NAME = 'code-window'
local log = require(quarto.utils.resolve_path('_vendor/quarto-lua-modules/logging.lua'):gsub('%.lua$', ''))
local schema = require(quarto.utils.resolve_path('_vendor/quarto-wizard/schema.lua'):gsub('%.lua$', ''))
local check = require(quarto.utils.resolve_path('_vendor/quarto-lua-modules/schema-check.lua'):gsub('%.lua$', ''))

--- The checker reports what "extensions.code-window" declares that this
--- extension cannot use. The validator is handed to it rather than required by
--- it, so the two vendored sources stay independent of each other. Building it
--- here reads "_schema.yml" once for the whole render. A schema that cannot be
--- read is reported and the render carries on: a fault in the configuration
--- must not remove the document.
local checker = check.new(schema, EXTENSION_NAME)

-- ============================================================================
-- LOAD SUBMODULES
-- ============================================================================

local cell_output = require(
  quarto.utils.resolve_path('_modules/cell-output.lua'):gsub('%.lua$', ''))

local language = require(
  quarto.utils.resolve_path('_modules/language.lua'):gsub('%.lua$', ''))

local code_annotations = require(
  quarto.utils.resolve_path('_modules/hotfix/code-annotations.lua'):gsub('%.lua$', ''))

local code_window = require(
  quarto.utils.resolve_path('code-window.lua'):gsub('%.lua$', ''))

code_window.set_code_annotations(code_annotations)
code_window.set_checker(checker)

-- ============================================================================
-- CELL OUTPUT
-- ============================================================================

--- Mark the code blocks that hold the output of an executed cell, so the later
--- passes leave them as Quarto wrote them. Walks the document only when there
--- is a pass to hold back, which means this render draws chrome and the output
--- has to stay unframed. Every reader that acts on the mark asks draws_chrome
--- first: the language pass below, and the two window paths. CodeBlock reads it
--- too, but only to remove it, and a mark that was never set costs nothing
--- there. So a render that draws no chrome would walk the whole document to set
--- an attribute nothing goes on to act on. draws_chrome answers false when
--- there is no configuration yet, so the second test below always has one in
--- hand.
--- @param doc pandoc.Pandoc
--- @return pandoc.Pandoc|nil Marked document, or nil when the pass is skipped
local function mark_cell_output(doc)
  if not code_window.draws_chrome() or code_window.CONFIG().cell_output then
    return nil
  end
  doc.blocks = doc.blocks:walk({ Div = cell_output.Div })
  return doc
end

-- ============================================================================
-- LANGUAGE
-- ============================================================================

--- Normalise a block's language where the render draws chrome.
--- The pass labels a block whose language Pandoc cannot highlight, and the
--- derived filename is the only reader of that label. Nothing derives a
--- filename in a render that draws no chrome, so the pass would rewrite a
--- class for nobody and hand the author back a language they did not write.
--- "auto-filename" belongs in the same question, because it is the reader
--- itself: with no derived name to build, both window paths return before they
--- read the label, so the pass would rewrite a class for nobody again.
--- Every question this asks is about the render, not about one block. A block
--- can still draw no chrome inside a render that does, through
--- "code-window-no-auto-filename" or "code-window-enabled", and its class is
--- rewritten with no reader either. Answering that per block means relabelling
--- where the name is built, which is a change to the two window paths rather
--- than to this gate.
--- @param block pandoc.CodeBlock
--- @return pandoc.CodeBlock|nil Relabelled block, or nil when the pass is skipped
local function normalise_language(block)
  if not code_window.draws_chrome() or not code_window.CONFIG().auto_filename then
    return nil
  end
  return language.CodeBlock(block)
end

-- ============================================================================
-- SKYLIGHTING HOT-FIX
-- ============================================================================

--- Load optional skylighting hot-fix module from sibling file.
--- @return table Module table with .filters and .set_wrapper, or empty table
local function load_skylighting_hotfix_module()
  local ok, result = pcall(require,
    quarto.utils.resolve_path('_modules/hotfix/skylighting-typst-fix.lua'):gsub('%.lua$', ''))
  if not ok then
    log.log_warning(EXTENSION_NAME,
      'Failed to load optional skylighting hot-fix: ' .. tostring(result))
    return {}
  end
  if type(result) ~= 'table' then
    log.log_warning(EXTENSION_NAME,
      'Skylighting hot-fix did not return a module table.')
    return {}
  end
  return result
end

-- ============================================================================
-- FILTER ASSEMBLY
-- ============================================================================

-- Meta runs first because the cell-output pass needs the configuration, and
-- that pass runs before the language pass so a marked block is never relabelled.
local filters = {
  { Meta = code_window.Meta },
  { Pandoc = mark_cell_output },
  { CodeBlock = normalise_language },
  { Pandoc = code_window.Pandoc },
  { CodeBlock = code_window.CodeBlock },
}

local skylighting_mod = load_skylighting_hotfix_module()

-- The hot-fix exists only to serve the chrome, so it asks draws_chrome like
-- every other pass that does. Its Skylighting override calls the colour helpers,
-- and code_window.Pandoc is what declares them, so asking hotfix_skylighting
-- alone left the override in a document that declared none.
for _, subfilter in ipairs(skylighting_mod.filters or {}) do
  local wrapped = {}
  for element_type, handler in pairs(subfilter) do
    wrapped[element_type] = function(...)
      if not code_window.draws_chrome() then
        return nil
      end
      local cfg = code_window.CONFIG()
      if not cfg.hotfix_skylighting then
        return nil
      end
      if skylighting_mod.set_wrapper then
        skylighting_mod.set_wrapper(cfg.typst_wrapper)
      end
      return handler(...)
    end
  end
  table.insert(filters, wrapped)
end

return filters
