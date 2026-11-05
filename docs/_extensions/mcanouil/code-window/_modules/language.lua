--- @module "language"
--- @license MIT
--- @copyright 2026 Mickaël Canouil
--- @author Mickaël Canouil
--- @brief Put the language class of a code block first, or add one.

local cell_output = require(
  quarto.utils.resolve_path('_modules/cell-output.lua'):gsub('%.lua$', ''))
local str = require(
  quarto.utils.resolve_path('_vendor/quarto-lua-modules/string.lua'):gsub('%.lua$', ''))

local M = {}

local known_language_cache = {}

--- Classes that turn on line numbers in Pandoc. They are not languages.
local NUMBERING_CLASSES = { ['numberLines'] = true, ['number-lines'] = true, ['number'] = true }

--- Check if a language is recognised by Pandoc's syntax highlighter.
--- Renders a test CodeBlock to HTML and checks that Pandoc names a language
--- on the code element, not only the sourceCode class.
--- @param lang string Language identifier
--- @return boolean
local function is_known_language(lang)
  if not lang or lang == '' or NUMBERING_CLASSES[lang] then
    return false
  end

  if known_language_cache[lang] ~= nil then
    return known_language_cache[lang]
  end

  local test_block = pandoc.CodeBlock('x', pandoc.Attr('', { lang }))
  local html = pandoc.write(pandoc.Pandoc({ test_block }), 'html')
  local is_known = html:find('<code%s+class="sourceCode%s+[^"]') ~= nil
  known_language_cache[lang] = is_known
  return is_known
end

--- Read the label that names a block's window, set by this module, by the
--- author, or by another filter. An empty value counts as no label.
--- @param block pandoc.CodeBlock
--- @return string|nil label
function M.auto_label(block)
  local label = block.attributes['code-window-auto-label']
  if str.is_empty(label) then
    return nil
  end
  return label
end

--- Set the label unless the block already has a filename or a label.
--- @param block pandoc.CodeBlock
--- @param label string
local function set_label(block, label)
  if str.is_empty(block.attributes['filename']) and not M.auto_label(block) then
    block.attributes['code-window-auto-label'] = label
  end
end

--- Find the class that Pandoc highlights the block with: the first class it
--- knows as a language, which need not be the first class.
--- @param classes pandoc.List
--- @return integer|nil index
local function find_language(classes)
  for index, class in ipairs(classes) do
    if is_known_language(class) then
      return index
    end
  end
  return nil
end

--- Find the label for a block with no language: the first class that is not a
--- line-numbering class.
--- @param classes pandoc.List
--- @return string|nil label
local function find_label(classes)
  for _, class in ipairs(classes) do
    if not NUMBERING_CLASSES[class] then
      return class
    end
  end
  return nil
end

--- Put the language class first, or add "default" in front when there is none.
--- The window is named after the first class, so it then names the class that
--- Pandoc highlights with. The label goes on `code-window-auto-label`, not on
--- `filename`, which is for author-set names. The output of an executed cell
--- is left as Quarto wrote it.
--- @param block pandoc.CodeBlock
--- @return pandoc.CodeBlock|nil
function M.CodeBlock(block)
  if cell_output.is_marked(block) then
    return nil
  end

  local index = find_language(block.classes)
  if index then
    block.classes:insert(1, block.classes:remove(index))
    return block
  end

  set_label(block, find_label(block.classes) or 'default')
  block.classes:insert(1, 'default')
  return block
end

return M
