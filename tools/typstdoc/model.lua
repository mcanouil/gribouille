local M = {}

-- Resolve a documented `..rest` sink's accepted keys into `{name, description}`
-- rows. Each key inherits the shared template from `@named-keys <keys> : <template>`
-- (`{}` expands to the key name) unless an explicit `@param <key>` overrides it.
-- Returns an empty list when the function declares no `@named-keys`.
function M.resolve_named_keys(doc)
  if not doc.named_keys or #doc.named_keys == 0 then return {} end
  local override = {}
  for _, p in ipairs(doc.params) do
    if p.description and p.description ~= "" then override[p.name] = p.description end
  end
  local rows = {}
  for _, key in ipairs(doc.named_keys) do
    local desc = override[key]
    if not desc and doc.named_keys_doc then desc = (doc.named_keys_doc:gsub("{}", key)) end
    rows[#rows + 1] = { name = key, description = desc or "" }
  end
  return rows
end

function M.new_param(opts)
  return {
    name = opts.name,
    variadic = opts.variadic or false,
    default = opts.default,
    description = opts.description or "",
  }
end

function M.new_example(opts)
  return {
    render = opts.render,
    segments = opts.segments or {},
  }
end

function M.new_arity(opts)
  return {
    signature = opts.signature,
    description = opts.description or "",
  }
end

function M.new_doc_block()
  return {
    summary = nil,
    description = {},
    category = nil,
    subcategory = nil,
    stability = "stable",
    since = nil,
    params = {},
    arities = {},
    named_keys = {},
    named_keys_doc = nil,
    has_theme_keys = false,
    returns = nil,
    examples = {},
    see = {},
    is_internal = false,
    is_advanced = false,
  }
end

function M.new_function(opts)
  return {
    kind = opts.kind or "function",
    name = opts.name,
    file = opts.file,
    line = opts.line,
    signature_params = opts.signature_params or {},
    signature_raw = opts.signature_raw or "",
    is_value = opts.is_value or false,
    doc = opts.doc,
  }
end

return M
