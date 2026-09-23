--- MC Pandoc Helpers - Pandoc element construction and format detection for Quarto Lua filters and shortcodes
--- @module "pandoc_helpers"
--- @license MIT
--- @copyright 2026 Mickaël Canouil
--- @author Mickaël Canouil

local M = {}

--- Load a sibling module from the same directory as this file.
--- @param filename string The sibling module filename (e.g., 'string.lua')
--- @return table The loaded module
local function load_sibling(filename)
  local source = debug.getinfo(1, 'S').source:sub(2)
  local dir = source:match('(.*[/\\])') or ''
  return require((dir .. filename):gsub('%.lua$', ''))
end

--- Load string module for is_empty
local str = load_sibling('string.lua')

-- ============================================================================
-- PANDOC/QUARTO FORMAT UTILITIES
-- ============================================================================

--- Create a Pandoc Link element
--- @param text string|nil The link text
--- @param uri string|nil The URI to link to
--- @return pandoc.Link|nil A Pandoc Link element or nil if text or uri is empty
function M.create_link(text, uri)
  if not str.is_empty(uri) and not str.is_empty(text) then
    return pandoc.Link({ pandoc.Str(text --[[@as string]]) }, uri --[[@as string]])
  end
  return nil
end

--- Helper to build Pandoc attributes
--- @param id string|nil Element ID
--- @param classes table|nil List of CSS classes
--- @param attributes table|nil Key-value attributes
--- @return pandoc.Attr Pandoc Attr object
function M.attr(id, classes, attributes)
  return pandoc.Attr(id or '', classes or {}, attributes or {})
end

--- Check if a class list contains a specific class name
--- @param classes table|nil List of CSS classes
--- @param name string The class name to search for
--- @return boolean True if the class is found, false otherwise
function M.has_class(classes, name)
  if not classes then return false end
  for _, cls in ipairs(classes) do
    if cls == name then return true end
  end
  return false
end

--- Add a class to the class list if it doesn't already exist
--- @param classes table List of CSS classes
--- @param name string The class name to add
function M.add_class(classes, name)
  if not M.has_class(classes, name) then
    table.insert(classes, name)
  end
end

--- Retrieve the current Quarto output format.
--- @return string The output format ("pptx", "html", "latex", "typst", "docx", or "unknown")
--- @return string The language of the output format
function M.get_quarto_format()
  if quarto.doc.is_format('html:js') then
    return 'html', 'html'
  elseif quarto.doc.is_format('latex') then
    return 'latex', 'latex'
  elseif quarto.doc.is_format('typst') then
    return 'typst', 'typst'
  elseif quarto.doc.is_format('docx') then
    return 'docx', 'openxml'
  elseif quarto.doc.is_format('pptx') then
    return 'pptx', 'openxml'
  else
    return 'unknown', 'unknown'
  end
end

-- ============================================================================
-- OBJECT/TABLE UTILITIES
-- ============================================================================

--- Check if an object (including tables and lists) is empty or nil
--- @param obj any The object to check
--- @return boolean true if the object is nil, empty string, or empty table/list
function M.is_object_empty(obj)
  local function length(x)
    local count = 0
    if x ~= nil then
      for _ in pairs(x) do
        count = count + 1
      end
    end
    return count
  end
  if pandoc.utils.type(obj) == 'table' or pandoc.utils.type(obj) == 'List' then
    return obj == nil or obj == '' or length(obj) == 0
  else
    return obj == nil or obj == ''
  end
end

--- Check if an object is a simple type (string, number, or boolean)
--- @param obj any The object to check
--- @return boolean true if the object is a string, number, or boolean
function M.is_type_simple(obj)
  return pandoc.utils.type(obj) == 'string' or pandoc.utils.type(obj) == 'number' or pandoc.utils.type(obj) == 'boolean'
end

--- Check if an object is a function or userdata
--- @param obj any The object to check
--- @return boolean true if the object is a function or userdata
function M.is_function_userdata(obj)
  return pandoc.utils.type(obj) == 'function' or pandoc.utils.type(obj) == 'userdata'
end

--- Get nested value from object using field path
--- @param fields table Array of field names to traverse
--- @param obj table The object to extract value from
--- @return any The value at the nested path
--- @usage local val = M.get_value({"a", "b", "c"}, obj)
function M.get_value(fields, obj)
  local value = obj
  for _, field in ipairs(fields) do
    value = value[field]
  end
  return value
end

--- Convert Pandoc AttributeList to plain table for easier processing.
--- @param element table Element with attributes field (Div, Span, Table, Image)
--- @return table Plain table with attribute key-value pairs
function M.attributes_to_table(element)
  local attrs = {}
  for k, v in pairs(element.attributes) do
    attrs[k] = v
  end
  return attrs
end

-- ============================================================================
-- MODULE EXPORT
-- ============================================================================

return M
