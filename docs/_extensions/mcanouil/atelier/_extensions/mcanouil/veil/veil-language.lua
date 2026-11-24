--- Veil - Language module
--- @module "veil-language"
--- @license MIT License
--- @copyright 2026 Mickaël Canouil
--- @author Mickaël Canouil
--- @brief The interface text of the runtime, in the language of the document.
--- @description Starts from the English text, applies the built-in text of the
--- document language, then applies the Quarto `language` keys of the document.

local M = {}

--- The built-in text, by language code. English is the base of all the others.
local BUILT_IN = {
  en = {
    ['veil-name'] = 'Veil',
    ['veil-level'] = 'Level',
    ['veil-groups'] = 'Groups',
    ['veil-none'] = 'none',
    ['veil-shown'] = 'shown',
    ['veil-hidden'] = 'hidden',
    ['veil-open-popover'] = 'Open the Veil popover',
    ['veil-level-up'] = 'Show the next level of content',
    ['veil-level-down'] = 'Hide the current level of content',
  },
  fr = {
    ['veil-name'] = 'Veil',
    ['veil-level'] = 'Niveau',
    ['veil-groups'] = 'Groupes',
    ['veil-none'] = 'aucun',
    ['veil-shown'] = 'affiché',
    ['veil-hidden'] = 'masqué',
    ['veil-open-popover'] = 'Ouvrir le panneau Veil',
    ['veil-level-up'] = 'Afficher le niveau de contenu suivant',
    ['veil-level-down'] = 'Masquer le niveau de contenu actuel',
  },
}

--- Read a metadata value as a string.
--- @param value any
--- @return string|nil
local function as_text(value)
  if value == nil then
    return nil
  end
  if type(value) == 'string' then
    return value
  end
  return pandoc.utils.stringify(value)
end

-- ============================================================================
-- PUBLIC FUNCTIONS
-- ============================================================================

--- The interface text of the document.
--- @param meta table Document metadata
--- @return table strings Map from key to text
function M.strings(meta)
  local strings = {}
  for key, text in pairs(BUILT_IN.en) do
    strings[key] = text
  end
  local code = (as_text(meta.lang) or ''):match('^(%a+)')
  local built_in = code and BUILT_IN[code:lower()]
  for key, text in pairs(built_in or {}) do
    strings[key] = text
  end
  local language = meta.language
  if type(language) == 'table' then
    for key, _ in pairs(strings) do
      local text = as_text(language[key])
      if text ~= nil and text ~= '' then
        strings[key] = text
      end
    end
  end
  return strings
end

return M
