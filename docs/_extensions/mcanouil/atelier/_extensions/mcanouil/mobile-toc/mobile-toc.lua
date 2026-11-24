--- Mobile TOC - Filter
--- @module "mobile-toc"
--- @license MIT
--- @copyright 2026 Mickaël Canouil
--- @author Mickaël Canouil
--- @brief Load the narrow-screen table of contents on pages that have one.
--- @description Adds the script and the stylesheet to Bootstrap HTML pages
--- whose `toc` is true, and writes the options block that the script reads
--- into the head. The close label is the default text, or the `language` key
--- `mobile-toc-close` when the project or the page sets one.

--- Close label when the `language` key is unset or empty.
local DEFAULT_CLOSE_LABEL = 'Close'

--- Check that the page has a table of contents that the script can copy.
--- The `toc` option is not in the metadata at this stage, so the filter reads
--- the writer options, which also cover a `toc` set under the format.
--- @return boolean True when the page uses Bootstrap and the writer builds a table of contents
local function has_toc()
  return quarto.doc.has_bootstrap() and PANDOC_WRITER_OPTIONS.table_of_contents == true
end

--- Resolve the label of the close button.
--- @return string The `mobile-toc-close` language key, or the default text
local function resolve_close_label()
  local language = quarto.doc.language or {}
  local value = language['mobile-toc-close']
  if type(value) == 'string' and value ~= '' then
    return value
  end
  return DEFAULT_CLOSE_LABEL
end

--- Add the dependency and the options block to the page.
--- @return nil
local function publish_options()
  if not has_toc() then
    return nil
  end
  quarto.doc.add_html_dependency({
    name = 'mobile-toc',
    scripts = { 'mobile-toc.js' },
    stylesheets = { 'mobile-toc.css' },
  })
  local json = quarto.json.encode({ labels = { close = resolve_close_label() } }):gsub('</', '<\\/')
  quarto.doc.include_text(
    'in-header',
    '<script type="application/json" id="mobile-toc-options">' .. json .. '</script>'
  )
  return nil
end

return {
  { Meta = publish_options },
}
