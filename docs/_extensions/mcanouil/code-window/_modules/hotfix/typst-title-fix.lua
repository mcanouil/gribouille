--- @module "typst-title-fix"
--- @license MIT
--- @copyright 2026 Mickaël Canouil
--- @author Mickaël Canouil
--- @brief Hot-fix for Quarto rendering theorem titles as string parameters.
--- Quarto renders custom type titles as title: "..." (string mode) which
--- stringifies any Typst markup. This post-quarto filter scans the source
--- for cross-reference div IDs, then injects Typst wrapper functions that
--- evaluate string titles as Typst markup via eval(mode: "markup").

--- Mapping from Quarto cross-reference prefix to Typst function name.
local PREFIX_TO_FUNC = {
  thm = 'theorem',
  lem = 'lemma',
  cor = 'corollary',
  prp = 'proposition',
  cnj = 'conjecture',
  def = 'definition',
  exm = 'example',
  exr = 'exercise',
  sol = 'solution',
}

--- Typst wrapper template. %s is replaced with the function name.
local WRAPPER_TEMPLATE = [==[
#let _cw-orig-%s = %s
#let %s(title: none, ..args) = {
  let t = if title != none and type(title) == str {
    eval(title, mode: "markup")
  } else {
    title
  }
  _cw-orig-%s(title: t, ..args)
}]==]

--- Build Typst code that wraps each theorem function to eval string titles.
--- @param func_names table List of function names to wrap
--- @return string Typst code
local function build_wrappers(func_names)
  local parts = { '// code-window: hot-fix for Quarto rendering theorem titles as strings.' }
  for _, name in ipairs(func_names) do
    table.insert(parts, string.format(WRAPPER_TEMPLATE, name, name, name, name))
  end
  return table.concat(parts, '\n')
end

--- Scan source files for cross-reference div IDs and return the
--- corresponding Typst function names.
--- NOTE: uses raw-text pattern matching on source files, so it will not
--- detect divs inside `include` shortcodes or other indirect sources.
--- @return table List of function names
local function detect_theorem_types()
  local func_names = {}
  local seen = {}
  for _, input_file in ipairs(PANDOC_STATE.input_files) do
    local f = io.open(input_file, 'r')
    if f then
      local ok, source = pcall(f.read, f, '*a')
      f:close()
      if not ok then source = '' end
      for prefix in source:gmatch('::: *{#(%w+)%-') do
        if PREFIX_TO_FUNC[prefix] and not seen[prefix] then
          table.insert(func_names, PREFIX_TO_FUNC[prefix])
          seen[prefix] = true
        end
      end
    end
  end
  return func_names
end

return {
  {
    Pandoc = function(doc)
      if not quarto.doc.is_format('typst') then
        return doc
      end

      -- Check if the hotfix is enabled via metadata set by the pre-quarto filter.
      local hotfix_meta = doc.meta['_code-window-hotfix']
      if hotfix_meta then
        local enabled = hotfix_meta['typst-title']
        if enabled and pandoc.utils.stringify(enabled) == 'false' then
          return doc
        end
      end

      -- Guard: skip if already injected.
      for _, blk in ipairs(doc.blocks) do
        if blk.t == 'RawBlock' and blk.format == 'typst'
            and blk.text:find('code-window: hot-fix for Quarto rendering theorem titles', 1, true) then
          return doc
        end
      end

      local func_names = detect_theorem_types()
      if #func_names == 0 then
        return doc
      end

      -- Insert at the start of doc.blocks. RawBlocks placed here appear
      -- after the Typst template preamble (where make-frame defines the
      -- theorem functions), so the wrappers can reference them.
      -- This relies on Quarto emitting the template preamble before
      -- doc.blocks; if that ordering changes the wrappers will break.
      table.insert(doc.blocks, 1, pandoc.RawBlock('typst', build_wrappers(func_names)))

      return doc
    end,
  },
}
