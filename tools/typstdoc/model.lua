local M = {}

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
