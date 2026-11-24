--- @module "post-render"
--- @license MIT
--- @copyright 2026 Mickaël Canouil
--- @author Mickaël Canouil
--- @brief Mark the windows that hold a derived filename.
--- @description The pre-quarto filter puts a code block with a derived name
--- inside the window node Quarto builds for an explicit filename. Quarto
--- renders that node to a `code-with-filename` Div with no room for a class of
--- the filter's own. This pass runs after that render, so it finds the Div and
--- moves the `cw-auto` marker from the code block to the Div as
--- `code-window-auto`, which the stylesheet reads. It reads only the marker,
--- so it does nothing on a format where the pre-quarto filter set none.

--- Move the cw-auto marker from the code block to its window.
--- @param div pandoc.Div
--- @return pandoc.Div|nil The marked window, or nil when nothing changes
local function mark_auto_window(div)
  if not div.classes:includes('code-with-filename') then
    return nil
  end
  local found = false
  local content = div.content:walk({
    CodeBlock = function(block)
      local _, index = block.classes:find('cw-auto')
      if not index then
        return nil
      end
      found = true
      block.classes:remove(index)
      return block
    end
  })
  if not found then
    return nil
  end
  div.content = content
  div.classes:insert('code-window-auto')
  return div
end

if not quarto.doc.is_format('html') then
  return {}
end

return {
  { Div = mark_auto_window },
}
